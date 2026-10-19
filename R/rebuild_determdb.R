#!/usr/bin/env Rscript
# Apply the official inclusion rule to the DetermDB general feed for the 2024+ era.
#
#   Rscript R/rebuild_determdb.R                       full run, 2024-01-01 .. latest day in the feed
#   Rscript R/rebuild_determdb.R --from=2026-05-04 --to=2026-05-10   a window (calibration)
#   Rscript R/rebuild_determdb.R --workers=12
#   output: data/rebuild/determ_post2024_decisions_v4.rds   (self-ignoring folder: carries URLs)
#           data/rebuild/determ_post2024_feed_counts.rds    rows scanned per day x platform
#
# Why (PI decision 2026-10-18, plan quality_reports/plans/2026-10-18_corpus-extension-to-2026-10-16.md):
# the vendor .xlsx exports that fed the post-2024 half of the accumulator stop at 2026-06-11, dropped
# YouTube and comments after January 2026, and never carried text for February-May 2024. DetermDB's
# merged table is ONE general feed from 2024-01-01 to the present with full text, so the 2024+ era is
# re-cut from it. The pre-2024 era stays cut from the accumulator (it was itself drawn from DetermDB).
#
# The rule is the official one, unchanged: word list v4 within the first 3 000 characters
# (>=1 decisive, >=2 total), then the second-pass ensemble. The score is stored for every word-rule
# passer so build_corpus.R can cut at any threshold. Only the first 3 000 characters are read, so
# word_rule and word_rule_window are the same flag here (the window fix is built in, not applied
# after). old_rule (the retired 95-term comparability flag) is likewise computed in the window.
#
# Only word-rule passers are stored; a 26-million-row decisions file would carry nothing the corpus
# uses. Rows scanned are kept as per-day counts so the manifest can still report rows_in.
#
# READ-ONLY on DetermDB (every connection opens read_only = TRUE). Resumable: each day is written to
# data/rebuild/.determ_days/ and skipped on a re-run.
suppressPackageStartupMessages({library(DBI); library(duckdb); library(parallel)})
.script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(.script_arg)) {
  setwd(normalizePath(file.path(dirname(sub("^--file=", "", .script_arg[[1]])), ".."),
                      mustWork = TRUE))
}
rm(.script_arg)
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/digikat_paths.R", encoding = "UTF-8")

args    <- commandArgs(trailingOnly = TRUE)
FROM    <- digikat_cli_value(args, "--from", "2024-01-01")
TO      <- digikat_cli_value(args, "--to", "")
WORKERS <- as.integer(digikat_cli_value(args, "--workers", "12"))
OUT_DIR <- "data/rebuild"
OUT     <- file.path(OUT_DIR, "determ_post2024_decisions_v4.rds")
COUNTS  <- file.path(OUT_DIR, "determ_post2024_feed_counts.rds")
DAY_DIR <- file.path(OUT_DIR, ".determ_days")
TERMS   <- "R/religious_terms_v4.R"
MODEL   <- "resources/models/second_pass_v2.rds"
# The nine platforms the corpus has always carried. Radio, TV, print, Bluesky and Threads exist in
# the feed but no page is built for them (PI decision 2026-10-18).
PLATFORMS <- c("web", "facebook", "youtube", "twitter", "reddit", "forum", "instagram", "tiktok",
               "comment")

dir.create(DAY_DIR, recursive = TRUE, showWarnings = FALSE)
gi <- file.path(OUT_DIR, ".gitignore")
if (!file.exists(gi)) writeLines(c("*", "!.gitignore"), gi)   # carries URLs: never committed
say <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n"); flush.console() }

DB  <- digikat_determdb_path()
TBL <- digikat_determdb_table()
con <- dbConnect(duckdb(), dbdir = DB, read_only = TRUE)
if (!nzchar(TO)) TO <- dbGetQuery(con, sprintf('SELECT max("DATE") AS d FROM %s', TBL))$d
days <- dbGetQuery(con, sprintf('SELECT DISTINCT "DATE" AS d FROM %s WHERE "DATE" BETWEEN ? AND ? ORDER BY 1',
                                TBL), params = list(FROM, TO))$d
dbDisconnect(con, shutdown = TRUE)
say("DetermDB:", DB, "|", TBL, "| read-only")
say("window:", FROM, "->", TO, "|", length(days), "days | platforms:", paste(PLATFORMS, collapse = " "))

todo <- days[!file.exists(file.path(DAY_DIR, paste0(days, ".rds")))]
say("days already done:", length(days) - length(todo), "| to scan:", length(todo), "| workers:", WORKERS)

