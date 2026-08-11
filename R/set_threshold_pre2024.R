#!/usr/bin/env Rscript
# What the second step's threshold costs and buys in the PRE-2024 half, measured on the 250 posts
# hand-read from that era's actual output, each weighted by how many real posts it stands for.
#
# This script REPORTS; it does not re-set anything. The deployed threshold is 0,40 in both eras by
# decision (quality_reports/plans/2026-08-10_pre2024-rebuild-under-v4.md §1): tuning it per era
# would equalise precision at the cost of making the inclusion rule itself depend on the era, which
# is the confound the whole exercise exists to remove. What matters is therefore not where this
# era's optimum sits but how much 0,40 gives away relative to it -- so that is what gets printed.
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "data/rebuild"
DEPLOYED <- 0.40

cd <- readRDS(file.path(OUT, "pre2024_coded.rds"))
d  <- readRDS(file.path(OUT, "pre2024_decisions_v4.rds"))
stopifnot(abs(unique(d$threshold_used) - DEPLOYED) < 1e-9)

POP <- c(KEPT     = sum(d$decision == "accepted"),
         R_SECOND = sum(d$decision == "rejected: second pass"),
         R_WORD   = sum(d$decision == "rejected: word rule"))
READ <- table(cd$stratum)[names(POP)]
cd$w <- as.numeric(POP[cd$stratum]) / as.numeric(READ[cd$stratum])
cat("each read post stands for:",
    paste(sprintf("%s %d", names(POP), round(POP / as.numeric(READ))), collapse = " | "), "\n")

# Every genuine post the era contains, as far as the word list can see it -- including the ones it
# threw out, which is what makes recall mean something rather than being 100% by construction.
total_genuine <- sum(cd$w * cd$clear)
cat("estimated genuinely Catholic posts in the pre-2024 half:",
    format(round(total_genuine), big.mark = " "), "\n")

g <- cd[cd$stratum != "R_WORD", ]          # the posts the word rule let through, with their scores
stopifnot(!any(is.na(g$score)))
cat("of the 250 read posts, the word list accepts", nrow(g), "\n\n")

curve <- bind_rows(lapply(c(0, .2, .3, .4, .5, .6, .7, .8, .9, .95), function(t) {
  k <- g$score >= t
  n <- sum(g$w[k]); tp <- sum(g$w[k] * g$clear[k])
  data.frame(threshold = t, posts = round(n), genuine = round(tp), junk = round(n - tp),
             precision = round(100 * tp / n, 1), recall = round(100 * tp / total_genuine, 1),
             f1 = round(200 * (tp/n) * (tp/total_genuine) / ((tp/n) + (tp/total_genuine)), 1))
}))
cat("=== threshold curve, pre-2024 (threshold 0 = word list only) ===\n")
print(as.data.frame(curve), row.names = FALSE)

best <- curve[which.max(curve$f1), ]
dep  <- curve[curve$threshold == DEPLOYED, ]
cat(sprintf("\nera-local optimum: %.2f (F1 %.1f) | deployed: %.2f (F1 %.1f) | gap %.1f F1 points\n",
            best$threshold, best$f1, DEPLOYED, dep$f1, best$f1 - dep$f1))
cat(sprintf("cost of holding 0,40 in this era: %s posts, %s genuine, %+.1f points of precision\n",
            format(dep$posts - best$posts, big.mark = " "),
            format(dep$genuine - best$genuine, big.mark = " "),
            dep$precision - best$precision))

write.csv(curve, file.path(OUT, "threshold_curve_pre2024_v4.csv"), row.names = FALSE,
          fileEncoding = "UTF-8")
cat("\nwrote threshold_curve_pre2024_v4.csv | nothing was re-set\n")
