"""Full-text stratified NER pilot. Each document's spans and completion commit together."""
from __future__ import annotations
import argparse, hashlib, importlib.metadata, json, math, re, time
from pathlib import Path
from voices_common import *

def allocation(counts, size):
    # One per observed stratum, then proportional largest remainder allocation.
    if size < len(counts): raise ValueError('Pilot too small for strata')
    alloc = {key: 1 for key in counts}
    remaining = size - len(counts)
    denominator = sum(n - 1 for n in counts.values())
    quota = {key: (n - 1) * remaining / denominator for key, n in counts.items()}
    for key in counts: alloc[key] += math.floor(quota[key])
    for key in sorted(counts, key=lambda k: (-(quota[k] % 1), k))[:size-sum(alloc.values())]: alloc[key] += 1
    assert sum(alloc.values()) == size and all(alloc[k] <= counts[k] for k in counts)
    return alloc

def freeze_sample(con):
    con.execute('''CREATE TABLE IF NOT EXISTS pilot_sample
      (doc_id VARCHAR PRIMARY KEY, platform VARCHAR, era VARCHAR, stratum_n INTEGER,
       sample_n INTEGER, selection_rank INTEGER, corpus_sha256 VARCHAR, config_hash VARCHAR, created_utc VARCHAR)''')
    n = con.execute('SELECT count(*) FROM pilot_sample').fetchone()[0]
    if n:
        if n != CONFIG['ner_pilot_documents']: raise RuntimeError('Incomplete pilot sample')
        return
    counts = {(p,e): n for p,e,n in con.execute('SELECT platform,era,count(*) FROM docs GROUP BY platform,era').fetchall()}
    alloc = allocation(counts, CONFIG['ner_pilot_documents'])
    with transaction(con):
        for (platform,era), nh in sorted(alloc.items()):
            ids = con.execute('''SELECT doc_id FROM docs WHERE platform=? AND era=?
                ORDER BY sha256(doc_id || ?) LIMIT ?''', [platform,era,str(CONFIG['seed']),nh]).fetchall()
            con.executemany('INSERT INTO pilot_sample VALUES (?,?,?,?,?,?,?,?,?)',
                [(doc_id,platform,era,counts[platform,era],nh,i,CORPUS_HASH,CONFIG_HASH,utc()) for i,(doc_id,) in enumerate(ids,1)])
    con.execute('CHECKPOINT')

def align_document_offsets(doc, text):
    """Reldi reports line-relative offsets; align tokens monotonically to full source."""
    cursor=0
    for sentence in doc.sentences:
        for token in sentence.tokens:
            start=text.find(token.text,cursor)
            if start < 0 or text[cursor:start].strip():
                raise ValueError('Token alignment would skip non-whitespace source text')
            end=start+len(token.text)
            token._start_char=start
            token._end_char=end
            cursor=end
    if text[cursor:].strip(): raise ValueError('Token alignment omitted trailing source text')
    doc.build_ents()
    return doc

def spans_from_doc(doc, text):
    result = []
    seen = set()
    for sentence_id, sentence in enumerate(doc.sentences):
        for ent in sentence.ents:
            if ent.type not in {'PER','PERSON','ORG','LOC'}: continue
            start, end = ent.start_char, ent.end_char
            if start is None or end is None or text[start:end] != ent.text:
                raise ValueError('Entity offset grounding failed')
            key=(start,end,'PER' if ent.type == 'PERSON' else ent.type)
            # Count a source span once if an upstream annotation is duplicated.
            if key in seen: continue
            seen.add(key)
            paragraph_id = len(re.findall(r'\n\s*\n', text[:start]))
            result.append((start,end,ent.text,'PER' if ent.type == 'PERSON' else ent.type,sentence_id,paragraph_id))
    return result

def report(con):
    rows = con.execute('''SELECT s.platform,s.era,max(s.stratum_n),max(s.sample_n),
      count(r.doc_id), coalesce(sum(r.n_chars),0),coalesce(sum(r.elapsed_seconds),0),
      coalesce(sum(r.person_spans),0),count(*) FILTER (WHERE r.status='failed')
      FROM pilot_sample s LEFT JOIN pilot_ner_docs r USING(doc_id)
      GROUP BY s.platform,s.era ORDER BY s.platform,s.era''').fetchall()
    strata=[]; projected=0.0
    for p,e,N,n,done,chars,seconds,persons,failed in rows:
        total_chars=con.execute('SELECT sum(n_chars) FROM docs WHERE platform=? AND era=?',[p,e]).fetchone()[0]
        estimate = total_chars*seconds/chars if chars else None
        if estimate is not None: projected += estimate
        strata.append(dict(platform=p,era=e,population_documents=N,sample_documents=n,processed=done,
          failed=failed,characters=chars,seconds=seconds,person_spans=persons,
          chars_per_second=chars/seconds if seconds else None,
          person_spans_per_1000_chars=1000*persons/chars if chars else None,
          projected_full_seconds=estimate))
    complete=all(s['processed']==s['sample_documents'] for s in strata)
    failed=sum(s['failed'] for s in strata)
    # A night means eight GPU-hours; this explicit operational assumption is not a finding.
    gate = ('pass' if projected <= 3*8*3600 else 'fallback_required') if complete and not failed else 'pending'
    atomic_json(workdir()/'pilot_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,ner_complete=complete,failed_documents=failed,strata=strata,
      projected_full_ner_hours=projected/3600,night_hours_assumption=8,ner_throughput_gate=gate,
      quote_dependency_benchmark='pending',inflection_load='pending',llm_pilot='pending',
      human_validation=False,precision_recall='unmeasured'))

