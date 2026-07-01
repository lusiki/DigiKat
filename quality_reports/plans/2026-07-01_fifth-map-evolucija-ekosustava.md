# Plan — Fifth analytical map: "Evolucija ekosustava" (longitudinal ecosystem map)

**Date:** 2026-07-01 · **Status:** APPROVED (decisions locked 2026-07-01); Phase-1 files written; awaiting HARD-GATE aggregate rebuild before render
**Owner:** PI (Luka Šikić) · **Type:** new analytical page (`pages/mapa/`) — plan-first trigger
**Author of plan:** Claude (recon-grounded; see "Verified facts" below)

---

## 1. Goal

Add a fifth analytical map that answers a question the current four do not: **how the Catholic
digital media ecosystem *changes over time*** — not what it *is* (L1), what it *talks about* (L2),
how it *feels* (L3), or what happened around a *specific event* (L4). It turns the year-facets that
L1 already shows into an explicit longitudinal story a non-specialist can narrate in three sentences:
**the space grew → influence migrated between platforms → power concentrated among a few actors.**

Keep it deliberately **simple, reproducible, and refactorable**: it reads ONLY the small tracked
`data/processed/*.rds` aggregates — no `data/nlp/`, no master, no `saveRDS` — which also makes it the
**cheapest analytical page in the site to render** (no udpipe re-execution under `freeze: auto`).

## 2. Identity and boundaries (why it earns a slot, and how it stays distinct)

- **Canonical layer name (recommended):** **„Evolucija ekosustava"** (Ecosystem evolution).
  Reads as the *time-twin of L1 „Mapa ekosustava"* — same volume/engagement/reach data, watched along
  the time axis. Alternates: „Putanje utjecaja", „Rast i koncentracija".
- **Boundary vs L1 (Mapa ekosustava):** L1 is a **snapshot** (per-year facets, actor typology). L5 is
  the **trajectory** — one line/area per platform through time, plus concentration trend.
- **Boundary vs L4 (Fokus na događaje) — the critical one.** L4 already owns **event-anchored, content-rich**
  temporal dynamics: daily Z-score „digitalni seizmograf", the Stepinac longitudinal narrative, Uskrs-2022
  seasonality, sentiment/theme/conflict shifts. L5 must stay **structural and content-free**: counts, shares,
  concentration ratios only — **no sentiment, no themes, no named events**, at **yearly (optionally monthly)**
  granularity. State this division in the lead sentence of L5, cross-link L4, and **avoid L4's signature
  vocabulary** („seizmograf", „anomalija", „događaj", „potres").

## 3. The map's content — three core movements (+ one optional, deferred)

Each movement = one intuitive figure + one interpretive read-out (house spine). Linear axes by default;
log only where dynamic range genuinely demands it (and then labelled + gridline-annotated).

**Movement 1 — „Rast": did the space grow, and who drove it?**
- Source: `platform_summary.rds` (year × SOURCE_TYPE × total_posts/interactions/reach). Buildable now.
- Chart: line (one per platform) of `total_posts` over 2021–2025, **2026 rendered as a distinct dashed/greyed
  „nepotpuna godina" segment** with a caption stating the last-scraped cutoff. Optional companion: indexed
  growth (first complete year = 100).
- Read: overall growth + YouTube's rise; web flat-and-dominant in absolute terms.

**Movement 2 — „Migracija utjecaja": where did attention move between platforms?**
- Source: `proportions_summary.rds` (already carries `interaction_share`/`reach_share` per platform-year). Buildable now.
- Chart: **interaction-share** (observed, higher quality) as the headline stacked-area/slope over time; reach-share
  only as a secondary, caveated panel restricted to web/youtube/facebook.
- Read: the „web produces, social engages" asymmetry shown as a *tilt over time*, not a single-year snapshot.

**Movement 3 — „Koncentracija utjecaja": is the space getting more top-heavy?**
- Source: `source_summary.rds` (year × FROM × interactions; 18.346 distinct actors). Buildable now **cross-platform**;
  the *honest per-platform* version needs a new aggregate (see §5, Phase 2).
- Chart: top-N actors' share of interactions per year (rising line = concentrating) + a one-line turnover read
  (how many of 2025's top-10 were not in 2021's).
