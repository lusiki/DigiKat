# Plan — Tematska istraživanja overview page (2026-08-07)

## Goal
Give the "Tematska istraživanja" navbar tab a landing/overview page listing all eight thematic
studies (title, hook, authors, status), mirroring the existing pattern of `pages/mapa/index.qmd`
("Pregled mapa" as the first dropdown entry).

## Decisions
- New page `pages/studije/index.qmd`, card-grid layout (`.card-grid` / `.info-card`), house voice.
- Nav: add "Pregled istraživanja" as the FIRST item of the "Tematska istraživanja" menu in
  `_quarto.yml` (same pattern as "Pregled mapa").
- **Render scope: MINIMAL, per explicit user choice (2026-08-07).** Only `index.qmd` (hero
  byline reorder) and the new `pages/studije/index.qmd` are rendered. Existing pages keep the
  stale dropdown (no "Pregled istraživanja" entry) until a future FULL render, which stays
  behind the hard gate.
- Rejected: full render now (user declined); putting the overview under `pages/mapa/` (wrong
  section); auto-generating the card list from qmd front matter (over-engineering for 8 items).

## Also in this change-set
- Landing-page hero byline reordered to "Luka Šikić · Hrvatsko katoličko sveučilište ·
  2021.–2027.", name linked to lukasikic.info without underline (user request).
