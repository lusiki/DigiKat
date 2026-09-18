source("studies/demokrscanstvo-barometar/02_panel.R", encoding = "UTF-8")
source("R/lib/barometar_engine.R", encoding = "UTF-8")

barometar_definition <- function() barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")

barometar_population_identity <- function(workdir,readiness) {
  metadata <- readRDS(file.path(workdir,"eligible_metadata_manifest.rds"))
  proposal <- readRDS(file.path(workdir,"panel_proposal.rds"))
  if(!identical(metadata$signature,barometar_cache_signature(readiness,metadata$from_values)) ||
     !identical(proposal$metadata_signature,metadata$signature) ||
     !identical(proposal$registry_hash,digikat_hash_file("studies/demokrscanstvo-barometar/config/outlet_registry.csv")) ||
     !identical(proposal$url_policy_hash,digikat_hash_file("R/lib/barometar_outlet_urls.R")))stop("Population cache is stale; rebuild the panel proposal before retrieval.")
  list(input_digest=readiness$input_digest,
    source_snapshot=readiness$snapshot[c("file_bytes","file_mtime","logs_digest")],
    denominator_signature=metadata$signature,
    registry_hash=digikat_hash_file("studies/demokrscanstvo-barometar/config/outlet_registry.csv"),
    population_code=vapply(c("studies/demokrscanstvo-barometar/02_panel.R","R/lib/barometar_outlet_urls.R"),
      digikat_hash_file,character(1L)))
}

