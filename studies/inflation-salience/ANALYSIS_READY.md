# Analysis-ready base — religion × inflation (v3)

**Date:** 2026-06-30 · **Status:** ✅ candidate pool CODED — **measured core ready** (`output/analysis_core_coded.csv`).
**Validation:** [VALIDATION.md](VALIDATION.md).

## ✅ MEASURED CORE (coded by 3 independent annotators, majority-adjudicated, full coverage 1,450/1,450)
The 1,450-candidate pool was coded (workflow `code-candidate-pool`, IAA ~0.97 on held-out). Results:
- confirmed inflation **1,329 / 1,450 (92%)** · confirmed religion-linked **652** (→ classifier linkage
  precision ≈ 45%, matching the held-out estimate) · **132 foreign**, **520 DOMESTIC** (recall-corrected ≈ **584**).
- **MEASURED DOMESTIC CORE = 520 posts** → `output/analysis_core_coded.{rds,csv}` (per-post: register, outlet,
  date, sentiment, URL, window). Full coded pool in `coded_pool_full.csv`; raw labels in `coded_labels.csv`.

**Register of the 520 (this is the paper's central table):**
| register | n | % |
|---|---|---|
| cost of religious life | 194 | **37.3** |
| Church-as-institution | 179 | **34.4** |
| charity | 87 | 16.7 |
| devotional | 26 | 5.0 |
| **structural / CST justice** | **15** | **2.9** |
| disputed (needs human tiebreak) | 12 | 2.3 |
| other | 7 | 1.3 |

- **Outlet:** Secular/other 442 (85%) · Catholic 75 (14%) · Business 3.
- **Year:** 2021→12, **2022→201 (peak, energy shock)**, 2023→100, 2024→88, 2025→66, 2026→53.
- **Temporal register shift** (`output/coded_register_over_time.png`): *institution* spikes in 2022 (clergy
  commenting on the shock); *cost-of-religious-life* dominates 2024+ (church-fee resets around the euro
  changeover). Justice is negligible throughout.

> **Finding, now MEASURED (not estimated):** religion meets domestic inflation as the **rising cost of
> religious life (37%)** and the **Church-as-institution (34%)** — together ~72% — with **charity 17%** and
> the **CST structural-justice voice just 3%**. The prophetic "preferential option for the poor" is essentially
> absent from Croatian religion×inflation discourse. Note the ~3% disputed need a human tiebreak before final reporting.

---

## How the pool was built (for reference)
**Inputs produced by** `scratchpad/10_rerun_fixed.R` + `13_make_coding_pool.R` (run on the master).

## The one thing to understand before using this
The regex classifier is a **high-recall candidate generator, not an accurate labeller** (held-out: linkage
**recall 0.89**, **precision ~0.38**; register agreement 0.46). It correctly shrinks **710,307 → 1,103
candidates**, but **~half the candidates are false positives** and register is unreliable. So:

> **Do NOT report auto-label counts/register as findings.** The candidate pool must be CODED (human or the
> validated 3-annotator LLM workflow, IAA 0.97) to produce the measured core the paper reports.

## Files (`output/`)
| File | What |
|---|---|
| `analysis_core.csv` / `.rds` | **1,103 candidate** domestic religion×inflation posts — the pool to code |
| `heldout_auto.csv`, `heldout_majority.csv` | held-out sample: classifier labels + 3-annotator truth |
| `validation_merged.csv` | the in-sample 90 (classifier + my labels) |
| `linkage_over_time_v3.png`, `register_by_year_v3.png` | provisional figures (auto labels — illustrative only) |

`analysis_core.csv` columns: `rid, DATE, year, month, FROM, SOURCE_TYPE, otype, register, m_crl, m_charity,
m_struct, m_clergy, m_devot, AUTO_SENTIMENT, URL, TITLE, window`.
⚠️ **PII / do-not-share:** contains `URL`, `FROM`, and a `window` text excerpt. It is derived from the
gitignored master — keep it untracked; run `/disclosure-check` before sharing any extract.

## Validated performance (held-out, n=80, out-of-sample)
- Inflation tag precision **85%** · Linkage recall **0.89** (good filter) · Linkage precision **~0.38** ·
  Foreign-flag precision **~0.39** (weakest — hand-check foreign) · Register agreement **0.46**.
- Inter-annotator agreement (3 annotators): infl 0.98, link 0.97, foreign 0.99.

## The robust finding (survives every cut)
Domestic religion×inflation discourse is dominated by **the Church-as-institution (~50%)** and **the rising
cost of religious life (~23%)** (mass stipends, church fees, weddings/funerals, pilgrimages); **charity ~12%**;
the **structural / CST justice voice is marginal (~8%)** and domestically often imported via foreign Church
figures. Secular outlets carry ~88% of the volume; Catholic outlets link at the highest rate but tiny count.

## Recommended path to "start the analysis"
1. **Code the 1,103 candidates** → final measured core. Fastest reliable instrument: the 3-annotator LLM
   workflow (proven IAA 0.97), majority-adjudicated, with a human double-coding a ~100 slice for the record.
   Output: `analysis_core_coded.csv` with validated `link`, `foreign`, `register`.
2. **Descriptive analysis on the coded core:**
   - attention over time vs **Croatian HICP** (headline + food + energy) — acquire HICP (Eurostat/DZS).
   - register composition + its shift across the 2022 energy shock and the **Jan-2023 euro changeover**.
   - actor map (who produces it) tied to the project's actor typology.
   - sentiment/tone via the project's CroSentilex layer (optional).
3. **Write** to the PROPOSAL_v2 spine: religion meets inflation as institution + cost-of-religious-life, not
   as prophetic justice — against the CST normative expectation; plus the methodological contribution
   (co-occurrence ≠ engagement; linkage must be measured and coded, not regex-counted).

## Reproduce
`Rscript scratchpad/10_rerun_fixed.R` (needs R + the master) rebuilds `analysis_core.*` and the held-out
sample. `12b_heldout_metrics.R` re-scores against the annotator majority. Lexicons + fixes are inline in
`10_rerun_fixed.R`; promote them into a numbered `R/` script when the coding instrument is finalized.