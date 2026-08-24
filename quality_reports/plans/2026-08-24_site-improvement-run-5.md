# Plan — site improvement Run 5

**Date:** 2026-08-24

**Scope:** The Croatian annual report for 2025, the bespoke **Kako se govori o Crkvi?** report, and the smallest shared report identity needed to connect both publications to the standard DigiKat site.

**Publishing surface:** `studies/annual-report/REPORT_TEMPLATE.qmd`, its report renderer and typeset CSS, the publishable annual-report HTML/PDF artifacts, `assets/izvjestaji/kako-se-govori-o-crkvi/`, shared report assets/includes where useful, focused regression checks, and the Run 5 completion record.

## Goal and rationale

Bring the two long-form publication systems into the same scholarly DigiKat family without flattening their distinct editorial rhythms. Both reports should provide immediate orientation, visible publication status and citation information, strong section navigation, restrained progress feedback, accessible and responsive figures, complete metadata, and reliable print or PDF output.

## Implementation

1. Audit the annual-report template, renderer, generated HTML, PDF, and report CSS for heading structure, embedded base64 images, section navigation, metadata, citation agreement, print behaviour, and responsive image handling.
2. Add a reusable report metadata and identity layer where it prevents drift across publication formats. Keep DigiKat typography, palette, masthead, footer, status strip, citation treatment, focus states, and accessibility behaviour recognizable without imposing one identical page template.
3. Revise the annual-report source and render path so the web edition has exactly one H1, a compact 60-second summary, sticky or otherwise persistent section orientation, a restrained reading-progress indicator, external optimized images with responsive variants and lazy loading below the fold, full publication metadata, and citation links that agree with the PDF edition.
4. Revise the bespoke report shell and styles to use the same minimum identity, metadata, status, citation, focus, progress, and print contracts while preserving its current editorial pacing and interactive analysis.
5. Apply the shared chart evidence contract where the reports expose substantive figures. Preserve public aggregate disclosure rules and avoid creating row-level downloads.
6. Add focused checks for one-H1 structure, external report assets, metadata and structured data, section navigation, progress/reduced-motion/print behaviour, responsive images, citation targets, and publication links.
7. Rebuild only the affected report artifacts with their documented scripts. Render or verify the corresponding standard Quarto entry surface page by page. Do not run a full-site render.
8. Inspect representative narrow and desktop widths when browser control is available, validate the annual-report PDF visually, run focused and existing report checks, and append the Run 5 completion record.

## Boundaries and rejected alternatives

- Do not change the official corpus, annual-report indicators, analytical aggregates, findings, inclusion rule, dictionaries, or disclosure policy.
- Do not touch unrelated work under `explorations/` or the pre-existing generated library changes in `docs/site_libs/`.
- Do not hand-edit `docs/` as source. Page-specific Quarto renders may update it.
- Do not run `R/03_aggregate.R --apply`, a full `quarto render`, publish, push, bulk-stage, or commit without a separate user request.
- Do not make the bespoke report a clone of the standard Quarto shell or the annual report. Shared identity is deliberately limited to scholarly furniture and behaviour.
- Do not optimize the web edition by degrading PDF typography, pagination, citations, or print output.
- Do not introduce promotional, product, service, or magazine-style language.

## Verification gate

- Annual-report generation and `05_report_checks.R` pass for the 2025 Croatian edition, and both HTML and PDF outputs are produced.
- The annual-report HTML contains one H1, no embedded base64 images, valid section orientation, external responsive/lazy figure assets, complete metadata and structured data, and a citation target matching the PDF link.
- The bespoke report contains one H1, complete metadata and structured data, visible status and citation information, keyboard-visible focus, restrained progress feedback, print/reduced-motion handling, and no page-level horizontal overflow at supported widths.
- The annual-report PDF renders cleanly and representative pages retain stable typography, figures, headings, and citations.
- Focused Run 5 checks, repository tests relevant to the affected surfaces, local link checks, and `git diff --check` pass with no new findings.
- Generated output appears only in expected publication or `docs/` locations, and unrelated worktree changes remain untouched.

## Completion record

Run 5 is complete. The annual report now publishes two external-asset HTML editions with one H1,
sticky section orientation, a 60-second summary, publication status, a citation block, canonical and
social metadata, `ScholarlyArticle` structured data, shared reading progress, and nine responsive
lazy-loaded figures per language. The Typst path remains independent of the web image attributes;
both 24-page A4 PDFs were rendered and visually inspected after that separation prevented web pixel
dimensions from affecting print layout.

The bespoke **Kako se govori o Crkvi?** report retains its editorial pacing and interactive SVG
figures while adding an explicit stable-edition status, a generated 60-second orientation, favicon,
and the same restrained progress component and print/reduced-motion behaviour. The verified source
packages were synchronized to `docs/` without a full-site render.

Focused Run 5 checks pass 21/21, annual-report mechanical checks pass 120/120, repository regression
tests pass 66/66, setup validation passes, and the site link check passes across 135 HTML files. The
Croatian and English PDFs render as 24 A4 pages with no clipping or overlap in the complete contact
sheet and representative high-resolution page review. The in-app browser had no available backend,
so no live console or viewport interaction pass could be completed; deterministic heading, asset,
metadata, responsive-CSS, focus, reduced-motion, print and link checks were used instead.

Repository-wide source and disclosure checks reproduce only their known pre-existing findings: four
source-encoding diagnostics and one restricted moral-economy output diagnostic. The machine also
continues to report its pre-existing `renv` out-of-sync and leftover-library-directory warning. A
full-site render was not run because it requires separate authorization. The scoped change set is
ready for review; no commit was created because committing requires a separate user request.