- Read: „who holds the megaphone, and is the circle tightening?" — the most arresting idea for a lay reader.

**Optional Movement 4 — „Godišnji ritam" (seasonality) — DEFERRED to Phase 2, and only if kept minimal.**
- Would need a new monthly aggregate (see §5). **Heavily overlaps L4** (Uskrs/liturgical pulse, event detection).
  If built at all: raw **monthly volume climatology only**, no sentiment/theme/event overlay, with an explicit
  cross-link „za sadržajnu dinamiku oko konkretnih događaja vidi Fokus na događaje". Recommendation: **defer**;
  ship the three structural movements first.

## 4. KPI metric grid (4 cards, all COMPUTED inline — never hand-typed)

1. **Rast volumena** — ratio between two *complete* years (e.g. 2021→2025). *(sanity anchor: 90.388 → 236.166 ≈ ×2,6)*
2. **Najbrže rastuća platforma** — computed (candidate: YouTube).
3. **Koncentracija (udio top-10)** — top-10 actors' % of interactions (per-platform in Phase 2; caveated cross-platform in Phase 1).
4. **Razdoblje analize** — `2021.–2026.` (with „2026. nepotpuna" noted in prose/method).

## 5. Data requirements — what exists vs what's new (this is the key feasibility finding)

**Verified: `R/03_aggregate.R` EXISTS and the aggregates are FRESH** (rebuilt 2026-06-30; 2021–2026; all 9
platforms incl. instagram/tiktok; **710.307 rows total**). The stale `CLAUDE.local.md` note (2021–2025 / ~609k /
no IG-TikTok / "03_aggregate.R does not exist") is **wrong** and should be corrected (see §9).

| Movement | Aggregate | Exists? | Notes |
|---|---|---|---|
| Rast | `platform_summary.rds` | ✅ | year × SOURCE_TYPE; ready |
| Migracija | `proportions_summary.rds` | ✅ | shares precomputed; ready |
| Koncentracija (cross-platform) | `source_summary.rds` | ✅ | year × FROM; **no SOURCE_TYPE** |
| Koncentracija (per-platform) | `actor_year_platform.rds` (year × SOURCE_TYPE × FROM) | ❌ **new** | needed for the *honest* version |
| Ritam (seasonality) | `platform_monthly.rds` (month × SOURCE_TYPE) | ❌ **new** | needs master; monthly floor of DATE |

Both new aggregates are cheap group-bys added to `R/03_aggregate.R` (insert after the `proportions_summary`
section, ~line 65), each with its own `saveRDS(..., file.path(processed_dir, ...))`; then update the header
write-list and the trailing „Wrote N aggregates" message. **The page itself never writes aggregates** (CLAUDE.md
principle 4) — it only READs them.

> **HARD GATE:** producing the two new aggregates means running `Rscript R/03_aggregate.R` against the master,
> which overwrites tracked `data/processed/*.rds`. That requires explicit user confirmation and a master backup
> check. This is why the build is **phased**.

## 6. Phasing (respects the HARD GATE; ships value early)

- **Phase 1 — zero pipeline change, reads only existing tracked aggregates.**
  Build Rast + Migracija + Koncentracija (cross-platform, honestly caveated). Fully renderable/verifiable
  immediately; touches no master, mutates no `data/`. This is a complete, shippable v1.
- **Phase 2 — needs `R/03_aggregate.R` edit + HARD-GATE rerun.**
  Upgrade Koncentracija to **per-platform** (`actor_year_platform.rds`) and optionally add **Ritam**
  (`platform_monthly.rds`). Only after PI confirms the aggregate rebuild.

## 7. Page architecture (matches the house spine; clone the *structure* of `diskurs.qmd`, drop its NLP machinery)

Follows the fixed analytical spine (voice-and-style §9). Concrete, recon-verified conventions:

1. **YAML:** `title: "Evolucija ekosustava — <descriptive Croatian gloss> (2021.–2026.)"`, informative
   non-duplicative `subtitle`, `date: last-modified`, `categories: ["Evolucija ekosustava", "<method>", "<scope>"]`
   (first element = canonical layer name → drives the badge). Diacritics literal UTF-8. **No `freeze`/`eval` keys.**
