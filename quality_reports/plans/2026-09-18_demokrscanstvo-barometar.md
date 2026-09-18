# Medijski barometar demokršćanstva: execution plan

Date: 2026-09-18. Owner and adjudicating coder: Luka Šikić (PI).

Status: **execution resumed 2026-09-18; recommended decisions and necessary gate actions authorized**.
This is the single execution plan required by brief revision 3, §0.3. Rows marked accepted or
overridden below record the PI's instructions. The instruction “Okay now run the plan” approves the remaining recommended design choices; human coding assignments, source-reuse clarification and licence confirmation remain at their stated gates.
The latest instruction, “run this brief and all decisions that are necessary and awaiting can be executed as recommended”, authorizes recommended choices and gate actions once their evidence exists. It supersedes repeat approval-only pauses in this plan. It does not supply human coding, establish unobserved validation results, or substitute for third-party licence/consent evidence. Earlier explicit amendments (D8, D15, D16 and collaborator exclusion) remain in force.

## Objective and authority

Implement the resource in `studies/demokrscanstvo-barometar/BRIEF.md`, copied byte-for-byte from
`quality_reports/plans/2026-09-18_demokrscanstvo-barometar_brief-r3.md`. Deliver a reproducible,
human-validated descriptive barometer, its Croatian Quarto page, open aggregate downloads, figures,
and edition-bound conference summary. The source population is the DetermDB general web feed,
separate from both the official DigiKat corpus and the historical accumulator.

The user's latest instruction authorizes the work and recommended decisions at G1–G6. Continue
autonomously, recording the concrete evidence and chosen recommendation at each gate. Gate
prerequisites remain executable checks; never fabricate scientific observations or licence consent.
Update this plan in place when decisions arrive. Do not create another execution plan. Later direct
PI instructions override the corresponding provisions of the original brief. Keep both original
brief copies unchanged; this plan records those amendments and governs the amended execution.

## Initial state and preflight

- Fetched `origin` and created `feat/demokrscanstvo-barometar` from `origin/main` at `ed19000`.
  The previous local `main` was `278a127`, 69 commits behind. Main was not changed.
- Original untracked files were the revision-3 review brief and
  `quality_reports/plans/2026-08-04_data-dictionary.md`. Leave both intact; never stage the latter.
- Read `CLAUDE.md`, `CLAUDE.local.md`, `.claude/rules/*.md`, the required MEMORY lessons, and
  the brief. Parallel read-only reviews cover all §1.2 governance, reuse and external-input material.
- Confirmed the expected CI mismatch: `tests/check_run6_site_quality.R:92` omits 1366 while
  `scripts/check_site_browser.mjs` includes it. Fix the expected string and synchronize the viewport
  list in `site-governance/RELEASE_CHECKLIST.md`; do not weaken a browser check.
- R 4.6.0 and explicit Quarto 1.9.38 are available. The current project's renv library is incomplete:
  a source-quality check stops on missing `jsonlite` before reaching the viewport assertion.
  Resolve the project library before claiming any R check passes. Do not rely on the stale
  CLAUDE.local assertion that all packages are present.
- No DB article passage, candidate record, numerator, period series, card or trend has been inspected.
  Preflight is limited to filesystem, source code, documentation and DB metadata. Existing project
  codebook examples encountered during the mandated reading are not development or evaluation labels.
- No application code, published data, `docs/`, database or tracked aggregate has been changed.
- All required input files and 23 checked reuse/seed files exist. Canonical predecessor SHA-256 is
  `60a207e03afa6e54434e8f4f9feedf9fdfb8b4d40b6218061e0704a106652d99`, matching the brief.
  The executed brief copy has SHA-256
  `e07fc231ef3abfa945cf7009034a64239d7f380f4afbfc4749541e54ed8e4f84`.
