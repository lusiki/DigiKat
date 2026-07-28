#!/usr/bin/env Rscript
# Normalize the protected master's year field from its canonical DATE field.
#
# Preview:
#   Rscript R/repair_master_year.R
#
# Apply after explicit authorization:
#   Rscript R/repair_master_year.R --apply --confirm=REPAIR_YEAR_FROM_DATE

source("R/lib/digikat_utils.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat(paste(
    "Usage: Rscript R/repair_master_year.R [--apply]",
    "       [--confirm=REPAIR_YEAR_FROM_DATE] [--master=PATH] [--report=PATH]",
    "",
    "Preview is the default. Apply creates and verifies a timestamped backup,",
    "stages and round-trips the repaired file, then atomically replaces it.",
    sep = "\n"
  ))
  quit(save = "no", status = 0L)
}

apply <- digikat_cli_flag(args, "--apply")
confirmation <- digikat_cli_value(args, "--confirm", "")
master_path <- digikat_cli_value(
  args,
  "--master",
  Sys.getenv("DIGIKAT_MASTER_PATH", unset = "data/merged_comprehensive.rds")
)
stamp <- format(Sys.time(), "%Y%m%d_%H%M%S", tz = "UTC")
report_path <- digikat_cli_value(
  args,
  "--report",
  file.path("quality_reports", "data-integrity", paste0("master-year-repair-", stamp, ".json"))
)

if (apply && !identical(confirmation, "REPAIR_YEAR_FROM_DATE")) {
  stop(
    "--apply requires --confirm=REPAIR_YEAR_FROM_DATE after explicit user authorization.",
    call. = FALSE
  )
}
if (!file.exists(master_path)) stop("Master not found: ", master_path, call. = FALSE)

cat("Reading protected master:", master_path, "\n")
master_before <- as.data.frame(readRDS(master_path), stringsAsFactors = FALSE)
digikat_require_columns(master_before, c("DATE", "year"), "master")
dates <- digikat_parse_date(master_before$DATE, name = "master DATE", allow_missing = FALSE)
derived_year <- as.integer(format(dates, "%Y"))
stored_year <- suppressWarnings(as.integer(as.character(master_before$year)))
mismatch <- which(
  is.na(stored_year) != is.na(derived_year) |
    (!is.na(stored_year) & !is.na(derived_year) & stored_year != derived_year)
)
before_metadata <- digikat_file_metadata(master_path, include_hash = TRUE)
schema <- list(
  rows = nrow(master_before),
  columns = ncol(master_before),
  names = names(master_before),
  classes = vapply(master_before, function(value) paste(class(value), collapse = "/"), character(1L))
)
mismatch_table <- as.data.frame(
  table(
    stored = stored_year[mismatch],
    derived = derived_year[mismatch],
    useNA = "ifany"
  ),
  stringsAsFactors = FALSE
)
mismatch_table <- mismatch_table[mismatch_table$Freq > 0, , drop = FALSE]
examples <- if (length(mismatch)) {
  utils::head(
    data.frame(
      row = mismatch,
      DATE = as.character(master_before$DATE[mismatch]),
      stored_year = stored_year[mismatch],
      derived_year = derived_year[mismatch]
    ),
    20L
  )
} else {
  data.frame()
}

report <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "R/repair_master_year.R",
  mode = if (apply) "apply" else "preview",
  master_before = before_metadata,
  schema = schema,
  mismatch_count = length(mismatch),
  mismatch_transitions = mismatch_table,
  examples = examples,
  invariant = "year is the integer calendar year derived from DATE"
)

if (!length(mismatch)) {
  report$status <- "already_normalized"
  digikat_write_json_atomic(report, report_path)
  cat("Master year is already normalized. Report:", report_path, "\n")
  quit(save = "no", status = 0L)
}

cat("Rows requiring correction:", length(mismatch), "\n")
if (!apply) {
  report$status <- "preview_only"
  digikat_write_json_atomic(report, report_path)
  cat("Preview complete; master was not modified. Report:", report_path, "\n")
  quit(save = "no", status = 0L)
}

