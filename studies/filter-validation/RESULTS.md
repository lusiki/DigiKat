# Filter validation — results

440 items hand-coded by the PI, 2026-08-07. All 440 completed. Aggregate figures only; no post text
or URLs appear here, so this file is tracked. Intervals are Wilson 95%.

Reproduce with `02_analyse_coding.R` (measurement) and `03_candidate_rule.R` (candidate rule).

---

## 1. How accurate the current filter is

"Clearly Catholic" = the Church or Catholic life is the subject. "Loose" also counts a real but
passing Catholic reference. `cannot_tell` items are excluded (there were none).

| Stratum | What it is | n | Clearly Catholic | Loose |
|---|---|---|---|---|
| **A** | master, `filtered_religious` (post-2024) | 120 | **55,0%** [46,1–63,6] | 64,2% |
| **B** | master, `original_dta` (pre-2024) | 120 | **70,0%** [61,3–77,5] | 76,7% |
| **C** | feed, passes ≥2, **not yet in master** | 100 | **19,0%** [12,5–27,8] | 29,0% |
| **D** | feed, exactly **1** term match (rejected) | 80 | 7,5% [3,5–15,4] | 15,0% |
| **E** | feed, **0** term matches (rejected) | 20 | 5,0% [0,9–23,6] | 5,0% |

### Three findings

**The post-2024 half is dirtier than the pre-2024 half.** 55,0% versus 70,0%, a 15,0 pp gap
(z = 2,42, p ≈ 0,016). Not a coin flip. The undocumented historical selection that produced
`original_dta` was doing real work; applying ≥2 to a vendor batch does less.

**A rebuild from the general feed, using the rule as it stands, would be a bad trade.** Stratum C is
what a rebuild would *add*, and it is 19,0% clean. On the projected ~559 000 added posts that is
roughly 106 000 genuine and 453 000 junk, dragging the whole pre-2024 corpus from 70% down to
about 36%. The rule must be fixed before, not after, any rebuild.

**The ≥2 threshold is not the main source of loss.** Only 7,5% of rejected one-term posts are
clearly Catholic. Stratum E's single positive is almost certainly a miscode (a forum thread about
private maternity wards, where *sestre* means nurses) — read as 0/20 it says the vocabulary is not
badly incomplete.

## 2. Which terms cause the damage

Share of accepted items containing each term that were **not** clearly Catholic. A row carries
several terms, so this attributes blame loosely — but it confirms the mechanism exactly.

| Term | rows | % not Catholic | | Term | rows | % not Catholic |
|---|---|---|---|---|---|---|
| demon | 20 | **85,0** | | sakrament | 10 | 0,0 |
| posvećenje | 48 | **70,8** | | redovnik | 10 | 0,0 |
| kler | 9 | **66,7** | | pobožnost | 9 | 0,0 |
| križ | 76 | **53,9** | | ispovijed | 8 | 0,0 |
| misa | 151 | **53,0** | | teološki | 11 | 0,0 |
| gospa | 118 | **51,7** | | hodočašće | 12 | 8,3 |
| ukazanje | 8 | 50,0 | | nadbiskup | 44 | 9,1 |
| papa | 78 | 48,7 | | krunica | 10 | 10,0 |
| časna | 33 | 45,5 | | nadbiskupija | 29 | 10,3 |
| kaptol | 11 | 45,5 | | biskup | 89 | 15,7 |

The ten worst are exactly the ten predicted from reading the regexes. All are unanchored patterns
that fire inside longer secular words.

## 3. A candidate repair, scored on the same 440 items

Two changes. **Anchor the ten leaking patterns to whole words** (`\bmis[aeu]\b|\bmisi\b|…` instead
of `mis[aeiou][jmz]*`), and drop standalone `časna`, which the multi-word term *časna sestra* already
covers. Then **tier the list**: 80 *decisive* terms that mean nothing outside a religious context,
and 14 *ambiguous* ones that need company.

