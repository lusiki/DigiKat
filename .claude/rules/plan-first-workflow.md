# Plan-First Workflow

Enter plan mode and save a plan to `quality_reports/plans/YYYY-MM-DD_<desc>.md` before any non-trivial
task — especially anything that changes WHAT is in the corpus or mutates the master.

**Always plan first:**
- Any change to the religious-terms filter (`R/religious_terms.R`) or the ≥2-match rule — it redefines the corpus.
- Any change to a lexicon/dictionary (`resources/lexicons/**`, `resources/dictionaries/**`) or the 16-category scheme.
- Rebuilding the master, large append batches, or editing `R/03_aggregate.R` (regenerates the tracked `processed/*.rds`).
- A new analytical page or thematic study (`pages/**`, data flow, `_quarto.yml` nav).
- Multi-file refactors, or anything touching the data-pipeline DAG.

**Fast-track (skip planning):** one-page typo, CSS tweak, single-page re-render, one new chart on an existing page.

**HARD GATE — STOP and confirm with the user before:**
- Overwriting `data/merged_comprehensive.rds`.
- Deleting or moving any `*_backup_*.rds`.
- Running `R/03_aggregate.R` (overwrites tracked `data/processed/*.rds`).
- A FULL `quarto render` that overwrites `docs/`.
- Any git history rewrite, force-push, or bulk `git add`.

Plans persist on disk so they survive context compaction. After approval, record the goal + rationale
(including rejected alternatives) so the "why" survives, not just the "what".
