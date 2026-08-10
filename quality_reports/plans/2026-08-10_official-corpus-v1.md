# Plan — build the official DigiKat corpus and repoint the site to it

**Date:** 2026-08-10 · **Owner:** PI · **Status:** EXECUTED — corpus, maps and live site regenerated (§5)
**Trigger:** PI, after the two-era rebuild — "create a new database that everything should point to …
this should be the official version of the DigiKat database."
**PI decisions taken 2026-08-10, before any file was written:**
threshold **0,70** (volume-leaning; 0,80 was the recommendation, 0,70 was chosen) and the window fix
**applied now, to both halves at once**.

---

## 1. What is being created, and what it is not

A new, derived, gitignored database holding only the posts the unified rule keeps:

```
data/digikat_corpus.rds        ← the official DigiKat database (gitignored)
data/digikat_corpus_manifest.json  ← tracked, no PII: what is in it and how it was cut
```

It is **derived, not primary**. The data flow gains one stage and still runs one way:

```
data/raw/*.xlsx
  → data/merged_comprehensive.rds        (legacy master, 710 307 rows — UNCHANGED, still the accumulator)
  → rule v4 + second pass @ 0,70 + window fix
  → data/digikat_corpus.rds              (THE official corpus — what the site describes)
  → data/processed/*.rds, data/nlp/*.rds (aggregates)
  → pages/**/*.qmd → docs/
```

The legacy master is **not** replaced, renamed, or edited. It stays the accumulator that
`R/append_new_data.R` writes to, and it stays the input every completed paper was computed from.
Nothing in this plan touches it, and no backup is moved or pruned.

## 2. The rule the corpus is cut by

| gate | what it does | source |
|---|---|---|
| 1 — word rule | ≥1 decisive term AND ≥2 terms total, over the **first 3 000 characters** | `R/religious_terms_v4.R` (119 terms) |
| 2 — second pass | ensemble model score ≥ **0,70** | `resources/models/second_pass_v2.rds` |

Both gates identical on both eras. That is the whole point of the exercise, and it is asserted in
code rather than trusted: `R/build_corpus.R` refuses to combine two decisions files cut by different
thresholds, and refuses to build if either half lacks the window flag.

**The window fix** is change 1 from `2026-08-10_filter-rule-v4-window-and-denomination.md`, promoted
here. Gate 1 previously read the whole text while gate 2 and the human coder read only the first
3 000 characters, so a post could be admitted on evidence nothing downstream ever saw; all 22 such
posts examined by hand across two rounds were not Catholic content. `R/backfill_window_flag.R`
recomputes gate 1 on truncated text for the post-2024 half, which was cut before the flag existed, so
the fix lands on both eras in the same operation and the eras stay rule-matched.

## 3. What it produced

| | pre-2024 | post-2024 | united |
|---|---|---|---|
| rows in | 269 583 | 440 724 | 710 307 |
| kept at 0,70, no window fix | 200 317 | 230 563 | 430 880 |
| dropped by the window fix | 7 456 | 9 439 | 16 895 |
| **kept in the corpus** | **192 861** (71,5%) | **221 124** (50,2%) | **413 985** (58,3%) |
| span | 2021-01-01 → 2024-07-04 | 2024-07-01 → 2026-06-11 | 2021–2026 |

`data/digikat_corpus.rds` is 413 985 × 54 (the accumulator's 47 columns plus seven `dk_*` provenance
columns: era, accumulator row, decisive and total match counts, model score, whether the retired
95-term rule would also have kept it, and the rule tag). 524 573 828 bytes.

The backfill answered the open question from §2: the post-2024 half is **5,4%** window-only accepts,
the same rate as pre-2024's 5,4%. The defect was never era-specific — it had simply never been
measured on that side.

Measured quality at 0,70 from the joint curve: ≈84,5% genuinely Catholic at 87,2% recall of genuine
material, era gap 13,6 points (68,0/87,0 at 0,40 → narrower here). The window fix removes posts the
audit found to be 0/22 genuine, so it can only raise precision; it is not separately re-measured, and
the corpus report will say so rather than claiming a measured improvement.

## 4. What gets repointed — and what deliberately does not