2. **setup chunk** (`#| include: false`): `knitr::opts_chunk$set(echo=FALSE, message=FALSE, warning=FALSE,
   fig.width=14, fig.height=9, dpi=200)`. No `dev.args` (no base-graphics figure).
3. **libraries chunk** (`#| include: false`): load packages once; `source("../../R/theme_digikat.R")`
   immediately after `library(ggplot2)`.
4. **load-data chunk** (`#| include: false`): `readRDS` ONLY the tracked `data/processed/*.rds` needed
   (`platform_summary`, `proportions_summary`, `source_summary`, + Phase-2 files). **No master, no `data/nlp/`,
   no `saveRDS`, no copied `eval:false` master-processing block.** No thematic dictionaries (this map is structural).
5. **Lead** (`## Uvod…`): back-links to all prior layers by bare `mapa.html` / `mapa_stats.html` / `diskurs.html`
   / `događaji.html`; states scope („korpus od preko 710.000 objava … 2021.–2026."), the structural-vs-event
   boundary vs L4, the 3 questions, and the **„2026. je nepotpuna godina"** caveat (with the computed cutoff date).
6. **KPI grid:** raw-HTML `.metric-grid` of 4 `.metric-card` (de-indented to column 0), 4th card = `2021.–2026.`.
7. **Method note:** short reader-visible statement of population (objave passing ≥2-match inclusion — *not* all
   Croatian media), what each metric means, which platforms are excluded from which metric and why.
8. **Findings:** one `##` per movement — framing sentence → one figure (`labs(title=, subtitle=)` Croatian
   sentence case, `theme_digikat(base_size=16)`, `scale_*_digikat*`, `big.mark="."`) → **bold-led** read-out.
   Sections separated by `---`. No chart without narrative.
9. **Synthesis** (`## Sinteza…`): `::: {.featured-box}` headline finding + bold-lead paragraphs; final sentence
   forward-links the next layer (loop back to L1 or onward to L2).

Avoid the known `događaji.qmd` drifts: keep the canonical layer name as `categories[0]` and bolded in the lead;
put the KPI grid right after the first lead paragraph; single clean load chunk.

## 8. Metric-honesty rules (from the adversarial pass — non-negotiable for a defensible page)

- **2026 partial year:** never let a raw 2026 point anchor a growth/share claim. End primary series at the last
  complete year; render 2026 dashed/greyed „nepotpuna godina (do <mjesec> 2026.)"; compute the cutoff from the
  data, don't hand-type. (Verified anchors: 2021=90.388, 2022=84.042, 2023=83.835, 2024=114.725, 2025=236.166,
  2026=101.151.)
- **Concentration:** pooling interactions across platforms is apples-to-oranges (a YouTube like ≠ a web
  interaction ≠ a FB reaction; `FROM` counts the same brand on different platforms as different actors). Prefer
  **per-platform** CR-N (Phase 2). If the Phase-1 cross-platform version is used, label it explicitly as „udio
  među platformama koje bilježe interakcije", print `N_actors` beside every share, and exclude
  reddit/forum/comment/twitter (≈no interaction data).
