---
name: deploy
description: Render the full DigiKat Quarto site to docs/ and verify it before publishing to GitHub Pages — checks Croatian diacritics, that figures rendered, internal links, and that the render did NOT mutate tracked data/processed/*.rds. Use when the user says "deploy the site", "publish the site", "render the site", "build the website", "update the website". Renders the WHOLE site; for one page use /render-page. Does not commit — hand off to /commit.
argument-hint: "(no args — renders the whole site)"
---

# /deploy — render + verify + stage the site

## Instructions
1. **Pre-flight.** Confirm `quarto --version`. Read `CLAUDE.local.md`: are R + the master/aggregates present?
   The four `pages/mapa/*.qmd` and `baza.qmd` are data pages needing `data/processed/*.rds` (some also need
   R / the master / `data/nlp/`). If those inputs are absent here, WARN that the data pages cannot fully
   render on this machine and offer to (a) render content-only pages, or (b) hand the full render to the
   pipeline machine.
2. **Record data state.** `git status --short data/processed/` BEFORE rendering (baseline).
3. **Render.** `quarto render`.
4. **Side-effect check (IMPORTANT).** `git status --short data/processed/` AFTER. If any aggregate changed,
   STOP and report — a page wrote into tracked data (the `mapa.qmd` saveRDS issue, a Phase-0 fix). Do NOT
   stage those changes.
5. **Verify output** (launch the `verifier` agent, or inline): per rendered page — the `docs/` HTML exists
   and is newer than source; no visible chunk-error blocks; figures present; Croatian diacritics are literal
   UTF-8; no NEW broken internal links (the empty `href: ""` study stubs in `_quarto.yml` are known/expected).
6. **Report** a PASS / WARN / FAIL table per page. **Do NOT auto-commit** — tell the user to run `/commit`
   to publish (committing `docs/` IS the GitHub Pages publish step).

## Troubleshooting
- A data page errors with a missing-file / `readRDS` error: the aggregates or master aren't on this machine
  — render it where the data lives (see `CLAUDE.local.md`), or use the synthetic `data/sample/` once it exists.
- Diacritics show as boxes/entities in `docs/`: stop and check encoding (see the croatian-encoding rule).
