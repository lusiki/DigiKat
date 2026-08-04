# Charity for the Poor, Institutions for Everything Else: Religion and the Economy in the Croatian Digital Media Space, and the Limits of Meaning-Based Measurement

**Luka Šikić**
Catholic University of Croatia (Hrvatsko katoličko sveučilište), Zagreb — Department of Communication Studies
*DigiKat project. Working manuscript, first complete version (2026-08-04). Authorship and order to be finalized.*

---

## Abstract

Catholic Social Teaching claims a distinctive voice on economic life, and its flagship commitment — the
preferential option for the poor — implies that poverty should be the site where that voice speaks most
structurally. We test this across an entire national digital media space, and we test it twice, with two
independent instruments. Using the DigiKat corpus (**710,307** religion-salient Croatian/Bosnian media posts,
January 2021 – June 2026), we tag eleven economic domains with an auditable keyword filter and measure
proximity-based religion–economy linkage (**132,519** linked candidates), then score every post in the corpus
against calibrated embedding anchors, and finally hand-code a stratified **555-post** gold sample on seven
axes with three blind coders (Fleiss κ = 0.94 for genuine linkage, 0.74 for the five-way register).

Three results. First, **co-occurrence is not engagement, at scale**: only **34.6%** of linked candidates are
genuine religion↔economy engagement, so raw keyword counts overstate religious economic discourse by roughly
threefold. Second, **the register flip is real but is a charity flip, not a justice flip**. Among genuine
links, poverty is met with charity or devotional language **70.6%** of the time versus **23.4%** for all other
domains; the justice register is only modestly lower for poverty (21.2% vs 27.1%). Religion does not respond
to poverty with structural critique — it responds with almsgiving and spiritual framing — but it is not
markedly *more* structural elsewhere either, and outside poverty it speaks mainly as an institution. Third,
against the study's own prior expectation, **the meaning lens does not recover what keywords miss**. At
matched volume the two lenses select the same posts only **19.7%** of the time, yet posts the embedding lens
adds are just **10.2%** genuine links [5.5, 18.3], against **29.3%** [17.6, 44.5] for posts it drops. On
finding genuine links the transparent keyword filter outperforms the embedding roughly 3:1.

We also refute a claim from our own pilot: the poor are **not** overwhelmingly mediated as a doctrinal
category. Hand coding puts the split at **44.7% doctrinal / 40.4% economic / 14.9% mixed** (n = 94), not the
~73% doctrinal the embedding reported; that number was an artifact, and the embedding classifier failed its
pre-declared validation gate by 52 percentage points. Methodologically, we show that embedding anchors built
from *invented concept sentences* are negatively rank-correlated with an auditable keyword ranking
(ρ = −0.38) while anchors built from *vouched-for posts* are strongly positive (ρ = +0.96), and that the
register grid's domain ordering is not stable across anchor construction. We conclude that meaning-based
measurement in this setting is trustworthy for *classifying* discourse once validated (register agreement
with humans, Cohen κ = 0.72) and untrustworthy for *finding* it.

**Keywords:** digital religion; Catholic Social Teaching; media framing; embeddings; measurement validation;
computational text analysis; Croatia.

---

## 1. Introduction

Between 2021 and 2026 Croatia compressed a macroeconomic decade into five years: a cost-of-living shock, an
energy crisis, euro adoption in January 2023, a tight labour market and a housing squeeze. Catholic Social
Teaching (CST) has an explicit stance on all of it, and its most cited commitment — the preferential option
for the poor — carries an implication that is empirically checkable: where poverty is discussed, religion
should speak structurally, naming causes rather than dispensing relief.

This paper asks where religion's economic voice actually goes in a national digital media space, in what
register, and — because the answer turns out to depend on how you measure — whether two independent
measurement instruments even agree about which discourse they are describing.

