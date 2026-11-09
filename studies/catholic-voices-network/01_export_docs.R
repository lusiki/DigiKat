# Read-only corpus input; transactional batches and checkpoint ledger are committed together.
# Uses installed global R packages via --vanilla; project renv remains unchanged.
source("studies/catholic-voices-network/00_common.R", encoding = "UTF-8")
main <- function() {
  path <- digikat_corpus_path()
  cat(utc(), "Verifying corpus SHA-256...\n")
  stopifnot(identical(digest::digest(file = path, algo = "sha256"), manifest$corpus$sha256))
  con <- open_db()
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  DBI::dbExecute(con, "CREATE TABLE IF NOT EXISTS checkpoints (stage VARCHAR, batch_start INTEGER, batch_end INTEGER, status VARCHAR, corpus_sha256 VARCHAR, config_hash VARCHAR, created_utc VARCHAR, PRIMARY KEY(stage,batch_start))")
  done <- DBI::dbGetQuery(con, "SELECT batch_start FROM checkpoints WHERE stage='export_docs' AND status='complete'")$batch_start
  starts <- seq.int(1L, manifest$corpus$rows, by = config$checkpoint_documents)
  pending <- setdiff(starts, done)
  if (!length(pending)) { cat("Export already complete; no documents reprocessed.\n"); return(invisible(NULL)) }
  cat(utc(), "Reading corpus in place...\n")
  d <- readRDS(path)
  stopifnot(nrow(d) == manifest$corpus$rows, ncol(d) == manifest$corpus$columns)
  required <- c("dk_source_id", "SOURCE_TYPE", "DATE", "FROM", "AUTHOR", "TITLE", "FULL_TEXT")
  stopifnot(all(required %in% names(d)))
  for (first in pending) {
    last <- min(first + config$checkpoint_documents - 1L, nrow(d))
    ix <- first:last
    text <- clean_text(d$FULL_TEXT[ix])
    dates <- as.character(as.Date(d$DATE[ix]))
    batch <- data.frame(doc_id = sprintf("DK%07d", ix), corpus_row = ix,
      dk_source_id = as.character(d$dk_source_id[ix]), platform = as.character(d$SOURCE_TYPE[ix]),
      date = dates, source = clean_text(d$FROM[ix]), author = clean_text(d$AUTHOR[ix]),
      title = clean_text(d$TITLE[ix]), text_clean = text, n_chars = stringi::stri_length(text),
      era = ifelse(dates < config$era_split, "pre2024", "post2024"),
      text_sha256 = vapply(text, digest::digest, character(1), algo = "sha256", serialize = FALSE),
      corpus_sha256 = manifest$corpus$sha256, config_hash = config_hash, created_utc = utc())
    DBI::dbWithTransaction(con, {
      if (!DBI::dbExistsTable(con, "docs")) {
        DBI::dbWriteTable(con, "docs", batch[0, ])
        DBI::dbExecute(con, "CREATE UNIQUE INDEX docs_id ON docs(doc_id)")
      }
      DBI::dbAppendTable(con, "docs", batch)
      DBI::dbAppendTable(con, "checkpoints", data.frame(stage = "export_docs", batch_start = first,
        batch_end = last, status = "complete", corpus_sha256 = manifest$corpus$sha256,
        config_hash = config_hash, created_utc = utc()))
    })
    DBI::dbExecute(con, "CHECKPOINT")
    cat(utc(), "Committed", last, "/", nrow(d), "documents\n"); flush.console()
  }
  total <- DBI::dbGetQuery(con, "SELECT count(*) AS n FROM docs")$n
  stopifnot(total == manifest$corpus$rows)
  cat(utc(), "Export verified complete. MinHash and model pilots are next.\n")
}
main()
