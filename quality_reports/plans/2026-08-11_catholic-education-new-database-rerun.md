# Plan — re-run and rewrite “Vjera u sadašnjosti, sjećanje u mučeniku”

**Date:** 2026-08-11  
**Study:** `studies/catholic-education/`  
**Authority:** User requested a new analysis using the new database and a full evidence-led rewrite of the paper.

## Goal

Re-estimate the Catholic-education and Stepinac study from the repository's rebuilt official DigiKat corpus,
validate all analytical signals and rewrite the current paper so that its research questions, methods, results,
discussion, limitations, tables, figures and conclusions consistently follow from the refreshed evidence.

## Input and safety contract

- Treat `data/digikat_corpus.rds` and `data/digikat_corpus_manifest.json` as the intended new database. Record
  its path, SHA-256, row count, schema, date range and inclusion rule in a study run manifest.
- Read the new official corpus and the former accumulator-based study outputs without modifying the protected
  corpus, accumulator, production aggregates or page-ready data.
- Do not run a production aggregate replacement or a full-site render. Preserve all unrelated working-tree
  changes and all existing completed-paper assets until the refreshed run passes.
- Keep row-level text, URLs and source identities out of tracked public outputs. Generated public tables and
  figures may contain aggregate results only.
- Preserve the 2021–2025 paper window. Explicitly account for the February–May 2024 vendor text gap and the
  change in collection method around July 2024 when interpreting time trends.
- Reuse the study's operational definitions only after auditing them against the new corpus schema and the
  current paper. Correct methodological or coding defects upstream rather than patching reported values.

## Execution

1. Audit the manuscript source, study scripts, prior outputs and the old-versus-new database contract.
2. Add a fail-closed study input resolver for the official corpus plus a run manifest that prevents silent reuse
   of accumulator-based outputs.
3. Run the complete study analysis in dependency order: entity detection and past anchoring, temporal recurrence
   and peaking, actor/source composition, confessional-versus-secular distribution, affect profiles, paper tables
   and figures.
4. Independently reconcile headline counts, denominators, overlap/incidental rates, temporal patterns, source
   shares and affect summaries; compare old and new findings and flag any construct that does not survive.
5. Rewrite the full paper around the refreshed evidence. Remove every obsolete database description, scalar,
   inference and conclusion rather than preserving the earlier narrative by default.
6. Regenerate standalone HTML/PDF/DOCX and publication assets only through the verified study publisher; update
   the study landing page only if its source can be checked and rendered without a hard-gated full-site render.

## Verification gates

- The selected input's path, SHA-256, dimensions, span and provenance are machine-recorded in the study output.
- Every required analysis script exits successfully against the official corpus and refuses an unintended input.
- All generated tables and figures reconcile with the same refreshed analytical slice.
- No prior accumulator-based number remains in manuscript prose unless explicitly labelled as a comparison.
- All numerical claims in the abstract, results, discussion and conclusion are cross-checked against generated
  tables or a derived-value registry.
- Standalone manuscript rendering succeeds and Croatian UTF-8 diacritics are intact in source and outputs.
- A final disclosure/readiness check confirms that public artifacts contain no row-level restricted content.

## Expected outputs

- Audited and, where needed, updated analysis scripts under `studies/catholic-education/`.
- A reproducible official-corpus run manifest and refreshed aggregate tables/figures under the study output.
- A fully rewritten current manuscript plus checked standalone publication files.
- A concise old-versus-new findings summary, validation status and exact rerun command.
