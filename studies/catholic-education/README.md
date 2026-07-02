# Study: Catholic *lieux de mémoire* — education as a site of memory transmission

- **Slug:** `catholic-education`
- **Owner:** memory-studies researcher (asistentica, *Mjesta sjećanja*; disertacija povijest × komunikologija)
- **Status:** planned (proposal written, pre-data)
- **Created:** 2026-06-30

## Research question
**Descriptive / interpretive** (memory studies × sociology of religion × media studies — see the discipline card).

- **Q1 (detection):** Which candidate Catholic anchors in the *education* field behave like *lieux de mémoire* —
  i.e. score jointly on **recurrence × temporal peaking × affective charge × past-anchoring** (the four-signal
  construct) — and which are flat present-tense topics?
- **Q2 (falsifiable core):** When *Catholic education* is invoked (`vjeronauk`, katoličke škole, HKS, SHKM, the
  teaching orders), is it **anchored to the past** (Stepinac, komunizam, 1991., kršćanski korijeni) — *memory
  transmission* — or framed as a **contemporary value/curriculum dispute** with no memorial anchoring?
- **Q2½:** Which actors (Giants / Community-Builders / Megaphones / Specialists) activate these anchors, and with
  what emotional register?

Full design, theory, and guardrails: [PROPOSAL.md](PROPOSAL.md).

## Corpus slice
- **Platforms:** all (web portals dominant · YouTube · Facebook · Twitter · Reddit · forums).
- **Terms / theme filter:** the global ≥2-match religion filter is **unchanged**; this study layers a *study-local*
  education-and-memory **entity probe** on top (see PROPOSAL §4) and reuses the existing
  `POVIJEST_I_NACIONALNI_IDENTITET` theme category for past-anchoring. **Does NOT redefine the corpus.**
- **Date range:** 2021–2025.
- **Sample:** **Stage A** = stratified 2–5 % (platform × year) for preliminary detection; **Stage B** = narrowed
  evidence-driven set (the survivors' actual posts, full corpus) for qualitative coding.

## Method
Three stages (PROPOSAL §5): **A** computational detection (four-signal scoring → ranked candidate table) →
**B** evidence-driven corpus selection → **C** qualitative discourse analysis with hand-validation + IAA.
Honesty guardrails (co-occurrence ≠ activation; homonym audit; provisional vs validated numbers) per PROPOSAL §6.

## Outputs
- working files in this folder; figures/tables/`slice.rds` in [`output/`](output/) (gitignored content).
- published page (later): `pages/studije/catholic-education.qmd` — **not yet wired in `_quarto.yml`** (proposal stage).

## Declarations (on publication)
- Data availability: see `/DATA_AVAILABILITY.md`
- AI-use disclosure: Claude Code used in the analysis pipeline

## Log
- 2026-06-30 — Study scaffolded from a memory-studies proposal. Spine fixed to **education-as-memory-transmission**
  (figures/orders + rituals kept as secondary signals). RQ sharpened via `/research-ideation`; four-signal
  operationalization of *lieu de mémoire* adopted as the measurable construct.
- 2026-06-30 — `croatian-nlp-reviewer` audited `slice.R`; fixes applied + verified (parse + recall spot-checks):
  **C1** DATE now parsed as real `Date` with a visible NA-drop count (no more silent date-drop bias);
  **C2** guard refuses the redacted disclosure sample (no false-empty table);
  **M3/M4/M5** past-anchor token now covers `komunist*`/`sekular*`/ASCII `zrtv*`/`rat*` inflections (the
  falsifiable-core signal); **m8** `katolička … škola` allows an intervening word; **M6** `redovi`→`redovi_orders`.
  Probe is SAFE TO RUN as a recall-first detection pass (precision fixed downstream by hand-validation).
- 2026-06-30 — 5-lens adversarial pressure-test of the PROPOSAL (memory-theory · religion-media domain ·
  measurement · devil's-advocate · feasibility), findings skeptically verified. Hardening applied:
  **slice.R** now computes **windowed** past-anchoring (±160 chars) with a genuine-vs-incidental split (verified:
  far-apart co-mention → not counted) + a `stepinac`/`odgoj` construct-validity control print + honest 2-of-4-signal
  framing; **PROPOSAL** Q2 reframed binary→**proportion** ("both, strategically blended" as a 3rd outcome); §3 decision
  rule now **operational thresholds + graded composite + pre-declared foil/positive-control**; §5 adds a **rare-*lieu*
  full-corpus allow-list** (sample is a speed gate, not a candidacy gate); §6 adds **circularity + secular-frame +
  κ/incidental-rate** limits; §7 hedges the "first" claim and promotes **actor-decomposition** as co-equal novelty;
  §9 adds a **scope-honesty** note (four signals measure memorial framing; identity/values via Stage C).
  Next: Stage-A `/data-analysis` on a REAL stratified sample (NOT the disclosure sample). `/lit-review` in parallel.
