#!/usr/bin/env Rscript
# Quarto may clean hidden files from docs/ before rendering. Restore the
# GitHub Pages marker as a deterministic post-render step.

source_path <- ".nojekyll"
output_path <- file.path("docs", ".nojekyll")

if (!file.exists(source_path)) {
  stop("Source marker is missing: ", source_path, call. = FALSE)
}
if (!dir.exists(dirname(output_path))) {
  stop("Rendered site directory is missing: ", dirname(output_path), call. = FALSE)
}
if (!file.copy(source_path, output_path, overwrite = TRUE, copy.date = TRUE)) {
  stop("Could not install GitHub Pages marker: ", output_path, call. = FALSE)
}
if (!identical(unname(tools::md5sum(source_path)), unname(tools::md5sum(output_path)))) {
  stop("GitHub Pages marker verification failed.", call. = FALSE)
}

cat("Verified GitHub Pages marker:", output_path, "\n")
