# DigiKat — cjeloviti pregled stranice (2026-07-01)

Overall readiness: FIX-FIRST. The site renders cleanly (no structural/build-breaking defects on any page), but a systematic, cross-cutting problem blocks a clean publish: the ~2024 collection-method change (two `data_source` streams) confounds every cross-year read-out on all four/five analytical maps, and it is uncaveated on the pages that matter most. Verified counts: **9 Critical**, **32 Major**, **~50 Minor**. The three biggest cross-cutting themes are (1) uncaveated stream/collection confound on year-over-year volume, share, engagement and concentration; (2) substring-based (unanchored) theme scoring plus lemma/lexicon case-folding gaps that undermine measurement validity in the NLP layers; and (3) site-wide consistency drift (4-vs-5 layers, RIK/RCI/CLI naming, hardcoded vs computed corpus counts, actor-typology casing) plus two broken navigation links introduced by the new fifth map.

## Prioritetni popravci

1. **[Critical]** `_quarto.yml:26-27` — "Pregled mapa" navbar item points to `pages/mapa/index.qmd`, which does not exist (dead link, will 404) → create the maps-overview landing page or remove the menu entry before deploy.
2. **[Critical]** `mapa/evolucija.qmd:146,161,179-215,316-320` — "Prostor je narastao" reads the x2,6 2021→2025 volume rise as real growth; MEMORY flags THIS page and calls the 2025 surge (236k) largely a collection artifact → add explicit collection-method caveat to the Rast section, KPI card and synthesis; state the ~2024 method change roughly doubles volume.
3. **[Critical]** `mapa/evolucija.qmd:253-286,316-317,324` — "Utjecaj se rasprsuje" (top-10 share 55,8%→23,3%, n_actors x2,9) is a mechanical artifact of the 2024 backfill injecting thousands of new FROM ids → add a collection caveat that the "dispersion" is confounded with a coverage expansion.
4. **[Critical]** `mapa/mapa.qmd:204,206-237,280-330,454` — cross-year volume and platform-share trends charted/interpreted as real media dynamics with no `data_source` caveat → add a method caveat (two streams; Instagram/TikTok only from 2024) and soften the 2025-surge / web-decline prose.
5. **[Critical]** `mapa/mapa_stats.qmd:253-284,111` — yearly topic-share trends read as real temporal signal with no stream caveat → add pre/post-2024 collection-break caveat; do not present 2021–2025 share shifts as trend without conditioning on stream/platform.
6. **[Critical]** `mapa/mapa_stats.qmd:89-104,99-100` — theme scoring uses unanchored `str_count()` substring matching feeding argmax `dominant_topic`; empirically over-counts (mis→3, rat→4) → anchor to word/lemma boundaries and re-validate `dominant_topic` on a hand-checked sample.
7. **[Critical]** `mapa/događaji.qmd:203,217,232` — sentiment/emotion/conflict joins key udpipe lemmas against lowercase lexicon words with no lowercasing on either side, so capitalized tokens (Stepinac, place/actor names) silently fail to match → apply `stri_trans_tolower()` to `lemma` before all three joins (ideally once in `R/04_nlp.R`).
8. **[Critical]** `mapa/događaji.qmd:268,291-395,453-520` — cross-year volume anomalies and per-year Stepinac frequencies read as substantive; MEMORY names this page for the confound → add reader-visible stream caveat at each cross-year read-out.
9. **[Critical]** `mapa/događaji.qmd:391-393,528` — "gotovo savršeno koincidiraju" asserts near-perfect seismograph precision against named events with no validation table/precision/recall → show the detected-date→event mapping with hits/misses and drop "gotovo savršeno", or reframe as a qualitative spot-check.
10. **[Critical]** `mapa/diskurs.qmd:123-157,298,480,512` — SCREAMING_SNAKE dictionary keys (DUHOVNOST_I_LITURGIJA, PAPE_I_VATIKAN…) leak into the heatmap y-axis and network nodes; contradicts the prose and §5/§6 → add a named recode to sentence-case Croatian labels (mirroring `emotion_translator_hr`) before plotting.
11. **[Critical]** `mapa/diskurs.qmd:320` — audience-behaviour claim ("Publika izražava frustraciju… kritičke komentare, dijeljenja… reakcije") with zero engagement/comment/reaction data on the page → delete or reframe to speak only to the emotional register of the TEXTS.
12. **[Major]** `mapa/evolucija.qmd:44-49` — page hard-codes a bright Tableau/brand palette (web #1f77b4 vs editorial #0F4C5C) and falsely comments it is "konzistentno s Mapom ekosustava"; every figure clashes with the other maps → replace with `platform_colors <- dk_platform_colors` and fix the comment.
13. **[Major]** `mapa/evolucija.qmd` + `R/03_aggregate.R` — `data/processed/platform_monthly.rds` (a page dependency) is UNTRACKED and `R/03_aggregate.R` is modified/uncommitted; a fresh clone would be missing it → commit the script and `git add` the aggregate (after disclosure/no-PII check).
14. **[Major]** (cross-page) `index.qmd/baza.qmd/mapa*` vs `evolucija.qmd` — layer count is FOUR everywhere but "peta analitička mapa"/"pet mapa" on evolucija; evolucija is not linked in from the other pages → pick one canonical count, update index/baza/CLAUDE.md vocabulary and the mapa cross-links, and stop calling Fokus na događaje the "zadnja" map.
15. **[Major]** `index.qmd:24-25` + `docs/index.html` — homepage hero CTAs use `baza.html`/`mapa/mapa.html` (resolve to missing `docs/baza.html`), and `docs/index.html` is a stale 239-byte redirect to about.html → fix hero links to `pages/baza.html`/`pages/mapa/mapa.html` and re-render so `index.qmd` regenerates `docs/index.html`.
16. **[Major]** (cross-page) diskurs vs događaji — conflict index named three ways (RIK / RCI / CLI); događaji never surfaces "RIK" to the reader → use RIK in all reader-visible chrome on both pages (expand once), keep rci/cli as code identifiers only.
17. **[Major]** `mapa/mapa_stats.qmd:121-122` — KPI card asserts "70+" religijskih pojmova; the inclusion filter has 95 terms and the theme layer uses ~200 substrings → replace with a computed, correctly-labelled value (95 for the filter, or the substring count for the dictionary).
18. **[Major]** `mapa/mapa_stats.qmd:229` — wordcloud stopword filter compares a lemma to a tibble (`!lemma %in% stop_words_hr`) not `$word`, so the Croatian stoplist is not applied and `all_stop_words` is dead code → fix to `!lemma %in% all_stop_words$word`.
19. **[Major]** `mapa/mapa_stats.qmd:89-104 vs 138` — page advertises "Lematizacija" but the core 16-category classification runs on raw FULL_TEXT substrings, not lemmas → run theme classification on lemmas or clarify the method note.
20. **[Major]** `baza.qmd:169` — hkm.hr glossed as "Hrvatski katolički radio"; it is Hrvatska katolička mreža (HKR/hkr.hr is separate and appears independently in the page's own conf_exact list) → correct the parenthetical to "(Hrvatska katolička mreža)" or drop it.
21. **[Major]** `baza.qmd:281,304` — INFLUENCE_SCORE described as "jedanaest razina"; data has 10 non-NA levels (1–10), eleven only if NA is miscounted → change to "deset razina" (or compute inline).

## Nalazi po stranici

### pages/mapa/mapa.qmd
**Critical**
- l.204/206-237/280-330/454 — cross-year volume & platform-share trends interpreted as real media dynamics with no `data_source` caveat → add a method caveat (two streams; Instagram/TikTok only from 2024) and soften trend prose.

**Major**
- l.393-431 — four archetypes assigned by per-platform median split over ~19 actors (non-comparable across platforms, mechanically relative) and quadrants are unlabeled → render quadrant labels + state the split is a relative per-platform median, or define fixed cross-platform thresholds.
- l.35-37/204/344-389/448 — corpus is topical (secular giants dominate the web elite) yet framed as "katolički kreatori"/"katolički ekosustav" with no indicative-labeling caveat → add a topical-corpus, indicative/PI-owned-labels caveat.
- l.53-54/280-330/41 — prose names only web/YouTube/Facebook while charts include 9 source types and Instagram/TikTok arrive only in 2024 → name the full set / flag thin, late-arriving platforms.
- l.204/344-387/439 — named rankings pooled 2021–2026 across streams; 2026 is an unmarked partial-year facet (101k) → mark 2026 partial and note pooled rankings mix differential coverage windows.
- plot-actor-map l.433-435/429 — panel titles Title Case ("Web Portali"…) inconsistent with the lollipop's sentence case; axis "(Log)" cased/English → lowercase titles to match l.374-376 and Croatianize the axis label.
- l.33/198/393/450 — heading levels inverted (H2 before any H1; synthesis H2 nested under actor-map H1) → promote opening to H1 and make the synthesis top-level.
- l.239 — "websadržaja" (Croglish), "Njaveći" (typo), double space after "24sata.hr" → "web-sadržaja", "Najveći", single space.

**Minor**
- metric-grid l.47-64 — four KPI values hardcoded as HTML literals → derive inline from aggregates.
- l.69 — "Doseg (reach)" gloss → drop "(reach)".
- l.395-403/58 — English type gloss (Giants/Community Builders/…) missing on first use; add the L1-vs-L3 distinct-construct note.
- l.39-45 — lead poses three page questions but names no project Q1–Q5 → name the RQs.
- l.200 — colon promises "tri pokazatelja" but no list follows → follow with a list or reword.
- plot-volume l.233 / plot-interaction l.272 — "Napomena:"-only captions missing "Izvor:"; empty subtitle at l.230 → add Izvor: line + subtitle.
- l.41/l.280 — trailing whitespace → strip.
- l.433-435 — actor-map figure titles Title Case (subset of the Major casing finding).

**Verdikt: FIX-FIRST**

### pages/mapa/mapa_stats.qmd
**Critical**
- l.253-284/111 — yearly topic-share trends read as real temporal signal, no stream caveat → add pre/post-2024 collection-break caveat.
- l.89-104/99-100 — unanchored `str_count` substring scoring drives argmax `dominant_topic` (empirically over-counts) → anchor to boundaries and re-validate.

**Major**
- l.121-122 — "70+" religijskih pojmova is a wrong hand-typed literal (filter = 95) → compute and label correctly.
- l.322-391/495-506 — engagement/polarization aggregates ignore platform confound; FB-only polarization generalized to "digitalni prostor"/"hrvatsko društvo" → condition on platform and scope the polarization to Facebook.
- l.458-491/497-506 — "jasna segmentacija"/"dva tematska svijeta" rests on one r>0.1 network over substring-inflated scores → soften, report threshold sensitivity, re-derive on anchored scores.
- l.70-86 — categories not mutually exclusive ("žrtv" in two categories; "bioetik" mis-placed in ZNANOST_I_VJERA vs the BIOETIKA category) → de-duplicate roots or document a deterministic tie-break. (Drop the "stvaranje" example — it is not on l.71.)
- l.229 — wordcloud stoplist compared to a tibble not `$word`; `all_stop_words` dead code → fix membership test and use the custom stoplist.
- l.89-104 vs 138 — advertises lematizacija but theme scoring runs on raw FULL_TEXT → run on lemmas or clarify the method note.

**Minor**
- l.399-456/97-101 — "Protagonisti" over-reads NER frequency; argmax on raw (non-normalized) counts biases dominant topics → soften and consider argmax on norm_ scores.
- l.355/385/389/391/502/504 — "Love"/"Angry" unglossed in Croatian prose → gloss on first use.
- l.113 — Latinate "interpretabilnosti" jargon-fog → plainer Croatian.
- l.145/251 — "prezentiramo"/"odgovaramo" 1st-person plural beyond framing → impersonal third person.
- l.113/391 — missing sentence period; double space → fix.
- figure chunks (147,257,292,328,359,405,464) — no fig-cap/fig-alt/Izvor: → add.
- l.98/334/414 — "Nema Teme" Title Case (code-only) → sentence case.
- l.2-3 — subtitle restates the title → make it informative.
- l.280 — "5%" in chart title → "5 %".
- l.278 vs 2/111/129 — x-axis breaks stop at 2025 while header says 2021.–2026. → annotate/extend axis.
- l.144/90 — base `tolower()` (locale-dependent) → `stri_trans_tolower()`.
- l.59/111 vs R/04_nlp.R — stratum label "platforma" vs SOURCE_TYPE; undisclosed tiktok exclusion → align wording, disclose exclusion.
- l.154 — stopword-list provenance comment missing → add.

**Verdikt: FIX-FIRST**

### pages/mapa/diskurs.qmd
**Critical**
- l.123-157/298/480/512 — SCREAMING_SNAKE topic keys render on the heatmap y-axis and network nodes → add a sentence-case recode before plotting.
- l.320 — audience-behaviour claim with no engagement data → delete/reframe to the texts' emotional register only.

**Major**
- l.185/312/318/534/540/552 — rejected register: "bifurkacija", "rekonfiguriraju", "epicentar svih narativnih prijepora" plus hype intensifiers → replace with plain Croatian, one metaphor per section.
- l.187/259-268/345-354/461-470 — pooled 2021–2026 baselines with no stream/collection caveat → add the ~2024 method-change note and flag baselines as cross-sectional.
- l.396-402/550 — outlet editorial labels (desno/aktivistički, vjerski, mainstream) asserted as fact; MEMORY: ~53% labelled, contestable, PI-owned; dragovoljac.com (n=69) isn't even in the shown figure → hedge as indicative/PI-owned.
- l.143-157/280-286/260-346-462 — winner-take-all `dominant_topic` (which.max, no tie rule) drives heatmap & baselines → state the single-label limit, add tie handling, or lean on continuous norm_ intensities.
- l.123-140/147 — shared/loose stems ("žrtv" in two categories; "vjer" catches povjerenje/vjerojatno) decide cells → de-duplicate + word-boundary matching. (Corrections: "bioetik" is only in ZNANOST_I_VJERA; "sakraln"/"sakrament" don't overlap.)
- l.314/548/320 — causal/strategic-intent framing ("empirijski verificiralo… strateškog emocionalnog uokvirivanja") beyond a descriptive cross-tab that is partly definitional → soften to associational language.
- l.318/286 — "Paradoksalna uloga Gađenja" is a thin single-cell read (n>3) with an invented corruption mechanism; the Pape row has no Gađenje cell in the rendered figure → raise the n threshold, report cell n's, drop the speculation.

**Minor**
- chunks 293/361/412 — no Izvor: caption / fig-alt → add (house-wide pattern).
- l.85/87-98 — file is lilaHR but comment/vars say "NRC"/nrc_lexicon_* → rename to lilaHR_*.
- l.389-390 — y-axis lacks "(RIK)"; x-axis introduces an unnamed twin metric (CLI) → append (RIK) and name the x-axis metric.
- l.301 — legend "Prosj. Sentiment" Title Case + abbreviation → "Prosječni sentiment".
- l.176-177 vs 185 — KPI card "2 razine" vs lead "tri komponente" → reconcile the count.
- l.187/359-402 — RIK medium sample sizes pooled across the collection change, uncaveated → add a half-sentence.
- l.187/394-402/538 — 2% sample fraction not restated at the strongest claims → add "(na 2% uzorku)".
- l.379-391/396-402 — quadrant language with no reference lines → add median/mean splits or drop quadrant language.
- l.396-402 — (positive check) L3 strategy typology does not collide with L1; optionally note they are distinct.
- l.144 — base `tolower()` → `stri_trans_tolower()`.
- l.123-140/234-238/435-439 — dictionaries inlined and conflict_lexicon duplicated within the file → extract to R/ helpers.
- l.187 — "po platformi" descriptor (likely non-issue: SOURCE_TYPE == canon platforma).
- l.119 — page correctness depends on pre-built pinned-model tokens (informational).
- RIK naming consistent in reader-visible prose (positive check).

**Verdikt: FIX-FIRST**

### pages/mapa/događaji.qmd
**Critical**
- l.203/217/232 — three lexicon joins with no lowercasing on either side → `stri_trans_tolower()` before all joins.
- l.268/291-395/453-520 — cross-year volume anomalies and Stepinac frequencies read as substantive, no stream caveat → add reader-visible caveat at each cross-year read-out.
- l.391-393/528 — "gotovo savršeno" validation claim with no mapping/precision/recall → show the date→event table or reframe as a spot-check.

**Major**
- l.257-259 + prose — computes rci/cli but never surfaces "RIK" to the reader → name and expand RIK once; label the conflict aesthetics canonically.
- l.264-268/441-449/510-536 — pervasive Latinate jargon-fog and stacked metaphors → plain Croatian, one metaphor per section.
- l.534/536/393 — promotional/speculative overreach ("prediktivno modeliranje", "u stvarnom vremenu", "optimalizaciju") → cut or demote to one measured future-work sentence.
- l.295 vs 321/391 — method note says "99. percentila" but code uses Z>3 SD → change l.295 to state the actual Z>3 rule.
- l.439-449/530 — "distinctive signatures" thesis built on one shown event (Uskrs) vs an unshown contrast class → add a controversial-event seismograph or soften to one illustrated case.
- l.508-520 — Stepinac frame-shift not conditioned on per-year corpus composition → add composition caveat (satisfied once the Critical stream caveat is applied here specifically).
- l.181 — base `tolower()` in theme scoring → `stri_trans_tolower()`.
- l.270-287/367-386 — metric grid holds only structural constants (no derived KPI); tables lack Izvor:/Napomena:; Z-score figures lack fig-cap → add ≥2 derived KPIs and captions.

**Minor**
- l.429/497 — legend "Prosječni sentiment" → "Prosječni tonalitet" (also in diskurs.qmd:515).
- l.348/359/368/374/443/399 — Title-Case parentheticals, unhyphenated "Z score", "Velikog Tjedna", bare year → normalize.
- l.393 — "Pride povorke" unglossed → gloss on first use.
- l.512 — "sps" read as SPC from a 3-char lemma → verify before interpreting or drop.
- l.84/99/136/140/217/226 — lilaHR loaded into nrc_lexicon_* vars → rename.
- l.161-178 — thematic dictionary inlined (backlog duplication) → extract to R/thematic_dictionaries.R.
- l.74-82/123-134/99-109/140-148 — dead/duplicated lexicon-prep blocks with divergent parsing (deleting the wrong one silently zeroes gold sentiment) → delete the dead first definitions, keep the read.delim2 '+'/'-' variant.

**Verdikt: FIX-FIRST**

### pages/mapa/evolucija.qmd (NEW / untracked)
**Critical**
- l.146/161/179-215/316-320 — "Prostor je narastao" reads x2,6 growth as real; MEMORY names this page → add collection-method caveat to Rast section, KPI card and synthesis.
- l.253-286/316-324 — "Utjecaj se rasprsuje" is a mechanical artifact of the 2024 backfill diluting top-10 share → add a collection caveat.

**Major**
- l.219-249/322 — "Migracija angažmana" over-rides its own hedge with "smjer je jasan" → soften to suggestive-not-established.
- l.44-49 — hard-coded bright palette with false "konzistentno s Mapom" comment → route through `dk_platform_colors`.
- l.161-162/320 — flagship growth KPI/synthesis lack the stream caveat → attach it to the card framing and synthesis line.
- l.171-175 — "Kako čitati ovu mapu" callout omits the single most important caveat (the ~2024 stream break) → add one sentence.
- `platform_monthly.rds` untracked + `R/03_aggregate.R` modified/uncommitted → commit the script and `git add` the aggregate (after disclosure check).

**Minor**
- l.174/245/249 — hand-typed "0 %" needs a non-breaking space; long doseg sentence could split.
- l.146/161-166/249/286/305-324 — several computed numbers (corpus_total, growth x2,6, actor x2,9, top-10 23,3%/55,8%, web share, peak/low months, new_entrants) verified correct — no numeric change needed (framing covered by the confound findings above).
- l.290-312 — liturgical-pulse attribution asserted, not separated from stream/platform composition → soften to a hypothesis.
- CLAUDE.local.md pipeline-notes now stale (says R/03_aggregate.R "does NOT exist"; aggregates now 710.307 with instagram/tiktok) → update the note.
- (positive checks) actor typology deliberately not invoked (no L1/L3 collision); 16-category scheme correctly deferred; ≥2-match framing correct.

**Verdikt: FIX-FIRST**

### pages/baza.qmd
**Major**
- l.169 — hkm.hr wrongly glossed as "Hrvatski katolički radio" (it is Hrvatska katolička mreža; HKR is separate) → correct or drop the gloss.
- l.281/304 — "jedanaest razina" for INFLUENCE_SCORE, which has 10 non-NA levels → "deset razina" (or compute inline).

**Minor**
- l.65/171 — "news-portala"/"news-mediji" Croglish → plain Croatian.
- l.60 — bare "baza" for the corpus → "korpus".
- l.30 — stale magic-number fallback 93L (file has 95) → 95L or fail loudly.
- l.214/236 — "backfill" un-glossed/un-italicized → gloss + italicize.
- l.95 — H2 "Što korpus NIJE" all-caps → sentence case.
- l.3 — subtitle "preko 710.000" hand-typed (truthful rounded figure; YAML cannot run R) → keep as deliberate round, confirm it doesn't drift.
- Numerous inline-computed claims (n_records 710.307, n_vars 47, date range, web share, n_platforms 9, stream counts, conf_pct/class_pct) verified data-driven and correct; page reads the master directly (not the aggregates), so aggregate staleness is irrelevant.
- l.341 — "16 tematskih kategorija" is a fixed cross-layer scheme constant, not a corpus figure (acceptable).

**Verdikt: FIX-FIRST**

### index.qmd (root homepage)
**Minor**
- l.116-117 — section-02 eyebrow and H2 verbatim identical → give the H2 an informative heading (as sections 01/03 do).
- l.91 — "≥2 matches" tech-tag pill pairs the operator with plain English "matches" → use a code-identifier-style token (e.g. "≥2").
- l.35/39/43/47/51/55 — six headline counts hardcoded HTML literals (correct today; drift risk) → drive from data/processed via inline `r`.
- (See navigation findings: hero CTA links and the stale `docs/index.html` redirect — Major, cross-page nav.)

**Verdikt: PUBLISH** (page content is sound; the linked nav/hero fixes are tracked under Konzistentnost.)

### pages/about.qmd
**Major**
- l.2-3 — subtitle "Ciljevi, doprinos i poziv na suradnju" duplicates the title "Ciljevi i doprinos projekta" → rewrite to add substance.

**Minor**
- l.58 — "otvorene znanosti" link points to a rot-prone third-party WordPress upload (resolves today) → repoint to a canonical open-science source/DOI.
- l.68/75 — "inovativnog"/"inovacije" self-praise → concrete grounded description.
- l.26 vs 73 — "(NLP)" gloss introduced on second use, not first → move gloss to l.26.
- l.10 — no computed scope sentence (≈size, year range) → add one inline `r` scope sentence.
- l.46-47 — "Big Data"/"Text Mining" English-only tag pills with existing Croatian equivalents in prose → Croatianize.

**Verdikt: PUBLISH**

### pages/schedule.qmd
**Major**
- l.56/90 — "tematskih cjelina" is the §5-rejected variant of Layer 2 → "tematskih struja".
- l.43/128 (also 57/78/91/112) — "baza podataka"/"baze" for the empirical object; canon reserves it for the published distribution product → use "korpus" for the corpus.

**Minor**
- l.9 — first body heading is H3 with no H2 (skipped level; sibling of year sections) → introduce an H2 spine.
- l.43 — in-site homepage link is an absolute GitHub Pages URL → relative path.
- l.20 — metric label "Godine" (paucal) vs §10 genitive-plural convention → "Godina" (or accept as intentional agreement with 3).

**Verdikt: FIX-FIRST**

### pages/news.qmd
**Minor**
- l.28/60 — "NLP" used without Croatian gloss on first use → gloss at l.28.
- l.8/15/72 — heading jumps H1→H3 (skips H2) → promote to H2/H3.
- l.67 — celebratory "!" off-register for a content page → remove.
- l.64 — "web scraping" un-italicized → italicize.
- l.68 — casual English "kick off" → drop the anglicism.
- l.44 — "24/7" slash-idiom (soft case) → plain Croatian "neprekidno".

**Verdikt: PUBLISH**

### pages/resources.qmd
**Major**
- l.106/115/129/143 — marketing superlatives ("najvažnija", "najveća", unverified "tisućama tutorijala") rejected by §2 → rewrite without superlatives/ranking claims.

**Minor**
- l.5 — YAML category "R & Python" uses ampersand → "R i Python".
- l.159/165/179/182 — English edition markers ("3rd edition"…) → Croatianize ("3. izdanje"…).
- l.46-94/115-146/156-198 — title–subtitle colons stripped throughout the bibliography → restore.
- l.40 vs 55 — "(NLP)" gloss on second use → move to first use (l.40).

**Verdikt: FIX-FIRST**

### pages/site-info.qmd (NEW / untracked)
**Major**
- l.37-42 — raw `sessionInfo()` wall, explicitly banned by §2 → replace with a curated styled summary (R/OS/locale/Quarto/pinned packages) or link to ENVIRONMENT.md/renv.lock.

**Minor**
- l.33 — sole body heading is H3 (skipped level) → promote to H2.
- l.8/12-27 — decorative Bootstrap icons lack aria-hidden; lead could name the site → add aria-hidden, optionally anchor with "DigiKat".

**Verdikt: FIX-FIRST**

### pages/studije/* (five stubs)
**Minor**
- All five are well-formed intentional "U pripremi" scaffold stubs (complete YAML, styled coming-soon callout, RQ, corpus slice, Status link) — the acceptable deliberate pattern, no action needed.
- self-help-youtube.qmd l.3 / demokrscanstvo.qmd l.3 — subtitles lean metaphorical ("zajedničkom sjecištu digitalnog diskursa") → optionally tighten to a plainer descriptor.

**Verdikt: PUBLISH**

## Konzistentnost (cross-page)

- **[Major]** Layer headcount contradiction: FOUR layers on index/baza/all four mapa pages vs "peta analitička mapa"/"pet mapa" on `evolucija.qmd`, which no other page links in to → pick one canonical count, update index (stats band and "kroz četiri… razine"), baza's layer list and the four mapa cross-links, stop calling Fokus na događaje the "zadnja" map, and add the layer to CLAUDE.md §4 controlled vocabulary.
- **[Major]** Conflict-index naming: RIK (canon) in diskurs prose, but RCI/CLI in diskurs labels/comments, and događaji never surfaces "RIK" to the reader (only "indeks konfliktnog jezika") → use RIK in all reader-visible chrome on both pages (expand once), keep rci/cli as code identifiers.
- **[Major]** Actor-typology naming/case: `mapa.qmd` panel titles Title Case ("Web Portali") vs its own lollipop sentence case ("Web portali"), and the four L1 archetypes introduced Croatian-only with no English gloss (§5 requires Giants/Community Builders/Megaphones/Specialists on first use) → normalize to sentence case and add the English gloss.
- **[Minor]** Corpus count is numerically consistent (~710k everywhere) but produced inconsistently: `mapa.qmd`/`mapa_stats.qmd` hardcode "710.000+" while `baza.qmd`/`evolucija.qmd` compute 710.307 → drive all four from an aggregate via inline `r` or align on one displayed form; also update the stale 610.000 exemplars in voice-and-style.md §7/§9.
- **[Minor]** Inline English glosses applied inconsistently: `mapa.qmd:69` "Doseg (reach)" vs plain "doseg" on baza/evolucija; "web scraping" italicized on some pages, not others → drop "(reach)", standardize italics for untranslatable terms site-wide (§4).
- **[Minor]** Religious-term count: `mapa_stats.qmd` card "70+" vs baza's computed ~95 (MEMORY: 95) → reconcile (compute, or relabel if the card actually refers to theme-dictionary stems).
- **[Minor]** Period labelling: index hero/stats present 2021.–2026. as the project span, conflating corpus coverage (2021.–2026., "2026. nepotpuna" on data pages) with the project timeline (2025.–2027., per schedule) → label 2021.–2026. as corpus coverage on index and add the "2026. nepotpuna" qualifier.
- **[Minor]** Platform count: index/mapa advertise "9 platformi" but `mapa.qmd` drops tiktok and factors 7 SOURCE_TYPE levels, while baza computes it → state the count consistently (analyzed subset per page, or footnote 9 as full inventory), preferring baza's computed approach.
- **[Minor]** Emotion-lexicon label: diskurs/događaji cards correctly say "lilaHR" but code/comments call it "NRC Leksikon Emocija"/nrc_lexicon_* → rename comments to lilaHR, use "8 emocija (lilaHR)" identically on both pages.
- **[Minor]** H1 pattern: `događaji.qmd` H1 lacks the "Name — descriptor (2021.–2026.)" appositive its four siblings carry; `mapa_stats.qmd` subtitle "Tematske struje u korpusu" duplicates the H1 layer name → add the em-dash descriptor to događaji and make the mapa_stats subtitle informative.

**Navigation (cross-page):**
- **[Critical]** `_quarto.yml:26-27` — "Pregled mapa" → `pages/mapa/index.qmd` (does not exist) → create the page or remove the entry before deploy.
- **[Major]** `index.qmd:24-25` — hero CTAs `baza.html`/`mapa/mapa.html` resolve to missing `docs/baza.html` → prefix with `pages/`.
- **[Major]** `docs/index.html` — stale 239-byte redirect to about.html → re-render so `index.qmd` regenerates it (fix by re-render, not hand-edit); remove orphaned `docs/pages/index.html`.
- **[Minor]** `evolucija.qmd` — in nav and links out to the four maps but has zero inbound links → add prose cross-links from at least mapa.qmd and događaji.qmd synthesis sections.
- **[Minor]** CLAUDE.md / quarto-verification.md §4 — stale note about empty `href: ""` studije stubs (all five now populated) → update the guidance, keep the "never introduce new empty hrefs" rule.

## Preporučeni sljedeći koraci

1. **Resolve the two navigation blockers first** (create/remove `pages/mapa/index.qmd`; fix the root `index.qmd` hero links) — these are the only defects that would visibly break the live site.
2. **Apply the collection-method (stream) caveat everywhere it is missing** — this is the single dominant theme: `evolucija.qmd` (Rast, concentration, callout, KPI/synthesis), `mapa.qmd`, `mapa_stats.qmd` and `događaji.qmd`. It is the highest-leverage fix for scientific defensibility.
3. **Fix the NLP measurement-validity defects** — boundary-anchor the theme scoring in mapa_stats/diskurs/događaji, lowercase lemmas before the događaji lexicon joins, and fix the mapa_stats wordcloud stoplist bug; then re-derive the affected figures.
4. **Correct the two factual/number errors on baza.qmd** (hkm.hr identity; "jedanaest"→"deset" razina) and the mapa_stats "70+" KPI.
5. **Commit the reproducibility fix** — commit `R/03_aggregate.R` and `git add data/processed/platform_monthly.rds` (after a disclosure/no-PII check) so evolucija's dependency is in the tracked aggregate layer.
6. **Resolve the site-wide consistency drift** — canonicalize the layer count (4 vs 5), RIK naming, the corpus-count compute path, actor-typology casing/glosses, and the platform/period labels; update CLAUDE.md §4 vocabulary, MEMORY, and the stale 610.000 exemplars in voice-and-style.md and CLAUDE.local.md.
7. **HARD GATE — before deploy:** run a full `quarto render` (overwrites `docs/`; requires user confirmation per the plan-first HARD GATE) and re-derive every numeric claim against freshly-rebuilt `data/processed/*.rds`, verifying Croatian diacritics, that figures rendered, and that no tracked aggregate was mutated as a render side-effect.
8. **Note the untracked/new pages:** `pages/mapa/evolucija.qmd` and `pages/site-info.qmd` (and `data/processed/platform_monthly.rds`) are new/untracked in git — they must be committed with their dependencies, and evolucija must clear its FIX-FIRST items (stream caveats, palette, tracking) before it is presented as a published fifth layer.

---

## Dodatak — Batch A primijenjen (2026-07-01)

**Repo changed mid-review.** During this session the repository was restructured underneath the review — almost certainly a Dropbox sync from the pipeline machine: `pages/index.qmd` was moved to a root `index.qmd`, `pages/mapa/index.qmd` (a maps-overview page) was added, and the `_quarto.yml` nav was rewired. Consequently the two "Critical" navigation findings were already resolved and needed no edit. **The Navigation / Konzistentnost sections above were assessed against the pre-restructure state and should be re-verified.**

Applied (source edits only — NOT yet render-verified; a full `quarto render` is a HARD GATE):

- **[resolved, no-op]** Nav "Pregled mapa" → `pages/mapa/index.qmd` now exists and is a valid overview page.
- **[resolved, no-op]** Root `index.qmd` hero CTAs already point to `pages/baza.html` / `pages/mapa/index.html`.
- **[fixed]** `baza.qmd:169` — hkm.hr gloss corrected to „Hrvatska katolička mreža" (was „Hrvatski katolički radio"; HKR/hkr.hr is a separate outlet).
- **[fixed]** `baza.qmd:281,304` — `INFLUENCE_SCORE` level count converted from the hardcoded word „jedanaest" to computed inline `` `r length(unique(na.omit(dta$INFLUENCE_SCORE)))` `` (both occurrences). **Could not render-verify:** reading the master `.rds` segfaulted twice (exit 139) on this machine — likely Dropbox mid-sync; verify master integrity before running the pipeline.
- **[fixed]** `mapa_stats.qmd:229` — wordcloud stoplist bug `!lemma %in% stop_words_hr` → `!lemma %in% all_stop_words$word` (the Croatian + religious stoplists were silently not applied). The wordcloud figure will change; needs render verification.
- **[fixed, assumption]** `mapa_stats.qmd:121` — KPI card „70+" → „95" religijskih pojmova (the label „Religijskih pojmova" maps to the 95-term corpus inclusion filter, not the page's thematic dictionary). Still hardcoded; ideally `` `r length(religious_terms)` ``. Confirm this is the intended referent.

### Batch B — stream-confound caveats (2026-07-01)

Added a consistent `::: {.callout-warning}` methodological caveat about the two-stream `data_source` collection change (~2024) to **all five** map pages, plus targeted inline hedges at the specific cross-year read-outs. Source edits only — **not render-verified** (HARD GATE); fence balance and diacritics checked statically.

- **`mapa.qmd`** — caveat callout after the metrics note; hedged the YouTube cross-year growth claim (l.204).
- **`mapa_stats.qmd`** — caveat in the „Vremenska dinamika tematskih kategorija" section, framed for topic *shares* (not volume).
- **`diskurs.qmd`** — caveat at the method note (l.187); notes that platform-stratification does not neutralize the collection change for the pooled RIK baselines.
- **`događaji.qmd`** — nuanced caveat after the KPI grid: the within-year Z-score peak-detection is robust to the change, but cross-year frequency comparisons (e.g. per-year Stepinac counts) are not.
- **`evolucija.qmd`** (most confounded) — caveat callout in the „Kako čitati ovu mapu" block + inline hedges on the total-growth claim, the top-10 dispersion claim (backfill mechanically injects actors → dilutes top-10 share), the synthesis, and softened the over-strong „smjer je jasan".

**Still open before deploy:** Batch C (NLP validity fixes + figure re-derivation), the HARD-GATE full render (also regenerates the stale `docs/index.html` redirect and removes any orphaned `docs/pages/index.html`), and committing `R/03_aggregate.R` + `data/processed/platform_monthly.rds`.
