#!/usr/bin/env Rscript
# Stage 4 — install generated scalars and table fragments into the manuscript.
#
# The tracked template holds prose and tokens only. Nothing numeric is ever typed into it, and a
# fragment is installed byte for byte, so a hand edit to a number cannot survive the next check.

suppressPackageStartupMessages({ library(here) })
source(here::here("studies", "annual-report", "report_lib.R"), encoding = "UTF-8")

template_path <- ar_template_path()
derived_path <- file.path(AR_OUT, "annual_report_derived.csv")
if (!file.exists(template_path)) stop("Missing report template.", call. = FALSE)
if (!file.exists(derived_path)) stop("Run 03_report_assets.R first.", call. = FALSE)

txt <- paste(readLines(template_path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
derived <- ar_read_csv(derived_path)
if (anyDuplicated(derived$key)) stop("Duplicate scalar key in annual_report_derived.csv.", call. = FALSE)

token_pattern <- "\\{\\{([^{}]+)\\}\\}"
tokens <- unique(gsub("^\\{\\{|\\}\\}$", "",
                      unlist(regmatches(txt, gregexpr(token_pattern, txt, perl = TRUE))), perl = TRUE))
if (!length(tokens)) stop("Template contains no installation tokens.", call. = FALSE)

fragment_paths <- c(list.files(AR_TABLES, pattern = "[.]md$", full.names = TRUE),
                    list.files(file.path(AR_PRIVATE, "profiles"), pattern = "[.]md$", full.names = TRUE))
fragment_names <- tools::file_path_sans_ext(basename(fragment_paths))
if (anyDuplicated(fragment_names)) stop("Duplicate fragment stem.", call. = FALSE)

replacement <- function(token) {
  if (startsWith(token, "scalar:")) {
    key <- sub("^scalar:", "", token)
    i <- match(key, derived$key)
    if (is.na(i)) stop("Unknown scalar token: ", token, call. = FALSE)
    return(derived$display_hr[i])
  }
  if (startsWith(token, "fragment:")) {
    key <- sub("^fragment:", "", token)
    i <- match(key, fragment_names)
    if (is.na(i)) stop("Unknown fragment token: ", token, call. = FALSE)
    return(paste(readLines(fragment_paths[i], encoding = "UTF-8", warn = FALSE), collapse = "\n"))
  }
  # {{plural:key:noun}} prints the noun in the case the scalar's value requires. Croatian agreement
  # depends on the count, and the count changes every edition, so a noun typed once into the
  # template is wrong in whichever years the number lands in another class.
  if (startsWith(token, "plural:")) {
    parts <- strsplit(sub("^plural:", "", token), ":", fixed = TRUE)[[1]]
    if (length(parts) != 2L) stop("A plural token reads {{plural:key:noun}}: ", token, call. = FALSE)
    i <- match(parts[1], derived$key)
    if (is.na(i)) stop("Unknown scalar in plural token: ", token, call. = FALSE)
    n <- suppressWarnings(as.numeric(derived$value[i]))
    if (is.na(n)) stop("Scalar is not countable in plural token: ", token, call. = FALSE)
    return(ar_noun_hr(n, parts[2]))
  }
  stop("Unknown token type: ", token, call. = FALSE)
}

for (token in tokens) txt <- gsub(paste0("{{", token, "}}"), replacement(token), txt, fixed = TRUE)
if (grepl(token_pattern, txt, perl = TRUE)) stop("Unresolved installation token remains.", call. = FALSE)

out_path <- file.path(AR_PRIVATE, "IZVJESTAJ.qmd")
ar_write_utf8(strsplit(txt, "\n", fixed = TRUE)[[1]], out_path)

installed <- data.frame(token = tokens, type = sub(":.*$", "", tokens),
                        key = sub("^[^:]+:", "", tokens), stringsAsFactors = FALSE)
ar_write_csv(installed, file.path(AR_PRIVATE, "installed_tokens.csv"))

unused <- setdiff(derived$key, installed$key[installed$type == "scalar"])
cat("Installed", sum(installed$type == "scalar"), "scalars and",
    sum(installed$type == "fragment"), "fragments into", basename(out_path), "\n")
if (length(unused)) cat("  scalars generated but not used in prose:", paste(unused, collapse = ", "), "\n")
