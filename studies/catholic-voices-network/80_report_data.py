"""Complete-corpus descriptive evidence for Level-A tables and figures.

The JSON is private: small cells are retained for reproducible computations and
must be suppressed by every public renderer, including figure coordinates.
"""
import collections,json
from voices_common import *


def linkage_coverage(con):
    selected={r[0] for r in con.execute('''SELECT e.entity_id FROM entities e JOIN entity_counts c
      ON c.entity_id=e.entity_id AND c.threshold=e.threshold WHERE e.threshold=.9
      ORDER BY c.documents DESC,e.entity_id LIMIT 1500''').fetchall()}
    saved=con.execute('SELECT entity_id,status,qid FROM entity_links').fetchall()
    if len(saved)!=len(selected) or {r[0] for r in saved}!=selected:
        raise RuntimeError('Incomplete or unexpected public-name linkage evidence')
    statuses=dict(collections.Counter(r[1] for r in saved))
    if set(statuses)-{'linked','unresolved','sacred','ambiguous'} or any((status=='linked')!=bool(qid) for _,status,qid in saved):
        raise RuntimeError('Invalid public-name linkage status')
    linked=statuses.get('linked',0)
    return dict(selected=len(selected),statuses=statuses,linked=linked,without_accepted_link=len(selected)-linked)


def check_linkage_report(coverage,report):
    if report['selected']!=coverage['selected'] or report['statuses']!=coverage['statuses']:
        raise RuntimeError('Final public-name linkage report differs from the database')


