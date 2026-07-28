# DigiKat full-housekeeping implementation report

> **Historical snapshot.** This report records the first housekeeping implementation pass. The later
> page-performance, master-year repair, downstream-equivalence, and final visual-QA work is documented in
> [`2026-07-28_page-speed-year-repair-qa-report.md`](2026-07-28_page-speed-year-repair-qa-report.md), which is
> the authoritative description of the current project state.

**Audit and implementation date:** 2026-07-28<br>
**Workspace:** `DigiKat`<br>
**Mode:** protected-production hard gates, applied only after explicit confirmation<br>
**Overall status:** complete. The active project has been reorganized, hardened, documented, validated, and
deployed into the tracked aggregate and site output directories. The former aggregate generation is retained as
a private timestamped backup.

## 1. Executive outcome

The project was not merely reformatted. The housekeeping pass corrected structural risks in the data pipeline,
consolidated duplicated analytical definitions, separated public and private research artifacts, pinned the
runtime and language resources, added end-to-end validation, removed active dependencies on legacy scripts, and
proved the complete site in an isolated build.

The most consequential findings were:

1. the old ingestion and merge paths did not provide one consistent staged/validated write contract;
2. URL deduplication could retain tracking-parameter variants or, if "fixed" by stripping every query string,
   could incorrectly merge genuinely different content;
3. 987 master rows have a stored `year` that differs from the year derived from `DATE`;
4. seven of the 14 currently published aggregate files differ from the newly validated full-master generation;
5. multiple study outputs with row-level URLs, titles, source identities, or text were trackable;
6. thematic dictionaries, resource paths, counts, date ranges, and operational instructions had drifted across
   scripts, pages, project memory, rules, and agent guidance;
7. the public-data page overstated access to the current 710,307-row master and conflated it with a historical
   612,065-row Kaggle snapshot;
8. the dependency environment was not fully reconciled, and third-party resource provenance was incomplete;
9. the site had stale production-output coupling, malformed schedule containers, and embedded-resource warnings;
10. Git is stored inside Dropbox. All seven pack/index pairs validate, but Dropbox reparse-point refs prevent a
    complete `git fsck` with `fatal: mmap failed: Invalid argument`.

No protected master, master backup, NLP generation, or semantic database was overwritten. After explicit
authorization, `data/processed` was replaced atomically and `docs/` was fully rendered; both operations passed
their independent post-write validation gates.

## 2. Inventory at completion

### 2.1 Repository and source inventory

| Area | Inventory |
|---|---:|
| Git-indexed paths before staging these changes | 702 |
| active R scripts/chunks checked | 49 R files |
| Quarto sources checked | 134 (`index.qmd` plus 133 under `pages/`) |
| publishable HTML pages in the isolated build | 133 |
| archived files | 28 |
| site source files under `pages/` | 135 |
| language-resource files | 15 inventoried third-party/project resources plus two inventory documents |
| automated regression assertions | 30 |
| complete public aggregate outputs | 14 RDS files |

`pages/izvori/_mreza_graf.qmd` is an underscore-prefixed partial and is intentionally not a standalone HTML page.
That explains the 134 parsed QMD sources versus 133 rendered pages.

### 2.2 Storage inventory

| Area | Files | Bytes | Interpretation |
|---|---:|---:|---|
| `data/` | 172 | 20,436,418,574 | protected master, backups, semantic/NLP products, raw drops, samples, aggregates |
| `data/semantic/` | 7 | 14,833,282,360 | local vector store and prepared semantic input |
| `data/new/` | 136 | 1,756,447,446 | ignored legacy/drop-folder material; includes an older master copy |
| `data/nlp/` | 8 | 453,145,523 | ignored samples/tokens plus validation manifest |
| `data/processed/` | 14 | 595,507 | tracked/public aggregate RDS files |
| `data/sample/` | 3 | 165,739 | fully synthetic fixture and manifest |
| `studies/` | 177 | 558,202,879 | scripts, documents, private working outputs, public tables/figures |
| `resources/` | 17 | 23,095,152 | model, lexicons, dictionaries, provenance |
| `R/` | 38 | 64,605,556 | active scripts plus ignored local semantic products |
| `pages/` | 135 | 582,773 | active site sources |
| `archive/` | 28 | 356,312 | retired code, prototype, draft, and roadmaps |
| `quality_reports/` at measurement | 42 | 1,116,782 | plans, reports, local recovery records |

