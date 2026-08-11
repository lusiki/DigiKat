#!/usr/bin/env Rscript
# Draw a blind, stratified validation sample for the >=2 religious-term filter,
# and generate a self-contained HTML coding tool.
#
#   Rscript studies/filter-validation/01_draw_sample.R
#
# Outputs (BOTH gitignored - they carry post text and URLs):
#   studies/filter-validation/output/private/coding_sample.csv
#   studies/filter-validation/output/private/coder.html
#
# Read-only with respect to every protected asset. Touches neither the master
# nor DetermDB beyond SELECTs.

suppressPackageStartupMessages({
  library(DBI); library(duckdb); library(dplyr); library(jsonlite)
})
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")

SEED         <- 20260807L
DETERM_PATH  <- "C:/Users/lsikic/Luka C/DetermDB/determDB.duckdb"
MASTER_PATH  <- "data/merged_comprehensive.rds"
OUT_DIR      <- "studies/filter-validation/output/private"
TEXT_CAP     <- 3000L    # characters shown to the coder
DRAW         <- c(A = 120L, B = 120L, C = 100L, D = 80L, E = 20L)

dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)
set.seed(SEED)
terms <- digikat_load_religious_terms()
cat("terms loaded:", nrow(terms), "\n")

trim <- function(x, n = TEXT_CAP) {
  x <- as.character(x); x[is.na(x)] <- ""
  ifelse(nchar(x) > n, paste0(substr(x, 1, n), " […]"), x)
}
mc_of <- function(txt) {
  digikat_match_religious(txt, terms, min_matches = 2L, include_details = TRUE, progress = TRUE)
}

# ---------------------------------------------------------------- master strata
cat("\nLoading master...\n")
m <- readRDS(MASTER_PATH)
m$DATE <- as.character(m$DATE)

pick_master <- function(stream, n) {
  idx <- sample(which(m$data_source == stream), n)
  data.frame(
    stratum = if (stream == "filtered_religious") "A" else "B",
    origin  = paste0("master/", stream),
    date = m$DATE[idx], platform = m$SOURCE_TYPE[idx],
    source = as.character(m$FROM[idx]), title = as.character(m$TITLE[idx]),
    url = as.character(m$URL[idx]), text_full = as.character(m$FULL_TEXT[idx]),
    stringsAsFactors = FALSE
  )
}
A <- pick_master("filtered_religious", DRAW[["A"]])
B <- pick_master("original_dta",       DRAW[["B"]])
master_urls <- unique(as.character(m$URL))
rm(m); invisible(gc())

# ------------------------------------------------------- general-feed strata
cat("\nSampling the general feed...\n")
con <- dbConnect(duckdb::duckdb(), dbdir = DETERM_PATH, read_only = TRUE)
g <- dbGetQuery(con, "
  SELECT CAST(DATE AS VARCHAR) AS date, SOURCE_TYPE AS platform, \"FROM\" AS source,
         TITLE AS title, URL AS url, FULL_TEXT AS text_full
  FROM media_data
  WHERE FULL_TEXT IS NOT NULL AND LENGTH(FULL_TEXT) > 0
  USING SAMPLE reservoir(60000 ROWS) REPEATABLE (20260807)")
dbDisconnect(con, shutdown = TRUE)
cat("  drew", nrow(g), "rows with text\n")

cat("  scoring against the 95-term list...\n")
gm <- mc_of(g$text_full)
g$mc <- gm$root_match_count
g$matched <- gm$matched_terms
g$in_master <- g$url %in% master_urls
cat(sprintf("  pass >=2: %d (%.2f%%) | of those already in master: %d\n",
            sum(g$mc >= 2), 100*mean(g$mc >= 2), sum(g$mc >= 2 & g$in_master)))

take <- function(rows, stratum, origin, n) {
  if (!length(rows)) stop("empty stratum: ", stratum)
  idx <- sample(rows, min(n, length(rows)))
  data.frame(stratum = stratum, origin = origin,
             date = g$date[idx], platform = g$platform[idx], source = g$source[idx],
             title = g$title[idx], url = g$url[idx], text_full = g$text_full[idx],
             stringsAsFactors = FALSE)
}
C <- take(which(g$mc >= 2L & !g$in_master), "C", "determdb/new-accept", DRAW[["C"]])
D <- take(which(g$mc == 1L),                "D", "determdb/near-miss",  DRAW[["D"]])
E <- take(which(g$mc == 0L),                "E", "determdb/zero-term",  DRAW[["E"]])

# ------------------------------------------------------------------ assemble
all <- bind_rows(A, B, C, D, E)
cat("\nScoring the full sample for the audit trail...\n")
sm <- mc_of(all$text_full)
all$match_count   <- sm$root_match_count
all$matched_terms <- ifelse(is.na(sm$matched_terms), "", sm$matched_terms)
all$text <- trim(all$text_full)
all$text_full <- NULL
all$title <- ifelse(is.na(all$title), "", as.character(all$title))
all$source <- ifelse(is.na(all$source), "", as.character(all$source))

all <- all[sample(nrow(all)), ]                    # blind the coder to stratum order
all$id <- sprintf("V%03d", seq_len(nrow(all)))
all$label <- ""; all$note <- ""
all <- all[, c("id","label","note","stratum","origin","date","platform",
               "source","title","url","match_count","matched_terms","text")]

cat("\n=== sample composition ===\n")
print(as.data.frame(table(all$stratum)), row.names = FALSE)
cat("total:", nrow(all), "items\n")

csv_path <- file.path(OUT_DIR, "coding_sample.csv")
con_csv <- file(csv_path, open = "wb")
writeBin(charToRaw("\ufeff"), con_csv)                        # BOM so Excel reads UTF-8
writeBin(charToRaw(enc2utf8(paste0(
  paste(names(all), collapse = ","), "\n",
  paste(apply(all, 1, function(r)
    paste0('"', gsub('"', '""', r, fixed = TRUE), '"', collapse = ",")), collapse = "\n"),
  "\n"))), con_csv)
close(con_csv)
cat("\nWrote", csv_path, "\n")

# ------------------------------------------------------------- coding tool
tpl <- readLines("studies/filter-validation/coder_template.tpl",
                 encoding = "UTF-8", warn = FALSE)
payload <- toJSON(all, dataframe = "rows", auto_unbox = TRUE, na = "string")
html <- sub("/*__DATA__*/[]", payload, paste(tpl, collapse = "\n"), fixed = TRUE)
html <- sub("__SAMPLE_ID__", paste0("digikat-filterval-", SEED), html, fixed = TRUE)
html_path <- file.path(OUT_DIR, "coder.html")
con_html <- file(html_path, open = "wb")
writeBin(charToRaw(enc2utf8(html)), con_html)
close(con_html)
cat("Wrote", html_path, "\n")
cat("\nOpen the HTML file in a browser, code the items, then click Export CSV.\n")
