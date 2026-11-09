"""Full completion evidence, run only after all corpus stages and actual visual QA.

This does not mark the conversation goal complete. The agent must inspect the
audit, the requirement scope, and actual artifacts before making that claim.
"""
import csv,importlib,json,subprocess,sys
from voices_common import *
from report_contract import assemble,sha
from completion_checks import require_visual_review,require_pinned_files,execution_file_contracts,require_document_coverage
from public_exports import safe_alias,public_edges,office_in_period
from aggregate_exports import verify_platform_coverage
atomic_text=importlib.import_module('85_assemble_report').atomic_text


def main():
    base=STUDY/'output/private/report';public=STUDY/'data/public';evidence=[]
    def record(requirement,proof):evidence.append(dict(requirement=requirement,status='verified',evidence=proof))
    def need(condition,message):
        if not condition:raise RuntimeError(message)
    def read(name):
        path=workdir()/name;value=json.loads(path.read_text(encoding='utf-8'))
        need(value.get('corpus_sha256')==CORPUS_HASH and value.get('config_hash')==CONFIG_HASH,'Wrong provenance: '+name)
        return value
    corpus_path=ROOT/MANIFEST['corpus']['path']
    need(corpus_path.is_file() and corpus_path.stat().st_size==MANIFEST['corpus']['bytes'],'Official corpus file missing or size changed')
    need(file_sha(corpus_path)==CORPUS_HASH,'Official corpus file differs from the frozen manifest')
    record('Original official corpus still matches the pinned input',dict(path=str(corpus_path),sha256=CORPUS_HASH,
      rows=MANIFEST['corpus']['rows'],columns=MANIFEST['corpus']['columns']))
    data=read('report_data.json');need(not data.get('synthetic_fixture'),'Constructed data cannot complete the study')
    audit=read('publication_audit.json');gate=read('model_gate_summary.json')
    for source,digest in data['source_sha256'].items():
        need(file_sha(workdir()/source)==digest,'Changed report source: '+source)
        need(data['evidence'][source.removesuffix('.json')]==json.loads((workdir()/source).read_text(encoding='utf-8')),'Embedded evidence differs from source: '+source)
    legacy=data['evidence']['legacy_pilot_diagnosis']
    need(legacy['original_file_sha256']==file_sha(STUDY/'output/private/pilot_diagnosis.json'),'Original pilot diagnostic changed')
    need(data['presentation']['legacy_invalid_json']==sum(r['totals']['invalid_json_calls'] for r in legacy['diagnostics']) and
      data['presentation']['legacy_invalid_json_at_limit']==sum(r['totals']['invalid_json_with_output_limit'] for r in legacy['diagnostics']),
      'Original failure totals do not reconcile')
    need(audit['level_a_identity_gate']=='passed','Identity publication gate incomplete')
    need(not gate['main_authorized'] and not gate['primary_synthetic_pass_exists'],'Use the qualified-model audit route if a configuration changes')
    need(all(x=='withdrawn' for x in gate['publication_levels'].values()),'Model withdrawal not explicit')
    con=connect();total=MANIFEST['corpus']['rows']
    coverage=require_document_coverage(con,
      ['docs','ner_docs','gazetteer_docs','form_docs','resolved_docs','candidate_docs','network_mention_docs'],total)
    need(con.execute("SELECT count(*) FROM ner_docs WHERE status IS DISTINCT FROM 'complete'").fetchone()[0]==0,'Unresolved NER failures')
    need(con.execute('''SELECT count(*) FROM mentions m JOIN docs d USING(doc_id)
      WHERE m.start_char<0 OR m.end_char>length(d.text_clean) OR m.end_char<=m.start_char
         OR substring(d.text_clean,m.start_char+1,m.end_char-m.start_char)<>m.surface''').fetchone()[0]==0,
      'NER spans do not ground in literal corpus text')
    provenance_tables=[]
    for table, in con.execute("SELECT table_name FROM information_schema.tables WHERE table_schema='main' ORDER BY table_name").fetchall():
        columns={r[0] for r in con.execute('SELECT column_name FROM information_schema.columns WHERE table_name=?',[table]).fetchall()}
        if {'corpus_sha256','config_hash'}<=columns:
            safe_table='"'+table.replace('"','""')+'"'
            bad=con.execute('SELECT count(*) FROM '+safe_table+' WHERE corpus_sha256 IS DISTINCT FROM ? OR config_hash IS DISTINCT FROM ?',[CORPUS_HASH,CONFIG_HASH]).fetchone()[0]
            need(bad==0,'Mixed table provenance: '+table);provenance_tables.append(table)
    settings=con.execute('SELECT stage,settings_hash,settings_json FROM stage_settings ORDER BY stage').fetchall()
    for stage,digest,raw in settings:need(hashlib.sha256(raw.encode('utf-8')).hexdigest()==digest,'Damaged stage pin: '+stage)
    pinned_files=require_pinned_files(settings,execution_file_contracts(STUDY,workdir()))
    record('Qualified execution adapters, preserved references and parity proofs match database pins',pinned_files)
    record('S0/S1 complete pinned export, durable settings and literal full-corpus NER',dict(coverage=coverage,provenance_tables=provenance_tables,stage_settings=len(settings)))
    need(con.execute('SELECT count(*) FROM docs JOIN minhash_signatures USING(text_sha256)').fetchone()[0]==total,'Incomplete MinHash coverage')
    need(con.execute('''SELECT count(*) FROM circulation_candidates c ANTI JOIN circulation_pair_checks p ON c.a=p.a AND c.b=p.b''').fetchone()[0]==0,'Pending near-duplicate pairs')
    text_count=con.execute('SELECT count(*) FROM circulation_texts').fetchone()[0]
    for threshold in [.8,.85,.9]:
        need(con.execute('SELECT count(*) FROM circulation_membership WHERE threshold=?',[threshold]).fetchone()[0]==text_count,'Incomplete circulation scenario')
    need(con.execute('SELECT count(*) FROM forms ANTI JOIN form_lemmas USING(form_id)').fetchone()[0]==0,'Missing morphology')
    for threshold in [.88,.9,.92]:
        need(con.execute('SELECT count(*) FROM forms f ANTI JOIN aliases a ON a.form_id=f.form_id AND a.threshold=?',[threshold]).fetchone()[0]==0,'Incomplete name-cluster scenario')
    need(con.execute('''SELECT count(*) FROM candidate_sentences s LEFT JOIN rule_sentence_results r USING(item_id)
      WHERE s.needs_parse AND (r.status IS NULL OR r.status<>'complete')''').fetchone()[0]==0,'Unfinished rule parsing')
    memory_proof=read('rules_memory_safe_parity.json')
    importlib.import_module('rules_memory_safe').validate_proof(memory_proof)
    large=memory_proof['large_sentence']
    saved_large=con.execute('''SELECT parsed_json,statements_json,first_person_signal
      FROM rule_sentence_results WHERE item_id=? AND status='complete' ''',[large['item_id']]).fetchone()
    need(saved_large is not None,'Memory recovery input was not completed')
    encoded=json.dumps([(json.loads(saved_large[0]),json.loads(saved_large[1]),saved_large[2])],
      ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()
    need(hashlib.sha256(encoded).hexdigest()==large['result_sha256'],
      'Committed memory recovery result differs from qualified probe')
    record('Memory recovery input committed exactly as qualified',dict(tokens=large['tokens'],
      result_sha256=large['result_sha256'],qualification_sha256=file_sha(workdir()/'rules_memory_safe_parity.json')))
    need(con.execute('SELECT count(*) FROM candidates ANTI JOIN rule_window_results USING(item_id)').fetchone()[0]==0,'Missing rule windows')
    record('S2/S3 identity, title, candidate and rule coverage plus circulation sensitivity',dict(unique_texts=text_count,
      publication_audit_sha256=file_sha(workdir()/'publication_audit.json'),office_coverage_sha256=file_sha(workdir()/'office_coverage_report.json')))
    # Reconstruct raw model replies anew; do not rely only on an earlier audit's flag.
    checker=importlib.import_module('71_publication_audit')
    need(checker.reconcile_constructed(con,gate)==audit['constructed_database_reconciliation'],'Constructed audit changed')
    need(checker.reconcile_benchmarks(con,gate)==audit['benchmark_database_reconciliation'],'Benchmark audit changed')
    need(all(audit['checks'][key]['status']=='not_run' for key in ['M-AG-1','M-ST-1']),'Actual-passage missing checks must remain explicit')
    need(all(audit['checks'][key]['status']=='not_applicable' for key in ['M-AG-2','M-ROB-1','M-ROB-2']),'Conditional omissions unexplained')
    need(audit['checks']['S6']['status']=='omitted','Optional claim module disposition missing')
    record('S4 retained failures; S5/S6 and model-dependent S7 consequences follow publication policy',
      dict(model_gate_sha256=file_sha(workdir()/'model_gate_summary.json'),configurations=len(gate['configurations']),
        model_findings='withdrawn',actual_agreement_repeatability='not run after failed prerequisite',
        distillation_speech_robustness='not applicable without qualified labels/edges',claims='optional module omitted'))
    fresh=importlib.import_module('80_report_data').collect(con)
    names={p['entity_id']:p['public_name'] for p in data['values']['people']}
    for person in fresh['people']:person['public_name']=names[person['entity_id']]
    need(fresh==data['values'],'Report evidence does not reproduce from the final database')
    allowed=set(names)
    need(con.execute('''SELECT count(*) FROM network_doc_entities n ANTI JOIN
      (SELECT DISTINCT r.doc_id,r.qid AS entity_id FROM resolved_mentions r JOIN network_people p ON p.entity_id=r.qid
       WHERE p.d6 AND r.life_class='contemporary') e USING(doc_id,entity_id)''').fetchone()[0]==0,'Ineligible public network document')
    need(con.execute('''SELECT count(*) FROM
      (SELECT DISTINCT r.doc_id,r.qid AS entity_id FROM resolved_mentions r JOIN network_people p ON p.entity_id=r.qid
       WHERE p.d6 AND r.life_class='contemporary') e ANTI JOIN network_doc_entities n USING(doc_id,entity_id)''').fetchone()[0]==0,'Missing public network document')
    for kind,network in data['evidence']['network_metrics']['networks'].items():
        need({n['entity_id'] for n in network['nodes']}==allowed,'Network nodes differ from frozen D6 people')
        need(all(n['metadata']['level']=='A' for n in [network]),'Wrong network claim level')
    alias_counts=con.execute('''SELECT r.qid,f.surface,count(DISTINCT r.doc_id) FROM resolved_mentions r
      JOIN form_mentions m ON r.doc_id=m.doc_id AND r.start_char=m.start_char AND r.end_char=m.end_char
      JOIN forms f USING(form_id) JOIN form_lemmas l USING(form_id)
      JOIN network_people n ON n.entity_id=r.qid AND n.d6
      WHERE r.origin='ner' AND r.life_class='contemporary' AND l.status='agreed'
      GROUP BY r.qid,f.surface HAVING count(DISTINCT r.doc_id)>=5 ORDER BY r.qid,f.surface''').fetchall()
    expected_aliases=[dict(entity_qid=qid,canonical_name=names[qid],surface_form=surface,documents=str(n))
      for qid,surface,n in alias_counts if safe_alias(surface)]
    con.close()
    record('S7 independently reproducible Level-A descriptions and D6 network population',dict(public_people=len(allowed),report_data_sha256=file_sha(workdir()/'report_data.json')))
    # Reopening the R driver verifies its immutable code/input/package settings;
    # completed RDS graphs are reused rather than inferred from test success.
    env={**os.environ,'LC_ALL':'English_United States.utf8','PYTHONUTF8':'1','DIGIKAT_VOICES_WORKDIR':str(workdir())}
    rscript='C:/Program Files/R/R-4.6.0/bin/Rscript.exe'
    rerun=subprocess.run([rscript,'--vanilla',str(STUDY/'70_networks.R')],cwd=ROOT,env=env,capture_output=True,text=True,encoding='utf-8')
    atomic_text(workdir()/'completion-network-reopen.log',rerun.stdout+'\n'+rerun.stderr)
    need(rerun.returncode==0,'R graph settings/reopen verification failed')
    for name,digest in data['evidence']['network_metrics']['source_sha256'].items():need(file_sha(workdir()/'network_results'/name)==digest,'Changed R graph checkpoint')
    release=json.loads((public/'release_manifest.json').read_text(encoding='utf-8'))
    need(release['report_data_sha256']==file_sha(workdir()/'report_data.json'),'Stale public release')
    for name,entry in release['files'].items():
        path=public/name;need(file_sha(path)==entry['sha256'],'Changed public file: '+name)
        with path.open(encoding='utf-8',newline='') as f:
            reader=csv.DictReader(f);need(reader.fieldnames==entry['columns'],'Changed public schema');rows=list(reader)
        need(len(rows)==entry['rows'],'Wrong public row count')
        if name=='aliases_public.csv':
            need(all(row['entity_qid'] in allowed and int(row['documents'])>=5 and safe_alias(row['surface_form']) for row in rows),'Unsafe public alias')
            need(rows==expected_aliases,'Public alias identities/counts do not reproduce from database')
        elif name.startswith('mention_'):
            kind=name.removeprefix('mention_').removesuffix('_edges.csv')
            expected=public_edges(data['evidence']['network_metrics']['networks'][kind],allowed)
            actual=[dict(from_qid=r['from_qid'],to_qid=r['to_qid'],shared_contexts=int(r['shared_contexts']),
              independent_documents=int(r['independent_documents']) if r['independent_documents'] else None) for r in rows]
            need(actual==expected,'Public edge list differs from disclosure-filtered full evidence')
        elif name=='offices.csv':
            snapshot=read('office_register.json');expected={r['statement_id'] for r in snapshot['offices'] if office_in_period(r)}
            need({r['statement_id'] for r in rows}==expected,'Public dated-office scope differs from source')
            indexed={r['statement_id']:r for r in snapshot['offices']}
            for row in rows:
                original=indexed[row['statement_id']]
                for key in ['entity_qid','name','office_qid','office_label_hr','start_earliest','start_latest','end_earliest','end_latest']:
                    need(row[key]==(original[key] or ''),'Changed public office field: '+key)
        tracked=subprocess.run(['git','ls-files','--error-unmatch','--',str(path.relative_to(ROOT))],cwd=ROOT,capture_output=True,text=True)
        need(tracked.returncode==0,'Plan requires this public byproduct to be tracked: '+name)
    record('Required public offices, aliases and aggregate edge lists',dict(release_manifest_sha256=sha(public/'release_manifest.json'),files=release['files']))
    aggregate=verify_platform_coverage(STUDY/'output/platform_coverage.parquet',data,release['aggregate_parquet'])
    record('Identity-free Parquet platform coverage, exact schema and complementary suppression',aggregate)
    registry_path=base/'report_registry.json';registry=json.loads(registry_path.read_text(encoding='utf-8'))
    regenerated,usage=assemble((STUDY/'REPORT_TEMPLATE.qmd').read_text(encoding='utf-8'),registry,base)
    need((base/'tko-govori-o-vjeri.qmd').read_text(encoding='utf-8')==regenerated,'Report fragments differ from assembled narrative')
    render=json.loads((base/'tko-govori-o-vjeri-render_checks.json').read_text(encoding='utf-8'))
    need(render['registry_sha256']==sha(registry_path) and render['qmd_sha256']==sha(base/'tko-govori-o-vjeri.qmd'),'Stale report render')
    review=json.loads((base/'visual_review.json').read_text(encoding='utf-8'))
    hashes=require_visual_review(render,review,base/'tko-govori-o-vjeri.pdf',base/'tko-govori-o-vjeri.html')
    need(json.loads((base/'claims.json').read_text(encoding='utf-8'))==registry['claims'],'Claims trail differs from registry')
    record('S8 Croatian PDF and HTML, 25–35 pages, all-page visual QA and evidence-linked numbers',dict(pages=render['pages'],**hashes,**usage))
    for name,command,cwd in [('python-tests',[sys.executable,'-m','unittest','discover','-p','test_*.py'],STUDY),
      ('disclosure',[rscript,'--vanilla',str(ROOT/'R/check_disclosure.R')],ROOT)]:
        result=subprocess.run(command,cwd=cwd,env=env,capture_output=True,text=True,encoding='utf-8')
        log=workdir()/('completion-'+name+'.log');atomic_text(log,result.stdout+'\n'+result.stderr)
        need(result.returncode==0,'Final '+name+' verification failed')
        record(name,dict(log_sha256=file_sha(log),exit_code=result.returncode))
    record('Optional site publication',dict(status='not performed',reason='Plan requires a separate PI decision after read-through; no site publication was requested.'))
    result=dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      plan_sha256=file_sha(ROOT/'quality_reports/plans/2026-10-25_catholic-voices-network-machine-only.md'),
      code_sha256=file_sha(__file__),requirements=evidence,all_required_evidence_verified=True,
      note='The agent must still inspect this evidence against the original scope before marking the conversational goal complete.')
    atomic_json(workdir()/'completion_audit.json',result);atomic_json(base/'study_completion.json',result)
    print('Completion evidence verified and saved; inspect the requirement record before claiming completion.')


if __name__=='__main__':main()
