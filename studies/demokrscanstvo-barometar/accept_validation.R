# Execute the already-delegated G3 recommendation from completed human evidence.
source("studies/demokrscanstvo-barometar/08_aggregate.R",encoding="UTF-8")
barometar_accept_validation <- function() {
  workdir <- barometar_workdir();definition <- barometar_definition();panel <- barometar_require_panel()
  path <- "studies/demokrscanstvo-barometar/config/gates.json"
  gates <- jsonlite::fromJSON(path,simplifyVector=FALSE)
  if(!identical(gates$G2_definition$status,"approved")||!identical(gates$G2_definition$definition_version,definition$definition_version))stop("G3 requires the current G2 freeze.")
  folder <- file.path(workdir,"validation",definition$definition_version)
  draw <- readRDS(file.path(folder,"draw.rds"));barometar_check_coding_package(folder,draw)
  result_path <- file.path(folder,"validation-result.rds")
  if(!file.exists(result_path))stop("G3 awaits completed actual human coding and adjudication.")
  result <- barometar_apply_release_policy(readRDS(result_path));classification <- readRDS(file.path(workdir,"classification_manifest.rds"))
  if(!isTRUE(result$human_validation_complete)||!identical(result$draw_id,draw$draw_id)||
    !setequal(names(result$input_hashes),c("pi","second","adjudicated","log"))||
    !identical(draw$input_identity$panel_hash,panel$panel_hash[1L])||
    !identical(classification$panel_hash,panel$panel_hash[1L])||
    !identical(draw$input_identity$classification_hash,classification$classification_hash)||
    !identical(draw$input_identity$classifier_body_hash,digikat_hash_object(body(barometar_classify_month))))stop("G3 human evidence identity is incomplete or stale.")
  bridge <- readRDS(file.path(workdir,"bridge_manifest.rds"))
  if(!isTRUE(bridge$validated)||!identical(bridge$validation_result_hash,digikat_hash_file(result_path))||
    !identical(bridge$identity$definition,definition$definition_hash)||!identical(bridge$identity$panel,panel$panel_hash[1L]))stop("Re-run the bridge with the completed human result before G3.")
  if(!identical(bridge$identity$code,vapply(names(bridge$identity$code),digikat_hash_file,character(1L))))stop("Bridge code changed after certification.")
  for(batch in c("old","new")) {
    con <- barometar_connect_readonly(if(batch=="old")digikat_determdb_old_path() else digikat_determdb_path())
    tryCatch(barometar_assert_snapshot(bridge$source_fingerprints[[batch]]$snapshot,con),finally=DBI::dbDisconnect(con,shutdown=TRUE))
  }
  gates$G3_validation <- list(status=if(result$release_scope=="none")"rejected" else "approved",date=as.character(Sys.Date()),
    authority="Delegated recommended decision, based on actual human coding and adjudication",definition_version=definition$definition_version,
    panel_hash=panel$panel_hash[1L],engine_hash=classification$engine_hash,classifier_body_hash=draw$input_identity$classifier_body_hash,
    accepted_routes=result$accepted_routes,release_scope=result$release_scope,
    break_policy=bridge$break_policy,draw_id=draw$draw_id,validation_result_sha256=digikat_hash_file(result_path),
    validation_input_digest=draw$input_identity$input_digest,bridge_sha256=digikat_hash_file(file.path(workdir,"bridge_manifest.rds")),
    validation_code_sha256=digikat_hash_file("R/lib/barometar_validation.R"),
    release_policy_code_sha256=digikat_hash_file("studies/demokrscanstvo-barometar/06_validation_score.R"),
    release_policy=if(is.null(result$release_policy))"accepted_A1" else result$release_policy)
  barometar_write_json(gates,path)
  message("G3 evidence recorded: ",gates$G3_validation$status,"; route scope ",result$release_scope,"; ",bridge$break_policy,".")
  invisible(gates$G3_validation)
}
if(barometar_script_main("accept_validation.R"))barometar_accept_validation()
