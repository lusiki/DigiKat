# DigiKat Claude Code Workflow — Tailored Suggestions

*A suggestions document. Nothing here is built yet — it is a menu the PI (Luka) decides from. Every concrete item carries: **what** / **why for DigiKat** / **which guide pattern it adapts** / **priority (P0/P1/P2) + effort (S/M/L)**. The guide referenced throughout is Pedro Sant'Anna's Claude Code workflow guide; the seven designer reports it merges are cited by layer (A–G).*

---

## Refinement decisions — 2026-06-25 (authoritative; re-prioritizes the sections below and supersedes §9 where they differ)

Four scoping decisions from the PI, and how each reshapes the plan:

| Decision | Choice | Effect on the plan |
|---|---|---|
| **Where R runs** | Mixed: this laptop is edit/site; R + master live elsewhere; pipeline runs occasionally | **Environment-flexible skills** (principle below). Drop the "run R locally" assumption everywhere. |
| **Who uses the workflow** | **Just the PI, for now** | **Defer the team layer** (§7.7: `/team-onboarding`, `/coauthor-brief`, team-map, CRediT, `/weekly-synth`). Keep committed `.claude/` + `CLAUDE.local.md` (now the per-env switch). |
| **Scope** | **Everything, incl. the study pipeline** | Build comprehensively; no "lean subset only." |
| **Studies timing** | Some now / soon | **Pull the study/paper stream forward** into the active build. Opus-tier reviewers become relevant when the first study reaches analysis — not "paper-stage someday." |

**New cross-cutting principle — environment-flexible execution (graceful degradation of the *runtime*).** R + the master live on a different machine than this editing laptop, so every R/Quarto skill must detect-then-branch, never assume:

- **`CLAUDE.local.md` is the per-machine switch** — declares `R_AVAILABLE` (true/false) and the master/model paths. Edit-laptop: R absent, master absent. Pipeline machine: both present.
- **R-running skills** (`/azuriraj-podatke`, `R/03_aggregate.R`, `/data-analysis`, NLP): if R+master present → run + verify; if absent → emit the exact command + a hand-off note ("run where R+data live; commit the refreshed aggregates / re-render"). Never fail silently.
- **Quarto skills** (`/objavi`, `/render-page`): content pages render anywhere; **data pages** (`baza.qmd`, `pages/mapa/*.qmd`) need R + aggregates/master — on the edit laptop they get *static* verification (syntax, div balance, diacritics in source), per the env-constraints memory.
- **Synthetic `data/sample/` is PROMOTED** (was P1): it's what lets the edit laptop actually render data pages and smoke-test the pipeline without the restricted master.
- **Day-1 fixes**: the path repoints + `saveRDS` extraction + dict extraction are *text edits* (do them anywhere, incl. here); **verifying** them by running needs R+master (do that where they live). `renv::init`/snapshot also runs where R lives — commit the lockfile.

### Revised roadmap (replaces §9)

**Phase 0 — Unblock & hygiene** *(text edits here; verify where R+master live)*
1. Repoint `R/text_analysis.R` `./Codes/` → `resources/lexicons/` (unblocks the whole "atmosfera diskursa" sentiment layer).
2. Repoint `R/write_tokens.R` Dropbox path → `resources/lexicons/`.
3. Extract the `saveRDS()` calls out of `pages/mapa/mapa.qmd` (lines 100–168) into `R/03_aggregate.R` (render stops mutating tracked data).
4. Extract `thematic_dictionaries_v3` from the 3 qmd pages → `R/thematic_dictionaries.R` (kills page-to-page drift of the 16 categories).
5. Delete the duplicate root `croatian-set-ud-2.5-191206.udpipe` (keep `resources/models/`).
6. Make `.gitignore` intent explicit: ignore `*_backup_*.rds` + `data/raw/new/`; keep `data/processed/*.rds` tracked.
7. `renv::init()` + commit `renv.lock` *(where R lives)* — pins `stringi`/ICU so the `≥2-match` corpus definition can't drift.

**Phase 1 — Constitution & safety skeleton** *(here)*
- Full `CLAUDE.md` (§1.1) with the env-flexibility principle baked in.
- `CLAUDE.local.md` as the per-env switch (`R_AVAILABLE`, master/model paths) — one per machine, gitignored.
- `.claude/settings.json` (`defaultMode: plan`, allowlist, `plansDirectory`) + the git/data-guard hook (interpreter-resolved for Windows).
- `MEMORY.md` seed (flat list).
- 3 core path-scoped rules: `data-pipeline-protocol`, `quarto-verification` (incl. no-side-effect + env-branch on data pages), `croatian-encoding` (defensive + locale assertion).

**Phase 2 — Operational skills + agents** *(env-flexible)*
- Skills: `/objavi`, `/render-page`, `/azuriraj-podatke`, `/commit`, `/context-status` — all run-or-handoff.
- Agents: `verifier` (haiku), `r-reviewer` (sonnet); wire `verifier`→`/commit`, `r-reviewer`→`/data-analysis`.
- Numbered master `R/00_run_all.R` (00–04).
- Remaining P1 rules (`r-code-conventions`, `single-source-of-truth`, `croatian-nlp-conventions`) as incidents arise.

**Phase 3 — Reproducibility & FAIR** *(core open-science goal)*
- `/capture-environment` (renv + udpipe SHA-256 + R version/locale).
- **Synthetic `data/sample/` + `--sample` mode** (promoted — enables local data-page render + CI smoke-test).
- `DATA_AVAILABILITY.md`, `REPLICATION.md`, auto-`CODEBOOK.md`, `/disclosure-check`, backup-prune script.

**Phase 4 — Study / paper stream** *(active now)*
- `discipline-card-digikat.md` (descriptive tilt; APA/Chicago; HR+EN venues — stops scholar skills defaulting to AER).
- `studije/` + `_STUDY_TEMPLATE` + `/novo-istrazivanje`; exploration-folder workflow.
- Skills: `/data-analysis`, `/provjeri-leksikon`, `/review-page`, `/lit-review`, `/research-ideation`; scholar-skill wiring (eda / compute / qual / citation / write / ethics / open).
- `/review-paper` + opus reviewers (`croatian-nlp-reviewer`, `religion-media-domain-reviewer`, `devils-advocate`) when the first study reaches analysis.
- `references.bib` (Better BibTeX, APA/Chicago); per-study declarations (data-availability + AI-use); OSF prereg only if Study 3 turns confirmatory.
- MCP: perplexity (lit-review + Croatian fact-check), Google Drive (data/doc access), Gmail (drafts only).

**Deferred — until the team adopts / project Year 2**
- Team layer: `/team-onboarding`, `/coauthor-brief`, team-map, `scholar-collaborate`/CRediT, `/weekly-synth`.
- Constitutional governance (project Year 2 / Phase 3).
- On trigger: `targets` (if the NLP layer branches), git worktrees (risky multi-day refactor), `R/check_claims.R` (if formal provenance is ever wanted), simulated peer review (submission, Phase 5–6).

---

## 0. Fit assessment — how DigiKat differs, and where the leverage is

The guide is engineered for a **solo econometrician shipping lecture slides** (Beamer/LaTeX/TikZ, Quarto-revealjs, DiD/IV identification, AEA replication packages, journal referees). DigiKat is a different animal on almost every axis:

| Guide assumption | DigiKat reality | Consequence |
|---|---|---|
| Beamer/LaTeX/TikZ slides | A **Quarto website** rendered to `docs/`, served by GitHub Pages | "Compile" = `quarto render`, not `xelatex`. Drop the entire LaTeX/TikZ/slide stack. |
| "Compile clean" verification | Render clean **+ Croatian diacritics (č ć ž š đ) intact** in `docs/` **+ no tracked data clobbered by the render** | Encoding correctness and render side-effects are quality dimensions with **no guide analogue**. |
| Econometric identification | **Descriptive / interpretive** sociology-of-religion + Croatian computational text analysis | Domain reviewers, paper types, and prereg norms all re-point to `descriptive`. No DiD/IV/RDD. |
| Solo PI | **10 researchers**, most non-coders, across 3 faculties, 3 years, 6 phases | Collaboration, handoff, shared committed config (PI-configures-once), and a why-history matter far more. |
| English monolingual | **Bilingual**: Croatian content/UI + English project docs | Skills, memory tags, and reviewers must be diacritic-aware and bilingual. |
| Clone-and-reproduce | Empirical core (`merged_comprehensive.rds`, 610k rows, 620 vars) is **gitignored and partly non-redistributable**, and the *only* producer of the shared aggregates needs it | "Clone and run" is impossible without a data-access story; reproducibility is the project's biggest structural gap. |
| AER-grade ceiling (18 agents / 52 skills) | Working mid-build infrastructure project, CC BY 4.0, Zenodo not AER | Adopt a **fraction**; progressive adoption; avoid over-engineering. |

**The highest-leverage opportunities for THIS project (re-ranked after verification):**

