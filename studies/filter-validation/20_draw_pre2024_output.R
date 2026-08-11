#!/usr/bin/env Rscript
# Draw 50 FRESH random posts from what the pre-2024 rebuild would actually KEEP.
#
# Why this population and not another. Everything read so far was read somewhere else:
#   round 1 (440) tuned the word list; round 2 (300) sampled what gate 1 accepts, with no gate 2;
#   round 3 (250) read the post-2024 OUTPUT. Nobody has ever read the pre-2024 rebuild's output,
#   i.e. feed rows that pass gate 1 AND score >= 0.50 on the frozen second pass. That is the pile
#   plan_pre2024.R projects at 79,5% clean, and the projection is a re-slice of 146 + 104 coded
#   items scored out-of-fold. This draw measures it directly and, for every post, records WHICH
#   patterns fired and in what textual context — which is what a pattern repair needs.
#
# Read-only: SELECTs against DetermDB, readRDS on the master. Writes only to output/private/.
suppressPackageStartupMessages({
  library(DBI); library(duckdb); library(dplyr); library(stringi)
})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
source("R/lib/second_pass.R", encoding = "UTF-8")

SEED        <- 20260810L            # round 3 used this seed on the master; this is a feed draw
DETERM_PATH <- "C:/Users/lsikic/Luka C/DetermDB/determDB.duckdb"
OUT         <- "studies/filter-validation/output/private"
FEED_POOL   <- 60000L
TEXT_CAP    <- 3000L                # what gate 2 and the coder see
READ_CHARS  <- 1000L                # what goes into the reading pack
KWIC        <- 75L                  # context either side of a match
THRESHOLD   <- 0.50
DRAW        <- 50L
set.seed(SEED)

v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")
sp <- digikat_load_second_pass()
cat("gate 1:", nrow(v3), "patterns |  gate 2:", length(sp$models), "models, threshold", THRESHOLD, "\n")

## ---- URLs already coded, so this is genuinely fresh ------------------------------------------
already <- character(0)
for (f in c("coded.rds", "holdout_coded.rds")) {
  p <- file.path(OUT, f)
  if (file.exists(p)) { x <- readRDS(p); if ("url" %in% names(x)) already <- c(already, as.character(x$url)) }
}
p3 <- "data/rebuild/discarded_coded.rds"
if (file.exists(p3)) { x <- readRDS(p3); already <- c(already, as.character(x$url)) }
already <- unique(already)
cat("excluding", length(already), "already-coded URLs\n")

