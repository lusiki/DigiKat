#!/usr/bin/env Rscript
# What the rebuild looks like if v3 is followed by the second-pass classifier.
# All inputs are measured, not assumed:
#   population sizes  <- holdout_population.csv (12_score_holdout.R)
#   precision of v3   <- the held-out 300 (12_score_holdout.R)
#   second-pass gain  <- cross-validated, 16_second_pass_on_s3.R (new material)
#                        and 15_where_to_spend.R (master material)
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "studies/filter-validation/output/private"
pop <- read.csv(file.path(OUT, "holdout_population.csv"), stringsAsFactors = FALSE)
scale <- 19781689 / sum(pop$n)

n_old <- pop$n[pop$group == "accept, in master"] * scale; p_old <- pop$precision[1]
n_new <- pop$n[pop$group == "accept, new"]       * scale; p_new <- pop$precision[2]

# second pass, cross-validated operating points
SP_NEW <- c(precision = 0.807, recall = 0.797)   # 16_second_pass_on_s3.R, "keep 90%" setting
SP_OLD <- c(precision = 0.907, recall = 0.870)   # 15_where_to_spend.R, master population

after <- function(n, p, sp) {
  genuine_in <- n * p
  genuine_out <- genuine_in * sp[["recall"]]
  total_out <- genuine_out / sp[["precision"]]
  c(posts = total_out, genuine = genuine_out, junk = total_out - genuine_out)
}
a_old <- after(n_old, p_old, SP_OLD)
a_new <- after(n_new, p_new, SP_NEW)

rows <- list(
  c(option = "A. keep what you have, v3 only",              posts = n_old, genuine = n_old * p_old),
  c(option = "A+. keep what you have, v3 + second pass",     posts = a_old[["posts"]],  genuine = a_old[["genuine"]]),
  c(option = "B. rebuild, v3 only",                          posts = n_old + n_new,     genuine = n_old * p_old + n_new * p_new),
  c(option = "B+. rebuild, v3 + second pass",                posts = a_old[["posts"]] + a_new[["posts"]],
    genuine = a_old[["genuine"]] + a_new[["genuine"]])
)
tab <- do.call(rbind, lapply(rows, function(r) data.frame(
  option = r[["option"]],
  posts = round(as.numeric(r[["posts"]]), -2),
  genuine = round(as.numeric(r[["genuine"]]), -2),
  junk = round(as.numeric(r[["posts"]]) - as.numeric(r[["genuine"]]), -2),
  clean = round(100 * as.numeric(r[["genuine"]]) / as.numeric(r[["posts"]]), 1))))

cat("=== four ways to end up, all measured ===\n")
print(tab, row.names = FALSE)
cat(sprintf("\nB+ vs A: %s more genuine Catholic posts (+%.0f%%) at %.1f%% clean vs %.1f%%.\n",
            format(tab$genuine[4] - tab$genuine[1], big.mark = " "),
            100 * (tab$genuine[4] - tab$genuine[1]) / tab$genuine[1],
            tab$clean[4], tab$clean[1]))
cat(sprintf("The second pass discards about %s junk posts from the new material alone.\n",
            format(round(n_new * (1 - p_new) - a_new[["junk"]], -2), big.mark = " ")))
write.csv(tab, file.path(OUT, "rebuild_options.csv"), row.names = FALSE, fileEncoding = "UTF-8")
