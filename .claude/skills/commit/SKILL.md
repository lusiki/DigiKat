---
name: commit
description: Stage, quality-gate, commit, and optionally open a PR for DigiKat with a clear Conventional-Commit message. Use when the user says "commit", "commit this", "open a PR", "save my changes", or after a completed task. Blocks staging the gitignored master, backups, raw .xlsx, or the .udpipe model; warns on data/processed/*.rds changes. NOT for deploying the site (use /deploy) or refreshing data (use /refresh-data).
argument-hint: "[optional commit message or scope hint]"
---

# /commit — quality-gated commit for DigiKat

## Instructions
1. **Survey.** Run `git status --short` and `git branch --show-current`. Show the user what changed. If on
   `main` and this is a multi-file feature, offer to branch first (`git checkout -b <type>/<slug>`).
2. **Forbidden-artifact gate (BLOCK).** Inspect what is staged / about to be staged. REFUSE to proceed if
   any of these are included: `data/merged_comprehensive*.rds`, `*_backup_*.rds`, `data/raw/**/*.xlsx`,
   `*.udpipe`, or any file > 50 MB. These must stay out of git. (The git/data guard hook also blocks
   `git add -A` — always stage explicit paths.)
3. **Processed-data check (WARN, don't block).** If `data/processed/*.rds` is modified, confirm WHY with
   the user: it must be the output of `R/03_aggregate.R`, never a hand-edit and never a render side-effect.
4. **Diacritic gate.** If any `.qmd` / `.md` / `.R` text file is staged, spot-check for mojibake
   (replacement chars or numeric entities where Croatian letters belong). Flag before committing.
5. **Verify.** Launch the `verifier` agent (Task tool, `subagent_type: "verifier"`) on the change-set. If
   it returns `VERDICT: FAIL`, report and stop unless the user explicitly overrides.
6. **Message.** Draft a Conventional-Commit message: `type(scope): summary`. Types: feat, fix, data, docs,
   chore, refactor, style. Scope = the area (e.g. `mapa`, `pipeline`, `lexicon`, `site`, `workflow`).
   Body: what + why (1–3 lines). This deliberately replaces the old `weiter` / `los` habit.
   Example: `data(pipeline): append Q2-2025 batch (+8,412 rows, 14.3% pass-rate)`.
7. **Commit.** `git add <explicit paths>` then `git commit`. Never `git add -A` / `.` / `*`.
8. **PR (optional).** If asked, `gh pr create` with a title + summary body.

## Examples
- "commit this" → survey → gate → verify → propose message → commit.
- "commit and open a PR for the diskurs page" → branch if needed → commit → `gh pr create`.

## Troubleshooting
- Guard hook blocked a `git add`: you used `-A` / `.` / `*`. Stage explicit paths instead.
- Forbidden artifact staged: `git restore --staged <file>` — it belongs in `.gitignore`, not the repo.
