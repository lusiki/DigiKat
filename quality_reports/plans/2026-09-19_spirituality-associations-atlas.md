# Croatia spirituality associations atlas exploratory study

User authorised creation of a new study and execution of data collection and exploratory analysis on 2026-09-19, selecting direction one in the supplied brief.

## Scope and location

Create `studies/spirituality-associations/` as a self-contained thematic study. Ask which organisations are registered in the spirituality category, where their seats are, and which can be observed in the monitored public sphere. This is descriptive feasibility work, not a completed paper or a causal analysis.

## Execution

1. Preserve and hash the supplied JSON, PDF and brief in gitignored study storage. Independently extract PDF rows and reconcile identifiers, counties, names and page references. Recover locality and website fields omitted from the JSON.
2. Produce a register audit, county and locality summaries, website completeness, and clearly labelled lexical cues rather than inferred religious identities. Preserve unknown orientation and operational status.
3. Collect a varied set of official website evidence with source dates and provenance. Define multi-axis coding and conservative identity rules. Build a reproducible 60-organisation feasibility sample retaining zero-match cases.
4. Query the general DetermDB read-only for calendar 2025. Record snapshot and coverage, retrieve conservative name candidates, inspect matches, and distinguish candidate retrieval from validated visibility. Audit the source filter on available unfiltered exports if feasible.
5. Save aggregate figures and tables, a research protocol, codebook, reproducible scripts, and an exploratory report. Preserve restricted rows, organisation-level source evidence and review sheets under `output/private/`.
6. Verify register reconciliation, denominators, matching edge cases, aggregates, figure rendering, disclosure checks and source immutability. Link the study from the studies index.

## Boundaries and rationale

Use general monitored media, because the official Catholic corpus is an inappropriate search population for this administrative frame. Use one calendar year within the newer collection regime. No global dictionaries, source databases, official corpus, production aggregates or website releases change. Existing unrelated working-tree changes remain intact. No publication or commit is required.

Registered seats do not measure membership or organisational reach; active administrative status does not prove current activity. Names provide sampling cues, not verified belief classifications. Zero retrieval means not observed under the particular search rules. Current organisations may not have existed in 2025. The newer feed's standalone-word filter needs explicit sensitivity work.

## Execution record

Completed 2026-09-19. All 1,325 PDF/JSON entries and 21 county totals reconcile. Added DZS mid-2025 population denominators and nine official-source profile groups (17 register entries). Screened 8,514,361 general-feed records in calendar 2025 with 1,043 initial organisation rulesets; retained 282 names for later identity work. Retrieved 3,806 unique candidate items for 248 names, with 795 screened names not observed under these rules. These are unvalidated candidates. The pilot has 60 organisations across all counties; candidate review queue has 453 rows; human labels remain blank. Fifteen AI development examples demonstrate ambiguity and plausible hits without supplying a precision estimate.

Twelve unfiltered days contain 510,471 raw records and 122 name-candidate records; the documented filter retains 118 candidates. This is a fixed-day diagnostic, not an annual correction. Generated five figure pairs, a searchable private directory, a Markdown report and a seven-page PDF. Verification covers sixteen groups of reconciliation and matching/disclosure safeguards. The repository disclosure guard passes. Source databases and unrelated work remain unchanged.

A large combined RE2 name alternation proved slow; the main extraction now uses Aho-Corasick after the same normalization. A COPY parameter-binding issue and an interrupted monthly cache were repaired before generating final outputs. Counts are reconciled against all twelve completed monthly files. Development findings remain separate from the next stage of historical identity and independent human validation.
