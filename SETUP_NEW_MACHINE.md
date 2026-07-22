# SETUP_NEW_MACHINE.md — continuing DigiKat on another computer

Practical checklist for picking up DigiKat work on a second machine. Written 2026-07-22.
Companion to `CLAUDE.md` (project rules) and `CLAUDE.local.md` (machine paths — **not** in git; see §3).

---

## 0. TL;DR — three transport channels

Files reach the new machine by **one of three routes**, and the big data does not travel by git:

| Route | Carries | Caveat |
|---|---|---|
| **GitHub** (`git clone/pull`) | all tracked code + docs: `R/**`, `pages/**`, `data/processed/*.rds` aggregates, the udpipe model | the master, backups, and the semantic store are **gitignored** |
| **Dropbox** (folder sync) | everything in the repo folder Dropbox does not ignore — incl. the **1.2 GB master** and any git-untracked working files | only if the new clone sits in the **same Dropbox account**; `data/semantic/` is Dropbox-ignored so it does **not** sync |
| **Manual copy** (USB / transfer) | **`data/semantic/digikat.ragnar.duckdb` (13.6 GB)** — the only artifact neither git nor Dropbox carries | copy it, or rebuild (§4) |

**Decide first: does the new clone live inside the same Dropbox account, or outside it?**
- *Inside Dropbox* → master + untracked files sync for free, but you inherit the `.git`-in-Dropbox hazard
  (rewritten SHAs, render file-locks — see `CLAUDE.local.md`). Pause Dropbox before any full render / pipeline run.
- *Outside Dropbox (recommended for a clean git history)* → clone from GitHub, then **manually copy** the master
  and the semantic store.

---

## 1. Get the code

```
git clone https://github.com/lusiki/DigiKat.git
cd DigiKat
git pull            # make sure you have the latest (incl. the study + semantic-script commits)
```

This brings all scripts, pages, tracked aggregates (`data/processed/*.rds`), and the udpipe model.

## 2. Move the two big data artifacts (neither is in git)

| File | Size | How to get it there |
|---|---|---|
| `data/merged_comprehensive.rds` (master, ≈710k×47) | 1.2 GB | Dropbox sync, or copy into `data/` |
| `data/semantic/digikat.ragnar.duckdb` (vector store) | 13.6 GB | **manual copy** into `data/semantic/`, or rebuild (§4) |

Optional: `data/*_backup_*.rds` (master backups) — copy only if you want the safety net.
Skip the `data/semantic/*_test*.duckdb` and `corpus_prepared.rds` — not needed to query.

## 3. Recreate `CLAUDE.local.md` (it is gitignored — machine-specific)

It will **not** arrive via git. Copy this machine's version as a template and edit the paths for the new box:
- `R_AVAILABLE`, and the `Rscript.exe` path (this machine: `C:\Program Files\R\R-4.4.1\bin\Rscript.exe`)
- the Quarto path (this machine: RStudio-bundled `...\RStudio\resources\app\bin\quarto\bin\quarto.exe`)
- master location + backup names
- the Dropbox-hazard note if the new clone is inside Dropbox

## 4. Semantic database (Level 3 meaning-search)

**To QUERY the existing store** you need FOUR things (see `R/semantic/README.md`):
1. the `.duckdb` file copied to `data/semantic/digikat.ragnar.duckdb` (§2)
2. R packages: `ragnar`, `duckdb`, `ellmer`, `uwot`, `here`
3. **Ollama installed + running + `ollama pull bge-m3`** — query text is embedded at search time, so the model
   must be live at `localhost:11434` **even just to search** (not only to build)
4. then: `source('R/semantic/12_query.R'); dk_retrieve('hodočašće u Mariju Bistricu')`

**To REBUILD from scratch** (instead of copying the 13.6 GB file):
```
Rscript R/semantic/10_prep.R      # master → data/semantic/corpus_prepared.rds
Rscript R/semantic/11_build.R     # embeds ~710k posts + builds index  (⚠ ~9–10 hours)
```
→ **Copying the file beats rebuilding** unless you can't move it. Either way, Ollama + bge-m3 must be present.

## 5. R environment

There is **no `renv.lock`** yet, so package versions are not pinned — reinstall by hand:
- **Semantic:** `ragnar`, `duckdb`, `ellmer`, `uwot`, `here`
- **Pipeline / analysis:** `data.table`, `readxl`, `dplyr`, `tidyr`, `stringi`, `ggplot2`, `udpipe`
- Prefer **R ≥ 4.2** (native UTF-8 on Windows) so Croatian diacritics (č ć ž š đ) round-trip (`croatian-encoding` rule).

Consider running `/capture-environment` before/after the move to write `renv.lock` + `ENVIRONMENT.md` and pin versions.

## 6. Quarto

Standalone install, or RStudio-bundled. **Always render from the REPO ROOT** (never `cd pages && quarto render`)
— see the MEMORY.md hard-won lesson about scattering output and emptying `docs/`.

## 7. Data that stays local (not in git, by design)

The following are **gitignored** (large and/or hold raw post text / URLs → disclosure risk on a public repo).
They travel via **Dropbox only**, and are regenerable from the master + scripts:
- study data outputs: `studies/*/output/*.rds`, most `output/*.csv` coding sheets and samples
- `R/semantic/*_sample.rds`, sample figures
- `data/nlp/`, `data/raw/` (`.xlsx`)

Aggregate, PII-free outputs that ARE shareable live in `data/processed/*.rds` (tracked) — never broaden the
gitignore to drop those.

---

**Sanity check after setup:** `git status` clean · master loads in R · Ollama running · `dk_retrieve("test")`
returns Croatian snippets with intact diacritics · a single `quarto render pages/<page>.qmd` builds from the root.
