#!/usr/bin/env Rscript
# moral-economy — official-corpus input contract for the RSP paper.
#
# Source this from every RSP analysis stage. The previous paper used accumulator-row IDs; the
# official corpus is a strict subset and preserves those IDs in `dk_master_row`. The prepared text
# and Stage-A files below are therefore study-local, ignored derivatives built by
# 29_prepare_official_rerun.R. They must never be replaced with row numbers from the filtered corpus.
suppressPackageStartupMessages({ library(here) })
source(here::here("R/lib/digikat_utils.R"))
source(here::here("R/lib/digikat_paths.R"))

RSP_STUDY <- here::here("studies/moral-economy")
RSP_OUT <- file.path(RSP_STUDY, "output")
RSP_PRIVATE <- file.path(RSP_OUT, "private")
RSP_INTERMEDIATE <- file.path(RSP_OUT, "intermediate")

RSP_CORPUS_PREPARED <- file.path(RSP_INTERMEDIATE, "corpus_prepared_official.rds")
RSP_STAGEA_CANDIDATES <- file.path(RSP_OUT, "stageA_candidates_official.rds")
RSP_CORE_CACHE <- file.path(RSP_PRIVATE, "cst_core_official.rds")
RSP_INPUT_MANIFEST <- file.path(RSP_OUT, "rsp_input_manifest.json")

RSP_R4_SHEET <- file.path(RSP_PRIVATE, "r4_sheet_official.csv")
RSP_R4_KEY <- file.path(RSP_PRIVATE, "r4_key_official.csv")
RSP_R4_ANN_REUSED <- file.path(RSP_PRIVATE, "r4_ann1_official_reused.tsv")
RSP_R4_ANN <- file.path(RSP_PRIVATE, "r4_ann1_official.tsv")
RSP_R4_BATCHES <- file.path(RSP_PRIVATE, "r4_batches_official_full_frame_recode")
RSP_R4_NEW_ANN <- file.path(RSP_PRIVATE, "r4_annotations_official_full_frame_recode")

RSP_R1_SHEET <- file.path(RSP_PRIVATE, "r1_sheet_official.csv")
RSP_R1_KEY <- file.path(RSP_PRIVATE, "r1_key_official.csv")
RSP_R1_ANN_REUSED <- file.path(RSP_PRIVATE, "r1_ann1_official_reused.tsv")
RSP_R1_ANN <- file.path(RSP_PRIVATE, "r1_ann1_official.tsv")
RSP_R1_BATCHES <- file.path(RSP_PRIVATE, "r1_batches_official_corrected_core_recode")
RSP_R1_NEW_ANN <- file.path(RSP_PRIVATE, "r1_annotations_official_corrected_core_recode")

rsp_read_input_manifest <- function(require = TRUE) {
  if (!file.exists(RSP_INPUT_MANIFEST)) {
    if (isTRUE(require)) {
      stop("Official RSP input manifest is missing. Run: Rscript studies/moral-economy/29_prepare_official_rerun.R",
           call. = FALSE)
    }
    return(NULL)
  }
  jsonlite::fromJSON(RSP_INPUT_MANIFEST, simplifyVector = TRUE)
}

rsp_expected_core_posts <- function() {
  m <- rsp_read_input_manifest()
  value <- m$reconciliation$core_posts
  if (!is.null(value) && length(value) && !is.na(value)) return(as.integer(value))
  # Step 29 intentionally stops at the official frame. Once the independently reconstructed frame
  # sensitivity exists, it provides a hash-bound external count gate for later core cache reads.
  p <- file.path(RSP_OUT, "cst_frame_sensitivity_manifest.json")
  if (!file.exists(p) || !file.exists(RSP_STAGEA_CANDIDATES)) return(NULL)
  z <- jsonlite::fromJSON(p, simplifyVector = TRUE)
  valid <- identical(as.character(z$inputs$database_sha256), as.character(m$database$sha256)) &&
    identical(as.character(z$inputs$candidates_sha256), digikat_hash_file(RSP_STAGEA_CANDIDATES))
  if (!valid || is.null(z$main$core_posts)) NULL else as.integer(z$main$core_posts)
}

rsp_assert_official_inputs <- function() {
  m <- rsp_read_input_manifest()
  current <- digikat_read_corpus_manifest()
  if (!identical(as.character(m$database$sha256), as.character(current$corpus$sha256))) {
    stop("The RSP study inputs were built from a different official corpus. Re-run step 29.",
         call. = FALSE)
  }
  derivatives <- list(
    prepared = RSP_CORPUS_PREPARED,
    candidates = RSP_STAGEA_CANDIDATES
  )
  for (nm in names(derivatives)) {
    p <- derivatives[[nm]]
    if (!file.exists(p)) stop("Official RSP derivative is missing: ", p, call. = FALSE)
    expected <- as.character(m$inputs[[nm]]$sha256)
    if (length(expected) != 1L || is.na(expected) || !nzchar(expected)) {
      stop("Official RSP manifest has no valid ", nm, " SHA-256. Re-run step 29.", call. = FALSE)
    }
    actual <- digikat_hash_file(p)
    if (!identical(actual, expected)) {
      stop("Official RSP ", nm, " derivative does not match its manifest. Re-run step 29.",
           call. = FALSE)
    }
  }
  invisible(m)
}

dir.create(RSP_INTERMEDIATE, recursive = TRUE, showWarnings = FALSE)
dir.create(RSP_PRIVATE, recursive = TRUE, showWarnings = FALSE)

invisible(TRUE)
