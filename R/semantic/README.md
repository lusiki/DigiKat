# R/semantic/ — Level 3: Meaning search

Search the ≈710k-post corpus by **meaning**, not just keyword, and draw a 2D "meaning map"
of themes. Every post becomes a vector (embedding) in a **local** DuckDB store; retrieval is
hybrid vector + BM25 via [`ragnar`]. **All local — post text never leaves this machine.**

Roadmap context: `SEMANTIC-INFRASTRUCTURE-ROADMAP.md` (Level 3). Plan: `quality_reports/plans/2026-07-08_semantic-search-L3.md`.

## One-time prerequisites
1. **Ollama** — install the Windows app (https://ollama.com/download), then in a terminal:
   ```
   ollama pull bge-m3
   ```
   Ollama must be **running** (it serves `http://localhost:11434`) whenever you build or query.
   This is the only step Claude can't do for you (GUI installer + model download).
2. **R packages** (already installed on this machine): `ragnar`, `duckdb`, `ellmer`, `uwot`.
   *(Optional: `mirai` for parallel embedding — failed to compile here; not required, just slower.)*

## Run order (from the REPO ROOT, where R + the master live)
```
Rscript R/semantic/10_prep.R      # master  -> data/semantic/corpus_prepared.rds  (lean slice)
Rscript R/semantic/11_build.R     # embed + store + BUILD INDEX -> data/semantic/digikat.ragnar.duckdb
Rscript -e "source('R/semantic/12_query.R'); print(dk_retrieve('hodočašće u Mariju Bistricu'))"
```
- `10_prep.R` — reads the master READ-ONLY, keeps `doc_id | platform | date | data_source | actor | url | text`,
  drops empty-text rows. Falls back to `data/sample/` if the master is absent.
- `11_build.R` — embeds every post with `bge-m3`, inserts in 1000-row batches, then
  **builds the index** (vss + fts). This is the step that is *silently fatal to skip*.
  Long-running (710k embeddings). Refuses to clobber an existing store; to rebuild:
  `DIGIKAT_SEMANTIC_REBUILD=1 Rscript R/semantic/11_build.R`.
- `12_query.R` — **source it, don't run it.** Helpers:
  - `dk_retrieve("question", top_k = 10)` → tidy tibble (doc_id, platform, date, data_source, similarity, snippet).
  - `dk_umap(n = 20000)` → 2D map coords (reservoir-sampled; `n = Inf` for all) — ready to `ggplot`.
  - `ragnar_store_atlas(dk_store())` → built-in interactive meaning-map at `http://localhost:3030`.

## Guardrails / gotchas
- `data/semantic/**` is **gitignored + Dropbox-ignored** — the `.duckdb` is large and a synced
  DuckDB file file-locks (the Dropbox hazard in `CLAUDE.local.md`). Rebuild it locally; never commit it.
- **Corpus caveat (MEMORY.md):** the ~2024 collection-method change confounds cross-year volume.
  Before reading any trend from retrieved results or the map, group/colour by `data_source` + `platform`.
- **Validation habit (roadmap §Validation):** hand-check a sample of retrievals and report retrieval
  precision in any methods section — meaning-search is recall-friendly but not infallible.
- Croatian diacritics (č ć ž š đ) round-trip correctly through the store (verified).

## What this unlocks (vs. the 16-category dictionary)
Themes beyond the fixed categories · how far **comment discourse drifts from portal framing** ·
**syndicated / reworded copies** (who feeds whom, with what delay) · a topic's **vocabulary migrating**
(e.g. abortion: theological → political). *Claims about documents in bulk.*

## Embedding-input truncation (important methodological note)
bge-m3's context is **8192 tokens**, and every token in one embedding batch must co-fit that window —
so a batch packed with long portal articles is rejected by Ollama ("input length exceeds the context
length"). `11_build.R` therefore truncates the **embed input** to the first **4000 chars** (~650 words)
and uses embed `batch_size = 64` (the fastest batch that survives a worst-case all-longest batch,
~21 rows/s). Consequences:
- The **full post text is still stored** in the DuckDB `chunks.text` column and returned by
  `dk_retrieve(..., full_text = TRUE)`; the `URL` column always links the source.
- For the ~⅓ of posts longer than 4000 chars, only the **embedding vector** is built from the
  lede+body. This is fine for topical/semantic retrieval; it can miss a topic that appears ONLY deep
  in a long article — that's what chunking (below) fixes.
- To trade time for more text, raise the truncation but LOWER the batch (measured-safe pairs:
  `5000×48` ~16 rows/s, `6000×32` ~14 rows/s) — keep them together or long-doc batches will 400.

## Not yet wired (documented follow-ups)
- **Category metadata** — the 16-cat labels aren't a stored master column (they're computed in
  `R/04_nlp.R`); v1 store omits them. Add later by joining the dictionary tags into `10_prep.R`.
- **Long-article chunking** — the full-fidelity fix for the truncation above: split long articles
  with `markdown_chunk()` into a version-2 store so every part gets its own vector. Deferred; only
  needed for a study that must retrieve deep-buried content from long articles.
