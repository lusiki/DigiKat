# Plan — repaired + tiered religious filter (v2), as a separate file

**Date:** 2026-08-07 · **Owner:** PI · **Status:** tasks 1–3 DONE and verified; 4–7 await sign-off
**Trigger:** `studies/filter-validation/RESULTS.md` §5 step 1

**PI decision, 2026-08-07:** do **not** edit `R/religious_terms.R`. The corrected list lives in its
own file and only code that explicitly opts in reads it. Nothing that reads v1 today changes
behaviour, so this is no longer a HARD GATE change — it adds files, it does not redefine the
corpus. The gate returns at task 5 (switching ingestion) and at the rebuild.

---

## 1. What was adopted

The filter repair measured on the 440 hand-coded items, shipped as a new list:

- **Nine unanchored patterns anchored to whole words** — `komisija` no longer counts as *misa*,
  `gospodin` as *Gospa*, `demonstracije` as *demon*, `papir` as *papa*, `Križevci` as *križ*.
- **The standalone term `časna` dropped** (`časna sestra` already covers it): 95 → 94 terms.
- **Two tiers** — 80 *decisive* terms, 14 *ambiguous* ones that need company.
- **Inclusion rule** `>=1 decisive AND >=2 total`, replacing *any 2 distinct terms*.

The 14 ambiguous terms: `misa`, `gospa`, `papa`, `križ`, `demon`, `posvećenje`, `ukazanje`, `kler`,
`kaptol`, `kršćanin`, `kršćanstvo`, `vatikan`, `duhovnost`, `blagoslov`.

### The nine anchored patterns

| Term | v1 (unanchored) | v2 |
|---|---|---|
| misa | `mis[aeiou][jmz]*` | `\bmis[aeu]\b\|\bmisi\b\|\bmisom\b\|\bmisama\b\|\bmisn[aeiou]` |
| gospa | `gosp[aeiou][jmsz]*` | `\bgosp[aeiu]\b\|\bgospom\b\|\bgospin[aeiou]*\b` |
| papa | `pap[aeiou][jmnstz]*` | `\bpap[aeiou]\b\|\bpapom\b\|\bpapin[aeiou]*\b` |
| križ | `križ[aeou]?[jmnvz]*` | `\bkriž(a\|u\|em\|evi\|eva)?\b` |
| demon | `demon[aeiou]?[jmstz]*` | `\bdemon(a\|i\|u\|om\|ima)?\b\|\bdemonsk[aeiou]` |
| posvećenje | `posveć[aeioš][njv][aeiou]?[jmstz]*` | `\bposvećenj[aeu]\b` |
| ukazanje | `ukazan[aeiou]?[jmstz]*` | `\bukazanj[aeu]\b` |
| kler | `kler[aeiou]?[jmnstv]*` | `\bkler[aui]?\b\|\bklerik` |
| kaptol | `kaptol[aeiou]?[jmstz]*` | `\bkaptol[aeiou]?\b` |

`\b` is Unicode-aware in ICU/stringi, so the anchors are safe with č ć ž š đ. No ASCII folding
(`.claude/rules/croatian-encoding.md` §3).

---

## 2. Why a separate file, not an edit

Two manuscripts pin `R/religious_terms.R` and **fail loud** if it changes:

- `studies/moral-economy/lexicon.R:82–112` rebuilds its religion regex from that file and applies
  five homonym tightenings by exact-pattern match. Four of the five targets disappear under the
  repair, so `me_build_religion_regex()` stops with "lexicon drift" — taking the RSP paper's
  reproduction route (29/29) with it. `01_stageA_tag_linkage.R:35` also records the file's md5.
- `studies/inflation-salience/_lib.R:91–93` builds its regex the same way; the EMIP v2 route is
  `RUN_ALL.R --v2 --no-network`, gate 33/33.

Keeping v1 untouched at its own path costs nothing and leaves both gates intact. The v2 list is
opt-in: a script reads the repaired rule only by naming `R/religious_terms_v2.R`.

**Files added (three; zero existing files modified):**

| File | What |
|---|---|
| `R/religious_terms_v2.R` | 94 terms, nine repairs, `tier` column; self-asserting (94 / 80 / 14) |
| `R/lib/religious_filter_v2.R` | sources the v1 library, adds `digikat_load_religious_terms_v2()`, `digikat_hit_matrix()`, `digikat_tier_counts()`, `digikat_passes_inclusion_v2()`, `digikat_collapse_nested()` |
| `studies/filter-validation/04_score_v2.R` | scores the tracked v2 file against the 440 coded items |

---

## 3. Verification — DONE (2026-08-07)

`Rscript studies/filter-validation/04_score_v2.R`, rc = 0.

**Drift check passed:** the tracked `R/religious_terms_v2.R` is `identical()` on `term`, `root`,
`regex` and `tier` to the candidate that `03_candidate_rule.R` measured. The file encodes exactly
what was scored — it is not a re-typing that drifted.

**Every row of `RESULTS.md` §3 reproduced exactly** (kept / precision / recall):
277 / 59,2 / 93,2 · 194 / 76,8 / 84,7 · 135 / 88,1 / 67,6 · 199 / 73,9 / 83,5 · 143 / 86,7 / 70,5 ·
**176 / 81,2 / 81,2** · 153 / 85,0 / 73,9. By-stratum likewise: A 55,0 → 80,0, B 70,0 → 88,4,
C 19,0 → 55,0, D and E correctly keep nothing.

