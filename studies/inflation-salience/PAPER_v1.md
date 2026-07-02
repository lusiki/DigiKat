# Costlier Candles, Quiet Prophets: How Religion Meets Inflation in the Croatian Digital Media Space, 2021–2026

**Luka Šikić**
Catholic University of Croatia (Hrvatsko katoličko sveučilište), Zagreb — Department of Communication Studies
*DigiKat project. Working manuscript, first complete version (2026-07-01). Authorship and order to be finalized.*

---

## Abstract

Catholic Social Teaching (CST) assigns the Church a distinctive voice in economic hardship: to name inflation
as an injustice that falls hardest on the poor. We ask what that voice actually sounds like in a national
digital media space during a cost-of-living shock. Using the DigiKat corpus — 710,307 religion-salient
Croatian/Bosnian media posts (January 2021–June 2026) — we isolate every post that mentions inflation and,
crucially, distinguish *genuine* religion–inflation linkage from incidental co-occurrence. Most co-mentions
prove incidental; after coding 1,450 proximity-selected candidates with three independent annotators
(inter-annotator agreement 0.97) and setting aside foreign-country inflation, a measured domestic core of
**520 posts** remains — 0.07% of the (web-portal-dominated) corpus and 6.5% of inflation-mentioning posts.
Within it, religion meets inflation overwhelmingly as an **economic object**: a macro-register combining *the
rising cost of religious life* and *the Church-as-institution* accounts for ≈72% (individually 37% and 34%, an
ordering within coding noise). *Charity* accounts for 17%, while the **structural / CST-justice register is
marginal** — 3% under strict coding, at most ≈8% if latent structural framing in adjacent posts is counted.
We formalize and evaluate four theory-derived expectations. Media inflation-attention is strongly
**price-coupled** (H1 supported: Pearson r ≈ 0.73 with the Croatian HICP within a confound-free window, with a
2.4-fold jump above the ≈4% attention threshold), yet the religious justice voice does not fill that attention
(P3 disconfirmed); framing is episodic rather than thematic (P4 supported). We argue that the justice-centred
frame CST foregrounds has **low visibility in the digital public sphere** — the Church surfaces as an
institution whose services became more expensive, not as a prophetic voice — while cautioning that
media-visibility is a weak proxy for the institution's conduct. Beyond the substantive finding, the paper
offers a transferable methodological caution: in keyword-filtered corpora, co-occurrence is not engagement, and
linkage must be measured, not counted.

**Keywords:** digital religion; inflation salience; Catholic Social Teaching; media framing; agenda-setting; Croatia; computational text analysis.

---

## 1. Introduction

Between 2021 and 2026 Croatia lived through the sharpest cost-of-living shock in a generation, compounded by the
adoption of the euro on 1 January 2023. Catholic Social Teaching has an unusually explicit stance on such
moments: from the "preferential option for the poor" to Pope Francis's "this economy kills" (*ova ekonomija
ubija*), doctrine frames economic hardship as a *structural* injustice the Church is called to name on behalf
of the vulnerable. In a country where the Catholic Church is a dominant cultural institution and operates one
of Europe's more developed religious media ecosystems, one might expect the digital public sphere to carry an
audible religious-economic voice when prices spike.

This paper asks a deliberately simple question: **when inflation surfaces in religion-salient Croatian digital
discourse, who carries it, and in what register?** We do not assume the Church is loud on the economy; we
measure whether it is, and how. The answer turns out to be less about prophecy than about price lists.

Three contributions follow. Substantively, we provide the first measurement of the religious register of
inflation discourse across an entire national digital media space, and document a gap between CST's normative
promise and observed practice. We combine this description with four theory-derived hypotheses and propositions
(§2.4): one — that media inflation-attention tracks real prices — is tested quantitatively against the
Harmonised Index of Consumer Prices (HICP) and supported, while the CST-derived expectation of a prophetic
justice voice is evaluated and disconfirmed. Methodologically, we show that the naïve approach — counting posts
where religion and inflation co-occur — overstates genuine engagement by roughly an order of magnitude (≈8,000
co-mentions versus 520 measured), and we demonstrate a validated pipeline for measuring linkage rather than
co-occurrence.

