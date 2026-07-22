# Proposal — Moral voice or economic object? Mapping the religion–economy nexus in the Croatian digital media space

**Date:** 2026-07-06 · **Status:** proposal v2 — revised after a 5-critic adversarial review (domain · Croatian-NLP · R · numeric-verification · hostile-referee); Stage-0 probe v2 run on the master · **Owner:** L. Šikić
**Discipline tilt:** descriptive + two preregistered confirmatory endpoints — sociology of religion · communication studies · economic sociology · computational text analysis.
**House model:** the *measure-honestly-then-narrow* discipline of [`studies/inflation-salience/PROPOSAL_v2_broadened.md`](../inflation-salience/PROPOSAL_v2_broadened.md) and [`studies/catholic-education/PROPOSAL.md`](../catholic-education/PROPOSAL.md).
**Relation to the sister paper:** [`inflation-salience/PAPER_v1.md`](../inflation-salience/PAPER_v1.md) (*Costlier Candles, Quiet Prophets*) is the **depth** study — one indicator, fully validated. This is the **breadth** sequel: the whole macroeconomic domain and the comparative questions only breadth makes answerable. It reuses that paper's validated *pipeline*; it does **not** reuse its coded posts in any confirmatory test (§7, overlap disclosure).

> **Radni naslov (HR):** *Moralni glas ili ekonomski objekt? Religija i ekonomija u hrvatskom digitalnom
> medijskom prostoru (2021.–2026.).*

---

## 0. The two things that make or break this paper

Both are inherited lessons, restated here with the sister paper's **corrected** numbers (the adversarial
review caught this proposal quoting its superseded draft figures — fixed throughout):

1. **Co-occurrence is not engagement — and register coding is the weak joint.** In the sister study, only
   **45% of proximity-flagged religion×inflation candidates survived coding** (over half incidental); the
   naïve co-mention count overstated genuine engagement by **roughly an order of magnitude (~15×: 8,019
   candidates vs 520 coded core)**; and the tuned regex classifier hit a **precision ceiling ≈ 0.4** — a
   candidate generator, not a labeller. Crucially for *this* paper: the sister's easy coding axes reached
   IAA 0.97, but the **register axis — the one this paper lives on — reached only 0.84 in-sample / 0.46
   held-out**. So this design (a) reports registers only from a coded core, (b) re-validates the register
   codebook on a **human-adjudicated gold slice before preregistration**, and (c) pre-commits to reporting
   whatever the measured rollup-level agreement is (§6).
2. **Denominator honesty.** The corpus is *religion-salient posts across the whole media space* (≥2 distinct
   religious-term matches), not a Catholic-outlet archive and not an economy corpus. The unit of analysis is
   therefore the **religion–economy meeting place**, wherever it occurs. Whether within-confessional economy
   salience is measurable from this corpus is a **hypothesis, not an assumption**: the ≥2-match filter keys on
   post text, not outlet identity, so a Glas Koncila piece on pension reform with one religious term never
   enters. §6 specifies a **stream-matched recall audit** (archived 2022 month + current 2025/26 month, in
   liturgically contrasting seasons) that measures confessional recall per collection stream *before* any
   "Catholic media cover X" claim is made — and every such claim is bounded by the measured recall.

---

## 1. The idea in one paragraph

Between 2021 and 2026 Croatia lived through a compressed macroeconomic decade: post-COVID rebound, the
sharpest cost-of-living shock in a generation, an energy crisis, euro adoption (January 2023), a tight labour
market with record immigration of foreign workers, a housing-affordability crisis, and the EU's green
agenda. Catholic Social Teaching claims a voice in *all* of it — dignity of work, option for the poor, common
good, integral ecology. The sister study measured that voice for **one** indicator (inflation) and found it
nearly mute: religion met rising prices overwhelmingly as an **economic object** (the rising cost of
religious life; the Church as an institution in economic news, together ≈72% of the coded core), charity took
17%, and the structural-justice register was **3%**. But one indicator cannot say whether that is *the*
finding about the Church in the economy or an inflation-specific artifact — doctrine has always spoken the
language of work, wages, and the poor, not the language of price indices. This paper generalizes the design
to the **entire macroeconomic domain** — eleven economy domains from GDP aggregates to poverty and debt
enforcement (*ovrhe*) — and produces the first bird's-eye, validated map of *where in the economy religion
speaks, in what register, carried by whom, and on whose calendar*. The organizing question — **moral voice or
economic object?** — is answered by an exhaustive three-way register partition (justice · charity · object)
measured per domain, with the theoretically decisive quantity, the **structural-justice share**, as the
preregistered confirmatory endpoint.

