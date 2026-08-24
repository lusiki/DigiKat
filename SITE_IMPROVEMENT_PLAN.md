# DigiKat site improvement plan

Status: ready for implementation  
Project type: academic research project website  
Implementation model: six sequential, reviewable runs  
Primary publishing system: Quarto website with R-generated content and versioned output in `docs/`

## 1. Purpose of this plan

This plan improves how visitors understand and navigate DigiKat without changing its academic character. The site should become easier to enter, read, verify, cite, and use while remaining methodologically transparent and visually restrained.

The central project outputs are, in this order:

1. the official DigiKat corpus and its documentation;
2. maps and analytical views of the media space;
3. annual and thematic research outputs;
4. supporting public tools, including **Moj medij**.

**Moj medij** may be the project's strongest public-facing tool, but it is not the project's main identity and must not displace the corpus, maps, or research on the homepage.

The public data story should remain simple: DigiKat is based on the **official corpus of approximately 400,000 records**. Internal accumulators and historical snapshots should not become a public narrative. The manifest remains the technical source of truth, but public-facing copy should emphasize the single official corpus.

## 2. Non-negotiable editorial and visual principles

### 2.1 Academic rather than commercial

The redesign must not make DigiKat resemble a commercial product, media startup, or marketing landing page.

Use:

- calm, evidence-led language;
- restrained typography and colour;
- clear research questions and findings;
- publication dates, citations, licences, and data cutoffs;
- editorial cards that resemble publication records or catalogue entries;
- modest calls to action that help visitors choose a research path;
- subtle motion only when it improves orientation;
- generous whitespace without promotional spectacle.

Avoid:

- sales language, urgency, or promotional superlatives;
- oversized marketing banners;
- repeated calls to action for the same destination;
- decorative badges without scholarly meaning;
- gamified metrics or dashboard aesthetics when a table or sentence is clearer;
- excessive animation, gradients, shadows, or saturated colour;
- describing ordinary navigation as a conversion funnel;
- making **Moj medij** appear to be the purpose of the project.

### 2.2 Stable project formulation

Use one canonical purpose sentence across the homepage, metadata, project description, and major outputs:

> DigiKat je otvoreni opservatorij koji pokazuje tko u Hrvatskoj objavljuje o katoličkim temama, o čemu govori i što privlači pozornost.

The homepage questions may remain as supporting copy, but they must not replace or compete with this formulation.

### 2.3 Evidence before interface

Every design choice should help visitors do at least one of the following:

- identify the official corpus;
- understand a finding;
- assess what can and cannot be concluded;
- find the methodological basis;
- inspect or download a public research artifact;
- cite a dataset, page, or publication;
- continue to the next relevant research output.

### 2.4 One canonical home for technical methodology

Splits, samples, thresholds, coverage changes, measurement construction, filtering rules, and other technical details belong on the methodology page.

Result pages may contain:

- a short scope statement;
- a plain-language caution necessary to interpret the result;
- a link to the relevant methodology anchor.

They should not repeat implementation-level methodological explanations beside every result. The 60-second summaries required below should state what can and cannot be concluded without reproducing technical detail.

### 2.5 One public corpus

The data page should present the official corpus as the authoritative dataset:

> Službeni korpus DigiKat obuhvaća približno 400.000 zapisa.

The visible page should not build a story around internal accumulators, superseded snapshots, or changing historical totals. If older material must remain accessible for reproducibility, place it in a quiet archival note or repository documentation rather than the primary data interface.

## 3. Scope and implementation constraints

The work affects:

- the global Quarto configuration and navigation;
- the homepage;
- the official corpus page;
- the methodology page;
- the five map pages;
- **Moj medij** and its generated data;
- the annual report;
- the bespoke **Kako se govori o Crkvi?** report;
- thematic-study entry pages;
- approximately 96 source-profile pages;
- shared CSS, chart themes, metadata includes, and generated assets;
- release validation and CI.

Existing unrelated changes under `explorations/` must remain untouched and must not be included in site-improvement commits.

Generated files under `docs/` must not be edited as primary source. Edit the relevant Quarto, R, CSS, JavaScript, or report source and regenerate the output.

## 4. Target information architecture

Keep approximately four primary navigation groups.

### Istražite

