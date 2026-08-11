#!/usr/bin/env Rscript
# CANDIDATE vocabulary expansion. 07_vocabulary_gap.R showed the lost recall is a vocabulary hole,
# not a rule problem: the 95-term list has *župnik* but not *župa*, *pobožnost* but not *molitva*,
# and nothing at all for Bog, Isus, Krist, vjernik, samostan, propovijed, krštenje.
#
# This hand-curates the automatic candidates into proper Croatian patterns in the house style
# (roots + case/plural alternations, word-anchored where a secular homonym exists) and scores them.
# CANDIDATE ONLY — does not touch R/religious_terms.R or R/religious_terms_v2.R.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")

d  <- readRDS("studies/filter-validation/output/private/coded.rds")
y  <- d$label == "catholic_clear"
v2 <- digikat_load_religious_terms_v2()

## ---- the curated expansion ---------------------------------------------------------------------
# Each pattern was written from the morphology, then checked against the secular word it must NOT
# match (third column). Artifacts from the automatic list (konferencije, ispis, prisutnosti, srcem,
# sati, video, ljudski) are deliberately excluded — they are corpus noise, not Catholic vocabulary.
EXPANSION <- tibble::tribble(
  ~term,             ~regex,                                              ~tier,       ~must_not_match,
  "molitva",         "\\bmolitv[aeiou][jmz]*\\b",                         "decisive",  "molim",
  "vjernik",         "\\bvjerni[ck][aeiou]?[jmz]*\\b",                    "decisive",  "vjerojatno",
  "župa",            "\\bžup[aeiou]\\b|\\bžupn[aeiou]",                   "decisive",  "županija",
  "krist",           "\\bkrist[aeou]?[mv]*\\b|\\bkristov",                "decisive",  "kristal",
  "isus",            "\\bisus[aeou]?[mv]*\\b|\\bisusov",                  "decisive",  "isušiti",
  "božji",           "\\bbožj[aeiou][mg]*[aeiou]*\\b",                    "decisive",  "božićni",
  "propovijed",      "\\bpropovijed[aeiou]?[jmiz]*\\b|\\bpropovjedni",    "decisive",  NA,
  "homilija",        "\\bhomilij[aeiou][jmz]*\\b",                        "decisive",  NA,
  "samostan",        "\\bsamostan[aeiou]?[mz]*\\b|\\bsamostansk[aeiou]",  "decisive",  NA,
  "svetkovina",      "\\bsvetkovin[aeiou][jmz]*\\b",                      "decisive",  NA,
  "krštenje",        "\\bkršten[aeiou]?[jmz]*\\b",                        "decisive",  NA,
  "apostol",         "\\bapostol[aeiou]?[mz]*\\b|\\bapostolsk[aeiou]",    "decisive",  NA,
  "prorok",          "\\bprorok[aeiou]?[mz]*\\b|\\bproro[cč][aeiou]",     "decisive",  NA,
  "oltar",           "\\boltar[aeiou]?[mz]*\\b|\\boltarsk[aeiou]",        "decisive",  NA,
  "procesija",       "\\bprocesij[aeiou][jmz]*\\b",                       "decisive",  NA,
  "spasenje",        "\\bspasenj[aeu]\\b",                                "decisive",  "spasilac",
  "milosrđe",        "\\bmilosrđ[aeu]\\b|\\bmilosrdn[aeiou]",             "decisive",  NA,
  "vjeroučitelj",    "\\bvjerouč[aeiou]?[a-zšđčćž]*",                     "decisive",  NA,
  "klanjanje",       "\\bklanjanj[aeu]\\b",                               "decisive",  NA,
  "djevica marija",  "\\bdjevic[aeiou]\\s+marij[aeiou]|\\bblažen[aeiou][jmz]*\\s+djevic",
                                                                          "decisive",  NA,
  # ambiguous: real religious use, but the same word is ordinary Croatian
  "bog",             "\\bbog[au]?\\b|\\bbogom\\b|\\bbogu\\b",             "ambiguous", "bogatstvo",
  "vjera",           "\\bvjer[aeiou]\\b|\\bvjerom\\b",                    "ambiguous", "vjerojatno",
  "blaženi",         "\\bblažen[aeiou][jmz]*\\b",                         "ambiguous", NA,
  "kapela",          "\\bkapel[aeiou][mz]*\\b",                           "ambiguous", "kapelan",
  "duša",            "\\bduš[aeiou]\\b|\\bdušom\\b",                      "ambiguous", "dušik"
) |> as.data.frame()

