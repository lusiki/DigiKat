# Short exploratory report on Catholic communicators

Revised 13 October 2026 following the user's narrower brief. This replaces the earlier research protocol.

Produce a six-page Croatian report that informs the question *Tko je preuzeo ulogu teologa u hrvatskom javnom prostoru?*, plus a separate top-50 source table. The work is exploratory and descriptive, with no pilot, manual content-coding exercise, dual coding, interviews or inferential models.

## Input and existing resources

Use the local Catholic-topic dataset resolved through `digikat_legacy_master_path()`. Direct inspection found 612,065 records through 6 January 2026; the repository's 710,307-record description does not describe this local file. Label it explicitly as the earlier snapshot, not the absent 413,985-record official corpus. Read the input only and record its hash, actual date range, schema and missingness. Use complete years 2021-2025 for the main report. Use an isolated standalone R session with installed packages because project renv startup is unavailable; record package versions and leave the project environment unchanged.

Reuse the actor classifier in `studies/catholic-influencers/actor_classification.R`, the more explicit mappings in `explorations/okvir-katolicanstva-prototype/source-groups.csv`, and `resources/dictionaries/source_labels.csv`. Preserve provenance and uncertainty. Separate institutional sources, independent Catholic media, clergy profiles, lay/devotional channels, communities and other/unclassified sources. Existing labels are exploratory, not newly verified claims about mandate or education.

## Six-page report

1. Scope and three main findings, with a brief explanation of what engagement can establish.
2. Actor composition: sources, posts and interactions, with classification coverage and a platform breakdown.
3. Leading sources: a readable selection from the top fifty, ranked within platform and accompanied by post counts and median interactions. Supply the complete top fifty as a separate table.
4. Attention concentration: top-source shares and a cumulative attention chart for the selected communicator set; explain the denominator and platform differences.
5. Existing sentiment labels and engagement: descriptive counts, medians and means by actor group within comparable platforms. Treat missing sentiment separately. No significance tests or causal claims.
6. Implications for the proposed research: where attention is located, which contrasts merit later study and the limits of the inherited categories. Include lightweight thematic signals from existing dictionaries only if text availability makes this straightforward.

## Outputs and checks

Write study-local code and aggregate results under `studies/theological-authority/`. Keep named source tables and research deliverables in ignored private output. Create a six-page PDF using the PDF skill, and a readable HTML copy and CSV companion without publishing the website. All report numbers come from computed outputs. Check row counts, joins, missing/zero distinctions, ranking totals, Croatian text and rendered page layout. Document the collection break, partial final year and platform-specific metrics in concise notes.

The only new work is a descriptive reanalysis and concise synthesis. Education and formal mandate remain possible fields for the research team to investigate later.

## Authorized extension: 20 pages

The user subsequently requested a systematic twenty-page report, retaining the
exploratory/descriptive scope and the same local dataset. Extend the executed
analysis with all nine platform categories, separate profiles for six platforms
with metrics, reach availability and distributions, monthly collection coverage,
annual actor composition, and a same-source comparison of July-December 2024
with July-December 2025. Keep unsupported metrics missing, show the 2024 gap and
collection transition, and distinguish estimated reach from unique audience.

Answer the three practical questions directly: what actor distinctions are
supported, which aggregates are already publicly accessible, and which fifty
sources lead recorded engagement. Verify public GitHub resources. Do not combine
the newer official-corpus aggregates with this earlier local snapshot. Include
the complete top fifty inside the report, enriched CSV companions and a local
archive of identity-free aggregates ready for sharing. Preserve the original
six-page report, use separate extended outputs, and do not publish the website.

Verify reconciliation, missingness, time windows, rank order and twenty-page
rendered layout. Reuse existing registries and dictionaries; no pilot, double
coding, new credentials research, interviews or inferential models.

Completed: standalone R extension executed against the same pinned local input;
twenty-page PDF and HTML created; complete top fifty and platform/social CSVs
exported; an identity-free aggregate ZIP prepared locally. Public availability
and corpus provenance were checked through GitHub. Twenty-five verification
checks passed, including the unchanged input hash and all fifty PDF names.
All pages were rendered and visually reviewed; the annual chart legend was
corrected after visual inspection. No publication, corpus replacement or shared
aggregate replacement was performed.

Subsequent correction: the user flagged the misleading shift from 601,036
analysed records to 153,015 selected-group records. Make the inclusion arithmetic
explicit on pages 1-3, distinguish the selected-group top fifty from a new
diagnostic full-dataset top fifty, and validate both. General-media and
unidentified source labels in the latter are not asserted to be theological
actors.