- Mapa medijskog prostora
- Moj medij
- Katalog izvora
- Izvršni pregled, if retained as an active public entry point

### Podaci i metodologija

- Službeni korpus
- Metodologija
- Reproducibilnost and public resources
- Citation and data-access information

### Istraživanja

- Pregled istraživanja
- Godišnji pregled
- Tematska istraživanja
- Other major research publications

### O projektu

- O projektu
- Tim and institutional context
- Obavijesti
- Projektni raspored
- Kontakt

GitHub, technical site information, licences, and secondary resources belong in the footer or a quiet utility area. Navigation labels should remain short enough not to wrap on supported desktop widths.

## 5. Shared page model

Every substantial page should use a consistent academic page model.

### 5.1 Page opening

Where appropriate, begin with a 60-second summary containing:

- the page purpose;
- up to three central findings or contributions;
- what can be concluded;
- what cannot be concluded;
- the most relevant next action or related output.

This should be a compact editorial summary, not a promotional hero.

### 5.2 Freshness and status

Substantial pages should expose the relevant subset of:

- **Objavljeno**
- **Ažurirano**
- **Podaci zaključno s**
- **Status**

Use a small, restrained metadata strip. Distinguish clearly between:

- project period: 2025–2027;
- observation period: 2021–2026, or the current manifest range;
- report year;
- page publication date;
- data cutoff date.

Recommended status vocabulary:

- Radni prikaz
- Preliminarno
- Ažurira se
- Stabilno izdanje
- Arhivirano

The final vocabulary should be ratified in Run 1 and then used consistently.

### 5.3 Reference layers

Long definition lists, variable dictionaries, technical details, and reproducibility material should use accessible expandable sections. Essential findings and interpretive cautions must remain visible without expansion.

### 5.4 Citation block

Major datasets, reports, and studies should provide a consistent citation block with:

- recommended citation;
- permanent URL;
- version or publication date;
- licence;
- machine-readable citation where available.

## 6. Controlled vocabulary and Croatian editorial guide

Run 1 should create a short maintained editorial guide. It must distinguish and define at least:

- **interakcije**: the preferred public term for recorded platform actions;
- **angažman**: use only when it denotes a defined calculated measure, or replace it with interakcije;
- **doseg**: label clearly as an estimated or vendor-provided value where relevant;
- **izvor**: the recorded publishing source or account;
- **akter**: use only for an analytically defined participant, not as an automatic synonym for source;
- **platforma**: the technical or publishing environment;
- **korpus**: the official research collection selected by the project's documented rule;
- **objava** and **zapis**: define when they may be treated as equivalent and when they may not.

Replace or explain expressions such as:

- `vendorska procjena` → `procjena pružatelja usluge` or a shorter defined term;
- `kick off` → `početni sastanak`;
- `seminalni rad` → `utjecajan`, `temeljni`, or another context-appropriate Croatian expression.

The final sweep must also check punctuation, capitalization, date formats, `R i Python`, duplicated full stops, and inconsistent names of outputs.

## 7. Run summary

| Run | Primary outcome | Improvements covered |
|---|---|---|
| 1 | Shared academic foundation | 1, 2, 6, 7, 9, 14, 15 |
| 2 | Homepage and official corpus page | 1, 3, 5, 8, 14, 15 |
| 3 | Moj medij as a flagship supporting tool | 4, 7, 11, 12 |
| 4 | Maps and analytical chart system | 7, 8, 10, 11, 12, 13 |
| 5 | Reports and long-form publications | 8, 9, 11, 12, 13, 14, 15 |
| 6 | Whole-site language, accessibility, responsive, metadata, performance, and CI pass | 6, 11, 12, 13, 14, 15 |

Runs should be executed sequentially. Each run ends with a reviewable commit and must pass its defined gate before the next run begins.

## 8. Run 1 — Shared academic foundation

### Objective

Establish the content, navigation, visual, metadata, and methodological contracts required by every subsequent page.

### Work

1. Add the canonical purpose sentence to the appropriate shared project metadata and editorial documentation.
2. Replace the current crowded navigation with the four-group structure.
3. Move schedule, news, contact, resources, technical information, and GitHub to appropriate secondary locations.
4. Create the controlled vocabulary and Croatian editorial guide.
5. Inventory repeated methodological passages and map each passage to a canonical methodology section and anchor.
6. Define which short cautions may remain on result pages.
7. Define shared design tokens for:
   - typography;
   - spacing;
   - colour;
   - borders and restrained shadows;
   - focus states;
   - status treatments;
   - chart colours;
   - print behaviour.
