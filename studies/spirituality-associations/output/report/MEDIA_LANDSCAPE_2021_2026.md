FIRST EXPLORATORY ANALYTICAL REPORT

Spirituality-related associations
in the media space

Croatia’s September 2026 association register linked to the full DetermDB merged dataset, 1 January 2021 to 10 September 2026.

The full-period search covers **42,267,474 monitored records** and retains all **1,325 organisations** in the administrative frame. It retrieves **23,436 candidate publication-days**, linked through names to **450 register entries**. These are measured search results, with identity and substantive relevance still unresolved at corpus level.

| Measure | Full-period result |
| --- | --- |
| Organisations with usable name rules | 1,043 / 1,325 |
| Names with at least one candidate | 450 |
| Organisation-publication-day candidate pairs | 24,286 |
| Years and months covered | 2021-2026; 69 months; 2026 is partial |

The first landscape

The retrieval signal is uneven: the ten most frequently matched names account for **31.7%** of candidate pairs. Web pages supply **71.3%** of candidate publication-days. Both patterns describe the monitored search output, not a verified hierarchy of organisational influence.

The inspected examples show several routes into public visibility: practical assistance and volunteering, spiritual programmes, social inclusion, education and publishing. They also show why a single “religious media presence” label would be too narrow for this administrative population.

A stronger national conclusion awaits historical identity checks and independent article coding. This report provides the descriptive landscape, computational exploration, contrastive case readings and reproducible evidence needed to make those next checks precise. It does not estimate public opinion, media hostility or causal influence.

Prepared 19 September 2026. Internal research edition; aggregate findings and AI-assisted interpretations are distinguished throughout.


## 1. What is in the full dataset?

The database contains records on every calendar day from 2021-01-01 to 2026-09-10: 2,079 observed dates. No year is excluded. The final year ends on 10 September and contributes 253 days. Counts below are source records before this study’s candidate reconciliation.

| Year | Monitored records | Days | Candidate publication-days | Matched names |
| --- | --- | --- | --- | --- |
| 2021 | 5,196,491 | 365 | 3,605 | 224 |
| 2022 | 5,931,094 | 365 | 3,843 | 240 |
| 2023 | 5,518,968 | 365 | 4,286 | 264 |
| 2024 | 9,590,440 | 366 | 4,538 | 251 |
| 2025 | 8,514,361 | 365 | 3,807 | 248 |
| 2026* | 7,516,120 | 253 | 3,357 | 250 |

Annual counts. Each candidate publication-day is a platform + canonical URL + database date, with an ID/text fallback for missing URLs. One item can generate several organisation-item pairs. “Matched names” is not a count of independently validated organisations. *Partial year. Source: annual_landscape.csv.

The collection break is now January 2024

The older plan located the feed change in April 2024. The current database has since replaced January-March 2024 with newer imports. Measured provenance is therefore **2021-2023: luka_opce, unfiltered; 2024-2026: mediaspace_full, filtered**. The latter retains records containing the standalone word “i”. The query scope, platform mix and retention process all change. A before/after count difference cannot be read as a social trend.

A present-day register viewed retrospectively

The 1,325-entry frame is the supplied active-status administrative list dated 11 September 2026. It includes cultural, welfare, educational and personal-development associations as well as explicitly spiritual bodies. It is not the historical population of all associations operating in each earlier year. Organisations absent from the 2026 frame cannot be recovered by searching this list, and year-specific existence/name eligibility has not been reconstructed.

All supplied monitored countries and languages are retained. Publisher country, language and activity location have not been adjudicated; a domain suffix does not establish them. This is a Croatian-register-linked view of the supplied media feed, not a census of Croatian journalism or a country-filtered editorial corpus.

The source database was opened read-only. Its file size and modification fingerprint were checked before and after retrieval. The source text, original fields and match evidence remain in the local private workspace; they are not reproduced in the aggregate supplement.


## 2. The search funnel and the meaning of a zero

Figure 1. Register coverage and unresolved search states. Source: funnel.csv and summary.json.

![Figure 1. Register coverage and unresolved search states. Source: funnel.csv and summary.json.](C:/Users/lsikic/projects/DigiKat/studies/spirituality-associations/output/figures/media-v1/search_funnel.png)

Usable rules were available for 1,043 names (78.7% of the frame). Across all years, 450 have a candidate and 593 have none under these rules. Another 282 short, generic or otherwise unresolved names remain held for identity work. These three states are retained separately in the all-organisation directory.

