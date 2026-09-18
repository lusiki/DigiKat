source("studies/demokrscanstvo-barometar/04_classify.R",encoding="UTF-8")
source("R/lib/barometar_validation.R",encoding="UTF-8")
source("R/lib/barometar_coding.R",encoding="UTF-8")

barometar_prepare_validation <- function() {
  workdir <- barometar_workdir()
  definition <- barometar_definition()
  gates <- jsonlite::fromJSON("studies/demokrscanstvo-barometar/config/gates.json",simplifyVector=FALSE)
  if(!identical(gates$G2_definition$status,"approved") || !identical(gates$G2_definition$definition_version,definition$definition_version))stop("Fresh evaluation draw requires the tested definition freeze.")
  manifest <- readRDS(file.path(workdir,"classification_manifest.rds"))
  if(isTRUE(manifest$development_only) || !identical(manifest$definition_version,definition$definition_version))stop("Evaluation needs frozen full-history classifications.")
  population <- as.data.frame(data.table::rbindlist(lapply(manifest$paths,function(path)readRDS(path)$decisions),fill=TRUE))
  population$item_id <- population$doc_key
  candidates <- readRDS(file.path(workdir,"candidate_manifest.rds"))
  if(!identical(manifest$input_digest,candidates$input_digest) || !identical(manifest$panel_hash,candidates$panel_hash))stop("Classification/candidate identity mismatch.")
  exclusion_paths <- c(file.path(workdir,"agent_reads.csv"),file.path("studies/demokrscanstvo-barometar/output/private","agent_reads.csv"),
    file.path(workdir,"segmentation","evaluation_exclusions.csv"),
    list.files(file.path(workdir,"development"),pattern="^agent_reads.*[.]csv$",full.names=TRUE,recursive=TRUE))
  exclusions <- character();exclusion_hashes <- list()
  for(path in exclusion_paths[file.exists(exclusion_paths)]) {
    log <- utils::read.csv(path,fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE)
    key <- intersect(c("doc_key","item_id"),names(log))
    if(!length(key) || anyNA(log[[key[1L]]]))stop("Invalid evaluation exclusion log.")
    exclusions <- union(exclusions,log[[key[1L]]])
    exclusion_hashes[[normalizePath(path,winslash="/",mustWork=TRUE)]] <- digikat_hash_file(path)
  }
  population <- population[!population$item_id %in% exclusions,,drop=FALSE]
  draw <- barometar_validation_draw(population)
  draw$exclusion_hashes <- exclusion_hashes
  draw$definition_version <- definition$definition_version
  boilerplate <- readRDS(file.path(workdir,"boilerplate.rds"))
  current_engine <- digikat_hash_object(lapply(c("R/lib/barometar_engine.R","R/lib/barometar_text.R","R/lib/barometar_rules.R"),digikat_hash_file))
  if(!identical(manifest$engine_hash,current_engine) || !identical(manifest$boilerplate_version,attr(boilerplate,"boilerplate_version")) ||
     !identical(manifest$retrieval_hash,candidates$retrieval_hash))stop("Classification engine, mask or retrieval changed before draw.")
  draw$input_identity <- list(classification_hash=manifest$classification_hash,input_digest=manifest$input_digest,
    classifier_body_hash=digikat_hash_object(body(barometar_classify_month)),
    panel_hash=manifest$panel_hash,boilerplate_version=attr(boilerplate,"boilerplate_version"),
    code_hashes=setNames(vapply(c("R/lib/barometar_validation.R","R/lib/barometar_coding.R",
      "studies/demokrscanstvo-barometar/coder_template.html"),digikat_hash_file,character(1L)),c("sampling","context","template")))
  draw$draw_id <- barometar_draw_identity(draw)
  parent <- file.path(workdir,"validation");dir.create(parent,recursive=TRUE,showWarnings=FALSE)
  final_folder <- file.path(parent,definition$definition_version)
  if(dir.exists(final_folder))stop("A coding package already exists for this definition; do not replace human work.")
  folder <- tempfile(paste0(definition$definition_version,"-pending-"),tmpdir=parent)
  dir.create(folder)
  barometar_write_csv(draw$membership,file.path(folder,"draw_membership_private.csv"))
  con <- DBI::dbConnect(duckdb::duckdb());on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE)
  paths <- paste(DBI::dbQuoteString(con,candidates$paths),collapse=",")
  ids <- paste(DBI::dbQuoteString(con,draw$assignments$item_id),collapse=",")
  raw <- DBI::dbGetQuery(con,paste0("SELECT * FROM read_parquet([",paths,"]) WHERE doc_key IN (",ids,") ORDER BY doc_key"))
  stopifnot(!anyDuplicated(raw$doc_key),setequal(raw$doc_key,draw$assignments$item_id))
  raw <- raw[match(draw$assignments$item_id,raw$doc_key),]
  registry <- utils::read.csv("studies/demokrscanstvo-barometar/config/outlet_registry.csv",fileEncoding="UTF-8-BOM")
  material <- lapply(seq_len(nrow(raw)),function(i) {
    keys <- boilerplate$segment_key[boilerplate$outlet_id==raw$outlet_id[i] & boilerplate$month==substr(raw$day[i],1L,7L)]
    context <- barometar_coding_context(raw$TITLE[i],raw$FULL_TEXT[i],definition,keys)
    c(list(item_id=raw$doc_key[i],day=raw$day[i],outlet=registry$display_name[match(raw$outlet_id[i],registry$outlet_id)]),context)
  })
  template <- paste(readLines("studies/demokrscanstvo-barometar/coder_template.html",encoding="UTF-8"),collapse="\n")
  for(role in c("human_PI","human_second")) {
    keep <- if(role=="human_PI")rep(TRUE,length(material)) else draw$assignments$double_code
    payload <- jsonlite::toJSON(list(coder_type=role,definition_version=definition$definition_version,draw_id=draw$draw_id,items=material[keep]),auto_unbox=TRUE,null="null",na="null")
    payload <- stringi::stri_replace_all_fixed(payload,"<","\\u003c")
    html <- stringi::stri_replace_first_fixed(template,"__CODING_PAYLOAD__",payload)
    connection <- file(file.path(folder,paste0(role,".html")),open="wb")
    writeBin(charToRaw(enc2utf8(html)),connection);close(connection)
  }
  saveRDS(draw,file.path(folder,"draw.rds"))
  package_files <- c("draw.rds","draw_membership_private.csv","human_PI.html","human_second.html")
  barometar_write_json(list(draw_id=draw$draw_id,files=as.list(setNames(vapply(file.path(folder,package_files),digikat_hash_file,character(1L)),package_files))),file.path(folder,"package_manifest.json"))
  if(!file.rename(folder,final_folder))stop("Could not atomically finalize the coding package; pending material remains private.")
  message("Blinded human coding package prepared: ",nrow(draw$assignments)," unique items; ",sum(draw$assignments$double_code)," independently double-coded. No human labels created.")
  invisible(final_folder)
}
