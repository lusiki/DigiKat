# Gap register

Status after edition 1 (reporting year 2025, built 2026-08-10). Effort: S ≤ half day; M one to two
days; L three to five days; XL more than five days or new data / an external decision.

## Closed by edition 1

| Gap | How it was closed |
|---|---|
| Stream-aware platform / year / month aggregate | The report cuts its own aggregates from the corpus, which carries `dk_era` and `data_source` on every row. One within-stream comparison is published (H2 2024 vs H2 2025) with the source count beside it. |
| Complete annual sixteen-theme table | All sixteen categories are reported under one denominator, with a second column for dominant-theme share and an explicit no-theme remainder. |
| NLP layers cut from the corpus | The NLP generation of 2026-08-10 is drawn from the corpus itself; stage 02's membership check now resolves at 100 % and remains as a guard. |
| Annual tone and conflict aggregate | Tone and the conflict-word index are computed for the reporting year, per theme and per source label, with document counts and 95 % intervals. |
| Calendar coverage for events | All 365 days are materialised. The fourteen-day collection outage is detected, disclosed, excluded from the baseline, and removed from both halves of the stream comparison. |
| Engagement benchmark denominator | Interaction and reach coverage is measured per platform; a platform below the coverage floor is excluded from those statistics and printed as "nije zabilježeno" rather than zero. |
| Actor year × platform panel (partial) | A 2025 actor × platform panel exists, with an eligibility floor of twelve posts and per-platform median splits. |

## Opened by edition 2 (reporting year 2024)

| Priority | Gap | Why it matters | Effort | Owner role | Acceptance condition |
|---|---|---|---:|---|---|
| Critical | 2024 collection interruptions | 159 of 366 days carry nothing, including Easter (31 March). Not recoverable; the annual total is a lower bound | — | — | Cannot be closed. Every comparison involving 2024 must state it |
| High | No year-over-year measure for 2024 | The post-2024 stream begins mid-year, so 2024 has no instrument-comparable predecessor. Published as a within-year quarter step instead, with the seasonal confound named | — | PI/editor | Closes only when a full year sits inside one stream on both sides |
| Medium | Quarter step carries season | Q3 → Q4 spans Advent and Christmas, so part of every 2024 movement is liturgical calendar, not structure | M | Methods lead | Seasonally adjusted or same-quarter-across-years comparison, once two full stream years exist |
| Medium | Cross-edition comparability of 2024 and 2025 | The two editions use different comparison modes and 2024 is missing five months, so their headline volumes are not a series | S | PI + methods lead | An explicit series-break note in `INDICATORS.md` before any two-edition trend is published |

## Still open

| Priority | Gap | Why it is still open | Effort | Owner role | Acceptance condition |
|---|---|---|---:|---|---|
| Critical | Typology reference rule | Floating annual medians can manufacture movement, so the 2025 distribution is published without movement | M | PI + methods lead | Reference distribution and transition rule frozen and back-tested |
| High | Outlet-label ratification | The sidecar is `proposed` and covers 34,5 % of annual volume | M plus PI time | PI/editor | Every used label ratified; coverage and version hash reported |
| High | Stable entity identity and aliases | The same brand can appear under several platform-specific names; normalisation is currently case and `www.` only | M | Data lead | Alias table with stable IDs, reviewed |
| High | Dictionary validity | The sixteen-category dictionary matches words, not meaning; per-category precision and recall are unmeasured | L | NLP lead + methods lead | Hand-coded validation sample per category |
| Medium | Composite headline index | Standing furniture in the writing guide, but it is a measure and no indicator defines it | M | PI + methods lead | Definition, reference year and back series recorded in `INDICATORS.md` |
| Medium | Event-naming protocol | Edition 1 names four days from the public calendar and cross-checks them against the days' theme composition; there is no two-person written protocol | S | Editor + reviewer | Private evidence packet and independent naming agreement per public label |
| Medium | Per-edition derivatives | The briefing deck and the one-page infographic are not yet produced from the generated assets | M | Report editor | Deck, infographic and press release built from `output/` |
| Deferred | Church-voice penetration (AR09) | Construct not yet validated | L–XL | Separate study lead | Voice-carry pilot passes measurement, timing and negative-control gates |
| Deferred | Audience survey (AR10) | No instrument or sampling frame | XL | PI + survey lead | Instrument, sample, ethics, budget, cadence and stewardship approved |

## Disposition

- **Published in edition 1:** AR01, AR03, AR05, AR06, AR07, AR08; AR04 without movement; AR02 as
  indicative only.
- **Deferred:** AR09, AR10.
- **Verdict:** edition 1 is complete and internally consistent; publication is a PI decision, and the
  open items above are what the second edition has to close.