### The nesting question (plan §3 of the earlier draft) — ANSWERED, do nothing

`nadbiskupija` alone matches four distinct terms, so "≥2 distinct" can be satisfied by one word.
Measured with span-containment collapse (`digikat_collapse_nested()`):

| Rule | kept | Precision | Recall | F1 |
|---|---|---|---|---|
| v2 tiered, as-is | 176 | 81,2 | 81,2 | **81,2** |
| v2 tiered, nesting collapsed | 170 | 82,4 | 79,5 | 80,9 |

Only **6** items (3,4% of those kept) pass the tiered rule solely because of nesting, and **3 of
the 6 are genuinely Catholic** — a coin flip. Collapsing buys 1,2 pp of precision for 1,7 pp of
recall, which is noise, in exchange for a materially more complex and slower rule. **Recommendation:
do not collapse.** The effect is documented and measured; that is enough. (Under the looser "any 2"
rule the inflation is larger — 11 items, 5,7% — which is one more reason to prefer the tiered rule.)

---

## 3b. Follow-up (2026-08-07): can it be improved further?

Asked whether the v1 95-term list could be combined with v2 to do better. Tested under 5-fold CV
(`06_improve_rule.R`): re-tiering from data, per-term weighted scoring, v1-only matches as a weak
third tier, and a logistic on the counts. **All of them lose under CV** (79,6–80,9 F1 against 81,2).
Items where a v1 pattern fires but the repaired one does not are 43,8% Catholic against a 43,7%
base rate — no information at all; two or more such matches is 15,5%, i.e. negative evidence.

The recall is a **vocabulary hole**: 18 of the 21 lost true positives carry no decisive term, and 6
match nothing. The list has *župnik* but not *župa*, *pobožnost* but not *molitva*, and nothing for
Bog, Isus, Krist, vjernik, samostan, propovijed, apostol, krštenje.

`08_expanded_terms.R` adds 25 curated patterns (20 decisive, 5 ambiguous), each guarded against its
secular homonym: **v3 = 201 kept, precision 80,1, recall 91,5, F1 85,4**, against v2's 81,2 / 81,2
and v1's 59,2 / 93,2. Nothing v2 kept is lost. Stratum C — what a rebuild would add — goes
55,0 / 57,9 → 59,3 / **84,2**. Automatic in-fold selection independently reaches 80,1 / 90,0, which
is the unbiased corroboration.

**Decision needed:** promote the expansion to `R/religious_terms_v3.R` (same additive pattern, no
existing file touched). This is a lexicon change, so it is a plan-first item — hence the ask rather
than the edit. Recommend dropping *kapela* (50%, n = 4) and reviewing *duša* (72,7%) first.

## 4. Remaining work — needs sign-off

4. **Record the outcome.** Append a §6 to `studies/filter-validation/RESULTS.md` naming the v2 file,
   the drift check, and the nesting answer; add a `[LEARN]` line to `MEMORY.md`.
   *Status: RESULTS.md §6 written; `MEMORY.md` line pending PI approval of the wording.*
5. **Re-count the rebuild under the repaired rule.** Run v2 over the DetermDB feed
   (`C:\Users\lsikic\Luka C\DetermDB\determDB.duckdb`, read-only, 19,78 M rows) to get the real
   rebuilt size. The old projection of 828 556 assumed the broken rule and no longer means anything.
   Read-only, touches nothing; the only cost is runtime. **This is the natural next run.**
6. **Fresh held-out sample.** Draw ~300 new items and code them, to replace the fitted 81,2% with an
   honest one. Nothing may quote 81,2% until this exists.
7. **Rebuild both eras under v2**, then switch `R/01_filter.R` / `R/append_new_data.R` to the v2
   rule, regenerate `data/processed/*.rds`, re-render. **HARD GATE — separate plan.**

## 5. Explicitly NOT done

- `R/religious_terms.R`, `R/lib/religious_filter.R`, `R/01_filter.R`, `R/append_new_data.R`,
  `R/00_setup.R`, `tests/run_tests.R`, `pages/baza.qmd`, and both frozen studies are **untouched**.
  Ingestion still runs the v1 ≥2 rule; the corpus is unchanged.
- No master write, no `R/03_aggregate.R --apply`, no render, no rebuild.

## 6. Rollback

Three new files on a clean tree; deleting them restores the prior state completely. No existing file
was modified, no data asset touched, no backup needed.

## 7. Open questions for the PI

- **(a) Recall.** 93,2% → 81,2% drops roughly one genuine Catholic post in eight. Recommended:
  accept — a corpus that is ~40% junk corrupts every sentiment, theme and actor number built on it.
  Both figures get published. The alternative on the table is *v2 list, any 3*: 88,1% precision at
  67,6% recall.
- **(b) Appends before the rebuild.** Pause `R/append_new_data.R`, or keep appending under v1 and
  accept a third inclusion regime in the master? Recommended: pause.
- **(c) Nesting.** Answered above — recommend no change.
- **(d) The stratum-E miscode.** The single zero-term post coded clearly Catholic is a forum thread
  about private maternity wards where *sestre* means nurses. If it is a miscode, the last hint that
  the vocabulary is incomplete disappears. Does not block anything.
