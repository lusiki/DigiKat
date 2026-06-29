# Research brainstorm — Welfare state & social insurance in Croatia's Catholic-themed media

**Status:** brainstorm / scoping note (not yet a plan or a study)
**Date:** 2026-06-29
**Context:** Computational (NLP) reframing of a proposed mixed-methods study on how Catholic media
construct the image of the welfare state (*socijalna država*) and social insurance, and how far that
construction rests on Catholic Social Teaching (*Katolički socijalni nauk*, KSN).
**Corpus:** DigiKat master — ≈610k posts, 2021–2025, religious-term-filtered (≥2 distinct matches).

> This file consolidates the brainstorm so it's available on any device after `git pull`. It captures
> (a) the original proposal in brief, (b) the computational reframing, (c) the grounding scan of the
> actual data infrastructure, (d) candidate article framings, and (e) the concrete next step.

---

## 0. The original proposal in one paragraph

The seed proposal is a classic **manual mixed-methods content analysis** (NVivo/MAXQDA, hand-coded
codebook, thematic analysis à la Braun & Clarke, elements of critical discourse analysis) of articles
in named Catholic outlets (Glas Koncila, IKA, Bitno.net, Verbum, Laudato TV, Hrvatski katolički radio).
Its goals: (1) quantify which **areas of social insurance** are most thematized (health, pensions,
unemployment, family/maternity benefits, social care for vulnerable groups); (2) assess the **normative
stance** toward the existing welfare model (support / critique / call for reform); (3) analyse the
**discursive frames** (Christian solidarity, subsidiarity, common good, preferential option for the
poor vs. demographic renewal, critique of neoliberalism/individualism); (4) **compare** media content
with KSN encyclicals (Rerum novarum, Quadragesimo anno, Centesimus annus, Caritas in veritate,
Laudato si', Fratelli tutti); (5) examine differences between outlets and shifts over time.

**Main RQ:** *How do Catholic media in Croatia construct the image of the welfare state and the social
insurance system, and to what extent is that image shaped by the principles of Catholic Social Teaching?*

---

## 1. The core reframing (why go computational)

The seed design is valid but does not use what DigiKat *is*: a 610k computational corpus with udpipe
lemmatization, a 16-category dictionary engine, sentiment lexicons (CroSentilex / CroSentilex Gold /
lilaHR), an actor typology, and an event-study layer. The interesting move is to do this study
**computationally at scale while preserving interpretive depth** — and the proposal's codebook
translates almost 1:1 into DigiKat's dictionary machinery.

---

## 2. Three decisions that shape everything

### 2.1 Sampling frame — term-corpus vs. Catholic-outlet sub-corpus (the big one)
The corpus is defined by a **religious-term filter (≥2 matches)**, not by outlet. A post enters because
it *talks about Catholic themes*, regardless of publisher. Consequence:
- It captures **religiously-inflected welfare discourse wherever it appears** (secular + religious outlets).
- It *misses* a straight pension-policy piece in a Catholic outlet that uses <2 religious terms.

**Fork:** (i) "how is welfare framed *wherever* Catholic themes surface in Croatian media" — the corpus is
built for this; or (ii) "how *Catholic outlets specifically* cover welfare" — narrower, needs the source
split. Recommendation: lean into (i), and add a **Catholic-vs-secular comparison** — more novel than a
qualitative re-read of Glas Koncila.

### 2.2 Time window — 2021–2025, NOT 2015–2025
The corpus starts in 2021. The migrant crisis (2015/16) is **out of scope**. In scope: the COVID tail
(2021–22), the **inflation / energy / cost-of-living crisis (2022–23)**, demographic/family-policy debates,
pension reform. The *Fokus na događaje* (event-study) layer is built for exactly this. Five years gives
within-period dynamics, **not** the decade-long discursive shift the proposal imagines — be honest about this.

### 2.3 The ≥2-match rule means the welfare sub-corpus is *already* "welfare seen through a Catholic lens"
A feature for an interpretive claim about KSN framing, but it bounds the claim, and it makes **feasibility
the first empirical question** (see §6).

---

## 3. The bridge: the proposal's codebook → DigiKat dictionary layers

The codebook becomes new sub-dictionaries slotted alongside the existing 16-category scheme (same method
as the *Tematske struje* layer):

- **Welfare-domain lexicon** — 6 domains: *zdravstveno, mirovinsko, nezaposlenost, obiteljska/rodiljna
  davanja, socijalna skrb, stanovanje/rad*.
- **KSN-principles lexicon** — *solidarnost, supsidijarnost, opće dobro, preferencijalna opcija za
  siromašne, dostojanstvo osobe, pravedna raspodjela*.
- **Encyclical / papal reference detector** — Rerum novarum, Quadragesimo anno, Centesimus annus,
  Caritas in veritate, Laudato si', Fratelli tutti + papal names. (Expect this to be **sparse** — likely a
  small qualitative sub-study, not a quantitative pillar.)

