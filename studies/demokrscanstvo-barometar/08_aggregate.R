# An explicit release build, never a page-render side effect.
source("studies/demokrscanstvo-barometar/06_validation_score.R",encoding="UTF-8")
source("R/lib/barometar_release.R",encoding="UTF-8")
source("R/lib/barometar_history.R",encoding="UTF-8")
source("R/lib/barometar_page.R",encoding="UTF-8")

barometar_write_release <- function(tables,summary,definition,validation,bridge,directory,previous_directory=NULL,new_edition=FALSE) {
  dir.create(directory,recursive=TRUE,showWarnings=FALSE)
  for(name in names(tables))barometar_write_csv(tables[[name]],file.path(directory,paste0(name,".csv")))
  for(frequency in c("monthly","weekly"))for(scope in unique(tables[[frequency]]$scope))
    barometar_write_csv(tables[[frequency]][tables[[frequency]]$scope==scope,,drop=FALSE],file.path(directory,paste0(frequency,"_",scope,".csv")))
  barometar_write_csv(validation$validation,file.path(directory,"validation.csv"))
  for(name in c("per_batch","theme_precision","miss_diagnostics","route_set_precision"))
    if(is.data.frame(validation[[name]]) && ncol(validation[[name]]))barometar_write_csv(validation[[name]],file.path(directory,paste0("validation_",name,".csv")))
  barometar_write_json(list(human_validation_complete=isTRUE(validation$human_validation_complete),
    broad_precision=validation$broad_precision,qualifies_agreement=validation$agreement,construct_agreement=validation$construct_agreement,
    double_coded_items=validation$second_coder_n,masked_evidence_losses=validation$masked_evidence_losses,
    release_scope=validation$release_scope,accepted_routes=validation$accepted_routes),file.path(directory,"validation_summary.json"))
  barometar_write_csv(bridge,file.path(directory,"bridge_summary.csv"))
  # Public inventory has no article fields, paths or vendor/source URLs.
  inventory <- list(definition_version=definition$definition_version,definition_hash=definition$definition_hash,
    max_tokens=80L,text_cap=definition$text_cap,
    entries=lapply(definition$compiled,function(rule)rule$entry[intersect(names(rule$entry),
      c("id","family","tier","kind","forms","slots","order","ascii_variants","exclude_if","excluded_forms","case_sensitive","gap_max","principle"))]),
    rules=definition$documents[["rules.yaml"]])
  if(length(barometar_public_inspect(inventory,"definitions")$issues))stop("Public definition inventory failed disclosure screening.")
  barometar_write_json(inventory,file.path(directory,"definitions_v1.json"))
  # Findings stay empty until an edition has defensible, human-validated claims.
  summary <- barometar_prepare_history(tables,summary,directory,previous_directory,new_edition)
  barometar_write_json(summary,file.path(directory,"summary.json"))
  readme <- c("# Medijski barometar demokršćanstva",
    if(isTRUE(summary$synthetic))"SINTETIČKI PODACI. Svi članci i mediji u ovom paketu su izmišljeni." else "Izvedeni skupni pokazatelji nakon zasebne ljudske provjere.",
    "", "Zastupljenost: broj uključenih članaka na 10.000 prihvatljivih članaka. Širina: postotak medija stalnog panela s uključenim člankom.",
    "Nula označava opaženu odsutnost; prazna numerička vrijednost znači da pokazatelj nije dostupan. partial označava djelomično razdoblje, published dostupno razdoblje, unavailable nedostupnost.",
    "Mjesečna i tjedna razdoblja računaju se iz dana, a rolling28 koristi 28 uzastopnih kalendarskih dana. Dostupnost zastupljenosti i širine provjerava se zasebno.",
    "A1 označava imenovanje tradicije; B primjenu socijalnog nauka; C kršćanski utemeljen politički argument. A2 i A? su odvojena dijagnostika, izvan pokazatelja.",
    "Teme mogu biti višestruke. Kompozicija navodi točne kombinacije putova; načela su višestruke oznake. Ne zbrajaju se u jedinstven indeks.",
    "Analize bez skupine medija mijenjaju N, D i panel. Analize bez crkvenog govornika ili jedinoga registriranog aktera HDZ-a filtriraju samo brojnik, uz zajednički nazivnik i panel.",
    "hdz_only ovisi o ograničenom registru naziva i uloga; ne dokazuje odsutnost drugih političara. Provjera propuštenih formulacija nije procjena odziva cijelog panela.",
    "Wilson_Kish označava približan Wilsonov interval s efektivnom veličinom uzorka uz težine. Sintetički paket nema ljudsku preciznost ni ljudsko slaganje.",
    "Izvorni članci, njihovi naslovi, poveznice i brojnici pojedinih medija nisu dio ovoga paketa.",
    paste("Definicija:",summary$definition_version,"Panel:",summary$panel_version,"Izdanje:",summary$release_version),
    paste("Podaci do:",summary$data_through,"Politika prekida:",summary$break_policy),
    "Citiranje: Šikić, L. (2026). Medijski barometar demokršćanstva. DigiKat, Hrvatsko katoličko sveučilište.",
    if(isTRUE(summary$synthetic))"Razvojni primjer, bez empirijskog izdanja." else "CC BY 4.0; licencijska potvrda izvora prethodi javnoj instalaciji.")
  con <- file(file.path(directory,"README.md"),"wb");writeBin(charToRaw(enc2utf8(paste0(paste(readme,collapse="\n"),"\n"))),con);close(con)
  barometar_finalize_manifest(directory,summary)
  invisible(directory)
}

