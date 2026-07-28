---
paths:
  - "R/00_run_all.R"
  - "R/00_setup.R"
  - "R/01_filter.R"
  - "R/02_merge.R"
  - "R/append_new_data.R"
  - "R/03_aggregate.R"
  - "R/04_nlp.R"
  - "R/religious_terms.R"
  - "R/lib/**"
  - "R/semantic/**"
  - "data/**"
---

# Data Pipeline Protocol

Protect the gitignored master and the inclusion semantics that DEFINE the corpus. The master
(`data/merged_comprehensive.rds`, 710,307 rows × 47 columns at the 2026-07-28 audit) is
irreplaceable and not in git.

1. **Never overwrite the master without explicit user confirmation and a verified timestamped backup first.**
   The active writers stage and validate their result before an atomic replacement; keep that fail-closed sequence.
2. **Preserve the inclusion contract:** `min_matches <- 2L`, counting DISTINCT term matches. Never change this
   silently — it redefines the corpus and moves every downstream number (HARD GATE: confirm with the user first).
3. **De-duplication** uses `canonicalize_url()` from `R/lib/digikat_utils.R`. It removes known tracking
   parameters while retaining query parameters that can identify distinct content; do not replace it with raw-URL
   matching or indiscriminate query stripping.
4. **Schema guardrails:** `FULL_TEXT` must exist (the filter needs it); bind only
   validated master-schema columns; assert no unexpected drift; report every missing, extra, or dropped column.
5. **Always emit a delta report:** rows before / read / pass-rate / deduped / appended / after.
6. **Aggregates are produced by `R/03_aggregate.R` against the master — never as a render side-effect.**
   Preview is the default; `--apply` is the production gate. A master change invalidates
   `data/processed/*.rds`, `data/nlp/*.rds`, the semantic store, and the map pages: say so explicitly
   and list what must be regenerated / re-rendered.
7. **Git policy:** the master, `*_backup_*.rds`, `data/raw/**`, and `data/nlp/**` are NEVER committed;
   `data/processed/*.rds` (no PII, CC BY 4.0) STAYS tracked. Never `git add -A`.
8. **Validate before applying:** run `Rscript R/00_run_all.R --sample`, then the full aggregate preview.
   Do not treat a successful preview as authorization to mutate protected production assets.
