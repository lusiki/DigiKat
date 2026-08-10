# Plan — DigiKat annual report, first internal pilot (2026-08-07)

## Outcome

Run one bounded, internal **Izvještaj 0** that tests whether the proposed flagship-report product works
before indicator definitions or publication promises are frozen. The pilot will produce a complete report
shape, populated wherever the current reviewed aggregates support a claim, and an explicit gap panel wherever
they do not. It will not be published.

The pilot succeeds if it answers five questions:

1. Can a decision-maker understand the report's stable indicator spine without knowing the DigiKat pipeline?
2. Which recurring indicators are useful enough to keep unchanged across editions?
3. Which promised annual comparisons are not currently supported by stream-aware data?
4. Can every displayed number be regenerated, installed, and mechanically checked?
5. Can an institutional-outlet annex survive disclosure and hostile-reader review?

## Fixed pilot decisions

- **Reporting year:** calendar 2025. This matches the project schedule's first-map commitment and is the only
  complete calendar year in the current corpus that belongs entirely to the later `filtered_religious` stream.
- **Data vintage:** the current tracked aggregate manifests, generated 2026-07-28 from a master ending
  2026-06-11. The readiness audit records these dates in the dummy; 2026 is not treated as an annual result.
- **Time comparisons:** the recurring baseline may begin in 2024, as the brief requires, but the pilot will not
  interpret a 2024–2025 movement from the current `data/processed/` files because they do not carry
  `data_source`. Such a comparison remains a visibly marked gap until the report-specific aggregate can
  condition on `data_source × platform`.
- **Pilot unit:** one annual flagship dummy. The charter should recommend an annual flagship plus a light
  mid-year build target, but the mid-year brief is not built in this pilot.
- **Special chapter:** provisionally use the mature *Socijalni nauk Crkve u javnoj raspravi o gospodarstvu*
  study to test the rotating slot. The PI can substitute another completed study at the editorial gate without
  changing the report spine.
- **Disclosure posture:** fail closed. Only institutional outlets may be named; no individual-account profile
  enters the annex. Named-account material and rendered internal copies remain in `output/private/`.
- **Publication posture:** no navigation edit, no `docs/` write, no full-site render, no deploy, and no public
  link. A local HTML/PDF render may be made only through an outside-repository temporary build.

## What the repository can support in the pilot

The first pass must distinguish a real annual result from an all-period layout demonstration. “Partial” below
means the dummy may use the existing number only with an explicit scope label; it is not ready to become the
edition-1 recurring series.

| # | Recurring indicator | Pilot status | Permitted in Izvještaj 0 | Edition-1 gap |
|---|---|---|---|---|
| 1 | Volume by platform | **Partial** | 2025 point-in-time totals from `platform_summary`; monthly 2025 pattern from `platform_monthly` | Add `data_source` to a report-specific platform aggregate before any 2024–2025 comparison |
| 2 | Confessional/secular share | **Partial** | Indicative 2025 share from `source_summary` joined to the PI-owned label sidecar | Ratify labels; report labelled coverage and unclassified remainder; add platform/stream dimensions |
| 3 | Top actors per platform | **Partial** | All-period institutional examples from `top_*_sources.rds`, clearly labelled as a layout test | Produce year × platform × actor aggregates and apply the institution-only disclosure rule |
| 4 | Actor types and movement | **Partial / movement blocked** | Static all-period typology for the current top-actor sets | Preserve actor-year-platform rows, define stable median reference rules, then compute transitions |
| 5 | Engagement benchmarks | **Partial** | Static benchmark for the current actor sets, without an annual trend claim | Define denominator and missing-reach policy; calculate by year × platform × type on an eligible universe |
| 6 | Thematic profile and movers | **Partial** | 2025 values available in `mapa_stats.rds`, with the scope of the existing guided-trend object stated | Generate the complete 16-category year × platform × stream table and freeze the mover rule |
| 7 | Tone and conflict | **Partial** | All-period theme/outlet patterns from `diskurs.rds` as a structure test | Generate annual, stream-aware overall and top-theme summaries; freeze CLI/RCI definitions and uncertainty rules |
| 8 | Events of the year | **Computable with review** | 2025 spikes from `dogadjaji.rds`; event labels require editorial verification | Freeze peak-selection, tie-breaking, and event-naming rules; retain a private evidence trail |
| 9 | Church-voice penetration | **Blocked** | A one-box placeholder saying the indicator is under validation | Complete and validate the voice-carry pilot before admitting it to the recurring spine |
| 10 | Audience-side survey | **Blocked** | Future-module placeholder only | Define and fund a survey instrument, sampling frame, cadence, and stewardship plan |

