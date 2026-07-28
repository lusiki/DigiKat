#!/usr/bin/env Rscript
# Explicitly update renv.lock. Kept separate from environment reporting so a
# diagnostic command never mutates dependency state.
#
# Usage:
#   Rscript R/snapshot_dependencies.R --apply

source("R/lib/digikat_utils.R", encoding = "UTF-8")
args <- commandArgs(trailingOnly = TRUE)

if ("--help" %in% args) {
  cat("Usage: Rscript R/snapshot_dependencies.R --apply\n")
  quit(save = "no", status = 0L)
}
if (!digikat_cli_flag(args, "--apply")) {
  stop("Dependency snapshot is a mutating operation. Re-run with --apply.", call. = FALSE)
}
if (!requireNamespace("renv", quietly = TRUE)) {
  stop("Package 'renv' is required. Install it once with install.packages('renv').", call. = FALSE)
}

active_packages <- c(
  "DBI", "av", "chromote", "data.table", "dbscan", "digest",
  "dplyr", "duckdb", "ellmer", "forcats", "ggplot2", "ggraph", "ggrepel",
  "ggridges", "here", "httr2", "igraph", "jsonlite", "kableExtra", "knitr",
  "lubridate", "patchwork", "purrr", "ragnar", "readxl", "renv",
  "rmarkdown", "scales", "showtext", "stringi", "stringr", "sysfonts",
  "tibble", "tidygraph", "tidyr", "tidytext", "udpipe", "uwot",
  "visNetwork", "widyr", "wordcloud", "yaml"
)
discovered <- renv::dependencies(".", progress = FALSE, errors = "reported")
base_packages <- rownames(installed.packages(priority = "base"))
discovered_packages <- setdiff(sort(unique(discovered$Package)), base_packages)
unlisted <- setdiff(discovered_packages, active_packages)
stale <- setdiff(active_packages, discovered_packages)
if (length(unlisted) || length(stale)) {
  stop(
    "The explicit dependency set is out of date.",
    if (length(unlisted)) paste0("\nReferenced but unlisted: ", paste(unlisted, collapse = ", ")) else "",
    if (length(stale)) paste0("\nListed but not referenced: ", paste(stale, collapse = ", ")) else "",
    call. = FALSE
  )
}
major_minor <- paste(R.version$major, strsplit(R.version$minor, ".", fixed = TRUE)[[1L]][1L], sep = ".")
default_user_library <- if (.Platform$OS.type == "windows") {
  file.path(Sys.getenv("LOCALAPPDATA", unset = ""), "R", "win-library", major_minor)
} else {
  file.path(path.expand("~"), "R", paste0(R.version$platform, "-library"), major_minor)
}
source_libraries <- unique(c(
  .libPaths(),
  path.expand(Sys.getenv("R_LIBS_USER", unset = "")),
  default_user_library,
  R.home("library"),
  .Library.site,
  .Library
))
source_libraries <- source_libraries[nzchar(source_libraries) & dir.exists(source_libraries)]
source_installed <- if (length(source_libraries)) {
  rownames(installed.packages(lib.loc = source_libraries))
} else {
  character()
}
missing_sources <- setdiff(active_packages, source_installed)
if (length(missing_sources)) {
  stop(
    "Cannot create a complete core lockfile because these packages are absent from the available libraries: ",
    paste(missing_sources, collapse = ", "),
    call. = FALSE
  )
}

if (!file.exists("renv/activate.R")) {
  renv::init(bare = TRUE, restart = FALSE)
}
renv::hydrate(
  packages = active_packages,
  sources = source_libraries,
  prompt = FALSE,
  report = FALSE
)
missing_project <- setdiff(active_packages, rownames(installed.packages()))
if (length(missing_project)) {
  stop(
    "renv hydration did not make these core packages available: ",
    paste(missing_project, collapse = ", "),
    call. = FALSE
  )
}
renv::snapshot(packages = active_packages, prompt = FALSE)
cat("Updated renv.lock for", length(active_packages), "active packages and their dependencies.\n")
