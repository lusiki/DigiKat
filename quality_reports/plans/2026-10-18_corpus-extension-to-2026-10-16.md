# Plan — extend the official corpus to 2026-10-16 and refresh ten site resources

**Status:** DRAFT, awaiting PI decision on the source option (§3). Nothing has been run that writes data.
**Requested by PI 2026-10-18:** update, with data 2021 → 16 Oct 2026, the pages Mapa ekosustava,
Evolucija, Tematske struje, Fokus na događaje, Moj medij, Katalog izvora, Izvršni pregled, Službeni
korpus (baza), the landing page (Katoličke teme u digitalnom prostoru) and Kako se govori o Crkvi?

## 1. Starting state (measured 2026-10-18)

| Layer | Span | Note |
|---|---|---|
| Official corpus `digikat_corpus.rds` (413 985 rows, sha 15473a61) | 2021-01-01 → 2026-06-11 | Dropbox copy; built 2026-08-10 |
| Accumulator (vendor .xlsx exports) | → 2026-06-11 | no new export waiting (`data/raw/new/` absent) |
| DetermDB merged (44 266 199 rows) | 2021-01-01 → **2026-10-16** | update-20261018 committed 09:53 today |
| `data/processed`, `data/nlp`, `data/page-ready`, `moj_medij.json` | → 2026-06-11 | all carry corpus sha 15473a61 |

The ONLY source holding data past 2026-06-11 is DetermDB. No R pipeline reads it into the corpus yet.

Defects found in the current corpus while checking:
- **YouTube stops after January 2026** (0 posts Feb–Jun 2026; ~1 500/month in late 2025). Comments
  likewise. The vendor export stopped delivering them; DetermDB still has them.
- **Feb–May 2024 is empty** in the corpus, but DetermDB merged now has full text for every month of
  2024 (0,0% missing Jan–Jun after the 2026-09-19 Q1 re-import and the MediaSpace feed from 2024-04-01).

## 2. Calibration — does "DetermDB + the official rule" reproduce the corpus? (week 2026-05-04..10)

Script: scratchpad `calib.R` (read-only). Rule = word list v4 in the first 3 000 characters
(≥1 decisive, ≥2 total) + second pass `second_pass_v2.rds` at 0,70, dedup on canonical URL.

- DetermDB holds **93,2%** of that week's corpus URLs (web 97,4%, Facebook 81,4%).
- Applying the rule to DetermDB reproduces **92,2%** of the corpus posts.
- It accepts 4 515 posts against the corpus's 2 154. On the corpus's own platforms:
  web 1 959 vs 1 589 (×1,23), Facebook 565 vs 515 (×1,10), YouTube 535 vs 0, Reddit 45 vs 24.
  The rest is platforms the corpus never had: radio 1 241, TV 80, print 49, Bluesky 4.
- So: the rule transfers, the feed is broader (more capture), and only 44% of DetermDB accepts are
  already in the corpus. Precision of the NEW-ONLY accepts is unmeasured.

## 3. Source options (PI decision)

**A. Append only 2026-06-12 → 2026-10-16 from DetermDB.** Cheapest; 2021–Jun 2026 unchanged.
But it adds a second instrument seam at 2026-06-12: web ×1,2 and YouTube jumping from 0 to ~2 000
a month in the LAST four months, which every volume chart (Evolucija, Mapa, Izvršni pregled) would
show as a surge. Leaves the Feb–May 2024 hole and the 2026 YouTube hole.

**B. (recommended) Re-cut the post-2024 era from DetermDB: 2024-01-01 → 2026-10-16, one feed.**
Pre-2024 era (`original_dta`, itself cut from DetermDB) kept as is, truncated at 2023-12-31.
- The seam moves to a clean year boundary (2024-01-01) instead of mid-2024 + mid-2026.
- Fills Feb–May 2024 (Easter 2024 returns) and restores YouTube/comments for 2026.
- Cost: every 2024–2026 number on the site changes (frozen studies/reports are unaffected by design).

**C. Re-cut everything 2021 → 2026-10-16 from DetermDB.** Most uniform, but also moves 2021–2023,
roughly doubles the work, and is not needed for this request. Not recommended now.

**Platform scope (applies to A/B):** keep the corpus's nine platforms; EXCLUDE radio, TV, print,
Bluesky, Threads for now (they would add ~30% volume in a category no page is built for).

## 4. Steps (option B)

