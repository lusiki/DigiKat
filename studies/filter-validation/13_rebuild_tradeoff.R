#!/usr/bin/env Rscript
# The rebuild decision, arithmetic only, from the held-out measurements.
# Reads holdout_population.csv (written by 12_score_holdout.R). No hand-typed numbers.
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "studies/filter-validation/output/private"
pop <- read.csv(file.path(OUT, "holdout_population.csv"), stringsAsFactors = FALSE)

FEED_ROWS <- 19781689
scale <- FEED_ROWS / sum(pop$n)
n_keep_old <- pop$n[pop$group == "accept, in master"] * scale   # today's corpus, re-filtered by v3
n_add      <- pop$n[pop$group == "accept, new"]       * scale   # what a rebuild would add
p_old <- pop$precision[pop$group == "accept, in master"]
p_add <- pop$precision[pop$group == "accept, new"]

opt <- data.frame(
  option = c("A. keep pre-2024 as it is, re-filtered by v3",
             "B. rebuild pre-2024 from the full feed, v3"),
  posts        = round(c(n_keep_old, n_keep_old + n_add), -2),
  genuine      = round(c(n_keep_old * p_old, n_keep_old * p_old + n_add * p_add), -2),
  junk         = round(c(n_keep_old * (1 - p_old),
                         n_keep_old * (1 - p_old) + n_add * (1 - p_add)), -2)
)
opt$pct_clean <- round(100 * opt$genuine / opt$posts, 1)

cat("=== the rebuild trade, using held-out precision ===\n")
print(opt, row.names = FALSE)
cat(sprintf("\nRebuilding buys %s more genuine Catholic posts (+%.0f%%)\n",
            format(round(n_add * p_add, -2), big.mark = " "),
            100 * (n_add * p_add) / (n_keep_old * p_old)))
cat(sprintf("and costs %.1f points of cleanliness (%.1f%% -> %.1f%%).\n",
            opt$pct_clean[1] - opt$pct_clean[2], opt$pct_clean[1], opt$pct_clean[2]))
cat(sprintf("\nFor comparison, under the OLD broken rule the same rebuild was 19%% clean;\n"))
cat(sprintf("under v3 the added material is %.1f%% clean.\n", 100 * p_add))
