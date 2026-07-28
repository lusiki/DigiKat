#!/usr/bin/env Rscript
# Build, adopt, or validate the local Ragnar semantic store.
#
# Read-only validation (default):
#   Rscript R/semantic/11_build.R
#
# Adopt a legacy store after exact prepared-doc-ID validation:
#   Rscript R/semantic/11_build.R --adopt-existing
#
# First build:
#   Rscript R/semantic/11_build.R --build
#
# Rebuild without deleting the usable store:
#   Rscript R/semantic/11_build.R --rebuild
#
# Rebuilds write a separate .building-* database, validate it, and only then
# move the previous store to a timestamped .previous-* path.

source("R/lib/digikat_utils.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat(paste(
    "Usage: Rscript R/semantic/11_build.R [--build | --rebuild | --adopt-existing]",
    "       [--input=PATH] [--store=PATH] [--limit=N]",
    "",
    "No action flag means read-only validation.",
    sep = "\n"
  ))
  quit(save = "no", status = 0L)
}

env_rebuild <- digikat_parse_bool(
  Sys.getenv("DIGIKAT_SEMANTIC_REBUILD", unset = ""),
  "DIGIKAT_SEMANTIC_REBUILD",
  default = FALSE
)
build <- digikat_cli_flag(args, "--build")
rebuild <- digikat_cli_flag(args, "--rebuild") || env_rebuild
adopt_existing <- digikat_cli_flag(args, "--adopt-existing")
if (sum(c(build, rebuild, adopt_existing)) > 1L) {
  stop("Choose only one of --build, --rebuild, or --adopt-existing.", call. = FALSE)
}

input <- digikat_cli_value(args, "--input", "data/semantic/corpus_prepared.rds")
input_manifest <- sub("\\.rds$", "_manifest.json", input)
if (identical(input_manifest, input)) input_manifest <- paste0(input, "_manifest.json")
limit_text <- digikat_cli_value(
  args,
  "--limit",
  Sys.getenv("DIGIKAT_SEMANTIC_LIMIT", unset = "")
)
limit <- suppressWarnings(as.integer(limit_text))
if (!nzchar(limit_text)) limit <- NA_integer_
if (!is.na(limit) && limit <= 0L) stop("--limit must be a positive integer.", call. = FALSE)

default_store <- if (is.na(limit)) {
  "data/semantic/digikat.ragnar.duckdb"
} else {
  sprintf("data/semantic/digikat_test%d.ragnar.duckdb", limit)
}
store_path <- digikat_cli_value(args, "--store", default_store)
manifest_path <- sub("\\.duckdb$", ".manifest.json", store_path)
if (identical(manifest_path, store_path)) manifest_path <- paste0(store_path, ".manifest.json")
model_name <- Sys.getenv("DIGIKAT_EMBED_MODEL", unset = "bge-m3")
insert_batch <- suppressWarnings(as.integer(Sys.getenv("DIGIKAT_SEMANTIC_BATCH", unset = "1000")))
if (is.na(insert_batch) || insert_batch < 1L) stop("DIGIKAT_SEMANTIC_BATCH must be positive.", call. = FALSE)

