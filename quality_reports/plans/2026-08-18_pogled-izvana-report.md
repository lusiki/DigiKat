# Plan: „Pogled izvana” report

## Goal

Create a reproducible exploratory report on how non-confessional outlets cover Catholic themes, using the official DigiKat corpus without changing production data.

## Placement decision

The report belongs in `explorations/pogled-izvana-prototype/` as a sibling of `explorations/okvir-katolicanstva-prototype/`. It asks a narrower question, has a different outlet-level universe and requires a PI-ratified sidecar registry. Folding it into the flagship would blur the unit of analysis and make independent promotion or archival impossible.

Shared definitions and computations belong in `explorations/_okvir_engine/okvir_lib.R`. Both prototypes source that library so actor definitions, frames, tonalitet, RIK, event arcs, trend rules and JSON output cannot drift.

## Work

1. Extract the shared analytical engine and re-run the flagship as a regression check.
2. Add the secular-outlet sidecar and generate the private top-source typing queue and coverage diagnostics.
3. Build the full-corpus, supplementary-text-sample, event and trend layers for the new report.
4. Build the standalone Croatian report with five figures, two tables and explicit honesty guards.
5. Run analysis, disclosure checks and browser QA at desktop and mobile widths.

## Guardrails

- Read only from the official corpus and existing resources.
- Write generated material only below each exploration's gitignored `output/`.
- Never read `AUTHOR`.
- Keep text, titles, URLs and row-level samples below `output/private/`.
- Do not link the exploration from production navigation before the 1 September 2026 decision.
- Treat outlet typing and frame labels as indicative until PI ratification and validation.

## Rejected alternatives

- A new section inside the flagship was rejected because its unit of analysis, sampling design and promotion decision differ.
- A production Quarto page was rejected because the brief explicitly keeps the work exploratory until 1 September 2026.
