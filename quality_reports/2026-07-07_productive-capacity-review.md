# DigiKat — Productive Capacity Review

**Date:** 2026-07-07 · **Question:** what would most raise this repo's throughput + output quality?
**Method:** 6-agent grounded workflow (5 lever-areas each reading the real pipeline code + 1 ROI prioritizer).
Load-bearing findings re-verified by hand (marked ✓).

> **Verdict.** DigiKat is **not** losing capacity to slow compute or to hand-maintaining the ~112 source
> pages (those are correctly generated). It is losing capacity in three specific places, and most of the
> bleed is **rework-risk and never-shipped work, not raw compute**:
> 1. **A daily edit tax** — `freeze: auto` re-runs chunks on every prose edit, and a finished 112-page
>    catalog sits committed but **unrendered** (`docs/izvori/` is empty ✓), one targeted render from readers.
> 2. **Copy-pasted instruments during a 38-commit/week phase** — the 16-category dictionary is byte-duplicated
>    across 3 published pages, the religious filter across 2 scripts, and a now-false caveat is baked into 103
>    generated pages. Each is one edit from silent divergence.
> 3. **A reproducibility floor that is a lie** — the advertised `R/00_run_all.R` is absent, and 3 tracked
>    `*_actors.rds` have no committed producer, so the canonical rebuild silently under-produces.
>
> **Single highest-leverage move — and it's the smallest:** extract `thematic_dictionaries_v3` into one
> sourced `R/thematic_dictionaries.R` this week. Minutes of effort; eliminates the only *live* wrong-number
> risk on three published pages, right before the education study edits that very dictionary. Its throughput
> twins are `freeze: true` + a targeted `izvori` render.

---

## Verified defects found (worth knowing now)

| # | Defect | Evidence ✓ | Effect |
|---|---|---|---|
| A | **112-page `izvori` catalog is generated + committed but never rendered** | `docs/izvori/` = 0 html of 133 in `docs/` | Finished work invisible to readers |
| B | **`03_aggregate.R` produces only 3 of 6 platforms' actor files** | loops `c("web","youtube","facebook")` at L105/L136; ig/tiktok/twitter `_actors.rds` dated a day later (ad-hoc) | Clean rebuild drops IG/TikTok/Twitter hubs → catalog shrinks ~103→~47 |
| C | **False provenance caveat on all 103 pages** | `wiki_sources.R:195` hard-codes *"2021.–2025. … ne uključuju Instagram i TikTok"*; log shows 18 IG + 19 TikTok published | IG/TikTok pages deny their own platform; date says 2025, data runs to 2026 — a no-hand-typed-numbers violation ×100 |
| D | **16-category dictionary triplicated** (byte-identical *today*) | `diskurs.qmd:123-140`, `mapa_stats.qmd:69-86`, `događaji.qmd:161-178` | One edit → divergent theme counts across pages claiming one scheme |
| E | **Religious filter is an O(rows×terms) scalar loop, not data.table** | `load_merge_filter_religious.R:58-134` + duplicated `append_new_data.R:136-186`; no data.table in `R/*.R` | ~100M+ stringi calls per full re-filter → term-list iteration takes tens of min–hrs |
| F | **`text_analysis.R`/`write_tokens.R`/`stemmer.R` are dead legacy** | sourced only by `archive/_Identifikacija.Rmd`; live loader is `04_nlp.R` + pages read `resources/lexicons/` ✓ | The `MEMORY.md:63-64` "repoint ./Codes/" P0 TODO is a **false alarm misdirecting the r-reviewer/nlp agents** |
| G | **~50 near-empty actor pages** (1–4 posts) pass the publish gate | `wiki_sources.R:245-249` is volume-blind; `_log.md` lists dozens of 1-post actors | Half the catalog is thin "profiles" inflating render + QA surface |
| H | Duplicate 19 MB udpipe model at repo root | `./croatian-set-ud-2.5-191206.udpipe` + `resources/models/…`; live refs point only to `resources/` | Disk clutter, confusion risk |
| I | Config drift: drop-folder path | `append_new_data.R:29` uses `data/new`; CLAUDE.md documents `data/raw/new/` | Ambiguous ingest folder |

---

## ROI-ranked roadmap

### Quick wins — this week, each < 1 h, no master needed (except where noted)

1. **Extract `thematic_dictionaries_v3` → `R/thematic_dictionaries.R`** and `source()` it in all three pages
   (next to their existing `theme_digikat.R` source). Re-render the three to confirm identical output.
   *Kills the only live wrong-number risk (defect D).* ← the single highest-leverage move.
2. **Set `execute: freeze: true`** on the heavy `mapa` data pages so prose/YAML edits stop re-running chunks.
   Document that a real data refresh must delete the affected `_freeze/` entry. *(defect: freeze tax)*
3. **Retire dead legacy scripts** (`text_analysis.R`, `write_tokens.R`, `stemmer.R` → `archive/`) **and delete
   the false TODOs** from `MEMORY.md:63-64`, `WORKFLOW_SUGGESTIONS.md`, and `.claude/agents/{r-reviewer,croatian-nlp-reviewer}.md`.
   *Stops your own notes + review agents chasing a phantom 0%-coverage bug (defect F).*
