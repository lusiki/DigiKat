# Exploratory atlas of public explanation of faith: existing-evidence synthesis

Date: 2026-11-02
Status: detailed proposal; ten editorial questions pending. Report production has not started.
Owner: Luka Sikic, DigiKat.

## 1. Purpose and intended use

Create one connected, descriptive and exploratory report addressing: Who appears to explain faith and theology in the media space observed by DigiKat, through which outlets and institutions, and with what supporting textual evidence?

The principal audience is professional theologians who will pursue interpretation and further research. The report must offer both the broad inventory and concrete passages, not only a shortlist of familiar public figures. It is a research guide, not a statistical estimate of the whole public sphere, a ranking of theological quality, or a validated census of interpreters.

Working Croatian title: "Tko objasnjava vjeru u medijskom prostoru? Ljudi, institucije, izvori i tragovi tumacenja". Final title and Croatian typography will be settled during drafting.

## 2. User constraints and production boundary

- Reuse existing data, aggregate outputs, figures, reports, and archived evidence.
- No new model runs, corpus processing, name detection, identity matching, thematic coding, speaker classification, or analytical filtering.
- No new network estimation, community detection, ranking method, pooled study counts, or reliability estimates.
- No corpus/master/database mutations, cleanup, relocation, publication, or Git operations are included.
- Narrative reading of displayed passages is editorial interpretation, not a new coded dataset or validation study. Do not attach new categorical labels to all records.
- Existing examples already assembled in the source reports/evidence packages form the initial case material. No new sampling procedure.
- Whether read-only export queries and document-layout scripts are permitted is an explicit pending question. If the user means literally no code or queries, use already exported artifacts and link database-only inventories without claiming they were converted into readable appendices.
- Complete inventories are separate from readable report displays. A PDF cannot usefully print hundreds of thousands of name strings. No raw entries disappear from their underlying private inventory.
- Initial output is local and private. Full unresolved-name and statement inventories are not automatically eligible for public release. Any public edition is a separate scope decision, retaining the established disclosure policy unless explicitly revised.

## 3. Evidence sources and their separate scopes

### A. Full-corpus names/network study

Repository: studies/catholic-voices-network/
External workdir: C:/Users/lsikic/Luka C/DigiKat_voices_work/
Main data: voices.duckdb (read-only).
Report: output/private/report/tko-govori-o-vjeri.pdf and HTML.
Saved reference register: office_register.json.
Saved summaries: report_data.json, network_metrics.json, network_public_names.json, identity/link reports, circulation reports, publication audit.

The study processed 611,583 documents across nine platforms. Existing table counts inspected on 2026-11-02: 8,037,060 PER mention records; 705,095 distinct detected strings; 569,686 documents with a detected PER mention. These are model detections, not verified names or distinct people.

The 1,394-person reference register is lookup material, not a corpus-observed speaker population. The 1,500 selected name groups checked for public linking yielded 170 linked groups, 1,272 unresolved groups, 56 sacred groups, and two ambiguous groups. Groups are not necessarily unique people. The final named network population has 110 public identities under the frozen inclusion rules.

The sentence-level rule output contains 31,458 candidate statement records: 12,298 direct, 18,650 indirect, 510 first-person. They are not unique claims or verified attributions. Overlapping passage/window records must not be added to this total. Candidate passages (2,144,976) and parsed sentences (799,627) have different units.

The source-context graph connects people sharing sources; it is not already a person-outlet two-mode graph. The paragraph graph connects people sharing paragraphs. Use their exact existing meanings. Public exported edges differ from the private analytical graphs because of disclosure filtering; retain the correct figure/metric pairing.

### B. Earlier 2,000-article coding study

Repository: studies/theological-voices-v2/
Saved evidence: output/private/coding.sqlite, frozen inputs/manifests, tables/, claims.json, diagnostics, report.
Report: output/private/report/tko-dobiva-rijec-o-vjeri-v2.pdf.

Uses an earlier 413,985-row corpus snapshot, 286,662 web export records, and a deduplicated frame of 282,701 publications. The main sample contains 2,000 publications allocated across calendar quarters. There are 1,950 structurally complete and 50 partial article results. Structural completeness does not establish semantic correctness.

Existing outputs include relevance, themes, mentions, voices, speaking capacity, interpretation-of-faith/experience fields, affected groups, evidence passages, and uncertainty. Preserve these labels as model suggestions. The frozen publication policy withheld model-derived estimates after semantic/long-text checks failed. Their existence does not authorise presenting them as reliable counts of interpreters or topics. Show diagnostic examples and evidence rather than reinstating withdrawn conclusions.

