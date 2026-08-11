#!/usr/bin/env Rscript
# The coded sample says the second step threw out a pile that is 42% genuine. Is the threshold
# simply set too high? Re-estimate precision and recall across the whole range, weighting each
# coded item by how many real posts it stands for (the strata were sampled at very different rates).
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "data/rebuild"

cd <- readRDS(file.path(OUT, "discarded_coded.rds"))
d  <- readRDS(file.path(OUT, "post2024_decisions.rds"))
cd <- left_join(cd[, c("id", "stratum", "url", "clear")],
                d[, c("url", "score", "word_rule", "decision")], by = "url")
stopifnot(!anyNA(cd$decision))

POP <- c(KEPT = sum(d$decision == "accepted"),
         R_SECOND = sum(d$decision == "rejected: second pass"),
         R_WORD = sum(d$decision == "rejected: word rule"))
READ <- table(cd$stratum)[names(POP)]
cd$w <- as.numeric(POP[cd$stratum]) / as.numeric(READ[cd$stratum])   # posts each item stands for
cat("weights: kept 1 read =", round(POP[["KEPT"]] / READ[["KEPT"]]),
    "posts | second-step rejects 1 =", round(POP[["R_SECOND"]] / READ[["R_SECOND"]]),
    "| word-list rejects 1 =", round(POP[["R_WORD"]] / READ[["R_WORD"]]), "\n")

total_genuine <- sum(cd$w * cd$clear)
cat("estimated genuinely Catholic posts in the whole post-2024 half:",
    format(round(total_genuine), big.mark = " "), "\n\n")

# posts that passed the word rule are the only ones the threshold can act on
g <- cd[cd$word_rule, ]
curve <- bind_rows(lapply(c(0.00, 0.20, 0.40, 0.50, 0.60, 0.70, 0.8145, 0.90, 0.95, 0.99),
                          function(t) {
  k <- g$score >= t
  n_posts <- sum(g$w[k]); n_true <- sum(g$w[k] * g$clear[k])
  data.frame(threshold = t,
             posts = round(n_posts),
             genuine = round(n_true),
             precision = round(100 * n_true / n_posts, 1),
             recall = round(100 * n_true / total_genuine, 1),
             f1 = round(200 * (n_true / n_posts) * (n_true / total_genuine) /
                          ((n_true / n_posts) + (n_true / total_genuine)), 1))
}))
cat("=== precision and recall against the second-step threshold (post-2024) ===\n")
cat("threshold 0.00 = word list only, no second step; 0.8145 = what was actually applied\n\n")
print(as.data.frame(curve), row.names = FALSE)

cat("\n=== the trade the second step actually made, as applied ===\n")
on  <- curve[curve$threshold == 0.8145, ]
off <- curve[curve$threshold == 0.00, ]
cat(sprintf("second step ON : %s posts, %s genuine, precision %.1f%%, recall %.1f%%\n",
            format(on$posts, big.mark=" "), format(on$genuine, big.mark=" "),
            on$precision, on$recall))
cat(sprintf("second step OFF: %s posts, %s genuine, precision %.1f%%, recall %.1f%%\n",
            format(off$posts, big.mark=" "), format(off$genuine, big.mark=" "),
            off$precision, off$recall))
cat(sprintf("\nIt removed %s posts to remove %s junk — discarding %.2f genuine posts per junk post.\n",
            format(off$posts - on$posts, big.mark = " "),
            format((off$posts - off$genuine) - (on$posts - on$genuine), big.mark = " "),
            (off$genuine - on$genuine) /
              ((off$posts - off$genuine) - (on$posts - on$genuine))))
write.csv(curve, file.path(OUT, "threshold_curve_post2024.csv"), row.names = FALSE,
          fileEncoding = "UTF-8")
cat("\nwrote threshold_curve_post2024.csv\n")