4. **Delete the duplicate root udpipe model.** *(defect H)*
5. **Fix the `data/new` vs `data/raw/new/` config drift** — reconcile so the drop-folder is unambiguous. *(defect I)*
6. **Data-drive the false caveat + date range in `wiki_sources.R`** (derive platforms + min/max year from the
   aggregate; drop the exclusion clause). Needs an R re-run of the generator on the PI machine. *(defect C)*

### Structural bets — raise the throughput ceiling (sequence matters)

7. **Ship the finished catalog:** targeted `quarto render pages/izvori` from repo root → commit `docs/izvori`.
   Static-only (no master, no udpipe), sidesteps the Dropbox-lock full render. Do **after** #6 (no false
   caveat) and #8/#9 (reproducible + de-thinned). Establishes a seconds-long catalog edit→publish loop. *(A)*
8. **Close the actor-aggregate hole:** extend `03_aggregate.R:24-25,105,136` to all six platforms, then
   **diff regenerated web/youtube/facebook against the committed files to prove byte-equivalence.**
   HARD GATE (rewrites tracked `processed/*.rds`) — confirm + verify. *This is the prerequisite that makes the
   one-command rebuild trustworthy.* *(B)*
9. **Raise the publish gate** with a volume floor (`publish=="yes" & total_posts >= MIN_POSTS`) routing thin
   actors to the existing `held/_log` path. PI sets `MIN_POSTS` (editorial call). Pairs with #6 in one
   `wiki_sources.R` re-run. *(G)*
10. **`R/00_run_all.R` — the one-command rebuild** (thin idempotent driver: `--from=NN`, `--sample`, per-step
    input asserts, one-line row-delta log, skip-if-unchanged, backup-verify before any master/processed
    overwrite). Build it **after** #8 so it doesn't enshrine an under-producing rebuild. *(reproducibility)*
11. **Vectorize + unify the religious filter** into one `R/religious_filter.R` sourced by both callers:
    95 vectorized `stri_detect` passes → `rowSums()>=2` → expensive extraction only on survivors. Turns a
    full re-filter from tens-of-min→minutes and kills the copy-paste divergence. HARD-GATE-adjacent: prove the
    new filtered row-count + `matched_terms` match the current master byte-for-byte before trusting. *(E)*
12. **`R/linkage.R` — one battle-tested windowed-linkage helper** that bakes in the *linkage-≠-engagement*
    house rule. The ~7× overstatement locus is reimplemented twice today (`catholic-education/slice.R:116-127`
    and `moral-economy/01:106-117`), each holding a fix the other lacks (catastrophic-backtracking; per-entity
    construct validity). Make `linkage_report()`'s default output juxtapose `doc_cooccurrence`,
    `windowed_genuine`, `incidental_share` with a fixed "do-not-report-without-hand-validation" banner. **Adopt
    in the NEXT study + `_STUDY_TEMPLATE` only — do NOT retrofit the running studies.**
13. **Enrich `_STUDY_TEMPLATE`** (a `slice.R` that *calls* the helpers, a `run.R` driver, a `REPLICATION.md`
    stub, an `output/{figures,tables}` contract) + an `R/study_helpers.R` (`read_corpus` with setDF RAM-guard,
    `parse_dates_visible` that logs drops, `checkpoint`). Compounds through `/new-study` on every future study.

### Do NOT bother now

- **Initialize renv / commit `renv.lock`** — real, but premature during the solo build phase; it adds a
  snapshot step to every install and pays off only at release / first collaborator. Do it then.
- **Refactor the 3 running studies onto the new helpers** — they've paid the setup cost; moral-economy is
  frozen with fingerprint caches, catholic-education is near submission. Refactoring destabilizes it for no gain.
- **Repoint the `./Codes/` / foreign-Dropbox paths** — that's polishing dead code (defect F). Retire, don't fix.
- **Sell `data/sample/` as a second-machine *analysis* enabler** — `make_sample.R` redacts free text, so the
  sample can only smoke-test schema/rendering, not drive udpipe/sentiment. Generate it (after fixing its
  schema bug: it strata-keys lowercase `source_type` but the master has `SOURCE_TYPE`, and it redacts `FROM`
  which is the group-by key for every source aggregate) — but scope it as render-scaffold + CI smoke test,
  not analysis. Reproducibility insurance, not a solo-phase speed win.
- **A standalone Dropbox-lock wrapper project** — fold the scatter check into `/deploy` opportunistically;
  the `.gitignore` + `git_data_guard.py` backstops already cover the known failure.

---

## Suggested sequencing

- **Today (safe, no master):** #1 dict extract · #2 freeze:true · #3 retire dead scripts + fix false TODOs ·
  #4 delete root model · #5 config drift. ~1–2 h, all reversible, all reduce live rework-risk.
- **Next PI-machine session (needs R + master, HARD-GATE verify):** #8 six-platform aggregate (diff-verify) →
  #6 + #9 regenerate catalog (correct caveat, de-thinned) → #7 render + publish `docs/izvori`.
- **Then the ceiling-raisers:** #10 `00_run_all.R` · #11 vectorized filter · #12 `R/linkage.R` + #13 template
  (for the next study, not a retrofit).

The through-line: **stop the wrong-number bleed (#1) and ship the finished-but-stranded catalog (#7), then
make the rebuild honest (#8, #10).** Everything else is real but subordinate to those.