The paper has an unusual shape because its most robust findings are partly about method. We designed a
dual-lens study in which a transparent keyword filter and a meaning-based embedding model measure the same
corpus and check each other, expecting convergence on substance with informative divergence at the margins.
We found convergence at the level of *aggregate ranking* and near-total divergence at the level of *individual
posts*, and hand coding shows the divergence runs against the embedding. We report that as a finding rather
than smoothing it, because it bears directly on a fast-growing practice: using embedding similarity to
constitute a corpus subset and then describing that subset as if it were the discourse.

## 2. Data

**Corpus.** The DigiKat master comprises 710,307 posts (47 variables) from Croatian and Bosnian media,
January 2021 – June 2026, retained when a post matches at least two *distinct* religious terms from a frozen
95-term lexicon. The corpus is therefore religion-*salient* and topical rather than source-based: it mixes
confessional outlets with secular mainstream media, and roughly 74% of posts are web portals, 13% Facebook,
9% YouTube.

**The collection seam.** A `data_source` marker splits the corpus into two time-segregated streams: an
ongoing monitoring query covering 2021–2024 (≈269.6k posts) and a filter-based backfill covering 2024–2026
(≈440.7k). Year-over-year volume is confounded by this change in collection method, and the streams differ
sharply in platform mix. Every temporal claim below is computed *within* the 2021–2024 monitoring stream, and
every cross-lens comparison is computed within platform × stream cells and post-stratified.

**Keyword layer (Stage A).** Eleven register-neutral economic domain regexes were applied to the full corpus,
and for each matched domain we recorded whether a religious term falls within ±220 characters of a domain
match — a *linkage candidate*. This yields 132,519 linked candidate rows (a post can be a candidate in more
than one domain). Domain linkage rates range from 19.0% (inflation) to 53.8% (poverty).

**Meaning layer.** All 710,307 posts are embedded with a local `bge-m3` model (1024 dimensions) in a DuckDB
vector store. Embedding input is truncated at the first 4,000 characters, which affects 30.4% of posts (39.7%
of web posts). We verify that the store's document identifiers map exactly onto master row indices (500-post
check, 100% exact match on both URL and date) and that stored vectors are unit-norm before any scoring.

## 3. Method

### 3.1 The two lenses

The keyword lens is transparent, auditable term by term, and captures *physical proximity* of religious and
economic language. The meaning lens is recall-friendly, insensitive to exact wording, and captures what a
post is *about* at document level. Neither is ground truth. The design principle is that convergence is a
claim to be measured, not an assumption.

### 3.2 Anchor calibration, and a correction to our pilot

An earlier pilot scored the corpus against hand-written Croatian concept sentences under raw cosine
similarity with winner-take-all assignment. That instrument assigned 6.5% of a background sample to
`euro_changeover` — a domain for which the keyword lens finds 407 linked posts, the smallest of eleven.

We diagnosed this and rebuilt the instrument. Two design choices were crossed in a 2×2 (Table 1): anchor
source (invented sentence vs centroid of posts the keyword lens vouched for) and space (raw cosine vs
mean-centred). The corpus is strongly anisotropic — random post pairs sit at cosine 0.354 and the corpus mean
vector has norm 0.596 — so we expected centring to be the decisive correction. It was not.

**Table 1. Instrument comparison (50,000-post background sample, decoy set held constant).**

| anchor source × space | Spearman ρ vs keyword ranking | euro share |
|---|---|---|
| hand sentences × raw (**the pilot**) | **−0.382** | 6.5% |
| hand sentences × centred | +0.091 | 1.9% |
| seed centroids × raw | +0.955 | 0.7% |
| seed centroids × centred (**adopted**) | **+0.964** | 1.3% |

Anchor source moves rank agreement from −0.38 to +0.96; centring moves it by 0.009. We retain centring (it
is theoretically motivated and costless) but the correction is the seed centroid. We note that agreement with
the keyword ranking is a *convergence* check, not an accuracy measure; it is read alongside the euro share,
which is a known-wrong answer.