scan_day <- function(day) {
  # A handful of vendor rows carry NUL bytes, which an R string cannot hold; strip them in SQL.
  q <- sprintf(paste("SELECT SOURCE_TYPE, ITEM_ID, replace(URL, chr(0), '') AS URL, \"DATE\", DATETIME,",
                     "replace(TITLE, chr(0), '') AS TITLE,",
                     "replace(substr(FULL_TEXT, 1, %d), chr(0), '') AS T",
                     "FROM %s WHERE \"DATE\" = ? AND SOURCE_TYPE IN (%s)"),
               SP$text_cap, TBL, paste0("'", PLATFORMS, "'", collapse = ","))
  x <- dbGetQuery(CON, q, params = list(day))
  counts <- as.data.frame(table(SOURCE_TYPE = x$SOURCE_TYPE), stringsAsFactors = FALSE)
  names(counts)[2] <- "rows"
  counts$with_text <- as.integer(tapply(!is.na(x$T) & nzchar(x$T), x$SOURCE_TYPE, sum)[counts$SOURCE_TYPE])
  counts$date <- day
  txt <- ifelse(is.na(x$T), "", x$T)
  H  <- digikat_hit_matrix(txt, V)
  cn <- digikat_tier_counts(H, V)
  ok <- digikat_passes_inclusion_v2(cn)
  k  <- which(ok)
  res <- NULL
  if (length(k)) {
    ttl <- ifelse(is.na(x$TITLE[k]), "", x$TITLE[k])
    Ht  <- digikat_hit_matrix(ttl, V)
    feat <- data.frame(dec = cn$decisive_match_count[k], amb = cn$ambiguous_match_count[k],
                       len = log1p(nchar(txt[k])),
                       title_dec = as.integer(rowSums(Ht[, V$tier == "decisive", drop = FALSE]) > 0),
                       title_any = as.integer(rowSums(Ht) > 0))
    old <- digikat_match_religious(txt[k], V1, min_matches = 2L, include_details = FALSE,
                                  progress = FALSE)
    res <- data.frame(
      era = "post2024", source_type = x$SOURCE_TYPE[k], item_id = as.character(x$ITEM_ID[k]),
      url = x$URL[k], date = x$DATE[k], datetime = format(x$DATETIME[k], "%Y-%m-%d %H:%M:%S"),
      n_decisive = cn$decisive_match_count[k], n_total = cn$total_match_count[k],
      word_rule = TRUE, word_rule_window = TRUE, old_rule = old$root_match_count >= 2L,
      score = digikat_second_pass_score(txt[k], feat, SP), threshold_used = THR,
      stringsAsFactors = FALSE)
  }
  out <- list(decisions = res, counts = counts)
  tmp <- file.path(DAY_DIR, paste0(day, ".rds.tmp"))
  saveRDS(out, tmp)
  file.rename(tmp, file.path(DAY_DIR, paste0(day, ".rds")))
  c(day = day, rows = nrow(x), passers = length(k))
}

if (length(todo)) {
  cl <- makePSOCKcluster(min(WORKERS, length(todo)))
  clusterExport(cl, c("DB", "TBL", "TERMS", "MODEL", "PLATFORMS", "DAY_DIR", "scan_day"))
  clusterEvalQ(cl, {
    suppressPackageStartupMessages({library(DBI); library(duckdb); library(stringi)})
    source("R/lib/digikat_utils.R", encoding = "UTF-8")
    source("R/lib/religious_filter.R", encoding = "UTF-8")
    source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
    source("R/lib/second_pass.R", encoding = "UTF-8")
    V   <- digikat_load_religious_terms_v2(TERMS)
    V1  <- digikat_load_religious_terms()
    SP  <- digikat_load_second_pass(MODEL)
    THR <- if (!is.null(SP$deployment_threshold)) SP$deployment_threshold else SP$threshold
    CON <- dbConnect(duckdb(), dbdir = DB, read_only = TRUE)
    NULL
  })
  t0 <- Sys.time(); done <- 0L
  # Chunks of 24 days: progress is reported between chunks and a crash loses at most one chunk.
  for (chunk in split(todo, ceiling(seq_along(todo) / 24))) {
    r <- parLapplyLB(cl, chunk, scan_day)
    done <- done + length(chunk)
    rr <- do.call(rbind, r)
    el <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
    say(sprintf("%d/%d days | last %s | %s rows, %s passers in chunk | %.1f min, ~%.0f min left",
                done, length(todo), chunk[length(chunk)],
                format(sum(as.numeric(rr[, "rows"])), big.mark = " "),
                format(sum(as.numeric(rr[, "passers"])), big.mark = " "),
                el, el / done * (length(todo) - done)))
  }
  clusterEvalQ(cl, dbDisconnect(CON, shutdown = TRUE))
  stopCluster(cl)
}

say("collecting", length(days), "days")
parts <- lapply(file.path(DAY_DIR, paste0(days, ".rds")), readRDS)
dec <- do.call(rbind, lapply(parts, `[[`, "decisions"))
cnt <- do.call(rbind, lapply(parts, `[[`, "counts"))
rm(parts); invisible(gc())
stopifnot(!anyDuplicated(paste(dec$source_type, dec$item_id)), length(unique(dec$threshold_used)) == 1L)
attr(dec, "digikat_source") <- list(determdb = DB, table = TBL, from = FROM, to = TO,
                                    platforms = PLATFORMS, terms = TERMS, model = MODEL,
                                    built = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"))

say("rows scanned:", format(sum(cnt$rows), big.mark = " "),
    "| word-rule passers:", format(nrow(dec), big.mark = " "),
    sprintf("| kept at 0,70 before dedup: %s", format(sum(dec$score >= 0.70), big.mark = " ")))
print(aggregate(cbind(rows) ~ SOURCE_TYPE, cnt, sum))
saveRDS(dec, OUT); saveRDS(cnt, COUNTS)
say("wrote", OUT, "and", COUNTS, "- DetermDB was not modified.")
