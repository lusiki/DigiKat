#!/usr/bin/env Rscript
# Can the second pass be made smarter without more coding? Four things the current version ignores:
#
#   1. THE TITLE. A religious word in the headline is much stronger evidence than one in
#      paragraph nine. We are currently throwing the title away entirely.
#   2. HOW OFTEN, not just whether. "biskup" once vs eleven times is a different post.
#   3. WHERE IN THE TEXT. A post about the Church has religious words throughout; a post that
#      mentions one in passing has a single cluster. Measured by splitting the text in five and
#      counting how many fifths contain a match.
#   4. DENSITY. Matches per 1000 characters, so a long article with two mentions scores low.
#
# Everything is computed from the match POSITIONS of the patterns that already fired, so it costs
# almost nothing extra at scale. Evaluated out-of-fold, at a fixed keep-90% operating point.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
set.seed(20260808)
OUT <- "studies/filter-validation/output/private"; CAP <- 3000L

r1 <- readRDS(file.path(OUT, "coded.rds")); r2 <- readRDS(file.path(OUT, "holdout_coded.rds"))
pool <- bind_rows(
  data.frame(stratum = r1$stratum, label = r1$label, title = r1$title, text = r1$text,
             stringsAsFactors = FALSE),
  data.frame(stratum = r2$stratum, label = r2$label, title = r2$title, text = r2$text,
             stringsAsFactors = FALSE))
pool$y <- pool$label == "catholic_clear"
v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")
H <- digikat_hit_matrix(pool$text, v3); cn <- digikat_tier_counts(H, v3)
ok <- digikat_passes_inclusion_v2(cn)
acc <- pool[ok, ]; H <- H[ok, , drop = FALSE]; cn <- cn[ok, ]
y <- acc$y
cat("accepted coded items:", nrow(acc), sprintf("| genuine %.1f%%\n", 100 * mean(y)))

## ---- the new features --------------------------------------------------------------------------
txt <- substr(acc$text, 1, CAP)
dec <- v3$tier == "decisive"
extra <- t(vapply(seq_len(nrow(acc)), function(i) {
  hits <- which(H[i, ]); n <- nchar(txt[i])
  if (!length(hits) || is.na(n) || n == 0) return(c(0, 0, 0, 0, 0, 0))
  loc <- do.call(rbind, lapply(hits, function(j) {
    m <- stri_locate_all_regex(txt[i], v3$regex[[j]],
                               opts_regex = list(case_insensitive = TRUE))[[1]]
    m <- m[!is.na(m[, 1]), , drop = FALSE]
    if (!nrow(m)) NULL else cbind(m, decisive = as.integer(dec[j]))
  }))
  if (is.null(loc) || !nrow(loc)) return(c(0, 0, 0, 0, 0, 0))
  fifths <- length(unique(pmin(5L, 1L + floor(5 * (loc[, 1] - 1) / n))))
  c(occurrences   = nrow(loc),
    dec_occur     = sum(loc[, "decisive"] == 1L),
    density_1k    = 1000 * nrow(loc) / n,
    spread_fifths = fifths,
    first_at      = min(loc[, 1]) / n,
    last_at       = max(loc[, 2]) / n)
}, numeric(6)))
colnames(extra) <- c("occ", "dec_occ", "dens", "spread", "first_at", "last_at")

ttl <- ifelse(is.na(acc$title), "", acc$title)
Ht <- digikat_hit_matrix(ttl, v3)
title_dec <- as.integer(rowSums(Ht[, dec, drop = FALSE]) > 0)
title_any <- as.integer(rowSums(Ht) > 0)
cat("posts with a religious word in the title:", sum(title_any),
    sprintf("(%.0f%% of them genuine, vs %.0f%% of the rest)\n",
            100 * mean(y[title_any == 1]), 100 * mean(y[title_any == 0])))
