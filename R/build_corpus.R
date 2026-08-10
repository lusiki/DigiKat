#!/usr/bin/env Rscript
# Build the official DigiKat corpus: the posts one inclusion rule keeps, across both collection eras.
#
#   Rscript R/build_corpus.R                    preview - counts only, writes nothing
#   Rscript R/build_corpus.R --apply            write data/digikat_corpus.rds + its manifest
#   Rscript R/build_corpus.R --threshold=0.80   re-cut at another gate-2 threshold (both eras)
#   Rscript R/build_corpus.R --no-window-fix    keep posts admitted only past the 3 000-character gate
#
# The corpus is DERIVED. data/merged_comprehensive.rds stays the accumulator and is opened read-only
# here; this script never writes to it and never touches a backup. Rebuilding is cheap and exact, so
# the corpus is not itself backed up: master + the two decisions files reproduce it byte for byte.
#
# One rule, both eras. That is the property the whole rebuild exists to establish, so it is asserted
# rather than assumed: the two decisions files must have been cut by the same model at the same
# threshold and must both carry the window flag, or this refuses to build.
#
# Gate 1  word list v4, >=1 decisive and >=2 terms total, within the first 3 000 characters
# Gate 2  second-pass ensemble score >= the threshold (default 0,70, set by the PI 2026-08-10)
suppressPackageStartupMessages({library(dplyr)})
.script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(.script_arg)) {
  setwd(normalizePath(file.path(dirname(sub("^--file=", "", .script_arg[[1]])), ".."),
                      mustWork = TRUE))
}
rm(.script_arg)
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/digikat_paths.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")

PRE   <- "data/rebuild/pre2024_decisions_v4.rds"
POST  <- "data/rebuild/post2024_decisions_v4.rds"
TERMS <- "R/religious_terms_v4.R"
MODEL <- "resources/models/second_pass_v2.rds"
OUT   <- digikat_corpus_path()
MAN   <- digikat_corpus_manifest_path()

# The PI's decision of 2026-08-10. 0,80 was the joint curve's recommendation (88,0% clean, keeps
# 84,0%); 0,70 was chosen as the volume-leaning option (84,5% clean, keeps 87,2%, era gap 13,6
# points). Changing this redefines the corpus and is a PI decision, not a script's default drifting.
DEFAULT_THRESHOLD <- 0.70

args        <- commandArgs(trailingOnly = TRUE)
apply_it    <- "--apply" %in% args
window_fix  <- !("--no-window-fix" %in% args)
.t          <- grep("^--threshold=", args, value = TRUE)
THRESHOLD   <- if (length(.t)) as.numeric(sub("^--threshold=", "", .t[[1]])) else DEFAULT_THRESHOLD
if (is.na(THRESHOLD) || THRESHOLD < 0 || THRESHOLD > 1) stop("--threshold must be in [0,1]", call. = FALSE)

say <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n"); flush.console() }
line <- function(s) cat("\n=== ", s, " ===\n", sep = "")

terms_tbl <- digikat_load_religious_terms_v2(TERMS)

# --- the two halves ------------------------------------------------------------------------------
a <- readRDS(PRE)
b <- readRDS(POST)
if (!"era" %in% names(b)) b$era <- "post2024"

need <- c("era", "master_row", "date", "n_decisive", "n_total", "word_rule", "old_rule",
          "score", "threshold_used", "word_rule_window")
for (nm in list(pre2024 = PRE, post2024 = POST)) {
  d <- if (identical(nm, PRE)) a else b
  miss <- setdiff(need, names(d))
  if (length(miss)) {
    stop(nm, " is missing: ", paste(miss, collapse = ", "),
         if ("word_rule_window" %in% miss)
           "\nRun: Rscript R/backfill_window_flag.R  (the window fix must land on BOTH eras or the eras stop matching)"
         else "", call. = FALSE)
  }
}
if (!identical(unique(a$threshold_used), unique(b$threshold_used))) {
  stop("the two eras were scored against different deployment thresholds - they are not one rule",
       call. = FALSE)
}
d <- bind_rows(a[, need], b[, need])
rm(a, b); invisible(gc())

say("decisions loaded:", format(nrow(d), big.mark = " "), "rows across",
    paste(sort(unique(d$era)), collapse = " + "))
