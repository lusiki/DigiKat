# Plan — site improvement Run 4

**Date:** 2026-08-24

**Scope:** The five analytical map pages and their shared chart-production contract, completed as the internal 4A and 4B sequence defined in `SITE_IMPROVEMENT_PLAN.md`.

**Publishing surface:** `pages/mapa/mapa.qmd`, `pages/mapa/evolucija.qmd`, `pages/mapa/mapa_stats.qmd`, `pages/mapa/diskurs.qmd`, `pages/mapa/događaji.qmd`, shared R chart helpers/theme, aggregate-only download assets, focused regression checks, and the corresponding page-by-page renders under `docs/`.

## Goal and rationale

Turn the map pages into five readable analytical arguments. Each retained figure must answer a stated question, support a distinct conclusion, and provide the same scholarly evidence layers without exposing restricted row-level material. The visual system should use one colour-blind-safe palette, visible non-colour cues, stable asset names, and practical responsive dimensions.

## Implementation

1. Add a shared R helper for figure captions, accessible summaries, responsive table/download blocks, safe CSV export, vector output defaults, and consistent collection-break annotations.
2. Standardize the platform and analytical palettes in `R/theme_digikat.R`; retain stable platform meaning across pages and add line/shape cues wherever colour otherwise carries the distinction alone.
3. Apply the shared page opening and freshness/status strip to all five analytical pages. Keep one visible H1 supplied by Quarto, a short scope statement, up to three findings, a bounded conclusion/caution, and a direct next step.
4. For every retained substantive figure, add an explicit analytical question and takeaway before the figure, a concise title, proper caption, meaningful alternative summary, accessible aggregate table, safe CSV download, and SVG download when the geometry is vector-friendly.
5. Annotate the known collection interruption or incomplete terminal period wherever it affects time interpretation. Move implementation detail behind links to the canonical methodology anchors.
6. Remove or combine only figures that do not carry a distinct claim; otherwise preserve empirical results and compute all new statements from existing tracked aggregates.
7. Keep tables inside keyboard-focusable responsive wrappers, lazy-load below-the-fold rendered images, and cap figure dimensions near their real display requirement.
8. Add regression checks for the chart contract, one-H1 structure, stable expected download files, aggregate-only disclosure, palette use, and absence of oversized chart settings.
9. Render the five pages individually from the repository root, verify the resulting HTML and assets, run repository/source/disclosure/link/browser checks that do not require a full-site overwrite, and inspect representative narrow and desktop widths if browser control is available.

## Boundaries and rejected alternatives

- Do not change the official corpus, tracked analytical aggregates, NLP page-ready data, research results, inclusion rule, dictionaries, or disclosure policy.
- Do not export row-level text, URLs, or source identifiers beyond already public aggregate labels.
- Do not hand-edit generated files under `docs/`; page renders produce those files.
- Do not run `R/03_aggregate.R --apply`, a full `quarto render`, publish, push, bulk-stage, or touch unrelated `explorations/` work.
- Do not add a JavaScript chart framework or a parallel visual language. The current Quarto/R stack remains authoritative.
- Do not satisfy accessibility with alt text alone. Each chart also needs a visible tabular evidence layer and downloadable aggregate data.

## Verification gate

- Focused Run 4 regression checks pass.
- `Rscript tests/run_tests.R`, `R/check_sources.R`, `R/check_disclosure.R`, and `R/00_setup.R` complete with no new failures.
- All five `quarto render pages/mapa/<page>.qmd` commands pass from the repository root without changing `data/**` or creating source-adjacent render scatter.
- Every retained substantive chart meets the shared chart contract, and every map page has exactly one H1 in rendered HTML.
- Download files contain aggregates only and pass the disclosure check.
- Rendered map pages have no browser-console errors and remain contained at 320, 375, 390, 768, and 1024 px.
- `git diff --check` passes, unrelated worktree changes remain untouched, and the completion record is appended to the site improvement plan.

## Completion record

Run 4 is complete. The five analytical map pages now share one chart contract: a stated
question and takeaway, a semantic caption and alternative summary, a keyboard-accessible
aggregate table, safe CSV and SVG downloads, responsive dimensions, lazy loading, and
explicit treatment of collection breaks. Twenty-three public aggregate datasets are built
deterministically from tracked project data and disclosure-checked before export.

The focused source and rendered-page contract checks, unit tests, setup validation, and local
link checks pass. The repository-wide source and disclosure checks reproduce only their known
pre-existing findings (four source-encoding hits and one restricted study diagnostic). All five
pages were rendered individually; a full-site render was not run because it requires separate
authorization. Browser control was unavailable in this session, so viewport and console review
could not be performed; rendered-DOM checks and deterministic responsive-CSS assertions were
used instead. The commit containing this record is the Run 4 completion commit.
