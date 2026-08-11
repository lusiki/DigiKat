#!/usr/bin/env Rscript
# Would coding another 400 items actually raise precision? Answer it from the 740 already coded,
# before anyone reads anything.
#
# Architecture tested: keep v3 as the recall-oriented sieve, then add a SECOND-PASS classifier that
# removes junk from what v3 accepts. That is what extra coded data can buy — a keyword rule cannot
# learn, a classifier can. The learning curve says whether it is still learning at n = 421.
#
# Evaluation population: items v3 ACCEPTS (that is where the junk that matters lives).
# Metric: precision at matched recall, so a "gain" cannot come from silently dropping more posts.
# Aggregates only; no post text, titles or URLs.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
set.seed(20260808)
OUT <- "studies/filter-validation/output/private"

r1 <- readRDS(file.path(OUT, "coded.rds"))
r2 <- readRDS(file.path(OUT, "holdout_coded.rds"))
pool <- bind_rows(
  data.frame(round = 1L, stratum = r1$stratum, label = r1$label, text = r1$text,
             stringsAsFactors = FALSE),
  data.frame(round = 2L, stratum = r2$stratum, label = r2$label, text = r2$text,
             stringsAsFactors = FALSE)
)
pool$y <- pool$label == "catholic_clear"
cat("pooled coded items:", nrow(pool), "| clearly Catholic:", sum(pool$y), "\n")

v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")
H <- digikat_hit_matrix(pool$text, v3)
cnt <- digikat_tier_counts(H, v3)
pool$keep <- digikat_passes_inclusion_v2(cnt)
pool$n_dec <- cnt$decisive_match_count
pool$n_amb <- cnt$ambiguous_match_count

acc <- pool[pool$keep, ]
cat("items v3 accepts (the second-pass training set):", nrow(acc),
    sprintf("| of them genuine: %.1f%%\n", 100 * mean(acc$y)))
cat("  by round:", sum(acc$round == 1), "from round 1,", sum(acc$round == 2), "from round 2\n\n")

## ---- features ---------------------------------------------------------------------------------
# Crude Croatian normalisation: lowercase, keep letters, truncate each token to 6 characters so
# case/plural endings collapse (misa/mise/misi -> "misa"/"mise"... -> stem-ish). Tested against raw.
tok <- function(x, trunc = 6L) {
  w <- unlist(stri_extract_all_regex(stri_trans_tolower(x), "[\\p{L}]{3,}"))
  if (!length(w)) return(character(0))
  unique(if (trunc > 0) stri_sub(w, 1, trunc) else w)
}
build_docs <- function(trunc) lapply(acc$text, tok, trunc = trunc)

# Naive-Bayes style log-odds score, vocabulary and weights fitted on TRAIN only.
nb_score <- function(docs, y, tr, min_df = 3L) {
  vt <- table(unlist(docs[tr]))
  vocab <- names(vt)[vt >= min_df]
  if (!length(vocab)) return(rep(0, length(docs)))
  ia <- table(unlist(docs[tr][y[tr]]));  ib <- table(unlist(docs[tr][!y[tr]]))
  a <- as.numeric(ia[vocab]); a[is.na(a)] <- 0
  b <- as.numeric(ib[vocab]); b[is.na(b)] <- 0
  na <- sum(y[tr]); nb <- sum(!y[tr])
  w <- log((a + 0.5) / (na + 1)) - log((b + 0.5) / (nb + 1))
  names(w) <- vocab
  vapply(docs, function(d) { h <- w[intersect(d, vocab)]; if (length(h)) sum(h) else 0 }, numeric(1))
}

