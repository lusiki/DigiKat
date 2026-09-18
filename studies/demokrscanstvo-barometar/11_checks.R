source("studies/demokrscanstvo-barometar/08_aggregate.R",encoding="UTF-8")
source("R/lib/barometar_page.R",encoding="UTF-8")

barometar_release_checks <- function(directory,synthetic_allowed=FALSE,private_candidates=NULL,extra_public_files=character()) {
  release <- barometar_read_release(directory,synthetic_allowed)
  files <- list.files(directory,recursive=TRUE)
  if(any(!stringi::stri_detect_regex(files,"[.](csv|json|md|svg|png|pdf)$")))stop("Unexpected public artifact type.")
  strings <- character()
  for(name in files) {
    path <- file.path(directory,name)
    if(stringi::stri_detect_regex(name,"[.](csv|json|md|svg)$")) {
      raw <- readBin(path,"raw",file.info(path)$size)
      if(any(raw==as.raw(13)))stop("Public text file contains CRLF: ",name)
      if(endsWith(name,".csv") && !identical(head(raw,3L),as.raw(c(239,187,191))))stop("CSV lacks UTF-8 BOM: ",name)
    }
    object <- if(endsWith(name,".csv"))utils::read.csv(path,fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE,na.strings="") else
      if(endsWith(name,".json"))jsonlite::fromJSON(path,simplifyVector=FALSE) else
      if(endsWith(name,".md"))readLines(path,encoding="UTF-8") else
      if(endsWith(name,".svg"))xml2::xml_text(xml2::xml_find_all(xml2::read_xml(path),"//*[local-name()='text']")) else NULL
    if(!is.null(object)) {
      checked <- barometar_public_inspect(object,name)
      if(length(checked$issues))stop(paste(checked$issues,collapse="\n"))
      strings <- union(strings,checked$strings)
    }
  }
  tables <- release$tables[c("monthly","weekly","rolling28")]
  for(table in tables) {
    count_fields <- c("matching_articles","total_articles","matching_outlets","panel_outlets","panel_active")
    counts <- unlist(table[count_fields],use.names=FALSE)
    if(anyNA(counts)||any(!is.finite(counts)|counts<0|counts!=floor(counts)) ||
      any(table$matching_articles>table$total_articles | table$matching_outlets>table$panel_outlets | table$panel_active>table$panel_outlets) ||
      anyDuplicated(table[c("scope","period_id")]))stop("Invalid period counts or keys.")
    for(metric in c("visibility_per_10000","breadth_pct")) {
      status <- table[[if(metric=="breadth_pct")"breadth_status" else "visibility_status"]]
      expected <- if(metric=="breadth_pct")100*table$matching_outlets/table$panel_outlets else 1e4*table$matching_articles/table$total_articles
      if(any(!status %in% c("published","partial","unavailable")) ||
        any(is.na(table[[metric]])!=(status=="unavailable")) ||
        any(abs(table[[metric]][status!="unavailable"]-expected[status!="unavailable"])>1e-9))stop("Indicator/status reconciliation failed.")
    }
  }
  read <- function(name)utils::read.csv(file.path(directory,paste0(name,".csv")),fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE,na.strings="")
  series <- rbind(tables$monthly,tables$weekly)
  key <- function(x)paste(x$frequency,x$scope,x$period_id,sep="|")
  themes <- read("themes");matched <- match(key(themes),key(series))
  if(anyNA(matched) || any(themes$total_articles!=series$total_articles[matched]) ||
    any(themes$articles_with_theme>series$matching_articles[matched] | themes$articles_with_theme<0))stop("Theme count reconciliation failed.")
  composition <- read("composition")
  for(facet in c("route_set","speaker_type","reference_geography","outlet_segment","register")) {
    part <- composition[composition$facet==facet,,drop=FALSE]
    if(!nrow(part))next
    sums <- aggregate(articles~frequency+scope+period_id,part,sum)
    if(any(sums$articles!=series$matching_articles[match(key(sums),key(series))]))stop("Composition reconciliation failed: ",facet)
  }
  sensitivity <- read("sensitivity");matched <- match(key(sensitivity),key(series))
  if(anyNA(matched) || any(sensitivity$total_articles>series$total_articles[matched] |
    sensitivity$matching_articles>series$matching_articles[matched]))stop("Sensitivity counts exceed parent series.")
  for(path in extra_public_files)strings <- union(strings,paste(readLines(path,encoding="UTF-8"),collapse="\n"))
  overlap_status <- "not_run"
  if(!is.null(private_candidates)) {
    public_ngrams <- barometar_public_ngrams(strings)
    con <- DBI::dbConnect(duckdb::duckdb());on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE)
    for(path in private_candidates) {
      cursor <- DBI::dbSendQuery(con,paste0("SELECT TITLE,FULL_TEXT FROM read_parquet(",DBI::dbQuoteString(con,path),")"))
      repeat {
        rows <- DBI::dbFetch(cursor,n=1000L);if(!nrow(rows))break
        if(length(barometar_text_overlap(strings,c(rows$TITLE,rows$FULL_TEXT),public_ngrams=public_ngrams)))stop("Eight-token overlap with restricted source text; public wording needs review.")
      }
      DBI::dbClearResult(cursor)
    }
    overlap_status <- "passed"
  }
  result <- list(status="passed",synthetic=isTRUE(release$summary$synthetic),overlap=overlap_status,
    manifest_sha256=digikat_hash_file(file.path(directory,"manifest.json")),
    definition_version=release$summary$definition_version,
    checker_sha256=digikat_hash_file("studies/demokrscanstvo-barometar/11_checks.R"))
  barometar_write_json(result,file.path(directory,"checks.json"))
  invisible(result)
}

