# Research brainstorm — Inflation salience & the preferential option for the poor in Catholic media

**Status:** scoping note, formalized via `/research-ideation` (five-agent panel, 2026-06-29). Not yet a plan or a study.
**Date:** 2026-06-29 (rev. 2 — panel synthesis folded in; supersedes rev. 1)
**Context:** Computational (text-as-data) spin-off from the proposed mixed-methods study *"Ekonomija u
katoličkom medijskom prostoru"* (frequency + framing + KSN alignment of economic themes). This note
develops **one** of several economic spin-off ideas: turning the corpus into a **media-attention index**
and testing what drives inflation coverage — the headline number, or its incidence on the poor.
**Corpus:** DigiKat master — ≈610k posts, 2021–2025, religious-term-filtered (≥2 distinct matches).
**Sibling note:** [[welfare-state-catholic-media-brainstorm]] (same corpus, welfare-state angle).

> rev. 2 folds in the `/research-ideation` panel (theorist · methodologist · domain-expert · journal-editor ·
> devil's-advocate). **Headline change: the design is sound as a *descriptive* study but the original
> "measurable fingerprint of CST" framing is two sizes too big for the data — all five panelists converge
> on this.** Consensus ≈5/10 as originally written, a clear 7/10 reframed. §8–§11 are new and binding;
> §1–§7 are kept but now read THROUGH §8. Where the old text conflicts with §8, §8 wins.

---

## 0. Where this sits among the economic spin-offs

The base proposal is **one descriptive paper** (frequency + interpretation + CST/KSN alignment). The
spin-offs that read as *economics* rather than content analysis each add one of: an **external benchmark**
(real macro data), an **identifying event**, or a **constructed index**. Five were brainstormed:

1. **Moral-economy attention index — does Catholic media track inflation, or the poor?** ← *this note*
2. Euro-adoption (1 Jan 2023) event study.
3. "Economized vs. moralized demography."
4. A "Catholic economic-anxiety index" from the emotion lexicons.
5. Diffusion of the papal economic frame ("ova ekonomija ubija").

(Shared asset across all five: a reusable **CST / KSN economic-principle classifier** — build once.)

---

## 1. The spine: one sharp, falsifiable contrast

> ⚠️ **rev. 2 — read this section through §8.1.** The contrast below is the right *operationalization*,
> but the inference from the conditional coefficient to CST is **not licensed on its own** (it is consistent
> with ≥5 non-CST stories — see §8.1). The spine is kept, but it is no longer the *headline*: the headline
> moves to the descriptive index + the framing contrast + the secular differential (§8.2).

Everything hangs on a single test. Coverage of inflation could be driven by:

- **H_macro** — the **headline** CPI number (they cover inflation because it is "the news"); or
- **H_poor** — the **regressive incidence** (they cover it because *food + energy* — the components that
  eat a poor household's budget — are what spiked), consistent with the *preferencijalna opcija za
  siromašne* frame.

The contrast is, at its core: **does food/energy inflation still predict coverage *after* conditioning on
headline CPI?** A positive conditional partial association is *suggestive* of a CST orientation in attention
allocation — **but only as a Catholic *differential* against a secular benchmark** (§8.2), never as a level.

---

## 2. Three versions, escalating ambition (pick the altitude)

> ⚠️ **rev. 2 reorders the altitudes.** The panel's verdict: **Version A (descriptive index) is the spine
> of the paper, not the "minimum viable" fallback. Version C (secular comparison) is NOT the "most
> ambitious" optional extra — it is the load-bearing element that makes the CST claim falsifiable at all
> (it defuses two of the three fatal objections at once, §8.2).** So the publishable paper is **A + the
> secular benchmark from C + the framing DV promoted to co-primary**; Version B's conditional coefficient
> is demoted to a pre-registered, parsimonious *secondary* analysis (§9).

### Version A — descriptive index (this is the SPINE, not the floor)
Monthly economy-coverage **share** vs. Croatian CPI YoY, plotted with the euro/war/energy events marked,
plus a cross-correlation. Decompose: coverage vs. food/energy CPI separately. Report the partial
correlation of food/energy controlling for headline as a *description*, with honest CIs. Lead with a clean
co-movement figure — more persuasive and more robust than a t-statistic on ~50 points.

### Version B — the conditional coefficient (DEMOTED to secondary; see §9 for why)
Poisson on monthly counts (log total religious posts as **exposure offset**) *or* OLS on shares.
RHS: headline CPI YoY, **food+energy CPI YoY**, unemployment, ECFIN perceptions, Google Trends, a
**war/energy-shock control**, post-euro dummy, **parsimonious seasonal control (NOT 11 month FE)**.
The food/energy coefficient conditional on headline is *not* the money result any more — at ~50 points with
collinear regressors it is likely **not identified** (§9). Report it as a pre-registered specification curve,
not a single headline number.

### Version C — secular comparison (NOW MANDATORY, not optional)
A matched set of *secular* Croatian outlets, same regression. **The CST claim lives in the
Catholic-minus-secular *difference*, not in the Catholic level.** Because the corpus is the ecosystem
filtered to religious terms, the honest comparison is "religious-themed economic content in Catholic vs.
secular outlets" — the `FROM` column identifies outlets (see [[welfare-state-catholic-media-brainstorm]]
§6.2). Comparability of the control group is the main referee target — scope it carefully, but it is no
longer skippable: without it the mechanism claim is unfalsifiable (war hit both fields, so only a Catholic
*excess* survives the war confound by construction).

---

## 3. Shared building blocks (same for all three)

- **DV as a *share*, not a count.** Total media volume grows over the window, so raw counts trend up
  mechanically. Use economy-posts ÷ all-religious-posts per month (or Poisson with the exposure offset).
  **rev. 2:** report numerator AND denominator series separately — a rising share can be a *shrinking
  denominator* (platform/scraper-coverage drift), not rising inflation coverage (§8, devil's-advocate minor).
- **Inflation sub-dictionary** off the existing codebook: *inflacija, poskupljenje, rast/skok cijena,
  troškovi života, cijene, …*. **rev. 2 — this is now a GATING task (§10):** match on **lemmas, not raw
  substrings**, require multi-term co-occurrence (e.g. `inflacija` OR (`cijene` near `rast/skuplje/poskupljenje`))
  to suppress metaphorical/homiletic *cijena/vrijednost* ("po svaku cijenu", "cijena spasenja"), and
  hand-validate the **false-positive rate on ~200–300 hits with a split-by-year check** (a drifting FP rate
  silently biases the DV trend).
- **Benchmark series (all public, monthly, free):**
  - DZS / Eurostat **HICP** — headline **and** the food and energy sub-indices (these *are* the incidence
    measure);
  - HZZ / Eurostat **unemployment**;
  - DG ECFIN Consumer Survey **inflation perceptions** (a "subjective inflation" series — a strong third
    RHS, and the discriminating control: secular salience should load on perceptions/Trends, CST attention
    on incidence even when perceptions are flat — §8.1, theorist);
  - **Google Trends "inflacija"** as a public-attention benchmark;
  - **rev. 2 — add an energy-shock / war control** (gas/electricity wholesale index, or a Feb-2022
    war-period spline) — food/energy CPI is near-collinear with the war and energy crisis (§8.3).
- **Lead-lag is its own mini-result — but treat it as DESCRIPTIVE.** Does Catholic media track the *data*
  (CPI) or *public attention* (Google Trends)? If it tracks attention more than data, it is a **resonance**
  medium, not an **agenda-setter**. **rev. 2:** at ~50 autocorrelated points a CCF is near-uninterpretable
  and will show spurious peaks from shared trend; pre-whiten, restrict to ONE pre-specified lag (lag 0 on
  the release calendar), present as a cross-correlogram with CIs and disclaim causal direction; do not
  headline it. The defensible prior for a niche confessional medium is *resonance* — finding *leadership*
  would be the surprising, publishable result, so state the directional prior up front.
- **Timing gotcha:** CPI for month *t* is released mid-*t+1*. Align coverage to the **release calendar**,
  not the reference month, or the response is mis-dated. *(Panel: keep this and say so in Methods — it is a
  credibility signal most submissions get wrong.)*

---

## 4. Feasibility within DigiKat

- **Count on the full corpus; CENSUS (do not sub-sample) the inflation slice for the framing DV.** Dictionary
  tagging is cheap regex-on-lemmas → tag *all* posts for the attention DV (DV1). **rev. 2 — the original
  "reserve the 2–5% stratified sample for the framing DV" is WRONG and is overridden:** the global 2–5%
  sample is sized for corpus-wide themes, so a food/energy-conditional sub-shift *inside* an already-thin
  inflation slice lands at single-digit monthly counts — far too few to estimate a monthly framing share.
  Because DV1 is recall-first, the inflation slice is small enough to **label fully or near-fully**. State
  this explicitly so a reviewer doesn't think the index OR the framing DV was sampled. If counts are still
  too thin for monthly DV2, demote DV2 to a **two-regime contrast** (pre/post the 2022 food/energy spike).
- **Every identifying event is inside 2021–2025** (inflation shock 2022–23, euro Jan 2023, energy crisis,
  war Feb 2022) → **no 2015–2020 backfill needed** for this paper. (Note: the base proposal says
  2015–2025; the master is 2021–2025. The backfill serves the long-run *frequency* story, not these
  event-leveraged designs.)
- **Environment:** needs R + the master `.rds`. Run on the pipeline machine (`CLAUDE.local.md` →
  `R_AVAILABLE`); otherwise emit the script and hand off. Use `/data-analysis` (sample-first).

---

## 5. Honest caveats to pre-empt

- **Short series:** ~48–60 monthly points is thin for a lagged VAR. Stay parsimonious; buy power from the
  **component decomposition** and from **outlet cross-section** (Glas Koncila vs. Bitno.net vs. IKA), not
  from long lag structures.
- **df budget (rev. 2, the load-bearing methods point):** ~50 points against headline + its own food/energy
  subcomponents + unemployment + perceptions + Trends + 11 month-FE ≈ 18 collinear parameters → the
  conditional coefficient is the *worst-identified* quantity in the system (regressing a variable on its own
  parts). **Fixes:** drop month FE for harmonic/quarter seasonality (recover ~8 df); residualize food/energy
  on headline rather than entering both; pre-commit ONE specification and report a specification curve; HAC
  (Newey-West) SEs throughout; report VIFs / condition number.
- **Collinearity:** food/energy inflation, the energy crisis, and the Feb-2022 war all co-move —
  "preferential-option attention" cannot be separated from "war shock" by timing alone. The **secular
  comparison** (§2 Version C) is the strongest defense (war hit both fields → a Catholic *excess* survives);
  back it with the **framing DV** (within-post language) and the explicit energy/war control.
- **Stance/frame ≠ sentiment.** The distributional-frame DV is a classification target (dictionary-for-recall
  + LLM/human-for-precision, validated against a gold set), **not** a CroSentilex valence proxy. **rev. 2 —
  but pair it with the Atmosfera-diskursa sentiment/conflict layer** to show the distributional framing is
  *compassion*-valenced (solidarity) rather than *conflict*-valenced (blame) — see §8.1 / §8.4.

---

## 6. Working title

> ⚠️ **rev. 2 — retitle away from "fingerprint."** "Fingerprints uniquely identify"; a conditional
> coefficient consistent with five other stories is the opposite. The old title below reads as physics-envy
> and hands a referee a free kill-shot — it is **superseded by §8.5**.

~~*"Inflation for whom? Macroeconomic salience and the preferential option for the poor in Croatian
Catholic media."*~~ (the question form is fine; drop any "fingerprint/measurable signature" subtitle)

Candidate replacements (descriptive, not causal): *"Inflation for whom? Distributional emphasis in Croatian
Catholic media's coverage of the 2021–2025 cost-of-living shock"* · *"Attention to the regressive incidence
of inflation: a pattern consistent with Catholic Social Teaching in Croatian Catholic media"*.

---

## 7. Concrete next step

> Superseded by **§11**. (Old text: "formalize Version B into RQ + hypotheses + variable table" — done in
> §8–§9; "spec the corpus slice + sub-dictionary + benchmarks" — now gated behind the two audits in §10.)

---

---

# 8. Panel synthesis (rev. 2 — `/research-ideation`, 2026-06-29) — BINDING

Five-agent evaluation panel calibrated to the discipline card (descriptive computational-text for
media/religion venues; NOT causal econometrics). **No panelist found an intrinsically fatal flaw — the data
asset is strong and every objection is a framing/design fix, not a data limitation.** But three independent
objections each reach "fatal *as worded*," so the headline claim must be reframed before any result is
reported.

## 8.0 Refined RQ (population–context–mechanism) — replaces the §1 headline

> **Among Croatian Catholic media outlets (population), during the 2021–2025 cost-of-living shock (context),
> is attention to inflation disproportionately responsive to its regressively-incident components
> (food + energy), and does the coverage frame that incidence *distributionally* — and is either pattern
> distinctively larger than in a secular media benchmark, in a way *consistent with* (not dispositive of) a
> Catholic-Social-Teaching orientation in attention allocation (mechanism)?**

Four changes the reframe forces in, each demanded by ≥3 panelists:

| # | Change | Why | Raised by |
|---|---|---|---|
| 1 | **Drop "fingerprint" / "driven by" / causal language** → "consistent with, not dispositive of" | the conditional coefficient is consistent with ≥5 non-CST stories | editor · devil · theorist |
| 2 | **Add a secular-media comparison benchmark** (now mandatory, §2-C) | CST signal = the *Catholic differential*, not the level; defuses mechanism gap AND war confound at once | all 5 |
| 3 | **Promote the framing DV (DV2) to CO-PRIMARY** | DV1's coefficient can't license CST; within-post distributional language is the only place the mechanism is observable in text | theorist · methodologist · devil |
| 4 | **Run a CST-prevalence + charity-vs-critical audit FIRST** (§10) | the interesting finding may be the *absence* of CST framing; the Caritas charity beat is the prior-favored rival | domain · devil |

## 8.1 [MAJOR/FATAL-as-worded] The mechanism leap — construct invalidity
A positive food/energy coefficient conditional on headline is consistent with at least **five non-CST
data-generating processes**, and the design distinguishes none: **(a)** secular echo — *all* Croatian media
over-covered food/energy in 2022–23; Catholic outlets reprinting HINA/secular portals produce the identical
coefficient with zero theological content; **(b)** the Caritas / charity beat — a structural editorial slot
that rises mechanically with food prices regardless of any "option for the poor" worldview; **(c)**
human-interest hardship as engagement bait; **(d)** anti-government **blame** framing (the poor as a cudgel
against the governing party — the *opposite* of solidarity); **(e)** plain newsworthiness (food/energy is the
more vivid, photographable face of inflation for *any* outlet). CST is the *preferred reading* of the
coefficient, not one the coefficient selects.
**Defuse (does not fully cure):** (i) drop causal/fingerprint language (§8.5); (ii) the secular comparison so
the claim is a *differential*; (iii) read the high-distributional-language posts for **solidarity vs. blame**
valence — that distinction *is* the construct and only the text resolves it; (iv) the discriminating control —
secular salience should load on perceptions/Google-Trends (public mood); a CST orientation should load on the
*incidence* component even when perceptions are flat.

## 8.2 The single fix that does the most work — the secular benchmark (all 5)
A matched secular-media comparison **simultaneously defuses §8.1 (mechanism) and §8.3 (war confound)**:
the war hit secular and Catholic outlets identically, so a Catholic *excess* response survives by
construction. Without *some* baseline the CST claim is not testable. This is the discipline card's
"descriptive-with-external-benchmark" design — the benchmark is not decoration, it is what carries the
mechanism. Comparability of the control group is the main referee target → scope explicitly (e.g. matched
general-news portals, or a within-corpus contrast of more- vs. less-magisterial outlets).

## 8.3 [MAJOR/FATAL-as-worded → MAJOR with benchmark] War/energy confound
Food & energy CPI in HR 2022–24 are a near-deterministic function of the Feb-2022 invasion and the gas/
electricity shock — the "preferential" coefficient and "the war" are the same column of variation. A
post-euro dummy + month FE do not absorb a single-episode level-and-slope shock. **Fix:** explicit
energy-shock/war control (§3); lean the identification on DV2's within-post language (does the post name
*prices/poverty* vs. *war/Ukraine*?); honestly state that within a 5-year, one-dominant-shock window you
cannot fully de-confound — that humility is a strength to a descriptive referee.

## 8.4 [MAJOR] Does the framing DV (DV2) rescue the mechanism, or relocate it?
**It relocates it unless paired.** DV2 is closer to "solidarity" than raw volume, but it inherits every DV1
confound plus two new ones: it is noisier (built on a sample unless censused — §4) and "distributional
language" *still* does not separate solidarity ("the poor are crushed") from blame ("…by this government").
DV2 rescues the mechanism **only if** paired with (a) the **Atmosfera-diskursa sentiment/conflict layer**
(compassion- vs. conflict-valenced) and (b) the **secular comparison**. On its own it just moves the gap one
step downstream.

## 8.5 [MAJOR, trivially fixable] "Measurable fingerprint" rhetoric
"Fingerprint"/"measurable" imply a *uniquely identifying* signature; a coefficient consistent with five
stories is the opposite. Delete it. Use "consistent with," "compatible with a CST orientation," "an
attention pattern distributional-solidarity accounts would predict." Costs nothing, removes a free kill-shot.
(See §6 for the retitle.)

## 8.6 [MAJOR, substantive] The CST anchor is likely mis-specified (domain expert)
"Preferential option for the poor" is a **liberation-theology-derived** formulation (Medellín/Puebla,
Gutiérrez) that the Croatian episcopal-conservative milieu has historically kept at arm's length. The CST
register Croatian Catholic media *actually* deploy on economics — to the extent they do — runs through
*Caritas in Veritate*, *Laudato si'*, *Fratelli tutti*, *Evangelii Gaudium*, and Francis's "ova ekonomija
ubija." Worse, the secondary literature on Glas Koncila (identity/culture-war positioning) suggests the
dominant register may be **culture-war/identity, not CST economics at all**.
**Fix:** reframe the anchor as the **Francis-era CST economic corpus**, with "option for the poor" as *one
strand*, not the master frame. And run §10's prevalence audit *first* — if CST-economic language is a thin
minority, the paper's premise collapses and the finding becomes the documented *absence*.

## 8.7 Minor but cheap
- **Denominator drift** (§3): show numerator & denominator separately.
- **Lead-lag** (§3): descriptive only, pre-whitened, one pre-specified lag, CI'd, no causal headline.
- **Outlet heterogeneity is a finding only with directional priors** (§5): state per-outlet expectations a
  priori (e.g. IKA wire = headline-CPI/event-driven; Bitno.net = culture-war-dominant w/ episodic economic
  moralizing; Glas Koncila = institutional charity-beat) so confirming/violating them *is* the contribution.

---

# 9. Hypotheses & the preregistration verdict

- **H1 (attention, confirmatory directional):** conditional on headline CPI, food/energy CPI is *positively*
  associated with Catholic-media inflation attention (DV1). **Paired null/alternative:** food/energy adds
  nothing once headline is controlled → pure news-salience story.
- **H2 (framing, co-primary):** the distributional-frame share (DV2) rises specifically with food/energy
  CPI, *not* merely with headline — separating attention from framing.
- **H3 (mechanism):** the food/energy attention/framing is *distinctively larger in Catholic than secular*
  outlets AND the distributional framing is compassion- (not conflict-) valenced — this is what makes the
  pattern "Catholic" rather than generic.

**Prereg verdict.** H1 *is* a confirmatory directional claim on a not-yet-examined slice — the discipline
card's exact OSF-prereg trigger. **BUT** the panel judges that at ~50 points with headline + its own
subcomponents + 11 month-FE + 4 collinear controls (~18 params), the conditional coefficient is **likely not
identified** — sign unstable to specification, a researcher-degrees-of-freedom artifact. **So: do NOT lead
with H1 as an inferential coefficient.** Demote it to a *pre-registered, parsimonious secondary* analysis
(drop month-FE → harmonic seasonality; residualize food/energy on headline; report a full specification
curve; HAC SEs). Preregister H1 *because* it is directional-confirmatory — but the paper's spine is
**descriptive** (DV1 index + DV2 framing contrast + secular differential), which needs no prereg.

---

# 10. GATING tasks — run BEFORE any result is reported

Both are an afternoon each on the pipeline machine; either can *reframe the whole paper*, so they come first.

1. **DV1 inflation-dictionary false-positive validation.** Lemma-based matching + multi-term co-occurrence;
   hand-code ~200–300 tagged posts for precision; **split-by-year** to confirm the FP rate is stable (a
   drifting rate biases the trend that is the dependent variable everywhere). Non-negotiable for these venues.
2. **CST-prevalence + charity-vs-critical audit.** What share of religious-themed economic coverage even
   contains CST-economic markers vs. **charity-appeal** (Caritas/almsgiving) vs. **culture-war/identity**?
   Within the CST/poverty stratum, split **critical/structural** ("economy that kills," naming injustice)
   from **ameliorative/charity** (donate, help). The CST-as-attention claim is only credible if the
   *critical* stratum — not the charity stratum — tracks regressive incidence. **If CST-economic language is
   negligible, pivot the paper to documenting that absence** (still novel, still publishable).

---

# 11. Scorecard & next step

| Panelist | Score | One-line |
|---|---|---|
| Theorist | 5/10 → 7–8 reframed | "doctrine as attention-allocation rule" is a real seam; coefficient can't carry it — promote DV2, add benchmark |
| Methodologist | 5/10 | descriptive spine sound; inferential spine unsupportable at n=50; **census** the inflation slice for DV2; validate DV1 FP rate |
| Domain expert | 6/10 sig · 7 nov | CST anchor likely mis-specified (Francis-era corpus, not liberation-theology "option"); audit prevalence first |
| Journal editor | 5/10 → 7 reframed | best fit **Journal of Media and Religion**; accept-track **Medijska istraživanja**; desk-reject NM&S on scope |
| Devil's advocate | 3/10 → 6–7 reframed | easy to kill as causal, strong as descriptive; the secular comparison defuses two fatal flaws at once |

**Consensus: ≈5/10 as originally written; a clear 7/10 reframed per §8.** Best venue: **Journal of Media
and Religion** (decisive), accept-track **Medijska istraživanja**; lead with the descriptive index, NOT the
NM&S tier. Two gates (§10) before any result.

**Corpus slice (authoritative):**
- **DV1 (attention):** full ≈610k corpus, 2021–2025, ≥2-term filter; regex-on-lemmas inflation
  sub-dictionary tagged on *all* posts; DV = inflation posts ÷ all religious-filtered posts (numerator &
  denominator reported separately).
- **DV2 (framing):** **census (or near-census) of the inflation-tagged slice** — NOT the global 2–5% sample;
  three strata coded (solidarity/critical · charity/ameliorative · blame/anti-government); demote to a
  pre/post-2022-spike two-regime contrast if monthly counts are too thin.
- **Outlet cross-section:** Glas Koncila · Bitno.net · IKA, with a priori directional expectations.
- **Benchmarks:** HICP headline + food/energy sub-indices · HZZ unemployment · DG ECFIN perceptions · Google
  Trends "inflacija" · energy-shock/war control — all **release-calendar aligned** · **+ secular-media
  comparison series**.

**Next step (in order):**
1. **`/data-analysis`** — run the two §10 gates first (lowest-regret; either can reframe the paper). Needs
   R + master → run on the pipeline machine per `CLAUDE.local.md`, else emit the script and hand off.
2. **`/lit-review`** — position against the two adjacent literatures the domain expert named: inflation-
   salience / agenda-setting (ECB attention monitoring; inflation word-frequency above ~4% CPI) and
   CST-economic-media reception (*Economic Justice for All* / *Evangelii Gaudium* "economy kills" debates).
   The gap is the *combination* in a non-US, post-socialist, identity-Catholic digital setting — claim it
   precisely, not as virgin territory.
3. **`/new-study`** — scaffold `studies/inflation-salience/` *iff* both gates pass.
