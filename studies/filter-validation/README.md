# Filter validation — how accurate is the ≥2 religious-term rule?

**Question:** of the posts the filter lets in, how many are really about the Catholic Church — and of
the posts it turns away, how many should have been let in?

Nobody has ever measured this. Every precision figure quoted about the DigiKat corpus is currently
an assumption. This study replaces the assumption with a hand-coded number.

**Owner:** PI · **Status:** sample drawn 2026-08-07, coding not started

---

## Why now

Two measurements made this urgent (both recorded in `data/EXTERNAL_DETERMDB.md`):

1. Nine of the 95 patterns in `R/religious_terms.R` match ordinary secular Croatian words —
   `komisija` and `misija` match *misa*, `gospodin`/`gospođa`/`gospodarstvo` match *gospa*,
   `demonstracije` matches *demon*, `časnik` matches *časna*, `križanje` and `Križevci` match *križ*,
   `papir` and `papar` match *papa*, `posvećen radu` matches *posvećenje*, `ukazano` matches
   *ukazanje*. The patterns are unanchored, so they fire inside longer words. A post reading
   "the commission met Mr. Horvat" contains two "religious" terms and passes.
2. Removing those nine terms drops 46,6% of `filtered_religious` and 14,4% of `original_dta` below
   the threshold. That is an upper bound on the damage, not an error rate — a real article about the
   Pope legitimately matches *papa* — which is exactly why it has to be coded by hand.

The decision this feeds is whether to rebuild the pre-2024 corpus from the full DetermDB feed
(projected ≈ 828 556 posts, 3,07× the current 269 583). Precision matters far more there than it
does today, because the general feed is ~95% non-religious, so loose patterns dominate what comes
back.

---

## Sample design

440 items, drawn with `SEED = 20260807`, **shuffled so the coder cannot see which stratum an item
came from**. Matched terms are hidden behind a click for the same reason.

| Stratum | n | Drawn from | Answers |
|---|---|---|---|
| **A** | 120 | master, `filtered_religious` | precision of the post-2024 corpus as published |
| **B** | 120 | master, `original_dta` | precision of the pre-2024 corpus as published |
| **C** | 100 | DetermDB, passes ≥2, **not already in the master** | precision of what a rebuild would ADD |
| **D** | 80 | DetermDB, exactly **1** term match | what the ≥2 threshold throws away |
| **E** | 20 | DetermDB, **0** term matches | sanity floor; should be ~all "not religious" |

Strata A and B measure what you have. C measures what you would gain. **D is the one people skip** —
a filter can look excellent on what it accepts while quietly binning half the real material, and
only the near-misses reveal that.

### Coding scheme

| Key | Label | Meaning |
|---|---|---|
| 1 | `catholic_clear` | The Catholic Church / Catholic life is the subject |
| 2 | `catholic_mention` | A real Catholic reference, but not what the item is about |
| 3 | `religious_other` | Religious, but Orthodox / Muslim / other |
| 4 | `not_religious` | No religious content |
| 5 | `cannot_tell` | Unreadable, empty, or genuinely ambiguous |

Two labels rather than one because precision has two defensible readings: strict (`1` only) and
loose (`1` + `2`). Report both.

---

## How to run it

**1. Draw the sample** (already done; re-run only if you want a fresh draw)

```
Rscript studies/filter-validation/01_draw_sample.R
```

Read-only against the master and DetermDB. Writes two gitignored files to `output/private/`.

**2. Code the items**

Open `output/private/coder.html` in a browser. Just double-click it — it is entirely
self-contained and needs no server or internet.

- Keys **1–5** label the item and advance automatically
- **← →** move without labelling
- Progress and a running tally per label sit in the header
- Work saves to the browser automatically after every click; closing the tab loses nothing
- *"pokaži koje su riječi okinule filter"* reveals the matched terms — use it **after** deciding,
  not before, or you will talk yourself into the filter's answer
- Notes field for anything worth remembering (borderline cases, recurring junk patterns)

Budget roughly 2–3 hours for all 440. It does not have to be one sitting.

**3. Export**

Click **Izvezi CSV**. Save the download over
`output/private/coding_sample_coded.csv`, then hand it back for analysis.

---

## Round 2 — the held-out 300 (drawn 2026-08-07)

Round 1's numbers were tuned on round 1's items, so they flatter themselves. This is the honest test.

```
Rscript studies/filter-validation/10_draw_holdout.R
```

`SEED = 20260808`, 300 items, **zero overlap** with the first 440 (round-1 URLs are excluded and the
script asserts it). Strata are re-based on what the **v3** rule does, and sample what it *accepts*
directly, so precision — the number that decides the rebuild — gets the tightest intervals:

| Stratum | n | Drawn from | Answers |
|---|---|---|---|
| **S1** | 75 | master, `filtered_religious`, v3 accepts | honest precision, post-2024 half |
| **S2** | 60 | master, `original_dta`, v3 accepts | honest precision, pre-2024 half |
| **S3** | 85 | feed, not in master, v3 accepts | **precision of what a rebuild adds** |
| **S4** | 60 | v3 rejects but ≥1 term matched | the recall v3 gives up |
| **S5** | 20 | feed, zero matches | sanity floor |

Coding is identical to round 1 — open `output/private/holdout_coder.html`, keys 1–5, export when
done, save as `output/private/holdout_sample_coded.csv`. Browser storage is keyed separately
(`digikat-filterval-holdout-20260808`), so round 1's progress is untouched. Budget ~1,5–2 hours.

Observed while drawing (sample-based, not a full count): v3 accepts **67,4%** of post-2024 master
rows, **88,3%** of pre-2024 master rows, and **3,14%** of the raw feed — of which 42,6% are already
in the master.

## What comes out of it

- Precision of the published corpus, both halves, strict and loose
- Precision of the ~558 000 posts a rebuild would add — the number that decides whether the rebuild
  is worth doing
- A miss rate from stratum D, and with it a defensible answer on whether ≥2 is the right threshold
  at all, or whether a tiered list (decisive terms alone; ambiguous terms needing company) does better
- A concrete list of which patterns produce the junk, to target the fix
- A fixed benchmark: any revised term list can be re-scored against these same 440 hand-coded items,
  so you can prove a change cut noise without cutting real content

---

## Files

| File | Tracked | What |
|---|---|---|
| `01_draw_sample.R` | yes | Draws the stratified sample, builds the coding tool |
| `coder_template.tpl` | yes | HTML/JS source of the tool (`.tpl` so gitignore's `studies/**/*.html` does not swallow it) |
| `output/private/coding_sample.csv` | **no** | 440 items with text and URLs — disclosive |
| `output/private/coder.html` | **no** | Same data embedded — disclosive |
| `output/private/coding_sample_coded.csv` | **no** | Your labels, after export |

Everything under `output/private/` carries post text, titles and URLs and is gitignored by
`.gitignore:73`. Verified with `git check-ignore`. Nothing from this study may be committed except
the two source files and this README.
