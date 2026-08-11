#!/usr/bin/env Rscript
# The recall v2 gives up is not recoverable from the two term lists (06_improve_rule.R). So is it
# recoverable from VOCABULARY the lists do not contain? Find tokens that predict "clearly Catholic"
# and are matched by no v2 pattern, then cross-validate what adding them actually buys.
# Prints candidate WORD FORMS and counts only — no text, titles or URLs.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
set.seed(20260807)

d  <- readRDS("studies/filter-validation/output/private/coded.rds")
y  <- d$label == "catholic_clear"
v2 <- digikat_load_religious_terms_v2()
H2 <- digikat_hit_matrix(d$text, v2)
c2 <- digikat_tier_counts(H2, v2)
keep2 <- digikat_passes_inclusion_v2(c2)

## ---- document-term presence ------------------------------------------------------------------
toks <- lapply(d$text, function(x) {
  if (is.na(x) || !nzchar(x)) return(character(0))
  unique(stri_trans_tolower(unlist(
    stri_extract_all_regex(x, "[\\p{L}][\\p{L}]{3,}", opts_regex = list(case_insensitive = TRUE))
  )))
})
vocab <- sort(unique(unlist(toks)))
cat("documents:", length(toks), "| distinct tokens (>=4 letters):", length(vocab), "\n")

df_cat <- integer(length(vocab)); names(df_cat) <- vocab
df_non <- df_cat
for (i in seq_along(toks)) {
  if (!length(toks[[i]])) next
  j <- match(toks[[i]], vocab)
  if (y[i]) df_cat[j] <- df_cat[j] + 1L else df_non[j] <- df_non[j] + 1L
}

## ---- drop anything the v2 list already covers -------------------------------------------------
covered <- stri_detect_regex(
  vocab, paste0("(", paste(v2$regex, collapse = ")|("), ")"),
  opts_regex = list(case_insensitive = TRUE)
)
cat("tokens already matched by a v2 pattern:", sum(covered), "\n")

nA <- sum(y); nB <- sum(!y)
cand <- data.frame(token = vocab, cat = as.integer(df_cat), non = as.integer(df_non),
                   covered = covered, stringsAsFactors = FALSE) |>
  mutate(logodds = log(((cat + 0.5) / (nA + 1)) / ((non + 0.5) / (nB + 1)))) |>
  filter(!covered, cat >= 5) |>
  arrange(desc(logodds))

cat("\n=== top uncovered tokens predicting 'clearly Catholic' (present in >=5 Catholic items) ===\n")
print(head(as.data.frame(cand[, c("token", "cat", "non", "logodds")]), 45), row.names = FALSE)

## ---- what is in the items v2 misses? -----------------------------------------------------------
missed <- y & !keep2
cat("\n=== uncovered tokens inside the", sum(missed), "clearly Catholic items v2 drops ===\n")
in_missed <- vapply(cand$token, function(t)
  sum(vapply(toks[missed], function(z) t %in% z, logical(1))), integer(1))
cm <- cand |> mutate(in_missed = in_missed) |> filter(in_missed >= 2) |>
  arrange(desc(in_missed), desc(logodds))
print(head(as.data.frame(cm[, c("token", "in_missed", "cat", "non", "logodds")]), 30),
      row.names = FALSE)

## ---- honest test: select candidate terms on the TRAIN fold only ---------------------------------
prf <- function(keep, truth) {
  tp <- sum(keep & truth); fp <- sum(keep & !truth); fn <- sum(!keep & truth)
  p <- if (isTRUE(tp + fp > 0)) tp / (tp + fp) else NA_real_
  r <- if (isTRUE(tp + fn > 0)) tp / (tp + fn) else NA_real_
  c(100 * p, 100 * r, if (is.na(p) || is.na(r) || p + r == 0) NA_real_ else 200 * p * r / (p + r))
}
# presence matrix restricted to the candidate pool (all uncovered tokens seen >=5 times anywhere)
pool <- cand$token
P <- matrix(FALSE, nrow = length(toks), ncol = length(pool), dimnames = list(NULL, pool))
for (i in seq_along(toks)) if (length(toks[[i]])) {
  j <- match(intersect(toks[[i]], pool), pool); P[i, j[!is.na(j)]] <- TRUE
}

cv_add <- function(k, reps = 5) {
  out <- matrix(NA_real_, 0, 3)
  for (rep in seq_len(reps)) {
    f <- integer(length(y))
    f[y]  <- sample(rep_len(1:5, sum(y)));  f[!y] <- sample(rep_len(1:5, sum(!y)))
    keep <- logical(length(y))
    for (fold in 1:5) {
      tr <- f != fold; te <- which(f == fold)
      ca <- colSums(P[tr, , drop = FALSE] &  y[tr])
      cb <- colSums(P[tr, , drop = FALSE] & !y[tr])
      lo <- log(((ca + 0.5) / (sum(y[tr]) + 1)) / ((cb + 0.5) / (sum(!y[tr]) + 1)))
      sel <- names(sort(lo[ca >= 4], decreasing = TRUE))[seq_len(k)]
      sel <- sel[!is.na(sel)]
      extra <- if (length(sel)) rowSums(P[, sel, drop = FALSE]) else rep(0L, length(y))
      nd <- c2$decisive_match_count + extra          # new terms enter as DECISIVE
      nt <- c2$total_match_count + extra
      keep[te] <- (nd >= 1 & nt >= 2)[te]
    }
    out <- rbind(out, prf(keep, y))
  }
  data.frame(added_terms = k, cv_P = round(mean(out[, 1]), 1),
             cv_R = round(mean(out[, 2]), 1), cv_F1 = round(mean(out[, 3]), 1))
}
cat("\n=== adding data-selected vocabulary as decisive terms (selection inside CV) ===\n")
base <- prf(keep2, y)
print(bind_rows(
  data.frame(added_terms = 0L, cv_P = round(base[1], 1), cv_R = round(base[2], 1),
             cv_F1 = round(base[3], 1)),
  bind_rows(lapply(c(5, 10, 20, 40), cv_add))
), row.names = FALSE)

write.csv(head(as.data.frame(cand), 100),
          "studies/filter-validation/output/private/vocab_candidates.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote vocab_candidates.csv (top 100)\n")
