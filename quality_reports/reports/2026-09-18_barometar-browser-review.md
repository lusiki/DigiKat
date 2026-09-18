# Barometer synthetic preview browser review

Date: 2026-09-18. Final 16-case audit completed at 20:29:00 UTC using Chrome
153.0.8010.50. Expanded methods review completed at 20:24 UTC; final direct-print,
resource and local-link checks completed at 20:29 UTC.

Verdict: **PASS for the bounded synthetic page interaction, accessibility,
numeric display, downloads, initial-resource budget and direct browser print
checks described below.** No implementation defect remains open in this review.
A Chrome PDF limitation after artificial print-media emulation is documented below.
This review does not establish completion of the entire brief, human validation,
licensing, an empirical edition, or permission to publish synthetic results.

## Scope and evidence

The artifact was `docs/pages/demokrscanstvo/index.html`, served from temporary
localhost servers. Each browser used an isolated headless profile. No live page,
native coding form or private article text was accessed. No publication occurred.
Reviewer changes were limited to the previously authorized repository tests,
private audit scripts and this source-free report; the implementation author
applied fixes independently.

- Eight interactive cases at 390 x 844 and 1440 x 900: both frequencies and scopes.
- Four interactive spot checks at 320 and 375 px: monthly/broad and weekly/narrow.
- Four JavaScript-disabled cases at 320, 375, 390 and 1440 px: monthly/broad default.
- Native keyboard input for frequency/scope, range, custom start, latest reset,
  chart Home/Right/End/Escape, and matrix arrows/Home/End/Enter/Space and paging.
- axe WCAG 2 A/AA, 2.1 A/AA and 2.2 AA checks in all 16 cases.
- Nine additional cases for new A2, composition, methods and Dataset content:
  all four modes at 390 and 1440 px, plus a 390 px no-JS default.
- Direct A4 print after native chart/matrix keyboard input: monthly/broad and
  weekly/narrow, with JavaScript active and the final source CSS.
- Four earlier metadata-only regressions with `default_scope=uze`, preserving
  both scopes and explicitly requesting broad/narrow URLs in both frequencies.
- All downloads, local links/fragments, SVG caption contrast and resource weight.

Ignored evidence is under
`studies/demokrscanstvo-barometar/output/private/browser-review/`:
`report.json` and 48 screenshots; `expanded/nine-case-report.json`, expanded
screenshots and `numeric-review.json`; `scope/report.json`; `local-links.json`;
`export-review.json`; and `print-isolation/final-*-keyboard-report.json`, PDFs,
page PNGs and `pdf-text.json`. Diagnostic print-isolation artifacts are retained
separately from the two final direct-print artifacts.

## Interaction and accessibility

All 16 final cases and all nine expanded cases have **zero axe violations**.
The four scope-default regression cases also passed. Each final page has one H1
and a visible synthetic warning with status `Radni prikaz`.

There are no page-level horizontal overflows, browser exceptions, console
errors, failed requests or measured SVG text overlaps. Native keyboard selection
updates the overview data attributes, URL and live region. Range/custom-start
controls and latest reset work. Chart keys update the readout and both crosshairs;
Escape clears them. Reduced-motion mode reports no animations and `auto` scroll.

The matrix has seven rows, twelve period columns, grid semantics and one tab stop.
Keyboard navigation updates focus and details. Paging changes the displayed
window; latest reset restores 2025-10 through 2026-09 for monthly or 2026-W26
through 2026-W37 for weekly. Sticky row headers remain fixed during horizontal
scroll. Focused cells remain visible beside the sticky header, including at
320 px. Unavailable values have an em dash, hatch and accessible description;
partial values have a dashed edge. Selection details reset on mode changes.

Changing only synthetic metadata to `default_scope=uze` does not override an
explicit `obuhvat=siri`. Both scopes remain accessible in both frequencies and
native radio-key changes work in both directions.

## Expanded content and independent numeric checks

All six methods details open with native Space input, including without JS.
All six navigation anchors exist; related studies precede methods and show their
population labels. The continuity link resolves to the actual methodology heading
`../metodologija.html#method-barometar-kontinuitet`; local period details use
`#dkb-periods`. Mobile tables scroll inside their containers without widening the
page. Visible body links now have an underline.

A2 chart lines, note and two table columns appear only in narrow scope. Every
displayed A2 count/rate agrees with the corresponding payload period in all four
modes, and enabling A2 leaves the headline indicator unchanged. The weekly
partial A2 point is visible. The readout uses the correct singular/plural forms.
Monthly breadth change is visible; weekly hides it. Composition updates with
frequency/scope, and weekly wording explicitly separates the individual week
from the cards' trailing 28-day window.

