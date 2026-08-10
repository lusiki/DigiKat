# Plan — DigiKat annual report, reporting year 2024

**Date:** 2026-08-10 · **Owner:** PI (Luka Šikić) · **Status:** approved, in build

## Goal

Produce the 2024 edition of the annual report (`DigiKat_godisnji_pregled_2024.{html,pdf}`) through the
same governed chain that produced edition 1 (reporting year 2025), without changing edition 1's
outputs.

## PI decisions taken before the build (2026-08-10)

1. **Framing:** full "Godišnji pregled 2024." — same anatomy and title form as edition 1. The coverage
   break is disclosed in the methods box and drawn on the year line, not used to retitle the product.
2. **Rotating special chapter:** `studies/inflation-salience` (replaces `studies/moral-economy`, which
   the 2025 edition used). Its window is 2021–2024 and 2024 is its repricing peak.

## What 2024 actually is (measured, not assumed)

| Fact | Value |
|---|---|
| Corpus posts in 2024 | 56 923 |
| Calendar days | **366** (leap year) |
| Collected days | **207** |
| Interruption 1 | 9 Jan – 31 May 2024 (144 days) — contains **Easter, 31 March** |
| Interruption 2 | 16 – 30 Sept 2024 (15 days) |
| H1 (pre2024 stream) | 6 710 posts / 38 collected days |
| H2 (post2024 stream) | 50 213 posts / 169 collected days |
| Attention arcs (z ≥ 3) | 2 — {24–25 Dec} and {15 Aug}; both fixed feasts |
| Distinct sources | 3 398 |
| NLP layers | 2 839 theme docs, 1 134 tone docs |

Consequence: **2024 has no instrument-comparable year-over-year movement.** The post-2024 stream
begins 2024-07-01, so H2 2023 sits on the far side of the seam. Edition 1's single comparison
(H2 2024 vs H2 2025) has no 2024 counterpart.

## Design decisions

- **Do not fork the study.** Nothing under `studies/annual-report/` is git-tracked yet, so the chain is
  parameterised by reporting year instead of copied. Outputs move to `output/<year>/`; edition 1 is
  re-run afterwards to prove it still reproduces.
- **Stream chapter, 2024 mode.** Since no year-over-year comparison exists, the recurring slope-chart
  FORM is preserved by comparing **Q3 2024 → Q4 2024 inside the post-2024 stream**, measured in
  **posts per collected day** so the 15-day September interruption cannot masquerade as growth, with
  the distinct-source count beside it. Prose and caption state plainly that this is a within-year
  movement spanning Advent and Christmas, not a year-over-year change. A gap panel records that the
  year-over-year measure does not exist for this edition.
- **Event naming** moves from a hard-coded four-label vector to a per-edition registry keyed by date.
  2024's arcs are Božić (24–25 Dec) and Velika Gospa (15 Aug). The report states that **Easter 2024
  falls inside the collection interruption** and is therefore absent from the data — the year's largest
  Catholic event is unmeasured, and saying so is not optional.
- **Summary:** ten findings, one generated number each. Edition 1's Pope-Francis finding becomes the
  Christmas peak; edition 1's stream-change finding is replaced by the collected-days coverage finding
  (the stream change stays in the chapter body, out of the headline, because of the seasonal confound).

## Work items

1. `report_lib.R` — `AR_REPORT_YEAR` from env `AR_YEAR` (default 2025); `AR_OUT = output/<year>/`;
   leap-aware `AR_CALENDAR_DAYS`; `AR_STREAM_MODE` derived from the corpus manifest's era spans;
   per-edition event registry, special-chapter config, and template path.
2. Migrate edition 1's outputs to `output/2025/`.
3. `00_data_readiness.R` — `report_year_months` becomes a measured WARN, not a 12-month FAIL.
4. `01_report_aggregates.R` — leap calendar; generic private filenames; two-mode stream aggregate with
   generic column names (`base_*` / `report_*` / `unit`).
5. `03_report_assets.R` — generic stream figure/table; event registry; year-branched tiles, summary,
   press release, fig03/fig04 captions; inflation-salience special chapter.
6. `05_report_checks.R` — `AR_CALENDAR_DAYS`; baseline-year-derived honesty guards.
7. New `REPORT_TEMPLATE_2024.qmd` (prose + tokens only).
8. Run the 2024 chain end to end; run the disclosure screen; re-run the 2025 chain and confirm it is
   unchanged.
9. Update `README.md`, `PIPELINE.md`, `GAPS.md`, `CHARTER.md`, `MEMORY.md`.

## Protected paths — unchanged by this work

`data/merged_comprehensive.rds`, `data/digikat_corpus.rds`, `data/processed/`, `data/nlp/`, `docs/`,
`_quarto.yml`. The chain writes only below `studies/annual-report/output/`, and stage 06 fingerprints
`docs/` before and after the render.

## Rejected alternatives

- **Fork into `studies/annual-report-2024/`** — duplicates 3 565 lines and makes every future edition
  a new copy; the divergence would be invisible at review time.
- **Retitle as a partial-year retrospective** — considered and put to the PI, who chose the full annual
  framing. The coverage facts are carried in the methods box and on the year line instead.
- **Skip the "Gdje se razgovor seli?" chapter** — would break the recurring canon the charter promises.
- **Compare 2024 to 2023** — crosses the collection seam; the checks script blocks it by design.