1. **Fix three broken scripts and decouple aggregate-production from rendering.** This is the single most valuable first move — it costs an afternoon and is worth more than the entire rules/agents/skills apparatus. Concretely: repoint `R/text_analysis.R` (five `./Codes/...` reads, lines 5–41, of the three sentiment lexicons that drive the entire "atmosfera diskursa" layer) and `R/write_tokens.R` (Dropbox path, lines 38–39) to the in-repo `resources/lexicons/`; and move the `saveRDS(.../data/processed/*.rds)` calls out of `pages/mapa/mapa.qmd` (lines 100–168) into a PI-run `R/03_aggregate.R`. Until this is done, no second person can run anything, and `quarto render` silently **mutates 10 git-tracked `.rds` files**. (Layers F, A)
2. **A lean `CLAUDE.md` constitution built on the one-way data lineage** (`raw → merged_comprehensive.rds → processed/*.rds → pages → docs`) as the single source of truth. The repo genuinely has this DAG, and `data/processed/*.rds` is **tracked** while the master is gitignored — so the SSoT principle is real and enforceable. The constitution must also encode the directory truth, since the README is outdated. (Layer A)
3. **`renv` dependency pinning, on Day 1.** ICU/`stringi` version drift can silently change which posts pass the `≥2` filter via `stri_trans_tolower` — i.e. dependency drift can silently alter the *corpus definition*. This is a higher-stakes, lower-effort win than most rules or agents. (Layer F)
4. **Protecting the irreplaceable gitignored master** (timestamped backups, the `≥2 distinct-term` inclusion contract, URL dedup) via a path-scoped rule + a PreToolUse git/data guard hook. Losing or silently re-defining the corpus is the worst-case failure. (Layers A, B, E)
5. **A claim-reconcile flag** so hard-typed numbers in Croatian prose ("preko 610.000 objava", "web čini oko 80 posto") don't go stale when an append batch runs. *Scope correction:* these numbers live in `PROJECT_DESCRIPTION.md` and **two** `mapa/*.qmd` pages (`mapa.qmd`, `mapa_stats.qmd`) — **not** in `README.md` (which contains none of them), and not across four pages. (Layers D, E, F)
6. **Defensive encoding correctness** as a path-scoped rule. *Correction from the prior draft:* there is **no live mojibake bug** — `R/stemmer.R` line 2 is clean UTF-8 (`budeš/ću/želim`). The earlier "shipping today" claim was the prior tooling corrupting bytes on read, not a repo defect. The rule is still worth having defensively, but it is **not** the highest-ROI item and is **not** justified by an existing bug. The real, verified encoding risk is locale-dependent reads on a second teammate's Windows machine (CP1250), addressed in §2.1/§6.x. (Layers A, B, D)
7. **Collaboration plumbing for 10 non-coders**: a committed PI-owned `.claude/`, a `/coauthor-brief` skill that includes the gitignored-data fetch recipe, and the three live MCPs (perplexity, Google Drive, Gmail) wired with graceful degradation. (Layer G)

A cross-cutting principle inherited from the guide: **command hooks flag, rules judge, agents review.** Keep the enforcement layer mechanical and cheap; leave judgment to Claude and the researcher.

---

## 1. Constitution & memory (`CLAUDE.md`, `MEMORY.md`, `CLAUDE.local.md`)

### 1.1 `CLAUDE.md` — the DigiKat constitution

- **What:** A lean (~120-line, hard cap 150) always-loaded constitution. Core principles, folder map, key commands, the four analytical layers as controlled vocabulary, project state, and a skill quick-reference table.
- **Why for DigiKat:** The instruction budget is real; the team is 10 people; and the constitution must encode the one-way data lineage, the directory truth (README is wrong), and the honest reproducibility caveat (master is gitignored; only the PI can refresh aggregates). Detailed standards live in `.claude/rules/`.
- **Adapts:** Guide Art. I (single source of truth), verify-after-compile, quality gates, customization tables — re-pointed from Beamer/econ to the data-pipeline + Quarto reality.
- **Priority/effort:** **P0 / M.** *(A ~60-line Day-1 stub is enough at first — see §9; the fuller version below fills in during Week 1.)*

Draft (trim to fit; skill names are placeholders owned by §3):

```markdown
# CLAUDE.md — DigiKat
**Project:** Prikaz i analiza katoličke tematike u digitalnom medijskom prostoru
**Institution:** Hrvatsko katoličko sveučilište — Komunikologija
**PI:** doc. dr. sc. Luka Šikić · Team: 10 · 2025–2027 · CC BY 4.0
**Repo:** github.com/lusiki/DigiKat · Site: lusiki.github.io/DigiKat

## Core Principles
1. **Plan-first** for any non-trivial task (pipeline change, new analysis,
   schema/lexicon/filter edit): enter plan mode, save the plan before editing.
2. **Verify-by-render** — never "done" until `quarto render` of touched page(s) succeeds
   AND Croatian diacritics (č ć ž š đ) are intact in docs/. R changes: source end-to-end first.
3. **Single source of truth** — data flows ONE way:
   data/raw/*.xlsx → religious filter (≥2 distinct) → data/merged_comprehensive.rds
   → data/processed/*.rds → pages/**/*.qmd → docs/.
   Never hand-edit a downstream artifact. Fix upstream and re-derive.
4. **Aggregate-production is a PI-only step, NOT a render side-effect.**
   data/processed/*.rds are produced by R/03_aggregate.R run against the master
   (which only the PI holds). Pages only READ them. Never regenerate processed/*.rds by
   rendering a page; never `git add` processed/*.rds churn caused by a render.
5. **Reproducibility-aware** — the master .rds is gitignored and ~610k rows. Any pipeline
   change must state how a teammate re-runs it and from what input (master or synthetic sample).
6. **Croatian correctness is a quality dimension** — content/UI Croatian, docs English.
   Read text files as UTF-8 explicitly; assume Windows defaults to CP1250 (see rules).
7. **Quality bar** (judged at MERGE, in plain words, not a numeric rubric):
   a touched page must render; numbers must trace to data; the master must be backed up
   before any overwrite. A teammate should be able to reproduce shipped work.
8. **[LEARN] tags** — when corrected: project-general → MEMORY.md; machine/path → CLAUDE.local.md.

## Directory conventions (authoritative — README is OUTDATED; there is NO /code, /publications, /reports)
R/ all R+Python pipeline scripts. R/00_run_all.R + R/0X_*.R = numbered master (to be built).
pages/, pages/mapa/ Quarto site (.qmd) — the project's "outputs".
data/raw/ gitignored .xlsx; data/raw/new/ incremental drop-folder.
data/merged_comprehensive.rds master (610k×620, GITIGNORED).
data/processed/*.rds TRACKED aggregates (CC BY 4.0, no PII) — PI-produced, page-read-only.
data/nlp/ gitignored tokenized output. resources/ lexicons/, dictionaries/, models/ (udpipe).
docs/ rendered site (Pages) — generated, do not hand-edit.

## Key Commands
| <Rscript> R/00_run_all.R [--from=NN] [--sample] | run/rebuild the numbered pipeline (PI) |
| <Rscript> R/append_new_data.R | append data/raw/new/*.xlsx; dedups URL; timestamped backup; ≥2-match |
| quarto render pages/mapa/<page>.qmd | render ONE page (fast; prefer during edits) |
| quarto render | full site → docs/ (before pushing site changes) |
> <Rscript> = full quoted path on this machine; Rscript is NOT on PATH. See CLAUDE.local.md.

## Analytical Layers (controlled vocabulary)
1 Mapa ekosustava (mapa.qmd) — volume/reach/engagement; actor typology
2 Tematske struje (mapa_stats.qmd) — udpipe → 16-category dictionary; 2–5% stratified sample
3 Atmosfera diskursa (diskurs.qmd) — CroSentilex / CroSentilex Gold / lilaHR (8 emotions); conflict index
4 Fokus na događaje (događaji.qmd) — temporal sentiment/theme shifts around events

## Skill Quick Reference
/objavi (deploy site) · /azuriraj-podatke (refresh data) · /render-page · /commit
/provjeri-leksikon (validate terms) · /novo-istrazivanje (new study) · /coauthor-brief · /graphify

> Keep ≤150 lines. Standards live in .claude/rules/. Machine paths in CLAUDE.local.md (gitignored).
> Hooks invoke a resolved interpreter (python OR python3); see .claude/hooks/.
```

### 1.2 Always-on rules set (keep few)

- **What:** Three lean always-on rules; the research orchestrator is **path-scoped** (not always-on).
- **Why for DigiKat:** Stays inside the ~100–150 instruction budget; a 10-person incremental data project does not benefit from per-commit scoring or a heavy multi-agent loop.
- **Priority/effort:** **P0 / S.**

| Guide always-on rule | DigiKat verdict |
|---|---|
| `plan-first-workflow.md` | **KEEP**, slim to ~40 ln; **data-aware threshold** + destructive-action hard gate (below). |
| `orchestrator-protocol.md` (heavy multi-agent loop) | **DROP from always-on; REPLACE** with the path-scoped simplified research loop (§2). |
| `session-logging.md` | **KEEP**, slim to ~15 ln; merge-only logs. Valuable for 10-person/3-year handoff. |
| `prompt-shaping.md` | **KEEP** as-is (~20 ln). High value for terse bilingual asks. |
| `meta-governance.md` (template machinery) | **DROP.** DigiKat is a working project, not a fork-template. |

`plan-first-workflow.md` — the DigiKat threshold and hard gate (the dangerous operations here are *mutating the master* and *changing what enters the corpus*):

```markdown
--- (always-on; no paths) ---
# Plan-First Workflow
Enter plan mode and save a plan to quality_reports/plans/YYYY-MM-DD_desc.md before:
- ANY change to the religious-terms filter (R/religious_terms.R) or the ≥2-match rule — changes WHAT is in the corpus.
- ANY change to a lexicon/dictionary (resources/lexicons/**, resources/dictionaries/**) or the 16-category scheme.
- Rebuilding the master, large append batches, or editing R/03_aggregate.R (it regenerates the tracked processed/*.rds).
- New analytical page or thematic study (pages/**, data flow, _quarto.yml nav).
Fast-track (skip planning): one-page typo, CSS tweak, single-page re-render, one new chart on an existing page.
HARD GATE — confirm with the user before: overwriting data/merged_comprehensive.rds,
deleting a backup_<timestamp>.rds, running R/03_aggregate.R (overwrites tracked processed/*.rds),
or a FULL `quarto render` that overwrites docs/.
```

`orchestrator-research.md` — path-scoped, replaces the heavy loop:

```markdown
--- paths: ["R/**/*.R","R/**/*.py","pages/**/*.qmd","explorations/**"] ---
# Research Orchestrator (simplified)
Loop: IMPLEMENT → VERIFY → DONE. No multi-agent fan-out, no review rounds.
VERIFY depends on what changed:
 - R script  → source end-to-end (PI: on real data; others: on data/sample); print row counts / dedup deltas / NA scans.
 - .qmd page → quarto render <that page>; confirm build + diacritics; confirm NO processed/*.rds were rewritten.
 - filter/lexicon → ALSO report how many rows/matches changed, and which processed/*.rds + pages are now stale.
DONE = verified + (if shipping) numbers trace to data + Croatian correct.
```