8. Create or standardize reusable components for:
   - 60-second summaries;
   - publication entries;
   - freshness/status strips;
   - citation blocks;
   - figure cards;
   - download groups;
   - expandable references.
9. Define the site-wide metadata model:
   - title;
   - description;
   - canonical URL;
   - social image and alternative text;
   - publication and modification dates;
   - data cutoff;
   - status;
   - Schema.org type.
10. Remove homepage-specific visual rules from inline styles where they should be reusable.
11. Preserve the existing restrained visual character; do not attempt the final page redesign in this foundational run.

### Deliverables

- revised `_quarto.yml` navigation and footer;
- shared design tokens and components in the main SCSS/include system;
- an editorial guide;
- a methodology relocation map;
- a metadata and freshness contract;
- a documented status vocabulary.

### Acceptance criteria

- Primary navigation contains four clear groups and does not wrap at 1024 px or wider.
- The canonical purpose sentence is stored once as the approved formulation.
- Every repeated technical-method passage has a designated methodology destination.
- Shared components look editorial and academic, not promotional.
- Focus styles and reduced-motion behaviour are included in the shared system.
- Existing pages still render without structural regressions.

### Review gate

Before Run 2, approve:

- the canonical purpose sentence;
- navigation labels and grouping;
- controlled vocabulary;
- status vocabulary;
- academic visual direction;
- methodology relocation rules.

## 9. Run 2 — Homepage and official corpus page

### Objective

Make the project's scope and primary research outputs immediately legible while keeping the homepage calm and academic.

### Homepage hierarchy

Use this order:

1. project purpose;
2. official corpus and database;
3. maps of the media space;
4. research and latest publications;
5. additional tools, including **Moj medij**.

### Homepage work

1. Use the canonical purpose sentence as the primary statement.
2. Retain the existing research questions as supporting copy.
3. Replace five competing hero buttons with a restrained path hierarchy.
4. Use one primary research-oriented action, preferably **Istražite mapu**.
5. Provide quiet secondary links to the official corpus and research overview.
6. Present **Moj medij** lower on the page or within the exploration section as a supporting tool, not as the main hero action.
7. Replace the small report-link line with a stronger but restrained **Najnoviji nalazi** section.
8. Make each research entry resemble a publication record and include:
   - title;
   - publication date;
   - one-sentence finding;
   - approximate reading time where useful;
   - status;
   - HTML and PDF links where available.
9. Rebuild the statistics strip so it uses one or two columns on narrow screens and never creates page-level horizontal scrolling.
10. Preserve the project's current visual restraint and avoid commercial hero treatments.

### Official corpus page work

1. Present one authoritative dataset: the official DigiKat corpus of approximately 400,000 records.
2. Provide a compact access panel showing:
   - current data cutoff;
   - version or manifest date;
   - licence for public artifacts;
   - recommended citation;
   - corpus manifest;
   - public aggregate files;
   - codebook;
   - synthetic sample;
   - full-text access procedure.
3. Keep the visible dataset story singular and stable.
4. Do not foreground internal accumulators or historical snapshots.
5. Retain older release information only where necessary for archival reproducibility, outside the primary page narrative.
6. Add a 60-second summary.
7. Move filtering, sampling, collection-break, and measurement details to methodology anchors.
8. Keep a concise visible statement of what the corpus can and cannot support.
9. Place full variable tables and reproduction instructions in accessible expandable reference sections.
10. Add Dataset structured data appropriate to the official corpus and its public artifacts.

### Deliverables

- revised homepage source and shared styles;
- revised official corpus page;
- publication-entry component populated with current research outputs;
- working public artifact and citation links;
- page-level descriptions and metadata for both pages.

### Acceptance criteria

- A first-time visitor can state the project's purpose after reading the first screen.
- The corpus, maps, and research are visibly the three central outputs.
- **Moj medij** is discoverable but not visually dominant.
- The official corpus is presented as one dataset of approximately 400,000 records.
- The page does not ask ordinary visitors to reconcile multiple internal or historical datasets.
- The homepage has no horizontal overflow at 320, 375, or 390 px.
- Publication links and all corpus-resource links resolve.

