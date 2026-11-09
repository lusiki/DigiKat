# Croatia spirituality associations and public visibility

Exploratory paper protocol, opened 19 September 2026. Working Croatian title: **Udruge iz područja duhovnosti u Hrvatskoj i njihova javna vidljivost**. Research area: sociology of religion and communication studies. Owner: Luka Šikić. Design: descriptive register analysis with computational retrieval and qualitative validation. This is the first research direction in the supplied brief.

## Research problem

An administrative label can join organisations whose purposes, activities and relationships differ substantially. Media attention may show a different distribution from organisational presence. The study will describe that difference without treating the spirituality category as a denomination, a measure of belief, or an inventory of all Croatian religious life.

The main question is: **Which kinds of associations are included in Croatia's spirituality register frame, where are they registered, and which become observable in the monitored public sphere?**

The component questions are:

1. What combinations of self-declared orientation, activities, organisational form and network relationships occur in this administrative population?
2. How are registered seats distributed across counties, before and after population adjustment?
3. How many organisations are observed in owned communication, independent reporting and public discussion, and how persistent and concentrated is that visibility?
4. How much do retrieval choices, alias ambiguity and collection filtering change the answer?

The possibility of diverse organisations but concentrated attention is an exploratory proposition. It is not a finding until identity matching and channel attribution are validated. No retrospective preregistration or causal interpretation is proposed.

## Population and dates

The closed starting frame is the supplied PDF dated 11 September 2026: active associations selected under `3. DUHOVNOST` and the subcategories printed on its cover. Its UDR ID is the study key; it is not silently treated as an OIB or legal registration number. The PDF assigns no individual subcategory codes to rows. Repeated subcategory numbers on the cover are preserved, not corrected by inference.

The JSON is independently reconciled with PDF cells. The September 2026 frame does not prove that each association existed in 2025, remains operational, or has the same legal name and seat throughout time. Maintain an explicit existence-in-2025 field and verify historical eligibility before computing a national observation proportion for that year. Dissolved associations missing from the 2026 frame cannot be recovered from this list alone.

The exploratory media interval is 1 January through 31 December 2025 in the general DetermDB feed. The official DigiKat Catholic corpus is not the search population. The underlying merged snapshot and its 2025 counts are measured at run time and saved in `output/tables/media_snapshot.json`; older counts in the brief are not reused. Queries are read-only.

The denominator for geographical density is DZS's mid-2025 county population estimate, published 4 September 2026. The resulting ratio combines a September 2026 organisation snapshot with mid-2025 population. It is a contextual density indicator, not a contemporaneous activity or membership rate.

## Organisational measurement

Keep five dimensions separate: documented religious or philosophical orientation; multiple activity domains; legal/organisational form; headquarters/branch/network relationships; and verified channels. Record source, access date, evidence status and uncertainty for each coded value. Unknown remains unknown. A humanitarian mission alone establishes neither religious nor secular identity.

Name-based regular expressions are discovery and sampling aids only. They are intentionally overlapping. A mutually exclusive priority stratum is used solely to select a feasibility sample; it must not become a national typology. The unknown/no-cue stratum is essential because ordinary names can conceal any kind of activity.

The pilot contains 60 organisations: ten in each of six lexical strata, with purposive website cases and deterministic county-diversity selection for the remaining slots. All counties are represented. The seed and selected IDs are frozen before media counts are inspected. This is not a representative sample and has no survey weights. Keep purposive profiles outside the pilot separate when necessary.

## Retrieval and article identity

The initial screen uses complete registered names with at least three tokens, 18 normalized characters and two tokens outside a small generic-word list. Selected official/provisional aliases are added for feasibility checks. Normalize case, accents and punctuation; require token boundaries. Avoid isolated generic words and shared network labels. Short names without adequate rules are **not yet searched**, not zero-visibility organisations.

Search title and full body without a religious keyword prefilter or sentiment filter. No language/location condition is added in the exploratory screen: it is a search of the vendor's monitored feed, not a claim that every hit is a Croatian publication. Later source and language eligibility should be explicitly audited. Long names, name inflection, historical names, abbreviations and missing channels cause false negatives.

