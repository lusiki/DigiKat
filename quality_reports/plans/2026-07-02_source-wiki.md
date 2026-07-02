# Plan — Source Wiki ("Katalog izvora")

**Date:** 2026-07-02 · **Author:** Claude (for PI Luka Šikić) · **Desc slug:** source-wiki
*(On approval, copy this to `quality_reports/plans/2026-07-02_source-wiki.md` — the date/desc convention.)*

## Context

The PI wants to apply Karpathy's "LLM wiki" pattern (persistent, interlinked, tool-maintained
markdown knowledge base — **not** RAG) to DigiKat's resources and publish it on the Quarto site.
After a design discussion we scoped a **Source Wiki**: one browsable page per media actor, a
per-actor *companion* to **Mapa ekosustava** (Layer 1) — a navigable reference layer, not a
replacement for the analytical `mapa.qmd` narrative.

Recon established the concrete shape:
- The feeding data already exists: `data/processed/{web,youtube,facebook}_actors.rds` — **19 rows each
  = 57 candidate actors** (`FROM, total_posts, total_interactions, total_reach`), plus
  `source_summary.rds` (adds `avg_engagement_rate`, per-year).
- The Layer-1 **actor typology** is *computable*, not a guess: `pages/mapa/mapa.qmd:405-431` splits
  each platform by the **median** of `total_interactions` (angažman, x) × `total_reach` (doseg, y) into
  **Divovi / Graditelji zajednica / Megafoni / Specijalizirani akteri**. The wiki reuses this rule so
  buckets match the map exactly.
- The 57 rows need triage: most are clean institutions, but there are **individuals** (Marko Perković
  Thompson, Miletić Marin, Velimir Bujanec), **noise/false-positives** (campaign-archive.com = 3 posts;
  "Abhinesh yadav 5050d" = 1 post), a **duplicate** ("Dijete Vjere" ×2), and **questionable topicality**
  (Atma, Добровољци, *Balkan Vibes*). These cannot be auto-published.

Constraints honored: no hand-typed numbers (compute from `data/processed/*.rds`); confessional/secular
labels are contestable + PI-owned (MEMORY); aggregates are **stale** (built 2026-01-08, miss
Instagram/TikTok) and actor totals span **2021.–2025.** across the ~2024 collection-method change →
everything ships **provisional + caveated**; render must not mutate `data/processed/*.rds`.

## Design decisions (with rationale)

1. **Generated, not hand-authored.** A new `R/wiki_sources.R` reads the aggregates + a labels sidecar and
   writes the pages. → no hand-typed numbers, reproducible on data refresh, PI-owned bits isolated. This
   *is* the wiki's "ingest" operation.
