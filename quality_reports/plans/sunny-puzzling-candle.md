# Plan — Source network on the homepage + catalog/network folded into the database page

**Date:** 2026-07-02 · **Author:** Claude (for PI Luka Šikić) · **Slug:** sunny-puzzling-candle

## Context

Two reader-facing information-architecture changes the PI asked for:

1. **Feature the interactive source network on the site landing page.** Today the network lives only on
   `pages/izvori/mreza.qmd` ("Mreža izvora", an interactive `visNetwork`). The PI wants it surfaced on the
   **homepage** (`index.qmd`) as a **two-column split** (prose + graph), and wants **every node to be a circle**
   — currently the six platform-hub nodes are diamonds (`shape = "diamond"`).
2. **Re-home the source catalog + network under the database, not the map.** The "Katalog izvora" (per-actor
   profiles) and "Mreža izvora" currently hang off the *Mapa medijskog prostora* navbar menu. The PI wants them
   **integrated seamlessly into the `pages/baza.qmd` prose** (with the link to the network and a **fuller
   explanation of what the network is**), and **removed from the navbar** — they don't need a nav entry at all.

Outcome: the homepage gains a network feature (all-circle nodes); `baza.qmd` gains a prose subsection that
introduces the catalog and explains the network, linking to both; the two navbar entries are deleted. Graph-build
logic is extracted to one shared R helper so the homepage and the standalone Mreža page stay a single source of
truth (numbers/typology still come from the aggregates, never hand-typed).

## Key constraints discovered (must respect)

- `pages/izvori/index.qmd` (the Katalog) is **machine-generated** by `R/wiki_sources.R` — never hand-edit it;
  change the generator's `idx_lines` if its wording must change.
- `pages/izvori/mreza.qmd` is **hand-authored** and preserved by the generator's cleanup regex — safe to edit.
- `index.qmd` is `page-layout: custom` (raw-HTML hero + stats band, **no R today**). Adding the widget means the
  homepage will start executing R and reading the tracked actor aggregates (`data/processed/*_actors.rds`) — no
  master, no `data/nlp`, so it stays render-safe.
- `freeze: auto` re-executes **all** chunks of a page on any source edit; editing `baza.qmd` re-runs its
  1.2 GB-master chunks on render (heavy but fine on this machine).
- Reuse `R/theme_digikat.R`: `dk_platform_colors` (keys web/youtube/facebook/instagram/tiktok/twitter),
  `dk_col$ink/accent_200/faint/paper`. Design tokens (SCSS vars in `assets/css/custom.scss`): `$dk-accent #0F4C5C`,
  `$dk-paper #F5F4F0`, `$dk-hairline #E4E2DA`, fonts Source Serif 4 / Source Sans 3 / IBM Plex Mono.

## Changes

### 1. New shared helper — `R/source_network.R` (single source of truth for the graph)

Extract the graph-build + widget code currently inline in `pages/izvori/mreza.qmd` (lines 24–156) into two functions:

- `build_source_network(proc_dir, sidecar)` → reads the six `*_actors.rds` + `source_labels.csv`, applies the
  same `classify_typology()` median split and the same node/edge construction (platform-membership + shared-brand
  edges), returns `list(nodes, edges, n_actors)`. Callers pass their own relative paths (repo-root vs `../../`).
- `source_network_widget(sn, height = "760px")` → builds the configured `visNetwork` (physics, hover, legend).
  **All nodes `shape = "dot"` (circles).** Hubs stay distinct by size (largest dot), `borderWidth = 4`, and a dark
  `color.border = dk_col$ink`; actors `borderWidth = 1`. Assumes the caller has already sourced `theme_digikat.R`
  (both pages do), so `dk_col`/`dk_platform_colors` are in scope.

### 2. `pages/izvori/mreza.qmd` (edit)

- Replace the inline `build-graph` + `plot-network` chunks with `source("../../R/source_network.R")` +
  `build_source_network("../../data/processed", "../../resources/dictionaries/source_labels.csv")` +
  `source_network_widget(sn, height = "760px")`.
- Fix the "Kako čitati" prose that says hubs are diamonds (line ~98: *"Šest čvorova u obliku romba…"*) → describe
  them as the six largest nodes, one per platform (no diamond wording). Everything else unchanged.

### 3. `index.qmd` — homepage (edit)

- Add a hidden setup chunk after the YAML: `knitr::opts_chunk$set(echo=FALSE, message=FALSE, warning=FALSE)`,
  `library(dplyr)`, `library(visNetwork)`, `source("R/theme_digikat.R")`, `source("R/source_network.R")`.
- After the existing stats-band `{=html}` block (line 74), add a new **two-column section** as nested fenced divs
  (`::: {.home-network}` › `.hn-inner` › `.hn-text` + `.hn-viz`). Left column `.hn-text`: a short serif heading
  ("Mreža izvora") + 2–3 framing sentences (each node = one source; links = platform + shared brand; explore by
  mouse) + Markdown links to **Mreža izvora** (`pages/izvori/mreza.html`), **Katalog izvora**
  (`pages/izvori/index.html`), **Baza podataka** (`pages/baza.html`). Right column `.hn-viz`: an R chunk calling
  `build_source_network("data/processed", …)` + `source_network_widget(sn, height ≈ "540px")`.
