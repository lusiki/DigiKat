# PROMPT — Design and pilot the DigiKat flagship report (Reuters-DNR-inspired)

> Paste this prompt into a Claude Code session in the DigiKat repo when ready to start.
> It is a DESIGN + PILOT brief: the outcome is a fixed report architecture and an internal
> "izvještaj 0" dummy — not a public publication. Plan-first rules apply.
>
> **STATUS 2026-08-10:** Tasks 1–5 are substantially EXECUTED (see `studies/annual-report/` —
> CHARTER.md, INDICATORS.md, PIPELINE.md, izvještaj 0 rendered). The spec sections v2/v3
> below have been CONSOLIDATED into the canonical, auto-loaded writing guide:
> `.claude/rules/annual-report-writing.md`. On any conflict, that rule file and the
> study's CHARTER.md supersede this prompt.

---

## Role and context

You are working in the DigiKat repository (Hrvatsko katoličko sveučilište; PI doc. dr. sc.
Luka Šikić). DigiKat holds a ≈710k-post corpus of Catholic-themed Croatian digital media
content (2021–2026) with a validated pipeline: 14 tracked aggregates in `data/processed/`,
page-ready NLP inputs in `data/page-ready/`, four analytical layers (Mapa ekosustava,
Tematske struje, Atmosfera diskursa, Fokus na događaje), an actor typology
(Giants / Community Builders / Megaphones / Specialists), and a proven
generator → sync → checks tooling pattern from the RSP paper
(`26_rsp_tables.R` → `27_sync_tables.R` → `25_paper_checks.R`).

The goal is a recurring flagship publication modeled on the Reuters Institute Digital News
Report's institutional logic: **a stable spine of indicators measured identically every
edition, rotating special chapters, a fixed publication date, transparent methodology.**
Primary audience: HBK's Committee for Social Communications, the HKM leadership, and
editors of Catholic and secular outlets. Secondary audience: scholars and funders. The
report is the shop window of a future observatory; its authority depends on a hostile
reader failing to find a thumb on the scale.

## Non-negotiable constraints (from CLAUDE.md / MEMORY.md — verify them there)

1. **The 2024 stream confound.** `data_source` splits the corpus into two time-segregated
   collection streams (original_dta 2021–2024; filtered_religious 2024–2026;
   Instagram/TikTok only from 2024). Cross-year volume trends are confounded.
   The comparable time series therefore STARTS AT 2024; earlier years appear only as
   stream-conditioned context, and the methodology box says so explicitly.
2. **No hand-typed numbers.** Every scalar in prose comes from a generated `derived.csv`;
   every table is an installed fragment; a checks script fails the build on drift.
3. **Disclosure gates.** Named profiles only for institutional media outlets, never
   individual accounts; small-cell suppression; `/disclosure-check` before any release.
   `*_actors.rds` files are the re-identification risk surface.
4. **Labeling honesty.** Confessional/secular outlet composition is ~53% classified and
   PI-owned; frame all such shares as indicative.
5. **Language.** Report prose Croatian (č ć ž š đ intact, UTF-8); an English executive
   summary; project/internal docs English. House voice per `.claude/rules/voice-and-style.md`.
6. **Figures** route through `R/theme_digikat.R`; no hard-coded colors.
7. Quarto renders from the repo root only; the report build must never touch `docs/`
   except through the normal deploy path.

## Task 1 — Editorial charter (one page, decide and write down)

Draft `studies/annual-report/CHARTER.md` fixing:
- **Name** (working title: *Katoličke teme u hrvatskom digitalnom prostoru: godišnji
  pregled* — propose 2–3 alternatives; the name should scale beyond Croatia).
- **Cadence**: recommend and justify one of (a) annual flagship, (b) annual flagship +
  light mid-year data brief (biannual rhythm). Consider production cost per edition —
  the mid-year brief must be a build target, not a second manuscript.
- **Publication date** anchored to the Church calendar (World Communications Day,
  May/June) and the implied data cutoff (calendar-year coverage needs the append
  pipeline run through December).
- **Audience order and register** (decision-makers first, scholars second; findings
  first, methods in a box; ~25–30 pages).
- **Independence statement** (funding, CC BY, no editorial input from covered actors,
  PI as editor).

## Task 2 — Indicator codebook (the spine; the real work)

Draft `studies/annual-report/INDICATORS.md`: 8–10 recurring indicators, each with
(a) plain-Croatian definition a bishop can read, (b) exact source aggregate or required
new aggregate, (c) known caveats, (d) comparability rule across editions. Start from:

