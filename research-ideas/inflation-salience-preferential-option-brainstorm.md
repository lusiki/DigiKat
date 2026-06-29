# Research brainstorm — Inflation salience & the preferential option for the poor in Catholic media

**Status:** brainstorm / scoping note (not yet a plan or a study)
**Date:** 2026-06-29
**Context:** Computational (text-as-data) spin-off from the proposed mixed-methods study *"Ekonomija u
katoličkom medijskom prostoru"* (frequency + framing + KSN alignment of economic themes). This note
develops **one** of several economic spin-off ideas: turning the corpus into a **media-attention index**
and testing what drives inflation coverage — the headline number, or its incidence on the poor.
**Corpus:** DigiKat master — ≈610k posts, 2021–2025, religious-term-filtered (≥2 distinct matches).
**Sibling note:** [[welfare-state-catholic-media-brainstorm]] (same corpus, welfare-state angle).

> This consolidates the brainstorm so it survives `git pull` on any device. It is the most "economist"
> of the economic spin-offs and the cheapest to get a first cut on.

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

Everything hangs on a single test. Coverage of inflation could be driven by:

- **H_macro** — the **headline** CPI number (they cover inflation because it is "the news"); or
- **H_poor** — the **regressive incidence** (they cover it because *food + energy* — the components that
  eat a poor household's budget — are what spiked), consistent with the *preferencijalna opcija za
  siromašne* frame.

The paper is, at its core: **does food/energy inflation still drive coverage *after* conditioning on
headline CPI?** A positive, significant conditional coefficient is a *measurable fingerprint* of Catholic
Social Teaching in attention allocation — not merely in rhetoric. The whole study lives or dies on that
one coefficient.

---

## 2. Three versions, escalating ambition (pick the altitude)

### Version A — descriptive (minimum viable; a `/data-analysis` afternoon)
Monthly economy-coverage **share** vs. Croatian CPI YoY, plotted with the euro/war/energy events marked,
plus a cross-correlation. Decompose: coverage vs. food/energy CPI separately. Report the partial
correlation of food/energy controlling for headline. Honest, fast, publishable in a religion-and-media
venue on its own.

### Version B — the core economics paper
Poisson on monthly counts (log total religious posts as **exposure offset**) *or* OLS on shares.
RHS: headline CPI YoY, **food+energy CPI YoY**, unemployment, month FE, post-euro dummy. The coefficient
on food/energy **conditional on headline** is the money result. Then add a **second DV**: among inflation
posts, the **share invoking the distributional frame** (*siromašni / obitelji / umirovljenici / socijalno
ugroženi*). Does that share rise specifically when food/energy is high vs. when headline is high but
food/energy moderate? That cleanly separates **attention** (do they cover it) from **framing** (how) —
two stories from one corpus.

### Version C — comparative identification (most ambitious)
Add a secular comparison group, diff-in-diff-flavoured: is the food/energy sensitivity **larger in
Catholic than secular** outlets? The only way to claim the mechanism is specifically Catholic rather than
how all media cover inflation. Because the corpus is the ecosystem filtered to religious terms, the honest
comparison is "religious-themed economic content in Catholic vs. secular outlets" — feasible (the `FROM`
column identifies outlets; see [[welfare-state-catholic-media-brainstorm]] §6.2), but the comparability of
the control group is the main referee target. Scope carefully.

---

## 3. Shared building blocks (same for all three)

- **DV as a *share*, not a count.** Total media volume grows over the window, so raw counts trend up
  mechanically. Use economy-posts ÷ all-religious-posts per month (or Poisson with the exposure offset).
- **Inflation sub-dictionary** off the existing codebook: *inflacija, poskupljenje, rast/skok cijena,
  troškovi života, cijene, …*. Hand-validate ~50 hits — beware the same crude-substring noise flagged in
  the sibling note (§6.3) if matching on raw text rather than lemmas.
- **Benchmark series (all public, monthly, free):**
  - DZS / Eurostat **HICP** — headline **and** the food and energy sub-indices (these *are* the incidence
    measure);
  - HZZ / Eurostat **unemployment**;
  - DG ECFIN Consumer Survey **inflation perceptions** (a "subjective inflation" series — a strong third
    RHS);
  - **Google Trends "inflacija"** as a public-attention benchmark.
- **Lead-lag is its own mini-result.** Does Catholic media track the *data* (CPI) or *public attention*
  (Google Trends / general media)? If it tracks attention more than data, it is a **resonance** medium,
  not an **agenda-setter** — a clean, quotable finding.
- **Timing gotcha:** CPI for month *t* is released mid-*t+1*. Align coverage to the **release calendar**,
  not the reference month, or the response is mis-dated.

---

## 4. Feasibility within DigiKat

- **Count on the full corpus; sample only for the deep read.** Dictionary tagging is cheap regex-on-lemmas
  → tag *all* posts for the attention DV (do **not** sub-sample the index). Reserve the 2–5% stratified
  sample for the expensive framing/sentiment DV. State this explicitly so a reviewer doesn't think the
  index was sampled.
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
- **Collinearity:** food/energy inflation, the energy crisis, and the Feb-2022 war all co-move — "preferential-
  option attention" cannot be fully separated from "war shock" by timing alone. Lean on the *framing* DV
  (within-post language, not just timing) to break the tie.
- **Stance/frame ≠ sentiment.** The distributional-frame DV is a classification target (dictionary-for-recall
  + LLM/human-for-precision, validated against a gold set), **not** a CroSentilex valence proxy.

---

## 6. Working title

*"Inflation for whom? Macroeconomic salience and the preferential option for the poor in Croatian
Catholic media."*

---

## 7. Concrete next step

Either:
1. Formalize **Version B** into RQ + hypotheses + a variable table (`/research-ideation`); or
2. Spec the **corpus slice + inflation sub-dictionary + benchmark sources** so it's ready to run the
   moment someone is on the pipeline machine (`/data-analysis`).
