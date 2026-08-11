#!/usr/bin/env Rscript
# Score the TRACKED v2 term list (R/religious_terms_v2.R) against the 440 hand-coded items.
#
# Purpose: prove that the file we will actually run with encodes exactly the candidate rule that
# 03_candidate_rule.R measured, then extend the measurement to the nesting variants.
#
# Reads R/religious_terms.R only to reconstruct the candidate for the drift assertion; it is never
# modified. Prints aggregates only — no post text, titles or URLs (R/check_disclosure.R contract).
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")

d <- readRDS("studies/filter-validation/output/private/coded.rds")
d$truth <- d$label == "catholic_clear"
canon <- digikat_load_religious_terms()          # v1, frozen, 95 terms
v2    <- digikat_load_religious_terms_v2()       # v2, repaired + tiered, 94 terms

cat("v1 terms:", nrow(canon), "| v2 terms:", nrow(v2),
    "| decisive:", sum(v2$tier == "decisive"),
    "| ambiguous:", sum(v2$tier == "ambiguous"), "\n")

## ---- 1. drift assertion: v2 == the candidate 03_candidate_rule.R scored ---------------------
repairs <- c(
  "misa"        = "\\bmis[aeu]\\b|\\bmisi\\b|\\bmisom\\b|\\bmisama\\b|\\bmisn[aeiou]",
  "gospa"       = "\\bgosp[aeiu]\\b|\\bgospom\\b|\\bgospin[aeiou]*\\b",
  "papa"        = "\\bpap[aeiou]\\b|\\bpapom\\b|\\bpapin[aeiou]*\\b",
  "križ"        = "\\bkriž(a|u|em|evi|eva)?\\b",
  "demon"       = "\\bdemon(a|i|u|om|ima)?\\b|\\bdemonsk[aeiou]",
  "posvećenje"  = "\\bposvećenj[aeu]\\b",
  "ukazanje"    = "\\bukazanj[aeu]\\b",
  "kler"        = "\\bkler[aui]?\\b|\\bklerik",
  "kaptol"      = "\\bkaptol[aeiou]?\\b",
  "časna"       = NA_character_
)
cand <- canon
for (tm in names(repairs)) {
  i <- which(cand$term == tm)
  if (!length(i)) stop("expected v1 term missing: ", tm)
  if (is.na(repairs[[tm]])) cand <- cand[-i, ] else cand$regex[i] <- repairs[[tm]]
}
AMBIG <- c("misa","gospa","papa","križ","demon","posvećenje","ukazanje","kler",
           "kaptol","kršćanin","kršćanstvo","vatikan","duhovnost","blagoslov")
cand$tier <- ifelse(cand$term %in% AMBIG, "ambiguous", "decisive")

stopifnot(
  identical(v2$term,  cand$term),
  identical(v2$regex, cand$regex),
  identical(v2$root,  cand$root),
  identical(v2$tier,  cand$tier)
)
cat("DRIFT CHECK: v2 file is identical to the scored candidate — OK\n\n")

## ---- 2. scoring helpers ---------------------------------------------------------------------
wil <- function(k, n) {
  if (!n) return(c(NA, NA, NA))
  p <- k / n; z <- 1.96; den <- 1 + z^2 / n
  c(100 * p,
    100 * ((p + z^2 / (2 * n)) / den - z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den),
    100 * ((p + z^2 / (2 * n)) / den + z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / den))
}
score <- function(keep, name) {
  tp <- sum(keep & d$truth); fp <- sum(keep & !d$truth); fn <- sum(!keep & d$truth)
  pr <- wil(tp, tp + fp); rc <- wil(tp, tp + fn)
  data.frame(rule = name, kept = sum(keep),
             precision = round(pr[1], 1), p_lo = round(pr[2], 1), p_hi = round(pr[3], 1),
             recall = round(rc[1], 1), r_lo = round(rc[2], 1), r_hi = round(rc[3], 1),
             f1 = round(2 * pr[1] * rc[1] / max(1e-9, pr[1] + rc[1]), 1))
}