## ---- the feed --------------------------------------------------------------------------------
con <- dbConnect(duckdb::duckdb(), dbdir = DETERM_PATH, read_only = TRUE)
g <- dbGetQuery(con, sprintf("
  SELECT CAST(DATE AS VARCHAR) AS date, SOURCE_TYPE AS platform, \"FROM\" AS source,
         TITLE AS title, URL AS url, FULL_TEXT AS text_full
  FROM media_data
  WHERE FULL_TEXT IS NOT NULL AND LENGTH(FULL_TEXT) > 0
  USING SAMPLE reservoir(%d ROWS) REPEATABLE (%d)", FEED_POOL, SEED))
dbDisconnect(con, shutdown = TRUE)
cat("drew", nrow(g), "feed rows with text\n")
g <- g[!(as.character(g$url) %in% already), ]
g$title  <- ifelse(is.na(g$title),  "", as.character(g$title))
g$source <- ifelse(is.na(g$source), "", as.character(g$source))

## ---- gate 1 ----------------------------------------------------------------------------------
H  <- digikat_hit_matrix(g$text_full, v3, progress = TRUE)
cn <- digikat_tier_counts(H, v3)
g$n_dec <- cn$decisive_match_count; g$n_amb <- cn$ambiguous_match_count
g$n_tot <- cn$total_match_count
g1 <- digikat_passes_inclusion_v2(cn)
cat(sprintf("gate 1 accepts %d of %d (%.2f%%)\n", sum(g1), nrow(g), 100 * mean(g1)))

## ---- gate 2 ----------------------------------------------------------------------------------
a <- g[g1, ]; Ha <- H[g1, , drop = FALSE]
Ht <- digikat_hit_matrix(a$title, v3)
feat <- data.frame(dec = a$n_dec, amb = a$n_amb,
                   len = log1p(nchar(substr(a$text_full, 1, TEXT_CAP))),
                   title_dec = as.integer(rowSums(Ht[, v3$tier == "decisive", drop = FALSE]) > 0),
                   title_any = as.integer(rowSums(Ht) > 0))
a$score <- digikat_second_pass_score(substr(a$text_full, 1, TEXT_CAP), feat, sp, progress = TRUE)
a$title_dec <- feat$title_dec; a$title_any <- feat$title_any
keep <- which(a$score >= THRESHOLD)
cat(sprintf("gate 2 keeps %d of %d gate-1 passers (%.1f%%) -> %.2f%% of the feed\n",
            length(keep), nrow(a), 100 * length(keep) / nrow(a), 100 * length(keep) / nrow(g)))

## ---- in the master already? ------------------------------------------------------------------
cat("loading master URLs (read-only)...\n")
m <- readRDS("data/merged_comprehensive.rds")
murl <- unique(as.character(m$URL[m$data_source == "original_dta"]))
rm(m); invisible(gc())
a$in_master <- a$url %in% murl
cat(sprintf("of the kept pile: %.1f%% already in the corpus\n", 100 * mean(a$in_master[keep])))

## ---- the 50 ----------------------------------------------------------------------------------
sel <- sort(sample(keep, DRAW))
s <- a[sel, ]; Hs <- Ha[sel, , drop = FALSE]
s$id <- sprintf("P%02d", seq_len(nrow(s)))

# For each fired pattern, the first occurrence in context. This is the diagnostic payload: a junk
# post is only actionable if you can see the words that let it through.
kwic_one <- function(txt, i) {
  terms <- v3$term[Hs[i, ]]
  out <- vapply(which(Hs[i, ]), function(j) {
    loc <- stri_locate_first_regex(txt, v3$regex[j], case_insensitive = TRUE)
    if (is.na(loc[1, 1])) return(NA_character_)
    from <- max(1L, loc[1, 1] - KWIC); to <- min(nchar(txt), loc[1, 2] + KWIC)
    sprintf("[%s|%s] ...%s...", v3$term[j], substr(v3$tier[j], 1, 3),
            gsub("\\s+", " ", substr(txt, from, to)))
  }, character(1))
  paste(out[!is.na(out)], collapse = "\n      ")
}
s$kwic <- vapply(seq_len(nrow(s)), function(i) kwic_one(substr(s$text_full[i], 1, TEXT_CAP), i),
                 character(1))
s$excerpt <- gsub("\\s+", " ", substr(s$text_full, 1, READ_CHARS))
s$terms_fired <- vapply(seq_len(nrow(s)), function(i) paste(v3$term[Hs[i, ]], collapse = "; "),
                        character(1))

saveRDS(list(sample = s, hits = Hs, terms = v3, seed = SEED, threshold = THRESHOLD,
             pool_rows = nrow(g), gate1_rate = mean(g1), gate2_rate = length(keep) / nrow(a),
             accept_rate = length(keep) / nrow(g), in_master_rate = mean(a$in_master[keep]),
             feed_scored = a[, c("date","platform","source","url","n_dec","n_amb","n_tot",
                                 "score","title_dec","title_any","in_master")]),
        file.path(OUT, "pre2024_output_sample.rds"))

## ---- the reading pack ------------------------------------------------------------------------
lines <- c(sprintf("50 random posts from the pre-2024 rebuild output (gate 1 + gate 2 >= %.2f).", THRESHOLD),
           sprintf("Feed pool %d rows | gate 1 %.2f%% | gate 2 keeps %.1f%% of those | net %.2f%%",
                   nrow(g), 100 * mean(g1), 100 * length(keep)/nrow(a), 100 * length(keep)/nrow(g)),
           "", strrep("=", 100), "")
for (i in seq_len(nrow(s))) {
  lines <- c(lines,
    sprintf("%s | %s | %s | %s | %s", s$id[i], s$date[i], s$platform[i],
            ifelse(nzchar(s$source[i]), s$source[i], "(no source)"),
            ifelse(s$in_master[i], "ALREADY IN CORPUS", "NEW MATERIAL")),
    sprintf("  gate2 %.3f | terms %d (decisive %d) | title_dec %d title_any %d | chars %d",
            s$score[i], s$n_tot[i], s$n_dec[i], s$title_dec[i], s$title_any[i], nchar(s$text_full[i])),
    sprintf("  TITLE: %s", ifelse(nzchar(s$title[i]), s$title[i], "(none)")),
    sprintf("  WHY IT PASSED:\n      %s", s$kwic[i]),
    sprintf("  TEXT: %s", s$excerpt[i]),
    "", strrep("-", 100), "")
}
con2 <- file(file.path(OUT, "pre2024_output_readpack.txt"), open = "wb")
writeBin(charToRaw(enc2utf8(paste(lines, collapse = "\n"))), con2); close(con2)

# blind coding sheet
sheet <- data.frame(id = s$id, label = "", note = "", url = s$url, stringsAsFactors = FALSE)
write.csv(sheet, file.path(OUT, "pre2024_output_sheet.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote pre2024_output_sample.rds, pre2024_output_readpack.txt, pre2024_output_sheet.csv\n")