The full-period search adds 202 names with candidates beyond the 2025-only set. A single year therefore gives a materially narrower view of which names can be found, even before validation. This is a gain in temporal search coverage, not proof of changes in organisational activity.

The screen reuses the documented legal-name rules and a small official-source alias set. It applies them independently to TITLE, FULL_TEXT and MENTION_SNIPPET, with accent-folding and word boundaries. It does not impose a Catholic or spirituality keyword filter. Names are never assembled across fields. Nevertheless, a complete legal phrase can still be ordinary language, an unrelated entity, navigation or an old story embedded in a new page.

| Evidence state | What can be concluded |
| --- | --- |
| Candidate found | A stored field matches a rule. The entity and substantive reference still need review. |
| Searched, no candidate | No match under the current finite rules in the supplied monitored feed. Short names, inflections and missed sources may matter. |
| Held for identity work | The search is incomplete for this register entry; no media-absence conclusion is available. |
| Validated substantive editorial link | Not yet estimated nationally; requires identity, relevance, prominence and source/production checks. |

Snippet-only matching contributes 58 pairs; 1,977 pairs rely only on curated aliases. The aliases improve discovery for selected cases but also make search effort unequal across organisations. No recall estimate or prevalence of “invisible organisations” is reported.


## 3. Registered geography and retrieved names

Figure 2. County of registered seat, with searched and held names kept visible. This is not a map of activities or audiences. Source: county_landscape.csv.

![Figure 2. County of registered seat, with searched and held names kept visible. This is not a map of activities or audiences. Source: county_landscape.csv.](C:/Users/lsikic/projects/DigiKat/studies/spirituality-associations/output/figures/media-v1/county_search_landscape.png)

Grad Zagreb contains 422 entries (31.8% of the register), of which 136 have at least one candidate. The county totals describe where associations are registered. A Zagreb seat can support activity elsewhere, while an organisation registered in another county may reach national media.

The geographical comparison should therefore be read in two layers: the distribution of registered organisations and the coverage of the search rules. County differences in matched-name rates can reflect name distinctiveness, organisational composition, aliases and monitored publishers. They are not population-adjusted measures of local spirituality or organisational effectiveness. The complete county table appears in the appendix.


## 4. Concentration and persistence of the search signal

Figure 3. Candidate-pair concentration among all searched names, including searched zeros. The curves describe retrieval inequality; they are not validated attention curves. Source: pairs and sensitivity.csv.

![Figure 3. Candidate-pair concentration among all searched names, including searched zeros. The curves describe retrieval inequality; they are not validated attention curves. Source: pairs and sensitivity.csv.](C:/Users/lsikic/projects/DigiKat/studies/spirituality-associations/output/figures/media-v1/candidate_concentration.png)

| Specification | Pairs | Names | Top-ten share |
| --- | --- | --- | --- |
| All candidate pairs | 24,286 | 450 | 31.7% |
| Restricted screen | 21,327 | 446 | 30.4% |
| Title or first 800 characters | 13,768 | 374 | 35.9% |
| One pair per exact-text group | 24,118 | 450 | 31.7% |

Among names with candidates, the median is 5 observed months out of 69 database months. This is a raw recurrence measure: historically eligible months are not known. A recurring name can represent sustained activity, repeatedly crawled evergreen pages, publicity, navigation or recurring mistaken matches.

The restricted screen removes snippet-only/tail-only references, four names with documented ambiguity and matches supported only by the short SKAC ST alias. It deliberately sacrifices possible genuine coverage to test sensitivity. The title/lead screen requires a name in the title or the first 800 normalized body characters. Neither screen is a validated set. No named league table is inferred from these counts.


## 5. Time: volume, collection regime and partial 2026

Figure 4. Monthly source records and raw candidate records. Dashed line: January 2024 regime change. Shaded final month: ten days only. Source: monthly_landscape.csv.

![Figure 4. Monthly source records and raw candidate records. Dashed line: January 2024 regime change. Shaded final month: ten days only. Source: monthly_landscape.csv.](C:/Users/lsikic/projects/DigiKat/studies/spirituality-associations/output/figures/media-v1/coverage_and_candidates.png)

The two panels separate the amount of available material from the number of name hits. The same-calendar-window comparison below retains 1 January-10 September in every year. It avoids comparing a partial 2026 total with a full earlier year, while leaving the feed change and historical-identity problem unresolved.

