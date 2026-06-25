---
paths:
  - "R/**"
  - "pages/**/*.qmd"
  - "resources/lexicons/**"
  - "resources/dictionaries/**"
  - "_quarto.yml"
---

# Croatian Encoding & Diacritics

Croatian text (č ć ž š đ, rich morphology) is the substance of the project. This rule is DEFENSIVE — there
is no known live mojibake bug (`R/stemmer.R` is clean UTF-8); the real risk is locale-dependent reads across machines.

1. **Read every text file as UTF-8 explicitly** — `readxl` (UTF-8 by default), `read.delim(..., fileEncoding =
   "UTF-8")`, `readLines(..., encoding = "UTF-8")`. The existing `read.delim` calls in `R/text_analysis.R` already
   set UTF-8 — keep it.
2. **Pin the locale/version assumption:** assume R ≥ 4.2 (native UTF-8 on Windows) or set `Sys.setlocale`; record
   the R version + locale in the environment snapshot. R on Windows defaults to CP1250 otherwise, so text can
   survive on one machine and mangle on another.
3. **Never** run corpus text through `iconv(..., "ASCII//TRANSLIT")` or otherwise strip diacritics.
4. **Rendered `docs/` HTML must contain literal UTF-8 diacritics**, not numeric entities or boxes.
5. **Diacritic filenames are intentional** (`pages/mapa/događaji.qmd`) — preserve them; quote paths in the shell
   and in `list.files()`.
6. **On any genuine mojibake: STOP and report** the file + byte signature, and confirm against a clean source
   before "fixing" — do NOT assume a bug from a single tool's misread (that false alarm produced a phantom
   "stemmer bug" earlier in this project's tooling).
