# DigiKat — Project Memory (committed; project-shared)

> Project learnings live HERE, not in the user's global `~/.claude/MEMORY.md`. Machine paths → `CLAUDE.local.md`.
> Format: one-line `[LEARN]` entries. Replace the seeds below with real incidents as they occur.

## Key facts
- `data/merged_comprehensive.rds` is gitignored (≈710k rows / 710.307, 47 vars); NOT reproducible from a clean clone.
- `data/processed/*.rds` IS tracked (10 small aggregates, no PII) and is produced ONLY by `R/03_aggregate.R`
  run against the master — NOT by rendering a page. Pages read them. `data/nlp/` output is gitignored.
- Inclusion rule: a post enters the corpus only with ≥2 DISTINCT religious-term matches (`R/religious_terms.R`).
- The Quarto site publishes to `docs/` → GitHub Pages.

## Corrections log (seeds — replace with real incidents)
- [LEARN] On Windows, R may default to CP1250; read `.xlsx`/`.txt` as UTF-8 explicitly and assume R ≥ 4.2
  (native UTF-8) or set the locale — otherwise č/ć/ž/š/đ mangle on a second machine. (There is NO mojibake
  bug in `R/stemmer.R`; that file is clean UTF-8.)
- [LEARN] Lowercase with `stri_trans_tolower` BEFORE tokenizing, or "Misa"/"misa" split into different lemmas.
- [LEARN] `append_new_data.R` dedups on the raw `URL` only — it does NOT strip `?utm_…` query strings, so the
  same article with different tracking params survives as a duplicate. (Known gap — strip query strings.)
- [LEARN] Confirm the timestamped backup was written BEFORE the master is overwritten; restore on mid-run error.
- [LEARN] Sentiment lexicons (CroSentilex / CroSentilex Gold / lilaHR) key on lemmas; match on the SAME
  normalization on both sides or join coverage collapses toward 0%.
- [LEARN] Adding a religious root without its case/plural/derivation alternations silently UNDER-matches.
- [LEARN] `pages/mapa/događaji.qmd` has a diacritic (đ) in its filename — don't rename casually; check `docs/` after.
- [LEARN] Run `quarto` from the REPO ROOT, never `cd pages && quarto render x.qmd`. A render with the project
  undetected scatters HTML / root `site_libs/` / `*_files/` beside the sources AND can EMPTY `docs/`; committing
  that wipe + pushing takes the live site down. Recovery: `git checkout -- docs/`, then re-render from root.
  Backstops added 2026-06-25: `.gitignore` makes the scattered output un-stageable, and `git_data_guard.py`
  blocks any `git commit` that would delete ≥3 `docs/**/*.html` pages. Verify post-render anyway (quarto rule §8).
- [LEARN] `freeze: auto` re-executes ALL R chunks on ANY source change (markdown/YAML included), not just code edits.
  So a "prose-only" edit to a data page (`baza`, `pages/mapa/*`) STILL forces full re-execution on render — there is
  no cheap text-only re-render. (2026-06-30: editing mapa-page prose triggered heavy udpipe re-runs.)
- [LEARN] Rendering `pages/mapa/mapa.qmd` RE-RUNS its in-render `saveRDS()` and OVERWRITES all 10 tracked
  `data/processed/*.rds` (clamped to 2025, no tiktok). Confirmed 2026-06-30. Recovery: `git checkout -- data/processed/`.
  Do NOT render mapa.qmd until that side-effect is extracted into `R/03_aggregate.R`.
- [LEARN] `pages/mapa/mapa_stats.qmd` currently FAILS on re-execution (`object 'doc_id' not found`) — render-blocked
  in the current environment (likely a missing `data/nlp/` tokenized dependency). Fix before any Phase-2 full render.

## Known repo issues (Phase 0 backlog — see WORKFLOW_SUGGESTIONS.md)
- `R/text_analysis.R` reads the 3 sentiment lexicons from a phantom `./Codes/` dir → repoint to `resources/lexicons/`.
- `R/write_tokens.R` reads `rules.txt`/`transformations.txt` from a hardcoded Dropbox path → repoint to `resources/lexicons/`.
- `pages/mapa/mapa.qmd` writes `data/processed/*.rds` during render → extract into `R/03_aggregate.R`.
- `thematic_dictionaries_v3` is copy-pasted across `mapa_stats`/`diskurs`/`događaji` → extract to `R/thematic_dictionaries.R`.
- Duplicate 19 MB udpipe model at repo root AND `resources/models/` → keep `resources/models/` only.
