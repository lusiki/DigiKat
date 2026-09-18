# Barometar: independent numeric-claim review, 2026-09-18

Reviewer: fresh-context numeric-claim verifier. The initial review was read-only except for this report. During the explicitly requested retest, added source-free R/JavaScript regression tests; no implementation, frozen definition, engine or metrics code was edited by this reviewer. No source article, held-out evaluation text, external work directory, or restricted database was opened.

## Verdict and boundary

**Method-only conference PDF: PASS for the numeric and status claims checked here.** Its metadata matches its own `output/conference/summary.json`, the frozen panel, G1/G2, and the frozen validation code. It states that human validation is incomplete and contains no empirical indicator, precision estimate, or media finding.

**Synthetic preview: PASS for the numeric and cross-format claims checked here, with the opening-week contract qualification below.** Headline numbers, count arithmetic, CSV/payload agreement, SVG point values and matrix colors MATCH. The parent implementer corrected both initial findings; the independent final retest below confirms their resolution.

This is an artifact-level verdict, not L1 completion, release approval, human validation, a source-data audit, or a conclusion about Croatian media. Every indicator value below is **invented synthetic test data**. The 12-member synthetic panel is distinct from the frozen 115-member methodological panel. G3 remains pending.

## Re-derived claims

| Claim / surface | Written or selected value | Independently derived value and source | Verdict |
|---|---|---|---|
| Synthetic panel | 12 invented outlets | `docs/data/barometar/demokrscanstvo/summary.json`: `synthetic=true`, `panel_outlets=12`, `panel_version=synthetic_panel`; same metadata in HTML payload | MATCH |
| Monthly, wide, August 2026 visibility | 322.6 per 10,000; 12 of 372 | `monthly.csv`, scope `siri`, period `2026-08`: 10,000 × 12 / 372 = 322.58064516129 | MATCH |
| Monthly, wide, August 2026 breadth | 91.7%; 11 of 12 | Same row: 100 × 11 / 12 = 91.66666666667 | MATCH |
| Monthly, narrow, August 2026 visibility | 161.3 per 10,000; 6 of 372 | `monthly.csv`, scope `uze`, period `2026-08`: 10,000 × 6 / 372 = 161.290322580645 | MATCH |
| Monthly, narrow, August 2026 breadth | 50.0%; 6 of 12 | Same row: 100 × 6 / 12 = 50 | MATCH |
| Weekly-view wide headline | 327.4 per 10,000; 11 of 336; 83.3%; 10 of 12 | `rolling28.csv`, wide, 2026-08-10 through 2026-09-06: 10,000 × 11 / 336 = 327.380952380952; 100 × 10 / 12 = 83.3333333333333 | MATCH |
| Weekly-view narrow headline | 178.6 per 10,000; 6 of 336; 50.0%; 6 of 12 | Same rolling window, narrow: 10,000 × 6 / 336 = 178.571428571429; 100 × 6 / 12 = 50 | MATCH |
| Weekly headline's period | 2026-W36, explicitly trailing 28 days | Latest fully available week ends 2026-09-06; `barometar-core.js` selects the rolling row ending that day | MATCH |
| Raw wide W36 values, distinct from weekly-view headline | 238.1 per 10,000; 2 of 84; 16.7%; 2 of 12 | `weekly.csv`: 10,000 × 2 / 84 = 238.095238095238; 100 × 2 / 12 = 16.6666666666667 | MATCH |
| Synthetic human precision / agreement | Not completed, no estimates | `validation.csv` header only; `validation_summary.json` precision and agreement null; all 5,138 theme records `unconfirmed`; `findings=[]` | MATCH |
| Method PDF panel | 115, `panel_v1` | Counted 115 data rows in `config/panel_v1.csv`; `config/gates.json:G1_panel.panel_size=115`; own conference summary also 115 | MATCH |
| Method PDF definition | `1.0.0+33429974d0b8` | Same conference summary and `config/gates.json:G2_definition.definition_version` | MATCH |
| Method PDF edition and source cutoff | `metoda-2026-09-18`, `2026-09-10` | Same values in its own `output/conference/summary.json`; independently extracted from actual PDF, page 2 | MATCH |
| Method PDF validation quotas | Up to 60 per main route, 100 recall-probe cases | Frozen `R/lib/barometar_validation.R:36`: A1/B/C quotas 60 each, recall_probe 100 | MATCH |
| Method PDF pre-specified gates | Precision at least 0.80; qualification κ at least 0.70 | Frozen `R/lib/barometar_validation.R:126,150`: route precision ≥ .8; weighted broad precision ≥ .8 and qualification κ ≥ .7 | MATCH |
| Method PDF empirical status | Human validation incomplete, no empirical findings | Own summary `human_validation_complete=false`; G3 pending; visible PDF status box and page-2 version box | MATCH |

