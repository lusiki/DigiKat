"""Repeat the frozen 300-window throughput benchmark with strict source IDs."""
import argparse,concurrent.futures,importlib,json,time
import requests
from voices_common import *
from active_protocol import VERSION,protocol
validation=importlib.import_module('40_validate_coder')
old=validation.old

def main():
    p=argparse.ArgumentParser();p.add_argument('--model',default='qwen3:14b');args=p.parse_args()
    con=connect();run='benchmark_'+VERSION+'_'+args.model.replace(':','_')
    pin_stage(con,run,dict(code=file_sha(__file__),call_code=file_sha(STUDY/'40_validate_coder.py'),
      protocol=file_sha(protocol.__file__),strict_parent=file_sha(STUDY/'coder_protocol_v3.py'),inherited=file_sha(STUDY/'repair_protocol.py'),version=VERSION,
      model=args.model,seed=CONFIG['seed'],num_ctx=4096,num_predict=1536,parallel=4))
    con.execute('''CREATE TABLE IF NOT EXISTS coder_check_calls
      (run VARCHAR,item_id VARCHAR,attempt INTEGER,response_json VARCHAR,
       corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(run,item_id,attempt))''')
    con.execute('''CREATE TABLE IF NOT EXISTS coder_check_batches (run VARCHAR,batch_id VARCHAR,seconds DOUBLE,
      calls INTEGER,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(run,batch_id))''')
    rows=con.execute('''SELECT w.item_id,w.text,w.author,w.mentions_json FROM pilot_llm_sample s
      JOIN pilot_window_candidates w USING(item_id) ORDER BY w.item_id''').fetchall()
    assert len(rows)==300
    saved={item:{'attempt':attempt,**json.loads(raw)} for item,attempt,raw in con.execute(
      'SELECT item_id,attempt,response_json FROM coder_check_calls WHERE run=? ORDER BY attempt',[run]).fetchall()}
    todo=[(item,protocol.prepare(text,author,json.loads(mentions)),0 if item not in saved else 1)
          for item,text,author,mentions in rows if item not in saved or (saved[item]['errors'] and saved[item]['attempt']==0)]
    if todo:
        with gpu_lock(),old.server():
            pin_stage(con,run+'_model',validation.runtime(args.model))
            with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
                while todo:
                    batch=todo[:4];todo=todo[4:];started=time.perf_counter();results=[]
                    futures={pool.submit(validation.call,args.model,bundle,attempt):(item,bundle,attempt) for item,bundle,attempt in batch}
                    for future in concurrent.futures.as_completed(futures):
                        item,bundle,attempt=futures[future];result=future.result();results.append((item,attempt,result))
                        # Keep the raw attempt even if another concurrent request fails.
                        with transaction(con):con.execute('INSERT INTO coder_check_calls VALUES (?,?,?,?,?,?,?)',
                          [run,item,attempt,json.dumps(result,ensure_ascii=False),CORPUS_HASH,CONFIG_HASH,utc()])
                        saved[item]={'attempt':attempt,**result}
                        if result['errors'] and attempt==0:todo.append((item,bundle,1))
                    con.execute('CHECKPOINT')
                    con.execute('INSERT INTO coder_check_batches VALUES (?,?,?,?,?,?,?)',
                      [run,utc(),time.perf_counter()-started,len(results),CORPUS_HASH,CONFIG_HASH,utc()])
                    print(utc(),run,len(saved),'/300 saved;',len(todo),'pending attempts',flush=True)
            requests.post(old.ENDPOINT+'/api/generate',json=dict(model=args.model,keep_alive=0),timeout=60).raise_for_status()
    calls=[(attempt,json.loads(raw)) for attempt,raw in con.execute('SELECT attempt,response_json FROM coder_check_calls WHERE run=?',[run]).fetchall()]
    first=[r for a,r in calls if a==0]
    def valid_json(r):
        try:json.loads(r['payload'].get('response',''));return True
        except (ValueError,TypeError):return False
    timing=con.execute('SELECT coalesce(sum(seconds),0),coalesce(sum(calls),0) FROM coder_check_batches WHERE run=?',[run]).fetchone()
    # Interrupted batches can have saved calls without timing: throughput then stays unverified.
    valid_rate=sum(valid_json(r) for r in first)/len(first)
    timing_complete=timing[1]==len(calls)
    seconds=timing[0]/300 if timing_complete else None
    report=dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,model=args.model,n=300,
      completed=len(saved),calls=len(calls),json_valid_first=valid_rate,
      mechanically_accepted_first=sum(not r['errors'] for r in first)/len(first),
      final_failed=sum(bool(r['errors']) for r in saved.values()),
      unfinished=sum('unfinished' in r['errors'] for _,r in calls),
      effective_seconds_per_window=seconds,timing_complete=timing_complete,
      throughput_gate_passed=bool(len(saved)==300 and valid_rate>=.97 and seconds is not None and seconds<=4),
      main_authorized=False,semantic_accuracy='unmeasured; constructed and agreement gates separate')
    atomic_json(workdir()/(run+'_report.json'),report);print(json.dumps(report));con.close()

if __name__=='__main__':main()
