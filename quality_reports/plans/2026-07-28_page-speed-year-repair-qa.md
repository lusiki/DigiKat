# Page-speed, year repair, and publication-preparation plan

## Goal

Complete the three approved improvements while leaving the repository in its current
Dropbox location:

1. make the three NLP-heavy analytical pages read small, validated, page-ready summaries;
2. normalize the master `year` field to the calendar year derived from `DATE`; and
3. perform technical and visual QA, then organize the resulting work into coherent local
   commits.

No remote push or publication is authorized by this plan.

## Safety constraints

- Preserve the corpus row set, row order, column order, inclusion rule, and all values
  other than the inconsistent `year` cells.
- Before replacing the master, create and independently verify a timestamped backup.
- Stage the repaired master separately, validate it completely, and replace the master
  atomically.
- Rebuild invalidated downstream artifacts from the repaired master rather than editing
  generated data by hand.
- Keep page-ready summaries free of raw text, titles, URLs, and row-level source identity.
- Prove that the refactored pages receive equivalent plot data and headline metrics before
  switching them to the summaries.
- Render touched pages individually first. Run a full production render only after the
  page-level checks pass.
- Do not move the repository, rewrite Git history, force-push, or push any branch.

## Execution

1. Inventory every data object, metric, table, and figure derived by
   `mapa_stats.qmd`, `događaji.qmd`, and `diskurs.qmd`.
2. Create a deterministic producer for page-ready summaries with an input/output manifest
   and structural validation.
3. Generate summaries from the current NLP generation, compare old and new page inputs,
   and refactor the pages to read only the small outputs.
4. Render each refactored page and compare its important numerical outputs and figures
   with the baseline.
5. Back up the master, repair only `year != year(DATE)`, verify the replacement, and record
   a repair report.
6. Regenerate all downstream aggregates and NLP/page summaries invalidated by the master
   change. Validate semantic-data compatibility and rebuild it only if required by the
   repository contract.
7. Run regression, parsing, disclosure, link, encoding, and full-pipeline checks.
8. Render the full site, inspect representative pages and figures visually, and correct
   any issues found.
9. Review the complete diff and create small local commits grouped by purpose, if the
   existing Dropbox-hosted Git metadata permits safe commits.

## Rejected alternatives

- Keeping the inconsistent master field and correcting it only in page code would leave a
  permanent source-of-truth ambiguity.
- Caching rendered figures without validated summary data would be faster but would make
  analytical reproduction and equivalence harder to audit.
- Repairing the damaged Dropbox-hosted Git object database in place is out of scope and
  riskier than the separately recommended fresh clone outside Dropbox.

