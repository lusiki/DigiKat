"""Resumable constructed semantic gate, before any main-run authorization.

Uses the common GPU lock; must run after CLASSLA exits. Each raw attempt and
mechanical outcome is durable. Retry only mechanical failures, never a case
merely because the semantic answer does not match the constructed expectation.
"""
import argparse,concurrent.futures,importlib,json,time
import requests
from voices_common import *
from active_protocol import VERSION,protocol
from synthetic_suite import fixtures,windows,assess
old=importlib.import_module('03_pilot_llm')

def runtime(model):
    response=requests.get(old.ENDPOINT+'/api/version',timeout=15);response.raise_for_status()
    return dict(digest=old.model_digest(model),ollama_version=response.json()['version'])

def call(model,bundle,attempt):
    start=time.perf_counter()
    request=dict(model=model,system=protocol.PROMPT,
      prompt=json.dumps(bundle,ensure_ascii=False),format=protocol.schema(bundle),think=False,
      stream=False,keep_alive='10m',options=dict(num_ctx=4096,num_predict=1536,
      temperature=0 if attempt==0 else .2,seed=CONFIG['seed']))
    if not model.startswith('qwen3:'):request.pop('think')
    r=requests.post(old.ENDPOINT+'/api/generate',json=request,timeout=(10,240))
    r.raise_for_status();payload=r.json();value,errors=protocol.validate(payload.get('response',''),bundle)
    if payload.get('done_reason')!='stop':errors.append('unfinished')
    return dict(seconds=time.perf_counter()-start,payload=payload,errors=errors,
                expanded=protocol.expand(value,bundle) if not errors else [])

def main():
    p=argparse.ArgumentParser();p.add_argument('--model',default='qwen3:14b');args=p.parse_args()
    con=connect();cases=fixtures()
    encoded=json.dumps(cases,sort_keys=True,ensure_ascii=False)
    import hashlib
    suite_hash=hashlib.sha256(encoded.encode()).hexdigest()
    run='synthetic_'+VERSION+'_'+args.model.replace(':','_')
    pin_stage(con,run,dict(code=file_sha(__file__),protocol=file_sha(protocol.__file__),version=VERSION,
      strict_parent=file_sha(STUDY/'coder_protocol_v3.py'),
      inherited_protocol=file_sha(STUDY/'repair_protocol.py'),suite=file_sha(STUDY/'synthetic_suite.py'),
      suite_hash=suite_hash,num_ctx=4096,num_predict=1536,model=args.model,seed=CONFIG['seed']))
    con.execute('''CREATE TABLE IF NOT EXISTS coder_check_calls
      (run VARCHAR,item_id VARCHAR,attempt INTEGER,response_json VARCHAR,
       corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(run,item_id,attempt))''')
    atomic_json(workdir()/(run+'_inputs.json'),dict(suite_hash=suite_hash,cases=cases))
    pending=[]
    for case in cases:
        for i,text in enumerate(windows(case)):
            item=case['id']+'_'+str(i)
            bundle=protocol.prepare(text,case['author'],[dict(surface=n) for n in case['names']])
            pending.append((item,bundle))
    saved={item:{'attempt':attempt,**json.loads(raw)} for item,attempt,raw in con.execute(
      'SELECT item_id,attempt,response_json FROM coder_check_calls WHERE run=? ORDER BY attempt',[run]).fetchall()}
    todo=[(item,bundle,0 if item not in saved else 1) for item,bundle in pending
          if item not in saved or (saved[item]['errors'] and saved[item]['attempt']==0)]
    if todo:
        with gpu_lock(),old.server():
            pin_stage(con,run+'_model',runtime(args.model))
            with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
                while todo:
                    batch=todo[:4];todo=todo[4:]
                    jobs={pool.submit(call,args.model,bundle,attempt):(item,bundle,attempt) for item,bundle,attempt in batch}
                    for future in concurrent.futures.as_completed(jobs):
                        item,bundle,attempt=jobs[future];result=future.result()
                        with transaction(con):con.execute('INSERT INTO coder_check_calls VALUES (?,?,?,?,?,?,?)',
                          [run,item,attempt,json.dumps(result,ensure_ascii=False),CORPUS_HASH,CONFIG_HASH,utc()])
                        saved[item]={'attempt':attempt,**result}
                        if result['errors'] and attempt==0:todo.append((item,bundle,1))
                    con.execute('CHECKPOINT')
                    print(utc(),run,len(saved),'windows saved;',len(todo),'pending attempts',flush=True)
            requests.post(old.ENDPOINT+'/api/generate',json=dict(model=args.model,keep_alive=0),timeout=60).raise_for_status()
    checks=[]
    for case in cases:
        items=[saved.get(case['id']+'_'+str(i)) for i,_ in enumerate(windows(case))]
        rows=[r for item in items if item and not item['errors'] for r in item['expanded']]
        failures=assess(case,rows)
        if any(not item or item['errors'] for item in items):failures.append('mechanical_failure')
        checks.append(dict(id=case['id'],case=case['case'],failures=failures,passed=not failures))
    n_pass=sum(c['passed'] for c in checks)
    atomic_json(workdir()/(run+'_report.json'),dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,suite_hash=suite_hash,model=args.model,n=54,passed=n_pass,
      synthetic_gate_passed=n_pass>=52,main_authorized=False,checks=checks,
      caveat='Constructed passage checks only. Legacy role/group/completeness fields outside the new schema are not scored. Historical/sacred exclusions require the separate identity checks. Cross-model, grounding and determinism gates are still required.'))
    con.close()
    print(f'{n_pass}/54 constructed passage checks passed. Main run remains gated.',flush=True)

if __name__=='__main__':main()
