# CLAUDE.md — DigiKat

**Project:** Prikaz i analiza katoličke tematike u digitalnom medijskom prostoru
**Institution:** Hrvatsko katoličko sveučilište — Komunikologija · **PI:** doc. dr. sc. Luka Šikić
**Scope:** 2025–2027 · CC BY 4.0 · open science (FAIR)
**Repo:** github.com/lusiki/DigiKat · **Site:** https://lusiki.github.io/DigiKat/ (Quarto → `docs/` → GitHub Pages)

DigiKat applies computational social science to map Catholic themes across the Croatian digital media
ecosystem. Empirical core: a ≈610k-row corpus of media posts (2021–2025, Croatian/Bosnian). Two output
streams: (1) reusable open-data infrastructure + the Quarto website; (2) thematic studies / papers.

## Core principles
1. **Plan-first.** Enter plan mode and save a plan before any non-trivial task. The threshold and the
   HARD GATE on master/corpus operations live in `.claude/rules/plan-first-workflow.md`.
2. **Verify-by-render / verify-by-run.** Never report "done" until you have actually verified: a touched
   `.qmd` must `quarto render` clean (build + figures + Croatian diacritics intact); an R change must be
   sourced end-to-end. If R or the data is not on THIS machine, see **Environment** below — hand off, don't fake it.
3. **Single source of truth — data flows ONE way:**
   `data/raw/*.xlsx → religious filter (≥2 distinct matches) → data/merged_comprehensive.rds
   → data/processed/*.rds → pages/**/*.qmd → docs/`.
   Never hand-edit a downstream artifact — fix upstream and re-derive. No hand-typed numbers in prose;
   compute them from `data/processed/*.rds`.
4. **Aggregate-production is an explicit step, NOT a render side-effect.** `data/processed/*.rds` are
   produced by `R/03_aggregate.R` run against the master — never by rendering a page. Pages only READ them.
   (Today `mapa.qmd` still writes them mid-render — a Phase-0 fix; until then, treat any `processed/*.rds`
   change during a render as an accident: do not stage it.)
5. **Protect the irreplaceable.** The master `.rds` (≈610k rows) is gitignored and not reproducible from a
   clean clone. Back it up before any overwrite; never change the ≥2-match inclusion rule silently. The
   git/data guard hook + deny list enforce this.
6. **Croatian correctness is a quality dimension.** Content/UI are Croatian (č ć ž š đ); project docs are
   English. Read text as UTF-8 explicitly; assume a teammate's R may default to CP1250.
7. **Reproducibility-aware & open.** For any pipeline change, state how a teammate re-runs it and from what
   input (master, or the synthetic sample). Aim for FAIR.
8. **[LEARN] tags.** When corrected: project-general → `MEMORY.md`; machine/path-specific → `CLAUDE.local.md`.

## Environment (where things run) — read CLAUDE.local.md
R + the master dataset live on the PI's pipeline machine, NOT necessarily the machine you are on now.
`CLAUDE.local.md` declares `R_AVAILABLE` and the master/model paths for THIS machine.
- **R-running work** (append, aggregate, NLP, analysis): if R + master are present → run + verify; if not →
  emit the exact command and hand it off ("run where R + data live, then commit refreshed aggregates / re-render").
- **Quarto:** content pages render anywhere; **data pages** (`baza.qmd`, `pages/mapa/*.qmd`) need R +
  aggregates/master — without them, verify statically (chunk syntax, `:::` div balance, diacritics in source).

## Directory conventions (authoritative — README.md is OUTDATED; there is NO /code, /publications, /reports)
- `R/` — all R + Python pipeline scripts. (Numbered master `R/00_run_all.R` + `R/0X_*.R` to be built.)
- `pages/`, `pages/mapa/` — Quarto site (`.qmd`); the project's published "outputs".
- `data/raw/` — gitignored `.xlsx`; `data/raw/new/` — incremental drop-folder for appends.
- `data/merged_comprehensive.rds` — master (≈610k × 620), **GITIGNORED**, not in repo.
- `data/processed/*.rds` — **TRACKED** aggregates (no PII, CC BY 4.0); PI-produced, page-read-only.
- `data/nlp/` — gitignored tokenized output. `resources/` — `lexicons/`, `dictionaries/`, `models/` (udpipe).
- `docs/` — rendered site (GitHub Pages); generated — do not hand-edit.
- `studies/` — thematic-study working folders (`_STUDY_TEMPLATE/` + one per study); published pages live in `pages/`.
- `explorations/` — throwaway analyses (sandbox; `output/` gitignored). `references.bib` — shared bibliography.

## Analytical layers (controlled vocabulary — use these names)
1. **Mapa ekosustava** (`pages/mapa/mapa.qmd`) — volume / reach / engagement; actor typology
   (Giants / Community Builders / Megaphones / Specialists).
2. **Tematske struje** (`pages/mapa/mapa_stats.qmd`) — udpipe → 16-category dictionary; 2–5% stratified sample.
3. **Atmosfera diskursa** (`pages/mapa/diskurs.qmd`) — CroSentilex / CroSentilex Gold / lilaHR (8 emotions); conflict index.
4. **Fokus na događaje** (`pages/mapa/događaji.qmd`) — temporal sentiment/theme shifts around events.

## Key commands (Rscript path/availability is machine-specific — see CLAUDE.local.md)
| Command | What |
|---|---|
| `Rscript R/00_run_all.R [--from=NN] [--sample]` | run/rebuild the numbered pipeline (where R + data live) |
| `Rscript R/append_new_data.R` | append `data/raw/new/*.xlsx`; ≥2-match filter; URL dedup; timestamped backup |
| `quarto render pages/mapa/<page>.qmd` | render ONE page (fast; prefer during edits) |
| `quarto render` | full site → `docs/` (before pushing site changes) |
| `quarto preview` | live local preview |

## Auto-loaded rules (`.claude/rules/` — load natively; path-scoped ones load when you touch matching files)
- `plan-first-workflow.md` (always-on) — plan threshold + HARD GATE.
- `data-pipeline-protocol.md` — R pipeline scripts + `data/**`.
- `quarto-verification.md` — `.qmd` / `_quarto.yml`.
- `croatian-encoding.md` — Croatian text (R, qmd, lexicons).
- `exploration-folder-protocol.md` — `explorations/**` (sandbox rules).
Agents (`.claude/agents/`): `verifier`, `r-reviewer`, `numeric-claim-verifier`, `croatian-nlp-reviewer`,
`religion-media-domain-reviewer`. Research config: `.claude/references/discipline-card-digikat.md`.
(Keep this file < 150 lines; detail lives in rules.)

## Memory
- Project learnings: @MEMORY.md (committed `[LEARN]` log — NOT the user's global `~/.claude/MEMORY.md`).
- This machine: `CLAUDE.local.md` (gitignored; auto-loaded after this file) — paths, tool availability, prefs.

## Skill quick reference
`/deploy` (render+verify+publish site) · `/render-page` · `/refresh-data` (safe data append) · `/commit`
`/data-analysis` · `/check-lexicon` · `/review-page` · `/new-study` · `/lit-review` · `/research-ideation`
`/capture-environment` · `/disclosure-check` · `/context-status`
