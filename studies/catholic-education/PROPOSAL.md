# Proposal — Catholic *lieux de mémoire* in Croatian digital media: education as a site of memory transmission

**Date:** 2026-06-30 · **Status:** proposal (pre-data) · **Owner:** memory-studies researcher (asistentica, *Mjesta sjećanja*)
**Discipline tilt:** descriptive / interpretive — sociology of religion · communication studies · memory studies · digital humanities.
**House model:** mirrors [`studies/inflation-salience/PROPOSAL_v2_broadened.md`](../inflation-salience/PROPOSAL_v2_broadened.md) — the same *measure-honestly-then-narrow* discipline.

> **Radni naslov (HR):** *Katolička mjesta sjećanja u hrvatskom digitalnom medijskom prostoru: obrazovanje kao
> prostor prijenosa pamćenja, identiteta i vrijednosnog odgoja (2021.–2025.).*

---

## 0. The one thing that makes or breaks this paper

The original idea is sound, but it contains one optimism the corpus *will* punish, and the sister study already
proved how. The plan is: keyword-tag candidate "sites of memory" → look at frequency/sentiment/engagement →
interpret. The inflation study ran the identical move and found **~68 % of co-mentions were incidental**, that a
naïve co-occurrence count **overstated genuine engagement ~7-fold**, and that a *single* homonym (`Gospa` vs
`gospodarstvo`) inflated the headline by half. Our bundles are worse on this axis: `škola`, `obitelj`, `mladi`,
`vrijednosti`, `identitet` are among the most common words in Croatian and co-occur with religion constantly
**without constituting a site of memory.**

The fix is not to drop the framing — it is to **build the linkage/validation discipline into the design from day
one**, which turns a competent descriptive map into a *methods contribution* as well (see §3, §7). Everything
below is organized around that.

---

## 1. The idea in one paragraph

Between 2021 and 2025 the Croatian digital media space carried a continuous, contested conversation about the
Catholic Church's role in public life — and a recurring strand of it is about **education**: religious
instruction in schools (`vjeronauk`), Catholic schools and HKS, youth formation (SHKM), and the symbolic figures
and orders that historically *carried* Catholic education (Stepinac, Strossmayer, Stadler, Petković; the
Jesuits, Franciscans, Salesians, časne sestre). Memory-studies theory (Nora's *lieux de mémoire*, J. & A.
Assmann's communicative vs. cultural memory, Halbwachs' social frameworks) predicts that some of these anchors
function as **sites of memory** — durable, ritually-recurring, affectively-charged nodes that bind a present
identity to a remembered past — while others are merely **present-tense policy disputes** wearing memory's
clothes. This study **detects which is which, empirically**, with education as the spine, and asks whether
*Catholic education* in particular is mediated as a vehicle of *memory transmission* (anchored to Stepinac /
communism / 1991 / "kršćanski korijeni") or as a *contemporary value-political battle* (curriculum,
secularization, parental rights) with no memorial anchoring.

---

## 2. The questions (two and a half)

- **Q1 — Detection / which anchors are sites of memory.** Of the candidate Catholic anchors in the education
  field, which behave like *lieux de mémoire* — i.e. score jointly on **recurrence × temporal peaking ×
  affective charge × past-anchoring** (the four-signal construct, §3) — and which are flat present-tense topics?
- **Q2 — Education as memory transmission (the falsifiable core).** **To what extent, and *by which actors*, is
  *Catholic education* (`vjeronauk`, katoličke škole, HKS, SHKM, the teaching orders) anchored to the past**
  (Stepinac, komunizam, 1991., kršćanski korijeni, sekularizacija-as-rupture) — *memory transmission* — **versus
  argued in present-tense terms** (curriculum, parental rights, secularization-as-policy)? Posed as a **proportion**,
  not a binary: the most likely real answer is *both, strategically blended* — culture-war fights are often **fought
  through** memorial anchors — so "blended" is a theorized **third outcome**, not a failure of the design. The
  binary (heavy memorial anchoring ↔ flat present-tense dispute) marks the *falsifiable poles*; the finding is
  *where on that continuum each anchor and each actor type sits.* The result is not knowable in advance — that is the paper.