### 1.3 Memory — three coexisting tiers

- **What:** A clean division between the user's existing global index and DigiKat's team brain.
- **Why for DigiKat:** Luka already runs a global `~/.claude` memory index; DigiKat learnings must reach the *whole team* on `git pull`, and machine paths differ per teammate.
- **Priority/effort:** **P1 / S** (create files + seed in Week 1, not Day 1); ongoing.

| File | Scope | Committed? | Holds |
|---|---|---|---|
| `~/.claude/MEMORY.md` (existing global) | All projects | personal | Cross-project habits. **No DigiKat-specific [LEARN] entry leaks here.** |
| `MEMORY.md` (repo root) | DigiKat, all teammates | **YES** | Project-general [LEARN] log: Croatian NLP gotchas, pipeline/render quirks, lexicon caveats. |
| `CLAUDE.local.md` (repo root) | DigiKat, this machine | **NO (gitignored)** | Absolute paths, R/Quarto versions, where the master .rds lives, personal effort prefs. |

**Conflict rule** (state in `MEMORY.md` header): *"Project memory lives here in the repo, not in `~/.claude/MEMORY.md`."*

Add to `.gitignore`: `CLAUDE.local.md`, `.claude/settings.local.json`, `quality_reports/session_logs/` (keep `quality_reports/plans/` **tracked**).