Candidate items are deduplicated by a conservative canonical URL that removes scheme, `www`, fragment, trailing slash and common tracking parameters but keeps substantive parameters. Missing URLs use vendor ITEM_ID, then a date/title/body hash. The unit is a recorded URL/item, not a unique story, author, person, or impression. Syndicated stories on different URLs remain separate. Inspect pages that are repeatedly updated, home-page URLs, empty URLs and reused IDs before publication. Organisation-item pairs count an item once for each organisation it contains; they therefore need not sum to unique items.

Keep all raw matches, snippets, domains, titles and review sheets private. Full names can still create false positives through generic phrases, event titles, navigation menus and named organisations outside Croatia. Candidate totals are retrieval diagnostics. They are neither precision-adjusted estimates nor strict lower bounds on visibility, because false positives remain possible.

## Channel attribution and validation

Three substantive channel types remain the intended outcome: own communication; editorially independent reporting; and public discussion. An organisation's exact official domain can suggest own communication, but a shared umbrella domain or a social platform domain cannot identify a branch or an account. External URLs do not establish editorial independence. Require account verification and inspection of bylines, reposts, attribution and substantive passages.

The pilot should annotate identity (correct, incorrect, ambiguous), organisation prominence (incidental, substantial, main subject), quoted voice, activity frames, and channel relation. Review both hits and apparent misses. The delivered deterministic development queue is not an independent held-out precision sample. AI development readings must be recorded separately from human labels; human review fields stay blank until someone codes them.

For the next stage, two people should independently label a stratified sample of candidates across matching routes, platforms, name ambiguity and organisations. Set aside evaluation records before revising rules. Report route-specific precision with uncertainty, disagreements and adjudication. Investigate apparent zeros with official-channel searches, alternative names and manually known 2025 events; do not claim population recall from a small convenience set.

## Indicators after validation

- Organisational presence: county counts, seats per 100,000 residents and population-share ratios.
- Observation: organisations with at least one validated item among historically eligible organisations; preserve zeros and unknown eligibility.
- Persistence: distinct months with validated observations.
- Breadth: distinct verified editorial outlets, separately from owned channels and social accounts.
- Attention concentration: top shares and a Lorenz/Gini summary of validated organisation-item counts, with the denominator and zeros explicit.
- Collection adjustment: matched eligible records per 10,000 eligible monitored records within consistent platform/month panels. Numerator and denominator must share their deduplication and eligibility rules.

Do not publish crude rates that divide deduplicated matches by raw vendor rows as if they were population prevalence. Do not collapse own publications and independent coverage into one substantive indicator. Whole-article sentiment cannot measure attitudes toward an organisation without target-specific validation. Membership, trust, influence, social contribution and participation are outside the observable measures.

## Collection sensitivity

The newer database keeps records containing the standalone word `i` in title, body or snippet. The initial sensitivity audit rereads unfiltered JSON exports for the fifteenth of each month in 2025, applies the same name rules and measures retention overall and by platform. These fixed days are a diagnostic, not a random sample or a correction factor. Short posts, aliases and organisations held outside the name screen may behave differently. Current raw exports and the merged database may reflect different import revisions; the audit estimates the filter's action within the raw exports rather than assuming they are an exact reconstruction of every merged day.

## Paper structure and next decision

The eventual paper can proceed from the administrative construction of the frame, through national geography and verified organisational profiles, to validated visibility and collection sensitivity. Eight to twelve contrasting organisational portraits should explain what the aggregate measures hide. The present outputs establish feasibility and an auditable data foundation. The next bounded work is historical identity and alias validation for the 60-case pilot, followed by independent coding. A national visibility ranking, public directory and final manuscript await those measurements.

## Data availability and AI use

Source register files, personal contact information, website snapshots, media records and organisational review sheets remain under gitignored `output/private/`. Public-source citations, scripts, methodological documents and aggregate diagnostics are reviewable in the study. Restricted vendor material is not redistributed. Aggregate diagnostics are exploratory research material, not an approved public data release. Apply the repository disclosure process before any commit or publication.

Codex assisted with source extraction, code, exploratory analysis and drafting. Official sources support profile notes; automated cues and AI readings are not human validation. No messages were sent to associations and no survey or interview collection was performed.
