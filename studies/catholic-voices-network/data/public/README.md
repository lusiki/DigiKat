# Public byproducts of the Catholic voices/network study

These files contain machine-derived public metadata and aggregates. They are not human-validated identities, speech labels or evidence of influence. The full analysis settings and limitations are in the study README, CODEBOOK and report.

- `offices.csv`: dated public office statements potentially overlapping the study period. Date precision is preserved as earliest/latest bounds. `end_basis` distinguishes an office-end qualifier from a death upper bound and an open end. Coverage is incomplete; an open end does not prove current office. Public-register names are source metadata, not claims that those people occur in the corpus.
- `aliases_public.csv`: short, morphologically agreed multiword forms for the frozen D6 population, each supported by at least five contemporary documents. Rare, ambiguous, title-only and non-name-shaped forms are omitted. Counts are per form and must not be summed to infer distinct documents for a person.
- `mention_outlets_edges.csv`: pairs of D6 public identities sharing statistically retained source contexts. Counts refer to distinct internal sources; no private source identifiers are exported.
- `mention_paragraphs_edges.csv`: pairs sharing retained paragraph contexts, with distinct supporting document counts. Low-support ties are omitted from both lists. The exported graph is therefore a disclosure-filtered subset of the internal graph used for community calculations.
- `../../output/platform_coverage.parquet`: identity-free platform totals and the document-length eligibility split. A small cell suppresses its full column family across platforms, including both sides of the eligibility split. This prevents reconstruction from row or corpus totals. The manifest records the schema, hash and disclosure implementation.

No source passages, row-level document identifiers, private accounts or attributed speech are included. The release manifest records file hashes, column allowlists and the source evidence hashes. A future release must be re-audited against its own frozen corpus and settings.
