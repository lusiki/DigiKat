# Plan — Harden `R/append_new_data.R` (safety-only) + append a new xlsx edition

**Date:** 2026-06-25 · **Owner:** Luka Šikić · **Trigger:** PI wants to append a new batch of
media-article `.xlsx` files to the master under the existing inclusion rule.

## Goal
Append a new `.xlsx` edition to `data/merged_comprehensive.rds` **without** silently corrupting or
losing the master, under the **current** inclusion rule. Make the append script robust enough to run
this and future editions safely (safety scope only; full future-proofing deferred).

## Decisions (confirmed with PI, 2026-06-25)
1. **Inclusion rule: KEEP AS-IS.** New rows filtered by the exact current rule — `match_count =
   length(unique(matched_terms)) >= 2` (distinct regex-row *labels*). No re-filter of the master.
   - Rationale: new data must be consistent with the existing ≈610k master, which was built under this
     rule. Rule-tightening (distinct *roots*; fixing over-broad `gosp/mis/demon/pap`; dead `provincijal`;
     oblique `sveti otac`) is a **separate, planned corpus revision** (HARD GATE) for later.
2. **Hardening scope: SAFETY-ONLY.** Blockers + key highs now; provenance/append-log/dry-run/schema-
   contract/`R/03_aggregate.R`/vectorization deferred.

### Rejected alternatives
- *Fix rule + re-filter master now* — rejected for this batch: corpus-redefining, moves every published
  number, much larger job. Kept as a future option.
- *Build append v2 from scratch* — rejected: the existing script is the right shape; harden in place.
- *Add a `--dry-run` flag* — deferred per scope; instead preview manually at run time (read+filter the
  small new batch and report, without loading the master or overwriting).

## Safety fixes applied to `R/append_new_data.R`
1. **Verified backup, before the bind.** Reorder to backup → verify (return value + `file.exists` +
   size match, abort if the backup name already exists) → `bind_rows` → `saveRDS`. Closes the
   "silent `file.copy` FALSE then overwrite master with no backup" blocker.
2. **Encoding + type guards on read.** Coerce `FULL_TEXT` to character; abort if it is all-NA/empty;
   abort if **no** Croatian diacritic (č ć ž š đ) appears anywhere in `FULL_TEXT` (CP1250 mis-decode
   guard); source `religious_terms.R` with `encoding = "UTF-8"`; coerce `year` to numeric and report NAs.
3. **Whole-master, normalized dedup.** Dedup the new batch against **all** master rows (both strata, not
   just `filtered_religious`) on a **canonicalized** URL (lowercase, strip `?…`/`#…`, strip trailing `/`)
   plus intra-batch dedup. Closes the cross-stratum-duplicate blocker, the `utm_`/query-string gap, and
   the `data_source`-missing idempotency hazard. Rows with no usable URL are kept un-deduped (no silent loss).

## NOT changed (deferred — logged for later)
- Inclusion-rule semantics (term-label vs root; over/under-matching patterns).
- Provenance column, append log, dry-run flag, versioned schema contract, archive-after-run.
- `R/03_aggregate.R` extraction (aggregates still regenerate via `mapa.qmd` render).
- O(rows×terms) loop vectorization (only matters for large batches).

## Run sequence (HARD GATE — only after PI provides the folder path + confirms)
1. Place ONLY the new `.xlsx` in `data/raw/new/` (or point the script at the PI's folder).
2. **Preview** (no write): read the new batch, run the filter, report rows read / pass-rate / schema diff.
3. Confirm with PI → `Rscript R/append_new_data.R` (writes timestamped backup, then master).
4. Post-append: regenerate `data/processed/*.rds` (re-render `pages/mapa/*.qmd`) + re-render affected pages;
   NLP-dependent maps need tokenization re-run. Verify with the `verifier` agent; do NOT stage the master/backup.

## Verification
- Syntax-check the edited script (`parse`).
- At run time: confirm backup exists + size matches before trusting the new master; emit the delta report
  (rows before / read / passed / deduped / appended / after).