- All three databases opened read-only without a lock and were closed. Merged metadata reports
  41,748,837 rows / 49 columns; old 19,781,689 / 46; mediaspace 23,524,289 / 49. Latest merged
  build/import is 2026-09-17 20:17:08; mediaspace logs cover 893 dates through 2026-09-10.
  These are private-input inventory observations, not barometer findings or release denominators.
- Global R libraries do contain the required packages (DuckDB 1.5.4, stringi 1.8.7 / ICU 74.1,
  yaml 2.3.12, ragg 1.5.2 and the other dependencies), verified with `Rscript --vanilla`.
  Restore the project lockfile environment for normal execution; ragg is not yet in that lockfile.
  None of the four new environment variables is configured. All three required font families
  currently resolve to Arial; typography verification must fail until this is repaired.
- Initial preflight reviewers: pipeline/input review, site/governance review and statistical-contract
  audit. These are planning reviews, not substitutes for the independent L1 acceptance verdicts.

## PI decision record

Decisions received on 2026-09-18 are recorded below. D9 is deliberately decided from evidence at G3;
D19 may remain outstanding until G4. D17 is resolved by excluding the coauthored manuscript and its
dictionaries, as recorded below. The remaining default design recommendations were accepted through the explicit instruction to run this plan.

| ID | Proposed decision | Alternative and reason for proposing this choice | Confirmation |
|---|---|---|---|
| D1 | Ratify the separate fixed-panel population and editorial exception. Keep “Medijski barometar demokršćanstva”, its clarifying subtitle and mandatory opening sentence. | Non-publication / longer title. The short title is usable only with explicit construct and population wording. | Accepted through plan execution approval, 2026-09-18 |
| D2 | Include qualifying confessional and political portals, tagged separately; publish the sensitivity series. Exclude institutional non-news sources. | Exclude either segment. Inclusion preserves the declared media population and makes composition inspectable. | Accepted 2026-09-18: “D2, do as recommended.” |
| D3 | Broad scope is the deduplicated union of accepted A1, B, C; narrow is accepted A1. A2 and A? enter neither. | Party-label coverage is not coverage of an idea. | Accepted through plan execution approval, 2026-09-18 |
| D4 | D is a speaker facet and diagnostic only, adding no articles. | Experimental inclusion risks a governing-party coverage measure and needs its own validation. | Accepted through plan execution approval, 2026-09-18 |
| D5 | Family/life identity terms may supply one C family; migration/Islam/enemy terms never do. | Excluding every identity family omits the proposed cultural-identity component. Publish the register facet subject to D17. | Accepted through plan execution approval, 2026-09-18 |
| D6 | Six Compendium policy domains plus Nerazvrstano; principles remain a separate facet. Verify Croatian names and migration placement. | Principle rows would repeat the inclusion rule. | Accepted 2026-09-18: “And D6, do as recommended.” |
| D7 | Full validation design, approximately 430 PI decisions; independent human double-coding of 25%, at least 80. | Reduced design has wider uncertainty. Need PI choice and second coder's name. | Full design accepted through plan approval; independent second human coder not yet assigned |
| D8 | Disregard the D8-specific AI passage-access procedure. Do not require the capped reader, 400-window quota, masking/access log, or a separate D8 consent step. | The PI explicitly withdrew this part of the brief. The independent development/evaluation split, human validation and public disclosure restrictions remain. The classifier's 80-token evidence window is a different rule and remains unchanged. | Overridden 2026-09-18: “I don't want to do anything with respect to passage access for AI D8. Just disregard that.” |
| D9 | Default cross-seam comparisons to `not_comparable_seam`; PI may ratify `comparable_bridged` only after the final June 2024 bridge passes both-scope criteria. | Preliminary overlap figures do not establish final-instrument comparability. | Evidence and G3 required |
| D10 | At least 200 body characters after title stripping. | Other eligibility thresholds change the population. | Accepted through plan execution approval, 2026-09-18 |
| D11 | Full method on Metodologija, short expandable page inventory and downloadable definitions. | All details on the public landing page would conflict with the field-first register. | Accepted through plan execution approval, 2026-09-18 |
| D12 | Descriptive barometer. | Preregistered confirmatory Study 3 requires a different scientific commitment before freeze. | Accepted through plan execution approval, 2026-09-18 |
| D13 | Actor registry contains organisations only. | Named persons are unnecessary for v1 and imply additional identity review. | Accepted through plan execution approval, 2026-09-18 |
| D14 | Ratify “članak” and “medij u panelu” for this distinct population. | “Objava”/“izvor” remain site terms elsewhere. | Accepted through plan execution approval, 2026-09-18 |
| D15 | **Izazovi i budućnost demokršćanstva u Hrvatskoj i Europi / The Challenges and Future of Christian Democracy in Croatia and Europe**, Hrvatsko katoličko sveučilište / Catholic University of Croatia, **24 September 2026**. Prepare the planned 1–2-page summary for that date. Presentation language and talk/poster format are not yet stated. | Corrected conference details supplied by the PI. This replaces the previously supplied event and its English-summary assumption. | Corrected by the PI on 2026-09-18; title, institution and date confirmed |
| D16 | Use the existing database snapshot for v1 without importing the April 2024 re-download. Bind the G1 panel to the measured digest; upstream remains read-only. | A new import is unnecessary under the PI's choice. Detect later external mutation instead of silently changing the frozen snapshot. | Accepted 2026-09-18: “You don't need to import April 2024.” |
| D17 | Keep the excluded collaborator out of participation/co-authorship. Exclude the coauthored manuscript, its dictionaries and related-study card. Use the brief and existing CST document titles as independent seeds. | This applies the exclusion without erasing provenance or inferring permission to reuse copied material. No such material was copied. | Resolved under delegated recommended-decision authority, 2026-09-18 |
| D18 | Publish no per-outlet numerators or rates; public outlet file contains membership and N only. | Named-media league tables are outside scope; publish anonymous concentration diagnostics. | Accepted through plan execution approval, 2026-09-18 |
| D19 | Confirm vendor terms permit the derived aggregates under CC BY 4.0; document restricted inputs separately. | Cannot infer redistribution permission from local access. | PI/vendor confirmation pending; G4 blocker |
| D20 | Public label “Medijska zastupljenost”; retain `visibility_per_10000` internally. | “Vidljivost” already refers to reach elsewhere in DigiKat. | Accepted 2026-09-18: “D20, do as recommended.” |

