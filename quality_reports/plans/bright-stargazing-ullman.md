# Plan — Align Mapa-page ggplot figures with the DigiKat design system

**Date:** 2026-06-30 · **Scope:** the 4 analytical pages (`pages/mapa/*.qmd`) + `R/theme_digikat.R`
**Type:** cosmetic refactor (figure theming only) — no data, corpus, or prose-logic changes.

## Context

The user noticed the ggplot figures on the four Mapa pages do not follow the page design
(petrol accent · cream paper `#F5F4F0` · white panel · brand palette · Source Serif/Sans/Mono fonts).

Root cause — a shared `theme_digikat()` **already exists** ([R/theme_digikat.R](../../R/theme_digikat.R)),
is sourced on all 4 pages, and is set as the global default. The figures look off **only because
individual plots override the theme** with off-design choices. This is an override-cleanup +
centralization job, not a theme rebuild.

**Confirmed design decisions (user):**
- Figure backgrounds → **cream, blended** (remove the white overrides; let the theme's cream paper +
  white plotting panel show — figures dissolve into the page).
- Platform colors → **harmonized to the brand palette** (web=petrol, YouTube=brick red, Facebook=blue,
  …), centralized in the theme file.

## Inventory of deviations (what's overriding the theme)

| Page | Lines | Off-design element | Fix |
|---|---|---|---|
| mapa | 195–199 | `platform_colors` = Tableau hexes | → reference centralized `dk_platform_colors` |
| mapa | 221, 261 | `geom_text(color="black")` | → `dk_col$ink` |
| mapa | 364, 423–424 | `geom_segment/vline/hline(color="grey"/"grey70")` | → `dk_col$faint` |
| mapa | 378–380, 437–439 | hard-coded `"#1f77b4"`/`"#d62728"`/`"#3b5998"` | → `dk_platform_colors[["web"]]` etc. |
| mapa | 417 | `theme_void()` (no-data fallback) | → `theme_digikat_void()` |
| mapa | 325, 387 | patchwork blocks w/ no canvas bg | → add `& theme(plot.background = cream)` |
| mapa | 447 | patchwork canvas `fill="white"` | → cream `dk_col$paper` |
| mapa_stats | 238 | wordcloud `brewer.pal(8,"Dark2")` | → `dk_palette` |
| mapa_stats | 300, 339 | fills `"#0072B2"` (Okabe blue) | → `dk_col$accent` |
| mapa_stats | 375–377 | `firebrick`/`steelblue`/`grey` polarization | → `dk_col$neg`/`dk_col$pos`/`dk_col$faint` |
| mapa_stats | 434 | `scale_fill_viridis_d()` | → `scale_fill_digikat()` |
| mapa_stats | 445, 448 | `color="gray40"`, grid `"#f0f0f0"` | → `dk_col$muted`, `dk_col$grid` |
| mapa_stats | 477–480 | network `lightblue`/`darkblue` + `theme_void()` | → `dk_col$accent_200`/`accent` + `theme_digikat_void()` |
| diskurs | 300–301 | heatmap text `"black"` + `firebrick/steelblue` | → `dk_col$ink` + `scale_fill_digikat_diverging()` |
| diskurs | 380 | jitter `color="darkred"` | → `dk_col$accent` |
| diskurs | 511–514 | network `"black"` nodes/text, `firebrick/steelblue` edges, `theme_graph()` | → `dk_col$accent`/`ink`, diverging edge colors, `theme_digikat_void()` |
| događaji | 343–356 | spike lines `"grey"`, points/threshold `"red"` | → `dk_col$faint` + `dk_col$alert` |
| događaji | 425–429 | line `"grey"`, event line `"black"`, `firebrick/steelblue` | → `dk_col$faint`/`ink` + `scale_color_digikat_diverging()` |
| događaji | 497 | `firebrick/steelblue` fill | → `scale_fill_digikat_diverging()` |

## Implementation

### 1. Extend `R/theme_digikat.R` (single source of truth — every page already sources it)
- Add `accent_300`/`accent_200` and semantic tokens to `dk_col`:
  `pos = "#2F73B8"` (blue, keeps prose "plave nijanse" valid), `neg = "#B5462F"` (brick, keeps "crvene"),
  `neutral = "#F0ECE3"` (cream mid), `alert = "#B5462F"`, `faint`/`line` already present.
- Add `dk_platform_colors` named vector (web/youtube/facebook/twitter/reddit/forum/comment/instagram/tiktok),
  all drawn from the brand palette.
- Add diverging scales reusing the tokens:
  `scale_fill_digikat_diverging()`, `scale_colour_digikat_diverging()`, `scale_color_digikat_diverging()`
  (wrap `scale_*_gradient2(low=neg, mid=neutral, high=pos, midpoint=0, ...)`).
- Add `theme_digikat_void(base_size)` — `theme_digikat()` with panel/axes blanked but the **cream
  plot.background and serif title/subtitle/caption kept** (for ggraph networks + the no-data fallback).

### 2. Edit each page per the table above
Minimal, surgical edits — keep existing per-plot `theme()` add-ons (legend position, strip sizes, angled
axis text) intact; only swap the off-design colors/backgrounds and the two `theme_void()`/`theme_graph()`
calls. Where the diverging scale's color is described in prose ("plave/crvene nijanse"), the blue=+/red=−
mapping is preserved, so **no prose edits are needed**.

## Verification

1. **Theme file (cheap, no data):** run `Rscript` to `source("R/theme_digikat.R")` then build a dummy
   `ggplot` exercising `theme_digikat_void()`, `scale_fill_digikat_diverging()`, `dk_platform_colors`,
   `scale_fill_digikat()` → must produce a plot object with no error (confirms syntax + symbols resolve,
   showtext fonts fall back gracefully).
2. **Static check** of every edited chunk: balanced parens/quotes, diacritics intact (UTF-8), no orphaned
   reference to a removed symbol; grep the 4 pages for residual off-design literals
   (`firebrick`, `steelblue`, `viridis`, `Dark2`, `"#0072B2"`, `"#1f77b4"`, `fill = "white"`, `theme_void`).
3. **Render-verify** the touched pages from the **repo root** (per quarto rule §8). Hazards to respect:
   pause Dropbox sync first; `mapa.qmd` writes `data/processed/*.rds` mid-render → after it renders,
   `git checkout -- data/processed/` to drop that side-effect and confirm `git status` shows no stray
   scatter and no `docs/` wipe. If a heavy page can't be rendered safely here, hand it off with the exact
   command. (`freeze: auto` will re-execute the R chunks since the source changed.)
4. **Design-consistency review:** a short adversarial pass (per-page) confirming every figure now resolves
   its colors/background through `theme_digikat` / the new tokens — no remaining hard-coded off-design value.

## Out of scope / preserved
- No prose rewrites, no corpus/data changes, no `R/03_aggregate.R` run, no full-site `docs/` overwrite.
- Per-plot functional `theme()` tweaks (legend position, facet strip sizing, angled tick labels) are kept.
