Confirmed: **README contains none of the headline numbers** — the document's claim that "610.000" is "duplicated across `README.md`, `PROJECT_DESCRIPTION.md`, and four `mapa/*.qmd` pages" is doubly wrong (README has zero; only 2 qmd pages, not four). Also, dedup is on raw `URL` with no utm-stripping, so the document's `[LEARN]` "strip ?utm_… before dedup" is a real gap (good), but its framing as documenting-existing-behavior is fine. I now have everything I need.

---

# ADVERSARIAL REVIEW — DigiKat Workflow-Design Document

Prioritized, sectioned list of concrete fixes. Each item quotes the suggestion being critiqued. Repo facts were verified against the actual tree, not the document's self-reported "verified" claims.

## A. INCORRECT / INFEASIBLE — factual errors that invalidate load-bearing recommendations (fix FIRST)

**A1. The "live mojibake bug in `R/stemmer.R`" is FALSE. This is the single most damaging error in the document.**
The document repeats, as its #2 highest-leverage opportunity and the justification for making `croatian-encoding.md` the "highest ROI" P0 rule:
> "`R/stemmer.R` currently contains `budeĹˇ / Ä‡u / Ĺľelim` — UTF-8-read-as-Latin1 corruption … This is shipping today."
> "[LEARN:encoding] R/stemmer.R stop=c(...) currently has mojibake (budeĹˇ/Ä‡u/Ĺľelim) → fix to budeš/ću/želim."
> Directive 2.1: "named existing defect: repair `R/stemmer.R`'s `budeĹˇ/Ä‡u/Ĺľelim` → `budeš/ću/želim`."

`R/stemmer.R` line 2 contains clean UTF-8: `...'budeš','si',...,'ću','ćeš','će',...,'želim','želiš','želi',...`. There is no mojibake. The corruption exists only in *the document's own text* — i.e., the designer's tooling mangled the bytes while reading the file, then "reported" the mangling as a repo bug. **Fix:** strike every reference to a stemmer.R mojibake "defect," the seeded `[LEARN:encoding]` entry, the quality-gate framing, and the Day-1 selling point "catches the live `R/stemmer.R` mojibake." The encoding *rule* may still be worth having (defensive), but it must be demoted: it is NOT validated by a live bug and is NOT the "highest ROI" item. The whole document's framing that "encoding correctness is a first-class P0 because there is a bug shipping today" collapses.

**A2. The claim-reconcile risk is overstated by mis-citing where the numbers live.**
> "The numbers are duplicated across `README.md`, `PROJECT_DESCRIPTION.md`, and four `mapa/*.qmd` pages."
README.md contains **none** of the headline numbers (610/620/80 posto — zero matches). The `610` figure appears in PROJECT_DESCRIPTION.md and only **two** qmd pages (`mapa.qmd`, `mapa_stats.qmd`), not four. The claim-reconcile hook's grep target list (`README.md`, `pages/**/*.qmd`) will mostly hit nothing in README and over-scope the qmd glob. **Fix:** narrow the hook to the files that actually carry numbers; drop README from the magic-number scan. The hook is still worth building, but at lower urgency than billed.

**A3. `quarto render` MUTATES git-tracked data — a contradiction the document never resolves.**
`pages/mapa/mapa.qmd` (lines 100–168) calls `saveRDS(..., "../../data/processed/*.rds")` *during render*. So `mapa.qmd` is simultaneously a "page" (output) AND the producer of the tracked `data/processed/*.rds` aggregates. This breaks several recommendations:
- The `/objavi` skill says "render the whole site to `docs/` … **do not auto-commit**" and the HARD GATE warns only about "a FULL `quarto render` that overwrites docs/." Neither flags that a full render also **overwrites 10 git-tracked `.rds` files** — which is far more consequential than overwriting `docs/`.
- `single-source-of-truth.md` Directive 2: "Regenerate, never hand-edit `processed/*.rds`" — fine, but it never says *rendering a page regenerates them*, so a teammate rendering `diskurs.qmd` then `git add`-ing will commit stale/foreign processed `.rds` churn.
- The `/commit` skill "**warn** on … `processed/*.rds` changed without a `mapa.qmd` re-render" has the dependency backwards: processed `.rds` change *because* `mapa.qmd` rendered, on the master that only the PI has. On any teammate's clone without the master, `mapa.qmd` can't render and the saveRDS lines error — so the producer can never run for them anyway.
**Fix:** This is the real architectural problem the document missed. Recommend extracting the aggregate-production `saveRDS` calls out of `mapa.qmd` into `R/03_aggregate.R` (which §6.2 proposes anyway) so rendering becomes side-effect-free and pages only *read* `processed/*.rds`. Until then, every render/commit guard must treat `data/processed/*.rds` as a render side-effect, not a hand-edit.