| Rule | kept | Precision | Recall | F1 |
|---|---|---|---|---|
| **Current: any 2 of 95** | 277 | 59,2 [53,3–64,8] | 93,2 [88,5–96,1] | 72,4 |
| Repaired list, any 2 | 194 | 76,8 [70,4–82,2] | 84,7 | 80,5 |
| Repaired list, any 3 | 135 | 88,1 [81,6–92,6] | 67,6 | 76,5 |
| Tiered: ≥1 decisive | 199 | 73,9 | 83,5 | 78,4 |
| Tiered: ≥2 decisive | 143 | 86,7 | 70,5 | 77,7 |
| **Tiered: ≥1 decisive AND ≥2 total** | 176 | **81,2** [74,8–86,3] | **81,2** | **81,2** |
| Tiered: 2 decisive OR 1 decisive + 2 ambiguous | 153 | 85,0 | 73,9 | 79,0 |

Best balance is **≥1 decisive AND ≥2 total**: precision 59,2 → 81,2, at a cost of 12 pp of recall.
If precision matters more than coverage, *repaired list, any 3* reaches 88,1% at 67,6% recall.

By stratum, under the best rule:

| Stratum | precision before | precision after | recall after |
|---|---|---|---|
| A (post-2024) | 55,0 | **80,0** | 84,8 |
| B (pre-2024) | 70,0 | **88,4** | 90,5 |
| C (rebuild adds) | 19,0 | **55,0** | 57,9 |
| D / E (rejected) | — | correctly keeps 0 | 0 |

Stratum C nearly triples but stays the weakest, which is expected: the general feed is ~95%
non-religious, so it punishes any residual looseness hardest.

## 4. Caveats

**These precision figures are fitted, not validated.** The candidate rule was tuned against these
same 440 items, so 81,2% is optimistic. A fresh sample must be drawn and coded before the number is
quotable.

**Recall falls from 93,2% to 81,2%.** About one in eight genuine Catholic posts is dropped. For
descriptive work that is usually the right trade — a corpus that is 40% junk corrupts every
downstream sentiment, theme and actor statistic — but it is the PI's call, and both figures should
be reported.

**Attribution in §2 is loose.** Because items carry several terms, a false positive counts against
every term present. The re-scoring in §3 is the clean measure.

## 5. The repaired list as shipped

The candidate is now a tracked file, `R/religious_terms_v2.R` (94 terms, nine anchored patterns, a
`tier` column). **`R/religious_terms.R` is not modified** — the moral-economy census and the
inflation-salience pipeline both rebuild their regexes from it and fail loud on drift, so v1 stays
frozen and v2 is opt-in. Tier-aware matching lives in `R/lib/religious_filter_v2.R`, also additive.

`04_score_v2.R` scores the tracked file rather than an in-memory candidate. It asserts that v2 is
`identical()` to what §3 measured, then reproduces every row of the §3 table and the by-stratum
table exactly. Re-run it after any edit to the term list.

### Does nested matching need fixing?

`nadbiskupija` alone matches four distinct terms (biskup, nadbiskup, biskupija, nadbiskupija), so
"≥2 distinct terms" can be satisfied by a single word; `časne sestre`, `rimokatolička crkva`,
`sveti križ`, `papinstvo` and eight more behave the same way. Collapsing matches whose text span
sits inside another match:

| Rule | kept | Precision | Recall | F1 |
|---|---|---|---|---|
| tiered, as-is | 176 | 81,2 | 81,2 | **81,2** |
| tiered, nesting collapsed | 170 | 82,4 | 79,5 | 80,9 |

Six items (3,4% of those kept) pass only because of nesting, and three of the six are genuinely
Catholic. The trade is 1,2 pp of precision for 1,7 pp of recall — noise, for a slower and more
complex rule. **Recommendation: leave it.** Under the looser *any 2* rule the inflation is twice as
large (11 items, 5,7%), which is a further argument for the tiered rule over a plain threshold.

## 6. Can the v1 list improve on this? No. Missing vocabulary can.

Two ways to spend the 12 pp of recall the repair cost were tested (`06_improve_rule.R`), everything
tuned reported under 5-fold CV, five repeats, selection done inside the fold.