def collect(con):
    def rows(sql,params=None):
        result=con.execute(sql,params or []);names=[x[0] for x in result.description]
        return [dict(zip(names,r)) for r in result.fetchall()]
    corpus=rows('''SELECT count(*) AS documents,sum(n_chars) AS characters,
      count(DISTINCT platform) AS platforms,count(DISTINCT text_sha256) AS unique_texts,
      min(nullif(date,'')) AS first_date,max(nullif(date,'')) AS last_date,
      count(*) FILTER(WHERE n_chars<300) AS short_documents FROM docs''')[0]
    platform=rows('''SELECT platform,count(*) AS documents,
      count(*) FILTER(WHERE n_chars>=300) AS long_documents,
      count(DISTINCT text_sha256) AS unique_texts FROM docs GROUP BY platform ORDER BY documents DESC,platform''')
    eras=rows('''SELECT platform,era,count(*) AS documents,count(*) FILTER(WHERE n_chars>=300) AS long_documents
      FROM docs GROUP BY platform,era ORDER BY platform,era''')
    recognition=rows('''SELECT d.platform,r.life_class,count(*) AS spans,count(DISTINCT r.doc_id) AS documents
      FROM resolved_mentions r JOIN docs d USING(doc_id) GROUP BY d.platform,r.life_class ORDER BY d.platform,r.life_class''')
    people=rows('''SELECT p.entity_id,p.documents,p.outlets,p.platforms,p.mention_spans,
      min(s.documents) AS minimum_documents,max(s.documents) AS maximum_documents,
      max(s.ambiguous_clusters) AS ambiguous_clusters
      FROM network_people p JOIN network_cluster_scenarios s USING(entity_id)
      WHERE p.d6 GROUP BY ALL ORDER BY p.documents DESC,p.entity_id''')
    distribution=rows('''SELECT a.entity_id,d.platform,d.era,count(*) AS documents
      FROM network_doc_entities a JOIN docs d USING(doc_id) GROUP BY ALL ORDER BY a.entity_id,d.platform,d.era''')
    # Private accounts are combined for public display only; the graph used
    # separate source IDs. Distinct documents prevent aggregate double counting.
    source_distribution=rows('''SELECT s.public_label,s.platform,s.publish,count(DISTINCT a.doc_id) AS documents,
      count(DISTINCT a.entity_id) AS people FROM network_doc_entities a JOIN docs d USING(doc_id)
      JOIN network_sources s ON s.source=d.source AND s.platform=d.platform GROUP BY ALL
      ORDER BY documents DESC,s.platform,s.public_label''')
    family_summary=rows('''WITH sizes AS (
      SELECT m.threshold,m.family_id,count(DISTINCT d.doc_id) AS documents,count(DISTINCT m.text_id) AS unique_texts,
        count(DISTINCT d.platform) AS platforms
      FROM circulation_membership m JOIN circulation_texts t USING(text_id) JOIN docs d USING(text_sha256) GROUP BY ALL)
      SELECT threshold,count(*) AS families,sum(documents) AS documents,
        sum(documents)-count(*) AS excess_appearances,
        count(*) FILTER(WHERE documents>1) AS repeated_families,
        count(*) FILTER(WHERE platforms>1) AS cross_platform_families,max(documents) AS largest_family
      FROM sizes GROUP BY threshold ORDER BY threshold''')
    family_distribution=rows('''WITH sizes AS (
      SELECT m.family_id,count(DISTINCT d.doc_id) AS documents
      FROM circulation_membership m JOIN circulation_texts t USING(text_id) JOIN docs d USING(text_sha256)
      WHERE m.threshold=.85 GROUP BY m.family_id)
      SELECT CASE WHEN documents=1 THEN '1' WHEN documents<=4 THEN '2–4' WHEN documents<=9 THEN '5–9'
        WHEN documents<=49 THEN '10–49' ELSE '50+' END AS size_group,
        count(*) AS families,sum(documents) AS documents FROM sizes GROUP BY size_group ORDER BY min(documents)''')
    title_status=rows('SELECT status,count(*) AS spans,count(DISTINCT doc_id) AS documents FROM title_mentions GROUP BY status ORDER BY status')
    role_cues=rows('''SELECT f.cue_class,count(*) AS spans,count(DISTINCT r.doc_id) AS documents
      FROM resolved_mentions r JOIN form_mentions m ON r.doc_id=m.doc_id AND r.start_char=m.start_char AND r.end_char=m.end_char
      JOIN forms f USING(form_id) LEFT JOIN network_people n ON n.entity_id=r.qid
      WHERE r.origin='ner' AND r.life_class IN ('contemporary','unresolved','date_uncertain')
        AND (n.d6 IS NULL OR NOT n.d6) GROUP BY f.cue_class ORDER BY f.cue_class''')
    quarter=rows('''SELECT platform,era,substr(date,1,4)||'-Q'||cast(ceil(cast(substr(date,6,2) AS INTEGER)/3.0) AS INTEGER) AS quarter,
      count(*) AS documents FROM docs WHERE date IS NOT NULL AND date<>'' GROUP BY ALL ORDER BY platform,era,quarter''')
    scope=dict(eligible_people=len(people),
      documents_with_public_person=con.execute('SELECT count(DISTINCT doc_id) FROM network_doc_entities').fetchone()[0],
      below_d6_people=con.execute('SELECT count(*) FROM network_people WHERE NOT d6').fetchone()[0],
      candidate_windows=con.execute('SELECT count(*) FROM candidates').fetchone()[0],
      parsed_rule_sentences=con.execute("SELECT count(*) FROM rule_sentence_results WHERE status='complete'").fetchone()[0])
    name_forms=dict(forms=con.execute('SELECT count(*) FROM forms').fetchone()[0],
      statuses=dict(con.execute('SELECT status,count(*) FROM form_lemmas GROUP BY status').fetchall()))
    if sum(name_forms['statuses'].values())!=name_forms['forms']:
        raise RuntimeError('Incomplete normalization evidence')
    return dict(corpus=corpus,scope=scope,platforms=platform,platform_eras=eras,identity_classes=recognition,
      people=people,person_platform_eras=distribution,source_distribution=source_distribution,
      circulation=family_summary,circulation_sizes=family_distribution,title_status=title_status,role_cues=role_cues,quarter_denominators=quarter,
      name_forms=name_forms,public_name_linkage=linkage_coverage(con))