Seed `MEMORY.md` entries (plausible, clearly tagged; team replaces with real incidents). *Note: a flat seed list is fine — defer the six-category `[LEARN]` tag taxonomy until MEMORY.md has >10 real entries (it's premature abstraction now).*

```markdown
# DigiKat — Project Memory (committed; team-shared)
> Learnings live HERE, not in ~/.claude/MEMORY.md. Machine paths go in CLAUDE.local.md.
## Key Facts
- merged_comprehensive.rds is gitignored (~610k rows); not reproducible from a clean clone.
- data/processed/*.rds IS tracked (10 small aggregates) and is produced ONLY by R/03_aggregate.R
  run against the master — NOT by rendering a page. Pages read them. data/nlp/ output is gitignored.
- Inclusion rule: a post needs ≥2 DISTINCT religious-term matches (R/religious_terms.R).
## Corrections Log (seeds — replace with real incidents)
- [LEARN] On Windows, R may default to CP1250; read .xlsx/.txt as UTF-8 explicitly and assert R >= 4.2
  (native UTF-8) or set Sys.setlocale, or č/ć/ž/š/đ mangle on a second machine. (NOTE: this is the REAL
  encoding risk — there is NO mojibake bug in R/stemmer.R; that file is clean UTF-8.)
- [LEARN] lowercase with stri_trans_tolower BEFORE tokenizing or "Misa"/"misa" split into different lemmas.
- [LEARN] append_new_data.R dedups on raw URL only — it does NOT strip ?utm_… query strings, so the same
  article with different tracking params survives as a duplicate. Strip query strings before dedup (real gap).
- [LEARN] Confirm the timestamped backup was written BEFORE the master is overwritten; restore on mid-run error.
- [LEARN] CroSentilex/lilaHR use different word forms; match on the SAME normalization or coverage collapses to ~0%.
- [LEARN] religious-terms regexes are morphology-aware; adding a root without case/plural alternations under-matches.
- [LEARN] pages/mapa/događaji.qmd has a diacritic filename (đ); don't rename casually; check docs/ after.
- [LEARN] Render one mapa/*.qmd at a time during edits; full-site render is slow and hides which page broke.
- [LEARN] Numbers in a .qmd derive from data/processed/*.rds at render time — never hand-typed.
```

`CLAUDE.local.md` seed (gitignored) — note the **verified machine facts**: Quarto is on PATH, `Rscript` is **not**:

```markdown
# CLAUDE.local.md — Luka's Windows machine (gitignored)
## Paths
- Repo root: C:\Users\lsikic\projects\DigiKat
- Master (gitignored): C:\Users\lsikic\projects\DigiKat\data\merged_comprehensive.rds
- udpipe model: C:\Users\lsikic\projects\DigiKat\resources\models\croatian-set-ud-2.5-191206.udpipe
## Tool versions / invocation
- Quarto: on PATH.
- Rscript: NOT on PATH. EITHER add R to PATH (preferred — makes the allowlist work) OR always call:
  & "C:\Program Files\R\R-4.x.x\bin\Rscript.exe" R/00_run_all.R
- Python: C:\Python314\python.exe (no python3 alias on this machine).
## Prefs
- Default effort: medium. Bump to high for filter/lexicon/aggregate changes (corpus-wide impact).
```

---

## 2. Path-scoped rules (`.claude/rules/`)

Start with **3 always-relevant rules** on Day-1/Week-1 (encoding, data-pipeline, quarto-verification); add the rest **only as a real incident motivates each**. The numeric quality-gate rubric is replaced by three plain sentences (see §2.5). Glob mechanics: Claude's matcher uses **forward-slash globs regardless of OS**, so all globs use `/` even on Windows.

```
.claude/rules/   (the first three are the core; the rest are add-on-demand)
├── data-pipeline-protocol.md     # P0 — pipeline scripts + data/**  (protects the master)
├── quarto-verification.md        # P0 — *.qmd, _quarto.yml  (render-before-done + no-side-effect render)
├── croatian-encoding.md          # P0 — everything touching Croatian text  (DEFENSIVE — no live bug)
├── r-code-conventions.md         # P1 — R + qmd analysis chunks  (add when first incident hits)
├── single-source-of-truth.md     # P1 — data/**, R/**, pages/**/*.qmd
├── croatian-nlp-conventions.md   # P1 — NLP scripts + lexicons/dictionaries
└── exploration-folder-protocol.md# P1 — explorations/**  (see §7.2)
```

### 2.1 `data-pipeline-protocol.md` — **P0 / M** *(the highest-value rule)*
- **What:** Protect the gitignored master and the inclusion semantics that define the corpus; codify what `append_new_data.R` already does so it survives a rewrite.
- **Why for DigiKat:** The master is irreplaceable; silently re-defining the corpus moves every downstream number.
- **Adapts:** Guide §5.5 replication-first ("match the spec exactly, STOP on mismatch"), re-pointed to "match the corpus-inclusion contract."
- **Directives:** (1) Never overwrite `merged_comprehensive.rds` without a timestamped backup first (`overwrite=FALSE`). (2) Preserve `min_matches <- 2L` with **distinct** counting. (3) Preserve URL dedup against the `filtered_religious` half only; **flag that dedup is on raw URL with no query-string stripping — `?utm_…` variants survive as duplicates** (known gap; fix when touched). (4) Schema guardrails: `FULL_TEXT` must exist; bind only `intersect(names(master), names(new))`; assert no column drift. (5) Always emit `rows before / appended / after` + filter pass-rate. (6) **Aggregate-production lives in `R/03_aggregate.R`, run against the master by the PI — never as a render side-effect.** A master change invalidates `processed/*.rds`, `nlp/*.rds`, and the map pages. (7) Master/backups/raw/nlp never committed — but **`data/processed/*.rds` stays tracked.**
- **Glob:** `R/append_new_data.R`, `R/load_merge_filter_religious.R`, `R/merge_and_save_data.R`, `R/load_and_merge_xlsx.R`, `R/03_aggregate.R`, `data/**`.

### 2.2 `quarto-verification.md` — **P0 / S**
- **What:** DigiKat's "compile before done" gate: a touched page must `quarto render` clean before "done", **and the render must not mutate tracked data.**
- **Why for DigiKat:** The website is the deliverable; the unique failure modes are mojibake, missing figures, and — the architectural one the prior draft missed — **a render that overwrites the 10 git-tracked `data/processed/*.rds`** (because `mapa.qmd` currently calls `saveRDS()` into them mid-render, lines 100–168).
- **Adapts:** Guide §3.4.2 verification-protocol + §8.5.2 "Quarto Won't Render" (Beamer/xelatex dropped).
- **Directives:** (1) Render the touched page before reporting done. (2) Figures actually render (no empty `<img>`, no chunk error in HTML). (3) Diacritics display in rendered HTML. (4) No new broken cross-refs/nav links — the `href: ""` "Tematska istraživanja" placeholders are **intentional stubs**, flag-don't-fail; never introduce *new* empty hrefs. (5) **Render must be side-effect-free on `data/`.** Until the `saveRDS` calls are extracted from `mapa.qmd` (see §0/§6.2), treat any change to `data/processed/*.rds` during a render as a render artifact: do **not** stage it; warn loudly. After extraction, no page may write into `data/` at all. (6) **Atomicity:** a render that errors after some `saveRDS` calls but before others leaves a partially-updated tracked dataset — until extraction, verify all-or-nothing (or stage to a temp dir) before touching `docs/`/`processed/`. (7) Pages reading the gitignored master **cannot render on a clone without it** — pages must read `data/processed/*.rds` (or the synthetic sample), not the master.
- **Glob:** `pages/**/*.qmd`, `R/*.qmd`, `_quarto.yml`.

### 2.3 `croatian-encoding.md` — **P0 / S** *(defensive — NOT justified by a live bug)*
- **What:** Diacritic/encoding correctness as an invariant across R, qmd, lexicons, `_quarto.yml`.
- **Why for DigiKat:** Croatian text is the substance. *Correction:* the prior "highest-ROI because of a shipping `R/stemmer.R` mojibake bug" framing was **wrong** — that file is clean UTF-8. The **real** portability risk is locale-dependent reads: R on Windows defaults to CP1250 unless R ≥ 4.2 (native UTF-8) or an explicit `encoding=`/`fileEncoding=`/`Sys.setlocale`, so diacritics can survive on the PI's machine and mangle on a teammate's.
- **Directives:** (1) Read every text file as UTF-8 explicitly (`readxl`; `fileEncoding="UTF-8"`; the `read.delim` calls in `text_analysis.R` already do this — keep it). (2) **Pin the locale/version assumption:** assert R ≥ 4.2 or set the locale; record it in `/capture-environment`. (3) Never `iconv(..., "ASCII//TRANSLIT")` corpus text. (4) Rendered `docs/` HTML must contain literal UTF-8, not `&#269;` entities or boxes. (5) Diacritic filenames (`događaji.qmd`) are intentional — preserve, quote in shell/`list.files()`. (6) On any genuine mojibake: **STOP and report** file + byte signature; confirm against a clean source before "fixing" — **do not assume a bug from a single tool's read** (that error produced the phantom stemmer "bug").
- **Glob:** `R/**`, `pages/**/*.qmd`, `resources/lexicons/**`, `resources/dictionaries/**`, `_quarto.yml`.

### 2.4 `r-code-conventions.md` — **P1 / S** *(add when first portability/repro incident hits)*
- **What:** R house style for a 610k×620 Croatian-text `data.table`.
- **Adapts:** Guide §4.2.1, re-pointed to big-`data.table` + Croatian text.
- **Directives:** (1) **One dated seed** `set.seed(YYYYMMDD)` at top; flag the existing `set.seed(123)` in `pages/mapa/*.qmd` on next edit (don't silently rewrite published output). (2) `library()` at top in `suppressPackageStartupMessages({...})`. (3) `data.table` for the master, dplyr for processed frames. (4) **Relative paths from repo root only** — `here::here()`; no `setwd()`, no `C:/Users/...`, no `./Codes/`. (5) `stringi` over base regex; `stri_trans_tolower`, never `tolower()`. (6) Memory discipline: load once, `rm()`+`gc()`, never `saveRDS()` the master from inside a render. (7) UTF-8 + locale assertion (§2.3). (8) No script may read from or write to a path outside the repo.
- **Glob:** `R/**/*.R`, `pages/**/*.qmd`, `R/*.qmd`.

### 2.5 Quality bar — three sentences, NOT a scoring rubric
*Critique accepted:* an 11-row deduction rubric (`-20/-15/-10/-5/-3`) is econometrics-referee theater for a sociology website, and "applied at merge" on a repo whose history is `weiter`/`los` means applied never. Replace the rubric with three plain sentences, stated in `CLAUDE.md` and enforced by the hooks/agents that already exist:

> **(1)** A touched page must `quarto render` clean (build + diacritics + figures) and must not clobber tracked `data/`. **(2)** Every number in shipped prose must trace to a `data/processed/*.rds` (or the master) computation, not be hand-typed. **(3)** The master must be backed up before any overwrite, and the `≥2 distinct` inclusion rule must not change silently.

### 2.6 `single-source-of-truth.md` — **P1 / S**
- **What:** Encode the DAG; derived artifacts always regenerate (via `R/03_aggregate.R`, not via render); no hand-typed numbers in prose.
- **Directives:** (1) The DAG is authoritative. (2) Regenerate, never hand-edit `processed/*.rds`/`nlp/*.rds`/`docs/`; **and `processed/*.rds` regenerates only via `R/03_aggregate.R`, never by rendering a page.** (3) No hand-typed numbers in qmd prose — counts/percentages/top-N come from inline R computed from `processed/*.rds` (preferred, clone-friendly). (4) One inclusion definition (`religious_terms.R` + `≥2`). (5) The processed tier is the clone-friendly source for the site.
- **Glob:** `data/**`, `R/**`, `pages/**/*.qmd`.

### 2.7 `croatian-nlp-conventions.md` — **P1 / M**
- **What:** Linguistic-correctness rules generic R review can't catch.
- **Directives:** (1) Morphology-aware regex review — new term ships `term`/`root`/`regex` (equal-length vectors), reviewed for over-/under-matching, tested against a sample. (2) Diacritic invariant (inherits §2.3). (3) Lexicon join-key integrity — lowercase with `stri_trans_tolower`, diacritic-preserving on both sides; report join coverage; a silent collapse to ~0% means an encoding mismatch. (4) Lemma vs token vs stem discipline — sentiment lexicons key on **lemmas**. (5) **Pin the udpipe model** by exact filename `croatian-set-ud-2.5-191206.udpipe`; never silently `udpipe_download_model()`. (6) Stopword provenance cited. (7) Document the stratified sampling fraction (2–5%), strata (platform × year), seed.
- **Glob:** `R/religious_terms.R`, `R/stemmer.R`, `R/Croatian_stemmer.py`, `R/text_analysis.R`, `R/write_tokens.R`, `resources/lexicons/**`, `resources/dictionaries/**`, `resources/models/**`.

### 2.8 Consolidations and rule drops

**Folded in / dropped from the guide:**

| Guide rule | Verdict |
|---|---|
| `verification-protocol.md` | Folded → `quarto-verification.md` + `data-pipeline-protocol.md`. |
| `cross-artifact-review.md` | Folded → `single-source-of-truth.md` + the "numbers trace to data" sentence. Re-promote standalone only when the thematic *papers* acquire real manuscripts (Phase 4, P2). |
| `quality-gates.md` (numeric rubric) | **DROPPED** — replaced by §2.5's three sentences. |
| `tikz-*` (visual/prevention/measurement) | No TikZ; figures are R/ggplot in qmd chunks. |
| `beamer-quarto-sync.md`, `no-pause-beamer.md` | No Beamer; the only "sync" that matters (qmd→docs/) is in quarto-verification. |
| `pdf-processing.md` | No PDF corpus; lexicons are TSV/TXT/XLSX. |
| `stata-code-conventions.md` | No Stata. |
| `r-package-conventions.md` | DigiKat is **not a package**; transferable bits in r-code-conventions. |
| `simulation-conventions.md` | No Monte Carlo today. |
| `knowledge-base-template`, `content-invariants`, `summary-parity`, `proofreading-protocol`, `model-routing`, `confidential-data` | Paper-stage / template / over-engineered. The one real invariant ("master/raw/nlp never committed") is in data-pipeline-protocol. |

---

## 3. Skills (`.claude/skills/<name>/SKILL.md`)

Ship **2–3 skills first**, with whatever single name the PI actually types. *Critique accepted:* building Croatian+English aliases for ~12 skills and a shared `${CLAUDE_SKILL_DIR}` diacritic helper before any skill exists is premature abstraction — add aliases only when a real teammate is confused, and inline the diacritic check until ≥3 skills share it.

### P0 — the recurring operational loop

**`/objavi`** — **P0 / M.** *What:* render the whole site to `docs/`, verify diacritics + figures + broken links, **assert no `data/processed/*.rds` changed during the render** (warn hard if it did), stage `docs/` for Pages. *Why:* the site is a primary deliverable; `docs/` is committed; and a full render currently also rewrites 10 tracked aggregates. *Adapts:* guide §8.2 `/deploy`. *Steps:* pre-flight `quarto --version` + processed-tier presence (warn if master absent — pages should read processed, not master) → record git status of `data/processed/` → `quarto render` → re-check `data/processed/` git status; **if changed, STOP and report** (this means the saveRDS calls are still in a page) → mojibake grep + known-string check → figure-dir non-empty per page → internal-link scan (catch `href: ""` stubs) → PASS/WARN/FAIL table; **do not auto-commit.**

**`/azuriraj-podatke`** — **P0 / M.** *What:* safely wrap `R/append_new_data.R` with guardrails + a structured delta report. *Why:* the single highest-risk recurring action — it overwrites the gitignored master in place. *Steps:* pre-flight the script's own `stop()` conditions → record master `nrow/ncol` + backup count → **run via the resolved `Rscript` path** (full quoted path, since `Rscript` is not on PATH — see §5.0/A4) → confirm a new `_backup_<timestamp>.rds` → parse into rows before/read/**pass-rate**/deduped/appended/after → sanity-flag wild pass-rate → **mandatory reminder that aggregates are now stale: run `R/03_aggregate.R` (PI) to regenerate `data/processed/*.rds`, then `/objavi`.**

**`/render-page`** — **P0 / S.** *What:* render+verify **one** map page. *Why for DigiKat:* the consumers (`mapa_stats`/`diskurs`/`događaji`) read `data/processed/*.rds` + `data/nlp/*.rds`; rendering against stale aggregates yields wrong figures. *(After the §6.2 extraction, `mapa.qmd` is a pure consumer too.)* *Steps:* resolve arg (accept ascii `dogadaji` → `događaji.qmd`) → warn if `processed/*.rds` older than the master and tell the PI to run `R/03_aggregate.R`; for `diskurs`/`događaji` confirm `data/nlp/*.rds` non-empty → render → verify (chunk errors, figures, diacritics) → **confirm no `data/processed/*.rds` changed.**

**`/commit`** — **P0 / S.** *What:* quality-gated stage → commit → optional PR with Conventional-Commit messages. *Why:* current history is `weiter`/`los`; the gate must block accidental commits of the master / raw xlsx / `.udpipe`, but **keep `data/processed/*.rds` tracked**. *Steps:* status/diff + branch check → **block** on staged `merged_comprehensive*.rds`, `*backup*.rds`, `data/raw/**/*.xlsx`, `*.udpipe`, >50 MB → **warn** on `processed/*.rds` changes (these are a *render side-effect today, an `R/03_aggregate.R` output tomorrow* — never a hand-edit; confirm the source) → diacritic gate → draft type-scoped message → commit → optional `gh pr create`. Wires in `verifier` (§4).

Sample message (vs `weiter`): `data: append Q2-2025 batch to master (+8,412 rows, 14.3% pass-rate)`.

**`/context-status`** — **P0 / S.** Port from guide §8.2 unchanged.

### P1 — analysis, study scaffolding, lexicon QA, review

**`/data-analysis`** — **P1 / M.** End-to-end R analysis on a corpus slice: explore → aggregate / score on a **stratified 2–5% sample** by default → figure+table to `output/{figures,tables}/<slug>/` → hand to `r-reviewer`. *Adapts:* guide §5.9.3, retargeted to Croatian computational text analysis. Never dumps 610k rows into context.

**`/novo-istrazivanje`** — **P1 / M.** Scaffold one of the 5 planned thematic studies under `studije/<slug>/` and fill the matching empty `href: ""`. *Adapts:* guide §8.2 `/create-lecture` → create-study.

**`/provjeri-leksikon`** — **P1 / M, read-only.** Sanity-check `R/religious_terms.R` regexes + the 3 lexicons against a Croatian fixture: every regex compiles; encoding check; coverage against inflected forms (biskup/biskupa/biskupi; misa/mise/misi; hodočašće/hodočašća); false-positive scan (`red…`, `gosp…`, `put…`); lexicon integrity. Recommends fixes; does not edit.

**`/review-page`** — **P1 / M, read-only.** Single-pass multi-lens review of one website page before publishing: claims-vs-data, clean render, Croatian prose + diacritics, a11y. **Disambiguation:** `/review-page` = a *website* page; `/review-paper` = a *manuscript*. *(No critic⇄fixer auto-loop — see §4 B3.)*

### Research/paper stream — thin wrappers over installed `scholar-skill:*` (delegate, don't rebuild)

- **`/lit-review` (P1 / S)** → `scholar-lit-review` + perplexity MCP for Croatian-venue coverage.
- **`/review-paper` (P2 / M)** → `scholar-respond --simulate`, **`descriptive` methods-referee tilt** (sampling frame, lexicon validity, representativeness of the 2–5% sample, false-positive rate of the term filter, encoding integrity) — **not** DiD/IV.
- **`/research-ideation` (P2 / S)** → `scholar-idea`/`scholar-hypothesis`.

### Ports — keep as-is

- **`/learn` (P1 / S)** — captures DigiKat gotchas into `MEMORY.md`.

### Skills to DROP

| Guide skill | Why |
|---|---|
| `/compile-latex` | No LaTeX. |
| `/extract-tikz`, `/new-diagram`, `/translate-to-quarto` | No TikZ; site is Quarto-native. |
| `/visual-audit`, `/slide-excellence`, `/pedagogy-review`, `/qa-quarto` | Lecture-slide machinery; substance folded into `/review-page` + `/objavi`. |
| `/stata-replication`, `/r-package-check` | No Stata; not a CRAN package. |
| `/did-event-study`, `/power-analysis`, `/simulation-study` | Causal-econometrics; DigiKat is descriptive. |
| `/syllabus`, `/teach-from-paper`, `/scaffold-exercises` | No teaching deliverable. |
| `/seven-pass-review`, `/deep-audit` | Heavyweight; defer to `scholar-skill`. |
| `/preregister`, `/replication-package`, `/audit-reproducibility`, `/capture-environment` | Reach for `scholar-skill` equivalents at submission. *Exception:* a lightweight `/capture-environment` IS recommended in §6 (renv + udpipe SHA + locale) — build that scoped-down version. |

---

## 4. Agents / reviewers (`.claude/agents/*.md`)

*Critique accepted:* the deliverable right now is a website + infrastructure build, not manuscripts. **Day-1/Week-1 needs exactly two agents:** `verifier` (mechanical, haiku) and `r-reviewer` (correctly called "the highest-value reviewer"). Everything opus-tier moves to Phase 4 when papers exist. All read-only agents pin `tools: ["Read","Grep","Glob","Bash"]` (+ `disallowedTools: ["Write","Edit"]`); only the fixer gets `Write`/`Edit`. Reviewers set `maxTurns` (8–15) and write to `quality_reports/<target>_<agent>.md` with `Critical/Major/Minor` severity.

| Agent | Model / effort | RO/RW | Priority/effort | Core job |
|---|---|---|---|---|
| `verifier` | haiku / low | RO | **P0 / S** | Mechanical: did render/Rscript exit 0; do expected `docs/` exist; was a backup created; **did the render leave `data/processed/*.rds` unchanged**. |
| `r-reviewer` | sonnet / medium | RO | **P0 / M** | R quality/repro/portability/perf on 610k `data.table`. |
| `numeric-claim-verifier` | sonnet / medium | RO | P1 / S | Fresh-context re-derivation of headline numbers from data; cannot self-confirm. |
| `quarto-page-critic` | sonnet / high | RO | P2 / M | Single-pass adversarial page audit (no auto-loop). |
| `croatian-nlp-reviewer` | opus / high | RO | **P2 / L** *(paper-stage)* | 5-lens review of Croatian computational text analysis. |
| `religion-media-domain-reviewer` | opus / high | RO | **P2 / M** *(paper-stage)* | Substantive hostile-referee on claims. |
| `devils-advocate` | opus / high | RO | P2 / M | Study-design teardown (first thematic paper). |

**`r-reviewer` (P0 / M)** — the highest-value reviewer; the pipeline is the project. *Real catches already in the repo:* `R/text_analysis.R` reads **five** files from `./Codes/...` (lines 5, 13, 26, 40, 41 — the three sentiment lexicons; this phantom directory blocks the **entire** "atmosfera diskursa" layer, the highest-value of the path bugs); `R/write_tokens.R` reads `rules.txt`/`transformations.txt` from a hardcoded `C:/Users/Lukas/Dropbox/...` (lines 38–39); `load_merge_filter_religious.R` `stop()`s on an un-sourced global `religious_terms` and runs an O(rows×terms) per-row loop over 70+ regexes × 610k rows; `mapa_stats.qmd` filters drop NA rows without a logged count; **`mapa.qmd` writes tracked `data/processed/*.rds` during render** (lines 100–168 — flag for extraction into `R/03_aggregate.R`). *Checks:* portability (no absolute/`./Codes/`/Dropbox paths; `here::here()`), reproducibility (`set.seed`; flag missing `renv`), silent data loss (log rows-in/out per filter), performance (flag per-row loops; vectorize), encoding hand-off (flag any `read.*` lacking `encoding`; assert R ≥ 4.2 / locale), **render side-effects (flag any `saveRDS` into `data/` from a `.qmd`).**

**`verifier` (P0 / S)** — mechanical pass/fail, haiku-cheap. Adds the DigiKat-specific check the prior draft missed: **after any render, assert `git status` shows no change to `data/processed/*.rds`** (a changed aggregate means a render had a data side-effect).

**`numeric-claim-verifier` (P1 / S)** — re-derives DigiKat's headline numbers (610k rows, 620 vars, 95 terms so "70+" is conservative-true, 16 categories, 2021–2025, platform shares) and reports match/mismatch. Can verify *without* the master using git-tracked anchors: `length(religious_terms$term)` (=95), `length(thematic_dictionaries_v3)` (must = 16), platform shares from `data/processed/platform_summary.rds`/`proportions_summary.rds`/`top_*_sources.rds`. If the master is absent, reports "unverifiable on this clone" rather than guessing.

**`croatian-nlp-reviewer` (P2 / L, paper-stage)** — *the* DigiKat domain reviewer when manuscripts exist; the guide's 5-lens framework re-pointed to encoding integrity, morphology/regex coverage, lexicon join validity, tokenization/lemmatization, and sampling representativeness. **The single highest-impact systemic catch it surfaces** — and worth acting on *before* paper stage — is that `thematic_dictionaries_v3` is **copy-pasted inline** across `mapa_stats.qmd`, `događaji.qmd`, and `diskurs.qmd`; if they drift, the "16 categories" differ page-to-page. *Structural fix (do this in Week 1, no opus reviewer needed):* extract to `R/thematic_dictionaries.R` sourced everywhere.

**Skill wiring:** `/commit` → `verifier`. `/data-analysis` → `r-reviewer`. `/review-page` → `quarto-page-critic` + `numeric-claim-verifier` (single pass). A `/review-study` (P2) → `religion-media-domain-reviewer` + `croatian-nlp-reviewer` + `devils-advocate` once papers exist.

**Agents dropped:** `slide-auditor`, `tikz-reviewer`, `pedagogy-reviewer`, `beamer-translator`, `sim-reviewer`, `r-package-reviewer`. **Deferred (conditional return):** `quarto-page-fixer` (the critic⇄fixer auto-loop with a 5-round cap is over-engineered for single-page web edits — re-add only if page edits get genuinely complex); `editor` + `methods-referee` + 2× `referee` return when a study targets a journal (Phase 5–6).

---

## 5. Hooks, settings, permissions, model/effort routing

This layer is deliberately small and Windows-correct.

### 5.0 Windows portability verdict (gates everything)
Verified facts and the corrections they force:
- **`Rscript` is NOT on PATH.** A `Bash(Rscript *)` allow rule never matches `& "C:\Program Files\R\...\Rscript.exe"`, so the daily-loop skills would silently fail on the PI's own machine (A4). **Resolve one of two ways and pick ONE everywhere:** (preferred) make "add R to PATH" a documented setup prerequisite, then the bare `Bash(Rscript *)` allow works; OR standardize on the full quoted path in every skill/allowlist. The draft below assumes R-on-PATH-as-prerequisite.
- **`python3` does not exist on this machine; `python` does.** But 2 teammates are on Mac/Linux where `python` may be `python3`-only. **Don't hardcode either** — hooks resolve the interpreter (test `python` then `python3`, or use a tiny launcher) rather than assuming `python` (C4).
- `chmod +x` is a **no-op on Windows** (skip it). Use `$CLAUDE_PROJECT_DIR` (expands cross-platform) and quote paths.

Hook command template (interpreter resolved, not hardcoded):

```json
"command": "python \"$CLAUDE_PROJECT_DIR/.claude/hooks/_run.py\" <name>"
```
where `_run.py` is a 5-line launcher that falls back to `python3` if invoked as `python` fails, or hooks shebang `#!/usr/bin/env python3` on POSIX. The point: no team laptop silently fails to fire a guard hook.

### 5.1 `.claude/settings.json` — permissions + modes
- **What:** committed, team-shared allow/deny + `plansDirectory` + `defaultMode`.
- **Priority/effort:** **P0 / S.**

```jsonc
{
  "permissions": {
    "allow": [
      "Bash(Rscript *)", "Bash(R -e *)", "Bash(R CMD *)",   // requires R-on-PATH (setup prereq); else use full-path allow
      "Bash(quarto render *)", "Bash(quarto preview *)", "Bash(quarto check *)",
      "Bash(git status *)", "Bash(git diff *)", "Bash(git log *)",
      "Bash(git add *)", "Bash(git commit *)", "Bash(git push)",
      "Bash(git pull *)", "Bash(git fetch *)", "Bash(git branch *)", "Bash(git checkout -b *)", "Bash(git stash *)",
      "Bash(gh pr *)", "Bash(gh issue *)", "Bash(gh repo view *)",
      "Bash(ls *)", "Bash(rg *)", "Bash(wc *)", "Read", "Grep", "Glob"
    ],
    "deny": [
      "Bash(git push --force *)", "Bash(git push -f *)", "Bash(git reset --hard *)",
      "Bash(git clean -f*)", "Bash(git clean -d*)", "Bash(rm -rf *)"
    ],
    "defaultMode": "plan"
  },
  "plansDirectory": "quality_reports/plans",
  "hooks": { /* §5.2 */ }
}
```

No `xelatex`/`pdflatex`. No `sync_to_docs.sh` (Quarto's `output-dir: docs` is the publish; commit `docs/` directly). `git add *` is gated through the guard hook (§5.2.1) — a blanket `git add` deny would block all staging.

### 5.2 Permission-mode strategy — `plan` for everyone, NO bypass on the path
*Critique accepted (A5/D2):* scheduling `bypassPermissions` and the guard hook on the same day is a sequencing error, and bypass is dubious for a team that "can't eyeball whether an R edit will corrupt the master." **Recommendation: keep `defaultMode: plan` for everyone, including the PI, and do not document a `bypassPermissions` path at all** until the guard hook has run and been tested for at least several days. If the PI later wants unattended execution, that is a deliberate, later, gitignored `.claude/settings.local.json` opt-in — never Day-1. The safety boundary is the deny list + guard hook (which fire in every mode), not plan approval. **P0 / S.**

### 5.2.1 The high-value hooks

**Git + data guardrails — PreToolUse[Bash] — P0 / S (the one Day-1 hook).** A single resolved-interpreter script protecting the irreplaceable assets: the gitignored master, the timestamped backups (the only undo for a bad append), and the committed `docs/` site. Block patterns (match **both** `/` and `\`, case-insensitive): `git reset --hard`, `git clean -*f`, `git push --force/-f`, `git add -A|--all|.`, `rm …merged_comprehensive`, `rm -rf …data/`, `rm -rf …docs/`, `(rm|mv) …_backup_<stamp>.rds`. Exit code **2** with a fix message. *Adapts:* guide §4.8.4, extended to DigiKat's *data* artifacts.

**Claim-reconcile — PostToolUse[Edit|Write] — P1 / M (narrowed).** *Verified, corrected scope:* the headline numbers live in `PROJECT_DESCRIPTION.md` and **two** qmd pages (`pages/mapa/mapa.qmd`, `pages/mapa/mapa_stats.qmd`) — **README.md has none**, and it is **not** four pages. *Behavior:* on edit to `R/**/*.R` (esp. `append_new_data.R`, `load_merge_filter_religious.R`, `religious_terms.R`, `merge_and_save_data.R`, `R/03_aggregate.R`), grep a small magic-number set (`610`, `620`, `16`, `80 posto`, `2021`) across **`PROJECT_DESCRIPTION.md` + `pages/mapa/mapa.qmd` + `pages/mapa/mapa_stats.qmd` only** and inject a reminder listing stale-claim locations. Mechanical flag, no LLM. *Lower urgency than the prior draft billed* — P1, not the Day-1 second hook.

**Session-log autowriter — Stop — P1 / S.** Auto-writes a one-line session-log entry to `quality_reports/session_logs/YYYY-MM-DD_<slug>.md`. Valuable because commit history is `weiter`/`los`.

**Context survival — PreCompact + SessionStart[compact|resume] — P1 / S.** Saves/reprints the active plan path + task. The `mapa/*.qmd` files are large; render-debug fills context fast.

**OPTIONAL render-verify — make it a skill, NOT an auto-hook — P2.** Auto-rendering on Stop would hang non-data sessions and could mutate tracked aggregates. Use the on-demand `/render-page`; a lightweight `quarto check` in the allowlist covers config validation.

### 5.3 Model/effort routing (70/20/10)
Baseline Opus 4.8 (1M, effort `high`); don't bump to `xhigh` except for genuinely hard runs.

| Tier | Model / effort | DigiKat work |
|---|---|---|
| ~70% Haiku 4.5 (low/med) | `haiku` | `verifier`, lexicon/TSV reformatting, `git status`/grep, qmd front-matter/nav fixes, renames. |
| ~20% Sonnet 4.6 (high) | `sonnet` | `r-reviewer`, encoding checker, `numeric-claim-verifier`, `quarto-page-critic`. |
| ~10% Opus 4.8 (high) | `opus` | `croatian-nlp-reviewer`, `religion-media-domain-reviewer` (paper-stage only). |

Cost note: the expensive path is **rendering heavy pages + NLP** (compute, not tokens).

### 5.4 Constitutional governance — DEFER, but pre-draft 4 Articles — P2.
Do **not** adopt on day one (codify only after 3–7 patterns *emerge*). Adopt at the **Year-2 transition (start 2026, Phase 3)**. Pre-drafted Articles ready to drop into `.claude/rules/constitution.md`: **I — Primary Artifact** (master produced *only* by `load_merge_filter_religious.R`/`append_new_data.R`; aggregates *only* by `R/03_aggregate.R`, never a render); **II — Verification = render + numeric-trace + no-data-side-effect**; **III — File Organization**; **IV — Plan-First Threshold**. Skip a numeric "Quality Gate ≥80" Article (consistent with dropping the rubric in §2.5).

---

## 6. Reproducibility & data architecture (FAIR / open-science)

This is DigiKat's single biggest real gap. There is no `renv`, no master script, three broken-path scripts, and — the architectural problem the prior draft missed — **the only producer of the "shareable FAIR tier" (`data/processed/*.rds`) is a render of `mapa.qmd` against the gitignored master**, so those tracked aggregates are effectively frozen artifacts only the PI can refresh, and any teammate who renders either fails (no master) or clobbers them.

### 6.1 Dependency pinning — `renv` on Day 1 — P0 / S–M
*Critique accepted (D3):* `renv` moves to **Day 1**, before any rule, because ICU/`stringi` drift can silently change which posts pass the `≥2` filter — i.e. dependency drift can silently alter the corpus definition. That is higher-stakes and lower-effort than most rules/agents.
- **`renv.lock`** pinning R version + the package set (data.table, tidyverse, **stringi**, udpipe, readxl, quarto, here, yaml). `.gitignore` adds `renv/library/` but **keeps** `renv.lock`, `renv/activate.R`, `renv/settings.json`, `.Rprofile`.
- **Python (P1 / S):** a 3-line `requirements.txt` or one-line `PYTHON_VERSION` note for the stdlib-only stemmer. No `uv.lock` for one rule-based file.

### 6.2 MASTER orchestration — numbered scripts, NOT `targets` — P0 / M
**Decision: a numbered master (`R/00_run_all.R` + `R/0X_*.R`), not the `targets` package.** The DAG is linear/shallow; expensive outputs are already on-disk `.rds`; the team is social scientists. Revisit `targets` only if a branching experiment grid appears (P2). **The aggregate step is where the render-side-effect gets fixed:**

```
R/00_setup.R     renv::restore(); here::i_am(); set.seed(2025); source("R/religious_terms.R"); assert R>=4.2/locale
R/01_filter.R    wraps load_merge_filter_religious.R (≥2 distinct-match filter)
R/02_merge.R     wraps merge_and_save_data.R → saveRDS(data/merged_comprehensive.rds) (idempotent)
R/03_aggregate.R produce data/processed/*.rds  ← THE saveRDS calls EXTRACTED from mapa.qmd live here (PI-run)
R/04_nlp.R       udpipe tokenize + stemmer + 16-cat theme + 3-lexicon sentiment → data/nlp/*.rds (EXPENSIVE; file.exists guard)
R/00_run_all.R   MASTER: source 00..04 in order; honour --force / --from=NN / --sample; log to logs/
```

**Three broken scripts the master/setup must fix on the way in (corrected from "two"):**
1. **`R/text_analysis.R` (lines 5, 13, 26, 40, 41)** reads **five** lexicon files from a phantom `./Codes/` directory — the three sentiment lexicons (CroSentilex negatives/positives, CroSentilex Gold, lilaHR ×2) that power the **entire "atmosfera diskursa" layer**. Repoint to `here::here("resources/lexicons/...")`. **Highest-value fix of the three** — it unblocks a whole analytical layer, not just tokenization.
2. `R/write_tokens.R` (lines 38–39) reads `rules.txt`/`transformations.txt` from a hardcoded `C:/Users/Lukas/Dropbox/...`; the files exist in-repo — repoint to `here::here("resources/lexicons/...")`.
3. `R/load_merge_filter_religious.R` `stop()`s if `religious_terms` isn't in the workspace — `00_setup.R` must `source("R/religious_terms.R")` first.

**And the render side-effect (the one the prior draft never identified):** move the `saveRDS(.../data/processed/*.rds)` calls from `pages/mapa/mapa.qmd` (lines 100–168) into `R/03_aggregate.R`. After this, `mapa.qmd` is a pure read-only consumer like the other three pages, rendering is side-effect-free, aggregate-refresh is an explicit PI step, and teammates can render the site from tracked aggregates + the synthetic sample without the master.

Run: `Rscript R/00_run_all.R` / `--from=03` / `--sample`.

### 6.3 Formal numeric provenance — DROP `passport.yaml`; a tiny `R/check_claims.R` if ever needed — P2
*Critique accepted (B2):* a per-page `passport.yaml` DSL with `tolerance`/`assert`/`last_verified` and a custom audit runner is a maintenance liability nobody on a sociology team will keep honest, for a project with ~5 headline numbers that move only on an append. **Delete it from the roadmap.** The cheap PostToolUse grep flag (§5.2.1) covers ~95% of the value. *If* formal provenance is ever wanted, a single `R/check_claims.R` that asserts the ~5 numbers (`nrow(master)≈610k`, `ncol≈620`, `length(religious_terms$term)==95`, `length(thematic_dictionaries_v3)==16`, date range) — runnable in `/commit` — is sufficient and maintainable. No YAML DSL.

### 6.4 FAIR / data-availability — P0 (the doc) / P1 (synthetic data + codebook)
- **`DATA_AVAILABILITY.md` — P0 / S.** Honest, with a per-source rights table: master = gitignored, **not redistributable in full**, on request to PI; `data/processed/*.rds` = aggregates, no PII, **CC BY 4.0, in repo, PI-refreshed via `R/03_aggregate.R`**; lexicons = check upstream licences + cite; udpipe model = verify/cite UD licence; the religious-terms regexes = citable methodology artifact.
- **`CODEBOOK.md` — P1 / M.** Auto-generated (`R/05_codebook.R` reads the master schema), ~620 variables grouped. Don't hand-maintain.
- **Synthetic sample `data/sample/merged_sample.rds` — P1 / M.** ~500 rows, real schema, scrubbed text, so anyone can `Rscript R/00_run_all.R --sample` end-to-end without the restricted master — and (post-§6.2) render the pages. The practical heart of "clone and reproduce" + a CI smoke-test fixture.
- **`REPLICATION.md` — P1 / S.** AEA's 8 sections scaled to DigiKat (Zenodo/GitHub + CC BY 4.0, **not** AER/openICPSR/DCAS).

### 6.5 `.gitignore` policy — keep `processed/` tracked, ignore backups — P0 / S
Verified: `data/*.rds` is **top-level only**, so the aggregates in `data/processed/` (517 KB, no PII) **are tracked**. Make the intent explicit; **do NOT broaden to `data/**/*.rds`** (that would silently drop the aggregates):

```gitignore
data/merged_comprehensive.rds
data/merged_comprehensive_backup_*.rds   # NEW: backups never committed
data/nlp/*.rds
data/raw/*.xlsx
data/raw/new/*.xlsx                        # NEW: incremental drop-folder
# data/processed/*.rds ARE intentionally tracked (CC BY 4.0, no PII) — do NOT add data/**/*.rds
```

### 6.6 Housekeeping & safety
- **Reconcile README vs reality — P0 / S.** README's `/code /publications /reports` is fiction; the real layout is `R/ pages/ data/ docs/ resources/ design/ archive/`. Update `README.md` text (don't rename `R/` → breaks every `here::here()`); the authoritative convention lives in `CLAUDE.md`.
- **Delete the duplicate udpipe model — P0 / S.** A 19 MB copy sits loose at repo root **and** in `resources/models/`. Keep only `resources/models/`.
- **Capture environment — P0 / S.** A lightweight `/capture-environment` writes `ENVIRONMENT.md` + refreshes `renv.lock`, and critically captures the **SHA-256 + filename of the udpipe model**, the master RNG seed, **and the R version / locale** (the actual diacritic-portability lever).
- **Backup prune policy — P1 / S.** `append_new_data.R` writes backups but never prunes. Add `R/prune_backups.R`: keep newest 3 + newest-per-month; gitignore them (§6.5).
- **`/disclosure-check` pre-flight — P1 / S.** Before sharing any extract, scan for author/account metadata + small-cell counts (re-identification, esp. `*_actors.rds`) + raw scraped text leaking into a "shareable" aggregate. Use `scholar-skill:scholar-safety` (local PII scan) as the engine.

---

## 7. Research / collaboration / MCP

### 7.1 Framing: DigiKat is descriptive/interpretive, not reduced-form econ
All five thematic studies map/classify/describe/trace — none have causal identification. The right paper type is the guide's **`descriptive`** (measurement validity, sampling frame, missingness, comparator): no peer-review machinery day one, no prereg except one specific study, **citation style APA/Chicago not AEA**, quality bar = measurement-validity + reproducibility.

### 7.2 Exploration-folder workflow — P1 / S
A 610k-row corpus *invites* throwaway analyses.

```
explorations/<slug>/{README.md (question, status, kill-by date), *.R, output/}
explorations/ARCHIVE/{completed_<slug>/, abandoned_<slug>/}
```

`exploration-folder-protocol.md` (`paths: ["explorations/**"]`): explorations may **read** the master/`processed/*.rds` but **never write** into `data/`, `pages/`, `docs/`, `studije/`; heavy slices use `data.table` + sample first; >2-week-untouched auto-flags for ARCHIVE; `explorations/*/output/` is gitignored. **Quality reports only when an exploration graduates**, not per commit.

### 7.3 Thematic-study / paper pipeline (LIGHT) — P1 / M
Every DigiKat study **enters mid-pipeline**.

```
studije/
├── _STUDY_TEMPLATE/{README.md (RQ, slice definition, status, owner), slice.R, refs.bib, output/}
├── youtube-selfhelp/ ├── hodocasnicki-turizam/ ├── demokrscanstvo/ ├── katolicko-obrazovanje/ └── sveci/
```

Working folder (`studije/`) stays separate from the published page (`pages/studije/<slug>.qmd`). **Delegate, don't rebuild** — wire `scholar-skill:*` with DigiKat defaults: `scholar-idea`/`scholar-hypothesis` (sociology of religion), `scholar-lit-review` (+ perplexity), `scholar-eda` (the workhorse), `scholar-compute` (16-theme/sentiment/BERTopic), `scholar-qual` (saints/interviews), `scholar-citation` (**APA/Chicago**), `scholar-write`, `scholar-ethics`/`scholar-open`.

### 7.4 Discipline card — the one real config artifact — P0 / S
`.claude/references/discipline-card-digikat.md` stops the scholar skills defaulting to AER/identification mode:

```markdown
field: sociology of religion / communication studies / digital humanities
dominant_paper_types: [descriptive, mixed-methods, computational-text-analysis]
citation_style: APA 7th (default) | Chicago author-date (history/sociology venues)
venues_hr: [Medijska istraživanja, Društvena istraživanja, Nova prisutnost, Diacovensia]
venues_en: [New Media & Society, Journal of Media and Religion, Religion, Social Media + Society]
preregistration_norm: NOT expected for descriptive work. Trigger OSF prereg ONLY for a
  confirmatory directional hypothesis on a NOT-YET-examined corpus slice (see Study 3).
methods_referee_tilt: descriptive   # measurement validity, sampling frame, missingness, comparator
language: bilingual — HR content + abstracts, EN for international venues
```

### 7.5 Preregistration: mostly skip — P2 / S
For 4 of 5 studies, prereg is theater (descriptive/exploratory). **The one genuine case: Study 3 (demokršćanstvo)** *if* it commits to a confirmatory directional test. Registry = **OSF**. The corpus already exists, so a prereg must honestly scope to a *not-yet-examined* subset; `scholar-design` **refuses retrospective preregistration** — respect that. Document the *trigger criterion* in the discipline card.

### 7.6 Two declarations that DO matter — P1 / S
Ship with every study via `scholar-open`/`scholar-ethics`: (1) a **data-availability statement** (access story for the gitignored master; the public `processed/` aggregates; the `≥2`-match inclusion criterion); (2) an **AI-use disclosure** (Claude Code in the pipeline).

### 7.7 Collaboration for 10 (mostly non-coder) researchers
- **`/team-onboarding`, NOT fork+customize — P1 / S.** PI configures `.claude/` once, commits it; teammates run the Anthropic-shipped `/team-onboarding` to inherit it. Non-coders never edit it. Machine bits go in gitignored `CLAUDE.local.md`.
- **`/coauthor-brief` — the keystone — P1 / M.** Produces a handoff brief: git delta since `<ref>`; per-artifact state (4 map pages + 5 studies: rendered/stale/owner via `docs/` mtimes vs `pages/` sources); and **the DigiKat-specific local-reproduction recipe** — how to obtain the gitignored master + udpipe model (PI / Google Drive via MCP), where to put them, then `renv::restore()` → `Rscript R/00_run_all.R` (or `--sample`) → `quarto render`. **Critically, the brief must state that `data/processed/*.rds` are PI-refreshed only** (`R/03_aggregate.R` against the master), so a teammate knows not to expect their render to update them.
- **Team-map + `scholar-collaborate` — P1 / S.** A `.claude/references/team-map.md` (Layer/Study → lead → files → NLP-heavy?). Use `scholar-collaborate` for CRediT statements.
- **`/weekly-synth` — P2 / S.** Rolls session logs into a bilingual digest, optionally a Gmail draft.

### 7.8 MCP integrations (perplexity, Google Drive, Gmail) — P1 / S–M
Design principle: **graceful degradation** — a missing MCP produces an explanation, not an error.

| Skill | Primary MCP | Fallback if absent |
|---|---|---|
| lit-review | perplexity (HR + EN venues) | local `references.bib` only |
| verify Croatian facts (events, outlets, dates, spellings) | perplexity | flag `UNVERIFIED`, manual |
| `/coauthor-brief` data link | Google Drive (`search_files`/`get_file_metadata`) | print "ask PI for data" note |
| `/weekly-synth` send | Gmail (**draft only, never auto-send**) | write digest to `session-logs/` only |
| citation/.bib | none (local `references.bib`) | CrossRef via perplexity |

**Reference manager: Zotero via committed `references.bib` (no MCP needed).** Shared Zotero group → export to repo-root `references.bib` (+ per-study `studije/<slug>/refs.bib`); `scholar-lit-review`/`scholar-citation` auto-detect a local `.bib`. Use **Better BibTeX** for stable keys across 10 people. Style = APA/Chicago. Zero tolerance for invented citations — emit `UNVERIFIED` rather than fabricate.

---

## 8. What to SKIP or DEFER from the guide (and why)

### SKIP outright (no DigiKat analogue)

| Guide feature | Why skip |
|---|---|
| Beamer / LaTeX / XeLaTeX stack | No slides, no LaTeX; output is a Quarto website + papers. |
| TikZ machinery (`tikz-reviewer`, `/extract-tikz`, `/new-diagram`, tikz-* rules) | Figures are R/ggplot chunks. |
| revealjs / lecture skills + reviewers (`pedagogy-reviewer`, `slide-auditor`, deck rhetoric) | No teaching mission; `/review-page` is the analogue. |
| Beamer→Quarto translation (`/translate-to-quarto`, `beamer-translator`, `beamer-quarto-sync`) | Site is Quarto-native. |
| Stata everything (`stata-mcp`, `/stata-replication`, `stata-code-conventions`) | R-first; no Stata. |
| Econ identification (DiD/IV/RDD/synthetic control; `sim-reviewer`, `simulation-conventions`) | All studies descriptive; pull from `scholar-skill` on demand if a study goes inferential. |
| R-package machinery (`r-package-reviewer`, CRAN gates) | Scripts + website, not a package. |
| AEA RCT registry / AEA `template_README` / openICPSR / DCAS / `scholar-grant` | Wrong field + registry; Zenodo/OSF + CC BY 4.0; already funded. |
| `meta-governance.md` / template machinery | Working project, not a fork-template. |
| Numeric quality-gate rubric (`-20/-15/…`) | Replaced by §2.5's three plain sentences. |
| `passport.yaml` provenance DSL + `/audit-reproducibility` runner | Maintenance liability for ~5 numbers; cheap grep flag + (if ever) `R/check_claims.R` suffices (§6.3). |
| Desktop-notification hook (`osascript`/`notify-send`) | No Windows value. |
| `chmod +x` hook-install step | No-op on Windows. |
| Full 18-agent / 52-skill ceiling, MAS v2, HTML dashboard, plugins | Over-engineering for a 10-person mid-build project. |
| critic⇄fixer auto-loop (5-round cap) for web pages | Over-engineered for single-page edits; single-pass `/review-page` instead. |

### DEFER (real analogue, adopt on trigger)

| Guide feature | Adopt when… | Priority |
|---|---|---|
| Constitutional governance (4 Articles, pre-drafted §5.4) | Year-2 transition (start 2026 / Phase 3) | P2 |
| Standalone `cross-artifact-review.md` rule | The thematic *papers* acquire real manuscripts | P2 |
| `croatian-nlp-reviewer` + `religion-media-domain-reviewer` (opus) | Manuscripts exist (Phase 4) — until then, do the *structural* NLP fix (extract `thematic_dictionaries`) without them | P2 |
| `quarto-page-fixer` / critic auto-loop | Page edits become genuinely complex | P2 |
| Simulated blind peer review (`/review-paper`, editor + referees) | A study is submission-ready (Phase 5–6) — **descriptive tilt only** | P2 |
| OSF preregistration | **Only if Study 3 turns confirmatory** (§7.5) | P2 |
| `scholar-replication` clean-room package | Final dissemination (Phase 6) — FAIR/Zenodo | P2 |
| Git worktrees (`isolation: worktree`) | A risky multi-day refactor (e.g. re-tokenizing the corpus) | P2 |
| `targets` / `_targets.R` | The NLP layer branches | P2 |
| `R/check_claims.R` numeric assertions | Formal provenance is ever actually wanted | P2 |
| Heavyweight Python `uv.lock`; Docker | A collaborator can't install R/`udpipe` natively | P2 |

---

## 9. Phased adoption roadmap

> **Superseded by the *Refinement decisions → Revised roadmap* at the top of this doc** (2026-06-25). The original below is kept for its rationale; where they differ, the top roadmap wins (full scope incl. studies, solo/no-team-layer, environment-flexible execution).

### Day 1 — genuinely minimal: fix what's broken, protect what's irreplaceable
*Rebalanced per the critique:* the prior "Day 1" was a week of work, and one anchor (the stemmer bug) was fiction. The real minimum is the afternoon of repo fixes that unblock everyone, plus the one hook that prevents catastrophe.

1. **The three real repo fixes** (the single most valuable move, §0/§6.2/§6.6): repoint `R/text_analysis.R` (`./Codes/` → `resources/lexicons/`, unblocks the whole sentiment layer) and `R/write_tokens.R` (Dropbox → `resources/lexicons/`); delete the duplicate root `.udpipe`. **P0 / S.**
2. **Decouple aggregate-production from rendering** — move the `saveRDS(.../processed/*.rds)` calls out of `mapa.qmd` into a new `R/03_aggregate.R`; confirm `quarto render` no longer mutates tracked data. **P0 / M.** *(This is the architectural fix; do it now even before the full numbered pipeline exists.)*
3. **`renv::init()` + commit `renv.lock`** — pins `stringi`/ICU so the corpus definition can't drift silently. **P0 / S.**
4. **A ~60-line `CLAUDE.md` stub** stating the data lineage, the directory truth (README is wrong), "render-before-done", and "aggregates are PI-only, not a render side-effect". **P0 / S.**
5. **The git/data-guard hook** (resolved interpreter, not hardcoded `python`) + `.claude/settings.json` with `defaultMode: plan` (**no bypass**). Add `.claude/settings.local.json`, `CLAUDE.local.md`, `quality_reports/session_logs/` to `.gitignore`; make the `processed/`-tracked + backup-ignore `.gitignore` intent explicit (§6.5). **P0 / S.**

### Week 1
- Expand `CLAUDE.md` to the fuller §1.1 version; create repo `MEMORY.md` (flat seed list — no tag taxonomy yet) + `CLAUDE.local.md`.
- The 3 core rules: `data-pipeline-protocol`, `quarto-verification` (with the no-side-effect + atomicity directives), `croatian-encoding` (defensive + locale assertion).
- 2 agents: `verifier` (incl. the post-render "did `processed/` change" check) and `r-reviewer`; wire `verifier` into `/commit`.
- 3 skills: `/objavi`, `/azuriraj-podatke` (resolved `Rscript` path), `/commit`. Add `/render-page`, `/context-status` if appetite allows.
- Begin the numbered master `R/00_run_all.R` (00–02 + 04; 03 already done Day-1), fixing `load_merge_filter_religious.R`'s un-sourced global.
- **Structural NLP fix:** extract `thematic_dictionaries_v3` from the three qmd pages into `R/thematic_dictionaries.R`.
- `discipline-card-digikat.md`; reconcile README directory text.

### Month 1
- Finish the numbered pipeline + `/capture-environment` (udpipe SHA-256 + R version/locale); `DATA_AVAILABILITY.md`.
- P1 rules (`r-code-conventions`, `single-source-of-truth`, `croatian-nlp-conventions`) — add as incidents motivate, not preemptively.
- `numeric-claim-verifier`; `/data-analysis`, `/review-page` (single-pass), `/provjeri-leksikon`, `/learn`.
- Claim-reconcile hook (narrowed scope: `PROJECT_DESCRIPTION.md` + 2 qmd pages), session-log + context-survival hooks.
- Collaboration: committed PI-owned `.claude/`, `/team-onboarding`, `/coauthor-brief` (with the data-fetch recipe + the "aggregates are PI-refreshed" note), team-map, committed `references.bib` (Better BibTeX, APA/Chicago).
- Wire perplexity + Google Drive + Gmail MCPs with graceful degradation.
- Synthetic `data/sample/` + `--sample` mode (now genuinely runnable end-to-end, post-§6.2); `/disclosure-check`; backup-prune policy; `studije/` convention + `_STUDY_TEMPLATE` + `/novo-istrazivanje`.

### Ongoing
- Replace seeded `[LEARN]` entries with real incidents; weekly session-log synthesis. Introduce the tag taxonomy only once >10 real entries exist.
- Re-evaluate deferred items at their triggers: constitution (start 2026); opus-tier reviewers + standalone cross-artifact rule + `/review-paper` + OSF prereg (Phases 4–6); `scholar-replication`/Zenodo (Phase 6); `targets` (only if NLP branches); `R/check_claims.R` (only if formal provenance is wanted).
- Auto-generate `CODEBOOK.md`; keep `CLAUDE.md` under 150 lines as standards migrate into `.claude/rules/`.

---

*Key load-bearing repo facts (re-verified against the tree for this final edit): `R/stemmer.R` line 2 is **clean UTF-8** — there is **no** mojibake bug; the prior "shipping defect" was a read-time corruption in the earlier tooling, and the encoding layer is demoted to defensive accordingly. `pages/mapa/mapa.qmd` calls `saveRDS(.../data/processed/*.rds)` **during render** (lines 100–168), so a full render mutates 10 git-tracked aggregates and the "shareable FAIR tier" can only be refreshed by the PI who holds the gitignored master — the central reproducibility gap, fixed by extracting those calls into `R/03_aggregate.R`. `R/text_analysis.R` reads **five** lexicon files from a phantom `./Codes/` directory (lines 5, 13, 26, 40, 41), blocking the entire sentiment layer; `R/write_tokens.R` reads a Dropbox path (lines 38–39). The headline numbers live in `PROJECT_DESCRIPTION.md` and **two** qmd pages — **not README** (zero matches) and **not four pages**. `append_new_data.R` dedups on **raw URL with no `?utm_…` stripping** (real gap) and never prunes backups. `data/processed/*.rds` is git-**tracked** (top-level `data/*.rds` glob misses the subfolder). On this machine `python` exists but `python3` does not, and `Rscript` is **not on PATH** — so hooks must resolve their interpreter and skills must use a resolved R path (or R must be added to PATH as a setup prerequisite).*