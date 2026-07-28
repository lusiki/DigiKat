# DigiKat full housekeeping implementation

**Date:** 2026-07-28<br>
**Status:** approved by the user's request to correct the audit findings<br>
**Scope:** repository code, documentation, project structure, validation, and safe generated-output policy

## Goal

Convert the findings from the 2026-07-28 read-only audit into a safer, reproducible, and easier-to-maintain
project without changing the scientific inclusion rule, silently changing the corpus, or deleting protected
research assets.

The implementation must leave the current master corpus, its backups, the semantic database, and existing
untracked research outputs intact unless a later protected operation is explicitly confirmed.

## Protected operations

The following operations remain separate hard gates:

1. overwriting `data/merged_comprehensive.rds`;
2. deleting or moving any `*_backup_*.rds`;
3. running `R/03_aggregate.R` against the tracked `data/processed/` directory;
4. running a full Quarto render that overwrites `docs/`.

Code for these operations may be repaired and tested against fixtures or temporary output directories before
the gate is crossed.

## Implementation sequence

### 1. Ingestion correctness

- Extract shared URL, date, schema, filtering, manifest, and atomic-write helpers.
- Replace query-string stripping with platform-aware URL canonicalization that preserves identity parameters.
- Make a missing deduplication key fatal unless an explicit override is supplied.
- Add dry-run and delta-report support to incremental ingestion.
- Normalize canonical `DATE` and derive `year` consistently while preserving upstream provenance where useful.
- Stage and validate master writes before atomic replacement.
- Add an ingestion ledger design without writing to the protected master during this task.

### 2. Reproducible derived data

- Make aggregate output a declared manifest covering every required platform.
- Allow aggregates to be generated into a temporary output directory for validation.
- Validate schemas, totals, and output completeness before replacement.
- Add input/output fingerprints and manifests to NLP generation.
- Make semantic preparation IDs stable where possible and write build metadata.
- Make semantic rebuild boolean parsing explicit and rebuild into a new store before a validated swap.
- Repair environment capture and separate reporting from dependency snapshotting.
- Provide a conservative pipeline runner with dry-run/sample modes.

### 3. Public site and documentation

- Make generated corpus coverage text derive from processed data.
- Remove false 2021–2025 / platform-exclusion caveats from source profiles.
- Add an editorial treatment for thin source profiles.
- Correct stale methodology, navigation, repository layout, footer, licensing, and citation documentation.
- Document the optional external Anthropic stage separately from the local semantic workflow.
- Remove or archive stale in-page pipeline code after preserving its historical context.

### 4. Repository organization and disclosure policy

- Quarantine verified legacy/one-off scripts under `archive/legacy-pipeline/` with a clear README.
- Archive the disconnected design prototype and remove its exact duplicate.
- Move unintegrated draft content to an explicitly documented archive area unless it is wired into the site.
- Formalize per-study `private`, `intermediate`, and `public` output directories.
- Strengthen ignore and disclosure checks for row-level CSV/text exports and semantic derived outputs.
- Remove verified root debris and the duplicate root model only after reference and hash checks.

### 5. Verification

- Parse every R file and every executable R chunk.
- Run unit tests for URL canonicalization, dates, filtering, manifests, and disclosure rules.
- Generate aggregates and samples only into temporary locations.
- Confirm aggregate totals reconcile to the fixture or master read-only input.
- Run Quarto checks and a full render in an isolated copy before requesting the protected production render.
- Crawl all generated HTML for missing local files and anchors.
- Confirm no protected data or existing untracked output changed.

## Explicit non-goals

- Do not redefine the `>= 2` distinct religious-term inclusion rule.
- Do not delete the master, backups, semantic database, or raw XLSX source archive.
- Do not rewrite Git history or run Git garbage collection in the Dropbox clone.
- Do not claim that a clean production build is complete until the protected full render has been confirmed and
  executed.

## Alternatives considered

- **Mass deletion based only on reference counts:** rejected because historical research scripts and raw inputs
  carry provenance even when not currently executed.
- **Hand-editing generated HTML:** rejected because `pages/` and generators are the source of truth.
- **Regenerating aggregates immediately:** rejected until the aggregate script can stage and validate a complete
  generation without overwriting tracked outputs.
- **Rebuilding the semantic database in place:** rejected because a failed long-running build would destroy the
  current usable database.
- **Treating all query parameters as tracking:** rejected because platforms such as YouTube encode document
  identity in the query string.

## Completion criteria

- Safety-critical helpers and workflows are tested.
- The repository has one documented, truthful pipeline.
- Public source pages and documentation agree with data manifests.
- Generated and private artifacts have explicit policies.
- Legacy material is archived with provenance instead of silently discarded.
- Temporary validation passes without changes to protected data.
- Any remaining protected operation is listed with the exact command and expected effect.
