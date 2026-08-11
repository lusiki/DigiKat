#!/usr/bin/env Rscript
# Where did the recall go? Diagnose the 12 pp v2 gave up, using the v1 95-term list as the
# comparison signal. Aggregates and single word forms only — no text, titles or URLs.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")

d  <- readRDS("studies/filter-validation/output/private/coded.rds")
d$truth <- d$label == "catholic_clear"
v1 <- digikat_load_religious_terms()
v2 <- digikat_load_religious_terms_v2()

H1 <- digikat_hit_matrix(d$text, v1)
H2 <- digikat_hit_matrix(d$text, v2)
c2 <- digikat_tier_counts(H2, v2)
keep1 <- rowSums(H1) >= 2
keep2 <- digikat_passes_inclusion_v2(c2)

## ---- 1. the four-way table -------------------------------------------------------------------
cat("=== v1 (any 2 of 95) x v2 (>=1 decisive AND >=2 total), among the 176 truths ===\n")
print(table(v1_keeps = keep1, v2_keeps = keep2, clearly_catholic = d$truth))

lost <- keep1 & !keep2 & d$truth          # true positives v2 threw away
cat("\ntrue positives lost by v2:", sum(lost), "\n")
cat("their v2 counts (decisive, ambiguous):\n")
print(table(decisive = c2$decisive_match_count[lost], ambiguous = c2$ambiguous_match_count[lost]))

## ---- 2. which anchored pattern is too tight? -------------------------------------------------
# For each repaired term, the items v1 matched but v2 did not, split by truth — and the actual
# surface forms v1 caught, so an over-tight anchor is visible as a real inflection we dropped.
repaired <- c("misa","gospa","papa","križ","demon","posvećenje","ukazanje","kler","kaptol","časna")
cat("\n=== per repaired term: items v1 matched that v2 no longer matches ===\n")
tab <- bind_rows(lapply(repaired, function(tm) {
  i1 <- which(v1$term == tm)
  hit1 <- H1[, i1]
  i2 <- which(v2$term == tm)
  hit2 <- if (length(i2)) H2[, i2] else rep(FALSE, nrow(H2))
  dropped <- hit1 & !hit2
  data.frame(term = tm, v1_hits = sum(hit1), dropped = sum(dropped),
             dropped_true = sum(dropped & d$truth),
             dropped_false = sum(dropped & !d$truth),
             pct_true = round(100 * sum(dropped & d$truth) / max(1, sum(dropped)), 1))
}))
print(as.data.frame(tab), row.names = FALSE)

cat("\n=== surface forms v1 caught and v2 dropped, in CLEARLY CATHOLIC items ===\n")
cat("(a real inflection here means the anchor is too tight, not that the repair was wrong)\n")
for (tm in repaired) {
  i1 <- which(v1$term == tm)
  i2 <- which(v2$term == tm)
  hit2 <- if (length(i2)) H2[, i2] else rep(FALSE, nrow(H2))
  rows <- which(H1[, i1] & !hit2 & d$truth)
  if (!length(rows)) next
  forms <- unlist(lapply(rows, function(r) {
    w <- stri_extract_all_regex(d$text[r], v1$regex[[i1]],
                                opts_regex = list(case_insensitive = TRUE))[[1]]
    unique(stri_trans_tolower(w[!is.na(w)]))
  }))
  tf <- sort(table(forms), decreasing = TRUE)
  cat(sprintf("\n%-12s (%d items): %s\n", tm, length(rows),
              paste(sprintf("%s x%d", names(tf), as.integer(tf)), collapse = ", ")))
}

## ---- 3. truths v2 keeps no evidence for -----------------------------------------------------
none <- d$truth & c2$total_match_count == 0
cat("\n\n=== clearly Catholic items with ZERO v2 matches:", sum(none), "===\n")
if (sum(none)) {
  cat("their v1 matched terms (aggregate):\n")
  tt <- sort(table(unlist(lapply(which(none), function(r) v1$term[H1[r, ]]))), decreasing = TRUE)
  print(tt)
}

## ---- 4. per-term precision under v2, to test the tier assignment ------------------------------
cat("\n=== per-term precision among items v2 matches (tier sanity) ===\n")
pt <- bind_rows(lapply(seq_len(nrow(v2)), function(j) {
  k <- H2[, j]
  if (sum(k) < 5) return(NULL)
  data.frame(term = v2$term[j], tier = v2$tier[j], rows = sum(k),
             pct_catholic = round(100 * sum(k & d$truth) / sum(k), 1))
})) |> arrange(pct_catholic)
print(as.data.frame(pt), row.names = FALSE)
