"""Reconcile database evidence before the withdrawn-model, Level-A report route."""
import collections,importlib,json,math
from voices_common import *
from office_register import read_cache
from wikidata_identity import person_facts
from synthetic_suite import fixtures,windows,assess
from publication_audit import death_status,withdrawn_checks


def reconcile_constructed(con,gate):
    output=[]
    for config in gate['configurations']:
        protocol=importlib.import_module('coder_protocol_'+config['protocol'])
        run='synthetic_'+config['protocol']+'_'+config['model'].replace(':','_')
        saved={};calls=0
        for item,attempt,raw,corpus,settings in con.execute('''SELECT item_id,attempt,response_json,corpus_sha256,config_hash
          FROM coder_check_calls WHERE run=? ORDER BY attempt''',[run]).fetchall():
            if corpus!=CORPUS_HASH or settings!=CONFIG_HASH:raise RuntimeError('Mixed provenance in constructed calls')
            saved[item]=json.loads(raw);calls+=1
        checks=[]
        for case in fixtures():
            rows=[];mechanical=False
            for i,text in enumerate(windows(case)):
                item=case['id']+'_'+str(i)
                if item not in saved:raise RuntimeError('Missing persisted constructed response: '+run+'/'+item)
                result=saved[item];bundle=protocol.prepare(text,case['author'],[dict(surface=n) for n in case['names']])
                value,errors=protocol.validate(result['payload'].get('response',''),bundle)
                if result['payload'].get('done_reason')!='stop':errors.append('unfinished')
                expanded=protocol.expand(value,bundle) if not errors else []
                if errors!=result['errors'] or expanded!=result['expanded']:raise RuntimeError('Raw response reconstruction mismatch: '+run+'/'+item)
                mechanical=mechanical or bool(errors);rows.extend(expanded)
            failures=assess(case,rows)
            if mechanical:failures.append('mechanical_failure')
            checks.append(dict(id=case['id'],case=case['case'],failures=failures,passed=not failures))
        recorded=json.loads((workdir()/config['source']).read_text(encoding='utf-8'))
        if checks!=recorded['checks']:raise RuntimeError('Constructed report differs from database responses: '+run)
        output.append(dict(run=run,received_calls=calls,final_windows=len(saved),cases=len(checks),passed=sum(c['passed'] for c in checks)))
    return output


def reconcile_benchmarks(con,gate):
    output=[]
    for config in gate['configurations']:
        if not config['benchmark']:continue
        protocol=importlib.import_module('coder_protocol_'+config['protocol'])
        run='benchmark_'+config['protocol']+'_'+config['model'].replace(':','_')
        bundles={item:protocol.prepare(text,author,json.loads(mentions)) for item,text,author,mentions in con.execute('''
          SELECT w.item_id,w.text,w.author,w.mentions_json FROM pilot_llm_sample s
          JOIN pilot_window_candidates w USING(item_id)''').fetchall()}
        first=[];final={};failures=0;unfinished=0;error_counts=collections.Counter();calls=0
        for item,attempt,raw,corpus,settings in con.execute('''SELECT item_id,attempt,response_json,corpus_sha256,config_hash
          FROM coder_check_calls WHERE run=? ORDER BY attempt''',[run]).fetchall():
            if corpus!=CORPUS_HASH or settings!=CONFIG_HASH:raise RuntimeError('Mixed benchmark call provenance')
            result=json.loads(raw);payload=result['payload'];calls+=1
            value,errors=protocol.validate(payload.get('response',''),bundles[item])
            if payload.get('done_reason')!='stop':errors.append('unfinished')
            expanded=protocol.expand(value,bundles[item]) if not errors else []
            if errors!=result['errors'] or expanded!=result['expanded']:raise RuntimeError('Benchmark raw reconstruction mismatch')
            try:json.loads(payload.get('response',''));valid=True
            except (TypeError,ValueError):valid=False
            if attempt==0:first.append((valid,not errors))
            final[item]=bool(errors);failures+=bool(errors);unfinished+='unfinished' in errors
            error_counts.update(set(errors))
        recorded=config['benchmark']
        actual=dict(n=len(bundles),completed=len(final),calls=calls,json_valid_first=sum(x[0] for x in first)/len(first),
          mechanically_accepted_first=sum(x[1] for x in first)/len(first),final_failed=sum(final.values()),unfinished=unfinished)
        for key,value in actual.items():
            if value!=recorded[key]:raise RuntimeError('Benchmark summary differs from database: '+run+'/'+key)
        seconds,ncalls=con.execute('SELECT sum(seconds),sum(calls) FROM coder_check_batches WHERE run=?',[run]).fetchone()
        if ncalls!=calls or not math.isclose(seconds/len(bundles),recorded['effective_seconds_per_window'],rel_tol=1e-12):
            raise RuntimeError('Benchmark batch timing not reconciled')
        output.append(dict(run=run,model=config['model'],calls=calls,mechanical_failures=failures,
          mechanical_failure_share=failures/calls,over_two_percent=failures/calls>.02,error_counts=dict(error_counts),
          final_failed_windows=sum(final.values()),caveat='Combined mechanical failures include schema, source-ID and logical constraints. This conservative gate is not semantic accuracy.'))
    return output


