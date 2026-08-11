# PROMPT — "Nosi li se glas Crkve?" / Does the Church's voice carry?

> Paste this prompt into a Claude Code session in the DigiKat repo to develop the
> message-penetration study. It is a RESEARCH-DESIGN brief first, a coding brief second;
> nothing here authorizes touching the master or the aggregate builder.

---

## The idea

The Croatian Catholic Church's entire media strategy exists to "make the voice of the
Church more audible in society" (HBK's stated modernization goal), and its standing
grievance is that secular media ignore or distort it. Nobody measures either claim.
This study builds the instrument: **does Church-originated messaging actually penetrate
secular Croatian digital media coverage — and who leads whom on religious topics?**

This is simultaneously (a) a publishable agenda-setting / intermedia study in a language
and religious context that is under-researched, and (b) the single most decision-relevant
number DigiKat can hand the HBK — which makes it the "wow" chapter of the planned
flagship report and the anchor of the observatory pitch.

## Why the corpus can support it

- The corpus is TOPICAL, not source-based: it already contains both confessional outlets
  (hkm.hr #1 at ~8%) and secular mainstream coverage of religious topics. The secular
  side of the comparison is already collected.
- A confessional/secular outlet labeling exists (~53% classified, PI-owned, indicative).
- A semantic index of the corpus exists (`data/semantic/digikat.ragnar.duckdb`, ~13.6 GB,
  local/ignored) — the natural engine for similarity-based uptake matching.
- Daily timestamps allow lead–lag analysis; the 16-category dictionary allows per-theme
  agenda comparison.

## Candidate measurements (develop, then rank by feasibility × value)

1. **Statement uptake tracking.** Take official Church communications as source signals —
   HBK/Iustitia et pax statements, IKA dispatches, major homilies/press releases
   (IKA dispatches in the corpus are themselves a usable proxy for "what the Church said").
   Measure: what fraction of these signals gets ANY uptake in secular outlets within
   k days; with what latency; with what tone; and how much of the original framing
   survives. Matching via semantic similarity against the ragnar store + quotation/
   phrase-overlap detection; every automated match layer must be precision-audited
   before any rate is published (see Discipline, below).
2. **Intermedia agenda-setting (lead–lag).** Per 16-category theme, daily/weekly series
   of confessional vs secular attention; cross-correlation at lags / Granger-style tests
   to establish who moves first. Deliverable claim shape: "on themes X, Y the confessional
   ecosystem leads secular coverage by N days; on themes Z it follows."
3. **Voice share.** In secular items on religious topics, how often are Church actors
   quoted or named as sources (vs the Church being talked ABOUT without being heard)?
   Likely needs NER + quotation heuristics on a stratified sample, human-audited.
4. **Frame survival.** For a small set of major episodes, code whether secular coverage
   adopts the Church's framing, a conflict/scandal framing, or an independent framing.
   Qualitative-leaning; feeds the report chapter with narrative depth.

## Design requirements

- **Route the formalization through `/research-ideation`** (scholar-idea panel) to sharpen
  the RQ, then `/lit-review` with the DigiKat discipline card. Anchor literatures:
  intermedia agenda-setting (Vliegenthart/Walgrave tradition), church communication
  studies, hybrid media systems. The gap statement should name the closest prior paper.
- **Pilot on 2–3 well-defined episodes first**, e.g. the 2024 Iustitia et pax
  pre-election statement (known public controversy), one papal event, one scandal-type
  event. Small, datable, checkable by hand. Only then generalize.
- **Scaffold via `/new-study`** (slug suggestion: `voice-carry`), standard folder layout;
  anything with URLs, outlet names at row level, or text excerpts goes to
  `output/private/` (enforced by `R/check_disclosure.R`).

## Discipline (hard lessons from MEMORY.md — they apply directly here)

1. **A keyword/similarity linkage layer is NOT a validated denominator.** The
   moral-economy audit found a "linked" layer only 39,5% genuine. Any published rate of
   the form "X% of Church statements were taken up" must divide by an audited precision
   of the matching layer, with the interval propagated. Budget a gold-set coding round
   (fresh RANDOM draw, not a re-sliced stratified set) before any headline number.
2. **Join annotations back on the item index and assert the id agrees** — the transcription
   gate that caught mis-keyed rows before.
3. **State units explicitly** (statements vs statement–outlet pairs vs posts) — the
   invocation-rate unit-mixing lesson.
4. **Lemma-level normalization must be identical on both sides of any lexical match**,
   lowercase before tokenizing, UTF-8 explicit.
5. **The 2024 stream confound**: uptake RATES compared across years must condition on
   collection stream + platform; safest is to run the pilot entirely within 2024–2026.
6. Sentiment layers key on lemmas (CroSentilex/Gold/lilaHR) — same normalization or
   coverage collapses.

## Deliverables of the first engagement (in order)

1. `studies/voice-carry/DESIGN.md` — formalized RQ + hypotheses, the four measurement
   candidates ranked with feasibility notes against the ACTUAL corpus (verify column
   availability: can IKA dispatches be identified? is the outlet label usable at scale?
   what does the semantic store's schema support?).
2. A feasibility probe (read-only, sample-based): for ONE pilot episode, pull the
   candidate signal posts and candidate secular uptake posts, hand-inspect ~50 pairs,
   and report a first precision estimate for semantic matching. No master mutation,
   no aggregate changes.
3. A measurement plan for the gold-set audit (sampling frame, coding rules, target n,
   double-coding/reliability plan).
4. A one-paragraph "report chapter shape" — what the flagship-report version of this
   finding would say if the pilot succeeds, in plain Croatian, so the analysis is
   designed toward a communicable claim from day one.

## Process requirements

- Plan-first: enter plan mode, save the plan to `quality_reports/plans/` before any
  files are created.
- R + master are on this machine per `CLAUDE.local.md`; sample-first (never load 710k
  rows into context); pause Dropbox sync for heavy semantic-store queries and never
  sync the duckdb while open.
- Review chain before anything is called a result: `r-reviewer` on the code,
  `croatian-nlp-reviewer` on the matching/normalization layer,
  `numeric-claim-verifier` on any headline rate.
