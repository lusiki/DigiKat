"""Bounded repair run; all original pilot tables are preserved."""
import argparse,concurrent.futures,importlib,json,time
import requests
from voices_common import *
from repair_protocol import PROMPT,prepare,schema,validate,expand
old=importlib.import_module('03_pilot_llm')

def call(model,row):
    item,text,author,mentions=row;bundle=prepare(text,author,json.loads(mentions));start=time.perf_counter()
    reply=requests.post(old.ENDPOINT+'/api/generate',json=dict(model=model,system=PROMPT,
      prompt=json.dumps(bundle,ensure_ascii=False),format=schema(bundle),think=False,stream=False,
      keep_alive='10m',options=dict(num_ctx=4096,num_predict=1536,temperature=0,seed=CONFIG['seed'])),timeout=(10,240))
    reply.raise_for_status();payload=reply.json();value,errors=validate(payload.get('response',''),bundle)
    if payload.get('done_reason')!='stop':errors.append('unfinished')
    return item,time.perf_counter()-start,payload,errors,expand(value,bundle) if not errors else []

def main():
    p=argparse.ArgumentParser();p.add_argument('--limit',type=int,default=32);p.add_argument('--model',default='qwen3:8b');args=p.parse_args()
    con=connect()
    pin_stage(con,'coder_repair_v2_'+args.model.replace(':','_'),dict(protocol=file_sha(STUDY/'repair_protocol.py'),
      code=file_sha(__file__),model=args.model,num_ctx=4096,num_predict=1536,seed=CONFIG['seed']))
    con.execute('''CREATE TABLE IF NOT EXISTS repair_calls (model VARCHAR,item_id VARCHAR,seconds DOUBLE,
      raw_json VARCHAR,errors_json VARCHAR,expanded_json VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,
      PRIMARY KEY(model,item_id))''')
    selected=con.execute('''SELECT w.item_id,w.text,w.author,w.mentions_json FROM pilot_llm_sample s
      JOIN pilot_window_candidates w USING(item_id) ORDER BY sha256(w.item_id || ?) LIMIT ?''',
      [str(CONFIG['seed'])+'repair',args.limit]).fetchall()
    done={r[0] for r in con.execute('SELECT item_id FROM repair_calls WHERE model=?',[args.model]).fetchall()}
    pending=[r for r in selected if r[0] not in done]
    if pending:
        with gpu_lock(),old.server():
            digest=old.model_digest(args.model)
            pin_stage(con,'coder_repair_model_'+args.model.replace(':','_'),dict(digest=digest))
            with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
                for offset in range(0,len(pending),4):
                    started=time.perf_counter()
                    futures=[pool.submit(call,args.model,row) for row in pending[offset:offset+4]]
                    for future in concurrent.futures.as_completed(futures):
                        item,seconds,payload,errors,expanded=future.result()
                        with transaction(con):
                            con.execute('INSERT INTO repair_calls VALUES (?,?,?,?,?,?,?,?,?)',
                              [args.model,item,seconds,json.dumps(payload,ensure_ascii=False),json.dumps(errors),
                               json.dumps(expanded,ensure_ascii=False),CORPUS_HASH,CONFIG_HASH,utc()])
                    con.execute('CHECKPOINT');print(f'{utc()} repair {args.model} {offset+len(futures)}/{len(pending)} saved; batch {time.perf_counter()-started:.1f}s',flush=True)
            requests.post(old.ENDPOINT+'/api/generate',json={'model':args.model,'keep_alive':0},timeout=60).raise_for_status()
    rows=con.execute('SELECT errors_json,raw_json FROM repair_calls WHERE model=?',[args.model]).fetchall()
    errors=[json.loads(e) for e,_ in rows]
    atomic_json(workdir()/('repair_'+args.model.replace(':','_')+'.json'),dict(created_utc=utc(),
      corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,n=len(rows),mechanically_accepted=sum(not e for e in errors),
      unfinished=sum('unfinished' in e for e in errors),json_failures=sum('json' in e for e in errors),
      semantic_validation='pending synthetic suite and cross-model checks; selecting valid IDs is not evidence of correctness'))
    con.close()

if __name__=='__main__':main()
