"""Build the first full-period analytical report entirely from computed tables."""
from pathlib import Path
import sys,json
import pandas as pd
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from common import ROOT,PRIVATE,TABLES,FIGURES,dump_json
from report_tools import Report
P=PRIVATE/'media/v1';T=TABLES/'media-v1';F=FIGURES/'media-v1'
def n(x):return f'{int(x):,}'
def pct(x):return f'{x:.1f}%'
def main():
    s=json.loads((T/'summary.json').read_text());man=json.loads((T/'manifest.json').read_text());ta=json.loads((T/'topic_audit.json').read_text())
    annual=pd.read_csv(T/'annual_landscape.csv');county=pd.read_csv(T/'county_landscape.csv');sens=pd.read_csv(T/'sensitivity.csv').set_index('scenario')
    plat=pd.read_csv(T/'platform_landscape.csv');web=plat.set_index('platform').loc['web'];sources=pd.read_csv(T/'web_domain_landscape.csv')
    same=pd.read_csv(T/'same_calendar_window.csv');org=pd.read_csv(P/'organisation_landscape.csv',dtype={'association_id':str}).set_index('association_id')
    terms=pd.read_csv(T/'topic_terms.csv').query('k==8 and seed==17');runs=pd.read_csv(T/'topic_model_runs.csv').query('seed==17')
    shares=pd.read_csv(T/'topic_shares.csv');topics=shares.pivot(index='topic',columns='corpus',values='share_pct').fillna(0)
    labels_path=ROOT/'media/topic_labels.json';labels=json.loads(labels_path.read_text(encoding='utf-8')) if labels_path.exists() else {}
    r=Report()
    r.p('FIRST EXPLORATORY ANALYTICAL REPORT','kicker');r.title('Spirituality-related associations\nin the media space')
    r.p('Croatia’s September 2026 association register linked to the full DetermDB merged dataset, 1 January 2021 to 10 September 2026.','h2')
    r.p(f'The full-period search covers **{n(man["rows"])} monitored records** and retains all **1,325 organisations** in the administrative frame. It retrieves **{n(s["candidate_items"])} candidate publication-days**, linked through names to **{n(s["candidate_names"])} register entries**. These are measured search results, with identity and substantive relevance still unresolved at corpus level.')
    r.table(['Measure','Full-period result'],[
        ['Organisations with usable name rules',n(s['searched_names'])+' / 1,325'],
        ['Names with at least one candidate',n(s['candidate_names'])],
        ['Organisation-publication-day candidate pairs',n(s['pairs'])],
        ['Years and months covered','2021-2026; 69 months; 2026 is partial']],widths=[.65,.35])
    r.h2('The first landscape')
    r.p(f'The retrieval signal is uneven: the ten most frequently matched names account for **{pct(sens.loc["all_candidate_pairs","top10_share_pct"])}** of candidate pairs. Web pages supply **{pct(100*web.candidate_items/s["candidate_items"])}** of candidate publication-days. Both patterns describe the monitored search output, not a verified hierarchy of organisational influence.')
    r.p('The inspected examples show several routes into public visibility: practical assistance and volunteering, spiritual programmes, social inclusion, education and publishing. They also show why a single “religious media presence” label would be too narrow for this administrative population.')
    r.p('A stronger national conclusion awaits historical identity checks and independent article coding. This report provides the descriptive landscape, computational exploration, contrastive case readings and reproducible evidence needed to make those next checks precise. It does not estimate public opinion, media hostility or causal influence.')
    r.p('Prepared 19 September 2026. Internal research edition; aggregate findings and AI-assisted interpretations are distinguished throughout.','small')

    r.page('1. What is in the full dataset?')
    r.p(f'The database contains records on every calendar day from {man["start"]} to {man["end"]}: {n(pd.read_csv(T/"daily_coverage.csv").date.nunique())} observed dates. No year is excluded. The final year ends on 10 September and contributes 253 days. Counts below are source records before this study’s candidate reconciliation.')
    r.table(['Year','Monitored records','Days','Candidate publication-days','Matched names'],[[str(int(x.year))+('*' if x.year==2026 else ''),n(x.monitored_records),n(x.observed_days),n(x.candidate_items),n(x.candidate_names)] for x in annual.itertuples()],widths=[.10,.24,.10,.30,.26])
    r.p('Annual counts. Each candidate publication-day is a platform + canonical URL + database date, with an ID/text fallback for missing URLs. One item can generate several organisation-item pairs. “Matched names” is not a count of independently validated organisations. *Partial year. Source: annual_landscape.csv.','small')
    r.h2('The collection break is now January 2024')
    r.p('The older plan located the feed change in April 2024. The current database has since replaced January-March 2024 with newer imports. Measured provenance is therefore **2021-2023: luka_opce, unfiltered; 2024-2026: mediaspace_full, filtered**. The latter retains records containing the standalone word “i”. The query scope, platform mix and retention process all change. A before/after count difference cannot be read as a social trend.')
    r.h2('A present-day register viewed retrospectively')
    r.p('The 1,325-entry frame is the supplied active-status administrative list dated 11 September 2026. It includes cultural, welfare, educational and personal-development associations as well as explicitly spiritual bodies. It is not the historical population of all associations operating in each earlier year. Organisations absent from the 2026 frame cannot be recovered by searching this list, and year-specific existence/name eligibility has not been reconstructed.')
    r.p('All supplied monitored countries and languages are retained. Publisher country, language and activity location have not been adjudicated; a domain suffix does not establish them. This is a Croatian-register-linked view of the supplied media feed, not a census of Croatian journalism or a country-filtered editorial corpus.','small')
    r.p('The source database was opened read-only. Its file size and modification fingerprint were checked before and after retrieval. The source text, original fields and match evidence remain in the local private workspace; they are not reproduced in the aggregate supplement.')

    r.page('2. The search funnel and the meaning of a zero')
    r.figure(F/'search_funnel.png','Figure 1. Register coverage and unresolved search states. Source: funnel.csv and summary.json.',230)
    r.p(f'Usable rules were available for {n(s["searched_names"])} names ({pct(100*s["searched_names"]/1325)} of the frame). Across all years, {n(s["candidate_names"])} have a candidate and {n(s["searched_zero"])} have none under these rules. Another {n(s["held_names"])} short, generic or otherwise unresolved names remain held for identity work. These three states are retained separately in the all-organisation directory.')
    r.p(f'The full-period search adds {n(s["candidate_names"]-int(annual.loc[annual.year==2025,"candidate_names"].iloc[0]))} names with candidates beyond the 2025-only set. A single year therefore gives a materially narrower view of which names can be found, even before validation. This is a gain in temporal search coverage, not proof of changes in organisational activity.')
    r.p('The screen reuses the documented legal-name rules and a small official-source alias set. It applies them independently to TITLE, FULL_TEXT and MENTION_SNIPPET, with accent-folding and word boundaries. It does not impose a Catholic or spirituality keyword filter. Names are never assembled across fields. Nevertheless, a complete legal phrase can still be ordinary language, an unrelated entity, navigation or an old story embedded in a new page.')
    r.table(['Evidence state','What can be concluded'],[
        ['Candidate found','A stored field matches a rule. The entity and substantive reference still need review.'],
        ['Searched, no candidate','No match under the current finite rules in the supplied monitored feed. Short names, inflections and missed sources may matter.'],
        ['Held for identity work','The search is incomplete for this register entry; no media-absence conclusion is available.'],
        ['Validated substantive editorial link','Not yet estimated nationally; requires identity, relevance, prominence and source/production checks.']],widths=[.32,.68])
    r.p(f'Snippet-only matching contributes {n(s["snippet_only_pairs"])} pairs; {n(s["alias_only_pairs"])} pairs rely only on curated aliases. The aliases improve discovery for selected cases but also make search effort unequal across organisations. No recall estimate or prevalence of “invisible organisations” is reported.')

    r.page('3. Registered geography and retrieved names')
    r.figure(F/'county_search_landscape.png','Figure 2. County of registered seat, with searched and held names kept visible. This is not a map of activities or audiences. Source: county_landscape.csv.',355)
    zag=county[county.county=='Grad Zagreb'].iloc[0]
    r.p(f'Grad Zagreb contains {n(zag.registered)} entries ({pct(100*zag.registered/1325)} of the register), of which {n(zag.candidate_names)} have at least one candidate. The county totals describe where associations are registered. A Zagreb seat can support activity elsewhere, while an organisation registered in another county may reach national media.')
    r.p('The geographical comparison should therefore be read in two layers: the distribution of registered organisations and the coverage of the search rules. County differences in matched-name rates can reflect name distinctiveness, organisational composition, aliases and monitored publishers. They are not population-adjusted measures of local spirituality or organisational effectiveness. The complete county table appears in the appendix.')

    r.page('4. Concentration and persistence of the search signal')
    r.figure(F/'candidate_concentration.png','Figure 3. Candidate-pair concentration among all searched names, including searched zeros. The curves describe retrieval inequality; they are not validated attention curves. Source: pairs and sensitivity.csv.',245)
    names={'all_candidate_pairs':'All candidate pairs','restricted_screen':'Restricted screen','title_or_lead':'Title or first 800 characters','exact_text_collapse':'One pair per exact-text group'}
    r.table(['Specification','Pairs','Names','Top-ten share'],[[label,n(sens.loc[key,'pairs']),n(sens.loc[key,'names']),pct(sens.loc[key,'top10_share_pct'])] for key,label in names.items()],widths=[.49,.17,.15,.19])
    r.p(f'Among names with candidates, the median is {s["median_candidate_months"]:.0f} observed months out of 69 database months. This is a raw recurrence measure: historically eligible months are not known. A recurring name can represent sustained activity, repeatedly crawled evergreen pages, publicity, navigation or recurring mistaken matches.')
    r.p('The restricted screen removes snippet-only/tail-only references, four names with documented ambiguity and matches supported only by the short SKAC ST alias. It deliberately sacrifices possible genuine coverage to test sensitivity. The title/lead screen requires a name in the title or the first 800 normalized body characters. Neither screen is a validated set. No named league table is inferred from these counts.')

    r.page('5. Time: volume, collection regime and partial 2026')
    r.figure(F/'coverage_and_candidates.png','Figure 4. Monthly source records and raw candidate records. Dashed line: January 2024 regime change. Shaded final month: ten days only. Source: monthly_landscape.csv.',285)
    r.p('The two panels separate the amount of available material from the number of name hits. The same-calendar-window comparison below retains 1 January-10 September in every year. It avoids comparing a partial 2026 total with a full earlier year, while leaving the feed change and historical-identity problem unresolved.')
    r.table(['Jan 1-Sep 10','Monitored records','Candidate publication-days','Raw hits / 10,000 records'],[[str(int(x.year)),n(x.monitored_records),n(x.candidate_items),f'{x.raw_candidates_per_10000:.2f}'] for x in same.itertuples()],widths=[.20,.25,.29,.26])
    r.p('The last column divides raw candidate records by raw monitored records; it is a search-yield diagnostic. Deduplicated publication-day counts are never divided by raw vendor counts. No growth or decline in actual organisational visibility is inferred from this table. Source: same_calendar_window.csv.','small')

    r.page('6. A common observed source panel')
    r.figure(F/'common_panel_yield.png','Figure 5. Raw search yield within web records, with a common-domain sensitivity panel. Source: common_domain_panel.csv; membership in common_domain_members.csv.',290)
    r.p(f'The panel contains {n(s["common_panel_domains"])} web domains with at least 100 monitored records in every one of the 69 months. This holds the observed domain set constant. It helps distinguish changes in the source mix from changes within repeatedly observed sources.')
    r.p('The panel does not hold all collection conditions constant. It cannot recover records removed by the “i” filter, guarantee equal crawling within a domain, settle historical organisation names or classify editorial independence. Domain continuity is also not publisher-group continuity. Treat the comparison as a robustness description, not a corrected time series.')
    r.h2('Database dates are not automatically event dates')
    r.p('The case reading found a Breza partnership page stored under 21 January 2021 that advertises training dates in November 2019. A Matica branch page dated in the database to May 2021 contains older branch/event material. These observed examples make it unsafe to label every peak as a contemporaneous activity peak. Event-specific interpretation needs publication, update and activity dates checked separately [C6-C7].')

    r.page('7. Channels: web dominates, but web is not an origin code')
    r.figure(F/'platforms.png','Figure 6. Candidate publication-days by vendor platform. The source platform field describes delivery format, not independence or production. Source: platform_landscape.csv.',270)
    r.p(f'The web channel contributes {n(web.candidate_items)} candidate publication-days, or {pct(100*web.candidate_items/s["candidate_items"])} of the retrieved total. The remainder spans social posts, video descriptions, discussion and other available formats. A social post linking to a story and the story itself remain separate channel observations.')
    r.p(f'Across candidates, {n(s["body_available_items"])} items have a non-empty FULL_TEXT field. This establishes text availability, not transcript completeness or successful article extraction. Bodies can contain teasers, product descriptions, navigation and related content. A YouTube description listing a guest does not establish what that person said in the programme [C4].')
    r.p(f'Only {n(s["own_domain_pairs"])} pairs match the small current official-domain map for six documented organisations. That is a mapping diagnostic, not an estimate of the amount of owned communication. All other relationships remain unresolved; missing owned-domain evidence is never converted into external editorial coverage.')
    r.p('The dataset does not yet support a national split into original reporting, republished organisational statements, institutional communication and public discussion. The report therefore does not use reach, engagement or vendor sentiment as measures of influence, public trust or target-specific evaluation.')

    r.page('8. Where candidate web material is found')
    r.figure(F/'web_domains.png','Figure 7. Twelve domains with the largest retrieved web volumes. These are source-discovery priorities, not a ranking of editorial support. Source: web_domain_landscape.csv.',295)
    r.p(f'The three largest domains together contribute {pct(100*sources.head(3).candidate_items.sum()/web.candidate_items)} of candidate web publication-days. Source concentration matters because a shared template or recurring page can create many name hits; the largest domain totals should receive early cleaning and provenance review.')
    r.p('Inspection shows that the web category contains several kinds of material. The Kršćanski akademski krug example is a journal product listing, not a news story. The SKAC Split example explicitly attributes text and photos to the organisation, despite appearing on another domain. The Hvar branch example is embedded in a wider branch listing. Counting all three as independent journalism would erase material differences in how organisations enter the media space [C2, C5, C7].')
    r.p('A useful next source map should record three axes separately: medium, publisher relationship to the association and production type. Where an affiliated outlet also reports original material, both attributes should be preserved. Current domain names alone do not establish historical ownership or editorial independence.')

    r.page('9. The initial topic model exposes recurring templates')
    r.p(f'The text exploration uses {n(ta["documents"])} candidate publication-days with usable restricted-screen context. Association names are masked and common function words removed. TF-IDF/NMF models were fitted with 6, 8, 10 and 12 topics and two random starts each. The eight-topic model is used as a readable exploratory map; the labels below are interpretive shorthand after reviewing representative passages, not human-coded organisational roles.')
    r.table(['Topic','Provisional reading','Highest-weight surface terms'],[[str(int(x.topic)),labels.get(str(int(x.topic)),'Computational grouping'),', '.join(x.terms.split(', ')[:7])] for x in terms.itertuples()],widths=[.09,.35,.56])
    r.p('Inspection shows that topics 1, 2, 3, 7 and 8 largely capture recurring support instructions, channel self-description or video tags. Topics 4-6 offer broad activity contexts, but their weakly assigned examples can be unrelated. The eight groups should therefore not be presented as eight substantive public roles.','small')
    r.table(['Topics','Across-start similarity','Iterations'],[[str(int(x.topics)),f'{x.aligned_mean_cosine_between_seeds:.3f}',str(int(x.iterations))] for x in runs.itertuples()],widths=[.20,.50,.30])
    r.p('Model stability. Similarity is the mean cosine similarity after optimal alignment of topic-term vectors across two starts, within each model size. It describes computational reproducibility, not substantive validity. More topics can split a recurring vocabulary without discovering a new social role. Source: topic_terms.csv and topic_model_runs.csv.','small')
    r.p('This first run uses accent-folded Croatian surface forms, not lemmatisation. Inflected forms can split across features. Contexts extend roughly 450 normalized characters to either side of a matched name and may cross sentence boundaries within a field. Consequently, the results are neither sentence-level concept associations nor a finished Croatian linguistic analysis.')

    r.page('10. How robust is the thematic map?')
    r.figure(F/'topic_channels.png','Figure 8. Strongest-topic assignments within each modelled channel subset. Percentages concern algorithmic groupings of provisional candidates, not the prevalence of frames or public roles. Source: topic_platform.csv.',260)
    r.table(['Topic','All modelled items','Web subset','One per exact text'],[[str(t),pct(topics.loc[t,'all_restricted_passages']),pct(topics.loc[t,'web_restricted_passages']),pct(topics.loc[t,'one_per_exact_text_group'])] for t in topics.index if t>0],widths=[.10,.30,.30,.30])
    r.p(f'Whole-text and association-context models have an aligned mean topic-vector similarity of {ta["fulltext_aligned_mean_cosine"]:.3f}. This directly tests whether the surrounding article produces the same structure as the association-focused window. {n(ta["low_dominance_below_0_4"])} items have a strongest-topic weight share below 0.4; {n(ta["zero_weight_items"])} have no model weight. Mixed and weak assignments should not be forced into single substantive frames.')
    r.p('Exact-text grouping only removes identical normalized bodies of at least 200 characters. Near-copies with changed headings, footers or small edits can remain separate. The web subset is not an editorial-only subset because source production has not been coded. These limits are visible rather than treated as completed controls.','small')

    r.page('11. After suppressing repeated passages')
    rep=json.loads((T/'repeat_check_summary.json').read_text());rl=json.loads((ROOT/'media/repeat_topic_labels.json').read_text(encoding='utf-8'))
    rt=pd.read_csv(T/'repeat_check_terms.csv');rc=pd.read_csv(T/'repeat_check_channels.csv').groupby('topic')['items'].sum();rm=pd.read_csv(T/'repeat_check_models.csv')
    r.p(f'A second exploratory pass suppresses every eight-token sequence found in at least 20 different candidate items. It removes {pct(100*rep["removed_repeated_tokens"]/rep["input_tokens"])} of the input tokens and retains {n(rep["retained_items"])} items with at least 15 remaining non-stopword tokens; {n(rep["excluded_below_15_tokens"])} fall below that threshold. Candidate counts elsewhere in this report do not change.')
    r.table(['Group','Reading after inspected examples','Remaining vocabulary','Items'],[[str(int(x.topic)),rl[str(int(x.topic))],', '.join(x.terms.split(', ')[:5]),n(rc.get(x.topic,0))] for x in rt.itertuples()],widths=[.09,.39,.37,.15])
    r.p('The more interpretable contexts include funded social-service projects, religious gatherings, commemorative and veterans’ activity, minority-cultural funding, festivals and workshops. These extend well beyond an exclusively religious news agenda. The broad conversational group remains heterogeneous and should not receive a single public-role label. Individual group assignments are exploratory, not adjudicated organisation-article representations.')
    r.p('Representative readings reinforce the administrative frame’s breadth: project texts describe partnerships and social-service provision; an Istrian cluster contains minority-cultural grant announcements and lists of organisations; local-programme material includes children’s festivals and environmental volunteering. These are patterns in selected retrieved passages, not population percentages of organisational functions.')
    r.p(f'The six-topic repeat-suppressed model has across-start similarity {rm.loc[rm.topics==6,"aligned_cosine"].iloc[0]:.3f}, compared with {rm.loc[rm.topics==8,"aligned_cosine"].iloc[0]:.3f} for eight topics. The six-topic display was chosen after the initial diagnostic, not preregistered. A recurring substantive announcement can be removed by this method too; this sensitivity set is not a validated clean corpus. Source: repeat_check_summary.json, repeat_check_terms.csv, repeat_check_models.csv.','small')

    r.page('12. Eight organisational starting portraits')
    r.figure(F/'selected_profiles.png','Figure 9. Purposively selected organisations with current documentary identity evidence. Numbers remain unresolved search counts. The cases are not representative and are not ordered as a visibility league table. Source: private organisation_year.csv.',275)
    r.h2('Breza: community services and partnership')
    r.p(f'Breza has {n(org.loc["8013","candidate_items"])} candidates across {n(org.loc["8013","candidate_months"])} months. Its [official description](https://breza.hr/o-nama/) foregrounds children and young people, social support, education, culture and volunteering. The inspected partnership item concerns training and tourism, with an older event date. This illustrates a practical public role and the need to separate organisation identity from administrative “spirituality” classification [C6].')
    r.h2('SKAC Palma and Split: formation and action')
    r.p(f'SKAC Palma has {n(org.loc["4553","candidate_items"])} candidates and SKAC Split {n(org.loc["58492","candidate_items"])}. Their documented self-descriptions combine Christian formation with youth development and volunteering. The inspected Palma invitation foregrounds spiritual preparation and a participant testimonial; the Split item foregrounds earthquake assistance and explicitly republishes the organisation’s own account. These are different routes into visibility, even within a closely related organisational setting [C2-C3; S2-S3].')

    r.page('13. What contrasting cases add')
    r.h2('Korablja: belonging, disability and a named professional role')
    r.p(f'Korablja has {n(org.loc["42673","candidate_items"])} candidates in {n(org.loc["42673","candidate_months"])} months. Its [identity page](https://korablja-arka.hr/tko-smo/) explicitly connects the legal association with the Arka community and describes shared life with and without intellectual disabilities. The inspected programme description identifies an association-linked professional discussing disability. It makes the association discoverable through an issue and a person’s role, while providing insufficient text to count spoken voices or evaluate the full interview [C4].')
    r.h2('Kršćanski akademski krug: publishing can look like coverage')
    r.p(f'The Krug has {n(org.loc["32947","candidate_items"])} candidates. Its [official account](https://www.krakr.hr/index.php/o-nama/sto-je-krscanski-akademski-krug.html) describes Christian intellectual and social reflection. The inspected web-shop record names the association through its journal, Nova prisutnost. This is meaningful public discoverability of a cultural/intellectual product, but it is not evidence of an independent article about the association [C5].')
    r.h2('Yoga in Rijeka: spiritual-practice organisations also appear as helpers')
    r.p(f'The Rijeka association has {n(org.loc["10420","candidate_items"])} candidates. In the inspected January 2021 body, the association is explicitly linked to hostel accommodation for people affected by the Petrinja earthquake. The immediate public role is assistance and partnership. This example supports looking for associations without a religious keyword prefilter; it does not establish that spirituality was hidden or excluded [C1].')
    r.h2('Padmasana and the Hvar branch: two different limits')
    r.p(f'Padmasana has {n(org.loc["14821","candidate_items"])} retrieved candidates under the current rules. Its [official page](https://padmasana.hr/en/o-nama/) describes Buddhist study, meditation and retreats near Zaprešić. Sparse retrieval cannot refute documented activity or measure its public reach. The Hvar branch of Matica hrvatska has {n(org.loc["14665","candidate_items"])} candidates, but an inspected early-body match occurs in a branch list on another branch’s page. This is a direct warning against treating literal-name prominence as sufficient entity/relevance validation [C7].')
    r.p('All counts in these portraits refer to unresolved candidates. The observations are purposive AI-assisted readings, not independently adjudicated case dossiers. Full source keys, passages and decisions remain private. None of the cases supplies an estimate of the population distribution of orientation, voice or framing.','small')

    r.page('14. From temporal patterns to event questions')
    r.figure(F/'case_timelines.png','Figure 10. Monthly retrieval for three documentary cases. The vertical line marks the collection change. Peaks select material to inspect; they do not independently identify an event. Source: private organisation_month.csv.',280)
    r.table(['Case observation','Date in database','What the text contributes'],[
        ['C2: SKAC Split','9 Jan 2021','Attributed organisational account of assistance in Petrinja and Glina.'],
        ['C3: SKAC Palma','15 Jan 2021','Spiritual programme invitation with a testimonial attributed to the own site.'],
        ['C1: Rijeka yoga association','19 Jan 2021','Explicit association-hostel partnership providing earthquake-related accommodation.']],widths=[.30,.20,.50])
    r.p('The January examples show that assistance and spiritual programmes can coexist in the same media period. They do not show a collaboration among the three associations. The Split and Rijeka observations concern earthquake assistance, but common subject matter alone does not establish shared organisation, causal influence or text-copying direction.')
    r.p('A full event dossier would now trace all relevant publications and versions, establish dates and origin evidence, identify repeated stories and seek counterexamples outside the peak. This first report supplies temporal selection and inspected evidence leads; the plan’s multi-source event investigations remain a later stage.')

    r.page('15. Measurement quality and what changes under checks')
    r.table(['Reconciliation layer','Measured result'],[
        ['Raw matched records',n(s['raw_candidates'])],['After exact selected-field record collapse',n(s['exact_unique_records'])],
        ['Candidate publication-days',n(s['candidate_items'])],['Distinct canonical URL/ID keys across dates',n(s['url_only_items'])],
        ['Exact normalized-text groups (short texts kept separate)',n(s['exact_text_groups'])],
        ['URL keys repeated on different dates',n(s['recurring_url_keys'])],
        ['Repeated-date URL keys with different text groups',n(s['recurring_url_keys_multiple_texts'])],
        ['Pairs attached to four known ambiguous names',n(s['known_risk_pairs'])]],widths=[.75,.25])
    r.p('The main unit keeps different database dates separate, because reused URLs can change. Collapsing every URL across years is a sensitivity check that may merge real updates. Exact-text groups provide a different check but undercount near-copy repetition. The report therefore uses “candidate publication-days”, not a claim that every record is a unique news article.')
    r.h2('What has and has not been established')
    r.p('The source inventory, all-year search, field separation, county and channel distributions, recurrence measures, source-panel sensitivity, exact-text checks and computational topic exploration are complete for the supplied merged snapshot. The national identity/relevance labels, historical eligibility, source affiliation and production types are not independently validated.')
    rq=json.loads((T/'review_queue_design.json').read_text())
    r.p(f'A separate blank review queue contains {n(rq["sample_exact_text_clusters"])} exact-text clusters and {n(rq["sample_pairs"])} organisation-cluster pairs, excluding the designated development clusters. It is preparation for review, not a completed accuracy estimate. Near-copy leakage and fuller route-risk stratification must be assessed before evaluation. No human decisions or inter-reader reliability statistics have been filled in.')
    r.p('The plan’s full unfiltered-export recovery, systematic apparent-miss web searches, national historical identity reconstruction, independent two-reader coding and investigative dossiers are not represented as finished. The earlier twelve-date filter diagnostic is not extrapolated to this full period. A new unfiltered corpus would require its own compatible denominator.')

    r.page('16. County appendix and practical reading')
    r.table(['County of registered seat','Registered','Searched','Names with candidates'],[[x.county,n(x.registered),n(x.searched),n(x.candidate_names)] for x in county.sort_values('registered',ascending=False).itertuples()],widths=[.49,.17,.17,.17])
    r.p('County totals. All 21 counties. Candidate counts remain unresolved name matches. Geography concerns registered seats; activity locations and publisher scope are separate uncompleted fields. Source: county_landscape.csv.','small')
    r.p('For organisation-level exploration, use the local directory and organisation_landscape.csv. They retain every register entry, identify searched-zero and held cases, and report raw recurrence, web-domain breadth and stricter-screen counts. Domain breadth is not verified editorial breadth, and observed months are not exposure-adjusted persistence.')

    r.page('17. Research implications, sources and reproduction')
    r.p('The most useful substantive direction is to examine **which activities make these heterogeneous associations publicly legible**. The inspected material supports service, partnership, youth formation, spirituality and publishing as case-level routes. The computational map helps select additional material; neither it nor the administrative category should define organisations’ religious identities.')
    r.p('The next analytical gain will come from validating a diverse set of entities and publications, especially high-volume ambiguous names, repeated source templates and apparently absent organisations. For longitudinal comparison, reconstruct historical names and existence before calculating eligible-month rates. For representation, compare contemporaneous self-descriptions with accepted external articles and distinguish original reporting from attributed publicity.')
    r.h2('Sources used')
    r.p('Primary local inputs: supplied association PDF/JSON dated 11 September 2026; determDB_merged.duckdb, table main.media_data_all, current snapshot; the supplied 15-page media research plan; source database maintenance log and data dictionaries. The register reconciliation, rule set and source hashes are recorded in the study manifests. The earlier 2025 report is retained separately.','small')
    r.p('Current official descriptions and identity evidence: [S1 Breza](https://breza.hr/o-nama/); [S2 SKAC Palma](https://www.skac.hr/upoznaj-skac/); [S3 SKAC Split](https://skac.st/o-nama/); [S4 Korablja](https://korablja-arka.hr/tko-smo/); [S5 Kršćanski akademski krug](https://www.krakr.hr/index.php/o-nama/sto-je-krscanski-akademski-krug.html); [S6 Padmasana](https://padmasana.hr/en/o-nama/); [S7 yoga centres](https://www.yoga-in-daily-life.hr/centri); [S8 Matica, Hvar branch](https://www.matica.hr/ogranci/ogranak-matice-hrvatske-u-hvaru/). Sources were accessed or inspected in the same-day local archive on 19 September 2026. Current descriptions do not prove historical ownership or activity in every study year.','small')
    r.p('C1-C7 refer to the separately recorded AI-assisted case observations and private source evidence. These preserve article provenance without redistributing restricted vendor text, titles or article URLs in this report. No organisation was contacted.','small')
    r.h2('Reproduction and available outputs')
    r.p('Run the numbered scripts in studies/spirituality-associations/media/ in the order documented in README.md. The scan is resumable by month and the source is read-only. Aggregate tables and scientific figures are supplied separately; restricted candidates, original texts, field-specific evidence, organisation profiles and blank coding queues stay under output/private/media/v1/. Numerical assertions and the PDF are checked by 06_verify.py, followed by rendered-page inspection.','small')
    r.p('AI assistance was used for code, extraction, computational analysis, purposive passage reading and drafting. Human coding fields remain blank. This is a first descriptive and exploratory research report with an explicit validation boundary; it is not a completed test of media fairness or organisational influence.','small')
    reportdir=ROOT/'output/report';reportdir.mkdir(exist_ok=True)
    target=ROOT.parents[1]/'output/pdf/spirituality-associations-media-landscape-2021-2026.pdf'
    r.write(target,reportdir/'MEDIA_LANDSCAPE_2021_2026.md')
    dump_json(T/'report_claims.json',{'source_records':man['rows'],'registered':1325,**s,
        'top10_candidate_pair_share_pct':float(sens.loc['all_candidate_pairs','top10_share_pct']),
        'web_candidate_share_pct':float(100*web.candidate_items/s['candidate_items']),
        'topic_documents':ta['documents'],'claim_sources':['summary.json','annual_landscape.csv','sensitivity.csv','platform_landscape.csv','topic_audit.json','county_landscape.csv','AI_CASE_OBSERVATIONS.md']})
    print('REPORT WRITTEN',target)
if __name__=='__main__':main()
