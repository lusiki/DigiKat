#!/usr/bin/env Rscript
# Safely append a new XLSX batch to the protected DigiKat master.
#
# Default mode is a READ-ONLY preview:
#   Rscript R/append_new_data.R
#
# Apply only after reviewing the JSON delta report:
#   Rscript R/append_new_data.R --apply
#
# Optional arguments:
#   --new-dir=PATH       default: data/raw/new
#   --master=PATH        default: data/merged_comprehensive.rds
#   --report=PATH        custom JSON report path
#   --allow-missing-dedup-key
#
# The >= 2 DISTINCT religious-term inclusion rule is unchanged.

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(stringi)
})

source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat(paste(
    "Usage: Rscript R/append_new_data.R [--apply] [--new-dir=PATH] [--master=PATH]",
    "       [--report=PATH] [--allow-missing-dedup-key]",
    "",
    "Without --apply the script writes only a JSON preview report.",
    sep = "\n"
  ))
  quit(save = "no", status = 0L)
}

apply_changes <- digikat_cli_flag(args, "--apply")
new_data_folder <- digikat_cli_value(
  args,
  "--new-dir",
  Sys.getenv("DIGIKAT_NEW_DATA_DIR", unset = "data/raw/new")
)
master_path <- digikat_cli_value(
  args,
  "--master",
  Sys.getenv("DIGIKAT_MASTER_PATH", unset = "data/merged_comprehensive.rds")
)
allow_missing_dedup <- digikat_cli_flag(args, "--allow-missing-dedup-key")
dedup_key <- "URL"
terms_path <- "R/religious_terms.R"
min_matches <- 2L
batch_size <- 5000L
stamp <- format(Sys.time(), "%Y%m%d_%H%M%S", tz = "UTC")
report_path <- digikat_cli_value(
  args,
  "--report",
  file.path("quality_reports", "ingestion", paste0("append-", stamp, ".json"))
)
cache_path <- file.path("data", "private", "cache", "master_url_keys.rds")

if (!file.exists(master_path)) {
  stop(
    "Master file not found: ", master_path,
    "\nThis script appends to an existing master; it never creates one from scratch.",
    call. = FALSE
  )
}
if (!dir.exists(new_data_folder)) {
  stop(
    "New-data folder not found: ", new_data_folder,
    "\nCreate data/raw/new/ and place only the new XLSX batch there.",
    call. = FALSE
  )
}

new_files <- sort(list.files(new_data_folder, pattern = "\\.xlsx$", full.names = TRUE))
if (!length(new_files)) stop("No XLSX files found in ", new_data_folder, call. = FALSE)

cat("Mode:", if (apply_changes) "APPLY" else "READ-ONLY PREVIEW", "\n")
cat("Found", length(new_files), "new file(s) in", new_data_folder, "\n")
cat("Loading master:", master_path, "...\n")
master <- readRDS(master_path)
master <- as.data.frame(master)
digikat_require_columns(master, c("FULL_TEXT", dedup_key, "DATE", "year"), "master")
master_rows_before <- nrow(master)
cat("  Master rows:", master_rows_before, "| columns:", ncol(master), "\n")

religious_terms <- digikat_load_religious_terms(terms_path)

read_one_xlsx <- function(path) {
  result <- as.data.frame(readxl::read_excel(path), stringsAsFactors = FALSE)
  result$.ingest_file <- basename(path)
  result
}

cat("Reading XLSX batch...\n")
new_parts <- lapply(new_files, read_one_xlsx)
new_data <- dplyr::bind_rows(new_parts)
rm(new_parts)
cat("  Incoming rows:", nrow(new_data), "| columns:", ncol(new_data), "\n")

digikat_require_columns(new_data, c("FULL_TEXT", "DATE"), "incoming batch")
if (!dedup_key %in% names(new_data) && !allow_missing_dedup) {
  stop(
    "Incoming batch has no ", dedup_key, " column. Refusing to append without deduplication.",
    "\nUse --allow-missing-dedup-key only after a documented manual review.",
    call. = FALSE
  )
}

new_data$FULL_TEXT <- as.character(new_data$FULL_TEXT)
if (all(is.na(new_data$FULL_TEXT) | !nzchar(trimws(new_data$FULL_TEXT)))) {
  stop("FULL_TEXT is entirely empty/NA; check the input sheet and column types.", call. = FALSE)
}