def main():
    con=connect();sources={}
    def read(name):
        path=workdir()/name;value=json.loads(path.read_text(encoding='utf-8'))
        if value.get('corpus_sha256')!=CORPUS_HASH or value.get('config_hash')!=CONFIG_HASH:raise RuntimeError('Mixed report provenance: '+name)
        sources[name]=file_sha(path);return value
    gate=read('model_gate_summary.json');checks=withdrawn_checks(gate)
    for name,digest in gate['source_sha256'].items():
        if file_sha(workdir()/name)!=digest:raise RuntimeError('Changed model evidence: '+name)
    rules=read('speech_rule_report.json');identity=read('identity_resolution_report.json')
    gazetteer=read('gazetteer_report.json');clusters=read('cluster_report.json')
    for table in ['ner_docs','resolved_docs','candidate_docs','gazetteer_docs']:
        if con.execute('SELECT count(*) FROM '+table).fetchone()[0]!=MANIFEST['corpus']['rows']:raise RuntimeError('Incomplete '+table)
    missing=con.execute('''SELECT count(*) FROM candidate_sentences s LEFT JOIN rule_sentence_results r USING(item_id)
      WHERE s.needs_parse AND (r.status IS NULL OR r.status<>'complete')''').fetchone()[0]
    if missing or rules['parse_failures']:raise RuntimeError('Unresolved rule parse failures or pending sentences')
    reconciled=reconcile_constructed(con,gate)
    benchmarks=reconcile_benchmarks(con,gate)
    for code in ['M-GR-1','M-GR-2','M-GR-3','M-GR-4']:
        checks[code]=dict(status='complete',runs=benchmarks,
          caveat='Strict schema and supplied candidate/evidence IDs jointly enforce mechanical source grounding. Combined failures are reported, not independent semantic pass rates.')
    public,_,_=read_cache(workdir()/'public_register_cache')
    facts={qid:[person_facts(entity)] for qid,entity in public.items()}
    for qid,raw in con.execute('SELECT qid,facts_json FROM entity_links WHERE qid IS NOT NULL').fetchall():facts.setdefault(qid,[]).append(json.loads(raw))
    death_counts=collections.Counter();direct=0
    cursor=con.execute('''SELECT d.date,r.statements_json FROM rule_sentence_results r
      JOIN candidate_sentences s USING(item_id) JOIN docs d USING(doc_id) WHERE r.status='complete' ''')
    while rows:=cursor.fetchmany(5000):
        for date,raw in rows:
            for statement in json.loads(raw):
                if statement['mode']!='direct':continue
                direct+=1;death_counts[death_status(facts.get(statement['entity_id'],[]),date)]+=1
    violations=death_counts['after_recorded_death']
    death_check=dict(status='complete',direct_statements=direct,counts=dict(death_counts),violations=violations,
      violation_share=violations/direct if direct else None,rework_required=bool(direct and violations/direct>.01),
      caveat='Conditional rule-tier consistency after historical identities were excluded upstream. No death claim is not proof of survival; absent statements do not validate attribution.')
    papal_n=con.execute('''SELECT count(*) FROM title_mentions WHERE status='resolved' AND contains(offices_json,'"Q19546"')''').fetchone()[0]
    checks['M-ID-1']=dict(status='complete',resolved_papal_titles=papal_n,violations=identity['papal_title_date_violations'])
    checks['M-ID-2']=death_check
    checks['M-ID-3']=dict(status='complete',top_entities=clusters['top_entities'],shifted=clusters['shifted_over_five_percent'],report_ranges=clusters['report_ranges'])
    checks['M-ID-4']=dict(status='exported_unscored',pairs=len(json.loads((workdir()/'cluster_pairs_private.json').read_text(encoding='utf-8'))),reason='Private inspection sample; no human scoring performed.')
    checks['M-REC-1']=dict(status='complete',platforms=gazetteer['platforms'])
    checks['M-SP-1']=dict(status='complete',platforms=rules['author_recovery'],caveat='Conditional mechanical recovery; never empirical accuracy. Platforms without eligible linked AUTHOR cases have no estimate.')
    for code,check in checks.items():check['check_id']=code
    blocked=bool(identity['papal_title_date_violations'] or death_check['rework_required'])
    result=dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,source_sha256=sources,
      code_sha256=file_sha(__file__),audit_rules_sha256=file_sha(STUDY/'publication_audit.py'),
      constructed_database_reconciliation=reconciled,benchmark_database_reconciliation=benchmarks,checks=checks,
      level_a_identity_gate='blocked' if blocked else 'passed',
      level_b='withdrawn',level_c_model_fields='withdrawn',
      publication_note='Level-A artifacts still require complete networks, disclosure checks and verified report rendering. This audit alone is not study completion.')
    atomic_json_stable(workdir()/'publication_audit.json',result);con.close()
    if blocked:raise RuntimeError('Identity audit requires correction before publication')
    print('Database-backed publication audit saved; evaluated model-dependent fields remain withdrawn.')


if __name__=='__main__':main()
