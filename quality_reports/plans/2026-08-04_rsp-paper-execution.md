# Plan — execute PROPOSAL_v5_rsp.md and draft the RSP manuscript

**Date:** 2026-08-04 · **Study:** `studies/moral-economy/` · **Owner:** PI (L. Šikić)
**Governing documents:** `PROPOSAL_v5_rsp.md` (blueprint), `LITREVIEW_pilot_rsp.md` (concepts/citations)
**Supersedes for execution purposes:** `quality_reports/plans/2026-08-04_cst-public-sphere-paper.md`
(that plan predates the RSP framing decision and the v5 robustness programme)

---

## 1. Goal

Clear Gate 1 of the proposal's work queue (Part X), then draft the manuscript. Nothing is written until
R4 resolves, because R4 decides *which* paper gets written (headline gradient vs. the Part V.7 fallback).

## 2. Verified starting state (2026-08-04, this session)

- `17_cst_robustness.R` re-run: gates **G1 / G1b / G2 all pass**; 25/25 variants put `green_energy`
  first, 24/25 disjoint. Baseline reproduces 7,15% [6,34; 8,07].
- Population = 1 198 doctrinal posts inside 108 966 religion-linked economic posts, from 710 307.
- Outstanding blockers per Part X: **R4** (denominator linkage precision, per-domain) and **R1/R2**
  (Tier-1 numerator precision). Everything else in Part V is cleared.

## 3. Steps

| # | Step | Script | Output | Gate |
|---|---|---|---|---|
| 1 | **R4 sample** — fresh stratified random draw from the linked layer, 60 × 11 domains, `ME_SEED` | `19_r4_linkage_sample.R` | `private/r4_sheet.csv`, `private/r4_batches/*.md` | blind sheet must carry no outlet/URL/label/stream |
| 2 | **R4 coding** — `ax1_link_genuine` only, codebook Axis 1, default `incidental` when uncertain | (annotation passes) | `private/r4_ann1.tsv`, `private/r4_ann2.tsv` (blind re-pass, 200-item slice) | κ reported, honestly labelled as repeat-pass stability |
| 3 | **R4 recompute** — per-domain precision + precision-adjusted gradient with intervals propagated through both terms | `20_r4_recompute.R` | `output/r4_linkage_precision.csv`, `output/cst_gradient_adjusted.csv` | **decides headline vs. fallback** |
| 4 | **R1/R2 audit** — ~150 cards from the 1 198, stratified era × domain tier × outlet-rank | `21_r1_precision_sample.R` → coding → `22_r1_recompute.R` | `output/r1_tier1_precision.csv` | precision ≥0,80 report as measured; 0,60–0,80 report both |
| 5 | **R9** — normalise `nauk`/`nauak`, `enciklika`/`enciklica`; drop papal attribution (`lav` ambiguity) | `23_r9_lemma_fix.R` | corrected lemma table | no papal-attribution claim in the paper |
| 6 | **Print figures** — `theme_digikat_print()` greyscale, white panel, Arial, ≥300 dpi, source line | `24_rsp_figures.R` | `output/figures/rsp_fig{1,2,3}.png` | monochrome-legible |
| 7 | **Numbers ledger** — every manuscript number machine-emitted from `output/*.csv` | `25_paper_numbers.R` | `output/paper_numbers.csv` | no hand-typed numbers in prose |
| 8 | **Draft** — English, 6 200 words body, decimal comma + space thousands, APA in-text | — | `PAPER_RSP_v1.md` | ≤50 000 characters |

## 4. Decision rule at Step 3 (pre-declared, before the coding is read)

- **Headline version** (Part 0 thesis) if `green_energy` remains first on the precision-adjusted gradient
  with an interval disjoint from the runner-up.
- **Fallback version** (Part V.7) if it does not: §4–§5 are replaced by the hand-coded register contrast,
  §1/§2/§3/§6/§7 survive. The paper becomes *how* religion engages the economy rather than *how often*.
- **Mixed outcome** (first but overlapping): report the raw gradient as the headline with the adjusted
  gradient as a stated sensitivity, and downgrade C2 to "established with stated measurement uncertainty".

Pre-declaring this matters because the adjusted numbers are visible before the draft is written.

## 5. Constraints carried from the proposal

- No p-values on census proportions (Trap 3). No temporal claims (Trap 4). No Tier-2 membership (Trap 1).
- `output/private/**` never committed, published, or turned into a web artifact (Trap 7).
- The study never opens `data/merged_comprehensive.rds`; it reads `corpus_prepared.rds` and
  `stageA_candidates.rds` read-only.
- `cst_core.R` aborts on population drift — do not pass `expect=NULL` to silence it.
- Run R from the repo root; Dropbox sync paused for the long `corpus_prepared.rds` reads.

## 6. Honest limits of what this session can deliver

The annotation passes are model passes, not human ones. Two passes by the same model measure **stability
under re-reading**, not inter-annotator independence. This is the same limitation the 555-item gold set
carries (`PAPER_v1.md` §6.1) and it must be stated in the manuscript's limitations section, not buried.
A human double-coded slice remains outstanding and is genuinely blocking if the fallback paper is written,
because there the coded data *is* the result (proposal Part V.7).
