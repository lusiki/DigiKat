# Plan — Catholic-education visual layer and thematic-study publication

**Date:** 2026-08-06
**Study:** `studies/catholic-education/`

## Goal

Give the paper a coherent black-and-white visual system, add only figures that communicate distinct findings,
and publish the paper through the same local profile-and-format pattern used by the existing entries under
**Tematska istraživanja**.

## Visual decisions

1. Restyle the recurrence-versus-anchoring scatterplot in grayscale, using shape and fill together so the
   comparison remains readable in print and does not depend on colour.
2. Restyle the seasonal small multiples so peak months are black and all other months are light gray. This
   makes the February and August calendars visible without a colour legend.
3. Add a proximity-filter figure comparing whole-document overlap (36,0 %) with local anchoring (11,0 %) and
   state the resulting 69,4 % reduction directly in the graphic.
4. Add a source-composition figure for the main anchors, using 100 % black-and-white bars to show confessional
   and non-confessional shares among classified posts.
5. Do not add a separate affect figure. Affect is explicitly supporting evidence, its differences are modest,
   and another chart would give that result more visual weight than the paper's argument warrants.

## Publication decisions

1. Create `pages/studije/katolicko-obrazovanje-i-stepinac.qmd` in Croatian, following the established study
   profile structure: question, data and method, findings, figures, formats, and status.
2. Add one navbar entry under **Tematska istraživanja**.
3. Register the local paper in `scripts/publish_thematic_papers.ps1`, publish HTML/PDF/Word copies under
   `assets/papers/`, and update the asset inventory.
4. Use **DigiKat projekt** as institutional author metadata because the manuscript names no individual author.
5. Render only the new profile and the home page. A full-site render is outside scope and requires separate
   confirmation under the repository hard gate.

## Verification

- Run the figure script end to end and inspect all four PNGs.
- Render the manuscript to HTML, PDF, and Word; verify four embedded figures and resolved references.
- Publish the thematic-paper formats using the existing publisher with `-Only` for the new paper.
- Render the new study profile and `index.qmd` from the repository root.
- Confirm literal Croatian diacritics, working local links, non-empty `docs/`, and no changes under `data/`.
