# Plan — execute the moral-economy dual-lens analysis (PROPOSAL_v3)

**Date:** 2026-08-04 · **Owner:** L. Šikić · **Executor:** Claude · **Study:** `studies/moral-economy/`
**Source of truth:** [`PROPOSAL_v3_dual_lens.md`](../../studies/moral-economy/PROPOSAL_v3_dual_lens.md) §7 stages, §8 honesty checks;
[`CODEBOOK.md`](../../studies/moral-economy/CODEBOOK.md) for the 7 coding axes.

## Context

Stage A (keyword census) is complete: 132,519 linked candidates over 11 economic domains, full 710,307-row run.
A semantic pilot ran but its hand-written anchors distorted coverage (a too-broad euro anchor took rank #2).
v3 turns the study into a dual-lens design — a transparent keyword lens and a meaning lens that check each
other — and everything downstream of the pilot is unbuilt. This plan executes S1 → S2 → S3 → V → C and then
drafts the manuscript. Nothing here touches the master, `data/processed/`, or `docs/`.

### User decisions taken (2026-08-04)
1. **Annotation:** Claude reads the gold sample, 3 blind passes, majority-adjudicated. ~187k tokens of blind
   corpus excerpts (no URL / outlet / date) leave the machine → **explicit exception to
   `R/semantic/README.md`'s local-only rule, recorded in the run manifest and the paper's ethics note.**
2. **Human double-code slice: skipped** at the PI's direction. Consequence stated as a limitation in the
   paper: validation rests on one model family. Revisit before OSF preregistration.
3. **Scope:** run through Stage C, then draft `PAPER_v1.md` from gate-passing numbers only.

## Facts established empirically (read-only benchmarks, 2026-08-04)

| # | Fact | Consequence |
|---|---|---|
| F1 | duckdb R pkg 1.5.4 exposes `array_inner_product` / `array_cosine_similarity` on `FLOAT[]` | SQL-side scoring available |
| F2 | Full corpus 710,307 × 25 anchors scores in **4.3 s** in DuckDB | Score everything; the proposal's "or a large sample" hedge is dropped |
| F3 | Pulling all embeddings into R = 5.8 GB as doubles | R path is the fallback only, batched 36 × 20k |
| F5 | Stored embeddings are exactly unit-norm | `array_inner_product` ≡ cosine; licenses the closed-form centering algebra |
| F6 | `chunk_id = CAST(substr(doc_id,4) AS INTEGER)` for all 710,307 rows | Join on integer `chunk_id` |
| F7 | **rid→doc_id gate PASSES** — 300/300 exact URL *and* DATE match | Stage A ↔ store join is sound; keep the gate in code |
| F8 | Anisotropy: mean random-pair cosine **0.354**, ‖corpus mean‖ **0.595**; after centering, mean 0.000 | **Mean-centering is mandatory, not stylistic** |
| F9 | Euro artifact reproduced: hand anchors + raw cosine + winner-take-all → euro **19.9%** of corpus | The breadth diagnostic (raw mean corpus cosine) catches it |
| F10 | Fix verified: seed centroids + centering → euro **3.9%**, Spearman(semantic, keyword) = **0.855** | S1 design works |
| F11 | Anchor collinearity max **0.767** (`unemployment`↔`demography_econ`) | **Winner-take-all coverage is unsound** — use threshold prevalence |
| F12 | Clean uni-domain seeds: poverty 26,989 … **euro 105** | euro is seed-starved; needs a stability gate |
| F13 | **30.4%** of posts exceed the 4,000-char embed truncation | Report by domain × platform; re-run coverage on the ≤4k subcorpus |
| F14 | Ollama has only `bge-m3`; no chat model, no API key | Annotator runner needs Claude (decision 1 above) |
| F15 | `.gitignore` ignores `studies/*/output/**/*.rds` and `output/private/`, but **tracks `.csv` / `.png`** | Every tracked CSV is a publication act |
| F17 | Multi-line `Rscript -e` segfaults under this Git Bash | Always write a script file; single-line `-e` only |
| F18 | `label` has five levels incl. `""` and `other` | Actor decomposition reports all five, not a binary |

## Approach

New scripts in `studies/moral-economy/`, following `01_stageA_tag_linkage.R`'s idiom (input fingerprint +
resumable checkpoint, read-only on shared assets, writes only to `output/`). All shared logic in a new
`sem_lib.R` — sourced, never run, mirroring `lexicon.R`'s role for the keyword lens.

