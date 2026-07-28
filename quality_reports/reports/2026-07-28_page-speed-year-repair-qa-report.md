# DigiKat page-speed, master-year repair, and final QA report

**Implementation date:** 2026-07-28  
**Workspace:** `DigiKat`  
**Scope authorized:** complete the remaining housekeeping work except moving the repository out of Dropbox  
**Publication scope:** local files and local Git history only; nothing was pushed or externally published  
**Overall status:** complete, with one known infrastructure limitation: a full `git fsck` remains impossible while
the Git database is hosted in Dropbox.

## 1. Executive result

The three slow language-analysis pages are now materially faster and produce the same analytical results as
before. Instead of reopening hundreds of megabytes of token-level data and repeating the same calculations every
time a page is rendered, they now read small, validated, page-ready summaries. All 15 chart/table input objects
were compared against the former calculations and passed equivalence checks, including attributes.

The incorrect master `year` field was repaired safely. Exactly 987 values were corrected, a byte-verified backup
of the former master was created before replacement, and all 46 other columns were proven unchanged. The repaired
master contains 710,307 rows and 47 columns and now has zero disagreements between `year` and the calendar year in
`DATE`.

Every downstream system affected by the new master fingerprint was then reconciled:

- all 14 public aggregate datasets remained exactly identical;
- all 15 page-ready analytical objects remained equivalent;
- the existing NLP sample and token membership remained valid;
- the 710,307-document semantic store passed document-level compatibility and structural validation;
- the dependency lockfile is consistent;
- all 133 website pages were rebuilt and link-checked.

Visual QA also corrected unclear or misleading presentation: Croatian interface labels were completed, raw internal
topic codes were replaced by readable labels, the word cloud was made legible, terminology was standardized, and
the Stepinac section was rewritten so that it describes only the two annual slices actually present in the sample.

No Dropbox relocation was performed.

## 2. Intuitive description of the page-speed change

Previously, opening any of the three language-analysis pages was like bringing the entire archive into the room,
sorting millions of words again, and only then drawing a handful of charts.

The new arrangement does that heavy sorting once in a controlled preparation step. It saves only the exact totals
and relationships that the pages need. A page now opens a small, checked package and draws the same charts from it.
The detailed source material remains available to the preparation pipeline, but it is no longer repeatedly loaded
during ordinary website rendering.

This separation has three practical advantages:

1. ordinary page rendering is substantially faster;
2. the calculation logic lives in one reusable, testable location;
3. the public page inputs contain aggregates rather than raw text, titles, URLs, or row-level records.

## 3. Language-page performance

### 3.1 Pages changed

The refactor covers:

- `pages/mapa/mapa_stats.qmd`
- `pages/mapa/diskurs.qmd`
- `pages/mapa/događaji.qmd`

The shared calculation and validation code is in:

- `R/lib/page_summaries.R`
- `R/05_page_summaries.R`

The main pipeline now validates the page-ready layer in production and builds it during the synthetic smoke test:

- `R/00_run_all.R`

### 3.2 Input-size reduction

The former pages collectively opened six NLP sample/token files totaling 453,143,006 bytes, approximately
432.2 MiB. The three new page-ready files total 2,206,545 bytes, approximately 2.10 MiB.

| Page | New page-ready input |
|---|---:|
| language statistics (`mapa_stats`) | 2,161,143 bytes |
| discourse (`diskurs`) | 4,891 bytes |
| events (`dogadjaji`) | 40,511 bytes |
| **Total** | **2,206,545 bytes** |

This is a 99.51% reduction in the files that ordinary rendering needs to read, or roughly a 205-fold smaller input
footprint. The old calculation path traversed 47,687,151 token rows across the three pages.

### 3.3 Measured timings

The legacy measurement below includes only the former page calculation phase. The new measurement includes the
entire page render, so the comparison is deliberately conservative.

| Page | Former calculation only | New full-page render | Conservative reduction |
|---|---:|---:|---:|
| `mapa_stats` | 84.03 s | 38.42 s | 54.3% |
| `diskurs` | 71.69 s | 29.11 s | 59.4% |
| `dogadjaji` | 70.86 s | 27.81 s | 60.8% |
| **Combined** | **226.58 s** | **95.34 s** | **57.9%** |

