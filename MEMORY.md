# DigiKat — Project Memory (committed; project-shared)

> Project learnings live HERE, not in the user's global `~/.claude/MEMORY.md`. Machine paths → `CLAUDE.local.md`.
> Format: one-line `[LEARN]` entries. Replace the seeds below with real incidents as they occur.

## Key facts
- `data/merged_comprehensive.rds` is gitignored (≈710k rows / 710.307, 47 vars); NOT reproducible from a clean clone.
- `data/processed/*.rds` IS tracked (14 small aggregates, no PII) and is produced ONLY by `R/03_aggregate.R`
  run against the master — NOT by rendering a page. Pages read them. `data/nlp/` output is gitignored.
- Inclusion rule: a post enters the corpus only with ≥2 DISTINCT religious-term matches (`R/religious_terms.R`,
  which has **95** terms — not 93). `FOUND_KEYWORDS` is the vendor monitoring service's NOISY keyword field
  (top value is the conjunction "i"/and), NOT the ≥2-filter evidence — the religious-match columns are not
  retained in the master; describe it honestly, don't present it as filter provenance.
- `data_source` splits the master into two TIME-SEGREGATED streams: `original_dta` (ongoing monitoring query,
  ~269.6k) covers **2021–2024**; `filtered_religious` (≥2-filter backfill, ~440.7k) covers **2024–2026** (overlap
  only in 2024; Instagram/TikTok appear only from 2024). So year-over-year VOLUME is CONFOUNDED by a
  collection-method change ~2024 — the 2025 "surge" (236k) is largely an artifact, NOT rising media attention.
  Do NOT read cross-year trends as real without conditioning on stream + platform (critical for
  `pages/mapa/događaji.qmd` and the new `pages/mapa/evolucija.qmd` "Evolucija ekosustava" layer).
