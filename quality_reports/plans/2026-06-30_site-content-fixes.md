# Plan — Site content-review fixes (from 2026-06-29 review)

**Date:** 2026-06-30 · **Owner:** Claude + PI · **Source:** `quality_reports/2026-06-29_site-content-review.md`
**Scope:** the 10 live reader-visible pages (`pages/**/*.qmd`) + the project-doc number drift. `design/*.qmd`
is a NON-rendered mockup (`_quarto.yml` renders only `pages/**`) — OUT of scope unless explicitly requested.

## Environment (verified 2026-06-30, this machine)
- R **4.4.1** at `C:\Program Files\R\R-4.4.1\bin\Rscript.exe` (not on PATH; UTF-8 native = TRUE). Also 4.3.2.
- Master present: `data/merged_comprehensive.rds` (1.19 GB) + two backups from 2026-06-29 morning.
- Quarto (RStudio-bundled): `C:\Program Files\RStudio\resources\app\bin\quarto\bin\quarto.exe`.
- `_freeze/` cache exists (`execute: freeze: auto`). ⇒ prose-only edits to data pages render light; ANY edit
  inside an R chunk re-runs it (needs R + master + correct aggregates).
- **Conclusion:** everything runs locally — NO hand-off. (Decision A resolved: run here.)

## Locked decisions
- **B — "620 variables":** WRONG → use **47** (master's real column count) everywhere it is reader-visible;
  correct project-doc copies too. Compute inline where feasible rather than hard-typing.
- **C — Emoji:** replace decorative emoji with **Bootstrap icons** (`bi-*`, available via cosmo). No style-guide change.
- **A — Aggregate refresh:** runs locally; still a HARD GATE (confirm before overwriting `data/processed/*.rds`).

## Root cause (from review)
Master refreshed 2026-06-29 (→ 710.307 rows, 2021–2026, +instagram/+tiktok) but the aggregates were NOT
regenerated. `data/processed/*.rds` are stale (Jan 8; sum 608.879; 2021–2025; no instagram/tiktok). The four
`mapa/*` pages read those aggregates and show 610k/2021–2025; `index`/`baza` were hand-updated to 710k.

### Correction to the review
- `R/03_aggregate.R` **does not exist** — the numbered pipeline was never built. Aggregates are currently
  produced by `mapa.qmd`'s in-render `saveRDS()` (Phase-0 anti-pattern). "Refresh aggregates" therefore means
  EITHER build `R/03_aggregate.R` (extract the `saveRDS` logic out of `mapa.qmd`) OR re-render `mapa.qmd`
  against the master. Prefer building the script (aligns with CLAUDE.md principle 4).
- `događaji.qmd` has the SAME sample-fraction bug as `diskurs` (comment 5% / code `0.03` = 3%) — TWO mismatches.
- `610`/`620` also live in `CLAUDE.md`, `MEMORY.md`, `PROJECT_DESCRIPTION.md`, `DATA_AVAILABILITY.md`,
  `REPLICATION.md`, `.claude/references/discipline-card-digikat.md` (project docs, not just pages).

## Phasing (dependency-ordered)

### Phase 1A — R-free / hand-typed pages (edit + render-verify locally)
Pages with no/minimal R chunks: `index`, `about`, `schedule`, `news`, `resources`, `site-info`, `studije/*` (5 stubs).
- `index.qmd`: 620→47; platform count 6→9 + add missing source pills; corpus size + year facts (2021.–2026.);
  terminology; any emoji→icons.
- `news.qmd`: remove leftover placeholder line; fix spurious year badge (2024.–2026.) + body 2021.–2024. claim;
  sentiment→tonalitet; dashes.
- `about`/`site-info`/`resources`: emoji→Bootstrap icons; subtitle de-duplication; Croglish.
- `schedule.qmd`: canonical layer names (not "sistematizirana karta"/"medijski prostor"/"baza podataka"); dashes.
- `studije/*`: minor subtitle/Croglish nits.

### Phase 1B — data-page PROSE-only edits (freeze-cached; no chunk re-run)
On `baza` + the four `mapa/*`, ONLY markdown/prose: canonical layer names in H1; `sentiment→tonalitet` in prose;
RIK consistency in prose; `„…"` quotes; dash/ordinal formats in prose; `baza` Croglish + bracketed-URL→Markdown
links + ASCII-quote fixes + caption/typo fixes; baza hardcoded 620→47 and 6→9. (Do NOT touch R chunks here.)

### Phase 2 — data-coupled (HARD GATE; re-runs chunks; needs R + master)
- Build `R/03_aggregate.R` (extract aggregation from `mapa.qmd`) → run vs master → refresh `data/processed/*.rds`
  (includes 2026 + instagram/tiktok; HARD GATE — back up + confirm).
- In-chunk edits: widen the four mapa date filters to include 2026; sync `sample_proportion` + comments
  (diskurs, događaji); replace `mapa`/`mapa_stats` "610.000+" literals with COMPUTED values; `NRC→lilaHR` in
  code comments/var names; in-figure Title-Case → sentence case (ggplot `labs()`), Croatian months lowercase;
  narrated approximate % → computed.
- Full `quarto render` → `docs/` (HARD GATE) → verify (verifier agent): docs/ non-empty, no scatter outside
  docs/, diacritics literal UTF-8, no accidental `processed/*.rds` staging beyond the intended refresh.

### Phase 3 — project-doc number drift (non-site)
Correct 610k→710.307 / 620→47 / 2021–2025→2021–2026 in `CLAUDE.md`, `MEMORY.md`, `PROJECT_DESCRIPTION.md`,
`DATA_AVAILABILITY.md`, `REPLICATION.md`, discipline card. Add a `[LEARN]` note about the aggregate-staleness trap.

## Verification & gates
- Each touched page: render from REPO ROOT (`quarto render pages/<p>.qmd`) — never `cd pages` (MEMORY.md trap).
- After any render: confirm no stray `site_libs/`, `*_files/`, root `index.html`, no emptied `docs/`.
- HARD GATEs (confirm with user): overwrite `data/processed/*.rds`; full `quarto render` → `docs/`; bulk `git add`.
- Commit per coherent batch (e.g., per phase) via `/commit`; do NOT stage the gitignored master/backups.

## Rejected alternatives
- **Hand off the data steps** — rejected: R + master + Quarto are all on this machine.
- **Bump `mapa` "610.000+" literals to 710k in Phase 1** — rejected: charts still sum to 608k; header/chart
  mismatch would be a NEW inconsistency. Their numeric literals move with the aggregate refresh (Phase 2).
- **Quick re-render of `mapa.qmd` to refresh aggregates** — deferred under building `R/03_aggregate.R`, which
  removes the render side-effect for good (CLAUDE.md principle 4); fall back to it only if time-boxed.
