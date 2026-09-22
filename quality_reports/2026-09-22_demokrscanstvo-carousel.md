# Christian-democracy carousel publication review

Date: 2026-09-22. Scope: replace the previous findings presentation with the
author-approved 18-slide Croatian carousel and publish it on the existing page.

## Artifact and evidence

- Exact requested title and `Doc. dr. sc. Luka Šikić` byline retained.
- 18 slides: project introduction, corpus and study scope, ten selected findings,
  guided exploration and further reading. Project teal, ivory, copper and serif
  typography; selectable text and native charts.
- Official DigiKat corpus: 413,985 records across 9 platforms. The separate
  barometer archive contains 41,397,670 searchable records across 14 platforms;
  its selected discussion has 2,306 publications and 2,253 distinct texts.
- Slide 3 and the publication page explicitly explain that the findings include
  Catholic and general media. No Catholic-publisher-only estimate is implied.
- Final PDF: 18 pages, 199,027 bytes, 31 links, embedded Georgia/Calibri fonts,
  tagged document structure. PDF/UA conformance is not claimed.
- PDF SHA-256: `65a9b43503559af1e6d0158abf1f0dfaffb30c44c5990f0248336886b89751d2`.
- All 18 rendered PDF pages were inspected individually. Final mobile and desktop
  publication previews were also inspected. No text overflow or missing glyphs.

## Verification

Passed:

- Carousel source hashes, numeric claims, title/byline, embedded fonts, PDF links,
  metadata and publication hashes (`carousel/verify.py`).
- Carousel desktop geometry, reading/presentation keyboard navigation, responsive
  widths 320/390/768/1024 and axe WCAG A/AA checks.
- R regression suite (`tests/run_tests.R`) and disclosure check (342 artifacts).
- JavaScript all-platform and thematic tests.
- Empirical and thematic release verifiers against the rendered page.
- Full Quarto render of 116 pages, followed by the final changed-page render.
- Internal-link crawl: 140 HTML files, no missing targets, anchors or mojibake.
- Site metadata, structure and performance budgets: 127 active HTML pages. The
  updated page is 1,453 KiB against a 1,465 KiB budget.
- Changed-page browser check at 320/375/390/768/1024/1366/1440/2048 pixels, including
  accessibility, native keyboard controls, all 14 platform series, missing-month
  gaps, thematic filters and the JavaScript-disabled fallback.
- Non-destructive sample pipeline stages 2 onward using the existing fixture.
- The 21 recorded production input hashes are unchanged. No data or analytical
  model code changed, and no dependencies were added to the project lockfiles.

The browser check previously referenced controls and a table removed in the
earlier chart simplification. It now verifies the existing platform-only chart,
its per-100,000 unit, rates/tooltips, missing-month gaps and partial-month markers
against the public monthly data for every platform. The UI itself is unchanged.

## Existing limitations

The full `R/00_run_all.R --sample` command stops at its source-quality guard,
which flags intentional U+FFFD replacement-character fixtures in six existing
R files. Those files were checked against HEAD and are unchanged. Subsequent
sample stages pass when started with `--from=2`; this is not recorded as a pass
of the complete command.

The main-branch validation run before this work already failed while installing
the pinned Windows DuckDB package (missing package `DESCRIPTION` during ZIP
extraction): [baseline run 35586174456](https://github.com/lusiki/DigiKat/actions/runs/35586174456).
Pages deployment for that same commit succeeded. This publication does not alter
or disable the dependency installer or validation workflow.

On this Windows machine, render/test processes used
`LC_ALL=English_United States.utf8` and `LANG=English_United States.utf8` because
the inherited Linux locale prevented R from reading Croatian source text.

## Publication scope

The new PDF, HTML, optimized WebP preview and checksummed metadata replace the
four named old presentation assets in both source and generated output. The old
authoring directory remains with a retirement notice. Frozen published studies
were preserved after the full render; unrelated generated changes were restored
from their pre-task revision. Existing user changes and untracked research are
excluded from staging. Only the affected page and sitemap entry are published.