| Rule | fitted F1 | **CV F1** |
|---|---|---|
| v2 tiered (nothing fitted) | 81,2 | **81,2** |
| v2 + widened `papin`/`gospin` anchors | 81,2 | 81,2 |
| v2 + v1-only matches as a weak third tier | 80,8 | 80,8 |
| v2, terms re-tiered from the coded data | 82,3 | 80,9 |
| per-term weighted score | 82,5 | 80,3 |
| weighted score + v1-only count | 82,6 | 80,2 |
| logistic on (decisive, ambiguous, v1-only) | 81,4 | 79,6 |

**Nothing beats the plain tiered rule.** Every fitted gain evaporates under cross-validation — the
fitted-minus-CV gap of 1,4–2,4 pp is a direct measure of how much a tuned rule flatters itself on
440 items, and is the reason §4's caveat stands.

**The v1 patterns carry no residual signal.** Items where a loose pattern fires but the repaired one
does not are 43,8% Catholic against a 43,7% base rate — literally zero information. Two or more such
matches is 15,5% Catholic, i.e. *negative* evidence: that is the `gospodin` + `komisija` junk
signature. Anchoring did not discard usable information; it discarded noise.

**The recall is a vocabulary hole, not a rule problem** (`07_vocabulary_gap.R`). Of the 21 true
positives v2 drops relative to v1, 18 carry no decisive term at all and 6 match nothing whatsoever.
The list has *župnik* but not *župa*, *pobožnost* but not *molitva*, and nothing for Bog, Isus,
Krist, vjernik, samostan, propovijed, apostol or krštenje. Selecting replacement vocabulary
automatically **inside the CV folds** — the unbiased test — gives, per number of terms added:
5 → F1 83,0 · 10 → 83,5 · 20 → 83,6 · 40 → **84,8** (precision 80,1, recall 90,0).

### The curated expansion (v3 candidate)

`08_expanded_terms.R` turns those candidates into 25 hand-written patterns in the house style —
20 decisive, 5 ambiguous — each checked against the secular word it must not match (`župa` vs
`županija`, `krist` vs `kristal`, `bog` vs `bogatstvo`, `vjera` vs `vjerojatno`). Corpus artifacts
from the automatic list (*konferencije*, *ispis*, *prisutnosti*, *sati*, *video*) are excluded.

| Rule | kept | Precision | Recall | F1 |
|---|---|---|---|---|
| v1: any 2 of 95 | 277 | 59,2 | 93,2 | 72,4 |
| v2 tiered, 94 terms | 176 | 81,2 | 81,2 | 81,2 |
| **v3 tiered, 119 terms** | 201 | **80,1** | **91,5** | **85,4** |

v3 recovers essentially all the recall the repair cost — 91,5 against v1's 93,2 — while holding
precision at 80,1 against v1's 59,2. Nothing is lost: every item v2 kept, v3 keeps. Clearly Catholic
items missed falls from 33 to 15.

By stratum, and this is what matters for the rebuild:

| Stratum | v2 precision / recall | v3 precision / recall |
|---|---|---|
| A (post-2024) | 80,0 / 84,8 | 78,8 / **95,5** |
| B (pre-2024) | 88,4 / 90,5 | 89,0 / **96,4** |
| C (rebuild adds) | 55,0 / 57,9 | **59,3** / **84,2** |

The curated terms were written after seeing the coded data, so 85,4 is optimistic like 81,2 is. But
the automatic version, selected strictly inside the CV folds, lands at 84,8 with 80,1 precision —
within noise of the curated result. Two routes with different exposure to the data agree, which is
the strongest evidence available short of the fresh sample.

Per-term precision is uniformly good: *krist* 97,6%, *vjernik* 96,6%, *apostol* 95,0%, *isus* 93,8%,
*župa* 91,8%, and *propovijed*, *homilija*, *samostan*, *spasenje*, *klanjanje*, *procesija*,
*djevica marija* at 100%. The two weak ones are *kapela* (50%, n = 4) and *duša* (72,7%) — both
candidates for removal on PI review.