diacritic_class <- "[čćžšđČĆŽŠĐ]"
if (!any(stringi::stri_detect_regex(new_data$FULL_TEXT, diacritic_class), na.rm = TRUE)) {
  stop(
    "No Croatian diacritics were found anywhere in FULL_TEXT. ",
    "Check the input encoding before continuing.",
    call. = FALSE
  )
}

incoming_date <- digikat_parse_date(new_data$DATE, name = "incoming DATE")
incoming_year <- as.integer(format(incoming_date, "%Y"))
year_mismatches <- integer()
if ("year" %in% names(new_data)) {
  upstream_year <- suppressWarnings(as.integer(as.character(new_data$year)))
  year_mismatches <- which(
    !is.na(upstream_year) & !is.na(incoming_year) & upstream_year != incoming_year
  )
}
new_data$DATE <- if (inherits(master$DATE, "Date")) incoming_date else as.character(incoming_date)
new_data$year <- incoming_year
if (length(year_mismatches)) {
  cat(
    "  Normalized", length(year_mismatches),
    "incoming year value(s) to the year derived from DATE.\n"
  )
}

missing_from_incoming <- setdiff(names(master), names(new_data))
extra_in_incoming <- setdiff(names(new_data), c(names(master), ".ingest_file"))
if (length(missing_from_incoming)) {
  cat(
    "  Master columns absent from incoming data will be NA:",
    paste(missing_from_incoming, collapse = ", "), "\n"
  )
}
if (length(extra_in_incoming)) {
  cat(
    "  Incoming columns not present in the master will be reported but not appended:",
    paste(extra_in_incoming, collapse = ", "), "\n"
  )
}

cat("Applying the religious filter (>= ", min_matches, " distinct terms)...\n", sep = "")
match_details <- digikat_match_religious(
  new_data$FULL_TEXT,
  religious_terms,
  min_matches = min_matches,
  include_details = TRUE,
  batch_size = batch_size,
  progress = TRUE
)
new_data <- dplyr::bind_cols(new_data, match_details)
passes_filter <- new_data$root_match_count >= min_matches
new_filtered <- new_data[passes_filter, , drop = FALSE]
new_filtered$data_source <- "filtered_religious"
cat(
  "  Passed:", nrow(new_filtered), "of", nrow(new_data),
  sprintf("(%.1f%%)\n", 100 * nrow(new_filtered) / max(1L, nrow(new_data)))
)