| Jan 1-Sep 10 | Monitored records | Candidate publication-days | Raw hits / 10,000 records |
| --- | --- | --- | --- |
| 2021 | 3,575,021 | 2,292 | 7.05 |
| 2022 | 4,325,589 | 2,398 | 5.68 |
| 2023 | 3,736,283 | 2,777 | 7.55 |
| 2024 | 7,178,853 | 3,131 | 4.37 |
| 2025 | 5,927,958 | 2,406 | 4.07 |
| 2026 | 7,516,120 | 3,357 | 4.48 |

The last column divides raw candidate records by raw monitored records; it is a search-yield diagnostic. Deduplicated publication-day counts are never divided by raw vendor counts. No growth or decline in actual organisational visibility is inferred from this table. Source: same_calendar_window.csv.


## 6. A common observed source panel

Figure 5. Raw search yield within web records, with a common-domain sensitivity panel. Source: common_domain_panel.csv; membership in common_domain_members.csv.

![Figure 5. Raw search yield within web records, with a common-domain sensitivity panel. Source: common_domain_panel.csv; membership in common_domain_members.csv.](C:/Users/lsikic/projects/DigiKat/studies/spirituality-associations/output/figures/media-v1/common_panel_yield.png)

The panel contains 60 web domains with at least 100 monitored records in every one of the 69 months. This holds the observed domain set constant. It helps distinguish changes in the source mix from changes within repeatedly observed sources.

The panel does not hold all collection conditions constant. It cannot recover records removed by the “i” filter, guarantee equal crawling within a domain, settle historical organisation names or classify editorial independence. Domain continuity is also not publisher-group continuity. Treat the comparison as a robustness description, not a corrected time series.

Database dates are not automatically event dates

The case reading found a Breza partnership page stored under 21 January 2021 that advertises training dates in November 2019. A Matica branch page dated in the database to May 2021 contains older branch/event material. These observed examples make it unsafe to label every peak as a contemporaneous activity peak. Event-specific interpretation needs publication, update and activity dates checked separately [C6-C7].


## 7. Channels: web dominates, but web is not an origin code

Figure 6. Candidate publication-days by vendor platform. The source platform field describes delivery format, not independence or production. Source: platform_landscape.csv.

![Figure 6. Candidate publication-days by vendor platform. The source platform field describes delivery format, not independence or production. Source: platform_landscape.csv.](C:/Users/lsikic/projects/DigiKat/studies/spirituality-associations/output/figures/media-v1/platforms.png)

The web channel contributes 16,707 candidate publication-days, or 71.3% of the retrieved total. The remainder spans social posts, video descriptions, discussion and other available formats. A social post linking to a story and the story itself remain separate channel observations.

Across candidates, 23,339 items have a non-empty FULL_TEXT field. This establishes text availability, not transcript completeness or successful article extraction. Bodies can contain teasers, product descriptions, navigation and related content. A YouTube description listing a guest does not establish what that person said in the programme [C4].

Only 215 pairs match the small current official-domain map for six documented organisations. That is a mapping diagnostic, not an estimate of the amount of owned communication. All other relationships remain unresolved; missing owned-domain evidence is never converted into external editorial coverage.

The dataset does not yet support a national split into original reporting, republished organisational statements, institutional communication and public discussion. The report therefore does not use reach, engagement or vendor sentiment as measures of influence, public trust or target-specific evaluation.


## 8. Where candidate web material is found

Figure 7. Twelve domains with the largest retrieved web volumes. These are source-discovery priorities, not a ranking of editorial support. Source: web_domain_landscape.csv.

![Figure 7. Twelve domains with the largest retrieved web volumes. These are source-discovery priorities, not a ranking of editorial support. Source: web_domain_landscape.csv.](C:/Users/lsikic/projects/DigiKat/studies/spirituality-associations/output/figures/media-v1/web_domains.png)

The three largest domains together contribute 9.7% of candidate web publication-days. Source concentration matters because a shared template or recurring page can create many name hits; the largest domain totals should receive early cleaning and provenance review.

Inspection shows that the web category contains several kinds of material. The Kršćanski akademski krug example is a journal product listing, not a news story. The SKAC Split example explicitly attributes text and photos to the organisation, despite appearing on another domain. The Hvar branch example is embedded in a wider branch listing. Counting all three as independent journalism would erase material differences in how organisations enter the media space [C2, C5, C7].

