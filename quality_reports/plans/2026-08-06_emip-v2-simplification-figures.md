# Plan — simplify PAPER_EMIP_v2 and strengthen its presentation

**Date:** 2026-08-06 · **Study:** `studies/inflation-salience/`

## Goal

Revise `PAPER_EMIP_v2.md` into a clearer economics paper: remove the requested procedural passages,
remove the A/B seam from the paper's argumentative structure, simplify dense prose without losing
economic terminology, and add a small set of reproducible figures that carry the main results.

## Boundaries

- Do not alter the coded data, measured set, or numerical results.
- Do not describe distinct collection procedures as identical unless the evidence establishes that.
- Preserve honest date coverage and limitations that materially affect interpretation.
- Do not touch unrelated existing changes in the dirty worktree.
- Treat manuscript disclosure blocks separately from journal submission requirements; note any required
  material that the working draft no longer contains.

## Steps

1. Audit the manuscript, checks, renderer, generated tables, and existing figure inputs.
2. Rewrite for a simpler academic flow, with conventional sectioning and shorter sentences.
3. Remove the requested corpus/filter wording, validation caveat paragraph, A/B-method discussion,
   declarations, and notes; clean all remaining A/B and seam references.
4. Generate and insert two or three black-and-white figures from tracked study outputs, with titles,
   notes, and sources suitable for the target journal.
5. Update manuscript checks/rendering only where needed, render full and blinded Word files, and run the
   v2 numeric/check suite.

## Verification

- Search for all removed wording and residual A/B/seam terminology.
- Run the v2 paper checker.
- Render both manuscript editions.
- Inspect figure files and final document structure.

## Completion

Completed 2026-08-06. The paper checker passed 30/30. Both Word editions rendered with two
embedded figures, the removal audit found none of the requested passages or A/B terminology, and
the disclosure-screened replication package rebuilt successfully with 64 files.