The 20 GB data tree and 558 MB study tree were inspected by role and disclosure risk, not treated as disposable
cache. Large/raw/private assets were retained unless they were exact duplicates or clearly generated debris.

### 2.3 Protected production state

| Asset | Bytes | Last modified | Result |
|---|---:|---|---|
| `data/merged_comprehensive.rds` | 1,187,912,348 | 2026-06-29 08:21:38 +02:00 | unchanged |
| `data/merged_comprehensive_backup_patch_20260629_061650.rds` | 1,187,912,356 | 2026-06-29 08:16:50 +02:00 | unchanged |
| `data/merged_comprehensive_backup_20260629_060704.rds` | 1,016,957,048 | 2026-06-29 08:07:04 +02:00 | unchanged |
| `data/processed/` | 598,956 total / 15 files | newest 2026-07-28 10:54:52 +02:00 | atomically regenerated and manifested |
| tracked `docs/` | 210 files / 37,409,646 bytes | newest 2026-07-28 11:11:37 +02:00 | fully rendered and link-checked |

Current master SHA-256:

```text
789fdc6ff710b5f5289ec81444876c1af56ffc8d2d30f220335ec7b853c9e59f
```

That hash matches the adopted NLP manifest and the semantic-store validation input.

## 3. Corrections implemented

### 3.1 One safe, numbered pipeline

The active path is now:

```text
R/00_setup.R
  -> R/01_filter.R
  -> R/02_merge.R
  -> R/03_aggregate.R
  -> R/04_nlp.R
  -> R/semantic/10_prep.R
  -> R/semantic/11_build.R
```

`R/00_run_all.R --sample` is the non-destructive orchestration/smoke-test entry point.

Shared infrastructure was extracted into:

- `R/lib/digikat_utils.R`: CLI parsing, booleans, URL canonicalization, YouTube normalization, strict dates/years,
  hashing, JSON, staging, and atomic replacement;
- `R/lib/religious_filter.R`: validated, vectorized matching of the canonical 95-term definition from
  `R/religious_terms.R`;
- `R/lib/thematic_dictionaries.R`: the single 16-category thematic definition used by all thematic pages.

The pipeline defaults are fail-closed:

- ingestion and aggregation preview rather than overwrite;
- `--apply` is required for protected production writes;
- staged results are read back and validated before replacement;
- manifests record input bytes, modification time, hashes, parameters, and output shapes;
- schema drift, missing columns, invalid dates, duplicate IDs, row-total mismatches, and incomplete generations
  stop the run;
- Quarto pages are read-only consumers, not data producers.

### 3.2 Filtering and deduplication

The inclusion contract remains unchanged: at least two **distinct** matches from the 95-term religious list.

Deduplication now uses a platform-aware canonical URL:

- scheme/host/case/trailing-slash normalization where safe;
- recognized tracking parameters are removed;
- query parameters that may identify different content are retained;
- YouTube URL variants normalize to the same video identity;
- blank/invalid URLs do not collapse unrelated rows into one record.

This resolves the tracking-variant gap without the data-loss risk of removing every query string.

### 3.3 Master-year integrity

The full 710,307-row preview found 987 records whose stored `year` conflicts with `DATE`. The new aggregate
producer treats the parsed date as authoritative and records the mismatch count. It includes all 710,307 rows
from 2021-01-01 through 2026-06-11.

