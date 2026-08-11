#!/usr/bin/env Rscript
# Can the identification be improved by using BOTH lists — the v1 95-term signal alongside the
# repaired v2 list — and by letting the coded data re-tier the terms?
#
# Anything tuned on the 440 items is reported under 5-fold CV (repeated 5x, stratified on the
# label) as well as fitted, because a fitted number on tuned rules is not a measurement.
# Aggregates only; no text, titles or URLs.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
set.seed(20260807)

d  <- readRDS("studies/filter-validation/output/private/coded.rds")
y  <- d$label == "catholic_clear"
v1 <- digikat_load_religious_terms()
v2 <- digikat_load_religious_terms_v2()

## ---- v2.1: two anchors widened -----------------------------------------------------------
# `\\bpapin[aeiou]*\\b` fails on papinom / papinim (trailing consonant); same for gospin*.
# Anchoring at the word START only is enough — nothing secular begins with papin/gospin.
v21 <- v2
v21$regex[v21$term == "papa"]  <- "\\bpap[aeiou]\\b|\\bpapom\\b|\\bpapin"
v21$regex[v21$term == "gospa"] <- "\\bgosp[aeiu]\\b|\\bgospom\\b|\\bgospin"

H1  <- digikat_hit_matrix(d$text, v1)
H2  <- digikat_hit_matrix(d$text, v2)
H21 <- digikat_hit_matrix(d$text, v21)

# v1-only evidence: the loose pattern fired where the repaired one did not.
shared <- intersect(v1$term, v2$term)
i1 <- match(shared, v1$term); i2 <- match(shared, v2$term)
V1ONLY <- H1[, i1, drop = FALSE] & !H2[, i2, drop = FALSE]
n_v1only <- as.integer(rowSums(V1ONLY)) +
  as.integer(H1[, which(v1$term == "časna")])   # dropped term counts as v1-only evidence

c2  <- digikat_tier_counts(H2,  v2)
c21 <- digikat_tier_counts(H21, v21)

## ---- scoring helpers -------------------------------------------------------------------------
prf <- function(keep, truth) {
  tp <- sum(keep & truth); fp <- sum(keep & !truth); fn <- sum(!keep & truth)
  p <- if (isTRUE(tp + fp > 0)) tp / (tp + fp) else NA_real_
  r <- if (isTRUE(tp + fn > 0)) tp / (tp + fn) else NA_real_
  c(precision = 100 * p, recall = 100 * r,
    f1 = if (is.na(p) || is.na(r) || p + r == 0) NA_real_ else 200 * p * r / (p + r))
}
folds <- function(y, k = 5) {           # stratified
  f <- integer(length(y))
  f[y]  <- sample(rep_len(seq_len(k), sum(y)))
  f[!y] <- sample(rep_len(seq_len(k), sum(!y)))
  f
}

# Empirical-Bayes per-term log-odds weight, shrunk toward the tier's own mean.
fit_weights <- function(H, terms, y, tr, alpha = 8) {
  base <- mean(y[tr])
  w <- numeric(ncol(H))
  for (j in seq_len(ncol(H))) {
    k <- H[tr, j]
    prior <- mean(y[tr][H[tr, terms$tier == terms$tier[j], drop = FALSE] |> rowSums() > 0])
    if (!is.finite(prior)) prior <- base
    p <- (sum(k & y[tr]) + alpha * prior) / (sum(k) + alpha)
    p <- min(max(p, 0.02), 0.98)
    w[j] <- log(p / (1 - p)) - log(base / (1 - base))
  }
  w
}
best_threshold <- function(score, y) {
  cand <- sort(unique(c(0, score)))
  f <- vapply(cand, function(t) {
    v <- prf(score >= t & score > 0, y)[["f1"]]
    if (is.na(v)) -1 else v
  }, numeric(1))
  cand[which.max(f)]
}

