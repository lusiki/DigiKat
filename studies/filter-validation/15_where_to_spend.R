#!/usr/bin/env Rscript
# 14_learning_curve.R showed the second-pass classifier plateaus around n = 220 — but 295 of those
# 402 items are master rows, and the population that decides the rebuild (new feed material) has
# only 104. This measures the MARGINAL value of a coded item drawn from that population, which is
# what "where should the next 400 go" actually asks.
# Aggregates only; no post text, titles or URLs.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
set.seed(20260808)
OUT <- "studies/filter-validation/output/private"

r1 <- readRDS(file.path(OUT, "coded.rds")); r2 <- readRDS(file.path(OUT, "holdout_coded.rds"))
pool <- bind_rows(
  data.frame(stratum = r1$stratum, label = r1$label, text = r1$text, stringsAsFactors = FALSE),
  data.frame(stratum = r2$stratum, label = r2$label, text = r2$text, stringsAsFactors = FALSE))
pool$y <- pool$label == "catholic_clear"
v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")
cnt <- digikat_tier_counts(digikat_hit_matrix(pool$text, v3), v3)
acc <- pool[digikat_passes_inclusion_v2(cnt), ]
cnt <- cnt[digikat_passes_inclusion_v2(cnt), ]
acc$n_dec <- cnt$decisive_match_count; acc$n_amb <- cnt$ambiguous_match_count
acc$feed <- acc$stratum %in% c("C", "S3")
cat("accepted items:", nrow(acc), "| from the feed population:", sum(acc$feed),
    sprintf("(%.1f%% genuine)\n", 100 * mean(acc$y[acc$feed])),
    "| from the master:", sum(!acc$feed),
    sprintf("(%.1f%% genuine)\n", 100 * mean(acc$y[!acc$feed])))

docs <- lapply(acc$text, function(x) {
  w <- unlist(stri_extract_all_regex(stri_trans_tolower(x), "[\\p{L}]{3,}"))
  if (!length(w)) character(0) else unique(stri_sub(w, 1, 6))
})
nb_score <- function(y, tr, min_df = 3L) {
  vt <- table(unlist(docs[tr])); vocab <- names(vt)[vt >= min_df]
  if (!length(vocab)) return(rep(0, length(docs)))
  ia <- table(unlist(docs[tr][y[tr]])); ib <- table(unlist(docs[tr][!y[tr]]))
  a <- as.numeric(ia[vocab]); a[is.na(a)] <- 0
  b <- as.numeric(ib[vocab]); b[is.na(b)] <- 0
  w <- log((a + 0.5) / (sum(y[tr]) + 1)) - log((b + 0.5) / (sum(!y[tr]) + 1)); names(w) <- vocab
  vapply(docs, function(d) { h <- w[intersect(d, vocab)]; if (length(h)) sum(h) else 0 }, numeric(1))
}
thr_for_recall <- function(score, y, target) {
  s <- sort(score[y], decreasing = TRUE); if (!length(s)) return(Inf)
  s[max(1L, floor(target * length(s)))]
}

y <- acc$y
feed_idx <- which(acc$feed); mast_idx <- which(!acc$feed)
TEST_N <- 34L; REPS <- 40L; TARGET <- 0.94

run <- function(k_feed) {
  out <- matrix(NA_real_, 0, 2)
  for (r in seq_len(REPS)) {
    te <- sample(feed_idx, TEST_N)
    trpool <- setdiff(feed_idx, te)
    tr <- c(mast_idx, if (k_feed > 0) sample(trpool, min(k_feed, length(trpool))) else integer(0))
    s <- nb_score(y, tr)
    df <- data.frame(nb = s, dec = acc$n_dec, amb = acc$n_amb, len = log1p(nchar(acc$text)))
    fit <- suppressWarnings(glm(y[tr] ~ nb + dec + amb + len, data = df[tr, ], family = binomial()))
    p <- as.numeric(predict(fit, newdata = df, type = "response"))
    th <- thr_for_recall(p[tr], y[tr], TARGET)
    keep <- p[te] >= th
    tp <- sum(keep & y[te]); fp <- sum(keep & !y[te]); fn <- sum(!keep & y[te])
    out <- rbind(out, c(100 * tp / max(1, tp + fp), 100 * tp / max(1, tp + fn)))
  }
  data.frame(feed_items_in_training = k_feed,
             precision = round(mean(out[, 1]), 1), recall = round(mean(out[, 2]), 1))
}

cat("\n=== precision on NEW FEED material, as feed-specific coded items are added ===\n")
cat("(second pass tuned to keep", round(100 * TARGET), "% of the genuine posts; test always 34 unseen feed items)\n")
cat("baseline, v3 alone on this population:",
    sprintf("precision %.1f, recall 100.0\n\n", 100 * mean(y[feed_idx])))
res <- bind_rows(lapply(c(0, 20, 40, 70), run))
print(as.data.frame(res), row.names = FALSE)

cat("\n=== the same, for the master population (where data is already plentiful) ===\n")
runm <- function(k) {
  out <- matrix(NA_real_, 0, 2)
  for (r in seq_len(REPS)) {
    te <- sample(mast_idx, 60L)
    trpool <- setdiff(mast_idx, te)
    tr <- c(feed_idx, sample(trpool, min(k, length(trpool))))
    s <- nb_score(y, tr)
    df <- data.frame(nb = s, dec = acc$n_dec, amb = acc$n_amb, len = log1p(nchar(acc$text)))
    fit <- suppressWarnings(glm(y[tr] ~ nb + dec + amb + len, data = df[tr, ], family = binomial()))
    p <- as.numeric(predict(fit, newdata = df, type = "response"))
    th <- thr_for_recall(p[tr], y[tr], TARGET)
    keep <- p[te] >= th
    tp <- sum(keep & y[te]); fp <- sum(keep & !y[te]); fn <- sum(!keep & y[te])
    out <- rbind(out, c(100 * tp / max(1, tp + fp), 100 * tp / max(1, tp + fn)))
  }
  data.frame(master_items_in_training = k, precision = round(mean(out[, 1]), 1),
             recall = round(mean(out[, 2]), 1))
}
cat("baseline, v3 alone on this population:",
    sprintf("precision %.1f, recall 100.0\n\n", 100 * mean(y[mast_idx])))
print(as.data.frame(bind_rows(lapply(c(0, 60, 120, 235), runm))), row.names = FALSE)

write.csv(res, file.path(OUT, "marginal_value_feed.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote marginal_value_feed.csv\n")
