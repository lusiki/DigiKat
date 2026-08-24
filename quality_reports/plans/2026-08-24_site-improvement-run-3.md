# Plan — site improvement Run 3

**Date:** 2026-08-24

**Scope:** **Moj medij** as the flagship supporting tool, using the hierarchy and shared academic foundation established in Runs 1 and 2.

**Publishing surface:** `pages/moj-medij.qmd`, one quiet corpus-page cross-link, a small reusable client-side findings module, focused regression tests, shared styles only if the page cannot remain self-contained, and the corresponding single-page renders under `docs/`.

## Goal and rationale

Make **Moj medij** the project's clearest public utility without promoting it above the official corpus, maps, or research. A selected profile should first explain three supportable facts in plain Croatian, then expose the underlying charts, tables, cautions, and methods.

## Implementation

1. Replace the long opening with one explanatory sentence and place the search control immediately after it.
2. Rebuild the search as an accessible combobox with arrow-key navigation, Enter selection, Escape dismissal, active-option semantics, focus management, and announced result, empty, and error states.
3. Add deterministic, support-thresholded three-finding logic in a reusable client-side module. Use scale, within-platform attention, topic, and publication-rhythm evidence in a fixed priority order, and state honestly when fewer than three findings are supported.
4. Start every selected profile with **Tri stvari koje trebate znati**, the named comparison platform, and a **Kopirajte poveznicu** control. Preserve `?medij=` links and disambiguate duplicate names with an optional platform parameter.
5. Keep all detailed charts after the summary. Add textual or tabular alternatives to each generated SVG and an explicit focusable narrow-screen treatment for wide tables and event displays.
6. Replace the dense methodological rail with short inline cautions, expandable reference notes, and links to the canonical methodology anchors.
7. Add regression tests for deterministic findings, sparse profiles, incomplete platform data, duplicate-name link resolution helpers, and support thresholds.
8. Render only `pages/moj-medij.qmd`, run the focused JavaScript and repository checks, test direct/no-result/duplicate/sparse paths, and inspect keyboard and narrow-width behaviour in the browser.

## Boundaries and rejected alternatives

- Do not alter the official corpus, analytical results, page-ready payload, or disclosure rules unless a demonstrated interface requirement cannot be met from the current public payload.
- Do not add a server, framework, tracking dependency, or external chart library. The tool remains a static, client-side Quarto page.
- Do not change the homepage hierarchy established in Run 2 or redesign maps, reports, and source profiles assigned to later runs.
- Do not hand-edit generated files under `docs/`. The single-page Quarto render may update its normal generated target and copied assets.
- Do not run a full-site render, publish, push, stage, commit, or disturb unrelated working-tree changes.
- Do not present sparse differences as dramatic findings or compare engagement and reach across platforms.

## Verification gate

- `node --test tests/moj_medij_findings.test.cjs` passes.
- `Rscript tests/run_tests.R`, source and disclosure checks relevant to the page, and `quarto render pages/moj-medij.qmd` pass from the repository root.
- The rendered profile begins with three supportable findings or an explicit fewer-findings statement and names the platform for every comparison.
- Existing `?medij=` links still resolve. Duplicate-name links can select the intended platform profile.
- Search works with Arrow Up, Arrow Down, Enter, and Escape, and screen-reader status text changes for results, empty results, selection, copy confirmation, and errors.
- SVG charts have adjacent tables or textual alternatives. Wide content remains contained at 320, 375, and 390 px with no page-level horizontal overflow.
- Browser-console checks pass, Croatian diacritics remain literal, `data/**` is unchanged, and no source-adjacent render scatter is created.

## Completion record

Run 3 was implemented on 24 August 2026.

- Commit: recorded by the commit that contains this completion record.
- Pages changed: `pages/moj-medij.qmd`; one quiet cross-link in `pages/baza.qmd`; corresponding generated pages in `docs/pages/`.
- Shared components changed: added `assets/js/moj-medij-findings.js`, which contains the deterministic support rules and deep-link helpers.
- Tests added or updated: added `tests/moj_medij_findings.test.cjs` with seven tests covering evidence priority, sparse and incomplete profiles, support thresholds, duplicate names, stable share parameters, keyboard semantics, chart alternatives, and narrow-screen containment rules.
- Verification commands passed: focused Node tests; all 63 R regression checks; `R/00_setup.R`; the 135-page site-link check; the Run 3 browser-console check across the base page, a normal deep link, a duplicate-name platform link, and a no-result link; final isolated Quarto render outside Dropbox.
- Payload review: all 356 public profiles render without a findings error. Of these, 325 receive three supported findings and 31 receive two plus the explicit fewer-findings notice.
- Manual viewports checked: deterministic source and rendered-DOM assertions cover 320, 375, and 390 px containment rules. The in-app browser had no available connection, so a visual viewport pass was not possible in this session.
- Remaining known issues: the workspace render wrote the final page but Dropbox locked `docs/sitemap.xml` during project post-render. The same final source rendered cleanly outside Dropbox. `R/check_sources.R` still reports four pre-existing mojibake lines in untouched R files. `R/check_disclosure.R` still reports one pre-existing `context` column under `studies/moral-economy/output/`. The corpus page's pre-existing client code raises a generic browser-console exception even though its new link and all site links resolve.
- Data and scatter checks: `data/**` remained unchanged, `docs/` retained 135 HTML pages, and empty root-level Quarto output and task-specific verification files were removed after their paths were checked.
- Approval to continue: pending user review. Run 4 was not started.