Because the former numbers exclude the rest of the rendering work, the actual end-to-end improvement relative to
the old full render is at least as good as shown here.

### 3.4 Equivalence proof

The former QMD calculations were preserved as recovery baselines and executed independently. Their resulting
plot/table inputs were compared with the newly prepared objects using `all.equal(..., check.attributes = TRUE)`.

| Page | Objects checked | Result |
|---|---:|---|
| `mapa_stats` | 7 | 7/7 equivalent |
| `diskurs` | 3 | 3/3 equivalent |
| `dogadjaji` | 5 | 5/5 equivalent |
| **Total** | **15** | **15/15 equivalent** |

The checked objects include the word-cloud frequencies, guided topic trends, thematic intensity, engagement,
polarization, leading actors, topic pairs, discourse heatmap, media strategy, discourse network, anomaly series,
spike dates, Easter dynamics, and Stepinac-associated terms.

The detailed object-by-object record, row counts, timings, and fingerprints are stored in:

- `quality_reports/recovery/page-equivalence-20260728/equivalence.json`

The pre-refactor sources and one-off comparison harness are retained under:

- `quality_reports/recovery/page-speed-baseline-20260728/`
- `quality_reports/recovery/run_page_equivalence.R`

### 3.5 Page-ready safety contract

`R/05_page_summaries.R` now provides two separate behaviors:

- normal execution validates that the installed page-ready files match their manifest and current inputs;
- `--build` constructs a complete candidate and installs it atomically only after validation.

Production validation rejects missing or unexpectedly empty analytical objects. Synthetic sample mode permits an
empty result only where a small fixture legitimately contains no matching Stepinac/event observations.

The tracked page-ready files disclose aggregate chart/table inputs only. They do not include `FULL_TEXT`, titles,
URLs, or row-level source records. Their manifest records the generator, disclosure contract, source fingerprints,
object row counts, and object fingerprints:

- `data/page-ready/manifest.json`

## 4. Master-year repair

### 4.1 Problem found

The master contained 987 rows where the stored `year` did not match the year derived from `DATE`:

| Stored year | Correct year from `DATE` | Rows |
|---:|---:|---:|
| 2023 | 2022 | 493 |
| 2024 | 2023 | 494 |
| **Total** |  | **987** |

These are year-boundary records dated 31 December. The stable rule is now explicit:

> `year` is the integer calendar year derived from `DATE`.

### 4.2 Safe repair procedure

The repair was implemented in `R/repair_master_year.R`. Before replacing the master, the script:

1. read and validated the 710,307-row, 47-column source;
2. calculated the exact mismatch set;
3. created a timestamped backup;
4. verified that the backup hash exactly matched the former master;
5. wrote a staged candidate;
6. verified row count, column count, names, and column classes;
7. fingerprinted every column to prove that only `year` changed;
8. atomically replaced the master;
9. reopened the installed file and independently validated it.

Dropbox briefly prevented immediate deletion of temporary replacement handles, but subsequent filesystem checks
confirmed that no `.replace-*` files remain.

### 4.3 Before, backup, and after

| Asset | Rows × columns | Bytes | SHA-256 |
|---|---:|---:|---|
| former master | 710,307 × 47 | 1,187,912,348 | `789fdc6ff710b5f5289ec81444876c1af56ffc8d2d30f220335ec7b853c9e59f` |
| verified backup | 710,307 × 47 | 1,187,912,348 | `789fdc6ff710b5f5289ec81444876c1af56ffc8d2d30f220335ec7b853c9e59f` |
| repaired master | 710,307 × 47 | 1,187,912,384 | `dd671e45882e1379418a0844a237f74402856133fd432ec9d42b4a7a1c3f2d35` |

Current independent check: **zero year/date mismatches**.

The recovery backup is:

- `data/merged_comprehensive_backup_year_20260728_095952.rds`

The full machine-readable repair record is:

- `quality_reports/data-integrity/master-year-repair-20260728_095952.json`