barometar_require_panel <- function() {
  gates <- jsonlite::fromJSON("studies/demokrscanstvo-barometar/config/gates.json", simplifyVector = FALSE)
  if (!identical(gates$G1_panel$status, "approved")) stop("G1 panel review is incomplete; no real candidate retrieval.", call. = FALSE)
  panel <- utils::read.csv("studies/demokrscanstvo-barometar/config/panel_v1.csv", fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
  if (!nrow(panel) || anyNA(panel$outlet_id) || anyDuplicated(panel$outlet_id) ||
      !all(panel$panel_hash == gates$G1_panel$panel_hash)) stop("Frozen panel hash mismatch.")
  panel
}

barometar_doc_key_sql <- function(prefix = "") {
  column <- function(x) paste0(prefix, x)
  paste0("md5(concat_ws('|', ", column("SOURCE_BATCH"), ", ", column("SOURCE_TYPE"),
    ", coalesce(CAST(", column("ITEM_ID"), " AS VARCHAR), ''), coalesce(", column("URL"),
    ", ''), strftime(", column("DATETIME"), ", '%Y-%m-%dT%H:%M:%S'), md5(coalesce(", column("FULL_TEXT"), ", ''))))")
}

barometar_candidates <- function(workdir = NULL, definition = barometar_definition()) {
  panel <- barometar_require_panel()
  workdir <- barometar_workdir(workdir)
  readiness <- readRDS(file.path(workdir, "readiness.rds"))
  proposal <- readRDS(file.path(workdir, "panel_proposal.rds"))
  con <- barometar_connect_readonly()
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  barometar_assert_snapshot(readiness$snapshot, con)
  DBI::dbExecute(con, paste0("ATTACH ", DBI::dbQuoteString(con, proposal$private_db), " AS denominator (READ_ONLY)"))
  ids <- paste(DBI::dbQuoteString(con, panel$outlet_id), collapse = ",")
  prefilter_hash <- digikat_hash_object(definition$prefilter$sql_condition)
  population_identity <- barometar_population_identity(workdir,readiness)
  retrieval_hash <- digikat_hash_object(list(population=population_identity,
    panel_hash=panel$panel_hash[1L],prefilter_hash=prefilter_hash,contract="representative_NUL_transport_v1"))
  folder <- file.path(workdir, "candidates", substr(retrieval_hash,1L,32L))
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  table <- barometar_table_sql(con)
  months <- unique(substr(readiness$days$day, 1L, 7L))
  paths <- character()
  counts <- list()
  for (month in months) {
    target <- file.path(folder, paste0(month, ".parquet"))
    count_file <- file.path(folder, paste0(month, "-count.rds"))
    if (file.exists(target) && file.exists(count_file)) {
      paths <- c(paths, target)
      counts[[month]] <- readRDS(count_file)
      next
    }
    # Representative keys ensure title/body eligibility and dedup are identical
    # for N and D. DISTINCT collapses duplicated source identities only.
    query <- paste0("WITH raw_candidates AS (SELECT ", barometar_doc_key_sql(),
      " AS doc_key, replace(TITLE, chr(0), '�') AS TITLE, replace(FULL_TEXT, chr(0), '�') AS FULL_TEXT, ",
      'sha256(FULL_TEXT) AS original_text_sha256, "DATE" AS day, SOURCE_BATCH AS source_batch FROM ', table,
      " WHERE SOURCE_TYPE='web' AND substr(\"DATE\",1,7)=", DBI::dbQuoteString(con, month),
      " AND ", definition$prefilter$sql_condition, ") SELECT DISTINCT c.doc_key, c.TITLE, c.FULL_TEXT, c.original_text_sha256, ",
      "c.day, c.source_batch, r.outlet_id, md5(r.outlet_id || '|' || r.canonical_url) AS article_hash, ",
      "(CAST(('0x' || substr(md5(r.outlet_id || '|' || r.canonical_url),1,7)) AS BIGINT) % 10 < 3) AS development ",
      "FROM raw_candidates c JOIN denominator.main.representatives r USING(doc_key) WHERE r.outlet_id IN (", ids, ")")
    pending <- paste0(target, ".partial")
    DBI::dbExecute(con, paste0("COPY (", query, ") TO ", DBI::dbQuoteString(con, pending), " (FORMAT PARQUET, COMPRESSION ZSTD)"))
    stats <- DBI::dbGetQuery(con, paste0("SELECT COUNT(*) AS n, COUNT(DISTINCT doc_key) AS unique_keys FROM read_parquet(", DBI::dbQuoteString(con, pending), ")"))
    stopifnot(stats$n == stats$unique_keys)
    if (!file.rename(pending, target)) stop("Could not finalize candidate chunk.")
    saveRDS(list(n = as.numeric(stats$n)), count_file)
    counts[[month]] <- list(n = as.numeric(stats$n))
    paths <- c(paths, target)
    # No topic counts by month are printed during development.
    message("Candidate chunk prepared: ", length(paths), "/", length(months), ".")
    barometar_assert_snapshot(readiness$snapshot, con)
  }
  result <- list(paths = paths, definition_hash = definition$definition_hash,
    definition_version = definition$definition_version, panel_hash = panel$panel_hash[1L],
    input_digest = readiness$input_digest, prefilter_hash=prefilter_hash,
    retrieval_hash=retrieval_hash,population_identity=population_identity, folder = folder)
  saveRDS(result, file.path(workdir, "candidate_manifest.rds"))
  message("Candidate materialization complete; no period series computed.")
  invisible(result)
}

# All-panel boilerplate is based on distinct representative documents, never
# the topic-selected subset. Only trigger-containing segments become mask keys.
barometar_boilerplate <- function(workdir = NULL, definition = barometar_definition()) {
  panel <- barometar_require_panel()
  workdir <- barometar_workdir(workdir)
  readiness <- readRDS(file.path(workdir, "readiness.rds"))
  proposal <- readRDS(file.path(workdir, "panel_proposal.rds"))
  con <- barometar_connect_readonly()
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  barometar_assert_snapshot(readiness$snapshot, con)
  DBI::dbExecute(con, paste0("ATTACH ", DBI::dbQuoteString(con, proposal$private_db), " AS denominator (READ_ONLY)"))
  ids <- paste(DBI::dbQuoteString(con, panel$outlet_id), collapse = ",")
  identity <- list(input_digest=readiness$input_digest,population=barometar_population_identity(workdir,readiness),panel_hash=panel$panel_hash[1L],
    trigger=definition$prefilter$literal_pattern,splitter=BAROMETAR_BOILERPLATE_SPLIT_PATTERN,
    key_contract="transport_then_title_stripped_i_dot_sigma_digit_space_v3")
  folder <- file.path(workdir, "boilerplate", substr(digikat_hash_object(identity),1L,32L))
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  splitter <- as.character(DBI::dbQuoteString(con, BAROMETAR_BOILERPLATE_SPLIT_PATTERN))
  whitespace <- "[\\x{0009}-\\x{000D}\\x{0020}\\x{0085}\\x{00A0}\\x{1680}\\x{2000}-\\x{200B}\\x{2028}\\x{2029}\\x{202F}\\x{205F}\\x{3000}]+"
  title_prefix <- "^[\\p{Z}\\p{P}\\x{0009}-\\x{000D}\\x{0085}]+"
  transported_title <- "replace(TITLE,chr(0),'�')";transported_body <- "replace(FULL_TEXT,chr(0),'�')"
  body_sql <- paste0("CASE WHEN TITLE IS NOT NULL AND length(TITLE)>0 AND starts_with(",transported_body,",",transported_title,") ",
    "THEN regexp_replace(substr(",transported_body,",length(TITLE)+1),",DBI::dbQuoteString(con,title_prefix),",'') ELSE ",transported_body," END")
  trigger <- DBI::dbQuoteString(con, definition$prefilter$literal_pattern)
  results <- list()
  for (month in unique(substr(readiness$days$day, 1L, 7L))) {
    path <- file.path(folder, paste0(month, ".rds"))
    if (file.exists(path)) { results[[month]] <- readRDS(path); next }
    query <- paste0("WITH raw AS (SELECT ", barometar_doc_key_sql(),
      ' AS doc_key, ',body_sql,' AS FULL_TEXT, "DATE" AS day FROM ', barometar_table_sql(con),
      " WHERE SOURCE_TYPE='web' AND substr(\"DATE\",1,7)=", DBI::dbQuoteString(con, month),
      "), segments AS (SELECT r.outlet_id, raw.doc_key, raw.day, unnest(regexp_split_to_array(raw.FULL_TEXT, ",
      splitter, ")) AS segment FROM raw JOIN denominator.main.representatives r USING(doc_key) ",
      "WHERE r.outlet_id IN (", ids, ")), keyed AS (SELECT outlet_id, doc_key, day, ",
      "md5(trim(regexp_replace(regexp_replace(replace(lower(replace(segment, 'İ', 'i̇')),'ς','σ'), '[0-9]', '#', 'g'), ",
      DBI::dbQuoteString(con, whitespace), ", ' ', 'g'))) AS segment_key FROM segments ",
      "WHERE length(segment)>=40 AND regexp_matches(segment, ", trigger, ")) ",
      "SELECT outlet_id, segment_key, COUNT(DISTINCT doc_key) AS documents, COUNT(DISTINCT day) AS days ",
      "FROM keyed GROUP BY 1,2 HAVING COUNT(DISTINCT doc_key)>=5 AND COUNT(DISTINCT day)>=3 ORDER BY 1,2")
    result <- DBI::dbGetQuery(con, query)
    result$month <- rep(month, nrow(result))
    saveRDS(result, path)
    results[[month]] <- result
    message("Boilerplate chunk prepared: ", length(results), ".")
  }
  all <- data.table::rbindlist(results)
  attr(all, "boilerplate_version") <- paste0("boilerplate_v1+", substr(digikat_hash_object(all), 1L, 12L))
  attr(all,"identity") <- identity
  saveRDS(all, file.path(workdir, "boilerplate.rds"))
  barometar_assert_snapshot(readiness$snapshot, con)
  invisible(all)
}