validate_store <- function(path, expected_rows = NULL, expected_doc_ids = NULL,
                           expected_row_signature = NULL) {
  if (!file.exists(path)) stop("Semantic store not found: ", path, call. = FALSE)
  if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
    stop("Packages 'DBI' and 'duckdb' are required to validate the store.", call. = FALSE)
  }
  connection <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = TRUE)
  on.exit(DBI::dbDisconnect(connection, shutdown = TRUE), add = TRUE)
  tables <- DBI::dbListTables(connection)
  required_tables <- c("chunks", "docs", "terms")
  missing_tables <- setdiff(required_tables, tables)
  if (length(missing_tables)) {
    stop("Semantic store is missing table(s): ", paste(missing_tables, collapse = ", "), call. = FALSE)
  }

  schema <- DBI::dbGetQuery(connection, "PRAGMA table_info(chunks)")
  required_columns <- c("chunk_id", "doc_id", "platform", "date", "text", "embedding")
  missing_columns <- setdiff(required_columns, schema$name)
  if (length(missing_columns)) {
    stop("Semantic chunks table is missing column(s): ", paste(missing_columns, collapse = ", "), call. = FALSE)
  }

  counts <- DBI::dbGetQuery(
    connection,
    paste(
      "SELECT COUNT(*) AS rows,",
      "SUM(CASE WHEN doc_id IS NULL OR doc_id = '' THEN 1 ELSE 0 END) AS missing_doc_id,",
      "SUM(CASE WHEN text IS NULL OR text = '' THEN 1 ELSE 0 END) AS missing_text,",
      "SUM(CASE WHEN embedding IS NULL THEN 1 ELSE 0 END) AS missing_embedding",
      "FROM chunks"
    )
  )
  rows <- as.numeric(counts$rows[[1L]])
  if (!is.null(expected_rows) && rows != expected_rows) {
    stop("Semantic store has ", rows, " rows; expected ", expected_rows, ".", call. = FALSE)
  }
  if (any(as.numeric(counts[1L, c("missing_doc_id", "missing_text", "missing_embedding")]) != 0)) {
    stop("Semantic store contains missing document IDs, text, or embeddings.", call. = FALSE)
  }

  count_index_rows <- function(table) {
    main_query <- paste0("SELECT COUNT(*) AS n FROM ", table)
    result <- tryCatch(
      DBI::dbGetQuery(connection, main_query),
      error = function(error) {
        DBI::dbGetQuery(
          connection,
          paste0("SELECT COUNT(*) AS n FROM fts_main_chunks.", table)
        )
      }
    )
    as.numeric(result$n[[1L]])
  }
  index_counts <- list(
    docs = count_index_rows("docs"),
    terms = count_index_rows("terms")
  )
  if (index_counts$docs == 0 || index_counts$terms == 0) {
    stop("Semantic store search indexes are empty.", call. = FALSE)
  }

  stored_doc_ids <- NULL
  if (!is.null(expected_doc_ids)) {
    stored_rows <- DBI::dbGetQuery(
      connection,
      paste(
        "SELECT doc_id, platform, CAST(date AS VARCHAR) AS date,",
        "length(text) AS text_characters",
        "FROM chunks ORDER BY chunk_id"
      )
    )
    stored_doc_ids <- stored_rows$doc_id
    if (!identical(as.character(stored_doc_ids), as.character(expected_doc_ids))) {
      stop("Semantic store document IDs do not exactly match the prepared corpus.", call. = FALSE)
    }
    if (!is.null(expected_row_signature)) {
      stored_signature <- stored_rows[, c("platform", "date", "text_characters"), drop = FALSE]
      stored_signature$date <- as.character(stored_signature$date)
      if (!identical(stored_signature, expected_row_signature)) {
        stop(
          "Semantic store platform/date/text-length sequence does not match the prepared corpus.",
          call. = FALSE
        )
      }
    }
  }

  embedding_type <- schema$type[schema$name == "embedding"][[1L]]
  list(
    rows = rows,
    missing_doc_id = 0L,
    missing_text = 0L,
    missing_embedding = 0L,
    embedding_type = embedding_type,
    index_documents = index_counts$docs,
    index_terms = index_counts$terms,
    doc_id_fingerprint = if (!is.null(stored_doc_ids)) digikat_hash_object(stored_doc_ids) else NULL
  )
}

