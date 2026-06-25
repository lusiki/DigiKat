---
name: disclosure-check
description: Pre-flight statistical-disclosure / PII screen before SHARING any DigiKat data extract or aggregate — scans for author/account metadata, small-cell counts (re-identification risk, esp. *_actors.rds), and raw scraped post text leaking into a "shareable" file. Use when the user says "disclosure check", "is this safe to share/publish", "check for PII", "can I commit this data", or before publishing data/sample/ or a new data/processed/ file. Read-only; flags, does not delete.
argument-hint: "<file or folder to screen> (e.g. data/sample/merged_sample.rds, data/processed/)"
---

# /disclosure-check — pre-share PII / disclosure screen

## Instructions
1. **Resolve target(s)** from `$ARGUMENTS` (a file or folder). Default scope: anything about to be shared
   (`data/sample/`, `data/processed/`, any new committed data).
2. **Delegate the PII scan** to `scholar-skill:scholar-safety` (local, pattern-based — raw data never enters
   the model context) for each file. Report its risk summary.
3. **DigiKat-specific checks:**
   - **Author/account columns** present and populated (AUTHOR / account / user / from_name) → re-identification risk.
   - **Small cells:** in `*_actors.rds` and any group-by aggregate, counts below a threshold (e.g. < 5) for a
     named actor/source → flag (dominance / singling-out).
   - **Free-text leakage:** any column still containing real scraped post text (FULL_TEXT / TITLE / content)
     in a file intended to be shared → flag (must be scrubbed or removed).
4. **Verdict:** `SHARE-OK` / `NEEDS-SCRUB` / `DO-NOT-SHARE`, with the specific columns/rows to fix. Gate on any
   CRITICAL (real text or PII in a to-be-shared file).
5. Read-only — recommend fixes (re-run `R/make_sample.R`, drop a column); do not edit the data.

## Note
If R is unavailable here, inspect what you can statically (column names, structure) and hand the row-level
small-cell check to the pipeline machine.