- Corpus is TOPICAL, not source-based: it mixes confessional/Catholic outlets (hkm.hr is #1 at ~8%) and secular
  mainstream media. Indicative outlet-composition (top-source labeling, ~53% classified): ≈27–28% clearly
  confessional; secular/local-news majority; per-platform confessional share YouTube ~42% / Facebook ~37% /
  web ~26% / forums-Reddit ~0%. Frame any such % as indicative (labeling is contestable — PI owns the labels).
- The Quarto site publishes to `docs/` → GitHub Pages.

## Corrections log (seeds — replace with real incidents)
- [LEARN] On Windows, R may default to CP1250; read `.xlsx`/`.txt` as UTF-8 explicitly and assume R ≥ 4.2
  (native UTF-8) or set the locale — otherwise č/ć/ž/š/đ mangle on a second machine. The retired stemmer
  implementation is preserved only under `archive/legacy-pipeline/`.
- [LEARN] Lowercase with `stri_trans_tolower` BEFORE tokenizing, or "Misa"/"misa" split into different lemmas.
- [LEARN] URL dedup now uses `canonicalize_url()` from `R/lib/digikat_utils.R`: known tracking parameters
  are removed, while query parameters that can identify distinct content are retained.
- [LEARN] Confirm the timestamped backup was written BEFORE the master is overwritten; restore on mid-run error.
- [LEARN] Sentiment lexicons (CroSentilex / CroSentilex Gold / lilaHR) key on lemmas; match on the SAME
  normalization on both sides or join coverage collapses toward 0%.
- [LEARN] Adding a religious root without its case/plural/derivation alternations silently UNDER-matches.
- [LEARN] `pages/mapa/događaji.qmd` has a diacritic (đ) in its filename — don't rename casually; check `docs/` after.
- [LEARN] Run `quarto` from the REPO ROOT, never `cd pages && quarto render x.qmd`. A render with the project
  undetected scatters HTML / root `site_libs/` / `*_files/` beside the sources AND can EMPTY `docs/`; committing
  that wipe + pushing takes the live site down. Recovery: `git checkout -- docs/`, then re-render from root.
  Backstops added 2026-06-25: `.gitignore` makes the scattered output un-stageable, and `git_data_guard.py`
  blocks any `git commit` that would delete ≥3 `docs/**/*.html` pages. Verify post-render anyway (quarto rule §8).
- [LEARN] `freeze: auto` re-executes ALL R chunks on ANY source change (markdown/YAML included), not just code edits.
  So a "prose-only" edit to a data page (`baza`, `pages/mapa/*`) STILL forces full re-execution on render — there is
  no cheap text-only re-render. (2026-06-30: editing mapa-page prose triggered heavy udpipe re-runs.)
- [LEARN] mapa.qmd's `data/processed`-writing side-effect is now EXTRACTED (2026-06-30): the in-render
  `data-preparation` chunk is `#| eval: false` ("Superseded by `R/03_aggregate.R`") and the page only READS the
  tracked aggregates in `load-data`. So rendering `pages/mapa/mapa.qmd` is now SAFE — it does NOT read the master
  or write `data/processed/*.rds`. (Aggregates are (re)built by `Rscript R/03_aggregate.R` from the repo root.)
  NB: the auto-mode guard may still block a `quarto render pages/mapa/mapa.qmd` because of the *old* warning text —
  it is render-safe; verify `md5sum data/processed/*.rds` is unchanged afterward to confirm.
- [LEARN] `pages/mapa/mapa_stats.qmd` now RENDERS CLEAN (2026-06-30, rc=0) — the earlier `object 'doc_id' not found`
  failure is resolved now that `data/nlp/mapa_stats_{sample,tokens}.rds` exist (built by `R/04_nlp.R`). diskurs &
  događaji also render clean from `data/nlp/`.
- [LEARN] All `pages/mapa/*` figures share ONE ggplot theme — `R/theme_digikat.R` (sourced after `library(ggplot2)`,
  `theme_set` as default). It exports: `dk_col` tokens (incl. `pos`/`neg`/`neutral`/`alert`, cream `paper`, white
  `panel`), `dk_palette` (16-hue), `dk_platform_colors` (brand-harmonized per platform), `scale_fill/colour_digikat()`,
  `scale_*_digikat_diverging()` (blue=+ / red=−, keeps the "plave/crvene nijanse" prose valid), and
  `theme_digikat_void()` (cream-bg network/empty-plot variant). Do NOT hard-code figure colors/backgrounds or
  `theme_void()`/`theme_graph()` — route through these so figures match the editorial design (cream paper, white panel).

## moral-economy denominator lesson (2026-08-04)
- [LEARN] A keyword-linkage layer is NOT a validated denominator. `stageA_candidates.rds`'s
  "religion meets economics" layer is only **39,5%** genuine on a fresh random audit (26,8% under a
  strict reading), and the rate ranges **21,7%–63,3%** across the 11 economic domains. Any rate of the
  form `X / linked(domain)` must divide by that domain's coded precision before it is published;
  `20_r4_recompute.R` does this and propagates the interval. The uncorrected "1 in 91" was wrong by a
  factor of ~3.
- [LEARN] Stratified sets do not answer questions they were not drawn for. The 555-item gold set's
  per-domain genuine-link rates (3,1%–53,1%) looked alarming and **did not reproduce** on a random
  draw — its `random_linked` stratum is n = 28. Draw fresh rather than re-slice.
- [LEARN] When an annotation is transcribed item-by-item, join it back to the sheet on the item index
  and **assert the id agrees**. That gate caught two mis-keyed rids in 810 coded items; without it each
  would have attached a coding decision to the wrong post and the wrong domain.
- [LEARN] Croatian homonym found by audit: `supsidijarna zaštita` (subsidiary protection — asylum
  status) matches the doctrinal term `supsidijarnost`. 1 false match in 150 cards. Fixing it in
  `cst_lexicon.R` would change the population and trip the `expect = 1198` gate in `cst_core.R`.
- [LEARN] Paper TABLES are prose with a grid around them, so rule 3 applies to them too:
  `26_rsp_tables.R` generates every table of `PAPER_RSP_v1.md` as a markdown fragment under
  `output/tables/` plus `rsp_derived.csv` (every scalar the prose quotes), and `25_paper_checks.R`
  fails unless each fragment still appears in the manuscript byte-for-byte and each scalar is still
  printed in the text. Hand-editing a number in the paper now breaks the build instead of surviving.
- [LEARN] Two numbers in the first RSP draft did not reproduce and were fixed by that check.
  (a) *opcija za siromašne* is **33** posts corpus-wide (`cst_census_terms.csv`); the widely quoted
  **29** is the count inside the religion-linked economic layer — state which layer. (b) The
  confessional-enclosure pair "70,4% vs 43,3%" exists in no tracked output; the reproducible form is
  55,2% of doctrinal pairs vs 21,7% of linked pairs (67,0% vs 43,0% among label-carrying pairs), all
  derivable from `cst_robustness_{summary,detail}.csv`.
- [LEARN] Report the invocation rate on **post–domain pairs** (1 949 / 132 519 = 1,47%), not posts
  (1 198 / 108 966 = 1,10%), or the corrected headline silently mixes units: 3,73% ("1 in 27") is the
  pair rate divided by the coded 39,5% linkage precision.
- [LEARN] The corpus descriptor in the RSP paper is an EDITORIAL DECISION by the PI (2026-08-04), not a
  drafting slip: the source line reads "the DigiKat corpus of 710 307 Croatian digital media posts" —
  "and Bosnian" was deliberately dropped, and the ≥2-distinct-term inclusion rule is no longer stated
  in the manuscript (it points to the database instead). The string lives in ONE place per generator,
  `SRC()` in `26_rsp_tables.R` and the caption in `24_rsp_figures.R`; changing it means re-running both
  and re-syncing the seven table blocks into the paper, or `25_paper_checks.R` fails byte-for-byte.
  Two open flags for the PI: "Croatian" alone may understate BiH-sourced material, and a methods
  referee will likely ask for the inclusion rule in-text.

## Manuscript prose style (PI, 2026-08-05)
- [LEARN] Papers are written as FLOWING ACADEMIC PROSE. No bold or italic run-in headings inside a
  section (`**The corpus.** …`, `*Mistake one: …*`), no label-then-explanation constructions, and no
  em-dash appositives. Colons are effectively banned in the prose (source notes and the declaration
  labels are the exception). Every term a first-time reader could miss must be explained where it is
  first used, tables and figures included: prefer "posts where religion and economics meet" and
  "economic subject" in the text over `religion-linked economic layer`, `doctrinal population`,
  `domain`, `Tier-1 vocabulary`, which stay as the code's names.
- [LEARN] RSP caps the manuscript at 50 000 characters INCLUDING tables, so clearer table headers and
  source notes are paid for out of the prose budget. `25_paper_checks.R` measures it; after the
  2026-08-05 clarity pass ≈ 759 characters remain, which is roughly what the Croatian abstract needs.
  Any further addition has to be a swap.
- [LEARN] Table fragments are installed into `PAPER_RSP_v1.md` by `27_sync_tables.R`, never by hand;
  the loop is `26_rsp_tables.R` → `27_sync_tables.R` → `25_paper_checks.R`. `28_render_paper.R`
  typesets the PDF (Typst, bundled with Quarto, no LaTeX) and a styled HTML into `output/paper/`,
  building in a temp directory OUTSIDE the repo so a stray render can never touch `docs/`.

## Two manuscript versions (PI, 2026-08-05)
- [LEARN] `PAPER_RSP_v1.md` (plain-language) and `PAPER_RSP_v2.md` (conventional academic structure —
  Introduction / Theoretical framework / Data and methods / Results / Discussion / Conclusion, with
  numbered subsections, an explicit gap statement and stated expectations) are BOTH live and BOTH
  reconcile against the SAME generated fragments and the same `rsp_derived.csv`. `25_paper_checks.R`,
  `27_sync_tables.R` and `28_render_paper.R` all take `--v2` (sync also takes `--all`); default is v1.
  Both pass 29/29. Do not fork the table generator — the fragments and their plain-language captions
  are shared, which is the deliberate 2026-08-05 accessibility decision, not an oversight in v2.
- [LEARN] The academic apparatus costs ~4 500 characters against RSP's 50 000 cap. v2 was drafted at
  55 007 and reduced to **49 990** purely by tightening prose and deleting one redundant appendix grid
  (the per-table provenance table, which the Reproduction paragraph already states); no table, figure,
  number or reference was cut. That leaves **10 characters** for the Croatian abstract, so v2 is NOT
  submittable as it stands. Closing the ~750-character gap needs a PI decision, and the cheapest
  candidates are Table 4 (vintage, ≈2 300 characters; its five era shares are all quoted in §4.2 prose,
  but dropping it means relaxing the seven-fragment gate in `25_paper_checks.R`), the remaining
  appendix quantities paragraph (≈700), or Boukes 2022 (≈215).
- [LEARN] The character gate counts hard-wrap newlines, roughly 550 of them, which do not exist in a
  submitted `.docx`. The measure is therefore conservative by ~1% and should not be gamed by rewrapping.
- [LEARN] References verified 2026-08-05 and cleared for citation, closing the two holes flagged in
  `LITREVIEW_pilot_rsp.md` Part F: Kallunki, V. & Zrinščak, S. (2021) *Journal of Contemporary
  Religion* 36(1), 123–142 (the Croatian church-and-welfare anchor); Stubbs, P. & Zrinščak, S. (2009)
  *Social Policy & Administration* 43(2), 121–135; Boukes, M. (2022) *IJPP* 27(2), 374–395;
  van Kersbergen & Manow (2009) Cambridge UP confirmed.

## inflation-salience reconstruction and EMIP reframe (2026-08-05)
- [LEARN] **`rid` in the inflation-salience study is the 1-based ROW INDEX of the master**, not a lost
  key. At all 1 450 pooled row numbers both `URL` and `DATE` agree. `PAPER_v1` never said what it was
  and `EMIP_EXECUTION.md` assumed it was unreconstructible and prescribed a `URL` join; six pooled
  items share a URL with another row, so that join would have been ambiguous. `03_finalize_coded.R`
  asserts the identity and stops if the master ever changes under it.
- [LEARN] The measured core is `c_infl == 1 & c_link == 1 & c_foreign == 0`. Dropping the first
  condition gives 532 rather than 520, because 13 items carry a linkage label while the annotators
  judged them not to be about inflation at all. `coded_labels.csv` and `coded_pool_full.csv` agree on
  every label; only the core rule distinguishes them.
- [LEARN] Six posts dated **2022-12-31** were booked to 2023 by the June 2026 run, so `PAPER_v1`
  Table 4 reads 2022 → 201 / 2023 → 100 where the dates say **207 / 94**. Derive the year from the
  date, never from a stored `year` column.
- [LEARN] A lost regex is not always recoverable, and the honest bound is worth measuring. The
  rebuilt inflation lexicon lands 0.27% above the published count and the rebuilt proximity filter
  17.5% above, recovering 94.5% of the coded pool. Fitting against the 39 MONTHLY counts in
  `h1_attention_hicp_series.csv` rather than the single total is what got it that close (r = 0.9973,
  identical denominators in every month). The `window` excerpts prove the original text normalization
  is unrecoverable: most are not substrings of the master text.
- [LEARN] Eurostat **closed `prc_hicp_manr` at 2025-12** on migration to ECOICOP ver.2. Current
  monthly data is `prc_hicp_minr`, dimension `coicop18`, all-items code `TOTAL` not `CP00`. Food is
  **`CP01`**, not the `FOOD` special aggregate, which folds in alcohol and tobacco and diverges by up
  to 3.4 pp — `CP01` reproduces the June pull in all 60 overlapping months, `FOOD` in 3.
- [LEARN] The instrument validates only where there is something to validate against. Media attention
  tracks HICP at r = 0.75 in the 2021–2024 window (inflation sd 4.03) and not at all in 2024–2026
  (sd 0.60, above the 4% threshold in 17 of 24 months). Report both; a flat regressor is uninformative,
  not disconfirming. Attention also tracks the LEVEL of inflation, not month-on-month changes
  (first differences t = 0.43).
- [LEARN] `fread` reads a header of year numbers as data and names the columns V1…V7. Pass
  `header = TRUE` whenever a generated CSV has numeric column names.
- [LEARN] EMIP v2's decisive W1 split is not merely pastoral attention. Of 179 institution-register
  posts, 91 are direct sector voice about the sector's own costs or revenues and 76 are direct sector
  voice about household hardship (counting `both` in each relevant total). Household speech peaks in
  2022-02, own-position speech in 2022-10, and repricing coverage in 2024-06, so the own-position to
  repricing lag is 20 months. The defensible claim is public possession of relevant information before
  late adjustment, not observed individual cognition.
- [LEARN] EMIP v2 unit matching must require speech to precede repricing strictly (`lag_days > 0`) and
  must keep exact unit names private. There are 32 named units, 22 with own-position speech, 14 with
  repricing coverage, and four valid within-unit sequences; their lags are 1 to 1 505 days (median 669),
  with three over one year. Only aggregate counts and unit types leave `output/private/`.
- [LEARN] The event register supports dates, lags, composition and concentration, not fee levels or a
  structural hazard. Repricing coverage peaks at 55 posts in 2024-06, 19 months after the 12.9% HICP
  peak and at a chained price-level gap of 25.7% from 2021-06. Fairness and organisational decision
  cost remain observationally equivalent and must be framed as consistency, not identification.
- [LEARN] The v2 reproducibility route is `RUN_ALL.R --v2 --no-network`: 15 scripts completed in 7.4
  minutes on 2026-08-05. The paper gate is 33/33 (nine byte-identical generated tables, all 152 derived
  scalars present, both abstracts under 150 words, UTF-8 intact). Rendering produces full and blinded
  Word files; replication produces 61 screened files and withholds corpus text and all private labels.

## Both eras under one rule — v4 + second pass (2026-08-10)

- [LEARN] A vocabulary gate cannot filter a population that was itself selected by vocabulary. Applied
  to `original_dta` (the 2021–2024 stream, cut from DetermDB by a keyword query), the v4 word list
  accepts **87,6%** of rows and the second pass at 0,40 removes only 6,7% — against 65,3% / 6,5% on the
  `filtered_religious` half. Result: 269 583 → **218 299** kept, measured **68,0% genuine [54,2–79,2]**
  on 250 hand-read posts, against 87,0% for post-2024 cut by the identical rule. The 19-point gap is a
  property of the two streams, not of either measurement.
- [LEARN] The pre-2024 half is **56,6% genuine before any filtering**, not the ~70% carried in earlier
  notes. The old figure re-sliced a stratified set drawn for another purpose; this one is a fresh random
  draw against the actual output. Same lesson as the moral-economy denominator.
- [LEARN] 0,40 is the wrong SHARED threshold. Adding the two eras' weighted curves
  (`R/joint_threshold.R`), the united corpus peaks at **0,80** (88,0% clean, keeps 84,0%; F1 85,9)
  against 0,40 (77,9% / 90,0%; 83,5), and the era gap narrows 19,0 → 10,2 points. Re-cutting is free —
  the score is stored for every gate-1 passer — but it redefines the corpus, so it is a PI decision.
- [LEARN] Sample-scaled VOLUMES from a 50-post kept stratum are ~7% low (one read post stands for
  4 366). Take volumes from the decisions file and precision from the read sample; never mix them.
- [LEARN] Tuning the gate-2 threshold PER ERA would equalise precision and reintroduce an era-dependent
  inclusion rule — the exact confound the rebuild exists to remove. One threshold both sides, then
  report what it costs each half.
- [LEARN] The window defect is still live and now sized: **11 783** pre-2024 accepts (5,4%) pass gate 1
  only on evidence past the 3 000 characters gate 2 and the coder see; 0 of the 4 that reached the read
  sample are genuine, consistent with 0 of 18 in June. Never measured on the post-2024 half.
- [LEARN] Source labels need normalising before any outlet ranking: 11 955 raw labels → 11 820 after
  lowercasing and stripping `www.`; only `bitno.net` moves materially (13th → 3rd, 8 099 posts).
  The united corpus also carries 7 736 duplicate canonical URLs, 478 of them across the era break.
- [LEARN] One inclusion rule makes the halves **rule-comparable, not capture-comparable**. The kept
  share still steps ~20 points down at the 2024 break (85,6% in 2023 → 61,6% in 2024); that is the
  instrument change, untouched by any of this, and volume across it still must not be read as attention.

## The official corpus — one rule, both eras (2026-08-10)
- [LEARN] There are now TWO datasets and they are NOT interchangeable. `data/merged_comprehensive.rds`
  is the **accumulator** (710 307 × 47, everything the vendor supplied, still written by
  `R/append_new_data.R`). `data/digikat_corpus.rds` is **THE official corpus** (413 985 × 54), cut from
  it by one inclusion rule applied identically to both collection eras. The SITE describes the corpus;
  the COMPLETED PAPERS stay pinned to the accumulator by name (`studies/moral-economy`,
  `studies/inflation-salience`, `studies/catholic-education`, `Church-and-dezinfo`), because repointing a
  finished analysis silently changes numbers it already published. Resolve both via
  `R/lib/digikat_paths.R`; never type either path.
- [LEARN] The rule is: word list v4 (119 terms, ≥1 decisive and ≥2 total) **within the first 3 000
  characters**, then the second-pass ensemble at **0,70** (PI decision 2026-08-10; 0,80 was the joint
  curve's recommendation, 0,70 chosen as volume-leaning: ≈84,5% genuine at 87,2% recall, era gap 13,6
  points). Re-cutting at another threshold is free — the score is stored for every gate-1 passer — but it
  redefines the corpus, so it is a PI decision, not a default that drifts.
- [LEARN] The window fix is now LIVE on both halves. Gate 1 previously read the whole text while gate 2
  and the coder read only the first 3 000 characters; all 22 such posts read by hand were not Catholic
  content. It costs 38 438 rows at gate 1, of which **16 895** (7 456 pre-2024 + 9 439 post-2024) would
  otherwise have been kept at 0,70. The window-only rate is **5,4% in BOTH eras** — the defect was never
  era-specific, only never measured on the post-2024 half. `R/backfill_window_flag.R` supplied the missing
  flag; `post2024_decisions_v4.rds.bak` is the pre-backfill file.
- [LEARN] The corpus manifest (`data/digikat_corpus_manifest.json`, TRACKED, no PII) is the ONLY place a
  page should read corpus figures from: it carries rows, columns, span, platform counts, term counts,
  threshold and the sha256 of the corpus itself, so a page renders on a machine with no data and cannot
  drift from the file it describes. `index.qmd`, `baza.qmd` and `pages/mapa/*` now compute every corpus
  number from it — none is typed.
- [LEARN] `digikat_assert_aggregates_current()` fails CLOSED and will STOP a render while
  `data/processed/` was built from a different dataset than the corpus manifest names. That is deliberate:
  the failure mode it prevents is a page printing the current corpus size above charts summing to the old
  one. Clearing it means regenerating in order — `R/03_aggregate.R` (preview, then `--apply`),
  `R/04_nlp.R --build`, `R/05_page_summaries.R --build` — and only then rendering.
- [LEARN] Inline `` `r ` `` DOES evaluate inside a ```` ```{=html} ```` raw block (verified 2026-08-10).
  So a hand-styled HTML band can be driven from data without being rebuilt as a `cat()`-ing chunk.
- [LEARN] In `dplyr::summarise`, a later expression sees the columns created EARLIER in the same call:
  `summarise(kept = sum(kept), kept_pct = 100 * mean(kept))` silently computes the mean of the new
  `kept` total, not of the logical flag. Name the intermediate differently and rename after.

## Housekeeping resolution (2026-07-28)
- [LEARN] Legacy NLP/stemmer scripts with phantom or hard-coded paths are archived under
  `archive/legacy-pipeline/`; active code uses `resources/` and `R/lib/`.
- [LEARN] `R/03_aggregate.R` is the only producer of the complete 14-file aggregate generation. Default
  mode is a temporary preview; `--apply` is the production gate. Quarto pages are read-only consumers.
- [LEARN] The 16-category dictionary has one canonical definition:
  `R/lib/thematic_dictionaries.R`.
- [LEARN] Only `resources/models/croatian-set-ud-2.5-191206.udpipe` is canonical; setup checks its SHA-256.
- [LEARN] Study rows with URLs, titles, source identities, or text excerpts belong in ignored
  `output/private/`, enforced by `R/check_disclosure.R` and CI.
- [LEARN] Historical workflow proposals moved to `archive/roadmaps/`; they are not operational guidance.