This availability table is itself a pilot deliverable. A sparse but honest dummy is preferable to filling a
chapter with numbers whose annual meaning the current aggregates cannot support.

## Planned study workspace

At execution time, use the repository's `.claude/skills/new-study` workflow with slug `annual-report`, then
adapt the generic thematic-study scaffold to this recurring product. The intended layout is:

```text
studies/annual-report/
├── README.md
├── CHARTER.md
├── INDICATORS.md
├── PIPELINE.md
├── GAPS.md
├── REPORT_0_TEMPLATE.qmd
├── refs.bib
├── 00_data_readiness.R
├── 01_report_aggregates.R
├── 02_report_assets.R
├── 03_sync_fragments.R
├── 04_report_checks.R
├── 05_render_report.R
└── output/
    ├── manifest.json
    ├── annual_report_derived.csv
    ├── tables/
    ├── figures/
    └── private/
        ├── IZVJESTAJ_0.qmd
        ├── profiles/
        ├── evidence/
        ├── review/
        └── rendered/
```

`REPORT_0_TEMPLATE.qmd` may be tracked only if it contains no named-account material. The populated internal
dummy and its named institutional profiles live in the gitignored private area until disclosure review decides
what may later be promoted.

## Roles and decisions

| Role | Responsibility in the pilot |
|---|---|
| PI/editor | Ratify name, cadence, audience order, indicator definitions, label sidecar, eligible institutions, special chapter, and final pilot verdict |
| Data lead | Run readiness audit; write the report-only derivations, manifest, tables, figures, and checks; never mutate the master or canonical aggregates |
| Report editor | Draft Croatian prose, the English summary, captions, and the methods page from approved generated results |
| Independent numeric reviewer | Re-derive every headline scalar and verify the claim registry without relying on the draft's interpretation |
| Domain/hostile-reader reviewer | Test construct validity, neutrality, Church/media terminology, caveats, and whether any comparison overreaches |
| Disclosure reviewer | Screen small cells, names, indirect identifiers, free text, and the institutional/individual boundary |

One person may perform more than one production role, but the numeric and hostile-reader passes need fresh
context rather than self-confirmation.

## Execution sequence

### Phase 0 — Preflight and scope lock (0.5 day)

1. Record `git status`; preserve the existing unrelated untracked work.
2. Confirm R and Quarto by absolute path and run `renv::status()`.
   - Current inspection found R 4.6.0 and Quarto 1.9.38 available.
   - Current `renv::status()` is not clean because `lmtest` and `sandwich` are absent. Before the pilot, either
     restore them or demonstrate that no pilot script imports them and record the bounded waiver in `README.md`.
3. Verify the master exists but do not open it: the pilot is explicitly existing-aggregates-only.
4. Verify the `data/processed/manifest.json` and `data/page-ready/manifest.json` hashes, schemas, generation
   dates, corpus range, and source row totals.
5. Confirm no other process will write pilot artifacts. Pause Dropbox only for a long render or any later
   master read; the bounded aggregate inspection does not need a master run.
6. Create the study scaffold. Do not touch `_quarto.yml`, `docs/`, `R/03_aggregate.R`, or
   `data/processed/`.

**Gate P0:** continue only if all required aggregates are readable and their manifests reconcile. A stale or
missing input becomes a recorded gap; it is not silently rebuilt during the pilot.

### Phase 1 — Freeze the editorial contract (0.75 day)

Draft `CHARTER.md` before drafting findings. It must contain:

- two or three scalable Croatian/English-compatible title options and one recommended working title;
- the annual flagship + light mid-year build-target recommendation, with the mid-year brief defined as a
  subset of the same generated assets rather than a second manuscript;
- a World Communications Day publication rule, calendar-year cutoff, January data freeze, production window,
  and embargo window; the exact annual date is confirmed from the Church calendar each edition;
- primary/secondary audience order, a findings-first register, 25–30-page budget, and the Croatian/English
  language split;
- the stable anatomy: Sažetak, one-page Metodologija, four permanent analytical chapters, rotating special
  chapter, institutional-outlet annex, declarations;
- the independence statement: funding, CC BY, no editorial input from covered actors, PI as editor;
- change control: an indicator definition can change only through a documented version bump, back-series
  decision, and an explicit comparability break note.

**Editorial gate E1:** the PI signs off the report name, cadence, publication rule, audience, special chapter,
and the provisional page budget. No prose production begins before this gate.

### Phase 2 — Freeze the indicator codebook (1.5 days)

Draft `INDICATORS.md`. Each indicator record must include:

- stable ID and Croatian public label;
- one-sentence plain-Croatian definition;
- conceptual numerator, denominator, unit, eligible universe, time unit, and treatment of missing values;
- exact current input object/columns or exact proposed report-aggregate schema;
- platform coverage and `data_source` handling;
- suppression, institutional-naming, and label-coverage rules;
- comparability rule, known break conditions, and edition version;
- pilot status: computable, partial, needs new aggregate, or blocked;
- proposed chart/table and the single decision it should help the reader make.

Resolve four definitions here rather than in prose:

1. whether “engagement” means total interactions, interactions per post, or an exposure-normalized rate;
2. whether typology medians are recalculated each year or frozen to an edition-1 reference distribution;
3. how a “mover” is selected when topic shares are stream/platform conditioned;
4. the small-cell rule (proposed default: suppress named cells with fewer than five posts, with stricter human
   review for rare combinations).

**Measurement gate M1:** the PI approves the 8 core definitions and explicitly leaves indicators 9–10 outside
the current spine. Any unresolved denominator or comparison rule stays labelled “blocked” in the dummy.

### Phase 3 — Specify and implement the minimum pilot build (2 days)

Write `PIPELINE.md` first, then implement only enough of the numbered chain to populate the dummy from current
aggregates:

1. `00_data_readiness.R`
   - validates manifest hashes, required objects/columns, 2025 completeness, 2026 partial coverage, label-sidecar
     schema, and output isolation;
   - writes a machine-readable readiness table and fails on an unsafe temporal comparison request.
2. `01_report_aggregates.R`
   - reads existing tracked aggregates read-only;
   - creates report-local 2025 tables and clearly labelled all-period diagnostic tables;
   - joins PI labels without overwriting them;
   - excludes individual/noise/off-topic sources from named-public candidates;
   - writes only under `studies/annual-report/output/`.
3. `02_report_assets.R`
   - generates every table fragment, figure, caption value, and `annual_report_derived.csv`;
   - routes all figures through `R/theme_digikat.R` and shared labels;
   - records input hashes, indicator versions, reporting year, date cutoff, and code version in `manifest.json`.
4. `03_sync_fragments.R`
   - installs generated fragments between stable sentinels in the private dummy;
   - never asks an editor to retype a table or scalar.
5. `04_report_checks.R`
   - asserts fragments are byte-identical to their installed copies;
   - asserts every quoted scalar is registered in `annual_report_derived.csv` and every registered headline
     scalar appears in both the Croatian and English summary where intended;
   - checks that each key-finding bullet contains exactly one analytical number, excluding its generated bullet
     ID;
   - rejects an unlabeled pre-2024 comparison, a 2026 annual claim, individual named profiles, unresolved
     placeholders, hard-coded figure colours, and outputs outside the study directory;
   - verifies Croatian diacritics and flags common mojibake signatures.
