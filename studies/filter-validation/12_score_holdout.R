#!/usr/bin/env Rscript
# The honest numbers: score v3 on the 300 held-out items nothing was tuned on.
# Stratified with unequal sampling fractions, so nothing may be pooled naively — each stratum is
# reported separately and combined only with measured population weights.
# Aggregates only; no post text, titles or URLs.
suppressPackageStartupMessages({library(DBI); library(duckdb); library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")

OUT <- "studies/filter-validation/output/private"
SEED <- 20260808L; FEED_POOL <- 40000L
DETERM_PATH <- "C:/Users/lsikic/Luka C/DetermDB/determDB.duckdb"

h  <- readRDS(file.path(OUT, "holdout_coded.rds"))
h$clear <- h$label == "catholic_clear"
h$loose <- h$label %in% c("catholic_clear", "catholic_mention")
v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")

wil <- function(k, n) {
  if (!n) return(c(NA, NA, NA))
  p <- k / n; z <- 1.96; den <- 1 + z^2 / n
  c(100 * p,
    100 * ((p + z^2 / (2*n)) / den - z * sqrt(p*(1-p)/n + z^2/(4*n^2)) / den),
    100 * ((p + z^2 / (2*n)) / den + z * sqrt(p*(1-p)/n + z^2/(4*n^2)) / den))
}
fmt <- function(k, n) { w <- wil(k, n); sprintf("%.1f [%.1f-%.1f]", w[1], w[2], w[3]) }

## ---- A. per-stratum, the primary result --------------------------------------------------------
LBL <- c(S1 = "master post-2024, v3 accepts", S2 = "master pre-2024, v3 accepts",
         S3 = "feed not in master, v3 accepts", S4 = "v3 rejects, >=1 term matched",
         S5 = "feed, zero terms matched")
cat("=== HELD-OUT RESULT: 300 items, nothing tuned on them ===\n\n")
A <- bind_rows(lapply(names(LBL), function(s) {
  i <- h$stratum == s
  data.frame(stratum = s, what = LBL[[s]], n = sum(i),
             clear = sum(h$clear[i]), strict = fmt(sum(h$clear[i]), sum(i)),
             loose = fmt(sum(h$loose[i]), sum(i)))
}))
print(as.data.frame(A), row.names = FALSE)

cat("\n=== round 1 (fitted) vs round 2 (honest), strict precision ===\n")
prev <- c(S1 = 78.8, S2 = 89.0, S3 = 59.3)
print(data.frame(
  stratum = names(prev),
  what = c("post-2024 corpus", "pre-2024 corpus", "what a rebuild ADDS"),
  fitted_r1 = unname(prev),
  honest_r2 = round(vapply(names(prev), function(s)
    100 * mean(h$clear[h$stratum == s]), numeric(1)), 1),
  drop = round(unname(prev) - vapply(names(prev), function(s)
    100 * mean(h$clear[h$stratum == s]), numeric(1)), 1)
), row.names = FALSE)

## ---- B. population weights, so recall can be estimated -----------------------------------------
cat("\nRe-deriving feed population weights (same reservoir draw as the sampler)...\n")
con <- dbConnect(duckdb::duckdb(), dbdir = DETERM_PATH, read_only = TRUE)
g <- dbGetQuery(con, sprintf("
  SELECT URL AS url, FULL_TEXT AS text_full FROM media_data
  WHERE FULL_TEXT IS NOT NULL AND LENGTH(FULL_TEXT) > 0
  USING SAMPLE reservoir(%d ROWS) REPEATABLE (%d)", FEED_POOL, SEED))
dbDisconnect(con, shutdown = TRUE)
H <- digikat_hit_matrix(g$text_full, v3, progress = TRUE)
cn <- digikat_tier_counts(H, v3)
g$keep <- digikat_passes_inclusion_v2(cn); g$tot <- cn$total_match_count

cat("Loading master URLs...\n")
m <- readRDS("data/merged_comprehensive.rds"); murl <- unique(as.character(m$URL))
rm(m); invisible(gc())
g$in_master <- g$url %in% murl

pop <- data.frame(
  group = c("accept, in master", "accept, new", "reject, >=1 term", "reject, zero terms"),
  n = c(sum(g$keep & g$in_master), sum(g$keep & !g$in_master),
        sum(!g$keep & g$tot >= 1L), sum(!g$keep & g$tot == 0L))
)
pop$share <- round(100 * pop$n / nrow(g), 2)
# precision measured for each group: in-master accepts ~ S2 (feed is 2021-2024 = pre-2024 stream)
pop$precision <- c(mean(h$clear[h$stratum == "S2"]), mean(h$clear[h$stratum == "S3"]),
                   mean(h$clear[h$stratum == "S4"]), mean(h$clear[h$stratum == "S5"]))
pop$true_posts <- pop$n * pop$precision
cat("\n=== feed population (", format(nrow(g), big.mark = " "), " sampled rows) ===\n", sep = "")
print(transform(pop, precision = round(100 * precision, 1),
                true_posts = round(true_posts, 0)), row.names = FALSE)

acc <- pop$true_posts[1] + pop$true_posts[2]
allt <- sum(pop$true_posts)
cat(sprintf("\nfeed-wide recall of v3: %.1f%%  (%.0f of an estimated %.0f genuinely Catholic posts)\n",
            100 * acc / allt, acc, allt))
cat(sprintf("feed-wide precision of v3: %.1f%%\n",
            100 * acc / (pop$n[1] + pop$n[2])))

## ---- C. what this means for the rebuild ---------------------------------------------------------
FEED_ROWS <- 19781689
scale <- FEED_ROWS / nrow(g)
cat("\n=== projected onto the full", format(FEED_ROWS, big.mark = " "), "row feed ===\n")
proj <- data.frame(
  quantity = c("v3 accepts (total)", "  of which already in master", "  NEW material a rebuild adds",
               "    genuinely Catholic", "    junk"),
  posts = round(c((pop$n[1] + pop$n[2]) * scale, pop$n[1] * scale, pop$n[2] * scale,
                  pop$n[2] * scale * pop$precision[2], pop$n[2] * scale * (1 - pop$precision[2])), -2)
)
print(proj, row.names = FALSE)
cat("\nRows with empty text are excluded by the query, so these are counts of postable rows.\n")

write.csv(A, file.path(OUT, "holdout_by_stratum.csv"), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(pop, file.path(OUT, "holdout_population.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote holdout_by_stratum.csv and holdout_population.csv\n")
