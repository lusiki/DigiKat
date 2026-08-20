#!/usr/bin/env Rscript

# Build the private 15% text sample used by the standalone
# "Kako se govori o Crkvi" exploration.
#
# The official corpus is read-only. The sample, tokens and manifest are written
# only to the requested exploration-local or temporary output directory.
#
# From the repository root:
#   Rscript explorations/okvir-katolicanstva-prototype/build-15pct-nlp.R
#   Rscript explorations/okvir-katolicanstva-prototype/build-15pct-nlp.R \
#     --output-dir=C:/path/outside/Dropbox/okvir-15pct-nlp
# To resume from an already-built deterministic sample:
#   Rscript explorations/okvir-katolicanstva-prototype/build-15pct-nlp.R \
#     --sample=C:/path/sample.rds --eligible-rows=413604 --output-dir=C:/path/new-output

options(stringsAsFactors = FALSE, encoding = "UTF-8", width = 160)
Sys.setenv(TZ = "Europe/Zagreb")

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(udpipe)
})

source(file.path("R", "lib", "digikat_utils.R"), encoding = "UTF-8")
source(file.path("R", "lib", "digikat_paths.R"), encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat(paste(
    "Usage: Rscript explorations/okvir-katolicanstva-prototype/build-15pct-nlp.R",
    "       [--output-dir=PATH] [--model=PATH]",
    "       [--sample=PATH --eligible-rows=N]",
    "",
    "Builds a deterministic 15% year x platform sample and its Croatian UDPipe token layer.",
    sep = "\n"
  ))
  quit(save = "no", status = 0L)
}

analysis_dir <- file.path("explorations", "okvir-katolicanstva-prototype")
output_dir <- digikat_cli_value(
  args,
  "--output-dir",
  file.path(analysis_dir, "output", "nlp-15pct")
)
model_path <- digikat_cli_value(
  args,
  "--model",
  file.path("resources", "models", "croatian-set-ud-2.5-191206.udpipe")
)
corpus_path <- digikat_corpus_path()
input_sample_path <- digikat_cli_value(args, "--sample", NULL)
input_eligible_rows <- digikat_cli_value(args, "--eligible-rows", NULL)
sample_path <- file.path(output_dir, "sample.rds")
tokens_path <- file.path(output_dir, "tokens.rds")
manifest_path <- file.path(output_dir, "manifest.json")

PROPORTION <- 0.15
SEED <- 123L
MIN_TEXT_CHARACTERS <- 101L
BATCH_SIZE <- 2500L

say <- function(...) {
  cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n")
  flush.console()
}

validate_generation <- function(directory, check_hashes = TRUE) {
  paths <- file.path(directory, c("sample.rds", "tokens.rds", "manifest.json"))
  if (!all(file.exists(paths))) {
    stop("Incomplete 15% NLP generation in: ", directory, call. = FALSE)
  }

  sample <- as.data.table(readRDS(paths[[1L]]))
  tokens <- as.data.table(readRDS(paths[[2L]]))
  required_sample <- c("doc_id", "DATE", "SOURCE_TYPE", "FROM", "TITLE", "FULL_TEXT")
  required_tokens <- c("doc_id", "token", "lemma", "upos")
  missing_sample <- setdiff(required_sample, names(sample))
  missing_tokens <- setdiff(required_tokens, names(tokens))
  if (length(missing_sample)) stop("Sample lacks: ", paste(missing_sample, collapse = ", "), call. = FALSE)
  if (length(missing_tokens)) stop("Tokens lack: ", paste(missing_tokens, collapse = ", "), call. = FALSE)
  if (anyDuplicated(sample$doc_id)) stop("Sample doc_id values are not unique.", call. = FALSE)

  sample_ids <- as.integer(sample$doc_id)
  token_ids <- unique(as.integer(tokens$doc_id))
  if (length(setdiff(sample_ids, token_ids)) || length(setdiff(token_ids, sample_ids))) {
    stop("Sample and token document IDs do not align.", call. = FALSE)
  }

  manifest <- jsonlite::read_json(paths[[3L]], simplifyVector = TRUE)
  if (!isTRUE(all.equal(as.numeric(manifest$parameters$proportion), PROPORTION))) {
    stop("Manifest does not describe a 15% sample.", call. = FALSE)
  }
  if (!identical(as.integer(manifest$sample$rows), nrow(sample))) {
    stop("Manifest sample row count is stale.", call. = FALSE)
  }
  if (!identical(as.integer(manifest$tokens$rows), nrow(tokens))) {
    stop("Manifest token row count is stale.", call. = FALSE)
  }
  if (isTRUE(check_hashes)) {
    if (!identical(manifest$sample$sha256, digikat_hash_file(paths[[1L]]))) {
      stop("Sample fingerprint is stale.", call. = FALSE)
    }
    if (!identical(manifest$tokens$sha256, digikat_hash_file(paths[[2L]]))) {
      stop("Token fingerprint is stale.", call. = FALSE)
    }
  }
  list(sample_rows = nrow(sample), token_rows = nrow(tokens), token_documents = length(token_ids))
}

