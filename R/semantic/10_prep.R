#!/usr/bin/env Rscript
# Prepare a lean, fingerprinted corpus for semantic embedding.
#
# Full protected corpus:
#   Rscript R/semantic/10_prep.R
#
# Synthetic smoke fixture:
#   Rscript R/semantic/10_prep.R --sample --output=PATH

suppressPackageStartupMessages({
  library(dplyr)
  library(here)
})
source("R/lib/digikat_utils.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat(paste(
    "Usage: Rscript R/semantic/10_prep.R [--sample] [--input=PATH] [--output=PATH]",
    "",
    "The sample is used only when --sample is explicit; there is no silent fallback.",
    sep = "\n"
  ))
  quit(save = "no", status = 0L)
}

use_sample <- digikat_cli_flag(args, "--sample")
default_input <- if (use_sample) {
  "data/sample/merged_sample.rds"
} else {
  Sys.getenv("DIGIKAT_MASTER_PATH", unset = "data/merged_comprehensive.rds")
}
input <- digikat_cli_value(args, "--input", default_input)
output <- digikat_cli_value(args, "--output", "data/semantic/corpus_prepared.rds")
manifest_path <- sub("\\.rds$", "_manifest.json", output)
if (identical(manifest_path, output)) manifest_path <- paste0(output, "_manifest.json")

if (!file.exists(input)) {
  stop(
    "Corpus not found: ", input,
    if (!use_sample) "\nUse --sample explicitly for the synthetic fixture." else "",
    call. = FALSE
  )
}

cat("Reading corpus:", input, if (use_sample) "(synthetic fixture)\n" else "(protected master)\n")
corpus <- readRDS(input)
if (inherits(corpus, "data.table")) {
  data.table::setDF(corpus)
} else {
  corpus <- as.data.frame(corpus)
}

column_map <- c(
  text = "FULL_TEXT",
  platform = "SOURCE_TYPE",
  date = "DATE",
  data_source = "data_source",
  actor = "FROM",
  url = "URL"
)
digikat_require_columns(corpus, column_map[c("text", "platform", "date")], "semantic input")
available <- column_map[column_map %in% names(corpus)]
lean <- as.data.frame(corpus[, available, drop = FALSE])
names(lean) <- names(available)
for (optional in setdiff(names(column_map), names(available))) lean[[optional]] <- NA_character_
rm(corpus)
invisible(gc())

input_rows <- nrow(lean)
lean$text <- trimws(as.character(lean$text))
lean$date <- digikat_parse_date(lean$date, name = "semantic DATE")
lean$platform <- as.character(lean$platform)
lean$data_source <- as.character(lean$data_source)
lean$actor <- as.character(lean$actor)
lean$url <- as.character(lean$url)

empty <- is.na(lean$text) | !nzchar(lean$text)
if (any(empty)) cat("Dropping", sum(empty), "row(s) with empty FULL_TEXT.\n")
lean <- lean[!empty, , drop = FALSE]

cat("Creating store-compatible semantic document IDs...\n")
# The production store was built with row-stable sequential IDs. The master is
# append-only and the preparation step preserves row order, so retaining this
# contract avoids a 710,307-document embedding rebuild after metadata-only
# master corrections. A future ID migration must rebuild the store explicitly.
doc_id <- sprintf("dk_%08d", seq_len(nrow(lean)))
if (anyDuplicated(doc_id)) stop("Stable semantic document IDs are not unique.", call. = FALSE)

lean$doc_id <- doc_id
lean <- lean[, c("doc_id", "platform", "date", "data_source", "actor", "url", "text")]

validate_prepared <- function(value) {
  digikat_require_columns(
    value,
    c("doc_id", "platform", "date", "data_source", "actor", "url", "text"),
    "prepared semantic corpus"
  )
  if (anyDuplicated(value$doc_id)) stop("Prepared semantic corpus has duplicate doc_id values.")
  if (any(is.na(value$text) | !nzchar(value$text))) stop("Prepared semantic corpus has empty text.")
  invisible(TRUE)
}
staged <- digikat_stage_rds(lean, output, validate = validate_prepared)
digikat_atomic_replace_file(staged, output)

manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "R/semantic/10_prep.R",
  synthetic_input = use_sample,
  input = digikat_file_metadata(input, include_hash = TRUE),
  output = c(
    digikat_file_metadata(output, include_hash = TRUE),
    list(rows = nrow(lean), columns = names(lean))
  ),
  transformation = list(
    input_rows = input_rows,
    dropped_empty_text_rows = sum(empty),
    document_id_algorithm = "dk_ + zero-padded 8-digit prepared-row number (append-only row-order contract)",
    field_map = as.list(column_map)
  )
)
digikat_write_json_atomic(manifest, manifest_path)

cat("Prepared semantic corpus:", nrow(lean), "rows x", ncol(lean), "columns ->", output, "\n")
cat("Manifest:", manifest_path, "\n")
cat("NEXT: Rscript R/semantic/11_build.R --build\n")
