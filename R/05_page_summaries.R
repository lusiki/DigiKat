#!/usr/bin/env Rscript
# Build or validate compact, disclosure-safe inputs for the three NLP pages.
#
# Validate current production summaries:
#   Rscript R/05_page_summaries.R
#
# Build and atomically install production summaries:
#   Rscript R/05_page_summaries.R --build
#
# Build into an empty comparison directory:
#   Rscript R/05_page_summaries.R --build --nlp-dir=PATH --output-dir=PATH

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
})
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/thematic_dictionaries.R", encoding = "UTF-8")
source("R/lib/page_summaries.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat(paste(
    "Usage: Rscript R/05_page_summaries.R [--build]",
    "       [--nlp-dir=PATH] [--output-dir=PATH]",
    "",
    "No --build flag means read-only validation.",
    sep = "\n"
  ))
  quit(save = "no", status = 0L)
}

build <- digikat_cli_flag(args, "--build")
output_dir <- digikat_cli_value(args, "--output-dir", "data/page-ready")
production_dir <- "data/page-ready"
is_production <- digikat_same_path(output_dir, production_dir)
nlp_dir <- digikat_cli_value(args, "--nlp-dir", "data/nlp")
allow_empty <- !digikat_same_path(nlp_dir, "data/nlp")
manifest_path <- file.path(output_dir, "manifest.json")
pages <- c("mapa_stats", "diskurs", "dogadjaji")

input_paths <- c(
  "R/lib/thematic_dictionaries.R",
  "R/lib/page_summaries.R",
  "resources/lexicons/crosentilex-negatives.txt",
  "resources/lexicons/crosentilex-positives.txt",
  "resources/lexicons/gs-sentiment-annotations.txt",
  "resources/dictionaries/lilaHR_clean.xlsx",
  file.path(nlp_dir, "manifest.json"),
  unlist(lapply(
    pages,
    function(page) file.path(nlp_dir, paste0(page, c("_sample.rds", "_tokens.rds")))
  ))
)
if (any(!file.exists(input_paths))) {
  stop("Missing page-summary input(s): ", paste(input_paths[!file.exists(input_paths)], collapse = ", "), call. = FALSE)
}

current_inputs <- function() {
  stats::setNames(
    lapply(input_paths, digikat_file_metadata, include_hash = TRUE),
    gsub("\\\\", "/", input_paths)
  )
}

validate_generation <- function(directory, require_manifest = TRUE) {
  if (require_manifest && !file.exists(file.path(directory, "manifest.json"))) {
    stop("Missing page-summary manifest: ", file.path(directory, "manifest.json"), call. = FALSE)
  }
  results <- list()
  for (page in pages) {
    path <- file.path(directory, paste0(page, ".rds"))
    if (!file.exists(path)) stop("Missing page summary: ", path, call. = FALSE)
    summary <- readRDS(path)
    digikat_validate_page_summary(summary, page, allow_empty = allow_empty)
    results[[page]] <- list(
      bytes = unname(file.info(path)$size),
      sha256 = digikat_hash_file(path),
      object_rows = vapply(summary$objects, nrow, integer(1L)),
      object_hashes = vapply(summary$objects, digikat_hash_object, character(1L))
    )
  }
  if (require_manifest) {
    manifest <- jsonlite::read_json(file.path(directory, "manifest.json"), simplifyVector = FALSE)
    inputs <- current_inputs()
    for (path in names(inputs)) {
      if (!identical(manifest$inputs[[path]]$sha256, inputs[[path]]$sha256)) {
        stop("Page-summary manifest is stale for input: ", path, call. = FALSE)
      }
    }
    for (page in pages) {
      if (!identical(manifest$pages[[page]]$sha256, results[[page]]$sha256)) {
        stop("Page-summary output hash mismatch: ", page, call. = FALSE)
      }
    }
  }
  results
}

if (!build) {
  results <- validate_generation(output_dir)
  cat("Page-ready summary validation passed for", length(results), "pages.\n")
  for (page in pages) {
    cat(sprintf("  %-12s %s bytes\n", page, format(results[[page]]$bytes, big.mark = ",")))
  }
  quit(save = "no", status = 0L)
}

if (is_production) {
  build_dir <- file.path("data", paste0(".page-ready-stage-", Sys.getpid()))
  if (dir.exists(build_dir)) stop("Page-summary staging directory already exists.", call. = FALSE)
} else {
  build_dir <- output_dir
  if (dir.exists(build_dir) && length(list.files(build_dir, all.files = TRUE, no.. = TRUE))) {
    stop("Custom output directory must be empty or absent: ", build_dir, call. = FALSE)
  }
}
dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)

lexicons <- digikat_load_atmosphere_lexicons(".")
builders <- list(
  mapa_stats = function(sample, tokens) {
    digikat_build_mapa_stats_summary(sample, tokens, digikat_thematic_dictionaries)
  },
  diskurs = function(sample, tokens) {
    digikat_build_diskurs_summary(sample, tokens, digikat_thematic_dictionaries, lexicons)
  },
  dogadjaji = function(sample, tokens) {
    digikat_build_dogadjaji_summary(sample, tokens, digikat_thematic_dictionaries, lexicons)
  }
)

for (page in pages) {
  cat("Building page-ready summary:", page, "\n")
  sample <- readRDS(file.path(nlp_dir, paste0(page, "_sample.rds")))
  tokens <- readRDS(file.path(nlp_dir, paste0(page, "_tokens.rds")))
  objects <- builders[[page]](sample, tokens)
  summary <- list(schema_version = 1L, page = page, objects = objects)
  digikat_validate_page_summary(summary, page, allow_empty = allow_empty)
  staged <- digikat_stage_rds(
    summary,
    file.path(build_dir, paste0(page, ".rds")),
    validate = function(value) {
      digikat_validate_page_summary(value, page, allow_empty = allow_empty)
    },
    compress = TRUE
  )
  if (!file.rename(staged, file.path(build_dir, paste0(page, ".rds")))) {
    stop("Could not install staged page summary for ", page, ".", call. = FALSE)
  }
  rm(sample, tokens, objects, summary)
  gc()
}

results <- validate_generation(build_dir, require_manifest = FALSE)
manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "R/05_page_summaries.R",
  disclosure = "aggregate plot and table inputs only; no text, title, URL, or row-level record",
  inputs = current_inputs(),
  pages = results
)
digikat_write_json_atomic(manifest, file.path(build_dir, "manifest.json"))
invisible(validate_generation(build_dir))

if (!is_production) {
  cat("Page-ready summary build passed:", build_dir, "\n")
  quit(save = "no", status = 0L)
}

stamp <- format(Sys.time(), "%Y%m%d_%H%M%S", tz = "UTC")
previous_dir <- file.path("data", "private", "page-ready-backups", stamp)
dir.create(dirname(previous_dir), recursive = TRUE, showWarnings = FALSE)
if (dir.exists(production_dir) && !file.rename(production_dir, previous_dir)) {
  stop("Could not retain previous page-ready generation at: ", previous_dir, call. = FALSE)
}
if (!file.rename(build_dir, production_dir)) {
  if (dir.exists(previous_dir)) file.rename(previous_dir, production_dir)
  stop("Could not install page-ready generation; previous generation restored.", call. = FALSE)
}
cat("Page-ready generation installed:", production_dir, "\n")
if (dir.exists(previous_dir)) cat("Previous generation retained at:", previous_dir, "\n")