## ---- the candidate rules ----------------------------------------------------------------------
# Each returns a predicate builder: fit(train idx) -> function(all) -> logical keep
RULES <- list(
  "v1: any 2 of 95 (no fitting)" = function(tr) function() rowSums(H1) >= 2,
  "v2 tiered (no fitting)"       = function(tr) function() digikat_passes_inclusion_v2(c2),
  "v2.1 widened anchors (no fitting)" = function(tr) function() digikat_passes_inclusion_v2(c21),
  "v2.1 + v1-only as weak 3rd tier" = function(tr) function()
    c21$decisive_match_count >= 1 & (c21$total_match_count + (n_v1only >= 2)) >= 2,
  "v2.1, re-tiered from data" = function(tr) {
    prec <- vapply(seq_len(ncol(H21)), function(j)
      if (sum(H21[tr, j]) >= 3) sum(H21[tr, j] & y[tr]) / sum(H21[tr, j]) else NA_real_, numeric(1))
    cut <- 0.80
    dec <- ifelse(is.na(prec), v21$tier == "decisive", prec >= cut)
    function() {
      nd <- rowSums(H21[, dec, drop = FALSE]); nt <- rowSums(H21)
      nd >= 1 & nt >= 2
    }
  },
  "weighted terms (v2.1)" = function(tr) {
    w <- fit_weights(H21, v21, y, tr)
    s_all <- as.numeric(H21 %*% w)
    th <- best_threshold(s_all[tr], y[tr])
    function() s_all >= th & rowSums(H21) > 0
  },
  "weighted terms (v2.1) + v1-only count" = function(tr) {
    w <- fit_weights(H21, v21, y, tr)
    df <- data.frame(s0 = as.numeric(H21 %*% w), v1o = n_v1only)
    fit <- suppressWarnings(glm(y[tr] ~ s0 + v1o, data = df[tr, ], family = binomial()))
    p_all <- as.numeric(predict(fit, newdata = df, type = "response"))
    th <- best_threshold(p_all[tr], y[tr])
    function() p_all >= th & (rowSums(H21) > 0 | n_v1only > 0)
  },
  "logistic on (decisive, ambiguous, v1-only)" = function(tr) {
    df <- data.frame(dec = c21$decisive_match_count, amb = c21$ambiguous_match_count,
                     v1o = n_v1only)
    fit <- glm(y[tr] ~ dec + amb + v1o, data = df[tr, ], family = binomial())
    p_all <- as.numeric(predict(fit, newdata = df, type = "response"))
    th <- best_threshold(p_all[tr], y[tr])
    function() p_all >= th
  }
)

## ---- fitted vs cross-validated ------------------------------------------------------------
all_idx <- seq_along(y)
res <- lapply(names(RULES), function(nm) {
  fitted <- prf(RULES[[nm]](all_idx)(), y)                 # tuned and scored on everything
  cvp <- matrix(NA_real_, nrow = 0, ncol = 3)
  for (rep in 1:5) {
    f <- folds(y, 5)
    keep <- logical(length(y))
    for (k in 1:5) {
      tr <- which(f != k); te <- which(f == k)
      keep[te] <- RULES[[nm]](tr)()[te]
    }
    cvp <- rbind(cvp, prf(keep, y))
  }
  data.frame(rule = nm,
             fit_P = round(fitted[["precision"]], 1), fit_R = round(fitted[["recall"]], 1),
             fit_F1 = round(fitted[["f1"]], 1),
             cv_P = round(mean(cvp[, 1]), 1), cv_R = round(mean(cvp[, 2]), 1),
             cv_F1 = round(mean(cvp[, 3]), 1))
}) |> bind_rows()

cat("\n=== fitted vs 5-fold CV (5 repeats), 440 coded items ===\n")
cat("the first three rules involve no fitting, so fit == cv up to fold noise\n\n")
print(as.data.frame(res), row.names = FALSE)

## ---- what the widened anchors alone buy ------------------------------------------------------
k2  <- digikat_passes_inclusion_v2(c2)
k21 <- digikat_passes_inclusion_v2(c21)
cat("\n=== v2 -> v2.1 (widened papin/gospin anchors only) ===\n")
cat("items gained:", sum(k21 & !k2), "| of them clearly Catholic:", sum(k21 & !k2 & y),
    "| items lost:", sum(k2 & !k21), "\n")

cat("\n=== how good is v1-only evidence on its own? ===\n")
print(data.frame(v1only_matches = 0:3,
                 n = as.integer(table(factor(pmin(n_v1only, 3), levels = 0:3))),
                 pct_catholic = round(100 * tapply(y, pmin(n_v1only, 3), mean), 1)),
      row.names = FALSE)

write.csv(res, "studies/filter-validation/output/private/v2_improvement_cv.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote v2_improvement_cv.csv\n")