On 2026-09-18 the PI instructed “Okay now run the plan.” Initial plan approval is complete. The collaborator/dictionary exclusion is resolved by the independent-source choice above. D8 is settled and must
not be raised again. D7 human validation and D19 licensing remain at their existing gates.

## Implementation sequence

### 0. Establish a working baseline after initial approval

Restore the locked project R environment without changing frozen studies. Verify the actual R,
DuckDB, ICU/stringi, yaml, jsonlite, graphics and Quarto versions; explicitly use Quarto >=1.8.
Install/lock the graphics dependency as permitted by §1.4 and verify the required font faces.
Fix the two viewport-contract files as separate Commit 0, run the source-quality check, and report
its actual result. Do not treat a repaired early CI step as proof later CI stages pass.

### 1. Libraries, safeguards and panel proposal, ending at G1

- Add the four environment-resolved path helpers in `R/lib/digikat_paths.R`, a placeholder
  `config/paths.example.Renviron`, the root `.Renviron` ignore, and setup documentation. Amend
  user-level environment configuration without replacing unrelated entries; local paths remain private.
- Create README, PIPELINE, INDICATORS and CHARTER, `run.R` and numbered script scaffolding.
  Keep all row-level/heavy output outside the repository; protect private and intermediate outputs.
  Record explicit pending/frozen gate states so `run.R` cannot bypass a missing ratification.