The report proves that `year` is the only changed column and contains hashes for all unchanged columns.

## 5. Downstream reconciliation after the master changed

Changing even one master value changes its file fingerprint. All systems that identify their inputs by fingerprint
therefore needed to be deliberately reconciled even where the analytical output was expected to remain unchanged.

### 5.1 NLP layer

`R/04_nlp.R --adopt-existing` verified exact sample membership, token membership, and sample/token alignment before
adopting the existing NLP generation under the repaired master fingerprint. The large token files did not need an
expensive rebuild because their actual selected records and tokens remained valid.

### 5.2 Public aggregates

A complete aggregate candidate was built in an isolated recovery directory and compared with the installed
generation.

Result: **14/14 aggregate RDS objects passed exact `identical()` comparison**, including values, row order,
attributes, and types.

The candidate was then installed atomically. The previous generation remains available at:

- `data/private/processed-backups/20260728_100903/`

The isolated comparison candidate is retained at:

- `quality_reports/recovery/aggregate-after-year-repair-20260728/`

### 5.3 Page-ready summaries

The page-ready summaries were rebuilt after the NLP manifest was reconciled. All 15 objects remained equivalent to
their pre-repair versions. Prior page-ready generations are retained under:

- `data/private/page-ready-backups/`

### 5.4 Semantic store

The 13.6 GB semantic index did not require rebuilding. Validation confirmed:

- 710,307 document rows;
- vector type `FLOAT[1024]`;
- 367,538,682 indexed terms.

This check also exposed a pre-existing contract mismatch: a newer preparation script generated hashed row IDs,
while the installed semantic store uses sequential IDs such as `dk_00000001`. The preparation step was corrected
to preserve the store-compatible sequential IDs under an explicit append-only row-order contract.

Adoption was then strengthened. `R/semantic/11_build.R` now checks more than document IDs: it verifies every row's
platform, date, and text-length signature before accepting an existing store. The prepared corpus and manifest
were regenerated, existing-store adoption passed, and structural validation passed.

This makes future silent misalignment substantially less likely without forcing an unnecessary rebuild of a
large, valid index.

## 6. Dependency and pipeline cleanup

The page refactor made several former direct dependencies obsolete. The dependency snapshot was corrected and
applied:

- removed unused `readr`, `textdata`, and `RColorBrewer` declarations;
- added the actually used `tibble` and `yaml` declarations;
- removed seven no-longer-needed lockfile entries: `bit`, `bit64`, `clipr`, `readr`, `textdata`, `tzdb`, `vroom`.

The project now has 42 active locked packages. Final `renv::status()` result:

> No issues found — the project is in a consistent state.

The regression suite was expanded to 38 checks. The final validation set includes:

- 38/38 regression checks passed;
- 51 active R files parsed and checked;
- 134 Quarto sources checked, with all R chunks parseable;
- 41 trackable study artifacts passed the disclosure guard;
- complete synthetic end-to-end smoke pipeline passed, including page-ready construction;
- complete production pipeline validation passed;
- page-ready production validation passed for all three files;
- semantic-store validation passed.

## 7. Visual and content QA

### 7.1 Full-site render

The complete site was rendered after all code and prose corrections.

| Check | Final result |
|---|---:|
| rendered HTML pages | 133 |
| total files in `docs/` | 210 |
| missing local links | 0 |
| missing anchors | 0 |
| detected mojibake signatures | 0 |
| source-adjacent `.html` / `.knit.md` debris | 0 |
| `docs/.nojekyll` present | yes |
| render error lines | 0 |

The previous post-render command depended on `Rscript` being available through the operating system's `PATH`.
That failed on this machine even though R itself was installed. The unnecessary hook was removed, and Quarto's
portable project-resource mechanism now preserves `.nojekyll` directly.

### 7.2 Croatian interface

The site now declares Croatian as its language. Because the installed Quarto version does not provide a complete
built-in Croatian interface, `_language.yml` supplies the interface labels. Visual inspection confirmed labels
such as:

- `Na ovoj stranici`
- `Objavljeno`
- Croatian-formatted dates

### 7.3 Chart readability