cat("posts with a DECISIVE word in the title :", sum(title_dec),
    sprintf("(%.0f%% genuine)\n\n", 100 * mean(y[title_dec == 1])))

## ---- shared machinery --------------------------------------------------------------------------
docs <- lapply(txt, function(x) {
  if (is.na(x) || !nzchar(x)) return(character(0))
  w <- unlist(stri_extract_all_regex(stri_trans_tolower(x), "[\\p{L}]{3,}"))
  if (!length(w)) character(0) else unique(stri_sub(w, 1, 6))
})
base <- data.frame(dec = cn$decisive_match_count, amb = cn$ambiguous_match_count,
                   len = log1p(nchar(txt)))
FEATS <- list(
  "current (words + counts + length)" = base,
  "+ title"                           = cbind(base, title_dec = title_dec, title_any = title_any),
  "+ how often / where / density"     = cbind(base, extra),
  "+ everything"                      = cbind(base, title_dec = title_dec, title_any = title_any, extra)
)

oof_eval <- function(X, reps = 4L, keep = 0.90) {
  oof_s <- numeric(nrow(acc)); oof_n <- integer(nrow(acc))
  for (rep in seq_len(reps)) {
    f <- integer(nrow(acc)); f[y] <- sample(rep_len(1:5, sum(y)))
    f[!y] <- sample(rep_len(1:5, sum(!y)))
    for (fold in 1:5) {
      tr <- which(f != fold); te <- which(f == fold)
      vt <- table(unlist(docs[tr])); vocab <- names(vt)[vt >= 3L]
      ia <- table(unlist(docs[tr][y[tr]])); ib <- table(unlist(docs[tr][!y[tr]]))
      a <- as.numeric(ia[vocab]); a[is.na(a)] <- 0
      b <- as.numeric(ib[vocab]); b[is.na(b)] <- 0
      w <- log((a + .5) / (sum(y[tr]) + 1)) - log((b + .5) / (sum(!y[tr]) + 1)); names(w) <- vocab
      nb <- vapply(docs, function(d) { h <- w[intersect(d, vocab)]
        if (length(h)) sum(h) else 0 }, numeric(1))
      df <- cbind(X, nb = nb)
      # response must be a NAMED column so that "." excludes it — passing y[tr] as an expression
      # lets "." pull the label in as its own predictor.
      d_tr <- cbind(df[tr, , drop = FALSE], yy = y[tr])
      g <- suppressWarnings(glm(yy ~ ., data = d_tr, family = binomial()))
      p <- as.numeric(predict(g, newdata = df[te, , drop = FALSE], type = "response"))
      oof_s[te] <- oof_s[te] + p; oof_n[te] <- oof_n[te] + 1L
    }
  }
  s <- oof_s / oof_n
  th <- { v <- sort(s[y], decreasing = TRUE); v[max(1L, floor(keep * length(v)))] }
  k <- s >= th
  fe <- acc$stratum %in% c("C", "S3")
  data.frame(
    precision_all  = round(100 * sum(k & y) / sum(k), 1),
    recall_all     = round(100 * sum(k & y) / sum(y), 1),
    precision_feed = round(100 * sum(k[fe] & y[fe]) / max(1, sum(k[fe])), 1),
    recall_feed    = round(100 * sum(k[fe] & y[fe]) / max(1, sum(y[fe])), 1))
}

cat("=== out-of-fold, threshold set to keep 90% of the genuine posts ===\n")
cat("baseline with no second pass at all: precision", round(100 * mean(y), 1),
    "| on new feed material", round(100 * mean(y[acc$stratum %in% c("C", "S3")]), 1), "\n\n")
res <- bind_rows(lapply(names(FEATS), function(nm)
  cbind(data.frame(features = nm), oof_eval(FEATS[[nm]]))))
print(as.data.frame(res), row.names = FALSE)
write.csv(res, file.path(OUT, "feature_comparison.csv"), row.names = FALSE, fileEncoding = "UTF-8")
