# moral-economy — pipeline (scripts → plan stages)

**Status (2026-08-04):** Stage A ran on the full master 2026-07-08 (132,519 linked candidates). The
dual-lens stages S1–S3, Stage V validation and Stage C all ran 2026-08-04; see `PAPER_v1.md` for results
and `quality_reports/plans/2026-08-04_moral-economy-dual-lens-run.md` for the full decision trail.
The keyword-only Stage B coding route below (`02`–`04`) was **superseded** by the 555-post gold sample
(`08`/`09a`/`09b`), which validates both lenses at once; `04_iaa_validation.R` survives as the kappa
implementation that `sem_lib.R` reuses.
Every script reads the corpus READ-ONLY and writes only to `output/`. Row-level coding sheets, URLs, source
identities, and text windows go to gitignored `output/private/`; only disclosure-reviewed aggregates belong
in tracked `output/`. The workflow never touches `data/` or the ≥2-match filter.
See [PLAN_census.md](PLAN_census.md) for the stage design, [CODEBOOK.md](CODEBOOK.md) for the coding scheme, [PROPOSAL.md](PROPOSAL.md) for the argument.

## Files

| Script | Plan stage | Reads | Writes | Master? |
|---|---|---|---|---|
| `lexicon.R` | (shared module) | `R/religious_terms.R` | — | no |
| `probe.R` | Stage 0 (done) | master | `domains_summary.csv`, … | yes ✅ ran |
| `diagnose_poverty.R` | Gate-1 seed (done) | master | `private/poverty_diagnosis_sample.csv` | yes ✅ ran |
| `01_stageA_tag_linkage.R` | **Stage A** | master | `stageA_candidates.rds`, `stageA_precision_sample.rds`, `stageA_domain_stats.csv` | **yes** |
| `02_gate1_precision_scan.R` | Gate 1 | `stageA_precision_sample.rds` | `private/gate1_precision_sheet.csv` → (coded) → `gate1_precision_by_domain.csv` | no |
| `03_build_coding_sheet.R` | Stage B prep | `stageA_candidates.rds` | `private/coding_sheet.csv`, `private/coding_key.csv`, `coding_allocation.csv` | no |
| `04_iaa_validation.R` | Gate 2 | `private/coding_sheet_ann*.csv` | `gate2_iaa.csv`, `coded_core.csv` | no |
| `build_calendar.R` | Stage C (H3) | — | `liturgical_calendar.csv` | no ✅ ran |