- Build pure `barometar_text.R`, `barometar_rules.R`, `barometar_url_rules.R` with stringi semantics,
  fixture tests and a synthetic-only end-to-end route. No DuckDB import in the shared libraries.
  Reuse canonical URL and Croatian-count helpers; extend nouns without changing existing meanings.
- Implement readiness and read-only connection handling, schema and loader-activity checks,
  per-day fingerprints, text-availability mask, and deterministic article eligibility/deduplication.
  Never use snippets, inferred publication dates or unfiltered DB totals as panel counts.
- Build the outlet inventory, registry proposal and continuity calculations from N only. Apply
  URL eligibility and title-stripped body length before the >=20-per-complete-month panel rule.
  Freeze none of the candidate outlet labels automatically. Do not inspect topic counts per outlet.
- Present the proposed registry, panel membership, exceptions/host overrides, snapshot identity,
  mask, dedup audit and decision notes. **G1: PI ratifies registry and panel_v1 after D16.**

### 2. Definition development, ending at G2

After G1 and clarification of D17, extract permitted copied seed assignments with source hashes
and PROVENANCE rows; never source or edit frozen dictionaries live. If the PI excludes the
co-authored source, record that explicit exception to the brief and develop from the remaining
approved sources and independently specified forms. Prepare all 12 v1 YAML files plus the public Croatian README. Quote
scalars, validate entry schema and provenance, enumerate surface forms and exclusions, and hash
the full definition including text cap.

Implement the normalization, title/body separation, 32,000-character cap, segmenter, identical
SQL/ICU boilerplate keys, <=80-token sentence windows, explicit argument/attribution tests,
A1/A2/A? precedence, B/C rules, D diagnostic and all required facets. Preserve excluded-hit reasons.
Candidates are a RE2 literal superset; inclusion is ICU only. Test transformation variants and
the seeded empirical rejected-candidate samples. Apply the amended D8 decision above; restricted
source text remains private and is never copied into the public resource.

Develop only in the stable 30% hash split, without period series. Record approximately 150 purposive
development cases and every rule change in DEVLOG as methodological development history, without
the withdrawn D8 reader/access-log procedure. AI diagnostics are labelled as assistant coding,
not PI coding, and are never reported human precision. Validate segmentation against udpipe in each batch.

Present the dictionary inventory, provenance, ambiguous-form decisions, fixture outcomes,
boilerplate-mask correctness checks and development history. These mask checks concern classifier
accuracy, not the withdrawn D8 access procedure. **G2: PI freezes definition v1 before series are computed.**

### 3. Frozen classification, human evaluation and bridge, ending at G3

Run the final classifier in fixed order with chunk/resume caches. Draw fresh seeded evaluation
samples from the unused 70%; development cases never enter evaluation. Generate blinded offline coding
sheets with correct item-id joins, hidden rules/route flags and independent second-coder assignment.
The PI and second human supply labels; compute and log adjudication, agreement, kappa, route Wilson
intervals, route-set-weighted broad precision and theme precision. Do not synthesize missing labels.

Run both June 2024 instruments read-only with identical frozen panel and definition. Report N/D/M,
shared/unique contributions, the seeded 2,000-replicate outlet bootstrap for the visibility ratio,
and breadth differences. Prepare the proposed route gates and D9 decision from actual evidence.
**G3: PI accepts validation outcome and break policy.**

### 4. Checked release preview, ending at G4

Aggregate from private outlet-by-day facts into exact calendar months, ISO weeks and trailing-28-day
windows, recomputing distinct outlet sets for each. Implement indicator-specific statuses and
comparison precedence, low-count/noise handling, all sensitivity series and anonymous concentration.
Reconcile route unions and overlap composition; test ISO edges, true zero, missing days, seam breaks,
and refresh invalidation. Latest cards are derived, never pinned to the brief's planning examples.

