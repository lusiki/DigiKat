# External source — DetermDB

**What this file is:** the record of an external database that sits UPSTREAM of the DigiKat master
corpus, where to find it, how it connects to `data/merged_comprehensive.rds`, and what it can and
cannot be used for.

**Status:** documented 2026-08-07. Not part of the DigiKat pipeline. Nothing in `R/` reads it yet.

The database has its own complete, standalone data dictionary — all 46 columns, per-platform field
availability, defects, query recipes. **Read that file before querying:**

```
C:\Users\lsikic\Luka C\DetermDB\DATA_DICTIONARY.md
```

This file does NOT repeat that content. It covers only the DigiKat relationship.

---

## 1. Location and status

| | |
|---|---|
| Path | `C:\Users\lsikic\Luka C\DetermDB\determDB.duckdb` |
| Size | ≈ 43,5 GB — **outside the repo, outside Dropbox** |
| Contents | one table `media_data`, 19 781 689 rows × 46 columns |
| Span | 2021-01-01 → 2024-07-04 |
| In git? | **No.** Never commit it, never move it into the repo or into Dropbox. |
| Machine | PI's pipeline machine only. Absent on any other clone. |

This is a **local, machine-specific asset**, in the same category as
`data/merged_comprehensive.rds` and `data/semantic/digikat.ragnar.duckdb`. Treat it as protected:
do not overwrite, prune, or relocate it without explicit confirmation.

Connect **read-only, always**:

```r
con <- DBI::dbConnect(duckdb::duckdb(),
                      dbdir = "C:/Users/lsikic/Luka C/DetermDB/determDB.duckdb",
                      read_only = TRUE)
```

---

## 2. What it is, in DigiKat terms

DetermDB is the **raw, unfiltered vendor feed** that DigiKat's 2021–2024 corpus segment was cut
from. Every row in it comes from one saved monitoring query (`GROUP_NAME = "Luka"`,
`KEYWORD_NAME = "opće"`), with **no topical filter of any kind**.

```
vendor monitoring platform
        │  query "Luka" / "opće"
        ▼
determDB.duckdb / media_data                          19 781 689 rows   2021-01-01 → 2024-07-04
        │  religious filter: >=2 DISTINCT term matches (R/religious_terms.R, 95 terms)
        ▼
data/merged_comprehensive.rds  WHERE data_source == "original_dta"
                                                         269 583 rows   2021-01 → 2024-07
```

**DigiKat's `original_dta` stream is 1,363% of this database** (269 583 / 19 781 689).

### Verification of the link

A random sample of 5 000 `URL` values drawn from `original_dta` was checked for membership in
`media_data`: **5 000 of 5 000 matched (100%)**. The schemas confirm it independently — DetermDB's
46 columns are the master's 47 minus the two DigiKat additions (`year`, `data_source`) plus the
vendor's `DATETIME`.

The `filtered_religious` stream is **not** in here, as expected: only 2,4% of its 2024 URLs and 0,1%
of its 2025+ URLs match. That stream came from a separate vendor archive export
(`GROUP_NAME = "Historical"`) covering 2024-07 onward.

### Independent confirmation of the inclusion rule

Replaying the canonical ≥2-distinct-term filter over all 269 583 `original_dta` rows: **94,1% pass**,
stable across years (2021 94,1% / 2022 93,7% / 2023 94,6% / 2024 93,7%). A 20 000-row
`filtered_religious` control passes at 100%. So the two master streams are built on materially the
same corpus definition; the ~6% shortfall is not what separates them.

---

## 3. Why this matters — three uses

### 3.1 It explains the missing months of 2024 — but does NOT recover them

The master has **no rows at all** for February–May 2024, and only 1 911 for January against a
~7 000/month norm. The rows exist in DetermDB, but **their text does not**:

| Month | DetermDB rows | `FULL_TEXT` missing | Master rows | Recoverable? |
|---|---|---|---|---|
| 2023-12 | 526 104 | 0,0% | 8 735 | already in |
| 2024-01 | 566 233 | **75,5%** | 1 911 | partly |
| 2024-02 | 484 321 | **100,0%** | 0 | **no** |
| 2024-03 | 527 441 | **100,0%** | 0 | **no** |
| 2024-04 | 513 136 | **100,0%** | 0 | **no** |
| 2024-05 | 489 286 | **100,0%** | 0 | **no** |
| 2024-06 | 487 350 | 0,0% | 8 477 | already in |
| 2024-07 | 67 369 (4 days) | 50,7% | 436 | partly |

Confirmed by direct probe: across all of February–May 2024 the strings `crkv`, `papa`, `biskup`,
`hrvat` and `zagreb` each occur **zero** times, because there is no text for them to occur in. Those
2 014 184 rows carry date, title, URL, source and engagement metadata only — the body is empty.