**Reuse, do not rewrite:** `R/lib/digikat_utils.R` (`digikat_stage_rds`, `digikat_atomic_replace_file`,
`digikat_write_json_atomic`, `digikat_require_columns`, `digikat_cli_flag/value`); `04_iaa_validation.R`'s
`fleiss_kappa()` / `majority()` / `collapse3()`; `03_build_coding_sheet.R`'s `draw_domain()` stratified
sampler and blind-sheet/withheld-key pattern; `01_stageA_tag_linkage.R`'s `wilson()`; `R/theme_digikat.R`
for every figure; `ragnar::embed_ollama(x, model = "bge-m3", batch_size = 64L)` for anchor embedding —
**not** `semantic_slice.R`'s hand-rolled httr2 (and never omit `model=`: the default is the wrong model).

### `sem_lib.R` — shared module
`sem_con()` read-only store connection · `sem_gate_id_mapping()` (the F7 hard gate) · `sem_gate_unit_norm()`
(the F5 gate that licenses the algebra) · `sem_corpus_mean()` exact mean over 36 batches, cached ·
`sem_score_sql()` builds the centered-scoring SQL · `sem_assert_shareable()` blocks text/URL/rid columns
from tracked writes · `sem_checkpoint()` fingerprinted resume · copies of the kappa/label helpers.

**The centering algebra** (why one SQL pass suffices): with ‖p‖=1,
`s_d(p) = (⟨p, â_d⟩ − ⟨μ, â_d⟩) / sqrt(1 − 2⟨p,μ⟩ + ‖μ‖²)`. The denominator is one inner product per row
shared by all anchors; each numerator is one inner product plus a precomputed scalar.

### `05_s1_anchor_calibration.R` — Stage S1
Domain anchors = centroids of Stage-A seeds that are `!foreign_hint & !infl_metaphor_hint &
!actor_only_caritas` and appear in exactly one domain; n=400 stratified by `stream × label`; **25% held out**
and never in the centroid. Decoys rebuilt as centroids by probe-retrieval among posts outside the linked
candidate pool, plus a new `news_generic` decoy (the pilot's decoy set has no ordinary-secular-news member,
so ordinary news leaks into the economic set).

**Revision (2026-08-04, during implementation) — register and poverty anchors.** The plan first proposed a
separate retrieve-then-curate reading pass (~600 excerpts) to seed the register anchors, and assumed
`output/private/poverty_diagnosis_sample.csv` was coded ground truth to seed the poverty split. Inspection
shows that file is 60 rows of *tagger diagnostics* with no labels — it cannot seed anything. Rather than add
a second ~600-post reading pass on top of the 560-post gold sample, registers now follow a **fit/validate
split of one reading effort**:

- **v0 anchors** = centroids of 3–4 hand-written Croatian probe paraphrases per register (and per poverty
  side), centred. Used only to build the provisional grid and to stratify the gold sample.
- The 560-post gold sample is split **50/50, stratified, into FIT and VALIDATE**.
- **v1 anchors** = centroids of the FIT posts grouped by human-majority `ax4` — i.e. seeds curated by actual
  coding against the CODEBOOK, which is strictly stronger than eyeballing retrieval hits. Thresholds and the
  poverty margin `delta_p` are fitted on FIT too.
- **Every published agreement number is computed on VALIDATE only.**

This is cheaper (one reading pass, not two), and it removes the circularity risk outright instead of
managing it: anchors are fitted and validated on disjoint posts by construction. `other` (register) and
`mixed` (poverty) get **no anchor** — they are remainder categories produced by the margin rule.
**Circularity firewall retained:** every Stage-A domain-seed rid is recorded and excluded from the gold sample.