if (!file.exists(corpus_path)) stop("DigiKat corpus not found: ", corpus_path, call. = FALSE)
if (!file.exists(model_path)) stop("Croatian UDPipe model not found: ", model_path, call. = FALSE)

if (dir.exists(output_dir) && length(list.files(output_dir, all.files = TRUE, no.. = TRUE))) {
  say("Validating existing generation", output_dir)
  validation <- validate_generation(output_dir)
  say(
    "Validation passed:", validation$sample_rows, "sample rows |",
    validation$token_rows, "token rows |", validation$token_documents, "documents"
  )
  quit(save = "no", status = 0L)
}

stage_dir <- paste0(output_dir, ".stage-", Sys.getpid())
if (dir.exists(stage_dir)) stop("Staging directory already exists: ", stage_dir, call. = FALSE)
dir.create(stage_dir, recursive = TRUE, showWarnings = FALSE)

required <- c("DATE", "SOURCE_TYPE", "FROM", "INTERACTIONS", "TITLE", "FULL_TEXT")
if (!is.null(input_sample_path)) {
  if (!file.exists(input_sample_path)) stop("Input sample not found: ", input_sample_path, call. = FALSE)
  if (is.null(input_eligible_rows)) {
    stop("--eligible-rows=N is required with --sample so the realized sampling rate can be checked.", call. = FALSE)
  }
  eligible_rows <- as.integer(input_eligible_rows)
  if (!is.finite(eligible_rows) || eligible_rows < 1L) stop("--eligible-rows must be a positive integer.", call. = FALSE)
  say("Reading the existing deterministic 15% sample")
  sample <- as.data.frame(readRDS(input_sample_path))
  missing_required <- setdiff(c(required, "doc_id"), names(sample))
  if (length(missing_required)) stop("Input sample lacks: ", paste(missing_required, collapse = ", "), call. = FALSE)
  if (anyDuplicated(sample$doc_id)) stop("Input sample doc_id values are not unique.", call. = FALSE)
  realized <- nrow(sample) / eligible_rows
  if (abs(realized - PROPORTION) > 0.001) {
    stop("Input sample rate is ", sprintf("%.4f", realized), ", not the required 15% design.", call. = FALSE)
  }
} else {
  say("Reading the official corpus (read-only)")
  base <- as.data.frame(readRDS(corpus_path))
  missing_required <- setdiff(required, names(base))
  if (length(missing_required)) stop("Corpus lacks: ", paste(missing_required, collapse = ", "), call. = FALSE)

  base$DATE <- digikat_parse_date(base$DATE, name = "corpus DATE", allow_missing = FALSE)
  base$year <- as.integer(format(base$DATE, "%Y"))
  keep <- unique(c(required, intersect("URL", names(base)), "year"))
  base <- base |>
    filter(
      !is.na(SOURCE_TYPE),
      SOURCE_TYPE != "tiktok",
      DATE >= as.Date("2021-01-01"),
      DATE <= as.Date("2026-12-31"),
      !is.na(FULL_TEXT),
      nchar(FULL_TEXT) >= MIN_TEXT_CHARACTERS
    ) |>
    select(all_of(keep))
  eligible_rows <- nrow(base)
  say("Eligible rows:", eligible_rows)

  set.seed(SEED)
  sample <- base |>
    group_by(year, SOURCE_TYPE) |>
    slice_sample(prop = PROPORTION) |>
    ungroup() |>
    mutate(doc_id = row_number())
  rm(base)
  invisible(gc())
}

