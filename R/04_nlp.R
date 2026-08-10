#!/usr/bin/env Rscript
# Build or validate the per-page NLP sample/token generations.
#
# Input is data/digikat_corpus.rds — the official corpus, cut by one inclusion rule across both
# collection eras — not the accumulator. Pass --master=data/merged_comprehensive.rds to work from
# the accumulator instead.
#
# Safe validation (default):
#   Rscript R/04_nlp.R
#
# Adopt and fingerprint an older, internally valid generation:
#   Rscript R/04_nlp.R --adopt-existing
#
# Rebuild all outputs after an input change:
#   Rscript R/04_nlp.R --build
#
# A rebuild is staged and validated before the current data/nlp generation is
# moved into data/private/nlp-backups/.

suppressPackageStartupMessages(library(dplyr))
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/digikat_paths.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat(paste(
    "Usage: Rscript R/04_nlp.R [--build | --adopt-existing]",
    "       [--master=PATH] [--model=PATH] [--output-dir=PATH]",
    "",
    "No action flag means read-only validation.",
    sep = "\n"
  ))
  quit(save = "no", status = 0L)
}

build <- digikat_cli_flag(args, "--build")
adopt_existing <- digikat_cli_flag(args, "--adopt-existing")
if (build && adopt_existing) stop("Choose either --build or --adopt-existing.", call. = FALSE)

master_path <- digikat_cli_value(args, "--master", digikat_corpus_path())
model_path <- digikat_cli_value(
  args,
  "--model",
  "resources/models/croatian-set-ud-2.5-191206.udpipe"
)
nlp_dir <- digikat_cli_value(args, "--output-dir", "data/nlp")
production_dir <- "data/nlp"
is_production <- digikat_same_path(nlp_dir, production_dir)
manifest_path <- file.path(nlp_dir, "manifest.json")
seed <- 123L
page_specs <- list(
  mapa_stats = list(proportion = 0.05),
  dogadjaji = list(proportion = 0.03),
  diskurs = list(proportion = 0.02)
)

if (!file.exists(master_path)) stop("Master not found: ", master_path, call. = FALSE)
if (!file.exists(model_path)) stop("UDPIPE model not found: ", model_path, call. = FALSE)

input_metadata <- function(include_hash = TRUE) {
  list(
    master = digikat_file_metadata(master_path, include_hash = include_hash),
    model = digikat_file_metadata(model_path, include_hash = include_hash)
  )
}

validate_pair <- function(directory, label, require_master_membership = FALSE, master_urls = NULL) {
  sample_path <- file.path(directory, paste0(label, "_sample.rds"))
  token_path <- file.path(directory, paste0(label, "_tokens.rds"))
  if (!file.exists(sample_path) || !file.exists(token_path)) {
    stop("Missing NLP pair for ", label, ": ", sample_path, " / ", token_path, call. = FALSE)
  }
  sample <- as.data.frame(readRDS(sample_path))
  tokens <- as.data.frame(readRDS(token_path))
  digikat_require_columns(sample, c("doc_id", "FULL_TEXT", "DATE", "SOURCE_TYPE"), paste(label, " sample"))
  digikat_require_columns(tokens, c("doc_id", "token", "lemma", "upos"), paste(label, " tokens"))

  if (anyDuplicated(sample$doc_id)) stop(label, " sample has duplicate doc_id values.", call. = FALSE)
  token_ids <- unique(as.integer(tokens$doc_id))
  sample_ids <- as.integer(sample$doc_id)
  missing_tokens <- setdiff(sample_ids, token_ids)
  orphan_tokens <- setdiff(token_ids, sample_ids)
  if (length(missing_tokens) || length(orphan_tokens)) {
    stop(
      label, " sample/token IDs do not align (missing token docs: ", length(missing_tokens),
      "; orphan token docs: ", length(orphan_tokens), ").",
      call. = FALSE
    )
  }

  if (isTRUE(require_master_membership)) {
    digikat_require_columns(sample, "URL", paste(label, " sample"))
    usable <- !is.na(sample$URL) & nzchar(sample$URL)
    absent <- usable & !sample$URL %in% master_urls
    if (any(absent)) {
      stop(label, " contains ", sum(absent), " URL(s) absent from the current master.", call. = FALSE)
    }
  }

  list(
    sample_rows = nrow(sample),
    token_rows = nrow(tokens),
    token_documents = length(token_ids),
    date_min = format(min(digikat_parse_date(sample$DATE), na.rm = TRUE)),
    date_max = format(max(digikat_parse_date(sample$DATE), na.rm = TRUE)),
    sample_sha256 = digikat_hash_file(sample_path),
    tokens_sha256 = digikat_hash_file(token_path)
  )
}

