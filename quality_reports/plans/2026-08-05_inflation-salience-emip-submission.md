# Plan — inflation-salience → *Ekonomska misao i praksa* (EMIP) submission

**Date:** 2026-08-05 · **Owner:** L. Šikić · **Study:** `studies/inflation-salience/`
**Target:** *Ekonomska misao i praksa / Economic Thought and Practice*, University of Dubrovnik
**Target deadline:** **30 September 2026** (December 2026 issue) · ~8 weeks from today
**Status:** awaiting PI decision on §3 (the reframe) before execution begins

---

## 1. The journal — verified constraints

Source: <https://emip.unidu.hr/information-for-authors/>, <https://emip.unidu.hr/aims-scope/>,
<https://www.unidu.hr/ekonomska-misao-i-praksa-01/>, <https://hrcak.srce.hr/en/emp>. Retrieved 2026-08-05.

| Item | Value |
|---|---|
| ISSN | 1330-1039 (print) · 1848-963X (online) |
| Indexing | **ESCI (WoS, IF ≈ 0.5)** · **EconLit** · **JEL** · DOAJ · EBSCO · ProQuest · EconBiz · ZBW · CAB · ROAD · Hrčak |
| Scope | Economics — theoretical, applied, **interdisciplinary and methodological**; scope list names **inflation** explicitly |
| Regional emphasis | Central and South Eastern Europe |
| Language | Croatian or English; **abstract and title required in BOTH** |
| Length | **≤ 25 pages including references** |
| Abstract | **≤ 150 words**, third person, must state methodology and results |
| Format | Word (.doc), 16.6 × 24 cm, Times New Roman 10; tables/figures **black and white**, title above (10 pt), source below (9 pt) |
| Citations | **APA**, in-text; references alphabetical by surname |
| Required blocks | Author Contributions · Funding · Conflict of Interest · **AI tool acknowledgment** · Notes · References |
| Title page | Academic title, name, institution, email, **ORCID**, title in HR + EN |
| Submission | Two files — full + **fully blinded** — by email to `ekon.misao@unidu.hr` |
| Review | Double-blind, 2–3 anonymous reviewers |
| Deadlines | **31 March** (June issue) · **30 September** (December issue) |
| Fees | None. Open access, CC BY. |

**Calibration from Vol. 34 No. 1 (2025):** 15 articles, **all in English**, all empirical and quantitative,
CEE/Western-Balkans focus. Categories used: *original scientific paper* (5), *preliminary communication* (7),
*review article* (2). Methods run to econometric modelling, panel models, machine learning. There is precedent
for computational methods (e.g. "Machine Learning in Clean Energy Transition Analysis"), but **no precedent for
media-text or sociology-of-religion work.** Plan accordingly.

Two format statements conflict across the journal's pages (UNIDU says A4 double-spaced; EMIP says 16.6 × 24,
TNR 10). **Action:** email the editorial office to confirm before typesetting. Assume the `emip.unidu.hr` spec.

---

## 2. Where the study stands

Complete, referee-hardened manuscript ([`PAPER_v1.md`](../../studies/inflation-salience/PAPER_v1.md), 2026-07-01),
dormant since 2026-07-03. Numbers verified against the coded core; a hostile domain review already forced three
claims to be demoted. Full state summary in the onboarding brief produced 2026-08-05.

**The expensive asset survives.** All 1,450 annotation decisions are on disk
(`output/coded_labels.csv`, `output/private/coded_pool_full.csv`, `output/private/analysis_core_coded.{rds,csv}`).
Nothing needs re-annotating. What is missing is only the *code* that produced them.

---

## 3. FRAMING — SUPERSEDED 2026-08-05