cat("scoring 440 items under v2...\n")
H  <- digikat_hit_matrix(d$text, v2)
HC <- digikat_collapse_nested(d$text, v2, H)      # nested matches removed
cnt  <- digikat_tier_counts(H,  v2)
cntC <- digikat_tier_counts(HC, v2)

base_mc <- digikat_match_religious(d$text, canon, min_matches = 2L,
                                   include_details = FALSE, progress = FALSE)$root_match_count

rows <- bind_rows(
  score(base_mc >= 2,                                    "CURRENT v1: any 2 of 95"),
  score(cnt$total_match_count >= 2,                      "v2 list, any 2"),
  score(cnt$total_match_count >= 3,                      "v2 list, any 3"),
  score(cnt$decisive_match_count >= 1,                   "v2 tiered: >=1 decisive"),
  score(cnt$decisive_match_count >= 2,                   "v2 tiered: >=2 decisive"),
  score(digikat_passes_inclusion_v2(cnt),                "v2 tiered: >=1 decisive AND >=2 total"),
  score(cnt$decisive_match_count >= 2 |
          (cnt$decisive_match_count >= 1 & cnt$ambiguous_match_count >= 2),
        "v2 tiered: 2 decisive OR 1 dec + 2 amb"),
  score(digikat_passes_inclusion_v2(cntC),               "v2 tiered + nesting collapsed"),
  score(cntC$total_match_count >= 2,                     "v2 any 2, nesting collapsed"),
  score(cntC$decisive_match_count >= 1,                  "v2 >=1 decisive, nesting collapsed")
)
cat("\n=== RULE COMPARISON on the 440 hand-coded items ===\n")
print(as.data.frame(rows), row.names = FALSE)

## ---- 3. the chosen rule, by stratum ----------------------------------------------------------
best <- digikat_passes_inclusion_v2(cnt)
cat("\n=== v2 tiered (>=1 decisive AND >=2 total), by stratum ===\n")
by_stratum <- bind_rows(lapply(sort(unique(d$stratum)), function(s) {
  k <- d$stratum == s
  data.frame(stratum = s, n = sum(k), truth = sum(d$truth[k]), kept = sum(best[k]),
             precision_v1 = round(100 * sum(d$truth[k]) / sum(k), 1),
             precision_v2 = round(100 * sum(best[k] & d$truth[k]) / max(1, sum(best[k])), 1),
             recall_v2    = round(100 * sum(best[k] & d$truth[k]) / max(1, sum(d$truth[k])), 1))
}))
print(as.data.frame(by_stratum), row.names = FALSE)

## ---- 4. how much of the corpus rests on a single nested token --------------------------------
inflated <- cnt$total_match_count >= 2 & cntC$total_match_count < 2
cat("\n=== nesting inflation ===\n")
cat("items passing 'any 2' only because of nested terms:", sum(inflated),
    sprintf("(%.1f%% of the %d that pass)\n", 100 * sum(inflated) / sum(cnt$total_match_count >= 2),
            sum(cnt$total_match_count >= 2)))
cat("of those, clearly Catholic:", sum(inflated & d$truth),
    sprintf("(%.1f%%)\n", 100 * sum(inflated & d$truth) / max(1, sum(inflated))))
infl_best <- best & !digikat_passes_inclusion_v2(cntC)
cat("items passing the TIERED rule only because of nested terms:", sum(infl_best),
    "| of those clearly Catholic:", sum(infl_best & d$truth), "\n")

## ---- 5. persist (ignored path: carries no text or URLs, but keep the study's convention) -----
out_dir <- "studies/filter-validation/output/private"
write.csv(rows,       file.path(out_dir, "v2_rule_scores.csv"),  row.names = FALSE, fileEncoding = "UTF-8")
write.csv(by_stratum, file.path(out_dir, "v2_by_stratum.csv"),   row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote v2_rule_scores.csv and v2_by_stratum.csv to", out_dir, "\n")