- **Reach is low quality:** ≈99% concentrated in web/youtube/facebook; 18/49 platform-years have reach=0. Lead
  on interaction-share; treat reach as a secondary, caveated panel („procijenjeni potencijalni doseg; nije
  dostupan za sve platforme"). Never call reach realized attention.
- **Coverage onset:** instagram first appears 2024, tiktok effectively 2024; a rising share can reflect *when
  scraping began*, not real migration. Start each platform's line at its first reliable year; caption the caveat.
- **Every caption states:** population = corpus objave (≥2-match), the partial final year, which platforms are
  excluded from *that* metric, and that figures are computed inline from `data/processed/*.rds`.

## 9. Nav wiring + housekeeping

- **Nav:** add a 5th `- text:/href:` child (10-space indent) to the „Mapa medijskog prostora" navbar dropdown in
  `_quarto.yml`, right after „Fokus na događaje i kampanje" (after line 34), e.g.
  `- text: "Evolucija ekosustava"` / `href: pages/mapa/evolucija.qmd`. `project.render` already globs
  `pages/**/*.qmd`, so no render-list edit. **Do not touch** the „Tematska istraživanja" dropdown.
- **Filename:** `pages/mapa/evolucija.qmd` (no diacritic in filename → avoids the `događaji.qmd` đ hazard).
- **Recommended side-fixes (not blocking):** (a) correct the stale `CLAUDE.local.md` pipeline note
  (03_aggregate.R exists; 2021–2026; 710.307; IG/TikTok present); (b) fix/update the misleading dead
  `eval:false` clamp comment in `mapa.qmd` (still says 2025 / drops tiktok).

## 10. Implementation steps

**Phase 1 (build now, after approval):**
1. Scaffold `pages/mapa/evolucija.qmd` per §7 (Phase-1 chunks read only existing aggregates).
2. Add nav entry in `_quarto.yml` (§9).
3. Render ONE page from repo root with the RStudio-bundled Quarto; verify build, figures, diacritics, and that
   **no `data/processed/*.rds` changed** (verifier agent).
4. Commit (site page + nav) via `/commit` — never stage master/aggregates.

**Phase 2 (only after explicit PI confirmation — HARD GATE):**
5. Edit `R/03_aggregate.R`: add `actor_year_platform.rds` (+ optionally `platform_monthly.rds`); update header
   write-list + „Wrote N aggregates" message. Have r-reviewer read the diff.
6. **Confirm master backup exists**, then run `Rscript R/03_aggregate.R` from repo root; verify new files +
   unchanged inclusion rule; check row counts.
7. Upgrade Koncentracija to per-platform (+ optional Ritam) in the page; re-render + re-verify; commit
   (aggregates + page).

## 11. Verification plan

- Static: chunk syntax, `:::` balance, diacritics in source, canonical layer name in `categories[0]` + lead.
- Render (repo root, one page): clean build, figures present, literal UTF-8 diacritics, no scatter outside
  `docs/`, `md5sum data/processed/*.rds` unchanged (Phase 1).
- Numeric: numeric-claim-verifier re-derives KPI cards + per-year anchors from the aggregates.
- Domain: religion-media-domain-reviewer on the concentration/migration claims; ensure no L4 boundary bleed.

## 12. Rejected alternatives (so the "why" survives)

- **Fold temporal charts into L1 instead of a new map** — rejected: renumbering L2–L4 is churn, and "how it
  changes" is a genuinely distinct question deserving its own page; append as #5 and cross-link L1.
- **Lead concentration/migration on reach** — rejected: reach is provider-estimated, ≈99% in 3 platforms, absent
  for many; interaction-share is the honest headline.
- **Pooled cross-platform concentration as the rigorous metric** — rejected as the *primary*; apples-to-oranges.
  Per-platform (Phase 2) is the defensible form; cross-platform kept only as a caveated Phase-1 placeholder.
- **Animated bump charts / network graphs / interactive plotly** — rejected: violates the "simple, followable"
  goal; reads as intricate.
- **Include seasonality (Ritam) in v1** — deferred: overlaps L4's territory and needs a new master-derived
  aggregate; ship the three structural movements first.
- **Trim 2026 out entirely** — considered; preferred instead to *show* 2026 as an explicit partial-year segment
  so the corpus's true extent is visible without letting it anchor a trend claim.

## 13. Decisions (locked 2026-07-01)

1. **Name:** **Evolucija ekosustava** → `pages/mapa/evolucija.qmd`, nav text „Evolucija ekosustava".
2. **Concentration:** **Phase-1 cross-platform (caveated) now**, per-platform upgrade deferred to Phase 2.
3. **Seasonality (Ritam):** **included now (volume-only climatology)** — this pulls the `platform_monthly.rds`
   aggregate (and therefore a HARD-GATE `R/03_aggregate.R` rerun) into the first build.
4. **2026 handling:** **dashed „nepotpuna godina" segment**, cutoff computed from the data.

### Consequence of decision 3 — build is no longer pipeline-free
Because seasonality is in, the first build needs `platform_monthly.rds`, which only `R/03_aggregate.R` can
produce from the master. The Phase 1 / Phase 2 split in §6 therefore collapses for *this* build: the aggregate
rebuild (HARD GATE) must happen before the page can render. Concentration still ships in its cross-platform
(caveated) form; the per-platform upgrade remains genuinely deferred.

### Status of files (written this session, un-rendered, uncommitted)
- `pages/mapa/evolucija.qmd` — new page, 4 movements (Rast / Migracija / Koncentracija / Godišnji ritam),
  reads only `data/processed/*.rds`, all numbers computed inline, 2026 dashed. **Cannot render until
  `platform_monthly.rds` exists.**
- `R/03_aggregate.R` — added `platform_monthly` block (section 2b) + header write-list + „Wrote 11 aggregates".
- `_quarto.yml` — added the 5th navbar-dropdown entry after „Fokus na događaje i kampanje".
- This plan.

### Remaining gated steps (need explicit PI confirmation)
1. **HARD GATE — run `Rscript R/03_aggregate.R`** (pause Dropbox; confirm master backup exists; it reads the
   1.19 GB master and overwrites the 10 tracked `data/processed/*.rds` + writes `platform_monthly.rds`).
   Verify: the 10 existing aggregates are unchanged (md5 before/after) and only `platform_monthly.rds` is new;
   if the 10 changed, the master moved since 2026-06-30 — investigate before proceeding.
2. **Render one page** from repo root (RStudio-bundled Quarto); verify build/figures/diacritics, no scatter
   outside `docs/`, and that the render mutated nothing in `data/`.
3. `/commit` the page + nav + aggregate script + the new `platform_monthly.rds` (never the master/backups).

### Recommended non-blocking follow-ups (surfaced by recon)
- Correct the stale `CLAUDE.local.md` pipeline note (03_aggregate.R exists; 2021–2026; 710.307; IG/TikTok present).
- Fix the misleading dead `eval:false` clamp comment in `mapa.qmd` (still says 2025 / drops tiktok).
- **MEMORY.md [LEARN] candidate:** the master's `DATE` is a **character** ISO string, NOT a `Date` — so
  `format(DATE, "%Y-%m-…")` errors (reads the pattern as `trim=`); floor to month via `substr(DATE,1,7)` or
  coerce with `as.Date(DATE)` first. The existing `03_aggregate.R` date-range filter (lines 37–38) "works"
  only via `Ops.Date` coercion of a character operand — fragile pre-existing backlog, left untouched here.

## 14. Review round 1 — incorporated (2026-07-01, before any render)
Two read-only reviews (r-reviewer + religion-media-domain-reviewer) ran against the written files. All
material findings fixed in `pages/mapa/evolucija.qmd` / `R/03_aggregate.R`:
- **BLOCKER (R):** char-`DATE` would have errored the `platform_monthly` mutate and halted the whole aggregate
  run → fixed with `substr(DATE,1,7)` flooring; kept surgical so the 10 existing aggregates regenerate unchanged.
- **CRITICAL (domain):** the concentration story was **backwards** — top-10 interaction share *falls* ~55,8 %
  (2021) → ~23,1 % (2025) while the actor pool ~triples, i.e. the space **de-concentrates / broadens**. Movement 3,
  the synthesis, the section heading, and KPI card 2 (now „Rast broja aktivnih aktera") rewritten accordingly;
  hardcoded „blago"/„izrazito koncentriran" replaced with a computed magnitude word.
- **Major:** TikTok (~507k interactions) was missing from the „Kako čitati" interaction-platform list → added,
  and the „ne ulaze u nazivnik" wording corrected (they carry 0 %, remain in the denominator). Top-10 actor set
  now excludes non-actor buckets (`anonymous_user`) with a disclosed caveat that „akter" = raw FROM handle.
  Migration read-out + synthesis carry the coverage-onset caveat (IG/TikTok enter 2024; FB low 2021 base).
- **Minor:** `geom_area` given an explicit zero baseline via `tidyr::complete(...)`; length-0 subscript guards
  (`stopifnot`) added; „Ritam" liturgical gloss softened to „u skladu s"; `tidyr` added to libraries.
Verdict shift: with these fixes the page's headline finding is now data-honest (broadening, not concentrating).
Still un-rendered — the R changes are verified statically only; render after the HARD-GATE aggregate build.