validate_manifest <- function() {
  if (!file.exists(manifest_path)) {
    stop(
      "NLP outputs have no manifest. Run --adopt-existing after reviewing them, or --build to regenerate.",
      call. = FALSE
    )
  }
  manifest <- jsonlite::read_json(manifest_path, simplifyVector = FALSE)
  current_inputs <- input_metadata(include_hash = TRUE)
  if (!identical(manifest$inputs$master$sha256, current_inputs$master$sha256)) {
    stop("NLP manifest is stale: master fingerprint changed.", call. = FALSE)
  }
  if (!identical(manifest$inputs$model$sha256, current_inputs$model$sha256)) {
    stop("NLP manifest is stale: UDPIPE model fingerprint changed.", call. = FALSE)
  }

  results <- lapply(names(page_specs), function(label) validate_pair(nlp_dir, label))
  names(results) <- names(page_specs)
  for (label in names(results)) {
    recorded <- manifest$pages[[label]]
    current <- results[[label]]
    if (!identical(recorded$sample_sha256, current$sample_sha256) ||
        !identical(recorded$tokens_sha256, current$tokens_sha256)) {
      stop("NLP manifest is stale: output fingerprint changed for ", label, ".", call. = FALSE)
    }
  }
  cat("NLP validation passed for", length(results), "page generations.\n")
  for (label in names(results)) {
    cat(
      sprintf(
        "  %-12s %d sample rows | %d token rows | %d documents\n",
        label,
        results[[label]]$sample_rows,
        results[[label]]$token_rows,
        results[[label]]$token_documents
      )
    )
  }
  invisible(results)
}

if (!build && !adopt_existing) {
  validate_manifest()
  quit(save = "no", status = 0L)
}

if (adopt_existing) {
  if (!is_production) stop("--adopt-existing is only supported for data/nlp.", call. = FALSE)
  cat("Reading master URL keys for adoption validation...\n")
  master_urls <- as.data.frame(readRDS(master_path))$URL
  if (is.null(master_urls)) stop("Master has no URL column.", call. = FALSE)
  page_results <- lapply(
    names(page_specs),
    function(label) validate_pair(
      nlp_dir,
      label,
      require_master_membership = TRUE,
      master_urls = master_urls
    )
  )
  names(page_results) <- names(page_specs)
  manifest <- list(
    schema_version = 1L,
    generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    generator = "R/04_nlp.R",
    provenance = "adopted_existing_after_membership_and_alignment_validation",
    inputs = input_metadata(include_hash = TRUE),
    parameters = list(
      seed = seed,
      date_min = "2021-01-01",
      date_max = "2026-12-31",
      excluded_source_types = list("tiktok"),
      minimum_text_characters = 101L,
      strata = list("year", "SOURCE_TYPE"),
      page_proportions = lapply(page_specs, `[[`, "proportion")
    ),
    pages = page_results
  )
  digikat_write_json_atomic(manifest, manifest_path)
  cat("Adopted and fingerprinted the existing NLP generation:", manifest_path, "\n")
  quit(save = "no", status = 0L)
}

if (!requireNamespace("udpipe", quietly = TRUE)) {
  stop("Package 'udpipe' is required for --build.", call. = FALSE)
}