The master itself was not patched: changing it would require a separate, explicit, backed-up production operation.
The correction is applied deterministically at the aggregate boundary.

### 3.4 Complete aggregate generation

`R/03_aggregate.R` is now the sole producer of:

1. `platform_summary.rds`
2. `proportions_summary.rds`
3. `platform_monthly.rds`
4. `source_summary.rds`
5. `top_sources_by_year.rds`
6. `top_web_sources.rds`
7. `top_youtube_sources.rds`
8. `top_facebook_sources.rds`
9. `web_actors.rds`
10. `youtube_actors.rds`
11. `facebook_actors.rds`
12. `instagram_actors.rds`
13. `tiktok_actors.rds`
14. `twitter_actors.rds`

It validates exact generation membership, RDS round trips, aggregate schemas, unique actor names, annual
proportions, and row-total reconciliation. A JSON manifest accompanies a candidate/applied generation.

`R/compare_aggregates.R` was added as a read-only comparison tool. The full candidate comparison found:

| File | Current vs validated candidate |
|---|---|
| `facebook_actors.rds` | identical |
| `instagram_actors.rds` | value difference; 19 -> 21 rows |
| `platform_monthly.rds` | identical |
| `platform_summary.rds` | value difference; same 49 × 5 shape |
| `proportions_summary.rds` | value difference; same 49 × 8 shape |
| `source_summary.rds` | value difference; 29,728 -> 29,707 rows |
| `tiktok_actors.rds` | value difference; 19 -> 18 rows |
| `top_facebook_sources.rds` | identical |
| `top_sources_by_year.rds` | value difference; same 90 × 6 shape |
| `top_web_sources.rds` | identical |
| `top_youtube_sources.rds` | identical |
| `twitter_actors.rds` | value difference; 19 -> 23 rows |
| `web_actors.rds` | identical |
| `youtube_actors.rds` | identical |

The annual differences are consistent with using `DATE` rather than the 987 conflicting stored-year values.
The social actor files also show that the current tracked directory is a partial/stale generation rather than
one atomically produced set. This is a real production correction, not an attribute or row-order difference.

### 3.5 NLP artifacts

`R/04_nlp.R` now supports explicit validation, adoption, build, and rebuild modes. It refuses silent fallback,
checks sample membership and document/token alignment, hashes every artifact, and stages replacements.

The current ignored NLP products were adopted only after full validation:

| Page product | Sample documents | Token rows |
|---|---:|---:|
| `mapa_stats` | 35,225 | 23,842,036 |
| `dogadjaji` | 21,126 | 14,368,700 |
| `diskurs` | 14,080 | 9,476,415 |

The manifest pins the master hash, model hash, seed, date bounds, excluded platforms, minimum text length,
strata, proportions, row counts, date ranges, and per-file hashes.

### 3.6 Synthetic fixture

`R/make_sample.R` now generates 2,700 entirely synthetic rows:

- exact 47-column master schema;
- 50 rows for each of 9 source types × 6 years;
- deterministic output;
- synthetic actors, titles, text, IDs, and `example.invalid` URLs;
- no protected row, URL, actor name, title, or post text.

Fixture SHA-256:

```text
4c27aa2e422a4a371b80ceea64a745699830c2227a1f4af00214c77e0f98914c
```

### 3.7 Semantic store

The semantic scripts now require explicit sample/full intent, preserve the production store's append-only
sequential document-ID contract, write manifests,
checkpoint long builds, validate schema and ID alignment, and stage a build separately from the live store.

The existing local store was adopted read-only after validation:

- 710,307 rows;
- `FLOAT[1024]` embeddings;
- 367,538,682 indexed terms;
- 13.6+ GB database;
- input aligned to the current master.

No embeddings or database rows were rebuilt or overwritten.

### 3.8 Study disclosure controls

Seventeen row-level working artifacts were moved from trackable output roots into ignored
`studies/*/output/private/`.

