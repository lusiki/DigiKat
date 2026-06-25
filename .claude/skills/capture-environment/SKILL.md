---
name: capture-environment
description: Snapshot the DigiKat computational environment for reproducibility — refresh renv.lock and write ENVIRONMENT.md (R version, locale, package versions, Quarto version, the pinned udpipe model + hash). Use when the user says "capture environment", "snapshot the environment", "update renv", "record dependencies", "what versions am I using", or before a release / replication package. Runs R — hands off if R isn't on this machine.
argument-hint: "(no args)"
---

# /capture-environment — reproducibility snapshot

## Instructions
1. **Env check.** Read `CLAUDE.local.md`. If `R_AVAILABLE = false` here, do NOT run — output the hand-off
   command (below) and stop.
2. **Run** `Rscript R/capture_environment.R` (resolved Rscript path). It refreshes `renv.lock` (if renv is
   initialized) and writes `ENVIRONMENT.md`, including the udpipe model's sha256.
3. **Verify** `ENVIRONMENT.md` was written and the model hash matches the pinned value
   `b8e0ad212bdc84c57366bd7267d21810e1fd3239c4d22ca5867f94e76c6cedc7` — a mismatch means the model file changed.
4. **Report** the captured R version, locale (flag if not UTF-8 / R < 4.2), Quarto version, and renv status.
   Suggest `/commit` for `ENVIRONMENT.md` + `renv.lock`.

## Hand-off (R not on this machine)
> On the pipeline machine: `Rscript R/capture_environment.R`, then commit `ENVIRONMENT.md` + `renv.lock`.

## Note
`renv` must be initialized once first (`renv::init()` on the pipeline machine) — it cannot be bootstrapped
without R. After that, this skill keeps the lock current.
