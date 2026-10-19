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
# Since 2026-10-18 (PI decision, plan 2026-10-18_corpus-extension-to-2026-10-16.md) the 2024+ era is
# cut from the DetermDB general feed by R/rebuild_determdb.R, not from the accumulator's vendor
# exports, which stop at 2026-06-11 and lost YouTube and comments after January 2026. The pre-2024
# era is unchanged but truncated at ERA_SPLIT, so the one collection seam falls on a year boundary.
# --post-source=accumulator rebuilds the 2026-08-10 corpus exactly (both eras from the accumulator).
DETERM        <- "data/rebuild/determ_post2024_decisions_v4.rds"
DETERM_COUNTS <- "data/rebuild/determ_post2024_feed_counts.rds"
ERA_SPLIT     <- "2024-01-01"
# Platforms the DetermDB feed carries only intermittently. `comment` has rows in 2024-04..06 and
# 2026-08..10 and none in between, so keeping it would print collection bursts as attention spikes.
# Left out of the 2024+ era (decision 2026-10-18); drop it from this vector to re-include.
POST_EXCLUDE  <- c("comment")
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
POST_SOURCE <- digikat_cli_value(args, "--post-source", "determdb")
if (!POST_SOURCE %in% c("determdb", "accumulator"))
  stop("--post-source must be determdb or accumulator", call. = FALSE)
if (is.na(THRESHOLD) || THRESHOLD < 0 || THRESHOLD > 1) stop("--threshold must be in [0,1]", call. = FALSE)

say <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n"); flush.console() }
line <- function(s) cat("\n=== ", s, " ===\n", sep = "")

terms_tbl <- digikat_load_religious_terms_v2(TERMS)

# --- the two halves ------------------------------------------------------------------------------
a <- readRDS(PRE)
if (POST_SOURCE == "determdb") {
  # word-rule passers only; rows scanned come from the feed counts
  b <- readRDS(DETERM)
  b <- b[!b$source_type %in% POST_EXCLUDE, ]
  b$master_row <- NA_integer_
  feed_counts <- readRDS(DETERM_COUNTS)
  feed_counts <- feed_counts[!feed_counts$SOURCE_TYPE %in% POST_EXCLUDE, ]
  pre_dropped <- sum(a$date >= ERA_SPLIT, na.rm = TRUE)
  a <- a[!is.na(a$date) & a$date < ERA_SPLIT, ]
} else {
  b <- readRDS(POST)
}
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
keys <- c("source_type", "item_id", "url", "datetime")
d <- bind_rows(a[, intersect(c(need, "url"), names(a))], b[, intersect(c(need, keys), names(b))])
rm(a, b); invisible(gc())
if (POST_SOURCE == "determdb")
  say("pre-2024 era truncated at", ERA_SPLIT, "- dropped", format(pre_dropped, big.mark = " "),
      "accumulator rows dated 2024+; the 2024+ era comes from DetermDB")

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

# The DetermDB feed can hold one article under several platform records or URL spellings. Keep the
# earliest record per canonical URL, and drop any 2024+ record whose URL the pre-2024 era already
# holds, so one piece of content is counted once. (The accumulator was deduplicated at append time.)
dup_within <- dup_across <- 0L
if (POST_SOURCE == "determdb") {
  post_k <- which(d$kept & d$era == "post2024")
  pre_k  <- which(d$kept & d$era == "pre2024")
  cu_post <- digikat_canonicalize_url(d$url[post_k])
  ord <- order(d$datetime[post_k], d$source_type[post_k], d$item_id[post_k])
  dup <- logical(length(post_k)); dup[ord] <- duplicated(cu_post[ord])
  dup_within <- sum(dup)
  across <- !dup & cu_post %in% digikat_canonicalize_url(d$url[pre_k])
  dup_across <- sum(across)
  d$kept[post_k[dup | across]] <- FALSE
  say("2024+ duplicates removed:", format(dup_within, big.mark = " "), "within the era,",
      format(dup_across, big.mark = " "), "already held by the pre-2024 era")
}

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
if (POST_SOURCE == "determdb") {
  # The 2024+ decisions file holds word-rule passers only; rows_in is every row the feed carried on
  # the nine corpus platforms, so the two eras' kept_pct measure different things (a query-cut
  # stream versus the whole general feed) and must not be compared.
  j <- by_era$era == "post2024"
  by_era$word_rule_passers <- NA_integer_
  by_era$word_rule_passers[j] <- by_era$rows_in[j]
  by_era$rows_in[j] <- sum(feed_counts$rows)
  by_era$kept_pct[j] <- round(100 * by_era$kept[j] / by_era$rows_in[j], 2)
  by_era$span[j] <- paste(min(feed_counts$date), max(feed_counts$date), sep = " -> ")
}
line("by era"); print(as.data.frame(by_era), row.names = FALSE)

