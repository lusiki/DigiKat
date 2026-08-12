# Rerun the Catholic-influencers paper on the official corpus

## Goal

Replace the published accumulator-era analysis behind *Katolički influenceri i institucionalni
deficit pažnje* with a reproducible run against `data/digikat_corpus.rds`. Update the methods,
results, interpretations, manuscript formats and public study summary wherever the new estimates
change or qualify the old claims.

## Rationale

The published manuscript is pinned to `Katolicki_Influenceri` commit `fa34ff5` and describes more
than 600.000 observations through 2025. The official DigiKat corpus rebuilt on 10 August 2026
contains 413.985 included observations from 2021 through 11 June 2026 under one documented
inclusion rule. Replacing only the headline sample description would leave every test, table,
figure and conclusion tied to the old input. The original manuscript also labels several
operational tests more strongly than their code warrants, so the rerun must distinguish a
rank-size fit from a formal power-law test, mean interactions per post from an audience-normalized
engagement rate, and a dictionary theme proxy from a topic model.

## Plan

1. Recover and audit the pinned source, its actor-classification rules, derived measures and all
   data-dependent prose.
2. Establish a study-local source and reproducible input contract that reads the official corpus
   through `R/lib/digikat_paths.R` and verifies its tracked manifest and SHA-256.
3. Adapt the analysis to the current schema without changing the corpus, its inclusion rule or any
   shared processed data. Recompute descriptive statistics, H1–H5 tests, robustness diagnostics,
   tables and figures.
4. Compare the new estimates with the published claims. Retain, weaken, reverse or reject each
   hypothesis according to the computed evidence, and state design limitations explicitly.
5. Revise the Croatian manuscript from computed values. Align the abstract, methods, results,
   discussion, conclusion, captions and hypothesis summary with the actual implementations.
6. Render and verify standalone HTML, PDF and Word outputs. Replace the published DigiKat paper
   assets from the revised local source and record exact provenance in an input/result manifest.
7. Update the public study profile and studies index from the same results. Render only the affected
   pages and verify numerical agreement, links and literal Croatian UTF-8.
8. Run disclosure checks, targeted analysis assertions and a final diff/provenance audit.

## Guardrails

- Read `data/digikat_corpus.rds` through `R/lib/digikat_paths.R` and verify it against
  `data/digikat_corpus_manifest.json`.
- Do not write to `data/merged_comprehensive.rds`, `data/digikat_corpus.rds`, backups,
  `data/processed/` or the official inclusion logic.
- Treat 2026 as partial and avoid before/after volume claims across the 2024 collection change.
- Do not preserve an old conclusion when the rerun does not support it.
- Do not hand-edit generated HTML, PDF or Word files. Edit source and regenerate downstream outputs.
- Do not run a full-site render. Render only the paper and affected study pages.

## Verification

- The study manifest records corpus path, SHA-256, dimensions, date range, code revision and run time.
- A clean analysis run reproduces every displayed estimate and all manuscript formats.
- H1–H5 decisions are asserted against generated results and match the prose.
- Published HTML, PDF and Word files open successfully and contain the revised corpus description.
- Affected Quarto pages render successfully with intact Croatian diacritics and working format links.
- Old corpus counts, date spans and unsupported method labels are absent from active source and output.

## Rejected shortcut

Updating the public profile and abstract while retaining the old tests, figures and discussion was
rejected because it would create a false provenance claim. Reusing the accumulator was also rejected
because new DigiKat work is required to use the official corpus unless a study has an explicit,
documented reason to stay pinned to a legacy input.

## Publication-readiness extension (2026-08-12)

The official-corpus rerun is the empirical baseline for a second pass requested by the authors. This
pass leaves the literature review and bibliography deliberately under-developed while bringing the
rest of the article closer to journal-submission quality.

1. Re-audit the actor-selection flow, interaction coverage, observational units and all model
   specifications. Make the high-confidence classification the inferential core if the broad
   name-based heuristic proves too heterogeneous for a primary analysis.
2. Replace unstable or mechanically favorable specifications with source-aware estimates,
   uncertainty intervals and transparent sensitivity analyses. Keep descriptive rank-size evidence
   separate from any formal distributional claim.
3. Expand the manuscript's empirical architecture. Add a clear analysis-sample flow, estimand-level
   method descriptions, effect-size interpretation, robustness reporting, alternative explanations,
   practical implications, limitations, and reproducibility/declaration material.
4. Improve figure and table conventions for standalone publication, including consistent Croatian
   number formatting, informative notes, confidence intervals and legible labels.
5. Regenerate the analysis results and every manuscript format, publish the derived assets, update the
   public study profile, and render only that profile page. Verify source/output agreement and scan for
   stale claims, broken references, malformed UTF-8 and disclosure issues.

The pass will not add citations, construct a new theoretical section, or polish the existing
literature list. Any claim that would require new literature support will instead be narrowed or
identified as an author-side literature task.
