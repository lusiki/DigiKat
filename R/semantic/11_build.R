#!/usr/bin/env Rscript
# R/semantic/11_build.R  —  Level 3 (Meaning search), step 2 of 3
# Embed every prepared post with local Ollama `bge-m3` and store it in a ragnar
# DuckDB store, then BUILD THE INDEX (the step that is silently fatal to skip).
#
# Reads  : data/semantic/corpus_prepared.rds  (from 10_prep.R)
# Writes : data/semantic/digikat.ragnar.duckdb (gitignored + Dropbox-ignored)
# Local-only: text never leaves the machine; embeddings come from Ollama on localhost.
#
# PREREQUISITE (one-time, machine level):
#   1. Install Ollama (Windows installer).
#   2. `ollama pull bge-m3`
#   Ollama must be running (it serves http://localhost:11434) BEFORE this script.
#
# Run where R + the prepared corpus + Ollama live:
#   Rscript R/semantic/11_build.R
#   # to rebuild from scratch:  DIGIKAT_SEMANTIC_REBUILD=1 Rscript R/semantic/11_build.R
suppressPackageStartupMessages({ library(here); library(ragnar) })

MODEL      <- "bge-m3"
BATCH      <- 1000L                                   # rows per insert (each triggers its own embedding)
in_path    <- here::here("data/semantic/corpus_prepared.rds")
rebuild    <- nzchar(Sys.getenv("DIGIKAT_SEMANTIC_REBUILD"))
# Optional test knob: DIGIKAT_SEMANTIC_LIMIT=N embeds only the first N rows into a SEPARATE
# test store (digikat_testN.ragnar.duckdb), so it never collides with the real full store.
LIMIT      <- suppressWarnings(as.integer(Sys.getenv("DIGIKAT_SEMANTIC_LIMIT")))
LIMIT      <- if (is.na(LIMIT) || LIMIT <= 0L) NA_integer_ else LIMIT
store_path <- if (is.na(LIMIT)) {
  here::here("data/semantic/digikat.ragnar.duckdb")
} else {
  here::here(sprintf("data/semantic/digikat_test%d.ragnar.duckdb", LIMIT))
}
if (!is.na(LIMIT)) cat("### TEST MODE: only the first", LIMIT, "rows ->", basename(store_path), "###\n")

if (!file.exists(in_path))
  stop("Missing ", in_path, " — run  Rscript R/semantic/10_prep.R  first.")

# --- no silent clobber: refuse to overwrite an existing store unless asked --------------------
if (file.exists(store_path) && !rebuild)
  stop("Store already exists: ", store_path,
       "\n  To rebuild from scratch, delete it or set DIGIKAT_SEMANTIC_REBUILD=1.",
       "\n  (Leaving it as-is; nothing was changed.)")

# --- the embedder: LOCAL Ollama bge-m3. Self-contained (ragnar runs it in a clean worker). ----
# TWO tuned constants (baked in as LITERALS — the closure is serialized into the store and runs in a
# clean worker, so it must not depend on outer free variables):
#   substr(.,1,4000)  truncate the EMBED INPUT to 4000 chars (~650 words). bge-m3's context is 8192
#     TOKENS and, crucially, ALL tokens in one embedding batch must co-fit that window — so a batch
#     packed with long portal articles 400s ("input length exceeds context"). 4000 chars keeps every
#     batch safe AND captures an article's topical signal (lede+body). The store still holds the FULL
#     text (ragnar stores chunks$text, NOT this truncated copy) and the URL links the source.
#   batch_size = 64  empirically the fastest batch that survives the WORST case (a whole batch of the
#     256 longest ~32k-char docs) — measured ~21 rows/s, with margin below the failure edge.
# Measured envelope (256-longest worst case): 4000x64 OK 20.8/s; 4000x128 OK 22.4/s; 8000x64 FAIL;
# 6000x32 OK 13.7/s. Full-fidelity alternative = chunk long articles into a v2 store (documented follow-up).
dk_embed <- function(x) ragnar::embed_ollama(substr(x, 1L, 4000L), model = "bge-m3", batch_size = 64L)

# --- preflight: is Ollama up and does bge-m3 answer? Fail LOUD with the fix, not a stack trace -
cat("Preflight: contacting Ollama (", MODEL, ") on http://localhost:11434 ...\n", sep = "")
probe <- tryCatch(dk_embed("test"), error = function(e) e)
if (inherits(probe, "error"))
  stop("Could not get an embedding from Ollama.\n",
       "  - Is Ollama installed and running?  (open the app / `ollama serve`)\n",
       "  - Is the model pulled?               `ollama pull ", MODEL, "`\n",
       "  Underlying error: ", conditionMessage(probe))
emb_dim <- ncol(probe)
cat("  OK — bge-m3 responds; embedding dimension =", emb_dim, "\n")

# --- load prepared corpus ---------------------------------------------------------------------
dat <- readRDS(in_path)
if (!is.na(LIMIT)) dat <- utils::head(dat, LIMIT)      # TEST MODE: first N rows only
n   <- nrow(dat)
cat("Prepared corpus:", n, "rows to embed + store.\n")

# --- create the store; declare metadata columns via a zero-row prototype (extra_cols) ---------
# version = 1: one row = one chunk (+ metadata). No document chunking (posts are short).
extra <- data.frame(doc_id = character(), platform = character(), date = as.Date(character()),
                    data_source = character(), actor = character(), url = character())
if (file.exists(store_path) && rebuild) { cat("REBUILD: removing old store.\n"); file.remove(store_path) }
store <- ragnar_store_create(location = store_path, embed = dk_embed, extra_cols = extra,
                             name = "digikat", title = "DigiKat corpus (bge-m3)",
                             version = 1, overwrite = rebuild)
cat("Store created:", store_path, "\n")

# --- insert in batches (bounded memory + visible progress) ------------------------------------
starts <- seq(1L, n, by = BATCH)
t0 <- proc.time()[["elapsed"]]
for (i in seq_along(starts)) {
  a <- starts[i]; b <- min(a + BATCH - 1L, n)
  chunk <- data.frame(
    text        = dat$text[a:b],
    doc_id      = dat$doc_id[a:b],
    platform    = dat$platform[a:b],
    date        = dat$date[a:b],
    data_source = dat$data_source[a:b],
    actor       = dat$actor[a:b],
    url         = dat$url[a:b],
    stringsAsFactors = FALSE)
  ragnar_store_insert(store, chunk)
  if (i %% 10L == 0L || b == n) {
    el  <- proc.time()[["elapsed"]] - t0
    eta <- (n - b) / max(b / max(el, 1e-9), 1e-9) / 60          # minutes left at current rate
    cat(sprintf("  inserted %d / %d rows (%.0f%%)  [%.1f min elapsed, %.0f rows/s, ETA %.0f min]\n",
                b, n, 100 * b / n, el / 60, b / max(el, 1e-9), eta))
    flush(stdout())                                            # so a tail'd log updates live over the long run
  }
}

# --- BUILD THE INDEX — do NOT skip. Default builds both VSS (vector) + FTS (BM25) = hybrid. ----
cat("Building index (vss + fts) — this is the silently-fatal-to-skip step ...\n")
ragnar_store_build_index(store)

cat("\nDONE. Store ready:", store_path, "\n")
cat("  rows embedded:", n, "| model:", MODEL, "| dim:", emb_dim, "\n")
cat("NEXT: source('R/semantic/12_query.R'); then dk_retrieve(\"your question\")\n")
cat("      interactive meaning-map:  ragnar_store_atlas(ragnar_store_connect('", store_path, "'))\n", sep = "")
