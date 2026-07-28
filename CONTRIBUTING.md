# Contributing to DigiKat

Bug reports, documentation corrections, reproducibility improvements, and well-scoped analytical
contributions are welcome.

## Before starting

- Open an issue for a change that affects the corpus definition, public schema, licensing, or site
  information architecture.
- Never attach the master corpus, raw exports, URLs, post text, semantic results, or private study
  coding to an issue or pull request.
- Work from the canonical sources. Do not hand-edit `docs/`, `data/processed/`, generated source-catalog
  pages, or generated manifests.
- Preserve Croatian UTF-8 text and diacritics.

## Development setup

```powershell
Rscript -e "renv::restore()"
Rscript R/00_setup.R
Rscript tests/run_tests.R
Rscript R/check_disclosure.R
Rscript R/00_run_all.R --sample
```

Do not update `renv.lock` implicitly. When a dependency change is intentional, run
`Rscript R/snapshot_dependencies.R --apply` and explain why the package set changed.

## Data and pipeline changes

- Keep the religious inclusion rule at two distinct canonical terms unless the project owner explicitly
  approves and documents a methodological change.
- Use preview mode before `--apply` for master ingestion or aggregate replacement.
- Any production generation must be staged, round-tripped, reconciled, and fingerprinted.
- Add a regression test for a corrected URL, date, filter, schema, or dictionary edge case.
- Row-level study artifacts belong in `studies/<study>/output/private/`.

## Site changes

Render the smallest affected page during development. Before publication, run the full render from the
repository root and crawl internal links:

```powershell
quarto render
Rscript R/check_site_links.R
```

The full render writes `docs/` and should only be performed when production inputs are known to be
current. Do not publish a site rendered from synthetic NLP data.

## Pull-request checklist

- [ ] Change is scoped and documented.
- [ ] `tests/run_tests.R` passes.
- [ ] `R/check_disclosure.R` passes.
- [ ] `R/00_run_all.R --sample` passes.
- [ ] Relevant full-corpus validation passed, or the limitation is stated.
- [ ] Relevant Quarto page/full render and link crawl passed.
- [ ] No restricted, generated, cache, backup, or machine-specific file is staged.
- [ ] Resource provenance and `renv.lock` were updated if dependencies changed.

Project-authored repository materials are currently declared CC BY 4.0. Third-party resources retain
their upstream terms. No separate MIT or other code license should be inferred.
