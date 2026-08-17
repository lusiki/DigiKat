# Moj medij behavioural and topic profiles

**Status:** implemented and verified

## Goal

Add five full-corpus diagnostics to every eligible profile on `pages/moj-medij.qmd`: attention concentration,
publishing rhythm, an outlet-versus-field calendar test, outlet topic mix versus its same-platform field, and
the nearest listed sources by topic profile.

## Rationale and constraints

- Compute from the official corpus and publish only compact source-level aggregates. Never publish post text,
  URLs, identifiers, or the ten leading posts.
- Compare concentration only within the same platform. Show a platform peer median so percentages have context.
- Treat zero-interaction rates as measurement properties as well as possible audience signals. Do not compare
  them across platforms.
- Audit the vendor `TIME` field once for parseability, precision, missingness, timezone semantics, and agreement
  with any timestamp-bearing field before enabling hour bands. If reliability cannot be established, retain a
  weekday-only result and make the limitation explicit.
- Suppress rhythm cells with fewer than 20 posts. Engagement in a cell means interactions per post, and the
  interpretation remains descriptive rather than causal.
- Reuse the annual-report event registry and date exclusions. Apply the identical measurable dates to outlet and
  field denominators. Mark an event unmeasurable when its event window or baseline overlaps a collection gap;
  specifically, Easter 2024 must never appear as zero.
- Preserve the existing disclosure gate. New aggregates are emitted only for sources already eligible for the
  public lookup.
- Extend the provisional news-gap dictionary method to the full corpus using the title plus the first 3,000 body
  characters, with no udpipe dependency. Fractionally allocate posts when several topics tie for the largest
  match count.
- Show topic comparisons only from 100 classified posts. The peer value is an equal-weight average of eligible,
  listed sources on the same platform, not a cross-platform or large-outlet-weighted field total.
- Keep the PI decision of 2026-08-13 visible: dictionary results are validation leads, not rankings.
- Compute cosine similarity only among eligible public profiles on the same platform. Publish three or four
  neighbour names, without scores, and describe them as sources with a similar topic profile rather than
  competitors.

## Implementation

1. Audit corpus schema and `TIME` reliability without changing the corpus or master.
2. Extend `R/06_moj_medij.R` to read the official corpus, compute validated compact aggregates, and attach them
   to `data/page-ready/moj_medij.json` under a schema-version bump.
3. Extend the client-side profile renderer in `pages/moj-medij.qmd` with metric cards, a 7 by time-band heatmap,
   and a compact paired-bar event table. Add accessible text and explicit methodological notes.
4. Add deterministic tests for metric formulas, suppression, matched event dates, and disclosure-safe output.
5. Add a chunked full-corpus dictionary classifier and reduce it immediately to compact source-platform-topic
   vectors. Precompute equal-weight peer means and cosine neighbours in R.
6. Add a 16-topic source-versus-peer dumbbell chart, a visible provisional label, support-floor states, and
   clickable similar-source links to the client renderer.
7. Run the generator in preview, install the refreshed JSON with `--apply`, run tests and disclosure checks, and
   render only `pages/moj-medij.qmd`. A full-site render is outside this change and remains a separate hard gate.

## Rejected alternatives

- Computing in the browser is rejected because it would require shipping row-level corpus data.
- Showing the top ten posts is rejected by the publication constraint.
- Cross-platform zero-rate comparison is rejected because vendor recording differs sharply by platform.
- Causal timing advice is rejected because publication time is confounded with content and event type.
- Hand-entering event dates is rejected where the annual-report registry can remain the single source of truth.

## Verification

- `Rscript R/06_moj_medij.R`
- `Rscript R/06_moj_medij.R --apply`
- focused unit tests and `Rscript tests/run_tests.R`
- `Rscript R/check_disclosure.R`
- `quarto render pages/moj-medij.qmd`
- inspect generated HTML for literal Croatian diacritics, accessible labels, suppressed cells, and no row-level data

## Result

- `R/06_moj_medij.R --apply` produced schema v4 for all 356 public profiles. The artifact contains 3,144
  rhythm cells at or above the 20-post threshold and ten reviewed calendar events across 2024 and 2025.
- The dictionary classified 316,147 corpus posts. Of the public source-platform records, 362 clear the threshold
  of 100 classified posts: 305 web, 41 Facebook, 12 YouTube, two comment, and two forum profiles.
- All 305 web, 41 Facebook, and 12 YouTube topic profiles have four same-platform neighbours. The two comment
  and two forum profiles retain their topic comparison but correctly omit neighbours because fewer than three
  eligible public peers exist. TikTok, Twitter, and Instagram profiles remain below the classification floor.
- Public topic vectors and equal-weight peer vectors each reconcile to 100%. Neighbour payloads contain names
  only, resolve to eligible listed profiles on the same platform, exclude the profile itself, and contain no
  similarity scores.
- The `TIME` audit passed all 413,985 rows and matched Europe/Zagreb time in all 3,860 Twitter checks.
- Easter 2024 is unmeasurable because of the collection gap. All other registered profile events are measurable.
- All 63 focused regression checks passed. The page rendered without Quarto warnings, its JavaScript compiled,
  and a headless browser rendered `hkm.hr` with 16 topic rows, the provisional label, and clickable neighbours.
- The site-link check passed and `data/processed/` remained byte-untouched.
- Two repository-wide legacy checks remain red for unrelated pre-existing files. `R/check_sources.R` reports four
  mojibake signatures outside this change. `R/check_disclosure.R` reports the tracked moral-economy diagnostics
  column `context`; no changed Moj medij artifact contains row-level text, URLs, or identifiers.
