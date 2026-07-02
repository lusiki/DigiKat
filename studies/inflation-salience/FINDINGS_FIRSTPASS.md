# First-pass findings — Inflation salience & CST framing

**Date:** 2026-06-30 · **Status:** FIRST PASS, exploratory · **Run:** R 4.4.1 against the master
(`data/merged_comprehensive.rds`, 710,307 × 47), read-only. **Lexicon UNVALIDATED** — all numbers provisional.
Artifacts in [output/](output/). Companion: [PROPOSAL.md](PROPOSAL.md) (this executes its §5 + §6).

> Bottom line: the proposal's §6 "absence" branch is the live outcome. **Catholic media barely cover
> inflation** (≈0.18% of their posts vs ≈1.34% for secular media in the same corpus — a ~7× gap), and the
> little they do is **charity-framed** (Caritas), not structural critique. Two design corrections below
> change *how* the paper must be framed.

> **DIRECTION CHOSEN 2026-06-30 — "broaden the unit."** The paper's unit is no longer the Catholic outlet
> but the **religion × inflation intersection** across the whole media space. See the new section
> **"Broadened unit"** at the bottom — that is now the live plan; the Catholic-outlet result above survives
> as a sub-finding.

---

## What was run
Tagged every post whose `TITLE`+`FULL_TEXT` matches an inflation lexicon anchored on
`inflacij* / poskup* / rast cijen* / trošak života / kupovna moć …` (deliberately **not** bare `cijena`,
to dodge the "price of salvation" trap). Then: monthly attention, outlet/platform/provenance breakdowns,
a rough structural-vs-charity framing split, and precision + recall eyeball checks.
Scripts: `scratchpad/0{0..4}_*.R` (ephemeral) → durable outputs in `output/`.

## Headline numbers (provisional)
- **8,105 inflation-tagged posts = 1.14% of the corpus**; date span **2021-01 → 2026-06**.
- **Catholic media: 0.18%** (217 / 120,512 posts, 371 outlets) vs **secular media: 1.34%** (7,888 / 589,795).
  → see `output/attention_catholic_vs_secular.png`, `summary_by_group.csv`.
- Catholic flagships: hkm.hr **0.27%**, glas-koncila.hr **0.88%**, laudato* **≈0.1%**, bitno.net **≈0.13%**,
  Radio Marija **0%**. The one elevated Catholic outlet is **caritas.hr (3.56%)** — the *charity* organ.
- Among inflation posts: **energy 68.9% ≫ food 34.4%** (consistent with the 2022 energy shock).
- Rough framing split (corpus-wide, secular-dominated — **not** yet a Catholic-media result):
  structural-any 38%, charity-any 21%, neither ~52%.

## §6 sanity checks
- **Check #1 (precision): PASS.** 18-context eyeball = genuine price-rise references; **zero** "price of
  salvation" false positives. Anchoring worked. (`output/fp_sample_60.csv` for the full hand-check.)
- **Check #2 (do they cover it at all): the "absence" is real and survives an adversarial recall probe.**
  A deliberately broad cost-of-living net raised the Catholic rate 14× (→2.6%), **but** the extra hits are
  almost entirely the homonym **`egzistencija`** (existential, theological) — *not* economic. After
  discarding it, genuine missed Catholic posts are few, and they are **Caritas paying utility bills**
  (charity framing). The gap is robust.

## Two design corrections (these change the paper)
1. **The corpus is NOT "Catholic media."** It is *religion-mentioning* posts across the whole Croatian
   media space, **dominated by secular outlets** (jutarnji, index, vecernji, slobodnadalmacija, crovijesti…).
   So "Catholic media" must be operationalized **by outlet (`FROM`)** — and that subset is small
   (~120k posts, ~217 inflation), which constrains the framing analysis. The proposal's "≈610k posts,
   already filtered to Catholic content" framing is inaccurate on both counts.
2. **`data_source` is a temporal batch marker, not a content split.** `original_dta` ≈ 2021–2024,
   `filtered_religious` ≈ 2024–2026 (same outlet mix in both). Any time trend pooled across the 2024 seam
   risks a composition artifact — control for outlet/batch.

## What this means for the RQ
The proposal asks *how* Catholic media frame inflation (structural vs charity). The data suggest the prior
question — *do they engage it at all?* — answers mostly **no**, and the residual engagement is charitable.
That is the publishable "absence/charity-over-justice" paper the proposal flagged in §6 — but it requires
re-centering the design on Catholic outlets and treating the secular field as the comparison baseline.

## Caveats / not-yet-done
- Lexicon unvalidated against a labelled gold set (only eyeballed). Some tagged posts are inflation
  **abroad** (Iran, US) — needs Croatian geo-scoping. Framing split is keyword-only (Caritas appears in
  both "Caritas in veritate" and the charity org).
- No HICP/price overlay yet (§5 figure is attention-only). Composition seam at 2024 not yet controlled.
- Framing not yet computed **on the Catholic subset alone** (the result that actually answers Q2).

## Suggested next steps
1. Build the §5 figure properly: overlay Croatian HICP (headline vs food/energy) on the **Catholic-outlet**
   attention line; control for outlet/batch.