**Moves to the new corpus** (the PI's stated scope: landing page, its numbers, the maps):

| file | change |
|---|---|
| `R/lib/digikat_paths.R` | NEW — one resolver, so no path is typed twice |
| `R/03_aggregate.R` | default input → the corpus (still preview-by-default, `--apply` still gated) |
| `R/04_nlp.R` | default input → the corpus |
| `R/05_codebook.R` | default input → the corpus |
| `pages/baza.qmd` | reads the corpus; methods prose describes the two-gate rule |
| `index.qmd` | the six hero numbers computed from the manifest, not typed |
| `pages/mapa/*.qmd` | hard-typed "710.000" replaced by the manifest figure |

**Stays on the legacy master, explicitly and by name:**

`studies/moral-economy/**` (the RSP paper, complete), `studies/inflation-salience/**` (EMIP,
complete), `studies/catholic-education/**`, `studies/filter-validation/**`, `Church-and-dezinfo/**`,
`R/append_new_data.R`, `R/02_merge.R`, `R/rebuild_era.R`, `R/backfill_window_flag.R` and the
threshold/sample scripts. A finished analysis whose input silently changes underneath it is no longer
reproducible, and the rebuild scripts must read the master by definition. These analyses already
resolve the legacy master explicitly rather than inheriting the live site's default. A study that
wants the new corpus opts in; none is moved for it.

## 5. The consistency hazard — resolved 2026-08-10

The PI subsequently authorized running the maps. The transition was completed in the guarded order:

1. `Rscript R/03_aggregate.R` preview passed, then `--apply` installed 14 aggregate outputs from
   the 413 985-row corpus. The preceding generation is retained at
   `data/private/processed-backups/20260810_155400/`.
2. `Rscript R/04_nlp.R --build` installed new stratified samples and tokens: 20 658 documents for
   `mapa_stats`, 12 384 for `dogadjaji` and 8 250 for `diskurs`. Read-only validation then passed.
   The preceding generation is retained at `data/private/nlp-backups/20260810_163539/`.
3. `Rscript R/05_page_summaries.R --build` installed disclosure-safe page inputs; read-only hash and
   schema validation passed. The preceding generation is retained at
   `data/private/page-ready-backups/20260810_163720/`.
4. All 111 active, non-thematic site inputs were rendered with `quarto render --no-clean`. This
   includes the landing page, database description, six map pages, overview pages and 95 source
   catalog pages. Every render passed, all expected figures were present, UTF-8 Croatian diacritics
   survived, and no stale 710 307/710 000 corpus claim remained. The old 710 307 figure appears only
   where the database page explicitly distinguishes the legacy accumulator from the 413 985-row
   official corpus.
5. `pages/studije/**/*.qmd` is excluded from the active render list. Before and after the full render,
   all 19 tracked files across thematic sources, frozen results and published thematic HTML were
   checked: the final Git diff is zero, all nine published thematic HTML pages remain present, and no
   excluded QMD source is published into `docs/`. The thematic analyses continue to use their
   versioned legacy inputs and retain their published numbers.
6. SHA-256 comparison confirmed that the full render changed none of the 27 aggregate, NLP,
   page-ready and manifest files. The render was therefore a read-only consumer of the rebuilt data.

`digikat_assert_aggregates_current()` remains active: a future mismatch between the official corpus,
aggregate manifest and page-ready inputs still stops rendering rather than producing a mixed page.

## 6. What this does not fix

The 2024 instrument change is untouched, as it was in the rebuild. One inclusion rule across both
halves makes the eras **rule-comparable, not capture-comparable**; the kept share still steps ~20
points down at the 2024 break, and volume across that break still must not be read as rising
attention. Nothing short of the vendor re-supplying the data changes this, and the corpus manifest
carries the caveat so a downstream consumer cannot lose it.

## 7. Rollback

The accumulator and completed studies remain untouched. A rollback of the rendered map generation
must now restore `data/processed/`, `data/nlp/` and `data/page-ready/` from the three timestamped
private backups listed in §5, then restore the repointed map sources and rendered `docs/pages/mapa/`
outputs together. Restoring only one layer would recreate the mixed-generation state that the guard
is designed to prevent.
