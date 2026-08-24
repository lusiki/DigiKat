# Plan — site improvement Run 2

**Date:** 2026-08-24  
**Scope:** Homepage and official corpus page, using the editorial, navigation, design, metadata, and methodology contracts established in Run 1.  
**Publishing surface:** Quarto sources and shared styles. Existing unrelated work remains untouched.

## Goal and rationale

Make DigiKat's purpose and three central outputs immediately legible. The homepage will lead with the project's canonical purpose, then guide readers to the official corpus, maps, and research. The corpus page will describe one authoritative official corpus and separate the stable public access story from archival and technical detail.

## Implementation

1. Rebuild the homepage hierarchy around the canonical purpose sentence, one primary map action, quiet corpus and research links, and the existing research questions.
2. Present the corpus, maps, and research as the three central outputs. Move **Moj medij** into a lower supporting-tools section.
3. Replace the compact report line with publication-style entries for current research outputs, including dates, findings, status, reading time where useful, and available HTML/PDF links.
4. Rework the homepage statistics for one- or two-column narrow layouts without page-level horizontal overflow.
5. Reframe `pages/baza.qmd` around the one official DigiKat corpus, add a 60-second summary and a compact access panel, and move technical detail behind methodology links or expandable references.
6. Add concise scope and limitation guidance, a citation block, resolvable public-resource links, and Dataset structured data derived from the tracked corpus manifest.
7. Add page-level descriptions and only the shared style rules required by these two pages.
8. Render the two touched pages from the repository root, check links and generated structure, and record any validation that remains blocked by the full-render hard gate.

## Boundaries and rejected alternatives

- Do not redesign maps, research articles, reports, or **Moj medij**. Those belong to later runs.
- Do not foreground the internal accumulator or historical snapshots in the corpus page's primary narrative.
- Do not change the corpus, manifests, aggregates, pipeline, or any file under `data/`.
- Do not hand-edit generated files under `docs/`; page renders may update their normal generated targets.
- Do not run a full-site render, publish, push, or alter the existing GitHub Pages architecture without explicit approval.
- Do not introduce a commercial hero treatment, a new framework, or a persistent capability.
- Do not stage, overwrite, or revert existing unrelated working-tree changes.

## Verification gate

- `quarto render index.qmd` and `quarto render pages/baza.qmd` succeed from the repository root when the local environment has their dependencies.
- The rendered pages preserve Croatian diacritics and contain the expected metadata and structured data.
- Homepage links, publication links, and corpus-resource links resolve locally or return a successful public response.
- Static narrow-layout checks cover 320, 375, and 390 px overflow risks without opening a browser unless browser testing is separately requested.
- No render changes `data/**`, creates source-adjacent output, or empties `docs/`.

## Completion record

Run 2 was implemented on 24 August 2026.

- The homepage now opens with the canonical purpose sentence and one primary map action. Quiet links lead to the official corpus and research overview.
- The official corpus, four map layers, current publications, and supporting source tools now follow the approved hierarchy. **Moj medij** appears only in the final supporting-tools section.
- Current research outputs use publication-style entries with dates, findings, reading times, status, and available formats.
- The homepage statistics use four, two, and one-column layouts at progressively narrower widths, with explicit overflow containment and reduced page padding on small screens.
- The corpus page now presents one official corpus, a 60-second summary, a compact access panel, public artifacts, a citation block, concise use limits, canonical methodology links, and expandable tables and reproduction instructions.
- Dataset JSON-LD describes the corpus and its public manifest, aggregate manifest, and synthetic sample. The rendered metadata contains all 54 variable names and the manifest-derived temporal coverage.
- `CITATION.cff`, the corpus manifest, all 14 public aggregate files, and the synthetic sample and its manifest are copied as public site resources.
- `quarto render index.qmd` and `quarto render pages/baza.qmd` both completed successfully from the repository root. The rendered HTML contains literal Croatian diacritics, no unresolved inline R, and no escaped component markup.
- A focused rendered-link check found no missing local files or anchors on either page. All homepage publication links and corpus-resource links resolve in `docs/`.
- Static narrow-layout checks confirmed overflow containment and the two-column and one-column statistics breakpoints used at 320, 375, and 390 px.
- The render left `data/**` unchanged, preserved 135 rendered HTML pages, and left no source-adjacent HTML or resource directories.

A full-site render was not run because it is a repository hard-gate operation requiring separate confirmation. Browser viewport inspection was not run because browser testing was not part of this request. No deployment, push, staging, or commit was performed.
