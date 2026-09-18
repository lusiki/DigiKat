# Invented human-export fixtures only. No real workdir/database is consulted.
run_barometar_human_import_tests <- function() {
  audit <- new.env(parent = globalenv())
  sys.source("studies/demokrscanstvo-barometar/06_validation_score.R", envir = audit)
  root <- tempfile("barometar-invented-human-import-")
  dir.create(root)
  version <- "invented-human-import-v1"
  folder <- file.path(root, "validation", version)
  dir.create(folder, recursive = TRUE)
  audit$barometar_workdir <- function(...) root
  audit$barometar_definition <- function(...) list(definition_version = version)
  failures <- character(); checked <- 0L
  check <- function(value, label) {
    checked <<- checked + 1L
    if (!isTRUE(value)) failures <<- c(failures, label)
  }
  rejects <- function(expr) inherits(tryCatch({force(expr); NULL}, error = identity), "error")
  pop <- data.frame(item_id = paste0("invented-import-", 1:8), development = FALSE,
    route_set = "A1", source_batch = rep(c("luka_opce", "mediaspace_full"), each = 4L),
    near_miss = FALSE, recall_probe = FALSE, themes = "work")
  draw <- barometar_validation_draw(pop)
  draw$definition_version <- version
  draw$exclusion_hashes <- list("invented-agent-log.csv" = "invented-exclusion-hash")
  code_paths <- c("R/lib/barometar_validation.R", "R/lib/barometar_coding.R",
                  "studies/demokrscanstvo-barometar/coder_template.html")
  draw$input_identity <- list(classification_hash = "invented-classification-hash",
    input_digest = "invented-source-hash", panel_hash = "invented-panel-hash",
    boilerplate_version = "invented-mask-version",
    code_hashes = setNames(vapply(code_paths, digikat_hash_file, character(1L)),
                          c("sampling", "context", "template")))
  draw_identity <- barometar_draw_identity
  draw$draw_id <- draw_identity(draw)
  package_files <- c("draw.rds", "draw_membership_private.csv", "human_PI.html", "human_second.html")
  manifest_path <- file.path(folder, "package_manifest.json")
  write_manifest <- function(x = draw) {
    manifest <- list(draw_id = x$draw_id,
      files = as.list(setNames(vapply(file.path(folder, package_files), digikat_hash_file,
        character(1L)), package_files)))
    barometar_write_json(manifest, manifest_path)
    invisible(manifest)
  }
  write_package <- function(x = draw) {
    saveRDS(x, file.path(folder, "draw.rds"))
    barometar_write_csv(x$membership, file.path(folder, "draw_membership_private.csv"))
    for (role in c("human_PI", "human_second"))
      writeLines(paste0("<!doctype html><title>Invented ", role, " package</title>"), file.path(folder, paste0(role, ".html")), useBytes = TRUE)
    write_manifest(x)
  }
  write_package()
  check(isTRUE(audit$barometar_check_coding_package(folder, draw)), "real package manifest and recomputed draw identity pass")
  check(setequal(names(jsonlite::fromJSON(manifest_path, simplifyVector = FALSE)$files), package_files), "JSON manifest preserves named file hashes as an object")
  for (name in package_files) {
    cat("invented-byte-tamper", file = file.path(folder, name), append = TRUE)
    check(rejects(audit$barometar_check_coding_package(folder, draw)), paste("reject tampered package file", name))
    write_package()
  }
  manifest <- write_manifest(); manifest$draw_id <- "invented-other-draw"
  barometar_write_json(manifest, manifest_path)
  check(rejects(audit$barometar_check_coding_package(folder, draw)), "reject mismatched manifest draw ID")
  manifest <- write_manifest(); manifest$files[["human_second.html"]] <- NULL
  barometar_write_json(manifest, manifest_path)
  check(rejects(audit$barometar_check_coding_package(folder, draw)), "reject missing required manifest entry")
  write_manifest()
  for (field in c("classification_hash", "input_digest", "panel_hash", "boilerplate_version")) {
    changed <- draw; changed$input_identity[[field]] <- "invented-changed-identity"
    write_package(changed)
    check(rejects(audit$barometar_check_coding_package(folder, changed)), paste("reject unbound draw identity change", field))
  }
  for (component in c("assignments", "membership", "frame", "design", "seed", "exclusion_hashes", "definition_version")) {
    changed <- draw
    if (component == "assignments") changed$assignments$double_code[1L] <- FALSE
    if (component == "membership") changed$membership$n[1L] <- 999L
    if (component == "frame") changed$frame$route_set[1L] <- "A1;C"
    if (component == "design") changed$design$N[1L] <- 999L
    if (component == "seed") changed$seed <- changed$seed + 1L
    if (component == "exclusion_hashes") changed$exclusion_hashes[[1L]] <- "invented-other-exclusion"
    if (component == "definition_version") changed$definition_version <- "invented-other-version"
    write_package(changed)
    check(rejects(audit$barometar_check_coding_package(folder, changed)), paste("reject stale draw ID for changed", component))
  }
  for (component in c("sampling", "context", "template")) {
    changed <- draw; changed$input_identity$code_hashes[[component]] <- "invented-obsolete-code-hash"
    changed$draw_id <- draw_identity(changed)
    write_package(changed)
    check(rejects(audit$barometar_check_coding_package(folder, changed)), paste("reject changed current instrument", component))
  }
  write_package()
  answer <- function(role) data.frame(item_id = draw$assignments$item_id, coder_type = role,
    qualifies = c(rep("da", 6L), "ne", "ne"),
    construct = c(rep("A1", 6L), "ništa", "ništa"),
    speaker_type = "ostalo / nepripisano", geography = "domaće", register = "supstancijski",
    themes = "work", axis1 = "genuine", axis2 = "domestic", axis3 = "both", axis4 = "other",
    masked_evidence = "ne", stringsAsFactors = FALSE)
  export <- function(role, name) list(draw_id = draw$draw_id, definition_version = version,
    coder_type = role, coder_name = name, answers = answer(role))
  pi <- export("human_PI", "Invented PI")
  second <- export("human_second", "Invented Independent Coder")
  final <- export("human_PI_adjudicated", pi$coder_name)
  final$human_review_complete <- TRUE
  put <- function(x, name) {
    path <- file.path(root, paste0(name, ".json"))
    jsonlite::write_json(x, path, auto_unbox = TRUE, pretty = TRUE, na = "null")
    path
  }
  paths <- c(pi = put(pi, "pi"), second = put(second, "second"), final = put(final, "final"))
  read <- function(x, role = "human_PI") audit$barometar_read_human_export(put(x, "probe"), draw, role)
  run <- function(adjudicated = paths[["final"]], log = file.path(root, "audit.csv"))
    audit$barometar_score_human_exports(paths[["pi"]], paths[["second"]], adjudicated, log)
  write_log <- function(x) utils::write.csv(x, file.path(root, "audit.csv"), row.names = FALSE, na = "")
  blank_log <- data.frame(item_id = character(), fields = character(), reason = character())
  write_log(blank_log)

  shuffled <- pi; shuffled$answers <- shuffled$answers[8:1, ]
  check(identical(read(shuffled)$answers$item_id, draw$assignments$item_id), "imports join by IDs, not row order")
  for (field in c("draw_id", "definition_version", "coder_type")) {
    bad <- pi; bad[[field]] <- "invented-wrong-value"
    check(rejects(read(bad)), paste("reject wrong", field))
  }
  for (name in list(NULL, "", " \t\n")) {
    bad <- pi; bad$coder_name <- name
    check(rejects(read(bad)), "reject missing or blank coder name")
  }
  bad <- pi; bad$answers$item_id[2L] <- bad$answers$item_id[1L]
  check(rejects(read(bad)), "reject duplicate IDs")
  bad <- pi; bad$answers$item_id[2L] <- "invented-foreign-item"
  check(rejects(read(bad)), "reject foreign IDs")
  bad <- pi; bad$answers <- bad$answers[-1L, ]
  check(rejects(read(bad)), "reject missing answers")
  bad <- pi; bad$answers$coder_type[1L] <- "human_second"
  check(rejects(read(bad)), "reject mismatched answer-row role")

  same <- second; same$coder_name <- "  INVENTED PI  "
  paths[["second"]] <- put(same, "second")
  check(rejects(run()), "reject same human after case/edge-space normalization")
  paths[["second"]] <- put(second, "second")
  for (complete in list(NULL, FALSE, "true", 1L)) {
    bad <- final; bad$human_review_complete <- complete
    check(rejects(run(put(bad, "unreviewed"))), "reject absent/nonlogical/uncompleted human review")
  }
  bad <- final; bad$coder_name <- "Another Invented Human"
  check(rejects(run(put(bad, "foreign-adjudicator"))), "adjudicator must be named PI")
  check(!file.exists(file.path(folder, "validation-result.rds")), "guard failures never produce a validation result")

  invisible(run(adjudicated = NULL))
  template_path <- file.path(folder, "adjudication-template.json")
  template <- jsonlite::fromJSON(template_path)
  check(identical(template$human_review_complete, FALSE), "generated template explicitly remains unreviewed")
  check(!file.exists(file.path(folder, "validation-result.rds")), "template generation does not score labels")
  check(rejects(run(adjudicated = template_path)), "generated template cannot be scored before review")
  check(rejects(run(adjudicated = NULL)), "do not overwrite existing adjudication work")

  # A second-coder disagreement and a separate PI revision both need reasons.
  second$answers$qualifies[1L] <- "ne"
  second$answers$construct[1L] <- "ništa"
  final$answers$axis2[2L] <- "foreign"
  final$answers$themes[2L] <- "economy;work"
  paths[["second"]] <- put(second, "second")
  paths[["final"]] <- put(final, "final")
  required <- audit$barometar_adjudication_requirements(pi$answers, second$answers, final$answers)
  check(setequal(required$item_id, draw$assignments$item_id[1:2]), "audit covers both disagreement and independent PI revision")
  check(all(c("construct", "qualifies") %in% strsplit(required$fields[required$item_id == draw$assignments$item_id[1L]], ";", fixed = TRUE)[[1L]]), "all disagreement fields recorded")
  check(all(c("axis2", "themes") %in% strsplit(required$fields[required$item_id == draw$assignments$item_id[2L]], ";", fixed = TRUE)[[1L]]), "all revised fields recorded")
  same_sets <- pi$answers; reversed_sets <- pi$answers
  same_sets$construct[1L] <- "A1;B"; reversed_sets$construct[1L] <- "B;A1"
  same_sets$themes[1L] <- "work;economy"; reversed_sets$themes[1L] <- "economy;work"
  check(nrow(audit$barometar_adjudication_requirements(same_sets, reversed_sets)) == 0L, "set-label ordering creates no spurious disagreement")
  check(rejects(run(log = NULL)), "adjudication log is mandatory")
  check(rejects(run()), "empty log cannot omit disagreement/revision rows")
  required$reason <- "Invented fixture explanation after independent human review."
  write_log(required[-2L, , drop = FALSE])
  check(rejects(run()), "audit cannot omit PI revision")
  missing_field <- required; missing_field$fields[1L] <- "construct"
  write_log(missing_field)
  check(rejects(run()), "audit cannot omit a changed field")
  no_reason <- required; no_reason$reason[1L] <- "  "
  write_log(no_reason)
  check(rejects(run()), "audit cannot use a blank explanation")
  foreign <- required; foreign$item_id[1L] <- "invented-foreign-item"
  write_log(foreign)
  check(rejects(run()), "audit cannot use a foreign item")
  write_log(required)
  result <- run()
  check(isTRUE(result$human_validation_complete) && identical(result$draw_id, draw$draw_id), "complete invented review scores with frozen draw identity")
  check(setequal(names(result$input_hashes), c("pi", "second", "adjudicated", "log")), "scored result fingerprints all four human inputs")
  check(file.exists(file.path(folder, "validation-result.rds")), "completed review writes a private validation result")

  # All-agreement review still needs the header-only audit, then may complete.
  paths[["second"]] <- put(export("human_second", "Invented Independent Coder"), "second")
  final <- export("human_PI_adjudicated", pi$coder_name); final$human_review_complete <- TRUE
  paths[["final"]] <- put(final, "final"); write_log(blank_log)
  check(isTRUE(run()$human_validation_complete), "header-only audit is accepted when no field changed")
  if (length(failures)) stop(paste(c("Human-import audit failed:", failures), collapse = "\n"))
  message("All ", checked, " invented human-import checks passed.")
  invisible(checked)
}

run_barometar_human_import_tests()
