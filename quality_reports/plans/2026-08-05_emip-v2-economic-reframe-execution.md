# Plan — execute PROPOSAL_EMIP_v2 (the economic reframe) and write PAPER_EMIP_v2.md

**Date:** 2026-08-05 · **Owner:** L. Šikić · **Study:** `studies/inflation-salience/`
**Authority:** `studies/inflation-salience/PROPOSAL_EMIP_v2.md` (PI-approved; user instructed
"run the full-fledged analysis and write version 2 of the paper"). This plan records how the
proposal is executed, not whether — the what/why live in the proposal.

**Execution status:** complete on 2026-08-05. `RUN_ALL.R --v2 --no-network` ran all 15 local
stages in 7.4 minutes; `10_paper_checks.R --v2` passed 33/33; both Word editions and the
61-file screened replication bundle were regenerated.

## Scope locks (from the proposal §7)

- The measured set of 520, every existing table, and the two-method seam handling are unchanged.
- No new data collection. W1/W2 recode material already coded; W3 is analytic; W4 re-describes
  the existing HICP series.
- The fixed 1 450 pool and the appendix rebuild statement are untouched.
- `PAPER_EMIP_v1.md` stays as-is and must keep passing its checks.

## Execution steps

1. **Codebook addendum** (CODEBOOK.md): three new fields on already-coded posts —
   `object` (own_cost vs pastoral, the W1 split; coded on the 179 institution-register core
   posts), `voice` (does a sector actor speak, or is the sector written about — carries the
   cheap-talk defence), `unit` (parish / diocese / order / caritas / conference / vatican /
   church-general / none; coded on all 520 core posts, the W2 tagging). A free-text
   `unit_name` goes to output/private only (disclosure rule).
2. **`14_v2_sheets.R`** — build blind coding sheets from the master + coded_core.rds:
   object sheet (179 items, decisions object+voice+unit), unit sheet (the other 341, decision
   unit). Excerpt ±500 chars around the cost-of-living match; batch files under
   `output/private/batches/v2/`.
3. **Three-annotator blind coding** — same majority design as June: three independent LLM
   annotator runs per batch, same written protocol, no access to each other or to existing
   labels. Same-family limitation carries over verbatim and is stated in the manuscript
   (proposal §8); three-way agreement is reported as the validation of the new axes.
4. **`15_v2_ingest.R`** — parse the three label sets, majority vote, per-axis three-way
   agreement (pairwise + Fleiss kappa), write tracked `v2_labels.csv` (rid + labels, no text),
   the own-cost vs pastoral yearly/monthly series, unit × response aggregates, and the
   matched-pair analysis (named units to private; aggregate counts tracked).
5. **`16_v2_event.R`** — W4: cumulative HICP price-level gap (chained annual rates) at the
   repricing concentration, spell length, dated event-process quantities.
6. **Tables loop** — extend `08_tables.R` (tab8 attention-object split, tab9 unit × response,
   `derived_v2.csv` = complete scalar list for the v2 manuscript), `09_sync_tables.R --v2`,
   `10_paper_checks.R --v2` (9 fragments, derived_v2, length gate relaxed — primary venue is
   JEBO, not EMIP's 25 pages), `11_render_paper.R --v2`. RUN_ALL.R gains 14–16 and the --v2
   check passes. 12_replication.R ships the new tracked files.
7. **`PAPER_EMIP_v2.md`** — structure per proposal §5; the claim-ladder frame selected by the
   W1 outcome (Reading 1/2/3 — all three are planned outcomes, none strands the paper);
   literature additions per §6; house prose style; every number generated, none hand-typed.
8. **Verification** — full RUN_ALL pass incl. both papers' checks; render both; MEMORY.md
   [LEARN] entries; EMIP_EXECUTION.md / RECONSTRUCTION.md pointers updated.

## Risks carried from the proposal §8

W1 may select Reading 2 (divergence paper) — planned branch, frame rewritten accordingly.
Speech is strategic — own-cost/voice split is the partial answer. LLM-only coding — disclosed.
Detection lag — three internal W3 grounds, stated as coverage-of-repricing. Fairness vs
decision cost — not separable; claimed as consistency only.
