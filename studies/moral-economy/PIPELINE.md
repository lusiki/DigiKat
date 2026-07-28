# moral-economy — pipeline (scripts → plan stages)

**Status:** scripts written + self-validated (2026-07-07); Stage A **not yet run** on the master.
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

## Not yet built (correctly deferred — depend on coded data)

- `05_analysis.R` (Stage C: domain×register grid, actor decomposition, HICP overlay reusing
  `../inflation-salience/output/hicp_hr.csv`, shock-window H4, H1 trend) — written after `coded_core.csv` exists.
- The coding runner itself (the 3-annotator LLM workflow against `private/coding_sheet.csv`) — the one genuinely
  from-scratch component (PLAN §0). Its output schema is fixed:
  `private/coding_sheet_ann*.csv` = the blind sheet + filled 7 axes.

## Reuse (from the machinery inventory)

- Religion lexicon: `R/religious_terms.R` (frozen) — tightened for economic homonyms inside `lexicon.R`.
- HICP: lift `../inflation-salience/output/hicp_hr.csv` (Eurostat, monthly 2021–25) — no re-acquisition.
- Coding schema mirrors the sister study's coded pool; the from-scratch part is the annotator instrument + IAA (built here as `04`).
