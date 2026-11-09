"""Shared resumable local inference engine; raw replies commit individually.

Transport failures have a separate journal and remain pending on restart. They
are not semantic/model failures. A received mechanically invalid reply gets at
most one configured retry. The GPU/server are owned only inside this function.
"""
import concurrent.futures,hashlib,importlib,json,time
import requests
from voices_common import *
from agreement_metrics import bundle_slots
from active_protocol import VERSION,protocol
validation=importlib.import_module('40_validate_coder')

def tables(con):
    con.execute('''CREATE TABLE IF NOT EXISTS llm_calls (run VARCHAR,model VARCHAR,item_id VARCHAR,
      replicate INTEGER,attempt INTEGER,seconds DOUBLE,raw_json VARCHAR,errors_json VARCHAR,expanded_json VARCHAR,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(run,model,item_id,replicate,attempt))''')
    con.execute('''CREATE TABLE IF NOT EXISTS llm_transport_errors (run VARCHAR,model VARCHAR,item_id VARCHAR,
      replicate INTEGER,attempt INTEGER,error_json VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    con.execute('''CREATE TABLE IF NOT EXISTS llm_batches (run VARCHAR,model VARCHAR,replicate INTEGER,
      batch_id VARCHAR,seconds DOUBLE,responses INTEGER,transport_failures INTEGER,corpus_sha256 VARCHAR,
      config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(run,model,replicate,batch_id))''')

def final_results(con,run,model,replicate=0):
    return {item:dict(attempt=attempt,errors=json.loads(errors),rows=json.loads(rows)) for item,attempt,errors,rows in
      con.execute('''SELECT item_id,attempt,errors_json,expanded_json FROM llm_calls
      WHERE run=? AND model=? AND replicate=? QUALIFY row_number() OVER (PARTITION BY item_id ORDER BY attempt DESC)=1''',
      [run,model,replicate]).fetchall()}

def safe_call(model,bundle,attempt):
    try:return validation.call(model,bundle,attempt)
    except requests.RequestException as exc:
        return dict(transport=dict(type=type(exc).__name__,message=str(exc),
          response_body=exc.response.text[:1500] if exc.response is not None else None))

def run_model(con,run,model,rows,replicate=0):
    """rows: item_id, text, author, author_qid, mentions_json (immutable source)."""
    tables(con)
    selection_hash=hashlib.sha256('\n'.join(sorted(r[0] for r in rows)).encode()).hexdigest()
    stage=f'{run}_{model.replace(":","_")}_rep{replicate}'
    pin_stage(con,stage,dict(engine=file_sha(__file__),call=file_sha(STUDY/'40_validate_coder.py'),
      protocol=file_sha(protocol.__file__),strict_parent=file_sha(STUDY/'coder_protocol_v3.py'),
      inherited=file_sha(STUDY/'repair_protocol.py'),version=VERSION,
      mapping=file_sha(STUDY/'agreement_metrics.py'),selection_hash=selection_hash,
      model=model,replicate=replicate,num_ctx=4096,num_predict=1536,seed=CONFIG['seed'],parallel=4))
    saved=final_results(con,run,model,replicate);todo=[]
    for item,text,author,author_qid,raw in rows:
        old=saved.get(item)
        if old and (not old['errors'] or old['attempt']==1):continue
        bundle,mapping=bundle_slots(text,author,author_qid,json.loads(raw))
        todo.append((item,bundle,mapping,0 if old is None else 1))
    if not todo:return
    with gpu_lock(),validation.old.server():
        runtime=validation.runtime(model)
        # Assert the backend/model still match the constructed suite.
        pin_stage(con,'synthetic_'+VERSION+'_'+model.replace(':','_')+'_model',runtime)
        pin_stage(con,stage+'_runtime',runtime)
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            while todo:
                batch=todo[:4];todo=todo[4:];batch_id=utc();started=time.perf_counter();responses=0;transport=0
                futures={pool.submit(safe_call,model,bundle,attempt):(item,bundle,mapping,attempt)
                         for item,bundle,mapping,attempt in batch}
                for future in concurrent.futures.as_completed(futures):
                    item,bundle,mapping,attempt=futures[future];result=future.result()
                    if 'transport' in result:
                        with transaction(con):con.execute('INSERT INTO llm_transport_errors VALUES (?,?,?,?,?,?,?,?,?)',
                          [run,model,item,replicate,attempt,json.dumps(result['transport']),CORPUS_HASH,CONFIG_HASH,utc()])
                        transport+=1;continue
                    surfaces={c['surface']:mapping[c['id']] for c in bundle['candidates']}
                    for row in result['expanded']:
                        row['entity_slot']=mapping[row['candidate_id']]
                        row['relation']['target_slot']=surfaces.get(row['relation']['target_surface'])
                    result['payload']['study_batch_id']=batch_id
                    with transaction(con):con.execute('INSERT INTO llm_calls VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',
                      [run,model,item,replicate,attempt,result['seconds'],json.dumps(result['payload'],ensure_ascii=False),
                       json.dumps(result['errors']),json.dumps(result['expanded'],ensure_ascii=False),CORPUS_HASH,CONFIG_HASH,utc()])
                    saved[item]=dict(attempt=attempt,errors=result['errors'],rows=result['expanded']);responses+=1
                    if result['errors'] and attempt==0:todo.append((item,bundle,mapping,1))
                con.execute('CHECKPOINT')
                con.execute('INSERT INTO llm_batches VALUES (?,?,?,?,?,?,?,?,?,?)',
                  [run,model,replicate,batch_id,time.perf_counter()-started,responses,transport,CORPUS_HASH,CONFIG_HASH,utc()])
                atomic_json(workdir()/(run+'_progress.json'),dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
                  config_hash=CONFIG_HASH,model=model,replicate=replicate,selected=len(rows),completed=len(saved),
                  failed_after_retry=sum(bool(r['errors']) and r['attempt']==1 for r in saved.values()),
                  transport_failures_this_batch=transport,pending_attempts=len(todo)))
                print(utc(),run,model,'replicate',replicate,len(saved),'/',len(rows),'saved;',len(todo),'attempts pending',flush=True)
                if transport:raise RuntimeError('Local model transport failed; received replies are saved and missing requests remain resumable')
        requests.post(validation.old.ENDPOINT+'/api/generate',json=dict(model=model,keep_alive=0),timeout=60).raise_for_status()

def call_quality(con,run,model,replicate=0):
    errors=[json.loads(r[0]) for r in con.execute('SELECT errors_json FROM llm_calls WHERE run=? AND model=? AND replicate=?',[run,model,replicate]).fetchall()]
    counts={e:sum(e in row for row in errors) for e in sorted({e for row in errors for e in row})}
    return dict(received_calls=len(errors),mechanically_failed_calls=sum(bool(e) for e in errors),
      grounding_failure_share=sum(bool(e) for e in errors)/len(errors) if errors else None,error_categories=counts,
      transport_errors=con.execute('SELECT count(*) FROM llm_transport_errors WHERE run=? AND model=? AND replicate=?',[run,model,replicate]).fetchone()[0])
