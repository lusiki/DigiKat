---
name: new-study
description: Scaffold a new DigiKat thematic study — create studies/<slug>/ with a README (RQ, corpus slice, status, owner), a slice.R starter, a refs.bib, and an output/ folder, and optionally wire the matching empty nav entry in _quarto.yml. Use when the user says "new study", "start a thematic study", "scaffold the pilgrimage/saints/education study", "set up a new sub-study".
argument-hint: "<slug> (e.g. youtube-selfhelp, pilgrimage-tourism, christian-democracy, catholic-education, saints)"
---

# /new-study — scaffold a thematic study

## Instructions
1. **Resolve the slug** from `$ARGUMENTS` (kebab-case English). The five planned studies:
   `youtube-selfhelp`, `pilgrimage-tourism`, `christian-democracy`, `catholic-education`, `saints`.
2. **Create** `studies/<slug>/` from `studies/_STUDY_TEMPLATE/`: `README.md`, `slice.R`, `refs.bib`,
   `output/.gitkeep`. Fill the README with the RQ, the corpus slice definition (which platforms / terms /
   date range), owner, and status. Do NOT invent findings.
3. **Plan-first** if the study touches the pipeline or term list (it usually shouldn't — studies READ the
   corpus, they don't redefine it).
4. **Optional nav.** If asked, fill the matching empty `href: ""` under "Tematska istraživanja" in
   `_quarto.yml` to point at `pages/studije/<slug>.qmd` (create the page later via the normal page workflow).
5. **Next steps.** Suggest `/research-ideation` (sharpen the RQ), `/lit-review` (related work), then
   `/data-analysis` on the slice.

## Note
Working files live in `studies/<slug>/`; the PUBLISHED page lives under `pages/` and renders to `docs/`.
Keep them separate.
