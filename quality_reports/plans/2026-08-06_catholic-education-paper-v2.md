# Plan — Catholic-education working paper → submission-ready journal article (v2)

**Date:** 2026-08-06 · **Study:** `studies/catholic-education/` · **Status:** approved framing (chat, 2026-08-06), execution pending
**Goal:** transform `WORKING_PAPER.md` (v0.1) into a homogeneous, robust, submission-ready manuscript
(`PAPER_v2.md`) with one headline, a validated evidence base, and a mechanical prose-equals-data guarantee.

---

## 0. The framing decision (already agreed — record of "why")

**One spine, one headline:** *In Croatian digital media (2021–2025), the Church's designated instrument of
memory transmission — education — is mediated in the present tense; the work of cultural memory is carried by
the martyr figure (Stepinac) instead.*

- The **four-signal instrument** and the **69,4 % incidental-overlap result** are demoted to supporting roles
  (methods section + one discussion paragraph each). They are NOT co-headlines. The method-forward paper
  ("detecting *lieux de mémoire* at scale") is a separate future paper for a computational venue — do not
  spend it here.
- **Section 4 "Hipoteze" is replaced by research questions.** H2/H3 are post-hoc by the draft's own admission
  ("refinements the first analysis suggested") — a referee magnet. New structure: RQ1 (which anchors behave
  as sites of memory vs present-tense disputes, with the ONE genuinely pre-committed expectation stated —
  memorial anchoring concentrates in figures, not institutions) + RQ2 (who carries each anchor, in what
  register). Stepinac-as-shared-national-site and conflict-vs-trust become *findings*, not hypotheses.
- **Primary venue: *Memory Studies*** (operationalizing Nora is their kind of contribution; tolerant of
  descriptive/interpretive stance). Fallback: *Journal of Media and Religion*. NOT *New Media & Society*
  for this version (the platform/actor-typology results are the weakest part).
- **Rejected alternatives:** method-forward framing (weaker substantive fit for *Memory Studies*; burns the
  second paper); keeping the hypothesis apparatus (post-hoc exposure); NM&S (weak platform results).

**Controlled vocabulary (fixed on page one, never varied):** *anchor* (a scored entity), *the education
strand* (the 176 312-post sub-corpus), *genuine anchoring* (windowed past co-occurrence), *the split* (the
headline finding). Every term explained at first use; flowing academic prose per house style (no run-in
bold headings, no label-then-explanation constructions).

---

## 1. Inventory — what exists and is reused as-is

| Asset | Location | Role in v2 |
|---|---|---|
| Working paper v0.1 | `WORKING_PAPER.md` | source text; §5 (methods) and §7 (discussion) survive nearly intact |
| Stage-A findings + audit trail | `FINDINGS_STAGEA.md` | provenance for every number; §6 documents the data_source confound |
| Ranked candidate table | `output/candidate_sites_of_memory.csv` | half of future Table 1 |
| Peaking, affect, actors, sources | `output/tables/*.csv` (9 files) | Table 1 columns + §6.2–6.4 evidence |
| Figures (4) | `output/figures/*.png` | Fig. 1–3 candidates (restyle check only) |
| Analysis scripts | `slice.R`, `signal2_actors.R`, `conf_secular.R`, `signal3_affect.R` | re-run only where Phase 2 changes inputs |
| Reproducibility machinery (sister study) | `studies/moral-economy/{26_rsp_tables,27_sync_tables,25_paper_checks,28_render_paper}.R` | adapt in Phase 5 |
| Bibliography scaffold | `refs.bib` (empty, 14 lines) | filled in Phase 4 |

**Guardrails (non-negotiable, all phases):** master and `data/` untouched — this study only READS;
all study writes go to `studies/catholic-education/output/`; anything row-level (text, URLs, source
identities) goes to `output/private/` (gitignored, `R/check_disclosure.R`-enforced); Dropbox sync paused
for any full-master R run; Quarto/R always from repo root; Croatian diacritics verified after every
generation step. R IS available on this machine (`CLAUDE.local.md`).

---

## 2. Phases

### Phase 0 — PI decisions (blocking; collect in one sitting)
1. **Venue + language** — confirm *Memory Studies* (EN). Drops the bilingual section headers; the Croatian
   sažetak is kept only if the venue takes one.
2. **Strossmayer path** — recommend **Path A**: add a 19th-century past-token register (narodni preporod /
   national-revival vocabulary) and re-run scoring, so "the instrument is register-sensitive" becomes a
   *demonstrated* point. Path B (scope the paper to 20th-century rupture memory, one limitation sentence)
   only if Path A's re-run stalls.
3. **Title** — recommend keeping the narrative title: *Faith in the present, memory in the martyr: Catholic
   education and the figure of Stepinac as sites of memory in Croatian digital media (2021–2025)*.
4. **Second coder** — name the person for the κ hand-validation (Phase 3 cannot finish without them; the
   study owner / asistentica is the natural first coder).
