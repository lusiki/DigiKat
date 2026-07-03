# Plan — Agentic-layer iconographic → bilingual detail page + exec-overview teaser

**Date:** 2026-07-03 · **Owner:** Luka Šikić · **Type:** new `pages/**` + edit exec overview (plan-first required)

## Goal
Integrate the agentic-layer iconographic into the site as a standalone **detail page**, available in
**Croatian and English**, add **Skills (Vještine)** as a first-class fourth organ (currently missing),
and reduce the executive overview's agentic section to a **brief teaser + link** out to the detail page.

## Why (and what this replaces)
The exec overview ([pages/pregled/izvrsni-pregled.qmd](../../pages/pregled/izvrsni-pregled.qmd)) currently
covers the agentic layer in three short cards (Pravila / Provjere / Zaštite) and **omits Skills entirely**.
The PI wants the richer picture integrated, an English version available, the overview to only touch it
briefly and link out, and Skills discussed.

## Files
1. **Update the iconographic** (scratchpad `agentski-sloj.html`) — add a 4th organ **Vještine**; re-publish
   the Artifact so the updated graphic is previewable. *(preview only, not in repo)*
2. **NEW `pages/pregled/agentski-sloj.qmd`** (HR) — lead → iconographic (`{=html}` block) → fuller discussion:
   the five parts (Kontekst · Pravila · **Vještine** · Provjere · Zaštite), "kako je sve povezano"
   (podjela ovlasti / obrana u dubinu / upravljana petlja), "što sloj ne radi" (proces, ne istina; PI drži
   oznake + tvrde brane), "sve je javno" (CLAUDE.md + .claude/ links). Language toggle → EN.
3. **NEW `pages/pregled/agentic-layer.qmd`** (EN) — English mirror: translated iconographic + prose. Toggle → HR.
4. **EDIT `pages/pregled/izvrsni-pregled.qmd`** — shorten the `## Agentski sloj` section to ~1 tight paragraph
   + a four-item Pravila/Vještine/Provjere/Zaštite line + a `.dk-btn` link "Cijeli prikaz agentskog sloja →".
   Update the `13:30–14:15` speaker-notes comment to mention Skills + the link.

## Skills grouping (all 14, for the Vještine organ + prose)
- **Objavljivanje i podaci:** `/deploy` · `/render-page` · `/refresh-data` · `/commit`
- **Analiza:** `/data-analysis` · `/check-lexicon` · `/disclosure-check`
- **Recenzija:** `/review-page` · `/review-paper`
- **Istraživanje:** `/new-study` · `/lit-review` · `/research-ideation`
- **Održavanje:** `/capture-environment` · `/context-status`

## Design
Reuse DigiKat tokens (teal on cream, IBM Plex Mono / Source Serif 4 — which the site already loads).
Four organ accents: teal → slate-blue → teal-green → brick; amber reserved for the human hard-gate.
Scoped `.ag-` classes (no collision with the site SCSS); inline SVG icon sprite. HR labels on the HR page,
English labels on the EN page.

## Nav (default: no `_quarto.yml` change)
The exec overview itself is **not** in the navbar — it's a shareable standalone doc. The detail page follows
the same pattern: reached from the overview's link + the EN↔HR toggle, not the global nav.
*Optional (say the word):* add a discovery link from [pages/site-info.qmd](../../pages/site-info.qmd).

## Verification (quarto-verification rule)
- Render the two new pages + the edited overview as **single-page** renders **from the repo root**.
- Confirm: output only under `docs/` (no scatter, `docs/` not emptied); Croatian diacritics literal UTF-8;
  EN↔HR links resolve; the overview still passes its `stopifnot` guards; **no `data/processed/*.rds` mutation**
  (`git status --short data/processed/`).
- Dropbox note: single-page renders only (no full-site render → no HARD GATE). If file-locking (`os error 32`)
  hits, stop and hand the render off.

## Out of scope / not doing
Full-site `quarto render` (HARD GATE); nav restructuring; any data/R-pipeline change; committing (that's a
separate `/commit`).

## Rejected alternatives
- **Inline-bilingual single page** — rejected; voice-and-style says an English mirror is a *separate page*.
- **Detail page in the global navbar** — rejected by default; the overview isn't nav-listed either, keeps nav clean.
- **Keep 3 organs, mention Skills only in prose** — rejected; PI wants Skills visible, and a 4th organ is more honest.