sample_out <- file.path(stage_dir, "sample.rds")
tokens_out <- file.path(stage_dir, "tokens.rds")
saveRDS(sample, sample_out)
say("Sampled", nrow(sample), "documents (", sprintf("%.3f", 100 * nrow(sample) / eligible_rows), "%)")

say("Loading Croatian UDPipe model")
model <- udpipe_load_model(model_path)
batch_starts <- seq.int(1L, nrow(sample), by = BATCH_SIZE)
token_parts <- file.path(stage_dir, sprintf("token-part-%03d.rds", seq_along(batch_starts)))
for (batch_index in seq_along(batch_starts)) {
  first <- batch_starts[[batch_index]]
  last <- min(first + BATCH_SIZE - 1L, nrow(sample))
  say("UDPipe batch", batch_index, "of", length(batch_starts), "| documents", first, "to", last)
  annotation <- udpipe_annotate(
    model,
    x = sample$FULL_TEXT[first:last],
    doc_id = as.character(sample$doc_id[first:last]),
    tagger = "default",
    parser = "none"
  )
  token_part <- as.data.table(as.data.frame(annotation))[, .(
    doc_id = as.integer(doc_id), token, lemma, upos
  )]
  saveRDS(token_part, token_parts[[batch_index]])
  rm(annotation, token_part)
  invisible(gc())
}

say("Combining and saving token batches")
tokens <- rbindlist(lapply(token_parts, readRDS), use.names = TRUE)
rm(model)
invisible(gc())
saveRDS(tokens, tokens_out)

sample_ids <- as.integer(sample$doc_id)
token_ids <- unique(as.integer(tokens$doc_id))
if (length(setdiff(sample_ids, token_ids)) || length(setdiff(token_ids, sample_ids))) {
  stop("Built sample and token document IDs do not align.", call. = FALSE)
}

say("Fingerprinting the completed generation")
manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "explorations/okvir-katolicanstva-prototype/build-15pct-nlp.R",
  input = list(
    corpus = digikat_file_metadata(corpus_path, include_hash = TRUE),
    model = digikat_file_metadata(model_path, include_hash = TRUE)
  ),
  parameters = list(
    proportion = PROPORTION,
    seed = SEED,
    date_min = "2021-01-01",
    date_max = "2026-12-31",
    excluded_source_types = list("tiktok"),
    minimum_text_characters = MIN_TEXT_CHARACTERS,
    strata = list("year", "SOURCE_TYPE"),
    batch_size = BATCH_SIZE,
    eligible_rows = eligible_rows
  ),
  sample = list(
    rows = nrow(sample),
    sha256 = digikat_hash_file(sample_out)
  ),
  tokens = list(
    rows = nrow(tokens),
    documents = length(token_ids),
    sha256 = digikat_hash_file(tokens_out)
  )
)
digikat_write_json_atomic(manifest, file.path(stage_dir, "manifest.json"))

rm(sample, tokens)
invisible(gc())
if (!file.rename(stage_dir, output_dir)) {
  stop("Could not install the validated generation at: ", output_dir, call. = FALSE)
}

validation <- validate_generation(output_dir)
say(
  "15% NLP generation complete:", validation$sample_rows, "sample rows |",
  validation$token_rows, "token rows |", validation$token_documents, "documents"
)
say("Output:", normalizePath(output_dir, winslash = "/", mustWork = TRUE))
