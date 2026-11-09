# Office-register mentions (exploration)

**Question:** how often is each person in the catholic-voices-network Wikidata office register
(1 394 people) named in the official corpus?
**Status:** done 2026-10-26 · **Kill-by:** 2026-11-09 (superseded once the study's own identity stage finishes).

**Inputs (read-only):** `data/digikat_corpus.rds` via the manifest path; the register
`C:/Users/lsikic/Luka C/DigiKat_voices_work/office_register.json`, written by the study run.
Nothing here touches that run's DuckDB database.

**Run from the repo root:**
```
python -I -X utf8 explorations/2026-10-26_office-register-mentions/01_export_register.py "<workdir>/office_register.json"   # from this folder
Rscript --vanilla explorations/2026-10-26_office-register-mentions/02_count_mentions.R
```

**Output:** `output/register_mentions.csv` (gitignored, UTF-8 with BOM for Excel).

**Rule:** a mention is the FULL name with Croatian case endings, one optional middle name allowed.
Surname-only and title-only references are not counted, so counts are lower bounds. Popes use dated
patterns. One-word names are not counted. Common names (Ivan Kovač, Marko Kovač) and names of streets,
schools and airports (Vladimir Nazor, Franjo Tuđman) inflate counts. Nothing is validated by hand.
