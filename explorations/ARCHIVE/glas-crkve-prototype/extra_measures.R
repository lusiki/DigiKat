#!/usr/bin/env Rscript

# Adapter for the three inherited instruments used by the Glas Crkve prototype.
# The upstream definitions remain the authority. This module extracts the literal
# R assignments, records SHA-256 fingerprints, and applies them without modifying
# any upstream study file.

extract_assignment <- function(path, object_name) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  start <- grep(paste0("^[[:space:]]*", object_name, "[[:space:]]*<-[[:space:]]*list\\("), lines)
  if (length(start) != 1L) {
    stop("Expected one assignment for ", object_name, " in ", path, call. = FALSE)
  }
  for (end in seq.int(start, length(lines))) {
    candidate <- paste(lines[start:end], collapse = "\n")
    parsed <- try(parse(text = candidate, keep.source = TRUE), silent = TRUE)
    if (!inherits(parsed, "try-error") && length(parsed) == 1L) {
      assignment <- parsed[[1L]]
      if (is.call(assignment) && identical(as.character(assignment[[1L]]), "<-") &&
          identical(as.character(assignment[[2L]]), object_name)) {
        return(eval(assignment[[3L]], envir = baseenv()))
      }
    }
  }
  stop("Could not parse ", object_name, " from ", path, call. = FALSE)
}

sha256_file <- function(path) {
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop("Package 'digest' is required for source fingerprinting.", call. = FALSE)
  }
  unname(digest::digest(file = path, algo = "sha256", serialize = FALSE))
}

load_extra_measures <- function(root = ".") {
  frame_path <- file.path(root, "Church-and-dezinfo", "code", "01_data_preparation.R")
  sps_path <- file.path(root, "Church-and-dezinfo", "papers", "demokrscanstvo_paper.qmd")
  cst_path <- file.path(root, "studies", "moral-economy", "cst_lexicon.R")
  required <- c(frame_path, sps_path, cst_path)
  missing <- required[!file.exists(required)]
  if (length(missing)) {
    stop("Missing inherited-measure source: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  cst_env <- new.env(parent = globalenv())
  source(cst_path, local = cst_env, encoding = "UTF-8")

  list(
    frames = extract_assignment(frame_path, "frame_dictionaries"),
    dict_a = extract_assignment(sps_path, "dict_A_cd_social"),
    dict_b = extract_assignment(sps_path, "dict_B_identity"),
    cst_detect = get("cst_detect", envir = cst_env, inherits = FALSE),
    cst_tier = get("CST_TIER", envir = cst_env, inherits = FALSE),
    source_manifest = data.frame(
      instrument = c("eight_narrative_frames", "sps_dictionaries", "cst_detector"),
      source_path = gsub("\\\\", "/", c(frame_path, sps_path, cst_path)),
      sha256 = vapply(required, sha256_file, character(1)),
      stringsAsFactors = FALSE
    )
  )
}

count_dictionary <- function(text, dictionary, ascii = FALSE) {
  if (ascii) {
    text <- stringi::stri_trans_general(text, "Latin-ASCII")
  }
  patterns <- unlist(dictionary, use.names = FALSE)
  if (ascii) patterns <- stringi::stri_trans_general(patterns, "Latin-ASCII")
  counts <- numeric(length(text))
  for (pattern in patterns) {
    hit <- stringi::stri_count_regex(text, pattern, opts_regex = list(case_insensitive = TRUE))
    hit[is.na(hit)] <- 0L
    counts <- counts + hit
  }
  counts
}

apply_extra_measures <- function(text_lower, instruments) {
  frame_counts <- vapply(instruments$frames, function(terms) {
    pattern <- paste0("(?i)(", paste(terms, collapse = "|"), ")")
    out <- stringi::stri_count_regex(text_lower, pattern)
    out[is.na(out)] <- 0L
    out
  }, integer(length(text_lower)))
  colnames(frame_counts) <- names(instruments$frames)
  frame_flags <- frame_counts > 0L

  text_ascii <- tolower(stringi::stri_trans_general(text_lower, "Latin-ASCII"))
  a_hits <- count_dictionary(text_ascii, instruments$dict_a, ascii = TRUE)
  b_hits <- count_dictionary(text_ascii, instruments$dict_b, ascii = TRUE)

  cst_matrix <- instruments$cst_detect(text_lower)
  tier_one <- names(instruments$cst_tier)[instruments$cst_tier %in% c("1_document", "1_marker")]
  cst_hits <- if (length(tier_one)) rowSums(cst_matrix[, tier_one, drop = FALSE]) else rep(0, length(text_lower))

  substance_hits <- a_hits + cst_hits
  denom <- a_hits + b_hits
  sps <- ifelse(denom > 0, a_hits / denom, NA_real_)
  identity_frames <- c("TRADITIONAL_VALUES", "FAITH_DEFENCE", "MORAL_DECAY")
  antagonistic_frames <- c(
    "CONSPIRACY", "MEDIA_CRITIQUE", "SOVEREIGNTY", "FOREIGN_THREAT",
    "INSTITUTIONAL_DISTRUST"
  )
  npi_weights <- c(
    CONSPIRACY = 2, FOREIGN_THREAT = 1.5, INSTITUTIONAL_DISTRUST = 1.5,
    MEDIA_CRITIQUE = 1
  )
  npi_raw <- as.numeric(frame_flags[, names(npi_weights), drop = FALSE] %*% npi_weights)

  data.table::data.table(
    substance_hits = substance_hits,
    identity_hits = b_hits,
    has_substance = substance_hits > 0,
    has_identity = b_hits > 0,
    sps = sps,
    identity_frame = rowSums(frame_flags[, identity_frames, drop = FALSE]) > 0,
    antagonistic_frame = rowSums(frame_flags[, antagonistic_frames, drop = FALSE]) > 0,
    npi = 100 * npi_raw / sum(npi_weights),
    frame_counts = rowSums(frame_flags)
  )[, c(paste0("frame_", colnames(frame_flags))) := as.data.table(frame_flags)]
}
