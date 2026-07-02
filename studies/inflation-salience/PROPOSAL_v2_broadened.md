# Proposal v2 (broadened unit) — When prices rise, what does religion say?

**Date:** 2026-06-30 · **Status:** second draft — rewritten after a first-pass run on the master · **Owner:** L. Šikić
**Supersedes:** [PROPOSAL.md](PROPOSAL.md) (v1, Catholic-outlet framing). **Evidence:** [FINDINGS_FIRSTPASS.md](FINDINGS_FIRSTPASS.md) + [output/](output/).

> Still the *simple* version: two-and-a-half plain questions and one figure. The difference from v1 is the
> **unit of analysis** — we no longer study "Catholic outlets" (they barely mention inflation: 0.18% of their
> posts). We study the **place where religion and inflation actually meet, wherever it happens** in the
> Croatian digital media space. The first run already gives us the headline answers; the rest is validation.

---

## 1. The idea in one paragraph

Between 2021 and 2026 Croatia lived through a sharp cost-of-living shock (food and energy especially), and in
January 2023 it switched to the euro — a textbook moment for price anxiety. Catholic Social Teaching has a
loud, clear stance on this: the Church should be the first to speak when prices crush **the poor** ("ova
ekonomija ubija"). So we look at every place in the Croatian digital media space where **religion and
inflation are mentioned together**, and we ask a simple question: *when the two actually meet, what is said?*
The first pass already tells us something striking — the genuine overlap is **small**, and when it does
happen it is mostly about the **Church as an institution** and the **rising cost of religious life itself**
(costlier Masses, church fees, cathedral weddings, Advent wreaths), **not** the prophetic, structural defence
of the poor that the doctrine would predict. The paper documents that gap.

---

## 2. The questions (two and a half)

- **Q1 — Linkage / salience.** How often is a religion–inflation co-mention a *genuine* link (the two are
  actually talking to each other) versus pure coincidence (both happen to sit in one long article)?
  *Measured answer: genuine domestic linkage is small — 520 posts, 6.5% of inflation-mentioning posts; even
  among proximity-flagged candidates only 45% survive coding, so most co-mentions are incidental.*
- **Q2 — Register.** When religion *is* genuinely invoked around inflation, in which register? Four candidates:
  **Church-as-institution** (bishops, the Pope, "the Church" in the news), **cost of religious life**
  (the price of religious goods/services rising), **structural / justice critique** (CST — inflation as
  injustice to the poor), **charity** (Caritas, relief). *Measured answer (n=520): cost-of-religious-life 37% +
  Church-as-institution 34% dominate; charity 17%; structural/CST justice just 3%.*
- **Q2½ — Who carries it.** Which actors produce the genuine link? *Measured answer: secular outlets carry 85%
  by volume; Catholic outlets 14% (75 posts) — and when Catholic outlets engage they tilt to charity (36% of their core).*

We stay descriptive: we map a pattern and let the reader judge whether it fits — or fails — the CST promise.

---

## 3. Why it's worth doing (the gap, in plain terms)

Same three literatures as v1 (inflation-and-media agenda-setting · CST economic framing · Croatian Catholic
media — see [LITERATURE.md](LITERATURE.md)), but the broadened unit adds a **fourth, methodological** gap:

- Nobody has asked what the **religious register of inflation discourse** looks like in a whole national
  digital media space — not "do Church outlets cover it" but "when religion is in the room as prices rise,
  what voice does it take." That is the substantive opening.
- **Method gap:** studies of "religion and X" in big text corpora routinely count **co-occurrence** and call
  it engagement. Our first run shows that is badly wrong here: **~68% of religion×inflation co-mentions are
  incidental**, and a naïve count would have **overstated genuine religious engagement ~7-fold** (and a
  single lexicon bug — `gospodarstvo` "the economy" matching the Marian *Gospa* — alone inflated it by
  half). Measuring **genuine linkage** is a transferable contribution.

---

## 4. Data (we already have it)

- **Corpus:** the DigiKat master — **710,307** posts × 47 vars, **2021-01 → 2026-06**, Croatian/Bosnian,
  religion-filtered (≥2 distinct religious-term matches). **Important:** it is *religion-salient posts across
  the whole media space* (secular-dominated: jutarnji, index, večernji, …), **not** a Catholic-outlet
  archive. `data_source` is a temporal batch marker (2021–24 vs 2024–26), not a content split.
- **Religion side:** the project lexicon `R/religious_terms.R` (95 terms), **tightened** for economic
  homonyms (Gospa/gospodarstvo, demon/demonstracije, kapitul/kapitulira, papa/papir, misa/misao).
- **Inflation side:** an anchored lexicon (`inflacij* / poskup* / rast cijen* / trošak života / kupovna moć`,
  deliberately not bare `cijena`); precision looks high on eyeball, no "price of salvation" hits.
- **Prices (to acquire):** Croatian HICP monthly — headline + food + energy — for the §6 overlay. Euro
  changeover (Jan 2023) as a natural salience break.

---

## 5. What we actually do (and what's already done)

1. **Tag inflation** across the corpus → 8,105 posts (1.14%). ✅ done.
2. **Measure linkage** — religious term within ±150 chars of the inflation mention → genuine vs incidental;
   flag foreign-country inflation. ✅ done → **858 domestic genuine-link posts**.
3. **Classify register** (institution / cost-of-religious-life / justice / charity) on the linked set.
   ✅ rough keyword pass done; ⬜ hand-validation pending.
4. **Hand-validate** ~150 linked + ~50 incidental from `output/linkage_coding_sheet_v2.csv` → precision/
   recall on both *linkage* and *register*. ⬜ next — this is the methods backbone.
5. **Actor map** — tie the producers of genuine links to the project's actor typology. ⬜
6. **Temporal** — plot domestic genuine-link volume against HICP (does the religious-inflation conversation
   track real prices and the euro switch?). ⬜ figure scaffolded (`output/linkage_over_time_v2.png`).

One figure (linkage over time, split domestic / foreign / incidental) + one register chart + one actor table
+ the HICP overlay. That's the paper.

---

## 6. Results

> **✅ MEASURED (coded core, 2026-06-30 — see [ANALYSIS_READY.md](ANALYSIS_READY.md)).** The 1,450 linked
> candidates were coded by 3 independent annotators (majority, full coverage). **Measured domestic core =
> 520 posts** (recall-corrected ≈584). Register: **cost-of-religious-life 37% · Church-as-institution 34% ·
> charity 17% · devotional 5% · structural-justice 3%**. Outlet: secular 85% / Catholic 14%. Peak year 2022
> (energy shock). The CST justice voice is essentially absent. This supersedes the provisional auto-label
> figures below (kept for the record / method illustration).

### 6a. Provisional auto-label first pass (pre-coding)

| Finding | Number |
|---|---|
| Inflation posts in the religion corpus | 8,105 (1.14%) |
| Genuine linkage (religion near inflation) | 1,167 (14.4%) — **down from 31.6% before tightening** |
| Foreign-country inflation (set aside) | 2,562 (31.6%) |
| **Domestic genuine religion–inflation core** | **858 (10.6%)** |
| Register: Church-as-institution | 55% |
| Register: cost of religious life | 41% |
| Register: structural / CST justice | 7% |
| Register: charity / Caritas | 8% |
| Who carries it (volume) | secular ~88%, Catholic ~10% (but 39% *rate*), business ~2% |
| Temporal peak (rate) | 2022 energy shock |

**The discovery v1 didn't anticipate:** a whole register of *"the cost of religious life is rising"* —
church fees and Mass stipends going up, cathedral wedding prices, Advent wreaths, pilgrimage costs. This is
the Church as an *economic object*, not a moral *voice*. It deserves its own codebook category.

---

## 7. Honesty checks (done + remaining)

- ✅ **Inflation precision:** eyeball clean; no "price of salvation" false positives.
- ✅ **Recall probe:** the broad cost-of-living net's extra hits were almost all the homonym `egzistencija`
  (existential, not economic) — strict tagging is not badly under-counting.
- ✅ **Linkage tightening:** removed 1,422 false links (mostly `gospodarstvo`→Gospa).
- ✅ **Validation + fixes + HELD-OUT re-validation** (→ [VALIDATION.md](VALIDATION.md), [ANALYSIS_READY.md](ANALYSIS_READY.md)).
  All 5 fixes implemented and re-run on the master → **1,103 candidate** posts (`output/analysis_core.csv`).
  Honest **held-out** test (80 fresh posts, 3 independent annotators, IAA 0.97): inflation precision **85%**,
  linkage **recall 0.89** but **precision ~0.38**, foreign precision ~0.39, register agreement 0.46.
  **Conclusion: the regex classifier is a high-recall candidate generator, not an accurate labeller** — it
  has a precision ceiling (~0.4); chasing more regex fixes overfits.
- ✅ **Substantive result is ROBUST** across in-sample, out-of-sample, and 3 independent annotators: domestic
  religion×inflation discourse is **institution ~50% · cost-of-religious-life ~23% · charity ~12% ·
  justice ~8% · devotional ~8%**. The CST justice voice is marginal (and often a *foreign* Church import).
- ⬜ **Code the 1,103-candidate pool** (validated 3-annotator LLM workflow, human double-codes a slice) →
  the paper's measured core. This is the immediate next step — do NOT publish auto-label counts/register.
- ⬜ Acquire **HICP**; build the coded-core temporal/register/actor analysis (euro changeover Jan-2023).

---

## 8. If we want to go further (optional, not the first paper)

- **Emotion/tone** around the linked posts via the project's CroSentilex / lilaHR layer — is the
  cost-of-religious-life register resigned, the justice register angry?
- **Euro-changeover event study** (Jan 2023) — does religious inflation talk spike at the switch?
- **Secular vs religious register comparison** — do secular outlets frame inflation structurally where
  religious framing does not? (Caveat: the secular baseline is itself religion-filtered.)

---

## 9. Venue

As v1 — **Journal of Media and Religion** or **Medijska istraživanja** — but the linkage-vs-co-occurrence
method now also fits a **digital-religion / computational-social-science methods** outlet.

## 10. Working title (options)

1. *When prices rise, what does religion say? Religion and the 2021–2026 cost-of-living shock in Croatian digital media.*
2. *Costlier candles, quiet prophets: the Church as economic object, not moral voice, in Croatian inflation discourse.*
3. *Co-occurrence is not engagement: measuring genuine religion–inflation linkage in a 710k media corpus.* (method-forward)

## 11. Next step

Run **§5 step 4** — generate the hand-coding sample from `output/linkage_coding_sheet_v2.csv` and code it
(≈200 posts, an afternoon). That converts every "provisional" number above into a validated one and fixes the
register taxonomy. Then acquire HICP and build the overlay. I can produce the coding sample on request.
