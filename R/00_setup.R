#!/usr/bin/env Rscript
# Validate the local runtime without installing or changing packages.

source("R/lib/digikat_utils.R", encoding = "UTF-8")

required_files <- c(
  "R/lib/digikat_utils.R",
  "R/lib/religious_filter.R",
  "R/religious_terms.R",
  "resources/models/croatian-set-ud-2.5-191206.udpipe"
)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) {
  stop("Missing required project file(s): ", paste(missing_files, collapse = ", "), call. = FALSE)
}

core_packages <- c(
  "data.table", "digest", "dplyr", "ggplot2", "here", "jsonlite",
  "knitr", "readxl", "rmarkdown", "stringi", "tidyr", "udpipe"
)
missing_packages <- core_packages[
  !vapply(core_packages, requireNamespace, logical(1L), quietly = TRUE)
]
if (length(missing_packages)) {
  stop(
    "Missing core package(s): ", paste(missing_packages, collapse = ", "),
    "\nRun `renv::restore()` before the pipeline.",
    call. = FALSE
  )
}

model_sha <- digikat_hash_file("resources/models/croatian-set-ud-2.5-191206.udpipe")
expected_sha <- "b8e0ad212bdc84c57366bd7267d21810e1fd3239c4d22ca5867f94e76c6cedc7"
if (!identical(model_sha, expected_sha)) {
  stop("The Croatian UDPIPE model does not match the pinned SHA-256.", call. = FALSE)
}

terms <- source("R/religious_terms.R", local = new.env(parent = baseenv()), encoding = "UTF-8")$value
source("R/lib/religious_filter.R", encoding = "UTF-8")
invisible(digikat_validate_religious_terms(terms))

cat("DigiKat setup validation passed.\n")
cat("  R:", R.version.string, "\n")
cat("  Locale:", Sys.getlocale("LC_CTYPE"), "\n")
cat("  UDPIPE SHA-256:", model_sha, "\n")