## 7. Round 2 — the held-out 300 (coded 2026-08-07). These are the honest numbers.

300 fresh items, `SEED = 20260808`, zero overlap with the first 440 (asserted). Integrity checked
before scoring by `11_check_holdout_coding.R`: 300/300 coded, no duplicate ids, every id agreeing
with the drawn item's URL and stratum, diacritics intact. Scored by `12_score_holdout.R`.

| Stratum | what it is | n | strict | loose |
|---|---|---|---|---|
| **S1** | master post-2024, v3 accepts | 75 | **77,3%** [66,7–85,3] | 77,3% |
| **S2** | master pre-2024, v3 accepts | 60 | **80,0%** [68,2–88,2] | 85,0% |
| **S3** | feed not in master, v3 accepts | 85 | **47,1%** [36,8–57,6] | 51,8% |
| **S4** | v3 rejects, ≥1 term matched | 60 | 13,3% [6,9–24,2] | 18,3% |
| **S5** | feed, zero terms matched | 20 | 0,0% [0–16,1] | 0,0% |

**The fitted numbers were optimistic, exactly as §4 and §6 warned** — and the size of the error
scales with how far the population sits from the tuning data:

| | fitted (round 1) | honest (round 2) | drop |
|---|---|---|---|
| post-2024 corpus | 78,8 | **77,3** | 1,5 |
| pre-2024 corpus | 89,0 | **80,0** | 9,0 |
| what a rebuild adds | 59,3 | **47,1** | 12,2 |

The post-2024 figure holds up almost exactly. The rebuild figure does not, and it is the one the
decision turns on. Note the direction of travel is still large: v1 measured **19,0%** on that same
population in round 1, so v3 is 2,5× better there even after the correction.

Feed-wide, weighted by the measured population shares (1,34% accepted and already in the master,
1,80% accepted and new, 4,97% rejected with ≥1 match, 91,88% rejected with none):
**precision 61,1%, recall 74,4%.**

### What it means for the rebuild (`13_rebuild_tradeoff.R`)

| Option | posts | genuine | junk | clean |
|---|---|---|---|---|
| **A.** keep pre-2024 as it is, re-filtered by v3 | 265 100 | 212 100 | 53 000 | **80,0%** |
| **B.** rebuild pre-2024 from the full feed under v3 | 622 100 | 380 100 | 242 000 | **61,1%** |

Rebuilding buys **168 000 more genuine Catholic posts (+79%)** and costs **18,9 points of
cleanliness**. That is a real choice rather than the obvious "no" it was under the broken rule,
where the same rebuild was 19% clean and would have dragged the corpus to ~36%. It is the PI's call,
and it depends on whether the work needs coverage or cleanliness.

### Limits of round 2

- Recall **inside the master** is not estimable from this draw: S4 was sampled from the feed only,
  so there is no measurement of genuine posts the current corpus holds that v3 would now reject.
  Round 1 covered that (v3 keeps 67,4% of post-2024 and 88,3% of pre-2024 master rows) but under
  fitted terms. If the re-filter decision matters, that stratum needs its own draw.
- The projection onto 19 781 689 rows assumes the reservoir sample is representative of rows with
  non-empty text. It is a sample estimate, not a count.
- S5 is 0/20. The vocabulary is not obviously incomplete, and round 1's single zero-term positive
  (the maternity-ward thread where *sestre* meant nurses) now looks even more like a miscode.

## 8. Would coding 400 more items raise precision? No — but a second pass would

Asked whether another 400 hand-coded items would buy more precision. Answered from the 740 already
coded, before spending any reading time.

**A second-pass classifier on top of v3 is a large, immediate gain.** Keep v3 as the recall-oriented
sieve; add a classifier (bag of 6-character token stems + the tier counts + length, Naive-Bayes
score fed to a logistic) that removes junk from what v3 accepts. All figures 5-fold CV.

