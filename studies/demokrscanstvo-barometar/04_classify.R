source("studies/demokrscanstvo-barometar/03_candidates.R", encoding = "UTF-8")

barometar_classify_month <- function(path,context) {
  definition <- context$definition;boilerplate <- context$boilerplate
  development_only <- context$development_only;engine_hash <- context$engine_hash
  target <- file.path(context$folder,paste0(basename(path),".rds"))
  parquet <- file.path(context$folder,paste0(basename(path),"-evidence.parquet"))
  if(file.exists(target)) {
    cached <- readRDS(target)
    if(!nrow(cached$evidence) || file.exists(parquet))return(target)
    # Repair an interrupted/missing portable export from the complete private RDS.
    local <- DBI::dbConnect(duckdb::duckdb());on.exit(DBI::dbDisconnect(local,shutdown=TRUE),add=TRUE)
    DBI::dbWriteTable(local,"evidence_export",as.data.frame(cached$evidence))
    if(file.exists(paste0(parquet,".partial")))unlink(paste0(parquet,".partial"))
    DBI::dbExecute(local,paste0("COPY evidence_export TO ",DBI::dbQuoteString(local,paste0(parquet,".partial"))," (FORMAT PARQUET, COMPRESSION ZSTD)"))
    digikat_atomic_replace_file(paste0(parquet,".partial"),parquet)
    return(target)
  }
  local <- DBI::dbConnect(duckdb::duckdb());on.exit(DBI::dbDisconnect(local,shutdown=TRUE),add=TRUE)
  DBI::dbExecute(local,"SET threads=1")
  query <- paste0("SELECT * FROM read_parquet(", DBI::dbQuoteString(local, path), ")",
    if (development_only) " WHERE development" else "", " ORDER BY doc_key")
  cursor <- DBI::dbSendQuery(local, query)
  decisions <- list()
  evidence <- list()
  started <- proc.time()[[3L]]
  repeat {
    rows <- DBI::dbFetch(cursor, n = 500L)
    if (!nrow(rows)) break
    classifications <- barometar_classify_batch(rows,definition,boilerplate)
    for (i in seq_len(nrow(rows))) {
      classified <- classifications[[i]]
      hits <- classified$evidence
      if (nrow(hits)) {
        hits$doc_key <- rows$doc_key[i]
        hits$normalizer_version <- BAROMETAR_NORMALIZER_VERSION
        hits$segmenter_version <- "segmenter_v1"
        hits$boilerplate_version <- attr(boilerplate,"boilerplate_version")
        hits$definition_version <- definition$definition_version
        hits$text_sha256 <- rows$original_text_sha256[i]
        hits$masked <- FALSE;hits$cap_applied <- classified$cap_applied
        hits$route_flags <- paste(classified$routes,collapse=";")
        hits$window_id <- vapply(seq_len(nrow(hits)),function(j)paste(which(vapply(classified$windows,function(w)
          w$field==hits$field[j] && hits$start[j]>=w$start && hits$end[j]<=w$end,logical(1L))),collapse=";"),character(1L))
        evidence[[length(evidence)+1L]] <- hits
      }
      qualifying <- classified$windows[vapply(classified$windows, function(w) w$route %in% c("A1","B","C"), logical(1L))]
      window <- if (length(qualifying)) qualifying[[1L]] else if (length(classified$windows)) classified$windows[[1L]] else NULL
      decisions[[length(decisions)+1L]] <- data.frame(doc_key = rows$doc_key[i], article_hash = rows$article_hash[i],
        outlet_id = rows$outlet_id[i], day = rows$day[i], source_batch = rows$source_batch[i], development = rows$development[i],
        route_set = paste(classified$routes, collapse = ";"), themes = paste(classified$themes, collapse = ";"),
        near_miss=classified$near_miss,near_miss_conditions=paste(classified$near_miss_conditions,collapse=";"),recall_probe=classified$recall_probe,
        principles = paste(classified$principles, collapse = ";"), register = classified$register,
        reference_geography = classified$reference_geography, speaker_type = classified$speaker_type,
        hdz_only=classified$hdz_only,facet_data=as.character(jsonlite::toJSON(classified$facets,dataframe="rows",auto_unbox=TRUE)),
        masked_chars = classified$masked_chars, cap_applied = classified$cap_applied,
        text_sha256 = classified$text_sha256, original_text_sha256=rows$original_text_sha256[i],
        field = if (is.null(window)) NA_character_ else window$field,
        evidence_start = if (is.null(window)) NA_integer_ else window$start,
        evidence_end = if (is.null(window)) NA_integer_ else window$end, stringsAsFactors = FALSE)
    }
  }
  DBI::dbClearResult(cursor)
  result <- list(decisions = data.table::rbindlist(decisions, fill = TRUE), evidence = data.table::rbindlist(evidence, fill = TRUE),
    definition_version = definition$definition_version, engine_hash = engine_hash,
    boilerplate_version = attr(boilerplate,"boilerplate_version"), development_only = development_only)
  # Portable private evidence store. RDS retains per-month decisions and audit
  # metadata; an empty candidate chunk explicitly has no evidence Parquet.
  if(nrow(result$evidence)) {
    if(file.exists(paste0(parquet,".partial")))unlink(paste0(parquet,".partial"))
    DBI::dbWriteTable(local,"evidence_export",as.data.frame(result$evidence),overwrite=TRUE)
    DBI::dbExecute(local,paste0("COPY evidence_export TO ",DBI::dbQuoteString(local,paste0(parquet,".partial"))," (FORMAT PARQUET, COMPRESSION ZSTD)"))
    digikat_atomic_replace_file(paste0(parquet,".partial"),parquet)
  }
  pending <- paste0(target,".partial");saveRDS(result,pending)
  if(!file.rename(pending,target))stop("Could not finalize classification chunk.")
  message("Private classification chunk completed: ",basename(path),"; ",round(proc.time()[[3L]]-started,1L)," s.")
  target
}


