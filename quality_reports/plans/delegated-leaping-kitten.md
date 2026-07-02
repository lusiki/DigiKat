# Plan — Evolucija ekosustava: monthly volume/engagement, drop forecast-look on concentration chart

**Date:** 2026-07-02 · **Scope:** `pages/mapa/evolucija.qmd` only — no pipeline/aggregate change, no HARD GATE.

## Context

The PI flagged that the "Evolucija ekosustava" map's charts extend a dashed line from the last complete
year (2025) to an isolated point at 2026 — visually reading as a forecast/extrapolation, even though the
2026 point is actually real (partial-year) data. The fix: switch to monthly granularity where the data
already supports it, so the series simply ends at the real cutoff month with no dashing needed at all.

Investigation found `data/processed/platform_monthly.rds` already covers 2021-01–2026-06 (6 real months of
2026) across all 9 platforms — no pipeline change needed for the volume/engagement charts. But
`data/processed/source_summary.rds` (actor-level, used for the top-10 concentration chart) is year-only, no
month column — monthly there would need a new aggregate (edit + rerun `R/03_aggregate.R`, a separate HARD
GATE). Per your choice: monthly for volume + engagement now; concentration stays annual, but the misleading
dashed connector to 2026 is removed and 2026-to-date is shown as a separate, clearly-labeled real (not
forecast) marker.

## Changes to `pages/mapa/evolucija.qmd`

1. **`plot-rast` (Rast ekosustava)** — replace the annual `platform_summary`-based line/dash with a monthly
   line built from `platform_monthly$total_posts`, faceted by `main_platforms` as before. `scale_x_date(date_breaks
   = "1 year", date_labels = "%Y")`. No dashed segment — the line just ends at the real cutoff month
   (`cutoff_m`/`cutoff_lbl`, already computed in `setup`/`load-data`). Subtitle states "podaci do
   `cutoff_lbl`; zadnji mjesec može biti nepotpun." Headline growth KPI/prose stays anchored to
   `first_year`→`last_full_year` (a legitimate complete-year comparison) — only the chart's resolution changes.
2. **`plot-migracija` (Migracija angažmana)** — new inline monthly share, derived the same way
   `proportions_summary` derives shares, but from `platform_monthly` (`interaction_share = total_interactions /
   sum(total_interactions)` grouped by `month` after `complete(month, SOURCE_TYPE, fill = 0)`). This is a
   page-local `dplyr` transform like the existing `rast_data`/`conc_by_year`/`ritam` — not a new tracked file,
   consistent with "pages only read `data/processed/*.rds`". `geom_area` on `scale_x_date`, same yearly breaks.
3. **`plot-koncentracija` (Raspodjela utjecaja)** — stays on `conc_by_year` (annual, `source_summary` has no
   month column). Trend line/points restricted to `year <= last_full_year` (2021–2025), solid, no dashing.
   The real 2026-to-date value (already computable the same way the code computes it today) is plotted as a
   separate, visually distinct, **unconnected** marker (different shape, own data label reading e.g. "2026.
   (do lipnja, nepotpuno)") — real data, explicitly not part of the trend line.
4. **Top callout ("Kako čitati ovu mapu")** — currently documents the old "iscrtkano" (dashed) convention;
   rewrite that sentence to describe the new one (monthly charts simply end at the real cutoff; the
   concentration chart shows 2026 as a separate, non-comparable real point).
5. **Section intros + captions** — add one framing sentence each to the Rast/Migracija sections explaining
   *why* they're monthly now (shows real 2026-to-date data instead of an annual placeholder), and one to the
   Raspodjela section noting it stays annual (actor-level data limitation) with 2026 shown separately. Update
   captions that reference "Godina 2026. nepotpuna je" / dashed-segment language to match the new visuals.
6. **Findings prose after Raspodjela chart** — optionally add one sentence reporting the real 2026-to-date
   top-10 share (already derivable from `conc_by_year`), explicitly framed as partial/non-comparable — this
   directly demonstrates "real data, not forecast" per the request.
7. No changes to "Godišnji ritam objavljivanja" (already monthly-based, already excludes 2026) or to the KPI
   grid (already anchored to complete years).

## Style-guide compliance for new prose
Follow the just-updated `.claude/rules/voice-and-style.md` §8: ≤1 em dash per paragraph, never an em dash +
semicolon together — split into plain sentences instead. All new numbers via the existing `fmt_int`/`fmt_pct`/
`fmt_x` helpers already defined in the page's `load-data` chunk, never hand-typed. En dash for ranges only.

## Verification
No master/aggregate touch — `data/processed/*.rds` must be byte-identical before/after (checksum). Render
`pages/mapa/evolucija.qmd` alone from the repo root (off-PATH R 4.4.1 + RStudio-bundled Quarto per
`CLAUDE.local.md`): rc=0, no chunk errors, all 4 figures present (`plot-rast`, `plot-migracija`,
`plot-koncentracija`, `plot-ritam`), literal Croatian diacritics, no output scatter outside `docs/`. Do not
commit/push until asked (matches this session's established rhythm of separating edit-and-verify from
publish).