Croatian display uses decimal commas. Both headline statuses are `published` (meaning available within this explicitly synthetic demonstration). The rates are not empirical findings. The main summary's weekly card stores rolling-28 values, while `weekly_comparison` stores raw-week values; this distinction is correct.

## Cross-format checks

- Verified all 39 manifest file hashes against the actual synthetic downloads.
- Reconciled all embedded fields against CSV: 138 monthly rows, 596 weekly rows, and 594 embedded rolling rows. The full rolling export contains 4,158 rows; embedding only week-ending rolling rows is intentional.
- Each of the four scope-specific CSV files exactly equals the corresponding scope subset of its full monthly or weekly CSV.
- For all monthly, weekly, and rolling rows, recalculated every non-null visibility and breadth rate from its numerator and denominator; no arithmetic mismatch. Narrow article counts never exceed wide counts. Every unavailable indicator is null, not zero.
- Verified the amended invariants from the accepted execution plan: `N >= D`, `P >= P_t`, `P >= M` in all rows, additionally `P_t >= M` for weekly/rolling rows. Monthly `P_t` requires five articles while `M` requires one matching article, so `P_t >= M` is not a monthly invariant. The 79 monthly rows that would fail the original blanket assertion are **not defects** under the explicit approved amendment at `quality_reports/plans/2026-09-18_demokrscanstvo-barometar.md:242–245`.
- Exact route-set composition counts sum to each period/scope's matching-article count. Embedded theme counts, reconstructed theme rates, and period availability match `themes.csv` in all four selections.
- Parsed actual default HTML cards: 322.6, 91.7%, 12/372 and 11/12 agree with the August-wide CSV and summary. All four enhanced headline selections follow the same verified `BarometarCore.headline` logic. This reviewer inspected the DOM-generation source; the separate browser reviewer owns interactive UI coverage.
- Independently parsed all eight downloadable SVGs and compared plotted circle coordinates to ordered CSV dates and values. Dates and values are affine-consistent within 0.006 SVG points, the two-decimal SVG serialization tolerance. Point counts agree (65 monthly visibility marks per scope, three monthly breadth marks per scope, 285 weekly visibility marks per scope, 15 weekly breadth marks per scope). The constant narrow monthly breadth series is correctly horizontal.
- PNG and SVG are generated from the same plot object in `09_figures.R`. Visually inspected the wide monthly and weekly visibility PNGs. Did not independently invert every PNG pixel into a numerical value; the SVG geometry check is the precise plot-data check.
- Inspected both rendered pages of the actual method PDF using the existing page PNGs and extracted text directly from `demokrscanstvo-metoda-2026-09-18.pdf`. Numerals and version strings are visible and legible. No empirical series is included.
- The current validation source SHA-256 equals the G2 frozen evidence hash. Therefore the PDF thresholds were checked against the frozen source, not merely an unfrozen current implementation.

## Initial findings, both resolved on retest

1. **Matrix colors disagree at exact bin boundaries.** `R/lib/barometar_page.R:67` serializes payload numbers with `digits=12`; `assets/js/barometar.js:40–43` recomputes rates from counts and uses strict `>` against those rounded bins. The static table in `pages/demokrscanstvo/index.qmd:150` compares CSV rates against full summary precision. Example: December 2025, wide, `unclassified`, displays 322.6 in both versions; static code chooses bin 1, enhanced code bin 3. Across finite theme cells, the two algorithms disagree for 49 monthly-wide, 23 monthly-narrow, 71 weekly-wide and 41 weekly-narrow cells. This changes encoded intensity while leaving printed numbers unchanged. Use the same tolerance-aware boundary rule in R and JavaScript, then regenerate and compare actual static cell colors with enhanced bins.

2. **Weekly downloadable figures do not identify the rolling line.** The eight plotted datasets have correct point values, but the four weekly PNG/SVG exports contain a trailing-28-day line whose meaning is not named in their visible caption. `R/lib/barometar_figures.R:17–24` adds the line; the caption at line 35 explains only the seam, partial marks and missingness. The interactive chart does explicitly label it at `assets/js/barometar.js:110`. Add “Zadnjih 28 dana” to the static weekly figure annotation/caption so the weekly bars cannot be confused with the headline's 28-day rate.

