#!/usr/bin/env Rscript
# R/semantic/12_query.R  —  Level 3 (Meaning search), step 3 of 3
# Small helpers to USE the store built by 11_build.R. SOURCE this file, don't run it:
#   source("R/semantic/12_query.R")
#   dk_retrieve("hodočašće u Mariju Bistricu")            # meaning-search the corpus
#   m <- dk_umap(); plot(m$x, m$y)                        # 2D meaning-map (sampled)
#
# Retrieval hits Ollama (bge-m3) to embed the QUERY only; the corpus vectors are already stored.
# dk_umap() reads stored vectors straight from DuckDB — no Ollama needed for the map.
suppressPackageStartupMessages({ library(here); library(ragnar) })

DK_STORE_PATH <- here::here("data/semantic/digikat.ragnar.duckdb")

# --- connect (read-only) ----------------------------------------------------------------------
dk_store <- function(path = DK_STORE_PATH) {
  if (!file.exists(path)) stop("No store at ", path, " — run R/semantic/11_build.R first.")
  ragnar_store_connect(path, read_only = TRUE)
}

# --- meaning search: returns a tidy tibble of the closest posts --------------------------------
# query    : natural-language question, in Croatian or English
# top_k    : how many posts to return
# full_text: FALSE -> a short snippet column; TRUE -> the whole post text
# NOTE (corpus caveat, MEMORY.md): the ~2024 collection-method change confounds cross-year volume.
#   For any trend claim, group/colour the results by data_source + platform before reading it.
dk_retrieve <- function(query, top_k = 10L, store = dk_store(), full_text = FALSE, snippet_chars = 240L) {
  res <- ragnar_retrieve(store, query, top_k = top_k)
  res <- as.data.frame(res, stringsAsFactors = FALSE)
  keep <- intersect(c("doc_id", "platform", "date", "data_source", "actor",
                      "url", "cosine_distance", "text"), names(res))
  res <- res[, keep, drop = FALSE]
  if ("cosine_distance" %in% names(res))                       # smaller distance = closer; report similarity
    res$similarity <- round(1 - res$cosine_distance, 3)
  if (!full_text && "text" %in% names(res)) {
    res$snippet <- ifelse(nchar(res$text) > snippet_chars,
                          paste0(substr(res$text, 1, snippet_chars), "…"), res$text)
    res$text <- NULL
  }
  res
}

# --- 2D meaning-map: project stored embeddings with UMAP (uwot) --------------------------------
# Reads vectors DIRECTLY from the DuckDB `chunks` table (no re-embedding, no Ollama).
# UMAP on the full ~710k is heavy, so it SAMPLES by default; raise n or pass n = Inf for all.
# Returns a data.frame: doc_id, platform, date, data_source, x, y  (ready to ggplot).
dk_umap <- function(path = DK_STORE_PATH, n = 20000L, seed = 20260708L,
                    n_neighbors = 15L, min_dist = 0.1, metric = "cosine") {
  stopifnot(requireNamespace("DBI", quietly = TRUE),
            requireNamespace("duckdb", quietly = TRUE),
            requireNamespace("uwot", quietly = TRUE))
  # array = "matrix": makes DuckDB hand back the FLOAT[] column as an R matrix (required).
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = TRUE, array = "matrix")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  total <- DBI::dbGetQuery(con, "SELECT COUNT(*) AS n FROM chunks")$n
  cols  <- "doc_id, platform, date, data_source, embedding"
  # Sample at the SQL level (reservoir, seeded = reproducible) so we DON'T pull all
  # ~710k x dim floats into RAM just to subsample. n = Inf -> the whole store.
  if (is.finite(n) && n < total) {
    q <- sprintf("SELECT %s FROM chunks USING SAMPLE %d ROWS (reservoir, %d)", cols, as.integer(n), as.integer(seed))
    message(sprintf("dk_umap: projecting a %d-row reservoir sample of %d (set n = Inf for all).", as.integer(n), total))
  } else q <- sprintf("SELECT %s FROM chunks", cols)
  res <- DBI::dbGetQuery(con, q)

  mat  <- res$embedding                                        # already an M x dim matrix
  meta <- res[, c("doc_id", "platform", "date", "data_source")]  # drops the matrix column
  emb  <- uwot::umap(mat, n_neighbors = n_neighbors, min_dist = min_dist, metric = metric)
  data.frame(meta, x = emb[, 1], y = emb[, 2], stringsAsFactors = FALSE)
}

# --- convenience banner when sourced interactively --------------------------------------------
if (interactive()) {
  message("DigiKat semantic helpers loaded:")
  message("  dk_retrieve(\"question\", top_k = 10)      # meaning-search")
  message("  dk_umap(n = 20000)                          # 2D meaning-map (sampled)")
  message("  ragnar_store_atlas(dk_store())              # built-in interactive map (localhost:3030)")
}
