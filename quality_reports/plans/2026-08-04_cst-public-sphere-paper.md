# Plan — "Catholic Social Teaching in the public sphere" paper (moral-economy study)

**Date:** 2026-08-04 · **Owner:** PI (L. Šikić) · **Study:** `studies/moral-economy/`
**Status:** approved framing, execution starting at Step 1

---

## 1. Decision

Write the **substantive sociology-of-religion / media-and-religion paper**, not the computational-methods
paper. The dual-lens measurement material is demoted to a robustness appendix.

**Chosen thesis — rare, recent, re-indexed** (revised 2026-08-04 after the Step-1 census, which replaced a
flat "absence" claim with a sharper one):

> In the Croatian digital public sphere the Catholic Church is highly present in economic discourse but
> rarely speaks *as doctrine*: explicit Catholic Social Teaching appears in **2.6%** of the 108,966
> religion-linked economic posts. Where doctrine does surface it is **Francis-era and ecological**, not the
> labour-capital tradition CST was built for — Francis-era documents outnumber the classical corpus
> **5.4 : 1**, and *Laborem Exercens*, the encyclical on human work, appears **34 times in 710,307 posts**.
> The classical texts are not topically unsuited: when cited at all they are the *most* economically embedded
> of any document group. Their absence is a loss of salience, not of fit. What occupies the vacated space is
> charity and pastoral voice rather than doctrinal argument.

Step 1 is complete (`12_cst_census.R`); §2 records its results.

This is a stronger and more defensible claim than the originally-scoped "which CST principles surface where,"
because the coded evidence shows there is almost nothing to distribute: the distributional question has an
absence for an answer, and the absence is the finding.

## 2. Why the data forces this framing

Census of the 555-item adjudicated gold set (3 blind annotator passes, majority adjudication):

| Quantity | Value |
|---|---|
| Genuine religion–economy link (Axis 1) | **192 / 555** (34.6%) — incidental co-mention is the norm |
| Names **any** CST principle (Axis 6) | **29 / 555** (5.2%) |
| Names **any** magisterial document (Axis 7) | **4 / 555** (0.7%) — 3× *Laudato si'*, 1× *Fratelli Tutti* |
| Of the 29 principle-namings: integral ecology | **13** — concentrated in `green_energy` |
| Of the 29: option for the poor | **5** — against `poverty_social` supplying 85/192 genuine items |
| Register among genuine (n=192) | object 58 · charity 49 · justice 47 · devotional 36 · other 2 |
| Voice among genuine | actor 123 · commentator 64 · both 5 |

Two design facts make the absence claim conservative rather than fragile:

1. **The gold set over-samples where CST should live.** The `register_cell` stratum was drawn as
   5 registers × 2 focus domains, putting `justice` at 70/555 by construction — above its corpus share.
   Near-zero CST inside an over-sampled justice stratum is a hard result.
2. **Absence claims are what small samples do well.** Wilson 95% upper bounds: principle-naming ≈ 7.4%,
   document-citation ≈ 1.8%. The ceiling, not the point estimate, carries the argument.

Axis-7's κ = 1.00 is an artifact of a near-zero base rate and must be reported as such, never as reliability.

## 3. Evidence architecture — three levels

**L1 · Corpus census (n = 710,307) — NEW WORK, the paper's spine.**
Direct lexical census of CST vocabulary over the full corpus: 16 magisterial documents, doctrine markers
(*socijalni nauk*, *supsidijarnost*, *integralna ekologija*, *univerzalna namjena dobara*, *opcija za
siromašne*), reported in two tiers — **Tier 1 unambiguous** (doctrine-specific) and **Tier 2 ambiguous**
(*solidarnost*, *opće dobro*, *dostojanstvo rada*, which carry ordinary secular senses and give the upper
bound only). Reported corpus-wide, within the economic-tagged layer, and within genuine-linked posts.
This converts the absence claim from n = 555 to n = 710,307 and removes the sampling objection entirely.

**L2 · Coded probe (192 genuine of 555) — what fills the space instead.**
Register distribution, actor-vs-commentator voice, domestic-vs-foreign geography. The substitution half of
the thesis: charity and pastoral voice occupy the space doctrine does not.

**L3 · The poverty case (85 genuine) — the option-for-the-poor paradox.**
`poverty_social` is the single largest contact zone: 8.71% of corpus, religion-linkage 0.618 [0.590, 0.645]
against 0.17–0.32 for every other domain, ~60% confessional among classified sources. Within it, charity (24)
outweighs justice (18), and CST's own economic principle is named 5 times. The Church's most-discussed
economic topic is discussed almost entirely without the doctrine written for it.

## 4. Explicitly dropped (state as scope limits, do not rescue)

- **All temporal claims.** `original_dta` ends 2024, `filtered_religious` begins 2024; year-over-year volume is
  a collection artifact. No trend analysis, no event windows, no `h4_shock_windows`.
- **The 710k semantic register grid.** `register_grid_v1.csv` is `provisional = TRUE` throughout and H2 already
  flipped between anchor versions v0→v1. Anchor-version dependence is a fact about the instrument.
- **All semantic-selection-based estimates**, including the 73.8% doctrinal-poverty figure — retrieval
  precision is 0.00 for `business_comp`, `macro_aggregates`, `wages_income`.
- **H2 as stated.** Retired, with the reason given in the appendix.

## 5. Work plan

| # | Step | Risk |
|---|---|---|
| 1 | **CST corpus census** (`12_cst_census.R`) over `corpus_prepared.rds` × `stageA_candidates.rds`; tiered, aggregate-only output | read-only, none |
| 2 | Design-weighted L2 estimates — the gold set is stratified; report within-stratum unweighted **and** corpus-weighted, or state the unweighted framing explicitly | analytic |
| 3 | **Human validation slice** on Axis 4 + Axis 6 — see §6; blocking for submission | procedural |
| 4 | Figures: CST census bar (Tier 1 vs 2), register×voice among genuine, poverty-case panel | low |
| 5 | Draft §§1–8 against computed numbers only; no hand-typed figures | low |
| 6 | Referee simulation via `/review-paper`, then domain review | low |

## 6. Referee kill-shots and mitigations

- **"Your annotators are LLMs."** The codebook specifies a validated LLM workflow with a human double-coded
  pre-declared slice; I found no evidence the human slice was executed. **This is blocking for a
  sociology-of-religion venue.** A human double-code of ~100 items on Axes 4 and 6 with reported κ against the
  adjudicated majority must exist before submission.
- **"Absence of evidence."** Answered by L1: a full-corpus lexical census, not a sample.
- **"Your dictionary missed the doctrine."** Answered by Tier 2: the deliberately over-broad ambiguous tier
  gives the upper bound, and it is still small.
- **"Croatia is idiosyncratic."** Accept it — frame as a single-country case with a strong claim, and let the
  Laudato si' crossover carry the comparative implication.

## 7. Reproduction

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/moral-economy/12_cst_census.R
```
Read-only on `data/semantic/corpus_prepared.rds` and `studies/moral-economy/output/stageA_candidates.rds`.
Writes aggregate-only CSVs (no text, URL, rid) under `studies/moral-economy/output/`.
