source("studies/demokrscanstvo-barometar/02_panel.R",encoding="UTF-8")

barometar_freeze_panel <- function() {
  workdir <- barometar_workdir()
  proposal <- readRDS(file.path(workdir,"panel_proposal.rds"))
  readiness <- readRDS(file.path(workdir,"readiness.rds"))
  review <- proposal$review
  # Missing labels cannot be silently interpreted as a non-news exclusion.
  eligible <- review$continuity_eligible
  unknown <- eligible & (is.na(review$editorial) | (as.character(review$editorial)=="TRUE" & is.na(review$croatia_link)))
  if(any(unknown))stop("Eligible outlet identities still unresolved: ",paste(review$outlet_id[unknown],collapse=", "),call.=FALSE)
  if(!isTRUE(proposal$audit$old_i_threshold_pass))stop("The standalone-i diagnostic exceeds the frozen threshold; review its measured effect before freeze.")
  con <- barometar_connect_readonly(); on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE)
  barometar_assert_snapshot(readiness$snapshot,con)
  panel <- proposal$panel
  if(!nrow(panel))stop("No qualifying panel.")
  registry_path <- "studies/demokrscanstvo-barometar/config/outlet_registry.csv"
  if(!all(panel$registry_hash==digikat_hash_file(registry_path)))stop("Registry changed after panel computation; rebuild proposal.")
  panel$panel_version <- "panel_v1"; panel$status <- "approved_recommended"
  barometar_write_csv(panel,"studies/demokrscanstvo-barometar/config/panel_v1.csv")
  mask <- readiness$masked_days
  mask$mask_version <- paste0("mask_v1+",substr(digikat_hash_object(mask[c("day","reason")]),1L,12L))
  barometar_write_csv(mask,"studies/demokrscanstvo-barometar/config/masked_days.csv")
  path <- "studies/demokrscanstvo-barometar/config/gates.json"
  gates <- jsonlite::fromJSON(path,simplifyVector=FALSE)
  gates$G1_panel <- list(status="approved",date="2026-09-18",panel_hash=panel$panel_hash[1L],input_digest=readiness$input_digest,
    authority="PI instruction: all necessary and awaiting decisions may be executed as recommended",
    evidence="quality_reports/2026-09-18_barometar-outlet-review.md",panel_size=nrow(panel))
  barometar_write_json(gates,path)
  message("G1 panel frozen under delegated PI authority: ",nrow(panel)," outlets; no topic counts used.")
  invisible(panel)
}

if(barometar_script_main("freeze_panel.R"))barometar_freeze_panel()
