# Execution plan — moral-economy, full 11-domain census → working-paper v1

**Date:** 2026-07-07 · **Status:** plan (execution held per user; codebook v3 drafted, nothing run) · **Owner:** L. Šikić
**Decision (2026-07-07):** **full 11-domain census** (not the vertical slice) · start artifact = **[CODEBOOK.md](CODEBOOK.md) v3** · otherwise **plan-only**.
**Companion docs:** [PROPOSAL.md](PROPOSAL.md) (design + Stage-0 v2 evidence) · [CODEBOOK.md](CODEBOOK.md) (coding instrument) · [probe.R](probe.R) (Stage-0, already run).

> **The census is viable, but only if coding SAMPLES.** Stage-0 gives ~90,000 linked candidates across the
> eleven domains (business ~20k + poverty ~38k = ~65%). The sister study hand-coded 1,450 for *one* domain.
> A census of *domains* does **not** mean a census of *posts* — every domain is fully represented, but each
> contributes a **power-sized stratified sample** to the coded core. That distinction is what makes 11
> domains tractable instead of a coding project that never finishes.

---

## 0. What is already solved vs what must be built (from the machinery inventory)

| Pipeline stage | Status | Asset |
|---|---|---|
| Religion lexicon | ✅ **reuse as-is** | `R/religious_terms.R` (frozen 95-term); `probe.R:62` already points Stage A at it |
| Windowed linkage (±220) | ✅ **reuse as-is** | `probe.R:121-144` — sister-validated algorithm, Caritas split, Wilson CIs, already run at Stage 0 |
| Domain tagger | ⚠️ **adapt** | `probe.R` v2 domains; add the metaphor guard + homonym fixes (esp. `misa zadužnica`) before freeze |
| HICP external data | ✅ **reuse as-is** | `studies/inflation-salience/output/hicp_hr.csv` (Eurostat, monthly 2021–25) — **lift the file**, no re-acquisition |
| Coding-sheet schema | ✅ **reuse as template** | `coded_pool_full.csv` header is the target format |
| **Coding instrument + prompts** | ❌ **BUILD FROM SCRATCH** | no committed code/prompt anywhere — the critical path |
| **IAA / gold-slice validation** | ❌ **build** (design in hand) | re-derivable; `VALIDATION.md` specifies the design; raw label matrices committed |
| Temporal / HICP correlation code | ❌ **build** (~10 lines) | method fully documented; only `cor()`/threshold/plot to rewrite |

**One-line takeaway:** tagging, linkage, and external data are lift-and-adapt; the **multi-annotator coding
instrument + its validation** is the real engineering, and it is also the paper's weakest measured axis
(register κ 0.46). Budget accordingly.

---

## 1. The reframe that survives the census (carry from the strategic review)

Stage-0 already **disconfirmed H2** (no abstraction gradient in linkage) and H1 is high-variance (justice ~3%,
κ 0.46). So the census is built **map-first**:
- **Guaranteed deliverable:** the descriptive map — which of the 11 domains religion genuinely engages, in what
  register, carried by whom (confessional/secular; actor typology), on what calendar. Publishable regardless of H1/H4.
- **Bonus confirmatory:** H1 (justice concentrates in tier-C work/poverty) and H4 (justice rises in crisis
  windows) — tested, but reported as informative nulls if flat. The **mediatization-of-religion** thesis
  ("the digital public sphere admits religion into economics as object, rarely as prophetic voice") survives
  either outcome.
- The poverty hand-pass gives a glimmer that H1 *could* land: genuine `justice` (structural causes of poverty)
  is really present in tier-C poverty, exactly where predicted — but it sits beside `doctrinal_poverty`, so it
  is only visible once Axis 5 (the poverty split) separates them.

---

## 2. The sampling design (the thing that makes a census codeable)

**Do not code the ~90k pool.** Fixed target **coded-n per domain**, stratified, driven by power:

- **Why a fixed per-domain n:** the confirmatory quantity (`justice` share) is ~3%. To estimate it per domain
  with a usable CI (± ~1 pp) you need ~800–1,200 coded/domain → ~25–40 justice cases each. Larger pools (poverty,
  business) do **not** need proportionally more coding — they need the *same* per-domain n, sampled.
- **Stratify each domain's linked pool by** `data_source` stream (2021–24 vs 2024–26 — never pooled) **×**
  outlet type (confessional / secular / other). Pre-declare the allocation.
- **Total coded core ≈ 9,000–13,000 posts** (11 domains × ~1,000, minus overlap). ~6–9× the sister study —
  large but feasible on the validated 3-annotator LLM workflow with a human-double-coded slice. This is the
  number that goes into the OSF prereg and the budget line.
- **Rare-cell rule (pre-declared):** any domain × register cell below a floor (e.g. n<20 justice) is reported
  descriptively only and drops out of the H1 trend test; the grid degrades gracefully to the 3-tier level.
- **Inflation domain:** its sister-coded posts are **held out of every confirmatory test** (anti-salami); it
  enters only as an external benchmark (justice 3% / charity 17% / object 72%).

---