Inflation-salience private files (13):

- `analysis_core.csv`, `analysis_core.rds`
- `analysis_core_coded.csv`, `analysis_core_coded.rds`
- `coded_pool_full.csv`
- `coding_pool.rds`, `coding_pool_index.csv`
- `fp_sample_60.csv`
- `heldout_auto.csv`
- `linkage_coding_sheet.csv`, `linkage_coding_sheet_v2.csv`
- `validation_auto.csv`, `validation_merged.csv`

Moral-economy private files (4):

- `coding_key.csv`
- `coding_sheet.csv`
- `gate1_precision_sheet.csv`
- `poverty_diagnosis_sample.csv`

All affected scripts and documents now reference the private paths. `studies/README.md` defines the policy.
`R/check_disclosure.R` enforces it in CI by scanning trackable study artifacts for row-level identity/text fields.

The final disclosure gate inspected 41 trackable study artifacts and passed.

### 3.9 Site and source catalog

Site corrections include:

- all thematic pages source one shared 16-category dictionary;
- the map page no longer contains a stale aggregate-writing block;
- the source-catalog generator handles all six actor platforms;
- 103 actor pages were generated and 11 actors were held for editorial review;
- catalog schema/log/index documents match the current six-platform scope;
- current corpus/date caveats distinguish partial 2026 coverage and the 2024 collection-method change;
- the data page distinguishes the restricted current 710,307-row master from the historical 612,065-row Kaggle
  snapshot;
- the executive overview no longer reads figures out of production `docs/`;
- the schedule uses balanced native Quarto containers;
- malformed font preconnect resources were removed;
- Croatian number formatters now set both `big.mark = "."` and `decimal.mark = ","`;
- footer dates and project counts were updated to 2026;
- old study snapshots are labeled as historical rather than silently presented as current.

The isolated full render initially exposed two missing map-image resources, six unclosed schedule containers,
three repeated font-root fetch warnings, and locale-format warnings. Each source defect was corrected. The
affected pages were rerendered cleanly, and the final isolated output passed the local target/anchor checker.

### 3.10 Archive and root cleanup

Retired material was preserved by role:

- `archive/legacy-pipeline/`: old load/filter/merge, patch, stemmer, token, and text-analysis implementations;
- `archive/drafts/`: non-site Quarto draft;
- `archive/design-prototype/`: the superseded site prototype;
- `archive/roadmaps/`: historical workflow proposals and critique.

An exact duplicate prototype page (`tim(1).qmd`) was removed. Root debris, a duplicate 19 MB UDPipe model,
the generated `README.html` bundle, and an interrupted `renv` staging directory were removed recoverably.
The canonical model remains under `resources/models/`.

`.renvignore` and `.gitignore` now separate source, protected data, private study work, semantic products,
previews, archives, rendered site output, and environment artifacts. `.gitattributes` establishes LF text
normalization and marks binary research formats explicitly.

### 3.11 Dependencies and runtime

The active dependency set was derived from source rather than guessed. Missing active optionals were installed,
and `renv.lock` was reconciled.

- R 4.6.0;
- Quarto 1.9.38;
- Croatian UTF-8 locale;
- 46 referenced packages;
- 46 installed;
- 0 missing;
- `renv::status()`: no issues.

Lock SHA-256:

```text
a54eca8de9d6ba1b7a1bec28913a7329652cba12285128127719c0d29dc1f8b5
```

### 3.12 Resource provenance and licensing

`resources/PROVENANCE.csv` inventories 15 resources by path, bytes, SHA-256, active/legacy status, origin family,
and license/status:

- 6 active;
- 9 retained legacy/reference.

`resources/README.md` documents that third-party resources do not inherit a general project badge. The active
model/lexicon terms recorded are:

- CroSentiLex: HR-CLARIN record lists MIT;
- LiLaH-derived `lilaHR_clean.xlsx`: CC BY-NC-SA 4.0;
- UDPipe model family: CC BY-NC-SA;
- underlying Croatian SET treebank: CC BY-SA 4.0;
- project-authored source-label sidecar: project-declared CC BY 4.0.

The model is pinned at 19,236,607 bytes and:

```text
b8e0ad212bdc84c57366bd7267d21810e1fd3239c4d22ca5867f94e76c6cedc7
```

Relevant citations were added to `references.bib`. `CITATION.cff`, `CONTRIBUTING.md`, and accurate availability,
replication, environment, and machine-setup documents were added or rewritten.

### 3.13 CI and automated controls

The GitHub Actions workflow now:

1. installs R 4.6, restores `renv`, and installs Quarto;
2. runs all regression checks;
3. parses active R and every site R chunk;
4. checks encoding/mojibake signatures;
5. runs the study disclosure guard;
6. validates setup and the pinned UDPipe model;
7. creates the synthetic fixture;
8. builds all 14 sample aggregates;
9. builds sample NLP products;
10. renders the full site against synthetic/candidate-safe data;
11. checks all local links and anchors.

## 4. Validation evidence

| Validation | Result |
|---|---|
| regression suite | 30/30 passed |
| active source check | 49 R files passed |
| QMD R-chunk extraction/parse | 134/134 passed |
| disclosure guard | 41 trackable artifacts passed |
| setup/model verification | passed |
| synthetic fixture | 2,700 × 47; deterministic hash passed |
| non-destructive sample pipeline | passed |
| sample aggregates | 14/14; 2,700 rows reconciled |
| sample NLP | 3/3 products passed |
| full-master aggregate preview | 14/14; 710,307 rows reconciled |
| installed aggregate reproduction | exact 14/14; zero ordering, attribute, or value differences |
| full existing NLP validation | passed |
| full semantic-store validation | passed |
| `renv::status()` | no issues |
| isolated Quarto render | 133/133 pages created |
| isolated local link/anchor audit | 133 HTML files; zero missing targets/anchors |
| production Quarto render | 133/133 pages; zero render warnings/errors |
| production site audit | zero missing targets, anchors, or mojibake signatures |
| resource byte/hash validation | 15/15 passed |
| Git pack/index validation | 7/7 passed |
| Git loose/pack garbage count | 0 after reverse-index quarantine |

The exact non-destructive pipeline command that passed was:

```powershell
Rscript R/00_run_all.R --sample
```

The exact production-candidate commands are:

```powershell
Rscript R/03_aggregate.R --output-dir=<empty-preview-directory>
Rscript R/compare_aggregates.R --candidate-dir=<preview-directory> --allow-differences
```

## 5. Production completion and remaining decisions

### 5.1 Completed: public aggregate replacement

After explicit confirmation, the complete production command ran successfully:

```powershell
Rscript R/03_aggregate.R --apply
```

The command atomically replaced the complete 14-file set and added `data/processed/manifest.json`. The former
14-file generation is retained at:

```text
data/private/processed-backups/20260728_085452/
```

An independent second full-master build was compared with the installed generation:

```powershell
Rscript R/compare_aggregates.R --candidate-dir=<independent-preview-directory>
```

All 14 outputs were exactly identical, including ordering and attributes. A subsequent full
`Rscript R/00_run_all.R` passed aggregate reconciliation, NLP validation, and semantic-store validation.
The master remained byte-, timestamp-, and SHA-256-identical.

### 5.2 Completed: production `docs/` render

The first production render attempt stopped before page generation because the Dropbox-backed ignored `.quarto`
cache returned a Deno KV `disk I/O error`. `docs/` was confirmed unchanged. The complete 351-file cache was moved
intact to:

```text
quality_reports/recovery/quarto-cache-20260728_105923/
```

The clean-cache retry created all 133 pages with no render warning or error. The final site has:

- 133 HTML pages;
- zero missing local targets;
- zero missing anchors;
- zero detected mojibake signatures;
- a verified `docs/.nojekyll` marker.

