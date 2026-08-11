#!/usr/bin/env Rscript
# Verify the tracked R/religious_terms_v3.R reproduces exactly what 08_expanded_terms.R measured,
# and that no expansion pattern re-opens a secular homonym. Aggregates only.
suppressPackageStartupMessages({library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")

v2 <- digikat_load_religious_terms_v2()
v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")
cat("v2:", nrow(v2), "terms | v3:", nrow(v3), "terms |",
    sum(v3$tier == "decisive"), "decisive,", sum(v3$tier == "ambiguous"), "ambiguous\n")

stopifnot(identical(v3$term[seq_len(nrow(v2))], v2$term),
          identical(v3$regex[seq_len(nrow(v2))], v2$regex),
          identical(v3$tier[seq_len(nrow(v2))], v2$tier))
cat("v3 contains v2 unchanged as its first", nrow(v2), "terms — OK\n")

# every added pattern must reject the secular word it was written against
guards <- c(molitva = "molim", vjernik = "vjerojatno", "župa" = "županija", krist = "kristal",
            isus = "isušiti", "božji" = "božićni", spasenje = "spasilac", bog = "bogatstvo",
            vjera = "vjerojatno", kapela = "kapelan", "duša" = "dušik")
for (tm in names(guards)) {
  rx <- v3$regex[v3$term == tm]
  if (stri_detect_regex(guards[[tm]], rx, opts_regex = list(case_insensitive = TRUE)))
    stop("pattern for '", tm, "' wrongly matches '", guards[[tm]], "'")
}
cat("all", length(guards), "homonym guards hold — OK\n")

d <- readRDS("studies/filter-validation/output/private/coded.rds")
y <- d$label == "catholic_clear"
H <- digikat_hit_matrix(d$text, v3)
k <- digikat_passes_inclusion_v2(digikat_tier_counts(H, v3))
tp <- sum(k & y); fp <- sum(k & !y); fn <- sum(!k & y)
cat(sprintf("\n440 coded items: kept %d | precision %.1f | recall %.1f\n",
            sum(k), 100 * tp / (tp + fp), 100 * tp / (tp + fn)))
stopifnot(sum(k) == 201L, abs(100 * tp / (tp + fp) - 80.1) < 0.15,
          abs(100 * tp / (tp + fn) - 91.5) < 0.15)
cat("matches 08_expanded_terms.R (201 / 80,1 / 91,5) — OK\n")