if (is_production) {
  build_dir <- file.path("data", paste0(".nlp-stage-", Sys.getpid()))
  if (dir.exists(build_dir)) stop("NLP staging directory already exists: ", build_dir, call. = FALSE)
} else {
  build_dir <- nlp_dir
  if (dir.exists(build_dir) && length(list.files(build_dir, all.files = TRUE, no.. = TRUE))) {
    stop("Custom NLP output directory must be empty or absent.", call. = FALSE)
  }
}
dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)

cat("Reading and normalizing master...\n")
base <- as.data.frame(readRDS(master_path))
digikat_require_columns(base, c("DATE", "SOURCE_TYPE", "FULL_TEXT"), "master")
base$DATE <- digikat_parse_date(base$DATE, name = "master DATE", allow_missing = FALSE)
base$year <- as.integer(format(base$DATE, "%Y"))
base <- base |>
  filter(
    !is.na(SOURCE_TYPE),
    SOURCE_TYPE != "tiktok",
    DATE >= as.Date("2021-01-01"),
    DATE <= as.Date("2026-12-31"),
    !is.na(FULL_TEXT),
    nchar(FULL_TEXT) > 100
  )
cat("  Eligible rows:", nrow(base), "\n")

cat("Loading UDPIPE model...\n")
model <- udpipe::udpipe_load_model(model_path)
page_results <- list()
for (label in names(page_specs)) {
  proportion <- page_specs[[label]]$proportion
  set.seed(seed)
  sample <- base |>
    group_by(year, SOURCE_TYPE) |>
    slice_sample(prop = proportion) |>
    ungroup() |>
    mutate(doc_id = row_number())

  sample_path <- file.path(build_dir, paste0(label, "_sample.rds"))
  token_path <- file.path(build_dir, paste0(label, "_tokens.rds"))
  saveRDS(sample, sample_path)
  cat(sprintf("  [%s] annotating %d documents...\n", label, nrow(sample)))
  annotation <- udpipe::udpipe_annotate(
    model,
    x = sample$FULL_TEXT,
    doc_id = as.character(sample$doc_id),
    tagger = "default",
    parser = "none"
  )
  tokens <- as.data.frame(annotation) |>
    transmute(doc_id = as.integer(doc_id), token, lemma, upos)
  saveRDS(tokens, token_path)
  page_results[[label]] <- validate_pair(build_dir, label)
}

manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "R/04_nlp.R",
  provenance = "generated",
  inputs = input_metadata(include_hash = TRUE),
  parameters = list(
    seed = seed,
    date_min = "2021-01-01",
    date_max = "2026-12-31",
    excluded_source_types = list("tiktok"),
    minimum_text_characters = 101L,
    strata = list("year", "SOURCE_TYPE"),
    page_proportions = lapply(page_specs, `[[`, "proportion")
  ),
  pages = page_results
)
digikat_write_json_atomic(manifest, file.path(build_dir, "manifest.json"))

if (!is_production) {
  cat("NLP build and validation passed:", build_dir, "\n")
  quit(save = "no", status = 0L)
}

stamp <- format(Sys.time(), "%Y%m%d_%H%M%S", tz = "UTC")
previous_dir <- file.path("data", "private", "nlp-backups", stamp)
dir.create(dirname(previous_dir), recursive = TRUE, showWarnings = FALSE)
if (dir.exists(previous_dir)) stop("NLP backup directory already exists: ", previous_dir, call. = FALSE)
if (dir.exists(production_dir) && !file.rename(production_dir, previous_dir)) {
  stop("Could not retain the previous NLP generation at: ", previous_dir, call. = FALSE)
}
if (!file.rename(build_dir, production_dir)) {
  if (dir.exists(previous_dir)) file.rename(previous_dir, production_dir)
  stop("Could not install staged NLP generation; previous generation restored.", call. = FALSE)
}
cat("NLP generation installed. Previous generation retained at:", previous_dir, "\n")