- Add `.home-network` styling to `assets/css/custom.scss` mirroring the hero band: `border-bottom: 1px solid
  $dk-hairline`; `.hn-inner { max-width: 1180px; margin: 0 auto; padding: 56px 40px; display: grid;
  grid-template-columns: 0.9fr 1.1fr; gap: 44px; align-items: center; }`; collapse to one column under ~900px.

### 4. `pages/baza.qmd` — database page (edit, prose only)

Insert a new `##` section **after "Sastav i tipologija izvora"** (after line 194, before "Kako je prikupljen") —
where source composition is already the topic. Content (qualitative, **no new hand-typed corpus numbers**):

- Introduce the **Katalog izvora**: per-actor profile pages (volumen/angažman/doseg + typology, computed as in the
  Mapa), link `[Katalog izvora](izvori/index.html)`.
- **Fuller explanation of the Mreža izvora**: nodes = sources (sized by volumen, coloured by platform); edges are
  **structural only** — platform membership + shared brand/person across platforms — and explicitly **not**
  shared audience, shared themes, or influence (the co-occurrence caveat). Link `[Mreža izvora](izvori/mreza.html)`.
- One caveat sentence consistent with the catalog (indicative, working version, 2021.–2025. aggregates).
  Follow `voice-and-style.md` (§7 numbers, §8 punctuation, `„…"` quotes, ≤1 em-dash/paragraph).

### 5. `_quarto.yml` — navbar (edit)

Delete the two entries under *Mapa medijskog prostora* menu: **"Katalog izvora"** (`pages/izvori/index.qmd`) and
**"Mreža izvora"** (`pages/izvori/mreza.qmd`) — lines 38–41. No other nav change; pages remain rendered and are
reached via the new `baza.qmd` links. Leave the *Evolucija ekosustava* entry intact.

### 6. `R/wiki_sources.R` — generator (light edit, for coherence)

In `idx_lines` (lines ~294–319): change `categories` from `["Katalog izvora", "Mapa ekosustava"]` to
`["Katalog izvora", "Baza podataka"]`, and add a link back to `[Baza podataka](../baza.html)` in the lead so the
generated catalog page is framed as part of the database (it still links to Mapa for the typology and to `mreza`).
Then **re-run the generator once** (`Rscript R/wiki_sources.R`) to regenerate `pages/izvori/index.qmd` (and the
actor/hub pages, identically). The script writes only under `pages/izvori/` and reads aggregates read-only.

## Verification (run where R + Quarto live — this machine; pause Dropbox first)

```
export PATH="/c/Program Files/R/R-4.4.1/bin:$PATH"
QUARTO="/c/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe"
md5sum data/processed/*.rds > /tmp/pre.md5            # baseline
"/c/Program Files/R/R-4.4.1/bin/Rscript.exe" R/wiki_sources.R   # regenerate catalog
"$QUARTO" render pages/izvori/mreza.qmd              # network page: all-circle nodes, rc=0
"$QUARTO" render index.qmd                           # homepage: two-column network renders
"$QUARTO" render pages/baza.qmd                       # heavy (reads master); confirm new prose renders
md5sum -c /tmp/pre.md5                                # HARD: data/processed/*.rds UNCHANGED
```

Check after each render (per `quarto-verification.md` §2/§3/§8):
1. **All nodes are circles** in `mreza.html` and the homepage widget (no diamonds); hubs still read as hubs.
2. Homepage two-column section renders (graph on one side, prose+links on the other) and is responsive.
3. `baza.html` shows the new catalog/network subsection with working links; Croatian diacritics literal (č ć ž š đ).
4. `md5sum -c` passes (no `data/processed` mutation); `mreza.qmd` survived the generator re-run.
5. `git status`: **no scatter outside `docs/`** (no root `site_libs/`, no `pages/**/*.html` beside sources).
6. Navbar in a rendered page no longer lists Katalog/Mreža under Mapa; both still reachable from `baza.html`.
7. Optional: run the `verifier` + `croatian-nlp-reviewer` agents on the touched pages before commit.

## Implementation order

1. `R/source_network.R` — new shared helper (extract from `mreza.qmd`; all nodes `shape = "dot"`).
2. `pages/izvori/mreza.qmd` — source the helper; fix the "romb"/diamond prose.
3. `assets/css/custom.scss` — add `.home-network` / `.hn-inner` / `.hn-text` / `.hn-viz` styles.
4. `index.qmd` — setup chunk + two-column network section.
5. `pages/baza.qmd` — new catalog/network prose subsection after "Sastav i tipologija izvora".
6. `_quarto.yml` — delete the Katalog + Mreža entries from the Mapa menu.
7. `R/wiki_sources.R` — light `idx_lines` edit (categories + link back to Baza); re-run the generator once.
8. Verify (render the 3 pages, `md5sum -c`, diacritics, no scatter); hand off to `/commit`.

## Not doing (out of scope / HARD GATES)

- No **full-site `quarto render`** overwriting `docs/`, no `R/03_aggregate.R`, no master/backup touch, no git
  history rewrite (all HARD GATES). Page-by-page render only.
- No new navbar entries; no absorbing the generated catalog *tables* into `baza.qmd` (kept as a separate page).
- No semantic (theme/audience) edges — v2, and gated by co-occurrence validation.
- Not auto-committing — hand off to `/commit` after the PI reviews the rendered output.
```