---

## 2. The questions (two and a half, house format)

- **Q1 — The map (descriptive spine).** Across the eleven domains, how often does religion *genuinely* meet
  each one (windowed linkage, not co-occurrence), at what volume, on which platforms, and how did the mix
  move across 2021–2026 (within collection stream)? Q1's volume/time series are necessarily built from
  **auto-linked candidates**, so they are published only as **precision-corrected candidate counts**: per-
  domain × per-stream precision estimated from the hand-scan, applied as correction factors with uncertainty
  bands (§5 Stage C). Register claims never come from candidates — coded core only.
- **Q2 — Voice or object (the falsifiable core).** When religion genuinely meets an economic domain, in what
  register? Reported as an **exhaustive three-way partition + remainder**: **justice** (structural/CST
  critique) · **charity** (relief, episodic) · **object** (Church-as-institution + cost-of-religious-life),
  with devotional/other shown as the explicit remainder (~9% in the sister core), never silently dropped.
  Charity is **not** folded into "voice": the sister paper's own framework (Iyengar) classifies charity as
  *episodic* — the non-prophetic side — so the paper's title contrast is operationalized as
  **justice-vs-object**, with charity tracked separately as its own theoretically ambiguous register
  (institutional relief *and* moral practice). Inflation's known values (justice 3% · charity 17% · object
  ≈72%) are the **external benchmark**, not a data point in any test.