Generate all §7.3 CSV/JSON/README files in preview, including versioned definitions, validation and
bridge tables, releases/revisions, and a frozen edition summary. Build the <=200 kB columnar payload.
Write deterministic UTF-8/LF with CSV BOM, hash final bytes, and verify repeat runs and fresh checkout.
Extend the disclosure scan to `data/barometar/` and enforce schema allow-lists plus the public-string
8-token overlap guard. No row text, headline, article URL, personal metadata or per-outlet D leaks.

Present the exact release candidate, check report and rights/provenance record under the resolved
D17 source choice. **G4: first production `run.R --apply` requires PI confirmation and satisfied
applicable reuse rights and D19.** Do not turn this into a request to contact the excluded collaborator.

### 5. Page, figures, PDF and site integration, ending at G5

Build `pages/demokrscanstvo/index.qmd`, `_metadata.yml`, scoped CSS, pure UMD core and DOM JS.
The page reads only checked public releases; hash or cutoff mismatch fails the render. A sample
override visibly says SINTETIČKI PODACI and is refused by production gates. Use `freeze: false`,
embedded JSON, relative paths, static default content, vanilla JS and inline SVG.

Follow the eight-section sequence and the exact DigiKat tokens in §8. Include accessible data tables,
native keyboard controls, URL state, 12-column matrix, fixed bins, separate principles table,
status-aware marks, seam gaps, no motion, print treatment, freshness, Dataset metadata and citation.
Bind findings to an edition; propose only claims backed by summary fields and sensitivity results.
The PI approves findings wording. Honour validation-driven narrow/default and no-publication fallbacks.

Produce matched PNG/SVG figures, 1200x630 social card, and the one/two-page Typst conference PDF from
the same release. Build the PDF outside the repo and fingerprint `docs/` before/after. Inspect every
PDF page and the rendered website. Page and PDF include the required disclosed AI-use sentence.

Integrate the page under Istraživanja, the homepage publication list and studies-index Pokazatelji.
Add the method section and continuity anchor, population/vocabulary exception, lineage and
reproducibility documentation, resource-copy rule, data-availability rows and refresh commands.
Apply the resolved “Keep Andrea out” instruction consistently to new credits and related-study
cards as well as dictionary provenance. Omit a joint-work card if necessary; never relabel an
existing joint work as solely authored. Existing published studies remain outside this edit scope.
Keep frozen study pages intact. Add the exact barometer browser assertions and a JS test CI step.
Single-page renders are allowed for iteration. **G5: obtain confirmation before full-site render.**

### 6. Full verification, PR and editorial handoff, ending at G6

After G5, render from repo root with the verified Quarto/R toolchain. Restore only generated frozen
outputs as prescribed: `git checkout -- docs/pages/studije docs/studies docs/site_libs`; confirm nine
study pages survive. Check unchanged protected aggregates and no render scatter. Check every local
href/src exists and is tracked, including content-hashed CSS, using `core.quotepath=false`.

Run the release checklist, link check, `npm run check:site`, `npm run check:browser`, pure R/JS tests,
synthetic run, disclosure and data reconciliation. Capture all four scope/frequency modes at
1440x900 and 390x844 under `quality_reports/`. Browser gates cover 320–2048, keyboard operation,
axe, reduced motion, URL/live-region state, 12 matrix periods, missing cells and seam separation.

Obtain fresh-context verifier, numeric-claim-verifier, R reviewer, Croatian NLP reviewer and domain
reviewer verdicts. The numerical reviewer independently checks all website/PDF claims. Resolve
failures before calling L1 ready. Stage explicit paths, push the feature branch and open the PR.
Read CI conclusion with `gh run view`; never infer it from `gh run watch --exit-status` or Pages.
**G6: merge/main push only after PI confirmation.** Open the deployed page and all downloads and
check HTTP 200 before calling L3 live. Editorial/manual accessibility acceptance remains with PI.

## Delivery sizing and no-go rules