## ---- evaluation: precision at matched recall ----------------------------------------------------
# Threshold picked on TRAIN to reach the target recall, then applied to TEST. Recall target is what
# a second pass would be allowed to cost: keep 90% of the genuine posts v3 already found.
thr_for_recall <- function(score, y, target) {
  s <- sort(score[y], decreasing = TRUE)
  if (!length(s)) return(Inf)
  s[max(1L, floor(target * length(s)))]
}
run_cv <- function(docs, sizes, target_recall = 0.90, reps = 5, k = 5) {
  y <- acc$y
  res <- list()
  for (rep in seq_len(reps)) {
    f <- integer(length(y))
    f[y]  <- sample(rep_len(seq_len(k), sum(y)))
    f[!y] <- sample(rep_len(seq_len(k), sum(!y)))
    for (n_tr in sizes) {
      keep <- logical(length(y)); done <- TRUE
      for (fold in seq_len(k)) {
        tr_all <- which(f != fold); te <- which(f == fold)
        if (length(tr_all) < n_tr) { done <- FALSE; break }
        tr <- sample(tr_all, n_tr)
        s <- nb_score(docs, y, tr)
        df <- data.frame(nb = s, dec = acc$n_dec, amb = acc$n_amb,
                         len = log1p(nchar(acc$text)))
        fit <- suppressWarnings(glm(y[tr] ~ nb + dec + amb + len, data = df[tr, ],
                                    family = binomial()))
        p <- as.numeric(predict(fit, newdata = df, type = "response"))
        th <- thr_for_recall(p[tr], y[tr], target_recall)
        keep[te] <- p[te] >= th
      }
      if (!done) next
      tp <- sum(keep & y); fp <- sum(keep & !y); fn <- sum(!keep & y)
      res[[length(res) + 1]] <- data.frame(
        n_train = n_tr, precision = 100 * tp / max(1, tp + fp),
        recall = 100 * tp / max(1, tp + fn))
    }
  }
  bind_rows(res) |> group_by(n_train) |>
    summarise(precision = round(mean(precision), 1), recall = round(mean(recall), 1),
              .groups = "drop")
}

SIZES <- c(80, 120, 160, 220, 280, 336)      # 336 = 80% of the accepted pool
cat("=== does a second-pass classifier help, and is it still learning? ===\n")
cat("baseline = v3 alone, i.e. keep everything it accepts:",
    sprintf("precision %.1f, recall 100.0\n\n", 100 * mean(acc$y)))

for (tr in c(6L, 0L)) {
  docs <- build_docs(tr)
  cat("--- tokens", if (tr) "truncated to 6 chars" else "raw", "---\n")
  print(as.data.frame(run_cv(docs, SIZES)), row.names = FALSE)
  cat("\n")
}

## ---- where would 400 more items go furthest? ---------------------------------------------------
cat("=== how much coded data exists per population ===\n")
acc$pop <- ifelse(acc$stratum %in% c("A", "S1"), "master post-2024",
           ifelse(acc$stratum %in% c("B", "S2"), "master pre-2024",
           ifelse(acc$stratum %in% c("C", "S3"), "feed, new material", "other")))
print(acc |> group_by(pop) |>
        summarise(n = n(), genuine = round(100 * mean(y), 1), .groups = "drop") |>
        as.data.frame(), row.names = FALSE)

cat("\n=== how much of the junk is separable at all? ===\n")
docs <- build_docs(6L)
y <- acc$y
f <- integer(length(y))
f[y] <- sample(rep_len(1:5, sum(y))); f[!y] <- sample(rep_len(1:5, sum(!y)))
p <- numeric(length(y))
for (fold in 1:5) {
  tr <- which(f != fold); te <- which(f == fold)
  s <- nb_score(docs, y, tr)
  df <- data.frame(nb = s, dec = acc$n_dec, amb = acc$n_amb, len = log1p(nchar(acc$text)))
  fit <- suppressWarnings(glm(y[tr] ~ nb + dec + amb + len, data = df[tr, ], family = binomial()))
  p[te] <- as.numeric(predict(fit, newdata = df[te, ], type = "response"))
}
curve <- bind_rows(lapply(seq(0.99, 0.70, by = -0.05), function(t) {
  th <- thr_for_recall(p, y, t)
  k <- p >= th
  data.frame(recall_target = round(100 * t), kept = sum(k),
             precision = round(100 * sum(k & y) / max(1, sum(k)), 1),
             recall = round(100 * sum(k & y) / sum(y), 1))
}))
print(as.data.frame(curve), row.names = FALSE)
write.csv(curve, file.path(OUT, "second_pass_curve.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote second_pass_curve.csv\n")