d$year <- substr(as.character(d$date), 1, 4)
by_year <- d |> group_by(year) |>
  summarise(rows_in = n(), n_kept = sum(kept), kept_pct = round(100 * mean(kept), 1),
            .groups = "drop") |>
  rename(kept = n_kept)
if (POST_SOURCE == "determdb") {
  fy <- tapply(feed_counts$rows, substr(feed_counts$date, 1, 4), sum)
  pre_y <- table(substr(d$date[d$era == "pre2024"], 1, 4))
  by_year$rows_in <- as.integer(ifelse(by_year$year %in% names(fy), fy[by_year$year], 0) +
                                ifelse(by_year$year %in% names(pre_y), pre_y[by_year$year], 0))
  by_year$kept_pct <- round(100 * by_year$kept / by_year$rows_in, 2)
}
line("by year"); print(as.data.frame(by_year), row.names = FALSE)

# --- assemble ------------------------------------------------------------------------------------
say("loading the accumulator (read-only):", digikat_legacy_master_path())
m <- readRDS(digikat_legacy_master_path())
master_rows <- nrow(m); master_cols <- ncol(m)
if (max(d$master_row, na.rm = TRUE) > master_rows) {
  stop("the decisions files index rows beyond the accumulator (", max(d$master_row, na.rm = TRUE), " > ",
       master_rows, ") - the master changed under them; re-run R/rebuild_era.R", call. = FALSE)
}

k <- d[d$kept, ]
k_acc <- !is.na(k$master_row)
corpus <- m[k$master_row[k_acc], , drop = FALSE]
acc_names <- names(m); acc_class <- lapply(m, function(z) class(z)[1])
rm(m); invisible(gc())
k <- rbind(k[k_acc, ], k[!k_acc, ])          # accumulator rows first, matching `corpus`

if (any(!k_acc)) {
  # Fetch the kept 2024+ rows in full from DetermDB (read-only) and give them the accumulator's
  # 47-column shape: the 45 shared vendor columns coerced to the accumulator's classes, `year` from
  # DATE, and data_source = "determdb". DATETIME / ITEM_ID / I_FILTERED / SOURCE_BATCH are dropped
  # (ITEM_ID survives as dk_source_id below).
  suppressPackageStartupMessages({library(DBI); library(duckdb)})
  kd <- k[!k_acc, ]
  say("fetching", format(nrow(kd), big.mark = " "), "kept 2024+ rows from DetermDB (read-only)")
  con <- dbConnect(duckdb(), dbdir = digikat_determdb_path(), read_only = TRUE)
  duckdb::duckdb_register(con, "dk_keep",
                          data.frame(source_type = kd$source_type, item_id = as.numeric(kd$item_id),
                                     ord = seq_len(nrow(kd))))
  tbl_name <- utils::tail(strsplit(digikat_determdb_table(), ".", fixed = TRUE)[[1]], 1)
  shared <- intersect(acc_names, dbListFields(con, tbl_name))
  sel <- paste0("replace(CAST(t.\"", shared, "\" AS VARCHAR), chr(0), '') AS \"", shared, "\"")
  num_like <- shared[vapply(acc_class[shared], function(c) c %in% c("numeric", "integer", "logical"), TRUE)]
  sel[shared %in% num_like] <- paste0("t.\"", num_like, "\"")
  q <- paste0("SELECT k.ord, ", paste(sel, collapse = ", "), " FROM ", digikat_determdb_table(),
              " t JOIN dk_keep k ON t.SOURCE_TYPE = k.source_type AND CAST(t.ITEM_ID AS DOUBLE) = k.item_id",
              " WHERE t.\"DATE\" >= '", ERA_SPLIT, "'")
  x <- dbGetQuery(con, q)
  dbDisconnect(con, shutdown = TRUE)
  if (nrow(x) != nrow(kd) || anyDuplicated(x$ord))
    stop("DetermDB returned ", nrow(x), " rows for ", nrow(kd), " kept keys - the feed changed under ",
         "the decisions file; re-run R/rebuild_determdb.R", call. = FALSE)
  x <- x[order(x$ord), , drop = FALSE]
  add <- as.data.frame(lapply(setNames(acc_names, acc_names), function(nm) {
    if (nm == "year") return(as.numeric(substr(x$DATE, 1, 4)))
    if (nm == "data_source") return(rep("determdb", nrow(x)))
    v <- if (nm %in% names(x)) x[[nm]] else rep(NA, nrow(x))
    switch(acc_class[[nm]], numeric = as.numeric(v), integer = as.integer(v),
           logical = as.logical(v), character = as.character(v), v)
  }), stringsAsFactors = FALSE, check.names = FALSE)
  corpus <- rbind(corpus, add)
  rm(x, add); invisible(gc())
}