The corrected conference takes place on **2026-09-24**, six days after the planning date.
Proposed conference scope is the brief's staged release: Release 1 contains validated A1 and B if it passes, C is
withheld/unvalidated, and D stays diagnostic; Release 2 follows fresh C validation. This staged scope is accepted through the plan execution instruction; confirm the available validated routes at G3. If full validation is feasible in time it may
still support the complete release. Never reduce or replace human coding implicitly to meet the
conference date. A method-only conference summary is the fallback if validation is incomplete.

If broad precision/agreement fails, default to passing A1 and label/withhold broad as specified.
If A1 fails, no navigation entry or empirical public barometer; provide method and validation only.
If essential data are inaccessible, implement the authorized synthetic repository-side fallback,
identify the missing file and publish nothing. Missing approved predecessor dictionaries must be
reported, not reinvented; a PI decision to exclude a source is a deliberate scope amendment.

## Resolutions and evidence requirements within the existing gates

The following recommended technical resolutions are accepted under the latest execution authority.
Missing human labels or documentary evidence remain missing inputs, not requests to approve the plan again.

- **G1, monthly active-outlet invariant:** monthly P_t uses N_o>=5, whereas M uses D_o>=1.
  P_t>=M is not mathematically guaranteed. Proposed correction: keep both definitions and check
  P>=P_t and P>=M for months; also check P_t>=M for weeks/rolling28. This recommendation is accepted;
  do not silently discard matching outlets to satisfy the impossible blanket assertion in §10.
- **Duplicate keys:** collapse exact duplicate source identities before asserting candidate doc_key
  uniqueness; retain a multiplicity audit and distinguish this from canonical-article deduplication.
  January's raw distinct-(URL,DATETIME) planning count is not an eligible canonical-article target.
- **G2 status truth table:** inactive-panel coverage below 0.90 forces unavailable/null breadth.
  Specify all other partial/unavailable branches, zero denominators and opening/running-period
  precedence before freezing; the explicitly partial ISO 2020-W53 must not become a fabricated zero.
- **Weekly intervals:** trailing28 headline numbers use their own trailing28 counts. Any change
  compares the distinct raw weeks and explicitly names that interval. Do not use the conditional
  binomial test on overlapping 28-day windows. Freeze monthly breadth-comparison handling separately
  from the visibility significance test before G2; weekly breadth has no change badge.
- **Evaluation design:** freeze overlap handling and inclusion probabilities at G2 so route-set
  weighting is estimable without duplicate coding records. The reduced design still double-codes
  at least 80 unique items. Bridge resampling is paired by outlet; undefined ratios cannot pass D9.
- **Cache dependencies:** changed days can change an outlet-month's boilerplate or move the earliest
  usable canonical article capture. Invalidate all affected classifications and old/new dates,
  then every dependent period, rather than only the originally changed date.
- **Readiness cost:** separate cheap schema/log/lock checks from the deliberate input-fingerprint
  text-hash scan. Classify eligible representatives, not arbitrary duplicate captures.
- **Existing helper boundaries:** the approved URL canonicalizer internally uses base-R regex;
  lint the new barometer files without rejecting that explicitly required shared helper.
- **Disclosure coverage:** adding a directory to the current scanner does not inspect JSON values.
  Cover JSON recursively in the builder/scanner as well as CSV schemas. The repository's
  `/disclosure-check` also references `scholar-skill:scholar-safety`, absent from this session's
  catalog. Do not claim it ran; locate it or document an equivalent local pattern scan and independent
  disclosure review before L1. No raw restricted data is sent to an external service for that review.
- **Downloads:** §8.2 mandates static relative links and forbids JS-created downloads, while §8.5
  requests Blob CSVs. Proposed resolution is checked static selection CSVs for all four modes,
  with JS only activating existing links. Full-precision exports remain the canonical downloads.
- **Method link:** the seam anchor is on Metodologija, so use
  `../metodologija.html#method-barometar-kontinuitet`, not a missing same-page fragment.