barometar_finalize_manifest <- function(directory,summary) {
  files <- sort(setdiff(list.files(directory,recursive=TRUE),c("manifest.json","checks.json")))
  manifest <- list(data_through=summary$data_through,synthetic=isTRUE(summary$synthetic),
    definition_version=summary$definition_version,panel_version=summary$panel_version,release_version=summary$release_version,
    files=as.list(setNames(vapply(file.path(directory,files),digikat_hash_file,character(1L)),files)))
  barometar_write_json(manifest,file.path(directory,"manifest.json"))
  invisible(manifest)
}

barometar_reserve_preview <- function(previous=NULL,date=Sys.Date(),directory="studies/demokrscanstvo-barometar/output/release") {
  if(length(date)!=1L || is.na(as.Date(date)))stop("A preview needs one valid release date.")
  base <- format(as.Date(date),"%Y.%m.%d")
  pattern <- paste0("^",stringi::stri_replace_all_fixed(base,".","[.]"),"(-[0-9]+)?$")
  dir.create(directory,recursive=TRUE,showWarnings=FALSE)
  repeat {
    used <- c(previous,list.files(directory,all.files=TRUE))
    used <- used[!is.na(used) & stringi::stri_detect_regex(used,pattern)]
    ordinals <- vapply(used,function(value)if(identical(value,base))1 else as.numeric(stringi::stri_replace_first_regex(value,"^.*-","")),numeric(1L))
    next_id <- max(c(0,ordinals))+1
    if(!is.finite(next_id)||next_id>.Machine$integer.max)stop("Preview revision suffix exceeds the supported range.")
    version <- if(next_id==1)base else paste0(base,"-",as.integer(next_id))
    target <- file.path(directory,version)
    if(dir.create(target,showWarnings=FALSE))return(list(release_version=version,directory=normalizePath(target,winslash="/")))
    if(!file.exists(target))stop("Could not reserve a fresh release preview directory.")
  }
}