## 10. Run 3 — Moj medij as a flagship supporting tool

### Objective

Make **Moj medij** the project's best public utility while keeping it subordinate to the corpus, maps, and research in the overall project hierarchy.

### Placement

- Keep it within **Istražite**.
- Link to it from relevant corpus, map, and source-catalogue contexts.
- Give it a modest secondary presence on the homepage.
- Do not make it the homepage's primary heading, first output, or dominant visual block.

### Work

1. Replace the current long opening with a one-sentence explanation.
2. Place the search control immediately below that sentence.
3. Preserve the current client-side, static-site-compatible architecture.
4. After source selection, begin with **Tri stvari koje trebate znati**.
5. Generate the three statements from the profile data and define deterministic rules for them.
6. Prioritize findings with sufficient support; do not generate dramatic claims from sparse values.
7. Place detailed charts after the three-point summary.
8. Explain the comparison group in plain language and always name the comparison platform.
9. Preserve existing shareable query URLs and, if stable identifiers are introduced, maintain backward compatibility.
10. Add a **Kopirajte poveznicu** control with accessible confirmation.
11. Move long methodological notes into:
    - brief inline interpretive cautions;
    - accessible expandable sections;
    - links to canonical methodology anchors.
12. Remove the narrow methodological rail treatment.
13. Improve search/listbox behaviour:
    - arrow-key navigation;
    - Enter selection;
    - Escape dismissal;
    - correct focus handling;
    - active-option semantics;
    - announced empty and error states.
14. Provide textual or tabular alternatives for generated SVG charts.
15. Ensure wide heatmaps and event charts have an explicit narrow-screen treatment.
16. Test direct links, duplicate names, no-result searches, sparse profiles, and incomplete platform data.

### Deliverables

- revised `pages/moj-medij.qmd` interface and script;
- any required changes to its R-generated public payload;
- deterministic three-finding logic with regression tests;
- stable share behaviour;
- accessible search and chart alternatives.

### Acceptance criteria

- Search is the first interactive element after the explanation.
- Every valid profile starts with three supportable findings or an honest statement that fewer findings are available.
- Comparisons are within-platform and clearly explained.
- Deep links remain stable.
- The tool is fully usable by keyboard.
- It produces no page-level horizontal scrolling at required widths.
- Methodological detail is no longer presented as a dense side rail.
- The page looks like a public research instrument, not a commercial analytics dashboard.

## 11. Run 4 — Maps and analytical chart system

### Objective

Make the five map pages readable as analytical arguments rather than archives of high-resolution graphics.

### Shared chart contract

Every substantive chart should have:

1. one explicit takeaway immediately before it;
2. a concise descriptive title;
3. direct labels for important values where feasible;
4. a visible annotation for methodological or collection breaks when relevant;
5. a proper figure caption;
6. a meaningful alternative summary;
7. an accessible table view;
8. CSV data download;
9. SVG download when the chart is suitable for vector output;
10. optimized PNG fallback where required.

### Work

1. Apply the shared page opening to:
   - Mapa ekosustava;
   - Evolucija ekosustava;
   - Tematske struje;
   - Atmosfera diskursa;
   - Fokus na događaje.
2. Define one analytical question and one main conclusion for every existing figure.
3. Remove or combine figures that do not contribute a distinct conclusion.
4. Split figures whose panels or labels are too dense at ordinary reading sizes.
5. Direct-label important series and values instead of relying only on legends.
6. Standardize the colour-blind-safe palette in the shared R theme.
7. Make colour meaning consistent across all map pages.
8. Move implementation-level methodological passages to the methodology page.
9. Retain only short result-specific interpretive cautions and anchor links.
10. Add accessible figure summaries and correct heading hierarchy to one H1 per document.
11. Prefer SVG for line, bar, point, and other vector-friendly charts.
12. Where raster output remains necessary, generate responsive variants close to actual display size rather than 5,600–9,800 pixels wide.
13. Use lazy loading for below-the-fold figures.
14. Make large tables responsive without making their contents inaccessible.
15. Add stable file naming for chart assets and data downloads.
16. Ensure downloadable data does not expose restricted row-level text or URLs.