barometar_apply_release <- function(directory) {
  gates <- jsonlite::fromJSON("studies/demokrscanstvo-barometar/config/gates.json",simplifyVector=FALSE)
  if(!identical(gates$G3_validation$status,"approved") || !isTRUE(gates$G4_first_apply$vendor_licence_confirmed))stop("Public installation requires human validation and documented vendor aggregate-licence confirmation.")
  if(!"A1" %in% gates$G3_validation$accepted_routes)stop("No empirical installation without accepted A1.")
  release <- barometar_read_release(directory,FALSE)
  if(!identical(release$summary$definition_version,gates$G3_validation$definition_version)||
    !identical(release$summary$validation_result_sha256,gates$G3_validation$validation_result_sha256))stop("Release does not match the accepted human evidence.")
  workdir <- barometar_workdir()
  preview <- readRDS(file.path(workdir,"release_manifest.rds"))
  if(!identical(normalizePath(directory,winslash="/"),normalizePath(preview$directory,winslash="/"))||is.null(preview$source_snapshot))stop("This is not the current empirical preview.")
  if(!identical(preview$code_hashes,barometar_release_code_hashes())||
    !identical(release$summary$definition_version,barometar_definition()$definition_version)||
    !identical(gates$G3_validation$panel_hash,barometar_require_panel()$panel_hash[1L]))stop("Preview method/code changed before installation; rebuild the checked release.")
  source_con <- barometar_connect_readonly();on.exit(DBI::dbDisconnect(source_con,shutdown=TRUE),add=TRUE)
  barometar_assert_snapshot(preview$source_snapshot,source_con)
  candidates <- readRDS(file.path(barometar_workdir(),"candidate_manifest.rds"))
  check <- barometar_release_checks(directory,FALSE,candidates$paths,
    c("pages/demokrscanstvo/index.qmd","studies/demokrscanstvo-barometar/typeset/conference.typ"))
  if(!identical(check$overlap,"passed"))stop("Restricted-text overlap gate is incomplete.")
  target <- "data/barometar/demokrscanstvo"
  dir.create(dirname(target),recursive=TRUE,showWarnings=FALSE)
  staged <- tempfile("demokrscanstvo-stage-",tmpdir=dirname(target));dir.create(staged)
  for(name in list.files(directory,recursive=TRUE)) {
    dir.create(dirname(file.path(staged,name)),recursive=TRUE,showWarnings=FALSE)
    if(!file.copy(file.path(directory,name),file.path(staged,name)))stop("Release staging failed.")
  }
  barometar_read_release(staged,FALSE)
  old <- if(dir.exists(target))barometar_read_release(target,FALSE)$summary else NULL
  if(!is.null(old)) {
    if(identical(old$release_version,release$summary$release_version))stop("This release is already installed.")
    history <- utils::read.csv(file.path(staged,"releases.csv"),fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE)
    if(!old$release_version %in% history$release_version)stop("Replacement omits installed release history.")
    for(name in list.files(file.path(target,"izdanja"),recursive=TRUE))
      if(!identical(digikat_hash_file(file.path(target,"izdanja",name)),digikat_hash_file(file.path(staged,"izdanja",name))))stop("Replacement changes a frozen edition.")
  }
  backup_root <- "studies/demokrscanstvo-barometar/output/intermediate/release-backups"
  dir.create(backup_root,recursive=TRUE,showWarnings=FALSE)
  sidecar_folder <- tempfile("sidecars-",tmpdir=backup_root);dir.create(sidecar_folder)
  installed_path <- file.path(workdir,"installed_release.rds")
  installed_staged <- file.path(sidecar_folder,"installed_release.rds")
  saveRDS(list(source_snapshot=preview$source_snapshot,data_through=release$summary$data_through,
    code_hashes=barometar_release_code_hashes(),release_version=release$summary$release_version,
    manifest_sha256=digikat_hash_file(file.path(staged,"manifest.json"))),installed_staged)
  metadata_path <- "pages/demokrscanstvo/_metadata.yml"
  metadata <- yaml::read_yaml(metadata_path);metadata$`data-cutoff` <- release$summary$data_through
  metadata_staged <- file.path(sidecar_folder,"_metadata.yml")
  connection <- file(metadata_staged,"wb");writeBin(charToRaw(enc2utf8(yaml::as.yaml(metadata))),connection);close(connection)
  gates$G4_first_apply$status <- "approved"
  gates$G4_first_apply$release_version <- release$summary$release_version
  gates$G4_first_apply$manifest_sha256 <- digikat_hash_file(file.path(staged,"manifest.json"))
  gates_path <- "studies/demokrscanstvo-barometar/config/gates.json"
  gates_staged <- file.path(sidecar_folder,"gates.json");barometar_write_json(gates,gates_staged)
  source("R/lib/barometar_install.R",local=environment(),encoding="UTF-8")
  barometar_install_generation(staged,target,setNames(c(installed_staged,metadata_staged,gates_staged),
    c(installed_path,metadata_path,gates_path)),backup_root)
  invisible(target)
}
if(barometar_script_main("11_checks.R")) {
  args <- commandArgs(trailingOnly=TRUE)
  if(length(args)!=1L)stop("Pass the release directory.")
  barometar_release_checks(args)
}