`lexicon.R` is the single source of truth — the 11 domain regexes + the economic-homonym-tightened
95-term religion regex. Editing it re-fingerprints the Stage-A checkpoint (a stale cache can't masquerade as fresh).

## Run order

```powershell
Rscript studies/moral-economy/lexicon.R                 # self-test: homonym guards

# >>> PAUSE DROPBOX SYNC before this — cold master read + Dropbox = os error 32 (CLAUDE.local.md) <<<
Rscript studies/moral-economy/01_stageA_tag_linkage.R

Rscript studies/moral-economy/02_gate1_precision_scan.R
Rscript studies/moral-economy/03_build_coding_sheet.R 1000
# → code private/coding_sheet.csv; save private/coding_sheet_ann{1,2,3}.csv
Rscript studies/moral-economy/04_iaa_validation.R
Rscript studies/moral-economy/build_calendar.R
```

## Gates (do not skip)

- **Gate 1 (after Stage A):** hand-code `private/gate1_precision_sheet.csv` (`econ_true`, `link_genuine`) → per-domain
  tagger precision. Re-run `02` to summarise. Feeds Q1 correction + H2 corrected denominators. The
  `croatian-nlp-reviewer` audit of `lexicon.R` happens here.
- **Gate 2 (before OSF prereg):** `04` reports register κ at 5-way and 3-way. Pre-declared fallback
  5-way → 3-way → binary; H1/H4 run at the first level clearing the prereg floor. If neither clears,
  H1/H4 → exploratory and the paper leans on the map.

## Dual-lens stages (PROPOSAL_v3; all ran 2026-08-04)

| Script | Stage | Reads | Writes | Master? |
|---|---|---|---|---|
| `sem_lib.R` | (shared module) | — | — | no |
| `05_s1_anchor_calibration.R` | S1 anchors | store, `stageA_candidates.rds` | `semantic/anchors.rds`, `anchor_diagnostics.csv` | no |
| `06_s2_corpus_scoring.R` | S2 scoring + gap audit | store, anchors | `scores_full.rds`, `coverage_ranking_v2.csv`, `gap_*.csv` | no |
| `07_s3_register_grid.R` | S3 grid | scores, anchors | `register_grid_{v0,v1}.csv`, `poverty_split_*.csv` | no |
| `08_build_gold_sheet.R` | V sheet | scores, anchors | `private/gold_sheet.csv` (blind), `private/gold_key.csv` | no |
| `09a_annotate_prep.R` | V batches | blind sheet | `private/batches/*.md` | no |
| `09b_iaa_validate.R` | V validation | 3 annotator files | `gate2_iaa.csv`, `gates.json`, `anchors_v1.rds` | no |
| `10_stage_c_analyses.R` | C figures | gates.json + all above | `output/figures/*.png`, `h4_shock_windows.csv` | no |
| `viewer_lib.R` | (shared module) | — | — | no |
| `11_gold_viewer.R` | (inspection) | gold sheet/key/core + `ann{1,2,3}/`, master (once) | `private/gold_viewer.html`, `private/gold_meta_cache.rds` | read-only, cached |
| `13_wta_viewer.R` | (inspection) | `scores_full.rds`, `lexicon.R`, master (once) | `private/wta_viewer.html`, `private/wta_sample_cache.rds` | read-only, cached |

`11` is an eyeball tool, not an analysis step: it renders the 555 gold posts as one local HTML page —
title linked to its URL, outlet/date/stream, the ±220 window, the 800-char coder excerpt, the full text,
and all three passes beside the majority verdict. Its output is **RESTRICTED** (row-level text, URLs,
outlet identities) and lives in gitignored `private/` — local viewing only, never committed or published.
The master is read READ-ONLY exactly once and cached to `private/gold_meta_cache.rds` (`--refresh-meta`
rebuilds); the run asserts `rid` really is the master row index by matching URLs against the 490 rids Stage A
recorded independently. Pause Dropbox for that first run.

`13` makes PAPER_v1 §6.5's "not credible" 55.5% inspectable: it re-derives the winner-take-all assignment
from `scores_full.rds` (asserting the total against `coverage_ranking_v2.csv`), samples 8 posts per domain ×
margin band, and attaches the decisive diagnostic — whether the post contains any `lexicon.R` economic
keyword for the domain the embedding assigned it. Both viewers share the HTML shell in `viewer_lib.R`.

Run order: `05` → `06` → `07` → `08` → `09a` → *(3 blind coding passes)* → `09b` → `07 --anchors=v1` →
`09b` (re-run, validates v1) → `10`. Note `07 --anchors=v1` **rescores** the corpus; swapping anchors
without rescoring silently reuses the v0 numbers. CLI flags need the leading dashes
(`digikat_cli_value` matches `--anchors`, not `anchors`).

`10` is **fail-closed**: it reads `gates.json` and refuses to plot any quantity whose pre-declared gate
failed. Two failed on this run (G-V4 retrieval precision, G-V7 poverty split) — see `PAPER_v1.md` §4.6.

## Not yet built (correctly deferred — depend on coded data)

- `05_analysis.R` (Stage C: domain×register grid, actor decomposition, HICP overlay reusing
  `../inflation-salience/output/hicp_hr.csv`, shock-window H4, H1 trend) — written after `coded_core.csv` exists.
- The coding runner itself (the 3-annotator LLM workflow against `private/coding_sheet.csv`) — the one genuinely
  from-scratch component (PLAN §0). Its output schema is fixed:
  `private/coding_sheet_ann*.csv` = the blind sheet + filled 7 axes.

## RSP paper stages (PROPOSAL_v5_rsp.md; 12–17 ran 2026-08-04, 19–25 the same day)

| Script | Stage | Reads | Writes | Master? |
|---|---|---|---|---|
| `cst_lexicon.R` / `cst_core.R` | (shared modules) | — | `private/cst_core.rds` | no |
| `12_cst_census.R` | corpus census | `corpus_prepared.rds` | `cst_census_*.csv` | no |
| `14_cst_core_profile.R` | descriptive profile | core | `cst_core_*.csv`, figures | no |
| `15_propose_source_labels.R` | outlet labels | core | `private/proposed_source_labels.csv` | no |
| `16_cst_viewer.R` | inspection HTML | core | `private/cst_viewer.html` (28 MB) | no |
| `17_cst_robustness.R` | 25 variants, gates G1/G1b/G2 | core, candidates | `cst_robustness_*.csv` | no |
| `18_gold_reanalysis.R` | re-analysis of the 555 gold set | `private/gold_core.csv` | `gold_*.csv` | no |
| **`19_r4_linkage_sample.R`** | **R4 sample** — 60 pairs × 11 domains, gold rids excluded | candidates, `corpus_prepared.rds` | `private/r4_{sheet,key}.csv`, `private/r4_batches/` | no |
| **`20_r4_recompute.R`** | **R4** — per-domain linkage precision + corrected gradient | `private/r4_ann1.tsv` | `r4_linkage_precision.csv`, `cst_gradient_adjusted.csv` | no |
| **`21_r1_precision_sample.R`** | **R1 sample** — 150 cards, era × outlet band | core | `private/r1_{sheet,key}.csv`, `private/r1_batches/` | no |
| **`22_r1_recompute.R`** | **R1/R2** — numerator precision vs. the pre-declared rule | `private/r1_ann1.tsv` | `r1_numerator_precision.csv`, `r1_precision_by_era.csv` | no |
| `rsp_labels.R` | (shared module) domain/term display names + RSP number formatting | — | — | no |
| **`24_rsp_figures.R`** | four print figures, greyscale/Arial/300 dpi | adjusted gradient, robustness detail, era table, core terms | `figures/rsp_fig{1,2,3,4}_*.png` | no |
| **`26_rsp_tables.R`** | the seven manuscript tables + every scalar the prose quotes | the `output/*.csv` above, gated core table | `tables/tab{1..7}_*.md`, `tables/rsp_derived.csv` | no |
| **`25_paper_checks.R`** | limits, decimal comma, table fragments intact, every number re-derived | `PAPER_RSP_v1.md`, `output/*.csv`, `tables/*` | — (aborts on mismatch) | no |

Tables are **generated, never typed**: `26_rsp_tables.R` writes each table as a markdown fragment and
`25_paper_checks.R` asserts the fragment still appears in `PAPER_RSP_v1.md` byte-for-byte, plus that
every scalar in `tables/rsp_derived.csv` is still printed somewhere in the text. Editing a number in the
manuscript by hand therefore fails the check rather than surviving it. Run order at the end: `24` → `26`
→ paste any changed fragment → `25`.

`19` and `21` only *draw* samples; the coding step is manual (or a blind model pass) and lands in
`private/r4_ann1.tsv` and `private/r1_ann1.tsv`. Both recompute scripts join the annotation to the
sheet **on `item` and assert the `rid` agrees** — a mis-keyed rid would silently attach a coding
decision to the wrong post and the wrong domain, and it caught two such errors on the first run.

## Reuse (from the machinery inventory)

- Religion lexicon: `R/religious_terms.R` (frozen) — tightened for economic homonyms inside `lexicon.R`.
- HICP: lift `../inflation-salience/output/hicp_hr.csv` (Eurostat, monthly 2021–25) — no re-acquisition.
- Coding schema mirrors the sister study's coded pool; the from-scratch part is the annotator instrument + IAA (built here as `04`).