> **DECIDED (PI, 2026-08-05): the sector framing, NOT the attention-index framing below.**
> The paper studies **the religious sector as an economic sector** — a large non-market service provider with
> no official price statistics — using media coverage as the observation instrument. The sampling-frame
> objection in §3.4 dissolves, because the frame matches the target population by construction and no
> media-wide quantity is estimated.
> **Live execution brief:** [`studies/inflation-salience/EMIP_EXECUTION.md`](../../studies/inflation-salience/EMIP_EXECUTION.md).
>
> Consequences for the rest of this plan: §5.2–5.6 shrink to a light validation pass (differences +
> Newey–West + count-with-offset only); the euro-changeover attention spike is replaced by the
> **delayed-repricing** result; §8's top risk is retired. §1, §4, §6–§10 stand as written.
>
> The rejected alternative is kept below for the record.

### 3.0 (superseded) Attention-index framing

`PAPER_v1` is a sociology-of-religion / media-framing paper. Submitted to EMIP as written it is a desk
reject: wrong literature, wrong contribution, no economic question. **But there is a genuinely economic paper
inside it, and for this venue it is the stronger paper.**

### 3.1 The recommended spine

> **Inflation attention in Croatia, 2021–2023: price coupling, the euro changeover, and the missing
> distributional frame.**
>
> **Pažnja prema inflaciji u Hrvatskoj, 2021.–2023.: povezanost s cijenama, uvođenje eura i izostanak
> distribucijskog okvira.**

The paper becomes a contribution to **media-based inflation-attention measurement** — the Korenok/Munro/Chen,
Pfäuti, Aarab et al. (ECB attention index) and Lamla & Maag line of work, all of which `PAPER_v1` already cites.
That literature is macro/behavioural economics, EconLit-native, and has **no Croatian entry**. The ECB index
covers DE/FR/IT/ES only.

### 3.2 Three contributions, in economics terms

1. **A monthly Croatian media inflation-attention series (2021–2023) validated against HICP.**
   Attention tracks headline HICP at r ≈ 0.73 and food at 0.72; energy decouples (0.44). The ≈4% **attention
   threshold** documented cross-nationally replicates: mean attention 0.49% below the threshold vs 1.17% at or
   above — a 2.4× jump. First evidence for Croatia, and (see §3.4) evidence the threshold survives in media
   content *not* selected on economic relevance.

2. **A euro-changeover salience spike that the price level does not explain — the paper's best hook, and it is
   already sitting in the data unremarked.** Verified 2026-08-05 from `output/h1_attention_hicp_series.csv` and
   `output/hicp_hr.csv`:

   | Month | HICP headline | Attention (% of posts) |
   |---|---:|---:|
   | 2022-10 | 12.7 | 1.49 |
   | 2022-11 | **13.0 (HICP peak)** | 1.15 |
   | **2022-12** | 12.7 (falling) | **2.34 (series max)** |
   | 2023-01 (euro adopted) | 12.5 | 1.26 |

   Attention **doubles in the month HICP starts falling** — December 2022, the month before euro cash
   conversion — then halves again. The attention maximum is not the inflation maximum. This connects directly to
   the euro-changeover perceived-inflation literature (Ehrmann; Eife & Maier; Del Giovane & Sabbatini) and to
   Croatia's own 2023 conversion-and-rounding debate. It is a clean, novel, regionally relevant economic finding.

