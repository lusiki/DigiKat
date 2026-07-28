#!/usr/bin/env Rscript
# Build and validate a candidate comprehensive corpus from two explicit inputs.
#
# This stage NEVER replaces data/merged_comprehensive.rds. A candidate must be
# reviewed, compared with the protected master, and installed through a
# separately confirmed operation.
#
# Usage:
#   Rscript R/02_merge.R --base=PATH --filtered=PATH [--output=PATH]

suppressPackageStartupMessages(library(dplyr))
source("R/lib/digikat_utils.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat(paste(
    "Usage: Rscript R/02_merge.R --base=PATH --filtered=PATH [--output=PATH]",
    "",
    "--base must be the reviewed original monitoring stream.",
    "--filtered is normally data/private/staging/filtered_religious.rds.",
    sep = "\n"
  ))
  quit(save = "no", status = 0L)
}

base_path <- digikat_cli_value(args, "--base")
filtered_path <- digikat_cli_value(args, "--filtered", "data/private/staging/filtered_religious.rds")
output <- digikat_cli_value(args, "--output", "data/private/staging/merged_candidate.rds")
if (is.null(base_path)) stop("--base=PATH is required; the original stream is not stored in this repository.", call. = FALSE)
if (!file.exists(base_path)) stop("Base stream not found: ", base_path, call. = FALSE)
if (!file.exists(filtered_path)) stop("Filtered stream not found: ", filtered_path, call. = FALSE)
if (digikat_same_path(output, "data/merged_comprehensive.rds")) {
  stop("R/02_merge.R may not write the protected master; choose a staging output.", call. = FALSE)
}

base <- as.data.frame(readRDS(base_path))
filtered <- as.data.frame(readRDS(filtered_path))
digikat_require_columns(base, c("DATE", "year", "URL", "FULL_TEXT"), "base stream")
digikat_require_columns(filtered, c("DATE", "year", "URL", "FULL_TEXT"), "filtered stream")

base$DATE <- as.character(digikat_parse_date(base$DATE, name = "base DATE"))
base$year <- as.integer(format(as.Date(base$DATE), "%Y"))
filtered$DATE <- as.character(digikat_parse_date(filtered$DATE, name = "filtered DATE"))
filtered$year <- as.integer(format(as.Date(filtered$DATE), "%Y"))
base$data_source <- "original_dta"
filtered$data_source <- "filtered_religious"

base_keys <- digikat_canonicalize_url(base$URL)
filtered_keys <- digikat_canonicalize_url(filtered$URL)
has_filtered_key <- !is.na(filtered_keys) & nzchar(filtered_keys)
duplicate_base <- has_filtered_key & filtered_keys %in% unique(base_keys)
duplicate_filtered <- has_filtered_key & duplicated(filtered_keys)
filtered_keep <- filtered[!(duplicate_base | duplicate_filtered), , drop = FALSE]

common_columns <- intersect(names(base), names(filtered_keep))
candidate <- bind_rows(
  base[, common_columns, drop = FALSE],
  filtered_keep[, common_columns, drop = FALSE]
)

validate <- function(value) {
  if (nrow(value) != nrow(base) + nrow(filtered_keep)) stop("Candidate row count is inconsistent.")
  if (!identical(names(value), common_columns)) stop("Candidate schema is inconsistent.")
  parsed <- digikat_parse_date(value$DATE, name = "candidate DATE")
  if (any(as.integer(format(parsed, "%Y")) != as.integer(value$year), na.rm = TRUE)) {
    stop("Candidate contains DATE/year mismatches.")
  }
  invisible(TRUE)
}
staged <- digikat_stage_rds(candidate, output, validate = validate)
digikat_atomic_replace_file(staged, output)

manifest_path <- sub("\\.rds$", "_manifest.json", output)
if (identical(manifest_path, output)) manifest_path <- paste0(output, "_manifest.json")
manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "R/02_merge.R",
  warning = "candidate_only_not_the_protected_master",
  inputs = list(
    base = digikat_file_metadata(base_path, include_hash = TRUE),
    filtered = digikat_file_metadata(filtered_path, include_hash = TRUE)
  ),
  rows = list(
    base = nrow(base),
    filtered_input = nrow(filtered),
    filtered_duplicate_of_base = sum(duplicate_base),
    filtered_duplicate_inside_stream = sum(duplicate_filtered),
    filtered_retained = nrow(filtered_keep),
    candidate = nrow(candidate)
  ),
  output = c(
    digikat_file_metadata(output, include_hash = TRUE),
    list(rows = nrow(candidate), columns = names(candidate))
  )
)
digikat_write_json_atomic(manifest, manifest_path)
cat("Wrote validated candidate corpus:", output, "\n")
cat("The protected master was not changed.\n")

