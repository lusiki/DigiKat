# Barometer synthetic preview browser review

Date: 2026-09-18. Latest final-preview audit completed at 19:43:25 UTC using Chrome
153.0.8010.50. Scope-default regression completed at 19:28:38 UTC.
Regenerated export contrast and final resource weight were verified at 19:49 UTC.
Independent review; no implementation files were edited.

Verdict: **Page interaction, accessibility, downloads, export-caption contrast and
page-weight PASS.** No open failures remain within this bounded review.
This is a bounded review of synthetic content, not approval to publish synthetic
results or a complete empirical edition.

## Scope and evidence

The reviewed artifact was `docs/pages/demokrscanstvo/index.html`, served from a
temporary localhost HTTP server. Chrome used an isolated headless profile and an
automatically allocated debugging port. Each run closed its server and browser.

- Eight interactive cases at 390 x 844 and 1440 x 900, monthly/weekly and both scopes.
- Four interactive spot checks at 320 and 375 px, monthly/broad and weekly/narrow.
- Four JavaScript-disabled cases, monthly/broad at 320, 375, 390 and 1440 px.
- Native keyboard input tested frequency/scope radios, range selection, custom
  start, latest-period reset, chart Home/Right/End/Escape, and matrix
  Right/Down/End/Home/Enter/Space plus previous-page/reset behavior.
- axe WCAG 2 A/AA, 2.1 A/AA and 2.2 AA rules ran on all 16 cases.
- Reduced motion, browser errors, failed requests, SVG text overlap, sticky row
  headers, all downloadable artifacts and page-resource weight were checked.
- Matrix focus geometry was checked in every interactive case.
- Four further cases at 390 px simulated `default_scope=uze` while preserving both
  available scopes, testing explicit monthly/weekly and broad/narrow URLs.
- Every local link and HTML fragment was checked for an existing target.

The audit script, JSON and screenshots are ignored private artifacts at
`studies/demokrscanstvo-barometar/output/private/browser-review/`.
`review.mjs` produced the current `report.json` and 48 screenshots.
`scope-review.mjs` produced `scope/report.json` and twelve regression screenshots.
`focus-review.mjs` retains focused keyboard screenshots from the earlier correction
check. `local-links.json` records the final local-link check.
`export-review.json` and `png-caption-review.json` record the final caption and
resource-weight verification after the figures were regenerated.

## Passing checks

- All 16 cases and all four scope regressions have **zero axe violations**.
- The latest sixteen cases each have exactly one H1. The visible development
  status is `Radni prikaz`.
- No page-level horizontal overflow, browser exceptions, console errors, HTTP
  errors or failed network requests occurred.
- Interactive chart text has no measured overlaps at any tested width.
- Native keyboard interaction changes the frequency and scope, updates the
  overview data attributes and URL, and announces the current state.
- Range selection, custom start and latest-period reset work. Chart
  Home/Right/End update the readout and both crosshairs; Escape clears them.
- Reduced-motion mode has zero animations and document scroll behavior `auto`.
- The matrix has seven rows and twelve period columns, grid semantics and one
  tab stop. Arrow keys, Home/End and Enter/Space update the active cell/detail.
- Previous-page navigation changes the displayed period window; the latest-period
  button restores the newest window. Monthly reset returns 2025-10 through
  2026-09; weekly reset returns 2026-W26 through 2026-W37.
- Sticky row headers remain at x=16 after horizontal scrolling. Missing values
  use an em dash, hatching and accessible descriptions. Ramp text passes contrast.
- The synthetic warning is visible in every case.

The final cases confirm the active matrix cell remains visible beside the sticky
row header after End then Home; changing mode resets stale selection detail; and
the denominator uses the correct `0 od 31 članka` form. At 320 px the complete
focused cell starts at x=176, immediately after the sticky header, and center
hit-testing returns that `TD`. No tested active cell was obscured.

The metadata regression changed only the synthetic payload in the temporary HTTP
response, leaving implementation and rendered files untouched. With its default
set to `uze`, explicit `obuhvat=siri` still opens broad scope for both frequencies;
explicit `uze` opens narrow scope. Native radio keys switch successfully in both
directions. No console, network, accessibility or overflow failure occurred.

## Weight and downloads

Direct local-resource weight is **1,313,610 / 1,500,000 bytes**; embedded payload is
**181,901 / 200,000 bytes**. HTML is 249,252 bytes. All pass the standard budgets.
The resource calculation
includes both mobile and desktop fallback SVGs even when CSS hides a counterpart.

All **53 download links, covering 41 distinct files**, returned HTTP 200 and
nonempty bodies. These include the per-mode CSV/SVG/PNG downloads, full indicator
and supporting tables, definitions, manifest, archived edition, social card and
README. The complete file list names each artifact's type and size. With
JavaScript, the quick download selection shows only the chosen mode's three
links. Without JavaScript, all twelve explicitly named quick links are available.
The complete download list remains available in both cases. Downloaded artifacts
are not initial page resources and are not included in the page-weight total.

All **68 distinct local links and fragments** have existing targets. The one
external link was recorded but not fetched by the localhost-only review.

All eight regenerated SVGs now use `#51575D` on `#F5F4F0` for caption text,
giving **6.65:1 contrast**. Pixel inspection confirms the same caption color in
all eight PNGs, and visual inspection confirms the weekly caption is legible and
unclipped. The corrected weekly wording distinguishes individual weeks from the
28-day line. The four weekly PNGs are 1440 by 548 px with approximately 144 dpi
metadata. Final resource accounting after regeneration remains within budget.

## No-JavaScript and visual inspection

At 320, 375 and 390 px, desktop plot wrappers compute to `display: none` and
mobile wrappers to `display: block`; at 1440 px these states reverse. One image
per chart is visibly presented, both variants load and alternative text is
present. The dedicated mobile plots remain intact at 320 px.

No-JS cards agree with interactive monthly/broad defaults, including the corrected
`12 od 372 članka` denominator. The 69-row static data
table and seven-by-twelve static theme matrix remain available, while interactive
controls are hidden. The static matrix has status/color classes and remains
inside its horizontal scroll container. Desktop/mobile matrix screenshots show
legible labels and working sticky row headers.

## Scope limits

This review does not replace complete release-schema checks, human validation,
PDF review, or the editorial manual release matrix. No publication occurred.

## Repeatable browser gate

The repository browser gate now includes the barometer only when its rendered
HTML exists. This preserves the normal pre-G4 build exclusion. The original page
list, viewport list, accessibility severity threshold and other checks remain.

The new `barometarExpression` verifies native keyboard selection of weekly/narrow,
overview data attributes, URL parameters, live-region text, twelve matrix columns,
unavailable cells displaying an em dash, and absence of a segment spanning
2024-04-01 in either indicator's rendered SVG or core segment data. It selects an
unavailable historical period explicitly so that the cell check is non-vacuous.

Verification passed: JavaScript parser; all five core tests, including an exact
boundary test for both indicators; all 391 Run 6 source-quality checks; and
`npm run check:browser` across **21 pages at 320, 375, 390, 768, 1024, 1366, 1440
and 2048 px**. This integration changed only tests and this review report.

After the final page-specific source and payload changes, the same barometer
gate entry was rerun at all eight standard widths and passed. The 16-case
independent page audit, all downloads and local links were also refreshed; the
unaffected twenty site pages were not redundantly rerun.