The gap in the DigiKat master is therefore **a defect inherited from the vendor feed, not a
processing loss**. Any text-based filter run over those months returns nothing, and no rerun of the
pipeline will change that. Closing the gap requires the vendor to re-supply the body text for
2024-02 → 2024-05.

Outside January–July 2024, `FULL_TEXT` coverage is good — about 3,3% missing. Nearly all of the
15,4% headline missingness in the database is concentrated in these few months.

### 3.2 It is the denominator the volume series lacks

The master's volume series is confounded: collection method changed in mid-2024 and capture roughly
tripled, so raw counts are not comparable across the break. Measured ratio ≈ 2,74 (old stream
~7 190 posts/month over 36 months; new stream ~19 700/month in 2025), against an observed 2023→2025
jump of 2,82 — meaning essentially **none** of the apparent rise survives as a substantive finding.

DetermDB fixes the measurement problem for the first era, because it is the *complete* feed those
269 583 rows were drawn from. Catholic-themed volume can be expressed as a **share of all monitored
Croatian media output**, which does not depend on crawl depth:

```sql
-- religion's share of total monitored output, monthly, 2021-01 .. 2024-07
SELECT strftime(DATETIME, '%Y-%m') AS month,
       COUNT(*) AS total_media,
       SUM(CASE WHEN <religious match> THEN 1 ELSE 0 END) AS religious,
       ROUND(100.0 * SUM(CASE WHEN <religious match> THEN 1 ELSE 0 END) / COUNT(*), 4) AS pct
FROM media_data GROUP BY 1 ORDER BY 1;
```

### 3.3 It does NOT close the 2024 break on its own

DetermDB ends 2024-07-04. The `filtered_religious` stream begins 2024-07. **There is no month in
which both instruments are observable**, so no direct calibration between them is possible. The only
usable overlap in the master is 2024-07 itself, where the old stream contributes 436 rows against
its own ~7 000 norm — far too thin to estimate anything from.

Closing the break properly needs one of:

- the equivalent **general** (`opće`) feed from the vendor for 2024-07 onward, which would extend the
  denominator across the whole period and make the break irrelevant; or
- a **backdated re-export** of the `Historical` archive query to 2021-01, which would replace
  `original_dta` with one consistent instrument end to end.

Both are vendor requests, and either is cheaper and stronger than any statistical patch.

---

## 4. Constraints on use

- **Read-only, always.** A read-write connection rewrites a 43,5 GB file and locks out other readers.
- **PII.** DetermDB is not anonymised: 696 980 distinct `AUTHOR` values, direct post URLs, full post
  text. Anything derived from it falls under `R/check_disclosure.R` and the rule that row-level
  output with URLs, titles, source identities, or text excerpts belongs in ignored
  `output/private/`. Nothing row-level from this database may be committed.
- **Do not treat vendor scores as measurements.** `AUTO_SENTIMENT` and `INFLUENCE_SCORE` are
  complete and tempting, but they are black-box vendor outputs unvalidated on Croatian. DigiKat's
  own sentiment layer (CroSentilex / CroSentilex Gold / lilaHR, see `pages/mapa/diskurs.qmd`) is the
  validated route.
- **`FOUND_KEYWORDS` is 100% noise** here exactly as it is in the master — every one of the
  19 781 689 values is the conjunction "i". It is not filter provenance. Confirms the note already
  in `MEMORY.md`.
- **Engagement metrics are not comparable across platforms.** Forum, Reddit and comment rows carry
  no reach or interaction data at all; their zeros are missing data. `VIRALITY` is web-only. Full
  availability matrix is in §5.5 of the standalone dictionary.
- **Dropbox hazard does not apply** — the file lives outside Dropbox, which is why it is safe to run
  long queries against it. Do not "tidy" it into the repo.

---

## 4a. Before any rebuild — the term list leaks (measured 2026-08-07)

Nine of the 95 regexes in `R/religious_terms.R` match common secular Croatian words. Verified by
direct probe, each of these words matches the term named beside it:

| Secular word | Meaning | Matches term | Pattern |
|---|---|---|---|
| `komisija` | commission | `misa` | `mis[aeiou][jmz]*` |
| `misija` | mission | `misa` | same |
| `gospodin` / `gospođa` | Mr / Mrs | `gospa` | `gosp[aeiou][jmsz]*` |
| `gospodarstvo` | economy | `gospa` | same |
| `demonstracije` | demonstrations | `demon` | `demon[aeiou]?[jmstz]*` |
| `časnik` / `časno` | officer / honourably | `časna` | `časn[aeiou][jmstz]*` |
| `posvećen radu` | dedicated to work | `posvećenje` | `posveć[aeioš][njv]...` |
| `križanje` / `Križevci` | intersection / town | `križ` | `križ[aeou]?[jmnvz]*` |
| `papir` / `papar` | paper / pepper | `papa` | `pap[aeiou][jmnstz]*` |
| `ukazano` | indicated | `ukazanje` | `ukazan[aeiou]?[jmstz]*` |