validate_recorded_generation <- function() {
  if (!file.exists(manifest_path)) {
    stop(
      "Semantic store has no manifest. Run --adopt-existing after review, or rebuild it.",
      call. = FALSE
    )
  }
  manifest <- jsonlite::read_json(manifest_path, simplifyVector = FALSE)
  if (!file.exists(input)) stop("Prepared corpus missing: ", input, call. = FALSE)
  current_input_hash <- digikat_hash_file(input)
  if (!identical(manifest$input$sha256, current_input_hash)) {
    stop("Semantic store manifest is stale: prepared-corpus fingerprint changed.", call. = FALSE)
  }
  result <- validate_store(store_path, expected_rows = as.numeric(manifest$store$rows))
  current_info <- file.info(store_path)
  if (as.numeric(current_info$size) != as.numeric(manifest$store$bytes)) {
    stop("Semantic store file size differs from the manifest.", call. = FALSE)
  }
  cat(
    "Semantic store validation passed:", result$rows, "rows |",
    result$embedding_type, "|", result$index_terms, "index terms.\n"
  )
  invisible(result)
}

if (!build && !rebuild && !adopt_existing) {
  validate_recorded_generation()
  quit(save = "no", status = 0L)
}

if (!file.exists(input)) stop("Prepared corpus missing: ", input, call. = FALSE)
prepared <- readRDS(input)
digikat_require_columns(
  prepared,
  c("doc_id", "platform", "date", "data_source", "actor", "url", "text"),
  "prepared semantic corpus"
)
if (anyDuplicated(prepared$doc_id)) stop("Prepared corpus has duplicate doc_id values.", call. = FALSE)
if (!is.na(limit)) prepared <- utils::head(prepared, limit)
expected_rows <- nrow(prepared)

if (adopt_existing) {
  expected_row_signature <- data.frame(
    platform = as.character(prepared$platform),
    date = as.character(prepared$date),
    text_characters = as.numeric(nchar(prepared$text, type = "chars")),
    stringsAsFactors = FALSE
  )
  result <- validate_store(
    store_path,
    expected_rows = expected_rows,
    expected_doc_ids = prepared$doc_id,
    expected_row_signature = expected_row_signature
  )
  store_info <- file.info(store_path)
  manifest <- list(
    schema_version = 1L,
    generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    generator = "R/semantic/11_build.R",
    provenance = "adopted_existing_after_exact_doc_id_row_signature_and_index_validation",
    input = c(
      digikat_file_metadata(input, include_hash = TRUE),
      list(manifest = if (file.exists(input_manifest)) gsub("\\\\", "/", input_manifest) else NULL)
    ),
    model = list(name = model_name, provider = "Ollama localhost"),
    store = c(
      list(
        path = gsub("\\\\", "/", store_path),
        bytes = unname(store_info$size),
        modified_utc = format(store_info$mtime, tz = "UTC", usetz = TRUE)
      ),
      result
    )
  )
  digikat_write_json_atomic(manifest, manifest_path)
  cat("Adopted and fingerprinted semantic store:", manifest_path, "\n")
  quit(save = "no", status = 0L)
}

if (!file.exists(input_manifest)) {
  stop(
    "Prepared corpus has no manifest: ", input_manifest,
    "\nRegenerate it with R/semantic/10_prep.R before building a store.",
    call. = FALSE
  )
}
if (!requireNamespace("ragnar", quietly = TRUE)) {
  stop("Package 'ragnar' is required to build the semantic store.", call. = FALSE)
}
if (build && file.exists(store_path)) {
  stop("Store already exists. Use --rebuild to build a validated replacement.", call. = FALSE)
}

stamp <- format(Sys.time(), "%Y%m%d_%H%M%S", tz = "UTC")
staging_path <- paste0(store_path, ".building-", stamp)
progress_path <- paste0(staging_path, ".progress.json")
if (file.exists(staging_path)) stop("Staging store already exists: ", staging_path, call. = FALSE)

embed_local <- function(x) {
  ragnar::embed_ollama(substr(x, 1L, 4000L), model = "bge-m3", batch_size = 64L)
}

cat("Preflight: contacting local Ollama model", model_name, "...\n")
probe <- tryCatch(embed_local("DigiKat semantic preflight"), error = function(error) error)
if (inherits(probe, "error")) {
  stop(
    "Ollama preflight failed. Confirm the service is running and execute `ollama pull ",
    model_name, "`. Underlying error: ", conditionMessage(probe),
    call. = FALSE
  )
}
embedding_dimensions <- ncol(probe)

