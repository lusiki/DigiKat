# Setting up DigiKat on a new machine

Use a normal local Git clone for code and transfer restricted data separately. Keeping `.git` inside a
live Dropbox folder is discouraged because sync conflict resolution can corrupt Git objects and refs.

## 1. Install prerequisites

- Git
- R 4.2 or newer; the current lock was captured with R 4.6.0
- Quarto; the current checked version is 1.9.38
- Rtools matching the installed R version if a package must compile
- optional semantic search: Ollama with the `bge-m3` model

Verify the command locations instead of hard-coding a versioned path:

```powershell
where.exe git
where.exe Rscript
where.exe quarto
Rscript --version
quarto --version
```

## 2. Clone and restore

```powershell
git clone https://github.com/lusiki/DigiKat.git
cd DigiKat
Rscript -e "renv::restore()"
Rscript R/00_setup.R
Rscript tests/run_tests.R
Rscript R/check_disclosure.R
Rscript R/00_run_all.R --sample
```

This establishes a working public development environment without the restricted corpus.

`CLAUDE.local.md` is intentionally gitignored. Create it only if local automation needs machine paths
or storage notes; do not put secrets in it.

## 3. Transfer restricted assets

An authorized pipeline machine may also need:

| Asset | Destination | Required for |
|---|---|---|
| master corpus | `data/merged_comprehensive.rds` | full validation, aggregate and NLP rebuilds |
| raw/new input batches | `data/raw/new/` | incremental ingestion |
| current NLP generation + manifest | `data/nlp/` | production analytical pages |
| semantic prepared corpus + manifest | `data/semantic/` | store validation or rebuild |
| Ragnar DuckDB + manifest | `data/semantic/` | semantic querying and validation |
| private study outputs | `studies/<study>/output/private/` | authorized study continuation |

Transfer these through an approved encrypted channel. Do not add them to Git, email attachments,
issues, or public cloud shares. File sizes can change; verify hashes rather than relying on a historical
size.

After transfer:

```powershell
Rscript R/00_run_all.R
```

This validates the full generation without replacing it.

## 4. Semantic search

Install and start Ollama, then:

```powershell
ollama pull bge-m3
Rscript R/semantic/11_build.R
Rscript -e "source('R/semantic/12_query.R'); print(dk_retrieve('hodočašće u Mariju Bistricu'))"
```

The first R command is validation-only. If no store was transferred:

```powershell
Rscript R/semantic/10_prep.R
Rscript R/semantic/11_build.R --build
```

For replacement of an existing store use `--rebuild`. The builder writes a separate database, validates
its schema, counts, IDs, and indexes, and only then retains the old store and activates the new one.
Never place a live DuckDB database in a synchronized folder.

## 5. Production data workflow

Preview incoming data:

```powershell
Rscript R/append_new_data.R
```

Review the JSON report before:

```powershell
Rscript R/append_new_data.R --apply
```

Preview all aggregate outputs:

```powershell
Rscript R/03_aggregate.R
```

Only after review and explicit authorization:

```powershell
Rscript R/03_aggregate.R --apply
Rscript R/04_nlp.R --build
```

These steps have independent gates by design; a site render never creates production aggregates.

## 6. Quarto

Always render from the repository root:

```powershell
quarto render
Rscript R/check_site_links.R
```

The full render writes `docs/`. Do not render from inside `pages/`, do not hand-edit `docs/`, and do not
publish a sample-NLP render as the production site.

## 7. Final machine check

- `git status --short` shows only intentional work.
- `renv::status()` reports the project synchronized.
- `R/00_run_all.R --sample` passes.
- On authorized machines, `R/00_run_all.R` passes.
- The model hash matches `ENVIRONMENT.md`.
- Croatian text round-trips with `č ć ž š đ`.
- Semantic queries work if that optional layer is installed.
- Full site render and local-link crawl pass before publication.
