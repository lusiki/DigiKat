# DigiKat — Site-wide content review

**Date:** 2026-06-29 · **Scope:** all 16 reader-visible pages (index + every navbar tab) · **Method:** multi-agent review (style/voice + Croatian-language lens on every page; dedicated data/numeric lens on the 6 data-bearing pages) against `.claude/rules/voice-and-style.md`, with all corpus figures verified directly against the live master `data/merged_comprehensive.rds`.

## Confirmed ground truth (verified against the live master, 2026-06-29)

| Fact | Value | Notes |
|---|---|---|
| Corpus size | **710.307** objava | `nrow` of live master. "710.000" is CORRECT; "610.000" is now obsolete. |
| Year span | **2021–2026** | 2026 = 101.151 rows. "2021.–2026." is correct for the data. Project *scope* (2025–2027) is a separate concept. |
| Variables | **47** columns | NOT 620. "620 varijabli" is wrong against the live master everywhere it appears. |
| Source types | **9** | web 524.393 · facebook 89.328 · youtube 65.521 · reddit 9.791 · twitter 7.052 · forum 6.410 · instagram 3.825 · comment 3.649 · tiktok 338. Not 6. |
| Tracked aggregates | **STALE** | `data/processed/*.rds` built 2026-01-08, sum to 608.879, cover only 2021–2025, miss instagram/tiktok. |

## Root cause

The master was refreshed (2026 data + instagram/tiktok appended) on 2026-06-29, but `R/03_aggregate.R` was **not** re-run, so `data/processed/*.rds` are stale. Pages that read those aggregates (the four `mapa/*` pages) show 610k / 2021–2025; `index.qmd` and `baza.qmd` were hand-updated to 710k / 2021–2026. Hence the cross-page disagreement.

---

## CRITICAL — data inconsistencies

1. **Corpus size disagrees across pages.** index/baza say 710.000; mapa/mapa_stats say 610.000+; CLAUDE.md/MEMORY.md/PROJECT_DESCRIPTION.md say ≈610k. Correct = 710.307.
2. **"620 varijabli" is wrong everywhere** (index.qmd L39; baza.qmd YAML L5; CLAUDE.md; MEMORY.md; PROJECT_DESCRIPTION.md). Master has 47 columns. Either correct to 47 or relabel explicitly as raw-export fields.
3. **Year range conflated & inconsistent.** Data = 2021.–2026.; project scope = 2025.–2027. (schedule only). news.qmd has a spurious 2024.–2026. badge and a 2021.–2024. body claim. The four mapa pages hard-clamp filters to 2025-12-31, silently excluding 2026.
4. **diskurs.qmd sample fraction:** comment says 5%, code sets `sample_proportion <- 0.02` (2%); no fraction stated in prose at all.
5. **Source-type count wrong:** index says 6 (pills omit comment/instagram/tiktok); baza metric card hardcodes 6. Actual = 9.

## MAJOR — consistency & language

6. **Stale aggregates** are the shared root cause (HARD GATE: re-run `R/03_aggregate.R`; also extract the `saveRDS()` calls out of mapa.qmd).
7. **"sentiment" → "tonalitet"** drift in prose (news, mapa, mapa_stats, diskurs, događaji). Keep "sentiment" only in variable names / legend labels.
8. **Canonical layer/typology names** not used consistently: schedule.qmd uses "sistematizirana karta"/"medijski prostor"/"baza podataka"; diskurs/događaji H1 omit the canonical layer name; "Tematske struje" body uses only "kategorije".
9. **RIK vs RCI/CLI:** prose uses RIK (canonical), code uses `rci` and comments mix "CLI i RCI". Introduce RIK once, reuse; explain CLI if kept.
10. **lilaHR mislabelled "NRC"** in diskurs/događaji code comments & variable names (file loaded is `lilaHR_clean.xlsx`).
11. **"baza podataka" used for the empirical corpus** on baza.qmd (canon: that is *korpus*; "baza podataka" = the published product only).
12. **Croglish / English-only prose:** baza.qmd is heavy ("Kaggle Dataset", "Sentiment scoring", "Wordcloud generiranje", "existirajuće", "tidyverse ekosystemom", English sentiment values); also news/mapa/događaji/resources/self-help.
13. **Year-range dash format** (hyphen vs en dash, missing ordinal periods) on schedule/news/događaji.
14. **Sample fraction** stated inconsistently / not disclosed in prose on mapa_stats/diskurs/događaji.