| Population | v3 alone | + second pass | operating point |
|---|---|---|---|
| items v3 accepts, pooled | 75,9% | **84,1%** | keeps 94% of the genuine |
| master rows | 83,6% | **90,7%** | keeps 87% |
| new feed material (S3) | 51,9% | **80,7%** | keeps 80% |

**More coded data would not help** (`15_where_to_spend.R`). Adding feed-specific coded items to the
training set — 0, 20, 40, 70 — gives precision 73,4 · 70,8 · 75,0 · 73,0 on held-out feed items.
Flat, within noise. The learning curve on the pooled set (`14_learning_curve.R`) plateaus by
n ≈ 220 of the 402 accepted items available: 83,8 · 83,6 · 86,7 · 88,7 · 88,5 at n = 80 · 120 · 160
· 220 · 280. The classifier is not data-starved; it has already learnt what these labels teach.

### What that does to the rebuild (`17_rebuild_with_second_pass.R`)

| Option | posts | genuine | junk | clean |
|---|---|---|---|---|
| A. keep what you have, v3 only | 265 100 | 212 100 | 53 000 | 80,0% |
| A+. keep what you have, v3 + second pass | 203 400 | 184 500 | 18 900 | **90,7%** |
| B. rebuild, v3 only | 622 100 | 380 100 | 242 000 | 61,1% |
| **B+. rebuild, v3 + second pass** | 369 400 | **318 400** | 50 900 | **86,2%** |

B+ against today's corpus: **+106 300 genuine Catholic posts (+50%) and cleaner** (86,2% vs 80,0%).
The second pass discards roughly 157 000 junk posts from the new material alone.

### Caveats before this is adopted

- **It has not been validated out of sample.** The CV figures are honest about the *threshold*, but
  the architecture and features were chosen while looking at these 740 items. This is the same trap
  §4 and §7 documented, and the correction there was 1,5–12,2 points.
- **It was fitted on the 3 000-character excerpts** shown to the coder, not full article text.
  Re-verify on full text before deployment.
- **It costs volume.** The existing corpus goes 265 100 → 203 400 posts to reach 90,7%.
- **It is a model, not a rule** — less transparent than a term list, harder to state in a methods
  section, and it must be frozen and versioned like the lexicon or results stop reproducing.

**Where 400 items would genuinely help:** not training, but (a) an out-of-sample test of the second
pass, which is required before betting a rebuild on it, and (b) narrowing the rebuild precision
interval, currently [36,8–57,6] on 85 items.

## 9. Recommended sequence

1. Approve the repaired regexes and the decisive/ambiguous split (HARD GATE: edits
   `R/religious_terms.R`, so a plan and confirmation are required).
2. Re-run the new rule over the full DetermDB feed to get the real rebuilt size — the old projection
   of 828 556 assumed the broken rule and no longer applies.
3. Draw and code a fresh held-out sample (~300 items) to get an honest precision figure.
4. Rebuild **both** eras with the same rule. Fixing only one recreates the comparability problem.
5. Publish shares of total monitored output, never raw counts.

## 10. Round 4 — 50 posts read from the pre-2024 output (2026-08-10)

Everything above was measured somewhere other than the thing being decided: round 1 tuned the word
list, round 2 sampled what gate 1 accepts with no second step, round 3 read the post-2024 output.
Nobody had read the **pre-2024 rebuild's own output** — feed rows that pass gate 1 *and* score
≥ 0,50 on the frozen second pass. `20_draw_pre2024_output.R` draws 50 of them at random from a
50 744-row reservoir sample of the feed, excluding all 990 previously coded URLs, and prints for
each post the words that admitted it, in context. `21_code_pre2024_output.R` records the coding.

Coder: assistant, single coder, not the PI. Nine items are marked BORDERLINE and need adjudication.

| | read | genuinely Catholic | incl. passing mention |
|---|---|---|---|
| all 50 | 50 | **64,0% [50,1–75,9]** | 78,0% |
| already in the corpus | 28 | 78,6% [60,5–89,8] | 89,3% |
| new material a rebuild would add | 22 | 45,5% [26,9–65,3] | 63,6% |