### C. Existing editorial and earlier descriptive material

- studies/theological-voices-editorial/output/private/katolicke-teme-u-arhivu-digikat.pdf: 24-page narrative treatment of supported source-concentration and exact-text-reuse findings, existing cases, leading-source directory.
- studies/theological-voices/: earlier closed-list mention/speech summaries and 300-post work; historical methodological context only unless the user requests a wider comparison. Its proximity-based speech detection is not interchangeable with the newer dependency-rule output.
- studies/theological-authority/: source/channel workbook and descriptive reports. Source identities are platform-plus-label, not necessarily people. Use only if scope question permits; do not equate recorded interactions/reach with theological authority.

Do not numerically merge different corpus snapshots, sample populations, or recognition methods. Cross-reference existing identities/documents only where the mapping is already supported; otherwise retain source-specific records.

## 4. Proposed deliverables

1. Main narrative report, provisionally 35-45 pages including concise methods and directory guide; final extent depends on user answers.
2. Companion inventories containing existing complete tables or faithful exports if permitted. No deduplication, inferred identities, or new classifications during export.
3. Evidence index: every reused figure, quantitative statement and displayed passage points to the existing file/table/record and original study scope.
4. Guide for theologians: open questions and locations of relevant evidence; optional blank review prompts, not completed expert coding.
5. README describing contents, units, limitations, provenance and preservation paths.

PDF/HTML/editable manuscript choices remain pending. All new artifacts must live in a separate folder, provisionally studies/faith-explanation-atlas/output/private/, preserving all source reports and databases. Do not create the production folder until production is requested.

## 5. Narrative and page architecture

### Opening: the question and a reading guide (3-4 pages)

Introduce the difference between being mentioned, speaking, and explaining. State what the archive observes and how to read evidence limitations. Include one inventory overview with explicit units and study dates.

### Part I: the observable landscape (6-8 pages)

Reuse platform/source coverage, named-person distributions and existing co-mention maps. Explain the 110-person analytical population and the much larger unresolved inventory. Include the 1,500-group linkage outcomes and 1,394-person reference register as separate populations.

Avoid changing a mention graph into a speech graph by altering its caption. Main-page displays are an orientation; companion inventories provide breadth.

### Part II: people, institutions and channels (5-7 pages)

Combine existing person profiles, documented offices, source summaries and directories. Distinguish office, article-presented speaking capacity, outlet, and platform. Missing office information remains unknown. Name matching remains automatic unless a documented review says otherwise.

Use existing relations and tables only. A diagram of the data structure may illustrate how layers relate, but must not imply an empirically computed network that does not exist.

### Part III: from attributed speech to religious explanation (8-10 pages)

Use already assembled cases and original supporting text. Display person/institution, source date, format when documented, the excerpt, the existing attribution, and an editorial reading tied to the excerpt. Contrast complete evidence with known extraction mistakes.

Where existing coding suggests interpretation of faith, show it explicitly as a provisional model label. Do not claim a new complete list of explainers, a new topic classification, or theological accuracy. Do not attach a later office to an earlier passage without dated support.

### Part IV: circulation and presentation (4-5 pages)

Reuse existing exact-reuse cases and summaries. Discuss recurrence across sources and the difference between presence in many outlets and many independent explanations. Do not identify first capture with origin or infer copying direction.

### Part V: research agenda for theologians (3-4 pages)

Questions can concern doctrinal explanation versus assertion, use of Scripture/tradition/experience, audience, expertise presented in the text, institutional mediation, and general-interest versus religious outlets where source categories already exist.

Present these as questions grounded in cases, not as completed coding. Do not treat an observed absence as proof a person or theme is absent from public life.

### Methods and inventory guide (4-6 pages)

Explain name recognition, identity resolution, attribution rules, local-model article coding, failures, scope differences and the 2024 collection break. Include a file guide and instructions for finding underlying evidence. Final page allocation is flexible rather than a filler quota.

## 6. Complete-inventory design

Provide separately labelled collections:

- Reference people (1,394): names/IDs and existing reference information; no implied corpus occurrence.
- Identity-checked groups (1,500): existing group labels and link status; linked groups need not equal people.
- Final analytical people (110): existing IDs, names and available aggregate counts.
- All detected name strings (705,095) and/or full occurrence table (8,037,060): original spelling, existing identifiers and occurrence locations; restricted research access, not printed name-by-name in the PDF.
- Candidate statements (31,458 sentence-level records): existing attribution and evidence fields with their original uncertainty; no claim deduplication.
- The 2,000 coded articles and existing mention/voice/evidence tables: preserve IDs, configuration, structural status and source-level scope.
- Existing aggregate tables and graph files: distinguish private full results from public disclosure-filtered exports.