### Recommended internal sequence

If the run is too large for one implementation session, split it without changing the contract:

- Run 4A: Mapa ekosustava and Evolucija ekosustava;
- Run 4B: Tematske struje, Atmosfera diskursa, and Fokus na događaje.

### Deliverables

- shared chart-production helpers;
- revised map-page structures;
- optimized chart assets;
- table alternatives and download files;
- chart accessibility summaries;
- regression checks for disclosure and expected output files.

### Acceptance criteria

- Every retained chart communicates a distinct finding.
- Every retained chart satisfies the shared chart contract.
- Every map page has exactly one H1.
- Chart meaning is not dependent on colour alone.
- Methodological breaks are visibly annotated where they affect interpretation.
- Raster width does not materially exceed responsive display needs.
- Map pages remain usable at all required viewports.
- Public download files pass disclosure checks.

## 12. Run 5 — Reports and long-form publications

### Objective

Bring long-form outputs into the same academic family as the main site while preserving their editorial strengths.

### Work

1. Define the minimum shared identity for standard Quarto pages, the annual report, and **Kako se govori o Crkvi?**:
   - masthead;
   - footer;
   - typography hierarchy;
   - core palette;
   - figure and table treatment;
   - status strip;
   - citation block;
   - focus and accessibility behaviour.
2. Preserve the distinctive editorial pacing of the bespoke report.
3. Do not force every output into an identical template.
4. Avoid magazine-style promotion or product-marketing treatments.
5. Add a 60-second summary to long reports where it improves orientation.
6. Add strong section navigation to the annual report.
7. Add a restrained reading-progress indicator, disabled or simplified for reduced-motion and print contexts.
8. Correct heading structure to one document H1 followed by logical H2/H3 sections.
9. Replace embedded base64 report images with external optimized assets.
10. Create responsive image variants and lazy-load below-the-fold figures.
11. Apply the shared chart accessibility and download contract where applicable.
12. Add canonical URL, description, Open Graph, Twitter, favicon, and Article or ScholarlyArticle structured data.
13. Add publication date, update date, report year, data cutoff, and status.
14. Verify that HTML and PDF citations and links agree.
15. Preserve print quality and PDF rendering while optimizing the web version separately.

### Deliverables

- revised annual-report source/template;
- revised bespoke-report shell and styles;
- shared report metadata include or equivalent reusable mechanism;
- external optimized report images;
- corrected heading and navigation structure;
- verified HTML and PDF outputs.

### Acceptance criteria

- All three publication systems are recognizably DigiKat without looking identical.
- The annual report contains one H1.
- The annual report no longer embeds large base64 images.
- Long reports provide visible section orientation.
- Report metadata and social previews resolve correctly.
- HTML remains readable on small screens and PDF/print output remains stable.
- The visual tone remains scholarly and restrained.

## 13. Run 6 — Whole-site hardening and release automation

### Objective

Apply the shared standards across the complete active site and convert the most important quality requirements into repeatable release checks.

### Editorial work

1. Run the Croatian-language sweep across active source files.
2. Apply the controlled vocabulary consistently.
3. Correct unexplained English terms, punctuation, capitalization, and date formats.
4. Update stale news and remove past events from **Uskoro**.
5. Check project period, observation period, report year, and publication dates for accidental conflation.

### Generated-page work

1. Identify the canonical generator or shared template for source-profile pages.
2. Apply freshness, terminology, metadata, and methodology-link changes through that generator or template.
3. Do not hand-edit approximately 96 repeated pages individually unless a page has genuinely unique content.
4. Regenerate and spot-check representatives from every platform.

### Accessibility work

1. Validate one H1 per page and logical heading order.
2. Validate link and control names, including the GitHub icon.
3. Validate keyboard-visible focus and complete keyboard operation.
4. Validate figure summaries, captions, and table alternatives.
5. Validate table headers, scopes, and responsive wrappers.
6. Validate WCAG 2.2 AA contrast.
7. Validate reduced-motion behaviour.
8. Validate forms and dynamic announcements in **Moj medij**.

### Responsive work

Test at minimum:

- 320 px;
- 375 px;
- 390 px;
- 768 px;
- 1024 px.

