# Public barometer: implementation and verification

The author requested a finished public presentation and a substantive thematic
analysis of the available material. Implemented in the source page and rendered
to `docs/pages/demokrscanstvo/index.html`. No commit or deployment was performed.

## Public presentation

- Removed preliminary labels, the earlier AI-review commentary, archive-search
  process explanations and repeated limitations from the reading path.
- Rewrote the Croatian page around ideas, themes, platforms and media attention.
  Kept concise operational definitions in expandable method sections.
- Added a thematic explorer with platform/year filters, topic descriptions,
  characteristic vocabulary, platform counts, reset and empty states.
- Preserved monthly rates, collection boundaries, data tables, and downloads.
  Added static topic content for JavaScript-free use and printing.
- Public-policy labels remain separate from the new exclusive topic groups.
  Removed the unclassified category from the policy chart and explain its count
  in the accompanying text, rather than depicting it as a public-policy issue.
- Changed the expanded release's presentation status to `empirical`; historical
  validation provenance remains factual. No human-validation claim was added.

## Computed thematic analysis

All 2,306 included records were reconstructed from the original qualifying
A1/B/C contexts, using the frozen engine's normalization and boilerplate masks.
Croatian UDPipe processing produced 1,731 distinct contexts. A 1,372-term TF–IDF
matrix supplied the ten-component NMF model. One record without retained
vocabulary is displayed under “Ostali konteksti”; 2,305 have a primary topic.

The alternatives had 6, 8, 10 and 12 components. Leading words were compared
across alternatives, and six leading contexts per selected component were
inspected for naming. The ten-component solution separates political identity,
patriotic rhetoric, party cooperation, family/national identity, European
heritage, elections, intellectual discussion, values and international affairs.
The descriptions are editorial summaries of model components, not quotations.

Random-start adjusted Rand agreement was 0.658, 0.528 and 0.659. This indicates
moderate stability rather than uniquely determined categories; the resource
uses one reproducible fixed model and presents descriptive language groupings.
Exact repeated contexts are fitted once; near-duplicates and syndicated stories
can still shape components, which is relevant to interpreting media repetition.
The strongest examples often reflect recurring statements and events. These
checks do not estimate the original inclusion classifier's precision or recall.

Full method and reproducibility commands:
[THEMATIC.md](../studies/demokrscanstvo-barometar/THEMATIC.md).
Design references are linked there. Private text, annotations, candidate models
and record assignments remain in the configured external work directory.

## Verification

- All topic counts reconcile exactly against every platform/month in the base
  release; the public thematic totals sum to 2,306.
- Both published aggregate directories and the rendered payload pass checksum,
  schema, total, proportion and provenance checks.
- Eight JavaScript tests pass, including all live platform/year intersections,
  zero-versus-missing behavior and collection boundaries.
- Two fabricated Python extraction/aggregation fixtures pass; the 24-text R
  contextual-policy regression passes.
- `tests/run_tests.R`: all 69 shared regression checks and all barometer suites
  pass. The R setup emits existing locale/renv startup notices.
- `R/check_disclosure.R`: passes for 270 trackable study/public artifacts.
- Quarto single-page render succeeds. No changes to `data/processed/`.
- Site quality checks pass for 127 active pages; link/anchor/encoding checks
  pass for 137 HTML files.
- Browser checks pass at 320, 375, 390, 768, 1024, 1366, 1440 and 2048 pixels:
  overflow, accessibility, reduced motion, keyboard controls, live announcements,
  theme selection, empty results, reset, data values and no-JavaScript content.
- Desktop (1440) and mobile (390) screenshots were visually inspected after
  the final layout pass; controls, labels and topic details render cleanly.
  Screenshots: [desktop](screenshots/2026-09-19-barometar-themes/barometar-themes-1440.png)
  and [mobile](screenshots/2026-09-19-barometar-themes/barometar-themes-390.png).
- `git diff --check` passes. Existing unrelated worktree files were preserved.

CI now checks the thematic public release and filters in addition to the
existing barometer checks. NLP fitting runs explicitly, separately from rendering.