Thresholds: recall-anchored `τ_d` = the 20th percentile of the domain's own held-out seed scores (so every
domain's threshold means the same thing), reported at ρ ∈ {0.5, 0.8, 0.9}; plus a robust background z-score
from a fixed 50k sample. Assignment is **soft multi-label** (`in_domain(p,d) := econ_gate(p) & s_d(p) ≥ τ_d`),
with winner-take-all kept only as a sensitivity column and for UMAP colouring of stable rows.

`anchor_diagnostics.csv` carries `n_seed`, `centroid_norm`, `seed_coherence`, `split_half_cos`,
`mean_raw_cos` (the euro tell), `max_gram` + partner, thresholds and prevalence.
**Anchor gates:** `split_half_cos ≥ 0.85`, `centroid_norm ≥ 0.15`, `max_gram ≤ 0.85`, `precision@20 ≥ 0.70`.
`euro_changeover` is the expected casualty (105 seeds) → its coverage is reported keyword-only, stated openly.

### `06_s2_corpus_scoring.R` — Stage S2
One DuckDB pass over all 710,307 rows (§F2). **Precision gate:** recompute scores in R for 5,000 rows and
require `max|SQL − R| < 1e-4`; fallback `--engine=r` wired but not default. Coverage ranking semantic vs
keyword with Spearman ρ + bootstrap CI, computed **within `platform × data_source` cells and post-stratified**
— stream conditioning alone is insufficient because the streams differ sharply in platform mix. Recall gap
(`sem_yes & kw_no`) and precision gap (`kw_yes & sem_no`) as 2×2 counts per domain — and, because a raw gap
is a *candidate* gap, 06 reserves two hand-check strata for the gold sheet so the published gap is
`raw_gap × stratum_precision` with Wilson CIs. Truncation sensitivity: coverage re-run on the ≤4,000-char
subcorpus, reported by domain × platform.

