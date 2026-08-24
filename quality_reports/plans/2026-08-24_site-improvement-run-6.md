# Plan — site improvement Run 6

**Date:** 2026-08-24

**Scope:** The complete active DigiKat site, the canonical source-profile generator, shared site metadata and styles, representative publication outputs, and the automated release checks that protect them.

## Goal and rationale

Finish the six-run improvement programme by applying the established scholarly, editorial, accessibility, responsive, metadata and performance contracts across the active site. Convert the most important contracts into deterministic checks that run locally and in CI so later changes cannot silently reintroduce stale content, inaccessible controls, broken metadata, excessive page weight or narrow-screen overflow.

## Implementation

1. Inventory active source and rendered pages, then add a dependency-free static quality audit for headings, descriptions, canonical URLs, social images, chart summaries, freshness fields, local links, image dimensions and page-weight budgets.
2. Extend the existing Chrome-based browser audit into a reusable release check. Test the required 320, 375, 390, 768 and 1024 pixel widths, page-level overflow, browser console and network failures, keyboard focus visibility, reduced motion and serious or critical WCAG findings on the representative review matrix.
3. Add the browser accessibility dependency as a pinned development dependency, wire the static and browser checks into CI, and document the complete local release sequence and measured page-class budgets.
4. Update the canonical `R/wiki_sources.R` generator with unique descriptions, explicit freshness/status information, clearer Croatian terminology, methodology links, accessible table markup through Quarto and consistent source notes. Regenerate the catalogue and spot-check one profile from web, YouTube, Facebook, Instagram, TikTok and Twitter plus all platform hubs.
5. Sweep active hand-authored pages for missing descriptions, stale news, unexplained English, controlled-vocabulary drift, punctuation, capitalization and date-format errors. Keep English mirror pages English and preserve historically published study findings.
6. Apply shared accessibility and responsive repairs in the site stylesheet and header include, including named icon links, keyboard-visible focus, reduced-motion behaviour, responsive tables/media and safe overflow containment. Preserve the current scholarly visual identity and existing social card.
7. Add or correct page-specific structured data only for semantically appropriate datasets, articles and scholarly reports while retaining the global `ResearchProject` and `WebSite` graph.
8. Run focused source, generator, static-quality and browser checks while iterating. Render only explicitly affected pages during implementation and verify generated output remains confined to `docs/`.
9. At the repository hard gate, request confirmation before the final full `quarto render`. After approval, run the complete regression, source, disclosure, setup, render, link, static-quality and browser sequence, inspect the final diff and append the completion record.

## Boundaries and rejected alternatives

- Do not change the official corpus, inclusion rule, aggregates, analytical findings, source classifications or disclosure policy.
- Do not hand-edit the generated source-profile pages or `docs/` output. Fix the generator or source and regenerate.
- Do not replace the established Quarto/GitHub Pages architecture with a new framework or hosting surface.
- Do not generate a new social card. The current DigiKat card and metadata are valid and branding is unchanged.
- Do not run `R/03_aggregate.R --apply`, overwrite protected data, publish, push, bulk-stage or commit.
- Do not run the final full-site render without the explicit confirmation required by `.claude/rules/plan-first-workflow.md`.
- Do not treat automated checks as a substitute for the documented manual academic-tone and visual review.

## Verification gate

- The canonical generator recreates the catalogue without touching `data/processed/`, and representative profiles from all six platforms expose unique metadata, freshness, status and methodology links.
- Active pages pass controlled-vocabulary and editorial checks; the obsolete **Uskoro** item is gone and dates distinguish project period, observation period, report year and publication date.
- Static checks pass for one H1, heading order, descriptions, canonicals, social assets, structured data, chart summaries, local links, freshness fields, image dimensions and page-weight budgets.
- Browser checks pass at 320, 375, 390, 768 and 1024 pixels with no page-level horizontal overflow, console/network failures or serious/critical automated accessibility violations.
- Keyboard focus, reduced motion, tables, figure summaries and **Moj medij** announcements remain functional.
- Repository tests, source/disclosure/setup checks, final full render, link check, `git diff --check` and output-location checks pass after the full-render gate is approved.