get_master_keys <- function() {
  signature <- list(
    path = digikat_normalize_path(master_path),
    bytes = unname(file.info(master_path)$size),
    modified = format(file.info(master_path)$mtime, tz = "UTC", usetz = TRUE)
  )
  if (file.exists(cache_path)) {
    cache <- tryCatch(readRDS(cache_path), error = function(e) NULL)
    if (is.list(cache) && identical(cache$signature, signature) && is.character(cache$keys)) {
      cat("Using cached master URL keys:", cache_path, "\n")
      return(cache$keys)
    }
  }
  cat("Canonicalizing master URLs (first run may take a while)...\n")
  keys <- unique(digikat_canonicalize_url(master[[dedup_key]]))
  dir.create(dirname(cache_path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(list(signature = signature, keys = keys), cache_path)
  keys
}

dedup_already_master <- 0L
dedup_inside_batch <- 0L
unkeyed_rows <- 0L
if (dedup_key %in% names(master) && dedup_key %in% names(new_filtered)) {
  existing_keys <- get_master_keys()
  new_keys <- digikat_canonicalize_url(new_filtered[[dedup_key]])
  has_key <- !is.na(new_keys) & nzchar(new_keys)
  in_master <- has_key & new_keys %in% existing_keys
  in_batch <- has_key & duplicated(new_keys)
  drop_rows <- in_master | in_batch
  dedup_already_master <- sum(in_master)
  dedup_inside_batch <- sum(in_batch)
  unkeyed_rows <- sum(!has_key)
  new_to_bind <- new_filtered[!drop_rows, , drop = FALSE]
} else {
  warning("Deduplication was explicitly bypassed; all qualifying rows will remain.")
  new_to_bind <- new_filtered
  unkeyed_rows <- nrow(new_to_bind)
}

rows_to_append <- nrow(new_to_bind)
cat(
  "Deduplication: ", dedup_already_master, " already in master; ",
  dedup_inside_batch, " repeated inside batch; ",
  rows_to_append, " rows remain.\n",
  sep = ""
)

file_reports <- lapply(new_files, function(path) digikat_file_metadata(path, include_hash = TRUE))
report <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  mode = if (apply_changes) "apply" else "preview",
  inclusion_rule = list(minimum_distinct_religious_terms = min_matches),
  paths = list(
    master = gsub("\\\\", "/", master_path),
    incoming_directory = gsub("\\\\", "/", new_data_folder)
  ),
  input_files = file_reports,
  columns = list(
    missing_from_incoming = missing_from_incoming,
    excluded_incoming_columns = extra_in_incoming
  ),
  rows = list(
    master_before = master_rows_before,
    incoming_read = nrow(new_data),
    passed_religious_filter = nrow(new_filtered),
    normalized_year_mismatches = length(year_mismatches),
    already_in_master = dedup_already_master,
    repeated_inside_batch = dedup_inside_batch,
    without_usable_dedup_key = unkeyed_rows,
    proposed_append = rows_to_append,
    proposed_master_after = master_rows_before + rows_to_append
  )
)

if (!apply_changes || rows_to_append == 0L) {
  report$result <- if (rows_to_append == 0L) "nothing_to_append" else "preview_complete"
  digikat_write_json_atomic(report, report_path)
  cat("Wrote delta report:", report_path, "\n")
  if (!apply_changes && rows_to_append > 0L) {
    cat("No protected data changed. Review the report, then rerun with --apply.\n")
  }
  quit(save = "no", status = 0L)
}

# Align exactly to the protected master schema. Filtering details remain in the
# delta report; the scientific master schema does not drift during an append.
for (missing_name in setdiff(names(master), names(new_to_bind))) {
  new_to_bind[[missing_name]] <- NA
}
new_to_bind <- new_to_bind[, names(master), drop = FALSE]

backup_path <- sub("\\.rds$", paste0("_backup_", stamp, ".rds"), master_path)
if (identical(backup_path, master_path)) backup_path <- paste0(master_path, "_backup_", stamp, ".rds")
if (file.exists(backup_path)) stop("Backup already exists: ", backup_path, call. = FALSE)

cat("Creating verified backup:", backup_path, "\n")
if (!isTRUE(file.copy(master_path, backup_path, overwrite = FALSE))) {
  stop("Could not create the master backup.", call. = FALSE)
}
master_hash <- digikat_hash_file(master_path)
backup_hash <- digikat_hash_file(backup_path)
if (!identical(master_hash, backup_hash)) {
  stop("Backup hash does not match the master; aborting before replacement.", call. = FALSE)
}

updated <- dplyr::bind_rows(master, new_to_bind)
expected_rows <- master_rows_before + rows_to_append
validate_updated <- function(value) {
  if (nrow(value) != expected_rows) stop("Staged master has an unexpected row count.")
  if (!identical(names(value), names(master))) stop("Staged master schema differs from the original.")
  tail_rows <- utils::tail(value, rows_to_append)
  tail_dates <- digikat_parse_date(tail_rows$DATE, name = "staged appended DATE")
  tail_year <- as.integer(format(tail_dates, "%Y"))
  if (any(tail_year != as.integer(tail_rows$year), na.rm = TRUE)) {
    stop("Staged appended rows contain DATE/year mismatches.")
  }
  invisible(TRUE)
}

cat("Staging and validating updated master...\n")
staged <- digikat_stage_rds(updated, master_path, validate = validate_updated)
digikat_atomic_replace_file(staged, master_path)
if (file.exists(cache_path)) unlink(cache_path)

report$result <- "applied"
report$backup <- c(digikat_file_metadata(backup_path, include_hash = FALSE), sha256 = backup_hash)
report$master_after <- digikat_file_metadata(master_path, include_hash = TRUE)
digikat_write_json_atomic(report, report_path)

cat("\nAppend complete.\n")
cat("  Master rows before:", master_rows_before, "\n")
cat("  Rows appended:     ", rows_to_append, "\n")
cat("  Master rows after: ", expected_rows, "\n")
cat("  Backup:            ", backup_path, "\n")
cat("  Delta report:       ", report_path, "\n")
cat("\nNEXT: validate and apply R/03_aggregate.R, rebuild invalidated NLP outputs, then render the site.\n")
