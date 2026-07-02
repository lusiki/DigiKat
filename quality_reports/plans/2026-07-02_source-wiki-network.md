# Plan — "Mreža izvora" (the Source Wiki as a network graph)

**Date:** 2026-07-02 · **Author:** Claude (for PI Luka Šikić) · **Desc slug:** source-wiki-network
*(On approval, copy to `quality_reports/plans/2026-07-02_source-wiki-network.md`.)*

## Context

The PI wants Karpathy's LLM-wiki idea (our **Katalog izvora**) *transformed into a network* — i.e. the
wiki's link structure made visible as a node-edge graph. The wiki is already an interlinked set of pages;
this renders that graph, in the same `ggraph` style as the two existing theme networks
([mapa_stats.qmd:485-496](pages/mapa/mapa_stats.qmd) · [diskurs.qmd:507-524](pages/mapa/diskurs.qmd)).

**Key design choice — what the edges mean.** Honest options are constrained by available data:
shared-**theme** or shared-**audience** edges would need per-actor theme-mix / audience-overlap data we
don't have yet (that's the v2 join) *and* carry the co-occurrence-validation caveat (co-occurrence ≠
relationship; the inflation study overstated ~7×). So v1 edges are **structural only** — the wiki's own
links + shared brand identity — which need no inference. Richer semantic edges are deferred to v2.

## Recommended design

**New page `pages/izvori/mreza.qmd` — "Mreža izvora"** (hand-authored, live `ggraph`). Mirrors the existing
network pages' setup: `knitr::opts_chunk` with cream `dev.args`, `library(ggraph)` + `library(igraph)`,
`source("../../R/theme_digikat.R")`. Reads **only** `../../data/processed/{web,youtube,facebook}_actors.rds`
+ `../../resources/dictionaries/source_labels.csv` (no master, no `data/nlp`).

- **Nodes** = 47 published actors + 3 platform-hub nodes (Web / YouTube / Facebook).
  - color = platform via `dk_platform_colors` (lowercase keys `web/youtube/facebook` already match).
  - actor size = **volumen** (`total_posts`, log-scaled); hub nodes larger + distinct shape (diamond).
  - labels = actor names (`geom_node_text`, repel).
- **Edges** = the wiki's own links (structural, no inference):
  1. **membership** — each actor → its platform hub (thin, `dk_col$faint`).
  2. **brand bridges** — actors sharing an `entity` across platforms (`dk_col$accent_200`, thicker):
     Bitno.net web↔fb, Laudato web↔fb↔yt, Index/Net.hr/Večernji/Jutarnji/24sata/Dnevnik web↔fb, RTL yt↔fb.
- Layout `fr`, `set.seed(123)`, `theme_digikat_void(base_size = 16)`. Croatian title/subtitle/legend.
- **Read-out prose** (voice-rule compliant): explains nodes/edges, then reads the graph — 3 platform
  constellations; web↔Facebook densely bridged by mainstream brands (+ Bitno.net, Laudato); YouTube largely
  platform-native except Laudato/RTL; confessional actors (hkm.hr, Radio Marija, Zagrebačka nadbiskupija)
  hang off their hub as platform-native. **Caveats:** edges are *structural* (shared brand / wiki link) —
  **not** co-occurrence, audience overlap or influence; volumes indicative (2021.–2025., provisional).

**Generator changes — `R/wiki_sources.R`:**
1. **Protect hand-authored pages from cleanup.** Change the start-of-run delete from "all `*.qmd`" to only
   the generated set (`index.qmd`, `platforma-*.qmd`, `^(web|youtube|facebook)-*.qmd`) so `mreza.qmd`
   survives regeneration. (`_schema.md`/`_log.md` are already safe as `.md`.)
2. **Link to the network** from the generated `index.qmd` lead (→ `mreza.html`).

**Nav — `_quarto.yml`:** add one line, "Mreža izvora" (`pages/izvori/mreza.qmd`), under *Mapa medijskog
prostora* right after *Katalog izvora*. (File is being externally edited via Dropbox — add the single line
only, touch nothing else.)

## Reused utilities

- `R/theme_digikat.R` → `dk_platform_colors`, `theme_digikat_void()`, `dk_col$accent_200/faint/ink`.
- `igraph::graph_from_data_frame()` + `ggraph(layout="fr")` + `geom_edge_*/geom_node_*` (as in the two
  existing network pages).
- Node/edge tables reconstructed from the **same** aggregates + sidecar the generator uses (single source
  of truth; numbers not hand-typed).

## Verification (before done)

1. Re-run `Rscript R/wiki_sources.R` → confirm **`mreza.qmd` NOT deleted**, `index.qmd` links to it, console
   counts unchanged (47/10), and **`md5sum data/processed/*.rds` unchanged**.
2. Render `pages/izvori/mreza.qmd` from repo root → rc=0, the **network figure is present** (non-empty
   `<img>`, no error block), Croatian diacritics literal, edges/legend visible.
3. Post-render: no scatter outside `docs/`; `docs/` intact. Quick voice-rule pass on the prose.
4. NOT doing: full-site render / `R/03_aggregate.R` (HARD GATES).

## Out of scope (v2)

- Semantic edges: shared-**theme** (needs the `data/nlp` per-actor theme-mix join) and shared-**audience**
  overlap — both require the v2 data *and* co-occurrence validation before any edge is claimed as a relationship.
- Interactive/clickable network (e.g. `visNetwork`); brand-level entity **merging** into single nodes.
