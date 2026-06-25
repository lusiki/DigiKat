---
name: refresh-data
description: Safely run the incremental data-append pipeline for DigiKat — wraps R/append_new_data.R with guardrails and a structured delta report, then reminds you to regenerate aggregates and re-render. Use when the user says "refresh the data", "append new data", "add the new batch", "update the corpus", "ingest new posts". Highest-risk recurring action (it overwrites the gitignored master in place). NOT for full rebuilds or for deploying the site (/deploy).
argument-hint: "(no args — processes data/raw/new/*.xlsx)"
---

# /refresh-data — safe incremental append

## Instructions
1. **Plan-first / HARD GATE.** This overwrites `data/merged_comprehensive.rds`. Confirm with the user
   before running (per the plan-first-workflow + data-pipeline-protocol rules).
2. **Env check (run-or-handoff).** Read `CLAUDE.local.md`. If `R_AVAILABLE = false` or the master is absent
   on THIS machine, do NOT attempt to run — output the exact command + the hand-off note (below) and stop.
3. **Pre-flight** (where R + master live): confirm `data/raw/new/` exists and contains `.xlsx`; confirm
   `data/merged_comprehensive.rds` exists; record current `nrow`/`ncol` and the count of existing
   `*_backup_*.rds`.
4. **Run** `Rscript R/append_new_data.R` (use the machine's resolved Rscript path from `CLAUDE.local.md`).
5. **Confirm safety:** a NEW `data/merged_comprehensive_backup_<timestamp>.rds` was written BEFORE the
   master was overwritten.
6. **Delta report** (parse the script output): rows before / read / pass-rate (≥2-match) / deduped /
   appended / after. Sanity-flag an implausible pass-rate (e.g. far from the historical ~10–15%).
7. **Stale-aggregates reminder (MANDATORY).** The append invalidated `data/processed/*.rds`, `data/nlp/*.rds`,
   and the map pages. Next steps: run `R/03_aggregate.R` (HARD GATE — overwrites tracked aggregates) to
   refresh `data/processed/`, re-run NLP if needed, then `/deploy`. Then `/commit` the refreshed aggregates
   only (the master and backups stay gitignored).

## Hand-off note (when R isn't on this machine)
> Run on the pipeline machine (where R + the master live):
> 1. drop the new `.xlsx` into `data/raw/new/`
> 2. `Rscript R/append_new_data.R`  — backs up the master, dedups on URL, keeps ≥2-match rows
> 3. `Rscript R/03_aggregate.R`     — refresh `data/processed/*.rds`
> 4. re-render the map pages, then commit the refreshed `data/processed/*.rds` (master/backups stay gitignored).

## Troubleshooting
- Script `stop()`s "Master file not found": the gitignored master isn't on this machine — you're on an
  edit-only machine; hand off (above).
- Pass-rate looks wrong: check the new `.xlsx` has a `FULL_TEXT` column and is Croatian text (UTF-8).