The per-segment rates reproduce round 2 (S2 80,0%, S3 47,1%) almost exactly, so the *segments* are
settled: pooled over both rounds, 79,5% in-corpus (n = 88) and 46,7% new (n = 107).

**The 79,5% in `pre2024_threshold_plan.csv` does not survive.** That projection applied out-of-fold
second-pass scores to the coded items and read off an 18-point precision lift. Measured on fresh
output the lift is about 3 points: gate 1 alone implies ~61% on this population, and the pile that
actually comes out at threshold 0,50 is 64,0%. AUC of the second-pass score against the labels on
these 50 is **0,691**; median score 0,997 on genuine posts and 0,934 on junk. This is the same
failure as round 3 (predicted 90% retention, delivered 84%), one order of magnitude larger.

### 10.1 The window defect — the largest single finding

Gate 1 searches the **entire** `FULL_TEXT`. Gate 2 and every human coder see only the **first 3000
characters**. So a post can be admitted on evidence nobody who judged it has ever seen.

- **161 of 1653** gate-1 accepts in the pool — **9,7%** — pass *only* on matches beyond character
  3000. Median length 7967 characters against 1988 for posts that pass inside the window.
- `25_window_probe.R` drew 15 of the 161 to read; three more turned up inside round 4.
  **0 of those 18 are genuinely Catholic** (0,0% [0,0–17,6]). Six of 15 are passing mentions, the
  rest are portal index pages, New Age columns and political polemic.
- 29% of the stratum is already in the master, so this junk is in the published corpus too, and the
  same defect applies to the post-2024 half.

Restricting gate 1 to the same 3000-character window costs 53 100 projected posts (545 200 →
492 100) and, on the read 50, moves precision **64,0% → 71,1% with zero genuine posts lost**.
The honest cost is visible in W12: a health-portal blob that also carries a full Easter liturgy
explainer past character 3000. The deeper fix is de-boilerplating the scrape; the window rule is the
cheap correct approximation, and it makes admission evidence and adjudication evidence the same text.

### 10.2 Pattern repairs the errors point at (`23_measure_repairs.R`)

| repair | measured effect |
|---|---|
| **`božji` decisive → ambiguous** | kills the two pious-formula false positives ("Počivao u miru Božjem" + "Bog i Hrvati"; "za ime Božje" + "dušu"). On the read 50: 71,1% precision, no genuine loss. On all 1040 coded posts: removes 8 junk, costs 2 genuine. |
| formulaic-`Bog` stoplist (26 phrases) | **no additional effect.** Once `božji` is ambiguous, those posts have no decisive term left. Do not add the complexity. |
| `blaženi` restricted to *bl. <Name>* / *Blažena Djevica* | **no additional effect** at population level. "blaženoj sedmogodišnjoj romansi" is already dropped by other repairs. |
| drop `duša`, `kaptol` | 3 junk removed, 1 genuine lost across 1040 items; nothing on the read 50. Marginal — PI's call. |

New homonyms found, for the record: **`križni put`** matches the 1945 death march (a political-history
sense, not the devotion) and **`župnik`** matched a rapper's stage name. Neither is fixable by pattern.

### 10.3 Denomination — the rule has no negative evidence

Six of the 50 are religious but **not Catholic**: one Muslim, three evangelical/charismatic
Protestant, one generic biblical forum exegesis, one celebrity-faith item. The second pass scores
them 0,86–1,00, the highest median of any class, because its features (Bog, Isus, molitva, vjera)
are the shared Christian core.

Catholic-specific vocabulary separates them cleanly. Among accepted coded posts, **87,0%** of
`catholic_clear` carry at least one of the 54 Catholic-specific terms (papa, biskup, župa, misa,
sakrament, krunica, franjevac, redovnica, katedrala, procesija …) against **11,1%** of
`religious_other`.

| variant | effect on the read 50 | effect on all 1040 coded |
|---|---|---|
| **F** require ≥ 1 Catholic-specific term | 71,1 → 82,4% precision, 4 of 32 genuine lost | 74,2 → 76,8%, **54 of 415 genuine lost (13%)** |
| **G** veto only when a non-Catholic religious marker is present **and** no Catholic term | 71,1 → **76,2%**, **0 genuine lost** | 74,2 → 74,9%, 12 of 415 lost |