- **Current brief prevails:** explicit publication dates replace obsolete `date: last-modified`
  advice; Source fonts and dot-grouped Croatian counts replace old report typography guidance.
- **Editorial issue outside scope:** the brief flags the stale 3,73 % CST figure in Godišnji
  pregled 2025. Notify the PI separately; do not revise a frozen report as part of this resource.

## Completion evidence and handoff

Maintain §10 evidence in this plan or linked check reports as work proceeds. No checklist item is
marked passed until actually run. Handoff at L1 includes preview, PR/green CI, card counts/statuses
for both scopes and frequencies, versions/cutoff/P, definition summary, human precision/kappa,
bridge outcome, decision record, every download/PDF, screenshots, exact refresh commands and
reviewer verdicts. Append only verified new project lessons to MEMORY.

| Gate | Reviewable object | State |
|---|---|---|
| Initial | This plan and D-decision record | Approved 2026-09-18: “Okay now run the plan.” |
| G1 | Snapshot, outlet registry and panel_v1 | Approved under delegated authority; 115 outlets, exact snapshot and panel hashes in config/gates.json |
| G2 | Definition v1, fixtures, provenance and development audit | Frozen 1.0.0+33429974d0b8 after 217-case development audit, passing superset/segmentation gates and independent freeze recommendation |
| G3 | Human validation, accepted routes and final bridge/D9 | Not run/accepted |
| G4 | Checked public release candidate and applicable reuse/D19 evidence | Not prepared/applied |
| G5 | Reviewed integration and exact full render operation | Not prepared/approved |
| G6 | Green PR and editorial sign-off for merge/publication | Not prepared/approved |

L1, L2 and L3 have **not** been achieved.

### Execution checkpoint after G2

The 105-entry independent inventory uses only this brief and existing CST
document titles. Under the instruction to execute recommended decisions and
keep the excluded collaborator out, the coauthored manuscript and dictionaries
are not reused, no role/contact is assigned, and its related-study card is
omitted. This resolves the source-choice part of D17 without erasing provenance
from copied material. No such material was copied. D19 still needs actual vendor
terms evidence.

`freeze_definition.R` executed successfully after the final independent delta
review. `DEVLOG.md` and `config/gates.json` bind the exact definition, engine,
boilerplate and prerequisite evidence. Full private classification subsequently
completed in all 69 monthly chunks. The verified blinded package contains 320
unique PI items and 80 second-coder items, with scarce strata censused under the
full frozen design. No human labels, precision, agreement or empirical findings
have been created. The [execution report](../2026-09-18_barometar-execution.md)
records the private handoff, completed checks and remaining G3/D19 inputs.

The source-schema synthetic end-to-end run passes on 3,206 invented records.
PNG/SVG generation and the expanded synthetic page render pass. A two-page
Croatian method-only conference summary is rendered and visually checked;
Croatian is the recommended fallback in the absence of a language preference.
The page is excluded from normal builds. Its generated `docs/` output and
downloads are development artifacts, not a public release.

### Indicator-contract qualifications identified during verification

The opening ISO week 2020-W53 contains only 1–3 January 2021. Its completeness
flag is false. The frozen status precedence additionally suppresses a period
with fewer than half of its calendar days observed, so this three-day fragment
is `unavailable`, not the brief's literal `partial`. Keep this conservative
suppression and missing numerical values. Do not turn the opening fragment into
a zero or a published estimate. Subsequent partial weeks with sufficient
observed days retain `partial`.

Monthly active-panel count P_t requires at least five eligible articles per
outlet; M counts an outlet with at least one included article. Therefore monthly
M can exceed P_t. The valid monthly invariants are P >= P_t and P >= M; weekly
and rolling periods also satisfy P_t >= M. Breadth remains M/P, with its separate
P_t/P availability check. This resolves the brief's contradictory universal
P_t >= M assertion without changing the frozen indicator definitions.