The patterns are unanchored, so they also fire inside longer words. Measured dependence on these
nine terms — the share of rows that fall below the ≥2 threshold once they are removed:

| Population | Passes with 95 terms | Passes with 86 | Depends on a loose term |
|---|---|---|---|
| DetermDB general feed (rows with text) | 4,91% | 2,05% | **58,3%** of passers |
| Master, `original_dta` | 93,99% | 80,47% | **14,4%** of passers |
| Master, `filtered_religious` | 100,00% | 53,35% | **46,6%** of passers |

**These are upper bounds on the damage, not false-positive rates.** A genuine article about the Pope
legitimately matches `papa`; removing the pattern discards it too. Establishing the true precision
requires hand-coding a random sample of passing items — that has not been done.

What the numbers do establish is that precision **depends on the base rate of the input**. Applied to
a vendor export that was already religion-oriented, the loose patterns cost relatively little.
Applied to a general feed where roughly 95% of items are not religious, they dominate: a document
containing "komisija" and "gospodin" passes the filter. This is the standard screening-test problem,
and it is why the term list must be tightened **before**, not after, any rebuild from the general
feed (§4b).

Changing `R/religious_terms.R` redefines the corpus and is a HARD GATE under
`.claude/rules/plan-first-workflow.md`.

## 4b. If a rebuild from the general feed is ever run

Applying the ≥2 rule to all of DetermDB would produce an estimated **828 556 rows**
(95% CI 811 188 – 845 924; measured on a 200 000-row sample, pass rate 4,1885%), which is **3,07×**
the current 269 583. That is the correct long-term direction — it replaces an undocumented,
unreproducible historical selection with one documented rule applied identically across the whole
period — but it must be sequenced:

1. Hand-code a random sample of passing items to measure precision as it stands.
2. Tighten the nine loose patterns; re-measure precision and recall against the coded sample.
3. Only then rebuild, and rebuild **both** streams with the same corrected list, or the two eras stop
   being comparable again for a new reason.

Note that a rebuild does not fix the mid-2024 instrument change (§3.3). It fixes the inclusion rule,
which is a different confound.

## 5. If a rebuild or recovery is ever run

Sequence, per `.claude/rules/data-pipeline-protocol.md`:

1. Write a plan to `quality_reports/plans/YYYY-MM-DD_determdb-2024-recovery.md`.
2. Confirm with the PI — this changes what is in the corpus.
3. Verified timestamped backup of `data/merged_comprehensive.rds` **before** any write.
4. Extract 2024-01-01 → 2024-07-04 from DetermDB, apply `digikat_match_religious(..., min_matches = 2L)`
   with the canonical 95-term list, and stage the result.
5. Deduplicate against the existing master with `canonicalize_url()` — January and June are already
   partly present, so overlap is expected and must be removed.
6. Emit the delta report: rows before / read / pass-rate / deduped / appended / after.
7. Atomic replacement of the master, then `Rscript R/03_aggregate.R` (preview) and `--apply`.
8. Regenerate `data/nlp/`, `data/page-ready/`, the semantic store, and re-render the map pages —
   a master change invalidates all of them.

Note the schema gap: DetermDB has `DATETIME` (which the master lacks) and lacks `year` and
`data_source` (which the master requires). Recovered rows are `data_source = "original_dta"`, since
they come from the same query as the rest of that stream.

Note also that recovery **narrows but does not remove** the confound. It fills a hole inside the old
regime; the mid-2024 instrument change remains.

---

## 6. Related documentation

| Where | What |
|---|---|
| `C:\Users\lsikic\Luka C\DetermDB\DATA_DICTIONARY.md` | Full standalone dictionary — all 46 columns, defects, recipes |
| `MEMORY.md` | Project learnings, incl. the `data_source` confound and `FOUND_KEYWORDS` |
| `CLAUDE.local.md` | Machine paths and protected local assets |
| `.claude/rules/data-pipeline-protocol.md` | Master-mutation rules |
| `.claude/rules/plan-first-workflow.md` | HARD GATE list |
| `R/religious_terms.R`, `R/lib/religious_filter.R` | The 95-term list and the ≥2 rule |
| `R/01_filter.R`, `R/02_merge.R` | How the two master streams were built and merged |
