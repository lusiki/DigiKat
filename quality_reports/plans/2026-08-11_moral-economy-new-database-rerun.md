# Plan — re-run and rewrite “Socijalni nauk Crkve u javnoj raspravi o gospodarstvu”

**Date:** 2026-08-11  
**Study:** `studies/moral-economy/`  
**Authority:** User requested a complete re-analysis with the new database and a full rewrite of the paper.

## Goal

Re-estimate the study from the repository's new official DigiKat corpus, validate the refreshed evidence and
rewrite the current RSP manuscript so that its research question, methods, results, discussion, tables, figures
and numerical claims consistently reflect that evidence.

## Input and safety contract

- Treat `data/digikat_corpus.rds` and its tracked manifest as the intended new database unless the schema and
  provenance audit contradict that interpretation. Report its hash, row count, time span and inclusion rule.
- Read both the official corpus and the old accumulator without modifying either. Do not rebuild the corpus,
  overwrite `data/merged_comprehensive.rds`, replace production aggregates or run a full-site render.
- Preserve all unrelated working-tree changes. The existing modification to
  `studies/moral-economy/01_stageA_tag_linkage.R` is user-owned and must be incorporated rather than discarded.
- Preserve the old manuscript and completed-paper artifacts until the refreshed run passes. Keep row-level text,
  URLs, source identities and coding sheets inside the gitignored private/intermediate output classes.
- Reuse an old model-coded decision only after a stable-key join proves that it still refers to the same item and
  coding question in the new corpus. Redraw or recode only where the changed target population makes reuse invalid.

## Execution

1. Audit the database schema and provenance, the RSP manuscript source, the complete study DAG and every cached,
   manually coded or identifier-sensitive dependency.
2. Add an explicit, fail-closed input contract for the official corpus and adapt the Stage A/RSP pipeline so
   refreshed results cannot be confused with the accumulator-based publication run.
3. Run the required analysis stages in dependency order, retaining validation and disclosure gates. Resolve stale
   cache and row-identifier assumptions upstream rather than editing outputs by hand.
4. Independently reconcile population and core counts, era/stream coverage, precision audits, gradient estimates,
   robustness variants, tables, figures and all manuscript scalars. Compare old and new findings.
5. Rewrite the full current RSP manuscript around the refreshed findings, including abstract, theory, data,
   methods, results, discussion, limitations and conclusion. Regenerate table fragments and figures from code.
6. Run the paper checks, disclosure check and standalone manuscript render. Update the publishable paper asset and
   study landing copy only if their source-to-output path can be verified without a hard-gated full-site render.

## Verification gates

- No silent source switch: the selected database path, SHA-256, row count, schema, time span and provenance appear
  in a study manifest or validation output.
- Every analysis script required for the refreshed RSP paper completes successfully against that database.
- Every retained annotation is identity-checked; missing/new items and population-coverage limits are explicit.
- Generated tables and figures reconcile with source CSV/RDS outputs, and no old-database scalar survives in prose.
- `25_paper_checks.R` (updated for the current manuscript if necessary), the standalone render and the repository
  disclosure check pass.
- Croatian UTF-8 diacritics remain intact in source and rendered outputs.

## Expected outputs

- Updated study input contract/scripts and a reproducible run record.
- Refreshed aggregate outputs, validation files, manuscript tables and figures under
  `studies/moral-economy/output/`.
- A fully rewritten current manuscript, preserving the previous version for comparison.
- Checked standalone HTML/PDF publication assets where the existing publisher supports them.
- A concise handoff summarizing the database change, old-versus-new findings, validation status and rerun command.
