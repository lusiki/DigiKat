# Proposal v3 — Two lenses on the same discourse: how religion mediates the economy in the Croatian digital media space

**Date:** 2026-07-09 · **Status:** proposal v3 — **dual-lens rewrite** after (a) the keyword census (Stage A) completed and (b) a semantic-database pilot ran · **Owner:** L. Šikić
**Supersedes:** [`PROPOSAL.md`](PROPOSAL.md) (v2, keyword-only). **Evidence in hand:** [`output/stageA_domain_stats.csv`](output/stageA_domain_stats.csv) (full census) + [`output/semantic/`](output/semantic/) (pilot).
**Discipline tilt:** descriptive + two preregistered directional endpoints — sociology of religion · communication studies · economic sociology · computational text analysis.
**House model:** the *measure-honestly-then-narrow* discipline of the sister study [`inflation-salience/PAPER_v1.md`](../inflation-salience/PAPER_v1.md).

> **Radni naslov (HR):** *Dvije leće na isti diskurs: kako se ekonomija posreduje u hrvatskom katoličkom digitalnom prostoru (2021.–2026.).*

---

## 0. What changed from v2, and why (the one paragraph that motivates this rewrite)

v2 was a **single-lens keyword study**: cast keyword nets for 11 economy domains, measure windowed religion-linkage, then **hand-code ~10,000 posts into registers** (institution / cost-of-religious-life / justice / charity / devotional) and analyze. That plan had one fragile joint — the register coding — which was also the paper's entire headline: the inherited register reliability was only **κ ≈ 0.46**, the coding was months of work, and the single most theory-loaded domain (poverty) is exactly where the keyword lens is blindest, because *"the poor"* is simultaneously a material-economic and a gospel-theological category that share the same word. Since v2 we did two things that change the design: we **ran the keyword census to completion** (132,519 linked candidates; poverty is #1 at 53.8% linkage / 56.4% confessional), and we **built + piloted a semantic database** — every one of the 710,307 posts embedded as a meaning-vector (bge-m3, local). The pilot showed the meaning lens can do at scale, in seconds, the two things the keyword lens can't: **produce the domain × register grid without hand-coding**, and **separate economic-"poor" from spiritual-"poor"** (pilot: ~73% of "poverty" talk is doctrinal/spiritual, not material). v3 therefore turns the study from *one lens + a coding bottleneck* into a **dual-lens design where a transparent keyword filter and a meaning-based embedding model measure the same discourse and check each other** — which repairs the weak joint, adds a genuine methods contribution, and makes every claim on which the two lenses converge close to referee-proof.

---

## 1. The idea in one paragraph

Between 2021 and 2026 Croatia lived a compressed macroeconomic decade — cost-of-living shock, energy crisis, euro adoption, a tight labour market, a housing squeeze. Catholic Social Teaching claims a voice in all of it. This study asks, across the whole religion-salient digital media space, **where that voice actually goes, in what register, and whether its flagship economic concern — the poor — is mediated as an economic reality or a spiritual category.** We answer with **two independent instruments**: a *keyword lens* (auditable regex nets + windowed linkage — transparent, defensible term-by-term, already run) and a *meaning lens* (post embeddings scored against concept anchors — recall-complete, meaning-aware, blind to the exact words). Where they agree, the finding is robust; where they diverge, the divergence is itself informative (a keyword recall gap, or an embedding artifact, each diagnosable). The pilots already sketch the answer: religious economic attention concentrates where the economy becomes **human** (poverty, work, wages) and thins over the **aggregate** (GDP, inflation, the euro); and the *register* flips by domain — **justice and dignity around work, charity and devotion around poverty** — so that the structural-justice voice CST would predict *for the poor* is actually loudest *around labour*, while poverty is met with compassion and almsgiving rather than structural critique.

---

## 2. The questions (three, plus a methodological one)