say("threshold:", sprintf("%.2f", THRESHOLD),
    if (THRESHOLD == DEFAULT_THRESHOLD) "(PI decision, 2026-08-10)" else "(OVERRIDE)")
say("window fix:", if (window_fix) "ON - gate 1 must fire within the first 3 000 characters"
    else "OFF - accepting evidence past the coder's window")

# --- the rule ------------------------------------------------------------------------------------
gate1 <- if (window_fix) d$word_rule & d$word_rule_window else d$word_rule
gate2 <- !is.na(d$score) & d$score >= THRESHOLD
d$kept <- gate1 & gate2

line("what the rule does")
cat(sprintf("  rows in                       : %s\n", format(nrow(d), big.mark = " ")))
cat(sprintf("  rejected by the word rule     : %s\n", format(sum(!d$word_rule), big.mark = " ")))
if (window_fix)
  cat(sprintf("  rejected by the window fix    : %s  (word rule fired only past 3 000 characters)\n",
              format(sum(d$word_rule & !d$word_rule_window), big.mark = " ")))
cat(sprintf("  rejected by the second pass   : %s\n", format(sum(gate1 & !gate2), big.mark = " ")))
cat(sprintf("  KEPT                          : %s  (%.1f%%)\n",
            format(sum(d$kept), big.mark = " "), 100 * mean(d$kept)))

by_era <- d |> group_by(era) |>
  summarise(rows_in = n(), n_kept = sum(kept), kept_pct = round(100 * mean(kept), 1),
            window_only_dropped = sum(word_rule & !word_rule_window & score >= THRESHOLD &
                                        !is.na(score)),
            span = paste(min(date, na.rm = TRUE), max(date, na.rm = TRUE), sep = " -> "),
            .groups = "drop") |>
  rename(kept = n_kept)
line("by era"); print(as.data.frame(by_era), row.names = FALSE)

d$year <- substr(as.character(d$date), 1, 4)
by_year <- d |> group_by(year) |>
  summarise(rows_in = n(), n_kept = sum(kept), kept_pct = round(100 * mean(kept), 1),
            .groups = "drop") |>
  rename(kept = n_kept)
line("by year"); print(as.data.frame(by_year), row.names = FALSE)

# --- assemble ------------------------------------------------------------------------------------
say("loading the accumulator (read-only):", digikat_legacy_master_path())
m <- readRDS(digikat_legacy_master_path())
master_rows <- nrow(m); master_cols <- ncol(m)
if (max(d$master_row) > master_rows) {
  stop("the decisions files index rows beyond the accumulator (", max(d$master_row), " > ",
       master_rows, ") - the master changed under them; re-run R/rebuild_era.R", call. = FALSE)
}

i <- d$master_row[d$kept]
k <- d[d$kept, ]
corpus <- m[i, , drop = FALSE]
rm(m); invisible(gc())

# Provenance travels WITH the row. Anyone holding the corpus can see which era a post came from,
# what the rule scored it, and which accumulator row it was, without needing this script.
corpus$dk_era         <- k$era
corpus$dk_master_row  <- k$master_row
corpus$dk_n_decisive  <- k$n_decisive
corpus$dk_n_total     <- k$n_total
corpus$dk_score       <- k$score
corpus$dk_old_rule    <- k$old_rule          # would the retired 95-term >=2 rule also have kept it
corpus$dk_rule        <- "v4+sp2@thr"
attr(corpus, "digikat_rule") <- list(
  terms = TERMS, model = MODEL, threshold = THRESHOLD, window_fix = window_fix,
  window_chars = 3000L, built = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
)
rownames(corpus) <- NULL

say("corpus assembled:", format(nrow(corpus), big.mark = " "), "rows x", ncol(corpus), "columns",
    sprintf("(%d from the accumulator + %d provenance)", master_cols, ncol(corpus) - master_cols))

plat <- if ("SOURCE_TYPE" %in% names(corpus)) table(as.character(corpus$SOURCE_TYPE)) else table(character(0))
line("by platform"); print(as.data.frame(plat, stringsAsFactors = FALSE), row.names = FALSE)

if (!apply_it) {
  cat("\nPREVIEW ONLY - nothing was written. Re-run with --apply to install:\n  ", OUT, "\n", sep = "")
  quit(save = "no", status = 0L)
}

