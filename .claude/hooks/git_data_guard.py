#!/usr/bin/env python
"""
PreToolUse[Bash] guard for DigiKat.

Blocks destructive operations on irreplaceable, gitignored, or generated assets:
  - the master corpus            data/merged_comprehensive.rds   (gitignored, ~610k rows, not in repo)
  - its timestamped backups      *_backup_*.rds                  (the ONLY undo for a bad append)
  - the data/ tree and docs/ site (recursive deletes)
  - bulk/unscoped git staging    git add -A | --all | . | *      (could sweep in the master / backups)
  - adding the master/backups to git, and destructive git history ops (defense-in-depth; the
    settings.json deny list also covers reset --hard / clean -f / push --force / rm -rf)

Contract (Claude Code hooks): reads the PreToolUse event JSON on stdin; exit code 2 BLOCKS the tool
call and shows stderr to Claude; exit 0 allows. Fails OPEN (exit 0) on any parse error so it can never
block all Bash.

Portability: invoked as `python ...` (this machine has no `python3`). When Mac/Linux teammates adopt
this repo, switch the settings.json command to a `python3 || python` wrapper (python3 may be the only one there).
"""
import sys
import json
import re

# (regex, human reason). Matched case-insensitively against the command with backslashes -> slashes.
RULES = [
    (r"\bgit\b[^\n]*\breset\b[^\n]*--hard",
     "git reset --hard can discard uncommitted work."),
    (r"\bgit\b[^\n]*\bclean\b[^\n]*-[a-z]*f",
     "git clean -f permanently deletes untracked files (including the gitignored master and backups)."),
    (r"\bgit\b[^\n]*\bpush\b[^\n]*(--force|--force-with-lease|\s-f\b)",
     "Force-push can rewrite shared history."),
    (r"\bgit\s+add\s+(-A\b|--all\b|\.(\s|$)|\*)",
     "Unscoped 'git add' can stage the master, backups, raw .xlsx, or the .udpipe model. Stage explicit paths."),
    (r"\bgit\s+add\b[^\n]*(merged_comprehensive|_backup_)",
     "Refusing to git-add the master corpus or a backup (keep them out of git)."),
    (r"\bgit\s+rm\b[^\n]*(merged_comprehensive|_backup_|data/|docs/)",
     "Refusing 'git rm' on the data tree / docs site."),
    (r"\b(rm|del|unlink)\b[^\n]*merged_comprehensive",
     "Refusing to delete the irreplaceable master corpus (data/merged_comprehensive.rds)."),
    (r"\b(rm|del|mv|move|unlink)\b[^\n]*_backup_[^\n]*\.rds",
     "Refusing to delete/move a master backup (*_backup_*.rds) — it is the only undo for a bad append."),
    (r"\brm\b[^\n]*-[a-z]*r[a-z]*\b[^\n]*(/?data\b|/?data/|/?docs\b|/?docs/)",
     "Refusing a recursive delete of data/ or docs/."),
    (r"\brmdir\b[^\n]*(/?data\b|/?docs\b)",
     "Refusing to remove the data/ or docs/ directory."),
    (r"(^|[^>])>\s*[^>\n]*merged_comprehensive",
     "Refusing a redirect that would truncate/overwrite the master corpus."),
]


def main():
    try:
        event = json.load(sys.stdin)
    except Exception:
        return 0  # fail open: never block all Bash on a parse error
    if event.get("tool_name") != "Bash":
        return 0
    cmd = ((event.get("tool_input") or {}).get("command") or "")
    if not cmd.strip():
        return 0
    norm = cmd.replace("\\", "/")
    for pattern, reason in RULES:
        if re.search(pattern, norm, re.IGNORECASE):
            sys.stderr.write(
                "BLOCKED by DigiKat git/data guard: " + reason +
                "\nCommand: " + cmd.strip() +
                "\nIf this is genuinely intended, run it manually outside Claude "
                "(and back up data/merged_comprehensive.rds first)."
            )
            return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
