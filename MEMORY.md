# DigiKat — Project Memory (committed; project-shared)

> Project learnings live HERE, not in the user's global `~/.claude/MEMORY.md`. Machine paths → `CLAUDE.local.md`.
> Format: one-line `[LEARN]` entries. Replace the seeds below with real incidents as they occur.

## Key facts
- `data/merged_comprehensive.rds` is gitignored (≈710k rows / 710.307, 47 vars); NOT reproducible from a clean clone.
- `data/processed/*.rds` IS tracked (10 small aggregates, no PII) and is produced ONLY by `R/03_aggregate.R`
  run against the master — NOT by rendering a page. Pages read them. `data/nlp/` output is gitignored.
- Inclusion rule: a post enters the corpus only with ≥2 DISTINCT religious-term matches (`R/religious_terms.R`,
  which has **95** terms — not 93). `FOUND_KEYWORDS` is the vendor monitoring service's NOISY keyword field
  (top value is the conjunction "i"/and), NOT the ≥2-filter evidence — the religious-match columns are not
  retained in the master; describe it honestly, don't present it as filter provenance.
- `data_source` splits the master into two TIME-SEGREGATED streams: `original_dta` (ongoing monitoring query,
  ~269.6k) covers **2021–2024**; `filtered_religious` (≥2-filter backfill, ~440.7k) covers **2024–2026** (overlap
  only in 2024; Instagram/TikTok appear only from 2024). So year-over-year VOLUME is CONFOUNDED by a
  collection-method change ~2024 — the 2025 "surge" (236k) is largely an artifact, NOT rising media attention.
  Do NOT read cross-year trends as real without conditioning on stream + platform (critical for
  `pages/mapa/događaji.qmd` and the new `pages/mapa/evolucija.qmd` "Evolucija ekosustava" layer).
- Corpus is TOPICAL, not source-based: it mixes confessional/Catholic outlets (hkm.hr is #1 at ~8%) and secular
  mainstream media. Indicative outlet-composition (top-source labeling, ~53% classified): ≈27–28% clearly
  confessional; secular/local-news majority; per-platform confessional share YouTube ~42% / Facebook ~37% /
  web ~26% / forums-Reddit ~0%. Frame any such % as indicative (labeling is contestable — PI owns the labels).
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
- [LEARN] mapa.qmd's `data/processed`-writing side-effect is now EXTRACTED (2026-06-30): the in-render
  `data-preparation` chunk is `#| eval: false` ("Superseded by `R/03_aggregate.R`") and the page only READS the
  tracked aggregates in `load-data`. So rendering `pages/mapa/mapa.qmd` is now SAFE — it does NOT read the master
  or write `data/processed/*.rds`. (Aggregates are (re)built by `Rscript R/03_aggregate.R` from the repo root.)
  NB: the auto-mode guard may still block a `quarto render pages/mapa/mapa.qmd` because of the *old* warning text —
  it is render-safe; verify `md5sum data/processed/*.rds` is unchanged afterward to confirm.
- [LEARN] `pages/mapa/mapa_stats.qmd` now RENDERS CLEAN (2026-06-30, rc=0) — the earlier `object 'doc_id' not found`
  failure is resolved now that `data/nlp/mapa_stats_{sample,tokens}.rds` exist (built by `R/04_nlp.R`). diskurs &
  događaji also render clean from `data/nlp/`.
- [LEARN] All `pages/mapa/*` figures share ONE ggplot theme — `R/theme_digikat.R` (sourced after `library(ggplot2)`,
  `theme_set` as default). It exports: `dk_col` tokens (incl. `pos`/`neg`/`neutral`/`alert`, cream `paper`, white
  `panel`), `dk_palette` (16-hue), `dk_platform_colors` (brand-harmonized per platform), `scale_fill/colour_digikat()`,
  `scale_*_digikat_diverging()` (blue=+ / red=−, keeps the "plave/crvene nijanse" prose valid), and
  `theme_digikat_void()` (cream-bg network/empty-plot variant). Do NOT hard-code figure colors/backgrounds or
  `theme_void()`/`theme_graph()` — route through these so figures match the editorial design (cream paper, white panel).

## Known repo issues (Phase 0 backlog — see WORKFLOW_SUGGESTIONS.md)
- `R/text_analysis.R` reads the 3 sentiment lexicons from a phantom `./Codes/` dir → repoint to `resources/lexicons/`.
- `R/write_tokens.R` reads `rules.txt`/`transformations.txt` from a hardcoded Dropbox path → repoint to `resources/lexicons/`.
- ~~`pages/mapa/mapa.qmd` writes `data/processed/*.rds` during render → extract into `R/03_aggregate.R`.~~ DONE
  (2026-06-30): data-prep chunk is `eval: false`; `R/03_aggregate.R` now produces the aggregates.
- `thematic_dictionaries_v3` is copy-pasted across `mapa_stats`/`diskurs`/`događaji` → extract to `R/thematic_dictionaries.R`.
- Duplicate 19 MB udpipe model at repo root AND `resources/models/` → keep `resources/models/` only.