### `07_s3_register_grid.R` — Stage S3
Register assignment on the 132,519 linked candidates by background-calibrated z with a **margin rule** —
below the margin the row is `ambiguous`, reported as its own column, never redistributed (the CODEBOOK's
"never silently dropped" rule applied to the machine). Domain × register grid with stratified bootstrap CIs
(2,000 resamples within `stream × platform`), plus a by-stream grid. Poverty split as a margin band (a
2-anchor argmax structurally cannot produce the CODEBOOK's `mixed`), reported on **three populations** —
keyword-linked poverty, semantic poverty, and their intersection — because the pilot's 73/27 came from the
top-800 of a hand-written anchor in a 20k sample and the number is expected to move.

### `08_build_gold_sheet.R` — Stage V sheet
N = 560, stratified: `domain_core` 220 · `register_cell` 120 · `poverty_split` 60 · `recall_gap` 88 ·
`precision_gap` 44 · `random_linked` 28. Excludes all S1 seed rids. Blind sheet = `rid, domain, window,
text_800` + the 7 blank axes exactly as `03_build_coding_sheet.R` names them; row order shuffled with a
recorded seed. The 800-char excerpt is new — register coding from a ±220-char window is part of why the
sister study's register κ was 0.46.

### `09_annotate_and_validate.R` — annotator runner + Stage V report
The one genuinely from-scratch component (inflation-salience's runner was never committed). Three blind
Claude annotator passes with differing framing emphasis, batched 10 posts/request, structured output
validated against the CODEBOOK's allowed levels (out-of-vocabulary → `NA` + counted, never coerced),
resumable by fingerprinted checkpoint, `--selftest` on fabricated posts. Blindness enforced structurally:
the runner refuses to run if any of `label/FROM/URL/DATE/stream` appears in the sheet. Output aligned to
`04_iaa_validation.R`'s existing contract (`coding_sheet_ann{1,2,3}.csv`, same rid order).

**Pre-declared pass floors** (fail-closed; nothing publishes past a failure):

| Gate | Floor | On failure |
|---|---|---|
| G-V1 Fleiss κ `ax4` 5-way | ≥ 0.60 | → 3-way → justice-vs-rest binary → H2 exploratory |
| G-V2 κ `ax1` genuine-link | ≥ 0.55 | precision-corrected denominators become ranges |
| G-V3 κ `ax5` 3-way | ≥ 0.60 | collapse to `economic vs rest` |
| G-V4 per-domain retrieval precision | ≥ 0.70 | that domain's semantic coverage is **not published** |
| G-V5 semantic-vs-human κ on `ax4`, per domain | ≥ 0.40 | that grid row publishes as hand-coded only |
| G-V6 share containment | ≥ 4 of 5 registers | grid annotated "not containment-validated" |
| G-V7 poverty split \|semantic − human\| | ≤ 10 pp | human number headlines; semantic becomes method commentary |

H3's ~73% headline is gated on G-V7; if it fails the finding becomes a methods contribution, which §9 of the
proposal already licenses as publishable. Report a same-model baseline κ alongside the headline: three
passes from one model is not three independent annotators, and the paper must say so.

### `10_stage_c_analyses.R` — Stage C
Reads `gates.json` and **refuses to emit any figure whose gate failed**. Coverage-convergence figure (with a
pilot-vs-calibrated inset — the method contribution made visible), domain × register heatmap matching
`diskurs.qmd`'s tile spec, poverty split over three populations with the human estimate overlaid, actor
decomposition across all five `label` levels, H4 shock-window χ² (windows pre-declared: shock 2022-06…2022-12
and 2022-12…2023-03; calm 2021-06…2021-12 and 2023-09…2024-03; **restricted to `original_dta`** so the test
does not straddle the 2024 collection seam; Holm-corrected), and a 2D UMAP meaning map of the *linked
candidates* built on centered vectors so the map and the scoring share one space.

### `PAPER_v1.md`
House style of `studies/inflation-salience/PAPER_v1.md`. Built only from numbers that cleared their gates,
with the annotation exception and the skipped human double-code stated in the limitations.

## S1 RESULTS (run 2026-08-04) — three planning assumptions overturned

Gates G0 (499/499 URL and DATE) and G1 (unit-norm) pass. All anchors clear the revised gates.

**1. The fix is the seed centroid, NOT mean-centering.** The plan asserted centering was "empirically
mandatory." The full 2×2 (anchor source × space), with the decoy set held constant, says otherwise:

| instrument | Spearman vs keyword rank | euro share (keyword: rank 11, 407 posts) |
|---|---|---|
| as published in the pilot | **−0.382** | 6.5% |
| hand sentence × raw | −0.079 | 0.0% |
| hand sentence × centred | +0.091 | 1.9% |
| seed centroid × raw | **+0.955** | 0.7% |
| seed centroid × centred | **+0.964** | 1.3% |

Anchor source moves ρ from −0.38 to +0.96; centering moves it +0.009. Centering is retained (it is
theoretically motivated and costs nothing) but **must not be reported as the correction** — the pilot's
error was building anchors from invented sentences instead of from posts the keyword lens had vouched for.
Caveat to state in the paper: agreement with the keyword ranking is *convergence*, not accuracy.

**2. Anchors compared against each other must be built the same way.** Domain anchors were post
centroids while decoys were short sentences; a post-centroid beats a sentence-probe for almost any post,
so the "is this economic?" gate passed nearly everything — the 11 domain shares summed to **0.998** of a
corpus that is overwhelmingly about faith. Decoys are now centroids of the posts their probe retrieves,
drawn only from outside the Stage-A linked pool. Symmetrically, the hand-sentence arms score 0.0% against
post-centroid decoys — the same artifact in reverse. **Modality match is a precondition, not a detail.**

**3. Unsupervised threshold prevalence does not work here, and Stage V must set the operating point.**
New diagnostic — AUC of held-out seeds vs background — puts the anchors at **0.73 (business_comp) to 0.92
(euro_changeover)**: they rank well but do not separate cleanly. With a 1–5% base rate, a threshold set to
capture 80% of seeds admits 25–56% of the corpus against a keyword prevalence of 0.6–5.4%. Consequences:

- τ is **provisional**, reported as a family (ρ ∈ {0.5, 0.8, 0.9}) plus a robust z, never as *the* answer.
- S2 stores **raw scores, not binary labels**, so no operating point is locked in upstream of validation.
- Coverage is compared at **matched volume** (top-k where k = that domain's keyword `n_linked`), which asks
  *which* posts each lens picks rather than how many — the only unsupervised comparison that is not an
  artifact of an arbitrary cut.
- The operating threshold is fitted on the Stage V FIT half against human labels and reported on VALIDATE.

**4. Also fixed:** `digikat_atomic_replace_file()` in `R/lib/digikat_utils.R` warned on *success* —
`unlink()` returns 0 when it works, so `!unlink(previous)` was inverted. Shared code, used by the main
pipeline; corrected to `unlink(previous) != 0`.

## S2 / S3 / STAGE V RESULTS (run 2026-08-04)

### S2 — full corpus scored (710,307 rows, one DuckDB pass, G3 max |SQL−R| < 1e-4)
- **Rankings converge, post selection does not.** Spearman(semantic WTA, keyword) = **+0.982**, poverty #1
  under both. But at matched volume the two lenses overlap on only **19.7%** of posts. Four in five posts
  are seen by one lens alone.
- **The answer depends on the operating rule**: WTA ρ +0.982 · z≥3 ρ **−0.682** (puts euro_changeover #1
  again — the pilot artifact in new clothes) · τ80 ρ +0.736. Ranks move up to 10 places.
- Platform × stream ρ range +0.68…+0.955, post-stratified **+0.844**. Truncation is not driving anything
  (30.4% truncated; ρ 0.982 → 0.964 on the ≤4,000-char subcorpus).
- WTA calls 55.5% of the corpus "economic" — **not credible**; 11 domain anchors versus 4 decoys wins on the
  order statistic alone. WTA is used for RELATIVE ranking only, and the paper must say so.

### Stage V — 555 posts, three blind passes, 1,665 codings
**Reliability is high** (Fleiss κ): ax1 genuine-link **0.941** · ax4 register 5-way **0.738**, 3-way 0.844,
binary 0.904 · ax5 poverty 3-way **0.891**. All clear their floors, so the register analysis runs at the
**5-way** level — far better than the sister study's 0.46. Caveat that must appear in the paper: three
passes by one model family is inter-pass reliability, not independent human coding.

**The headline correction — two thirds of the linked pool is not a genuine link.** Majority-adjudicated
genuine rate: domain_core **38.4%**, register_cell 36.1%, random_linked 32.1%. This replicates the sister
study's "co-occurrence is not engagement" at 11 domains, and it means every raw keyword count is an
overstatement of religious economic engagement by roughly 3×.

**Gate outcomes:**

| gate | value | floor | verdict |
|---|---|---|---|
| G-V1 register IAA 5-way | 0.738 | 0.60 | PASS |
| G-V2 ax1 IAA | 0.941 | 0.55 | PASS |
| G-V3 ax5 IAA | 0.891 | 0.60 | PASS |
| G-V4 retrieval precision | 0.385 | 0.70 | **FAIL** |
| G-V5 semantic-vs-human register (v1) | **0.717** | 0.40 | PASS |
| G-V6 share containment | 6 of 6 | 4 | PASS |
| G-V7 poverty split deviation | 52.2 pp | ≤10 | **FAIL** |

- **G-V4 fails and is partly mis-specified.** It uses ax1 (is the religion↔economy *link* genuine?) as the
  precision criterion, so it measures the genuineness of the pair, not whether the anchor retrieved
  on-topic posts. The codebook has no "is this post about domain d?" axis. Report the 38.5% as what it is —
  the genuine-link rate among top-ranked candidates — and record the conflation as a limitation.
- **G-V7 fails under both anchor versions** (29.6 pp with v0, 52.2 pp with v1, where 73% of VALIDATE lands in
  `mixed`). **The meaning lens cannot measure the poverty economic/doctrinal split.** No further tuning was
  attempted: the margin is fitted on FIT, and iterating until VALIDATE passes is what the design forbids.
- **H3 is refuted as stated.** The pilot's "~73% doctrinal" does not survive: hand coding puts the split at
  **40.9% economic / 38.6% doctrinal / 20.5% mixed** (VALIDATE, n=44) — roughly even, not doctrine-dominated.
  The doctrinal majority was an artifact of the embedding. Per proposal §9 this becomes a methods finding.

**The recall gap is not a recall gap.** Posts the meaning lens picks that keywords miss are only **10.2%**
genuine [5.5, 18.3]; posts keywords pick that the meaning lens misses are **29.3%** genuine [17.6, 44.5]. So
the 80% cross-lens divergence is mostly the meaning lens adding noise, not recovering paraphrase the keyword
lens missed — the opposite of what §3 of the proposal predicted ("recall-complete"). **On finding genuine
religion↔economy links, the transparent keyword lens outperforms the embedding lens roughly 3:1.**

### S3 — the register grid is anchor-version-dependent
Rebuilding register anchors from coded FIT posts (v1) lifts agreement with humans (κ 0.613 → **0.717**) and
matches the human justice share exactly (30.8% vs 30.8%) — but it **reorders the domains**: poverty's justice
share goes from 7.2% (v0, lowest of 11) to 12.5% (v1, 4th), and green_energy jumps to 48.1%. **H2's ordering
claim does not survive the anchor-version change** and cannot be published as a stable finding. What does
survive: the human-coded register distribution on genuine links, and the fact that the ordering is unstable.

### Implementation defects found and fixed
- `digikat_atomic_replace_file()` warned on success (inverted `unlink()` test) — shared code.
- `digikat_cli_value()` matches the bare flag name, so `--anchors=v1` silently fell back to the default;
  every CLI flag in 05–09a was affected. Fixed to pass `--name`.
- Swapping anchors without rescoring silently reused v0 scores — 07 now rescores under `--anchors=v1`.

## Disclosure classification
**Tracked (shareable):** `anchor_diagnostics.csv`, `anchor_gram.csv`, `coverage_ranking_v2.csv`,
`gap_matrix.csv`, `truncation_by_domain_platform.csv`, `register_grid*.csv`, `poverty_split.csv`,
`gold_allocation.csv`, `gate2_iaa.csv`, `semantic_vs_human.csv`, `h4_shock_windows.csv`, `fig_*.png`,
`*_manifest.json`, `gates.json`.
**Restricted (`output/private/`):** `register_seed_curation.csv`, `anchor_top20.csv`, `gold_sheet.csv`,
`gold_key.csv`, `coding_sheet_ann{1,2,3}.csv`, `gold_core.csv`.
**Enforced in code, not just documented:** `sem_assert_shareable()` stops on any `text`/`window`/`URL`/
`TITLE`/`FROM`/`actor`/`rid` column before a tracked write; tracked cells with `n < 10` are suppressed.

## Verification
- Gates G0 (rid↔doc_id), G1 (unit-norm), G2 (anchor quality), G3 (SQL-vs-R agreement < 1e-4), G4 (blindness
  + seed exclusion), G5 (the seven Stage-V floors) each print PASS/FAIL and halt the run on failure.
- `09 --selftest` and `04 --selftest` run without network.
- After the run: `git status` must show no change to `data/processed/`, `data/merged_comprehensive.rds`, or
  `docs/`; the master's mtime and size must be unchanged (nothing in this plan reads or writes the master).
- Hand-eyeball `output/private/anchor_top20.csv` before any anchor's number is published.

## Out of scope
No master mutation. No `data/processed/` regeneration. No site render or `docs/` write. No change to
`R/religious_terms.R` or the ≥2-match inclusion rule. No OSF submission — the prereg text is drafted, not filed.