G is the better deal by a wide margin. But its 12 "losses" on the pooled data are the reason it
cannot be adopted without a decision — see below.

### 10.4 A coding divergence the PI must settle

Rounds 1–3 produced **7 `religious_other` labels in 990 posts (0,7%)**. Round 4 produced 6 in 50
(12%). That gap is not sampling noise. Isolating the disputed class — accepted posts carrying an
Islamic / Orthodox / Protestant marker and **no** Catholic-specific term — finds **12 posts coded
`catholic_clear` in rounds 1–3** and 0 in round 4. The earlier rounds treated non-Catholic Christian
devotional prose as in scope; round 4 did not. Listed in `denomination_adjudication.csv` (private).

The headline depends on which convention holds:

| convention | precision of the read 50 | + window fix |
|---|---|---|
| non-Catholic Christian devotion is **out** of scope (round 4) | 64,0% | 71,1% |
| non-Catholic Christian devotion is **in** scope (rounds 1–3) | 76,0% | **84,4%** |

Nothing downstream should quote either figure until the PI writes the scope rule down. Note the
project's own stated object is *katolička tematika*, which argues for the round-4 reading, but the
corpus is topical and the call is the PI's.

### 10.5 What the recommended stack projects (`24_recommended_stack.R`)

Gate 1 limited to the window + `božji` ambiguous + veto G, then gate 2 at 0,50:

| stage | posts | already in corpus | new | est. genuine | est. clean |
|---|---|---|---|---|---|
| v3 as specified today | 545 200 | 44,2% | 55,8% | — | — |
| gate 1, repaired | 461 700 | 47,9% | 52,1% | 336 100 | ~73% |
| + gate 2 ≥ 0,50 | 363 700 | 47,9% | 52,1% | 264 700 | ~73% |

Against 269 583 posts at 79,5% clean (≈ 214 000 genuine) today. So the rebuild still roughly
**doubles the pre-2024 half and adds ~50 000 genuine posts**, but it does *not* get cleaner — it goes
from ~80% to ~73%, because half of what it adds is new material that is only 46,7% genuine. The
earlier claim of "doubles and gets cleaner at the same time" was an artifact of the 79,5% projection.

### 10.6 What still is not measured

- **What gate 2 throws away on this population.** This draw sampled only gate-2 accepts, so the
  0,50 threshold cannot be evaluated against 0,00 from these data. With AUC 0,691 and a 21,2%
  volume cost, the second step may not be worth running on the pre-2024 half at all. Round 5 should
  draw a matched sample of gate-1-pass / gate-2-reject items.
- **The repairs are fitted to these 50 errors.** Only the window fix and the denominational
  contrast have independent mechanisms and n large enough to stand on. Everything else needs a
  fresh draw after the rebuild, exactly as §9 step 3 prescribed.
- Nine borderline labels in round 4 and 12 disputed labels in rounds 1–3 are unadjudicated.

## 11. Round 5 — 100 posts read from what the second step DISCARDS (2026-08-10)

§10.6 said the 0,50 threshold could not be priced from a sample of accepts alone. `28_draw_gate2_rejects.R`
draws 100 random posts from the other side: gate 1 accepts them, the second pass scores them below 0,50.
Gate 1 is held at v3-on-full-text exactly as round 4 drew it, so the two samples are a two-stratum
sample of one population (1653 gate-1 accepts in the 50 744-row pool: 1302 kept, 351 discarded) and can
be reweighted — each read accept stands for 26,04 posts, each read reject for 3,51.

| what the second step throws away | read | genuinely Catholic |
|---|---|---|
| all 100 | 100 | **6,0% [2,8–12,5]** |
| new material | 79 | 5,1% |
| already in the corpus | 21 | 9,5% |

