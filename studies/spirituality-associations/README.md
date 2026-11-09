# Study Croatia spirituality associations and public visibility

- **Slug:** `spirituality-associations`
- **Owner:** Luka Šikić
- **Status:** exploratory analysis completed; identity and visibility validation pending
- **Opened:** 2026-09-19
- **Croatian working title:** Udruge iz područja duhovnosti u Hrvatskoj i njihova javna vidljivost
- **Research direction:** national atlas of organisations and their public visibility

This is a self-contained research-paper workspace alongside DigiKat's other thematic studies. It uses the supplied spirituality-category association register and the general monitored media feed. It does not use the Catholic-filtered corpus as its search population.

## Start here

- **Two Croatian reader reports (revised 22 September 2026):** [Udruge iz područja duhovnosti u medijskom prostoru](../../output/pdf/udruge-duhovnosti-u-medijskom-prostoru.pdf) and [Udruge iz područja duhovnosti: od riječi do javne uloge](../../output/pdf/udruge-duhovnosti-od-rijeci-do-javne-uloge.pdf). Each has 16 pages, with direct interpretations of results, ten leading organisational/programme names, named outlet counts, organisation-specific vocabulary and topic profiles, a six-topic map and seven word clouds. [Sources and reproduction](reader-reports/README.md). The reader-facing caution and collection passages were removed at the user's request; the operational provenance and original study records remain in the research documentation.
- **Full-period media landscape (2021-2026):** [execution and reproduction](media/README.md), [analytical report source](output/report/MEDIA_LANDSCAPE_2021_2026.md), and [PDF](../../output/pdf/spirituality-associations-media-landscape-2021-2026.pdf). This extends the initial 2025 screen to every date in the updated merged database; national identity/relevance validation remains pending.
- [Exploratory report](EXPLORATORY_REPORT.md) and [seven-page PDF](output/report/spirituality_associations_exploratory_report.pdf).
- [Research protocol and paper direction](PROTOCOL.md).
- [Detailed media collection and representation analysis plan](MEDIA_ANALYSIS_PLAN.md), with a [readable PDF](../../output/pdf/spirituality-associations-media-research-plan.pdf). This next-stage plan adapts *Demokršćanstvo u medijskom prostoru* to organisation identity, article matching, channels, themes, voices and investigative case studies.
- [Data codebook](CODEBOOK.md) and [official website evidence](WEB_EVIDENCE.md).
- [Searchable local directory](output/private/directory.html), retaining all 1,325 entries; open it in a browser. It is intentionally gitignored.
- [Aggregate tables](output/tables/) and [five figures in PNG and SVG](output/figures/).

The register reconciles exactly to all 21 PDF county totals. Official DZS estimates supply population context. The 2025 screen yields 3,806 unique candidate items linked by discovery rules to 248 association names; 795 screened names have no candidates and 282 names await identity rules. Candidates are not validated media coverage. A fixed twelve-day audit of unfiltered exports and nine official-source profile groups establish the main measurement issues.

## What is ready for further research

The private workspace contains a 60-organisation feasibility sample spanning all counties, 453 blank candidate review records, an apparent-miss queue, 17 documentary profile proposals covering nine source groups, and 15 separately labelled AI development readings. These are starting materials for identity, historical-eligibility and source-affiliation work. No human labels or validated national visibility ranking are claimed. All unknowns and zero-retrieval cases are retained.

## Files and disclosure

| Location | Contents |
|---|---|
| `01_register.py` | Preserve supplied files and independently extract/reconcile PDF cells |
| `02_media.py` | Read-only media inventory, deterministic pilot, full-year name screen and review queues |
| `03_enrichment.py` | Collect official HTML, save provenance and parse DZS county populations |
| `04_filter_audit.py` | Apply the vendor filter to twelve unfiltered daily exports |
| `05_profiles.py` | Documentary profile proposals and shared-domain audit |
| `06_outputs.py` | Generate report source, aggregate figures and private HTML directory |
| `07_report_pdf.py` | Typeset the report with embedded Croatian-capable fonts |
| `08_verify.py` | Sixteen groups of reconciliation, matching, privacy and reporting checks |
| `09_development_audit.py` | Join optional private AI notes without touching human labels |
| `10_media_plan_pdf.py` | Render the prospective media collection and analysis plan from Markdown |
| `output/private/` | Supplied PDF/JSON/brief, saved HTML, register rows, candidates and coding sheets |
| `output/tables/` | Aggregate diagnostics and provenance without media text or identifiers |
| `output/report/` | Research report PDF |

