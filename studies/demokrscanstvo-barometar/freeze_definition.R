# Execute the PI's delegated recommended G2 decision only after actual checks.
source("studies/demokrscanstvo-barometar/04_classify.R",encoding="UTF-8")
barometar_freeze_definition <- function() {
  workdir <- barometar_workdir();definition <- barometar_definition();panel <- barometar_require_panel()
  gates_path <- "studies/demokrscanstvo-barometar/config/gates.json"
  gates <- jsonlite::fromJSON(gates_path,simplifyVector=FALSE)
  if(identical(gates$G2_definition$status,"approved")) {
    if(!identical(gates$G2_definition$definition_version,definition$definition_version))stop("A frozen definition changed; a new version and evaluation are required.")
    return(invisible(gates$G2_definition))
  }
  readiness <- readRDS(file.path(workdir,"readiness.rds"))
  candidates <- readRDS(file.path(workdir,"candidate_manifest.rds"))
  boilerplate <- readRDS(file.path(workdir,"boilerplate.rds"))
  if(!identical(candidates$population_identity,barometar_population_identity(workdir,readiness)) ||
    !identical(attr(boilerplate,"identity")$population,candidates$population_identity) ||
    !identical(attr(boilerplate,"identity")$key_contract,"transport_then_title_stripped_i_dot_sigma_digit_space_v3"))stop("Retrieval/mask prerequisites are stale.")
  prefilter <- readRDS(file.path(workdir,"prefilter_gate.rds"))
  segmenter <- jsonlite::fromJSON(file.path(workdir,"segmentation","report.json"),simplifyVector=FALSE)
  development <- readRDS(file.path(workdir,"development_review_manifest.rds"))
  review <- readRDS(file.path(development$folder,"review-private.rds"))
  acceptance <- jsonlite::fromJSON(file.path(workdir,"development-acceptance.json"),simplifyVector=FALSE)
  versions <- c(prefilter$definition_version,segmenter$definition_version,development$definition_version,acceptance$definition_version)
  if(!all(versions==definition$definition_version) || !isTRUE(prefilter$pass) || !isTRUE(segmenter$gate_pass) ||
    development$n<150L || !all(review$rows$development) || !identical(acceptance$recommendation,"freeze") ||
    !isTRUE(acceptance$all_changed_cases_reviewed) || acceptance$unresolved_critical_issues!=0L)stop("Current G2 empirical development checks/review are incomplete.")
  if(!identical(review$boilerplate_version,attr(boilerplate,"boilerplate_version")))stop("Development used a different boilerplate mask.")
  for(path in c("tests/barometar_engine_tests.R","tests/barometar_definition_review_tests.R","tests/barometar_near_miss_audit_tests.R")) {
    env <- new.env(parent=globalenv());source(path,local=env,encoding="UTF-8")
    if(endsWith(path,"definition_review_tests.R"))env$run_barometar_definition_review_tests()
  }
  con <- barometar_connect_readonly();on.exit(DBI::dbDisconnect(con,shutdown=TRUE),add=TRUE)
  barometar_assert_snapshot(readiness$snapshot,con)
  sources <- c("tests/fixtures/barometar_cases.csv","tests/barometar_engine_tests.R","tests/barometar_definition_review_tests.R",
    "R/lib/barometar_validation.R","R/lib/barometar_metrics.R","R/lib/barometar_bridge.R",
    "studies/demokrscanstvo-barometar/DEVLOG.md",acceptance$report)
  gates$G2_definition <- list(status="approved",date="2026-09-18",definition_version=definition$definition_version,
    definition_hash=definition$definition_hash,panel_hash=panel$panel_hash[1L],input_digest=readiness$input_digest,
    boilerplate_version=attr(boilerplate,"boilerplate_version"),
    authority="PI authorized execution of recommended pending decisions; empirical prerequisites checked before full classification",
    human_validation_complete=FALSE,development_cases=development$n,
    evidence_sha256=as.list(setNames(vapply(sources,digikat_hash_file,character(1L)),sources)),
    prefilter_gate_sha256=digikat_hash_file(file.path(workdir,"prefilter_gate.rds")),
    segmenter_gate_sha256=digikat_hash_file(file.path(workdir,"segmentation","report.json")),
    assistant_review_sha256=digikat_hash_file(file.path(workdir,"development-acceptance.json")))
  barometar_write_json(gates,gates_path)
  message("G2 frozen: ",definition$definition_version,". Human evaluation has not yet occurred.")
  invisible(gates$G2_definition)
}
if(barometar_script_main("freeze_definition.R"))barometar_freeze_definition()
