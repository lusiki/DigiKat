#!/usr/bin/env Rscript
# Give the post-2024 decisions file the window flag the pre-2024 one already carries.
#
# Gate 1 reads the WHOLE text; gate 2 and the human coder read only the first `text_cap`
# characters. A post admitted solely on words that appear past that point was accepted on evidence
# nothing downstream ever saw, and every such post checked by hand (22 across two rounds) turned out
# not to be Catholic content. `R/rebuild_era.R` records this as `word_rule_window`, but the
# post-2024 half was cut by the earlier `R/rebuild_post2024.R`, which did not.
#
# Without the flag on both sides the defect can only be fixed in one era, which would reintroduce
# the era-dependent inclusion rule the whole rebuild exists to remove. So this recomputes gate 1 over
# the truncated text for the post-2024 half and writes the column back. Nothing else changes: scores,
# decisions and thresholds are carried through untouched.
#
#   Rscript R/backfill_window_flag.R
#
# READ-ONLY with respect to data/merged_comprehensive.rds. Rewrites
# data/rebuild/post2024_decisions_v4.rds in place, keeping the previous file as .bak.
suppressPackageStartupMessages({library(stringi)})
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

DEC   <- "data/rebuild/post2024_decisions_v4.rds"
TERMS <- "R/religious_terms_v4.R"
MODEL <- "resources/models/second_pass_v2.rds"
STREAM <- "filtered_religious"

say <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n"); flush.console() }

d <- readRDS(DEC)
if ("word_rule_window" %in% names(d)) {
  say("post2024_decisions_v4.rds already carries word_rule_window - nothing to do")
  quit(status = 0)
}
say("rows in the decisions file:", nrow(d))

v  <- digikat_load_religious_terms_v2(TERMS)
sp <- digikat_load_second_pass(MODEL)
CAP <- sp$text_cap
say("word list:", TERMS, "-", nrow(v), "terms | window:", CAP, "characters")

say("loading master (read-only)...")
m <- readRDS("data/merged_comprehensive.rds")
i <- which(m$data_source == STREAM)
# The decisions file stores master row indices; the two must line up exactly or the flag would be
# attached to the wrong posts. Fail loudly rather than silently mis-key 440 724 rows.
stopifnot(identical(as.integer(i), as.integer(d$master_row)))
txt <- substr(as.character(m$FULL_TEXT[i]), 1, CAP)
rm(m); invisible(gc())
say("master rows agree with the decisions file - proceeding")

say("gate 1 over the first", CAP, "characters of", length(txt), "posts x", nrow(v), "patterns")
cnw <- digikat_tier_counts(digikat_hit_matrix(txt, v, progress = TRUE), v)
d$word_rule_window <- digikat_passes_inclusion_v2(cnw)
if (!"era" %in% names(d)) d$era <- "post2024"

acc <- d$decision == "accepted"
say("accepted at 0,40:", sum(acc),
    "| of those, admitted only past", CAP, "characters:", sum(acc & !d$word_rule_window),
    sprintf("(%.1f%%)", 100 * mean(!d$word_rule_window[acc])))

tmp <- paste0(DEC, ".tmp")
saveRDS(d, tmp)
if (file.exists(DEC)) file.rename(DEC, paste0(DEC, ".bak"))
file.rename(tmp, DEC)
say("wrote", DEC, "- previous file kept as", paste0(basename(DEC), ".bak"))
say("The master was not modified.")
