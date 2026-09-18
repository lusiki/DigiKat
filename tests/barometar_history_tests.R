# Release-history fixtures are entirely invented; no empirical release is read.
run_barometar_history_tests <- function(strict = TRUE) {
  source("studies/demokrscanstvo-barometar/08_aggregate.R", encoding = "UTF-8")
  failures <- character(); checked <- 0L
  check <- function(value, label) {
    checked <<- checked + 1L
    if (!isTRUE(value)) failures <<- c(failures, label)
  }
  rejects <- function(expr) inherits(tryCatch({force(expr); NULL}, error = identity), "error")
  root <- tempfile("barometar-invented-history-"); dir.create(root)
  version <- "2026.09.18"
  check(identical(barometar_release_version(date = "2026-09-18"), version), "first release uses date version")
  second_version <- barometar_release_version(version, "2026-09-18")
  third_version <- barometar_release_version(second_version, "2026-09-18")
  check(length(unique(c(version, second_version, third_version))) == 3L &&
    as.integer(sub("^.*-", "", third_version)) == as.integer(sub("^.*-", "", second_version)) + 1L,
    "repeated same-day versions are unique and consecutive")
  check(identical(barometar_release_version(third_version, "2026-09-19"), "2026.09.19"), "new date resets same-day suffix")
  check(rejects(barometar_release_version("2026.09.18-bad", "2026-09-18")), "invalid same-day suffix is rejected")
  make_table <- function(frequency, ids) data.frame(frequency = frequency, scope = "uze", period_id = ids,
    visibility_status = c("published", "partial"), total_articles = 300L, matching_articles = 100L,
    visibility_per_10000 = 10000/3, release_version = version, data_through = "2024-02-29")
  tables <- list(monthly = make_table("monthly", c("2024-01", "2024-02")),
    weekly = make_table("weekly", c("2024-W04", "2024-W05")),
    rolling28 = make_table("rolling28", c("2024-01-28", "2024-01-29")))
  summary <- list(synthetic = TRUE, human_validation_complete = FALSE, release_version = version,
    definition_version = "invented-definition", panel_version = "invented-panel", data_through = "2024-02-29",
    latest_publishable_month = "2024-01", latest_publishable_week = "2024-W04",
    computed_at = "2026-09-18T12:00:00Z", findings = list("Invented frozen finding."), break_policy = "not_comparable_seam")
  definition <- list(definition_version = summary$definition_version, definition_hash = "invented-definition-hash",
    text_cap = 10000L, compiled = list(), documents = list(rules.yaml = list(invented = "rule")))
  validation <- list(human_validation_complete = FALSE, validation = data.frame(route = character(), precision = numeric()),
    release_scope = "uze", accepted_routes = "A1")
  bridge <- data.frame(scope = character(), ratio = numeric())
  write_release <- function(path, t = tables, s = summary, previous = NULL, edition = FALSE)
    barometar_write_release(t, s, definition, validation, bridge, path, previous, edition)
  read_csv <- function(path) utils::read.csv(path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE, na.strings = "")
  first <- file.path(root, "first")
  write_release(first)
  frozen <- file.path("izdanja", "2024-01", "summary.json")
  original_bytes <- readBin(file.path(first, frozen), "raw", n = file.info(file.path(first, frozen))$size)
  check(nrow(read_csv(file.path(first, "revisions.csv"))) == 0L, "first release starts with an empty revision log")
  check(nrow(read_csv(file.path(first, "releases.csv"))) == 1L, "first release has one history entry")

  # A no-op refresh must not turn serialization rounding into revisions.
  no_op_summary <- summary; no_op_summary$release_version <- second_version
  no_op_tables <- lapply(tables, function(x) {x$release_version <- second_version; x})
  no_op <- file.path(root, "no-op")
  write_release(no_op, no_op_tables, no_op_summary, first)
  check(nrow(read_csv(file.path(no_op, "revisions.csv"))) == 0L, "unchanged numeric values survive CSV round-trip without false revisions")

  changed_tables <- no_op_tables
  changed_tables$monthly$visibility_per_10000[1L] <- 3400
  changed_tables$monthly$visibility_status[2L] <- "unavailable"
  changed_tables$rolling28 <- changed_tables$rolling28[-1L, ]
  changed_summary <- no_op_summary
  changed_summary$latest_publishable_month <- "2024-02"
  changed_summary$findings <- list("Invented replacement must not rewrite frozen findings.")
  second <- file.path(root, "second")
  write_release(second, changed_tables, changed_summary, first)
  revised <- read_csv(file.path(second, "revisions.csv"))
  numeric_revision <- revised[revised$table == "monthly" & revised$period_id == "2024-01" & revised$field == "visibility_per_10000", ]
  check(nrow(numeric_revision) == 1L && as.numeric(numeric_revision$current_value) == 3400, "numeric revisions identify field and period")
  check(any(revised$table == "monthly" & revised$period_id == "2024-02" & revised$field == "visibility_status" &
    revised$previous_value == "partial" & revised$current_value == "unavailable", na.rm = TRUE), "status revisions preserve old and new states")
  check(any(revised$table == "rolling28" & revised$period_id == "2024-01-28" & is.na(revised$current_value)), "removed rows are represented in the revision log")
  check(!any(revised$field %in% c("release_version", "data_through", "computed_at")), "administrative metadata changes are not aggregate revisions")
  preserved <- readBin(file.path(second, frozen), "raw", n = file.info(file.path(second, frozen))$size)
  check(identical(original_bytes, preserved), "refresh preserves old edition bytes exactly")
  loaded_second <- barometar_read_release(second, synthetic_allowed = TRUE)$summary
  check(identical(loaded_second$edition, "2024-01") && identical(loaded_second$findings, summary$findings), "ordinary refresh retains the frozen edition and findings")
  check(identical(loaded_second$edition_summary_sha256, digikat_hash_file(file.path(second, frozen))), "summary binds the preserved edition hash")
  check(nrow(read_csv(file.path(second, "releases.csv"))) == 2L, "second release appends its history entry")

  # Same fixed inputs must give identical files, including manifest and history.
  replica <- file.path(root, "replica")
  write_release(replica, changed_tables, changed_summary, first)
  paths <- list.files(second, recursive = TRUE)
  check(identical(paths, list.files(replica, recursive = TRUE)) && all(vapply(paths, function(path)
    identical(digikat_hash_file(file.path(second, path)), digikat_hash_file(file.path(replica, path))), logical(1L))),
    "second release has deterministic bytes under fixed inputs")

  third_summary <- changed_summary; third_summary$release_version <- third_version
  third <- file.path(root, "third")
  write_release(third, changed_tables, third_summary, second, edition = TRUE)
  check(file.exists(file.path(third, "izdanja", "2024-02", "summary.json")) &&
    identical(digikat_hash_file(file.path(first, frozen)), digikat_hash_file(file.path(third, frozen))), "new monthly edition preserves the older edition and adds its own file")
  check(nrow(read_csv(file.path(third, "releases.csv"))) == 3L &&
    nrow(read_csv(file.path(third, "revisions.csv"))) >= nrow(revised), "third release retains prior release and revision history")
  collision_summary <- third_summary; collision_summary$release_version <- barometar_release_version(third_version, "2026-09-18")
  check(rejects(write_release(file.path(root, "edition-collision"), changed_tables, collision_summary, third, TRUE)), "an existing edition cannot be overwritten")
  migration <- no_op_summary; migration$panel_version <- "invented-other-panel"
  check(rejects(write_release(file.path(root, "migration"), no_op_tables, migration, first)), "panel migration cannot silently join an earlier history")
  check(rejects(write_release(file.path(root, "same-version"), tables, summary, first)), "same release version cannot be reused")
  cat("Barometer history audit: ", checked - length(failures), "/", checked, " invented checks passed.\n", sep = "")
  if (length(failures)) {
    cat(paste0("- ", failures, collapse = "\n"), "\n")
    if (strict) stop("Release history audit failed.", call. = FALSE)
  }
  invisible(list(checks = checked, failures = failures))
}
run_barometar_history_tests()
