# Replication guide — DigiKat

This guide separates what anyone can reproduce from a clean clone from the restricted full-corpus
workflow available only on an authorized pipeline machine.

## 1. Scope

DigiKat:

1. filters incoming media records with the frozen “at least two distinct religious terms” rule;
2. merges and deduplicates retained records by platform-aware canonical URL;
3. produces 14 aggregate datasets;
4. builds three sampled UDPipe token generations for analytical pages;
5. renders a Quarto website; and
6. optionally builds a local semantic-search store.

The current aggregate generation covers 710,307 records, 47 master columns, nine source types, and
2021 through June 2026. The public synthetic fixture has 2,700 records with the same 47-column schema.

## 2. Shared and restricted inputs

| Asset | Role | Clean clone |
|---|---|---|
| `data/sample/merged_sample.rds` | fully synthetic pipeline fixture | included |
| `data/sample/merged_sample_manifest.json` | fixture schema, counts, and hash | included |
| `data/processed/*.rds` | 14 disclosure-reviewed production aggregates | included |
| `resources/**` | dictionaries, lexicons, labels, and pinned UDPipe model | included, upstream licenses apply |
| `data/merged_comprehensive.rds` | restricted full corpus | excluded |
| `data/raw/**` | source exports and incoming batches | excluded |
| `data/nlp/*.rds` | generated sampled documents and tokens | excluded |
| `data/semantic/**` | prepared text, vectors, database, and manifests | excluded |
| `studies/*/output/private/**` | row-level coding and validation artifacts | excluded |

See `DATA_AVAILABILITY.md` and `resources/README.md` for redistribution and licensing detail.

## 3. Computational environment

The checked environment snapshot was produced with:

- R 4.6.0 on Windows 11;
- Quarto 1.9.38;
- UTF-8 locale support from R 4.2 or newer;
- package versions in `renv.lock`; and
- UDPipe model SHA-256
  `b8e0ad212bdc84c57366bd7267d21810e1fd3239c4d22ca5867f94e76c6cedc7`.

Restore the R library from the repository root:

```powershell
Rscript -e "renv::restore()"
Rscript R/capture_environment.R
```

`R/capture_environment.R` is read-only. Updating `renv.lock` is deliberately separate:

```powershell
Rscript R/snapshot_dependencies.R --apply
```

## 4. Public synthetic replication

From a clean clone:

```powershell
Rscript tests/run_tests.R
Rscript R/check_disclosure.R
Rscript R/00_run_all.R --sample
```

This run:

- validates the environment and shared logic;
- regenerates the 2,700-row deterministic synthetic fixture;
- builds and reconciles all 14 aggregates in a temporary directory;
- tokenizes deterministic 5%, 3%, and 2% stratified NLP samples; and
- deletes the temporary outputs after successful validation.

It never reads or modifies the restricted master.

To retain synthetic aggregate outputs for inspection:

```powershell
Rscript R/03_aggregate.R `
  --master=data/sample/merged_sample.rds `
  --output-dir=quality_reports/sample-processed
```

The destination must be absent or empty.

## 5. Authorized full-corpus validation

On a machine with the restricted master, pinned model, and existing NLP/semantic artifacts:

```powershell
Rscript R/00_run_all.R
```

The default full-corpus orchestration is non-destructive. It performs:

- setup and model checks;
- regression tests;
- a complete 14-file aggregate build in a temporary directory with row-total reconciliation;
- NLP manifest and sample/token alignment validation; and
- semantic manifest, schema, index, and document-count validation when the store exists.

No tracked aggregate, NLP generation, semantic database, or site output is replaced.

## 6. Explicit production operations

These operations are intentionally separate from validation.

### Append an incoming batch

```powershell
Rscript R/append_new_data.R
# inspect quality_reports/ingestion/append-*.json
Rscript R/append_new_data.R --apply
```

Apply mode verifies the backup hash, stages and round-trips the new RDS, then atomically replaces the
master. A missing deduplication key fails closed unless the exceptional override is explicitly supplied.

### Replace production aggregates

```powershell
$candidate = Join-Path $env:TEMP "digikat-aggregate-preview"
Rscript R/03_aggregate.R --output-dir=$candidate
Rscript R/compare_aggregates.R --candidate-dir=$candidate --allow-differences
# review the build manifest and every reported value difference
Rscript R/03_aggregate.R --apply
```

Apply mode stages and validates the entire generation before swapping directories. The previous
generation is retained under the ignored private backup area. Omit `--allow-differences` when the
comparison is being used as a strict equality gate.

### Build NLP artifacts

```powershell
Rscript R/04_nlp.R               # validate only
Rscript R/04_nlp.R --build       # stage, validate, and replace
```

Each generation records input, model, sample, and token hashes. A stale manifest fails validation.

### Build semantic search

```powershell
Rscript R/semantic/10_prep.R
Rscript R/semantic/11_build.R --build
```

Rebuilds use `--rebuild`; they create and validate a separate `.building-*` database before retaining
the previous usable store. See `R/semantic/README.md`.

### Render the site

```powershell
quarto render
Rscript R/check_site_links.R
```

Always render from the repository root. A full render writes `docs/` and should follow successful
pipeline validation. Never hand-edit `docs/`.

## 7. Program map

| Program | Responsibility |
|---|---|
| `R/00_setup.R` | validate runtime, packages, model, and religious-term source |
| `R/00_run_all.R` | conservative orchestration and synthetic smoke workflow |
| `R/01_filter.R` | full-corpus application of the canonical religious filter |
| `R/02_merge.R` | merge candidate generations without targeting the protected master |
| `R/append_new_data.R` | preview/apply incremental ingestion with backup and URL deduplication |
| `R/03_aggregate.R` | one canonical 14-output aggregate generation |
| `R/04_nlp.R` | build/adopt/validate sampled UDPipe outputs |
| `R/05_codebook.R` | generate a schema-oriented codebook |
| `R/lib/*.R` | shared CLI, hashing, URL, filter, and thematic-dictionary logic |
| `R/semantic/10_prep.R` | prepare stable document IDs and semantic input |
| `R/semantic/11_build.R` | stage, index, adopt, rebuild, or validate the Ragnar store |
| `R/wiki_sources.R` | regenerate the source catalog from six actor aggregates |
| `pages/**/*.qmd` | read-only analytical and narrative site sources |

## 8. Output mapping

| Site layer | Source | Main inputs |
|---|---|---|
| Mapa ekosustava | `pages/mapa/mapa.qmd` | 14 files in `data/processed/` |
| Tematske struje | `pages/mapa/mapa_stats.qmd` | `mapa_stats_*` NLP pair + shared thematic dictionary |
| Atmosfera diskursa | `pages/mapa/diskurs.qmd` | `diskurs_*` NLP pair + CroSentiLex/LiLaH |
| Fokus na događaje | `pages/mapa/događaji.qmd` | `dogadjaji_*` NLP pair + shared thematic dictionary |
| Katalog izvora | `pages/izvori/*.qmd` | six `*_actors.rds` aggregates + `source_labels.csv` |

## 9. Verification criteria

A replication is successful only when:

- all regression and disclosure checks pass;
- all 14 aggregate outputs round-trip and reconcile to the included input rows;
- every sampled document has tokens and no token document is orphaned;
- manifests match current input/model/output hashes;
- every rendered internal link resolves; and
- no restricted row-level artifact is trackable.
