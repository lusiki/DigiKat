# Plan: merge the three exploration reports into one „Kako se govori o katoličanstvu”

Date: 2026-08-19 · Status: completed

## Goal
One report, one folder, one `analysis.R`, one `index.html`, six chapters, 9 figures + 1 table, that tells
the Croatian Catholic digital media story end-to-end for a general reader. The two continuations
(`glas-crkve-prototype`, `pogled-izvana-prototype`) are absorbed, not linked.

## Why (assessment summary)
- The event story was told three times (flagship Fig 4 + Table 1, glas Fig 1, pogled Fig 3), and glas Fig 1
  and pogled Fig 3 were the same finding measured with two different definitions of "the outside"
  (group 4 vs a 70-brand curated web panel): 89 % vs 86 % for the Pope's death.
- Two topic instruments that looked alike: 5 unvalidated frames (flagship) vs 16 canonical categories → 6
  themes (pogled).
- Flagship verdict contradicted its own computation: `Tone status: worse` (post-2024 RIK slope +0,60
  [0,07; 1,13]) but a hard-coded "a njegov se ton ne zaoštrava" in the title.
- "⅓ → ⅕" headline straddled the 2024 collection seam; within-era slopes are the defensible version.

## Decisions recorded (PI, 2026-08-19)
1. Frames survive only as binary "sharp / not sharp" (political + conflict vs rest). "What" is measured by
   the canonical 16-category dictionary collapsed to 6 themes (mapping from pogled).
2. "The outside" = group 4 „Ostali mediji i javni izvori” everywhere. `secular_outlets.csv` panel kept only
   as a diagnostic CSV.
3. `i1_status` must drive the verdict title. No hard-coded tone claim.
4. One folder: `explorations/okvir-katolicanstva-prototype/` absorbs the other two; `_okvir_engine/okvir_lib.R`
   stays the shared engine; the two continuations move to `explorations/ARCHIVE/`.

Defaults unless PI objects: Ch 2 themes on full corpus, all platforms, posts with text (first 3 000 chars),
web-only split as diagnostic CSV; Ch 3 heatmap = 6 themes × 4 groups on the 15 % sample (cells < 20 posts
unreportable); rhythm model and event-arc procedure reused verbatim.

## Target structure
| Ch | Question | Figures | Data |
|---|---|---|---|
| 0 | Hero + verdict | generated title + summary | i1/i2/i3 status |
| 1 | Tko govori? | F1 posts vs reactions by group & period | actor_period |
| 2 | O čemu se govori? | F2 six themes × four groups; F3 eight largest category gaps (group 4 vs Catholic circle) | theme_by_actor, category_gap |
| 3 | Kako se govori? | F4 sharp share posts vs reactions by group; F5 tone/RIK themes × groups | sharp_by_actor, tone_rik_by_theme_actor |
| 4 | Kada se govori — i tko tada? | F6 daily-peak calendar; T1 largest arcs; F7 composition of 8 biggest peaks; F8 rhythm change by group | event_arcs, event_composition, rhythm_effects |
| 5 | Mijenja li se što? | F9 church-media web share by half-year | trend_estimates |
| 6 | Što to znači | synthesis + ≤2 capability-register sentences | scalars |

Pogled Fig 3 dropped (F7 is the same finding under the agreed definition).

## Work steps
0. Freeze: copy each current `output/` summary + CSVs to `explorations/ARCHIVE/2026-08-19_pre-merge/{okvir,glas,pogled}/`;
   flagship `actor_totals.csv` = reconciliation anchor.
1. Engine: add theme map/labels/colors + `classify_themes()` wrapper with private cache; `sharp_frame()`;
   move `fit_rhythm()` + calendars into `_okvir_engine/registry/`; verdict built from `i2_status × i1_status`.
2. `analysis.R` sections: 01_corpus (assert anchor) · 02_events (+composition, +rhythm) · 03_themes
   (+diagnostics incl. panel) · 04_text_measures (binary sharp, themes on sample) · 05_trends (within-era) ·
   06_verdict · 07_write (disclosure gate).
3. Page: six chapters; port 2 renderers from glas, 2 from pogled; delete five-frame UI; bridge sentences;
   house voice; method at bottom + link to metodologija.
4. QA: qa-browser (9 figures + 1 table, no empty charts, no JS errors, no overflow, screenshots); disclosure
   scan of public output; diacritics; reconciliation vs Step-0 copies.
5. Archive: move the two continuation folders under `ARCHIVE/` with `ARCHIVED.md`; update READMEs.
6. Verify: run build-15pct (if stale) → analysis.R → qa-browser; report verdict, headline numbers,
   reconciliation, screenshots.

## Guardrails
Corpus & `data/processed/` read-only; no AUTHOR/URL read; row-level only under `output/private/`; no
hand-typed numbers; no change to `R/lib/thematic_dictionaries.R` or inclusion rule; nothing in
`_quarto.yml`/`docs/`; run from repo root; pause Dropbox for the theme pass.

## Acceptance
One folder/script/page; verdict title responds to statuses (stub-tested); one topic vocabulary + one
outside on the page; all figures render from data; qa green; disclosure clean; diacritics intact;
`actor_totals`, `event_arcs`, `rhythm_effects` reproduce Step-0 byte-for-byte.

## Risks
Theme recognition weaker on short social posts → print recognised share per group; fallback to web-only
for F2/F3 if < ~60 %. Verdict may now say conflict vocabulary slightly denser since 2024. Abuse theme
mostly unreportable in heatmap (greyed, not hidden).

## Rejected alternatives
Three linked pages; keeping the curated panel alongside group 4; themes on the 15 % sample only for Ch 2.
