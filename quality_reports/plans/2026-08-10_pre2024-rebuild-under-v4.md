# Plan — apply the v4 rule to the pre-2024 half, so both eras rest on one rule

**Date:** 2026-08-10 · **Owner:** PI · **Status:** EXECUTED — one PI decision open (§6)
**Trigger:** PI, after the post-2024 v4 rebuild — "run this procedure on the pre-2024 data … so the
two parts can be united on the same principles."
**Read-only** with respect to `data/merged_comprehensive.rds`. No aggregate rebuilt, no render.

---

## 1. What "the same principles" has to mean here

The post-2024 run cleaned master rows in place: gate 1 (word list v4) then gate 2 (second-pass model
v2) applied to the 440 724 rows where `data_source == "filtered_religious"`, keeping 259 354. The
matching operation on the other half is the identical two gates over the 269 583 rows where
`data_source == "original_dta"`.

**Scope decision — master rows only, not a feed rebuild.** DetermDB (19,8 M rows, 2021-01 →
2024-07-04) is the raw feed the pre-2024 stream was cut from, and a rebuild from it would recover new
material. It is deliberately **not** in scope here, because there is no equivalent feed for the
post-2024 half (`EXTERNAL_DETERMDB.md` §3.3: the archive query begins 2024-07 and no month is
observable on both instruments). Rebuilding one era from a feed and the other from the master would
replace the old confound with a new, larger one. A feed expansion stays available as a separate,
later decision; unification does not depend on it.

**Threshold decision — one threshold for both eras, then measured.** The tempting move is to tune the
gate-2 threshold separately for each era, since the pre-2024 half enters at a much higher base rate
(~70% genuine, against ~55% post-2024). That would equalise precision but would make the inclusion
rule itself era-dependent, which is precisely the confound this exercise exists to remove: volume
trends across 2024 would then partly track the threshold. So the rule stays **v4 + gate 2 at 0,40 in
both halves**, and the pre-2024 threshold curve is measured anyway and reported — if the two eras
genuinely demand different thresholds, that is a finding the PI decides on, not something to settle
silently inside a script.

## 2. Sequence

1. `R/rebuild_pre2024.R` — gate 1 + gate 2 over `original_dta`, storing the score for every row that
   passes gate 1, so the threshold stays re-settable without a rescan. Writes
   `data/rebuild/pre2024_decisions_v4.rds` (self-ignoring; carries URLs).
2. `R/draw_pre2024_sample.R` — the same blind stratified draw as post-2024: 100 word-rule rejects,
   100 gate-2 rejects, 50 kept as control, shuffled, reason hidden.
3. Code all 250 against the same five-label scheme
   (`catholic_clear` / `catholic_mention` / `religious_other` / `not_religious` / `cannot_tell`).
4. `R/set_threshold_pre2024.R` — re-weight the 250 by pile population, measure precision and recall,
   emit the threshold curve, and report what 0,40 costs against the era-local optimum.
5. Unified statement of the two halves under one rule, with the era break stated, not smoothed over.

## 3. What is carried over unchanged, and what that costs

Gate 1 matches on the **whole** `FULL_TEXT`, and gate 2 and the coder see only the first 3 000
characters. The window fix measured in `2026-08-10_filter-rule-v4-window-and-denomination.md` (§2,
change 1: 0 of 18 such posts genuine) is **not** in `R/religious_terms_v4.R`, which is terms-only, and
so was not applied to the post-2024 half either. Applying it to pre-2024 alone would break the very
comparability this plan is for. It stays an open item for **both** eras, and the coding round below
will show how much of the pre-2024 kept pile depends on evidence past 3 000 characters.

The denominational veto (change 3) is likewise not promoted and not applied.

## 4. Limits to state in the report

- Neither era's gate 1 is measured against material it rejects *outside* the master. Recall is recall
  within the corpus as collected, not within Croatian media.
- The 2024 instrument change is untouched by any of this. One inclusion rule across both halves makes
  the two eras **rule-comparable**; it does not make them **capture-comparable**, and the volume
  series still must not be read as rising attention.
- February–May 2024 has no text in the feed and therefore no rows in either half. The gap is a vendor
  defect and no rerun changes it.

## 5. What it produced (2026-08-10)

| | pre-2024 | post-2024 | united |
|---|---|---|---|
| rows in | 269 583 | 440 724 | 710 307 |
| kept at 0,40 | 218 299 (81,0%) | 259 354 (58,8%) | 477 653 (67,2%) |
| genuinely Catholic | **68,0%** [54,2–79,2] | 87,0% (weighted) | 77,9% |
| genuine material kept | 97,3% | 85,5% | 90,0% |
| genuine before the rule | 56,6% | 55,2% | — |

Both pre-2024 discard piles are 8,0% genuine, so the two gates together cost 2,7% of the era's
genuine material. Gate 1 accepts 87,6% of the era's rows, because `original_dta` was itself cut by a
keyword query — a vocabulary test has almost no discriminating power on a population selected by
vocabulary. Gate 2 therefore does all the work in this era, and at 0,40 it removes only 6,7%.

## 6. The decision that came out of it — the shared threshold should not be 0,40

Adding the two eras' measured curves (each weighted to its own populations, `R/joint_threshold.R`),
the united corpus reads: 0,40 → 77,9% clean at 90,0% recall (F1 83,5); 0,70 → 84,5% / 87,2% (85,8);
**0,80 → 88,0% / 84,0% (85,9)**; 0,90 → 91,3% / 81,1% (85,9). The era gap narrows with it: 19,0
points at 0,40, 13,6 at 0,70, 10,2 at 0,80. Recommend 0,80; 0,70 is defensible if volume matters
more. Exact counts at 0,80 are 189 769 + 216 568 = **406 337** (the sample-scaled 377 545 understates
volume by ~7%, because one read post in the kept pile stands for 4 366 real ones). Re-cutting costs
nothing — the score is stored for every gate-1 passer — but it changes what is in the corpus, so it
is a PI decision, not a script's.

This supersedes the 0,40 set on 2026-08-10 from the post-2024 curve alone.

## 7. Rollback

Delete `R/rebuild_pre2024.R`, `R/draw_pre2024_sample.R`, `R/set_threshold_pre2024.R` and the
`data/rebuild/pre2024_*` files. Nothing else is touched: the master, `data/processed/`, `data/nlp/`,
`docs/` and the frozen v1/v2/v3 word lists are all untouched by this plan.
