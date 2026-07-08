# Plan — Semantic search (Level 3) infrastructure

**Date:** 2026-07-08 · **Owner:** PI (Luka Šikić) · **Layer:** `R/semantic/`
**Roadmap ref:** `SEMANTIC-INFRASTRUCTURE-ROADMAP.md` — Level 3 "Meaning search".

## Goal
Let the corpus be searched by *meaning* (not just keyword), and lay the base for a 2D
"meaning map" of themes. Every post → an embedding vector in a local DuckDB store;
hybrid vector + BM25 retrieval via `ragnar`. **All local — data never leaves the machine.**

## Why (exclusive conclusions this unlocks — from the roadmap)
- Themes beyond the 16 dictionary categories.
- How far **comment discourse drifts from portal framing**, and whether the gap widens around events.
- **Reworded / syndicated copies** (which portal feeds which, with what delay).
- A topic's **vocabulary migrating** (e.g. abortion: theological → political).

## Prerequisites (state as of this plan)
- **R 4.4.1** present (UTF-8 TRUE). `duckdb` ✅ + `uwot` ✅ already installed;
  `ragnar` + `ellmer` being installed now.
- **Ollama NOT installed** — MANUAL step for the PI (GUI installer + `ollama pull bge-m3`).
  Nothing in `11_build.R` can run until the local embedding model answers on `localhost:11434`.
- **Master present** (`data/merged_comprehensive.rds`, ~710k × 47). Read READ-ONLY.

## Confirmed master columns (from pipeline code — validated at runtime by the script)
| Semantic field | Master column | Note |
|---|---|---|
| text     | `FULL_TEXT`   | the post body |
| platform | `SOURCE_TYPE` | web/facebook/youtube/… |
| date     | `DATE`        | CHARACTER ISO "YYYY-MM-DD" — parse with `as.Date` |
| stream   | `data_source` | `original_dta` (2021–24) vs `filtered_religious` (2024–26) — KEEP for the confound |
| actor    | `FROM`        | account/author |
| url      | `URL`         | for provenance + dedup |
| doc_id   | *synthesized* | master has no stable id → `dk_<rownum>` (+ URL kept) |

**Category (16-cat) is NOT a stored column** — it is computed via the dictionary pass
(`R/04_nlp.R`). Deferred: v1 store carries platform/date/stream/actor/url only; category
metadata is a documented follow-up (needs the dictionary tagging join).

## Files (build order)
1. `R/semantic/10_prep.R` — read master READ-ONLY → validate columns → synthesize `doc_id`
   → drop empty/whitespace `FULL_TEXT` → write `data/semantic/corpus_prepared.rds`
   (a lean table: doc_id, platform, date, data_source, actor, url, text). Reports row counts +
   drops. Falls back to `data/sample/` if the master is absent (like `slice.R`).
2. `R/semantic/11_build.R` — create/open the ragnar store at
   `data/semantic/digikat.ragnar.duckdb` (embed via Ollama `bge-m3`) → insert in batches →
   **`ragnar_store_build_index()`** (the silently-fatal-to-skip step). Idempotent-ish: warns if
   the store already exists (no silent clobber). Preflight-checks Ollama is reachable and errors
   with a clear message if not.
3. `R/semantic/12_query.R` — `dk_retrieve(query, top_k)` wrapper over `ragnar_retrieve()`
   returning a tidy tibble (doc_id, platform, date, score, text-snippet); plus `dk_umap()` that
   pulls the stored vectors and projects to 2D with `uwot` for the meaning map. Sourced, not run.

## Guardrails
- **No HARD-GATE action.** Reads master read-only; does NOT overwrite the master, backups,
  `data/processed/*.rds`, or `docs/`. No full render.
- `data/semantic/**` is **gitignored + Dropbox-ignored** (the `.duckdb` is large + Dropbox
  file-locking is a known hazard here — see `CLAUDE.local.md`).
- Croatian: read/lower with explicit UTF-8 (`stringi`/`locale="hr"`); confirm diacritics survive a
  round-trip retrieval before trusting output.
- **Validation habit (roadmap §Validation):** hand-check a sample of retrievals; report retrieval
  precision in any methods section. Respect the ~2024 collection-method confound — filter/colour by
  `data_source` + platform before reading any trend.

## Run sequence (where R + master + Ollama live)
```
# one-time, machine level:  install Ollama, then:  ollama pull bge-m3
Rscript R/semantic/10_prep.R          # slice → data/semantic/corpus_prepared.rds
Rscript R/semantic/11_build.R         # embed + store + BUILD INDEX  (long: 710k embeds)
Rscript -e 'source("R/semantic/12_query.R"); print(dk_retrieve("hodočašće u Mariju Bistricu"))'
```

## As-built / execution notes (2026-07-08)
- **Env verified:** R 4.4.1; `ragnar` 0.3.0 + `ellmer` installed (`duckdb`,`uwot` already present; `mirai`
  failed to compile — not required, just no parallel embedding). Ollama installed; `bge-m3` pulled
  (1.2 GB, 1024-dim); serves on `localhost:11434`; runs 100% on the RTX 4080 Laptop GPU.
- **Store is ragnar VERSION 1** (one post = one chunk + metadata). v2 wants `markdown_chunk()` inputs.
- **`10_prep.R` ran on the real master:** 710,307 × 7 → `data/semantic/corpus_prepared.rds` (~1 GB).
  Column map confirmed: FULL_TEXT/SOURCE_TYPE/DATE/data_source/FROM/URL; doc_id synthesized `dk_########`.
- **HTTP 400 "input length exceeds the context length" — root cause + fix.** bge-m3 context = 8192
  TOKENS, and ALL tokens in one embedding batch must co-fit that window. The corpus has long portal
  articles (median 2,487 chars but the tail runs to ~32k, incl. long Serbian pieces), so a batch packed
  with them overflows and Ollama 400s the whole request. First full run crashed at a few-thousand rows.
  **Fix (empirically tuned on the 256 longest docs = worst case):** truncate the EMBED INPUT to the
  first **4000 chars** and use embed **`batch_size = 64`** (in `dk_embed`, baked in as literals — the
  closure is serialized into the store + runs in a clean worker, so no free vars). Full text is still
  STORED (ragnar keeps `chunks$text`, not the truncated copy); only the vector of the longest ~⅓ posts
  is built from the lede+body. Measured envelope: 4000×64 OK ~21/s, 4000×128 OK ~22/s, 8000×64 FAIL,
  6000×32 OK ~14/s, 2000×256 FAIL. Full-fidelity alternative (deferred) = chunk long articles (v2 store).
- **10k integration test through `11_build.R` passed clean** (26 rows/s), then the **full build launched**
  (~26 rows/s, ETA ~7.5 h). Store ≈ 12 GB projected (174 MB / 10k rows). Test stores
  `digikat_test{800,10000}.ragnar.duckdb` left as sandboxes (gitignored/Dropbox-ignored).
- **Query layer works** (`dk_retrieve`/`dk_umap` validated offline + on the 800-row real store);
  Croatian diacritics round-trip cleanly; `ragnar_store_atlas()` gives a built-in interactive map.

## Rejected alternatives
- **Cloud embeddings (OpenAI/Voyage):** rejected — sensitive scraped text must stay local; roadmap mandates local `bge-m3`.
- **Chunk every post:** rejected — most posts are short = one vector each; only long portal
  articles need splitting (roadmap §2). v1 embeds whole `FULL_TEXT`; long-article chunking deferred.
- **Python/LangChain path:** rejected — R-native `ragnar`+`duckdb`+`ellmer` keeps the stack in Positron/R.