`R/ensure_nojekyll.R` is now a Quarto post-render hook, so future renders deterministically restore and verify
the GitHub Pages marker after Quarto cleans the output directory.

### 5.3 Git should be relocated out of Dropbox

The object packs are internally readable:

- 7 pack/index pairs;
- all 7 pass `git verify-pack`;
- Git reports zero garbage after quarantining optional reverse indexes.

Seven optional `.rev` files were preserved at:

```text
quality_reports/recovery/git-rev-quarantine-20260728/
```

Nevertheless, `git fsck --full` still fails while verifying Dropbox-backed refs:

```text
fatal: mmap failed: Invalid argument
```

Refs and several Git-control files are sparse/reparse points, and the repository also contains historical Dropbox
"conflicted copy" index/ref artifacts. A reliable repair should not mutate this dirty working tree in place.
Recommended procedure:

1. create a fresh clone outside Dropbox, for example under `C:\src\DigiKat`;
2. verify the clean clone with `git fsck --full`;
3. transfer this working-tree change set with an explicit file manifest or patch;
4. run the complete validation suite there;
5. keep Dropbox only as a data/document synchronization location, not the live `.git` database.

This requires choosing the destination and coordinating the uncommitted changes, so it was not assumed here.

### 5.4 Access and licensing decisions

- The historical Kaggle dataset narrative says CC BY 4.0, while the Kaggle API metadata reports MIT. Reusers
  should verify the intended license before relying on that snapshot.
- The current protected master is not a public download. Public materials are the aggregate generation and
  synthetic sample; access to full text is controlled/on request.
- No new software-code license was invented during housekeeping. The project declares CC BY 4.0 for its public
  materials, but the team should decide whether code should receive a separate software license.

### 5.5 Retained data that needs owner review

`data/new/` contains 136 ignored files (1.756 GB), including an older 1.017 GB master copy and vendor/drop-folder
material. It is protected from Git and not used by the documented active ingestion path (`data/raw/new/`).
Because the files may be source evidence or a recovery point, they were not deleted or moved. The PI should decide
whether to:

- preserve them as a dated raw-data snapshot;
- move them into a documented private archive; or
- delete confirmed duplicates after independent backup verification.

Likewise, 9 legacy language resources remain checksum-inventoried because their historical provenance or
redistribution status is incomplete. They are inactive, not silently deleted.

## 6. Recommended staging sequence

Do not use `git add -A`. With the two confirmation-gated production operations complete:

1. review `git status --short`;
2. stage explicit infrastructure/document/archive paths;
3. stage the complete 14-file aggregate generation and its manifest together;
4. stage the complete `docs/` render together only after the link audit;
5. confirm that `data/merged_comprehensive.rds`, backups, `data/new/`, `data/nlp/`, `data/semantic/`, and
   `studies/*/output/private/` are absent from the staged set;
6. inspect deleted-versus-archived path pairs;
7. commit in coherent units if desired:
   - pipeline/tests/environment;
   - disclosure/archive/documentation;
   - regenerated public aggregates;
   - regenerated site.

## 7. Final assessment

The active project is materially safer and more reproducible:

- one canonical pipeline;
- one religious matching implementation around one 95-term definition;
- one 16-theme dictionary;
- one complete 14-file aggregate contract;
- deterministic synthetic data;
- validated NLP and semantic manifests;
- enforced study disclosure boundaries;
- pinned dependencies and language-resource hashes;
- isolated, successful 133-page site build;
- automated regression, encoding, disclosure, render, and link controls.

The aggregate and site production operations are complete and validated. Git relocation is the only
infrastructure repair that cannot be safely completed inside the current Dropbox-backed dirty worktree without a
destination decision. The remaining owner decisions concern licensing, the retained `data/new/` drop-folder
snapshot, and inactive legacy resources with incomplete provenance.
