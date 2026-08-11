#!/usr/bin/env Rscript
# Choose the deployment threshold for the post-2024 half from MEASURED data: the 250 posts the PI
# hand-read from the actual output. Each coded post is re-scored under the current word list and
# model, then weighted by how many real posts it stands for (the three piles were sampled at very
# different rates), so precision and recall are population estimates rather than sample averages.
#
#   Rscript R/set_threshold_post2024.R [terms_file] [model_file] [decisions_file]
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
source("R/lib/second_pass.R", encoding = "UTF-8")

.a <- commandArgs(trailingOnly = TRUE)
TERMS_FILE <- if (length(.a) >= 1) .a[[1]] else "R/religious_terms_v4.R"
MODEL_FILE <- if (length(.a) >= 2) .a[[2]] else "resources/models/second_pass_v2.rds"
DEC_FILE   <- if (length(.a) >= 3) .a[[3]] else "data/rebuild/post2024_decisions_v4.rds"
OUT <- "data/rebuild"

cd <- readRDS(file.path(OUT, "discarded_coded.rds"))     # 250 read posts, with labels
old <- readRDS(file.path(OUT, "post2024_decisions.rds")) # v3 run: defines the sampling strata
d   <- readRDS(DEC_FILE)                                 # current run: scores to threshold

# population of each sampling pile, from the STRICT v3 decision the sample was drawn against
POP <- c(KEPT     = sum(old$decision_strict == "accepted"),
         R_SECOND = sum(old$decision_strict == "rejected: second pass"),
         R_WORD   = sum(old$decision_strict == "rejected: word rule"))
READ <- table(cd$stratum)[names(POP)]
cd$w <- as.numeric(POP[cd$stratum]) / as.numeric(READ[cd$stratum])
cat("each read post stands for:",
    paste(sprintf("%s %d", names(POP), round(POP / as.numeric(READ))), collapse = " | "), "\n")

# re-score the 250 under the CURRENT word list and model
v  <- digikat_load_religious_terms_v2(TERMS_FILE)
sp <- digikat_load_second_pass(MODEL_FILE)
H  <- digikat_hit_matrix(cd$text, v); cn <- digikat_tier_counts(H, v)
cd$word_rule <- digikat_passes_inclusion_v2(cn)
Ht <- digikat_hit_matrix(ifelse(is.na(cd$title), "", cd$title), v)
feat <- data.frame(dec = cn$decisive_match_count, amb = cn$ambiguous_match_count,
                   len = log1p(nchar(substr(cd$text, 1, sp$text_cap))),
                   title_dec = as.integer(rowSums(Ht[, v$tier == "decisive", drop = FALSE]) > 0),
                   title_any = as.integer(rowSums(Ht) > 0))
cd$score <- NA_real_
cd$score[cd$word_rule] <- digikat_second_pass_score(cd$text[cd$word_rule],
                                                    feat[cd$word_rule, , drop = FALSE], sp)
total_genuine <- sum(cd$w * cd$clear)
cat("estimated genuinely Catholic posts in the post-2024 half:",
    format(round(total_genuine), big.mark = " "), "\n")
cat("of the 250 read posts, the current word list accepts", sum(cd$word_rule), "\n\n")

g <- cd[cd$word_rule, ]
curve <- bind_rows(lapply(c(0, .2, .3, .4, .5, .6, .7, .8, .9, .95), function(t) {
  k <- g$score >= t
  n <- sum(g$w[k]); tp <- sum(g$w[k] * g$clear[k])
  data.frame(threshold = t, posts = round(n), genuine = round(tp), junk = round(n - tp),
             precision = round(100 * tp / n, 1), recall = round(100 * tp / total_genuine, 1),
             f1 = round(200 * (tp/n) * (tp/total_genuine) / ((tp/n) + (tp/total_genuine)), 1))
}))
cat("=== threshold curve, post-2024 (threshold 0 = word list only) ===\n")
print(as.data.frame(curve), row.names = FALSE)
best <- curve$threshold[which.max(curve$f1)]
cat("\nbest overall balance at threshold", best, "\n")

# apply it
d$threshold_used <- best
d$second_pass <- !is.na(d$score) & d$score >= best
d$decision <- ifelse(!d$word_rule, "rejected: word rule",
              ifelse(!d$second_pass, "rejected: second pass", "accepted"))
saveRDS(d, DEC_FILE)
sp$deployment_threshold <- best
sp$deployment_note <- paste0("Chosen from 250 posts hand-read from the actual post-2024 output ",
  "(2026-08-10), re-scored under ", TERMS_FILE, ". Calibrated value was ",
  sprintf("%.4f", sp$threshold), "; measured optimum is ", best,
  ". Valid for the post-2024 half only — the raw feed is far dirtier.")
saveRDS(sp, MODEL_FILE)

cat("\n=== final post-2024 decisions ===\n")
r <- as.data.frame(table(decision = d$decision)); r$pct <- round(100 * r$Freq / nrow(d), 1)
print(r, row.names = FALSE)
write.csv(curve, file.path(OUT, "threshold_curve_post2024_v4.csv"), row.names = FALSE,
          fileEncoding = "UTF-8")
cat("\nwrote", DEC_FILE, "and threshold_curve_post2024_v4.csv\n")
