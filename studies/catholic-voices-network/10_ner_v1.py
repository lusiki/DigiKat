"""Full-corpus S1 NER. Resume per document; reuse only pinned compatible pilot outputs."""
import argparse,importlib,importlib.metadata,json,time
from voices_common import *
pilot=importlib.import_module('02_pilot_ner')

def progress(con):
    rows=con.execute('''SELECT d.platform,count(*) AS total,count(n.doc_id) AS processed,
      count(*) FILTER (WHERE n.status='failed') AS failed FROM docs d LEFT JOIN ner_docs n USING(doc_id)
      GROUP BY d.platform ORDER BY d.platform''').fetchall()
    n=sum(r[2] for r in rows);fail=sum(r[3] for r in rows)
    atomic_json(workdir()/'ner_progress.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,total=MANIFEST['corpus']['rows'],processed=n,failed=fail,
      complete=n==MANIFEST['corpus']['rows'] and fail==0,
      platforms=[dict(platform=p,total=t,processed=k,failed=f) for p,t,k,f in rows]))
    return n,fail

def main():
    p=argparse.ArgumentParser();p.add_argument('--limit',type=int);p.add_argument('--retry-failed',action='store_true');args=p.parse_args()
    import classla,torch
    torch.set_num_threads(4)
    if not torch.cuda.is_available():raise RuntimeError('CUDA required for this pinned full run')
    con=connect()
    resources={str(p.relative_to(Path.home()/'classla_resources')):file_sha(p) for p in sorted((Path.home()/'classla_resources').rglob('*')) if p.is_file()}
    settings=dict(processors='tokenize,ner',seed=CONFIG['seed'],offset_alignment='monotonic_literal_tokens_v1',
      packages={n:importlib.metadata.version(n) for n in ['classla','torch','duckdb']},model_files=resources,night_hours=8)
    # Also asserts compatibility before reusing the pilot's outputs.
    pin_stage(con,'pilot_ner_v2',settings)
    pin_stage(con,'full_ner_v1',{**settings,'implementation':file_sha(__file__)})
    con.execute('''CREATE TABLE IF NOT EXISTS ner_docs (doc_id VARCHAR PRIMARY KEY,model_type VARCHAR,status VARCHAR,
      n_chars INTEGER,elapsed_seconds DOUBLE,person_spans INTEGER,error_type VARCHAR,corpus_sha256 VARCHAR,
      config_hash VARCHAR,created_utc VARCHAR)''')
    con.execute('''CREATE TABLE IF NOT EXISTS mentions (doc_id VARCHAR,start_char INTEGER,end_char INTEGER,
      surface VARCHAR,type VARCHAR,sentence_id INTEGER,paragraph_id INTEGER,corpus_sha256 VARCHAR,
      config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(doc_id,start_char,end_char,type))''')
    con.execute('''CREATE TABLE IF NOT EXISTS ner_errors (doc_id VARCHAR,attempt_utc VARCHAR,error_type VARCHAR,
      message VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    with transaction(con):
        con.execute('''INSERT INTO mentions SELECT m.* FROM pilot_mentions m
          JOIN pilot_ner_docs p ON p.doc_id=m.doc_id LEFT JOIN ner_docs n ON n.doc_id=m.doc_id
          WHERE p.status='complete' AND n.doc_id IS NULL''')
        con.execute('''INSERT INTO ner_docs SELECT p.* FROM pilot_ner_docs p LEFT JOIN ner_docs n USING(doc_id)
          WHERE p.status='complete' AND n.doc_id IS NULL''')
        if args.retry_failed:con.execute("DELETE FROM ner_docs WHERE status='failed'")
    con.execute('CHECKPOINT');progress(con)
    attempted=0
    with gpu_lock():
        ensure_ollama_idle()
        for kind in ('standard','nonstandard'):
            cond="d.platform='web'" if kind=='standard' else "d.platform<>'web'"
            ids=con.execute(f'''SELECT d.doc_id FROM docs d LEFT JOIN ner_docs n USING(doc_id)
              WHERE n.doc_id IS NULL AND {cond} ORDER BY d.doc_id''').fetchall()
            if not ids:continue
            nlp=classla.Pipeline('hr',type=kind,processors='tokenize,ner',use_gpu=True,verbose=False)
            smoke='Ivan Horvat govori o vjeri.'
            assert any(s[3]=='PER' for s in pilot.spans_from_doc(pilot.align_document_offsets(nlp(smoke),smoke),smoke))
            print(f'{utc()} full NER {kind}: {len(ids)} pending',flush=True)
            consecutive_failures=0
            for offset in range(0,len(ids),500):
                batch=[v[0] for v in ids[offset:offset+500]]
                rows=con.execute('''SELECT doc_id,text_clean,n_chars FROM docs WHERE doc_id>=? AND doc_id<=?
                  AND doc_id IN (SELECT unnest(?)) ORDER BY n_chars,doc_id''',[batch[0],batch[-1],batch]).fetchall()
                for doc_id,text,nchars in rows:
                    start=time.perf_counter();spans=[];status='complete';error='';message=''
                    try:
                        if text.strip():spans=pilot.spans_from_doc(pilot.align_document_offsets(nlp(text),text),text)
                    except Exception as exc:status='failed';error=type(exc).__name__;message=str(exc)[:1000]
                    elapsed=time.perf_counter()-start
                    with transaction(con):
                        if spans:con.executemany('INSERT INTO mentions VALUES (?,?,?,?,?,?,?,?,?,?)',
                          [(doc_id,*s,CORPUS_HASH,CONFIG_HASH,utc()) for s in spans])
                        con.execute('INSERT INTO ner_docs VALUES (?,?,?,?,?,?,?,?,?,?)',
                          [doc_id,kind,status,nchars,elapsed,sum(s[3]=='PER' for s in spans),error,CORPUS_HASH,CONFIG_HASH,utc()])
                        if error:con.execute('INSERT INTO ner_errors VALUES (?,?,?,?,?,?,?)',[doc_id,utc(),error,message,CORPUS_HASH,CONFIG_HASH,utc()])
                    attempted+=1;consecutive_failures=consecutive_failures+1 if error else 0
                    if attempted%100==0:
                        con.execute('CHECKPOINT');done,failed=progress(con)
                        print(f'{utc()} full NER saved {done}/{MANIFEST["corpus"]["rows"]}; failed={failed}',flush=True)
                    if consecutive_failures>=3 or error=='OutOfMemoryError':
                        progress(con);raise RuntimeError('NER stopped for repeated errors or GPU memory failure; see ner_errors')
                    if args.limit and attempted>=args.limit:
                        con.execute('CHECKPOINT');progress(con);con.close();return
            del nlp;torch.cuda.empty_cache()
    con.execute('CHECKPOINT');done,failed=progress(con);con.close()
    if failed:raise RuntimeError(f'{failed} failed NER documents require resolution; outputs retained')

if __name__=='__main__':main()
