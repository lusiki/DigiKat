---
name: data-analysis
description: Run an end-to-end exploratory R analysis on a slice of the DigiKat corpus — explore, aggregate or score on a stratified 2–5% sample by default, produce a figure/table, then hand the code to the r-reviewer agent. Use when the user says "analyze the data", "run an analysis", "explore the corpus", "make a chart/table from the data", "what does the data say about X". Sample-first; never dumps 610k rows into context. Hands off if R isn't on this machine.
argument-hint: "<research question or corpus slice> (e.g. 'engagement of LaudatoTV', 'theme trends 2021-2025')"
---

# /data-analysis — DigiKat corpus analysis (sample-first)

## Instructions
1. **Plan-first** for anything non-trivial; save a short plan. Clarify the question, the slice, and the
   expected output (figure / table / summary) if ambiguous.
2. **Env check (run-or-handoff).** Read `CLAUDE.local.md`. If `R_AVAILABLE = false` / master absent, write the
   analysis script + the exact run command and hand off; do NOT fabricate results.
3. **Work on a SAMPLE by default.** Draw a stratified 2–5% sample (platform × year, seeded) — or use
   `data/sample/` — unless the user explicitly needs the full corpus. Never load 610k rows into context.
4. **Analyze.** Explore (structure, missingness), then aggregate/score. Reuse the religious filter + the
   thematic-dictionary definitions; do not redefine the corpus.
5. **Output.** Save figures/tables to `output/<slug>/` (`figures/`, `tables/`). No hand-typed numbers — compute them.
6. **Review.** Launch the `r-reviewer` agent (Task, `subagent_type: "r-reviewer"`) on the script; address
   Critical/Major findings.
7. **Report** what was found + where outputs landed. Suggest `/review-page` if it's going onto a website page.

## Note
This is for ad-hoc analysis. For a standing thematic study, scaffold it with `/new-study` first.
