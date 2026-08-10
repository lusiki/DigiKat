# Plan — rule v4: the window fix and the denominational veto

**Date:** 2026-08-10 · **Owner:** PI · **Status:** measured; awaiting two PI decisions
**Trigger:** 50 random posts read from the pre-2024 rebuild output (`RESULTS.md` §10)
**Supersedes:** the pre-2024 threshold plan in `pre2024_threshold_plan.csv` (its 79,5% does not hold)

---

## 1. What was measured, and what it overturns

50 fresh random posts from what the pre-2024 rebuild would actually keep (gate 1 + gate 2 ≥ 0,50),
plus a focused 15-post read of one stratum. Full detail in `studies/filter-validation/RESULTS.md`
§10; the three results that change decisions:

1. **The kept pile is 64,0% genuine [50,1–75,9], not 79,5%.** The per-segment rates reproduce
   round 2 exactly (79,5% for posts already in the corpus, 46,7% for new material); what does not
   reproduce is the second pass's contribution. Its measured lift on fresh output is ~3 points, not
   the ~18 the out-of-fold projection promised. AUC on the 50 is **0,691**.
   *This is the third time an out-of-fold estimate of the second pass has been optimistic.*
2. **Gate 1 searches the whole text; gate 2 and the coder see only the first 3000 characters.**
   9,7% of accepts pass only on evidence past that point, and **0 of 18 such posts read are
   genuinely Catholic** (0,0% [0,0–17,6]). 29% of the stratum is already in the master.
3. **Six of the 50 are religious but not Catholic**, scored 0,86–1,00 by gate 2. Catholic-specific
   vocabulary separates that class at 87,0% vs 11,1%.

Consequence for the rebuild story: it still roughly **doubles** the pre-2024 half and adds
~50 000 genuine posts, but it does **not** get cleaner — ~80% → ~73% — because half of what it adds
is new material that is only 46,7% genuine. "Doubles and gets cleaner at the same time" was an
artifact of the 79,5% figure and must not be repeated anywhere.

## 2. The candidate — v4

Written and verified as `studies/filter-validation/lib_rule_v4.R`; `27_verify_v4.R` asserts it
reproduces §10 (rc = 0). **Study-local. Nothing in `R/` reads it. The corpus is unchanged.**

The 119 v3 patterns are untouched. Three rule-level changes:

| # | change | measured |
|---|---|---|
| 1 | match inside the first 3000 characters only | 64,0% → 71,1% on the 50, **0 genuine lost**; −53 100 projected posts |
| 2 | `božji` decisive → ambiguous | included in the above; on all 1040 coded posts removes 8 junk, costs 2 genuine |
| 3 | veto when a non-Catholic religious marker is present **and** no Catholic-specific term is | 71,1% → **76,2%**, **0 genuine lost** on the 50; 12 genuine lost on the pooled 1040 — see decision (a) |

Measured and **rejected** as adding nothing: a 26-phrase formulaic-`Bog` stoplist, and restricting
`blaženi` to *bl. \<Name\>* / *Blažena Djevica*. Both are subsumed by change 2. Dropping `duša` and
`kaptol` is available behind `drop_marginal = TRUE`, default off (3 junk removed, 1 genuine lost).

Projection: gate 1 accepts **2,76%** of feed rows with text ≈ **461 700** posts; with gate 2 at 0,50,
≈ 363 700 at ~73% clean.

## 3. Two decisions needed from the PI

**(a) Scope — is non-Catholic Christian devotional content in the corpus?**
Rounds 1–3 produced 7 `religious_other` labels in 990 posts (0,7%); round 4 produced 6 in 50 (12%).
Twelve posts carrying an Islamic/Orthodox/Protestant marker and **no** Catholic-specific term were
coded `catholic_clear` in rounds 1–3 (listed in `denomination_adjudication.csv`, private). So the two
rounds used different conventions, and the headline moves with it:

| | read 50 | + window fix |
|---|---|---|
| out of scope (round 4's reading) | 64,0% | 71,1% |
| in scope (rounds 1–3's reading) | 76,0% | 84,4% |

Change 3 only makes sense under the first reading. Recommend: **out of scope** — the project's stated
object is *katolička tematika* — and that the rule be written into `README.md` so no future round
drifts again. Either way, nothing may quote a precision figure until this is settled.

**(b) Does the second pass stay on for the pre-2024 half? — ANSWERED 2026-08-10, yes, at 0,50.**
Round 5 read the 100 gate-2 rejects this plan asked for (`RESULTS.md` §11). The pile it discards is
**6,0% genuinely Catholic [2,8–12,5]**, so the second step costs 21,2% of the volume and 2,5% of the
genuine posts for **+12,3 points** of precision. The measured F1 curve is flat from 0,40 to 0,80, so
0,50 stands. **This corrects §10 and the first version of this plan**, which put the lift at ~3 points
by trusting a carried-over ~61% baseline for gate-1-only precision; measured directly it is 51,7%.
The AUC of 0,691 was computed inside the accepted tail only and does not bear on the threshold.

Stacked with the repaired gate 1: **76,2% clean at ~360 700 posts, keeping 97,5%** of the genuine
material gate 1 admits. Adopt both.

## 4. Sequence once (a) is answered

1. Adjudicate the 9 borderline round-4 labels and the 12 disputed rounds 1–3 labels (private CSVs).
2. ~~Round 5: ~100 gate-2 rejects, coded.~~ **DONE 2026-08-10** — see decision (b) above.
3. Promote v4 to `R/religious_terms_v4.R` + `R/lib/religious_filter_v4.R`, additive, v1/v2/v3 frozen
   — the moral-economy and inflation-salience gates pin v1 and must stay at 29/29 and 33/33.
   **HARD GATE, separate plan** (`.claude/rules/plan-first-workflow.md`): it redefines the corpus.
4. Rebuild **both** eras under v4. Fixing one era recreates the comparability confound for a new
   reason. Note the window fix also removes this junk class from the post-2024 half, where it has
   never been measured.
5. Fresh 250-post read of the actual rebuilt output. Nothing published until it exists.
6. Regenerate `data/processed/*.rds`, `data/nlp/`, `data/page-ready/`, the semantic store; re-render.

## 5. What this plan does NOT do

No file in `R/` was touched. No lexicon promoted, no master read for anything but a read-only URL
membership check, no aggregate rebuilt, no render. Rollback is deleting seven files under
`studies/filter-validation/` and the appended `RESULTS.md` §10.

## 6. Honest limits

- The repairs were chosen after seeing these 50 errors, so their measured gains are fitted. Only
  change 1 (n = 18, mechanism independent of the labels) and the 87,0%/11,1% denominational contrast
  stand on their own.
- 64,0% rests on 50 posts read by one coder who is not the PI. Treat every figure as ±8 points and
  the borderline labels as open.
- The window rule is an approximation of the real problem, which is that scraped `FULL_TEXT` often
  concatenates a whole portal page (see W01, W03, W12). De-boilerplating the scrape would be the
  proper fix and would also improve every downstream NLP layer, which currently reads the full blob.
