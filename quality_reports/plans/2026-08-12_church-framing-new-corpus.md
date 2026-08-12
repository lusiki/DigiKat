# Rerun the Catholic-media framing paper on the official corpus

## Goal

Replace the published pre-rebuild analysis behind *Tko govori iz katoličkoga medijskog prostora*
with a reproducible run against `data/digikat_corpus.rds`, then update every empirical statement,
table, figure, manuscript format and public study summary that depends on the old data.

## Rationale

The published manuscript uses a frozen derived web corpus ending on 2026-01-06. The official DigiKat
corpus was rebuilt on 2026-08-10 with one inclusion rule across both collection eras and extends to
2026-06-11. The two inputs are not interchangeable. Replacing only the headline corpus count would
misrepresent the analysis, so all frames, models, co-occurrences, time series and robustness checks
must be recomputed.

## Plan

1. Recover and audit the paper source and its data-preparation code from the pinned source repository.
2. Map the official corpus schema to the paper variables without changing the official corpus or its
   inclusion rule.
3. Build a study-local, reproducible derived web corpus from the official corpus. Recompute source
   classifications, eight frame indicators, validation references and all analytical outputs.
4. Compare the new run with the published run. Identify findings that persist, weaken, reverse or can
   no longer be supported.
5. Revise the manuscript prose, abstract, methods, results, discussion, conclusion, captions and
   appendices from computed values. Add an input manifest and corpus fingerprint.
6. Render and verify the paper HTML and PDF. Replace the published paper assets from the revised source.
7. Update the DigiKat study page and studies index from the same computed results. Render only the
   affected site pages and verify links, Croatian encoding and numerical agreement.
8. Run study checks, targeted project tests and a final diff/provenance audit.

## Guardrails

- Read `data/digikat_corpus.rds` through `R/lib/digikat_paths.R` and verify it against
  `data/digikat_corpus_manifest.json`.
- Do not write to `data/merged_comprehensive.rds`, `data/digikat_corpus.rds`, their backups, or
  `data/processed/`.
- Do not preserve an old conclusion when the new estimates do not support it.
- Do not hand-edit generated HTML/PDF. Change the manuscript source and render downstream artifacts.
- Do not run a full-site render. Render only the paper and affected study pages.

## Verification

- Exact corpus path, SHA-256, row count and date range recorded in a study input manifest.
- Every displayed corpus count and estimate traceable to generated tables or inline computation.
- Analysis scripts complete from a clean study-output directory.
- Paper HTML and PDF render successfully.
- Affected Quarto pages render successfully with intact Croatian diacritics and working paper links.
- Old headline numbers and the old 2026-01-06 cutoff are absent from active source and published output.

## Rejected shortcut

Updating the page text while retaining the old manuscript tables and figures was rejected because it
would create a false provenance claim and leave the inferential results tied to the old input.