6. `05_render_report.R`
   - copies the manuscript, figures, and styles to a temporary directory outside the repository;
   - renders only the dummy to internal HTML and Typst PDF;
   - copies results to `output/private/rendered/` and verifies that `docs/` is byte/state unchanged.

The edition-1 version of `01_report_aggregates.R` may later read the master read-only to produce the missing
stream-aware schemas. That extension is a separate reviewed task; it must not alter `R/03_aggregate.R`.

**Build gate B1:** all scripts pass from the repository root, write only to the declared study paths, and leave
the master, canonical aggregates, `_quarto.yml`, and `docs/` unchanged.

### Phase 4 — Assemble Izvještaj 0 (2 days)

Populate the private dummy in this order:

1. design the Sažetak slots but write them last;
2. write the one-page methods statement, including the two-stream seam, 2025 reporting-year choice, 2026 cutoff,
   incomplete outlet classification, open-aggregate links, and suppression policy;
3. build the four permanent chapters using their controlled Croatian names:
   - Mapa ekosustava;
   - Tematske struje;
   - Atmosfera diskursa;
   - Fokus na događaje;
4. insert the provisional special chapter as a bounded synthesis of already generated study outputs;
5. create three to five mirror-profile pages for PI-approved institutional outlets selected to test different
   platforms and typology quadrants—not to rank favourites;
6. add a visible “what this pilot cannot yet show” panel wherever an annual indicator is partial or blocked;
7. write 8–10 Croatian key findings, each containing exactly one generated analytical number, then translate
   that section only into English using the same scalar keys.

The dummy should target 25–30 pages in layout, but it need not fill every page with substantive findings. Blank
space, a short chapter, or a gap panel is evidence about the product and should be retained for the pilot review.

**Content gate C1:** every section of the permanent anatomy is present; every empirical statement is generated,
scoped, or explicitly marked unavailable; no blocked indicator is cosmetically promoted to a finding.

### Phase 5 — Mechanical, disclosure, and adversarial review (1.5 days)

Run checks in this order so later reviewers see a mechanically coherent draft:

1. `04_report_checks.R`;
2. repository disclosure guard plus the `/disclosure-check` workflow on the complete share candidate;
3. manual small-cell and institutional/individual review, including combinations that could single out a person;
4. independent `numeric-claim-verifier` pass against the generated files;
5. independent `religion-media-domain-reviewer` hostile-reader pass;
6. manual Croatian house-voice and English-summary equivalence review;
7. isolated HTML/PDF render and visual inspection of representative pages, figures, footnotes, and annex pages.

All findings go to `output/private/review/issue_log.csv` with severity, owner, resolution, and whether the issue
changes the indicator definition or only the presentation.

**Release gate R0:** this gate authorizes only an internal review copy. Any individual account, unsuppressed
small cell, number without provenance, temporal overclaim, or unresolved critical review finding blocks even
internal circulation beyond the core project team.

### Phase 6 — Pilot workshop and product decision (0.75 day)

Hold a 60–90 minute readout with the PI and two or three primary-audience proxies. Give them the report without
an oral walkthrough for the first 20 minutes; the product should explain itself. Capture:

- which three findings they remember;
- which indicator led to a decision or question;
- which pages they skipped;
- whether the caveats were understood;
- whether actor profiles felt useful, unfair, or overly thin;
- which missing indicator materially weakened the report;
- whether the special chapter belonged in the same publication.

Then classify each recurring indicator as **keep**, **revise before freeze**, or **drop/defer**. Update `GAPS.md`
with the agreed requirement, dependency, owner role, effort, and deadline.

**Decision gate D1:** choose one outcome:

- **Go:** architecture is fixed; build the missing report aggregates and prepare edition 1.
- **Revise and re-pilot:** one or more indicator definitions or chapter roles are unstable.
- **Stop:** the recurring product does not add enough value beyond the four existing analytical pages.

## Edition-1 gap register and effort classes

`GAPS.md` should use comparable effort classes rather than false precision:

| Effort | Meaning |
|---|---|
| S | Up to 0.5 day; formatting, labels, or a simple derivation from a reviewed aggregate |
| M | 1–2 days; one new report aggregate plus tests and documentation |
| L | 3–5 days; longitudinal or multi-input measure requiring validation and disclosure review |
| XL | More than 5 days or dependent on new data collection/manual coding/external decision |

Expected initial entries are:

| Gap | Initial effort | Dependency |
|---|---:|---|
| Stream-aware platform/year/month aggregate | M | Read-only master derivation; no canonical aggregate change |
| Actor year × platform panel and transition logic | L | Stable actor identity, eligible universe, typology reference rule |
| Engagement benchmark definition and missing-reach audit | M–L | Indicator decision at M1 |
| Complete 16-theme annual table by platform/stream | M | Existing dictionary and NLP inputs; definition freeze |
| Annual tone/conflict table by top theme and stream | M–L | Existing NLP inputs; CLI/RCI validation |
| PI ratification and coverage report for outlet labels | M plus PI time | `source_labels.csv` review |
| Event-name evidence trail and editorial protocol | M | Private row-level inspection and disclosure controls |
| Voice-carry indicator | L–XL | Separate validation pilot |
| Audience survey module | XL | New instrument, sample, budget, ethics/data stewardship |
| Stable PDF/HTML annual-report typeset layer | M | Charter and page-budget freeze |

## Estimated duration

The bounded pilot is **8–9 working days of production effort**, plus waiting time for PI decisions and fresh
reviews:

| Work | Effort |
|---|---:|
| Preflight and scaffold | 0.5 day |
| Charter and anatomy | 0.75 day |
| Indicator codebook | 1.5 days |
| Minimum pilot pipeline | 2 days |
| Dummy drafting and annex | 2 days |
| Checks, review, and revision | 1.5 days |
| Workshop and gap register | 0.75 day |

A realistic calendar is two weeks if E1 and M1 decisions are returned within one working day. Do not compress
the codebook gate to protect a launch date: the first published definition creates the future back-series burden.

## Acceptance criteria

The first pilot is complete only when:

- `CHARTER.md`, `INDICATORS.md`, `PIPELINE.md`, and `GAPS.md` exist and record all decisions above;
- Izvještaj 0 contains the complete permanent anatomy and uses real generated data wherever it makes a claim;
- every indicator is visibly classified as computable, partial, new-aggregate, or blocked;
- every quoted scalar traces to `annual_report_derived.csv`; generated table fragments are byte-identical;
- the report makes no cross-stream trend claim from the current non-stream-aware aggregates;
- all named profiles are institutional, privately held, and suppression-reviewed;
- Croatian and English summary findings use the same scalar keys;
- the automated checks, disclosure screen, numeric review, and hostile-reader review have no unresolved critical
  findings;
- the private HTML/PDF render succeeds outside the repository and `docs/` remains unchanged;
- the PI records a Go / Revise and re-pilot / Stop decision and ratifies the edition-1 gap list.

## Explicitly out of scope

- updating or overwriting the master corpus;
- running `R/03_aggregate.R --apply` or changing the canonical 14-output builder;
- refreshing NLP or semantic stores;
- completing the voice-carry or survey indicators;
- public copy-editing, launch collateral, embargo outreach, navigation changes, deployment, or a full-site render;
- committing or sharing any `output/private/` artifact.

## Annual runbook to validate, not execute publicly in this pilot

The pipeline specification should finish with this stable future run order:

1. close the calendar-year ingest and verify the December cutoff;
2. run the controlled `/refresh-data` workflow;
3. run canonical previews and obtain the separate apply authorization where required;
4. build report-specific stream-aware aggregates;
5. generate figures, tables, fragments, `annual_report_derived.csv`, and the manifest;
6. sync the manuscript and run report checks;
7. run disclosure, numeric-claim, and domain/hostile-reader reviews;
8. render HTML and Typst PDF outside the repository;
9. issue a controlled embargo pre-brief with no covered-actor editorial input;
10. obtain final PI sign-off and publish through the normal `/deploy` workflow.

The pilot executes steps 4–8 only against current reviewed aggregates and stops before any public circulation.