If faithful exports are permitted, joins may only expose already stored relationships and must preserve unmatched records and original IDs. If a convenient field or aggregate does not exist, mark it unavailable rather than silently deriving a new analysis. A final inventory checklist records which collections are included as tables versus linked in their original storage.

## 7. Writing and visual principles (proposed)

- Croatian reader-facing prose, pending user choice; plain but academically credible.
- Lead with substantive questions and evidence. Explain technical terms once in the methods/guide.
- Distinguish three things throughout: saved descriptive result, provisional machine output, editorial interpretation/question.
- Put limitations beside the relevant claim, with full detail in methods; avoid repeating generic disclaimers on every page.
- Reuse the existing editorial visual system unless requested otherwise. No decorative networks or invented examples presented as data.
- Preserve Croatian diacritics and the exact wording of excerpts. Mark omissions and retain enough context for attribution.
- Document dates are not automatically dates of speech. Mentions, identities, sources, statements and articles each have distinct denominators.
- Quotations are selected evidence, not an exhaustive representation of a person's thought or a measure of doctrinal competence.

## 8. Production sequence and persistence

Phase 1 — Settle the ten editorial decisions; record answers and any approved scope changes in this plan.
Phase 2 — Inventory existing outputs; create the provenance/evidence index and inventory checklist. Read-only work, no new inference.
Phase 3 — Produce a detailed contents list and page-by-page evidence allocation. Flag unavailable promised components before drafting.
Phase 4 — Draft the connected manuscript from existing results and already assembled cases. Include all agreed inventory groups, not only the 110-person subset.
Phase 5 — Assemble companion existing tables/exports if permitted and the guide for theologians.
Phase 6 — Lay out and render agreed formats using applicable document skills. Presentation automation is distinct from analytical coding and remains subject to the user's answer.
Phase 7 — Verify evidence and visually inspect every report page. Correct only the new report, not source studies.
Phase 8 — Deliver local files, contents guide, known limitations and exact paths. No external publication.

Save each completed phase and its status so an interruption does not lose completed work. Use source references instead of copying the 18.74-GB database into the report folder. Preserve the source studies and existing recovery copies; storage cleanup is outside this task.

## 9. Verification and completion criteria

- All displayed quantities trace to an existing source result, with units and scope.
- The reference register is never described as observed corpus speakers.
- The 110-person analysis is never described as the complete name inventory.
- Structural/engineering checks are not described as semantic validation.
- No withdrawn model estimates are silently restored as substantive findings.
- Existing chart labels, populations and edge meanings remain correct.
- All quotations and attributions are checked against their saved supporting text; unresolved readings stay explicit.
- No new sample, identity merge, classification or filtering has occurred.
- All agreed companion inventories are included or directly locatable, with omissions stated.
- Final PDF/HTML is legible, complete, and visually reviewed; no fabricated graphs or source claims.
- Source data and source-report files remain unchanged.

## 10. Ten questions for the user

1. Audience: professional theologians first, or a mixed audience of theologians, communication researchers and institutional leaders?
2. Language and voice: Croatian analytical prose for educated nonspecialists (proposed), formal academic prose, or a more essayistic style?
3. Extent: approximately 35-45 pages plus separate inventories (proposed), a shorter 20-25-page report, or a longer reference volume?
4. Report ambition: a descriptive atlas with cautious case interpretation (proposed), or a more argumentative essay advancing explicit provisional theses?
5. Thematic breadth: doctrine/Scripture only, or also moral reasoning, spirituality, homilies, lived experience and religion in public controversies (proposed broad coverage)?
6. Actor breadth: all actor types already in the saved material, including institutions, lay voices, politicians and historical/sacred references with separate status labels (proposed), or a narrower substantive focus?
7. Inventory and circulation: private complete research companion with unresolved names (proposed), or an edition intended for external circulation, which would need a separate disclosure treatment?
8. Evidence presentation: more original Croatian passages with commentary (proposed), or more maps/tables with shorter textual examples?
9. Visual style and formats: reuse the existing 24-page editorial report style, use a simpler academic design, or another specified reference; PDF only or PDF plus navigable HTML/editable manuscript?
10. Meaning of no coding: may we use read-only queries/faithful exports and layout scripts solely to assemble existing data (proposed), or only already exported files with no code/query execution?

