# Catholic communicators: descriptive research reports

## Review workbook (2021–2025 local snapshot)

The Croatian PDF `output/private/extended/katolicki-komunikatori-15-grafova.pdf`
contains one introductory page and 15 numbered graph pages, each with a short
explanation. Rebuild with `python studies/theological-authority/build_visual_brief.py`.
It uses the same `workbook_data.json`; named-source figures remain private.
The graph sequence covers inclusion, group counts, publication/interaction shares,
platform composition, collection coverage, annual totals/composition, concentration,
same-source annual ranks, matched seasonal comparisons, and all 50 shortlist names
across two platform-grouped graphs. Graphs 14 and 15 retain each source's original
overall shortlist rank and show captured publications (web articles, videos or
social posts), summed recorded reach, and recorded interactions. The light bars
compare interactions within each platform; an asterisk marks partial metric
coverage. Summed reach is not a count of unique people. Charts are embedded as
vector PDF graphics.
The graph 2 count means a unique platform plus normalized `FROM` label observed
in the local input, not a verified person, publisher or website. Of 722 selected
pairs, 514 carry the provisional devotional/author label; 483 of those labels
come from the `creator_pattern` name rule. The chart now shows assignment method
alongside group count, and the cover identifies the local input file. User-provided
examples were not treated as the list of all actors.
Render using Poppler into `tmp/pdfs/actor-visual-brief/page-*.png`, then run
`python studies/theological-authority/verify_visual_brief.py` for content, exact
top-50 totals/names, Croatian text, page bounds and unchanged input-hash checks.

An interactive Croatian research view is generated with
`python studies/theological-authority/build_research_visual.py` from the validated
workbook data. The private fragment `output/private/extended/akteri-vjera-istrazivanje.html`
compares actor-group publication/interaction shares, provides up to 50 sources per
platform/year selection, retains five-year histories of selected sources, and
shows the matched July–December supplement. Its default view is Facebook; raw
cross-platform sums are explicitly labeled as selection lists. It includes only
the six selected groups, with the full-dataset size provided as context. All named
data remain private. The view measures recorded attention, not demonstrated
theological authority, doctrinal interpretation or verified lay/clergy status.
Browser checks cover source selection, empty years, all 50 overall leaders,
seasonal comparisons and narrow-screen layout. Public actor aggregates were
independently confirmed on GitHub on 2026-10-13; their official-corpus provenance
differs from this visualization and their values are not mixed into it.

`analyze_extended.R` now also sources `workbook_tables.R`. It retains the report's
existing `source_year.csv` annual top-50 export and adds complete
`source_year_all.csv` and `source_overall_all.csv` in `output/private/extended/`.
Both contain explicit `all` and `selected` scopes; these overlap and must not be
added together. Source identity remains platform plus normalized source label.

After rebuilding the extended analysis with the command below, run:

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --vanilla studies/theological-authority/export_workbook.R
python studies/theological-authority/test_workbook.py
```

The workbook is
`output/private/extended/katolicke-teme-i-komunikacijski-akteri-2021-2025.xlsx`.
It has the nine requested sheets, Croatian headings and glossary, filters,
frozen headers, and numeric metrics. `Kodiranje` retains the specified stable
field keys, explained in Croatian in `Procitaj`. The July–December comparison,
including the matched-source supplement, is in `Obuhvat`. All results describe
interactions recorded for publications dated in the selected period, not the
date when interactions occurred. Unknown metrics are blank; observed zeros
remain zero. Overall means and medians come directly from publications.

The inclusion flow is recalculated: 612,065 input records, 609,156 dated in
2021–2025, 601,036 after duplicate handling, and 153,015 in the selected groups.
The window does not imply complete collection. Annual platform coverage includes
zero-capture platform/year combinations. Rankings break ties by stable source ID
after descending interactions, separately within scope/platform/year. The overall
selected top 50 is a cross-platform selection list. Its 250-row annual history
retains years below the annual top 50 and flags years without captured posts.

Manual coding is stored separately in `output/private/manual-coding/kodiranje.csv`.
Edit that CSV **or** the workbook's `Kodiranje` sheet. On export, a three-way merge
with the last-export baseline preserves edits by source ID, including cleared
cells. Conflicting edits stop the export before either is overwritten. CSV
versions are backed up by content hash. Existing source rows are retained even
if absent from a later analysis. Do not change identifiers or delete coding rows.
Draft classifications are not silently replaced by reviewed labels in analysis.
Mandate, individual clergy/lay status, channel type, theological education,
authority claims and interpretation of doctrine are distinct, initially unknown
fields. Record date intervals for changing status; use notes for multiple intervals.

`export_workbook.R` calls the study-local Python preservation/verification helper
and the JavaScript workbook builder. Requirements: Python with `openpyxl` (read
only), Node, and the Codex-supplied `@oai/artifact-tool` runtime. Set
`CODEX_WORKBOOK_NODE_MODULES` to that runtime's `node_modules` on another host.
It does not install or alter repository dependencies. Generated workbooks, named
CSVs, JSON intermediates and visual previews remain ignored/private; only
identity-free inclusion, coverage, actor-year and seasonal summaries go to
`output/extended/workbook_*.csv`.

Validation reconciles annual/overall and selected totals, unique joins, missing
metrics, contextual ranks/shares, full shortlist histories, Croatian text and
every saved cell's type/value, filters, frozen headers, manual coding preservation,
and the unchanged SHA-256 of the input. See private `workbook_validation.json`.

Six-page Croatian research briefing plus a top-50 source table, requested on
13 October 2026. This is an exploratory reuse of existing data and actor lists.
It contains no pilot, human content-coding exercise, dual coding, interviews,
credential verification or inferential models.

The authorized extension is a **twenty-page Croatian report** with all-platform
coverage, six platform profiles, recorded reach, monthly collection coverage,
annual actor composition, a matched-source seasonal comparison, public-resource
availability, and the complete top fifty inside the PDF. The original six-page
briefing is preserved. The extension retains the same exploratory scope.

The report explicitly distinguishes **601,036 analysed records** from the
**153,015 records** attributed to the six selected Catholic-communicator groups.
The other 448,021 records remain in all-platform and time overviews; the selected
group comparisons and PDF top fifty do not describe all records. The separately
supplied full-dataset top fifty is a ranking of recorded source labels, including
general media and labels that do not identify an individual actor.

## Input

The input is the available local file resolved by `digikat_legacy_master_path()`.
Direct inspection found **612,065 rows**, dated 2021-01-01 through 2026-01-06,
with SHA-256 `f6b276321822b29525240012c7be950fce9e6502928590f5f0815648c79d0d4f`.
This is not the newer 413,985-row official corpus and does not match the larger
accumulator described by repository documentation. The user requested the
Catholic dataset available here; the snapshot distinction was stated before
analysis and is explicit in the report.

The analysis selects 2021-2025, then retains the greatest available interaction
snapshot for repeated exact platform/URL pairs. Missing URLs remain separate.
The report gives the complete sample flow. Dates, not the stored year field,
determine the analysis period. Sources are platform/name pairs; the one explicit
duplicate alias in the existing source catalogue is combined within platform.

## Reused resources

- `studies/catholic-influencers/actor_classification.R`
- Pure name-pattern definitions from `explorations/_okvir_engine/okvir_lib.R`
- `explorations/okvir-katolicanstva-prototype/source-groups.csv`
- `resources/dictionaries/source_labels.csv`
- `R/lib/thematic_dictionaries.R`

The more explicit registry overrides broad inherited labels. Unknown operators
are not called lay people. Novi Zivot is retained as a separate inter-Christian
boundary case following the existing registry. The pulherissimus classification
uses the register's note about a priest editor. No new biographical claims were
researched. A classification describes the publishing channel, not necessarily
the speaker appearing in a publication.

## Reproduce

From the repository root on this Windows machine:

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --vanilla studies/theological-authority/analyze.R
python studies/theological-authority/build_report.py
python studies/theological-authority/verify_report.py
```

