---
paths:
  - "R/append_new_data.R"
  - "R/load_merge_filter_religious.R"
  - "R/merge_and_save_data.R"
  - "R/load_and_merge_xlsx.R"
  - "R/03_aggregate.R"
  - "data/**"
---

# Data Pipeline Protocol

Protect the gitignored master and the inclusion semantics that DEFINE the corpus. The master
(`data/merged_comprehensive.rds`, ≈610k rows) is irreplaceable and not in git.

1. **Never overwrite the master without a timestamped backup first** (`file.copy(..., overwrite = FALSE)`),
   exactly as `append_new_data.R` already does. Confirm the backup exists before any `saveRDS()` of the master.
2. **Preserve the inclusion contract:** `min_matches <- 2L`, counting DISTINCT term matches. Never change this
   silently — it redefines the corpus and moves every downstream number (HARD GATE: confirm with the user first).
3. **De-duplication** runs on `URL` against the `data_source == "filtered_religious"` half of the master.
   KNOWN GAP: dedup uses the raw URL with no query-string stripping, so `?utm_…` variants survive as duplicates —
   strip query strings before dedup when you touch this.
4. **Schema guardrails:** `FULL_TEXT` must exist (the filter needs it); bind only
   `intersect(names(master), names(new))`; assert no unexpected column drift; report any columns dropped.
5. **Always emit a delta report:** rows before / read / pass-rate / deduped / appended / after.
6. **Aggregates are produced by `R/03_aggregate.R` against the master — never as a render side-effect.**
   A master change invalidates `data/processed/*.rds`, `data/nlp/*.rds`, and the map pages: say so explicitly
   and list what must be regenerated / re-rendered.
7. **Git policy:** the master, `*_backup_*.rds`, `data/raw/**`, and `data/nlp/**` are NEVER committed;
   `data/processed/*.rds` (no PII, CC BY 4.0) STAYS tracked. Never `git add -A`.
8. **If R isn't on this machine** (`R_AVAILABLE = false` in `CLAUDE.local.md`), do not fake a run — emit the
   exact command and hand off to the pipeline machine, then expect refreshed aggregates to be committed.
