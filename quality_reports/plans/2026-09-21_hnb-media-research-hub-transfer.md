# Croatian National Bank in the media: research hub transfer specification

Prepared 21 September 2026. Intended destination: the existing Croatian National Bank research project, alongside its paper, data documentation, and analytical code.

This document is a self-contained implementation brief. Give the entire document to the researcher or coding agent working in that project. The requested outcome is a coherent public research resource, supported by the research already completed there. The present document specifies that work; it does not claim that HNB findings, data availability, or validation have already been checked.

The reference is **“Demokršćanstvo u medijima”** in DigiKat. Here, “the same principle” means its research-to-publication architecture: accessible questions → supported findings → explorable evidence → substantive reports → transparent methods and reusable data. It does not mean constructing a democratic-integrity score, assessing Christian-democratic ideas in HNB coverage, or replacing words in the existing page.

The DigiKat source, linked publication sources, aggregate metadata, and methods were inspected locally. The HNB project location and paper were not supplied during preparation. Consequently, HNB categories below are proposed analytical distinctions, and page text describes the intended resource rather than asserting results. Audit the destination project before implementing them.

**Reading routes:** start with the [implementation instruction](#1-instruction-to-the-implementing-researcher-or-agent); use the [project audit](#3-audit-the-existing-hnb-project-before-designing-around-it) to map existing work; consult the [indicator catalogue](#8-indicator-catalogue-implement-selectively) and [economic context](#10-add-external-indicators-to-answer-specific-questions) for analytical choices; then follow the [page specification](#11-specify-the-public-page), [publication family](#12-produce-a-coherent-publication-family), and [execution plan](#15-execution-plan-with-concrete-completion-criteria). The final two sections identify the reference code and official data sources.

## 1. Instruction to the implementing researcher or agent

> Build a Croatian-language public research hub titled **“Hrvatska narodna banka u medijima”**, using DigiKat’s “Demokršćanstvo u medijima” page and publication family as the structural model. Start by reading and inventorying this HNB project’s paper, appendices, data definitions, scripts, figures, completed analyses, and publication constraints. Preserve established research definitions and frozen paper results. Identify which existing findings can support each public component, which can be adapted, and which require new analysis. Reuse strong existing work before proposing additional models.
>
> Translate the reference’s analytical questions into HNB-specific questions about institutional visibility, economic and policy topics, communication, attributed responsibility, voices, and scrutiny. Distinguish HNB mentions from substantive HNB coverage; HNB as an information source from HNB as the object of reporting; statements about economic conditions from evaluations of the institution; and media discourse from public opinion. Treat HNB, the ECB/Eurosystem, commercial banks, and the Croatian government as distinct actors whose responsibilities must be interpreted for the relevant date.
>
> Deliver an evidence-led landing page, an interactive topic explorer and time-series view, two complementary public reports in HTML and PDF where the evidence supports both, a concise findings presentation in HTML and PDF, a research-and-paper linking layer, public aggregate downloads, and versioned methodology and provenance. All artifacts must draw from the same verified release or clearly identify their different releases. Existing paper results remain tied to the paper’s original analytical version.
>
> Implement the core resource first. Add target-specific stance, communication-transfer measures, and macroeconomic comparisons only when the required text, dates, validation, and external series exist. Do not invent findings, inherit the reference’s topic count, reuse its private material, or create an unsupported overall HNB reputation/trust/performance score. If one optional module lacks evidence, omit it or present its research question without a result; continue the independently supportable work.
>
> Use the detailed specifications below as the working plan. Resolve ordinary implementation choices from the repository and document them. Escalate only decisions that materially change the study’s population, scientific claims, rights to publish, or authorized publication scope. Produce a concrete local preview and a verification report before deployment.

## 2. What the reference actually provides

### 2.1 Reader journey and resource family

The active page at `pages/demokrscanstvo/index.qmd` has eight anchored sections, plus its introductory hero:

| Reference component | What it does for the reader | HNB translation |
|---|---|---|
| Hero and coverage strip | States a public question; gives dates/platforms; offers direct routes to findings, topics, and publications | Ask how HNB enters public discussion; state actual corpus coverage and edition date |
| `#pregled` | Four numerical orientation cards and a brief interpretation | Show the scale and composition of the verified HNB corpus, without filling the cards with speculative scores |
| `#nalazi` | Three substantive findings and a preview of the findings presentation | Select three robust findings from the paper and existing analyses; link each to its supporting view and study |
| `#teme` | Topic explorer filtered by platform and year; descriptions, counts, terms, and platform distributions | Explore HNB topics with stable labels, explicit denominators, and the same model across filter selections |
| `#kretanja` | Monthly relative visibility with platform selection and static fallback | Separate HNB attention from changes in monitoring; optionally annotate policy events and economic releases |
| `#platforme` | Distribution across platforms with an expandable numeric table | Show where observed HNB coverage comes from, separating media, official communication, and audience discussion |
| `#javna-pitanja` | Overlapping public-policy categories, distinct from exclusive model topics | Show everyday and policy implications: prices, household budgets, credit, savings, financial resilience, accountability |
| `#izvjestaj` | Two complementary report cards and a presentation, with online and downloadable formats | Provide overview + language/communication report + findings deck; surface the existing academic paper prominently |
| `#metoda` | Plain-language definitions, technical documentation, and downloads | Explain scope, units, denominators, dates, validation, limitations, citation, and release lineage |

The three currently published reference assets are:

1. **Demokršćanstvo u medijskom prostoru**: a 14-page public overview, PDF and HTML.
2. **Demokršćanstvo: od riječi do argumenta**: a 12-page language/argument report, PDF and HTML.
3. **Demokršćanstvo u medijima: 12 ključnih nalaza**: a 15-slide presentation, PDF and HTML, with 12 findings.

Those lengths describe the reference; they are not HNB quotas. Its page also provides six direct aggregate/definition downloads, with more provenance in the release directories. The reports’ source packages and technical analyses are useful implementation references but are not all public navigation destinations.

### 2.2 The analytical architecture worth retaining

- The public page provides a readable synthesis while allowing deeper inspection.
- Topics, time, source composition, and concrete public issues answer different questions.
- Topic discovery is separate from rules used to include material in the corpus.
- Model-derived primary topics form a partition, including unassigned cases; policy tags can overlap.
- Publication volume and distinct-text language analysis use different units, named explicitly.
- The publication family uses shared data, linked methods, consistent typography, and verified numerical claims.
- The page reads prepared public aggregates; rendering does not query a private database or rerun research.
- HTML remains useful without interactive JavaScript. Reports and charts have readable numeric alternatives.

### 2.3 What must be redesigned

The active reference is an **all-platform descriptive empirical release**, distinct from the historical **115-outlet fixed-panel study**. Its source metadata says independent human validation is incomplete. Do not treat its public availability as evidence that any classifier or interpretive measure is already validated for HNB.

The reference has three different counts: 2,306 archived records, 2,253 exact-text groups in the language report, and 1,731 distinct contexts used to fit the topic model. These are not three estimates of the same population. HNB needs its own corresponding unit definitions and reconciliations.

Do not transfer:

- Christian-democratic inclusion routes, religious dictionaries, ideological categories, or actor registries.
- The assumption that 10 topics, 14 platforms, or the reference dates suit the HNB project.
- Its particular text-window length, classification thresholds, sample sizes, or uncompleted validation workflow as automatic defaults.
- Its display/data seam: the page shows rates per 100,000 while its CSV stores `per_10000`. Use consistent units in new HNB exports and charts.
- Any inference that negative economic vocabulary expresses hostility to HNB.
- The reference’s current choice to connect the trend across a known collection change. The technical README and current rendering differ on this point. Decide HNB comparability from HNB evidence and keep its documentation and charts aligned.
- Topic-specific authorship, institutional branding, rights restrictions, or permissions as though they automatically apply to the destination project.

## 3. Audit the existing HNB project before designing around it

### 3.1 Read in this order

1. Repository instructions, README, project purpose, data-access documentation, and environment lockfiles.
2. The latest paper and its actual status: published, accepted, submitted, working paper, or draft. Record the canonical manuscript path and version.
3. The abstract, research questions, hypotheses, tables, figures, conclusions, limitations, and supplements.
4. Data collection and inclusion code, dataset manifests, source/platform coverage, time fields, deduplication, language filters, and missingness reports.
5. Completed topic, sentiment, stance, framing, actor, event, network, communication, and econometric analyses, if present.
6. Validation datasets and results, distinguishing development checks from held-out evaluation and independent human coding.
7. Existing public outputs, prior releases, related studies, bibliography, website stack, and any restrictions on publishing extracts or article-level links.

Read the results and code, not only filenames. An object named `sentiment_hnb` may measure whole-text economic tone rather than HNB-directed stance. Establish what every reused variable actually means.

### 3.2 Produce four small project records

**A. `research-inventory.csv`** — one row per reusable study or analysis:

```text
research_id,title,path_or_url,status,authors,version,date,
research_question,population,period_start,period_end,unit,
method,validation_status,principal_result,limitations,
reproducible_entrypoint,input_release,output_tables,output_figures,
publication_rights,proposed_page_section,reuse_action
```

Use `reuse_action = reuse | adapt | new_analysis | defer`. Do not label unfinished work published or peer-reviewed.

**B. `evidence-map.csv`** — one row per proposed public claim:

```text
claim_id,proposed_croatian_text,research_id,artifact_path,
table_or_figure,estimand,unit,numerator,denominator,filters,
period,release_id,uncertainty,validation_status,
support_status,public_destination,review_note
```

Use `support_status = supported | supported_with_qualification | unavailable | contradicted`. A model coefficient, selected example, and population percentage are different claim types.

**C. `decisions.md`** — settled assumptions, alternatives rejected, unresolved questions, and why each matters. Include primary audience, date scope, corpus layers, edition policy, source rights, and which paper results must remain frozen.

**D. `gap-analysis.md`** — a short mapping from this specification to the inventory. Identify the smallest additional work needed for each missing component and whether it can be omitted without weakening the main page.

### 3.3 Rules for reuse

- A supported result should be translated into accessible Croatian and linked to its evidence, rather than recomputed with a new definition merely to match the page design.
- A result with inadequate validation can motivate a question or a carefully bounded descriptive view; it does not become a validated headline finding through editing.
- A paper result and an updated website result may coexist. Label their periods, populations, and versions; do not overwrite the published result.
- If the paper uses a topic-specific corpus, do not claim a share of all Croatian media unless a separate, compatible background denominator exists.
- If several studies overlap in source material, record that dependence. Their agreement is not necessarily independent replication.
- If the destination already has a reliable stack, keep it. The blueprint is not a requirement to migrate everything to R, Python, or Quarto.

**Audit completion criterion:** every proposed page module has a source, an explicit additional analysis, or a documented omission. No invented studies, numbers, links, or file locations remain in the plan.

## 4. Define the HNB-specific research question

### 4.1 Recommended central question

**How is the Croatian National Bank made visible and interpreted in the media, in relation to economic conditions, policy decisions, institutional responsibility, and citizens’ everyday concerns?**

This supports six connected analytical questions:

1. **Visibility:** When, where, and how prominently does HNB appear? Is it central to the story or a passing statistical source?
2. **Agenda:** Which economic, institutional, and social issues organize the coverage? How does their composition vary over time and across source types?
3. **Voice and role:** Who speaks about HNB? When does HNB itself explain, forecast, announce, defend, or respond?
4. **Interpretation and responsibility:** How are HNB decisions, competence, independence, accountability, and responsibility described? Which actor is credited or blamed, by whom, and for what?
5. **Communication:** Which elements of official communication reach media coverage? What is retained, simplified, contextualized, challenged, or left out?
6. **Economic context:** How does observed coverage co-vary with inflation, interest rates, credit conditions, and selected events? Which relationships are supported descriptively, and which have a defensible causal design in existing research?

### 4.2 The institutional distinction that shapes the entire project

Croatia adopted the euro and HNB joined the Eurosystem on **1 January 2023**. HNB participates in euro-area monetary policy and implements it within its remit; euro-area policy rates are not a unilateral HNB choice. HNB also has national functions, including responsibilities relating to financial stability, supervision, and payments. Specify responsibilities using the rules applicable at the time. See [HNB’s institutional remit](https://www.hnb.hr/en/about-us/functions-and-structure/role) and [the ECB’s euro-entry announcement](https://www.ecb.europa.eu/press/pr/date/2023/html/ecb.pr230101~2046d0fd6f.en.html), also listed as S1–S2 below.

Create a dated responsibility registry for HNB, ECB/Eurosystem, government/Ministry of Finance, commercial banks, and other relevant regulators. For bank supervision and joint decisions, permit shared or qualified responsibility. Record source URLs and effective dates for the exact responsibility asserted.

Keep these distinctions throughout coding and prose:

| Distinction | Why it matters | Example of correct handling |
|---|---|---|
| HNB vs ECB/Eurosystem | Monetary-policy authority and participation change with the euro regime | An article about an ECB rate decision is not automatically an article evaluating HNB |
| HNB vs commercial banks | Retail pricing and lending decisions have several determinants and decision-makers | A complaint about a bank’s fee is not coded as criticism of HNB unless that target is stated or clearly resolved |
| HNB vs government | Monetary, fiscal, tax, and administrative measures differ | Record the article’s claimed responsibility separately from the research team’s assessment |
| Institution vs officeholder | Visibility of a governor can concern institutional activity or another subject | Include officeholders through contextual and date-valid role evidence |
| Economic conditions vs institutional evaluation | “Inflation is high” can be negative news with no evaluation of HNB | Maintain separate economic-tone and HNB-stance fields |
| Official message vs media interpretation | Coverage can quote, endorse, question, or oppose an official message | Identify both the original speaker and the reporting voice |
| Media discourse vs population attitudes | A corpus contains selected publications and participants | Call a measure “critical coverage” or “expressed distrust,” not “public distrust” |

**Do not equate media misattribution with deliberate misinformation.** Code what is attributed, verify the relevant remit where necessary, and reserve intent claims for evidence that can establish them.

## 5. Establish corpus layers and analytical units

### 5.1 Keep related corpora separate but linkable

| Layer | Definition | Main use | Boundary |
|---|---|---|---|
| A: Direct HNB coverage | HNB is explicitly named, unambiguously referenced, or represented by an officeholder acting in that role | Main institutional attention and topic analysis | Record central, secondary, and passing mentions separately |
| B: Broader policy context | Relevant Croatian monetary, banking, inflation, euro, or financial-stability discussion without a necessary HNB reference | Context/comparison and a potential selected-policy denominator | Do not label all of it HNB coverage or assume it is a complete denominator |
| C: Official communication | HNB releases, speeches, reports, interviews, announcements, and selected ECB material | Institutional agenda and message-to-coverage analysis | Official publication volume is not earned media attention |
| D: Audience discussion | Available comments, forums, and social posts relevant to the topic | Observed discussion, questions, reactions, circulation | Participants are not a representative sample of Croatia |
| E: Existing research artifacts | Papers, validated analytical datasets, supplements, and finished studies | Findings, explanatory links, and reproducibility | Preserve each artifact’s original population and version |

These can be flags within common storage rather than five duplicate databases. Each chart must declare which layer or union of layers it uses. Deduplicate overlapping layer unions by publication ID. An HNB-authored post and a news article quoting it must not be silently counted as the same kind of media response. An interview reproduced on both sites has two publication instances, a documented relationship, and distinct publisher roles; classifying its content as official communication does not make the news-site publication an HNB-owned channel.

### 5.2 Entity and relevance rules

Build the HNB lexicon from the destination project, then test it against examples. Candidate expressions include “Hrvatska narodna banka,” “HNB,” inflected forms such as “HNB-a,” “HNB-u,” and “HNB-ov,” English names when relevant, historical names if the corpus requires them, and officeholders’ names with valid role dates. The bare expression “narodna banka,” the acronym in an unrelated context, or a name outside its institutional context must not suffice.

Preserve Unicode and original text. Normalize a matching copy; document diacritic and ASCII variants. Resolve ambiguous names and cross-country central-bank references. For HTML, remove navigation, recommendations, and recurring boilerplate before testing substantive relevance. For audio/video, describe the text actually available; do not imply audiovisual analysis when only captions, descriptions, or partial transcripts were analyzed.

Use three relevance levels as a proposed starting point:

- **Central:** HNB, its decision, institutional position, or official analysis is a main subject.
- **Secondary:** HNB is substantively discussed within a broader story.
- **Passing:** HNB appears only as a brief attribution, isolated statistic source, or incidental mention.

Add `unassessable` where truncation prevents a decision. Validate these levels before publishing centrality percentages. Avoid arbitrary rules such as “two mentions means central” unless their performance has been demonstrated.

### 5.3 Name every unit

Retain distinct identifiers for:

```text
capture_id       a retrieval/capture in the archive
publication_id   a publication instance on a source/platform
exact_text_group_id an exact-text group under a documented normalization rule
near_duplicate_cluster_id an optional approximate-text cluster, separately validated
story_cluster_id an estimated common story/event, only if separately validated
context_id       the HNB-relevant passage used for a particular analysis
statement_id     a speaker–target statement or argument, where coded
official_doc_id  an official communication item
event_id         a dated announcement, decision, release, or contextual event
```

Do not create `story_cluster_id` merely by renaming a duplicate-text ID. Same text, same story, and same event are different concepts.

Use publication instances for distribution and circulation. Use deduplicated text groups for language comparisons where syndication would otherwise dominate. Use statements for speaker-specific stance and arguments. Report both publication-weighted and text-group-weighted results when repeated agency material materially changes the conclusion.

### 5.4 Denominators and time fields

For each platform/source and period, determine whether you possess:

1. All eligible monitored content in a compatible background archive.
2. Only a selected economics/policy background corpus.
3. Only HNB query results.

Only case 1 permits a rate described as HNB coverage per all monitored publications. Case 2 permits a rate explicitly described as a share of that selected background. Case 3 permits HNB counts and within-HNB composition, not HNB prevalence in the whole media environment. “All monitored” still does not mean “all Croatian media.”

Keep publication date/time, archive capture date/time, event date/time, and official release date/time separate. Record timezone, precision, date provenance, and missingness. Use Europe/Zagreb for reader-facing local dates where appropriate. Do not calculate hours-to-coverage from capture dates or day-only timestamps. If only capture dates exist, label the timeline accordingly and omit unsupported lag analysis.

Build a coverage table with source start/end dates, platforms, searchable/full-text counts, known outages, collection regimes, and partial periods. An observed day is not proof of complete monitoring. A zero numerator is valid only when the denominator/coverage is known; unavailable is not zero.

## 6. Use an HNB-specific analytical framework

### 6.1 Proposed topic families, to reconcile with existing research

These are a starting taxonomy for audit and coding, not a claim that a model will find exactly ten topics:

| Candidate family | Interesting subquestions | Boundary to code |
|---|---|---|
| Prices, inflation, and purchasing power | Which price pressures are discussed? How are forecasts and responsibilities explained? | Inflation reporting without HNB belongs to context unless a direct link is established |
| Interest rates and monetary transmission | How do policy rates relate in reporting to housing loans, business credit, and savings? | Separate ECB decisions, HNB explanations, and bank product rates |
| Euro adoption and monetary integration | How are conversion, price perceptions, sovereignty, and integration framed? | Separate preparation, changeover, and later euro-area membership |
| Lending, housing, and household indebtedness | Who is described as constrained, protected, or exposed? | Distinguish market developments, regulation, and individual experiences |
| Banking stability and supervision | How are risks, resilience, bank conduct, and supervisory actions described? | State the relevant authority and avoid assuming all supervision belongs to one actor |
| Economic forecasts, data, and expertise | Is HNB cited for evidence, forecasts, or authority? How is uncertainty communicated? | A citation to HNB statistics is not necessarily evaluation of HNB |
| Independence, governance, and accountability | What questions are raised about appointments, transparency, conflicts, or scrutiny? | Record allegations and responses as attributed claims, not established facts |
| Payments, cash, and financial infrastructure | Which practical access, technology, security, or service issues enter coverage? | Match each subtopic to the actual project period and available material |
| Consumers, fees, savings, and financial literacy | How are public concerns translated into institutional responsibilities and explanations? | Avoid treating individual anecdotes as population prevalence |
| European and international institutional relations | How is HNB situated among European institutions and other central banks? | Separate institutional background from substantive HNB reporting |

Keep `other` and `unassigned` visible. If the paper already has a defensible taxonomy, map it to these questions instead of replacing it. Record one-to-many mappings and ambiguities. Do not silently merge materially different paper categories.

### 6.2 Keep six annotation dimensions distinct

1. **Topic:** the subject discussed.
2. **Frame:** the organizing interpretation, such as technical management, household consequences, political conflict, risk/resilience, or accountability. A frame requires contextual evidence.
3. **Speaker/voice:** HNB representative, ECB representative, journalist/editorial voice, politician, commercial-bank representative, independent expert, business, household/consumer representative, or other/unknown.
4. **Target and stance:** whom/what a statement evaluates and whether it is supportive, critical, mixed, or descriptive/neutral. Keep a present target with no evaluation separate from no identifiable HNB target (`not_applicable`) and insufficient evidence (`unassessable`).
5. **Attributed responsibility:** actor, outcome/action, attribution type, and speaker. The author’s verified responsibility assessment is a separate field.
6. **Argument/explanation:** stated problem → institution/decision → mechanism/evidence → consequence or proposed response, with uncertainty and qualifiers preserved.

The same article can contain several speakers, targets, frames, and stances. Do not collapse opposing quotations into a single institutional attitude without an explicit, validated aggregation rule.

### 6.3 The distinctive replacement for “from words to arguments”

The HNB equivalent should investigate **how economic information becomes a public explanation**. A useful report title is **“HNB u javnoj raspravi: poruke, tumačenja i odgovornost.”**

Examine whether coverage:

- Merely cites a number or institution, or explains why a development matters.
- Connects a policy decision to a mechanism and to consequences for households or firms.
- Separates observations, forecasts, risks, and recommendations.
- Preserves uncertainty, conditions, time horizons, and attribution from an official message.
- Adds independent evidence, competing interpretations, or accountability questions.
- Uses a headline whose emphasis differs from the body.

Neither agreement with HNB nor verbatim reproduction is a definition of good journalism. Critical reporting can accurately convey a message and scrutinize it. Faithful transmission and journalistic evaluation must be separate variables.

## 7. Analytical workflow and validation

### 7.1 Prefer the existing validated pipeline

Make a reproducible adapter from established HNB outputs to the public release. New classification, topic modeling, or econometrics is justified by a documented gap, not by the presence of that feature in DigiKat.

For topic discovery when genuinely needed:

1. Identify whether full articles or HNB-relevant passages answer the intended question. Compare them on a pilot; whole articles can be dominated by unrelated context, while short windows can lose argument and attribution.
2. Deduplicate fitting units appropriately; preserve publication multiplicity for visibility counts.
3. Reuse the project’s Croatian NLP tools and inspect financial terminology, named entities, negation, and inflections.
4. Remove retrieval boilerplate from topic features without erasing the institution/entity information needed for attribution analysis.
5. Evaluate a small candidate set of topic solutions with domain reading, distinctiveness, stability, unassigned cases, and compatibility with prior research.
6. Assign reviewed labels and descriptions. Save examples privately, where rights require it.
7. Freeze one model per release. Filters subset assignments; they must not refit the model on each platform/year.
8. If using the reference's primary-topic display, reconcile every included item to one primary topic or unassigned. Preserve an existing HNB multilabel/probabilistic model and its original outputs; derive a primary display only if justified and documented. Otherwise use a clearly labelled multilabel or topic-weight view with the appropriate interpretation. Keep policy tags in separate tables.
9. Quantify sensitivity to duplicate handling, source composition, text availability, language, and date regime.

The reference’s TF–IDF/NMF approach is a transparent possible baseline, not a required method. Reuse a stronger established HNB method if available. Topic stability is not evidence of stance accuracy or human agreement.

### 7.2 Human validation and sampling

Design validation for the actual claims:

- Relevance/entity retrieval: assess both false positives and false negatives. A sample drawn only from accepted hits cannot estimate recall. Sample rejected/background records through a documented independent retrieval or probability design where the archive permits it. Alternative retrieval can expose missed cases, but recall measured on its union applies only to that evaluation frame. Corpus-wide recall requires a defensible reference frame or probability design with known inclusion probabilities.
- Topic interpretation: review representative, random, weak-assignment, and ambiguous cases. Leading examples alone can make poor topics appear coherent.
- Targeted stance, responsibility, frames, and explanation: independently code a development pilot, reconcile definitions, then evaluate on separate material.
- Match strata to likely failures: pre/post euro membership, collection regimes, platforms, source types, headlines/full text/snippets, minority classes, officeholder references, and highly syndicated stories.
- Keep development, training, and evaluation groups separate at the text/story level where leakage is plausible. A copied article in both train and test is not independent evaluation.
- Preserve independent labels, adjudicated labels, disagreements, coder notes, rule/model versions, and sampling probabilities.

Report class-specific precision and recall, confusion matrices, uncertainty, and an appropriate agreement statistic. Set release criteria before the final evaluation based on the claim’s stakes and acceptable error; do not copy an unexplained threshold from another project or optimize it after viewing test results.

If prevalence is estimated from a stratified coded sample, use its sampling weights and design-aware uncertainty. If a classifier labels the full observed archive, explain classification error and selection limits; a narrow binomial interval does not capture those uncertainties. If dependable evaluation is absent, restrict strong interpretive claims and label the method accurately.

### 7.3 Minimum robustness checks

Check whether each headline result survives reasonable alternatives:

- Publication counts versus distinct-text counts.
- All available sources versus a demonstrably stable source subset, if one exists.
- All searchable material versus adequate full text.
- Direct HNB coverage versus substantive central/secondary coverage.
- Large-source or high-volume agency exclusion/sensitivity, without selectively deleting inconvenient evidence.
- Separate collection regimes and institutionally meaningful periods.
- Consistent units and categories when comparing to the paper.

Record changed conclusions, not only successful checks. Qualify or drop a headline whose interpretation depends on a fragile choice.

## 8. Indicator catalogue: implement selectively

### 8.1 Notation and release rules

For a specified layer, platform/source group `p`, and period `t`:

- `N_pt`: eligible background publications under a compatible monitoring rule, if available.
- `H_pt`: included HNB publication instances, after capture deduplication.
- `H_kpt`: publications assigned primary topic `k`.
- `A_pt`: HNB publications with sufficient text for the particular coding task.
- `U`: distinct eligible text groups for a defined language-analysis slice.

Every percentage must carry its numerator, denominator, unit, scope, and available/unassessable count. `A_pt` can differ by task: enough text for entity relevance may be insufficient for argument analysis. For sampled coding, replace raw ratios with the corresponding weighted estimates.

Do not combine the following into one overall index. Choose a small set for the landing page; place specialist indicators in reports or topic detail views.

| ID and priority | Indicator and computation | What it answers | Required condition / limitation |
|---|---|---|---|
| M01 Core | **Observed coverage:** `H_pt` | How much HNB material is in the monitored archive? | Accompany with coverage status; not the volume of all Croatian media |
| M02 Core if denominator exists | **Relative visibility:** `100000 × H_pt / N_pt` | How prominent is HNB within the monitored content? | Same eligibility, source/time scope, and unit in numerator and denominator; unavailable if `N_pt` is absent or zero |
| M03 Core | **Primary topic share:** `100 × H_kpt / H_pt` | What is the composition of HNB coverage? | Include unassigned; all primary shares sum to 100% apart from rounding |
| M04 Core when tags supported | **Public-issue prevalence:** `100 × H_jpt / H_pt` if all items are assessable; otherwise tagged items divided by task-specific assessable items | Which everyday/policy concerns accompany HNB? | Show unknown/unassessable items; tags overlap and sum may exceed 100%; specify local HNB context versus full text |
| M05 Core | **Source/platform composition:** `100 × H_pt / Σ_p H_pt` for mutually exclusive groups in a declared period | Where do the observed publications come from? | Common time window; official and independent sources distinguishable; not audience reach; overlapping groups require separately labelled proportions |
| M06 Conditional | **Substantive centrality:** central + secondary HNB items divided by relevance-assessable HNB items | How often is HNB discussed substantively rather than mentioned? | Validated relevance coding; disclose passing and unassessable categories |
| M07 Conditional | **HNB voice presence:** assessable items containing attributed HNB speech divided by `A_pt` | How often does HNB speak in the coverage? | Separate direct quotation, paraphrase, and mere data citation; presence is not endorsement |
| M08 Conditional | **HNB data/forecast citation:** items explicitly sourcing data/forecasts to HNB divided by `A_pt` | How often is HNB used as an information authority? | Distinguish forecast from observation; overlap with M07 is allowed |
| M09 Conditional | **Target-specific stance distribution:** shares supportive, critical, mixed, descriptive/neutral, unclear | How is HNB evaluated in attributable statements or texts? | Choose statement or publication unit explicitly; preserve multiple voices and unassessable share; no generic sentiment substitution |
| M10 Conditional | **Mechanism explanation:** items meeting the validated decision/action → mechanism → consequence code divided by assessable substantive items | Does coverage explain how a policy or economic process works? | Keyword co-occurrence and article length are insufficient; allow accurate explanation combined with criticism |
| M11 Conditional | **Responsibility attribution:** share of coded responsibility claims assigned to each actor | Who is credited, blamed, or expected to act? | Claim-level measure; distinguish reported attribution from independently checked remit; overlapping/shared actors allowed |
| M12 Conditional | **Officeholder visibility:** substantive HNB items referring to an officeholder divided by substantive items assessable for this code | How often are institutional representatives named? | A name mention alone does not establish personality-centred framing; use a separate deeper code if needed |
| M13 Conditional | **Lexical prevalence:** `100 × number of U containing term/phrase / U` | Which expressions recur across different texts? | Show selected text scope, lemmatization, and text-group denominator; a word is not a belief |
| M14 Optional | **Headline/body emphasis difference:** assessable pairs with a validated difference in target, certainty, or emphasis divided by assessable pairs | Does the headline foreground something different from the body? | Not a generic distortion score; preserve legitimate summarization and quotations |
| M15 Optional | **Communication uptake:** eligible official items with ≥1 validated independent-media match in window `W` divided by eligible official items | Which official messages receive observed coverage? | Complete follow-up window, stable monitoring, matching validation, genre breakdown; exclude own-channel reposts |
| M16 Optional | **Message-element retention:** matched pairs retaining an element divided by matched, element-assessable pairs where that element exists in the original | Which mechanisms, qualifications, numbers, and uncertainties survive translation? | Each element has its own denominator; unassessable pairs are not omissions; quote overlap alone is insufficient |
| M17 Optional | **Observed uptake lag:** time from official release to first matched independent publication | How quickly does observed coverage appear? | True publication timestamps; censor unmatched/right-truncated items; call it “observed lag” and avoid a global median over only successes |
| M18 Optional | **Publisher concentration:** `Σ_i (n_i / N_known)^2`, where `n_i` is publisher `i`'s publication count and `N_known = Σ_i n_i` in the same slice | Is observed coverage concentrated among a few identified publishers? | Publisher identity/group rule fixed; report unknown-source share; concentration is not ideological diversity |
| M19 Optional | **Outlet breadth:** active panel outlets with ≥1 HNB item divided by eligible active panel outlets | How widely does coverage spread in a specified stable panel? | Requires a defensible panel/activity denominator, not just outlets returned by an HNB query |

For M09, a primary statement-level table is often preferable. If a publication-level summary is needed, document how multiple statements produce supportive/critical/mixed/neutral categories. Never add overlapping statement labels and describe them as an exclusive article distribution.

For M17, a first descriptive release may show the share covered within 24 hours, 72 hours, or seven days, restricted to official items with complete corresponding follow-up. Select windows based on media cadence before analysis. A conditional lag median can be shown only if explicitly labelled “among matched items,” with the matching rate alongside it.

### 8.2 Recommended first release

Use M01, M03, M05, and M02 if its denominator exists. Add M04 and up to two of M06–M11 only if the existing research already supports them. Move other indicators to later releases according to the inventory. A complete, credible page can be built without a sentiment gauge, communication-transfer model, or econometric extension.

For period comparisons, show both absolute counts and composition where helpful. An increased topic share can reflect fewer other stories rather than more stories on that topic. Report changes in percentages as **percentage points**, and distinguish them from relative percentage changes.

## 9. Link official communication to independent coverage

This is the most promising substantive extension if the project already contains deep communication research. It requires a separate official-document inventory, rather than treating HNB website pages as ordinary independent media coverage.

### 9.1 Official-document fields

```text
official_doc_id,title,canonical_url,document_hash,language,
genre,author,speaker,role_at_date,institution,
publication_timestamp,event_timestamp,reference_period,
decision_announcement_date,effective_date,version,
topic_ids,event_id,revision_or_republication_flag
```

Record the original source when an HNB page republishes an interview. It must not appear that the interview responded to a later HNB repost. Distinguish policy decisions, official statistics, forecasts, analysis, speeches, interviews, rebuttals, and educational material. Preserve author-level attribution for blog/research material.

Official sources include HNB press releases, speeches, interviews, information/responses, HNBlog, macroeconomic forecasts, financial-stability publications, and the release calendar (source group S4).

### 9.2 Matching procedure

1. Define an eligible set of official documents and fixed follow-up windows by genre.
2. Generate candidate media matches using dates, named entities, document titles, numbers, quotations, URLs, event references, and textual similarity.
3. Validate candidate matching, including false matches from recurring standard language or a common third-party source.
4. Allow many-to-many document–article links. Save matching confidence, evidence type, and review status.
5. Separate literal syndication, attributed quotation/paraphrase, and independent interpretation. A text-similarity edge does not by itself prove information flow or influence.
6. Code message elements, including stated uncertainty and conditions, on a sampled or complete assessable set according to the validated design.
7. Compare by genre and topic. A technical statistical release and a controversial policy announcement have different expected coverage.

### 9.3 Public case-study format

Select three cases through stated criteria, not only the largest peaks:

- A routine forecast/statistical communication, illustrating ordinary use of HNB as an information source.
- A concrete policy measure, illustrating mechanisms, household consequences, and different institutional responsibilities.
- An episode of scrutiny or disagreement, illustrating attribution, criticism, and response.

For each: public question → official event and precise dates → what HNB said → how coverage represented it → what other voices added → what the example establishes and cannot establish. Include contradictory examples where they change the interpretation.

One verified candidate, **if within the corpus**, is HNB’s consumer-lending criteria: announcement/consultation, decision communicated on **19 March 2025**, and entry into force on **1 July 2025** are different event stages (S5). The case can connect financial stability, credit access, and household consequences. It is a candidate for analysis, not a pre-established finding.

Use sourced paraphrases and lawful short extracts where appropriate. Link verified public sources; do not invent a URL when only an archival copy exists. Keep restricted evidence passages in the private analytical layer.

## 10. Add external indicators to answer specific questions

### 10.1 Prioritized data menu

No external series is mandatory just because it is available. Start with two or three that illuminate the existing paper. Each selected series needs an explicit research question, a source, a join rule, and an interpretation limit.

| Priority | Indicator | Media question it can contextualize | Source / frequency | Key distinction |
|---|---|---|---|---|
| First | Croatian and euro-area HICP annual inflation; selected components if relevant | Does inflation-related HNB attention accompany observed price pressures and releases? | Eurostat/DZS; monthly (S6) | Harmonized inflation vs national CPI; rate vs price level; no claim HNB alone determines inflation |
| First | ECB policy rates, beginning with deposit-facility rate if justified | Does coverage track monetary-policy announcements and transmission? | ECB; effective-date series and separate announcement calendar (S3) | Announcement vs effective date; euro-area policy vs unilateral HNB decision |
| First | New housing/consumer loan rates and household deposit rates | Does coverage distinguish borrowers’ and savers’ experiences? | HNB; monthly weighted rates (S7) | New business vs outstanding contracts; household vs corporate; nominal vs effective rates |
| Next | Household/corporate credit and deposit growth | How does lending/saving coverage relate to recorded conditions? | HNB monetary statistics; series-specific cadence (S8) | Stocks vs flows and adjusted growth; valuation/reclassification effects |
| Next | Credit standards and loan demand | Do reported credit constraints correspond to bank survey assessments? | HNB bank-lending survey; quarterly (S9) | Bank responses/net percentages, not consumer sentiment or realized lending growth |
| Next | NPL ratio and a capital/liquidity measure | How do financial-stability narratives relate to sector indicators? | HNB supervisory tables; verify selected frequency (S10) | Different denominators and revisions; sector conditions are not an HNB performance score |
| Optional | House-price index and, only with an adequate income measure, affordability | How do housing-credit debates relate to prices and purchasing constraints? | Eurostat/DZS; quarterly HPI (S11) | Transaction prices vs rents; price index alone is not affordability |
| Optional | Croatian consumer confidence and verified price-perception/expectation questions | Does observed discourse coincide with household survey signals? | HNB / European Commission DG ECFIN; monthly where available (S12) | Confidence/qualitative balances are not trust in HNB or numerical expected inflation |
| Optional | Trust in ECB / attitudes toward the euro among Croatian respondents | How does institution-related coverage coexist with separately measured attitudes? | Exact Eurobarometer/Commission wave; wave-specific (S13) | ECB trust, euro support, and HNB trust are different constructs |

**Specific source checks:** the [ECB Consumer Expectations Survey country list](https://www.ecb.europa.eu/stats/ecb_surveys/consumer_exp_survey/html/index.en.html) checked for this plan excludes Croatia; do not present it as a Croatian sample. No comparable monthly HNB-trust series was verified. Use an actual HNB-specific survey only if the destination project supplies one with the exact question, sampling design, dates, weights, and provenance. Eurobarometer trust in the ECB cannot fill that gap; the [ECB’s trust-methodology discussion](https://www.ecb.europa.eu/press/economic-bulletin/articles/2024/html/ecb.ebart202403_01~05b13dbf02.en.html) distinguishes the survey constructs (S13–S14).

From January 2026, HICP/CPI classification/reference changes require checking current metadata; do not hardcode old series codes or join index levels across base changes without a documented consistent series (S6). The HNB euro-area bank-lending survey and its older archive also need a comparability check before concatenation (S9).

### 10.2 External-series contract

Store a source registry and immutable download snapshots:

```text
series_id,provider,source_url,provider_series_key,title,
geography,population,unit,frequency,adjustment,
reference_period_start,reference_period_end,value,
release_timestamp,vintage_date,retrieved_at,revision_status,
transformation,method_break,licence,source_hash
```

Not every provider supplies every historical release timestamp or vintage. Mark unavailable fields and narrow the analysis accordingly. Do not manufacture a real-time history from latest revised values. Eurostat’s live database does not provide a general historical version archive; save local snapshots and use archived releases for historical-information questions where needed. Consult official API documentation (S15).

### 10.3 Three different temporal analyses

**A. Descriptive context:** align monthly media measures with the corresponding economic observation month. Label the figure as co-movement and show release timing separately where material. Small multiples with shared time axes are generally clearer than unrelated dual axes.

**B. Information/communication response:** align coverage with the actual publication time of an HNB/ECB announcement or statistical release. Record decision, announcement, and effective dates separately. Exclude right-censored follow-up windows or model their censoring explicitly.

**C. Causal analysis:** reuse the paper’s causal result only if its identification and limitations support it. A new before/after comparison or correlation does not establish that media caused economic outcomes, that HNB communication changed public attitudes, or that a policy caused a coverage shift. Any causal extension needs its own design, counterfactual, assumptions, diagnostics, and research justification.

Do not interpolate quarterly bank stability or lending-survey values and display them as observed monthly data. If repeating a quarterly value for layout, label the repetition explicitly and do not count the repeated months as independent observations. Do not select lags after searching for the most attractive relationship without reporting the search and multiplicity. Account for autocorrelation and shared trends in any statistical comparison.

For forecast comparisons, preserve the exact forecast vintage, target variable, horizon, and first/updated realized value. A later revision is not what journalists knew at the earlier date; a forecast error is not automatically evidence of bias or incompetence.

## 11. Specify the public page

### 11.1 Proposed opening copy

**Title**

> Hrvatska narodna banka u medijima

**Lead question**

> Kako se o Hrvatskoj narodnoj banci govori u javnosti i s kojim se gospodarskim i društvenim pitanjima povezuje?

**Introductory paragraph**

> Analiza prati kada Hrvatska narodna banka ulazi u medijsku raspravu, koje teme oblikuju njezinu javnu sliku i tko sudjeluje u njihovu tumačenju. Povezuje izvještavanje o inflaciji, kamatama, euru i bankovnom sustavu s pitanjima svakodnevnog života, institucionalne odgovornosti i objašnjavanja gospodarskih odluka.

This is draft scope copy, not a statement of measured results. Narrow the listed topics if the audited corpus does not support them. Add the actual project name and authorship; do not imply the page is an official HNB service or endorsed by HNB without evidence.

### 11.2 Page order and section contracts

Use the following reader journey, with deeper modules omitted when unsupported:

| Section / anchor | Required content | Data/interaction | Reader takeaway |
|---|---|---|---|
| Hero | Title, question, short introduction, coverage and release dates | Three actions: key findings, topic exploration, publications | What this research can answer |
| `#pregled` — Pregled | Four orientation cards and a short scope sentence | Suggested cards: media publications about HNB; distinct texts; distinct independent-media publishers; coverage period. Substitute a validated substantive measure where useful | Scale and unit of the evidence |
| `#nalazi` — Ključni nalazi | Three supported findings, each with evidence link and bounded interpretation | Prefer one agenda finding, one time/source finding, and one communication/representation finding if available | What the existing research establishes |
| `#teme` — Teme rasprave | Topic distribution and explanatory detail | Platform/source group and period filters; topic description, count/share, terms, public issue, related research link | What coverage is about |
| `#kretanja` — Medijska pozornost | Counts and normalized visibility when available | Platform control; explicit selected period/unit; relevant event markers | When attention changes within observed coverage |
| `#izvori` — Izvori i glasovi | Source/platform distribution; separately, quoted voices if validated | Publisher and speaker have separate charts; source coverage table | Where coverage appears and who speaks |
| `#javna-pitanja` — Gospodarske odluke i svakodnevni život | Overlapping policy/household issues | Concise bars or matrix with denominator and overlap note | How reporting connects institutions to practical concerns |
| `#komunikacija` — Od poruke do tumačenja, conditional | Official-to-media case studies or validated uptake view | Clearly labelled official message → matched coverage → interpretation | How economic communication is translated |
| `#kontekst` — Gospodarski kontekst, conditional | Two or three explanatory indicator comparisons | Choose a question/indicator; aligned small multiples, units, source, and vintage | How media patterns sit alongside economic conditions |
| `#istrazivanja` — Povezana istraživanja | Main paper and selected related studies | Evidence-connected cards, accurate study status and DOI/repository links | Where to read the full research and related work |
| `#publikacije` — Izvještaji i prezentacija | Public overview, complementary report where justified, presentation | HTML/PDF, covers, author, edition, file size, period, citation | Different depths and formats for different readers |
| `#metoda` — O analizi i podaci | Concise method, limitation notes, downloads, citation, contact/version | Expandable explanations and technical links | How to interpret, check, and reuse the results |

The active DigiKat page does **not** contain a related-research section. `#istrazivanja`, official-message comparison, and external-indicator context are intentional HNB extensions, not existing reference features.

Keep sticky navigation compact: group deeper modules under a small number of understandable labels rather than displaying twelve cramped tabs. Every chart needs a sentence explaining the question before it and a supported interpretation after it. Avoid turning the page into an unprioritized catalogue of every analysis.

### 11.3 Interaction details

- Start with a meaningful default selection and show its actual denominator and period.
- Keep topic identifiers and descriptions fixed within a release. A filter changes the subset, not topic meaning.
- Include an explicit reset button. Preserve selected state in the URL when practical so readers can share a particular view.
- If a monitored slice contains zero qualifying publications, display “Nema objava u odabranom skupu.” If coverage is unavailable, display “Podaci nisu dostupni za odabrani prikaz.” A visibility rate may legitimately be zero with a positive background denominator; a within-HNB topic share is unavailable when there are no HNB items.
- If a selected topic disappears after filtering, clearly select another valid topic or show the empty state; do not leave stale detail.
- Show total included, assigned, and unassigned where it affects percentages. Explain why multilabel issue shares need not sum to 100%.
- Distinguish real policy/institutional events from data-collection changes visually and in the legend. Institutional milestones need markers; they do not inherently require breaking a comparable series. Collection changes require segmentation or qualified comparisons when comparability is unresolved.
- Flag partial months and years; compare like periods. Do not rank a partial year against full years without a clear matching window.
- Do not pool unlike platform engagement/reach fields into a single audience or influence measure. Any available interaction analysis should remain platform-specific and explicit about metric definitions.

### 11.4 Design and accessibility

Transfer the reference’s hierarchy: substantial editorial title, generous reading width, restrained cards, compact figures, visible publication covers, clear methods links. Adapt colors and typefaces to the HNB project’s existing identity. Do not mimic official HNB branding in a way that suggests institutional ownership.

Use accessible controls, keyboard navigation, visible focus, readable chart labels, sufficient contrast, and text/table alternatives. Color cannot be the only signal for stance or missingness. Interactions should enhance a complete static HTML view. Give report PDFs a matching readable HTML edition. Test narrow mobile widths, zoom, print, Croatian diacritics, and long labels.

Word clouds are optional. Ranked phrases, annotated excerpts, or a message/interpretation comparison may explain HNB communication better. If clouds are used, supply frequencies and state what size, color, and position mean; avoid implying spatial relationships that are not encoded.

## 12. Produce a coherent publication family

### 12.1 Resource A: public overview

**Working title:** “Hrvatska narodna banka u medijskom prostoru.”

Audience: interested public, journalists, students, and policy readers. A suggested 12–18 pages is an editorial planning range, not a target to fill.

Recommended sequence:

1. The public question, three main findings, and actual scope.
2. Why the HNB/ECB/bank/government distinctions matter.
3. What the corpus contains and what a counted publication means.
4. Main topics and their substantive interpretation.
5. Attention over time, with verified episodes and coverage boundaries.
6. Sources and voices, kept distinct.
7. Prices, credit, savings, and everyday consequences where supported.
8. Three contrasting episodes that explain the aggregate patterns.
9. Two or three connections to existing research and the paper.
10. A concise limits/methods/citation page with links to deeper documentation.

Deliver `hnb-u-medijskom-prostoru.html`, matching `.pdf`, cover image, and metadata JSON. Generate both reading formats from a shared content source and shared figures.

### 12.2 Resource B: language and communication report

**Working title:** “HNB u javnoj raspravi: poruke, tumačenja i odgovornost.”

This report must add an analytical perspective rather than repeat the overview. Build it only from existing or completed evidence supporting language, stance, framing, attribution, or message-transfer analysis.

Recommended sequence: vocabulary and meaningful expressions → institution versus officeholders → speakers and targets → economic tone versus HNB evaluation → mechanisms and uncertainty → three close readings → what patterns of explanation and scrutiny the evidence supports.

Use distinct-text units for lexical comparisons where appropriate and statement-level units for stance. Explain that change from the overview. Describe purposive cases as illustrations, not a representative distribution. If independent coding is unavailable, provide bounded close readings and withhold quantitative prevalence claims that would require it.

Deliver `hnb-poruke-tumacenja-odgovornost.html`, matching `.pdf`, cover, and metadata. If there is insufficient distinct evidence, integrate the supported material into the overview and record the second report as deferred; do not manufacture a second document for symmetry.

### 12.3 Resource C: findings presentation

**Working title:** “Hrvatska narodna banka u medijima: ključni nalazi.”

Select roughly 8–12 genuinely supported findings, with as many slides as the story requires. Do not force the reference’s exact 12 findings/15 slides. Use one proposition per slide, one explanatory visual where useful, a source/claim reference, and a concise interpretation. Include scope, the paper link, and the key interpretation limits.

Provide self-contained HTML reading mode and keyboard slide mode, plus 16:9 PDF. Support readable mobile layout, text alternatives, and source links. Use the same release and claim register as the page and reports.

### 12.4 Resource D: academic-paper entry

Keep the paper itself intact. Provide its actual title, authors, status, date/version, DOI or canonical repository link, abstract or accurate plain-language summary, citation, and available supplements. Distinguish a working-paper version from a published article.

The page should explain what the paper contributes beyond the public overview. The paper may use a different period or analytical sample; show that difference. Do not rewrite the manuscript or its reported estimates as a side effect of building the public site.

### 12.5 Resource E: downloadable research package

Provide public aggregate CSV/JSON, field dictionary, methodology, source citations, release manifest/checksums, and reuse terms. Include editable report/deck sources if authorized and useful. Separate a lightweight public download from any internal review package.

A re-layout/rebuild of public outputs should work from public aggregates and supplied editorial/build sources without access to restricted article text. Reproducing the underlying analysis may require restricted input; document that distinction honestly. Never describe a bundle as fully reproducible when key inputs or steps are missing.

### 12.6 Shared publication metadata

```text
artifact_id,title,subtitle,authors,language,format,
publication_date,data_start,data_end,release_id,
unit,records_or_texts,pages_or_slides,bytes,
canonical_url,source_commit,sha256,licence,citation
```

The metadata must describe the actual artifact. Generate counts, dates, page totals, file sizes, and hashes; do not hand-maintain competing copies. Use an HTML-only or PDF-only field when appropriate rather than ambiguous metadata.

## 13. Connect the page to the existing paper and other research

### 13.1 Build connections through findings, not just a bibliography

For each selected finding, provide a chain:

```text
Public question
  → concise supported finding
  → interactive/static evidence view
  → exact paper table, figure, model, or analytical result
  → related study that extends, qualifies, compares, or challenges it
```

A related-study card should contain its real title, author(s), publication status, period/population, a two-sentence finding summary, one sentence explaining the connection, and a verified DOI/URL. Include an optional caveat when the comparison is not like-for-like.

### 13.2 Classify the relationship

Use a small controlled vocabulary in `research-links.csv`:

```text
link_id,from_claim_or_topic,to_research_id,relation,
connection_text,compatibility_note,canonical_url,verified_at
```

`relation = supports | extends | contextualizes | compares | qualifies | contradicts | provides_method`.

Examples below are connection patterns, not claims that these studies already exist:

- An inflation-coverage finding → the project's existing paper on inflation narratives → HICP as contextual evidence.
- A lending-policy episode → existing credit/household-finance research → lending rates or survey credit standards.
- An institutional-criticism finding → existing governance/accountability research → verified responsibility definitions, without inventing a macroeconomic proxy for accountability.
- A communication-transfer finding → existing central-bank communication research → official releases and matched media reports.
- A euro-related topic → existing euro-adoption research → separately measured attitudes or price developments.

If the user’s other research concerns a different period, population, or institution, say what is comparable. A shared keyword alone is a weak reason for a link. Do not synthesize estimates into a meta-result unless the designs genuinely permit it.

### 13.3 Placement

Place the main paper near the first findings or prominently in the research section. Topic detail cards should link directly to relevant studies rather than only to a general bibliography. Reports should link back to the page and cite their research foundations. If related research is hosted elsewhere, add outbound links here; editing those external projects is a separate task unless already authorized.

## 14. Data, code, and release architecture

### 14.1 Suggested destination structure

Adapt naming to the existing project; do not create a competing parallel pipeline unnecessarily.

```text
docs/project/hnb-media-hub/
  implementation-plan.md
  research-inventory.csv
  evidence-map.csv
  decisions.md
  gap-analysis.md
  verification-report.md

config/hnb-media/
  entity-registry.csv
  source-registry.csv
  responsibility-registry.csv
  topic-map.csv
  coding-guide.md
  indicator-registry.csv
  external-series-registry.csv
  event-registry.csv
  research-links.csv

analysis/hnb-media/                # adapters/new analysis only where needed
data/public/hnb-media/<release>/
  summary.json
  coverage.csv
  monthly.csv
  topics.csv
  topic_monthly.csv
  policy_issues.csv
  source_groups.csv
  indicators.csv
  external_series.csv             # only selected, redistributable series
  events.csv
  research.json
  claim-register.csv
  data-dictionary.csv
  methods.md
  manifest.json

pages/hnb/index.<project-format>
assets/hnb/                       # scoped styles, scripts, covers, public figures
publications/hnb/overview/
publications/hnb/communication/
publications/hnb/presentation/
tests/hnb-media/                  # meaningful data/filter/release checks
```

Do not use a generated website `docs/` directory for hand-authored project records if the destination uses `docs/` as its build output. In that case put the first group under `quality_reports/` or the repository's existing planning directory. All row-level texts, private evidence spans, account identifiers, and restricted mappings stay in the destination project's established private location, outside public build resources.

### 14.2 Core schemas

**`monthly.csv`** — one row per declared series slice and month:

```text
release_id,scope_id,source_group,platform,month,unit,
date_basis,collection_regime,coverage_status,
captured_count,eligible_background_count,hnb_publication_count,
denominator_id,rate_per_100000,observed_days,
full_text_count,snippet_count,title_only_count
```

Where only an HNB-selected dataset exists, background counts and rate are null; do not fill them with the HNB corpus total. Count fields must have compatible scope, with separate background text-availability and HNB text-availability columns if both are needed. A dictionary defines which universe every field counts.

**`topics.csv`** — reviewed topic ID, label, explanation, leading terms, model/version, primary/multilabel/weight status, and linked public-issue/research IDs. Keep quantitative counts by slice in separate tables.

**`topic_monthly.csv`** — release, scope, source/platform, month, unit, topic, numerator/count or explicitly labelled weight, denominator, assigned/unassigned status. Supply additional cross-tabs only for filters the public UI actually supports. Never infer a joint platform × year × source-group table by multiplying marginal tables.

**`indicators.csv`** — a tidy output table:

```text
release_id,indicator_id,scope_id,period,source_group,platform,
unit,target,category,numerator,denominator,estimate,scale,
lower,upper,interval_method,unassessable_count,
estimate_type,validation_status,availability_status
```

State when estimates are weighted, model-adjusted, or raw. Do not encode mutually incompatible estimands under the same `indicator_id`. Optional columns can be null where inapplicable.

**`events.csv`** — event ID, label, actor, type, event date/time, announcement date, effective date, official URL, topic tags, timestamp precision, and the rule used to include the event. Mark policy events separately from collection changes.

**`manifest.json`** — schema and release versions; source/input release identifiers; actual data coverage; inclusion and deduplication versions; topic/model/code hashes; environment information; validation status; artifact hashes; creation time; prior edition; and change summary. Describe a size/mtime fingerprint as a metadata fingerprint, not a byte-level content hash.

### 14.3 Pipeline boundary

```text
Existing paper + existing analytical outputs + permitted source data
  → audited unit/definition mapping
  → validated adapters and any necessary new analysis
  → checked aggregate release + claim register + manifest
  → page + figures + reports + slides + download package
```

Rendering consumes a pinned release. It does not collect articles, change classification, call a private database, refit topics, or refresh external statistics. External data updates and public release creation are explicit analytical steps. A failed validation stops the release rather than silently mixing old and new artifacts.

Build public outputs in a staging location, verify the complete set, then install them together through the destination project's normal publication process. Keep previous editions and their metadata. An updated page must not silently alter already cited PDF content.

### 14.4 Public disclosure and provenance

Use the destination project's actual data rights. Do not inherit DigiKat’s restrictions or open license automatically. Publish only aggregates, identifiers, extracts, and links allowed by the relevant agreements and law. Preserve source citations and attribution. Independently verify that public bundles, embedded JSON, caches, source maps, and browser requests do not expose restricted text or private paths.

Keep detailed evidence privately when required, but publish enough information to understand the population, method, validation, denominators, and limitations. Small-cell suppression or source-level exclusions, if required, must be applied consistently and explained; do not insert arbitrary thresholds merely because another project used them.

## 15. Execution plan with concrete completion criteria

These are work phases, not estimates of calendar time. New data collection or independent coding may dominate duration. Do not promise a timetable before the audit identifies those dependencies.

| Phase | Work | Deliverable | Complete when |
|---|---|---|---|
| 1. Audit and crosswalk | Read paper/code/data; inventory existing results; map blueprint modules | Four records in §3; initial page outline | Every proposed component has evidence, a bounded gap, or a documented omission |
| 2. Definitions and minimal release | Fix units, layers, scope, dates, rates; adapt existing outputs | Core aggregate release, dictionary, initial claim register | Counts/denominators reconcile; paper differences are explained; unsupported indicators excluded |
| 3. HNB-specific analysis | Only necessary relevance/topic/voice/stance work; sensitivity and validation | Reusable analysis outputs and validation report | Each interpretive measure has evidence adequate for its intended claim; optional failed measures deferred |
| 4. Core page | Hero, overview, findings, topics, trends, sources/issues, paper, methods | Static then interactive local preview | Reads coherently with actual results; filters and alternatives work; no placeholder findings |
| 5. Selected extensions | Official-message cases/metrics, external indicators, related research | Bounded modules with direct sources | Each extension answers a stated question with valid joins and clear limits |
| 6. Publication family | Overview, complementary report if warranted, findings deck | Matching HTML/PDF, covers, metadata | All claims map to the release; formats agree; every page/slide inspected |
| 7. Release verification | Technical, numerical, methodological, editorial, accessibility review | Verification report and public bundle | Acceptance checklist below passes; unresolved limitations are stated |
| 8. Publication and maintenance handoff | Follow destination authorization/deployment process | Published release if authorized; otherwise complete local release candidate | Final report states what is built/published, versions, verification, and deferred work |

### 15.1 Priority order

**Must have:** audited research reuse; honest corpus scope; coherent HNB story; three evidence-based findings when available; topic/time/source views supported by data; main-paper link; one substantive report; methods; public numeric tables; consistent release/provenance.

**Should have:** a complementary report when analytically justified; findings presentation; links from claims/topics to related studies; stable-period/source sensitivity; a small economic-context module when it improves interpretation.

**Could have:** validated stance/explanation views, communication-transfer metrics, headline/body comparisons, more external indicators, advanced event models. Promote a feature only because the evidence and research purpose justify it.

The full requested family remains the target. If a component cannot be supported, record the exact missing input or evidence and deliver the rest. Do not mislabel an incomplete optional analysis as finished, and do not stop a useful core release solely because an advanced extension is unavailable.

### 15.2 Parallel work where it is useful

After the shared audit/definitions, independent work can proceed on: (a) evidence mapping and Croatian narrative; (b) data adapters/validation; (c) official sources and indicator metadata; (d) design/publication rendering. One owner maintains the units, release contract, and claim register so parallel work does not create conflicting numbers.

### 15.3 First concrete actions in the destination project

1. Read repository instructions and identify the canonical paper and data manifests.
2. Save the inventory, evidence map, and gap analysis before creating new metrics.
3. Select the strongest three existing findings and write a one-paragraph public interpretation for each, with exact evidence references.
4. Decide the smallest corpus/indicator release capable of supporting those findings and the core page.
5. Produce a content wireframe using real labels and evidence placeholders explicitly marked as unavailable, then populate it from the verified release.
6. Reuse/add analyses only for remaining justified gaps.

Do not spend the first phase building a new dashboard shell while leaving the paper-to-finding mapping unresolved.

## 16. Verification and acceptance checklist

### 16.1 Research and numerical checks

- [ ] Every HNB result has a traceable analytical source; proposed questions are not presented as findings.
- [ ] The paper’s population, version, and estimates remain intact and correctly linked.
- [ ] Corpus layers and any unions have explicit inclusion and deduplication rules.
- [ ] Publication, exact-text, near-duplicate, story, context, statement, official-document, and respondent units are not conflated.
- [ ] When a compatible background exists: `0 ≤ HNB count ≤ eligible background ≤ captured background` for the same slice. Topic-only datasets are checked under their own valid bounds.
- [ ] Monthly and source/platform totals reconcile where units are additive. Distinct groups spanning slices are recomputed as sets rather than summed.
- [ ] For primary topics, topic counts plus unassigned equal included items in every supported filter slice. Multilabel/soft outputs use their own documented invariants.
- [ ] Multilabel policy tags and overlapping retrieval routes are not added as if they were exclusive categories.
- [ ] Rates, charts, downloads, and prose use the same scale and denominator; zero, unavailable, suppressed, and partial values are distinct.
- [ ] Every numerical claim has the correct period, filter, unit, denominator, rounding, and uncertainty description.
- [ ] HNB stance, economic tone, policy stance, source identity, speaker identity, and survey attitudes are distinguishable.
- [ ] Interpretive code reliability/accuracy is documented for the actual target population and claims; AI review and model stability are not described as independent human validation.
- [ ] Collection discontinuities and institutional milestones are handled separately and consistently in code, charts, and methods.
- [ ] Macroeconomic joins preserve release timing/vintage where needed; no revised future information is used as if historically available.
- [ ] Event comparisons state their design and limitations; descriptive co-movement is not labelled causal.

### 16.2 Publication and software checks

- [ ] Page, reports, slides, tables, and downloadable package have consistent release identifiers and real metadata/hashes.
- [ ] Each supported filter intersection has correct counts, shares, empty states, reset behavior, and text alternatives; marginal tables are not mistaken for joint data.
- [ ] The site remains readable without JavaScript; keyboard and mobile use work.
- [ ] All links, anchors, downloads, citations, images, and publication covers resolve.
- [ ] Public JSON/CSV cannot expose restricted texts, private IDs, account data, or local private paths.
- [ ] Croatian diacritics, decimal/thousands separators, date forms, and long labels render correctly.
- [ ] Every PDF page and slide is inspected for clipping, overflow, tiny labels, illegible legends, broken links, and mismatch with HTML.
- [ ] All charts have titles, units, source notes, interpretive text, and numerical alternatives.
- [ ] Shared report sources keep HTML and PDF claims identical; deliberately different editorial scope is documented.
- [ ] Selected data-release/aggregation tests and frontend checks pass. A successful build alone is not called research validation.
- [ ] Final verification distinguishes automated checks, manual inspection, scientific validation, unresolved limitations, and work deferred.

The handoff report should state: files created/updated; canonical output locations; which findings were reused or newly computed; data/release versions; checks run and their outcomes; unavailable modules; known interpretation limits; and whether anything was actually deployed.

## 17. Maintenance and edition policy

Choose explicitly between a **fixed research edition** and a **periodically updated observatory**. The user's existing paper makes a fixed first edition a sensible default unless the destination already maintains an update process.

For a fixed edition, preserve source data and estimates; corrections generate a documented new version. For an updating resource, separate routine data ingestion from released analytical editions. A new month of data does not automatically warrant revised topic names, rewritten findings, new PDF claims, or a changed paper.

At each new edition:

1. Audit collection coverage, source changes, and new missingness.
2. Apply the documented frozen method or record/validate a method change.
3. Update compatible external series with source/vintage metadata.
4. Recompute aggregates and compare them with the prior edition.
5. Review changed headline claims and existing-case relevance.
6. Rebuild the whole publication family from the agreed release.
7. Publish a concise change log and retain the prior release.

Set cadence from actual data availability, effort, and research purpose. There is no need to make an ongoing observatory merely because the reference has a time-series chart.

## 18. Reference implementation map

Reference site: [Demokršćanstvo u medijima](https://lusiki.github.io/DigiKat/pages/demokrscanstvo/index.html).

Local audit baseline: DigiKat working tree on 21 September 2026; Git HEAD `b50eb609a6c6d3cce3d35ae0674c6fd022ca02f5`. Some supporting analysis/plan directories were untracked or modified, so this is a working-tree audit, not a claim that every inspected file exists at that commit. The hosted page could not be retrieved by the web text tool during this audit; page descriptions above are based on the actual local source, assets, and metadata.

| Path in DigiKat | Use in transfer |
|---|---|
| `pages/demokrscanstvo/index.qmd` | Active narrative, section order, data bindings, report checks, embedded frontend data |
| `assets/css/barometar.css` | Scoped responsive editorial layout and accessibility patterns; includes legacy selectors that need pruning |
| `assets/js/barometar-themes.js` | Fixed-model topic filtering and detail view with static fallback |
| `assets/js/barometar-multiplatform.js` | Rate calculation, missingness, platform selection, responsive SVG |
| `R/lib/barometar_multiplatform_page.R` | Release/schema/hash checks and topic-to-month reconciliation |
| `data/barometar/demokrscanstvo-multiplatform/v1/` | Example monthly/source/availability/definition release contract |
| `data/barometar/demokrscanstvo-themes/v1/` | Example linked thematic release with model descriptions and monthly topic counts |
| `studies/demokrscanstvo-barometar/MULTIPLATFORM.md` | Active corpus/unit/denominator/retrieval method; compare rendering seam described above |
| `studies/demokrscanstvo-barometar/THEMATIC.md` | Topic preprocessing, fitting, assignment, interpretation, reproducibility |
| `studies/demokrscanstvo-barometar/text-public/technical-methods.md` | Distinct-text unit, vocabulary, close-reading boundaries, unfinished human coding |
| `studies/demokrscanstvo-barometar/public-report/` | Shared public overview content and HTML/PDF generation |
| `studies/demokrscanstvo-barometar/text-public/` | Complementary report manuscript, public numerical inputs, builders, checks |
| `studies/demokrscanstvo-barometar/presentation/` | Editable slide narrative, reading/slide modes, PDF rendering, package creation |
| `assets/izvjestaji/demokrscanstvo-*.meta.json` | Actual current publication metadata and hashes |
| `studies/demokrscanstvo-barometar/report/` and `text-addendum/` | Deeper analytical/supporting resources; not all public or completed validation |
| `tests/barometar_themes.test.cjs` and `tests/barometar_multiplatform.test.cjs` | Examples of meaningful aggregation/filter/empty-state tests |
| `quality_reports/plans/2026-09-21_demokrscanstvo-rename-and-clarity.md` | Documents current display decisions and seams with older methods documentation |

Repository access: [DigiKat on GitHub](https://github.com/lusiki/DigiKat). If the implementing environment lacks the local reference repository, use the public site and available repository files plus this map. Do not assume local private/untracked analyses are downloadable; do not make their availability a prerequisite for the HNB project.

## 19. Verified primary-source directory for HNB adaptation

Sources were checked on 21 September 2026. These are official discovery and methodology links, not a completed downloaded HNB indicator dataset. At implementation, record exact series IDs, units, coverage, access dates, and any changed methodology. The descriptions below support the analytical choices above; they are not empirical findings about HNB media coverage.

### S1–S3: institutional remit and monetary-policy regime

- **S1 — [HNB: Role](https://www.hnb.hr/en/about-us/functions-and-structure/role).** Starting point for a dated responsibility taxonomy, including monetary-policy participation/implementation and other central-bank functions. Check historical remits separately.
- **S2 — [ECB: Croatia introduces the euro, 1 January 2023](https://www.ecb.europa.eu/press/pr/date/2023/html/ecb.pr230101~2046d0fd6f.en.html).** Documents euro adoption, Eurosystem membership, and supervisory integration; also notes close cooperation from October 2020. Do not reuse historical institution/bank counts as current facts.
- **S3 — [ECB: Key interest rates](https://www.ecb.europa.eu/stats/policy_and_exchange_rates/key_ecb_interest_rates/html/index.en.html).** Policy-rate history with effective dates. Pair it with dated Governing Council announcements when studying communication.

### S4–S5: official communication and a candidate policy episode

- **S4 — Official communication entry points:** [HNB press releases](https://www.hnb.hr/javnost-rada/priopcenja/hnb), [speeches](https://www.hnb.hr/javnost-rada/izlaganja/govori), [interviews](https://www.hnb.hr/javnost-rada/izlaganja/intervjui), [information and responses](https://www.hnb.hr/javnost-rada/informacije-i-ocitovanja), [HNBlog](https://www.hnb.hr/javnost-rada/hnblog), [macroeconomic developments and outlook](https://www.hnb.hr/analize-i-publikacije/redovne-publikacije/makroekonomska-kretanja-i-prognoze), [financial stability](https://www.hnb.hr/analize-i-publikacije/redovne-publikacije/financijska-stabilnost), [macroprudential diagnostics](https://www.hnb.hr/analize-i-publikacije/redovne-publikacije/makroprudencijalna-dijagnostika), and [statistical release calendar](https://www.hnb.hr/statistika/kalendar-objava). Preserve actual document dates, genre, author, reference period, and revisions.
- **S5 — [HNB: announcement of the decision on consumer-lending criteria, 19 March 2025](https://www.hnb.hr/-/priopcenje-o-donosenju-odluke-o-kriterijima-kreditiranja-potrosaca).** A source for separating advance announcement/consultation, decision, and 1 July 2025 implementation in an event timeline.

### S6–S12: economic-context data

- **S6 — Inflation:** [Eurostat HICP database](https://ec.europa.eu/eurostat/web/hicp/database), [HICP metadata](https://webgate.ec.europa.eu/eurostat/cache/metadata/en/prc_hicp_esms.htm), and [DZS January 2026 CPI/HICP publication](https://podaci.dzs.hr/2026/en/121356). Support correct indicator choice, monthly frequency, CPI/HICP distinction, and the 2026 classification/reference update.
- **S7 — [HNB: credit-institution interest rates](https://www.hnb.hr/statistika/statisticki-podaci/financijski-sektor/druge-monetarne-financijske-institucije/kreditne-institucije/kamatne-stope).** Monthly lending/deposit rates and definitions; select sector, product, new/existing business, maturity/fixation, and rate concept explicitly.
- **S8 — [HNB: aggregate balance sheet of other monetary financial institutions](https://www.hnb.hr/statistika/statisticki-podaci/financijski-sektor/druge-monetarne-financijske-institucije/agregirana-bilanca-drugih-monetarnih-financijskih-institucija).** Lending/deposit series and methodology. Verify growth adjustments and reporting perimeter for the chosen series.
- **S9 — [HNB: euro-area bank-lending survey results](https://www.hnb.hr/statistika/statisticki-podaci/financijski-sektor/druge-monetarne-financijske-institucije/kreditne-institucije/rezultati-ankete-o-kreditnoj-aktivnosti-banaka-za-europodrucje).** Quarterly bank-reported credit conditions/demand; check continuity with the pre-2023 survey archive.
- **S10 — [HNB: credit-institution business indicators](https://www.hnb.hr/statistika/statisticki-podaci/financijski-sektor/druge-monetarne-financijske-institucije/kreditne-institucije/bankovna-supervizija/pokazatelji-poslovanja-kreditnih-institucija).** Supervisory measures of asset quality, capital, liquidity, profitability, and structure; inspect individual table dates and definitions.
- **S11 — Housing:** [Eurostat house-price metadata](https://ec.europa.eu/eurostat/cache/metadata/en/prc_hpi_inx_esms.htm) and [quarterly house-price table](https://ec.europa.eu/eurostat/databrowser/product/page/prc_hpi_q). Supports house-price context, not rent or affordability by itself.
- **S12 — Consumer surveys:** [DG ECFIN survey-data downloads](https://economy-finance.ec.europa.eu/economic-forecast-and-surveys/business-and-consumer-surveys/download-business-and-consumer-survey-data_en), [survey programme](https://economy-finance.ec.europa.eu/economic-forecast-and-surveys/business-and-consumer-surveys_en), and [HNB consumer confidence indices](https://www.hnb.hr/statistika/statisticki-podaci/odabrane-nefinancijske-statistike/indeksi-pouzdanja). Verify Croatian question-level availability and definitions before using price expectations or confidence balances.

### S13–S15: survey constructs and data access

- **S13 — [ECB: trust in the ECB, methodological discussion](https://www.ecb.europa.eu/press/economic-bulletin/articles/2024/html/ecb.ebart202403_01~05b13dbf02.en.html), [Commission public-opinion surveys on the euro](https://economy-finance.ec.europa.eu/euro/public-opinion-euro_en), and [Croatia and the euro](https://economy-finance.ec.europa.eu/euro/eu-countries-and-euro/croatia-and-euro_en).** Guides separation of institution-specific trust, euro attitudes, and changeover perceptions. Verify exact Croatian wave/questions before analysis.
- **S14 — [ECB Consumer Expectations Survey](https://www.ecb.europa.eu/stats/ecb_surveys/consumer_exp_survey/html/index.en.html).** Country coverage must be checked; Croatia was absent from the listed participating countries at preparation. Do not substitute covered-country results for Croatian attitudes.
- **S15 — Official access documentation:** [ECB data API](https://data.ecb.europa.eu/help/api/data) and [Eurostat API introduction](https://ec.europa.eu/eurostat/web/user-guides/data-browser/api-data-access/api-introduction). Use provider metadata and source snapshots; historical-vintage availability differs between providers and series.
