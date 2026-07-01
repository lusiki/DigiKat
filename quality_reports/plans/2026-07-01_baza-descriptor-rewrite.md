# Plan — Rewrite `pages/baza.qmd` as a real database *description* (descriptor)

**Date:** 2026-07-01 · **Owner:** Claude (for PI Luka Šikić) · **Status:** awaiting approval

## Goal
Replace the current codebook-that-reads-like-an-R-tutorial with a proper **data descriptor**: lead with
*what the database is, how it was collected, how it was filtered, and who is in it* (incl. the
confessional-vs-secular outlet composition the PI asked about), keep the codebook role as a demoted reference
appendix, and cut the technical cruft (performance tables, base-R-vs-data.table speed, library ads, R-version
footer, code recipes).

## Why (rationale)
User feedback: *"this database tab is not good — too much technical crap, not enough description of what this
database is about."* The current page never states the sampling frame, provenance, outlet composition, or
limitations; instead it teaches `data.table` syntax and lists library load times. A descriptor answers
"what is this?" first.

## Grounded data findings (from the 1.2 GB master; drive the new prose)
- **710.307 objava × 47 varijabli**; DATE 2021-01-01 → 2026-06-11 (snapshot cut = 11 June 2026).
- **9 platforms:** web 73,8 % · facebook 12,6 % · youtube 9,2 % · reddit 1,4 % · twitter 1,0 % · forum 0,9 % ·
  instagram 0,5 % · comment 0,5 % · tiktok 0,05 %.
- **Corpus is topical, not source-based:** built by the ≥2-distinct-match rule over 93 religious terms.
  Confirmed by outlets: #1 source is confessional **hkm.hr (56.5k, 8 %)**, but the top list interleaves
  confessional (Laudato, Glas Koncila, crovijesti, Radio Marija, dioceses) and secular mainstream
  (Slobodna Dalmacija, Večernji, Index, Jutarnji, 24sata, HRT).
- **Indicative outlet composition (post-level, labeled top sources):** konfesionalni ≈ **27,6 %** (lower bound;
  196k), mainstream/secular ≥ 21,7 % *labeled* but the majority once the ~47 % unlabeled long tail (secular
  local news: prigorski, medjimurski, sibenik.in…) is counted; community/forum ≈ 3,1 %. **Per-platform
  contrast:** YouTube 42 % confessional, Facebook 37 %, web only ≈ 26 %, reddit/forum ≈ 0 %.
- **2025 "surge" is largely a COLLECTION ARTIFACT.** `data_source` streams are time-segregated:
  `original_dta` (monitoring query) = 2021–2023 (+sliver 2024); `filtered_religious` (≥2-filter backfill) =
  2024–2026. Instagram/TikTok appear only from 2024. So cross-year volume mixes real activity with a change
  in collection method/coverage around 2024 — **must not be read as growing attention.**
- **AUTO_SENTIMENT is vendor-supplied** (positive 47,2 % / negative 28,8 % / neutral 24,0 % / undefined ~0),
  coarse, distinct from the project's lexicon tonalitet in *Atmosfera diskursa*. MANUAL_SENTIMENT 100 % empty.
- **Engagement metrics are uneven & vendor-computed:** REACH/INTERACTIONS ~100 % on web+facebook only,
  VIEW_COUNT youtube/instagram only, FB reactions ~87 % NA overall, FOLLOWERS_COUNT ~85 % NA, INFLUENCE_SCORE
  is an 11-level ordinal. REACH heavy-tailed (median 516, max 9,06 M). **Not comparable across platforms.**
- **Empty-by-design cols (100 % NA):** MANUAL_SENTIMENT, TAGS, TWEET_COUNT, COUNT.
- **`FOUND_KEYWORDS` is the vendor's noisy keyword field** (top value = "i"/and), NOT the ≥2-filter evidence —
  describe honestly; do NOT present it as match provenance. The ≥2-match columns are not retained in this master.
