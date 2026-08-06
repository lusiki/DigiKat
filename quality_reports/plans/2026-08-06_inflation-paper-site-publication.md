# Plan — publish the revised inflation paper on the project website

**Date:** 2026-08-06 · **Study:** `studies/inflation-salience/`

## Goal

Retitle the manuscript as *Inflation, Information, and Delayed Repricing*, list Luka Šikić and
Petra Palić as authors at the Catholic University of Croatia, and replace the obsolete
“Poskupjele svijeće, tihi proroci” thematic page with the revised study. Publish readable HTML
with visible figures plus downloadable PDF and Word editions.

## Steps

1. Update the bilingual manuscript title and author block.
2. Extend manuscript production to generate HTML and PDF alongside the existing full and blinded Word files.
3. Publish the full HTML, PDF, Word file and both figures under `assets/papers/`.
4. Replace `pages/studije/inflacija-i-religija.qmd` with the revised study summary and format links.
5. Update the thematic-explorations navigation label.
6. Run manuscript checks, render all paper formats, render the single website page, and inspect links and figures.

## Boundaries

- Treat the requested authorship as two authors total because only Petra Palić was supplied as an addition.
- Do not invent Petra Palić's email, ORCID or a separate affiliation.
- Do not run a full-site render, which requires separate confirmation under the project rules.

## Completion

Completed 2026-08-06 after explicit approval for the full-site render. Quarto rendered all 134 source
pages successfully. The old title is absent from all generated files; 136 HTML files carry the new
navigation state. The site link checker passed across all 136 HTML files with no missing local targets,
broken anchors or mojibake. The published paper is available as self-contained HTML, a 14-page PDF and
Word, with both figures verified in every applicable format.