3. **A measurement-error result for keyword/co-occurrence text indicators.** Attention and topic indices
   (including the ECB's) are built by counting keyword co-occurrence. Coding shows **only 45% of
   proximity-flagged items are genuine**, and a tuned classifier hits a **precision ceiling ≈ 0.4** — a naïve
   count overstates by roughly an order of magnitude. Delivered with a validated three-annotator protocol and
   reported agreement. This is the "methodological work" the journal's scope explicitly invites.

**The substantive religion result is repositioned as the content decomposition of contribution 1:** what the
attention is *about*. Dominated by **non-market/administered fee adjustment** (the "cost of religious life"
register, 37%, rising 41 → 39 → 61 posts across 2022–2024 around the euro conversion) and institutional actors
(34%), with the **distributional "who bears the burden" frame at 3–8%**. In economic terms: inflation discourse
in this corpus is about *administered price resets*, not about incidence. Given Lamla & Maag's finding that news
tone and content shape household inflation expectations, an inflation discourse with almost no incidence content
is an economically meaningful absence — and it complements the macro spike with a micro mechanism.

### 3.3 What gets demoted

- Catholic Social Teaching drops from the paper's spine to **one paragraph** of normative motivation for why
  the distributional frame is the natural benchmark. The "prophetic voice" language goes entirely.
- "Costlier candles, quiet prophets" is a good title for a religion-and-media journal. It is the wrong title
  here. Keep it for the JMR version if that version is ever revived.
- Agenda-setting theory stays but compressed; Iyengar's episodic/thematic survives as the operationalization
  of the distributional frame, which economists read comfortably.

### 3.4 The honest weakness, and how to carry it

The corpus is **religion-filtered** (≥2 distinct religious terms), so this is an attention index over a
religion-salient media subcorpus, not over Croatian media at large. This is the single biggest referee risk at
an economics journal and **must be stated in the abstract, not buried**.

`data/raw/` is empty on this machine (verified 2026-08-05 — only `.gitkeep`), so no pre-filter corpus exists
and a general-media benchmark **cannot be constructed** from current holdings. Two responses, in order:

- **Carry it as a design feature.** The subcorpus is selected on a criterion orthogonal to economics. Finding
  the ≈4% attention threshold *there* is stronger external-validity evidence than finding it in economic news,
  where it is nearly tautological. Frame the index as a **lower-bound attention measure on non-economic media
  content** and every claim follows honestly.
- **Optionally strengthen** by requesting unfiltered monitoring exports from the vendor for a general-media
  comparison series (§9, decision 3). Materially better paper; adds cost and time; not required for submission.

Any claim that the distributional frame is *rarer in religious than in secular* coverage must be dropped. It
was already flagged as unsupported in `REVIEW_RESPONSE.md` (M3).

### 3.5 Alternative framing considered and rejected

*A pure text-as-data methods note* built on contribution 3 alone. Rejected: too thin for 25 pages, and the
journal's actual output is applied empirics, not methods notes. Contribution 3 is better delivered as a section
inside an applied paper.

---

## 4. Blocking work — the reproducibility spine

Nothing else can start until this is done. `PAPER_v1` Appendix A names `10_rerun_fixed.R` … `17_h1_hicp.R`
under a `scratchpad/` directory that **exists nowhere in the repo or in git history**. Tables in the manuscript
are hand-typed markdown. This violates project rule 3 and makes the paper unreproducible and unarchivable.

**4.1 Reconstruct the pipeline as numbered study scripts.** Specification is fully recoverable from
`PAPER_v1.md` §3 and `VALIDATION.md` §v3 (lexicons, metaphor guard, ±220 window, foreign gazetteer,
homonym exclusions).

| New script | Rebuilds | Acceptance test (fixture = surviving outputs) |
|---|---|---|
| `01_tag_inflation.R` | inflation tagging on the master | 8,105 raw → **8,019 clean** |
| `02_linkage_candidates.R` | ±220-char proximity filter | **1,450** candidates |
| `03_finalize_coded.R` | measured core from surviving labels | **652** linked / **132** foreign / **520** core |
| `04_core_analyses.R` | register, outlet, sentiment, stream | Tables 2–5 to the digit |
| `05_attention_index.R` | monthly index + HICP merge | 39-month series; r = 0.73 / 0.72 / 0.44 |

Each script must reproduce its fixture **exactly** or the reconstruction is wrong. This is a strong test — the
outputs were independently numerically verified in June.

**4.2 Port the moral-economy generator discipline.** `26_rsp_tables.R` → `27_sync_tables.R` →
`25_paper_checks.R`: every table becomes a generated markdown fragment, every scalar quoted in prose lands in a
`derived.csv`, and the checker fails the build if a number in the manuscript stops matching. Also ports the
character-count gate — retargeted from RSP's 50,000 characters to EMIP's 25 pages.

**4.3 Environment.** `/capture-environment` → refreshed `renv.lock` + `ENVIRONMENT.md`.

---

## 5. New analysis required for an economics referee

`PAPER_v1` tests H1 with a Pearson correlation and a two-group mean contrast. **That will not survive an
economics review.** The following are additions, not rewrites.

**5.1 Fix the estimation window (correctness, not preference).** The clean series is **2021-01 → 2023-12, 39
contiguous months** — verified 2026-08-05. The manuscript describes it as "the 2021–2024 monitoring stream",
which is wrong: in 2024 the monitoring stream has **February–May missing entirely**, January at n = 1,911 and
July at n = 436 against a normal ~7,000. Correct every statement of the window to 2021–2023.

**5.2 Address the spurious-correlation objection.** Both series trend and peak in 2022; r = 0.73 in levels is
inflated by the common trend. Required:
- unit-root check on both series (ADF/KPSS), reported;
- the relationship in **first differences**;
- **Newey–West HAC** standard errors on the levels specification;
- a short **ADL / distributed-lag** specification with 1–3 lags of HICP.

**5.3 Make the denominator defensible.** Monthly `n_total` swings 4,970–12,860 even in the clean window.
Define the index formally and show robustness to: (i) share of posts, (ii) a **Poisson / negative-binomial count
model with `log(n_total)` offset**, (iii) volume-detrended share.

**5.4 Upgrade the threshold result.** Replace the two-group mean contrast with a **threshold indicator
regression** (`1[HICP ≥ 4]`), reporting bin counts, and a sensitivity sweep over thresholds 2–6% so the ≈4%
break is shown rather than assumed.

**5.5 Settle H2 (resonance vs. setting).** Currently "pending". A **cross-correlation function** of ΔAttention
and ΔHICP at ±6 months is cheap and standard, and closes an open question the current draft leaves dangling.
With n = 39 report it descriptively; do not run Granger tests on 39 points.

**5.6 Formalize the euro-changeover spike (§3.2, contribution 2).** Estimate the attention–HICP relationship,
then show December 2022 as an outlier in the **residuals**; add a changeover indicator and report its size.
Check whether the register composition shifts in the same window. This is a new result and needs its own figure.

**5.7 Human adjudication of ≥100 coded posts — now non-optional.** EMIP requires an AI tool acknowledgment.
Disclosing that all 1,450 items were labelled by LLM annotators with *no* human validation invites a referee to
reject the measurement wholesale. A human-coded slice with reported human-vs-model agreement converts the
disclosure from a liability into a methods strength. Must include the foreign/domestic boundary that defines the
520, plus the 12 disputed register cases.

---

## 6. Manuscript production

- **Category:** target *original scientific paper* (izvorni znanstveni rad).
- **Language:** English (see §9, decision 2), with the required Croatian title, abstract and keywords.
- **Structure:** Introduction · Literature (attention/salience, euro-changeover perceptions, text-as-data
  measurement error) · Data and methods · Results · Discussion · Conclusion. Standard for the journal's output.
- **JEL codes.** Not stated as required, but the journal is EconLit- and JEL-indexed, so include them:
  **E31** (price level, inflation) · **D84** (expectations) · **L82** (media) · **C55** (large datasets) ·
  **Z12** (religion).
- **Budget the 25 pages.** With ~6 tables and 4 figures at journal size, prose gets roughly 15–17 pages. Cut
  Table 5 (sentiment — vendor auto-labels, indicative only, and the weakest evidence in the paper) and merge
  Tables 3 and 4. The `paper_checks` gate enforces the ceiling.
- **Declarations:** Author Contributions, Funding (DigiKat / HKS), Conflict of Interest, AI tool acknowledgment
  (drafted via `scholar-ethics`; must also appear in Methods), Notes, References.
- **Two files**, full and fully blinded — the blinded version must also strip the DigiKat/HKS funding line and
  the repository URLs, which otherwise identify the author immediately.
- **Writing pass:** `scholar-write` in **review-only** mode over the reframed sections, then **single-section**
  redrafts where the panel flags problems. Not full-draft — that would discard June's referee-hardening.
- **Citation pool:** ~15 existing references (APA 7, two still UNVERIFIED per `LITERATURE.md`) plus ~10 new
  economics references on euro-changeover perceived inflation and text-as-data. Build and verify with
  `scholar-citation`'s five-tier check — there is no Zotero library on this machine.

---

## 7. Archiving and open science

- **Replication package** via `scholar-replication`: numbered scripts under a master script, generated tables,
  `derived.csv`, `hicp_hr.csv`, the non-identifying coded labels, AEA-style README, clean-room rerun, and a
  paper-to-code correspondence audit.
- **Disclosure gate:** `output/private/**` never ships (URLs, outlet identities, text excerpts). Run
  `/disclosure-check` on every file in the package, and specifically re-verify that the tracked
  `output/coded_labels.csv` carries no URLs or excerpts.
- **DOI:** deposit the package to Zenodo, cite the DOI in the Data Availability statement. The journal is CC BY
  and DOAJ-listed, so this fits its norms.
- **Master corpus** stays non-redistributable; the statement says so and points to the aggregates.
- **`MEMORY.md`:** add a `[LEARN]` block recording the reconstruction, the corrected 2021–2023 window, and the
  euro-changeover finding.

---

## 8. Risks, stated plainly

| Risk | Severity | Mitigation |
|---|---|---|
| Religion-filtered sampling frame reads as unrepresentative to an economics referee | **High** | §3.4 — state it in the abstract, argue it as an orthogonal-selection external-validity design, bound every claim |
| Topic reads as marginal to economics | Medium | Contributions 1 and 3 are corpus-general; religion is the application, not the subject |
| Levels correlation attacked as spurious | Medium | §5.2 — differences, HAC, ADL |
| LLM annotation rejected as unvalidated | Medium | §5.7 — human-adjudicated slice, reported agreement, full AI disclosure |
| Pipeline reconstruction fails to reproduce the fixtures | Medium | If it cannot hit 8,019 / 1,450 / 520, stop and escalate — a mismatch means the published numbers are not what the described method produces |
| 25-page ceiling | Low | §6 budget; enforced by the checker |
| Format spec ambiguity | Low | Email the editorial office |

---

## 9. Decisions needed from the PI

1. **Approve the reframe** (§3). Substantial repositioning; everything downstream depends on it.
2. **Language** — English or Croatian. Recommend **English**: the issue inspected was 100% English, and it
   maximizes ESCI/EconLit reach. Croatian abstract and title required either way.
3. **Pursue unfiltered vendor exports** for a general-media benchmark? Materially stronger paper; adds cost and
   schedule risk. Recommend **no** for this submission, and flag it as the obvious extension.
4. **Who performs the human adjudication** of ≥100 posts (§5.7). PI, a coder, or a student — but a human.
5. **Article category** — original scientific paper (recommended) or preliminary communication.
6. **Authorship and order**, plus ORCID for the title page.

---

## 10. Schedule to 30 September 2026

| Week | Work |
|---|---|
| 1 (Aug 5–11) | PI decisions §9. Confirm format spec with the editorial office. Reconstruct scripts 01–03, hit the fixtures. |
| 2 (Aug 12–18) | Scripts 04–05. Port the table generator + checker. Capture environment. |
| 3 (Aug 19–25) | New econometrics §5.2–5.6, including the euro-changeover result and its figure. |
| 4 (Aug 26–Sep 1) | Human adjudication slice §5.7. Build and verify the citation pool. |
| 5 (Sep 2–8) | Reframed draft: Introduction and Literature rewritten to the economics spine; Results re-cut. |
| 6 (Sep 9–15) | `scholar-write` review panel; revisions; Croatian abstract, title, keywords; JEL codes. |
| 7 (Sep 16–22) | Replication package, Zenodo DOI, declarations, disclosure check. Typeset to journal format. |
| 8 (Sep 23–29) | Blinded version, final numeric verification, mock referee pass (`/review-paper`), submit. |

Two weeks of slack are absent by design — the reconstruction in weeks 1–2 is the only step that can fail
unrecoverably. If the fixtures do not reproduce by **August 18**, target the **31 March 2027** deadline for the
June 2027 issue rather than compressing validation.
