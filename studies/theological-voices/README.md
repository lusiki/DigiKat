# Tko tumači vjeru? — who has taken over the theologian's role

Croatian report in the editorial and analytical method reverse-engineered from the Merkat Media report
"Glasna tema, tiha većina" (2026): three evidence tiers (full corpus, closed list, reviewed sample),
fixed vocabulary (spomen, izjava, glas, tumač, priča), one finding per page, caveats beside findings.
Plan: `quality_reports/plans/2026-10-13_theological-voices-report.md`.

## Input
The OFFICIAL corpus (413 985 × 54), read in place via `DIGIKAT_CORPUS_PATH`; its sha256 is checked
against `data/digikat_corpus_manifest.json` before every stage. On the PI machine the file lives in the
Dropbox project copy, not in `data/`.

## Reproduce (repo root, Windows)
```bash
export DIGIKAT_CORPUS_PATH=".../Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat/data/digikat_corpus.rds"
R="/c/Program Files/R/R-4.6.0/bin/Rscript.exe"
"$R" --vanilla studies/theological-voices/01_discover_names.R   # role-cue name candidates
"$R" --vanilla studies/theological-voices/02_voices.R           # closed list: mentions vs statements
"$R" --vanilla studies/theological-voices/03_sources.R          # groups, top 50, signals, echo
"$R" --vanilla studies/theological-voices/04_sample.R           # 300-post sample + coding batches
"$R" --vanilla studies/theological-voices/05_source_sample.R    # evidence packets for the top 50
# model coding (Claude subagents, CODEBOOK.md) -> output/private/coding/coded_*.jsonl, sources_coded.jsonl
"$R" --vanilla studies/theological-voices/06_report_data.R      # every printed number -> report_data.json
python studies/theological-voices/build_report.py               # Typst -> PDF (Quarto 1.9 bundled Typst)
```
Stages 01–05 are seeded and deterministic. The model coding is not: re-coding gives similar but not
identical sample shares. No human validation of the coding or of statement recognition (PI decision,
2026-10-13); the report says so on every sample page and in Metoda.

## Outputs
- `output/private/report/tko-tumaci-vjeru.pdf` — 34-page report (named people and channels; private).
- `output/private/top50_katolicki_akteri_kodirano.csv` — named top 50 with model-coded channel fields.
- `output/private/voices_summary.csv` — closed-list persons: mentions, statements, sources.
- `output/*.csv` — identity-free aggregates (groups, roles, signals, echo, concentration).

## Caveats that travel with every number
- Source groups describe the CHANNEL, not the speaker. "Svećenički profili" is 97 % one channel
  (pulherissimus), which the model coder could not see an author for.
- Engagement (`INTERACTIONS`) is platform-specific; compare groups only within a platform.
- Statements = name + speech verb within 110 characters in one paragraph; approximate.
- The doctrine keyword list is study-local: the canonical `TEOLOGIJA_I_DOKTRINA` stem `moral`
  also matches the verb *morati*.
