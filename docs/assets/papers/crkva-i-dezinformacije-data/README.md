# Church-framing paper results

These are the compact, generated inputs and results used by the August 2026 rerun of *Tko govori iz
katoličkoga medijskog prostora*. The run reads the official `data/digikat_corpus.rds` without modifying
it. `official_corpus_manifest.json` and `framing_input_manifest.json` record the exact input fingerprint,
selection rule, row counts and date range. `framing_results_manifest.json` and the CSV files record the
models, prevalence estimates, co-occurrences, interactions and robustness checks used by the manuscript
and study profile.

The large study-local RDS files are retained in the paper source repository and are not duplicated here.
Regenerate these files with `code/01_data_preparation.R` and `code/02_framing_analysis.R` in the
`Church-and-dezinfo` source checkout.
