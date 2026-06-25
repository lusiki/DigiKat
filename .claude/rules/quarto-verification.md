---
paths:
  - "pages/**/*.qmd"
  - "R/*.qmd"
  - "_quarto.yml"
---

# Quarto Verification

"Compile-before-done" for the website. The site is a primary deliverable and `docs/` is committed.

1. **Render the touched page before reporting done:** `quarto render <that page>` must succeed (no chunk
   errors in the output HTML). Prefer rendering ONE page during edits; a full-site render is slow and hides
   which page broke.
2. **Figures actually render** — no empty `<img>`, no error blocks in the output HTML.
3. **Croatian diacritics display** in the rendered HTML (č ć ž š đ as literal UTF-8, not `&#269;` or boxes).
4. **No NEW broken links / cross-refs.** The empty `href: ""` entries under "Tematska istraživanja" in
   `_quarto.yml` are intentional stubs — flag, don't fail; never introduce new empty hrefs.
5. **Render must be side-effect-free on `data/`.** Today `pages/mapa/mapa.qmd` calls `saveRDS()` into
   `data/processed/*.rds` mid-render (Phase-0 fix pending): treat ANY change to `data/processed/*.rds` during a
   render as an accident — do NOT stage it; warn loudly. After those calls move into `R/03_aggregate.R`, no
   page may write into `data/` at all.
6. **Data pages need data + R.** `baza.qmd` and `pages/mapa/*.qmd` read `data/processed/*.rds` (and some read
   the gitignored master / `data/nlp/`). On a machine without them (`R_AVAILABLE = false`, master absent — see
   `CLAUDE.local.md`), you CANNOT render these — verify statically (chunk syntax, `:::` div balance, diacritics
   in source) and hand rendering off, or render against the synthetic `data/sample/` once it exists.
7. **Publish = commit `docs/`.** Quarto's `output-dir: docs` IS the publish step; there is no separate sync script.