**A4. The permission allowlist will not function as intended on this Windows machine.**
> `"Bash(Rscript *)"`, and `/azuriraj-podatke` "run via `Rscript`".
Verified: `Rscript` is **not on PATH** (`which Rscript` → nothing). The document acknowledges this in the `CLAUDE.local.md` seed ("Rscript: NOT on PATH … call full path") but then writes allowlist entries and skill steps assuming bare `Rscript`. A `Bash(Rscript *)` allow rule never matches `& "C:\Program Files\R\...\Rscript.exe"`. **Fix:** reconcile — either standardize on the full quoted path everywhere (and allowlist that), or instruct setup to add R to PATH as a prerequisite. As written, the daily-loop skills (`/azuriraj-podatke`, `/objavi` pre-flight) silently fail on the PI's own machine.

**A5. Allowlisting `Bash(rg *)`, `Bash(ls *)`, `Bash(wc *)` as the toolchain while telling agents to use Bash.**
Read-only agents pin `tools: ["Read","Grep","Glob","Bash"]`. Fine, but the broad `Bash(...)` allows plus `git add *` (which the doc admits is gated only "through the hook") means the safety story depends entirely on the PreToolUse hook being correct. The document itself says "the hooks must be correct before anyone turns on bypass" — yet schedules the git/data-guard hook and `bypassPermissions` for the SAME Day-1. **Fix:** ship and *test* the guard hook for at least a few days before documenting any `bypassPermissions` path; or drop bypass from the roadmap entirely (see D2).

## B. OVER-ENGINEERING — disproportionate to a 10-person descriptive academic project

**B1. Eight `.claude/rules/` + a separate quality-gates scoring rubric is still too much for Day 1.**
> "A tight set of **8 rules** (vs the guide's ~27)."
"Tight" is relative to an AER-grade fork, not to DigiKat. The `quality-gates.md` 11-line deduction table (`-20`, `-15`, `-10`, `-5`, `-3` …) is econometrics-referee theater applied to a sociology website. A 10-person team of mostly non-coders will never internalize an 11-row scoring rubric, and "applied at merge, not per commit" on a repo whose merge discipline is currently `weiter`/`los` means it will be applied **never**. **Fix:** collapse to 3 always-relevant rules (encoding, data-pipeline, quarto-verification) and replace the numeric quality-gate rubric with three plain sentences ("a touched page must render; numbers must trace to data; the master must be backed up before overwrite"). Defer the rest until a real incident motivates each.

**B2. `passport.yaml` numeric-provenance machinery is over-rated even as a deferred item.**
> §6.3 — per-page `passport.yaml` with `tolerance`/`last_verified`/`status`, `expr`/`assert`, and `/audit-reproducibility` to "gate `/commit`."
For a project with ~5 headline numbers (610k, 620 vars, 16 categories, 95 terms, date range) that change only on an append batch, a YAML provenance DSL with assertion expressions and a custom audit runner is a maintenance liability nobody on a sociology team will keep `last_verified` honest. The cheap PostToolUse grep flag (§5.2.1) already covers 95% of the value. **Fix:** delete `passport.yaml` from the roadmap entirely (not just defer it). If formal provenance is ever needed, a single `R/check_claims.R` that asserts the ~5 numbers is enough.

