#!/usr/bin/env Rscript
# Apply the rule to ONE era of the master. One code path for both halves, on purpose: the point of
# the exercise is that 2021-2024 and 2024-2026 end up defined by the same inclusion rule, and the
# cheapest way to be able to say that is for the same script to do both.
#
#   Rscript R/rebuild_era.R --era=pre2024   [terms_file] [model_file] [output_file]
#   Rscript R/rebuild_era.R --era=post2024  [terms_file] [model_file] [output_file]
#   defaults: R/religious_terms_v4.R  resources/models/second_pass_v2.rds
#             data/rebuild/<era>_decisions_v4.rds
#
#   era        master stream         span        what this can do
#   pre2024    original_dta          2021-2024   clean what is in the corpus
#   post2024   filtered_religious    2024-2026   clean what is in the corpus
#
# NEITHER era is rebuilt from a raw feed here. DetermDB is the feed the pre-2024 stream was cut from
# and would recover new material, but there is no equivalent feed for the post-2024 half
# (data/EXTERNAL_DETERMDB.md §3.3), so feeding one era and not the other would trade the old
# comparability confound for a bigger one. Feed expansion is a separate decision.
#
# READ-ONLY with respect to data/merged_comprehensive.rds. Writes one decisions file to
# data/rebuild/, which is self-ignoring (it carries URLs). The score is stored for EVERY post that
# passes the word rule, so the accept/reject threshold can be changed later without rescanning.
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
source("R/lib/second_pass.R", encoding = "UTF-8")

STREAM <- c(pre2024 = "original_dta", post2024 = "filtered_religious")

.a  <- commandArgs(trailingOnly = TRUE)
.e  <- grep("^--era=", .a, value = TRUE)
ERA <- if (length(.e)) sub("^--era=", "", .e[[1]]) else ""
if (!ERA %in% names(STREAM))
  stop("give --era=pre2024 or --era=post2024", call. = FALSE)
.a <- .a[!grepl("^--", .a)]
TERMS_FILE <- if (length(.a) >= 1) .a[[1]] else "R/religious_terms_v4.R"
MODEL_FILE <- if (length(.a) >= 2) .a[[2]] else "resources/models/second_pass_v2.rds"
OUT_FILE   <- if (length(.a) >= 3) .a[[3]] else
  file.path("data/rebuild", paste0(ERA, "_decisions_v4.rds"))
OUT_DIR <- dirname(OUT_FILE)
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)
gi <- file.path(OUT_DIR, ".gitignore")
if (!file.exists(gi)) writeLines(c("*", "!.gitignore"), gi)   # carries URLs: never committed

say <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n"); flush.console() }

v1 <- digikat_load_religious_terms()
v  <- digikat_load_religious_terms_v2(TERMS_FILE)
sp <- digikat_load_second_pass(MODEL_FILE)
thr <- if (!is.null(sp$deployment_threshold)) sp$deployment_threshold else sp$threshold
say("era:", ERA, "- master stream", STREAM[[ERA]])
say("word list:", TERMS_FILE, "-", nrow(v), "terms |",
    sum(v$tier == "decisive"), "decisive,", sum(v$tier == "ambiguous"), "ambiguous")
say("model:", MODEL_FILE, "-", length(sp$models), "models | threshold", sprintf("%.4f", thr),
    if (!is.null(sp$deployment_threshold)) "(deployment)" else "(calibrated)")

say("loading master (read-only)...")
m <- readRDS("data/merged_comprehensive.rds")
stopifnot("data_source" %in% names(m), "FULL_TEXT" %in% names(m))
i <- which(m$data_source == STREAM[[ERA]])
if (!length(i)) stop("no rows for stream ", STREAM[[ERA]], call. = FALSE)
say("rows in this era:", length(i))
txt <- as.character(m$FULL_TEXT[i])
ttl <- ifelse(is.na(m$TITLE[i]), "", as.character(m$TITLE[i]))
out <- data.frame(era = ERA, master_row = i, url = as.character(m$URL[i]),
                  date = as.character(m$DATE[i]), stringsAsFactors = FALSE)
rm(m); invisible(gc())
say("date span:", min(out$date, na.rm = TRUE), "->", max(out$date, na.rm = TRUE))
say("rows with no text:", sum(is.na(txt) | !nzchar(txt)))

say("step 1/3 - word rule over", length(txt), "posts x", nrow(v), "patterns")
H  <- digikat_hit_matrix(txt, v, progress = TRUE)
cn <- digikat_tier_counts(H, v)
out$n_decisive <- cn$decisive_match_count
out$n_total    <- cn$total_match_count
out$word_rule  <- digikat_passes_inclusion_v2(cn)
say("  passes the word rule:", sum(out$word_rule),
    sprintf("(%.1f%%)", 100 * mean(out$word_rule)))

say("step 2/3 - comparability flag: would it also pass the OLD 95-word rule?")
old <- digikat_match_religious(txt, v1, min_matches = 2L, include_details = FALSE, progress = TRUE)
out$old_rule <- old$root_match_count >= 2L
say("  passes the old rule:", sum(out$old_rule), sprintf("(%.1f%%)", 100 * mean(out$old_rule)))

say("step 3/3 - second step on the", sum(out$word_rule), "posts that got through")
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

# how much of the kept pile leans on evidence past the 3000 characters gate 2 and the coder see —
# the open window question from the v4 plan, measured rather than assumed
cnw <- digikat_tier_counts(digikat_hit_matrix(substr(txt, 1, sp$text_cap), v), v)
out$word_rule_window <- digikat_passes_inclusion_v2(cnw)
say("accepted posts that pass only on evidence past", sp$text_cap, "characters:",
    sum(out$decision == "accepted" & !out$word_rule_window),
    sprintf("(%.1f%% of accepts)", 100 * mean(!out$word_rule_window[out$decision == "accepted"])))

say("=== result at threshold", sprintf("%.2f", thr), "===")
res <- as.data.frame(table(decision = out$decision)); res$pct <- round(100 * res$Freq / nrow(out), 1)
print(res, row.names = FALSE)
saveRDS(out, OUT_FILE)
say("wrote", OUT_FILE, "-", format(file.size(OUT_FILE), big.mark = " "), "bytes")
say("The master was not modified. Scores are stored, so the threshold can be re-set for free.")
