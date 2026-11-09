"""Paired 300-window single/four-request Ollama benchmark, locally served and durable."""
import argparse, concurrent.futures, importlib.metadata, json, shutil, subprocess, time, uuid
import requests
from voices_common import *
from llm_protocol import SCHEMA,PROMPT,gates

ENDPOINT='http://127.0.0.1:11435'

@contextlib.contextmanager
def server():
    # A separate loopback server ensures PARALLEL=4 without changing the user's Ollama service.
    try:
        requests.get(ENDPOINT+'/api/version',timeout=2)
    except requests.ConnectionError:pass
    else:raise RuntimeError('Port 11435 is occupied; do not replace another service')
    ensure_ollama_idle()
    env=os.environ.copy();env.update(OLLAMA_HOST='127.0.0.1:11435',OLLAMA_NUM_PARALLEL='4',
        OLLAMA_MAX_LOADED_MODELS='1',OLLAMA_CONTEXT_LENGTH='2048',OLLAMA_NO_CLOUD='1')
    log=workdir()/('ollama-pilot-'+datetime.now().strftime('%Y%m%d-%H%M%S')+'.log')
    with log.open('ab') as handle:
        proc=subprocess.Popen([shutil.which('ollama'),'serve'],env=env,stdout=handle,stderr=handle,
          creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            for _ in range(60):
                if proc.poll() is not None:raise RuntimeError('Dedicated Ollama server exited')
                try:
                    r=requests.get(ENDPOINT+'/api/version',timeout=2);r.raise_for_status();break
                except requests.RequestException:time.sleep(1)
            else:raise RuntimeError('Ollama server startup timeout')
            yield
        finally:
            proc.terminate()
            try:proc.wait(timeout=15)
            except subprocess.TimeoutExpired:proc.kill();proc.wait()

def model_digest(model):
    models=requests.get(ENDPOINT+'/api/tags',timeout=15).json()['models']
    return next((m['digest'] for m in models if m['name']==model),None)

def call_once(model,row,temperature):
    item_id,text,author=row
    started=time.perf_counter();payload={};error=None
    try:
        r=requests.post(ENDPOINT+'/api/generate',json=dict(model=model,system=PROMPT,
            prompt=json.dumps({'AUTHOR':author,'PASSAGE':text},ensure_ascii=False),format=SCHEMA,
            think=False,stream=False,keep_alive='10m',
            options=dict(num_ctx=2048,num_predict=768,temperature=temperature,seed=CONFIG['seed'])),timeout=(10,240))
        r.raise_for_status();payload=r.json()
    except Exception as exc:error=type(exc).__name__
    check=gates(payload.get('response',''),text,author)
    # Truncation is a processing failure even if a JSON fragment happens to parse.
    check['finished']=payload.get('done') is True and payload.get('done_reason')=='stop'
    check['accepted']=check['grounded'] and check['finished'] and error is None
    return dict(item_id=item_id,seconds=time.perf_counter()-started,payload=payload,check=check,error=error)

def save(con,model,mode,batch_id,result,attempt):
    with transaction(con):
        con.execute('INSERT INTO pilot_llm_calls VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)',
          [str(uuid.uuid4()),model,mode,result['item_id'],attempt,batch_id,result['seconds'],
           json.dumps(result['payload'],ensure_ascii=False),json.dumps(result['check']),result['error'],CORPUS_HASH,CONFIG_HASH,utc()])
        if result['check']['accepted'] or attempt==2:
            con.execute('INSERT INTO pilot_llm_results VALUES (?,?,?,?,?,?,?,?)',
              [model,mode,result['item_id'],'complete' if result['check']['accepted'] else 'task_failed',
               json.dumps(result['payload'],ensure_ascii=False),CORPUS_HASH,CONFIG_HASH,utc()])

def report(con):
    results=[]
    for model,mode in con.execute('SELECT DISTINCT model,mode FROM pilot_llm_calls ORDER BY model,mode').fetchall():
        calls=con.execute('SELECT attempt,checks_json FROM pilot_llm_calls WHERE model=? AND mode=?',[model,mode]).fetchall()
        first=[json.loads(c) for a,c in calls if a==1]
        complete,failed=con.execute("SELECT count(*),count(*) FILTER (WHERE status='task_failed') FROM pilot_llm_results WHERE model=? AND mode=?",[model,mode]).fetchone()
        timing=con.execute('SELECT coalesce(sum(wall_seconds),0),coalesce(sum(items),0) FROM pilot_llm_timing WHERE model=? AND mode=?',[model,mode]).fetchone()
        effective=timing[0]/timing[1] if timing[1] else None
        valid=sum(c['json_valid'] for c in first)/len(first) if first else None
        schema=sum(c['schema_valid'] for c in first)/len(first) if first else None
        accepted=sum(c['accepted'] for c in first)/len(first) if first else None
        results.append(dict(model=model,mode=mode,processed=complete,failed=failed,first_attempts=len(first),
          json_valid_rate=valid,schema_valid_rate=schema,first_attempt_grounded_completion_rate=accepted,
          effective_seconds_per_passage=effective,timed_passages=timing[1],
          gate=('pass' if valid>=.97 and effective<=4 else 'fallback_required') if complete==300 and effective is not None else 'pending'))
    atomic_json(workdir()/'pilot_llm_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,results=results,scope='300 paired windows per model; all entities unresolved; throughput only',
      parallel_server=4,num_ctx=2048,think=False,human_validation=False,
      caveat='Timing includes retries and persistence within completed batches, excludes warmup. Interruption-incomplete batch timing excluded. S4 synthetic, cross-model and determinism gates remain pending.'))
    return results

