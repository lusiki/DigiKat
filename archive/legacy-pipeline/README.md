# Legacy pipeline archive

These scripts preserve the historical development path of DigiKat. They are **not active entry points** and
must not be run against the protected corpus without a separate code review.

## Replacements

| Archived script | Current replacement |
|---|---|
| `load_and_merge_xlsx.R`, `load_merge_filter_religious.R` | `R/01_filter.R` + `R/lib/religious_filter.R` |
| `merge_and_save_data.R` | `R/02_merge.R` (candidate-only) and `R/append_new_data.R` (incremental) |
| `patch_master.R` | no direct replacement; use the verified append workflow and explicit backups |
| `text_analysis.R`, `write_tokens.R` | `R/04_nlp.R` and the analytical Quarto pages |
| `stemmer.R`, `Croatian_stemmer.py` | UDPIPE lemmatization in `R/04_nlp.R`; retained for historical comparison |

Several archived scripts depend on workspace objects, obsolete `./Codes/` paths, or a personal Dropbox path.
Their outputs are not part of the reproducible pipeline described in `REPLICATION.md`.