At each width, test:

- global navigation;
- homepage purpose and actions;
- statistics strip;
- publication entries;
- official corpus access panel;
- **Moj medij** search and all chart types;
- map figures and tables;
- annual-report navigation;
- footer;
- absence of page-level horizontal scrolling.

### Metadata work

1. Give every substantial page a unique conventional description.
2. Prevent duplicated site names in titles.
3. Fix social-image paths for nested pages.
4. Validate canonical URLs.
5. Validate image dimensions and alternative text.
6. Add Dataset, Article, or ScholarlyArticle structured data only where semantically appropriate.
7. Keep the global ResearchProject and WebSite schema.

### Performance work

1. Establish measured page-weight budgets for standard pages, map pages, **Moj medij**, and reports.
2. Flag raster assets significantly larger than their rendered requirement.
3. Lazy-load appropriate below-the-fold images.
4. Defer nonessential scripts.
5. Avoid duplicating large JSON or CSS payloads across pages.
6. Verify that optimizations do not remove citation, table, or accessibility content.

### CI additions

Add automated checks for:

- exactly one H1 per substantial page;
- logical heading order;
- missing or empty descriptions;
- missing canonical URLs;
- unresolved social images;
- missing accessible chart summaries;
- broken local links and anchors;
- page-level horizontal overflow at required viewports;
- serious automated accessibility violations;
- stale or invalid freshness fields;
- image-dimension and page-weight budgets;
- browser console and network errors.

### Deliverables

- completed language sweep;
- regenerated profile pages;
- accessibility and responsive fixes;
- corrected site-wide metadata;
- performance improvements;
- expanded CI and release checklist;
- final rendered `docs/` output.

### Acceptance criteria

- All active pages pass the controlled-vocabulary and editorial checks.
- No stale **Uskoro** entry remains.
- All substantial pages expose appropriate freshness and status information.
- Required viewports have no page-level horizontal overflow.
- Automated accessibility checks have no serious or critical violations, with remaining manual findings documented and resolved.
- Canonical, description, social-image, and structured-data checks pass.
- Full build, disclosure, regression, link, and browser checks pass.
- A final manual review confirms that the site remains academic rather than commercial.

## 14. Verification workflow for every run

Use the repository's locked environment where possible. The documented target is R 4.6.0 and Quarto 1.9.38.

Before editing:

```powershell
git status --short
quarto --version
Rscript --version
```

Preserve unrelated worktree changes. Do not stage or commit unrelated files.

During implementation, run the smallest relevant checks first. Before completing a run, execute the applicable full sequence:

```powershell
Rscript tests/run_tests.R
Rscript R/check_sources.R
Rscript R/check_disclosure.R
Rscript R/00_setup.R
quarto render
Rscript R/check_site_links.R
```

For pages with dynamic JavaScript, also run the existing browser-console check against the affected rendered pages:

```powershell
node scripts/check_browser_console.mjs docs index.html pages/moj-medij.html
```

Extend the page list for the run being verified. Run the responsive and accessibility checks introduced in Run 6 as soon as those scripts exist.

After rendering:

```powershell
git status --short
git diff --stat
git diff --check
```

Review generated changes before staging. Each run should end with:

- source changes;
- corresponding regenerated output where the repository tracks it;
- tests or checks for new behaviour;
- a concise commit message describing one coherent outcome.

## 15. Manual review matrix

| Area | Representative pages |
|---|---|
| Homepage and navigation | `index.html` |
| Official corpus | `pages/baza.html` |
| Methodology | `pages/metodologija.html` |
| Public tool | `pages/moj-medij.html` |
| Map landing | `pages/mapa/index.html` |
| Quantitative map | `pages/mapa/mapa.html` |
| Time map | `pages/mapa/evolucija.html` |
| NLP map | `pages/mapa/mapa_stats.html` |
| Discourse map | `pages/mapa/diskurs.html` |
| Event map | `pages/mapa/događaji.html` |
| Study index | `pages/studije/index.html` |
| Annual report | `assets/izvjestaji/godisnji-pregled-2025.html` |
| Bespoke report | `assets/izvjestaji/kako-se-govori-o-crkvi/index.html` |
| Source catalogue | `pages/izvori/index.html` and one profile from each platform |
| News and freshness | `pages/news.html` |

