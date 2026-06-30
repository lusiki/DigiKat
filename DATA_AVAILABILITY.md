# Data Availability — DigiKat

> Living document. DigiKat is committed to open science (FAIR) under CC BY 4.0, but its empirical core
> includes scraped / API-collected media content that cannot be fully redistributed. This file states,
> per asset, what is shared, what is not, and how to obtain access.

## Summary

| Asset | In repo? | License | Redistributable? | How to get it |
|---|---|---|---|---|
| `data/merged_comprehensive.rds` (master, ≈710k×47) | **No** (gitignored) | — | **No** (full corpus) | On reasonable request to the PI (below) |
| `data/processed/*.rds` (10 aggregates) | **Yes** (tracked) | CC BY 4.0 | **Yes** — aggregate, no PII | clone the repo |
| `data/sample/merged_sample.rds` (synthetic ≈500-row) | Yes, once generated | CC BY 4.0 | **Yes** — scrubbed/synthetic | clone, or `Rscript R/make_sample.R` |
| `data/raw/*.xlsx` (raw scrape / API dumps) | No (gitignored) | source-dependent | **No** | derived from MySQL `determ_all` / source platforms |
| `resources/lexicons/*` (CroSentilex, CroSentilex Gold, lilaHR) | Yes | _TODO: verify upstream; cite originals_ | per upstream | clone; cite original authors |
| `resources/dictionaries/*` (katolički_izrazi, lilaHR) | Yes | _TODO: verify_ | per upstream | clone |
| `resources/models/croatian-set-ud-2.5-191206.udpipe` | Yes | _TODO: verify (UDPipe / Universal Dependencies)_ | per upstream | clone; or download from UDPipe |
| `R/religious_terms.R` (Catholic root-term regexes) | Yes | CC BY 4.0 | **Yes** — citable methodology artifact | clone |
| code (`R/**`, `pages/**`) | Yes | CC BY 4.0 _(code license — PI to confirm MIT vs CC)_ | **Yes** | clone |

## The master corpus
- ≈710,000 media posts (2021–2026), Croatian/Bosnian, across web portals, YouTube, Facebook, Twitter,
  Reddit, and forums; 47 variables. Stored as an R `.rds` (`data.table`).
- **Gitignored** and not in the repository (size + redistribution constraints of scraped/API content).
- **Inclusion criterion:** a post is in the corpus iff it matches **≥ 2 DISTINCT** Catholic root terms
  (`R/religious_terms.R`).
- **Provenance:** assembled from a MySQL database (`determ_all`) and Excel dumps; incremental updates via
  `R/append_new_data.R`.

## How to request access
Researchers may request access for non-commercial research use. Contact the PI:
doc. dr. sc. Luka Šikić — luka.sikic@unicath.hr. Redistribution of full post text is constrained by
source-platform terms; aggregate and derived data are shared openly (CC BY 4.0).

## Pinned dependency (for reproducibility)
- udpipe model: `resources/models/croatian-set-ud-2.5-191206.udpipe`
  - size: **19,236,607 bytes**
  - sha256: `b8e0ad212bdc84c57366bd7267d21810e1fd3239c4d22ca5867f94e76c6cedc7`
  - A byte-identical duplicate currently sits at the repo root — Phase-0 cleanup keeps only `resources/models/`.

## TODO before public release
- Verify and state the exact upstream license for each lexicon/dictionary and the UD model; add citations.
- Confirm the code license (CC BY 4.0 for data + content vs MIT for code).
- Generate and commit `data/sample/merged_sample.rds` (`Rscript R/make_sample.R`), then run `/disclosure-check` on it.
