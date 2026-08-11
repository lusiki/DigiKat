#!/usr/bin/env Rscript
# HELD-OUT validation sample for the v3 rule (119 terms, >=1 decisive AND >=2 total).
#
#   Rscript studies/filter-validation/10_draw_holdout.R
#
# Why a second sample: every precision figure for v2 and v3 was tuned on the first 440 items, so
# they flatter themselves. This draws 300 items that were NOT in that sample and re-bases the
# strata on what the NEW rule does, so the result is an honest measurement rather than a re-fit.
#
# Strata (300 items). Round 1 sampled the population and then measured what the rule kept, which
# spent most of the budget on posts the rule rejects anyway. Round 2 samples what v3 ACCEPTS
# directly, so precision — the number that decides the rebuild — gets tight intervals.
#
#   S1  75  master, filtered_religious (post-2024), v3 accepts   precision on the dirty half
#   S2  60  master, original_dta (pre-2024), v3 accepts          precision on the clean half
#   S3  85  feed, not in master, v3 accepts                      precision of what a rebuild ADDS
#   S4  60  v3 rejects but >=1 term matched (near miss)          the recall the rule gives up
#   S5  20  feed, zero term matches                              sanity floor, should be ~all no
#
# Outputs (BOTH gitignored — they carry post text and URLs):
#   studies/filter-validation/output/private/holdout_sample.csv
#   studies/filter-validation/output/private/holdout_coder.html
#
# Read-only with respect to every protected asset: SELECTs against DetermDB, readRDS on the master.

suppressPackageStartupMessages({
  library(DBI); library(duckdb); library(dplyr); library(jsonlite); library(stringi)
})
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")

SEED        <- 20260808L          # NOT round 1's 20260807 — a different draw
DETERM_PATH <- "C:/Users/lsikic/Luka C/DetermDB/determDB.duckdb"
MASTER_PATH <- "data/merged_comprehensive.rds"
OUT_DIR     <- "studies/filter-validation/output/private"
CODED_PATH  <- file.path(OUT_DIR, "coded.rds")
TEXT_CAP    <- 3000L
MASTER_POOL <- 5000L              # candidates scored per master stream
FEED_POOL   <- 40000L             # reservoir draw from the 19,78 M-row feed
DRAW        <- c(S1 = 75L, S2 = 60L, S3 = 85L, S4 = 60L, S5 = 20L)

dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)
set.seed(SEED)

v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")
cat("v3 terms:", nrow(v3), "(", sum(v3$tier == "decisive"), "decisive,",
    sum(v3$tier == "ambiguous"), "ambiguous )\n")

# round 1's items, excluded so this really is held out
already <- character(0)
if (file.exists(CODED_PATH)) {
  cd <- readRDS(CODED_PATH)
  if ("url" %in% names(cd)) already <- unique(as.character(cd$url))
  cat("excluding", length(already), "URLs already coded in round 1\n")
} else {
  warning("coded.rds not found — cannot exclude round-1 items")
}

trim <- function(x, n = TEXT_CAP) {
  x <- as.character(x); x[is.na(x)] <- ""
  ifelse(nchar(x) > n, paste0(substr(x, 1, n), " […]"), x)
}
# v3 verdict + the terms that fired, for one vector of texts
score_v3 <- function(txt, label) {
  cat("  scoring", length(txt), label, "texts against", nrow(v3), "patterns...\n")
  H <- digikat_hit_matrix(txt, v3, progress = TRUE)
  cnt <- digikat_tier_counts(H, v3)
  list(
    keep = digikat_passes_inclusion_v2(cnt),
    total = cnt$total_match_count,
    decisive = cnt$decisive_match_count,
    terms = vapply(seq_len(nrow(H)),
                   function(i) paste(v3$term[H[i, ]], collapse = "; "), character(1))
  )
}

# ---------------------------------------------------------------- master strata
cat("\nLoading master...\n")
m <- readRDS(MASTER_PATH)
m$DATE <- as.character(m$DATE)
master_urls <- unique(as.character(m$URL))

pick_master <- function(stream, stratum, n) {
  pool <- which(m$data_source == stream & !(as.character(m$URL) %in% already))
  idx <- sample(pool, min(MASTER_POOL, length(pool)))
  txt <- as.character(m$FULL_TEXT[idx])
  s <- score_v3(txt, paste0("master/", stream))
  ok <- which(s$keep)
  cat("   ", stream, ": v3 accepts", length(ok), "of", length(idx),
      sprintf("(%.1f%%)\n", 100 * length(ok) / length(idx)))
  if (length(ok) < n) stop("not enough accepted rows in ", stream)
  sel <- sample(ok, n)
  data.frame(
    stratum = stratum, origin = paste0("master/", stream),
    date = m$DATE[idx[sel]], platform = m$SOURCE_TYPE[idx[sel]],
    source = as.character(m$FROM[idx[sel]]), title = as.character(m$TITLE[idx[sel]]),
    url = as.character(m$URL[idx[sel]]), text_full = txt[sel],
    v3_keep = TRUE, v3_total = s$total[sel], v3_decisive = s$decisive[sel],
    v3_terms = s$terms[sel], stringsAsFactors = FALSE
  )
}
S1 <- pick_master("filtered_religious", "S1", DRAW[["S1"]])
S2 <- pick_master("original_dta",       "S2", DRAW[["S2"]])
rm(m); invisible(gc())