Run at scale this yields volume-by-domain × source × time, plus the publishable descriptive result:
**which KSN principles co-occur with which welfare domains** (does *supsidijarnost* cluster with family
benefits? *solidarnost* with pensions?).

---

## 4. The hard part: normative stance & framing

Dictionaries find *topics*; they do not reliably find *stance* or *frame*.

- **Stance ≠ sentiment.** Do NOT proxy "supports the welfare model" with CroSentilex valence — different
  constructs. For nuanced stance, the modern, referee-proof path is **dictionary-for-recall +
  LLM-for-precision**: lexicons retrieve all welfare-relevant docs at scale; a zero/few-shot Claude
  classifier then labels each *sampled* doc on {domain, stance (support/critique/reform), KSN principle,
  encyclical, political target}, **validated against a human-coded gold set** (report inter-coder κ).
  This *is* the mixed method the proposal wants — at scale.
- **Frames:** run an **STM (structural topic model)** on the welfare sub-corpus — frame prevalence can vary
  by source and over time, directly answering "tradicionalni vs. suvremeni outlets" and "shift around
  COVID / inflation." Then close-read (Braun & Clarke) exemplar docs per frame.

---

## 5. Article menu (one corpus → several papers)

- **A — "Mapping welfare-state discourse in Croatia's Catholic media space"** (descriptive; *safest first
  paper*): the dictionary map + domain × source × time + principle–domain co-occurrence. Fully leverages
  existing infrastructure.
- **B — "Solidarnost or supsidijarnost? Competing frames of social protection"** (framing/interpretive):
  STM → frames → mapped onto KSN, with qualitative close-reads. The substantive sociology-of-religion
  contribution.
- **C — "Faith, crisis, and the welfare state, 2021–2025"** (event-study): interrupted time series of
  domain prevalence + sentiment around COVID and the cost-of-living crisis.
- **D — "Catholic vs. secular framing of social protection"** (comparative): when Catholic themes appear,
  do Catholic outlets frame welfare differently than secular ones? Novel precisely because the corpus
  spans outlet types. **Now confirmed feasible** (see §6).

Suggested sequence: **A → (B or C)**, with D as the ambitious one.

---

## 6. Grounding scan — what the actual data supports

A read of the pipeline/pages (read-only) established the following.

### 6.1 You're not building greenfield — category 9 already exists
The 16-category dictionary already contains **`KARITAS_I_SOCIJALNA_PRAVDA`** (terms: *caritas, pomoć,
siromaš, humanitar, solidarn, socijaln, izbjeglic, potres, volonter*). The welfare-state study is the
**deepening of an existing category**, sitting at the intersection of three current categories:
- **9** `KARITAS_I_SOCIJALNA_PRAVDA` (solidarnost, siromaštvo, socijalno)
- **7** `POLITIKA_I_ODNOS_S_DRZAVOM` (vlada, zakon, sabor, EU)
- **8** `BIOETIKA_I_KULTURNI_RATOVI` (obitelj, život, djeca → family/demographic-policy domain)