# --- write ---------------------------------------------------------------------------------------
# Staged then renamed, so an interrupted run cannot leave a half-written official corpus in place.
tmp <- paste0(OUT, ".tmp")
say("writing", tmp)
saveRDS(corpus, tmp)
back <- readRDS(tmp)
stopifnot(nrow(back) == nrow(corpus), ncol(back) == ncol(corpus))
rm(back); invisible(gc())
if (file.exists(OUT)) say("replacing the existing corpus (re-derivable from master + decisions)")
file.rename(tmp, OUT)
say("wrote", OUT, "-", format(file.size(OUT), big.mark = " "), "bytes")

dates <- as.character(corpus$DATE)
manifest <- list(
  schema_version = 1L,
  generated_utc = format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%d %H:%M:%S UTC"),
  generator = "R/build_corpus.R",
  corpus = list(
    path = OUT, rows = nrow(corpus), columns = ncol(corpus),
    bytes = as.numeric(file.size(OUT)), sha256 = digikat_hash_file(OUT),
    date_min = min(dates, na.rm = TRUE), date_max = max(dates, na.rm = TRUE),
    year_min = as.integer(substr(min(dates, na.rm = TRUE), 1, 4)),
    year_max = as.integer(substr(max(dates, na.rm = TRUE), 1, 4)),
    platforms = as.integer(length(plat)),
    platform_counts = as.list(setNames(as.integer(plat), names(plat)))
  ),
  rule = list(
    description = paste("word list v4 within the first 3 000 characters (>=1 decisive, >=2 total),",
                        "then the second-pass ensemble at", sprintf("%.2f", THRESHOLD)),
    # Counted here, not typed, and carried in the manifest so a Quarto page can quote them without
    # sourcing the term list — v4 resolves its own paths from the repo root and will not load from
    # inside pages/.
    terms_count = nrow(terms_tbl),
    terms_decisive = sum(terms_tbl$tier == "decisive"),
    terms_ambiguous = sum(terms_tbl$tier == "ambiguous"),
    min_decisive = 1L, min_total = 2L,
    terms_file = TERMS, terms_sha256 = digikat_hash_file(TERMS),
    model_file = MODEL, model_sha256 = digikat_hash_file(MODEL),
    threshold = THRESHOLD, window_fix = window_fix, window_chars = 3000L,
    identical_across_eras = TRUE,
    measured_precision_note = paste(
      "Measured at threshold 0,40 on 250 hand-read posts per era: 68,0% genuinely Catholic pre-2024,",
      "87,0% post-2024. The joint threshold curve puts this corpus at roughly 84,5% genuine at 87,2%",
      "recall of genuine material. The window fix removes posts an audit found 0 of 22 genuine and is",
      "not separately re-measured.")
  ),
  source = list(
    accumulator = digikat_legacy_master_path(),
    accumulator_rows = master_rows, accumulator_columns = master_cols,
    decisions_pre2024 = PRE, decisions_post2024 = POST
  ),
  eras = lapply(split(by_era, by_era$era), function(r) list(
    rows_in = as.integer(r$rows_in), kept = as.integer(r$kept),
    kept_pct = as.numeric(r$kept_pct), span = r$span)),
  years = setNames(lapply(seq_len(nrow(by_year)), function(j) list(
    rows_in = as.integer(by_year$rows_in[j]), kept = as.integer(by_year$kept[j]))), by_year$year),
  caveats = list(
    instrument_change_2024 = paste(
      "One inclusion rule makes the two eras RULE-comparable, not CAPTURE-comparable. The collection",
      "method changed in 2024 and the kept share still steps about 20 points down at that break.",
      "A rise in post counts across it is not a rise in media attention."),
    text_gap = "February-May 2024 carries no text in the vendor feed, so neither era has rows there."
  )
)
writeLines(jsonlite::toJSON(manifest, auto_unbox = TRUE, pretty = TRUE, null = "null"), MAN,
           useBytes = TRUE)
say("wrote", MAN, "(tracked, no PII)")

cat("\nThe accumulator was not modified. data/processed/ and data/nlp/ are now STALE:\n",
    "  Rscript R/03_aggregate.R          # preview\n",
    "  Rscript R/03_aggregate.R --apply  # HARD GATE - confirm with the PI\n",
    "  Rscript R/04_nlp.R --build\n",
    "  Rscript R/05_page_summaries.R --build\n", sep = "")