0. **Clean slate.** The working tree holds ~120 uncommitted `docs/` files from a mobile-chart pass
   (new CSS bundle `bootstrap-05a0de8c…`). Commit it separately or set it aside first.
   Copy current corpus + manifest + decisions to a timestamped backup (Dropbox data/).
1. **New script `R/rebuild_determdb.R`** (read-only on DetermDB): era `determ2024`, 2024-01-01 →
   2026-10-16, nine platforms; writes `data/rebuild/determ2024_decisions_v4.rds` with the same
   columns as the existing decisions files (score stored for every gate-1 passer). Maps DetermDB's
   46 columns onto the corpus schema; `data_source = "determdb"`. ~25 M rows → gate 1 is the long
   step (≈3–4 h at the measured rate; an SQL pre-filter on decisive stems can cut it).
2. **`R/build_corpus.R`**: accept the third decisions file, take pre2024 rows < 2024-01-01 from the
   accumulator and 2024+ rows from DetermDB, dedup on canonical URL, assert one model/threshold/
   window across eras. Manifest: new era spans, new caveats (seam at 2024-01-01; Feb–May 2024
   filled; YouTube restored), source = DetermDB for the 2024+ era. Preview → `--apply`.
3. **Precision audit (needs PI reading time).** Draw ~150 accepted 2024+ posts, stratified
   in-old-corpus / new-only, read by hand; report against the 84,5% headline. Do not publish before.
4. `R/03_aggregate.R` preview → **`--apply`** (HARD GATE).
5. `R/04_nlp.R --build` (udpipe; hours) → `R/05_page_summaries.R --build`.
6. `R/06_moj_medij.R --apply` (revisit `EVENT_YEARS`, Easter-2024 assertion) → `R/wiki_sources.R`.
7. **Kako se govori o Crkvi?**: `build-15pct-nlp.R` (new 15% udpipe generation; hours) →
   `analysis.R` → copy `analysis-data.js` to `assets/izvjestaji/kako-se-govori-o-crkvi/` → fix the
   typed "do 11. lipnja 2026." → `qa-browser.mjs`.
8. **Hand-typed values:** `data-cutoff` in 13 page YAMLs; "Ažurirano …" strips (7 pages);
   "približno 400.000" (index:70, baza:5, baza:175); metodologija:224 ("Najveća godina … 2025."),
   :252 ("do lipnja"); "nepotpunu 2026." (baza:226, izvrsni-pregled:518); izvrsni-pregled:444;
   moj-medij:737. Metodologija's description of the source/eras needs a prose rewrite.
9. **Render.** Clear `_freeze/` for every corpus-reading page (freeze:auto does NOT re-run on data
   change). Also refresh pages NOT on the request list that read the same data or they will
   contradict the rest: Atmosfera diskursa, mapa/index, izvori/mreza, metodologija, about,
   agentic-layer, agentski-sloj. Full `quarto render` (HARD GATE) then restore
   `docs/pages/studije` + `docs/site_libs` per MEMORY, verify every href/src is tracked.
10. Verify: verifier agent (aggregates untouched by render), numeric-claim-verifier on the ten pages,
    diacritics, asset-tracking check. Commit in separate commits (pipeline code / aggregates / docs).

## 5. Not changing
Frozen study pages, annual report 2025, Barometar/Demokršćanstvo (already its own DetermDB edition;
can be re-run separately — it predates the Q1-2024 re-import).

## 6. Rollback
Old corpus + manifest + decisions backed up; `data/processed` and `data/page-ready` are tracked
(git restore); `data/nlp` previous generation kept by `04_nlp.R`'s backup.

## 7. Outcome (2026-10-18, PI chose option B)
- Corpus rebuilt: 611 583 × 55, 2021-01-01 → 2026-10-16, sha 5d8b6959…; pre-2024 unchanged; 2024+ from
  DetermDB (26,4 M rows scanned, 425 706 kept after dedup). `comment` excluded from 2024+ (intermittent).
- `03_aggregate.R --apply` (PI confirmed), `04_nlp.R --build`, `05_page_summaries.R --build`,
  `06_moj_medij.R --apply` (427 sources), `wiki_sources.R` (70 published, 46 held) all run.
- Pages re-rendered one by one (no full-site render); 8 hand-typed claims falsified by the new data fixed.
- "Kako se govori o Crkvi?" re-run on a new 15% sample (91 636 docs); report-local period overrides;
  two generated sentences made data-driven; v1.3; browser QA passed.
- OPEN: precision audit (data/rebuild/determ_coder.html) unread; 19 dropped catalogue pages still in
  docs/ (guard blocks deleting them); nothing committed or pushed.