Representative page and chart screenshots were inspected. The following display-only improvements were applied:

- increased the word-cloud scale so it uses the available canvas;
- converted internal `SCREAMING_SNAKE_CASE` topic keys into human-readable labels;
- standardized relevant legends on the Croatian term `tonalitet`;
- improved topic, heatmap, and network labels without altering underlying analytical objects.

The shared display conversion is implemented in `R/theme_digikat.R`.

### 7.4 Stepinac interpretation correction

The visual check showed that the filtered 3% sample contains enough Stepinac associations only for 2023 and 2025.
The former prose nevertheless described a continuous 2021–2025 evolution. That claim was not supported by the
displayed data.

The section now:

- states explicitly that only 2023 and 2025 are represented;
- presents the figure as a comparison of available annual slices;
- describes the terms actually visible in each slice;
- avoids claims about unobserved 2021, 2022, and 2024 results;
- explains that a larger dedicated sample is required for a longitudinal conclusion.

This was a content-validity correction, not a numerical change.

### 7.5 Stale render artifacts

Final rendering exposed four obsolete `unnamed-chunk-7/8` PNG files from the former events-page structure. They
were not referenced by current source, HTML, or render metadata. The two production copies and two tracked freeze
copies were removed. The tracked copies remain recoverable through Git, and all four were generated artifacts.

## 8. Git and publication status

The substantive local work was organized into two coherent commits:

- `9bcffb3` — full repository housekeeping and pipeline hardening;
- `e8fa5e3` — page-ready NLP summaries and master-year repair;

The final small QA/report group could not be staged safely because Git resumed failing with the Dropbox-related
`mmap` error during `git add`. That remaining working-tree group consists of this report, the historical-report
notice, the corrected generated search index, and removal of two obsolete tracked freeze images. The substantive
code, page, data-manifest, localization, and pipeline changes are already in the two commits above.

Nothing was pushed, no pull request was opened, and no website deployment was triggered.

Git can currently read status and create commits in this working copy, but `git fsck --full` still fails with:

```text
fatal: mmap failed: Invalid argument
```

This is the known Dropbox-hosted Git metadata problem. Fixing it properly requires the one action expressly
excluded from this task: creating and verifying a fresh clone outside Dropbox. No attempt was made to rewrite,
repair in place, or relocate `.git`, because that would introduce unnecessary risk.

## 9. Recovery and audit trail

The main recovery points are:

| Purpose | Location |
|---|---|
| former master | `data/merged_comprehensive_backup_year_20260728_095952.rds` |
| master repair record | `quality_reports/data-integrity/master-year-repair-20260728_095952.json` |
| old aggregate generation | `data/private/processed-backups/20260728_100903/` |
| older page-ready generations | `data/private/page-ready-backups/` |
| former language-page sources | `quality_reports/recovery/page-speed-baseline-20260728/` |
| page equivalence proof | `quality_reports/recovery/page-equivalence-20260728/equivalence.json` |
| post-repair aggregate candidate | `quality_reports/recovery/aggregate-after-year-repair-20260728/` |
| visual-QA captures | `quality_reports/recovery/visual-qa-20260728/` |
| final full-render logs | `quality_reports/recovery/final-full-render.stdout.log` and `.stderr.log` |

Recovery records under `quality_reports/recovery/` and private generation backups are intentionally not treated as
public website content.

## 10. Final assessment

Within the authorized scope, the remaining housekeeping work is complete:

- the three heavy language pages are faster;
- their analytical outputs were proven equivalent;
- the master year field is correct and recoverable;
- downstream outputs were reconciled rather than assumed safe;
- the semantic store has a stronger alignment contract;
- unused dependency baggage was removed;
- visual and content QA corrected both presentation and an unsupported interpretation;
- the complete local site passes automated and visual checks;
- the substantive work is in two coherent local commits, while the final QA/report group remains uncommitted
  because of the Dropbox Git-database fault;
- no Dropbox relocation or external publication occurred.

The only unresolved item is the health of Git's underlying object database while it remains inside Dropbox. That
does not affect the validated project outputs, but it prevents a trustworthy full repository-integrity scan.