**B3. The agent roster is front-loaded with too many reviewers for the actual deliverable cadence.**
Eight agents including `croatian-nlp-reviewer` (opus/high/L), `religion-media-domain-reviewer` (opus/high), `quarto-page-critic` ⇄ `quarto-page-fixer` convergence loop (5-round cap), `devils-advocate`. The deliverable right now is a website and an infrastructure build — not manuscripts. An opus-tier 5-lens NLP reviewer and a hostile religion-media referee are paper-stage tools. **Fix:** Day-1/Week-1 needs exactly two agents: `verifier` (mechanical, haiku) and `r-reviewer` (the document correctly calls this "the highest-value reviewer"). Everything opus-tier moves to Phase 4 when papers exist. The critic⇄fixer auto-loop with a "converge after 2 clean rounds, 5-round cap" is over-engineered for single-page web edits.

**B4. Bilingual skill aliases, a "shared diacritic helper under `${CLAUDE_SKILL_DIR}`," and a `[LEARN]` tag taxonomy are speculative polish.**
> "/objavi (alias /deploy)", "Factor the diacritic/mojibake check into one shared helper", "[LEARN] tag taxonomy: croatian-nlp · lexicon · data-pipeline · encoding · quarto · workflow."
Building Croatian + English trigger aliases for ~12 skills, a shared helper script, and a six-category tag taxonomy before a single skill exists is premature abstraction. **Fix:** ship 2–3 skills with whatever single name the PI actually types; add aliases only when a real teammate is confused. Drop the tag taxonomy until MEMORY.md has >10 real entries.

## C. GAPS / OMISSIONS — important for THIS project, missing or under-developed

**C1. No reproducibility story for the fact that the *only* producer of the shared aggregates requires the gitignored master.** (See A3.) The document's whole "clone → run" narrative (synthetic sample, `--sample` mode, `DATA_AVAILABILITY.md`) never confronts that `data/processed/*.rds` — the "clone-friendly FAIR tier" it celebrates — is regenerated only by rendering `mapa.qmd` against the 610k master nobody else has. So the tracked aggregates are effectively **frozen artifacts only the PI can refresh**, and any teammate who renders will either fail or clobber them. This is the central reproducibility gap and it is unaddressed. **Fix:** make aggregate-production a standalone PI-run step that commits `data/processed/*.rds`; make all *pages* read-only consumers that render from tracked aggregates + synthetic sample, never the master.

**C2. Croatian encoding portability across machines is asserted but never operationalized for the actual failure mode.** The real Windows risk isn't the (nonexistent) stemmer bug — it's that `text_analysis.R` reads lexicons via `read.delim("./Codes/...")` with locale-dependent encoding, and R on Windows defaults to a non-UTF-8 locale (CP1250) unless `R >= 4.2` native-UTF-8 or explicit `encoding=`. The document's encoding rule says "read every file as UTF-8 explicitly" but never pins the R version / `options(encoding=)` / locale that makes diacritics survive `quarto render` on a second teammate's machine. **Fix:** add a concrete locale/version assertion to `r-code-conventions.md` and `/capture-environment` (R ≥ 4.2 or explicit `Sys.setlocale`/`fileEncoding`), since that is the actual portability lever.

**C3. The hardcoded-path bugs are under-scoped.** The document flags `write_tokens.R` (Dropbox path) and `load_merge_filter_religious.R` (global), but `text_analysis.R` reads **five** files from `./Codes/` (lines 5,13,26,40,41) — a directory that does not exist in the repo. The 3 sentiment lexicons (the empirical core of the "atmosfera diskursa" layer) are loaded from a phantom path. **Fix:** the Day-1 "two path bugs" should be "three broken scripts," and `text_analysis.R`'s `./Codes/` → `resources/lexicons/` repoint is the highest-value of the three because it blocks the entire sentiment layer, not just tokenization.

**C4. Windows hook portability hedge is incomplete.** The document correctly notes `python3` doesn't exist and uses `python`. But it never addresses that `$CLAUDE_PROJECT_DIR` expansion and `python "..."` quoting differ between the Git-Bash tool and PowerShell, and the team has 2 Mac/Linux members where `python` may be `python3`-only. A "one-line hedge in CLAUDE.md" is not a portable hook. **Fix:** have hooks resolve the interpreter (`sys.executable` shebang via a launcher, or test `python`/`python3`) rather than hardcoding `python`.