5. **Outlet labels** — reconfirm the PI owns the confessional/secular label set and accepts publishing it
   as "proposed and contestable, covering 30–44 % of posts", with the Phase 2 sensitivity note.

### Phase 1 — Analysis hardening (R; full-master runs; pause Dropbox)
1. **19c register (Path A).** New script `past_register_19c.R` (or a flag in `slice.R`): a small,
   pre-declared token set for national-revival memory (e.g. `preporod`, `ilirsk`, `biskup bošnjak/đakovačk`
   contextual forms — draft the list, then have `croatian-nlp-reviewer` audit inflections BEFORE the run).
   Re-run windowed scoring → `output/candidate_sites_of_memory_v2.csv` with BOTH registers side by side
   (20c column, 19c column, combined). Pre-commit the reading: Strossmayer is expected to rise on the 19c
   register; Stepinac should NOT (that asymmetry is itself evidence the registers measure different memories).
2. **Table 1 builder.** New script `paper_tables.R` (Phase 5 will grow it): assemble the paper's centerpiece —
   **four signals × 8 anchors summary table** (recurrence n; genuine windowed anchoring + incidental share;
   peaking CV + recurring-month flag; dominant lilaHR register + coverage %; composite reading) from
   `candidate_sites_of_memory_v2.csv`, `temporal_peaking_by_entity.csv`, `affect_by_entity.csv`.
3. **Foil reframe check.** From `bundle_subtoken_counts.csv`, generate the one table/paragraph that presents
   `odgoj_vrijednosti` explicitly as the pre-declared foil (driven by `vrijednost` 60 698 / `odgoj` 27 455;
   `kršćanski korijeni` n=1; `kurikul` 1 910) — turns the draft's soft underbelly into validation design.
4. **Outlet-label sensitivity.** Small script: recompute the §6.3 confessional shares under (a) labelled-only
   and (b) worst-case bounds for unlabelled posts → one sensitivity sentence + appendix numbers.
5. **Verification:** every script exits 0 end-to-end; `verifier` agent confirms `data/processed/*.rds`
   untouched; diacritics intact in generated CSVs.

### Phase 2 — Hand-validation (κ) — converts "indicative" → "measured"
1. **Sampling script** `handcode_sample.R`: draw ~150 anchor-mention posts stratified by anchor
   (oversample Stepinac + the two lowest-precision bundles per the audit priority in PROPOSAL §6:
   `vrijednost/odgoj`, `redovi_orders` incl. `samostan`/`stadler` homonyms), with the ±160-char window
   highlighted. Coding sheet → `output/private/handcode_sheet.csv` (row-level text = private; never tracked).
   Coding scheme (3 fields): genuine-vs-incidental past link; memorial-transmission vs present-tense frame
   vs blended; homonym/false-positive flag.
2. **Two human coders** code independently (PI decision 0.4). NOT Claude — the κ claim requires human coders.
3. **Ingest script** `handcode_kappa.R`: join codes back **on the item index AND assert the id agrees**
   (moral-economy lesson — this gate has caught mis-keyed rows before); compute Cohen's κ per field;
   compute measured precision per anchor; write `output/tables/handcode_summary.csv` (aggregates only).
