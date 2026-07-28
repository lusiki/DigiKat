# Coding codebook v3 — moral-economy (religion × economy register coding)

**Date:** 2026-07-07 · **Status:** design (pre-coding; supersedes the 5-register prose inherited from the sister study)
**Anchors drawn from restricted real corpus windows**
(`output/private/poverty_diagnosis_sample.csv`, 2026-07-07 poverty hand-pass).
**Purpose:** the coding instrument for Stage B. This is the paper's *measured core* and its *weakest measured axis*
(inherited held-out register agreement **0.46** — the number to beat). Every axis below is coded on the
**hand-confirmed genuine-link set only**; auto-labels are withheld from annotators (sister-study procedure).

> **Why v3 exists.** The sister paper's 5-register scheme (institution · cost-of-religious-life · justice ·
> charity · devotional) is inherited intact, but the poverty hand-pass (2026-07-07) showed it is **not
> sufficient for the whole economy**: the single most theory-loaded domain, `poverty_social`, conflates
> *economic poverty* with *the poor as a theological category*, and that blur is the empirical heart of the
> "moral voice vs economic object" question — not noise to delete. v3 adds the distinctions that make that
> measurable, plus the actor/commentator, KSN-principle, and encyclical codes the proposal promised.

---

## The seven axes

Each genuine-link post gets one value on each axis (Axis 5 only for the poverty domain; Axes 6–7 only where
Axis 4 = justice / where a document is named).

### Axis 1 — Genuine link *(confirm the candidate)*
`genuine` / `incidental`. Is religion actually *in conversation with* the economic content inside the ±220
window, or do the two just co-occur? **Default to `incidental` when uncertain** (the sister precision ceiling
~0.4 means the pool is noisy by construction).
- `genuine`: a bishop comments on the at-risk-of-poverty rate; an encyclical is invoked about markets.
- `incidental`: *"…**ovršni** postupak… ispred **crkvice** na Perilima održat će se izložba…"* — a debt term
  and a church term in one festival announcement, not talking to each other.

### Axis 2 — Reference geography
`domestic` / `foreign` / `mixed`. Croatian (or BiH-Croatian) economy vs a foreign-country economy (the sister
study found the CST-justice voice is often a *foreign* import — papal comment on US migration, missions in
Africa/Bolivia). Foreign posts are set aside from the domestic core but **counted** (the import pattern is a finding).

### Axis 3 — Religion as actor vs commentator *(NEW — Rule 2, the object/voice fault line)*
`actor` / `commentator` / `both`. Is religion the **economic actor being described**, or **commenting on** the economy?
- `actor`: Caritas runs a food bank; the diocese sells property; a parish organizes earthquake relief; Mass fees rise.
- `commentator`: *"…otklanjanje **strukturalnih uzroka siromaštva**…"* (Abp. Kutleša) — the Church speaking *about* the economy.
- This axis is what keeps "Caritas beside a food bank" from being miscounted as religion engaging the economy.

### Axis 4 — Register *(inherited 5 + `devotional` sharpened + `other`)*
The primary outcome. Exactly one:

| Code | Definition | Object/Voice | Real anchor (trimmed) |
|---|---|---|---|
| `object_institution` | Church / clergy / Pope / parish as an **institutional actor** in economic news | **object** | "…u zgradi KŠC-a… počeo s radom vrtić…" (Church as economic institution) |
| `object_cost_relig_life` | the **price of religious goods/services** rising (fees, stipends, weddings, wreaths) | **object** | (sister-study register; rare in poverty domain) |
| `charity` | **relief / almsgiving as action** — Caritas, collections, aid (episodic, Iyengar) | *separate* | "…anđeli dobrote… prikupljaju pomoć za siromašne vršnjake u Africi…" |
| `justice` | **structural critique** — causes of poverty, dignity of work, CST principles (thematic, Iyengar) | **voice** | "…otklanjanje strukturalnih uzroka siromaštva… kršćanska nada… preuzimanje odgovornosti za svijet…" |
| `devotional` | economic vocabulary used **devotionally / metaphorically**, no economic referent | *neither* | "…presiromašni smo da bismo postavljali uvjete, trebamo praštati…" (spiritual poverty) |
| `other` | genuine link but none of the above (e.g. tax status of church property as neutral fact) | *remainder* | — |

**Reporting rule:** the paper's title contrast is **`justice` vs `object_*`** — charity is tracked as its own
register (episodic; theoretically ambiguous — institutional relief *and* moral practice), **never folded into
"voice."** `devotional` + `other` are reported as the explicit remainder, never silently dropped. Agreement is
reported at the 5-way level **and** the collapsed 3-way (`justice` / `charity` / `object`) level; the
confirmatory endpoint (H1/H4) runs at whichever level clears a pre-declared reliability floor.

