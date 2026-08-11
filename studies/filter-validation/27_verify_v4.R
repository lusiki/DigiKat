#!/usr/bin/env Rscript
# Verify lib_rule_v4.R reproduces the numbers RESULTS.md section 10 claims. Fails loud if not.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
source("studies/filter-validation/lib_rule_v4.R", encoding = "UTF-8")
OUT <- "studies/filter-validation/output/private"
v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")
cat("Catholic-specific terms present in v3:", sum(DIGIKAT_V4_CATHOLIC %in% v3$term), "of",
    length(DIGIKAT_V4_CATHOLIC), "\n")
stopifnot(all(DIGIKAT_V4_CATHOLIC %in% v3$term))

## the read 50
r4 <- readRDS(file.path(OUT, "pre2024_output_coded.rds"))
v <- digikat_rule_v4(r4$text_full, v3)
p <- function(k, y = r4$clear) sprintf("%d kept, %d genuine, %.1f%%", sum(k), sum(k & y),
                                       100*sum(k & y)/max(1, sum(k)))
cat("\n=== the 50 read posts ===\n")
cat("as drawn (v3 full text + gate 2)   :", p(rep(TRUE, nrow(r4))), "\n")
cat("v4 gate 1, veto off (= window+bozji):", p(digikat_rule_v4(r4$text_full, v3, veto = FALSE)$keep), "\n")
cat("v4 gate 1, veto on                 :", p(v$keep), "\n")
stopifnot(sum(v$keep) == 42L, sum(v$keep & r4$clear) == 32L)      # 76,2%
stopifnot(sum(digikat_rule_v4(r4$text_full, v3, veto = FALSE)$keep) == 45L)
# window-only = v3 admits it on the whole text but not inside the window. Compare the two directly
# rather than inferring it from `truncated`, which also catches long posts that fail for other reasons.
g1 <- function(H) rowSums(H[, v3$tier == "decisive", drop = FALSE]) >= 1L & rowSums(H) >= 2L
wo <- g1(digikat_hit_matrix(r4$text_full, v3)) &
      !g1(digikat_hit_matrix(substr(r4$text_full, 1, DIGIKAT_V4_CAP), v3))
cat("window-only admissions among the 50:", sum(wo), "->", paste(r4$id[wo], collapse = ", "),
    "| genuine among them:", sum(wo & r4$clear), "\n")
stopifnot(sum(wo) == 3L, sum(wo & r4$clear) == 0L)

## the population
cc <- readRDS(file.path(OUT, "repair_pool_cache.rds"))
vp <- digikat_rule_v4(cc$g$text_full, v3, progress = TRUE)
n_text <- cc$n_text
cat("\n=== feed pool", nrow(cc$g), "rows ===\n")
cat(sprintf("v4 gate 1 accepts %d (%.3f%%) -> projected %s of %s rows with text\n",
            sum(vp$keep), 100*mean(vp$keep),
            format(round(n_text*mean(vp$keep)), big.mark = " "), format(n_text, big.mark = " ")))
stopifnot(abs(sum(vp$keep) - 1400L) <= 2L)
cat("\nVERDICT: lib_rule_v4.R reproduces RESULTS.md section 10.\n")
