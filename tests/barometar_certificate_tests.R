# Exercise G3 acceptance only inside a temporary invented project. The real
# repository gates, empirical workdir, human labels and source DBs are untouched.
run_barometar_certificate_tests <- function() {
  audit <- new.env(parent = globalenv())
  sys.source("studies/demokrscanstvo-barometar/accept_validation.R", envir = audit)
  repository <- getwd()
  root <- tempfile("barometar-invented-certificate-"); dir.create(root)
  root <- normalizePath(root, winslash = "/")
  stopifnot(startsWith(root, paste0(normalizePath(tempdir(), winslash = "/"), "/")))
  paths <- unique(c("R/lib/barometar_validation.R", "R/lib/barometar_coding.R",
    "studies/demokrscanstvo-barometar/coder_template.html",
    "studies/demokrscanstvo-barometar/07_bridge.R", "studies/demokrscanstvo-barometar/02_panel.R",
    "R/lib/digikat_utils.R", "R/lib/barometar_bridge.R", "R/lib/barometar_outlet_urls.R",
    "R/lib/barometar_url_rules.R", "R/lib/barometar_engine.R", "R/lib/barometar_text.R", "R/lib/barometar_rules.R"))
  for (path in paths) {
    target <- file.path(root, path); dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
    stopifnot(file.copy(file.path(repository, path), target))
  }
  setwd(root); on.exit(setwd(repository), add = TRUE)
  workdir <- file.path(root, "work"); dir.create(workdir)
  version <- "invented-certificate-v1"
  definition <- list(definition_version = version, definition_hash = "invented-definition")
  panel <- data.frame(outlet_id = "invented", panel_hash = "invented-panel")
  audit$barometar_workdir <- function(...) workdir
  audit$barometar_definition <- function(...) definition
  audit$barometar_require_panel <- function(...) panel
  database <- setNames(file.path(root, paste0(c("old", "new"), ".duckdb")), c("old", "new"))
  snapshots <- list()
  for (batch in names(database)) {
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = database[[batch]])
    DBI::dbExecute(con, "CREATE TABLE invented_metadata (value INTEGER)")
    DBI::dbDisconnect(con, shutdown = TRUE)
    Sys.setFileTime(database[[batch]], as.POSIXct(floor(as.numeric(Sys.time())) - 600, origin = "1970-01-01", tz = "UTC"))
    con <- barometar_connect_readonly(database[[batch]])
    snapshots[[batch]] <- list(snapshot = barometar_source_snapshot(con))
    DBI::dbDisconnect(con, shutdown = TRUE)
  }
  audit$digikat_determdb_old_path <- function() database[["old"]]
  audit$digikat_determdb_path <- function() database[["new"]]
  population <- data.frame(item_id = paste0("invented-certificate-", 1:8), development = FALSE,
    route_set = "A1", source_batch = rep(c("luka_opce", "mediaspace_full"), each = 4L),
    near_miss = FALSE, recall_probe = FALSE, themes = "work")
  draw <- barometar_validation_draw(population)
  draw$definition_version <- version
  draw$exclusion_hashes <- list(invented = "exclusion")
  draw$input_identity <- list(classification_hash = "invented-classification", input_digest = "invented-input", panel_hash = panel$panel_hash,
    classifier_body_hash = digikat_hash_object(body(barometar_classify_month)),
    code_hashes = setNames(vapply(paths[1:3], digikat_hash_file, character(1L)), c("sampling", "context", "template")))
  draw$draw_id <- barometar_draw_identity(draw)
  folder <- file.path(workdir, "validation", version); dir.create(folder, recursive = TRUE)
  saveRDS(draw, file.path(folder, "draw.rds"))
  barometar_write_csv(draw$membership, file.path(folder, "draw_membership_private.csv"))
  for (role in c("human_PI", "human_second"))
    writeLines(paste("<!doctype html><title>Invented package", role, "</title>"), file.path(folder, paste0(role, ".html")), useBytes = TRUE)
  package_files <- c("draw.rds", "draw_membership_private.csv", "human_PI.html", "human_second.html")
  barometar_write_json(list(draw_id = draw$draw_id, files = as.list(setNames(vapply(file.path(folder, package_files),
    digikat_hash_file, character(1L)), package_files))), file.path(folder, "package_manifest.json"))
  classification <- list(classification_hash = "invented-classification", engine_hash = "invented-engine", panel_hash = panel$panel_hash)
  saveRDS(classification, file.path(workdir, "classification_manifest.rds"))
  result <- list(human_validation_complete = TRUE, draw_id = draw$draw_id,
    input_hashes = setNames(rep("invented-export-hash", 4L), c("pi", "second", "adjudicated", "log")),
    accepted_routes = "A1", release_scope = "uze")
  result_path <- file.path(folder, "validation-result.rds"); saveRDS(result, result_path)
  bridge <- list(validated = TRUE, validation_result_hash = digikat_hash_file(result_path),
    identity = list(definition = definition$definition_hash, panel = panel$panel_hash,
      code = vapply(paths[4:length(paths)], digikat_hash_file, character(1L))),
    source_fingerprints = snapshots, break_policy = "not_comparable_seam")
  bridge_path <- file.path(workdir, "bridge_manifest.rds"); saveRDS(bridge, bridge_path)
  gate_path <- "studies/demokrscanstvo-barometar/config/gates.json"
  barometar_write_json(list(G2_definition = list(status = "approved", definition_version = version)), gate_path)
  checked <- 0L
  check <- function(value, label) {
    checked <<- checked + 1L
    if (!isTRUE(value)) stop("Certificate fixture failed: ", label)
  }
  rejects <- function(expr, message) {
    error <- tryCatch({force(expr); NULL}, error = identity)
    inherits(error, "error") && grepl(message, conditionMessage(error), fixed = TRUE)
  }
  accepted <- audit$barometar_accept_validation()
  check(accepted$status == "approved" && accepted$release_scope == "uze", "invented complete evidence permits narrow G3")
  check(identical(accepted$classifier_body_hash, draw$input_identity$classifier_body_hash) &&
    identical(accepted$validation_result_sha256, digikat_hash_file(result_path)) &&
    identical(accepted$validation_input_digest, "invented-input"), "certificate binds body, result and original validation population")
  classifier <- barometar_classify_month
  changed_classifier <- classifier
  body(changed_classifier) <- substitute({invented_change <- TRUE; BODY}, list(BODY = body(classifier)))
  audit$barometar_classify_month <- changed_classifier
  check(rejects(audit$barometar_accept_validation(), "identity is incomplete or stale"), "changed classifier body cannot reuse the human draw")
  audit$barometar_classify_month <- classifier
  broken <- result; broken$human_validation_complete <- FALSE; saveRDS(broken, result_path)
  check(rejects(audit$barometar_accept_validation(), "identity is incomplete or stale"), "incomplete human review cannot be accepted")
  saveRDS(result, result_path)
  broken <- classification; broken$classification_hash <- "invented-new-population"; saveRDS(broken, file.path(workdir, "classification_manifest.rds"))
  check(rejects(audit$barometar_accept_validation(), "identity is incomplete or stale"), "initial certificate requires the evaluated classification")
  saveRDS(classification, file.path(workdir, "classification_manifest.rds"))
  broken <- classification; broken$panel_hash <- "invented-other-panel"; saveRDS(broken, file.path(workdir, "classification_manifest.rds"))
  check(rejects(audit$barometar_accept_validation(), "identity is incomplete or stale"), "classification panel must match the human draw and frozen panel")
  saveRDS(classification, file.path(workdir, "classification_manifest.rds"))
  original_panel <- panel
  panel$panel_hash <- "invented-newly-frozen-panel"
  broken <- bridge; broken$identity$panel <- panel$panel_hash; saveRDS(broken, bridge_path)
  check(rejects(audit$barometar_accept_validation(), "identity is incomplete or stale"), "a refreshed bridge cannot transfer old validation onto another panel")
  panel <- original_panel; saveRDS(bridge, bridge_path)
  broken <- bridge; broken$validation_result_hash <- "invented-stale-result"; saveRDS(broken, bridge_path)
  check(rejects(audit$barometar_accept_validation(), "Re-run the bridge"), "bridge must be bound to the exact completed result")
  saveRDS(bridge, bridge_path)
  code_path <- paths[4L]
  bytes <- readBin(code_path, "raw", n = file.info(code_path)$size)
  connection <- file(code_path, "ab"); writeBin(charToRaw("\n# invented change\n"), connection); close(connection)
  check(rejects(audit$barometar_accept_validation(), "Bridge code changed"), "bridge method code changes invalidate acceptance")
  connection <- file(code_path, "wb"); writeBin(bytes, connection); close(connection)
  for (batch in names(database)) {
    old_time <- file.info(database[[batch]])$mtime
    Sys.setFileTime(database[[batch]], old_time - 1)
    check(rejects(audit$barometar_accept_validation(), "changed during the run"), paste("changed", batch, "source snapshot invalidates acceptance"))
    Sys.setFileTime(database[[batch]], old_time)
  }
  check(identical(audit$barometar_accept_validation()$status, "approved"), "restored invented inputs permit acceptance again")
  cat("Barometer certificate audit: ", checked, "/", checked, " invented checks passed.\n", sep = "")
  invisible(checked)
}
run_barometar_certificate_tests()
