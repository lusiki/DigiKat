# Shared, fail-closed input contract for the Catholic-education study.
#
# New analysis uses the official DigiKat corpus. The legacy accumulator remains
# available for historical comparison, but this study must not silently fall
# back to it or to the redacted sample.

source(here::here("R/lib/digikat_paths.R"), encoding = "UTF-8")
source(here::here("R/lib/digikat_utils.R"), encoding = "UTF-8")

catholic_education_resolve_path <- function(path) {
  is_absolute <- grepl("^(?:[A-Za-z]:[/\\\\]|/|\\\\\\\\)", path, perl = TRUE)
  normalizePath(
    if (is_absolute) path else file.path(here::here(), path),
    winslash = "/",
    mustWork = FALSE
  )
}

catholic_education_input_contract <- function(verify_hash = TRUE) {
  corpus_path <- catholic_education_resolve_path(digikat_corpus_path())
  manifest_path <- catholic_education_resolve_path(digikat_corpus_manifest_path())
  if (!file.exists(corpus_path)) {
    stop(
      "Official DigiKat corpus not found: ", corpus_path,
      "\nThis re-analysis does not fall back to the accumulator or sample.",
      call. = FALSE
    )
  }
  manifest <- digikat_read_corpus_manifest(path = manifest_path)
  expected <- manifest$corpus
  info <- file.info(corpus_path)

  if (!identical(as.numeric(info$size), as.numeric(expected$bytes))) {
    stop(
      "Official corpus byte size differs from its manifest: ", info$size,
      " != ", expected$bytes,
      call. = FALSE
    )
  }
  actual_sha <- if (isTRUE(verify_hash)) digikat_hash_file(corpus_path) else expected$sha256
  if (!identical(tolower(actual_sha), tolower(expected$sha256))) {
    stop(
      "Official corpus SHA-256 differs from its manifest.\n  actual: ", actual_sha,
      "\n  expected: ", expected$sha256,
      call. = FALSE
    )
  }

  list(
    path = corpus_path,
    manifest_path = manifest_path,
    manifest = manifest,
    fingerprint = list(
      source_kind = "official_digikat_corpus",
      sha256 = tolower(actual_sha),
      rows = as.integer(expected$rows),
      columns = as.integer(expected$columns),
      date_min = expected$date_min,
      date_max = expected$date_max,
      analysis_start = "2021-01-01",
      analysis_end = "2025-12-31"
    )
  )
}

catholic_education_read_corpus <- function(contract) {
  corpus <- readRDS(contract$path)
  if (inherits(corpus, "data.table")) {
    data.table::setDF(corpus)
  } else {
    corpus <- as.data.frame(corpus)
  }

  required <- c(
    "FULL_TEXT", "DATE", "FROM", "SOURCE_TYPE", "data_source",
    "INTERACTIONS", "REACH"
  )
  digikat_require_columns(corpus, required, label = "official DigiKat corpus")
  expected <- contract$fingerprint
  if (nrow(corpus) != expected$rows || ncol(corpus) != expected$columns) {
    stop(
      "Official corpus dimensions differ from the input contract: ",
      nrow(corpus), " x ", ncol(corpus), " != ",
      expected$rows, " x ", expected$columns,
      call. = FALSE
    )
  }

  parsed <- digikat_parse_date(corpus$DATE, name = "DATE", allow_missing = FALSE)
  observed_span <- c(format(min(parsed)), format(max(parsed)))
  expected_span <- c(expected$date_min, expected$date_max)
  if (!identical(observed_span, expected_span)) {
    stop(
      "Official corpus date span differs from the manifest: ",
      paste(observed_span, collapse = " to "), " != ",
      paste(expected_span, collapse = " to "),
      call. = FALSE
    )
  }
  corpus
}

catholic_education_assert_slice_current <- function(slice) {
  cache <- attr(slice, "cache_fingerprint")
  if (is.null(cache$input$sha256)) {
    stop(
      "Study slice has no official-corpus fingerprint. Re-run slice.R before downstream analysis.",
      call. = FALSE
    )
  }
  manifest <- digikat_read_corpus_manifest()
  expected <- tolower(manifest$corpus$sha256)
  observed <- tolower(cache$input$sha256)
  if (!identical(observed, expected)) {
    stop(
      "Study slice is stale for the current official corpus.\n  slice: ", observed,
      "\n  official manifest: ", expected,
      "\nRe-run studies/catholic-education/slice.R.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}
