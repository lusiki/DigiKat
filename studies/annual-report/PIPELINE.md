# Annual-report production pipeline

## Choosing the edition

The reporting year is the only parameter. `AR_YEAR` (default `2025`) selects it, and everything else
derives: the output directory `output/<year>/`, the calendar length (2024 is a leap year), which
period comparison is instrument-comparable, which completed study rotates into the special chapter,
and which manuscript template is installed. Set it once per shell.

```powershell
$env:AR_YEAR = '2024'    # omit, or set to 2025, for edition 1
```

An edition owns its directory. Two editions sharing one folder look identical on disk, and the older
generation's files get swept into the newer manifest — the failure that published the pilot's
236 166 after the corpus rebuild.

## The chain

Run from the repository root with the absolute R executable recorded in `CLAUDE.local.md`:

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/annual-report/00_data_readiness.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/annual-report/01_report_aggregates.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/annual-report/02_nlp_layers.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/annual-report/03_report_assets.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/annual-report/04_sync_fragments.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/annual-report/05_report_checks.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' R/check_disclosure.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/annual-report/06_render_report.R
```

Stage 06 re-runs stage 05 itself and refuses to render if any check fails, so the last two lines are
the only ones needed after an edit to prose or typeset.

## What the edition reads

**`data/digikat_corpus.rds`** — the official corpus, opened read-only. This is the dataset the
edition describes, and the report's own annual aggregates are cut from it (step 4 of the public
runbook below). `data/processed/` is used only as a reconciliation reference: stage 01 asserts that
its own platform cut equals `platform_summary.rds` cell for cell.

**`data/nlp/*_sample.rds` and `*_tokens.rds`** — reused, not rebuilt. Since the generation of
2026-08-10 these are drawn from the corpus itself (`manifest.json` names `data/digikat_corpus.rds` and
carries its sha256), so stage 02's corpus-membership match is a no-op safety filter that currently
resolves at 100 %. Keep it: it is what makes the stage safe to run against an older, accumulator-derived
NLP generation, where it would silently do the real work instead of quietly mixing two populations.
Stage 02 measures and records the surviving share in `output/nlp_coverage.csv` — about 5,0 % of the
corpus year for themes and 2,0 % for tone. udpipe is never re-run here.

## Script contracts

| Script | Reads | Writes | Fails when |
|---|---|---|---|
| `00_data_readiness.R` | corpus + processed + NLP manifests, schemas, lexicons, label sidecar | `output/readiness.csv`, `readiness_manifest.json` | the corpus hash does not match its manifest, `data/processed/` was built from another dataset, a schema or package is missing |
| `01_report_aggregates.R` | the corpus, the label sidecar, the special-chapter registry | volume / stream / source / actor / coverage CSVs | a total fails to reconcile, the calendar is not the year's own length, or the report's cut disagrees with `platform_summary.rds` |
| `02_nlp_layers.R` | corpus keys, NLP samples and tokens, sentiment lexicons | theme, tone and event-signature CSVs, `nlp_coverage.csv` | a sample cannot be matched to the corpus or a layer comes back empty |
| `03_report_assets.R` | the report's own CSVs | 9 figures, 10 table fragments, `annual_report_derived.csv`, `manifest.json` | a scalar cannot be derived, a table exceeds five columns, or a figure fails to draw |
| `04_sync_fragments.R` | the tracked template, scalars, fragments | `output/private/IZVJESTAJ.qmd` | a token is unknown, duplicated or unresolved |
| `05_report_checks.R` | template, manuscript, outputs, manifest | `output/private/review/mechanical_checks.csv` | any of the 57 checks fails |
| `06_render_report.R` | the checked manuscript, figures, typeset assets | private HTML with external responsive assets and Typst PDF | checks fail, Quarto is older than 1.8, a render fails, `docs/` changes, metadata is incomplete, images embed as base64, or the HTML loses diacritics |

## Provenance model

- `output/readiness_manifest.json` records the corpus hash, its cutting rule and the NLP sampling design.
- `output/manifest.json` records the reporting year, the dataset, generator-script hashes, upstream
  manifest hashes and a hash for every generated artifact. Repository-relative paths only.
- `output/annual_report_derived.csv` is the only source of prose scalars. Tables are installed
  byte-for-byte and re-checked against the fragment on disk.
- The populated manuscript and everything naming an outlet at row level stay in gitignored
  `output/private/`.

## Which comparison an edition may publish

The recurring chapter "Gdje se razgovor seli?" needs a movement measured inside ONE collection
stream. `AR_STREAM_MODE` derives which shape is available from the corpus manifest's era spans, and
stage 01 emits the same columns either way, so the figure and the table do not know which edition
they are drawing.

| Mode | When | What is compared | Unit |
|---|---|---|---|
| `yoy_h2` | the baseline year's second half is already inside the stream | H2 baseline vs H2 report year, same calendar days removed from both | posts |
| `within_year_quarters` | the stream begins during the reporting year, so no year-over-year answer exists | Q3 vs Q4 of the reporting year | posts per collected day |

2025 uses the first; 2024 uses the second, because the post-2024 stream begins 2024-07-01. The rate
unit is not cosmetic — 2024's Q3 loses fifteen days to an interruption, and a raw count would have
printed that as a fall in attention. Where the second mode applies, the edition must also say in
prose that the step carries the Advent and Christmas season, and print the missing year-over-year
measure as a gap panel rather than substituting the quarter step for it.

## Protected paths

The chain writes only below `studies/annual-report/output/`. It does not change
`data/digikat_corpus.rds`, `data/merged_comprehensive.rds`, `data/processed/`, `data/nlp/`,
`R/03_aggregate.R`, `_quarto.yml` or `docs/`. Rendering happens in a temporary directory outside the
repository, and `docs/` is fingerprinted before and after.

## Public annual runbook

1. Close the calendar-year ingest and verify coverage through December, including a check for
   collection interruptions — 2025 carried a fourteen-day one.
2. Run the controlled `/refresh-data` workflow.
3. Rebuild the corpus and the aggregates in order, with separate authorization for each protected apply.
4. Run the report's own stream-aware annual aggregates (stage 01).
5. Generate the reading layers, figures, fragments, scalars and manifest (stages 02–03).
6. Sync the manuscript and run the mechanical checks (stages 04–05).
7. Run the disclosure screen and the independent numeric and domain reviews.
8. Render HTML and PDF outside the repository (stage 06).
9. Freeze the copy and hold the embargo pre-brief without covered-actor editorial input.
10. Obtain PI sign-off; run `06_render_report.R --promote`, then publish the site only through `/deploy`.

## Recovery

Every output is derived. Delete the exact contents of `studies/annual-report/output/` after confirming
the resolved path, then rerun the chain. Never clean a broader directory.
