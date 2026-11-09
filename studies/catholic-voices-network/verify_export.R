source("studies/catholic-voices-network/00_common.R", encoding = "UTF-8")
con <- DBI::dbConnect(duckdb::duckdb(), file.path(workdir, "voices.duckdb"), read_only = TRUE)
counts <- DBI::dbGetQuery(con, "SELECT platform, count(*) AS n FROM docs GROUP BY platform")
expected <- unlist(manifest$corpus$platform_counts)
stopifnot(setequal(counts$platform, names(expected)))
stopifnot(all(as.numeric(counts$n) == as.numeric(expected[counts$platform])))
totals <- DBI::dbGetQuery(con, "SELECT count(*) AS n, count(DISTINCT doc_id) AS unique_ids, min(date) AS first_date, max(date) AS last_date, count(DISTINCT corpus_sha256) AS hashes, count(DISTINCT config_hash) AS configs FROM docs")
stopifnot(totals$n == manifest$corpus$rows, totals$unique_ids == totals$n,
  totals$first_date == manifest$corpus$date_min, totals$last_date == manifest$corpus$date_max,
  totals$hashes == 1, totals$configs == 1)
checkpoints <- DBI::dbGetQuery(con, "SELECT * FROM checkpoints WHERE stage='export_docs' ORDER BY batch_start")
stopifnot(identical(checkpoints$batch_start, seq.int(1L, manifest$corpus$rows, by = config$checkpoint_documents)),
  all(checkpoints$status == "complete"), tail(checkpoints$batch_end, 1) == manifest$corpus$rows)
DBI::dbDisconnect(con, shutdown = TRUE)
cat("PASS: all rows, unique IDs, nine platform counts, dates and checkpoint coverage match the pinned manifest.\n")