extra_columns <- data.frame(
  doc_id = character(),
  platform = character(),
  date = as.Date(character()),
  data_source = character(),
  actor = character(),
  url = character()
)
store <- ragnar::ragnar_store_create(
  location = staging_path,
  embed = embed_local,
  extra_cols = extra_columns,
  name = "digikat",
  title = "DigiKat corpus (bge-m3)",
  version = 1,
  overwrite = FALSE
)

starts <- seq.int(1L, expected_rows, by = insert_batch)
started <- Sys.time()
for (batch_number in seq_along(starts)) {
  first <- starts[[batch_number]]
  last <- min(first + insert_batch - 1L, expected_rows)
  chunk <- data.frame(
    text = prepared$text[first:last],
    doc_id = prepared$doc_id[first:last],
    platform = prepared$platform[first:last],
    date = prepared$date[first:last],
    data_source = prepared$data_source[first:last],
    actor = prepared$actor[first:last],
    url = prepared$url[first:last],
    stringsAsFactors = FALSE
  )
  ragnar::ragnar_store_insert(store, chunk)

  progress <- list(
    schema_version = 1L,
    staging_store = gsub("\\\\", "/", staging_path),
    started_utc = format(started, tz = "UTC", usetz = TRUE),
    updated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    inserted_rows = last,
    expected_rows = expected_rows,
    completed_batches = batch_number,
    total_batches = length(starts)
  )
  digikat_write_json_atomic(progress, progress_path)
  if (batch_number %% 10L == 0L || last == expected_rows) {
    elapsed <- as.numeric(difftime(Sys.time(), started, units = "secs"))
    rate <- last / max(elapsed, 1)
    eta_minutes <- (expected_rows - last) / max(rate, 1e-9) / 60
    cat(sprintf(
      "  inserted %d/%d (%.0f%%) | %.0f rows/s | ETA %.0f min\n",
      last,
      expected_rows,
      100 * last / expected_rows,
      rate,
      eta_minutes
    ))
    flush.console()
  }
}

cat("Building vector and full-text indexes...\n")
ragnar::ragnar_store_build_index(store)
validation <- validate_store(staging_path, expected_rows = expected_rows)

if (file.exists(store_path)) {
  previous_path <- paste0(store_path, ".previous-", stamp)
  if (!file.rename(store_path, previous_path)) {
    stop(
      "Validated staging store is retained at ", staging_path,
      " but the current store could not be moved aside.",
      call. = FALSE
    )
  }
}
if (!file.rename(staging_path, store_path)) {
  if (exists("previous_path") && file.exists(previous_path)) file.rename(previous_path, store_path)
  stop("Could not install validated semantic store; previous store restored.", call. = FALSE)
}
if (file.exists(progress_path)) unlink(progress_path)

store_info <- file.info(store_path)
manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "R/semantic/11_build.R",
  provenance = "generated_and_validated",
  input = c(
    digikat_file_metadata(input, include_hash = TRUE),
    list(manifest = gsub("\\\\", "/", input_manifest))
  ),
  model = list(
    name = model_name,
    provider = "Ollama localhost",
    embedding_dimensions = embedding_dimensions,
    embed_input_max_characters = 4000L,
    embed_batch_size = 64L,
    insert_batch_size = insert_batch
  ),
  store = c(
    list(
      path = gsub("\\\\", "/", store_path),
      bytes = unname(store_info$size),
      modified_utc = format(store_info$mtime, tz = "UTC", usetz = TRUE)
    ),
    validation
  ),
  previous_store = if (exists("previous_path")) gsub("\\\\", "/", previous_path) else NULL
)
digikat_write_json_atomic(manifest, manifest_path)

cat("Semantic store installed and validated:", store_path, "\n")
if (exists("previous_path")) {
  cat("Previous store retained:", previous_path, "\n")
}
