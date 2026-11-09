# Plan — Data dictionary for DigiKat (2026-08-04)

## Goal
Create an authoritative, machine-readable data dictionary for all data in the repo, generated
from the data itself (not from memory), and point CLAUDE.md at it. Test: someone who has never
seen the data can reconstruct its meaning without asking the PI a single question.

## Why this shape (rationale + rejected alternatives)
- **Flat CSV variable tables + prose dataset-level block first** — parseable, validatable,
  model-readable. Rejected: a single Word/wiki-style document (not validatable, drifts).
- **Generated stats merged with hand-written semantics** — storage type, missing share,
  n_distinct, ranges come from a read-only R profiling run against the master; only labels,
  descriptions, sources, derivations, roles are hand-written. Rejected: fully hand-written
  dictionary (wrong within two months).
- **A check script (`R/06_dictionary_check.R`)** re-derives the generated columns and compares,
  so the dictionary is an *input* the pipeline validates against, not an output that goes stale.
- Existing `R/05_codebook.R` stays (quick auto-codebook) but the dictionary supersedes it as the
  authoritative reference; the dictionary README says so.

## Deliverables
1. `data/dictionary/DATA_DICTIONARY.md` — dataset-level metadata in prose FIRST (unit of
   observation, grain/keys, population & coverage, collection process, the data_source stream
   confound, weighting = none, known limitations, relationships/join keys, version/provenance),
   then pointers to the CSVs. Explicit prohibitions (e.g. "do not read cross-year volume trends
   as real attention shifts").
2. `data/dictionary/master_variables.csv` — one row per master variable: name, label,
   description, type_storage, type_semantic, unit, allowed_values, missing_codes, role, source,
   derivation, notes + generated: n_missing_share, n_distinct, min, max, examples (PII-safe).
3. `data/dictionary/datasets.csv` — one row per data file/family (master, 14 processed
   aggregates, nlp batches, sample): path, tracked-in-git, produced_by, unit_of_observation,
   grain_keys, rows, cols, license/PII status.
4. `data/dictionary/processed_variables.csv` — one row per (dataset, variable) for the tracked
   aggregates (+ nlp token schema).
5. `R/06_dictionary_check.R` — validates dictionary vs data (column sets agree, types agree,
   missing shares within tolerance); exits non-zero on drift.
6. CLAUDE.md: add the dictionary to the directory conventions + a one-line rule ("consult/update
   `data/dictionary/` when touching schema"). Keep CLAUDE.md < 150 lines.

## PII / disclosure guardrails
- Profiling run is READ-ONLY (readRDS only; no saveRDS of master or processed).
- Example values: real values only for enumerable/safe columns (SOURCE_TYPE, year, data_source,
  outlet names already public in tracked aggregates). FULL_TEXT/TITLE/URL/author-like columns get
  descriptive placeholders, never real content.

## Steps
1. R profiling script → JSON to scratchpad (master + each processed rds + one nlp batch).
2. Author the four dictionary files from profile + pipeline-script reading (03_aggregate.R,
   append_new_data.R, 04_nlp.R, religious_terms.R, MEMORY.md caveats).
3. Write R/06_dictionary_check.R; run it end-to-end → must PASS.
4. Update CLAUDE.md pointer. No commit unless asked.