backup_path <- file.path(
  dirname(master_path),
  paste0(
    tools::file_path_sans_ext(basename(master_path)),
    "_backup_year_",
    stamp,
    ".rds"
  )
)
if (file.exists(backup_path)) stop("Backup target already exists: ", backup_path, call. = FALSE)
cat("Creating verified backup:", backup_path, "\n")
if (!file.copy(master_path, backup_path, overwrite = FALSE, copy.date = TRUE)) {
  stop("Could not create master backup.", call. = FALSE)
}
backup_metadata <- digikat_file_metadata(backup_path, include_hash = TRUE)
if (!identical(backup_metadata$sha256, before_metadata$sha256) ||
    !identical(as.numeric(backup_metadata$bytes), as.numeric(before_metadata$bytes))) {
  stop("Backup verification failed; protected master was not changed.", call. = FALSE)
}

column_hashes_before <- vapply(
  master_before[setdiff(names(master_before), "year")],
  digikat_hash_object,
  character(1L)
)
year_class <- class(master_before$year)
master_before$year <- as.numeric(derived_year)
if (!identical(class(master_before$year), year_class)) {
  stop("Year repair would change the year column class.", call. = FALSE)
}

stage_path <- file.path(
  dirname(master_path),
  paste0(".", tools::file_path_sans_ext(basename(master_path)), "-year-stage-", Sys.getpid(), ".rds")
)
if (file.exists(stage_path)) stop("Staging target already exists: ", stage_path, call. = FALSE)
on.exit(if (file.exists(stage_path)) unlink(stage_path), add = TRUE)
cat("Writing staged repaired master...\n")
saveRDS(master_before, stage_path)
rm(master_before)
gc()

cat("Round-trip validating staged master...\n")
master_after <- as.data.frame(readRDS(stage_path), stringsAsFactors = FALSE)
if (!identical(nrow(master_after), schema$rows) ||
    !identical(ncol(master_after), schema$columns) ||
    !identical(names(master_after), schema$names)) {
  stop("Staged master schema or dimensions changed.", call. = FALSE)
}
if (!identical(
  vapply(master_after, function(value) paste(class(value), collapse = "/"), character(1L)),
  schema$classes
)) {
  stop("Staged master column classes changed.", call. = FALSE)
}
after_year <- suppressWarnings(as.integer(as.character(master_after$year)))
if (!identical(after_year, derived_year)) {
  stop("Staged master year values do not equal year(DATE).", call. = FALSE)
}
column_hashes_after <- vapply(
  master_after[setdiff(names(master_after), "year")],
  digikat_hash_object,
  character(1L)
)
if (!identical(column_hashes_after, column_hashes_before)) {
  changed <- names(column_hashes_before)[column_hashes_before != column_hashes_after]
  stop(
    "The staged repair changed non-year column(s): ",
    paste(changed, collapse = ", "),
    call. = FALSE
  )
}
rm(master_after)
gc()

staged_metadata <- digikat_file_metadata(stage_path, include_hash = TRUE)
cat("Installing staged master atomically...\n")
digikat_atomic_replace_file(stage_path, master_path)
after_metadata <- digikat_file_metadata(master_path, include_hash = TRUE)
if (!identical(after_metadata$sha256, staged_metadata$sha256)) {
  stop(
    "Installed master hash does not match the validated stage. Restore from: ",
    backup_path,
    call. = FALSE
  )
}

report$status <- "applied"
report$backup <- backup_metadata
report$master_after <- after_metadata
report$changed_columns <- list("year")
report$unchanged_column_hashes <- column_hashes_after
report$recovery <- paste("Restore the verified backup only if later validation fails:", backup_path)
digikat_write_json_atomic(report, report_path)
cat("Master year repair applied safely.\n")
cat("  corrected rows:", length(mismatch), "\n")
cat("  verified backup:", backup_path, "\n")
cat("  report:", report_path, "\n")