A useful next source map should record three axes separately: medium, publisher relationship to the association and production type. Where an affiliated outlet also reports original material, both attributes should be preserved. Current domain names alone do not establish historical ownership or editorial independence.


## 9. The initial topic model exposes recurring templates

The text exploration uses 20,598 candidate publication-days with usable restricted-screen context. Association names are masked and common function words removed. TF-IDF/NMF models were fitted with 6, 8, 10 and 12 topics and two random starts each. The eight-topic model is used as a readable exploratory map; the labels below are interpretive shorthand after reviewing representative passages, not human-coded organisational roles.

| Topic | Provisional reading | Highest-weight surface terms |
| --- | --- | --- |
| 1 | Laudato support / fundraising template | laudato, broj, klubprijatelja, klubprijatelja laudato, webshop laudato, webshop, gracanska cesta |
| 2 | Service schedules and contact template | adresa, multi, kristjeinternacionalan, donacije, nedjeljom, swift addiko, kristjeinternacionalan gmail |
| 3 | Donation and bank-detail template | bank name, swift bank, bank, name, adresa, nedjeljom, nedjeljom adresa |
| 4 | Religious / civic event notices (broad) | hrvatskih, zagrebu, program, odrzati, susret, branitelja, organizira |
| 5 | Education and project partnerships | projekta, projekt, skola, partneri, stem, nositelj, osnovna skola |
| 6 | Social support and family programmes (mixed) | sto, ove, program, djecu, obitelji, aktivnosti, djece |
| 7 | Repeated Christian channel description | proucavati bibliju, sastanke seminare, dosli sastanke, navijestati radosnu, moliti proucavati, krscane zele, bibliju navijestati |
| 8 | SKAC video tags / youth-Mass vocabulary | skac, slavonski brod, misa, brod, slavonski, misa mladih, studentski |

Inspection shows that topics 1, 2, 3, 7 and 8 largely capture recurring support instructions, channel self-description or video tags. Topics 4-6 offer broad activity contexts, but their weakly assigned examples can be unrelated. The eight groups should therefore not be presented as eight substantive public roles.

| Topics | Across-start similarity | Iterations |
| --- | --- | --- |
| 6 | 1.000 | 70 |
| 8 | 0.754 | 139 |
| 10 | 0.800 | 117 |
| 12 | 0.752 | 68 |

Model stability. Similarity is the mean cosine similarity after optimal alignment of topic-term vectors across two starts, within each model size. It describes computational reproducibility, not substantive validity. More topics can split a recurring vocabulary without discovering a new social role. Source: topic_terms.csv and topic_model_runs.csv.

This first run uses accent-folded Croatian surface forms, not lemmatisation. Inflected forms can split across features. Contexts extend roughly 450 normalized characters to either side of a matched name and may cross sentence boundaries within a field. Consequently, the results are neither sentence-level concept associations nor a finished Croatian linguistic analysis.


## 10. How robust is the thematic map?

Figure 8. Strongest-topic assignments within each modelled channel subset. Percentages concern algorithmic groupings of provisional candidates, not the prevalence of frames or public roles. Source: topic_platform.csv.

![Figure 8. Strongest-topic assignments within each modelled channel subset. Percentages concern algorithmic groupings of provisional candidates, not the prevalence of frames or public roles. Source: topic_platform.csv.](C:/Users/lsikic/projects/DigiKat/studies/spirituality-associations/output/figures/media-v1/topic_channels.png)

| Topic | All modelled items | Web subset | One per exact text |
| --- | --- | --- | --- |
| 1 | 2.2% | 1.2% | 2.2% |
| 2 | 2.9% | 0.0% | 2.9% |
| 3 | 1.2% | 0.1% | 1.2% |
| 4 | 32.8% | 35.9% | 32.8% |
| 5 | 11.5% | 12.6% | 11.5% |
| 6 | 46.2% | 48.0% | 46.1% |
| 7 | 0.8% | 0.1% | 0.8% |
| 8 | 2.6% | 2.0% | 2.6% |

Whole-text and association-context models have an aligned mean topic-vector similarity of 0.592. This directly tests whether the surrounding article produces the same structure as the association-focused window. 1,108 items have a strongest-topic weight share below 0.4; 1 have no model weight. Mixed and weak assignments should not be forced into single substantive frames.

