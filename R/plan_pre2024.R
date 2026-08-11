#!/usr/bin/env Rscript
# What threshold should the pre-2024 rebuild use, and what comes out?
#
# The post-2024 threshold cannot be carried over: it was measured on a population the word rule
# leaves 73,6% clean, whereas the raw feed leaves it about 61% clean overall and only 47% on
# material not already in the corpus. So re-derive the curve for the FEED population.
#
# Scores are OUT-OF-FOLD (the same 4x5 cross-validation the model was built with), because every
# coded feed post is in the model's training set and in-sample scores would flatter the result.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
set.seed(20260808)
OUT <- "studies/filter-validation/output/private"
sp <- readRDS("resources/models/second_pass_v1.rds")
CAP <- sp$text_cap; STEM <- sp$stem_chars; MIN_DF <- sp$min_df

r1 <- readRDS(file.path(OUT, "coded.rds")); r2 <- readRDS(file.path(OUT, "holdout_coded.rds"))
pool <- bind_rows(
  data.frame(stratum = r1$stratum, label = r1$label, title = r1$title, text = r1$text,
             stringsAsFactors = FALSE),
  data.frame(stratum = r2$stratum, label = r2$label, title = r2$title, text = r2$text,
             stringsAsFactors = FALSE))
pool$y <- pool$label == "catholic_clear"
v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")
cn <- digikat_tier_counts(digikat_hit_matrix(pool$text, v3), v3)
ok <- digikat_passes_inclusion_v2(cn)
acc <- pool[ok, ]; cn <- cn[ok, ]; y <- acc$y
Ht <- digikat_hit_matrix(ifelse(is.na(acc$title), "", acc$title), v3)
feat <- data.frame(dec = cn$decisive_match_count, amb = cn$ambiguous_match_count,
                   len = log1p(nchar(substr(acc$text, 1, CAP))),
                   title_dec = as.integer(rowSums(Ht[, v3$tier == "decisive", drop = FALSE]) > 0),
                   title_any = as.integer(rowSums(Ht) > 0))
docs <- lapply(substr(acc$text, 1, CAP), function(x) {
  if (is.na(x) || !nzchar(x)) return(character(0))
  w <- unlist(stri_extract_all_regex(stri_trans_tolower(x), "[\\p{L}]{3,}"))
  if (!length(w)) character(0) else unique(stri_sub(w, 1, STEM))
})

oof_s <- numeric(nrow(acc)); oof_n <- integer(nrow(acc))
for (rep in 1:4) {
  f <- integer(nrow(acc)); f[y] <- sample(rep_len(1:5, sum(y))); f[!y] <- sample(rep_len(1:5, sum(!y)))
  for (fold in 1:5) {
    tr <- which(f != fold); te <- which(f == fold)
    vt <- table(unlist(docs[tr])); vocab <- names(vt)[vt >= MIN_DF]
    ia <- table(unlist(docs[tr][y[tr]])); ib <- table(unlist(docs[tr][!y[tr]]))
    a <- as.numeric(ia[vocab]); a[is.na(a)] <- 0; b <- as.numeric(ib[vocab]); b[is.na(b)] <- 0
    w <- log((a + .5)/(sum(y[tr]) + 1)) - log((b + .5)/(sum(!y[tr]) + 1)); names(w) <- vocab
    nb <- vapply(docs, function(d) { h <- w[intersect(d, vocab)]; if (length(h)) sum(h) else 0 }, numeric(1))
    df <- cbind(feat, nb = nb)
    g <- suppressWarnings(glm(yy ~ ., data = cbind(df[tr, , drop = FALSE], yy = y[tr]), family = binomial()))
    oof_s[te] <- oof_s[te] + as.numeric(predict(g, newdata = df[te, , drop = FALSE], type = "response"))
    oof_n[te] <- oof_n[te] + 1L
  }
}
acc$score <- oof_s / oof_n

## ---- the feed population --------------------------------------------------------------------
pop <- read.csv(file.path(OUT, "holdout_population.csv"), stringsAsFactors = FALSE)
scale <- 19781689 / sum(pop$n)
N_IN  <- pop$n[pop$group == "accept, in master"] * scale   # feed rows v3 accepts, already in corpus
N_NEW <- pop$n[pop$group == "accept, new"]       * scale   # feed rows v3 accepts, new material
N_REJ_TRUE <- pop$n[pop$group == "reject, >=1 term"] * scale * pop$precision[3]  # genuine we lose at gate 1
cat("feed rows the word list accepts:", format(round(N_IN + N_NEW), big.mark = " "),
    sprintf("(%s already in the corpus, %s new)\n",
            format(round(N_IN), big.mark = " "), format(round(N_NEW), big.mark = " ")))

inm <- acc$stratum %in% c("B", "S2")     # pre-2024 master rows = the in-corpus part of the feed
new <- acc$stratum %in% c("C", "S3")     # new feed material
cat("coded posts available: ", sum(inm), " in-corpus (", round(100*mean(y[inm])), "% genuine), ",
    sum(new), " new (", round(100*mean(y[new])), "% genuine)\n\n", sep = "")

total_genuine <- N_IN * mean(y[inm]) + N_NEW * mean(y[new]) + N_REJ_TRUE
curve <- bind_rows(lapply(c(0, 0.3, 0.5, 0.6, 0.7, 0.8, 0.8145, 0.9, 0.95), function(t) {
  ki <- acc$score[inm] >= t; kn <- acc$score[new] >= t
  posts <- N_IN * mean(ki) + N_NEW * mean(kn)
  gen   <- N_IN * mean(ki & y[inm]) + N_NEW * mean(kn & y[new])
  data.frame(threshold = t, posts = round(posts), genuine = round(gen),
             junk = round(posts - gen), precision = round(100 * gen / posts, 1),
             recall = round(100 * gen / total_genuine, 1),
             f1 = round(200 * (gen/posts) * (gen/total_genuine) /
                          ((gen/posts) + (gen/total_genuine)), 1))
}))
cat("=== pre-2024 rebuild: what each threshold gives ===\n")
cat("threshold 0 = word list only. Estimated genuine posts findable in the feed:",
    format(round(total_genuine), big.mark = " "), "\n\n")
print(as.data.frame(curve), row.names = FALSE)

cat("\n=== against what you have today ===\n")
best <- curve[which.max(curve$f1), ]
today_posts <- 269583; today_genuine <- round(today_posts * 0.70)
print(data.frame(
  option = c("pre-2024 as it stands today", sprintf("rebuilt at threshold %.2f", best$threshold)),
  posts = c(today_posts, best$posts), genuine = c(today_genuine, best$genuine),
  junk = c(today_posts - today_genuine, best$junk),
  clean = c(70.0, best$precision)), row.names = FALSE)
write.csv(curve, file.path(OUT, "pre2024_threshold_plan.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote pre2024_threshold_plan.csv\n")