| # | Indicator | Candidate source |
|---|---|---|
| 1 | Volume of Catholic-themed coverage, total + per platform | `platform_summary`, `platform_monthly` |
| 2 | Confessional vs secular share of coverage | `source_summary` + PI labels (indicative) |
| 3 | Top actors per platform | `top_*_sources.rds` |
| 4 | Actor-typology distribution and movement between types | `*_actors.rds` |
| 5 | Engagement benchmarks per actor type and platform | `*_actors.rds` |
| 6 | Thematic profile (16-category dictionary) + year's movers | `page-ready/mapa_stats.rds` |
| 7 | Tone + conflict index, overall and on top themes | `page-ready/diskurs.rds` |
| 8 | Events of the year (attention peaks, sentiment shifts) | `page-ready/dogadjaji.rds` |
| 9 | (optional, if voice-carry pilot matures) Church-voice penetration into secular coverage | new |
| 10 | (future) Audience-side indicator from survey module | new |

For each indicator flag: computable today / needs a new aggregate (extend the aggregate
builder as a SEPARATE report-specific script, not by silently changing `R/03_aggregate.R`)
/ blocked. Changing an indicator definition after edition 1 breaks the product — spend
the review effort here.

## Task 3 — Report anatomy

Specify the document structure (write into CHARTER.md):
1. **Sažetak** — ~10 key findings, each carrying exactly one number; written last,
   designed first. English translation of this section only.
2. **Metodologija** — one page: corpus, inclusion-rule pointer, 2024 baseline decision,
   labeling caveats, links to open aggregates.
3. **Four chapters = the four analytical layers** (existing controlled vocabulary as
   permanent chapter names).
4. **Annex: per-actor mirror profiles** — one page per named institutional outlet
   (reach, engagement vs type benchmark, thematic profile, platform mix).
5. **Rotating special chapter** — sourced from that year's thematic study.

## Task 4 — Production pipeline design

Specify (do not yet fully build) the build chain, copying the RSP paper pattern:
- `studies/annual-report/` numbered scripts: data-readiness audit → report aggregates →
  tables/figures generator + `derived.csv` → fragment sync → checks (byte-identical
  fragments, every quoted scalar present) → Quarto render (site page + PDF via the
  Typst route, building OUTSIDE the repo like `28_render_paper.R`).
- The annual runbook as an ordered checklist: ingest cutoff → `/refresh-data` →
  aggregates → report build → `/disclosure-check` → `numeric-claim-verifier` +
  `religion-media-domain-reviewer` agents → render → embargo pre-brief → `/deploy`.

## Task 5 — Izvještaj 0 (the pilot dummy)

Assemble an INTERNAL pilot from existing aggregates only: real numbers, rough prose,
full structure. Purpose: surface structural problems (boring indicators, thin profiles,
missing data) before anything is public. Output: `studies/annual-report/output/` (and
anything row-level or named-account into `output/private/`). Do NOT publish, do NOT
add to `_quarto.yml` nav, do NOT run `quarto render` full-site.

## Report spec v2 (added 2026-08-10) — decision-maker edition parameters

This spec REFINES Tasks 1 and 3 above: the report family is a conversion instrument
(free flagship → briefing requests → commissioned analyses), not a methods showcase.

**Family:** annual flagship (May, World Communications Day + spring HBK plenary,
24–32 pp) + biannual "puls" brief from the 2025-covering edition onward (November,
autumn HBK plenary, 8–12 pp, 5 findings, build-target cheap).

**Design rules:**
1. Three-minute rule — the sažetak alone delivers the year; full read ≤45 min; all
   methods behind one "Kako mjerimo" box + link to online methodology.
2. One number per finding; max 10 findings (annual) / 5 (puls).
3. Figure-first; every figure title states the FINDING, readable standalone
   (designed to be lifted into IKA articles and decks).
4. Named actors everywhere (rankings, movers) — every ranking is an implicit pitch
   to everyone ranked and everyone omitted.
5. One composite headline index (e.g., Indeks digitalne prisutnosti Crkve) reported
   with movement every edition — the recurring, quotable, anticipatable hook.
6. Teaser depth: each aggregate finding carries one italic line noting the
   disaggregation exists as a commissioned analysis.
7. Each chapter ends with a "Pitanja koja podaci otvaraju" box — 2–3 deliberately
   unanswered questions = the commission menu written as curiosity.
8. One boxed "Primjer dubinske analize" one-pager inside the report — the product demo.
9. THE WALL: selling confined to the boxes and the back page; findings prose stays
   uncompromised or the document's authority (and price premium) dies.
10. Invisible rigor: simplified presentation, unchanged production discipline
    (derived.csv scalars, checks gate, disclosure screen).

**Annual outline:** cover + year's one number → uvodnik (1 pp, independence) →
sažetak 10 findings (2 pp) → index (1 pp) → Ekosustav (rankings, typology; gate:
mirror profiles) → Teme (movers; gate: theme deep-dives) → Atmosfera (tone, conflict;
gate: reputation/crisis analysis) → Događaji (timeline + 2 event boxes, one = demo;
gate: campaign evaluation) → Posebna tema (rotating; voice-carry when mature) →
annex: 5–8 mirror one-pagers → Kako mjerimo → back page "Analize po narudžbi" menu
(Profil aktera · Dubinska tematska analiza · Evaluacija kampanje/događaja · Analiza
dosega poruke · Radionica za tiskovne urede; prices na upit) + CTA: free 45-minute
institutional briefing.