2. **Typology computed, consistent with Layer 1.** Reuse the `mapa.qmd` per-platform median rule verbatim.
3. **PI-owned bits in a sidecar** — `resources/dictionaries/source_labels.csv` (UTF-8): `from, entity,
   label{confessional|secular|other}, kind{institution|individual}, publish{yes|no}, status{proposed|
   confirmed}, description`. Generator joins on `from`; I **seed** it with *proposals* (marked
   „predloženo") and safe defaults; PI edits one file and re-runs. Missing/blank → `TBD (PI)`, never a fabrication.
4. **Static markdown output** (`.qmd`, no render-time R). Numbers baked from the aggregate at generation
   time + dated; pages can't read the master and render trivially. Provenance block cites the source aggregate.
5. **Standard Quarto relative links, not `[[wikilinks]]`.** Keeps every wiki property (interlinking,
   index, log, frontmatter, lint) except the `[[ ]]` glyph, with zero tooling risk; a wikilink Lua filter
   is a later option. Matches the "everything reader-visible is a `.qmd` under `pages/`" convention.
6. **Disclosure gate baked into the generator.** Only `kind=institution, publish=yes` render. Individuals
   + noise + questionable-topicality are **held**, listed in `_log.md` as PI work-items (runs the
   `/disclosure-check` spirit). Safe default = hold.
7. **One page per actor-as-it-appears (per platform) for v1.** Matches the aggregates and how Layer 1
   treats actors; avoids contestable cross-platform entity-merging. The sidecar's `entity` column enables
   **v2** brand-level merging (one node per brand across platforms) + "ista marka na drugim platformama" links.
8. **ASCII kebab-case slugs** (transliterate diacritics/Cyrillic for the *filename* only; display name keeps
   original script) — avoids the `događaji.qmd` diacritic-filename hazard.

## Files created / changed

| Path | Action | Notes |
|---|---|---|
| `R/wiki_sources.R` | NEW | generator: reads aggregates + sidecar → writes pages/index, appends log; UTF-8 connections throughout |
| `resources/dictionaries/source_labels.csv` | NEW | PI-owned sidecar, seeded with proposals (UTF-8) |
| `pages/izvori/_schema.md` | NEW | wiki rules: ingest / query / lint (English; `_`-prefix → unrendered internal artifact) |
| `pages/izvori/_log.md` | NEW | append-only provenance + held/noise triage (`_`-prefix → unrendered) |
| `pages/izvori/index.qmd` | NEW | catalog front door; grouped by platform → typology; uses `.card-grid`/`.info-card` design classes |
| `pages/izvori/platforma-{web,youtube,facebook}.qmd` | NEW (×3) | platform hubs (mini-indexes + cross-link targets) |
| `pages/izvori/<slug>.qmd` | NEW (~45–47) | one per publishable institutional actor |
| `_quarto.yml` | EDIT | one nav entry — "Katalog izvora" under the **Mapa medijskog prostora** menu |

**Triage (first pass):** ~**47 publishable** (web 18 · youtube ~12 · facebook 17) · ~**10 held/excluded**
(3 individuals, 2 noise, ~4 questionable-topicality, 1 duplicate) — exact split shown in `_log.md`.

## Per-actor page template

YAML frontmatter (`type: source`, `name`, `platform`, `typology`, `label`, `rank`, `sources`, `updated`)
then Croatian sections:
- **Što je** — 1-line factual description from the sidecar (or `TBD (PI)`).
- **Profil** — volumen / angažman / doseg, Croatian-formatted (`big.mark="."`, `%` with decimal comma), rank-in-platform.
- **Tipologija** — computed quadrant + one-sentence read; „(predloženo)" until PI confirms the label.
- **Povezano** — platform hub + same-platform neighbors (+ best-effort same-brand link).
- **Izvori podataka** — provenance (which `*_actors.rds`, generation date) + the ⚠ 2021.–2025. / stale / two-stream caveat.

Croatian content, English frontmatter keys. Voice-rule compliant (sentence-case headings; canonical terms
korpus/objava/doseg/angažman/volumen; no marketing hype).

## Verification (before reporting done)

1. `Rscript R/wiki_sources.R` sources clean; prints counts (published / held / noise).
2. **`md5sum data/processed/*.rds` UNCHANGED** after the run (generator writes pages only — never `processed/*.rds`).
3. Render **2–3 sample pages + `index.qmd`** with Quarto **from the repo root** (single-page, not full-site):
   pick pages with tricky text — `zagrebacka-nadbiskupija` (đ/č/ž) and one Cyrillic-name case if published —
   confirm build ok, **diacritics + Cyrillic literal UTF-8** in the HTML, figures/links ok.
4. Post-render: **no scatter** outside `docs/` (no root `site_libs/`, `pages/**/*.html`, `*_files/`), `docs/` non-empty.
5. Quick voice-rule pass on `index.qmd` + one actor page.

*(Not doing: a full-site `quarto render`, and running `R/03_aggregate.R` — both HARD GATES, out of scope here.)*

## Out of scope (hand-off to PI)

- **PI review**: confirm labels/descriptions (flip `status`→confirmed), rule on the ~10 held actors (individuals/noise/topicality).
- **Theme-mix per actor** (which of the 16 categories each drives) — needs a `data/nlp` join → v2.
- **Aggregate refresh** (stale; needs `R/03_aggregate.R`) — separate HARD-GATE task.
- **Full-site render + publish** — hand to `/deploy` (HARD GATE).
- `[[wikilink]]` Lua filter; promoting `_schema`/`_log` to published pages; brand-level entity merging (v2).

## How a teammate re-runs it

Edit `resources/dictionaries/source_labels.csv` (or refresh the aggregates) → `Rscript R/wiki_sources.R`
from the repo root → regenerates pages + index, appends `_log.md` → `/render-page` the changed pages →
`/deploy` when ready.
