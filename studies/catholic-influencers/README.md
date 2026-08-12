# Study: Katolički influenceri i institucionalni deficit pažnje

- **Slug:** `catholic-influencers`
- **Owners:** Suzana Obrovac Lipar and Luka Šikić
- **Status:** analysis
- **Created:** 2026-08-12

## Research question

How is recorded digital attention distributed among high-confidence Catholic creator sources, and
do creator-layer sources attract more interactions per post than official Church communicators when
the comparison is restricted to a platform shared by both groups?

## Corpus slice

- Platforms: web, YouTube, Facebook, Twitter/X, Reddit, forum, comment and Instagram
- Terms/theme filter: official DigiKat inclusion rule; no study-specific corpus filter
- Date range: 2021-01-01 through 2026-06-11; 2026 is partial
- Sample: full official corpus; TikTok is excluded because the inherited actor classifier was not
  defined for it and the official corpus contains only 197 TikTok observations

## Method

The primary analysis uses only source labels assigned by manual rules or unambiguous institutional,
diocesan, parish and priest patterns. Broader devotional-name classification is retained as a
sensitivity analysis. The study reports source-level concentration, a within-YouTube comparison with
HC3 robust uncertainty, post- and source-weighted platform profiles, a six-family multi-label theme
dictionary with source bootstrap intervals, and an exploratory model within the creator layer. The
rank-size fit is descriptive rather than a formal power-law test. “Interactions per post” is a vendor
snapshot, not an audience-normalized engagement rate, and platform effects are not estimated where
the data lack common support.

## Reproduction

From the DigiKat repository root, with the restricted official corpus present:

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/catholic-influencers/analysis.R
& 'C:\Program Files\Quarto\bin\quarto.exe' render studies/catholic-influencers/PAPER.qmd
```

The analysis verifies the corpus SHA-256 against `data/digikat_corpus_manifest.json`, writes only
aggregate/public outputs under `output/`, and writes account-name audit tables to the gitignored
`output/private/` folder.

## Outputs

- `output/analysis_input_manifest.json` records the exact corpus and code input.
- `output/analysis_results.json` is the single numerical source for the manuscript and profile page.
- `output/tables/` and `output/figures/` contain disclosure-reviewed aggregates.
- `output/private/` contains account-level classification audit material and is never published.
- The published profile is `pages/studije/katolicki-influenceri.qmd`.

## Declarations

- Data availability: see `/DATA_AVAILABILITY.md`.
- AI-use disclosure: Codex was used to audit, adapt and execute the analysis pipeline and to revise
  the manuscript under author review.

## Log

- 2026-08-12 — Recovered source revision `fa34ff5`, moved the study to the official corpus, corrected
  implementation errors, added provenance and robustness checks, and regenerated the manuscript.
- 2026-08-12 — Journal-manuscript pass: added an English abstract, a deliberately minimal theory
  section (left compact for co-authors to expand), a sample-composition table, a theme-distribution
  table and a robustness table, expanded results and discussion, and removed all working-paper meta
  material (file paths, reproduction commands, hash checks, visible code folds) from the manuscript.
- 2026-08-12 — Publication-readiness pass made the high-confidence classifier primary, replaced the
  pooled platform adjustment with a within-YouTube comparison, added robust and bootstrap intervals,
  removed the unidentified primary-platform coefficient, expanded limitations and regenerated all
  manuscript formats. The literature section was intentionally left unchanged.