## 2. Background

The study sits at the intersection of three literatures that are each well developed but rarely meet.

**Inflation salience and media agenda-setting.** Public and media attention to inflation is non-linear: it
stays flat until inflation crosses a threshold of roughly 2–4%, then jumps (Korenok, Munro & Chen, 2026;
Pfäuti, 2024). Coverage is less about the headline rate than about *who is hurt* and *which component* — the
"heating or eating" framing of food versus energy (Champagne et al., 2024) — and the European Central Bank now
maintains a dictionary-based media inflation-attention index (Aarab et al., 2025). Agenda-setting theory
(McCombs & Shaw, 1972) is the backdrop, with an open question of whether media *set* or merely *reflect*
attention (Wlezien & Soroka, 2024). This literature is almost entirely secular and Anglophone/euro-area; it
says nothing about the religious media sphere as an inflation channel.

**CST economic framing.** The theological distinction between *charity* (relieving symptoms) and *justice*
(changing structures) maps closely onto Iyengar's (1991) episodic-versus-thematic framing and gives us a
measurable construct. The structural critique is not only a Francis-era phenomenon (Benedict XVI, 2009; Francis,
2013). But existing studies examine secular press coverage of poverty, not religious media as the storyteller.

**Croatian Catholic media** are well studied on identity, nation, and culture-war themes, but their coverage of
the economy has never been measured, still less linked to a live cost-of-living shock.

**The gap — and a fourth, methodological one.** No work has asked what register religion takes when it meets
inflation in a whole national digital space. And studies of "religion and X" in large corpora routinely equate
co-occurrence with engagement; we show below why that is unsafe here.

### 2.4 Hypotheses and propositions

The study is primarily descriptive, but prior theory licenses explicit, testable expectations. We state two
directional **hypotheses** — where theory predicts a direction and the data permit a quantitative test — and
two theory-derived **propositions**, evaluated by pattern-matching against the coded evidence in the
interpretive tradition (Yin, 2018).

- **H1 (attention–price coupling).** From inflation-salience and agenda-setting theory, media attention to
  inflation should rise with the real HICP and jump once inflation crosses a ≈4% threshold, with the food and
  energy components at least as salient as the headline rate. *Tested* against Croatian HICP (§4.6).
- **H2 (resonance, not setting).** From the setter-versus-resonance debate, religious inflation coverage should
  *resonate with* real conditions rather than *lead* them — entering the discourse reactively, as an affected
  party. *Assessed* via the temporal pattern; a formal lead–lag test is left to future work.
- **P3 (prophetic-actor proposition).** If the Church functions as a prophetic economic actor in the digital
  public sphere, the structural / CST-justice register should be non-trivial and should rise with hardship.
  *Evaluated* against the coded register distribution and its time path.
- **P4 (episodic over thematic; Iyengar, 1991).** Religious framing of inflation should be predominantly
  *episodic* (relief, institutional, the price of services) rather than *thematic* (structural critique).
  *Evaluated* against the register distribution.

We deliberately avoid inferential machinery the observational, batch-confounded data cannot bear: H1 is tested
by correlation and a threshold contrast, the propositions by pattern-matching.

## 3. Data and methods

**Corpus.** The DigiKat master is a topical corpus of **710,307** Croatian/Bosnian media posts (2021-01 →
2026-06) retained by a religious-content filter (≥2 distinct religious-term matches). It is *religion-salient
posts across the whole media space*, not a Catholic-outlet archive: secular mainstream outlets dominate, and
the core is 96% web-portal content (Facebook 2%, other platforms negligible). A provenance marker
(`data_source`) reflects two collection streams — a monitoring query covering ≈2021–2024 and a filter-based
backfill covering ≈2024–2026 — that are **not comparable** (see §4.4); we condition on it in all temporal
analysis.

