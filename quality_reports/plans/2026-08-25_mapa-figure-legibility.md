# Plan — fix figure legibility on the five `pages/mapa/*` pages

**Date:** 2026-08-25 · **Trigger:** PI reported that the charts "look terrible" in a desktop browser
while looking acceptable on a phone.

## Diagnosis (measured, not inferred)

The figures are `svglite` SVGs embedded as `<img class="img-fluid" width="1200">`. The SVG canvas is
`fig.width × 72` user units (720 units for a 10-inch figure) and the browser scales it to the content
column, which measures ≈760 CSS px on a 1440-px-wide laptop. On-screen text size is therefore

```
on_screen_px = font_size_pt × (760 / (fig_width_in × 72))
```

Two independent defects were confirmed.

### Defect 1 — text is up to 1.85× oversized, and clips (dominant, this plan fixes it)

Fourteen chart chunks call `theme_digikat(base_size = 24)` on a 10-inch canvas. That renders axis text
at 18,72 units ≈ **19,5 CSS px** and plot titles at 36 units ≈ **37,5 CSS px**, against a body text of
16 px. Nine other chunks use `base_size = 16` on the same canvas and land at ≈13 px, which reads
correctly. The site therefore has no consistent figure scale at all, and the range across 23 figures is
8,9 px to 19,5 px.

Because ggplot never shrinks a title to fit, the oversized text overflows the device. Measured on the
committed SVGs, **18 of 23 figures** carry oversized text and/or at least one text run wider than the
whole canvas, which the device then truncates. Verified examples on `plot-volume-1.svg`
(canvas 720 units wide):

| element | textLength | outcome |
|---|---|---|
| title `Broj objava po platformama (2021.–2026.)` | 710 units | overflows, clipped mid-parenthesis |
| caption `Napomena: Platforme su …` | 1 049 units | clipped at "Novije platforme (Insta" |
| bar value labels | — | clipped at panel edge (`52.4` for 52.405) |
| y-axis platform labels | — | collide vertically in the 2024–2026 panels |

This is why a phone looks acceptable: the figure scales to ≈390 px there, so the same defects are
present but too small to notice.

### Defect 2 — the theme's three typefaces all fall back to Arial (reported, NOT fixed here)

`systemfonts::match_font()` resolves **Source Serif 4, Source Sans 3 and IBM Plex Mono all to
`arial.ttf`** on this machine — none of the three is installed. `theme_digikat.R` deliberately skips
`showtext` for SVG output so the browser can use the page's web fonts, but an SVG referenced through
`<img>` is an isolated document and cannot inherit page CSS. `svglite` therefore both measures and
writes `font-family: "Arial"`, and every chart loses the serif-title / mono-numeral / sans-body system.
Arial is also wider than Source Sans 3, so it worsens Defect 1.

## Decision — scale the canvas, do not touch `base_size`

Each oversized chunk couples three hand-tuned numbers, e.g. `plot-volume`:
`theme_digikat(base_size = 24)`, `strip.text = element_text(size = 22)`, `geom_text(size = 5.5)`.
Lowering `base_size` alone would leave the value labels and strip labels larger than the axis text.
Re-tuning all three in fourteen chunks is high-risk hand work.

Scaling `fig-width`/`fig-height` by the same factor changes **only** the ratio of text to canvas and
preserves every internal proportion exactly. Applied factor:

```
k = base_size / 15.5   ->   k = 1.55 for the base_size-24 chunks
```

The rule this establishes, to be recorded in `MEMORY.md`: **canvas width in inches ≈ base_size × 0,645**,
so that on-screen text lands at 12–13 px in the site's content column. Chunks already at
`base_size = 16` / 10 inches satisfy it and are left untouched.

## Steps

1. Scale `#| fig-width:` / `#| fig-height:` by 1,55 in the chart chunks that use `base_size = 24`
   (14 chunks across the five pages). Inspect `git diff` before rendering.
2. Re-render the five pages individually from the repo root. Never a full site render (HARD GATE).
3. Re-measure every emitted SVG with the calibration script: require **zero** text runs wider than the
   canvas and a modal on-screen size of 11–14 px.
4. Screenshot `mapa.html` at 1440 px and read it back to confirm visually.
5. A second pass for outliers the measurement flags in the other direction — `plot-shares` (9,5 px) and
   `plot-polarization-by-topic` (8,9 px) are currently too small.
6. Verify no `data/processed/*.rds` mutation, then commit.

## Rejected alternatives

- **Normalize `base_size` to 16.** Better long-term style, but needs the coupled `strip.text` and
  `geom_text` sizes re-tuned in every chunk by hand. Rejected as regression-prone for a cosmetic fix.
- **Widen the site content column.** Would enlarge every figure but leaves the internal clipping
  (a 1 049-unit caption in a 720-unit canvas) untouched, and changes the reading measure of all pages.
- **Fix the fonts in the same pass.** Installing or vendoring Source Sans 3 / Source Serif 4 /
  IBM Plex Mono changes text metrics and would confound the size calibration. It is a separate change
  and a PI decision (it adds ~1 MB of binary assets under an SIL OFL licence). Reported, not done.

## Outcome (2026-08-25, executed)

| measure | before | after |
|---|---|---|
| figures with oversized text or canvas-wide clipping | 18 of 23 | **0 of 23** |
| text runs clipped by their panel | 10 (of 54 raw hits, 44 false) | **0** |
| on-screen axis text | 8,9–19,5 px | 10,7–13,0 px |
| on-screen plot title | 20,3–37,5 px | 20,6–25,0 px |

Beyond the planned canvas scaling, the render exposed four defects the measurement then drove out.

1. Five in-plot captions and six titles were longer than any sane canvas and were wrapped with `\n`.
2. `plot-volume` and `plot-interaction` lacked the `expand_limits()` headroom every other bar chart on
   the pages already had, so the longest bar's value label was cut by the panel. 2025 web read `6`
   instead of `67.198`. Factors 1,22 and 1,45 respectively.
3. `plot-lollipops-interactions` and `plot-actor-map` each carried three per-panel size legends that
   overlapped and ran off the canvas. Dropped via `scale_size_continuous(guide = "none")`; both
   subtitles already state what point size encodes. **Editorial call, reversible.**
4. The lollipop panels leave only ~200 units of plotting area each, so the axis title was shortened to
   `Interakcije\nu tisućama` and the ticks set to `n.breaks = 3` at 45° with smaller `axis.text.x`.

Not done, reported instead: the Arial font fallback (Defect 2 above) and the space-vs-period thousands
separator in axis labels. Both are recorded in `MEMORY.md`.

## Guard rails

- `data/processed/manifest.json` `input.sha256` already matches the corpus manifest, so
  `digikat_assert_aggregates_current()` passes and the pages can render.
- Pages render one at a time from the repo root. A full `quarto render` is not performed.
- No change to any chart's data, geometry, colour or text content. Sizes only.
