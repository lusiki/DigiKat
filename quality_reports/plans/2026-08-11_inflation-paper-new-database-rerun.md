# Plan — re-run and rewrite “Inflacija, informacije i odgođene promjene cijena”

**Date:** 2026-08-11  
**Study:** `studies/inflation-salience/`  
**Authority:** User requested a complete re-analysis with the new database and a full rewrite of the paper.

## Goal

Re-estimate the study from the repository’s new database, validate every derived sample and result, and
rewrite `PAPER_EMIP_v2.md` so that its question, methods, results, discussion, tables, figures and numerical
claims consistently reflect the refreshed evidence.

## Safety and input contract

- Do not overwrite `data/merged_comprehensive.rds`, rebuild the official corpus, or run any production
  aggregate replacement.
- Identify the intended “new database” from local provenance, manifests, timestamps and study contracts
  before changing the study input.
- Preserve the existing completed-paper artifacts until the refreshed run has passed validation.
- The working tree is already dirty. Preserve all unrelated changes and inspect the existing modification to
  `studies/inflation-salience/_lib.R` before editing it.
- Keep raw/private text out of tracked public outputs.

## Execution

1. Inventory the available databases, their manifests and schemas; compare them with the study’s currently
   pinned accumulator input.
2. Audit the full analysis DAG, frozen coding fixtures, manual annotations and paper synchronization checks;
   adapt only what is necessary for the new input.
3. Run the pipeline from the new database, resolving fixture assumptions that encode the old sample while
   retaining methodological gates and disclosure protections.
4. Independently reconcile funnel counts, time coverage, coded-set joins, tables, figures and manuscript
   scalar claims.
5. Rewrite the full EMIP manuscript around the new results, keeping the journal-oriented economic framing
   only where supported.
6. Run the manuscript checks, render full and blinded outputs, publish standalone assets if safe, and report
   any site artifact that remains intentionally unmodified because a full render requires a hard-gate approval.

## Verification gates

- No silent source switch: input path, row count, time span, schema and provenance are reported.
- All analysis scripts complete successfully against the selected new database.
- Every generated table and figure is internally consistent with the refreshed derived data.
- `10_paper_checks.R --v2` and the end-to-end study runner pass.
- The rendered manuscript preserves Croatian diacritics and contains no stale old-database claims.

## Expected outputs

- Updated study scripts/input contract where necessary.
- Refreshed derived tables, figures and validation reports under `studies/inflation-salience/output/`.
- Fully rewritten `studies/inflation-salience/PAPER_EMIP_v2.md` plus checked rendered manuscript files.
- A concise comparison of old and new findings and a reproducible run command.