barometar_aggregate_release <- function(new_edition=FALSE) {
  workdir <- barometar_workdir();definition <- barometar_definition();panel <- barometar_require_panel()
  gates <- jsonlite::fromJSON("studies/demokrscanstvo-barometar/config/gates.json",simplifyVector=FALSE)
  if(!identical(gates$G2_definition$definition_version,definition$definition_version) ||
    !identical(gates$G3_validation$status,"approved"))stop("Aggregate release requires the frozen definition and accepted human validation.")
  folder <- file.path(workdir,"validation",definition$definition_version)
  draw <- readRDS(file.path(folder,"draw.rds"));barometar_check_coding_package(folder,draw)
  validation <- readRDS(file.path(folder,"validation-result.rds"))
  if(!isTRUE(validation$human_validation_complete) || !identical(validation$draw_id,draw$draw_id) || validation$release_scope=="none")stop("No human-validated release scope.")
  classification <- readRDS(file.path(workdir,"classification_manifest.rds"))
  if(!identical(classification$panel_hash,panel$panel_hash[1L])||
    !identical(draw$input_identity$panel_hash,panel$panel_hash[1L]))stop("Evaluation/classification and frozen panel differ.")
  current_engine <- digikat_hash_object(lapply(c("R/lib/barometar_engine.R","R/lib/barometar_text.R","R/lib/barometar_rules.R"),digikat_hash_file))
  if(!identical(classification$engine_hash,current_engine) || !identical(classification$definition_version,definition$definition_version))stop("Classification code differs from the frozen current definition.")
  if(!identical(gates$G3_validation$validation_result_sha256,digikat_hash_file(file.path(folder,"validation-result.rds")))||
    !identical(gates$G3_validation$engine_hash,classification$engine_hash)||
    !identical(gates$G3_validation$classifier_body_hash,digikat_hash_object(body(barometar_classify_month)))||
    !identical(gates$G3_validation$panel_hash,classification$panel_hash)||
    !identical(gates$G3_validation$validation_code_sha256,digikat_hash_file("R/lib/barometar_validation.R")))stop("Current classification lacks its frozen human-validation certificate.")
  bridge <- readRDS(file.path(workdir,"bridge_manifest.rds"))
  if(!isTRUE(bridge$validated) || !identical(bridge$validation_result_hash,digikat_hash_file(file.path(folder,"validation-result.rds"))))stop("Bridge certification is stale.")
  if(!identical(bridge$identity$definition,definition$definition_hash) || !identical(bridge$identity$panel,panel$panel_hash[1L]) ||
    !identical(bridge$identity$registry,digikat_hash_file("studies/demokrscanstvo-barometar/config/outlet_registry.csv")) ||
    !identical(bridge$identity$code,vapply(names(bridge$identity$code),digikat_hash_file,character(1L))))stop("Bridge method dependencies changed.")
  for(batch in c("old","new")) {
    check <- barometar_connect_readonly(if(batch=="old")digikat_determdb_old_path() else digikat_determdb_path())
    tryCatch(barometar_assert_snapshot(bridge$source_fingerprints[[batch]]$snapshot,check),finally=DBI::dbDisconnect(check,shutdown=TRUE))
  }
  readiness <- readRDS(file.path(workdir,"readiness.rds"));proposal <- readRDS(file.path(workdir,"panel_proposal.rds"))
  candidates <- readRDS(file.path(workdir,"candidate_manifest.rds"))
  if(!identical(bridge$source_fingerprints$new$snapshot,readiness$snapshot))stop("Bridge and denominator use different source snapshots.")
  if(!identical(candidates$population_identity,barometar_population_identity(workdir,readiness)) ||
    !identical(candidates$retrieval_hash,classification$retrieval_hash) ||
    !identical(classification$input_digest,readiness$input_digest))stop("Current denominator differs from the evaluated classification population.")
  original <- barometar_connect_readonly()
  on.exit(DBI::dbDisconnect(original,shutdown=TRUE),add=TRUE)
  barometar_assert_snapshot(readiness$snapshot,original)
  con <- DBI::dbConnect(duckdb::duckdb(),dbdir=proposal$private_db,read_only=TRUE)
  on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE)
  ids <- paste(DBI::dbQuoteString(con,panel$outlet_id),collapse=",")
  denominator <- DBI::dbGetQuery(con,paste0("SELECT day,outlet_id,COUNT(*) AS N FROM representatives WHERE outlet_id IN (",ids,") GROUP BY 1,2 ORDER BY 1,2"))
  denominator$N <- as.numeric(denominator$N)
  decisions <- as.data.frame(data.table::rbindlist(lapply(classification$paths,function(path)readRDS(path)$decisions),fill=TRUE))
  registry <- utils::read.csv("studies/demokrscanstvo-barometar/config/outlet_registry.csv",fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE)
  panel$outlet_domain <- vapply(stringi::stri_split_fixed(registry$url_hosts[match(panel$outlet_id,registry$outlet_id)],";"),`[`,character(1L),1L)
  previous_directory <- "data/barometar/demokrscanstvo"
  previous <- if(dir.exists(previous_directory))barometar_read_release(previous_directory,FALSE)$summary else NULL
  if(is.null(previous))previous_directory <- NULL
  reserved <- barometar_reserve_preview(if(is.null(previous))NULL else previous$release_version)
  versions <- list(panel_version=unique(panel$panel_version),definition_version=definition$definition_version,
    release_version=reserved$release_version)
  available <- c(if(isTRUE(validation$broad_publishable))"siri",if(isTRUE(validation$narrow_publishable))"uze")
  tables <- barometar_build_tables(denominator,decisions,readiness$days,panel,versions,validation$accepted_routes,available,
    validation$theme_precision,bridge$break_policy,definition$documents[["domain_themes.yaml"]]$labels)
  summary <- barometar_release_summary(tables,versions,readiness$days,panel,validation,FALSE,bridge$break_policy)
  summary$input_digest <- readiness$input_digest
  summary$validation_input_digest <- draw$input_identity$input_digest
  summary$validation_draw_id <- draw$draw_id
  summary$validation_result_sha256 <- digikat_hash_file(file.path(folder,"validation-result.rds"))
  summary$code_commit <- unname(system2("git",c("rev-parse","HEAD"),stdout=TRUE))
  target <- reserved$directory
  barometar_write_release(tables,summary,definition,validation,bridge$summary,target,previous_directory,new_edition)
  barometar_write_csv(bridge$contributions,file.path(target,"bridge_contributions.csv"))
  barometar_finalize_manifest(target,summary)
  barometar_assert_snapshot(readiness$snapshot,original)
  saveRDS(list(directory=normalizePath(target,winslash="/"),classification_hash=classification$classification_hash,
    validation_hash=digikat_hash_file(file.path(folder,"validation-result.rds")),source_snapshot=readiness$snapshot,
    bridge_hash=digikat_hash_file(file.path(workdir,"bridge_manifest.rds")),
    code_hashes=barometar_release_code_hashes()),file.path(workdir,"release_manifest.rds"))
  message("Release preview created; disclosure/overlap, figures and licence checks still precede installation.")
  invisible(target)
}
if(barometar_script_main("08_aggregate.R"))barometar_aggregate_release()