## MINOR / polish

15. Title Case in headings & figure labels (Web portali, YouTube kanali, month names) — mapa/događaji/schedule.
16. Decorative emoji used as a design pattern (site-info/about/resources) — banned by style guide; needs a project-wide decision (replace with Bootstrap icons, or carve out an exception).
17. Title↔subtitle near-duplication (schedule/news/site-info/događaji/sveci).
18. Metric-card labels not derived / wrong genitive-plural form (mapa_stats/događaji).
19. Approximate percentages narrated off charts instead of computed (mapa/mapa_stats).
20. Leftover placeholder/scaffolding line live on news.qmd.
21. baza.qmd: bracketed-literal URLs instead of Markdown links; ASCII quotes in reader-visible cells; "Top 10 izvora" caption mislabels source *types*; typos ("izvlučena", redundant manual date footer); Kaggle anchor "2021-2025".

---

## Per-page snapshot

| Page | Crit | Maj | Min/Nit | Headline issue |
|---|---|---|---|---|
| index.qmd | 6 | 4 | 11 | 710k/620/6-platform/year facts (data correct except 620 & platform count) |
| baza.qmd | 2 | 6 | ~16 | reads live master (computed values OK); hardcoded 620 & 6; heavy Croglish |
| about.qmd | 0 | 0 | 1 | clean; emoji only |
| schedule.qmd | 0 | 6 | 4 | non-canonical layer names; dash formats |
| site-info.qmd | 0 | 1 | 5 | emoji; subtitle dup |
| news.qmd | 1 | 3 | 9 | placeholder text; year claims; sentiment |
| resources.qmd | 0 | 1 | 8 | emoji; Croglish |
| mapa/mapa.qmd | 1 | 8 | 12 | stale 610k; Title Case; sentiment; narrated % |
| mapa/mapa_stats.qmd | 1 | 5 | 16 | stale 610k; "struje" not surfaced; sample fraction |
| mapa/diskurs.qmd | 2 | 4 | 8 | 2025 clamp; 2% vs 5%; NRC→lilaHR; RIK/RCI; H1 name |
| mapa/događaji.qmd | 0 | 10 | 13 | most major issues; lilaHR; dashes; subtitle |
| studije/* (5 stubs) | 0 | 0 | ~11 | clean stubs; minor subtitle/Croglish nits |

---

## Recommended fix plan

**Needs your go-ahead (HARD GATE / decision):**
- **A. Re-run `R/03_aggregate.R`** against the current master to refresh `data/processed/*.rds` (overwrites tracked aggregates) — unblocks correct 710k figures on the mapa pages.
- **B. The "620" question:** is it (i) plain wrong → use 47, or (ii) a count of raw pre-ingestion xlsx fields → relabel as "izvornih varijabli" and keep 47 for the working corpus?
- **C. Emoji policy:** replace decorative emoji with Bootstrap icons, or sanction `.info-card-icon` in the style guide.
- **D. Full `quarto render` to `docs/`** (HARD GATE) after fixes.

**Safe source fixes I can do without re-aggregating (Phase 1):**
- Standardize corpus size → 710.000+/derived; year range → 2021.–2026.; fix 620→47 (pending B); fix platform count → 9 + add missing index pills.
- Widen the four mapa date filters to 2026; fix diskurs 2% comment + add prose method note.
- Terminology: sentiment→tonalitet in prose; canonical layer names in H1s; RIK consistency; NRC→lilaHR in code.
- Remove news.qmd placeholder; fix Croglish, dash formats, Title Case, baza links/quotes/typos.

(Editing across `pages/**` is a multi-file change → plan-first per project rules before Phase 1.)
