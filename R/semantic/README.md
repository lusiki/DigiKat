# Semantic search — local Level 3

This optional layer retrieves DigiKat records by meaning with a local `bge-m3` embedding model and a
Ragnar DuckDB store. Post text and vectors stay on the machine running Ollama; do not replace the local
provider with an external API for restricted corpus text.

## Prerequisites

Restore the project R library, install Ollama, and pull the pinned model name:

```powershell
Rscript -e "renv::restore()"
ollama pull bge-m3
```

Ollama must be running while building or querying because query text also needs an embedding.

Required R packages include `ragnar`, `duckdb`, `DBI`, `ellmer`, `dplyr`, `here`, and `digest`.
`uwot` is needed only for a two-dimensional map.

## Commands

### Prepare the full corpus

```powershell
Rscript R/semantic/10_prep.R
```

The script reads the master without modifying it and stages:

- `data/semantic/corpus_prepared.rds`
- `data/semantic/corpus_prepared_manifest.json`

It keeps stable hashed `doc_id`, platform, date, data-source, actor, URL, and text fields. It validates
the staged output before replacement. Missing master data is an error; there is no silent sample fallback.

For a synthetic check:

```powershell
Rscript R/semantic/10_prep.R --sample --output=<temporary-path>.rds
```

### Validate, adopt, build, or rebuild

```powershell
Rscript R/semantic/11_build.R                   # read-only validation
Rscript R/semantic/11_build.R --adopt-existing  # fingerprint a reviewed legacy store
Rscript R/semantic/11_build.R --build           # first build
Rscript R/semantic/11_build.R --rebuild         # replace after separate successful build
```

`--build` and `--rebuild` write a `.building-*` database, checkpoint batches, build both vector and
full-text indexes, validate schema/counts/document IDs, and then activate it. A prior usable database is
moved to a timestamped `.previous-*` path only after the new store passes.

For a bounded test:

```powershell
Rscript R/semantic/11_build.R --build --limit=1000
```

Use `DIGIKAT_EMBED_MODEL` and `DIGIKAT_SEMANTIC_BATCH` only when deliberately testing an alternative
model or batch size. Boolean `DIGIKAT_SEMANTIC_REBUILD=0` is parsed as false.

### Query

```powershell
Rscript -e "source('R/semantic/12_query.R'); print(dk_retrieve('hodočašće u Mariju Bistricu'))"
```

`12_query.R` is sourced as a helper module:

- `dk_retrieve(question, top_k = 10)` returns document metadata, similarity, and snippets.
- `dk_umap(n = 20000)` creates a sampled two-dimensional coordinate table.
- `ragnar_store_atlas(dk_store())` starts Ragnar’s local interactive atlas.

## Storage and disclosure

Everything under `data/semantic/` is gitignored. The directory contains corpus text, URLs, embeddings,
and a large mutable database. Keep it on local, access-controlled storage and outside actively
synchronized Dropbox/OneDrive directories.

To move a validated store to another authorized machine, copy the database, prepared input, and both
manifests through an approved encrypted channel. Verify with `Rscript R/semantic/11_build.R` after transfer.

## Methodological constraints

- The model accepts a finite context. The builder embeds the first 4,000 characters while retaining the
  full text in the store. A topic appearing only deep in a long article can therefore be missed.
- Retrieval is recall-friendly, not a gold label. Hand-check a documented sample and report precision
  for any study that turns retrieval into a substantive claim.
- Time comparisons must account for platform and `data_source`, especially around the approximate 2024
  collection-method seam.
- Meaning-search complements rather than replaces the shared 16-category dictionary.

Long-article chunking and category metadata are intentionally future schema versions; they should not be
added silently to the existing store because either change alters the unit of retrieval.
