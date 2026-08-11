#!/usr/bin/env Rscript
# Apply the rule to the post-2024 half (2024-2026). There is no raw feed for this period, so this
# can only CLEAN what is already in the corpus.
#
# SUPERSEDED by R/rebuild_era.R --era=post2024, which is this script generalised to either era so
# that both halves are demonstrably cut by one code path. Kept unchanged as the record of what
# actually produced data/rebuild/post2024_decisions_v4.rds on 2026-08-10; the gate logic in the
# generic script is line-for-line the same, plus one added diagnostic column (word_rule_window).
#
#   Rscript R/rebuild_post2024.R [terms_file] [model_file] [output_file]
#   defaults: R/religious_terms_v4.R  resources/models/second_pass_v2.rds
#             data/rebuild/post2024_decisions_v4.rds
#
# READ-ONLY with respect to data/merged_comprehensive.rds. Writes one new decisions file to
# data/rebuild/, which is self-ignoring (it carries URLs). Scores are stored for EVERY post that
# passes the word rule, so the accept/reject threshold can be changed later without rescanning.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
source("R/lib/second_pass.R", encoding = "UTF-8")

.a <- commandArgs(trailingOnly = TRUE)
TERMS_FILE <- if (length(.a) >= 1) .a[[1]] else "R/religious_terms_v4.R"
MODEL_FILE <- if (length(.a) >= 2) .a[[2]] else "resources/models/second_pass_v2.rds"
OUT_FILE   <- if (length(.a) >= 3) .a[[3]] else "data/rebuild/post2024_decisions_v4.rds"
OUT_DIR <- dirname(OUT_FILE)
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)
gi <- file.path(OUT_DIR, ".gitignore")
if (!file.exists(gi)) writeLines(c("*", "!.gitignore"), gi)   # carries URLs: never committed

say <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n"); flush.console() }

v1 <- digikat_load_religious_terms()
v  <- digikat_load_religious_terms_v2(TERMS_FILE)
sp <- digikat_load_second_pass(MODEL_FILE)
thr <- if (!is.null(sp$deployment_threshold)) sp$deployment_threshold else sp$threshold
say("word list:", TERMS_FILE, "-", nrow(v), "terms |",
    sum(v$tier == "decisive"), "decisive,", sum(v$tier == "ambiguous"), "ambiguous")
say("model:", MODEL_FILE, "-", length(sp$models), "models | provisional threshold",
    sprintf("%.4f", thr))

say("loading master (read-only)...")
m <- readRDS("data/merged_comprehensive.rds")
stopifnot("data_source" %in% names(m), "FULL_TEXT" %in% names(m))
i <- which(m$data_source == "filtered_religious")
say("post-2024 rows:", length(i))
txt <- as.character(m$FULL_TEXT[i])
ttl <- ifelse(is.na(m$TITLE[i]), "", as.character(m$TITLE[i]))
out <- data.frame(master_row = i, url = as.character(m$URL[i]),
                  date = as.character(m$DATE[i]), stringsAsFactors = FALSE)
rm(m); invisible(gc())

say("step 1/3 — word rule over", length(txt), "posts x", nrow(v), "patterns")
H  <- digikat_hit_matrix(txt, v, progress = TRUE)
cn <- digikat_tier_counts(H, v)
out$n_decisive <- cn$decisive_match_count
out$n_total    <- cn$total_match_count
out$word_rule  <- digikat_passes_inclusion_v2(cn)
say("  passes the word rule:", sum(out$word_rule),
    sprintf("(%.1f%%)", 100 * mean(out$word_rule)))

say("step 2/3 — comparability flag: would it also pass the OLD 95-word rule?")
old <- digikat_match_religious(txt, v1, min_matches = 2L, include_details = FALSE, progress = TRUE)
out$old_rule <- old$root_match_count >= 2L
say("  passes the old rule:", sum(out$old_rule), sprintf("(%.1f%%)", 100 * mean(out$old_rule)))

say("step 3/3 — second step on the", sum(out$word_rule), "posts that got through")
Ht <- digikat_hit_matrix(ttl, v)
feat <- data.frame(dec = out$n_decisive, amb = cn$ambiguous_match_count,
                   len = log1p(nchar(substr(txt, 1, sp$text_cap))),
                   title_dec = as.integer(rowSums(Ht[, v$tier == "decisive", drop = FALSE]) > 0),
                   title_any = as.integer(rowSums(Ht) > 0))
out$score <- NA_real_
k <- which(out$word_rule)
out$score[k] <- digikat_second_pass_score(txt[k], feat[k, , drop = FALSE], sp, progress = TRUE)
out$threshold_used <- thr
out$second_pass <- !is.na(out$score) & out$score >= thr
out$decision <- ifelse(!out$word_rule, "rejected: word rule",
                ifelse(!out$second_pass, "rejected: second pass", "accepted"))

say("=== result at the provisional threshold ===")
res <- as.data.frame(table(decision = out$decision)); res$pct <- round(100 * res$Freq / nrow(out), 1)
print(res, row.names = FALSE)
saveRDS(out, OUT_FILE)
say("wrote", OUT_FILE, "-", format(file.size(OUT_FILE), big.mark = " "), "bytes")
say("The master was not modified. Scores are stored, so the threshold can be re-set for free.")