# ------------------------------------------------------------- general feed
cat("\nSampling the general feed...\n")
con <- dbConnect(duckdb::duckdb(), dbdir = DETERM_PATH, read_only = TRUE)
g <- dbGetQuery(con, sprintf("
  SELECT CAST(DATE AS VARCHAR) AS date, SOURCE_TYPE AS platform, \"FROM\" AS source,
         TITLE AS title, URL AS url, FULL_TEXT AS text_full
  FROM media_data
  WHERE FULL_TEXT IS NOT NULL AND LENGTH(FULL_TEXT) > 0
  USING SAMPLE reservoir(%d ROWS) REPEATABLE (%d)", FEED_POOL, SEED))
dbDisconnect(con, shutdown = TRUE)
cat("  drew", nrow(g), "rows with text\n")

g <- g[!(as.character(g$url) %in% already), ]
sg <- score_v3(g$text_full, "feed")
g$v3_keep <- sg$keep; g$v3_total <- sg$total
g$v3_decisive <- sg$decisive; g$v3_terms <- sg$terms
g$in_master <- g$url %in% master_urls
cat(sprintf("  v3 accepts %d (%.2f%%) | of those already in master: %d\n",
            sum(g$v3_keep), 100 * mean(g$v3_keep), sum(g$v3_keep & g$in_master)))

take <- function(rows, stratum, origin, n) {
  if (length(rows) < n) stop("stratum ", stratum, " has only ", length(rows), " candidates")
  i <- sample(rows, n)
  data.frame(stratum = stratum, origin = origin,
             date = g$date[i], platform = g$platform[i], source = g$source[i],
             title = g$title[i], url = g$url[i], text_full = g$text_full[i],
             v3_keep = g$v3_keep[i], v3_total = g$v3_total[i],
             v3_decisive = g$v3_decisive[i], v3_terms = g$v3_terms[i],
             stringsAsFactors = FALSE)
}
S3 <- take(which(g$v3_keep & !g$in_master),            "S3", "feed/new-accept", DRAW[["S3"]])
S4 <- take(which(!g$v3_keep & g$v3_total >= 1L),       "S4", "feed/near-miss",  DRAW[["S4"]])
S5 <- take(which(g$v3_total == 0L),                    "S5", "feed/zero-term",  DRAW[["S5"]])

# ------------------------------------------------------------------ assemble
all <- bind_rows(S1, S2, S3, S4, S5)
all$text <- trim(all$text_full); all$text_full <- NULL
all$title  <- ifelse(is.na(all$title),  "", as.character(all$title))
all$source <- ifelse(is.na(all$source), "", as.character(all$source))
all$matched_terms <- all$v3_terms; all$match_count <- all$v3_total

all <- all[sample(nrow(all)), ]                     # blind the coder to stratum order
all$id <- sprintf("H%03d", seq_len(nrow(all)))
all$label <- ""; all$note <- ""
all <- all[, c("id","label","note","stratum","origin","date","platform","source","title","url",
               "match_count","matched_terms","v3_keep","v3_decisive","text")]

cat("\n=== holdout composition ===\n")
print(as.data.frame(table(all$stratum)), row.names = FALSE)
cat("total:", nrow(all), "items | overlap with round 1:",
    sum(all$url %in% already), "(must be 0)\n")
stopifnot(sum(all$url %in% already) == 0L, nrow(all) == sum(DRAW))

csv_path <- file.path(OUT_DIR, "holdout_sample.csv")
cc <- file(csv_path, open = "wb")
writeBin(charToRaw("\ufeff"), cc)                                  # BOM so Excel reads UTF-8
writeBin(charToRaw(enc2utf8(paste0(
  paste(names(all), collapse = ","), "\n",
  paste(apply(all, 1, function(r)
    paste0('"', gsub('"', '""', r, fixed = TRUE), '"', collapse = ",")), collapse = "\n"),
  "\n"))), cc)
close(cc)
cat("\nWrote", csv_path, "\n")

tpl <- readLines("studies/filter-validation/coder_template.tpl", encoding = "UTF-8", warn = FALSE)
payload <- toJSON(all, dataframe = "rows", auto_unbox = TRUE, na = "string")
html <- sub("/*__DATA__*/[]", payload, paste(tpl, collapse = "\n"), fixed = TRUE)
html <- sub("__SAMPLE_ID__", paste0("digikat-filterval-holdout-", SEED), html, fixed = TRUE)
hp <- file.path(OUT_DIR, "holdout_coder.html")
ch <- file(hp, open = "wb"); writeBin(charToRaw(enc2utf8(html)), ch); close(ch)
cat("Wrote", hp, "\n")
cat("\nOpen holdout_coder.html in a browser, code the 300 items, then click Izvezi CSV\n",
    "and save over", file.path(OUT_DIR, "holdout_sample_coded.csv"), "\n")
