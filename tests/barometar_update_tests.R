# Refresh orchestration uses invented metadata/receipts and a tiny temporary DB.
# Population work, classification, bridge and figures are recording adapters;
# certificate checks, DB probing, release hashes/reader and version reservation
# are real. No real gates, corpus, release or installation is consulted.
run_barometar_update_tests <- function() {
  audit <- new.env(parent = globalenv())
  sys.source("studies/demokrscanstvo-barometar/12_update.R", envir = audit)
  repository <- getwd()
  code_paths <- unique(c(names(barometar_release_code_hashes()), "R/lib/barometar_engine.R",
    "R/lib/barometar_text.R", "R/lib/barometar_rules.R", "R/lib/barometar_validation.R",
    "studies/demokrscanstvo-barometar/07_bridge.R", "R/lib/barometar_bridge.R"))
  root <- tempfile("barometar-invented-updates-"); dir.create(root)
  root <- normalizePath(root, winslash = "/")
  stopifnot(startsWith(root, paste0(normalizePath(tempdir(), winslash = "/"), "/")))
  on.exit(setwd(repository), add = TRUE)
  checked <- 0L; number <- 0L
  check <- function(value, label) {
    checked <<- checked + 1L
    if (!isTRUE(value)) stop("Update fixture failed: ", label)
  }
  error_of <- function(expr) tryCatch({force(expr); NULL}, error = identity)
  real_connect <- barometar_connect_readonly
  real_read <- barometar_read_release
  fixture <- function() {
    number <<- number + 1L
    workspace <- file.path(root, paste0("workspace-", number)); dir.create(workspace)
    for (path in code_paths) {
      destination <- file.path(workspace, path); dir.create(dirname(destination), recursive = TRUE, showWarnings = FALSE)
      stopifnot(file.copy(file.path(repository, path), destination))
    }
    setwd(workspace)
    workdir <- file.path(workspace, "work"); dir.create(workdir)
    database <- file.path(workspace, "invented.duckdb")
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = database)
    DBI::dbWriteTable(con, "invented", data.frame(DATE = "2024-02-29", SOURCE_TYPE = "web"))
    DBI::dbDisconnect(con, shutdown = TRUE)
    Sys.setFileTime(database, as.POSIXct(floor(as.numeric(Sys.time())) - 600, origin = "1970-01-01", tz = "UTC"))
    con <- real_connect(database); snapshot <- barometar_source_snapshot(con); DBI::dbDisconnect(con, shutdown = TRUE)
    old_database <- file.path(workspace, "invented-old.duckdb")
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = old_database)
    DBI::dbWriteTable(con, "invented_metadata", data.frame(value = 1L))
    DBI::dbDisconnect(con, shutdown = TRUE)
    Sys.setFileTime(old_database, as.POSIXct(floor(as.numeric(Sys.time())) - 600, origin = "1970-01-01", tz = "UTC"))
    state <- new.env(parent = emptyenv()); state$calls <- character(); state$bridge_generation <- 1L
    record <- function(value) state$calls <- c(state$calls, value)
    version <- "invented-refresh-v1"
    definition <- list(definition_version = version, definition_hash = "invented-definition", compiled = list(),
      text_cap = 10000L, documents = list(rules.yaml = list(invented = "rule")))
    panel <- data.frame(outlet_id = "invented", panel_hash = "invented-panel", panel_version = "invented-panel-v1")
    validation_folder <- file.path(workdir, "validation", version); dir.create(validation_folder, recursive = TRUE)
    validation_path <- file.path(validation_folder, "validation-result.rds")
    saveRDS(list(invented = "result"), validation_path)
    validation_hash <- digikat_hash_file(validation_path)
    gates <- list(G2_definition = list(status = "approved", definition_version = version),
      G3_validation = list(status = "approved", definition_version = version, panel_hash = panel$panel_hash,
        engine_hash = digikat_hash_object(lapply(c("R/lib/barometar_engine.R", "R/lib/barometar_text.R", "R/lib/barometar_rules.R"), digikat_hash_file)),
        classifier_body_hash = digikat_hash_object(body(barometar_classify_month)),
        validation_result_sha256 = validation_hash, validation_code_sha256 = digikat_hash_file("R/lib/barometar_validation.R")))
    gate_path <- "studies/demokrscanstvo-barometar/config/gates.json"
    barometar_write_json(gates, gate_path)
    barometar_write_csv(data.frame(outlet_id = "invented"), "studies/demokrscanstvo-barometar/config/outlet_registry.csv")
    make_bridge <- function() {
      capture <- function(path) {
        con <- real_connect(path); on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
        list(snapshot = barometar_source_snapshot(con))
      }
      saveRDS(list(invented = state$bridge_generation, validated = TRUE, validation_result_hash = validation_hash,
        identity = list(definition = definition$definition_hash, panel = panel$panel_hash,
          registry = digikat_hash_file("studies/demokrscanstvo-barometar/config/outlet_registry.csv"),
          code = vapply(c("studies/demokrscanstvo-barometar/07_bridge.R", "R/lib/barometar_bridge.R"), digikat_hash_file, character(1L))),
        source_fingerprints = list(old = capture(old_database), new = capture(database))), file.path(workdir, "bridge_manifest.rds"))
    }
    make_bridge()
    saveRDS(list(snapshot = snapshot), file.path(workdir, "readiness.rds"))
    make_package <- function(directory, release_version, validation_id = validation_hash) {
      period <- function(frequency, id) data.frame(frequency = frequency, scope = "uze", period_id = id, total_articles = 10L)
      tables <- list(monthly = period("monthly", "2024-02"), weekly = period("weekly", "2024-W08"),
        rolling28 = period("rolling28", "2024-02-25"))
      for (name in c("themes", "composition", "sensitivity", "outlets")) tables[[name]] <- data.frame(invented = character())
      summary <- list(synthetic = FALSE, human_validation_complete = TRUE, release_version = release_version,
        definition_version = version, panel_version = panel$panel_version, data_through = "2024-02-29",
        latest_publishable_month = "2024-02", latest_publishable_week = "2024-W08", findings = list(),
        validation_result_sha256 = validation_id, break_policy = "not_comparable_seam")
      validation <- list(human_validation_complete = TRUE, validation = data.frame(route = character()), release_scope = "uze")
      barometar_write_release(tables, summary, definition, validation, data.frame(scope = character()), directory)
    }
    installed_directory <- "data/barometar/demokrscanstvo"
    make_package(installed_directory, "2026.09.18")
    installed <- list(source_snapshot = snapshot, data_through = "2024-02-29", code_hashes = barometar_release_code_hashes(),
      release_version = "2026.09.18", manifest_sha256 = digikat_hash_file(file.path(installed_directory, "manifest.json")))
    installed_path <- file.path(workdir, "installed_release.rds"); saveRDS(installed, installed_path)
    audit$barometar_workdir <- function(...) workdir
    audit$barometar_require_panel <- function(...) panel
    audit$barometar_definition <- function(...) definition
    audit$barometar_connect_readonly <- function(path = NULL) {
      if (is.null(path)) path <- database
      record(if (identical(path, old_database)) "connect_old" else "connect"); real_connect(path)
    }
    audit$digikat_determdb_old_path <- function() old_database
    audit$barometar_table_sql <- function(...) '"main"."invented"'
    audit$barometar_read_release <- function(...) {record("read_release"); real_read(...)}
    audit$barometar_readiness <- function(con, workdir) {
      record("readiness"); value <- list(snapshot = barometar_source_snapshot(con)); saveRDS(value, file.path(workdir, "readiness.rds")); value
    }
    audit$barometar_outlet_inventory <- function(...) {record("inventory"); list(invented = TRUE)}
    audit$barometar_registry_candidate_from_values <- function(...) "invented.example.invalid"
    audit$barometar_eligible_metadata <- function(...) {record("metadata"); list(invented = TRUE)}
    audit$barometar_panel_proposal <- function(...) {record("proposal"); invisible(NULL)}
    audit$barometar_candidates <- function(...) {
      record("candidates"); saveRDS(list(paths = "invented-candidates.parquet"), file.path(workdir, "candidate_manifest.rds"))
    }
    audit$barometar_boilerplate <- function(...) record("boilerplate")
    audit$barometar_classify_candidates <- function(workdir, development_only, workers) {
      stopifnot(!development_only, workers == 3L); record("classification")
      saveRDS(list(classification_hash = "invented-classification"), file.path(workdir, "classification_manifest.rds"))
    }
    audit$barometar_run_bridge <- function() {
      record("bridge"); make_bridge()
    }
    audit$barometar_aggregate_release <- function(new_edition) {
      record(if (new_edition) "aggregate_new_edition" else "aggregate")
      reserved <- barometar_reserve_preview("2026.09.18", date = "2026-09-18")
      make_package(reserved$directory, reserved$release_version)
      reserved$directory
    }
    audit$barometar_figures <- function(directory) {stopifnot(dir.exists(directory)); record("figures")}
    audit$barometar_release_checks <- function(directory, ...) {stopifnot(dir.exists(directory)); record("checks")}
    force_refresh <- function() {changed <- installed; changed$code_hashes <- "invented-stale-code"; saveRDS(changed, installed_path)}
    make_preview <- function() {
      force_refresh(); audit$barometar_run_bridge()
      directory <- file.path(workspace, "studies/demokrscanstvo-barometar/output/release/2026.09.18-2")
      make_package(directory, "2026.09.18-2")
      receipt <- list(directory = directory, source_snapshot = snapshot, classification_hash = "invented-classification",
        validation_hash = validation_hash, bridge_hash = digikat_hash_file(file.path(workdir, "bridge_manifest.rds")),
        code_hashes = barometar_release_code_hashes())
      saveRDS(receipt, file.path(workdir, "release_manifest.rds")); state$calls <- character(); receipt
    }
    list(state = state, gates = gates, gate_path = gate_path, workdir = workdir, database = database, old_database = old_database,
      installed = installed, installed_path = installed_path, make_package = make_package,
      make_preview = make_preview, force_refresh = force_refresh)
  }
  run <- function(new_edition = FALSE) audit$barometar_update(workers = 3L, new_edition = new_edition)
  f <- fixture()
  result <- run()
  check(is.null(result) && identical(f$state$calls, c("connect", "read_release", "connect_old")), "matching receipt, instrument and both sources take no-new shortcut without pipeline work")
  for (field in c("definition_version", "panel_hash", "engine_hash", "classifier_body_hash", "validation_result_sha256", "validation_code_sha256")) {
    f <- fixture(); changed <- f$gates; changed$G3_validation[[field]] <- "invented-mismatch"; barometar_write_json(changed, f$gate_path)
    check(inherits(error_of(run()), "error") && !length(f$state$calls), paste("stale certificate", field, "is rejected before source access"))
  }
  for (gate in c("G2_definition", "G3_validation")) {
    f <- fixture(); changed <- f$gates; changed[[gate]]$status <- "pending"; barometar_write_json(changed, f$gate_path)
    check(inherits(error_of(run()), "error") && !length(f$state$calls), paste(gate, "pending blocks no-new shortcut"))
  }
  f <- fixture(); f$force_refresh(); run()
  check("aggregate" %in% f$state$calls && !"readiness" %in% f$state$calls &&
    identical(tail(f$state$calls, 3L), c("aggregate", "figures", "checks")), "release-code change rebuilds aggregates while preserving valid population metadata")
  for (field in c("manifest_sha256", "release_version")) {
    f <- fixture(); changed <- f$installed; changed[[field]] <- "invented-stale-receipt"; saveRDS(changed, f$installed_path); run()
    check("aggregate" %in% f$state$calls, paste("installed receipt", field, "must match actual installed generation"))
  }
  f <- fixture()
  summary_path <- "data/barometar/demokrscanstvo/summary.json"
  summary <- jsonlite::fromJSON(summary_path, simplifyVector = FALSE); summary$validation_result_sha256 <- "invented-old-validation"
  barometar_write_json(summary, summary_path); barometar_finalize_manifest(dirname(summary_path), summary)
  f$installed$manifest_sha256 <- digikat_hash_file(file.path(dirname(summary_path), "manifest.json")); saveRDS(f$installed, f$installed_path)
  run(); check("aggregate" %in% f$state$calls, "new human validation cannot silently retain old accepted-route aggregates")
  f <- fixture(); Sys.setFileTime(f$database, file.info(f$database)$mtime - 1); run()
  check(all(c("readiness", "inventory", "metadata", "proposal", "classification", "bridge", "aggregate") %in% f$state$calls), "changed source metadata rebuilds denominator through release")
  f <- fixture(); Sys.setFileTime(f$old_database, file.info(f$old_database)$mtime - 1); run()
  check(all(c("connect_old", "bridge", "aggregate") %in% f$state$calls) && !"readiness" %in% f$state$calls,
    "changed standalone old source alone invalidates no-new shortcut and rebuilds bridge/release")
  f <- fixture(); cat("\n# invented bridge-only change\n", file = "studies/demokrscanstvo-barometar/07_bridge.R", append = TRUE); run()
  check(all(c("bridge", "aggregate") %in% f$state$calls), "bridge-only method change invalidates no-new shortcut")
  f <- fixture(); run(TRUE)
  check("aggregate_new_edition" %in% f$state$calls, "explicit new edition bypasses no-new shortcut")
  f <- fixture(); preview <- f$make_preview(); result <- run()
  check(identical(result, preview$directory) && !"aggregate" %in% f$state$calls && all(c("figures", "checks") %in% f$state$calls), "complete current preview is reused and rechecked")
  for (field in c("validation_hash", "bridge_hash", "classification_hash", "code_hashes")) {
    f <- fixture(); preview <- f$make_preview(); changed <- preview; changed[[field]] <- "invented-stale-preview"
    saveRDS(changed, file.path(f$workdir, "release_manifest.rds")); result <- run()
    check("aggregate" %in% f$state$calls && !identical(result, preview$directory), paste("preview", field, "mismatch gets a fresh generation"))
  }
  f <- fixture(); preview <- f$make_preview(); f$state$bridge_generation <- 2L; run()
  check("aggregate" %in% f$state$calls, "recomputed bridge policy cannot reuse prior aggregates")
  f <- fixture(); preview <- f$make_preview()
  cat("invented corrupt bytes", file = file.path(preview$directory, "monthly.csv"), append = TRUE)
  before <- digikat_hash_file(file.path(preview$directory, "monthly.csv")); result <- run()
  check("aggregate" %in% f$state$calls && basename(result) == "2026.09.18-3" &&
    identical(before, digikat_hash_file(file.path(preview$directory, "monthly.csv"))), "incomplete preview is preserved and rebuilt under a newer version")

  # Reservation examines all attempts, including incomplete directories and
  # colliding files, so retries never reuse a lower hole or overwrite bytes.
  directory <- file.path(root, "isolated previews")
  a <- barometar_reserve_preview(date = "2026-09-18", directory = directory)
  dir.create(file.path(directory, "2026.09.18-7"))
  writeLines("invented sentinel", file.path(directory, "2026.09.18-12"))
  before <- digikat_hash_file(file.path(directory, "2026.09.18-12"))
  b <- barometar_reserve_preview("2026.09.18-4", "2026-09-18", directory)
  c <- barometar_reserve_preview("2026.09.18-20", "2026-09-18", directory)
  d <- barometar_reserve_preview(NULL, "2026-09-18", directory)
  check(a$release_version == "2026.09.18" && b$release_version == "2026.09.18-13" &&
    c$release_version == "2026.09.18-21" && d$release_version == "2026.09.18-22", "preview versions increase above every reserved and installed same-day suffix")
  check(identical(before, digikat_hash_file(file.path(directory, "2026.09.18-12"))) &&
    all(dir.exists(c(a$directory, b$directory, c$directory, d$directory))), "reservation preserves prior files and incomplete directories")
  check(barometar_reserve_preview(d$release_version, "2026-09-19", directory)$release_version == "2026.09.19", "new day starts a fresh date version")
  cat("Barometer update audit: ", checked, "/", checked, " invented checks passed.\n", sep = "")
  invisible(checked)
}
run_barometar_update_tests()