The expanded independent comparison ran **46 checks with zero failures**:
dictionary family/entry totals against definitions; all 72 panel denominator
cells against exported outlet-year rows; monthly A2/A? diagnostic counts against
`diagnostics.csv`; the explicit pending-human-validation state; release history
against `releases.csv`; and the dated edition's SHA-256 against the summary.
No precision or kappa is fabricated while human validation is incomplete.

Dataset JSON-LD includes the synthetic description/version, canonical identifier
and URL, Croatian language, modification date, temporal coverage, creator, both
measured variables with units, and seventeen CSV distributions. This is a check
of the current preview metadata, not release licensing approval.

## Weight, downloads and no-JavaScript fallback

Direct local-resource weight is **1,337,926 / 1,500,000 bytes**. Embedded payload
is **182,665 / 200,000 bytes**; HTML is 269,716 bytes. Both mobile and desktop
fallback SVGs are included in resource accounting even when one is hidden.

All **53 download links, covering 41 distinct files**, return HTTP 200 with
nonempty bodies. Per-mode CSV/SVG/PNG selection, full indicator/supporting tables,
definitions, manifest, archived edition, social card and README are present.
The complete list gives file type and size. JS exposes three selected-mode quick
links; no-JS exposes all twelve named quick links. Download bodies are excluded
from initial-resource weight. All **73 distinct local links and fragments**
resolve; the one external link was recorded without fetching it.

At 320, 375 and 390 px, mobile plot wrappers are shown and desktop counterparts
hidden; at 1440 px the states reverse. Each chart shows one fallback image, both
variants load and have alternative text. No-JS cards match monthly/broad defaults,
including the `12 od 372 članka` denominator. The 69-row static table and
seven-by-twelve static matrix remain available; interactive controls are hidden.

All eight SVG export captions use `#51575D` on `#F5F4F0`, a **6.65:1 contrast
ratio**. Earlier pixel and visual checks of the same exports confirmed the PNG
caption color and unclipped weekly wording. Weekly captions distinguish separate
weeks from the 28-day line; the weekly PNGs are 1440 x 548 px at approximately
144 dpi.

## Browser print

The final source produces monthly/broad and weekly/narrow A4 PDFs with active
JavaScript after ordinary keyboard interaction, in 0.85 and 0.68 seconds
respectively. The 10-page and 14-page outputs include the full opened data and
methods bodies. These are diagnostic prints of the web page, not the brief's
separate one- or two-page conference PDF.

MuPDF rasterization and visual inspection confirm a white hero, readable ink
text, hidden controls/sub-navigation, the frequency/scope state line, intact
indicator cards, chart axes and unavailable bands, all twelve matrix columns,
matrix colors/status markers and legends, panel/dictionary/diagnostic/history
tables, and the disclosure. No clipped matrix columns or table content were
observed. All final PDF pages were rasterized; charts, matrix, panel and final
methods pages were inspected at reading resolution.

Three defects discovered during review were corrected: inline SVG hatch fills
could hang Chrome's PDF renderer, closed details bodies were omitted, and an
indicator card could split after its heading. Final print CSS uses a solid grey
unavailable band, makes `details::details-content` visible and keeps cards intact.
On-screen chart hatching remains present.

Chrome 153 still times out in the diagnostic sequence that explicitly emulates
print media, returns to screen media, and then requests PDF. Direct print of the
final source succeeds, including after native keyboard interaction. That artificial
emulation sequence is not reported as supported. The details pseudo-element and
print behavior were verified in this Chrome version; other engines were not tested.

## Repeatable browser gate and limits

The repository gate conditionally includes the barometer when its rendered HTML
exists, preserving normal pre-G4 exclusion and every original page/viewport gate.
Its `barometarExpression` checks native weekly/narrow selection, overview data
attributes, URL/live region, twelve matrix columns, an explicitly selected
unavailable period's em dash, and no SVG/core segment spanning 2024-04-01 in either
indicator.

Earlier integration validation passed the JS parser, all five core tests, all
391 Run 6 source-quality checks and the original full browser gate across 21
pages. The final barometer entry was rerun successfully at 320, 375, 390, 768,
1024, 1366, 1440 and 2048 px. Unchanged site pages were not redundantly rerun.

This bounded review does not replace full public-schema/disclosure checks,
human coding/validation, licensing, release approval, empirical findings review,
or the conference PDF's separate edition-matching and visual review.