Exact-text grouping only removes identical normalized bodies of at least 200 characters. Near-copies with changed headings, footers or small edits can remain separate. The web subset is not an editorial-only subset because source production has not been coded. These limits are visible rather than treated as completed controls.


## 11. After suppressing repeated passages

A second exploratory pass suppresses every eight-token sequence found in at least 20 different candidate items. It removes 11.4% of the input tokens and retains 18,938 items with at least 15 remaining non-stopword tokens; 1,660 fall below that threshold. Candidate counts elsewhere in this report do not change.

| Group | Reading after inspected examples | Remaining vocabulary | Items |
| --- | --- | --- | --- |
| 1 | Funded projects and social-service partnerships | projekta, projekt, provodi, aktivnosti, sklopu | 3,090 |
| 2 | Religious gatherings and event notices | susret, zagrebu, prof, ika, crkvi | 4,933 |
| 3 | Conversational / help-related language (mixed) | sto, ljudi, skac, mogu, kojima | 5,442 |
| 4 | War remembrance and veterans' associations | branitelja, rata, domovinskog, hrvatskih, domovinskog rata | 1,020 |
| 5 | Minority-cultural organisations and Istrian funding | istarske, istarske zupanije, zupanije, kulturno, zajednica | 342 |
| 6 | Festivals, workshops and local community activity | ove, grada, program, festival, organizira | 4,111 |

The more interpretable contexts include funded social-service projects, religious gatherings, commemorative and veterans’ activity, minority-cultural funding, festivals and workshops. These extend well beyond an exclusively religious news agenda. The broad conversational group remains heterogeneous and should not receive a single public-role label. Individual group assignments are exploratory, not adjudicated organisation-article representations.

Representative readings reinforce the administrative frame’s breadth: project texts describe partnerships and social-service provision; an Istrian cluster contains minority-cultural grant announcements and lists of organisations; local-programme material includes children’s festivals and environmental volunteering. These are patterns in selected retrieved passages, not population percentages of organisational functions.

The six-topic repeat-suppressed model has across-start similarity 0.913, compared with 0.803 for eight topics. The six-topic display was chosen after the initial diagnostic, not preregistered. A recurring substantive announcement can be removed by this method too; this sensitivity set is not a validated clean corpus. Source: repeat_check_summary.json, repeat_check_terms.csv, repeat_check_models.csv.


## 12. Eight organisational starting portraits

Figure 9. Purposively selected organisations with current documentary identity evidence. Numbers remain unresolved search counts. The cases are not representative and are not ordered as a visibility league table. Source: private organisation_year.csv.

![Figure 9. Purposively selected organisations with current documentary identity evidence. Numbers remain unresolved search counts. The cases are not representative and are not ordered as a visibility league table. Source: private organisation_year.csv.](C:/Users/lsikic/projects/DigiKat/studies/spirituality-associations/output/figures/media-v1/selected_profiles.png)

Breza: community services and partnership