Clean framing: *category 9 is currently a coarse bucket; we decompose it into welfare domains × KSN
principles.* Adding a sub-dictionary is low-barrier (one named vector). **First extract**
`thematic_dictionaries_v3` into a shared `R/thematic_dictionaries.R` — it is copy-pasted across
`mapa_stats.qmd`, `diskurs.qmd`, `događaji.qmd` (a Phase-0 backlog item).

### 6.2 Paper D (Catholic vs. secular) is feasible
Sources are identifiable via the **`FROM`** column — **bitno.net** and **LaudatoTV** are named explicitly,
alongside mainstream (vecernji.hr, jutarnji.hr, index.hr). There is **no** pre-built "is this a Catholic
outlet" flag, so the one build cost is to **hand-classify the top-N `FROM` values** into outlet types once.

### 6.3 Technical gotcha that protects against a bad result
The dictionary method is **crude substring counting** on lowercased raw text (`str_count`, dominant =
argmax) — **not** lemma-based. So `"socijaln"` matches **socijalne mreže** (social media!) and **socijalni
radnik** as readily as **socijalna država**. Implications: (a) the *existing* category-9 numbers may already
be contaminated — worth checking; (b) it is the empirical case for the dictionary-for-recall +
LLM-for-precision pipeline, rather than trusting raw substring counts.

### 6.4 Engagement angle unlocked
`INTERACTIONS`, `ENGAGEMENT_RATE`, `REACH` are present → **which welfare frames get amplified?** Does
*solidarnost* or *demografska obnova / kritika neoliberalizma* drive more engagement? Ties the discourse to
the actor typology (**Divovi / Graditelji zajednica / Megafoni / Specijalizirani akteri**).

### 6.5 Key variables confirmed
- **Time:** `DATE` (2021-01-01 – 2025-12-31), `year` (numeric).
- **Engagement:** `INTERACTIONS`, `ENGAGEMENT_RATE`, `REACH`.
- **Text:** `FULL_TEXT` (filtered to `nchar > 100` on analytical pages).
- **Platform:** `SOURCE_TYPE` ∈ {web, youtube, facebook, twitter, reddit, forum, comment} (TikTok excluded).
- **Source/account:** `FROM`. **Filter metadata:** `root_match_count`, `matched_terms`, `matched_words`,
  `matched_sentences`. **No language column** (assumed Croatian).

---

## 7. Concrete next step — the feasibility probe

Before committing to any design:
1. Draft a **welfare-domain + KSN lexicon** (deepening category 9).
2. Run it over a **stratified 2–5% sample** of the corpus.
3. Report **both** raw doc counts per domain **and** a **false-positive scan** on the noisy stems
   (`socijaln`, `obitelj`).

This tells us in one pass whether there is enough religiously-inflected welfare discourse to carry a
computational paper, and how much LLM-precision filtering is actually needed. Rough decision rule:
~15k clean docs → full computational treatment; ~300 → the study becomes mostly qualitative.

**Environment note:** the probe needs R + the master `.rds`. Run on the pipeline machine where R + data
live (check `CLAUDE.local.md` for `R_AVAILABLE`); otherwise emit the script and hand off. Use
`/data-analysis` (sample-first; never dumps 610k rows).

---

## 8. Open forks (the author's call — not feasibility-limited)

1. **Whose framing is the target** — religiously-inflected welfare discourse *across all outlets* (what the
   corpus does best) vs. *Catholic outlets specifically* (needs the source split). The data supports either.
2. **One paper or a programme** — Paper A for a fast first publishable unit, or the A→B→C arc for a
   thesis/programme.

## 9. Rigor checklist (for whichever design)
- A new dictionary needs **validation**: precision/recall against a hand-labeled sample (`/check-lexicon`).
- **Stance ≠ sentiment** — keep them distinct constructs.
- Report the **sensitivity** of the welfare sub-corpus to the ≥2-match threshold.
- Encyclical references will be **sparse** — manage expectations.
- The "tradicionalni vs. suvremeni" outlet split needs an **a priori, defensible** classification, not post-hoc.
- The substring-matching method is recall-oriented and **noisy** — disambiguate `socijaln` / `obitelj` etc.
