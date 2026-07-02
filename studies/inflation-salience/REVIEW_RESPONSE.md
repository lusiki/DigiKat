# Review response — DRAFT_v1 → v1.1

**Date:** 2026-06-30. Two review agents ran on DRAFT_v1: a **numeric-claim-verifier** (re-derived every figure
from the coded data) and a **religion-media-domain-reviewer** (hostile peer review). Below: every finding and
what was done. Supporting re-analysis: `scratchpad/16_review_response.R`; new figure `output/coded_core_by_stream.png`.

## Numeric verification — outcome
**All Table 1–6 numbers and all §4 numeric claims reproduce exactly** from `analysis_core_coded.csv` /
`coded_pool_full.csv`. Three **stale narrative figures** (carried from the pre-coding pass) were **fixed**:

| Location | Was | Now | Status |
|---|---|---|---|
| Abstract | "~14% of co-mentions genuine" | removed; state 520 / 0.07% / 6.5% | ✅ fixed |
| §1 | "overstates … sevenfold" | "roughly an order of magnitude (≈8,000 vs 520)" | ✅ fixed |
| §4.1 | "two of every three incidental" | "45% of candidates survive coding — over half incidental" | ✅ fixed |

Same stale figures corrected at source in `PROPOSAL_v2_broadened.md` (§2 Q1/Q2/Q2½ "first answers" → measured).

## Peer review — findings and responses

| # | Severity | Finding | Response in v1.1 |
|---|---|---|---|
| **C1** | Critical | "Faded after 2022" confounded by the 2024 collection-batch change (MEMORY.md warns of this); core carried no `data_source`. | **Re-analysed by stream.** Confirmation rate at 2024: original_dta 0.86 vs filtered_religious 0.21 → streams not comparable. §4.4 rewritten: the 2022 peak + decline is claimed **only within the 2021–2024 monitoring stream** (201→100→64); the 2025–26 backfill figures are explicitly *not* evidence of continued decline. New Fig 3a (`coded_core_by_stream.png`). Stream-conditioned re-coding flagged as top next step (§7). **Partly rescued, properly hedged.** |
| **C2** | Critical | "Catholic leans charity" rests on n=75, 75% one aggregator (hkm.hr=56), and hkm.hr's own top register is *institution* (27) not charity (18). | **Demoted to hypothesis.** §4.3 and §5 now report the with/without-hkm.hr decomposition (non-hkm Catholic tail = 19 posts), note wide CIs, and explicitly decline to claim the outlet contrast. |
| **C3** | Critical | (a) "Justice absent (3%)" is a strict-lexicon floor — latent justice framing lands in charity/devotional. (b) VALIDATION.md said domestic justice = 0 / all foreign, contradicted by the coded core. | (a) Added the **upper bound: 3% strict → ≤8% (43 posts)** including latent structural language (chiefly 18 charity posts); abstract/§4.3/§5 now say "floor, not point estimate". (b) Corrected: the "zero/foreign-only" claim was a small-sample (n=26 held-out) artifact; the coded core has **15 domestic justice posts (5 Catholic)**. VALIDATION.md annotated accordingly. |
| **M1** | Major | institution↔cost-of-religious-life split is within coding noise (register agreement 0.46; shared keywords). | Lead with the **~72% economic-object macro-register**; the 37/34 ordering is now explicitly "within coding noise" (abstract, §4.3, §7). |
| **M2** | Major | Residual false positives survive coding (e.g. a mall stabbing coded cost-of-religious-life). | §7: residual-FP acknowledged; **high-confidence 3/3-agreement subset (518 posts)** offered for sensitivity; random-slice human recheck added to the plan. |
| **M3** | Major | CST "not prophetic" from media counts risks an ecological fallacy; no benchmark for "marginal". | Reframed throughout to **"digital-public visibility of the frame," not the Church's conduct** (abstract, §5). §7 adds the missing **secular benchmark** as required future work. |
| **M4** | Major | Funnel inconsistent across docs (1,103 vs 1,450). | §3 now explains: we code the full **linked** set (1,450), not the classifier's **domestic-linked** subset (1,103), because the automatic foreign flag is unreliable (P≈0.39). |
| **m1** | Minor | "full coverage 1,450/1,450" slightly overstated. | §3: "1,447/1,450 coded by all three (three by two)." |
| **m2** | Minor | IAA is inter-*LLM*, not human. | Abstract now flags "LLM annotators; human validation pending". |
| **m3** | Minor | "whole national digital space" oversells a 96%-web core. | Qualified to **"web-portal-dominated"** (abstract, and platform note). |
| **m4** | Minor | Foreign/domestic boundary (defines the 520) rests on the weak foreign axis. | §7: human spot-check of the boundary added. |

## What the paper now claims (survives the hostile pass)
1. **Co-occurrence ≠ engagement** (methodological contribution) — solid.
2. Religion meets domestic inflation overwhelmingly as an **economic object** (~72% macro-register) — robust; sub-ordering is not.
3. The **structural/CST justice frame has low digital-public visibility** (3% floor, ≤8% broad) — robust as a *visibility* claim.

Demoted to hypotheses pending further work: the outlet "division of labour" (C2) and the cross-seam "fade" (C1).

## Outstanding before submission
Stream-conditioned re-coding (C1) · human double-code a slice incl. the foreign/domestic boundary (M2, m4) ·
secular structural-framing benchmark (M3) · HICP overlay · resolve 12 disputed register cases.
