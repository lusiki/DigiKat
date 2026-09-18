# Manual refresh. Upstream vendor loading remains a separate PI-run operation.
source("studies/demokrscanstvo-barometar/11_checks.R",encoding="UTF-8")
source("studies/demokrscanstvo-barometar/09_figures.R",encoding="UTF-8")
source("studies/demokrscanstvo-barometar/07_bridge.R",encoding="UTF-8")
source("studies/demokrscanstvo-barometar/00_readiness.R",encoding="UTF-8")
source("studies/demokrscanstvo-barometar/01_outlets.R",encoding="UTF-8")

barometar_same_source <- function(a,b)identical(a[c("file_bytes","file_mtime","logs_digest")],b[c("file_bytes","file_mtime","logs_digest")])

barometar_update <- function(workers=8L,new_edition=FALSE) {
  workdir <- barometar_workdir();panel <- barometar_require_panel()
  gates <- jsonlite::fromJSON("studies/demokrscanstvo-barometar/config/gates.json",simplifyVector=FALSE)
  if(!identical(gates$G3_validation$status,"approved"))stop("Empirical refresh awaits accepted actual human coding, adjudication and the validated bridge (G3).")
  if(!"A1" %in% gates$G3_validation$accepted_routes)stop("No empirical refresh without accepted A1.")
  definition <- barometar_definition()
  validation_path <- file.path(workdir,"validation",definition$definition_version,"validation-result.rds")
  validation_hash <- digikat_hash_file(validation_path)
  validation <- barometar_apply_release_policy(readRDS(validation_path))
  if(identical(validation$release_scope,"none"))stop("No empirical refresh without the current accepted A1 result.")
  current_engine <- digikat_hash_object(lapply(c("R/lib/barometar_engine.R","R/lib/barometar_text.R","R/lib/barometar_rules.R"),digikat_hash_file))
  if(!identical(gates$G2_definition$status,"approved")||
    !identical(gates$G2_definition$definition_version,definition$definition_version)||
    !identical(gates$G3_validation$definition_version,definition$definition_version)||
    !identical(gates$G3_validation$panel_hash,panel$panel_hash[1L])||
    !identical(gates$G3_validation$engine_hash,current_engine)||
    !identical(gates$G3_validation$classifier_body_hash,digikat_hash_object(body(barometar_classify_month)))||
    !identical(gates$G3_validation$validation_result_sha256,validation_hash)||
    !identical(gates$G3_validation$validation_code_sha256,digikat_hash_file("R/lib/barometar_validation.R")) ||
    !identical(gates$G3_validation$release_policy_code_sha256,digikat_hash_file("studies/demokrscanstvo-barometar/06_validation_score.R")))stop("Refresh instrument differs from the accepted human-validation certificate.")
  code_hashes <- barometar_release_code_hashes()
  con <- barometar_connect_readonly()
  probe <- tryCatch(list(snapshot=barometar_source_snapshot(con),data_through=DBI::dbGetQuery(con,
    paste0('SELECT MAX("DATE") AS cutoff FROM ',barometar_table_sql(con)," WHERE SOURCE_TYPE='web'"))$cutoff[[1L]]),
    finally=DBI::dbDisconnect(con,shutdown=TRUE))
  installed_path <- file.path(workdir,"installed_release.rds")
  if(file.exists(installed_path)&&!new_edition) {
    installed <- readRDS(installed_path)
    if(barometar_same_source(installed$source_snapshot,probe$snapshot)&&identical(installed$data_through,probe$data_through)&&
      identical(installed$code_hashes,code_hashes)) {
      current <- barometar_read_release("data/barometar/demokrscanstvo",FALSE)$summary
      bridge_path <- file.path(workdir,"bridge_manifest.rds")
      bridge_current <- FALSE
      if(file.exists(bridge_path)) {
        previous_bridge <- readRDS(bridge_path)
        old_con <- barometar_connect_readonly(digikat_determdb_old_path())
        old_snapshot <- tryCatch(barometar_source_snapshot(old_con),finally=DBI::dbDisconnect(old_con,shutdown=TRUE))
        bridge_current <- isTRUE(previous_bridge$validated) &&
          identical(previous_bridge$validation_result_hash,validation_hash) &&
          identical(previous_bridge$identity$definition,definition$definition_hash) &&
          identical(previous_bridge$identity$panel,panel$panel_hash[1L]) &&
          identical(previous_bridge$identity$registry,digikat_hash_file("studies/demokrscanstvo-barometar/config/outlet_registry.csv")) &&
          identical(previous_bridge$identity$code,vapply(names(previous_bridge$identity$code),digikat_hash_file,character(1L))) &&
          barometar_same_source(previous_bridge$source_fingerprints$old$snapshot,old_snapshot) &&
          barometar_same_source(previous_bridge$source_fingerprints$new$snapshot,probe$snapshot)
      }
      if(identical(installed$release_version,current$release_version) &&
        identical(installed$manifest_sha256,digikat_hash_file("data/barometar/demokrscanstvo/manifest.json")) &&
        identical(current$validation_result_sha256,validation_hash) && bridge_current) {
        message("nema novih podataka")
        return(invisible(NULL))
      }
    }
  }
  readiness_path <- file.path(workdir,"readiness.rds")
  if(!file.exists(readiness_path)||!barometar_same_source(readRDS(readiness_path)$snapshot,probe$snapshot)) {
    con <- barometar_connect_readonly()
    tryCatch({
      readiness <- barometar_readiness(con,workdir)
      inventory <- barometar_outlet_inventory(con,readiness,workdir)
      registry_path <- "studies/demokrscanstvo-barometar/config/outlet_registry.csv"
      registry <- utils::read.csv(registry_path,fileEncoding="UTF-8-BOM",stringsAsFactors=FALSE)
      if(!all(panel$outlet_id %in% registry$outlet_id))stop("Frozen panel is absent from current registry.")
      values <- barometar_registry_candidate_from_values(inventory,registry)
      metadata <- barometar_eligible_metadata(con,readiness,inventory,workdir,values)
      # This rebuilds denominator representatives, never config/panel_v1.csv.
      barometar_panel_proposal(con,readiness,inventory,registry_path,workdir,metadata)
    },finally=DBI::dbDisconnect(con,shutdown=TRUE))
  }
  barometar_candidates(workdir)
  barometar_boilerplate(workdir)
  barometar_classify_candidates(workdir,development_only=FALSE,workers=workers)
  barometar_run_bridge()
  path <- file.path(workdir,"release_manifest.rds")
  preview <- if(file.exists(path))readRDS(path) else NULL
  reuse <- !new_edition && !is.null(preview) && !is.null(preview$source_snapshot) &&
    barometar_same_source(preview$source_snapshot,probe$snapshot) && dir.exists(preview$directory) &&
    identical(preview$classification_hash,readRDS(file.path(workdir,"classification_manifest.rds"))$classification_hash)
  reuse <- reuse && identical(preview$code_hashes,code_hashes)
  reuse <- reuse && identical(preview$validation_hash,validation_hash) &&
    identical(preview$bridge_hash,digikat_hash_file(file.path(workdir,"bridge_manifest.rds")))
  if(reuse) {
    completed <- tryCatch(barometar_read_release(preview$directory,FALSE),error=function(e)NULL)
    reuse <- !is.null(completed) && identical(completed$summary$validation_result_sha256,validation_hash)
  }
  directory <- if(reuse)preview$directory else barometar_aggregate_release(new_edition)
  barometar_figures(directory)
  candidates <- readRDS(file.path(workdir,"candidate_manifest.rds"))
  barometar_release_checks(directory,FALSE,candidates$paths,
    c("pages/demokrscanstvo/index.qmd","studies/demokrscanstvo-barometar/typeset/conference.typ"))
  message("Checked preview complete; --apply installs it only after the licence prerequisite.")
  invisible(directory)
}
if(barometar_script_main("12_update.R"))barometar_update()
