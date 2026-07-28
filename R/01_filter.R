#!/usr/bin/env Rscript
# Filter raw XLSX candidates with the canonical >=2 distinct-term rule.
#
# This stage never writes the master. Its output is a private staging RDS plus
# a provenance manifest.
#
# Usage:
#   Rscript R/01_filter.R
#   Rscript R/01_filter.R --raw-dir=PATH --output=PATH

suppressPackageStartupMessages({
  library(dplyr)
  library(readxl)
})
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat("Usage: Rscript R/01_filter.R [--raw-dir=PATH] [--output=PATH]\n")
  quit(save = "no", status = 0L)
}

raw_dir <- digikat_cli_value(args, "--raw-dir", "data/raw")
output <- digikat_cli_value(args, "--output", "data/private/staging/filtered_religious.rds")
manifest_path <- sub("\\.rds$", "_manifest.json", output)
if (identical(manifest_path, output)) manifest_path <- paste0(output, "_manifest.json")

if (!dir.exists(raw_dir)) stop("Raw-data directory not found: ", raw_dir, call. = FALSE)
files <- sort(list.files(raw_dir, pattern = "\\.xlsx$", full.names = TRUE))
if (!length(files)) stop("No XLSX files found directly under: ", raw_dir, call. = FALSE)

read_one <- function(path) {
  value <- as.data.frame(readxl::read_excel(path), stringsAsFactors = FALSE)
  value$.ingest_file <- basename(path)
  value
}
cat("Reading", length(files), "raw XLSX file(s)...\n")
data <- bind_rows(lapply(files, read_one))
digikat_require_columns(data, c("FULL_TEXT", "DATE", "URL"), "raw candidates")
data$FULL_TEXT <- as.character(data$FULL_TEXT)
data$DATE <- as.character(digikat_parse_date(data$DATE, name = "raw DATE"))
data$year <- as.integer(format(as.Date(data$DATE), "%Y"))

terms <- digikat_load_religious_terms()
matches <- digikat_match_religious(
  data$FULL_TEXT,
  terms,
  min_matches = 2L,
  include_details = TRUE,
  progress = TRUE
)
data <- bind_cols(data, matches)
filtered <- data[data$root_match_count >= 2L, , drop = FALSE]
filtered$data_source <- "filtered_religious"

validate <- function(value) {
  if (any(value$root_match_count < 2L)) stop("Filtered output violates the >=2-term rule.")
  digikat_require_columns(value, c("FULL_TEXT", "DATE", "year", "URL", "data_source"), "filtered output")
  invisible(TRUE)
}
staged <- digikat_stage_rds(filtered, output, validate = validate)
digikat_atomic_replace_file(staged, output)

manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "R/01_filter.R",
  inclusion_rule = list(minimum_distinct_religious_terms = 2L),
  input_files = lapply(files, digikat_file_metadata, include_hash = TRUE),
  rows = list(read = nrow(data), retained = nrow(filtered)),
  output = c(
    digikat_file_metadata(output, include_hash = TRUE),
    list(rows = nrow(filtered), columns = names(filtered))
  )
)
digikat_write_json_atomic(manifest, manifest_path)
cat("Filtered", nrow(filtered), "of", nrow(data), "rows ->", output, "\n")