- **Q2½ — Who carries it & with what affect.** Which actors (secular portals vs Catholic outlets vs community
  pages, via the project's Giants/Community-Builders/Megaphones/Specialists typology) activate these anchors, and
  with what emotional register (CroSentilex / lilaHR 8-emotion layer; conflict index)?

We stay **descriptive/interpretive**: we map a pattern and let the reader judge whether it fits — or fails — the
memory-transmission expectation. No causal claims.

---

## 3. The decisive move — operationalize "mjesto sjećanja" as a measurable construct

This is what makes it a DigiKat study and not a humanities essay. A candidate anchor is flagged as a **strong
site-of-memory candidate** when it scores on **four signals the pipeline already produces** — no new pipeline:

| Signal | What it measures (Nora / Assmann) | Pipeline source — **already exists** |
|---|---|---|
| **Recurrence** | a *durable* anchor, not a one-off | term/entity frequency over the corpus (NLP token counts) |
| **Temporal peaking** | ritualized "warm" memory; commemorative calendar | `DATE` → annual/seasonal peaks (`Fokus na događaje` logic) |
| **Affective charge** *(supporting)* | memory is emotionally *invested*, not neutral | CroSentilex / CroSentilex Gold / lilaHR 8-emotion layer (`Atmosfera diskursa`) — **report lexicon coverage %**; downgrade to supporting where coverage is thin |
| **Past-anchoring** | separates *memory* from *current affairs* | **windowed** co-occurrence (±160 chars) with a focused past-reference probe aligned to `POVIJEST_I_NACIONALNI_IDENTITET` |

**Each signal is a measured quantity with a pre-committed provisional threshold (fixed BEFORE the table is seen):**
recurrence = post count above the spine-field median; temporal-peaking = a peakedness statistic (e.g. max-month
share / Gini) above a stated cutoff, **and** a recurring-calendar test (does the peak repeat on the same date
across years — *commemorative* — or is it a one-off *news-cycle* spike?); affective-charge = non-neutral share
above a stated value, **reported with coverage %**; past-anchoring = **windowed** genuine-linkage share (not
whole-document co-occurrence) above chance.

**Decision = a graded composite, not a strict AND.** Each candidate gets the four scores plus a transparent
composite; the strict-AND gate is reported as one column, but ranking uses the composite so a genuinely strong
*lieu* is not killed by one thin signal (e.g. low emotion-lexicon coverage). **Construct-validity controls
(pre-declared):** `stepinac` is the expected **positive control** (should score high) and the
`odgoj/kurikul/vrijednost` bundle the expected **policy-dispute foil** (should score low). *If the screen does
not separate them in the expected direction, the construct — not the data — is suspect and is revisited before
any substantive claim.* That built-in falsification is what makes the four-signal screen a *validated instrument*
(§7), and the foil-vs-control contrast is itself a finding about how Croatian Catholic education is mediated. The
scores travel with every candidate into §5. **`slice.R` emits 2 of the 4 signals now (recurrence + doc/windowed
past-anchoring); peaking and affect are added in `/data-analysis`** — Stage A's table is an explicit *partial screen*.

## 4. Data (we already have it)

- **Corpus:** the DigiKat master — **710,307** posts × 47 vars, **2021-01 → 2026-06** (we use **2021–2025**),
  Croatian/Bosnian, religion-filtered (**≥2 distinct** religious-term matches, `R/religious_terms.R`).
  **Important framing (carried from the sister study):** this is *religion-salient posts across the whole media
  space* (secular-dominated: index, jutarnji, večernji, …), **not** a Catholic-outlet archive. That is a feature —
  it lets us study how the *whole* mediasphere activates Catholic memory, not just how the Church talks to itself.
- **Platforms:** web portals (dominant) · YouTube · Facebook · Twitter · Reddit · forums. (Coverage is uneven by
  platform/year — the detection sample is stratified to respect this.)
- **Fields used:** `FULL_TEXT` (matching + NLP), `DATE` (temporal peaking), `SOURCE_TYPE` / `FROM` (actor map),
  `ENGAGEMENT_RATE` and reaction fields (reach), plus the 16-category theme dictionary and the sentiment layer.
- **Entity probe (NEW, study-local — does NOT touch the global filter):** a focused education-and-memory entity
  list layered *on top of* the existing corpus (it only sub-selects; it never changes the ≥2-match rule):
  - **Education / transmission:** `vjeronauk`, `vjeroučitelj(ica)`, katolička škola, HKS, sjemenište, učiteljska
    škola, odgoj, kurikulum, roditelj(i), mladi, tradicija, kršćanski korijeni, identitet, vrijednosti.
  - **Symbolic figures / orders (the carriers):** Stepinac, Strossmayer, Stadler, Petković, isusovci, franjevci,
    dominikanci, salezijanci, časne sestre, samostan, katoličko sveučilište.
  - **Past-anchoring tokens:** komunizam, sekularizacija, 1991., Jugoslavija, žrtva, rat, domovinski. In `slice.R`
    these are a **focused, transparent past-reference probe** (a subset *aligned with* `POVIJEST_I_NACIONALNI_IDENTITET`,
    not that 16-cat category re-run); the full-category version is computed in `/data-analysis` from the shared
    dictionary and the two are reported side-by-side. **None of these is a spine/carrier entity**, so signal #4 is
    measured against a token set *disjoint* from the entities being scored (no Stepinac-counts-itself circularity).
  - **Secondary (rituals, NOT the spine):** Hod za život, SHKM, Progledaj srcem, Antunovski hod mladih,
    procesija, hodočašće — kept as *signals*, since the spine is education.

## 5. What we actually do — the three-stage answer to the proposer's own question

> *"Bi li bilo moguće najprije napraviti preliminarnu detekciju... pa zatim odabrati konkretniji korpus?"*
> **Yes — and it is the only correct order. It does NOT touch the master or the ≥2-match filter; this study only
> READS and sub-samples.**

**Stage A — Preliminary detection (computational; sample-first, then full-corpus for survivors).** ⬜
Score the signals (§3) on the entity probe (§4) over the **stratified 2–5 % sample first** (fast, house
default), produce a **ranked candidate table** (entity × recurrence × doc/windowed past-anchor × incidental-share,
then peak-dates × emotion from `/data-analysis`), then re-score survivors on the full corpus. *Output:* the
evidence the proposer asked for — a ranked list of candidate sites of memory, education-first. `slice.R` + `/data-analysis`.
**Rare-*lieu* rescue (important):** the 2–5 % sample is a *frequency gate* — a genuine but **rare** *lieu* (a
beatified figure like Marija Petković, a minor order, a low-frequency anniversary) can have too few sample hits to
survive. So Stage A **also** scores a small **pre-declared named allow-list** of theoretically-important low-frequency
entities **directly on the full corpus**, not only on the sample. Detection is recall-first; the sample is for
speed, not for deciding what is *allowed* to be a candidate.

**Stage B — Evidence-driven corpus selection.** ⬜ Take the candidates that score high on the **graded composite**
(not a brittle all-four AND), pull their actual posts from the full corpus (now a *small, named* set — likely a
few hundred to low thousands), and **that becomes the qualitative working corpus.** The proposer chooses from
evidence, not intuition.

**Stage C — Qualitative discourse analysis.** ⬜ Close reading / discourse coding of the narrowed set
(memory-transmission frames, identity claims, past↔present linking), with the four-signal scores as the
sampling frame and as context for each excerpt.

This is exactly the workflow the inflation study used (`tag → measure linkage → hand-validate → narrow → code`)
and proved on this data.

## 6. Honesty checks (the guardrails — non-negotiable, learned from `inflation-salience`)

- ⬜ **Co-occurrence ≠ activation.** Every "X is a site of memory" claim distinguishes *genuine* linkage (entity
  topically connected to education/memory within a tight window) from *incidental* co-mention. Budget for it; it
  cut the sister study's headline ~7×.
- ⬜ **Homonym / false-positive audit before any number is reported.** Hand-scan and report precision.
  **Hand-validation priority (ranked by `croatian-nlp-reviewer` audit, 2026-06-30, noisiest first):**
  (1) broad spine controls `vrijednost` / `odgoj` (ubiquitous, recall-first by design);
  (2) `redovi_orders` — esp. `samostan` (tourism/real-estate "u bivšem samostanu"), `isusov`, `franjev`;
  (3) `stadler` — **Stadler Rail** (HŽ contracts in-period) is an undisambiguated homonym;
  (4) `kurikul` — the intended "policy-dispute, not site-of-memory" control.
  `Petković` IS disambiguated to *Marija Petković* in the probe; the `red`/*red vožnje* homonym is fully avoided
  (the probe never matches bare `red`). (Sister-study lesson: one homonym halved a headline.)
- ⬜ **Hand-validation with inter-annotator agreement** on the narrowed corpus — feasible *because* Stage A
  narrows it; double-code ≥50 posts and **report Cohen's κ** plus the measured **incidental-co-mention rate**.
- ⬜ **Provisional vs validated numbers kept visibly separate** until hand-coded (house convention — see the
  sister study's §6 vs §7 split).
- ⬜ **State the construct's circularity limit plainly (in the paper).** Signal #4 measures *lexical past-reference*,
  **not** memory *function*. The four signals are a **screening filter for close reading**, not the definition of a
  *lieu de mémoire*; **Stage C qualitative coding** is what adjudicates whether a past-reference performs memory
  transmission or is mere rhetorical decoration. The past-token probe is held disjoint from the scored entities (§4).
- ⬜ **State the sampling-frame / secular-frame limit plainly.** The corpus is religion-*salient* posts across a
  secular-dominated mediasphere, not a Catholic archive — so the unit is **how the *whole mediasphere* mediates
  Catholic educational memory**, and Q2½'s actor typology is the instrument that *decomposes* secular-portal vs
  Catholic-outlet vs community framing. Report the ≥2-match rule's precision/recall character as an explicit limit.
- ⬜ **Croatian encoding integrity** end-to-end (č ć ž š đ in lemmas; đ in `događaji`); the `croatian-nlp-reviewer`
  agent audits the probe regexes before any run.
- ⬜ **No silent re-scoping.** The ≥2-match inclusion rule and the master are untouched; `slice.R` writes only to
  `studies/catholic-education/output/`, never to `data/`.

## 7. Why this is more publishable than a plain descriptive map

Three contributions — and to keep *either* Q2 answer informative, **name the prior up front**: the
secularization-as-present-tense default predicts education talk is mostly curriculum/parental-rights dispute, so
confirming **heavy memorial anchoring is a finding *against* that default**, and confirming **flatness falsifies
the memory-transmission spine.** The result has somewhere to surprise.
- **Substantive:** a computational map of Catholic *lieux de mémoire* in a national digital mediasphere — **"first,
  for the Croatian mediasphere, to our knowledge"** (hedged pending `/lit-review`, §10; drop unqualified primacy),
  with the education-as-memory-transmission question **answered empirically** on the §2 continuum.
- **Actor-decomposition (the genuinely novel result — promote it):** *which actor types* (Giants / Community-
  Builders / Megaphones / Specialists) activate *which* anchors, with what affect, across a 710k secular-dominated
  corpus. No humanities essay and no Catholic-outlet study could produce this — it is the defensible novelty for
  *New Media & Society*, and the instrument that answers the secular-frame objection (§6).
- **Methodological:** a **validated four-signal screening instrument** for *lieux de mémoire* (recurrence × peaking
  × affect × past-anchoring), transferable to any dated, sentiment-scored, dictionary-tagged corpus. This claim is
  defensible **only because** the foil-vs-positive-control validation (§3) is reported — without it, it is just four
  reasonable-sounding columns. *That* validation is what lifts the study from a regional descriptive piece.

## 8. Venue

- **EN:** *Memory Studies* · *Journal of Media and Religion* · *New Media & Society* · *Religion*.
- **HR:** *Nova prisutnost* · *Medijska istraživanja* · *Diacovensia* · *Društvena istraživanja*.

## 9. Working title (options)

> **Scope honesty (carry into the abstract):** the four-signal screen measures **memorial framing** — the
> *mjesta sjećanja* claim. *Identitet* and *vrijednosni odgoj* are addressed **qualitatively in Stage C**, not as
> separately-measured quantities. Title 1 (below) names all three; if the empirical core stays on memorial framing,
> prefer Title 2 or trim 1 to *"…obrazovanje kao prostor prijenosa pamćenja"* and let identity/values enter via the
> close reading. Don't promise three measured constructs and deliver one.

1. *Katolička mjesta sjećanja u hrvatskom digitalnom medijskom prostoru: obrazovanje kao prostor prijenosa pamćenja (2021.–2025.).*
2. *Memory transmission or culture war? Catholic education as a site of memory in the Croatian digital media space.*
3. *Detecting* lieux de mémoire *at scale: a four-signal method on a 710k Catholic-media corpus.* (method-forward)

## 10. Theoretical anchors (to harden via `/lit-review`)

Nora (*lieux de mémoire*) · J. Assmann + A. Assmann (communicative vs. cultural / political memory) · Halbwachs
(social frameworks of memory) · digital/connective memory (Hoskins; van Dijck) · mediatization of religion
(Hjarvald; Hoover) · Croatian Catholic-media & memory scholarship (to be mapped). → run `/lit-review`.

## 11. Next step

**Before the run (cheap, pre-commit on paper):** (a) write the four provisional thresholds + the graded-composite
formula (§3); (b) declare the `stepinac` positive-control / `odgoj-kurikul` foil pair (already wired into
`slice.R` §3b); (c) list the rare-*lieu* named allow-list to score on the full corpus (§5).

**Run Stage A** — `/data-analysis` on the stratified sample via [`slice.R`](slice.R) (now emits recurrence +
doc/windowed past-anchoring with the incidental split; peaking + affect added in `/data-analysis`, reporting
emotion-lexicon coverage %). Output: the ranked candidate-site-of-memory table — the proposer's requested
*preliminary detection*, from which the Stage-B qualitative corpus is selected. `/lit-review` (§10) runs in
parallel to harden the theory and retire the hedged "first" claim.
