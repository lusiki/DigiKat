#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(data.table)
  library(stringi)
})

extract_host <- function(url) {
  host <- tolower(trimws(fifelse(is.na(url), "", url)))
  host <- sub("^[a-z][a-z0-9+.-]*://", "", host, perl = TRUE)
  host <- sub("^//", "", host, perl = TRUE)
  host <- sub("[/?#].*$", "", host, perl = TRUE)
  host <- sub(":[0-9]+$", "", host, perl = TRUE)
  sub("^www\\.", "", host, perl = TRUE)
}

x <- as.data.table(readRDS("data/digikat_corpus.rds"))
registry <- fread("studies/news-gap/source_registry.csv")
x[, `:=`(
  url_host_key = extract_host(URL),
  raw_from_key = tolower(trimws(FROM)),
  source_type_key = tolower(trimws(SOURCE_TYPE)),
  date = as.Date(DATE)
)]
registry[, `:=`(
  url_host_key = tolower(url_host),
  raw_from_key = tolower(raw_from),
  source_type_key = tolower(source_type)
)]
y <- merge(x, registry, by = c("url_host_key", "raw_from_key", "source_type_key"))
y <- y[
  (data_source == "filtered_religious" & date >= as.Date("2024-07-01") & date <= as.Date("2026-01-31")) |
    (data_source == "original_dta" & date >= as.Date("2021-01-01") & date <= as.Date("2023-12-31"))
]
y[, era := fifelse(data_source == "filtered_religious", "main", "historical")]
y[, title_norm := stri_trans_tolower(
  stri_trim_both(stri_trans_nfkc(fifelse(is.na(TITLE), "", TITLE))), locale = "hr"
)]
y[, url_no_scheme := sub("^[a-z][a-z0-9+.-]*://", "", tolower(fifelse(is.na(URL), "", URL)), perl = TRUE)]
y[, path := sub("^[^/?#]*", "", url_no_scheme, perl = TRUE)]
y[, path := sub("[?#].*$", "", path, perl = TRUE)]

cat("COMMON TITLES\n")
common <- y[, .N, by = .(era, product_id, title_norm)][order(era, product_id, -N)]
print(common[, head(.SD, 15L), by = .(era, product_id)], nrows = Inf)

cat("CANDIDATE GENERIC\n")
generic_titles <- c("početna", "naslovnica", "home", "arhiva", "pretraživanje", "rezultati pretraživanja")
candidates <- y[
  title_norm %in% generic_titles |
    grepl("^/(page|stranica)/[0-9]+/?$", path, perl = TRUE) |
    grepl("^/(category|tag|author|search)(/|$)", path, perl = TRUE) |
    path %in% c("", "/")
]
print(candidates[, .(
  n = .N,
  interactions = sum(INTERACTIONS, na.rm = TRUE),
  titles = paste(head(unique(title_norm), 5L), collapse = " | "),
  paths = paste(head(unique(path), 5L), collapse = " | ")
), by = .(era, product_id)][order(era, product_id)], nrows = Inf)
print(candidates[, .(
  era, product_id, date, title_norm, URL, INTERACTIONS
)][order(era, product_id, date)], nrows = 250L)

cat("PATH PREFIX\n")
y[, prefix := sub("^/([^/]+).*$", "\\1", path, perl = TRUE)]
prefixes <- y[, .N, by = .(era, product_id, prefix)][order(era, product_id, -N)]
print(prefixes[, head(.SD, 15L), by = .(era, product_id)], nrows = Inf)

private_dir <- "studies/news-gap/output/private"
dir.create(private_dir, recursive = TRUE, showWarnings = FALSE)
fwrite(common, file.path(private_dir, "editorial_common_titles.csv"), bom = TRUE)
fwrite(candidates, file.path(private_dir, "editorial_generic_candidates.csv"), bom = TRUE)
fwrite(prefixes, file.path(private_dir, "editorial_path_prefixes.csv"), bom = TRUE)
fwrite(y[, .(
  era, product_id, date, title_norm, URL, path,
  interactions = INTERACTIONS,
  text_characters = nchar(FULL_TEXT)
)], file.path(private_dir, "editorial_row_audit.csv"), bom = TRUE)