Original personal contact details remain only in the preserved private PDF. Email addresses are not copied into the derived register. No full media texts, titles, excerpts, URLs, individual addresses or coding sheets belong in trackable output. The local directory also omits personal contacts, addresses and media text. The reported official-source examples concern organisations' public self-descriptions.

## Reproduce from the repository root

The first run used Python 3.14 with the exact analysis package versions in [requirements](requirements.txt). It is an isolated Python study; the R pipeline and `renv.lock` are unchanged. The R disclosure guard ran through the project's normal startup and passed, with pre-existing locale and renv out-of-sync warnings.

Install the listed dependencies into a suitable Python environment. Use paths to your authorised local source files. In PowerShell:

```powershell
$env:PYTHONIOENCODING = 'utf-8'
python -m pip install -r studies/spirituality-associations/requirements.txt

python studies/spirituality-associations/01_register.py `
  --json 'PATH/associations_parsed.json' `
  --pdf 'PATH/POPIS UDRUGA U RH PO ŽUPANIJAMA.pdf' `
  --brief 'PATH/pasted-text.txt'

python studies/spirituality-associations/02_media.py `
  --database 'PATH/determDB_merged.duckdb'
python studies/spirituality-associations/03_enrichment.py
python studies/spirituality-associations/04_filter_audit.py `
  --source-dir 'PATH/Determ_mediaspace_full'
python studies/spirituality-associations/05_profiles.py
# Optional: requires the saved private AI development-label file.
python studies/spirituality-associations/09_development_audit.py
python studies/spirituality-associations/06_outputs.py
python studies/spirituality-associations/07_report_pdf.py
python studies/spirituality-associations/08_verify.py
Rscript R/check_disclosure.R
```

`02_media.py --inventory-only --database PATH` runs metadata/coverage and prepares the pilot without retrieving media candidates. The source connection is always read-only; DuckDB spill and candidate caches are private. Full-year retrieval scans all 2025 title/body records using an Aho-Corasick matcher. Cache signatures prevent reuse after source fingerprints or identity rules change. An interrupted file is renamed privately and recomputed; successfully written monthly files are installed atomically. The extraction can resume without repeating completed months. Do not alter or overwrite a source database to run this study.

The web collector preserves already downloaded HTML, records access time and SHA-256, and logs failures. To establish a new dated web snapshot, preserve the current directory and run against a separate new private snapshot; do not overwrite the frozen evidence silently. Websites are live, so fresh HTML need not reproduce old hashes. The original private register sources are required for complete replication and are not included in Git.

The PDF uses ReportLab; no desktop Word or LibreOffice automation is needed. Render it with Poppler and inspect every page after layout changes. Visual QA images are private. Report figures and PDF are rebuilt from the report script and aggregates, not edited by hand. The empirical report and tables are English; Croatian names and diacritics are retained. A Croatian public-facing version is a later paper/publication task.

## Interpretation and next step

The detailed [media analysis plan](MEDIA_ANALYSIS_PLAN.md) specifies the proposed next study stage: complete the 60-organisation identity pilot, expand retrieval into unfiltered 2025 exports, validate organisation-article links, then describe and investigate representation. It includes query templates, source and editorial-origin distinctions, sampling and coding plans, analysis denominators, case-selection rules and work-package completion criteria. These proposed analyses have not yet been executed. Rebuild its PDF with `python -X utf8 studies/spirituality-associations/10_media_plan_pdf.py`, then render and inspect every page.

Read `PROTOCOL.md` before extending the analysis. The next bounded stage is to verify historical identity and aliases for the pilot, inspect apparent misses and independently annotate held-out passages. Separate own communication, independent reporting, public discussion and unresolved institutional/other content. Large candidate counts for generic sayings or website navigation must not become evidence of prominence. The fixed-day filter diagnostic cannot correct annual or national visibility estimates.

No website publication, commit, upstream database mutation, survey, interview or organisational contact is part of this first exploration. Before publication, complete human validation, assess vendor terms and disclosure, and decide which aggregate outputs and organisation-level directory fields are suitable for release.

## Declarations and log

Restricted data remain private under the project's [data availability policy](../../DATA_AVAILABILITY.md). Scripts and aggregate diagnostics are research working material pending publication review. Codex assisted with source extraction, analysis and drafting; AI profile proposals and development readings are not human validation.

- **2026-09-19:** Opened study; reconciled frame; collected official web/population evidence; scanned full calendar 2025; audited twelve unfiltered dates; generated report, directory, figures and coding queues; verified outputs and disclosure. No existing study or production corpus was changed.
- **2026-09-19:** Added the detailed next-stage media research plan and PDF, using the Christian-democracy report as the analytical reference. Expanded retrieval, human validation and substantive representation analysis remain planned work.