4. **Consequence rule (pre-committed):** if measured genuine-linkage precision for an anchor differs from
   the automated share by more than the κ-implied uncertainty, the paper reports the corrected share and
   says so — mirroring the moral-economy denominator lesson (divide by coded precision, don't publish raw).

### Phase 3 — Literature (parallel to Phases 1–2)
1. Run **`/lit-review`** with the DigiKat discipline card, scoped to: (a) digital/connective memory measured
   at scale (does anything anticipate the four-signal move? — decides the fate of the hedged "first" claim);
   (b) **Croatian scholarship on Stepinac memory** (the draft's most exposed flank at *Memory Studies*) and
   on Catholic media in Croatia; (c) verification of the 8 working references (Nora, Halbwachs, J./A.
   Assmann, Hoskins, van Dijck, Hjarvard, Hoover — confirm editions/pages).
2. Fill `refs.bib`; every reference verified before it enters (zero-tolerance rule); retire or precisely
   hedge the "first for the Croatian mediasphere" claim based on (a).

### Phase 4 — Manuscript v2 (`PAPER_v2.md`) — the restructuring itself
Section mapping (old → new); drafting order follows evidence, not page order:

| New section | Built from | Key changes |
|---|---|---|
| Title + Abstract | v0.1 title; abstract rewritten | abstract = miniature of new structure: puzzle → method (1 sentence) → the split → shared authorship → implication; method result gets ONE sentence, not a third of the abstract |
| 1. Introduction | old §1 + §2 merged | one puzzle stated once; "three gaps" scaffolding cut; incidental-overlap point moved out |
| 2. Theory | old §3 tightened | three moves: Nora's four properties → four signals (keep — it is the hinge); Assmann communicative/cultural as interpretive frame; mediatization/connective turn as one-paragraph justification of the whole-mediasphere unit; Halbwachs folded to a sentence; **+ Croatian Stepinac literature (Phase 3)** |
| 3. Research questions | replaces old §4 | RQ1 + RQ2 + the one pre-committed expectation; hypothesis apparatus deleted |
| 4. Data and methods | old §5 nearly intact | + Validation subsection gathering: positive-control/foil design, isusov correction, incidental correction, **hand-coding κ result (Phase 2)**, 19c register (Phase 1) |
| 5. Results | old §6 reordered | 5.1 the split (Table 1 centerpiece) → 5.2 February rhythm → 5.3 shared authorship (LEAD with confessional/secular split; typology = one honest null sentence; + sensitivity note) → 5.4 affect explicitly as supporting → 5.5 convergence |
| 6. Discussion | old §7 + demotions | division of memory labour; Stepinac as national property; then ONE paragraph each: transferable instrument, overlap-is-not-engagement |
| 7. Limitations, Conclusion | old §8–§9 | Strossmayer limitation replaced by the Path-A result; Petković/rare-lieu → footnote; August rituals → one sentence; foil reframe applied |
| Declarations | old closing block | keep; re-run `/disclosure-check` before any share |

Style gates while drafting: flowing prose, no run-in headings, every term explained at first use, EN
throughout, **no hand-typed numbers** — every scalar comes from Phase 5's `paper_derived.csv`.

### Phase 5 — Reproducibility harness (adapt moral-economy machinery)
1. `paper_tables.R` (grown from Phase 1.2) — generates EVERY table of `PAPER_v2.md` as a markdown fragment
   under `output/tables_md/` + `paper_derived.csv` (every scalar the prose quotes).
2. `sync_tables.R` — installs fragments into `PAPER_v2.md` (never by hand).
3. `paper_checks.R` — fails unless: each fragment appears byte-for-byte; each derived scalar is printed in
   the text; UTF-8/diacritics intact; venue word-limit respected (*Memory Studies*: ~8 000–10 000 words —
   confirm current guide for authors in Phase 3).
4. `render_paper.R` — Typst/HTML render in a temp directory OUTSIDE the repo (never touches `docs/`).
5. Update figure calls to confirm `theme_digikat` styling (no hard-coded colors).

### Phase 6 — Review gates (in order; each produces a findings report, fixes applied between)
1. `r-reviewer` — all new/changed R scripts (Phases 1, 2, 5).
2. `croatian-nlp-reviewer` — the 19c token register + any probe change (BEFORE the Phase 1 run, see 1.1).
3. `numeric-claim-verifier` — fresh-context re-derivation of every headline number in `PAPER_v2.md`.
4. `religion-media-domain-reviewer` — does the argument survive a hostile referee on substance.
5. **`/review-paper`** — full mock peer review calibrated to descriptive tilt; triage findings with PI.
6. `/disclosure-check` on everything that will be shared/tracked.

### Phase 7 — Venue packaging
1. Format to *Memory Studies* specs (reference style, structure, anonymization for review).
2. Declarations: data availability, AI-use disclosure (already drafted in v0.1 — update), ethics n/a
   statement, CC BY figures/tables note.
3. Update study `README.md` log + status; `/commit` (tables_md, derived csv, PAPER_v2.md tracked;
   `output/private/` and row-level slices never staged).

---

## 3. Dependencies and ordering

```
Phase 0 (PI decisions)
  ├─→ Phase 1 (analysis hardening)  ─┐
  ├─→ Phase 2 (hand-coding; humans) ─┤─→ Phase 4 (manuscript v2) → Phase 5 (harness) → Phase 6 (reviews) → Phase 7 (package)
  └─→ Phase 3 (lit review; parallel)─┘
```
- Phases 1–3 run in parallel after Phase 0. Phase 4 can START from existing numbers (drafting structure and
  prose) but cannot FINISH until 1–3 land; Phase 5's checks are what make late number changes safe.
- Longest pole: **Phase 2** (two human coders). Prepare the sheet immediately after Phase 0 so coding runs
  while everything else proceeds.

## 4. Risks and mitigations
- **Hand-coding contradicts an automated share** → pre-committed consequence rule (2.4); the paper reports
  corrected shares. This is a feature (measured, not indicative), not a failure.
- **Lit review finds prior art for the "first" claim** → claim is hedged/dropped; the actor-decomposition
  and validated-instrument aspects still carry novelty.
- **19c register re-run perturbs other anchors' scores** → both registers reported side by side; 20c column
  stays the headline basis; any drift is explained, not hidden.
- **Dropbox/git hazard on full-master runs** → pause sync (CLAUDE.local.md protocol); verify no scatter.
- **Scope creep back toward three papers** → the §0 hierarchy is the contract; anything that grows beyond
  its allotted paragraph moves to the future methods paper.

## 5. What only humans can do (explicit)
- Phase 0 decisions (venue, Strossmayer path, title, coder, labels) — PI.
- Phase 2 coding of the 150-post sheet — two named human coders.
- Final triage of mock-review findings and the submit decision — PI.
Everything else (scripts, runs, drafting, harness, reviews) is executable by Claude on this machine.
