# Katalog izvora — wiki schema

*Internal maintenance doc (English, per project convention). The `_` prefix keeps Quarto from rendering
it into `docs/`. This is the "schema" layer of the LLM-wiki pattern (Karpathy): it defines how the wiki
is built and maintained, in DigiKat's idiom.*

## What this is

A **Source Wiki** — one browsable page per media actor — that acts as a per-actor *companion* to
**Mapa ekosustava** (Layer 1). It is a navigable reference layer, **not** a replacement for the analytical
narrative in `pages/mapa/mapa.qmd`, and **not** RAG: the pages are a synthesized, interlinked artifact that
is regenerated (not re-derived per query) whenever the inputs change.

## Three layers

1. **Aggregate sources (immutable to the generator).**
   `data/processed/{web,youtube,facebook,instagram,tiktok,twitter}_actors.rds` — tracked,
   disclosure-reviewed aggregates
   aggregates (`FROM, total_posts, total_interactions, total_reach`). The wiki READS these; never writes them.
2. **The wiki (generated).** Everything under `pages/izvori/*.qmd` — actor pages, platform hubs, `index.qmd`.
   Owned by the generator; do **not** hand-edit (edits are overwritten on the next run).
3. **The schema (this doc + the sidecar).** This file + `resources/dictionaries/source_labels.csv` — the
   PI-owned configuration that decides what is published and how it is labeled.

## Files

| File | Owner | Role |
|---|---|---|
| `R/wiki_sources.R` | generator | the "ingest" operation — reads inputs, writes the wiki, appends the log |
| `resources/dictionaries/source_labels.csv` | **PI** | per-actor label / keep-decision sidecar (see columns below) |
| `pages/izvori/index.qmd` | generator | catalog front door (per platform → per typology) |
| `pages/izvori/platforma-<platform>.qmd` | generator | platform hubs for the six actor platforms |
| `pages/izvori/<platform>-<slug>.qmd` | generator | one page per published actor |
| `pages/izvori/_schema.md` | human | this doc |
| `pages/izvori/_log.md` | generator (append) | provenance + triage of held/excluded actors + lint notes |

## The sidecar (`source_labels.csv`, UTF-8)

`from` — the actor's `FROM` value, **must match the aggregate exactly** (else the row is treated as `TBD`).
`entity` — brand group across platforms (for v2 merging; unused in v1). `kind` ∈ `institution | individual
| noise | offtopic | duplicate`. `label` ∈ `confessional | secular | other` (blank → `TBD (PI)`).
`publish` ∈ `yes | no`. `status` ∈ `proposed | confirmed` (proposed labels render with „(predloženo)").
`description` — one-line factual description (blank → `TBD (PI)`; never fabricate).

**PI workflow:** edit this one file (confirm labels → `status=confirmed`, rule on held actors → set
`publish`), then re-run the generator. Nothing else is hand-edited.

## Operations

- **Ingest / rebuild:** `Rscript R/wiki_sources.R` from the repo root. Regenerates the managed actor
  pages and catalog index, then appends a timestamped entry to `_log.md`. Writes **only** under
  `pages/izvori/` — never `data/processed/*.rds`.
- **Query:** browse the site section, or `grep` the `pages/izvori/*.qmd` frontmatter.
- **Lint:** the generator flags thin actors and attribution anomalies into `_log.md`; a periodic manual pass
  checks for stale labels, held actors awaiting a PI decision, and aggregate staleness.

## Derivation rules (so numbers are never hand-typed)

- **Metrics** (volumen/angažman/doseg) are baked from `*_actors.rds` at generation time, Croatian-formatted
  (`big.mark="."`). Provenance + the source aggregate's own mtime are printed on each page.
- **Typology** reuses `pages/mapa/mapa.qmd`'s Layer-1 rule verbatim: within each platform, split by the
  **median** of `total_interactions` (x) × `total_reach` (y) → **Divovi / Graditelji zajednica / Megafoni /
  Specijalizirani akteri**. Computed over the full per-platform aggregate, so buckets match the map.
- **Disclosure:** only `kind=institution` + `publish=yes` render. Individuals, noise, off-topic and
  duplicates are held and listed in `_log.md`.

## Status caveats

The current catalog reads all six actor aggregates and reports the production coverage dynamically:
2021.–2026., with 2026 partial. Totals cross the approximate 2024 collection-method change and remain
indicative for longitudinal comparison. Profiles with fewer than 20 posts are very thin; profiles below
200 posts are provisional. Refresh path: preview and review `R/03_aggregate.R`, apply the complete
aggregate generation only after authorization, then rerun `R/wiki_sources.R`.
