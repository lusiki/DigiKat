#!/usr/bin/env Rscript
# Train and FREEZE the second-pass model, then save it as a self-contained artifact.
#
# The second pass only ever sees posts the word rule already accepted, so it is trained only on
# those. It reads the FIRST 3000 CHARACTERS of a post — exactly what the human coder saw — so the
# model is never applied to a longer text than it was trained on.
#
# CALIBRATION. A single model fitted on all 402 items memorises them: in-sample precision comes out
# at 99,6%, and a threshold chosen on those probabilities would be far too strict on real data. So
# the artifact is an ENSEMBLE of models each fitted on a random 80%, deployment scores are the
# average across the ensemble, and the threshold is chosen on OUT-OF-FOLD predictions — scores for
# items the contributing models never saw. Threshold and scores are then the same kind of number.
#
# Writes the model named by MODEL_OUT (arg 2). Touches no corpus file.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
.script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(.script_arg)) {
  setwd(normalizePath(file.path(dirname(sub("^--file=", "", .script_arg[[1]])), ".."),
                      mustWork = TRUE))
}
rm(.script_arg)
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
set.seed(20260808)
# terms file and output path are arguments so a new word list can be trained without forking this
# script; earlier models stay on disk untouched.
.a <- commandArgs(trailingOnly = TRUE)
TERMS_FILE <- if (length(.a) >= 1) .a[[1]] else "R/religious_terms_v4.R"
MODEL_OUT  <- if (length(.a) >= 2) .a[[2]] else "resources/models/second_pass_v2.rds"
OUT <- "studies/filter-validation/output/private"
TEXT_CAP <- 3000L; STEM <- 6L; MIN_DF <- 3L
N_MODELS <- 20L; SUBSAMPLE <- 0.80
KEEP_TARGET <- 0.90

r1 <- readRDS(file.path(OUT, "coded.rds")); r2 <- readRDS(file.path(OUT, "holdout_coded.rds"))
pool <- bind_rows(
  data.frame(stratum = r1$stratum, label = r1$label, title = r1$title, text = r1$text,
             stringsAsFactors = FALSE),
  data.frame(stratum = r2$stratum, label = r2$label, title = r2$title, text = r2$text,
             stringsAsFactors = FALSE))
pool$y <- pool$label == "catholic_clear"