**Inflation tagging.** We tagged every post whose title or body matches an anchored inflation lexicon
(`inflacij*`, `poskup*` "to become more expensive", `rast/porast/skok cijen*` "price rises", `trošak života`
"cost of living", `kupovna moć` "purchasing power"), deliberately excluding the bare word `cijena` "price" to
avoid devotional false positives (e.g. "the price of salvation"). A metaphor guard removes figurative uses
("inflation of words/values"). This yields **8,019** clean inflation-mentioning posts (1.13% of the corpus).

**Linkage, not co-occurrence.** A long news article can mention inflation in one paragraph and a saint's feast
in another with no connection. We therefore measured, for each inflation post, whether a religious term
(project lexicon of 95 terms, tightened for economic homonyms such as *gospodarstvo* "economy" vs *Gospa* "Our
Lady") appears within ±220 characters of an inflation mention. This proximity filter is deliberately
recall-oriented (validated recall ≈0.89): it generates **1,450 candidate** linked posts while accepting false
positives, which the coding stage removes. We code the full *linked* set (1,450) rather than the classifier's
narrower *domestic-linked* subset (1,103), because the automatic foreign/domestic flag is unreliable (held-out
precision ≈0.39); the annotators, not the flag, decide foreign versus domestic.

**Coding.** All 1,450 candidates were coded by **three independent annotators** (large-language-model
annotators applying a fixed codebook), majority-adjudicated; 1,447/1,450 were coded by all three. Each post was
labelled on four axes: whether it is genuinely about inflation/cost of living; whether religion is genuinely
linked to the inflation content (versus incidental, a geographic landmark, a metaphor, a hashtag, or a secular
organisation containing a religious word, e.g. *Crveni križ* = Red Cross, *Papa-test* = Pap smear); whether the
inflation is foreign or domestic; and, when linked, its **register**: *cost of religious life* (the price of
religious goods/services rising), *Church-as-institution* (clergy/Pope/parish as actor or commentator),
*structural / CST justice*, *charity* (Caritas/relief), *devotional*, or *other*.

**Validation.** On a stratified held-out sample of 80 posts (disjoint from any tuning data), inter-annotator
agreement was high — infl 0.975, link 0.967, foreign 0.992 — confirming the constructs are reliably measurable;
register is the harder judgement (held-out agreement 0.46). The proximity filter's held-out precision for
domestic linkage was modest (≈0.38–0.46) with recall ≈0.89 — i.e. a *filter*, not a labeller; the full-pool
coding confirmed this (45% of candidates coded as genuinely linked). We therefore report coded figures
throughout and never regex counts. Annotators are LLM-based, so the agreement is inter-model reliability rather
than a human gold standard; a human double-coding pass is planned (§7).

**Price data.** Croatian HICP annual rate of change (monthly; all-items, food, energy) was obtained from
Eurostat (`prc_hicp_manr`) for 2021–2025.

**Analysis.** We report the corpus-to-core funnel; the register distribution and its outlet, temporal, and
tonal structure; and a test of H1 correlating monthly inflation-attention with HICP. Because the corpus changes
collection instrument at 2024, all temporal analysis is conducted *within* the 2021–2024 monitoring stream and
the batch-pooled series is reported only for completeness.

## 4. Results

### 4.1 Co-occurrence is not engagement

The path from corpus to measured core is steep (Table 1). Of 710,307 posts, 8,019 (1.13%) mention inflation. Of
those, the recall-oriented filter flags 1,450 as candidate-linked; coding confirms only **652** as genuine
religion–inflation linkage, of which **132** concern foreign inflation, leaving a **domestic measured core of
520 posts — 0.07% of the corpus and 6.5% of inflation-mentioning posts.** A naïve co-occurrence count would
have reported the phenomenon as an order of magnitude larger than it is; even among the proximity-flagged
candidates, just 45% survive coding.

**Table 1. From corpus to measured core.**

| Stage | n | % of corpus |
|---|---:|---:|
| Full religion-filtered corpus | 710,307 | 100.000 |
| Mentions inflation (clean) | 8,019 | 1.129 |
| Linked candidates (filter, recall ≈0.89) | 1,450 | 0.204 |
| Confirmed religion-linked (coded) | 652 | 0.092 |
| … foreign inflation | 132 | 0.019 |
| **… domestic (measured core)** | **520** | **0.073** |

### 4.2 Who carries it

Genuine religion×inflation discourse is overwhelmingly a **secular-media** phenomenon: 442 of 520 posts (85%)
come from secular/mainstream outlets, 75 (14%) from Catholic outlets, and 3 from business press (Table 3). The
single largest producer is the Catholic aggregator *hkm.hr* (56 posts), followed by mainstream titles
(*slobodnadalmacija.hr* 17, *novilist.hr* 16, *24sata.hr* 12, *jutarnji.hr* 11, *večernji.hr* 10). The Church's
own outlets are not where this discourse mainly lives.

### 4.3 The register of religious-economic discourse

The central result is the register distribution (Table 2, Figure 1). Religion meets domestic inflation as, in
order: the **cost of religious life** (37.3%), the **Church-as-institution** (34.4%), **charity** (16.7%),
**devotional** framing (5.0%), and **structural / CST justice** at just **2.9%** (15 posts).

Two cautions attach to this table. First, the two leading registers are close, share vocabulary (*crkva*,
*biskup*), and register was the lowest-agreement coding axis (0.46), so their ordering is within coding noise;
the robust statement is that together they form an *economic-object* macro-register of **≈72%** (373 posts).
Second, the 3% justice figure is a strict-coding floor: broadening to posts in other registers whose text
carries latent structural language (chiefly 18 charity posts, e.g. Caritas discussing structural poverty)
raises the upper bound to **≈8%** (43 posts). Justice is marginal on either definition.

**Table 2. Register of the domestic core (n = 520).**

| Register | n | % |
|---|---:|---:|
| Cost of religious life | 194 | 37.3 |
| Church-as-institution | 179 | 34.4 |
| Charity / relief | 87 | 16.7 |
| Devotional | 26 | 5.0 |
| Structural / CST justice | 15 | 2.9 |
| Disputed (pending human tiebreak) | 12 | 2.3 |
| Other | 7 | 1.3 |

![Figure 1. Register composition of the measured core.](output/fig_register_composition.png)

The two dominant registers describe the Church as an *economic object*, not a moral voice: masses, church fees,
weddings, funerals and pilgrimages that became more expensive ("cost of religious life"), and clergy or dioceses
appearing in economic news as commentators or affected parties ("institution").

An outlet pattern is visible but must be read cautiously (Table 3, Figure 2). The "cost of religious life"
register is almost entirely a **secular** story — 189 of 194 such posts are secular outlets reporting that the
Church raised its prices. A tempting reading is that Catholic outlets, when they engage, tilt toward *charity*
(27/75 = 36% of the Catholic core vs 58/442 = 13% of the secular core). We do not press this claim: the Catholic
subsample is small (n = 75), 75% of it is the single aggregator *hkm.hr* (56 posts) whose own top register is
*institution* (27), not charity (18), and stripping *hkm.hr* leaves just 19 posts. We therefore report the
direction as a hypothesis for a larger Catholic-outlet sample, not a finding. What is robust across outlets is
the near-absence of the justice register (10 secular, 5 Catholic).

**Table 3. Register by outlet type (counts).**

| Register | Secular/other | Catholic | Business |
|---|---:|---:|---:|
| Cost of religious life | 189 | 4 | 1 |
| Church-as-institution | 147 | 32 | 0 |
| Charity / relief | 58 | 27 | 2 |
| Devotional | 22 | 4 | 0 |
| Structural / CST justice | 10 | 5 | 0 |
| Other / disputed | 16 | 3 | 0 |

![Figure 2. Register composition by outlet type (shares).](output/fig_register_by_outlet.png)

### 4.4 Temporal dynamics (read within collection stream)

An important caveat governs this section. The two collection streams are not comparable: at 2024, where they
overlap, **86%** of `original_dta` candidates but only **21%** of `filtered_religious` candidates survive coding
as genuine domestic linkage. Cross-year volume must therefore be read *within* a stream, not across the 2024
seam (Figure 3).

**Within the clean 2021–2024 monitoring stream**, the core rises sharply to a **2022 peak (201 posts)** — the
height of the energy shock — and declines thereafter (2023: 100; 2024: 64). This within-instrument decline is
genuine, not a collection artifact. The later backfill figures (2025: 66; 2026: 53) come from a different
instrument and are **not** evidence of a continued decline.

![Figure 3. Measured core volume by collection stream (batch-confound check).](output/coded_core_by_stream.png)

Within that same window, the register composition shifts (Figure 4, Table 4): the *institution* register
dominates the 2022 shock (105 posts) — clergy commenting on the crisis — and recedes (38 in 2023, 9 in 2024),
while *cost-of-religious-life* rises (41 → 39 → 61), tracking the church-fee revisions around the euro changeover
(1 January 2023). The discourse thus appears to migrate from acute-crisis commentary toward institutional price
adjustment. We treat this register shift as suggestive rather than established: part of it spans the stream seam
and awaits a stream-conditioned re-coding. At no point, in either stream, does the justice register gain
traction.

**Table 4. Register by year (counts, full core).** 2021–2023 are entirely the monitoring stream; **2024 mixes
both streams** (64 monitoring + 24 backfill = 88); 2025–2026 are entirely the backfill stream. Read across the
2024 seam with caution (§4.4); the within-stream monitoring series is 2021→12, 2022→201, 2023→100, 2024→64.

| Year | Institution | Cost-relig-life | Charity | Devotional | Justice | Other/disputed |
|---|---:|---:|---:|---:|---:|---:|
| 2021 | 8 | 0 | 0 | 1 | 2 | 1 |
| 2022 | 105 | 41 | 34 | 13 | 1 | 7 |
| 2023 | 38 | 39 | 11 | 5 | 5 | 2 |
| 2024 | 9 | 61 | 12 | 0 | 4 | 2 |
| 2025 | 16 | 13 | 26 | 4 | 2 | 5 |
| 2026 | 3 | 40 | 4 | 3 | 1 | 2 |

![Figure 4. Register over time (monthly, measured core).](output/coded_register_over_time.png)

### 4.5 Tone

Vendor auto-sentiment (indicative only) splits meaningfully by register (Table 5, Figure 5). The core is 43%
negative, 32% positive, 25% neutral overall, but "cost of religious life" is markedly negative (100 of 194,
51%), consistent with public grumbling about church price hikes, whereas "Church-as-institution" is the most
positive register (83 of 179, 46%), consistent with pastoral or commentary framing. The rare justice posts lean
negative (9 of 15).

**Table 5. Auto-sentiment by register (counts; vendor labels, indicative).**

| Register | Negative | Neutral | Positive |
|---|---:|---:|---:|
| Cost of religious life | 100 | 56 | 38 |
| Church-as-institution | 51 | 45 | 83 |
| Charity / relief | 38 | 12 | 37 |
| Devotional | 15 | 8 | 3 |
| Structural / CST justice | 9 | 4 | 2 |

![Figure 5. Auto-sentiment by register (shares).](output/fig_sentiment_by_register.png)

### 4.6 H1 — inflation attention tracks real prices

To test H1 we correlate monthly inflation-attention (the share of corpus posts mentioning inflation) with the
Croatian HICP annual rate of change (headline, food, energy), within the clean 2021–2024 monitoring stream (39
months); the batch-pooled series is reported for completeness only. Within the clean window, attention tracks
inflation strongly (Table 6, Figure 6): Pearson **r = 0.73** with headline HICP (p < 0.001), **0.72** with
food, and **0.44** with energy (Spearman ρ comparable). The threshold form of H1 also holds: mean attention is
**0.49%** of posts in months with headline HICP below 4% and **1.17%** at or above — a 2.4-fold jump around the
≈4% attention threshold documented cross-nationally. **H1 is supported**, with one nuance: food inflation tracks
attention as strongly as the headline, but **energy does not** (r = 0.44) — energy's large, partly negative
swings in 2023–2024 decouple it from attention, so the "food-and-energy" salience prediction holds for food but
not energy here. The batch-pooled series attenuates the coupling (headline r = 0.63), consistent with the 2024
seam adding noise. The religion-linked core is too sparse for a monthly test, but its annual volume aligns with
inflation (both peak in 2022).

**Table 6. Inflation-attention vs HICP (monthly, within the 2021–2024 stream, n = 39).**

| HICP component | Pearson r | Spearman ρ |
|---|---:|---:|
| Headline | 0.73 | 0.75 |
| Food | 0.72 | 0.74 |
| Energy | 0.44 | 0.43 |

![Figure 6. Inflation-attention vs HICP, 2021–2024 monitoring stream.](output/h1_attention_vs_hicp.png)

## 5. Discussion

**The Church as economic object, not moral voice.** The dominant way religion meets inflation in Croatian
digital discourse is not the pulpit but the price list. Seven in ten linked posts (the ≈72% economic-object
macro-register) describe either the rising cost of religious life or the Church as an institution caught in
economic news; charity adds a sixth; the structural-justice critique CST foregrounds is marginal (3% strict,
≤8% broad). We frame this as a claim about **digital-public visibility, not the Church's pastoral conduct**:
homilies, pastoral letters and Caritas fieldwork are structurally under-represented in a media-monitoring
corpus of news posts, so the low visibility of the justice frame is weak evidence about institutional silence as
such (§7). What the data support is that, in the national digital public sphere, the frame that surfaces around
inflation is overwhelmingly the fee and the institution, not the prophecy.

**Attention existed; a prophetic voice did not fill it.** The two results interlock. H1 shows that media
inflation-attention is real and price-coupled — the corpus registers the shock on cue with prices (§4.6). Yet
within that attention, once linkage is measured, the *religious* engagement is small (§4.1) and, where present,
non-prophetic (§4.3). The public conversation about inflation was there for a religious justice voice to enter;
it largely did not.

**A possible division of narrative labour (hypothesis).** The register–outlet pattern hints at two
storytellers: secular media supplying the "costlier candles" story — reporting, often critically and in
negative tone, that the Church raised the price of masses, weddings and funerals around the euro changeover —
and Catholic outlets leaning, in their thin non-aggregator tail, toward "quiet charity." As §4.3 stresses, the
Catholic subsample is too small and too aggregator-dominated to establish this contrast, so we advance it only
as a hypothesis. What both kinds of outlet share is the near-absence of the prophetic, structural voice.

**Mechanism and timing.** Within the 2021–2024 stream, the pattern is consistent with an agenda-setting
reading: the religious linkage flares during the acute 2022 shock (institutional commentary) and recedes as
prices stabilise, while church-fee coverage rises around euro adoption. On this within-stream evidence the
dynamic looks closer to *resonance* than to *setting* (H2, provisional) — religion enters inflation discourse
reactively, as an affected party, not as an agenda-setter for economic justice.

**Why it matters.** For sociology of religion, the finding qualifies accounts of the Croatian Church as a strong
public actor: on the economy, at least, its digital-public presence is thin and non-prophetic. For media
studies, it extends inflation-salience research into the religious sphere and shows the "who is hurt" framing has
a specifically institutional variant — "who charges more." For CST scholarship, the absence poses the question:
why the doctrinal justice frame does not travel into the national digital public sphere.

**Hypothesis scorecard.** H1 (attention–price coupling) **supported**; H2 (resonance not setting)
**provisionally consistent**, pending a lead–lag test; P3 (prophetic actor) **disconfirmed**; P4 (episodic over
thematic) **supported** (Appendix C).

## 6. The methodological contribution: co-occurrence ≠ engagement

Independent of the substantive story, the study is a cautionary demonstration. Had we counted co-occurrence, we
would have reported thousands of "religious engagements with inflation." Measured, genuine domestic linkage is
520 posts. The gap is not noise to tolerate but signal to remove: keyword-filtered corpora manufacture
incidental co-mention at scale. Our pipeline — anchored lexicons with metaphor and homonym guards, a
recall-oriented proximity filter, and multi-annotator coding with reported inter-annotator agreement — is a
reusable template for any "religion and X" (or "A and B") corpus study.

## 7. Limitations

- **Collection-batch confound.** The corpus mixes two streams with very different confirmation rates at their
  2024 overlap (0.86 vs 0.21). We read temporal trends *within* stream and do not claim a decline across the
  2024 seam. A stream-conditioned re-coding is the single highest-value robustness check.
- **LLM annotators.** Inter-annotator agreement is high (0.97), but this is inter-model reliability, not a human
  gold standard; a human double-coding of a ≥100-post slice (including the foreign/domestic boundary that
  defines the 520) is required before final publication, along with resolution of 12 "disputed" register cases.
- **Residual false positives.** Even after majority coding, a few core posts are misclassified; a high-confidence
  subset (3/3 agreement, 518 posts) is available for sensitivity analysis.
- **Register ordering / justice floor.** Register was the lowest-agreement axis; the 37% vs 34% ordering is
  within noise (we report the ≈72% macro-register), and 3% justice is a strict floor (≤8% broadly construed).
- **HICP scope.** H1 is tested at the level of corpus-wide inflation-attention; a monthly HICP overlay on the
  religion-linked core specifically is too sparse to test, and the H2 lead–lag test against public search
  interest is future work.
- **No secular benchmark yet.** Because the corpus is religion-filtered, we cannot yet say whether structural
  framing is rarer in religious than in secular inflation coverage; a benchmark on non-religious inflation posts
  is needed before any claim that the Church specifically underuses the justice frame.
- **Filtered baseline & platform coverage.** "Secular" here means secular outlets' religion-adjacent output, not
  their full inflation coverage; and the core is 96% web, so claims generalize to the web-portal public sphere
  rather than to all platforms.

## 8. Conclusion

When prices rose in Croatia, religion did enter the digital conversation about inflation — but as an institution
whose candles, masses and fees had become more expensive, and whose charities responded, far more than as a
prophetic voice for the poor. Media attention to inflation tracked real prices closely; the religious
structural-justice frame did not fill that attention. Costlier candles, quiet prophets. Whether this reflects a
genuinely quiet Church or merely a low-visibility frame in the digital public sphere is the question the
absence opens — and one the planned extensions (a secular benchmark, a lead–lag test, human validation) are
designed to answer.

---

## Data and code availability

Tracked aggregates, coded outputs, tables and figures are in the study `output/` directory
(`analysis_core_coded.csv`, the `tables/` folder, `hicp_hr.csv`). The underlying master corpus contains scraped
post text and is not redistributable; analyses are reproducible from the numbered pipeline scripts (Appendix A)
given access to the master. The measured-core file carries URLs and text excerpts and is held internally
pending a statistical-disclosure review.

## Ethics and disclosure

The corpus consists of publicly posted media content collected via a commercial monitoring service. The paper
reports only aggregate counts and shares; no personal data, account identifiers, or verbatim private content are
published. Outlet names are public publishers. A disclosure/PII screen is run before any data extract is shared.

## Funding and acknowledgements

DigiKat project, Catholic University of Croatia (Hrvatsko katoličko sveučilište), Department of Communication
Studies. Released under CC BY 4.0; open-science (FAIR) principles apply.

## References

- Aarab, I., Bańbura, M., Bobeica, E., & Leguay, T. (2025). Tracking inflation attention. *ECB Economic Bulletin* 6/2025.
- Benedict XVI (2009). *Caritas in Veritate.*
- Champagne, C., et al. (2024). "Heating or eating": framing the cost-of-living crisis. *Social Science & Medicine, 360*, 117312.
- Francis (2013). *Evangelii Gaudium.*
- Geiß, S. (2022). Conditional agenda-setting. *Communication Research, 49*(2), 296–323.
- Gutiérrez, G. (1971/1973). *A Theology of Liberation.* Orbis.
- Iyengar, S. (1991). *Is Anyone Responsible?* University of Chicago Press.
- Korenok, O., Munro, D., & Chen, J. (2026). Inflation and attention thresholds. *Review of Economics and Statistics, 108*(3), 842–850.
- Lamla, M. J., & Maag, T. (2012). The role of media for inflation expectations. *Journal of Money, Credit and Banking, 44*(7), 1325–1350.
- McCombs, M. E., & Shaw, D. L. (1972). The agenda-setting function of mass media. *Public Opinion Quarterly, 36*(2), 176–187.
- Pfäuti, O. (2024). The inflation attention threshold. arXiv:2308.09480.
- Wlezien, C., & Soroka, S. (2024). Media and the public's attention. *American Political Science Review, 118*(3), 1563–1569.
- Yin, R. K. (2018). *Case Study Research and Applications: Design and Methods* (6th ed.). Sage.

*Some literature entries remain to be verified against Hrčak / CrossRef before submission; see `LITERATURE.md`.*
**Data source:** Croatian HICP annual rate of change (Eurostat `prc_hicp_manr`, all-items/food/energy, monthly), retrieved 2026-07-01 (`output/hicp_hr.csv`).

---

## Appendix A. Reproducibility

Pipeline: `10_rerun_fixed.R` (tagging + linkage + fixes) → `13_make_coding_pool.R` (1,450-candidate pool +
annotation batches) → the `code-candidate-pool` workflow (3 annotators × 20 batches, majority) →
`14_finalize_coded.R` (measured core) → `15_paper_analysis.R` (register/outlet/sentiment tables + figures) →
`16_review_response.R` (stream conditioning; hkm.hr decomposition; latent-justice bound) → `17_h1_hicp.R`
(H1 test). Run against the master (R path in `CLAUDE.local.md`). Coded data: `output/analysis_core_coded.{rds,csv}`.

## Appendix B. Coding protocol and validation

Four axes (§3). Held-out validation (n = 80): inter-annotator agreement infl 0.975 / link 0.967 / foreign 0.992
/ register 0.46; classifier held-out precision (domestic linkage) ≈0.38–0.46, recall ≈0.89; full-pool coding
confirmed 45% of candidates as genuinely linked. Full log: `VALIDATION.md`, `REVIEW_RESPONSE.md`.

## Appendix C. Hypothesis scorecard

| # | Statement | Test | Verdict |
|---|---|---|---|
| H1 | Attention rises with HICP; jumps above ≈4%; food/energy ≥ headline | Correlation + threshold contrast (§4.6) | **Supported** (r ≈ 0.73; 0.49→1.17% at threshold; food ≈ headline > energy) |
| H2 | Religious coverage resonates rather than leads | Temporal pattern (§4.4, §5) | **Provisionally consistent**; lead–lag test pending |
| P3 | If prophetic actor, justice register non-trivial and rises with hardship | Pattern-matching (§4.3–4.4) | **Disconfirmed** (3% strict / ≤8% broad; no rise) |
| P4 | Framing episodic, not thematic | Register distribution (§4.3) | **Supported** (episodic registers ≫ thematic justice) |
