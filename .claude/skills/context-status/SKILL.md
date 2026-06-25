---
name: context-status
description: Report current Claude Code session health for DigiKat — approximate context usage, the active plan, and recent decisions, with a nudge to capture learnings before compaction. Use when the user says "context status", "how full is context", "/context-status", or during a long session that may be near compaction.
argument-hint: "(no args)"
---

# /context-status — session health

## Instructions
1. Report approximate context fullness qualitatively (low / moderate / high) based on session length and
   tool-call volume.
2. Point to the most recent active plan in `quality_reports/plans/` (if one exists).
3. List the last few decisions from any session log under `quality_reports/session_logs/` (if present).
4. If context seems high, suggest capturing learnings NOW: add `[LEARN]` entries to `MEMORY.md`, save/update
   the active plan, and consider `/compact` with a focusing instruction (e.g. "compact, focusing on the
   pipeline change").
