#!/usr/bin/env Rscript
# Round 5. Price the second step: draw 100 random posts it DISCARDS.
#
# Round 4 read 50 of the posts gate 2 keeps (64,0% genuine). That cannot price the threshold, because
# the alternative -- not running gate 2 at all -- was never observed. This draws from the other side:
# feed rows that pass gate 1 (v3, as specified today) and score BELOW 0,50. In the 50 744-row pool
# that pile is 351 posts of 1653 gate-1 accepts (21,2%).
#
# Gate 1 is held at v3-on-full-text, exactly as round 4 drew it, so the two samples compose into one
# measured trade-off. Whether each post also survives the v4 window rule is recorded, so the same
# 150 coded posts price the threshold under v3 AND under v4.
#
# Read-only. Writes a private read pack.
suppressPackageStartupMessages({library(DBI); library(duckdb); library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
source("studies/filter-validation/lib_rule_v4.R", encoding = "UTF-8")
OUT <- "studies/filter-validation/output/private"
CAP <- 3000L; READ <- 800L; KW <- 60L; MAXKW <- 5L; DRAW <- 100L
set.seed(20260812L)
v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")

cc <- readRDS(file.path(OUT, "repair_pool_cache.rds")); g <- cc$g
dec <- v3$tier == "decisive"
g1 <- rowSums(cc$Hf[, dec, drop = FALSE]) >= 1L & rowSums(cc$Hf) >= 2L
fs <- readRDS(file.path(OUT, "pre2024_output_sample.rds"))$feed_scored
cat("gate-1 accepts in pool:", sum(g1), "| scored rows on file:", nrow(fs), "\n")

acc <- g[g1, ]
acc <- left_join(acc, fs[, c("url","score","n_dec","n_amb","n_tot","title_dec","title_any","in_master",
                             "platform","source")], by = "url")
acc <- acc[!duplicated(acc$url) & !is.na(acc$score), ]
rej <- acc[acc$score < 0.50, ]
cat("gate-2 rejects:", nrow(rej), sprintf("(%.1f%% of accepts)\n", 100*nrow(rej)/nrow(acc)))
cat("their score range:", sprintf("%.3f to %.3f | median %.3f\n",
    min(rej$score), max(rej$score), median(rej$score)))

already <- unique(c(readRDS(file.path(OUT, "pre2024_output_coded.rds"))$url,
                    readRDS(file.path(OUT, "window_probe_index.rds"))$url))
rej <- rej[!(rej$url %in% already), ]
sel <- sort(sample(nrow(rej), min(DRAW, nrow(rej))))
s <- rej[sel, ]; s$id <- sprintf("R%03d", seq_len(nrow(s)))

# v4 verdict for each, so the threshold can be priced under the repaired gate 1 too
v4 <- digikat_rule_v4(s$text_full, v3)
s$v4_keep <- v4$keep; s$v4_gate1 <- v4$gate1; s$v4_vetoed <- v4$vetoed

# real titles, straight from the feed
con <- dbConnect(duckdb::duckdb(), dbdir = "C:/Users/lsikic/Luka C/DetermDB/determDB.duckdb",
                 read_only = TRUE)
dbWriteTable(con, "want", data.frame(url = s$url), temporary = TRUE)
ti <- dbGetQuery(con, "SELECT DISTINCT m.URL AS url, m.TITLE AS title
                       FROM media_data m JOIN want w ON m.URL = w.url")
dbDisconnect(con, shutdown = TRUE)
s <- left_join(s, ti[!duplicated(ti$url), ], by = "url")
s$title <- ifelse(is.na(s$title), "", as.character(s$title))

H <- digikat_hit_matrix(substr(s$text_full, 1, CAP), v3)
kwic <- vapply(seq_len(nrow(s)), function(i) {
  w <- which(H[i, ]); if (!length(w)) return("(no match inside the first 3000 characters)")
  w <- head(w, MAXKW); txt <- substr(s$text_full[i], 1, CAP)
  paste(vapply(w, function(j) {
    lo <- stri_locate_first_regex(txt, v3$regex[j], case_insensitive = TRUE)
    if (is.na(lo[1,1])) return(NA_character_)
    sprintf("[%s|%s] ...%s...", v3$term[j], substr(v3$tier[j],1,3),
            gsub("\\s+", " ", substr(txt, max(1L, lo[1,1]-KW), min(nchar(txt), lo[1,2]+KW))))
  }, character(1)) |> na.omit(), collapse = "\n      ")
}, character(1))

L <- c(sprintf("100 random posts the SECOND STEP discards (gate 1 accepts them, score < 0,50)."),
       sprintf("Reject pile in the pool: %d of %d gate-1 accepts. Scores %.3f-%.3f.",
               nrow(rej) + length(already[already %in% acc$url]), nrow(acc),
               min(s$score), max(s$score)),
       "", strrep("=", 96), "")
for (i in seq_len(nrow(s))) {
  L <- c(L, sprintf("%s | %s | %s | %s | %s | %s", s$id[i], s$date[i], s$platform[i],
                    ifelse(nzchar(s$source[i]), s$source[i], "(no source)"),
                    ifelse(s$in_master[i], "IN CORPUS", "NEW"),
                    ifelse(s$v4_keep[i], "v4 keeps", if (s$v4_vetoed[i]) "v4 vetoes" else "v4 drops")),
         sprintf("  score %.3f | terms %d (dec %d) | title_dec %d | chars %d",
                 s$score[i], s$n_tot[i], s$n_dec[i], s$title_dec[i], s$nchar[i]),
         sprintf("  TITLE: %s", ifelse(nzchar(s$title[i]), s$title[i], "(none)")),
         sprintf("  MATCHES:\n      %s", kwic[i]),
         sprintf("  TEXT: %s", gsub("\\s+", " ", substr(s$text_full[i], 1, READ))),
         "", strrep("-", 96), "")
}
cn <- file(file.path(OUT, "gate2_reject_readpack.txt"), open = "wb")
writeBin(charToRaw(enc2utf8(paste(L, collapse = "\n"))), cn); close(cn)
saveRDS(s[, c("id","url","date","platform","source","title","score","n_dec","n_amb","n_tot",
              "title_dec","title_any","in_master","nchar","v4_keep","v4_gate1","v4_vetoed",
              "text_full")],
        file.path(OUT, "gate2_reject_sample.rds"))
cat("\ndrawn:", nrow(s), "| v4 would still keep", sum(s$v4_keep),
    "| already in master", sum(s$in_master), "\n")
cat("wrote gate2_reject_readpack.txt\n")