barometar_classify_candidates <- function(workdir = NULL, development_only = TRUE, workers = 1L) {
  panel <- barometar_require_panel()
  workdir <- barometar_workdir(workdir)
  definition <- barometar_definition()
  manifest <- readRDS(file.path(workdir, "candidate_manifest.rds"))
  readiness <- readRDS(file.path(workdir,"readiness.rds"))
  if(!identical(manifest$population_identity,barometar_population_identity(workdir,readiness)))stop("Candidate population dependencies changed; rebuild retrieval and boilerplate.")
  if (!identical(manifest$prefilter_hash, digikat_hash_object(definition$prefilter$sql_condition)) ||
      !identical(manifest$panel_hash, panel$panel_hash[1L])) stop("Candidate cache belongs to different rules/panel.")
  gates <- jsonlite::fromJSON("studies/demokrscanstvo-barometar/config/gates.json", simplifyVector = FALSE)
  if (!development_only && (!identical(gates$G2_definition$status, "approved") ||
      !identical(gates$G2_definition$definition_version, definition$definition_version))) stop("Full classification requires the tested G2 freeze.")
  boilerplate_path <- file.path(workdir, "boilerplate.rds")
  if (!file.exists(boilerplate_path)) stop("All-panel boilerplate has not been prepared.")
  boilerplate <- readRDS(boilerplate_path)
  bp_identity <- attr(boilerplate,"identity")
  if(!identical(bp_identity$input_digest,manifest$input_digest) ||
     !identical(bp_identity$population,manifest$population_identity) ||
     !identical(bp_identity$panel_hash,manifest$panel_hash) ||
     !identical(bp_identity$trigger,definition$prefilter$literal_pattern))stop("Stale boilerplate identity.")
  engine_hash <- digikat_hash_object(lapply(c("R/lib/barometar_engine.R", "R/lib/barometar_text.R", "R/lib/barometar_rules.R"), digikat_hash_file))
  classification_hash <- digikat_hash_object(list(definition_hash=definition$definition_hash,
    engine_hash=engine_hash,panel_hash=manifest$panel_hash,input_digest=manifest$input_digest,
    boilerplate_version=attr(boilerplate,"boilerplate_version"),development_only=development_only,
    retrieval_hash=manifest$retrieval_hash,output_contract="decisions_evidence_route_scoped_facets_v3",
    extraction_hash=digikat_hash_file("studies/demokrscanstvo-barometar/04_classify.R")))
  folder <- file.path(workdir, "classifications", substr(classification_hash,1L,32L))
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  context <- list(definition=definition,boilerplate=boilerplate,development_only=development_only,
    engine_hash=engine_hash,folder=folder)
  pending <- manifest$paths[!file.exists(file.path(folder,paste0(basename(manifest$paths),".rds"))) |
    !file.exists(file.path(folder,paste0(basename(manifest$paths),"-evidence.parquet")))]
  workers <- as.integer(workers)
  if(length(workers)!=1L || is.na(workers) || workers<1L || workers>12L)stop("Use one to twelve classification workers.")
  if(length(pending) && workers>1L) {
    cluster <- parallel::makePSOCKcluster(min(workers,length(pending)),outfile=file.path(folder,"worker-log-private.txt"),rscript_args="--vanilla")
    on.exit(parallel::stopCluster(cluster),add=TRUE)
    parallel::clusterCall(cluster,function(root,library,context) {
      setwd(root);.libPaths(library)
      if(.Platform$OS.type=="windows")Sys.setlocale("LC_CTYPE","English_United States.utf8")
      source("studies/demokrscanstvo-barometar/04_classify.R",encoding="UTF-8")
      assign("barometar_worker_context",context,envir=.GlobalEnv)
      TRUE
    },normalizePath(getwd(),winslash="/"),.libPaths(),context)
    message("Classifying ",length(pending)," cached candidate chunks with ",min(workers,length(pending))," workers.")
    invisible(parallel::parLapplyLB(cluster,pending,function(path)barometar_classify_month(path,barometar_worker_context)))
  } else if(length(pending))for(path in pending)barometar_classify_month(path,context)
  result_paths <- file.path(folder,paste0(basename(manifest$paths),".rds"))
  if(!all(file.exists(result_paths)))stop("Classification did not finish every candidate chunk.")
  output <- list(paths=result_paths, definition_version=definition$definition_version, engine_hash=engine_hash,
    classification_hash=classification_hash,input_digest=manifest$input_digest,
    panel_hash=panel$panel_hash[1L], development_only=development_only,
    retrieval_hash=manifest$retrieval_hash,boilerplate_version=attr(boilerplate,"boilerplate_version"))
  evidence_paths <- file.path(folder,paste0(basename(manifest$paths),"-evidence.parquet"))
  output$evidence_paths <- evidence_paths[file.exists(evidence_paths)]
  saveRDS(output,file.path(workdir,if(development_only) "development_manifest.rds" else "classification_manifest.rds"))
  invisible(output)
}
