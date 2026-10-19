# Plan — make the five mapa pages' figures impeccable (2026-10-19)

Status: DONE 2026-10-19. PI decisions: drop the Love/Angry chart; Stepinac needs a fast minimum
number of texts; keep the title in the image and a one-line source caption; filter generic words
at page level; commit on the current branch and fast-forward main.

Outcome: all 22 charts redrawn and checked by eye at desktop and phone width. Stepinac now reads 60
texts a year from the full corpus (`R/07_stepinac_terms.R`). Two latent bugs in
`R/lib/digikat_charts.R` fixed (phone export mutated desktop text; NULL axis labels became variable
names). The suspected phone overflow was a screenshot artefact, not a page defect. Aggregates and
the three NLP page summaries are byte-identical to before.

## Scope
`pages/mapa/{mapa,mapa_stats,diskurs,događaji,evolucija}.qmd` — 23 figures, each in a desktop PNG
(`*_files/figure-html/`) and a mobile PNG (`docs/assets/images/maps/mobile/`, via
`assets/filters/lazy-images.lua`). Shared code: `R/theme_digikat.R`, `R/lib/digikat_charts.R`.

## Audit (rendered 2026-10-18 build, corpus through 2026-10-16)

### Broken outright
- `plot-lollipops-interactions` — plotting areas ~15 px wide. Three side-by-side panels and long
  y labels (e.g. "Danijela Širola-Dujić - Life Coaching i Motivacija") consume ~1 000 of 1 440 px.
  Axis ticks pile on top of each other; lollipop stems invisible. Same on mobile, axis title clipped.
- `plot-polarization-by-topic` — every label "0,0%", axis in thousandths of a percent, labels clipped
  at both edges, a "Nema teme" row. The measure itself is wrong or degenerate (denominator).
- `plot-actors-in-topics` — y labels overprint each other; tofu glyph (□□) in the Politika panel;
  diacritics lost (Plenkovic, Milanovic); non-actors (Bog, Hrvatska, Zagreb) and obituary noise
  (OŽALOŠĆENI, ispraćaj); shared x scale makes four of five panels unreadable.
- `plot-volume-anomalies`, `plot-conflict-anomalies` — y-axis title runs into the chart title
  (overprints the "Đ"); peaks are unannotated (21 Apr 2025, death of Pope Francis, is not named).
- `narrative-biography-robust` — 2021/2022/2024 panels rest on 1–3 texts (every tone exactly ±1,00,
  tokens "#mis", "hamilton", "18.", "ZOOM"); bar length = count but label = tone; 2023 missing.

### Defective
- Mixed fonts: every `geom_text`/`ggrepel` label renders in Arial while the rest is Source Sans/Serif
  (actor map, shares, topic trends, both networks, RCI scatter, migracija).
- Raw platform codes ("web", "youtube", "comment") in some charts, Croatian names ("web-portali",
  "Facebook", "komentari") in others; colours/order not guaranteed identical.
- Decimal points instead of Croatian commas (heatmap 0.77, network legend 0.15, Uskrs 0.25) and
  missing thousands separators (actors-in-topics 10000).
- Clipped value label: `plot-volume` 2025 web "90.61⁴".
- Direct labels that do not sit at line ends and collide with lines (`plot-shares`, `plot-migracija`);
  "komentari" label floating mid-chart; collection-change line drawn at 2023.5, not 2024-01-01.
- Partial periods read as collapses: October 2026 (16 days) plunges in every monthly series; 2026 is
  not marked partial in `plot-volume`/`plot-interaction`.
- `plot-actor-map` — the four typology quadrants (Giants / Community Builders / Megaphones /
  Specialists) are drawn but not named; labels overlap; points clipped at the panel edge; a label
  truncated ("…Life Coac"); log-axis ticks collide ("3.000 K5.000 K").
- Source-name duplicates in rankings: "Majko Marijo" ×2, "Katolička obitelj"/"KATOLIČKA OBITELJ",
  "Bitno.net"/"bitno.net"; `anonymous_user` labelled as a source.
- Networks: gridlines and axis grid under a network; labels sit on nodes and edges; the diskurs
  network draws all edges (hairball) and has a one-item legend; both networks share one title.
- `plot-wordcloud` — stopword lemmas in the top 25 (sav, sv., sat, sam, prvi, mnogi).
- `plot-engagement-by-topic` — "Unutarcrkveni prijepori" = 0, almost certainly a pipeline bug.
- `event-seismograph-uskrs` — daily shares from tiny daily samples (0 % / 67 % swings, gaps).
- Category casing "Pape i vatikan", missing comma "Mediji umjetnost i kultura".
- Triple captioning: title + note baked into the PNG, then a figcaption repeating it, then a
  "Sažetak grafikona" paragraph.

### Page level
- Mobile (390 px) screenshot shows body text, KPI cards and the callout running past the right edge
  — horizontal overflow. Verify with device emulation before fixing.
- Prose glitches: "2021.–2026.." and "listopada 2026.." double periods; internal RQ codes "Q3", "Q5"
  in public prose; section heading repeats the subtitle verbatim.

## Why the existing gate missed it
`tests/check_map_chart_contract.R` checks structure (labels, alt text, mobile attribute), not
pixels. No step looks at the rendered image.

## Work plan
1. **Shared foundation** (`R/theme_digikat.R`, `R/lib/digikat_charts.R`): geom text defaults to the
   theme font (incl. ggrepel); one platform table (Croatian label, colour, order) used by all
   charts; Croatian number formatters for scales, labels and legends; a helper that marks the
   partial final year/month; seam line at 2024-01-01; `theme_digikat_void()` for every network.
2. **Per-chart redesign**, page by page, mapa.qmd first. Key changes: lollipops → one ranked dot
   chart per platform stacked vertically with shortened names; actor map → named quadrants, fewer
   but non-overlapping labels; shares/migracija → small multiples or end-of-line labels that
   follow the data; anomalies → annotated top peaks; networks → thresholded edges, void theme.
3. **Content fixes that change what a chart says** (need PI sign-off, below).
4. **Page fixes**: mobile overflow, double periods, RQ codes, one caption layer.
5. **Visual QA gate**: script renders a contact sheet of all 46 PNGs and runs geometric checks
   (minimum panel width, text inside canvas) through `ggplot_build`/gtable; I review every image
   before calling it done. Extend `check_map_chart_contract.R` with the geometric checks.
6. Render each page with Quarto 1.9.38 from the repo root, confirm `data/processed/*.rds` md5
   unchanged, verify assets are tracked before committing.

## Decisions for the PI
- Polarisation (Love/Angry) chart: fix the measure, or drop the chart.
- Stepinac early years and the Uskrs 2022 window: apply a minimum-n floor (drops thin years) or replace.
- Captions: keep title in the image (good for shared previews) and cut the figcaption to a one-line
  source, or move titles out of the image entirely.
- Whether "Unutarcrkveni prijepori = 0" and the stopword list are fixed upstream (`R/04_nlp.R`,
  touches `data/nlp/` + `data/page-ready/`) or filtered at page level.

## Out of scope / hard gates
No change to the corpus, the inclusion rule, `R/03_aggregate.R --apply`, or a full-site render
without explicit approval.
