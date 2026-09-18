# Source reconstruction probes use only a small invented DuckDB database.
# The native-old table deliberately lacks ITEM_ID and SOURCE_BATCH.
run_barometar_bridge_source_tests <- function() {
  audit <- new.env(parent = globalenv())
  sys.source("studies/demokrscanstvo-barometar/07_bridge.R", envir = audit)
  root <- tempfile("barometar-invented-bridge-source-"); dir.create(root)
  database <- file.path(root, "invented.duckdb")
  definition <- barometar_definition()
  neutral <- paste(rep("Invented neutral body sentence.", 9L), collapse = " ")
  fixture <- function(day, slug, title = "Invented title", body = neutral) data.frame(
    DATE = day, TITLE = title, FROM = "invented.example.invalid",
    URL = paste0("https://invented.example.invalid/", slug), SOURCE_TYPE = "web",
    FULL_TEXT = body, DATETIME = as.POSIXct(paste(day, "12:00:00"), tz = "UTC"),
    stringsAsFactors = FALSE)
  rows <- rbind(
    fixture("2024-05-15", "prior"), fixture("2024-06-15", "prior"),
    fixture("2024-05-15", "short", "Title", paste0("Title", strrep("x", 199L))),
    fixture("2024-06-15", "short"),
    fixture("2024-05-15", "nul-prefix"), fixture("2024-06-15", "nul-prefix"),
    fixture("2024-05-15", "white-space", "Title", paste0("Title:\u0085\u202f\t", strrep("x", 199L))),
    fixture("2024-06-15", "white-space"),
    fixture("2024-05-15", "archive-first", "Arhiva invented", neutral),
    fixture("2024-06-15", "archive-first"),
    fixture("2024-06-15", "control", body = paste("To nema veze s demokršćanstvom.", neutral)),
    fixture("2024-06-15", "tie", body = paste(neutral, "version alpha")),
    fixture("2024-06-15", "tie", body = paste(neutral, "version beta"))
  )
  # Embedded-NUL query keys crash the mandated shared URL decoder. They must
  # never be presented to it for outlets outside this reconstruction's panel.
  outside <- do.call(rbind, lapply(c("outside", "unregistered"), function(host) {
    x <- rbind(fixture("2024-05-15", "outside-prior"), fixture("2024-06-15", "outside-june"))
    x$FROM <- paste0(host, ".example.invalid")
    x$URL <- paste0("https://", x$FROM, "/story?%00bad=1")
    x
  }))
  rows <- rbind(rows, outside)
  registry <- data.frame(outlet_id = c("invented", "outside"),
    from_values = c("invented.example.invalid", "outside.example.invalid"),
    url_hosts = c("invented.example.invalid", "outside.example.invalid"))
  panel <- data.frame(outlet_id = "invented")
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = database)
  DBI::dbWriteTable(con, "media_data", rows)
  DBI::dbExecute(con, "UPDATE media_data SET TITLE='Prefix'||chr(0),FULL_TEXT='Prefix'||'�'||repeat('x',199) WHERE URL LIKE '%/nul-prefix' AND \"DATE\"='2024-05-15'")
  newer <- fixture("2024-06-15", "new-control")
  newer$SOURCE_BATCH <- "mediaspace_full"; newer$ITEM_ID <- 1L
  wrong_batch <- fixture("2024-06-15", "wrong-batch")
  wrong_batch$SOURCE_BATCH <- "luka_opce"; wrong_batch$ITEM_ID <- NA_integer_
  newer_outside <- outside; newer_outside$SOURCE_BATCH <- "mediaspace_full"; newer_outside$ITEM_ID <- seq_len(nrow(outside)) + 10L
  DBI::dbWriteTable(con, "media_data_all", rbind(newer, wrong_batch, newer_outside))
  DBI::dbExecute(con, "CREATE TABLE bad_timing AS SELECT * FROM media_data")
  DBI::dbExecute(con, "UPDATE bad_timing SET \"DATE\"='2024-07-15',DATETIME=TIMESTAMP '2024-05-15 12:00:00' WHERE URL LIKE '%/control'")
  DBI::dbExecute(con, "CREATE TABLE missing_timing AS SELECT * FROM media_data")
  DBI::dbExecute(con, "UPDATE missing_timing SET DATETIME=NULL WHERE URL LIKE '%/control'")
  DBI::dbDisconnect(con, shutdown = TRUE)
  Sys.setFileTime(database, Sys.time() - 600)
  failures <- character(); checked <- 0L
  check <- function(value, label) {
    checked <<- checked + 1L
    if (!isTRUE(value)) failures <<- c(failures, label)
  }
  rejection <- function(expr, pattern) {
    error <- tryCatch({force(expr); NULL}, error = identity)
    if (inherits(error, "error") && !grepl(pattern, conditionMessage(error), fixed = TRUE))
      message("Unexpected invented-fixture error: ", conditionMessage(error))
    inherits(error, "error") && grepl(pattern, conditionMessage(error), fixed = TRUE)
  }
  check(inherits(tryCatch(barometar_canonicalize_url(outside$URL[1L]), error = identity), "error"),
    "invented malformed query is a meaningful shared-decoder crash probe")
  old_fingerprint <- audit$barometar_bridge_fingerprint(database, "main.media_data", "old")
  old <- audit$barometar_bridge_population(database, "main.media_data", "old", registry,
    panel, definition, file.path(root, "old"), old_fingerprint)
  article <- function(slug) digest::digest(paste0("invented|https://invented.example.invalid/", slug), algo = "md5", serialize = FALSE)
  expected <- vapply(c("short", "nul-prefix", "white-space", "control", "tie"), article, character(1L))
  check(setequal(old$rows$article_hash, expected), "native-old table reconstructs exact eligible June URL set without ITEM_ID")
  check(!article("prior") %in% old$rows$article_hash, "earliest prior eligible capture remains outside June")
  check(article("short") %in% old$rows$article_hash, "199-character prior body cannot suppress eligible June capture")
  check(article("nul-prefix") %in% old$rows$article_hash, "SQL lookback uses the same NUL-transported prefix as R eligibility")
  check(article("white-space") %in% old$rows$article_hash, "SQL and ICU strip punctuation/NEL/narrow-space/tab before counting")
  check(!article("archive-first") %in% old$rows$article_hash, "earliest noneditorial representative cannot be replaced by later editorial title")
  ties <- rows[grepl("/tie$", rows$URL), ]
  tie_keys <- vapply(seq_len(nrow(ties)), function(i) digest::digest(paste("luka_opce", "web", "", ties$URL[i],
    "2024-06-15T12:00:00", digest::digest(ties$FULL_TEXT[i], algo = "md5", serialize = FALSE), sep = "|"), algo = "md5", serialize = FALSE), character(1L))
  check(identical(old$rows$doc_key[old$rows$article_hash == article("tie")], min(tie_keys)), "timestamp ties use the standard old-source document identity")
  fresh_fingerprint <- audit$barometar_bridge_fingerprint(database, "main.media_data_all", "new")
  newer_result <- audit$barometar_bridge_population(database, "main.media_data_all", "new", registry,
    panel, definition, file.path(root, "new"), fresh_fingerprint)
  check(identical(newer_result$rows$article_hash, article("new-control")), "new fingerprint and reconstruction both exclude other source batches")
  check(all(old$rows$outlet_id == "invented") && all(newer_result$rows$outlet_id == "invented"),
    "invalid registered non-panel and unmapped URLs in June and lookback cannot break either source reconstruction")
  check(rejection(audit$barometar_bridge_fingerprint(database, "main.bad_timing", "old"), "DATE/DATETIME invariant"),
    "reject later DATE with earlier DATETIME even beyond June fingerprint horizon")
  check(rejection(audit$barometar_bridge_fingerprint(database, "main.missing_timing", "old"), "DATE/DATETIME invariant"),
    "reject missing timestamps before bounded global deduplication")
  classifier <- barometar_classify_batch
  classification_finished <- FALSE
  audit$barometar_classify_batch <- function(...) {
    classification_finished <<- TRUE
    classifier(...)
  }
  # Windows protects the live DuckDB file against timestamp mutation. Inject a
  # stale expected timestamp only after classification, then use the real guard.
  audit$barometar_assert_snapshot <- function(snapshot, con) {
    if (classification_finished) snapshot$file_mtime <- snapshot$file_mtime - 1
    barometar_assert_snapshot(snapshot, con)
  }
  check(rejection(audit$barometar_bridge_population(database, "main.media_data", "old", registry,
    panel, definition, file.path(root, "changed-during-classification"), old_fingerprint), "changed during the run"),
    "final snapshot guard runs after classification and rejects a stale source identity")
  if (length(failures)) stop(paste(c("Bridge source audit failed:", failures), collapse = "\n"))
  message("All ", checked, " invented bridge-source checks passed.")
  invisible(checked)
}

run_barometar_bridge_source_tests()
