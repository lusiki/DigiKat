# The News Gap, Catholic edition

- **Slug:** `news-gap`
- **Owner:** DigiKat
- **Status:** provisional outlet profiles published by PI decision; manual topic validation pending
- **Created:** 2026-08-13

## Research question

What is the difference between the thematic mix Catholic editorial products publish and the thematic mix their audiences reward, and does the following month's supply move toward the topics that received an engagement premium?

## Corpus slice

- Platform: web only.
- Products: HKM, IKA, HKR, Laudato, Bitno.net, and Glas Koncila, defined in `source_registry.csv` by source label and URL host.
- Main descriptive window: seven complete months of calendar 2025 (February, June-August, and October-December). January, March, April, May, and September are excluded because primary-source collection has multi-day outages or a half-month gap.
- Main lagged window: July 2024 through December 2025 engagement, excluding incomplete September 2024 and January, March, April, May, and September 2025; January 2026 is used only as a next-month production outcome. Transitions never bridge an excluded month.
- Historical consistency check: the separate 2021-2023 collection stream (four products but only two organizations). It is never pooled with the main era and is not an independent replication.
- Topics: the canonical 16-category dictionary in `R/lib/thematic_dictionaries.R`.

## Method

Non-editorial home, listing, archive, and pagination captures are removed before classification. Each article is scored from its title plus the first 3,000 body characters using the canonical dictionary. A unique topic winner receives one unit; tied winners split it equally. The production vector is the share of classified post mass in each topic. The recorded-reward vector applies the same assignments to recorded interactions. Their difference, in percentage points, is the news gap. Half the sum of absolute topic gaps is the total distance between the two vectors. Full-page text is retained as a sensitivity specification.

The main panel model is:

`next production share ~ current gap + current production share + product-by-topic fixed effects + topic-by-month fixed effects`

The coefficient therefore measures whether a product shifts next month's supply toward a topic that overperformed relative to that product's own mix, compared with other products covering the same topic in the same month. Uncertainty is time-HAC by month and is checked with an IID whole-month cluster bootstrap, winsorized interactions, removal of each product-month's top post, change scores, full-text classification, and leave-one-product/organization-out estimates. The newer-era panel has very few usable current months, so inference is explicitly exploratory and associational.

This is an exploratory dictionary-based study. The canonical dictionary contains several broad stems, and the first audit sample shows clear face-validity failures in some categories. Every finding remains provisional. By PI decision on 2026-08-13, the outlet profiles may appear as an editorial diagnostic in `Moj medij` before validation, but they must not be described as human-validated rankings or direct audience-preference measures. The flagship pools retained months within each product, then gives the six products equal weight; it does not give each product-month equal weight. The script writes the private stratified sample, separate answer key, and high-interaction audit needed for review without changing the global dictionary.

## Outputs

- `FINDINGS.md`: concise interpretation, limits, and decision status.
- `output/gap_overall.csv`: disclosure-safe field-level produced and rewarded vectors.
- `output/outlet_profiles.csv`: broad product summaries with robustness columns; named topics are validation leads, not rankings, without a public product-month-topic panel.
- `output/event_results.csv`: aggregate weekly coverage and the explicit finding that the papal-transition contrast is not estimable from this snapshot.
- `output/lag_model.csv`: main and robustness model estimates.
- `output/diagnostics.csv`: coverage, classification, and sensitivity diagnostics.
- `output/figures/`: annual-report-ready charts.
- `output/analysis_results.json`: machine-readable numerical authority.
- `output/manifest.json`: input, code, parameter, and output hashes.
- `output/intermediate/`: exact analytical panels (gitignored).
- `output/private/`: row-level, prediction-free coding sheets plus hidden answer keys and audit coverage (gitignored).
  It also contains private review copies of the six-product vectors and charts. The publication-gated
  aggregate used by `Moj medij` is `output/outlet_topic_profiles.csv`.

## Run

From the repository root:

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --vanilla studies/news-gap/analysis.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --vanilla studies/news-gap/checks.R
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --vanilla R/check_disclosure.R
```

## Private `Moj medij` preview

The outlet charts can be reviewed locally without putting provisional values in `data/page-ready/`
or `docs/`. From the repository root, run:

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --vanilla R/06_moj_medij.R --preview-news-gap --write-preview
$env:DIGIKAT_NEWS_GAP_PREVIEW = '1'
& 'C:\Program Files\Quarto\bin\quarto.exe' render pages/moj-medij.qmd --output-dir studies/news-gap/output/private/moj-medij-site-preview
Remove-Item Env:\DIGIKAT_NEWS_GAP_PREVIEW
```

Open `studies/news-gap/output/private/moj-medij-site-preview/pages/moj-medij.html` and search for
HKM, IKA, HKR, Laudato, Bitno.net, or Glas Koncila. The preview directory and its data are gitignored.

## Declarations

- Data availability: see `/DATA_AVAILABILITY.md`.
- AI-use disclosure: OpenAI Codex assisted with analysis design and implementation; all interpretive claims require researcher review.

## Log

- 2026-08-13 — study registered; source/product boundaries and engagement measurement break audited.
- 2026-08-13 — analysis pipeline implemented and run against the official corpus snapshot.
- 2026-08-13 — PI authorised provisional publication of the six product profiles in `Moj medij` while manual validation remains pending.
