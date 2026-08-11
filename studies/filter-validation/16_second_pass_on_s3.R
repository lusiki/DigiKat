#!/usr/bin/env Rscript
# The decision number, measured on the right slice. 15_where_to_spend.R pooled round-1 stratum C
# with round-2 S3; C items that v3 accepts passed BOTH rules and are much cleaner, which inflates
# the baseline. This evaluates the second pass on S3 ONLY — the honest rebuild population.
# Aggregates only.
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
cn <- digikat_tier_counts(digikat_hit_matrix(pool$text, v3), v3)
ok <- digikat_passes_inclusion_v2(cn)
acc <- pool[ok, ]; cn <- cn[ok, ]
acc$n_dec <- cn$decisive_match_count; acc$n_amb <- cn$ambiguous_match_count

docs <- lapply(acc$text, function(x) {
  w <- unlist(stri_extract_all_regex(stri_trans_tolower(x), "[\\p{L}]{3,}"))
  if (!length(w)) character(0) else unique(stri_sub(w, 1, 6))
})
nb_score <- function(y, tr, min_df = 3L) {
  vt <- table(unlist(docs[tr])); vocab <- names(vt)[vt >= min_df]
  ia <- table(unlist(docs[tr][y[tr]])); ib <- table(unlist(docs[tr][!y[tr]]))
  a <- as.numeric(ia[vocab]); a[is.na(a)] <- 0
  b <- as.numeric(ib[vocab]); b[is.na(b)] <- 0
  w <- log((a + .5) / (sum(y[tr]) + 1)) - log((b + .5) / (sum(!y[tr]) + 1)); names(w) <- vocab
  vapply(docs, function(d) { h <- w[intersect(d, vocab)]; if (length(h)) sum(h) else 0 }, numeric(1))
}
thr <- function(s, y, t) { v <- sort(s[y], decreasing = TRUE); if (!length(v)) Inf else v[max(1L, floor(t * length(v)))] }

y <- acc$y
s3 <- which(acc$stratum == "S3"); rest <- setdiff(seq_along(y), s3)
cat("S3 items v3 accepts:", length(s3), sprintf("(%.1f%% genuine)\n", 100 * mean(y[s3])))
cat("training material available elsewhere:", length(rest), "items\n\n")

evaluate <- function(target, reps = 40L, test_n = 30L) {
  out <- matrix(NA_real_, 0, 2)
  for (r in seq_len(reps)) {
    te <- sample(s3, test_n); tr <- c(rest, setdiff(s3, te))
    s <- nb_score(y, tr)
    df <- data.frame(nb = s, dec = acc$n_dec, amb = acc$n_amb, len = log1p(nchar(acc$text)))
    fit <- suppressWarnings(glm(y[tr] ~ nb + dec + amb + len, data = df[tr, ], family = binomial()))
    p <- as.numeric(predict(fit, newdata = df, type = "response"))
    k <- p[te] >= thr(p[tr], y[tr], target)
    tp <- sum(k & y[te]); fp <- sum(k & !y[te]); fn <- sum(!k & y[te])
    out <- rbind(out, c(100 * tp / max(1, tp + fp), 100 * tp / max(1, tp + fn)))
  }
  data.frame(keep_target = paste0(round(100 * target), "%"),
             precision = round(mean(out[, 1]), 1), recall = round(mean(out[, 2]), 1))
}

cat("=== second pass on NEW FEED MATERIAL (S3), the rebuild population ===\n")
cat("v3 alone:", sprintf("precision %.1f, recall 100.0\n\n", 100 * mean(y[s3])))
print(as.data.frame(bind_rows(lapply(c(0.98, 0.94, 0.90, 0.85), evaluate))), row.names = FALSE)

## what the rebuild looks like with a second pass at the 94% setting
e <- evaluate(0.94)
p_new <- e$precision / 100; r_new <- e$recall / 100
popf <- read.csv(file.path(OUT, "holdout_population.csv"), stringsAsFactors = FALSE)
scale <- 19781689 / sum(popf$n)
n_add <- popf$n[popf$group == "accept, new"] * scale
n_old <- popf$n[popf$group == "accept, in master"] * scale
p_old <- popf$precision[popf$group == "accept, in master"]
cat(sprintf("\n=== rebuild with a second pass (keep %.0f%% of what v3 found) ===\n", 100 * r_new))
cat(sprintf("new material admitted : %s posts, %.1f%% genuine (was %s posts at %.1f%%)\n",
            format(round(n_add * r_new * p_old / p_old, -2), big.mark = " "),
            e$precision, format(round(n_add, -2), big.mark = " "),
            100 * popf$precision[popf$group == "accept, new"]))
kept_new <- n_add * (r_new * popf$precision[popf$group == "accept, new"]) / p_new
cat(sprintf("  approx %s admitted, of which approx %s genuine and %s junk\n",
            format(round(kept_new, -2), big.mark = " "),
            format(round(kept_new * p_new, -2), big.mark = " "),
            format(round(kept_new * (1 - p_new), -2), big.mark = " ")))