**Puls outline:** cover number → 5 one-page findings → index update → one theme
spotlight → one event box → half-page menu + briefing CTA. Producible in <2 weeks
from the standing pipeline.

**Per-edition derivatives (produced WITH the report):** 10-slide briefing deck
(doubles as the sales-meeting material), 1-page infographic, 3-number press release.
The measurable KPI of every edition is BRIEFING REQUESTS, not readers.

## Report spec v3 (added 2026-08-10) — recurring topic canon + visual & voice system

The chapter canon is derived from the best recurring reports worldwide (Reuters DNR,
Edelman Trust Barometer, DataReportal, Ofcom news consumption, Pew/Barna religion
reporting), NOT from DigiKat's existing page structure. Principles learned from them:
stable READER QUESTIONS (not stable datasets); the same chart redrawn with new numbers
every edition (recognition = following); one named composite index; movers/risers-fallers
as standing furniture; one rotating special chapter for the year's standout finding.

**The eight recurring chapters (each titled as the reader's question):**
1. *Koliki je prostor?* — headline dashboard: size, growth, actors, engagement totals
   (DataReportal-style opening spread; 8–10 big numbers, each with YoY arrow).
2. *O čemu se govorilo?* — the agenda: top themes, biggest movers, timeline of the
   year with attention peaks; "moment godine" as a recurring named fixture.
3. *Tko vodi?* — league tables: top actors by platform, risers/fallers, typology map
   (DNR brand-chart logic: same table every year, movement visible at a glance).
4. *Gdje se razgovor seli?* — platforms: share shifts, format trends (video/short-form),
   where growth and engagement concentrate (DNR platform-chapter logic; the most
   action-inducing chapter for editors).
5. *Kakvim se tonom govori?* — the barometer: tone balance, conflict index, where
   hostility concentrates (Edelman logic: a named recurring index with movement).
6. *Nosi li se glas?* — voice & penetration: confessional share of voice, uptake of
   Church messaging in secular coverage, who leads whom (the differentiator chapter;
   fed by the voice-carry study as it matures).
7. *Tko sluša?* — audiences: engagement-as-proxy at first; graduates to survey data
   (reach, trust, consumption habits) once the survey module exists (DNR core logic).
8. *Posebna tema* — rotating special chapter; ALSO the frame for "the year's most
   interesting finding" promoted to the cover.

**Standing furniture in every edition:** the composite index with movement; "10 brojeva
godine" spread; league table with ▲▼ arrows; timeline of the year; one "mit i podaci"
box (a common belief tested against the data); and from edition 2 onward "što smo rekli
prošle godine" (last edition's key numbers revisited — the accountability page that
builds trust and makes editions feel serial).

**Visual system:**
- One chart FORM per recurring topic, identical every edition; only numbers change.
- Restricted chart vocabulary: bars (ranked, horizontal), lines (time), slope charts
  (two-point change), dot/lollipop (comparison), small multiples; simple share stacks
  allowed; NO pies beyond binary shares, no dual axes, no 3D, no radar.
- Direct labeling on marks instead of legends wherever possible; figure title = the
  finding; subtitle = the measure; footer = source + period on every figure.
- All figures through `R/theme_digikat.R` tokens (cream paper, white panel, fixed
  platform colors, blue=+/red=− diverging); Croatian number formatting (decimal comma,
  thin-space thousands).
- Tables as "ranked cards": rank, name, one key number, ▲▼ change vs last edition,
  optional sparkline; never more than 5 columns; every table answers one question
  stated in its title.
- Accessibility: color never the only encoding; all figures legible in grayscale print.

**Voice parameters ("službeno, ali toplo"):**
- Short sentences, active voice, verbs over nominalizations (avoid the Croatian
  bureaucratic register: "provedena je analiza" → "analizirali smo").
- Every technical term explained at first use in plain Croatian; no untranslated
  English jargon in body text.
- Honest uncertainty in plain words ("procjena", "otprilike", "u ovom uzorku"), never
  academic hedging chains and never false precision.
- The uvodnik is allowed warmth and first person; findings prose stays measured;
  humor no, humanity yes.
- Numbers in prose: max one per sentence; comparisons anchored to familiar magnitudes
  where possible.

## Process requirements

- Enter plan mode first; save the plan to `quality_reports/plans/` before touching files.
- Scaffold the study folder via the `/new-study` skill (slug: `annual-report`).
- R and the master are on this machine per `CLAUDE.local.md` — verify before running;
  pause Dropbox sync for long runs.
- Deliverables of THIS engagement: CHARTER.md, INDICATORS.md, pipeline spec,
  izvještaj 0 draft, and a gap list of what edition 1 needs that the repo cannot yet
  produce (with effort estimates).