- **Language/geography are auto-detected multi-label:** hr dominant (542.8k pure) + hr+bs/hr+bs+sl/bs/sr/sl;
  HR 605.8k + HR+BA 68.1k + SI/RS/ME. Flattening to "hr"/"HR" drops ~168k / ~104k records.

## New page structure (13 sections; Croatian; leads with description, codebook demoted)
1. **Što je ovaj korpus** — one-sentence definition + unit = objava + links to the 4 layers.
2. **Ključni pokazatelji** — `.metric-grid` ×4: 710.307 · 2021.–2026. (2026 nepotpuna) · 9 platformi (web 73,8 %) · prag ≥2 / 93 pojma.
3. **Što korpus NIJE** — `.featured-box` interpretive guardrail.
4. **Kako je korpus definiran** — ≥2/93 rule, precision>recall, filter limits (homographs, morphology; heuristic not validated classifier).
5. **Tko govori: sastav i tipologija izvora** — confessional-vs-secular composition + 4-way typology + per-platform voice dominance (the PI's parameter).
6. **Kako je prikupljen** — monitoring export, two time-segregated streams, URL dedup + ?utm_ gap, observational not probability sample.
7. **Opseg korpusa** — years (with the collection-artifact caveat), platforms, multi-label language, geography.
8. **Struktura podataka** — 47 vars in 6 groups, FULL_TEXT on request, value dictionaries.
9. **Signali i mjere: podrijetlo** — vendor AUTO_SENTIMENT caveat + engagement provenance/uncomparability.
10. **Kvaliteta i ograničenja** — metric-availability matrix, 3 classes of missingness, safe-vs-unsafe inferences.
11. **Kako se korpus koristi** — links to 4 layers + studies.
12. **Pristup, licencija i citiranje** — CC BY 4.0, Kaggle, repro path, PII note, resolved citation w/ snapshot date, contact/ORCID, one minimal `readRDS` line.
13. **Referenca: potpuni popis varijabli** — collapsible data-driven 47-var table w/ group column + key=URL note.

## Cuts (from current page)
Performance-notes table; library recommendations + "10–100× faster than base R"; advanced-analysis code recipes;
basic-analysis one-liners; the load/process code chunk; `str()` dump; pins/board_kaggle snippet;
"Format: R data.table"/separators/encoding rows; `R.version.string` footer + "Verzija 2.1"; corrplot;
single-value "Hrvatski (hr)"/"Hrvatska (HR)" → replaced by multi-label truth.

## Implementation & verification
- Rewrite in-page R chunks that READ the master and compute every number inline (no `saveRDS`, no
  `data/processed` writes). Embed a compact, transparent outlet-classification block (confessional set +
  church-domain patterns) so the composition is computed + reviewable, clearly caveated as indicative.
- Follow `voice-and-style.md` (canonical terms, `big.mark="."`, `12,3 %`, `2021.–2026.`, sentence-case headings).
- Render ONE page from repo root (R + master present on this machine); verify: builds clean, diacritics intact,
  no scatter outside `docs/`, `md5sum data/processed/*.rds` unchanged. Pause Dropbox first (Dropbox hazard).

## Open questions → recommended resolution
1. **Outlet composition:** publish the indicative % + typology (clearly caveated) — *recommended, it's the asked-for parameter* — vs qualitative-only. (User decision.)
2. **Versioning/DOI:** no data version today ("Verzija 2.1" is meaningless). Recommend snapshot label "presjek 2026-06-11" + Kaggle URL; add Zenodo DOI if one exists. (User decision.)
3. **Kaggle N/columns:** confirm the public Kaggle download's N and that it excludes FULL_TEXT — keep citation honest. (Flag; PI to confirm.)
4. **PII/disclosure:** section 5 names public outlets/accounts only; consider a `/disclosure-check` follow-up before any new data extract. (Flag.)
