# QA report — DigiKat 2025 annual-report pilot

Date: 2026-08-07  
Scope: internal **Izvještaj 0**, calendar 2025  
Product disposition: **revise and re-pilot; public publication is a no-go**

## Build result

The bounded pilot completed from current reviewed aggregates without opening the master corpus, changing
canonical aggregates, editing `_quarto.yml`, writing to `docs/`, or deploying. The private report rendered to
HTML and Typst PDF outside the repository; the render wrapper verified an unchanged `docs/` fingerprint.

| Gate | Result |
|---|---|
| Data readiness | 39 PASS, 6 WARN, 0 FAIL — ready with warnings |
| Report mechanical checks | 50/50 PASS |
| Headline numeric re-derivation | 8/8 correct after revision |
| Disclosure guard | PASS — 147 trackable study artifacts inspected |
| HTML/PDF render | PASS |
| Protected-path diff | clean for `data/`, `R/`, `_quarto.yml`, and `docs/` |

The six readiness warnings are intentional gates: a scoped `renv` waiver for unused `lmtest` and `sandwich`,
separate 5%/3%/2% NLP sample designs, partial 2026 coverage, missing stream markers in annual aggregates,
351/365 represented event-sample days, and proposed rather than ratified outlet labels.

## Independently verified headline values

| Claim | Re-derived value |
|---|---:|
| Recorded 2025 posts | 236,166 |
| Web share of post volume | 64.3818% |
| Facebook share of post volume | 18.8435% |
| Posts in the two classified source categories | 28.0904% |
| Confessional share inside that classified subset | 45.5246% |
| Most frequent guided dictionary category in the 5% thematic sample | 24.5473% |
| Detected high-volume days in the 3% event sample | 4 |
| Posts in the strongest event-sample day | 106 |

## Review corrections incorporated

- Repaired recycled platform interaction/reach shares and added normalization tests.
- Recomputed AR05 benchmarks within platform × typology and removed pooled medians from the typology table.
- Removed all-NA institutional candidate rows.
- Disclosed that theme, event, and tone layers are separate unweighted 5%/3%/2% samples that exclude TikTok
  and texts of 100 characters or fewer.
- Added the nine-category thematic remainder and downgraded thematic language from a population finding to a
  dictionary-sample diagnostic.
- Added a 351/365 event-calendar coverage artifact and downgraded AR08 to partial/coverage blocked.
- Reframed special-chapter detector layers as candidates and identified the adjusted estimate as pair-level.
- Replaced the geographic subtitle with an evidence-bounded corpus description.
- Removed absolute local paths from the public manifest and added NLP, special-chapter, and generator hashes.

The detailed review issue log is private at `studies/annual-report/output/private/review/issue_log.csv`.

## Unresolved edition-1 blockers

The internal dummy is coherent, but a public edition remains blocked by:

1. sample weighting or full-corpus NLP measures plus uncertainty and human validity tests;
2. complete calendar and collection-stream coverage diagnostics;
3. a governed annual actor × platform panel and stable eligible universe;
4. PI ratification of source labels and a defensible classification frame;
5. an annual tone/conflict measure with direction, range, uncertainty, and conflict definition;
6. a complete sixteen-theme annual table and reviewed event-naming evidence.

These are recorded with owners and acceptance conditions in `studies/annual-report/GAPS.md`.