# Provenance travels WITH the row. Anyone holding the corpus can see which era a post came from,
# what the rule scored it, and which accumulator row (pre-2024) or DetermDB record (2024+,
# dk_source_id = "SOURCE_TYPE:ITEM_ID") it was, without needing this script.
corpus$dk_era         <- k$era
corpus$dk_master_row  <- k$master_row
corpus$dk_n_decisive  <- k$n_decisive
corpus$dk_n_total     <- k$n_total
corpus$dk_score       <- k$score
corpus$dk_old_rule    <- k$old_rule          # would the retired 95-term >=2 rule also have kept it
corpus$dk_rule        <- "v4+sp2@thr"
corpus$dk_source_id   <- ifelse(is.na(k$master_row), paste0(k$source_type, ":", format(as.numeric(k$item_id), scientific = FALSE, trim = TRUE)), NA_character_)
attr(corpus, "digikat_rule") <- list(
  terms = TERMS, model = MODEL, threshold = THRESHOLD, window_fix = window_fix,
  window_chars = 3000L, built = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
)
rownames(corpus) <- NULL

say("corpus assembled:", format(nrow(corpus), big.mark = " "), "rows x", ncol(corpus), "columns",
    sprintf("(%d vendor columns + %d provenance)", master_cols, ncol(corpus) - master_cols))
corpus <- corpus[order(corpus$DATE, corpus$TIME), , drop = FALSE]; rownames(corpus) <- NULL

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
  source = c(list(
    accumulator = "data/merged_comprehensive.rds",
    accumulator_rows = master_rows, accumulator_columns = master_cols,
    post2024_source = POST_SOURCE,
    decisions_pre2024 = PRE,
    decisions_post2024 = if (POST_SOURCE == "determdb") DETERM else POST
  ), if (POST_SOURCE == "determdb") list(
    era_split = ERA_SPLIT,
    determdb_table = digikat_determdb_table(),
    determdb_rows_scanned = sum(feed_counts$rows),
    determdb_span = paste(min(feed_counts$date), max(feed_counts$date), sep = " -> "),
    determdb_platforms = sort(unique(feed_counts$SOURCE_TYPE)),
    determdb_excluded_platforms = POST_EXCLUDE,
    duplicates_removed_within_2024plus = dup_within,
    duplicates_removed_across_eras = dup_across
  )),
  eras = lapply(split(by_era, by_era$era), function(r) list(
    rows_in = as.integer(r$rows_in), kept = as.integer(r$kept),
    kept_pct = as.numeric(r$kept_pct), span = r$span)),
  years = setNames(lapply(seq_len(nrow(by_year)), function(j) list(
    rows_in = as.integer(by_year$rows_in[j]), kept = as.integer(by_year$kept[j]))), by_year$year),
  caveats = if (POST_SOURCE == "determdb") list(
    instrument_change_2024 = paste(
      "One inclusion rule makes the two eras RULE-comparable, not CAPTURE-comparable. Up to 2023 the",
      "corpus is cut from a stream the vendor had already selected with a religious keyword query;",
      "from 2024-01-01 it is cut from the vendor's whole general feed. The seam falls on 1 January 2024.",
      "A rise in post counts across it is not a rise in media attention."),
    precision_2024plus = paste(
      "The rule's precision was measured on the accumulator's post-2024 stream (87,0% at 0,40). The",
      "2024+ era is now cut from the general feed, which holds material that stream never carried; its",
      "precision is being re-measured on a hand-read sample.")
  ) else list(
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
