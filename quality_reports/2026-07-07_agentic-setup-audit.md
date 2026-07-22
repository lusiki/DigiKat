# DigiKat Agentic Setup — Audit against Sant'Anna's "My Claude Code Setup"

**Date:** 2026-07-07 · **Guide:** https://psantanna.com/claude-code-my-workflow/workflow-guide.html
(Pedro H. C. Sant'Anna, *My Claude Code Setup*, rev. 2026-06-10)
**Method:** the full guide (157 KB text, 9 top-level sections) was compared against every file in
`.claude/`, `CLAUDE.md`, `MEMORY.md`, `CLAUDE.local.md`, and `quality_reports/` by an 11-agent workflow
(1 inventory + 9 per-dimension gap analyses + 1 completeness/prioritization critic). Facts marked ✓ were
re-verified by hand.

> **Headline:** DigiKat is in the **top decile** of academic Claude Code setups measured against this guide.
> It already has the structural spine the guide argues for, and has correctly *rejected* the guide's
> slide-shop / econometric / heavy-orchestration machinery as non-applicable. The remaining gaps are a
> **handful of cheap, high-leverage rule/skill/config additions**, not architecture. The main risk now is
> the opposite of under-building: resist cargo-culting the guide's ceremony.

---

## 1. What you have today (inventory)

**Constitution & memory (the guide's §4.1, §4.8)**
- `CLAUDE.md` — 90-line constitution: 8 numbered core principles, one-way data-flow contract, directory
  conventions, controlled analytical vocabulary, key-commands table, skill quick-reference. Self-caps at
  "< 150 lines; detail lives in rules" — exactly the guide's instruction-budget discipline.
- `MEMORY.md` — committed, project-shared `[LEARN]` log + key-facts + corrections + a Phase-0 issue backlog.
  Captures subtle domain traps (2024 collection-method confound → the 2025 "surge" is an artifact; 47-not-620
  columns; 95-not-93 terms; the Quarto site-wipe incident).
- `CLAUDE.local.md` — gitignored machine layer: `R_AVAILABLE`, off-PATH Rscript/Quarto paths, master
  presence (~1.19 GB), the Dropbox-inside-repo hazard.
- Global auto-memory (`~/.claude/projects/.../memory/`) — index + `catholic-memory-study-design`,
  `cooccurrence-not-engagement` house rules.
- `.claude/references/discipline-card-digikat.md` — steers the scholar-* skills away from
  economics/causal-inference defaults toward descriptive sociology-of-religion / media norms.

**Rules — 6 (`.claude/rules/`, the guide's §4.2 path-scoping)**
- `plan-first-workflow.md` — **always-on**; plan threshold + fast-track carve-out + **HARD GATE** on
  master/aggregate/docs-overwriting ops (a domain escalation the guide lacks).
- `data-pipeline-protocol.md` *(paths: R/**, data/**)* — backup-before-overwrite, `min_matches <- 2L`
  inclusion contract, delta reporting, R-absent hand-off.
- `quarto-verification.md` *(paths: pages/**/*.qmd, _quarto.yml)* — compile-before-done, render-from-root,
  no scatter outside `docs/`, no data side-effects.
- `voice-and-style.md` *(paths: pages/**/*.qmd)* — 13 KB Croatian house voice: terminology canon, number
  conventions (610.000, 12,3 %), a mandated 5-part analytical-page spine.
- `croatian-encoding.md` *(paths: R/**, lexicons)* — defensive UTF-8 / diacritic integrity.
- `exploration-folder-protocol.md` *(paths: explorations/**)* — sandbox: read-only on data, 2-week
  kill-switch, graduation path.

**Agents — 5 (`.claude/agents/`, the guide's §3, §4.5) with a real multi-model roster**
- `verifier` (**haiku**) — mechanical PASS/FAIL: render succeeded, no `data/processed` mutation, backup exists.
- `numeric-claim-verifier` (**sonnet**) — fresh-context re-derivation of headline numbers; cannot self-confirm.
- `r-reviewer` (**sonnet**) — reproducibility / path-portability / silent-data-loss / 610k-perf / encoding.
- `croatian-nlp-reviewer` (**opus**) — the guide's explicit **5-lens** domain reviewer, adapted to Croatian NLP.
- `religion-media-domain-reviewer` (**opus**) — substance + a **hostile-referee** pass.
  All five are **read-only** (no Write/Edit) — the incentive-separated "critic" half of the guide's pattern.

**Skills — 14 (`.claude/skills/`)** — deploy, render-page, refresh-data, commit, data-analysis,
check-lexicon, review-page, review-paper, new-study, lit-review, research-ideation, capture-environment,
disclosure-check, context-status. These *are* your slash commands; each wraps a house rule as one command
with guardrails (sample-first analysis, PII pre-flight, a commit that refuses to stage the master).

**Enforcement — hook + permissions (the guide's §4.6, §8.4)**
- `.claude/hooks/git_data_guard.py` — PreToolUse[Bash] regex guard, **fails open**; blocks master/backup
  deletion, unscoped `git add`, recursive `data/`·`docs/` deletes, and a **docs-wipe commit** (≥3 `docs/*.html`
  deletions = a render that emptied the site). Materially stronger than the guide's `git-guardrails.py`.
- `.claude/settings.json` — allow/deny lists, `defaultMode: "plan"`, `plansDirectory: "quality_reports/plans"`.
- `quality_reports/plans/` — ~16 real dated plans; plan-first is *practiced*, not just documented.

---

## 2. Distinctive strengths (better than a default project — and in places better than the guide)

1. **Data-flow as an enforced invariant, not a convention** — one-way DAG (raw → ≥2-match filter → master →
   processed → pages → docs) enforced redundantly by rule + hook + verifier agent.
2. **Defense-in-depth around one irreplaceable asset** — the 1.2 GB gitignored master is guarded by the deny
   list, the fail-open hook, and a backup-before-overwrite rule.
3. **Explicit machine-gating** — `R_AVAILABLE` + every skill's "hand off, don't fake it" clause lets the same
   config work correctly on a machine that can't run the pipeline.
4. **Cost-aware agent tiering** — haiku for mechanical, sonnet for review, opus reserved for the two
   substance-critical reviewers. This is the guide's 70/20/10 routing, done right.
5. **Deep Croatian-domain encoding** — a full voice/style rule + defensive UTF-8 rule + a corrections log of
   real data traps. Rarely seen in any repo.
6. **Right *adaptation* calls** — replaced the guide's slide-shop 80/90/95 numeric score with a more honest
   verify-by-render + numeric-claim-verifier discipline, and correctly rejected git worktrees (Dropbox hazard)
   and Beamer/econometrics machinery.

---

## 3. Coverage vs the guide

| Guide building block | DigiKat status |
|---|---|
| CLAUDE.md as slim constitution (§4.1) | ✅ Present (90 lines, self-capped) |
| Path-scoped rules (§4.2) | ✅ Present (5 path-scoped + 1 always-on) |
| **R-code-conventions rule (§4.2.1 flagship example)** | ❌ **Absent — biggest single gap** |
| Constitutional governance (§4.3) | 🟡 De-facto via HARD GATE (guide says skip formal doc for solo — correct) |
| Requirements spec for complex tasks (§2.5) | 🟡 Plans cover most; a spec would help *study* kickoff |
| Skills / slash commands (§4.4, §7.4) | ✅ 14 skills; none set `effort:` (§4.7) |
| Specialized read-only critic agents (§3.1, §4.5) | ✅ Present, multi-model |
| Adversarial critic **+ fixer loop** (§3.2) | 🟡 Critic half only; no fixer, no loop-until-dry |
| Domain reviewer 5-lens (§3.5) | ✅ Present (croatian-nlp-reviewer) |
| 80/90/95 numeric quality score (§3.4) | ⬜ Deliberately not adopted (slide-specific; boolean gate is more honest) |
| Six-layer permissions / Plan→Bypass (§4.6) | 🟡 One CLI layer only; **no `settings.local.json`**; allowlist inert for off-PATH R/Quarto ✓ |
| Effort levels (§4.7) | ❌ Not configured anywhere ✓ |
| Two-tier memory + /promote-memory (§4.8) | 🟡 Three overlapping stores, no reconciliation protocol |
| **Session logs (`session_logs/`, §5.1.4)** | ❌ **Absent — `context-status` already points at the missing dir** ✓ |
| Context-survival hooks (PreCompact/SessionStart, §4.8.5) | ❌ Absent (plans-on-disk partly cover) |
| Plan-first (§5.1) | ✅ Present + stronger (HARD GATE) |
| Orchestrator / contractor mode (§5.2) | 🟡 In-spirit inside skills; no formal runtime (correct at this scale) |
| Replication-first + passport (§5.5) | 🟡 "No hand-typed numbers" enforced; no committed numeric anchor |
| Self-improvement `/learn` (§5.7) | 🟡 `[LEARN]` tags yes; no skill-promotion path |
| Devil's advocate (§5.8) | 🟡 At manuscript stage (review-paper); none at *plan/design* time |
| Parallel agents + Monitor tool (§5.9.1) | 🟡 Agents exist; parallel fan-out + backgrounding not encoded |
| Exploration folder (§5.9.2) | ✅ Present (rule + scaffold) |
| Research-skill dependency graph (§5.9.3) | 🟡 All nodes exist; no map (no `studies/README.md`) |
| Git worktrees (§5.9.4) | ⬜ Contra-indicated (Dropbox) — record the "no" |
| Reproducibility / AEA (§5.10.1) | 🟡 DATA_AVAILABILITY + capture-env built; **no LICENSE, no ENVIRONMENT.md/renv.lock** ✓ |
| Rhetoric of decks (§5.10.2) | ⬜ N/A (no slides; principles already in theme_digikat + voice-and-style) |
| Sequential adversarial audits (§5.10.3) | 🟡 Parallel/merged review; no blind sequential pass |
| Preregistration (§5.10.4) | 🟡 Deliberately scoped to one future study (correct) |
| MCP servers (§6.7, §7.5) | 🟡 **`perplexity` MCP referenced in lit-review but not provisioned** ✓ |
| Plugins / team-onboarding (§6.9, §7.6) | ⬜ Defer (solo team) |

✅ present · 🟡 partial · ❌ genuine gap · ⬜ deliberately not adopted

---

## 4. Prioritized extensions (the roadmap)

Ranked by leverage-for-a-solo-researcher × low friction. Effort: S(< 1 h) / M(a few h) / L(a day+).

### Tier A — do these first (cheap, close real gaps)

1. **`r-code-conventions.md` rule** — S · *paths: `R/**`, `studies/**/*.R`, `explorations/**/*.R`*.
   Codify the R standards now scattered as `MEMORY.md` prose so they auto-surface when an `.R` file is
   edited: `set.seed(YYYYMMDD)` once at top, `library()` at top, repo-relative paths (kills the `./Codes/`
   and hardcoded-Dropbox-path bugs), explicit UTF-8 reads, **always `source(R/theme_digikat.R)` and route
   colours through `dk_col`/`scale_*_digikat()` (never hardcode / `theme_void()`)**, data.table + sample-first.
   *This is the guide's flagship §4.2.1 example and your single clearest missing layer.*

2. **Machine-local `settings.local.json`** — S (gitignored). Two fixes in one file:
   (a) allow the **off-PATH absolute-path** R/Quarto invocations (`"Bash(\"C:/Program Files/R/R-4.4.1/bin/Rscript.exe\" *)"`
   + the RStudio quarto path) — your two most-run commands currently fall through the allowlist and prompt
   every time ✓; (b) optionally `defaultMode: "bypassPermissions"` so after plan-approval work runs
   prompt-free. Safe here *because* `git_data_guard.py` still blocks master/backup/site wipes even under bypass.

3. **Add the `LICENSE` file(s) you already claim** — S. `CLAUDE.md` + `DATA_AVAILABILITY.md` assert CC BY 4.0
   open science, but **no LICENSE exists** ✓ and the MIT-vs-CC code question is open. Add `/LICENSE`
   (CC BY 4.0 for data + content) and, if code is MIT, `/LICENSE-CODE.txt`. Cheapest FAIR/credibility win.

4. **Run `/capture-environment` and commit `ENVIRONMENT.md` + `renv.lock`** — S (on the pipeline machine).
   The skill exists but the artifact was **never produced** ✓, so exact R/locale/package/udpipe versions are
   undocumented. Zero new code — just execute what's built.

5. **`HEADLINE_NUMBERS.yaml` passport + `numeric-provenance.md` rule** — M. Anchor every load-bearing figure
   (710,307 rows, 47 vars, 95 terms, 16 categories, per-platform confessional shares, date range) to the exact
   script + expression that produces it, with a tolerance; have `numeric-claim-verifier` and `/review-page`
   **diff prose against the anchor** instead of re-deriving each time. Targets your demonstrated failure mode
   (stale 608,879-row aggregates; "620 variables" drift).

### Tier B — high value for the studies stream / long sessions

6. **Session-log scaffolding** — S. Create `quality_reports/session_logs/` and add a short "Session log"
   section to `plan-first-workflow.md` (write goal + rejected alternatives at approval; 1–3-line entries on
   each decision; close with open questions). Fixes the **dead reference** in `context-status` (which already
   points at this non-existent dir ✓) and captures the *why* (e.g. why the 2024 stream-change confounds a
   trend claim) that git + plans don't.

7. **Plan-time devil's-advocate skill** — S · `.claude/skills/devils-advocate/SKILL.md`. Spawn a fresh agent
   given **only** the plan/artifact (not the conversation) that raises 5–7 challenges tuned to your documented
   traps (collection-method confound, co-occurrence ≠ engagement ~7×, contestable outlet labels, lexicon
   under-matching), and reports what survives. Fills the gap between fast-track edits and full manuscript
   review — challenge a *design* before you build it.

8. **Per-study `REPLICATION.md` exhibit→script map** — M. Add to `_STUDY_TEMPLATE/` (propagated by
   `/new-study`); a table mapping each figure/table in `output/{figures,tables}` to its generating R script
   (+approx line) and input slice. Backfill `studies/catholic-education/` first (nearing submission). The
   useful 80 % of the guide's AEA "Table/Figure Mapping" without the YAML tooling.

9. **Reconcile the three memory stores** — S · `.claude/rules/memory-map.md`. 15 lines declaring what each of
   `MEMORY.md` (committed project) / `CLAUDE.local.md` (machine config) / global auto-memory (study notes)
   owns, plus a 5-line dedupe checklist. Prevents the same fact drifting/contradicting across stores.

### Tier C — throughput & hygiene (low effort, do opportunistically)

10. **Set `effort:` on mechanical skills** — S. `effort: medium` (or low) on `/commit`, `/render-page`,
    `/context-status`; keep the Opus-4.8 high default on `/review-paper`, `/data-analysis`, `/lit-review`.
    Free token cut, no quality loss ✓ (none set it today).
11. **Encode parallel reviewer fan-out + a Monitor pattern** — S. State in `/review-page` & `/review-paper`
    that the independent reviewers run in parallel (fork, ~3 at a time) then synthesize; add a note to
    `data-pipeline-protocol.md` to launch long udpipe/append/render jobs with `run_in_background` + the
    Monitor tool (and still emit the exact backgrounded command when R is machine-gated off).
12. **Reconcile the phantom `perplexity` MCP** — S. `/lit-review` calls `perplexity_research`/`perplexity_search`
    but **no `mcpServers`/`.mcp.json` exists anywhere** ✓ (it does degrade gracefully). Cheapest correct fix:
    repoint the skill at the built-in **WebSearch/WebFetch** tools (available here) and keep the fallback line.
13. **`studies/README.md` dependency map** + one `MEMORY.md` line recording **worktrees are contra-indicated**
    (Dropbox) — S. Orients the studies pipeline and pre-empts a future worktree mistake.
14. **Small accuracy fixes** — S. `CLAUDE.md` calls all six rules "Auto-loaded"; only `plan-first` is
    always-on — the rest are path-scoped. Add descriptive names + a `Status: COMPLETED` footer convention to
    plans (retire codename slugs like `jolly-stirring-sketch.md`).

---

## 5. Deliberately NOT adopting (honest scoping — record these as "not now")

The guide is written for an economist shipping Beamer slides and causal-inference papers to AEA/RES. These
parts don't map to a descriptive-text-analysis Quarto + studies repo, and adopting them would be ceremony a
one-person team won't sustain:

- **80/90/95 numeric quality score + pre-commit score gate** — slide/proofreading-specific; your boolean
  PASS/FAIL gates (verifier + forbidden-artifact + diacritics + numeric-mismatch) are more honest for a data repo.
- **Formal `constitutional-governance.md` Articles doc** — the guide itself says skip for solo repos; your
  HARD GATE already *is* the immutable-articles set. (At most, add a 3-line "immutable articles" pointer.)
- **Deterministic orchestrator runtime / loop-until-dry / hallucination-guard** — over-engineered for 5 agents.
- **Git worktrees** — actively contra-indicated (repo lives inside Dropbox → `.git` confusion + render
  file-locking). Use feature branches + `/commit`'s auto-branch.
- **Rhetoric-of-decks / slide-auditor / Beamer / MB-MC / 24pt rules** — no slides; the transferable chart
  principles already live in `theme_digikat.R` + `voice-and-style.md` + the `dataviz` skill.
- **stata-mcp, AEA 8-section README + README.pdf, agent-debates over DiD/SC/RDD, aspredicted/aea-rct prereg,
  `program.md` (autoresearch), third-party plugins, `/team-onboarding`** — R-not-Stata, descriptive-not-causal,
  no experiments, no compute-search loop, solo team. Revisit `/team-onboarding` when a second maintainer joins.
- **Full context-survival hook stack (`context-monitor.py` 40/55/65/80/90 % warnings, `/compress-session` +
  `/checkpoint` split)** — the qualitative `/context-status` skill + plans-on-disk cover the need; a lightweight
  PreCompact→SessionStart *restore* pair (writes active plan path + first unchecked task) is the only piece
  worth adding, and only if long renders keep hitting auto-compaction.

---

## 6. Suggested sequencing

- **This week (all S):** #1 r-code rule · #2 settings.local.json · #3 LICENSE · #10 effort tiers ·
  #12 lit-review WebSearch fix · #14 accuracy fixes. ~2 hours total, all reversible.
- **Next (needs the pipeline machine):** #4 capture-environment → commit ENVIRONMENT.md + renv.lock.
- **Before the next study milestone:** #5 numbers passport · #6 session logs · #7 devil's-advocate ·
  #8 REPLICATION.md (backfill catholic-education) · #9 memory-map.

None of these touch the master, `docs/`, or the inclusion rule; all are additive config/docs and fit the
fast-track tier. The passport (#5) and the R-conventions rule (#1) are the two that most directly defend
against your own documented failure modes.
