#!/usr/bin/env Rscript

failures <- character()
checks <- 0L
expect_true <- function(value, message) {
  checks <<- checks + 1L
  if (!isTRUE(value)) failures <<- c(failures, message)
}

read_utf8 <- function(path) paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
count_matches <- function(text, pattern) {
  hits <- regmatches(text, gregexpr(pattern, text, perl = TRUE))[[1L]]
  sum(nzchar(hits))
}

annual_paths <- c(
  hr = file.path("assets", "izvjestaji", "godisnji-pregled-2025.html"),
  en = file.path("assets", "izvjestaji", "annual-review-2025.html")
)
for (language in names(annual_paths)) {
  path <- annual_paths[[language]]
  expect_true(file.exists(path), paste(language, "annual-report HTML must exist"))
  if (!file.exists(path)) next
  html <- read_utf8(path)
  expect_true(count_matches(html, "<h1(?:[[:space:]>])") == 1L,
              paste(language, "annual-report HTML must contain one H1"))
  expect_true(!grepl("data:image/", html, fixed = TRUE),
              paste(language, "annual-report HTML must not embed base64 images"))
  expect_true(count_matches(html, "<img(?:[[:space:]>])") == 9L &&
                count_matches(html, "srcset=") == 9L &&
                count_matches(html, "loading=\"lazy\"") == 9L,
              paste(language, "annual-report figures must be responsive and lazy loaded"))
  expect_true(all(vapply(c("rel=\"canonical\"", "property=\"og:title\"",
                           "name=\"twitter:card\"", "application/ld+json",
                           "ScholarlyArticle", "report-shell.js"),
                         grepl, logical(1L), x = html, fixed = TRUE)),
              paste(language, "annual-report metadata and shared shell must be complete"))
  expect_true(grepl("report-summary-60", html, fixed = TRUE) &&
                grepl("report-status-strip", html, fixed = TRUE) &&
                grepl("citation-block", html, fixed = TRUE),
              paste(language, "annual report must expose summary, freshness and citation blocks"))
}

expected_publications <- c(
  "assets/izvjestaji/godisnji-pregled-2025.pdf",
  "assets/izvjestaji/annual-review-2025.pdf",
  "assets/izvjestaji/godisnji-pregled-2025_files/figures/fig01_deset_brojeva-960.png",
  "assets/izvjestaji/godisnji-pregled-2025_files/figures/fig01_deset_brojeva-1440.png",
  "assets/izvjestaji/annual-review-2025_files/figures/fig01_ten_numbers-960.png",
  "assets/izvjestaji/annual-review-2025_files/figures/fig01_ten_numbers-1440.png"
)
expect_true(all(file.exists(expected_publications)),
            "annual-report PDF and representative responsive image variants must exist")

bespoke_path <- "assets/izvjestaji/kako-se-govori-o-crkvi/index.html"
bespoke <- read_utf8(bespoke_path)
expect_true(count_matches(bespoke, "<h1(?:[[:space:]>])") == 1L,
            "bespoke report must contain one H1")
expect_true(all(vapply(c("Sažetak u 60 sekundi", "Stabilno izdanje", "reading-progress",
                         "../report-shell.css", "../report-shell.js", "rel=\"canonical\"",
                         "application/ld+json", "Autorstvo i citiranje"),
                       grepl, logical(1L), x = bespoke, fixed = TRUE)),
            "bespoke report must expose orientation, status, shared progress, metadata and citation")
expect_true(!grepl("data:image/", bespoke, fixed = TRUE),
            "bespoke report shell must not embed base64 images")

shell_css <- read_utf8("assets/izvjestaji/report-shell.css")
shell_js <- read_utf8("assets/izvjestaji/report-shell.js")
expect_true(grepl("prefers-reduced-motion", shell_css, fixed = TRUE) &&
              grepl("@media print", shell_css, fixed = TRUE),
            "shared reading progress must simplify for reduced motion and disappear in print")
expect_true(grepl("requestAnimationFrame", shell_js, fixed = TRUE) &&
              grepl("scrollHeight", shell_js, fixed = TRUE),
            "shared reading progress must update against document length")

annual_css <- read_utf8("studies/annual-report/typeset/report.css")
bespoke_css <- read_utf8("assets/izvjestaji/kako-se-govori-o-crkvi/styles.css")
html_filter <- read_utf8("studies/annual-report/typeset/report-html.lua")
expect_true(all(vapply(c("focus-visible", "@media print", "prefers-reduced-motion",
                         "report-masthead", "report-footer"),
                       grepl, logical(1L), x = annual_css, fixed = TRUE)),
            "annual-report CSS must carry the shared identity and accessibility contract")
expect_true(all(vapply(c("focus-visible", "@media print", "prefers-reduced-motion", "summary-60"),
                       grepl, logical(1L), x = bespoke_css, fixed = TRUE)),
            "bespoke report CSS must carry the accessibility and summary contract")
expect_true(grepl('image.attributes[key] = nil', html_filter, fixed = TRUE) &&
              grepl('"width", "height"', html_filter, fixed = TRUE),
            "the HTML image contract must not leak physical dimensions into the Typst PDF")

if (length(failures)) {
  cat("FAILED", length(failures), "of", checks, "Run 5 publication checks:\n")
  cat(paste0("- ", failures, collapse = "\n"), "\n")
  quit(save = "no", status = 1L)
}
cat("All", checks, "Run 5 publication checks passed.\n")