Breza has 707 candidates across 67 months. Its [official description](https://breza.hr/o-nama/) foregrounds children and young people, social support, education, culture and volunteering. The inspected partnership item concerns training and tourism, with an older event date. This illustrates a practical public role and the need to separate organisation identity from administrative “spirituality” classification [C6].

SKAC Palma and Split: formation and action

SKAC Palma has 868 candidates and SKAC Split 613. Their documented self-descriptions combine Christian formation with youth development and volunteering. The inspected Palma invitation foregrounds spiritual preparation and a participant testimonial; the Split item foregrounds earthquake assistance and explicitly republishes the organisation’s own account. These are different routes into visibility, even within a closely related organisational setting [C2-C3; S2-S3].


## 13. What contrasting cases add

Korablja: belonging, disability and a named professional role

Korablja has 74 candidates in 24 months. Its [identity page](https://korablja-arka.hr/tko-smo/) explicitly connects the legal association with the Arka community and describes shared life with and without intellectual disabilities. The inspected programme description identifies an association-linked professional discussing disability. It makes the association discoverable through an issue and a person’s role, while providing insufficient text to count spoken voices or evaluate the full interview [C4].

Kršćanski akademski krug: publishing can look like coverage

The Krug has 44 candidates. Its [official account](https://www.krakr.hr/index.php/o-nama/sto-je-krscanski-akademski-krug.html) describes Christian intellectual and social reflection. The inspected web-shop record names the association through its journal, Nova prisutnost. This is meaningful public discoverability of a cultural/intellectual product, but it is not evidence of an independent article about the association [C5].

Yoga in Rijeka: spiritual-practice organisations also appear as helpers

The Rijeka association has 68 candidates. In the inspected January 2021 body, the association is explicitly linked to hostel accommodation for people affected by the Petrinja earthquake. The immediate public role is assistance and partnership. This example supports looking for associations without a religious keyword prefilter; it does not establish that spirituality was hidden or excluded [C1].

Padmasana and the Hvar branch: two different limits

Padmasana has 0 retrieved candidates under the current rules. Its [official page](https://padmasana.hr/en/o-nama/) describes Buddhist study, meditation and retreats near Zaprešić. Sparse retrieval cannot refute documented activity or measure its public reach. The Hvar branch of Matica hrvatska has 23 candidates, but an inspected early-body match occurs in a branch list on another branch’s page. This is a direct warning against treating literal-name prominence as sufficient entity/relevance validation [C7].

All counts in these portraits refer to unresolved candidates. The observations are purposive AI-assisted readings, not independently adjudicated case dossiers. Full source keys, passages and decisions remain private. None of the cases supplies an estimate of the population distribution of orientation, voice or framing.


## 14. From temporal patterns to event questions

Figure 10. Monthly retrieval for three documentary cases. The vertical line marks the collection change. Peaks select material to inspect; they do not independently identify an event. Source: private organisation_month.csv.

![Figure 10. Monthly retrieval for three documentary cases. The vertical line marks the collection change. Peaks select material to inspect; they do not independently identify an event. Source: private organisation_month.csv.](C:/Users/lsikic/projects/DigiKat/studies/spirituality-associations/output/figures/media-v1/case_timelines.png)

| Case observation | Date in database | What the text contributes |
| --- | --- | --- |
| C2: SKAC Split | 9 Jan 2021 | Attributed organisational account of assistance in Petrinja and Glina. |
| C3: SKAC Palma | 15 Jan 2021 | Spiritual programme invitation with a testimonial attributed to the own site. |
| C1: Rijeka yoga association | 19 Jan 2021 | Explicit association-hostel partnership providing earthquake-related accommodation. |

The January examples show that assistance and spiritual programmes can coexist in the same media period. They do not show a collaboration among the three associations. The Split and Rijeka observations concern earthquake assistance, but common subject matter alone does not establish shared organisation, causal influence or text-copying direction.

A full event dossier would now trace all relevant publications and versions, establish dates and origin evidence, identify repeated stories and seek counterexamples outside the peak. This first report supplies temporal selection and inspected evidence leads; the plan’s multi-source event investigations remain a later stage.


## 15. Measurement quality and what changes under checks

| Reconciliation layer | Measured result |
| --- | --- |
| Raw matched records | 23,851 |
| After exact selected-field record collapse | 23,514 |
| Candidate publication-days | 23,436 |
| Distinct canonical URL/ID keys across dates | 23,400 |
| Exact normalized-text groups (short texts kept separate) | 23,272 |
| URL keys repeated on different dates | 35 |
| Repeated-date URL keys with different text groups | 27 |
| Pairs attached to four known ambiguous names | 2,395 |

The main unit keeps different database dates separate, because reused URLs can change. Collapsing every URL across years is a sensitivity check that may merge real updates. Exact-text groups provide a different check but undercount near-copy repetition. The report therefore uses “candidate publication-days”, not a claim that every record is a unique news article.

What has and has not been established

The source inventory, all-year search, field separation, county and channel distributions, recurrence measures, source-panel sensitivity, exact-text checks and computational topic exploration are complete for the supplied merged snapshot. The national identity/relevance labels, historical eligibility, source affiliation and production types are not independently validated.

A separate blank review queue contains 480 exact-text clusters and 506 organisation-cluster pairs, excluding the designated development clusters. It is preparation for review, not a completed accuracy estimate. Near-copy leakage and fuller route-risk stratification must be assessed before evaluation. No human decisions or inter-reader reliability statistics have been filled in.

The plan’s full unfiltered-export recovery, systematic apparent-miss web searches, national historical identity reconstruction, independent two-reader coding and investigative dossiers are not represented as finished. The earlier twelve-date filter diagnostic is not extrapolated to this full period. A new unfiltered corpus would require its own compatible denominator.


## 16. County appendix and practical reading

| County of registered seat | Registered | Searched | Names with candidates |
| --- | --- | --- | --- |
| Grad Zagreb | 422 | 318 | 136 |
| Splitsko-dalmatinska | 172 | 134 | 47 |
| Primorsko-goranska | 99 | 74 | 27 |
| Istarska | 79 | 65 | 26 |
| Osječko-baranjska | 79 | 66 | 34 |
| Zagrebačka | 76 | 52 | 23 |
| Dubrovačko-neretvanska | 52 | 45 | 9 |
| Sisačko-moslavačka | 40 | 30 | 13 |
| Šibensko-kninska | 40 | 37 | 19 |
| Varaždinska | 36 | 31 | 17 |
| Karlovačka | 35 | 28 | 12 |
| Vukovarsko-srijemska | 31 | 24 | 10 |
| Krapinsko-zagorska | 27 | 22 | 14 |
| Zadarska | 22 | 19 | 8 |
| Brodsko-posavska | 21 | 18 | 10 |
| Požeško-slavonska | 21 | 20 | 13 |
| Međimurska | 21 | 17 | 5 |
| Koprivničko-križevačka | 19 | 13 | 8 |
| Bjelovarsko-bilogorska | 17 | 15 | 11 |
| Ličko-senjska | 8 | 8 | 3 |
| Virovitičko-podravska | 8 | 7 | 5 |

County totals. All 21 counties. Candidate counts remain unresolved name matches. Geography concerns registered seats; activity locations and publisher scope are separate uncompleted fields. Source: county_landscape.csv.

For organisation-level exploration, use the local directory and organisation_landscape.csv. They retain every register entry, identify searched-zero and held cases, and report raw recurrence, web-domain breadth and stricter-screen counts. Domain breadth is not verified editorial breadth, and observed months are not exposure-adjusted persistence.


## 17. Research implications, sources and reproduction

The most useful substantive direction is to examine **which activities make these heterogeneous associations publicly legible**. The inspected material supports service, partnership, youth formation, spirituality and publishing as case-level routes. The computational map helps select additional material; neither it nor the administrative category should define organisations’ religious identities.

The next analytical gain will come from validating a diverse set of entities and publications, especially high-volume ambiguous names, repeated source templates and apparently absent organisations. For longitudinal comparison, reconstruct historical names and existence before calculating eligible-month rates. For representation, compare contemporaneous self-descriptions with accepted external articles and distinguish original reporting from attributed publicity.

Sources used

Primary local inputs: supplied association PDF/JSON dated 11 September 2026; determDB_merged.duckdb, table main.media_data_all, current snapshot; the supplied 15-page media research plan; source database maintenance log and data dictionaries. The register reconciliation, rule set and source hashes are recorded in the study manifests. The earlier 2025 report is retained separately.

Current official descriptions and identity evidence: [S1 Breza](https://breza.hr/o-nama/); [S2 SKAC Palma](https://www.skac.hr/upoznaj-skac/); [S3 SKAC Split](https://skac.st/o-nama/); [S4 Korablja](https://korablja-arka.hr/tko-smo/); [S5 Kršćanski akademski krug](https://www.krakr.hr/index.php/o-nama/sto-je-krscanski-akademski-krug.html); [S6 Padmasana](https://padmasana.hr/en/o-nama/); [S7 yoga centres](https://www.yoga-in-daily-life.hr/centri); [S8 Matica, Hvar branch](https://www.matica.hr/ogranci/ogranak-matice-hrvatske-u-hvaru/). Sources were accessed or inspected in the same-day local archive on 19 September 2026. Current descriptions do not prove historical ownership or activity in every study year.

C1-C7 refer to the separately recorded AI-assisted case observations and private source evidence. These preserve article provenance without redistributing restricted vendor text, titles or article URLs in this report. No organisation was contacted.

Reproduction and available outputs

Run the numbered scripts in studies/spirituality-associations/media/ in the order documented in README.md. The scan is resumable by month and the source is read-only. Aggregate tables and scientific figures are supplied separately; restricted candidates, original texts, field-specific evidence, organisation profiles and blank coding queues stay under output/private/media/v1/. Numerical assertions and the PDF are checked by 06_verify.py, followed by rendered-page inspection.

AI assistance was used for code, extraction, computational analysis, purposive passage reading and drafting. Human coding fields remain blank. This is a first descriptive and exploratory research report with an explicit validation boundary; it is not a completed test of media fairness or organisational influence.
