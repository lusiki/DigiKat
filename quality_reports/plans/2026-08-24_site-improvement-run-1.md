# Plan — site improvement Run 1

**Date:** 2026-08-24  
**Scope:** Shared academic foundation only. Do not begin the homepage or corpus-page redesign assigned to Run 2.  
**Publishing surface:** Quarto sources and shared site configuration. Existing unrelated work under `explorations/` remains untouched.

## Goal and rationale

Establish the shared editorial, navigation, design, metadata, and methodology contracts that later site-improvement runs can apply consistently. The site must remain an academic research publication whose primary outputs are the official corpus, maps, and research.

## Implementation

1. Replace the crowded top-level navigation with four short groups and move technical or utility links to the footer.
2. Ratify the canonical purpose sentence, controlled vocabulary, status vocabulary, and Croatian editorial rules in one maintained guide.
3. Inventory repeated technical-method passages and assign each family to a stable anchor on `pages/metodologija.qmd`. Define the short cautions that may remain on result pages.
4. Extend the shared SCSS with explicit design tokens and restrained reusable components for summaries, publication entries, freshness strips, citations, figures, downloads, and expandable references.
5. Define the site-wide page metadata and freshness contract, and align shared site metadata and structured data with the canonical purpose sentence.
6. Verify representative Quarto pages without running a full-site render, which requires a separate explicit confirmation under the repository hard gate.
7. Record the completed Run 1 checks and create one reviewable commit containing only Run 1 files.

## Boundaries and rejected alternatives

- Do not redesign `index.qmd`, `pages/baza.qmd`, maps, reports, or `Moj medij`; those belong to later runs.
- Do not edit generated files under `docs/` by hand or mutate `data/**`.
- Do not introduce a commercial visual language, new application framework, or new persistent capability.
- Do not stage or commit the existing unrelated changes under `explorations/`.
- Do not publish or push. The repository uses GitHub Pages, and external publication is outside this implementation request.

## Verification gate

- `_quarto.yml` parses and representative pages render from the repository root.
- Rendered HTML contains literal Croatian diacritics and no empty navigation targets introduced by this run.
- Shared focus and reduced-motion rules are present.
- `git status` contains no source-adjacent render scatter and no changes under `data/`.
- The Run 1 completion record names any deferred full-render or viewport checks.
