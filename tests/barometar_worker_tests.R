# Verify the actual month classifier after Windows-compatible PSOCK transport.
# Tiny invented parquet chunks only; no source database or empirical workdir.
run_barometar_worker_tests <- function() {
  source("studies/demokrscanstvo-barometar/04_classify.R", encoding = "UTF-8")
  root <- tempfile("barometar-invented-workers-"); dir.create(root)
  serial_folder <- file.path(root, "serial"); parallel_folder <- file.path(root, "parallel")
  dir.create(serial_folder); dir.create(parallel_folder)
  definition <- barometar_definition()
  filler <- paste(rep("Ovo je izmišljeni neutralni dodatak za provjeru duljine.", 6L), collapse = " ")
  statements <- c("To nema veze s demokršćanstvom.",
    "U skladu sa socijalnim naukom Crkve, Vlada bi trebala povisiti minimalnu plaću.",
    "Personalizirana ponuda za vašu obitelj.")
  rows <- data.frame(TITLE = "Izmišljeni naslov čćžšđ", FULL_TEXT = paste(statements, filler),
    day = "2024-05-15", outlet_id = "invented", doc_key = paste0("invented-worker-", 1:3),
    article_hash = paste0("invented-article-", 1:3), source_batch = "mediaspace_full",
    development = c(TRUE, FALSE, TRUE), stringsAsFactors = FALSE)
  rows$original_text_sha256 <- vapply(rows$FULL_TEXT, digest::digest, character(1L), algo = "sha256", serialize = FALSE)
  con <- DBI::dbConnect(duckdb::duckdb())
  paths <- file.path(root, c("2024-05.parquet", "2024-06.parquet"))
  for (i in seq_along(paths)) {
    chunk <- rows; chunk$day <- if (i == 1L) "2024-05-15" else "2024-06-15"
    chunk$doc_key <- paste0(chunk$doc_key, "-", i)
    DBI::dbWriteTable(con, "invented", chunk, overwrite = TRUE)
    DBI::dbExecute(con, paste0("COPY invented TO ", DBI::dbQuoteString(con, paths[i]), " (FORMAT PARQUET)"))
  }
  DBI::dbDisconnect(con, shutdown = TRUE)
  boilerplate <- data.frame(outlet_id = character(), month = character(), segment_key = character())
  attr(boilerplate, "boilerplate_version") <- "invented-mask"
  context <- list(definition = definition, boilerplate = boilerplate, development_only = FALSE,
    engine_hash = "invented-engine-hash", folder = serial_folder)
  serial_paths <- vapply(paths, barometar_classify_month, character(1L), context = context)
  context$folder <- parallel_folder
  cluster <- parallel::makePSOCKcluster(2L, outfile = file.path(root, "worker-private.log"), rscript_args = "--vanilla")
  on.exit(parallel::stopCluster(cluster), add = TRUE)
  parallel::clusterCall(cluster, function(root, library, context) {
    setwd(root); .libPaths(library)
    if (.Platform$OS.type == "windows") Sys.setlocale("LC_CTYPE", "English_United States.utf8")
    source("studies/demokrscanstvo-barometar/04_classify.R", encoding = "UTF-8")
    assign("barometar_worker_context", context, envir = .GlobalEnv)
    TRUE
  }, normalizePath(getwd(), winslash = "/"), .libPaths(), context)
  parallel_paths <- unlist(parallel::parLapplyLB(cluster, paths,
    function(path) barometar_classify_month(path, barometar_worker_context)), use.names = FALSE)
  checks <- 0L
  evidence_connection <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(evidence_connection, shutdown = TRUE), add = TRUE)
  evidence_path <- function(input, folder) file.path(folder, paste0(basename(input), "-evidence.parquet"))
  read_evidence <- function(input, folder) DBI::dbGetQuery(evidence_connection,
    paste0("SELECT * FROM read_parquet(", DBI::dbQuoteString(evidence_connection, evidence_path(input, folder)), ")"))
  for (i in seq_along(paths)) {
    serial <- readRDS(serial_paths[i]); concurrent <- readRDS(parallel_paths[i])
    stopifnot(identical(as.data.frame(serial$decisions), as.data.frame(concurrent$decisions)))
    stopifnot(identical(as.data.frame(serial$evidence), as.data.frame(concurrent$evidence)))
    stopifnot(identical(serial[c("definition_version", "engine_hash", "boilerplate_version", "development_only")],
                        concurrent[c("definition_version", "engine_hash", "boilerplate_version", "development_only")]))
    serial_parquet <- read_evidence(paths[i], serial_folder)
    parallel_parquet <- read_evidence(paths[i], parallel_folder)
    stopifnot(identical(serial_parquet, as.data.frame(serial$evidence)),
      identical(parallel_parquet, as.data.frame(concurrent$evidence)),
      identical(serial_parquet, parallel_parquet))
    stopifnot(nrow(serial_parquet) > 0L, all(serial_parquet$doc_key %in% serial$decisions$doc_key),
      all(serial_parquet$definition_version == definition$definition_version),
      !any(c("TITLE", "FULL_TEXT", "URL") %in% names(serial_parquet)))
    checks <- checks + 7L
  }
  context$folder <- file.path(root, "development"); dir.create(context$folder)
  context$development_only <- TRUE
  development <- readRDS(barometar_classify_month(paths[1L], context))
  stopifnot(nrow(development$decisions) == 2L, all(development$decisions$development))
  development_parquet <- read_evidence(paths[1L], context$folder)
  stopifnot(identical(development_parquet, as.data.frame(development$evidence)),
    all(development_parquet$doc_key %in% development$decisions$doc_key))
  checks <- checks + 2L

  # Interrupted finalization: an evidence file exists, but its RDS companion
  # never completed. All touched files are this test's invented temp fixtures.
  resume_folder <- file.path(root, "resume"); dir.create(resume_folder)
  stopifnot(file.copy(evidence_path(paths[1L], serial_folder), evidence_path(paths[1L], resume_folder)))
  context$folder <- resume_folder; context$development_only <- FALSE
  resumed <- readRDS(barometar_classify_month(paths[1L], context))
  stopifnot(identical(as.data.frame(resumed$evidence), read_evidence(paths[1L], resume_folder)))
  checks <- checks + 1L

  # The reverse incomplete pair must be repaired or rejected, never accepted
  # as a finished chunk with silently missing portable evidence.
  missing_folder <- file.path(root, "missing-evidence"); dir.create(missing_folder)
  stopifnot(file.copy(serial_paths[1L], file.path(missing_folder, basename(serial_paths[1L]))))
  context$folder <- missing_folder
  missing_result <- tryCatch(barometar_classify_month(paths[1L], context), error = identity)
  stopifnot(inherits(missing_result, "error") || file.exists(evidence_path(paths[1L], missing_folder)))
  if (!inherits(missing_result, "error"))
    stopifnot(identical(as.data.frame(readRDS(missing_result)$evidence), read_evidence(paths[1L], missing_folder)))
  checks <- checks + 1L

  # Test the actual scheduling wrapper too: its pending list must send an
  # incomplete pair through the repair path. Only metadata/panel resolvers are
  # adapted; the real cache, classifier and Parquet I/O remain under test.
  wrapper <- new.env(parent = globalenv())
  wrapper$barometar_classify_candidates <- barometar_classify_candidates
  environment(wrapper$barometar_classify_candidates) <- wrapper
  population_identity <- list(invented = "population")
  wrapper$barometar_require_panel <- function() data.frame(outlet_id = "invented", panel_hash = "invented-panel")
  wrapper$barometar_population_identity <- function(workdir, readiness) population_identity
  wrapper$barometar_workdir <- function(workdir) workdir
  workdir <- file.path(root, "wrapper-work"); dir.create(workdir)
  saveRDS(list(input_digest = "invented-input"), file.path(workdir, "readiness.rds"))
  saveRDS(list(paths = paths, population_identity = population_identity,
    prefilter_hash = digikat_hash_object(definition$prefilter$sql_condition),
    panel_hash = "invented-panel", input_digest = "invented-input", retrieval_hash = "invented-retrieval"),
    file.path(workdir, "candidate_manifest.rds"))
  attr(boilerplate, "identity") <- list(input_digest = "invented-input", population = population_identity,
    panel_hash = "invented-panel", trigger = definition$prefilter$literal_pattern)
  saveRDS(boilerplate, file.path(workdir, "boilerplate.rds"))
  first <- wrapper$barometar_classify_candidates(workdir, development_only = TRUE, workers = 1L)
  stopifnot(length(first$evidence_paths) == 2L)
  # Preserve the invented evidence as a backup while simulating its absence.
  missing_path <- first$evidence_paths[1L]
  stopifnot(startsWith(normalizePath(missing_path, winslash = "/"), normalizePath(root, winslash = "/")))
  stopifnot(file.rename(missing_path, paste0(missing_path, ".invented-backup")))
  repeated <- wrapper$barometar_classify_candidates(workdir, development_only = TRUE, workers = 1L)
  stopifnot(length(repeated$evidence_paths) == 2L, file.exists(missing_path))
  restored <- DBI::dbGetQuery(evidence_connection,
    paste0("SELECT * FROM read_parquet(", DBI::dbQuoteString(evidence_connection, missing_path), ")"))
  stopifnot(identical(restored, as.data.frame(readRDS(first$paths[1L])$evidence)))
  checks <- checks + 2L
  message("All ", checks, " invented classifier-worker checks passed.")
  invisible(checks)
}

run_barometar_worker_tests()
