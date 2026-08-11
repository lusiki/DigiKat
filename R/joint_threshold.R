#!/usr/bin/env Rscript
# One threshold has to serve both eras, so the question is not what is best for either of them but
# what is best for the corpus they make together. This adds the two measured curves.
#
# Each era's curve was produced from its own hand-read sample, weighted to its own populations, so
# the sum is a population estimate for the united corpus rather than a pooled sample average.
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "data/rebuild"

rd <- function(p) read.csv(file.path(OUT, p), stringsAsFactors = FALSE)
a <- rd("threshold_curve_pre2024_v4.csv")
b <- rd("threshold_curve_post2024_v4.csv")

# every genuine post the era contains as far as the word list can see it, back out of recall
tot <- function(x) x$genuine[x$threshold == 0] / (x$recall[x$threshold == 0] / 100)
TA <- tot(a); TB <- tot(b); TT <- TA + TB
cat(sprintf("genuinely Catholic posts findable: pre-2024 %s | post-2024 %s | together %s\n",
            format(round(TA), big.mark = " "), format(round(TB), big.mark = " "),
            format(round(TT), big.mark = " ")))

t <- intersect(a$threshold, b$threshold)
a <- a[match(t, a$threshold), ]; b <- b[match(t, b$threshold), ]
j <- data.frame(
  threshold = t,
  posts   = a$posts + b$posts,
  genuine = a$genuine + b$genuine,
  junk    = (a$posts - a$genuine) + (b$posts - b$genuine))
j$precision <- round(100 * j$genuine / j$posts, 1)
j$recall    <- round(100 * j$genuine / TT, 1)
j$f1 <- round(200 * (j$genuine/j$posts) * (j$genuine/TT) /
                ((j$genuine/j$posts) + (j$genuine/TT)), 1)
j$pre_prec  <- a$precision
j$post_prec <- b$precision
j$gap <- round(b$precision - a$precision, 1)

cat("\n=== the united corpus, one threshold, both eras ===\n")
print(j, row.names = FALSE)

best <- j[which.max(j$f1), ]
dep  <- j[j$threshold == 0.40, ]
cat(sprintf("\ndeployed 0.40 : %s posts, %.1f%% clean, keeps %.1f%% of the genuine material\n",
            format(dep$posts, big.mark = " "), dep$precision, dep$recall))
cat(sprintf("best F1 %.2f  : %s posts, %.1f%% clean, keeps %.1f%% of the genuine material\n",
            best$threshold, format(best$posts, big.mark = " "), best$precision, best$recall))
cat(sprintf("\nthe two eras' precision differs by %.1f points at 0.40 and %.1f points at %.2f\n",
            dep$gap, best$gap, best$threshold))
write.csv(j, file.path(OUT, "threshold_curve_joint_v4.csv"), row.names = FALSE,
          fileEncoding = "UTF-8")
cat("\nwrote threshold_curve_joint_v4.csv | nothing was re-set\n")