def main():
    legacy_path=STUDY/'output/private/pilot_diagnosis.json'
    legacy=json.loads(legacy_path.read_text(encoding='utf-8'))
    if legacy['corpus_sha256']!=CORPUS_HASH or legacy['config_hash']!=CONFIG_HASH:raise RuntimeError('Wrong original pilot diagnosis')
    atomic_json_stable(workdir()/'legacy_pilot_diagnosis.json',{**legacy,'original_file_sha256':file_sha(legacy_path)})
    source_names=['publication_audit.json','model_gate_summary.json','gazetteer_report.json','cluster_report.json',
      'identity_resolution_report.json','speech_rule_report.json','office_coverage_report.json',
      'circulation_report.json','network_inputs_report.json','mention_network_report.json','network_metrics.json','network_public_names.json',
      'legacy_pilot_diagnosis.json','forms_report.json','wikidata_link_report.json']
    evidence={};hashes={}
    for name in source_names:
        path=workdir()/name;value=json.loads(path.read_text(encoding='utf-8'))
        if value.get('corpus_sha256')!=CORPUS_HASH or value.get('config_hash')!=CONFIG_HASH:raise RuntimeError('Mixed source: '+name)
        evidence[name.removesuffix('.json')]=value;hashes[name]=file_sha(path)
    if evidence['publication_audit']['level_a_identity_gate']!='passed':raise RuntimeError('Identity audit not passed')
    con=connect()
    if con.execute('SELECT count(*) FROM network_mention_docs').fetchone()[0]!=MANIFEST['corpus']['rows']:raise RuntimeError('Incomplete network input')
    values=collect(con);con.close()
    forms=evidence['forms_report']
    if forms['forms']!=values['name_forms']['forms'] or forms['statuses']!=values['name_forms']['statuses']:
        raise RuntimeError('Final normalization report differs from the database')
    check_linkage_report(values['public_name_linkage'],evidence['wikidata_link_report'])
    names={r['entity_id']:r['public_name'] for r in evidence['network_public_names']['people']}
    repeated=collections.Counter(names.values())
    names={qid:name+' ('+qid+')' if repeated[name]>1 else name for qid,name in names.items()}
    for person in values['people']:person['public_name']=names[person['entity_id']]
    if values['corpus']['documents']!=MANIFEST['corpus']['rows']:raise RuntimeError('Wrong report denominator')
    if sum(r['documents'] for r in values['platforms'])!=values['corpus']['documents']:raise RuntimeError('Platform totals differ')
    created=utc()
    result=dict(created_utc=created,corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      presentation=dict(report_title='Tko govori o vjeri?',report_date=created[:10],
        corpus_period=values['corpus']['first_date']+' — '+values['corpus']['last_date'],
        corpus_sha_short=CORPUS_HASH[:12],legacy_invalid_json=sum(r['totals']['invalid_json_calls'] for r in legacy['diagnostics']),
        legacy_invalid_json_at_limit=sum(r['totals']['invalid_json_with_output_limit'] for r in legacy['diagnostics'])),
      code_sha256=file_sha(__file__),source_sha256=hashes,values=values,evidence=evidence,
      display_policy=dict(minimum_cell=5,range_counts=evidence['cluster_report']['report_ranges'],
        no_cross_era_volume_comparisons=True,named_people='frozen D6 population only',
        model_dependent_findings='withdrawn',private_intermediate=True),
      constants=dict(era_split=CONFIG['era_split'],ner_proxy_threshold=.9,cluster_thresholds=[.88,.9,.92],
        cluster_change_threshold=.05,cluster_population_threshold=.1,d6_documents=20,d6_sources=3,
        minimum_cell=5,synthetic_required=52,synthetic_cases=54,minimum_speech_chars=300,
        model_window_characters=1200,sdsm_alpha=.05,range_is_confidence_interval=False,
        author_threshold=.85,agreement_main=.7,agreement_appendix=.5,repeat_threshold=.95,grounding_failure_limit=.02,
        form_context_limit=3,public_link_limit=1500))
    atomic_json_stable(workdir()/'report_data.json',result)
    print('Complete-corpus report evidence saved; private cells require disclosure-aware rendering.')


if __name__=='__main__':main()
