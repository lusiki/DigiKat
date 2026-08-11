#!/usr/bin/env Rscript
# Loosen the second-step threshold from the calibrated 0.8145 to a value chosen from MEASURED data
# on the post-2024 half (250 hand-coded posts, R/check_discarded_coding.R).
#
# No rescanning: every post's score is already stored, so this only re-reads a number. The strict
# decision is preserved alongside the new one so nothing is lost.
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "data/rebuild"
NEW_THRESHOLD <- 0.50

d  <- readRDS(file.path(OUT, "post2024_decisions.rds"))
cd <- readRDS(file.path(OUT, "discarded_coded.rds"))
sp <- readRDS("resources/models/second_pass_v1.rds")
old_thr <- sp$threshold
cat("calibrated threshold:", sprintf("%.4f", old_thr),
    "-> deployment threshold:", sprintf("%.4f\n\n", NEW_THRESHOLD))

d$decision_strict <- d$decision
d$second_pass <- !is.na(d$score) & d$score >= NEW_THRESHOLD
d$decision <- ifelse(!d$word_rule, "rejected: word rule",
              ifelse(!d$second_pass, "rejected: second pass", "accepted"))
d$threshold_used <- NEW_THRESHOLD

cat("=== post-2024, re-decided ===\n")
cmp <- data.frame(
  decision = c("accepted", "rejected: second pass", "rejected: word rule"),
  strict = as.integer(table(factor(d$decision_strict,
             levels = c("accepted","rejected: second pass","rejected: word rule")))),
  loosened = as.integer(table(factor(d$decision,
             levels = c("accepted","rejected: second pass","rejected: word rule")))))
cmp$change <- cmp$loosened - cmp$strict
print(cmp, row.names = FALSE)

## ---- what the coded sample says about the posts just re-admitted -------------------------------
cd2 <- left_join(cd[, c("id","stratum","url","clear")], d[, c("url","score","word_rule")],
                 by = "url")
back <- cd2$stratum == "R_SECOND" & cd2$score >= NEW_THRESHOLD
cat(sprintf("\nof the %d second-step rejects you read, %d would now be re-admitted; %d of those (%.0f%%) are genuine\n",
            sum(cd2$stratum == "R_SECOND"), sum(back), sum(back & cd2$clear),
            100 * mean(cd2$clear[back])))

POP <- c(KEPT = sum(d$decision_strict == "accepted"),
         R_SECOND = sum(d$decision_strict == "rejected: second pass"),
         R_WORD = sum(d$decision_strict == "rejected: word rule"))
READ <- table(cd2$stratum)[names(POP)]
cd2$w <- as.numeric(POP[cd2$stratum]) / as.numeric(READ[cd2$stratum])
total_genuine <- sum(cd2$w * cd2$clear)
g <- cd2[cd2$word_rule, ]
est <- function(t) {
  k <- g$score >= t
  n <- sum(g$w[k]); tp <- sum(g$w[k] * g$clear[k])
  c(posts = n, genuine = tp, precision = 100 * tp / n, recall = 100 * tp / total_genuine)
}
a <- est(old_thr); b <- est(NEW_THRESHOLD)
cat("\n=== estimated composition, from the 250 coded posts ===\n")
print(data.frame(
  setting = c(sprintf("strict (%.4f)", old_thr), sprintf("loosened (%.2f)", NEW_THRESHOLD)),
  posts = round(c(a[["posts"]], b[["posts"]])),
  genuine = round(c(a[["genuine"]], b[["genuine"]])),
  junk = round(c(a[["posts"]] - a[["genuine"]], b[["posts"]] - b[["genuine"]])),
  precision = round(c(a[["precision"]], b[["precision"]]), 1),
  recall = round(c(a[["recall"]], b[["recall"]]), 1)), row.names = FALSE)
cat(sprintf("\nrecovered: %s genuine Catholic posts, at the cost of %s junk\n",
            format(round(b[["genuine"]] - a[["genuine"]]), big.mark = " "),
            format(round((b[["posts"]] - b[["genuine"]]) - (a[["posts"]] - a[["genuine"]])),
                   big.mark = " ")))

saveRDS(d, file.path(OUT, "post2024_decisions.rds"))
sp$deployment_threshold <- NEW_THRESHOLD
sp$deployment_note <- paste0(
  "Calibrated threshold ", sprintf("%.4f", old_thr), " kept only 84% of genuine posts on the real ",
  "post-2024 population (promised 90%) and performed worse overall than no second step at all. ",
  "Deployment threshold set to ", sprintf("%.2f", NEW_THRESHOLD), " from 250 hand-coded posts ",
  "drawn from the actual output (R/check_discarded_coding.R, 2026-08-10). This value is calibrated ",
  "for the post-2024 half ONLY; the raw feed is far dirtier and needs its own measurement.")
saveRDS(sp, "resources/models/second_pass_v1.rds")
cat("\nupdated post2024_decisions.rds (strict decision preserved as `decision_strict`)\n")
cat("updated resources/models/second_pass_v1.rds with the deployment threshold\n")