## Qualifications for the handoff

- The literal original brief's opening-week checklist expects “partial” for 2020-W53. Actual CSVs retain the full ISO interval 2020-12-28 through 2021-01-03 and return unavailable because 3/7 observed days is below 0.5, consistent with the frozen status function at `R/lib/barometar_metrics.R:40–41`. They do not fabricate a zero. W37 is partial. September 2026 is unavailable at 10/30 observed days. Record this precise frozen behavior rather than ticking the original “2020-W53 partial” wording without qualification.
- No independent reconstruction from daily facts, source rows, deduplication keys or private outlet sets was attempted. This review checks exported arithmetic and agreement, not empirical counts, classifier accuracy, recall, κ, bridge results, or provenance of the source cutoff.
- The event date printed in the method PDF is source-authored conference metadata, not an empirically measured quantity; this review did not externally verify the conference schedule.
- No live-site or publication claim is made. A method-only PDF can pass this narrow numeric review while G3 and the empirical release remain incomplete.

Initial reviewed hashes:

```text
docs/pages/demokrscanstvo/index.html
aac28c322d40ac2a90dbe1b3800cb516271f5fc74ccc14c552c26ef58e5a39e0
docs/data/barometar/demokrscanstvo/summary.json
24fdc04b4258ebd44c2afd132599a211b468c891ca983219293476fe5b1da589
studies/demokrscanstvo-barometar/output/conference/demokrscanstvo-metoda-2026-09-18.pdf
9516519ea369bb117703fae53fb94e7aca2f8cc316682e62fc1ec05fcae1d5e0
```

## Final independent retest after regeneration

Both initial findings are **RESOLVED** in the regenerated artifacts. The method-only PDF is byte-identical to the initial reviewed copy, so its previous PASS remains applicable. No empirical or human-validation status changed.

1. The current R and JavaScript helpers implement the same tolerance-aware boundary rule (`value > cutoff + 1e-10`), and embedded numeric serialization uses 16 decimal digits. Executed the actual JavaScript helper on all 4,900 finite thematic cells across the four frequency/scope modes: no mismatch between full-summary cutoffs and embedded-payload cutoffs. Independently parsed the regenerated static HTML table and compared all 84 actual cell background colors with the enhanced-selection calculation: **zero mismatches**. The served `docs/assets/js/barometar-core.js` is identical to its source. The 16 mode-specific cutoff checks also pass.

2. All four weekly SVGs now contain the explicit caption “Stupci: zasebni tjedni. Puna crta: zadnjih 28 dana.” Opened all four weekly PNGs and verified the added caption. Their 73-pixel caption bands are byte-identical, confirming the same visible wording across both metrics and scopes. All 39 manifest file hashes still match the actual regenerated downloads.

3. Added durable tests for the specific observed serialization regression and for genuine changes that must cross a bin boundary:
   - `tests/barometar_core.test.cjs`: CSV-decimal values, 12-digit cutoff serialization, full JSON round trips, duplicate cutoffs, and values 0.000001 beyond a cutoff. `node --test tests/barometar_core.test.cjs`: **6/6 PASS**.
   - `tests/barometar_page_display_tests.R`: the same independently stated expected categories through actual `jsonlite` 12- and 16-digit round trips. `Rscript tests/barometar_page_display_tests.R`: **PASS** on installed R 4.6.0. R reported existing locale/renv startup warnings but exited 0. A prior stdin attempt failed on a PowerShell BOM before executing any assertions; the saved UTF-8 test-file run is the recorded successful verification.

The actual embedded UTF-8 payload is 181,901 bytes, below the 200,000-byte limit. These tests concern presentation of invented data; they do not alter the frozen scientific definition or validate real article classifications.

Final reviewed hashes:

```text
docs/pages/demokrscanstvo/index.html
81e50d136b884bf7dadb88097a0591aef95f3b242344ad52489e1c07482cc50b
docs/data/barometar/demokrscanstvo/summary.json
9535fe7d55e7f371a4836d1748ac4455dcdd96d0b10d2d28d2a13b883a51bb36
docs/data/barometar/demokrscanstvo/manifest.json
d9d797377a451b08640d84d365c42f235786e96ce76e50d1ee697bf53e19d03b
studies/demokrscanstvo-barometar/output/conference/demokrscanstvo-metoda-2026-09-18.pdf
9516519ea369bb117703fae53fb94e7aca2f8cc316682e62fc1ec05fcae1d5e0
```
