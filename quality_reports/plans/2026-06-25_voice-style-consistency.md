# Plan — Voice/Style consistency: guide + HIGH-priority fixes

**Date:** 2026-06-25 · **Owner:** Claude (for PI L. Šikić) · **Status:** in progress

## Goal
Stamp a canonical house voice/style for DigiKat and fix the highest-impact cross-page inconsistencies
surfaced by the 11-page audit, so the site reads as one study rather than three voices.

## Done
- `.claude/rules/voice-and-style.md` — path-scoped (`pages/**/*.qmd`, `_quarto.yml`) canonical guide. Auto-loads when editing site content.
- Referenced in `CLAUDE.md` auto-loaded rules list.

## Canonical decisions (locked)
- Big counts → `610.000` (period grouping); figures `big.mark="."`. Percentages → digit + `%`, decimal comma.
- Year range → `2021.–2025.` (ordinal dots + en dash) everywhere incl. YAML titles.
- Corpus = **korpus**; product = **baza podataka**; unit = **objava**; polarity = **tonalitet** (sentiment only in labels/vars).
- Conflict index → **RIK** (Relativni indeks konflikta), one acronym, expanded once. (replaces RCI/CLI in visible text)
- Croatian-first; no English-only prose, no inline CRO/ENG slash labels. Analytical voice = impersonal.

## HIGH-priority fixes — scope
1. **index.qmd** — Croatian-ize the two English-only blocks (hero subtitle, framework intro) + all CRO/ENG slash
   labels/valuebox English lines → Croatian-only; fix `610&#8201;000` thin-space → `610.000`; `2021–2025` → `2021.–2025.`.
   *(static HTML page — renders without R; fully verifiable here.)*
2. **YAML title year-range** `(2021-2025)` → `(2021.–2025.)` in baza, mapa, mapa_stats, diskurs, događaji.
3. **diskurs.qmd** — conflict-index acronym: reader-visible `RCI`/`CLI` → `RIK` (display strings only, NOT R variable names).

## Needs a decision before doing (asked separately)
- **Typology collision** (diskurs L3 "Graditelji zajednice" vs mapa L1 "Graditelji zajednica") — rename the L3 group.
- **Empty "Tematska istraživanja" menu** (5 `href:""`) — stub "Uskoro" pages vs hide menu vs leave flagged.
- **Number-format in R** (baza `big.mark=","`, mapa `scales::comma`) — edit + render-verify (needs R+data; present here).

## Verification
- index.qmd: `quarto render pages/index.qmd` (no R needed) → check Croatian diacritics, no English-only prose, `610.000`.
- Data pages: static check of YAML/title edits now; full render-verify (R+master present) in the R-number batch.
- HARD GATE: do NOT run `R/03_aggregate.R`; do NOT full-`quarto render` over `docs/`; if a single-page render writes
  `data/processed/*.rds` (mapa.qmd known issue) → do not stage it.

## MEDIUM batch — done (2026-06-25)
- **De-hyperbole:** about ("sveobuhvatan uvid", "pouzdanije i inovativnije" → softened); resources ("Biblija za svakoga",
  "Najvažnija zajednica", "Odlična/zabavna knjiga" → neutral); all English `[Link]` → `[Poveznica]`.
- **Terminology (korpus/baza/dataset):** baza captions + cat() `dataset(u/a)` → "baze podataka"/"skupu podataka"; news
  `dataset` → "skup podataka"; news `dashboard` → "nadzorna ploča".
- **Layer-name leads + relative cross-links:** mapa→Tematske struje, mapa_stats→Tematske struje/Atmosfere diskursa,
  diskurs→Atmosfera diskursa/Fokus na događaje, događaji→Fokus na događaje. ALL `raw.githack.com` links → relative
  in-site paths; **fixed događaji's dead self-link** (was → događaji.html, now → diskurs.html).
- **Polarity term:** valenca/valencija → tonalitet/obojenost (diskurs, događaji ×3, mapa_stats).
- **Lexicon mislabel:** diskurs metric card NRC → lilaHR.
- **Numbers:** mapa prose "oko 80 posto" → "oko 80 %".
- **Jargon-fog:** transcendira(ju) → nadilazi/nadilaze (4 spots). **Hyphenation:** "društveno politički" →
  "društveno-politički" (all). **Typos:** tematskie→tematske, odgovog→odgovor, "tematske analiza"→analize.
- **Site-info:** added Croatian caption framing the `sessionInfo()` block. **Schedule:** added corpus(2021.–2025.)
  vs project(2025.–2027.) bridging clause.
- **M3 (analytical "mi"):** confirmed guide-compliant (method-framing only) — no rewrite needed.

## MEDIUM — deferred (flagged to user)
- **baza per-table read-outs** (M4): add 1-line interpretation under each distribution table — better done WITH computed
  values (a /data-analysis pass), not invented prose.
- **M8 platform count "6 vs 7 SOURCE_TYPE":** verify whether "comment" is a non-platform (then 6 is correct) and
  substantiate from data rather than hand-assert.
- **about-as-methodology** (content #5): structural split of recruitment vs methods, or retarget the footer "Metodologija" link.
- **resources bibliography:** ~40 English reference titles lost their colons — separate cleanup.
- **news "Ožujak 2023"** entry sits inside the 2025 timeline — chronology/ordering bug; needs the correct date (don't fabricate).
- Remaining Latinate-fog density (bifurkacija, rekonfiguriraju, epicentar …) — ongoing tone polish.

## Rejected alternatives
- Bilingual `/en/` mirror inline → rejected (Croatian-first; an English mirror, if ever, is a separate page).
- Converting index numbers to computed `r` values now → deferred (would make index a data-page needing R); fixed format only this pass.