For the twenty-page extension (the locale must be set before sourcing on this host):

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --vanilla -e "Sys.setlocale('LC_CTYPE','English_United States.utf8'); source('studies/theological-authority/analyze_extended.R', encoding='UTF-8')"
python studies/theological-authority/build_extended_report.py
python studies/theological-authority/verify_extended_report.py
```

The extension sources the base analysis, then adds reach, yearly/monthly measures
and source ranks. Undefined metrics have missing totals, not zeros. Sources with
no observed engagement are never ranked. Seasonal comparisons retain sources
with at least five captured posts in each July-December window in 2024 and 2025;
they do not equalize observation age or establish causality. Public availability
was checked against GitHub and recorded in `public_availability.json`.

The standalone R invocation intentionally uses the installed global packages
because this clone's renv startup did not complete. Package versions and resource
hashes are recorded in `output/manifest.json`; no dependency or lockfile was
changed. All computations read the dataset without writing it. No website build
or publication is involved.

## Outputs

Twenty-page deliverables:

- `output/private/extended/katolicki-akteri-platforme-doseg-vrijeme.pdf`
- `output/private/extended/izvjestaj.html`
- `output/private/extended/top-50-izvora.csv`: full-period top fifty, within-platform
  ranks, 2025 ranks and totals, reach coverage, blank fields for later coding;
  this is the **selected six-group** ranking.
- `output/private/extended/top-50-sve-oznake-izvora.csv`: diagnostic ranking
  among **all 601,036 records**, with actor-classification status.
- `output/private/extended/top-50-po-platformama.csv`: up to fifty per platform.
- `output/private/extended/top-50-drustvene-mreze.csv`: social platforms only.
- `output/extended/agregati-za-dijeljenje.zip`: identity-free tables, manifest,
  public-resource inventory and Croatian field glossary. Prepared locally,
  **not newly published online**.

PDF validation checks twenty pages, all fifty names and exact companion values,
rank sequences, total reconciliation, unsupported metrics, the 2024 gap, Croatian
text, page geometry and input-file immutability. All pages are rendered for visual
review using PyMuPDF because Poppler is unavailable on this host.

Original six-page deliverables:

- `output/private/katolicki-akteri-istrazivacki-uvid.pdf`: six-page report.
- `output/private/izvjestaj.html`: readable HTML version of the same content.
- `output/private/top-50-izvora.html`: complete named source list.
- `output/private/top-50-izvora.csv`: semicolon-separated UTF-8 table, with blank
  mandate, education and notes columns for possible later work.
- `output/private/top50_social.csv` and `top50_by_platform.csv`: supplementary
  platform views.
- `output/*.csv`: aggregate descriptive tables, including all sentiment levels.
- `output/manifest.json`: input and resource provenance.

Named sources and research deliverables remain in the ignored private directory.
Raw posts, excerpts and corpus URLs are not exported. The full ranking uses the
vendor's raw interaction field; it is not a platform-neutral influence ranking
or a count of unique people. Primary concentration and sentiment comparisons are
made within platforms. Text matching is a simple dictionary indicator, not a
measurement of performed theological interpretation or recognized authority.
