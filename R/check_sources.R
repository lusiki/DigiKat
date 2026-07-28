#!/usr/bin/env Rscript

# Static syntax and UTF-8 sanity checks for active R and Quarto sources.

excluded_prefix <- "^(archive|renv|docs|_freeze|quality_reports|\\.git|\\.Rproj\\.user)/"
normalize_rel <- function(path) {
  sub("^\\./", "", gsub("\\\\", "/", path))
}

r_files <- list.files(".", pattern = "\\.[Rr]$", recursive = TRUE, full.names = TRUE)
r_rel <- vapply(r_files, normalize_rel, character(1L))
r_files <- r_files[!grepl(excluded_prefix, r_rel)]

failures <- character()
for (path in r_files) {
  parsed <- try(parse(file = path, encoding = "UTF-8"), silent = TRUE)
  if (inherits(parsed, "try-error")) {
    failures <- c(failures, paste0(path, ": ", conditionMessage(attr(parsed, "condition"))))
  }
}

qmd_files <- c("index.qmd", list.files("pages", pattern = "\\.qmd$", recursive = TRUE, full.names = TRUE))
qmd_with_r <- 0L
for (path in qmd_files) {
  extracted <- tempfile("digikat-qmd-", fileext = ".R")
  on.exit(unlink(extracted), add = TRUE)
  result <- try(
    suppressWarnings(knitr::purl(path, output = extracted, documentation = 0L, quiet = TRUE)),
    silent = TRUE
  )
  if (inherits(result, "try-error")) {
    failures <- c(failures, paste0(path, ": R-chunk extraction failed"))
    next
  }
  if (file.exists(extracted) && file.info(extracted)$size > 0L) {
    qmd_with_r <- qmd_with_r + 1L
    parsed <- try(parse(file = extracted, encoding = "UTF-8"), silent = TRUE)
    if (inherits(parsed, "try-error")) {
      failures <- c(
        failures,
        paste0(path, ": R-chunk syntax: ", conditionMessage(attr(parsed, "condition")))
      )
    }
  }
  unlink(extracted)
}

trackable <- suppressWarnings(system2(
  "git",
  c("ls-files", "--cached", "--others", "--exclude-standard"),
  stdout = TRUE,
  stderr = TRUE
))
if (!is.null(attr(trackable, "status")) && attr(trackable, "status") != 0L) {
  stop("Unable to enumerate trackable text sources with git.", call. = FALSE)
}
trackable <- trackable[
  file.exists(trackable) &
    grepl("\\.(R|r|qmd|md|yml|yaml|cff)$", trackable)
]
text_files <- unique(c(r_files, qmd_files, trackable))
text_rel <- vapply(text_files, normalize_rel, character(1L))
text_files <- unique(text_files[!grepl(excluded_prefix, text_rel)])
mojibake_pattern <- paste(c(
  paste0(intToUtf8(0x00E2), intToUtf8(0x20AC)),
  paste0(intToUtf8(0x00C4), "[", paste0(intToUtf8(c(0x2021, 0x0164, 0x2018)), collapse = ""), "]"),
  paste0(intToUtf8(0x00C5), "[", paste0(intToUtf8(c(0x00BE, 0x00A1)), collapse = ""), "]"),
  intToUtf8(0xFFFD)
), collapse = "|")
for (path in text_files) {
  lines <- try(readLines(path, encoding = "UTF-8", warn = FALSE), silent = TRUE)
  if (inherits(lines, "try-error")) next
  hits <- grep(mojibake_pattern, lines, perl = TRUE)
  if (length(hits)) {
    failures <- c(
      failures,
      paste0(path, ": possible mojibake on line(s) ", paste(utils::head(hits, 5L), collapse = ", "))
    )
  }
}

if (length(failures)) {
  cat("Source checks FAILED:\n", paste0("- ", failures, collapse = "\n"), "\n", sep = "")
  quit(status = 1L, save = "no")
}

cat(
  "Source checks passed:",
  length(r_files), "active R files;",
  length(qmd_files), "site QMD files;",
  qmd_with_r, "QMD files with parseable R chunks.\n"
)