A second artifact is worth recording because it nearly reached publication. When domain anchors are centroids
of *posts* but the non-economic decoy anchors are short *sentences*, the post-shaped anchors win almost every
comparison, and the eleven domain shares summed to 0.998 of a corpus that is overwhelmingly about faith.
Anchors that are compared against each other must be constructed the same way.

### 3.3 Why no unsupervised threshold is reported

Each domain anchor's ability to separate its own held-out seeds from background posts is AUC 0.73–0.92: good
enough to rank, not to threshold. At a 1–5% base rate, a cut that captures 80% of known seeds admits 25–56%
of the corpus. Coverage is therefore reported under three operating rules, and the operating point for
classification is fitted against hand-coded data rather than chosen a priori.

### 3.4 The gold sample

We drew a stratified 555-post sample — top-ranked posts per domain, register cells, poverty-margin bands, and
both cross-lens disagreement strata — excluding every post used to build an anchor. Three blind coders coded
seven axes from the codebook, seeing only the text, the ±220-character window and the assigned domain: no
outlet, date, URL, stratum, or machine label. The sample was split 50/50 into FIT and VALIDATE *before*
coding; FIT rebuilds the register anchors and fits margins, and every reported agreement statistic comes from
VALIDATE. Seven pass floors were declared in advance.

## 4. Results

### 4.1 Two thirds of the linked pool is not a genuine link

Majority-adjudicated across three coders, **34.6%** of the gold sample (192 of 555) is genuine religion↔economy
engagement. Among the posts the meaning lens ranks *highest* per domain, the rate is 38.4% [32.2, 44.9].
Inter-coder reliability on this axis is very high (Fleiss κ = 0.941), so the estimate is not a coding artifact.