**C5. Nothing keeps the live website correct after a render fails halfway.** Because `mapa.qmd` writes `processed/*.rds` mid-render, a render that errors after `saveRDS(platform_summary)` but before later saves leaves a **partially updated tracked dataset** plus a stale `docs/`. There's no transactional/atomic-render guard. **Fix:** add to `quarto-verification.md`: render to a temp/staging area or verify all-or-nothing before staging `docs/` + `processed/`.

## D. PRIORITIZATION — what's front-loaded vs genuinely minimal

**D1. Day-1 is front-loaded.** It proposes: full `CLAUDE.md` + `MEMORY.md` (seeded with a FALSE bug entry, see A1) + `CLAUDE.local.md`, 3–5 rules, 3 skills, settings.json + 2 hooks, plus 2 repo fixes. That is a week of work mislabeled "Day 1," and one of its anchor justifications (the stemmer bug) is fiction. **Fix — genuinely minimal Day-1:** (a) the two *real* repo fixes — delete the duplicate root `.udpipe` and repoint `text_analysis.R`'s `./Codes/` + `write_tokens.R`'s Dropbox path; (b) a ~60-line `CLAUDE.md` stating the data lineage, the directory truth (README is wrong), and "render-before-done"; (c) the git/data-guard hook (the one thing that prevents catastrophe). Skills, the rule set, quality gates, and MEMORY seeding move to Week 1.

**D2. `bypassPermissions` + the guard hook on the same day is a sequencing error** (see A5). Bypass should be the *last* thing adopted, not Day-1, and arguably never for a team that "can't eyeball whether an R edit will corrupt the master." **Fix:** remove bypass from the documented path; keep `defaultMode: plan` for everyone including the PI until hooks have proven themselves.

**D3. `renv` should move EARLIER, not sit in Week-1/Month-1.** The document's own strongest argument — "ICU/stringi version shifts can silently change which posts pass the `≥2` filter via `stri_trans_tolower`" — means dependency drift can silently alter the corpus definition. That is a higher-stakes, lower-effort win than half the rules/agents. **Fix:** `renv::init()` + commit `renv.lock` belongs on Day 1, before any pipeline rule.

## E. The single most valuable thing FIRST, and the single most over-rated suggestion

**Most valuable FIRST:** Fix the three broken-path scripts and decouple aggregate-production from rendering (A3/C1/C3). Concretely: repoint `text_analysis.R` (`./Codes/` → `resources/lexicons/`) and `write_tokens.R` (Dropbox → `resources/lexicons/`), and move the `saveRDS(.../processed/*.rds)` calls out of `mapa.qmd` into a PI-run `R/03_aggregate.R`. This is what actually unblocks a second person from running anything and stops `quarto render` from mutating tracked data. It costs an afternoon and is worth more than the entire rules/agents/skills apparatus. The document buried this under §6.2/§6.6 as "two path bugs" and never identified the render-side-effect at all.

**Most over-rated:** The encoding layer as the "highest ROI / P0 / first-class" priority — justified by a mojibake bug that **does not exist** (A1). Closely tied for over-rated: the `passport.yaml` provenance DSL (B2). Both are solutions in search of a problem at DigiKat's current stage.

---

**Net assessment:** The document is well-structured and its translate-don't-copy instinct (dropping Beamer/TikZ/Stata/DiD) is correct. But it is built partly on a phantom bug, mis-states where numbers live, allowlists a binary that isn't on PATH, and entirely misses that the site's render mutates git-tracked data and that the "shareable FAIR tier" can only be regenerated by the one person holding the gitignored master. Verify file bytes before asserting bugs; the most cited "verified" fact (stemmer.R mojibake) was the tool's own corruption, not the repo's.

Relevant files: `C:\Users\lsikic\projects\DigiKat\R\stemmer.R` (clean, no mojibake — line 2), `C:\Users\lsikic\projects\DigiKat\pages\mapa\mapa.qmd` (saveRDS to processed/ during render, lines 100–168), `C:\Users\lsikic\projects\DigiKat\R\text_analysis.R` (5 `./Codes/` reads, lines 5–41), `C:\Users\lsikic\projects\DigiKat\R\write_tokens.R` (Dropbox paths, lines 38–39), `C:\Users\lsikic\projects\DigiKat\.gitignore`, `C:\Users\lsikic\projects\DigiKat\croatian-set-ud-2.5-191206.udpipe` (duplicate of resources/models copy).