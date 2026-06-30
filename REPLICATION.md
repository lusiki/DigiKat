# Replication Guide — DigiKat

> **Status: IN PROGRESS.** Follows the AEA Data Editor's 8-section template, scaled to DigiKat (open data +
> a Quarto website; archived on GitHub, intended for Zenodo, CC BY 4.0 — **not** an AER/openICPSR submission).
> Items marked **(PENDING)** depend on work scheduled in the workflow roadmap (`WORKFLOW_SUGGESTIONS.md`).

## 1. Overview
DigiKat maps Catholic themes across the Croatian digital media ecosystem. The code (a) filters a raw media
corpus to Catholic content (≥2 distinct term matches), (b) builds aggregate datasets, (c) runs NLP (udpipe
tokenization/lemmatization, dictionary themes, lexicon sentiment), and (d) renders a Quarto website.
Primary language: R (+ a small stdlib Python stemmer). Output: the `docs/` site + `data/processed/*.rds`.

## 2. Data availability
See `DATA_AVAILABILITY.md`. The master corpus is gitignored and available on request; aggregate data
(`data/processed/*.rds`) and a synthetic sample (`data/sample/`, **PENDING**) are in the repo under CC BY 4.0.

## 3. Dataset list
| File | Role | In repo |
|---|---|---|
| `data/merged_comprehensive.rds` | master corpus (≈710k×47) | no (gitignored) |
| `data/processed/*.rds` | 10 aggregates (platform/source/actor summaries) | yes |
| `data/sample/merged_sample.rds` | synthetic ≈500-row sample | **PENDING** |
| `resources/lexicons/*`, `resources/dictionaries/*` | sentiment + theme dictionaries | yes |
| `resources/models/croatian-set-ud-2.5-191206.udpipe` | Croatian UD model | yes |

## 4. Computational requirements
- **R** (≥ 4.2 recommended — native UTF-8 on Windows) with packages pinned via `renv` (`renv.lock`, **PENDING**:
  run `renv::init()` once on the pipeline machine). Core: data.table, tidyverse, stringi, udpipe, readxl, here, yaml.
- **Quarto** (≥ 1.3; developed with 1.6.43).
- **Python 3** (stdlib only) for the optional `R/Croatian_stemmer.py`.
- **udpipe model** pinned by sha256 `b8e0ad21…cedc7` (see `DATA_AVAILABILITY.md`).
- **Seeds** set deterministically (`set.seed`, YYYYMMDD convention).
- Capture the exact environment with `Rscript R/capture_environment.R` → `ENVIRONMENT.md`.

## 5. Description of programs
Target numbered pipeline (assembly **PENDING** — roadmap Phase 0):
- `R/00_run_all.R` — master orchestrator (sources 00–04 in order; honours `--from=NN`, `--sample`)
- `R/00_setup.R` — `renv::restore`, `here`, seed, `source("R/religious_terms.R")`, locale assertion
- `R/01_filter.R` — religious-terms ≥2 filter (wraps `load_merge_filter_religious.R`)
- `R/02_merge.R` — build/merge → `data/merged_comprehensive.rds`
- `R/03_aggregate.R` — `data/processed/*.rds` (the `saveRDS` calls extracted from `mapa.qmd`)
- `R/04_nlp.R` — udpipe + stemmer + 16-theme + 3-lexicon sentiment → `data/nlp/*.rds`
- `pages/**/*.qmd` — the website (reads `processed/` + `nlp/`)

Utilities (built): `R/append_new_data.R` (incremental), `R/make_sample.R` (sample), `R/05_codebook.R`
(codebook), `R/prune_backups.R` (backup retention), `R/capture_environment.R` (environment snapshot).

## 6. Instructions to replicators
**Full corpus** (PI / pipeline machine, where the master + R live):
```
renv::restore()
Rscript R/00_run_all.R      # rebuild data/processed/ + data/nlp/   (PENDING the numbered master)
quarto render               # rebuild docs/
```
**Without the master** (anyone, from a clean clone) — **PENDING** the sample:
```
renv::restore()
Rscript R/00_run_all.R --sample   # runs on data/sample/merged_sample.rds
quarto render
```

## 7. Table/figure mapping (exhibit → page → data)
| Analytical layer | Page | Reads |
|---|---|---|
| Mapa ekosustava (volume/reach/engagement, actor typology) | `pages/mapa/mapa.qmd` | `data/processed/{platform_summary,proportions_summary,source_summary,top_*_sources,*_actors}.rds` |
| Tematske struje (16 themes over time) | `pages/mapa/mapa_stats.qmd` | `data/nlp/*` + processed |
| Atmosfera diskursa (sentiment/emotion/conflict) | `pages/mapa/diskurs.qmd` | `data/nlp/*` + `resources/lexicons/*` |
| Fokus na događaje (event dynamics) | `pages/mapa/događaji.qmd` | `data/nlp/*` + processed |

Per-exhibit script+line provenance can be added later if formal provenance is wanted (see `WORKFLOW_SUGGESTIONS.md` §6.3).

## 8. References
- Universal Dependencies / UDPipe — Croatian model `croatian-set-ud-2.5-191206`. _TODO: full citation + license._
- CroSentilex; CroSentilex Gold; lilaHR (NRC-based). _TODO: citations._
- DigiKat: Šikić, L. et al. (2025–2027). CC BY 4.0. https://github.com/lusiki/DigiKat
