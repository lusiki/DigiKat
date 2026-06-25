---
paths:
  - "explorations/**"
---

# Exploration Folder Protocol

`explorations/` is the sandbox for throwaway analyses a 610k-row corpus invites. Lower rigor (~60/100),
fast-track, explicit kill-switch.

Layout:
```
explorations/<slug>/    README.md (question, status, kill-by date), *.R, output/
explorations/ARCHIVE/   completed_<slug>/ · abandoned_<slug>/
```

Rules:
1. Explorations may **READ** the master / `data/processed/*.rds` / `data/sample` — but **never write** into
   `data/`, `pages/`, `docs/`, or `studies/`. Outputs stay in `explorations/<slug>/output/` (gitignored).
2. Heavy slices: `data.table` + sample first; don't load 610k rows casually.
3. Fast-track: skip formal planning, but do a 2-minute value check first ("does this improve a page / study /
   the analysis?"). If "no", don't build it.
4. Kill-switch: anything untouched > 2 weeks gets flagged for ARCHIVE with a one-paragraph why. No guilt.
5. Graduation: when an exploration earns its place, MOVE the code to `R/` or `studies/<slug>/` and upgrade to
   full rigor (plan-first, `r-reviewer`, reproducible paths). Quality reports only at graduation, not per commit.