- **Q1 — Coverage (where does the economic attention go?).** Across the 11 domains, where does religion-salient discourse concentrate its economic attention — and does the **keyword ranking and the semantic ranking agree**? *(Pilot: both put poverty #1 and aggregates cold; the two lenses diverge in the middle ranks — §4.)*
- **Q2 — Register (in what voice?).** When religion meets each economic domain, in what register — **justice** (structural critique, dignity of work) · **charity** (relief, almsgiving) · **institution** (the Church as economic actor) · **cost-of-religious-life** · **devotional** (spiritual/metaphorical)? Reported as a **domain × register grid**, produced semantically at scale and **validated against a hand-coded gold sample**. *(Pilot: poverty → devotional/charity, justice only ~9%; wages/taxes → justice ~30–34%.)*
- **Q3 — The poor: economic or doctrinal? (the sharp question).** Of the discourse about *"the poor,"* what share is **material-economic** (at-risk-of-poverty, debt, eviction, welfare) versus **doctrinal-spiritual** (almsgiving, poor-in-spirit, gospel category)? *(Pilot: ~73% doctrinal / ~27% economic — directionally strong; exact ratio to be firmed up, §8.)*
- **Q_M — Method (do two lenses see the same discourse?).** How far do a keyword filter and a meaning model **converge**, where do they **diverge**, and what does each divergence reveal? This is the transferable methods contribution.

We stay descriptive/interpretive; the directional expectations in §5 are tested by cross-lens convergence + pattern-matching, not causal identification.

---

## 3. The decisive move — the dual-lens instrument

| | **Keyword lens** (Stage A, done) | **Meaning lens** (semantic store, piloted) |
|---|---|---|
| **Unit** | literal term match + ±220-char proximity | whole-post embedding (bge-m3, 1024-dim) |
| **"Belongs to domain X"** | contains domain regex | high cosine similarity to domain concept anchor |
| **Strength** | transparent, auditable term-by-term, reproducible from a regex; captures *physical proximity* of religion↔economy | recall-complete (catches paraphrase/synonym); separates meanings that share a word (poor↔poor-in-spirit); yields registers + a 2D map with no hand-coding |
| **Weakness** | misses paraphrase; blind to homonyms it wasn't handed; keyword breadth over/under-counts | magnitudes sensitive to anchor breadth; document-level (no within-post proximity); embed input truncated to first ~4000 chars; needs validation (retrieval precision) |
| **What it decides** | the auditable coverage backbone + the genuine-linkage candidate pool | the register grid (Q2), the poverty split (Q3), the recall-gap audit, the meaning map |

**The design principle:** neither lens is ground truth. The keyword lens is the **transparent backbone**; the meaning lens is the **meaning-resolver**. Every headline number is reported **with both lenses side by side**, and the three outcomes are all publishable: *converge* → robust finding; *keyword-only signal* → possible keyword artifact (flag); *semantic-only signal* → recall gap keywords missed (a finding about the method). The register grid and poverty split come from the meaning lens **because the keyword lens structurally cannot produce them**, and are made trustworthy by validating the semantic classifier against a hand-coded gold sample (§7), not by assuming the embedding is correct.

---

## 4. Evidence already in hand (this is a strength, not a promise)

**Keyword census — Stage A complete** ([`output/stageA_domain_stats.csv`](output/stageA_domain_stats.csv), full 710,307-row run):

| domain | tier | matched | linked | linkage | confessional |
|---|---|---|---|---|---|
| poverty_social | C | 71,007 | **38,232** | **53.8%** | **56.4%** |
| business_comp | A | 87,389 | 31,416 | 35.9% | 19.3% |
| taxes_fiscal | A | 62,198 | 23,375 | 37.6% | 36.7% |
| wages_income | C | 36,146 | 13,724 | 38.0% | 32.7% |
| macro_aggregates | A | 31,641 | 7,090 | 22.4% | 10.6% |
| housing | B | 18,727 | 6,106 | 32.6% | 16.9% |
| unemployment | C | 22,150 | 5,849 | 26.4% | 29.2% |
| green_energy | B | 11,854 | 3,425 | 28.9% | 16.2% |
| inflation_prices | C | 8,479 | 1,607 | 19.0% | 8.1% |
| demography_econ | B | 6,029 | 1,288 | 21.4% | 17.9% |
| euro_changeover | A | 2,072 | 407 | 19.6% | 11.0% |

Total linked candidate pool: **132,519**. Poverty dominates; there is **no clean tier A→C gradient** (taxes/business, tier A, out-link most tier-C domains).

**Meaning lens — pilot run** ([`output/semantic/`](output/semantic/), 20k-post sample, 21 concept anchors):
- **Coverage:** poverty **#1 under both lenses** (the robust convergence). Middle ranks diverge — some real (business/taxes look *over-counted* by keywords), some **anchor artifact** (a too-broad "euro/prices" anchor vaulted euro to #2). → coverage magnitudes need anchor calibration (§7).
- **Register grid (pilot, illustrative):** poverty → **devotional 0.54 / charity 0.20 / justice 0.09**; wages → **justice 0.31**; taxes → **justice 0.34**; inflation → devotional 0.42 / justice 0.30. The *justice-for-work, charity/devotion-for-poverty* flip is visible.
- **Poverty split (pilot):** **~73% doctrinal / ~27% economic** among the posts most about "poverty."
- **Validation:** top semantic hits per domain are on-topic (wages → pay-slips/minimum-wage/pensions; taxes → church-tax/Vatican-contract debates; macro → GDP/IMF). The instrument works; the calibration is the open work.

---

## 5. Hypotheses (directional; each named to a test and a lens)

- **H1 — Human over aggregate (both lenses; prereg candidate).** Religious economic attention concentrates on **person-level/distributional** domains (poverty, wages, unemployment, housing) over **aggregate/stabilization** domains (GDP, inflation, euro, public debt). *Test:* coverage ranking under **both** lenses; the hypothesis is *supported only if both agree* (the cross-lens convergence is the test). *(Pilot: consistent.)*
- **H2 — The register flip (semantic grid, hand-validated; the theory-relevant surprise).** The **structural-justice** register concentrates in **work/wages/fiscal**, *not* in poverty; poverty is engaged predominantly through **charity + devotion**. This runs *against* the naïve CST reading (that the "preferential option for the poor" would make poverty the site of the loudest structural-justice voice). *Test:* domain × register distribution on the coded/validated core; justice-share by domain. *(Pilot: strongly consistent — poverty justice ≈ 9% vs wages/taxes ≈ 31–34%.)*
- **H3 — The poor is mediated doctrinally (semantic; the sharp claim).** Discourse about "the poor" is **majority doctrinal-spiritual**, not material-economic — i.e. religion's flagship economic concern is also where its language is *least* economic. *Test:* economic-vs-doctrinal share on the poverty subset, three-way anchor (material / religious-charitable / spiritual), hand-validated. *(Pilot: ~73% doctrinal.)*
- **H4 — Crisis window (secondary; keyword+temporal).** In acute shock windows (2022 energy/price peak; Jan-2023 euro switch, within the 2021–24 stream) the justice-share of linked poverty/inflation discourse rises vs adjacent calm windows. *Test:* register share, shock vs calm, χ². (Retained from v2; secondary.)

---

## 6. Data

- **Corpus:** DigiKat master — **710,307** posts × 47 vars, 2021-01 → 2026-06, religion-filtered (≥2 distinct matches). Religion-*salient* posts across a secular-dominated mediasphere; platform mix web ≈74% / FB ≈13% / YT ≈9%. `data_source` is a **batch marker** (monitoring ≈2021–24 · backfill ≈2024–26) — conditioned on in all temporal analysis, never compared across.
- **Keyword layer:** [`lexicon.R`](lexicon.R) (11 register-neutral domain regexes + the economic-homonym-tightened 95-term religion regex) → [`output/stageA_candidates.rds`](output/stageA_candidates.rds) (132,519 linked candidates with window excerpts, actor/foreign flags, stream, outlet label).
- **Meaning layer:** `data/semantic/digikat.ragnar.duckdb` — all 710k embedded (bge-m3, 1024-dim, hybrid vector+BM25 via `ragnar`), **local** (Ollama). Caveats (from `R/semantic/README.md`): embed input truncated to first ~4000 chars (a topic buried deep in a long article can be missed until chunking is added); **document-level** (no within-post proximity — the keyword lens owns that signal); gitignored + Dropbox-ignored.
- **External:** Croatian HICP (reuse `../inflation-salience/output/hicp_hr.csv`); a liturgical-event calendar ([`output/liturgical_calendar.csv`](output/liturgical_calendar.csv), built).

---

## 7. What we do — stages (keyword done; semantic + validation are the new work)

- **Stage A — Keyword census. ✅ done** (§4). The transparent backbone + candidate pool.
- **Stage S1 — Anchor calibration.** Replace hand-written concept sentences with **seed-post centroids**: build each domain's meaning anchor from the average embedding of its Stage-A high-confidence linked posts (and each register anchor from a curated seed set). Use **soft/threshold assignment**, not winner-take-all, and a **balanced** anchor set — this fixes the pilot's over-broad-anchor distortions (the euro artifact).
- **Stage S2 — Semantic coverage + recall audit.** Score the corpus (or a large sample) against calibrated domain anchors → semantic coverage ranking; quantify the **recall gap** (posts semantically in a domain that the keyword net missed) and the **precision gap** (keyword hits that are semantically off-topic). Reconcile against §4 side-by-side.
- **Stage S3 — Register grid + poverty split.** Score linked candidates against calibrated register anchors → the domain × register grid (Q2) and the poverty economic/doctrinal split (Q3, three-way).
- **Stage V — Gold-sample validation (the honesty spine).** Hand-code a **stratified ~400–600-post gold sample** (domain × register, plus the poverty split). Report: retrieval precision per domain, **agreement between the semantic classifier and human coders** (the semantic analogue of κ), and whether the semantic register shares fall within CI of the hand-coded shares. **No semantic number is published unless it survives this check.** *(This replaces v2's "hand-code 10,000"; we hand-code hundreds to validate, then measure at scale.)*
- **Stage C — Analyses + the meaning map.** Domain × register grid; coverage convergence figure (keyword vs semantic); poverty split; the **2D UMAP meaning map** of religious-economic discourse (a genuinely new artifact); actor decomposition (confessional/secular); shock-window contrast (H4); affect layer as support.
- **Stage D — Close reading** of the sharpest register contrasts and the material-vs-spiritual poverty boundary cases.

- **OSF preregistration** of H1 (both-lens convergence) + H2 (register flip) after Stage V fixes the measurement, before the confirmatory reads.

---

## 8. Honesty checks (keyword + semantic; non-negotiable)

**Inherited (keyword):** co-occurrence ≠ engagement (numbers from validated cores only); homonym audit (documented in `lexicon.R`; the tightened religion regex verified); batch-confound conditioning; PI-owned *proposed* outlet labels framed as indicative; no master mutation.

**New (semantic):**
- ⬜ **Anchors are calibrated, not hand-wavy** — seed-post centroids + balanced sets + soft assignment; the pilot's euro/business distortions are named as the reason.
- ⬜ **Retrieval precision reported** per domain (hand-checked sample) — meaning-search is recall-friendly, *not* infallible (README validation habit).
- ⬜ **Semantic ≠ hand-coding until proven** — every semantic register/split number carries its agreement-with-humans on the gold sample; where they disagree, the human sample rules.
- ⬜ **Truncation limit stated** — ~1/3 of posts embedded on lede+body only; a topic buried deep in a long article can be under-detected until v2-store chunking.
- ⬜ **Document-level limit stated** — the meaning lens measures "what the post is about," not "religion physically near economics"; the keyword lens owns proximity. The two are **complementary operationalizations**, reported as such, never conflated.
- ⬜ **Convergence is a claim, not an assumption** — the paper reports where the lenses agree *and where they don't*, with each divergence diagnosed.

---

## 9. Why this is publishable (substantive + methodological)

1. **Substantive:** the first dual-validated map of how an entire national mediasphere mediates the economy through religion — with a genuine, non-obvious result (**the register flip**: justice for *work*, charity/devotion for *the poor*) that runs against the naïve CST expectation, plus the **doctrinal-poor** finding (the flagship concern is the least economic in language). These land harder because two independent methods back the coverage and the meaning lens uniquely resolves the register.
2. **Methodological (the transferable contribution):** a **validated dual-lens instrument** — transparent keyword filter × meaning-based embeddings, cross-checked on a hand-coded gold sample — for measuring how a value-community engages a topic domain. Directly reusable for religion×climate, religion×migration, or any "community × topic" corpus study. The recall-gap / precision-gap reconciliation is a concrete, citable procedure.
3. **A figure editors remember:** the 2D meaning map of religious-economic discourse, colored by domain and register — an artifact the keyword method cannot produce.

**Failure modes, named:** semantic classifier fails gold-sample validation → fall back to hand-coding a stratified core (v2's plan, but now targeted by the semantic screen, so far smaller); anchor calibration doesn't tighten coverage convergence → report the divergence honestly as a finding about method-dependence; poverty three-way split blurs → report as economic vs (charitable+spiritual) binary with the boundary cases read qualitatively.

## 10. Venue

- **EN:** *Journal of Media and Religion* · *Social Compass* · *New Media & Society* (the dual-lens method leads) · *Journal for the Scientific Study of Religion*.
- **HR:** *Društvena istraživanja* · *Medijska istraživanja* · *Nova prisutnost*.

## 11. Working titles

1. *Two lenses on the same discourse: keyword and meaning-based measurement of how religion mediates the economy in Croatia.* (method-forward)
2. *Justice for work, charity for the poor: the register of religious economic discourse in a national mediasphere.* (finding-forward)
3. HR: *Dvije leće na isti diskurs: ekonomija u hrvatskom katoličkom digitalnom prostoru (2021.–2026.).*

## 12. Theory anchors (harden via `/lit-review`)

Mediatization of religion (Hjarvard; Hoover) — the lead frame · CST economic framing + Iyengar episodic/thematic (charity↔justice) · moral economy (Thompson; Fourcade & Healy) · computational text analysis / embeddings for social science (validation-of-embeddings literature — needed to defend the meaning lens) · Croatian Catholic media.

## 13. Next steps (in order)

1. **Stage S1 — anchor calibration** (seed-post centroids from the Stage-A pool; balanced sets; soft assignment). Re-run coverage → does the ranking convergence tighten?
2. **Stage S3 — register grid + poverty split** on all 11 domains with calibrated anchors.
3. **Stage V — build + hand-code the ~500-post gold sample**; report semantic-vs-human agreement. Gate everything on this.
4. `croatian-nlp-reviewer` on the anchors; `/lit-review` on the two new theory strands (mediatization; embedding-validation) — in parallel.
5. **OSF prereg (H1, H2)** → Stage C analyses + the meaning map → draft.

---

## 14. Mapping v2 → v3 (what moved)

| v2 (keyword-only) | v3 (dual-lens) |
|---|---|
| Coverage from keyword linkage counts | Coverage from **both** lenses, side-by-side; convergence = the test (H1) |
| Register via **hand-coding ~10,000 posts** (κ 0.46 bottleneck) | Register via **semantic scoring at scale, validated on ~500 hand-coded gold** |
| Poverty economic/doctrinal split = a flagged *worry* needing a hand-pass | Poverty split = a **measured result** (pilot ~73/27), hand-validated |
| Deliverables: grid + actor map + temporal | + **coverage-convergence figure, recall-gap audit, 2D meaning map** |
| Contribution: substantive map + linkage-not-co-occurrence method | + **validated dual-lens instrument** (the transferable methods contribution) |
| Risk: the coding step is fragile and huge | Risk moved to **anchor calibration + gold-sample validation** — smaller, faster, and itself reportable |
