---
name: render-page
description: Render and verify ONE DigiKat Quarto page (fast iteration) — confirms it builds, figures render, Croatian diacritics are intact, and no tracked data/processed/*.rds was mutated. Use when the user says "render the X page", "check the diskurs/mapa/događaji page", "rebuild this page", "does this page build?". For the WHOLE site use /deploy.
argument-hint: "<page> (e.g. mapa, mapa_stats, diskurs, dogadaji, baza, or a path)"
---

# /render-page — render + verify a single page

## Instructions
1. **Resolve the target** from `$ARGUMENTS`. Map short names to paths:
   `mapa`→`pages/mapa/mapa.qmd`, `mapa_stats`→`pages/mapa/mapa_stats.qmd`,
   `diskurs`→`pages/mapa/diskurs.qmd`, `dogadaji`|`događaji`→`pages/mapa/događaji.qmd`
   (NOTE the đ in the real filename), `baza`→`pages/baza.qmd`; otherwise accept a literal path.
2. **Env check.** If it's a data page and R / aggregates / master are absent here (`CLAUDE.local.md`), do a
   STATIC review instead (chunk syntax, `:::` div balance, obvious errors, diacritics in source) and say it
   must be rendered where the data lives. For data pages that read ONLY `data/processed/*.rds`, those
   aggregates ARE in the repo — render if Quarto + the required R packages are available.
3. **Baseline.** `git status --short data/processed/`.
4. **Render** the one page — **from the REPO ROOT**: `quarto render <path>` (e.g.
   `quarto render pages/mapa/mapa.qmd`). NEVER `cd pages && quarto render mapa.qmd`: rendering with the project
   undetected scatters HTML / `site_libs/` / `*_files/` beside the source and can EMPTY `docs/` (this once
   nearly took the live site down — see `MEMORY.md` and the quarto-verification rule §8).
5. **Scatter / wipe check.** Confirm output went to `docs/` and ONLY `docs/`: `git status --short` shows NO
   stray output (no `pages/**/*.html`, no `site_libs/` or `*_files/` beside the source, no root `index.html`)
   and NO deletion of `docs/**/*.html`. If you see scatter or an emptied `docs/`: STOP, `git checkout -- docs/`,
   re-render from the root, and do NOT stage the deletions. (`.gitignore` + the git/data guard hook backstop
   this, but verify anyway.)
6. **Side-effect check.** `git status --short data/processed/` — flag any change (`mapa.qmd` writes
   aggregates today; that's a Phase-0 fix, not something to stage).
7. **Verify** the page HTML: built, figures present, diacritics literal UTF-8, no chunk errors.
8. **Report** PASS / WARN / FAIL with the specific issues.