def benchmark(con,model,limit=None):
    digest=model_digest(model)
    if not digest:raise RuntimeError(f'Model not installed: {model}')
    pin_stage(con,'llm_pilot_'+model.replace(':','_')+'_v1',dict(model=model,digest=digest,
        prompt=PROMPT,schema=SCHEMA,context=2048,parallel=4,seed=CONFIG['seed'],
        code_sha=file_sha(__file__),protocol_sha=file_sha(STUDY/'llm_protocol.py')))
    # Synthetic warmup is excluded from timed corpus calls.
    call_once(model,('warmup','Ivan je rekao: "Misa počinje u deset sati."',''),0)
    for mode,workers in [('single',1),('parallel4',4)]:
        rows=con.execute('''SELECT w.item_id,w.text,w.author FROM pilot_llm_sample s
          JOIN pilot_window_candidates w USING(item_id) LEFT JOIN pilot_llm_results r
          ON r.item_id=w.item_id AND r.model=? AND r.mode=? WHERE r.item_id IS NULL
          ORDER BY sha256(w.item_id || ?)''',[model,mode,str(CONFIG['seed'])]).fetchall()
        if limit:rows=rows[:limit]
        with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
            for offset in range(0,len(rows),workers):
                chunk=rows[offset:offset+workers];batch_id=str(uuid.uuid4());started=time.perf_counter()
                futures={}
                for row in chunk:
                    prior=con.execute('SELECT max(attempt) FROM pilot_llm_calls WHERE model=? AND mode=? AND item_id=?',
                        [model,mode,row[0]]).fetchone()[0]
                    attempt=2 if prior else 1
                    futures[pool.submit(call_once,model,row,.2 if prior else 0)]=(row,attempt)
                retry=[]
                for f in concurrent.futures.as_completed(futures):
                    row,attempt=futures[f]
                    result=f.result();save(con,model,mode,batch_id,result,attempt)
                    if not result['check']['accepted'] and attempt==1:retry.append(row)
                retry_futures=[pool.submit(call_once,model,row,.2) for row in retry]
                for f in concurrent.futures.as_completed(retry_futures):save(con,model,mode,batch_id,f.result(),2)
                with transaction(con):
                    con.execute('INSERT INTO pilot_llm_timing VALUES (?,?,?,?,?,?,?,?)',
                      [batch_id,model,mode,len(chunk),time.perf_counter()-started,CORPUS_HASH,CONFIG_HASH,utc()])
                con.execute('CHECKPOINT');report(con)
                print(f'{utc()} {model} {mode}: saved {offset+len(chunk)}/{len(rows)} pending passages',flush=True)
    requests.post(ENDPOINT+'/api/generate',json={'model':model,'keep_alive':0},timeout=60).raise_for_status()

def main():
    p=argparse.ArgumentParser();p.add_argument('--limit',type=int);args=p.parse_args()
    con=connect()
    con.execute('''CREATE TABLE IF NOT EXISTS pilot_llm_calls (call_id VARCHAR PRIMARY KEY,
      model VARCHAR,mode VARCHAR,item_id VARCHAR,attempt INTEGER,batch_id VARCHAR,seconds DOUBLE,
      raw_json VARCHAR,checks_json VARCHAR,error_type VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    con.execute('''CREATE TABLE IF NOT EXISTS pilot_llm_results (model VARCHAR,mode VARCHAR,item_id VARCHAR,
      status VARCHAR,raw_json VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,
      PRIMARY KEY(model,mode,item_id))''')
    con.execute('''CREATE TABLE IF NOT EXISTS pilot_llm_timing (batch_id VARCHAR PRIMARY KEY,model VARCHAR,
      mode VARCHAR,items INTEGER,wall_seconds DOUBLE,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    assert con.execute('SELECT count(*) FROM pilot_llm_sample').fetchone()[0]==300
    with gpu_lock(),server():
        benchmark(con,'qwen3:14b',args.limit)
        outcomes=report(con)
        failed=any(r['model']=='qwen3:14b' and r['mode']=='parallel4' and r['gate']=='fallback_required' for r in outcomes)
        if failed and not args.limit:
            if not model_digest('qwen3:8b'):
                print(f'{utc()} 14B throughput gate failed; downloading plan-approved qwen3:8b fallback',flush=True)
                with requests.post(ENDPOINT+'/api/pull',json={'model':'qwen3:8b','stream':True},stream=True,timeout=(10,600)) as response:
                    response.raise_for_status()
                    for line in response.iter_lines():
                        if line and json.loads(line).get('error'):raise RuntimeError('Fallback model pull failed')
            benchmark(con,'qwen3:8b')
        report(con)
    con.execute('CHECKPOINT');con.close()

if __name__=='__main__':main()