The implication is blunt: **raw counts of "religion and the economy" in a keyword-filtered corpus overstate
engagement by roughly a factor of three.** Typical false positives are homonyms (`zadužen za` = "responsible
for", not "indebted"; `posvećen` = "dedicated"; `primanje` of a sacrament rather than of income), secular
economic news in which a church appears as a venue or a street name, and religious articles in which an
economic term appears incidentally.

Genuine-link rates differ sharply by outlet type: **67.0%** in confessional outlets versus **33.7%** in
secular ones (outlet labels are PI-assigned and indicative). Among genuine links, religion appears as an
economic *actor* 64.1% of the time and as a *commentator* 33.3%; 30.2% concern foreign rather than domestic
economies.

### 4.2 Coverage: the ranking converges, the posts do not

Under winner-take-all assignment the meaning lens reproduces the keyword ranking almost exactly
(Spearman ρ = **+0.982**, bootstrap 95% CI over domains [+0.85, +1.00]); poverty ranks first under both, and
the ordering is stable within platform × stream cells (ρ range +0.68 to +0.955, post-stratified +0.844) and
on the untruncated subcorpus (ρ = +0.964).

That convergence is fragile to the operating rule, however. A robust z ≥ 3 threshold *inverts* the ranking
(ρ = **−0.682**) and returns `euro_changeover` to first place — the pilot's artifact in new clothes. A
recall-anchored threshold gives ρ = +0.736. Ranks move by up to ten positions across rules. We report the
winner-take-all ranking as the headline because it is the only rule whose failure mode we can externally
check, and we report the spread rather than concealing it.

At matched volume — each lens selecting exactly as many posts per domain — the two lenses overlap on only
**19.7%** of posts (range 10.1% for demography to 30.2% for green energy). Aggregate agreement and post-level
agreement are simply different things here.

### 4.3 The divergence runs against the meaning lens

Because a raw gap is a *candidate* gap, we hand-coded both sides. Posts the meaning lens selects that keywords
miss are **10.2%** genuine [5.5, 18.3]. Posts keywords select that the meaning lens misses are **29.3%**
genuine [17.6, 44.5]. The proposal predicted the embedding would be recall-complete, recovering paraphrase
that regexes cannot see. The data say the opposite: what the embedding adds is mostly topically-adjacent
religious or economic material without a genuine link between the two.

This is the paper's main methodological result, and it generalizes beyond this corpus: **document-level
semantic similarity is a poor instrument for detecting a relation between two topics within a document.**
The keyword lens wins here precisely because ±220-character proximity encodes the relation, while a
whole-post embedding encodes only aboutness.

### 4.4 Register: charity for the poor, institution for the rest

The register question is where the meaning lens earns its place, because a regex has no register. After
rebuilding register anchors from coded FIT posts, machine and human labels agree at Cohen κ = **0.717**
(5-way, VALIDATE) and all six register shares fall inside the human bootstrap 95% CI — both pre-declared
gates pass.

We nonetheless lead with the hand-coded distribution, for a reason given in §4.6: the machine grid's *domain
ordering* is not stable across anchor versions. Among the 192 genuine links (Table 2):

**Table 2. Register of genuine religion↔economy links (hand-coded, majority of three, n = 192).**

| register | share |
|---|---|
| charity | 25.5% |
| justice | 24.5% |
| object_institution | 22.9% |
| devotional | 18.8% |
| object_cost_relig_life | 7.3% |
| other | 1.0% |

The domain contrast is the substantive finding:

| | poverty (n = 85) | all other domains (n = 107) |
|---|---|---|
| charity + devotional | **70.6%** | **23.4%** |
| justice | 21.2% | 27.1% |

**Religion meets poverty with almsgiving and spiritual framing, and meets the rest of the economy as an
institution.** The naïve CST reading — that the preferential option for the poor makes poverty the site of the
loudest structural-justice voice — is not supported. But the finding is not the mirror image the pilot
suggested either: justice is only modestly higher outside poverty (27.1% vs 21.2%), and outside poverty the
dominant registers are institutional rather than structural. The flip is a *charity* flip.

### 4.5 The poor: not doctrinal after all

Our pilot reported that ~73% of talk about "the poor" was doctrinal-spiritual rather than material-economic,
and treated this as a headline. It does not survive. Hand coding of 94 poverty-domain posts (Fleiss
κ = 0.891) gives **44.7% doctrinal / 40.4% economic / 14.9% mixed** — close to even.

The embedding classifier failed its pre-declared gate for this quantity under both anchor versions (deviation
29.6 pp with probe anchors; 52.2 pp with coded anchors, which pushed 73% of validation posts into *mixed*).
Per our pre-registered fallback, the machine estimate is **withheld** and the hand-coded number stands alone.
The lesson is specific and transferable: a two-anchor contrast in embedding space can produce a confident,
stable, entirely wrong ratio, and only labelled data reveals it.

### 4.6 What did not survive

- **The register grid's domain ordering is anchor-version dependent.** With probe anchors, poverty has the
  lowest justice share of eleven domains (7.2%); with anchors rebuilt from coded posts, poverty rises to
  fourth (12.5%) and green energy jumps to 48.1%. The *human-coded* contrast in §4.4 does not depend on
  anchors and is what we report.
- **H4 (crisis windows) is not supported directionally.** Within the 2021–2024 monitoring stream, comparing
  the 2022-06…2023-03 shock window against adjacent calm windows, 3 of 11 domains show a Holm-significant
  shift in justice share — but two move the *wrong* way (green energy 89.6% → 56.2%; unemployment 33.4% →
  15.7%), and only housing rises (3.8% → 8.5%). We report no support for a crisis-driven rise in structural
  framing.
- **Per-domain retrieval precision failed its gate** (mean 0.385 against a 0.70 floor). We note a
  specification problem in our own gate: it uses the genuine-*link* axis as the criterion, so it measures the
  genuineness of the religion↔economy pair rather than whether the anchor retrieved on-topic posts. The
  codebook has no "is this post about domain d?" axis. The 38.5% figure is reported for what it is.

## 5. Discussion

For sociology of religion and media studies, the substantive contribution is a measured, corpus-wide picture
of how a national mediasphere renders religion's economic voice — and it is not the picture CST's own
self-description implies. Where poverty appears, the response is overwhelmingly charitable and devotional
(70.6%); structural critique is a minority register everywhere and is not concentrated where the doctrine
would place it. Religion's economic presence outside poverty is largely *institutional*: the Church as
employer, property-holder, contracting party, and as the provider of services whose prices rise.

That pattern is consistent with an episodic rather than thematic framing regime, and it echoes our sister
study on inflation, which found the structural-justice register marginal and the Church surfacing mainly as
an institution whose services became more expensive. Two independent studies of the same corpus, with
different domains and different instruments, now point the same way.

For computational social science, the contribution is a cautionary and reusable result. Embedding retrieval is
increasingly used to constitute study populations. Our evidence is that it is *good at classifying* discourse
once an operating point is fitted to labelled data (register κ = 0.72, share containment 6 of 6) and *poor at
constituting* it (10.2% precision on what it uniquely adds). The asymmetry has a clean explanation: document
embeddings encode aboutness, not within-document relations, and most interesting social-science constructs are
relations. Where the construct is "topic A engaging topic B," proximity beats similarity.

## 6. Limitations

1. **The coders are not human.** The three "independent" coders are three blind passes by one large language
   model with differing framing emphasis. The reported Fleiss κ (0.74–0.94) is *inter-pass* reliability and
   overstates what independent human coders would achieve on the same instrument. A human double-code of a
   pre-declared slice was planned and, at the PI's direction, not performed; it should precede preregistration.
2. **Small n on the substantive claims.** The register contrast rests on 192 genuine links and the poverty
   split on 94 posts. Intervals are wide and are reported.
3. **Outlet labels are indicative,** PI-assigned, and cover roughly half the corpus; the confessional/secular
   contrast in §4.1 should be read as suggestive.
4. **Document-level truncation.** 30.4% of posts exceed the 4,000-character embedding input; the coverage
   ranking is robust to this (ρ 0.982 → 0.964), but topic detection deep in long articles is under-powered.
5. **The absolute "economic share" is not identified.** Winner-take-all assigns 55.5% of a religion-filtered
   corpus to some economic domain, which is not credible; eleven domain anchors against four decoys win on the
   order statistic. Only relative ranking is used.
6. **One corpus, one language, one confession.** Generalization beyond Croatian Catholic media is untested.

## 7. Data, code, and ethics

All analysis scripts are in `studies/moral-economy/` (`sem_lib.R`, `05`–`10`), each writing a manifest with
input hashes. Aggregate outputs are tracked and shareable; row-level text, URLs, source identities and coding
sheets are restricted to gitignored `output/private/`, enforced in code. The master corpus is not
redistributable.

**AI-use disclosure.** All 555 gold-sample codings were produced by a large language model (three blind
passes, majority-adjudicated), not by human annotators. Coding used blind excerpts of at most 800 characters
with outlet, date and URL removed; this transmission of restricted corpus text to an external model provider
is an explicit, PI-authorised exception to the project's local-only processing rule, recorded in
`output/semantic/gates.json`. Embedding was performed locally.

## 8. What would strengthen this paper

1. Human double-coding of ≥100 gold posts, to convert inter-pass reliability into inter-annotator reliability.
2. A domain-topicality axis in the codebook, so retrieval precision can be measured separately from link
   genuineness.
3. Chunk-level embedding, which would let the meaning lens see within-document proximity and would test
   directly whether the 3:1 keyword advantage is an artifact of document-level representation.
4. Preregistration of the register contrast (§4.4) as a confirmatory test on a fresh coded sample.
