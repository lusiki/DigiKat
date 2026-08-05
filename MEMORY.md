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