## 3. Stage sequence with hard gates

**Stage A — Full tagging + linkage (computational; ~1 run).**
Swap the probe-quality religion regex for `R/religious_terms.R`; add the metaphor guard + homonym fixes
(CODEBOOK §homonyms); tag all 11 domains on the full corpus; compute ±220 windowed linkage for every matched
post; flag foreign economics. Output: the per-domain candidate pool with domain, linkage, actor-term flag,
outlet, stream, date. → **run where R + master live; ~1–1.5 h given the cold-read Dropbox penalty (pause Dropbox sync first).**

- **GATE 1 — precision hand-scan:** ~60 posts/domain hand-scanned for tagger precision (per-domain, per-stream).
  Feeds the Q1 correction factors and the H2 corrected-linkage denominators. **`croatian-nlp-reviewer` audits
  the frozen lexicon here.** Poverty's precision is already partly known (the 2026-07-07 diagnosis) — extend it.

**Build — coding instrument (the from-scratch stage).**
Implement the 3-annotator workflow against CODEBOOK v3 (7 axes); text-only sheets; majority adjudication;
human double-codes a slice. Reuse the `coded_pool_full.csv` schema.

- **GATE 2 — gold-slice register re-validation (BEFORE prereg):** human-adjudicated ground truth re-estimates
  κ on Axis 4 (register) and Axis 5 (poverty split) at 5-way and 3-way. **Pre-declare** the confirmatory level
  from the result (5-way → 3-way → binary). If even 3-way fails the floor, H1/H4 become exploratory and the
  paper leans fully on the map (the reframe already protects this).

**OSF preregistration (H1, H4).** Lock: the sampling allocation, the per-domain floors, the confirmatory
level from Gate 2, the tests (Jonckheere–Terpstra for H1 across tiers on non-inflation domains; χ² for H4 in
shock vs calm windows within the 2021–24 stream), and the held-out-inflation rule.

**Stage B — Coding.** Draw the stratified per-domain samples; code; adjudicate; produce the coded core.

**Stage C — Analyses.** Domain × register grid (Q2); actor decomposition (Q2½); precision-corrected candidate
time series with uncertainty bands (Q1); within-stream series vs HICP (reuse `hicp_hr.csv`) and the liturgical
calendar (H3 — subject to its cell-size gate); shock-window contrasts (H4); H1 trend; affect layer (coverage % reported).

**Stage D — Close reading.** Qualitative pass on the `justice` posts (imported papal voice vs domestic — the
sister found justice often foreign) and the sharpest justice-vs-object pairs.

**Working-paper v1** = Stages A–C written up with the map as spine, H1/H4 as confirmatory sections, Stage D as
the interpretive close. Structure mirrors the sister `PAPER_v1.md`.

---

## 4. Parallelizable, non-blocking (HELD — not started per user)

Independent of the coding pipeline; can run anytime the user greenlights:
- `/lit-review` — mediatization-of-religion (Hjarvard/Hoover) as the lead frame; moral-economy (Thompson;
  Fourcade & Healy); religious time (Zerubavel) for H3. Hardens §10 and retires hedged claims.
- **HICP:** already in hand (reuse the sister file) — only the liturgical-event **calendar CSV** must be built.
- **Confessional-recall audit** (stream-matched, two liturgically contrasting months) — bounds every
  "Catholic media cover X" claim.

---

## 5. Risks → pre-declared fallbacks

| Risk | Fallback |
|---|---|
| Register κ fails even at 3-way (Gate 2) | H1/H4 → exploratory; paper leans on the map + object-dominance (reframe already covers this) |
| Per-domain justice cells too thin | collapse to 3-tier grid; rare cells descriptive-only |
| Poverty split (Axis 5) unreliable | report poverty descriptively; the split becomes a qualitative finding (Stage D) |
| Coding budget overruns ~13k | reduce per-domain n on the *object-dominated* tier-A domains (lower justice stakes), protect tier-C n |
| Salami-slicing referee objection | held-out inflation + explicit overlap-disclosure paragraph (PROPOSAL §6) |
| Stage-A cold-read is slow (Dropbox) | pause Dropbox sync before the run; checkpoint is fingerprinted (safe resume) |

---

## 6. Immediate next actions (when execution is greenlit)

1. **Fold CODEBOOK v3 homonym fixes into a lexicon v3** (esp. `misa zadužnica` exclusion; `siromaš` devotional
   guard) → `croatian-nlp-reviewer` audit → freeze. *(design-adjacent; can be done under "plan-only" if desired)*
2. Run **Stage A** (full tagging + validated linkage) → per-domain candidate pools. *(first real compute)*
3. **GATE 1** precision hand-scan (extend the poverty diagnosis to all domains).
4. Build the **coding instrument** + run **GATE 2** gold-slice re-validation.
5. **OSF prereg (H1, H4)** with the §2 sampling design locked.
6. **Stage B–D** → working-paper v1. `/lit-review` + calendar-build run in parallel from step 1.

**Nothing above step 1 is started.** This document + CODEBOOK.md are the planning deliverables; the corpus,
master, and `data/` are untouched.
