# All-platform empirical barometer execution

Status: completed provisional empirical release; publication authorized on 2026-09-19. All 69 classification chunks and the single-page Quarto render pass. Publication uses the existing GitHub Pages source (`main`, `/docs`). The publication pass also renders the homepage navigation and checks the aggregate release before committing and pushing.

## Authorized scope

The PI approved searching the supplied merged DuckDB across all platforms and sources, followed by implementing actual results on the barometer page. The approved [plan](plans/2026-09-19_barometar-all-platforms.md) records the expansion beyond the 115-outlet web panel. Additional vendor sourcing, archive confirmation, human exports and licence paperwork are not prerequisites for this provisional edition. Neither completed human validation nor verified vendor licence evidence is claimed.

The PI subsequently explicitly authorized committing and pushing the resource to the live page. The public destination is [the media barometer](https://lusiki.github.io/DigiKat/pages/demokrscanstvo/index.html).

## Extracted population

- Source table: `main.media_data_all` in the supplied merged archive, attached read-only.
- Source size: 91,362,439,168 bytes. Source modification timestamp is unchanged after extraction.
- Raw records: 41,748,837.
- Repeated capture identities removed: 351,165.
- Distinct capture identities: 41,397,672.
- Text-eligible records: 41,397,670. Two records have no searchable letter/digit content.
- Broad retrieval candidates: 5,275,313. These are not the final included count.
- Platforms: 14. Period: 2021-01-01 through 2026-09-10, represented by 69 monthly extraction chunks.
- Extraction signature: `a58df9795d3363518162`.
- Frozen base definition: `1.0.0+33429974d0b8`.

## Final empirical result

The contextual rules include **2,306 records**, of which **2,211** explicitly name Christian democracy as an idea or tradition (A1). The additional 95 qualify through B/C without A1. These are automated rule-based results, not human-confirmed counts or a population prevalence estimate. Retrieval candidates must not be confused with these included records.

| Platform | Included records |
|---|---:|
| Web | 1,811 |
| Twitter / X | 137 |
| Facebook | 108 |
| Print | 72 |
| Comments | 56 |
| Television | 28 |
| Radio | 27 |
| Reddit | 26 |
| Forums | 20 |
| YouTube | 11 |
| Instagram | 8 |
| TikTok | 2 |
| Bluesky | 0 |
| Threads | 0 |

Zeros indicate no qualifying match in the available archived text under this definition, not an absence of discussion outside it. Platform coverage and text availability differ. The public monthly table has 966 rows (69 months × 14 platforms).

Local page: [rendered barometer](../docs/pages/demokrscanstvo/index.html).
Aggregate release: [summary](../data/barometar/demokrscanstvo-multiplatform/v1/summary.json),
[monthly data](../data/barometar/demokrscanstvo-multiplatform/v1/monthly.csv),
[manifest](../data/barometar/demokrscanstvo-multiplatform/v1/manifest.json).

Private candidate text, capture keys, source labels and evidence remain under the configured external work directory. The repository receives aggregate tables and a public dictionary inventory only. The official DigiKat master and processed aggregates are outside this pipeline.

## Implementation

The all-platform adapter retains the frozen A1/B/C contextual inclusion rules, while allowing short or title/snippet-only records and searching the complete stored selected body. Web boilerplate is learned separately by source/month. Platform-specific vendor identities and conservative legacy capture identities avoid collapsing unrelated comments with a shared URL. This is an archived-record denominator, not an estimate of unique articles or people.

The page provides platform, broad/narrow scope, count/rate and text-availability controls. It shows denominators and archive-day availability, breaks the series at April 2024 and missing months, and supplies aggregate downloads. The earlier 55-item assistant review is labelled AI review of web-panel contexts, not human validation of the expanded population. The fixed-panel gates and human forms are unchanged. The former synthetic page preview command is retired to avoid replacing the new page accidentally.

## Verification

- Synthetic identity fixtures preserve separate comments sharing a URL, separate platform IDs and correct text fallbacks.
- New text-policy and necessary-condition checks pass for 24 texts, including the frozen contextual fixtures, short and title-only posts, and a match beyond 32,000 characters.
- Original frozen route-engine regression passes 22 cases plus Unicode, window, attribution and precedence checks.
- Aggregate-builder fixtures reconcile candidate and denominator counts and distinguish measured zero from missing months.
- JavaScript calculation/segmentation tests cover broad/narrow and full-body rates, leap years, missing denominators and the April 2024 collection break.
- A source-file snapshot check confirms the original database is unchanged.
- A deterministic private audit reclassified 338 candidates across all 14 platforms using the exact contextual engine, without the vector activation shortcut. There were zero disagreements (280 screen-rejected and 58 context-checked records). This verifies software consistency, not human agreement, precision or recall.
- All 5,275,313 candidate decisions reconcile and have distinct record keys. Monthly, platform and text-availability tables reconcile with the complete denominator.
- Public source and copied `docs/` releases pass manifest SHA256 checks, denominator/rate invariants and schema/privacy checks. No source text, source account names, URLs or record identifiers appear in public tables.
- Single-page Quarto rendering succeeded. The rendered payload reconciles to the CSVs, all local resource links resolve, and three new SVG figures were generated. The page has no synthetic-data banner or render-error block.
- All 15 protected `data/processed/` file hashes are unchanged after render. No page output was scattered outside `docs/` and no full-site render was run.
- The former synthetic downloads and page/figures were preserved in the external work directory under `multiplatform-v1/retired-synthetic-20260919`. They are no longer present in the website output.

The computer-use connector initially reported “No browser is available.” During the publication pass, the repository's Chrome browser test successfully exercised the homepage and the empirical barometer at 320, 375, 390, 768, 1024, 1366, 1440 and 2048 pixels. Keyboard selectors, live announcements, data-table values, missing-month display, the April 2024 series boundary, overflow, focus, reduced motion and accessibility checks pass. This is automated browser verification; no manual visual inspection is claimed.

## Publication checks

- The homepage was rendered separately from the repository root and now links to the barometer through the research menu. Protected processed data remain unchanged.
- CI now runs the new JavaScript, Python and R regressions and verifies both the committed and rendered empirical release. Its browser check recognizes the new platform controls while retaining support for the original panel page.
- Whole-site static quality checks pass for 127 active pages. Local-link checks pass for 137 HTML files. All 392 source-quality checks and the disclosure check pass.
- Only source code, aggregate data, generated page assets and the associated reports are included in the publication commit. Unrelated prototype files and an older local plan remain outside it.
- The checksum-sealed aggregate directories retain exact bytes in Git, avoiding automatic line-ending conversion. Both staged release copies were checked against every manifest SHA256 before publication.