For every representative page, review:

- academic tone;
- clarity of purpose;
- output hierarchy;
- headings;
- metadata and freshness;
- keyboard use;
- responsive layout;
- chart/table accessibility;
- working local links;
- print behaviour where relevant.

## 16. Performance and accessibility budgets

Run 1 should record current baselines; Run 6 should enforce agreed budgets. Use these principles when setting them:

- no raster chart should be several times wider than its largest intended rendered size;
- standard page HTML should remain compact;
- large research tools may carry justified data payloads, but those payloads should not be copied to unrelated pages;
- long reports should not embed large base64 image sets in HTML;
- below-the-fold imagery should normally be lazy-loaded;
- optimization must not replace accessible text or tables with image-only output;
- page-level horizontal scrolling is a release failure at the required viewports;
- WCAG 2.2 AA is the accessibility target.

Exact numeric byte budgets should be set after measuring the post-foundation baseline so they remain realistic for the project's research outputs.

## 17. Deferred and out-of-scope work

Unless separately authorized, this plan does not include:

- changing the official research results;
- recomputing completed thematic studies on a new corpus;
- publishing restricted full text or source URLs;
- exposing internal accumulators as public datasets;
- making historical Kaggle snapshots part of the main public data narrative;
- rebuilding DigiKat as a commercial dashboard or a different web framework;
- changing the repository's data-disclosure rules;
- editing unrelated exploratory prototypes.

## 18. Definition of done

The overall programme is complete only when all of the following are true:

- The first screen states the project's purpose unambiguously.
- The corpus, maps, and research are visibly the central outputs.
- **Moj medij** is an excellent, discoverable supporting tool without dominating the homepage.
- Primary navigation contains four task-oriented groups and does not wrap at supported widths.
- The public data page presents one official corpus of approximately 400,000 records.
- Technical sampling, coverage, threshold, and split explanations have one canonical methodological home.
- Long pages provide layered entry points and accessible reference sections.
- Every analytical chart has a takeaway, caption, meaningful accessible summary, table view, and appropriate downloads.
- All substantial pages show the relevant publication, update, data-cutoff, and status information.
- The main site and reports share a restrained academic visual identity.
- Every substantial page has a useful description, valid canonical URL, working social image, and appropriate structured data.
- Tested viewports have no page-level horizontal scrolling.
- The annual report no longer embeds its large images as base64 data.
- The Croatian editorial and controlled-vocabulary sweep is complete.
- Regression, source, disclosure, render, link, accessibility, responsive, metadata, performance, and browser checks pass.
- A final manual review finds no interface treatment that makes DigiKat resemble a commercial product.

## 19. Run completion record

Append a short record after each completed run:

```markdown
### Run N completion

- Commit:
- Pages changed:
- Shared components changed:
- Tests added or updated:
- Verification commands passed:
- Manual viewports checked:
- Remaining known issues:
- Approval to continue:
```

Begin with Run 1. Do not combine all six runs into one implementation change.

### Run 4 completion

- Commit: recorded by the commit containing this completion record.
- Pages changed: all five analytical map pages, their generated site output, and the executive-overview links that consume the rebuilt map figures.
- Shared components changed: colour-blind-safe chart theme and non-colour encodings, aggregate-download builder and chart-evidence helper, Croatian date labels, lazy-image filter, responsive chart/table styles, 23 CSV downloads, and compact text-based SVG figures.
- Tests added or updated: focused source and rendered chart-contract checks, responsive-CSS assertions, aggregate disclosure validation, and Croatian date/download regressions.
- Verification commands passed: five individual map-page renders, executive-overview render, `R/00_setup.R`, `tests/run_tests.R`, rendered Run 4 contract checks, and `R/check_site_links.R`; repository-wide source and disclosure checks introduced no new findings.
- Manual viewports checked: browser control was unavailable; rendered DOM, one-H1, lazy-loading, overflow-containment, keyboard-focus, and download-target checks were used as deterministic substitutes.
- Remaining known issues: four pre-existing source-encoding findings, one pre-existing restricted-study disclosure finding, a pre-existing executive-overview alt-text warning, no browser-console/visual viewport pass, and no full-site render without explicit authorization.
- Approval to continue: pending user review.
