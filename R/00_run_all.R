#!/usr/bin/env Rscript
# Conservative DigiKat pipeline orchestrator.
#
# Default: validate setup, tests, aggregate reproducibility, NLP fingerprints,
# and semantic-store fingerprints without overwriting protected outputs.
#
# Synthetic smoke pipeline:
#   Rscript R/00_run_all.R --sample
#
# Start at a numbered stage:
#   Rscript R/00_run_all.R --from=03

source("R/lib/digikat_utils.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat(paste(
    "Usage: Rscript R/00_run_all.R [--sample] [--from=NN]",
    "",
    "This orchestrator is non-destructive. Production aggregate replacement,",
    "NLP rebuilds, master replacement, and full site renders retain their",
    "separate explicit gates.",
    sep = "\n"
  ))
  quit(save = "no", status = 0L)
}

use_sample <- digikat_cli_flag(args, "--sample")
from <- suppressWarnings(as.integer(digikat_cli_value(args, "--from", "0")))
if (is.na(from) || from < 0L) stop("--from must be a nonnegative stage number.", call. = FALSE)
rscript <- file.path(R.home("bin"), "Rscript")

run_step <- function(label, script, arguments = character()) {
  cat("\n==", label, "==\n")
  status <- system2(rscript, c(script, arguments))
  if (!identical(status, 0L)) stop("Pipeline step failed: ", label, call. = FALSE)
}

temporary_root <- tempfile("digikat-pipeline-smoke-")
if (use_sample) {
  dir.create(temporary_root, recursive = TRUE)
}

if (from <= 0L) run_step("00 setup", "R/00_setup.R")
if (from <= 0L && file.exists("tests/run_tests.R")) {
  run_step("automated tests", "tests/run_tests.R")
}
if (from <= 0L && file.exists("R/check_sources.R")) {
  run_step("source syntax and encoding", "R/check_sources.R")
}
if (from <= 0L && file.exists("R/check_disclosure.R")) {
  run_step("study disclosure guard", "R/check_disclosure.R")
}

if (use_sample) {
  if (from <= 1L) run_step("synthetic fixture", "R/make_sample.R")
  sample_master <- "data/sample/merged_sample.rds"
  if (from <= 3L) {
    run_step(
      "sample aggregates",
      "R/03_aggregate.R",
      c(
        paste0("--master=", sample_master),
        paste0("--output-dir=", file.path(temporary_root, "processed"))
      )
    )
  }
  if (from <= 4L) {
    run_step(
      "sample NLP",
      "R/04_nlp.R",
      c(
        "--build",
        paste0("--master=", sample_master),
        paste0("--output-dir=", file.path(temporary_root, "nlp"))
      )
    )
  }
  if (from <= 5L) {
    run_step(
      "sample page-ready summaries",
      "R/05_page_summaries.R",
      c(
        "--build",
        paste0("--nlp-dir=", file.path(temporary_root, "nlp")),
        paste0("--output-dir=", file.path(temporary_root, "page-ready"))
      )
    )
  }
} else {
  if (from <= 3L) run_step("aggregate preview", "R/03_aggregate.R")
  if (from <= 4L) run_step("NLP validation", "R/04_nlp.R")
  if (from <= 5L) run_step("page-ready summary validation", "R/05_page_summaries.R")
  if (from <= 11L && file.exists("data/semantic/digikat.ragnar.duckdb")) {
    run_step("semantic-store validation", "R/semantic/11_build.R")
  }
}

if (use_sample && dir.exists(temporary_root)) {
  unlink(temporary_root, recursive = TRUE, force = TRUE)
}
cat("\nDigiKat non-destructive pipeline validation passed.\n")