2. Compute the structural-vs-charity split **on Catholic outlets only**, then hand-validate a sample.
3. Tighten the lexicon (drop `egzistencija`; add Croatian geo-scope) and validate on a labelled set via
   the `croatian-nlp-reviewer` agent; run `religion-media-domain-reviewer` on the framing interpretation.
4. Decide the paper's spine: "Catholic media's near-silence on the cost-of-living shock — charity over
   justice." Update PROPOSAL.md §1/§4 accordingly (and the 610k→710k / 2021–2026 facts).

---

# Broadened unit (CHOSEN DIRECTION) — first results

> **⚠️ TIGHTENED v2 (2026-06-30, supersedes the percentages in this section).** After cleaning 5 lexicon
> collisions (esp. **`gospodarstvo`="the economy" matching the Marian `Gospa` pattern**, plus
> `demonstracije`→demon, `kapitulira`→kapitul, `papir`→papa, `misao/misija`→misa) and adding a foreign-geo
> flag, genuine linkage fell **31.6% → 14.4%** (1,422 false links removed), foreign inflation = 31.6% of
> inflation posts, and the clean core is **858 DOMESTIC religion-linked posts (10.6%)**. Registers among
> those 858 (overlap): **clergy/Church 55%**, **everyday cost of religious life 41%**, **structural/CST 7%**,
> **charity 8%**. Artifacts: `output/*_v2.{csv,png}`, `linkage_coding_sheet_v2.csv`. The pre-tightening
> numbers below are kept only to show the size of the correction.

**Unit:** the **religion × inflation intersection** — posts where religion is salient (≥2-match corpus)
*and* inflation is discussed, wherever they occur. **RQ:** when inflation enters religion-salient Croatian
digital discourse, (a) is the link genuine or incidental, (b) who carries it, (c) in what register?
Religion side uses the project lexicon (`R/religious_terms.R`, 95 terms). Artifacts: `output/linkage_*`,
`output/modes_by_year.*`, `output/linkage_coding_sheet.csv` (per-post sheet for hand-coding).

## The pivotal measurement — genuine linkage vs incidental co-occurrence
Of **8,105** inflation posts in the religion corpus, only **2,558 (31.6%)** have a religious term **within
±150 chars** of the inflation mention (genuine linkage). **68.4% are incidental** — religion sits elsewhere
in a long article (politics, world news) unrelated to the price talk. *The raw co-occurrence count is not
the phenomenon; linkage must be measured.* (Eyeball confirms both classes; see `linkage_over_time.png`.)
> **Project-wide implication:** the ≥2-match religious filter yields heavy incidental co-mention, so ANY
> "religion and X" DigiKat sub-study faces this same linkage problem.

## Who carries it (linkage rate by outlet type)
Catholic **54.4%** (118/217) · Business **40.6%** (147/362) · Secular/other **30.5%** (2,293/7,526).
Catholic outlets link at the highest *rate* but tiny *volume*; **secular outlets carry ~90% of all genuine
religion×inflation discourse by count.**

## Register of religion invocation (among 2,558 linked; modes OVERLAP; detector noisy)
- **clergy / Church-as-institution 26.0%** — bishops, Pope, parishes, "the Church" near inflation (dominant).
- **devotional / everyday cost of religious life 17.9%** — e.g. *"poskupljuju mise"*, costlier Advent wreaths, pilgrimage fees up.
- **structural / CST critique 9.2%** — the justice frame (marginal).
- **charity / Caritas relief 4.2%** — smaller than expected.
- ⚠️ **A register the proposal never anticipated:** *religion/Church as an economic actor or affected entity*
  (mass stipends rising with inflation, parish heating bills, pilgrimage costs) — needs its own codebook category.
- ⚠️ Detector noise to fix before trusting mode %: `županija`→devotional, `papučar`→clergy(`pap`), metaphorical
  *"inflacijski"*, and **foreign** inflation (Iran/US) not geo-scoped.

## Temporal
Genuine-linkage volume tracks the shock: linkage *rate* peaks 2022 (39%, energy crisis) and the *count*
surges 2025–26 (654→709/yr). So even after stripping incidental noise, the religion×inflation signal is real
and shock-responsive.

## Refined next steps (this direction)
1. **Tighten the linkage detector** (drop `županija`/`papučar`/metaphor; geo-scope to Croatia) and re-run → clean linked set.
2. **Hand-validate** ~150 linked + 50 incidental from `linkage_coding_sheet.csv` → precision/recall on linkage + register (the methods backbone).
3. **Add the 5th register** ("Church as economic actor/affected") to the codebook.
4. **Actor map**: tie producers of genuine linkage to the project's actor typology (Giants/Community Builders/…).
5. **HICP overlay** on genuine-linkage monthly volume (does the *linked* discourse track real food/energy prices?).
6. **Reframe PROPOSAL.md** to the broadened unit; fix corpus facts (710k / religion-filtered-not-Catholic / 2021–2026).
7. **Review**: `croatian-nlp-reviewer` on the detector, `religion-media-domain-reviewer` on the register taxonomy.