- **Q2½ — Who carries it, on whose calendar.** Which actors (confessional vs secular outlets — PI-owned
  *proposed* labels, all shares indicative; the project actor typology) carry each domain-register cell — and
  is there evidence that confessional economy-talk runs on the **liturgical calendar** while secular
  religion-economy talk runs on the **statistical calendar**? (Exploratory — see H3's identification limits.)

---

## 3. The decisive move — a domain × register grid with de-contaminated instruments

The eleven domains are **pre-ordered on an abstraction gradient**, and CST's doctrinal structure makes
directional predictions along it. What turns this from "more of the same, wider" into hypothesis tests is
the grid — plus two instrument-hygiene rules the adversarial review forced, which are themselves small
methods contributions:

**Rule 1 — register-neutral domain lexicons.** No CST/justice vocabulary (*dostojanstvo rada*, *radnička
prava*) and no charity-operations vocabulary (*banka hrane*, *pučka kuhinja*) may **define** domain
membership — otherwise posts are selected into tier C by the very words that will later code them as
justice/charity, and the gradient is confirmed by construction. Domain membership uses neutral economic
vocabulary only ([`probe.R`](probe.R) v2); registers are assigned exclusively by Stage-B coding.

**Rule 2 — religion-as-commentator vs religion-as-actor.** Caritas beside a food bank is one entity being
described, not religion in conversation with the economy. The linkage instrument therefore reports rates
**with and without** Caritas-type actor terms, Stage-B coding carries an explicit *actor/commentator* code,
and the H2 gradient must survive the actor-excluded measurement.

**The domain grid** (full regexes + homonym hazards in [`probe.R`](probe.R)):

| Tier | Domains | Character |
|---|---|---|
| **A — aggregates / system** | macro aggregates (GDP, recession, debt, deficit, monetary/fiscal) · euro changeover · taxes & fiscal · business & competitiveness | the economy as *system and statistic* |
| **B — sectoral / transitional** | green & energy transition · housing · economic demography (workforce, foreign workers — moralized natality discourse deliberately excluded) | the economy as *policy field* |
| **C — lived / person-level** | inflation & prices (sister anchors; benchmark only) · unemployment & labour market · wages & pensions · poverty, social care & debt enforcement | the economy as *lived experience* |

**The register codebook** is the sister paper's five-code scheme (institution · cost-of-religious-life ·
justice · charity · devotional) **plus** the actor/commentator code — inherited with its reliability stated
honestly (held-out register agreement 0.46; the paper's weakest measurement) and **re-validated on a
human-adjudicated gold slice before prereg**, with agreement reported at both the 5-way and the 3-way
(justice/charity/object) level. Two cheap lexical add-ons: an **encyclical/document probe** (*Rerum novarum*
→ *Fratelli tutti*) counting doctrinal anchoring in economic contexts, and **KSN-principle sub-codes** inside
the justice register (solidarity, subsidiarity, common good, option for the poor, dignity of work).

### Hypotheses (one operationalization and one estimand each)

- **H1 — Justice gradient (primary confirmatory; preregister).** The **structural-justice share** of
  genuinely-linked religion–economy discourse rises along A → C and is highest in the work/poverty domains —
  because CST's economic doctrine is person- and work-centred (*Rerum novarum* → *Laborem exercens*), not
  aggregate-centred. *Test:* justice share by tier on the coded core, ordinal trend (Jonckheere–Terpstra),
  **non-inflation domains only** (inflation = external benchmark); per-domain minimum coded-cell floor
  pre-declared after Stage A, below which a domain reports descriptively and exits the test. *Both outcomes
  are informative:* justice ≈ 3% everywhere = the strong mediatization result (the prophetic voice is absent
  from the digital public sphere, full stop); a real gradient = doctrine speaks where it always spoke.
- **H2 — Abstraction gradient in linkage (exploratory, revised — Stage-0 v2 disconfirms the simple form).**
  Original prediction: the genuine-linkage *rate* of a domain's mentions rises A → C. **Stage-0 v2 does not
  support this even as a hypothesis-generating pattern:** linkage is flat (0.17–0.32, overlapping CIs) across
  ten of eleven domains regardless of tier, and the one clear outlier — `poverty_social` at 0.62 — is not a
  tier effect but an unexplained domain-specific one (§5) that survives Caritas-exclusion and needs its own
  hand-pass before it can be interpreted. H2 is retained as a **disclosed-null exploratory test** on
  Stage-A's full, precision-corrected data (not a "hint" motivating the design); if the flat pattern
  replicates at full scale, the paper reports "linkage does not vary systematically by abstraction tier" as
  a finding in its own right rather than searching for a gradient that Stage-0 did not show.
- **H3 — Two calendars (exploratory; demoted by design).** Confessional economy-talk shows recurring
  liturgical-calendar peaks; secular religion-economy talk couples to the macro-news calendar. Named
  identification obstacles: (a) the religion filter itself censors non-liturgically-framed confessional
  economy items, partly *manufacturing* liturgical coupling — the §6 audit therefore uses liturgically
  contrasting months to bound seasonal selection; (b) several anchor events are collinear with the secular
  calendar (1 May = Workers' Day; Advent = budget/consumption season), so the event set is restricted to
  events without a secular twin (e.g. Lent onset, World Day of the Poor where separable); (c) within-stream
  confessional monthly cells may be too thin — a cell-size gate after Stage A decides whether H3 is reported
  as a test or as a descriptive illustration. It stays out of the title unless it survives all three.
- **H4 — Crisis moralization (secondary confirmatory; preregister).** In acute shock windows (2022
  energy/price peak; January 2023 euro changeover — within the 2021–24 stream), the **justice share** of
  linked discourse rises relative to adjacent calm windows. *Test:* justice share, shock vs calm, χ² on the
  coded core, **non-inflation domains only** (the sister's coded inflation posts are held out entirely — its
  2022 peak was in overall linkage *volume*; whether register mix shifted is untested and is exactly what H4
  asks). Preregistered before Stage-B coding; the Stage-0 probe measured volumes and linkage only, never
  registers, so the confirmatory endpoints are genuinely unseen.

No causal machinery — the discipline card's descriptive tilt holds; trend and contingency statistics on coded
data, in the tradition the sister paper established (its §2.4).

---

## 4. Data (we already have it)

- **Corpus:** the DigiKat master — **710,307** posts × 47 vars, **2021-01 → 2026-06**, Croatian/Bosnian,
  religion-filtered (≥2 distinct matches, `R/religious_terms.R`). Religion-salient posts across the whole
  media space; platform mix of the full corpus: **web ≈ 74%, Facebook ≈ 13%, YouTube ≈ 9%**, minor others
  (from `data/processed/platform_summary.rds`; the sister paper's oft-quoted 96% web figure describes its
  520-post inflation core, not the corpus). `data_source` is a **temporal batch marker** (monitoring query
  ≈2021–24 · filter backfill ≈2024–26) — conditioned on in every temporal analysis, never compared across.
  Benchmark for coupling analyses: the sister paper's HICP correlation is **r ≈ 0.73 within the clean
  2021–24 stream** (batch-pooled it attenuates to 0.63).
- **Slice:** the union of the eleven economy-domain tags (Stage-0 v2 measured — §5) → windowed-linkage
  candidates → coded core. Study-local probe; the global ≥2-match filter is untouched.
- **Fields:** `FULL_TEXT` (tagging + windows), `DATE` (calendars), `FROM` + `resources/dictionaries/
  source_labels.csv` (confessional/secular — *proposed*, PI-owned, indicative), `SOURCE_TYPE` (actor
  typology), engagement fields (reach, secondary), sentiment layer (affect, secondary, with lexicon-coverage
  % reported).
- **External series (public):** Croatian HICP monthly incl. food/energy (Eurostat); registered unemployment
  (HZZ/DZS); consumer confidence (HNB/EC); a **liturgical/ecclesial event calendar 2021–2026** constructed
  once and committed as a sourced CSV.

---

## 5. What we actually do — five stages

**Stage 0 — Feasibility probe v2 (✅ run 2026-07-06, after lexicon de-contamination — [`probe.R`](probe.R)).**
Recall-first tagging of the master; per domain: volume, share, by-year/month × stream, overlap, confessional
composition, and sampled ±220-char windowed linkage (Wilson CIs; with/without Caritas; per stream).

> **STAGE-0 v2 RESULTS (`output/domains_summary.csv`, n=710,307; sampled linkage n=1,200/domain, Wilson 95% CI):**
>
> | domain | tier | n | % corpus | linked (95% CI) | linked, ex-Caritas | conf. share |
> |---|---|---|---|---|---|---|
> | macro_aggregates | A | 31,604 | 4.45 | 0.207 [.185–.230] | 0.205 | 0.11 |
> | euro_changeover | A | 2,069 | 0.29 | 0.197 [.175–.220] | 0.195 | 0.11 |
> | taxes_fiscal | A | 15,066 | 2.12 | 0.255 [.231–.280] | 0.243 | 0.15 |
> | business_comp | A | 65,068 | 9.16 | 0.315 [.289–.342] | 0.312 | 0.19 |
> | green_energy | B | 11,854 | 1.67 | 0.284 [.259–.310] | 0.283 | 0.16 |
> | housing | B | 18,727 | 2.64 | 0.285 [.260–.311] | 0.274 | 0.17 |
> | demography_econ | B | 6,038 | 0.85 | 0.213 [.191–.237] | 0.208 | 0.18 |
> | inflation_prices | C | 8,478 | 1.19 | 0.171 [.151–.193] | 0.168 | 0.08 |
> | unemployment | C | 22,150 | 3.12 | 0.263 [.239–.289] | 0.259 | 0.29 |
> | wages_income | C | 14,544 | 2.05 | 0.282 [.257–.308] | 0.278 | 0.18 |
> | poverty_social | C | 61,857 | 8.71 | **0.618 [.590–.645]** | **0.611** | **0.60** |
>
> **Any-domain posts: 166,021 (23.4% of the corpus).** Inflation candidates (8,478) sit close to the
> sister paper's 8,105 — a sanity check the pipelines are comparable despite the widened window.
>
> **Two honest findings, not smoothed over:**
> 1. **No clean A→C monotonic gradient.** Linkage ranges narrowly (0.17–0.32) across ten of the eleven
>    domains with heavily overlapping CIs — tier does not obviously order linkage. **H2 is not supported
>    even as a hypothesis-generating pattern** on this evidence; it stays in the design as a stated,
>    disclosed-null exploratory test on the corrected Stage-A data, not as a "hint" the paper leans on.
> 2. **`poverty_social` is a genuine outlier, and Rule 2 (actor/commentator separation) only partly
>    explains it.** Linkage is 0.62 (vs 0.17–0.32 elsewhere) and its confessional share is 0.60 — also a
>    stark outlier (all others sit at 0.11–0.29). Excluding Caritas from the religion probe barely moves it
>    (0.611 vs 0.618), so this is **not simply the Caritas-actor artifact** the review flagged — something
>    else in the domain (candidates: `siromaš*` catching devotional/spiritual-poverty language even after
>    the v2 anchoring; `beskućni`/`ovrh*` co-occurring with parish charitable-outreach reporting that
>    mentions religion structurally, not incidentally) is driving both the linkage rate and the
>    confessional skew. **This domain cannot enter Stage B until its 1,200 sampled candidates get a hand
>    pass** to determine which mechanism is operating — reported as a named pre-Stage-A task, not deferred
>    silently into the coding budget.

**Stage A — Full tagging + linkage (computational).** Freeze the lexicon after a `croatian-nlp-reviewer`
audit; tag the full corpus; compute windowed linkage for **all** matched posts using the **validated sister
machinery** (tightened 95-term religion lexicon, ±220 window, inflation metaphor guard); flag foreign-country
economics for set-aside. Then the two budget gates: (i) per-domain hand-scan → precision estimates (feeds Q1
correction + H2); (ii) the **coding budget + MDE analysis** — expected coded-n per domain and the minimum
detectable trend under the measured register reliability, published *before* prereg; domains below floor are
pre-assigned to descriptive-only reporting.

**Stage B — Validated coding (the paper's measured core).** *Register-codebook gold-slice re-validation, then
OSF prereg of H1 + H4, then coding.* Three independent annotators (validated LLM workflow, human double-codes
a slice; report IAA at 5-way and 3-way levels, plus the incidental-co-mention rate) on: genuine/incidental ·
domestic/foreign · register · actor/commentator · KSN-principle sub-codes · encyclical references. If the
pool exceeds capacity, stratify by domain × stream × outlet-type (pre-declared).

**Stage C — The comparative analyses.** Domain × register grid (Q2, H1); corrected linkage gradient (H2);
precision-corrected candidate time series with uncertainty bands (Q1); within-stream, within-subsample series
vs HICP/unemployment and the liturgical calendar (Q2½, H3 — subject to its gates); shock-window contrasts
(H4); actor-typology decomposition; affect as a supporting layer.

**Stage D — Close reading.** Qualitative pass over the justice-register posts (imported papal voice vs
domestic?; the sister found justice often foreign) and the sharpest justice-vs-object contrast pairs — the
qualitative arm of the motivating sketch (§12), feasible because the pipeline narrows.

---

## 6. Honesty checks (inherited + new; non-negotiable)

- ⬜ **Co-occurrence ≠ engagement** — registers only from the coded core; volume series only as
  precision-corrected candidate counts, labelled as such (the 45%-survival / ~15× lesson).
- ⬜ **Register reliability stated and re-measured.** Inherited held-out register agreement is **0.46** — the
  design's weakest link, named as such; gold-slice re-validation before prereg; report 5-way and 3-way
  agreement; confirmatory endpoints run at the level that proves reliable, pre-declared.
- ⬜ **Lexicon–codebook decoupling** (Rule 1) and **actor/commentator separation** (Rule 2) — the two
  circularity guards; H1/H2 results must survive them.
- ⬜ **Homonym audit before any number is public.** Hazards documented in `probe.R` v2 (deficit, gospodarstv/
  OPG, tečajn, tvrtk, nekretnin, spiritual *siromaštvo*, *otpuštanje grijeha* guard, euro anchoring, no bare
  *plać\** forms after the *plače* catch); `croatian-nlp-reviewer` audits the frozen lexicon; per-domain
  precision from the hand-scan reported.
- ⬜ **Regex is a candidate generator (~0.4 precision ceiling)** — no auto-label result is published.
- ⬜ **Batch confound:** every temporal statement conditioned on `data_source`; the 2022–23 shock cluster and
  H4 live inside the 2021–24 stream.
- ⬜ **Stream-matched confessional-recall audit** (upgraded per review): one **archived 2022 month** (IKA /
  Glas Koncila web archives) audited against the 2021–24 stream AND one **2025/26 month** against the current
  stream; two liturgically contrasting months (Advent vs Ordinary Time) to bound seasonal selection (feeds
  H3); minimum usable item count pre-committed; every within-confessional salience claim scoped to the
  stream whose recall was measured.
- ⬜ **Outlet labels are PI-owned and *proposed*** — shares indicative; sensitivity with/without unlabeled.
- ⬜ **Multiple tests disciplined:** H1/H4 preregistered with named tests and cell floors; H2/H3 explicitly
  exploratory; no silent promotion.
- ⬜ **Overlap disclosure (anti-salami):** the paper states exactly what it shares with the sister paper
  (corpus, pipeline, codebook) and what it does not (no sister-coded posts in any confirmatory test;
  inflation as external benchmark only), in a dedicated data-availability/disclosure paragraph.
- ⬜ **Croatian encoding integrity** end-to-end; **no master mutation** — the study writes only to
  `studies/moral-economy/output/`.

---

## 7. Why this is publishable (and where it could fail)

1. **Substantive:** the first validated, whole-mediasphere map of the religion–economy nexus for any
   European mediasphere — answering, with measured linkage, *where the Church's economic voice actually
   lives* in the digital public sphere. The sister paper documents one cell and raises exactly this
   question; the differentiation is theoretical, not just additive: this paper is a **test of
   mediatization-of-religion theory** (Hjarvard) — does the digital mediasphere admit religion into economic
   discourse only as object/news-event, never as prophetic commentator? — with CST's self-description as the
   competing prediction.
2. **Theoretical:** the **justice-vs-object contrast** operationalizes that debate on an exhaustive register
   partition, and the **two-calendars idea** (even as exploratory description) gives the mediatization
   argument a temporal signature; both constructs transfer to any religion×domain corpus study
   (religion×climate, religion×migration).
3. **Methodological:** instrument hygiene for keyword-built designs — register-neutral domain lexicons,
   actor/commentator separation, precision-corrected candidate series, and a stream-matched recall audit for
   topical (filtered) corpora. Each answers a failure the sister study measured or this review caught;
   together they are a citable checklist for "religion and X" corpus studies.

**Failure modes, named:** (a) coded cells too thin per domain → pre-declared tier-level fallback (grid
degrades gracefully to 3×3, still a paper); (b) justice ≈ 3% everywhere, flat → that *is* the strong
mediatization finding, publishable with the prior named up front; (c) register reliability fails the gold
slice at the 5-way level → confirmatory endpoints shift to the 3-way level or, at worst, to
justice-vs-everything-else (binary), pre-declared in that order; (d) coding budget — gated before prereg,
with per-domain floors deciding the grid's resolution honestly.

## 8. Venue

- **EN:** *Journal of Media and Religion* (natural sequel venue) · *Social Compass* · *Journal for the
  Scientific Study of Religion* · *New Media & Society* (if the mediatization/method angle leads).
- **HR:** *Društvena istraživanja* · *Medijska istraživanja* · *Nova prisutnost*.

## 9. Working title (options)

1. *Moral voice or economic object? Mapping the religion–economy nexus in the Croatian digital media space, 2021–2026.*
2. *Where the Church talks money: domains and registers of religious economic discourse in Croatia.*
3. HR: *Moralni glas ili ekonomski objekt? Religija i ekonomija u hrvatskom digitalnom medijskom prostoru (2021.–2026.).*
   (The "two calendars" phrase stays out of the title unless H3 survives its §3 gates.)

## 10. Theoretical anchors (to harden via `/lit-review`)

Inherited, already mapped ([`inflation-salience/LITERATURE.md`](../inflation-salience/LITERATURE.md)):
inflation-salience/agenda-setting · CST economic framing (Iyengar episodic/thematic) · Croatian Catholic
media. **New strands to map:** mediatization of religion (Hjarvard; Hoover) — the paper's lead frame ·
economic sociology of moralized markets (Thompson's moral economy; Fourcade & Healy) · sociology of religious
time (Zerubavel; liturgical calendars) for H3 · religion-and-economy coverage in other national corpora (gap
check). → run `/lit-review` with these four queries.

## 11. Next steps (in order)

1. **Stage-0 v2 numbers are in** (§5); no domain fell below the 500-candidate merge floor (smallest is
   `euro_changeover` at 2,069) — the eleven-domain grid stands as designed.
2. **Hand-pass `poverty_social`'s 1,200 sampled candidates FIRST**, before anything else below — its
   linkage rate (0.62) and confessional share (0.60) are outliers unexplained by the Caritas-actor
   exclusion already applied, and no interpretation of H1/H2 is trustworthy while this domain's behavior is
   unknown. Output: a named mechanism (spiritual-poverty false positives? parish-outreach reporting that is
   genuinely religion-linked? something else?) and, if warranted, a further lexicon fix — logged as a v3
   change, not folded silently into v2.
3. `croatian-nlp-reviewer` audit of the frozen v2 lexicon (informed by the poverty hand-pass); fix; freeze.
4. `/lit-review` (§10 queries) — in parallel.
5. **Stage A** full run with the validated linkage machinery → hand-scan precision estimates → coding budget
   + MDE → **gold-slice register re-validation** → **OSF prereg (H1, H4)** → Stage B.
6. Register the study in the site nav only when there is a page to publish.

---

## 12. Mapping to the motivating draft (co-author sketch, 2026-07)

The sketch ("Ekonomija u katoličkom medijskom prostoru", 2015–2025, six Catholic outlets, manual
mixed-methods coding) survives here as follows — every goal kept, each re-grounded in what the corpus can
honestly support:

| Sketch element | This proposal |
|---|---|
| Frequency of economic themes in Catholic media, 2015–2025 | Q1 map, 2021–2026 (corpus coverage; within-stream); within-confessional salience claims gated by the §6 stream-matched recall audit |
| Unit = six named Catholic outlets | Unit = the religion–economy nexus in the whole mediasphere, with confessional/secular decomposition. The sister study's validated core found secular outlets carry 85% of genuine religion–inflation discourse (Catholic 14%) — an outlet-first design would study the 14% and miss the 85%. (Its unvalidated first-pass also suggested Catholic outlets rarely mention inflation at all — ~0.2% of their posts — provisional, superseded, but directionally why the unit was broadened.) |
| Macro-indicator inventory (GDP, inflation, unemployment, debt…) | Tier A + C domains; indicator *interpretation* via registers; indicator *coupling* via the Q2½/H3 series |
| Normative stance (support/critique/reform) | The register codebook + actor/commentator code, with measured IAA and a gold-slice re-validation — stance coding with known reliability instead of ad-hoc categories |
| Framing (neoliberalism critique, integral ecology, demography…) | Register × domain grid; green transition and economic demography are their own domains |
| Comparison with KSN documents (encyclicals) | Encyclical/document probe — direct counts of doctrinal anchoring in economic contexts, by domain and outlet type |
| Braun & Clarke thematic analysis / CDA | Stage D close reading of the coded core |
| 2015–2025 window | Not supported by the corpus (2021–2026); pre-2021 needs a separate archive build — out of scope for paper 1, noted as an extension |
