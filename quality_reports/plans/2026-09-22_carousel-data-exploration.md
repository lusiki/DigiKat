# Carousel revision around the data

The author explicitly identified slides 10–15 (six qualitative cases) for
replacement with exploratory data views. Keep the approved 18-slide conference
design and no-pink palette. Replace unclear reader-facing “barometar” vocabulary
with concrete descriptions of the collection/analysis, and rename the platform
slide to describe differences in themes.

Read the frozen 2,306 included records only. Derive public aggregate tables for
the 1,811 web articles, reconcile monthly/topic counts against the existing public
releases, and leave the corpus, inclusion rules, models and existing reports alone.
No private article bodies, record keys or row-level exports enter the publication.

Replace slides 10–15 with selected named public figures (one count per article,
full-name matches with Croatian inflections), leading sources, monthly article
counts, the four busiest months, leading topics in those months, and the busiest
day. Describe selected people as mentioned, never as inferred political supporters.
Explain the available-text unit, changing collection coverage and partial 2026.
Update the concluding synthesis and resource links to match the revised story.

Implement reproducible calculations in a dedicated preparation script. Record
input hashes, matching rules and aggregate evidence. Keep row-level inspection in
ignored output only. Build the HTML and PDF from the existing carousel source,
verify counts independently, check fit, keyboard controls, responsive layout and
accessibility, then visually inspect every rendered slide. Carry forward the
author's authorization to replace the existing published carousel and commit/push.
Publish only the scoped assets and authoring changes; leave all unrelated dirty
files from previous work untouched.

## Verification

- Public monthly and topic counts reconciled with all 1,811 frozen web articles.
  Reviewed the matched name forms and local title examples. Published only
  aggregate counts, matching patterns, limitations and provenance hashes.
- Rebuilt all 18 slides and the tagged PDF. Reviewed all rendered PDF pages.
  Numeric checks, embedded fonts, 32 links and publication hashes pass.
- Carousel browser checks pass with no axe violations, working keyboard controls
  and no clipping at 320, 390, 768 and 1024 pixels.
- Focused Quarto render of `pages/demokrscanstvo/index.qmd` passes. Automatic
  approval review rejected the full-site render because of unrelated pre-existing
  work and explicitly recommended the focused render. No attempt to bypass it.
- Static site checks pass for all 127 active pages. The modified landing page
  passes browser checks at eight widths from 320 to 2048 pixels.
- Site link check passes for 140 HTML files with no missing targets, anchors or
  mojibake signatures. No corpus or existing aggregate files changed.