### Axis 5 — Poverty sub-split *(NEW — `poverty_social` domain ONLY)*
`economic_poverty` / `doctrinal_poverty` / `mixed`. The poverty hand-pass showed these are ~equal in volume and
jointly drive the domain's outlier linkage (0.62) and confessional skew (0.60). Coding them apart is the
domain's core deliverable.
- `economic_poverty`: a material/economic referent — at-risk-of-poverty rate, debt, eviction (*ovrha*),
  welfare policy, material deprivation. *"svaki peti građanin Hrvatske u riziku od siromaštva… Svjetski dan siromaha…"*
- `doctrinal_poverty`: **the poor as a gospel/theological category** with no economic referent — almsgiving as
  virtue, hagiography ("sve ostavio siromasima"), "option for the poor" as principle, "siromasi duhom."
- Note the interaction: `doctrinal_poverty` will correlate with `devotional`/`justice` registers and high
  confessional share; `economic_poverty` is where genuine economic engagement lives. **This split is itself a
  finding** about how Croatian Catholic discourse mediates "the poor."

### Axis 6 — KSN principle *(NEW — sub-code inside `justice` only)*
Which Catholic Social Teaching principle is invoked (multi-select allowed): `solidarnost` · `supsidijarnost` ·
`opće dobro` · `dostojanstvo rada` · `opcija za siromašne` · `integralna ekologija` · `univerzalna namjena dobara` ·
`none-named`. Lets us say *which* doctrine surfaces where, not just "justice happened."

### Axis 7 — Encyclical / document reference *(NEW — lexical probe + confirm)*
Named magisterial document if any: `Rerum Novarum` · `Quadragesimo Anno` · `Laborem Exercens` · `Centesimus Annus` ·
`Caritas in Veritate` · `Laudato si'` · `Fratelli Tutti` · `Evangelii Gaudium` · `other` · `none`. Direct,
countable evidence of doctrinal anchoring in economic contexts (answers the co-author sketch's KSN-comparison goal).

---

## Homonym / false-positive exclusions (confirmed from the hand-pass — fold into lexicon v3 before Stage A)

- **`misa zadužnica`** = *requiem Mass*, NOT debt — the `du[zž]ni[kc]` regex catches `za**dužnica**`. **Exclude**
  `zadušnic|zadužnic` from the poverty/debt tagger (add negative lookaround or a post-filter).
- **`siroma[sš]` + devotional context** — guard or down-weight when the window carries `duhom|duha|zavjet|
  redovni[čc]k|blaženi|evanđelj` (spiritual poverty), routing to `doctrinal_poverty` at coding, not economic.
- **`ovršn`/`ovrh` incidental** — the debt regex fires in unrelated text (church festivals, art ateliers);
  Axis 1 (`incidental`) catches these at coding, but flag for the precision hand-scan.
- **`duhovn` devotional-content channels** — YouTube/portal devotional feeds co-occur with any economic term;
  genuine-link (Axis 1) is the guard.

---

## Annotator procedure (to build — the one from-scratch pipeline stage)

1. **Text-only sheet:** annotators see the `window` excerpt + minimal context, **never** the auto-labels
   (sister procedure; auto-labels bias agreement upward). Schema mirrors the sister study's coded pool:
   `rid, DATE, FROM, otype, window` + the seven axes above.
2. **Three independent annotators** (validated LLM workflow); **human double-codes a pre-declared slice**;
   majority adjudication; disagreements logged.
3. **Gold-slice re-validation BEFORE preregistration:** a human-adjudicated ground-truth set re-estimates
   agreement on **register (Axis 4)** and the **poverty split (Axis 5)** — the two new/weak axes — at 5-way and
   3-way levels. Report κ per axis. If register clears the floor only at 3-way, confirmatory tests run at 3-way
   (pre-declared fallback order: 5-way → 3-way → justice-vs-rest binary).
4. **Report** the incidental-co-mention rate and per-domain precision alongside every register distribution.

**Reuse note (from the machinery inventory):** the sister study committed **no annotator code or prompt** —
only the codebook prose and output CSVs. So this instrument is genuinely built from scratch; the reusable
assets are the **output schemas** (`coded_pool_full.csv`: `rid,DATE,FROM,otype,c_infl,c_link,c_foreign,c_register,domestic,n_ann`)
and this codebook. Budget the real engineering here.