## ---- guard: every pattern compiles, and rejects its secular homonym ---------------------------
for (i in seq_len(nrow(EXPANSION))) {
  ok <- stri_detect_regex("", EXPANSION$regex[i], opts_regex = list(case_insensitive = TRUE))
  if (is.na(ok)) stop("regex fails to compile: ", EXPANSION$term[i])
  mn <- EXPANSION$must_not_match[i]
  if (!is.na(mn) && stri_detect_regex(mn, EXPANSION$regex[i],
                                      opts_regex = list(case_insensitive = TRUE)))
    stop("pattern for '", EXPANSION$term[i], "' wrongly matches '", mn, "'")
}
if (any(EXPANSION$term %in% v2$term)) stop("expansion duplicates an existing term")
cat("expansion: ", nrow(EXPANSION), " terms (",
    sum(EXPANSION$tier == "decisive"), " decisive, ",
    sum(EXPANSION$tier == "ambiguous"), " ambiguous) — all compile, all reject their homonym\n",
    sep = "")

v3 <- bind_rows(
  v2[, c("term", "regex", "tier")],
  EXPANSION[, c("term", "regex", "tier")]
)
cat("v2: ", nrow(v2), " terms -> v3 candidate: ", nrow(v3), " terms\n\n", sep = "")

## ---- score ---------------------------------------------------------------------------------
prf <- function(keep, truth) {
  tp <- sum(keep & truth); fp <- sum(keep & !truth); fn <- sum(!keep & truth)
  p <- if (isTRUE(tp + fp > 0)) tp / (tp + fp) else NA_real_
  r <- if (isTRUE(tp + fn > 0)) tp / (tp + fn) else NA_real_
  c(kept = sum(keep), precision = round(100 * p, 1), recall = round(100 * r, 1),
    f1 = round(if (is.na(p) || is.na(r)) NA_real_ else 200 * p * r / (p + r), 1))
}
H2 <- digikat_hit_matrix(d$text, v2);  c2 <- digikat_tier_counts(H2, v2)
H3 <- digikat_hit_matrix(d$text, v3);  c3 <- digikat_tier_counts(H3, v3)
k2 <- digikat_passes_inclusion_v2(c2)
k3 <- digikat_passes_inclusion_v2(c3)

cat("=== 440 hand-coded items ===\n")
print(bind_rows(
  data.frame(rule = "v1: any 2 of 95",           t(prf(rowSums(digikat_hit_matrix(d$text,
                digikat_load_religious_terms())) >= 2, y))),
  data.frame(rule = "v2 tiered (94 terms)",      t(prf(k2, y))),
  data.frame(rule = "v3 tiered (119 terms)",     t(prf(k3, y))),
  data.frame(rule = "v3, decisive expansion only",
             t(prf({ dv <- v3$term %in% c(v2$term, EXPANSION$term[EXPANSION$tier == "decisive"])
                     Hx <- H3[, dv, drop = FALSE]; vx <- v3[dv, ]
                     cx <- digikat_tier_counts(Hx, vx); digikat_passes_inclusion_v2(cx) }, y)))
), row.names = FALSE)

cat("\n=== by stratum: v2 -> v3 ===\n")
print(bind_rows(lapply(sort(unique(d$stratum)), function(s) {
  i <- d$stratum == s
  data.frame(stratum = s, n = sum(i), truth = sum(y[i]),
             v2_kept = sum(k2[i]), v2_P = round(100 * sum(k2[i] & y[i]) / max(1, sum(k2[i])), 1),
             v2_R = round(100 * sum(k2[i] & y[i]) / max(1, sum(y[i])), 1),
             v3_kept = sum(k3[i]), v3_P = round(100 * sum(k3[i] & y[i]) / max(1, sum(k3[i])), 1),
             v3_R = round(100 * sum(k3[i] & y[i]) / max(1, sum(y[i])), 1))
})), row.names = FALSE)

cat("\n=== per new term: how much does each earn its place? ===\n")
print(bind_rows(lapply(EXPANSION$term, function(tm) {
  j <- which(v3$term == tm); h <- H3[, j]
  data.frame(term = tm, tier = v3$tier[j], rows = sum(h),
             pct_catholic = round(100 * sum(h & y) / max(1, sum(h)), 1),
             newly_kept = sum(k3 & !k2 & h),
             newly_kept_true = sum(k3 & !k2 & h & y))
})) |> arrange(desc(rows)) |> as.data.frame(), row.names = FALSE)

gained <- k3 & !k2; lost <- k2 & !k3
cat("\nnet: +", sum(gained), " items (", sum(gained & y), " Catholic, ",
    sum(gained & !y), " junk) | -", sum(lost), " items\n", sep = "")
cat("clearly Catholic items still missed:", sum(y & !k3), "(was", sum(y & !k2), ")\n")

write.csv(EXPANSION, "studies/filter-validation/output/private/v3_expansion_terms.csv",
          row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote v3_expansion_terms.csv\n")
