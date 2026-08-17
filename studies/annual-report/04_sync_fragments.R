#!/usr/bin/env Rscript
# Stage 4 — install generated scalars and fragments into both language manuscripts.
#
# The tracked templates hold prose and tokens only. Numbers are installed from one shared scalar
# registry; each language owns its word-bearing table, figure and profile fragments.

suppressPackageStartupMessages({ library(here) })
source(here::here("studies", "annual-report", "report_lib.R"), encoding = "UTF-8")

derived_path <- file.path(AR_OUT, "annual_report_derived.csv")
if (!file.exists(derived_path)) stop("Run 03_report_assets.R first.", call. = FALSE)
derived <- ar_read_csv(derived_path)
if (anyDuplicated(derived$key)) stop("Duplicate scalar key in annual_report_derived.csv.", call. = FALSE)

install_report <- function(template_path, fragment_dirs, profile_file, display_col, out_name,
                           token_registry, language) {
  if (!file.exists(template_path)) stop("Missing report template: ", template_path, call. = FALSE)
  txt <- paste(readLines(template_path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  token_pattern <- "\\{\\{([^{}]+)\\}\\}"
  tokens <- unique(gsub("^\\{\\{|\\}\\}$", "",
                        unlist(regmatches(txt, gregexpr(token_pattern, txt, perl = TRUE))), perl = TRUE))
  if (!length(tokens)) stop("Template contains no installation tokens: ", template_path, call. = FALSE)

  fragment_paths <- c(unlist(lapply(fragment_dirs, function(path) {
    list.files(path, pattern = "[.]md$", full.names = TRUE)
  })), profile_file)
  fragment_paths <- fragment_paths[file.exists(fragment_paths)]
  fragment_names <- tools::file_path_sans_ext(basename(fragment_paths))
  if (anyDuplicated(fragment_names)) stop("Duplicate fragment stem in ", language, " edition.", call. = FALSE)

  replacement <- function(token) {
    if (startsWith(token, "scalar:")) {
      key <- sub("^scalar:", "", token)
      i <- match(key, derived$key)
      if (is.na(i)) stop("Unknown scalar token: ", token, call. = FALSE)
      return(derived[[display_col]][i])
    }
    if (startsWith(token, "fragment:")) {
      key <- sub("^fragment:", "", token)
      i <- match(key, fragment_names)
      if (is.na(i)) stop("Unknown fragment token: ", token, call. = FALSE)
      return(paste(readLines(fragment_paths[i], encoding = "UTF-8", warn = FALSE), collapse = "\n"))
    }
    if (startsWith(token, "plural:") && identical(language, "hr")) {
      parts <- strsplit(sub("^plural:", "", token), ":", fixed = TRUE)[[1]]
      if (length(parts) != 2L) stop("A plural token reads {{plural:key:noun}}: ", token, call. = FALSE)
      i <- match(parts[1], derived$key)
      if (is.na(i)) stop("Unknown scalar in plural token: ", token, call. = FALSE)
      n <- suppressWarnings(as.numeric(derived$value[i]))
      if (is.na(n)) stop("Scalar is not countable in plural token: ", token, call. = FALSE)
      return(ar_noun_hr(n, parts[2]))
    }
    stop("Unknown token type in ", language, " edition: ", token, call. = FALSE)
  }

  for (token in tokens) txt <- gsub(paste0("{{", token, "}}"), replacement(token), txt, fixed = TRUE)
  if (grepl(token_pattern, txt, perl = TRUE)) stop("Unresolved installation token remains.", call. = FALSE)

  out_path <- file.path(AR_PRIVATE, out_name)
  ar_write_utf8(strsplit(txt, "\n", fixed = TRUE)[[1]], out_path)
  installed <- data.frame(token = tokens, type = sub(":.*$", "", tokens),
                          key = sub("^[^:]+:", "", tokens), language = language,
                          stringsAsFactors = FALSE)
  ar_write_csv(installed, file.path(AR_PRIVATE, token_registry))
  cat("Installed", sum(installed$type == "scalar"), "scalars and",
      sum(installed$type == "fragment"), "fragments into", basename(out_path), "\n")
  invisible(installed)
}

installed_hr <- install_report(
  ar_template_path(), AR_TABLES, file.path(AR_PRIVATE, "profiles", "profiles.md"),
  "display_hr", "IZVJESTAJ.qmd", "installed_tokens.csv", "hr"
)
installed_en <- install_report(
  ar_template_en_path(), AR_TABLES_EN, file.path(AR_PRIVATE, "profiles", "profiles_en.md"),
  "display_en", "REPORT_EN.qmd", "installed_tokens_en.csv", "en"
)

unused_both <- setdiff(derived$key,
                       union(installed_hr$key[installed_hr$type == "scalar"],
                             installed_en$key[installed_en$type == "scalar"]))
if (length(unused_both)) {
  cat("  scalars generated but not used in either edition:", paste(unused_both, collapse = ", "), "\n")
}
