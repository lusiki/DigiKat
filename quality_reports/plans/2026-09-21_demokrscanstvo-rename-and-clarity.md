# Demokršćanstvo u medijima — rename follow-through and accepted clarity fixes

**Date:** 2026-09-21 · **Owner:** PI (Luka Šikić) · **Branch:** feat/demokrscanstvo-barometar

## Goal
Finish the rename "Medijski barometar demokršćanstva" → "Demokršćanstvo u medijima" and apply the
subset of the 2026-09-21 review findings the PI accepted. Render two pages only
(`pages/demokrscanstvo/index.qmd`, `index.qmd`). No full site render.

## Accepted (PI, 2026-09-21)
1. **metodologija.qmd** — fix the contradiction. The section still says the instrument is *u pripremi*
   with *izmišljeni podaci*, and describes a web-only panel. Rewrite to the published reality; keep the
   `{#method-barometar}` anchor (two private check scripts key on it).
2. **Validation disclosure** — NO change. PI: the page is good as it is.
3. **Presentation** — must not call the page by its old name. One string, `build.py:75`.
4. **Rate basis** — per 10.000 → **per 100.000** (finding 5). Everything else in finding 5 declined.
5. **Grammar** — fix "1.731 različitih tekstnih konteksta" (numeral agreement).
6. **Style breaches (finding 7)** — DECLINED, leave alone.
7. **Smaller things (finding 8)** — fix.
8. **Kretanja chart** — remove the collection-break line and the line break. Connect the dots. No
   methodological marking of *promjena prikupljanja* anywhere on the chart.
9. **Kretanja controls** — remove `Obuhvat`, `Pokazatelj`, `Tekst`. Keep `Platforma`.

## Decisions taken while planning
- **Rate conversion is display-only.** `monthly.csv` / `platforms.csv` keep the `per_10000` column,
  because `multiplatform_verify.py` asserts `per_10000 == 10000*n/d` and the release is built from
  DetermDB (not cheaply rebuildable). R and JS multiply by 10 at render time. This leaves a seam: a
  reader who downloads the CSV gets a column named per_10000. Flag to PI.
- **Line breaks on null months stay.** `segments()` splits on (a) a null value and (b) the collection
  break. Only (b) is removed. A month with no eligible records has no dot to connect — web has none
  of these (0/69), so the web series becomes fully continuous, which is what the PI is looking at.
- **Anchor IDs unchanged** (`#method-barometar`, `#metoda`, `#kretanja`) so no inbound link breaks.
- **Arial figure fonts NOT fixed** — needs the three typefaces vendored under OFL plus
  `svglite(web_fonts=)`; site-wide, and it shifts every figure metric. Stays a PI decision.

## Order of work
A. metodologija.qmd rewrite.
B. Page edits (rate, grammar, finding-8 items, control removal, static chart).
C. `assets/js/barometar-multiplatform.js` + `tests/barometar_multiplatform.test.cjs`.
D. Presentation: verify current build reproduces byte-identically, then edit build.py, rebuild HTML,
   re-render PDF via render.mjs, refresh `pdf_sha256` and `bytes` in the tracked meta.json.
E. Render `pages/demokrscanstvo/index.qmd` and `index.qmd`. Verify.

## Verification gates
- Both barometer verifiers pass against the rendered HTML.
- `node --test tests/barometar_*.test.cjs` green.
- `data/processed/*.rds` md5 unchanged.
- Every href/src in both rendered pages exists on disk AND in `git ls-files`.
- Page `stopifnot` on the three PDF sha256 gates passes (proves meta.json was refreshed correctly).