def main():
    parser=argparse.ArgumentParser(); parser.add_argument('--limit',type=int); parser.add_argument('--smoke',action='store_true')
    args=parser.parse_args()
    import classla, torch
    torch.set_num_threads(4)
    if not torch.cuda.is_available(): raise RuntimeError('GPU unavailable; do not silently benchmark CPU')
    con=connect()
    resource_dir=Path.home()/'classla_resources'
    resource_files = sorted(p for p in resource_dir.rglob('*') if p.is_file())
    model_fingerprint = {str(p.relative_to(resource_dir)): file_sha(p) for p in resource_files}
    pin_stage(con,'pilot_ner_v2',dict(processors='tokenize,ner',seed=CONFIG['seed'],offset_alignment='monotonic_literal_tokens_v1',
        packages={n:importlib.metadata.version(n) for n in ['classla','torch','duckdb']},
        model_files=model_fingerprint,night_hours=8))
    freeze_sample(con)
    con.execute('''CREATE TABLE IF NOT EXISTS pilot_ner_docs
      (doc_id VARCHAR PRIMARY KEY, model_type VARCHAR, status VARCHAR, n_chars INTEGER,
       elapsed_seconds DOUBLE, person_spans INTEGER, error_type VARCHAR,
       corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    con.execute('''CREATE TABLE IF NOT EXISTS pilot_mentions
      (doc_id VARCHAR,start_char INTEGER,end_char INTEGER,surface VARCHAR,type VARCHAR,
       sentence_id INTEGER,paragraph_id INTEGER,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,
       PRIMARY KEY(doc_id,start_char,end_char,type))''')
    if con.execute("SELECT count(*) FROM pilot_ner_docs WHERE status='failed'").fetchone()[0]:
        raise RuntimeError('Saved pilot failures require investigation before continuing')
    with gpu_lock():
        ensure_ollama_idle()
        for model_type in ['standard','nonstandard']:
            condition="d.platform='web'" if model_type=='standard' else "d.platform<>'web'"
            pending=con.execute(f'''SELECT d.doc_id,d.text_clean,d.n_chars FROM docs d
              JOIN pilot_sample s USING(doc_id) LEFT JOIN pilot_ner_docs r USING(doc_id)
              WHERE r.doc_id IS NULL AND {condition} ORDER BY d.n_chars,d.doc_id''').fetchall()
            if not pending: continue
            nlp=classla.Pipeline('hr',type=model_type,processors='tokenize,ner',use_gpu=True,verbose=False)
            synthetic='Papa Franjo posjetio je Zagreb. Ivan Horvat govori o vjeri.'
            smoke=spans_from_doc(align_document_offsets(nlp(synthetic),synthetic),synthetic)
            if not any(x[3]=='PER' for x in smoke): raise RuntimeError('Synthetic NER smoke found no person')
            print(f'{utc()} {model_type}: GPU smoke passed; {len(pending)} documents pending',flush=True)
            if args.smoke: continue
            processed=0
            for doc_id,text,n_chars in pending:
                started=time.perf_counter(); status='complete'; error=''; spans=[]
                try: spans=spans_from_doc(align_document_offsets(nlp(text),text),text) if text.strip() else []
                except Exception as exc:
                    # Keep errors visible without printing corpus content into logs.
                    status='failed'; error=type(exc).__name__
                elapsed=time.perf_counter()-started
                with transaction(con):
                    if spans: con.executemany('INSERT INTO pilot_mentions VALUES (?,?,?,?,?,?,?,?,?,?)',
                       [(doc_id,*span,CORPUS_HASH,CONFIG_HASH,utc()) for span in spans])
                    con.execute('INSERT INTO pilot_ner_docs VALUES (?,?,?,?,?,?,?,?,?,?)',
                      [doc_id,model_type,status,n_chars,elapsed,sum(s[3]=='PER' for s in spans),error,CORPUS_HASH,CONFIG_HASH,utc()])
                processed+=1
                if processed%25==0 or status=='failed':
                    con.execute('CHECKPOINT')
                    if processed%100==0 or status=='failed': report(con)
                    print(f'{utc()} {model_type}: committed {processed}, latest={status}',flush=True)
                if status=='failed': raise RuntimeError(f'Pilot stopped on {error}; saved failure requires investigation')
                if args.limit and processed>=args.limit: break
            del nlp
            torch.cuda.empty_cache()
        report(con); con.execute('CHECKPOINT')
    con.close()

if __name__=='__main__': main()