Including passing mentions it is 56,0%, and that is the whole story of this pile: **50 of the 100 are
`catholic_mention`** — state and local commemorations, funeral notices, civic anniversaries and municipal
programmes that contain a Mass, a prayer or a priest. Croatian civic life is saturated with Catholic
ritual, so a term filter cannot help meeting it. The other 40 are not religious at all.

### 11.1 Correction to §10 — the second step does earn its keep

§10 put the second pass's lift at about 3 points, by comparing the measured 64,0% of the kept pile against
a ~61% estimate of gate-1-only precision carried over from round 2's strata. **That baseline was too high.**
Measured directly on the reweighted two-stratum sample, gate-1 accepts are **51,7% genuine**, so:

| | posts (projected) | clean |
|---|---|---|
| gate 1 only | 545 186 | 51,7% |
| gate 1 + second pass ≥ 0,50 | 429 421 | **64,0%** |

It costs **21,2% of the volume and 2,5% of the genuine posts for +12,3 points of precision.** That is a
good filter, not a marginal one. The AUC of 0,691 reported in §10 was computed inside the accepted tail
only and is the wrong statistic for a threshold decision; it should not be quoted as evidence about the
threshold.

### 11.2 The threshold curve, measured rather than projected

Reweighted over the 150 coded posts (`threshold_curve_measured.csv`). Recall here is recall *within
gate-1 accepts*, which is the frame the threshold decision lives in.

| threshold | posts | genuine | precision | recall | F1 |
|---|---|---|---|---|---|
| 0,00 | 545 186 | 281 775 | 51,7 | 100,0 | 68,1 |
| 0,30 | 453 731 | 279 460 | 61,6 | 99,2 | 76,0 |
| **0,50** | **429 421** | **274 829** | **64,0** | **97,5** | **77,3** |
| 0,70 | 386 479 | 257 652 | 66,7 | 91,4 | 77,1 |
| 0,80 | 360 713 | 249 064 | 69,0 | 88,4 | 77,5 |
| 0,90 | 300 594 | 223 299 | 74,3 | 79,2 | 76,7 |

F1 is flat from 0,40 to 0,80 (76,7–77,5), so there is no measured reason to move off **0,50**. The six
genuine posts in the reject pile score 0,140 / 0,258 / 0,359 / 0,391 / 0,450 / 0,495 — bunched just under
the threshold, against a reject-pile median of 0,131, which is what a working score looks like.

### 11.3 Stacking the two repairs

| | posts | clean | keeps of the genuine |
|---|---|---|---|
| v4 gate 1 only | 448 695 | 62,5% | 99,6% |
| v4 gate 1 + 0,30 | 379 236 | 73,7% | 99,2% |
| **v4 gate 1 + 0,50** | **360 713** | **76,2%** | **97,5%** |
| v4 gate 1 + 0,70 | 334 948 | 76,9% | 91,4% |

The repaired gate 1 buys almost as much precision as the second pass does (51,7 → 62,5) at a twentieth of
the recall cost, and the two compose: together they reach **76,2% clean while keeping 97,5% of the genuine
material gate 1 admits.** Recommendation for the rebuild: adopt both, threshold 0,50.

### 11.4 More homonyms, all toponyms

Seven of the 100 passed on a place name: **Općina Biskupija** (`biskup`, `biskupija`), **Sveti Križ
Začretje** (`sveti križ`, four separate posts), **Vatikanska ulica** (`vatikanski`), **Općina Kapela**
(`kapela`). Also `oltar` in the patriotic metaphor *oltar Domovine* and `bog` + `isus` in the idiom *nema
boga isusa*. A toponym stoplist is straightforward but low value — all seven were already discarded by
the second pass — so it is recorded rather than recommended.

### 11.5 Still not measured

- Both rounds were coded by one coder who is not the PI, under the round-4 scope reading (§10.4). The
  scope question is untouched by round 5 and still gates every published figure.
- The 56% mention rate in the reject pile means the strict/loose distinction now carries real weight. If
  the PI ever wants the Church's presence in civic life as a research object, this discarded pile is the
  data, and it should be kept as a labelled side-stream rather than thrown away.