v3 <- digikat_load_religious_terms_v2(TERMS_FILE)
cat("word list:", TERMS_FILE, "->", nrow(v3), "terms
")
cn <- digikat_tier_counts(digikat_hit_matrix(pool$text, v3), v3)
ok <- digikat_passes_inclusion_v2(cn)
acc <- pool[ok, ]; cn <- cn[ok, ]
acc$n_dec <- cn$decisive_match_count; acc$n_amb <- cn$ambiguous_match_count
acc$feed <- acc$stratum %in% c("C", "S3")
y <- acc$y

# The TITLE is the single most useful thing the earlier version ignored: 95% of posts with a
# religious word in the headline are genuine, against 53% of the rest (19_better_features.R).
Ht <- digikat_hit_matrix(ifelse(is.na(acc$title), "", acc$title), v3)
acc$title_dec <- as.integer(rowSums(Ht[, v3$tier == "decisive", drop = FALSE]) > 0)
acc$title_any <- as.integer(rowSums(Ht) > 0)
cat("training items (word rule accepted):", nrow(acc),
    sprintf("| genuine %.1f%%\n", 100 * mean(y)))

sp_tokens <- function(txt, cap = TEXT_CAP, stem = STEM) {
  txt <- substr(as.character(txt), 1, cap)
  lapply(txt, function(x) {
    if (is.na(x) || !nzchar(x)) return(character(0))
    w <- unlist(stri_extract_all_regex(stri_trans_tolower(x), "[\\p{L}]{3,}"))
    if (!length(w)) character(0) else unique(stri_sub(w, 1, stem))
  })
}
docs <- sp_tokens(acc$text)
feat <- data.frame(dec = acc$n_dec, amb = acc$n_amb,
                   len = log1p(nchar(substr(acc$text, 1, TEXT_CAP))),
                   title_dec = acc$title_dec, title_any = acc$title_any)

fit_one <- function(tr) {
  vt <- table(unlist(docs[tr])); vocab <- names(vt)[vt >= MIN_DF]
  ia <- table(unlist(docs[tr][y[tr]])); ib <- table(unlist(docs[tr][!y[tr]]))
  a <- as.numeric(ia[vocab]); a[is.na(a)] <- 0
  b <- as.numeric(ib[vocab]); b[is.na(b)] <- 0
  w <- log((a + 0.5) / (sum(y[tr]) + 1)) - log((b + 0.5) / (sum(!y[tr]) + 1)); names(w) <- vocab
  nb <- vapply(docs, function(d) { h <- w[intersect(d, vocab)]
    if (length(h)) sum(h) else 0 }, numeric(1))
  df <- cbind(feat, nb = nb)
  d_tr <- cbind(df[tr, , drop = FALSE], yy = y[tr])
  g <- suppressWarnings(glm(yy ~ ., data = d_tr, family = binomial()))
  list(vocab = vocab, weights = unname(w), coefficients = coef(g),
       predict_all = as.numeric(predict(g, newdata = df, type = "response")))
}

## ---- ensemble + out-of-fold scores --------------------------------------------------------------
# 4 repeats of stratified 5-fold = 20 models, each trained on 80%, and every item held out
# exactly 4 times. Random subsampling would leave a few items never held out.
models <- list()
oof_sum <- numeric(nrow(acc)); oof_n <- integer(nrow(acc))
for (rep in seq_len(N_MODELS / 5L)) {
  f <- integer(nrow(acc))
  f[y]  <- sample(rep_len(1:5, sum(y)))
  f[!y] <- sample(rep_len(1:5, sum(!y)))
  for (fold in 1:5) {
    tr <- which(f != fold); te <- which(f == fold)
    m <- fit_one(tr)
    models[[length(models) + 1L]] <- m[c("vocab", "weights", "coefficients")]
    oof_sum[te] <- oof_sum[te] + m$predict_all[te]; oof_n[te] <- oof_n[te] + 1L
  }
}
stopifnot(all(oof_n > 0))
oof <- oof_sum / oof_n
cat("ensemble:", N_MODELS, "models |",
    "each item scored out-of-fold by", round(mean(oof_n), 1), "of them on average\n")

threshold <- { s <- sort(oof[y], decreasing = TRUE); s[max(1L, floor(KEEP_TARGET * length(s)))] }
cat(sprintf("threshold (from out-of-fold scores, keep %.0f%% of genuine): %.4f\n\n",
            100 * KEEP_TARGET, threshold))

report <- function(i, name) {
  k <- oof[i] >= threshold
  data.frame(population = name, n = sum(i), before = round(100 * mean(y[i]), 1), kept = sum(k),
             after = round(100 * sum(k & y[i]) / max(1, sum(k)), 1),
             keeps_genuine = round(100 * sum(k & y[i]) / max(1, sum(y[i])), 1))
}
cat("=== honest effect of the frozen model (out-of-fold scores) ===\n")
print(bind_rows(report(rep(TRUE, nrow(acc)), "all accepted"),
                report(!acc$feed, "master rows"),
                report(acc$feed, "new feed material")), row.names = FALSE)

dir.create("resources/models", recursive = TRUE, showWarnings = FALSE)
saveRDS(list(
  version = tools::file_path_sans_ext(basename(MODEL_OUT)),
  built_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  text_cap = TEXT_CAP, stem_chars = STEM, min_df = MIN_DF,
  features = c("nb", "dec", "amb", "len", "title_dec", "title_any"),
  n_models = N_MODELS, subsample = SUBSAMPLE,
  models = models, threshold = threshold, keep_target = KEEP_TARGET,
  n_train = nrow(acc), terms_file = TERMS_FILE,
  note = paste("Ensemble of", N_MODELS, "logistic models over Naive-Bayes stem scores, trained on",
               nrow(acc), "hand-coded posts that", TERMS_FILE, "accepted. Reads the first", TEXT_CAP,
               "characters, matching the coder's view. Threshold calibrated on out-of-fold scores;",
               "the deployment threshold is set separately from measured output.")
), MODEL_OUT)
cat("\nwrote", MODEL_OUT, "\n")
