#!/usr/bin/env Rscript
# Crawl rendered HTML and fail on missing local files or anchors.

source("R/lib/digikat_utils.R", encoding = "UTF-8")
args <- commandArgs(trailingOnly = TRUE)
site_dir <- digikat_cli_value(args, "--site", "docs")
if (!dir.exists(site_dir)) stop("Rendered site directory not found: ", site_dir, call. = FALSE)

html_files <- list.files(site_dir, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)
if (!length(html_files)) stop("No HTML files found under: ", site_dir, call. = FALSE)
site_root <- digikat_normalize_path(site_dir)
errors <- character()
anchor_cache <- new.env(parent = emptyenv())
mojibake_pattern <- paste(c(
  paste0(intToUtf8(0x00E2), intToUtf8(0x20AC)),
  paste0(intToUtf8(0x00C4), "[", paste0(intToUtf8(c(0x2021, 0x0164, 0x2018)), collapse = ""), "]"),
  paste0(intToUtf8(0x00C5), "[", paste0(intToUtf8(c(0x00BE, 0x00A1)), collapse = ""), "]"),
  intToUtf8(0xFFFD)
), collapse = "|")

read_ids <- function(path) {
  key <- digikat_normalize_path(path)
  if (exists(key, envir = anchor_cache, inherits = FALSE)) return(get(key, envir = anchor_cache))
  html <- paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  matches <- gregexpr("\\bid=[\"'][^\"']+[\"']", html, perl = TRUE)
  raw <- regmatches(html, matches)[[1L]]
  ids <- if (length(raw) && !identical(raw, character(0))) {
    sub("^.*id=[\"']([^\"']+)[\"']$", "\\1", raw)
  } else {
    character()
  }
  assign(key, ids, envir = anchor_cache)
  ids
}

for (html_path in html_files) {
  html <- paste(readLines(html_path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  if (grepl(mojibake_pattern, html, perl = TRUE)) {
    errors <- c(
      errors,
      paste0(
        sub(
          paste0("^", gsub("([.^$|()\\[\\]{}*+?\\\\])", "\\\\\\1", site_root), "/?"),
          "",
          digikat_normalize_path(html_path)
        ),
        " -> possible mojibake or Unicode replacement character"
      )
    )
  }
  matches <- gregexpr("\\b(?:href|src)=[\"'][^\"']+[\"']", html, perl = TRUE)
  attributes <- regmatches(html, matches)[[1L]]
  if (!length(attributes)) next
  references <- sub("^.*=[\"']([^\"']+)[\"']$", "\\1", attributes)
  for (reference in references) {
    if (!nzchar(reference) ||
        grepl("^(?:https?:|mailto:|tel:|data:|javascript:)", reference, ignore.case = TRUE)) next

    pieces <- strsplit(reference, "#", fixed = TRUE)[[1L]]
    path_part <- sub("\\?.*$", "", pieces[[1L]])
    anchor <- if (length(pieces) > 1L) pieces[[2L]] else ""
    if (!nzchar(path_part)) {
      target <- html_path
    } else {
      path_part <- utils::URLdecode(path_part)
      path_part <- sub("^/DigiKat/", "", path_part, ignore.case = TRUE)
      path_part <- sub("^/+", "", path_part)
      target <- if (grepl("^/", reference)) {
        file.path(site_root, path_part)
      } else {
        file.path(dirname(html_path), path_part)
      }
      if (dir.exists(target)) target <- file.path(target, "index.html")
    }
    target <- digikat_normalize_path(target)
    if (!file.exists(target)) {
      errors <- c(
        errors,
        paste0(
          sub(paste0("^", gsub("([.^$|()\\[\\]{}*+?\\\\])", "\\\\\\1", site_root), "/?"), "", digikat_normalize_path(html_path)),
          " -> ",
          reference
        )
      )
      next
    }
    if (nzchar(anchor) && grepl("\\.html?$", target, ignore.case = TRUE)) {
      if (!anchor %in% read_ids(target)) {
        errors <- c(errors, paste0(basename(html_path), " -> missing anchor #", anchor, " in ", basename(target)))
      }
    }
  }
}

errors <- sort(unique(errors))
if (length(errors)) {
  cat("Broken local site references:", length(errors), "\n")
  cat(paste0("- ", errors, collapse = "\n"), "\n")
  quit(save = "no", status = 1L)
}
cat(
  "Site link check passed:",
  length(html_files),
  "HTML files, no missing local targets, anchors, or mojibake signatures.\n"
)
