# explorations/

Sandbox for throwaway analyses (see `.claude/rules/exploration-folder-protocol.md`).

- One folder per experiment: `explorations/<slug>/` with a README (question, status, kill-by date), code, and `output/`.
- `output/` is gitignored; explorations may **read** the corpus but **never write** into `data/`, `pages/`, `docs/`, or `studies/`.
- Done or dead? Move it to `explorations/ARCHIVE/completed_<slug>/` or `abandoned_<slug>/` with a one-paragraph why.
- Earned its place? Graduate the code to `R/` or `studies/<slug>/` and upgrade to full rigor.
