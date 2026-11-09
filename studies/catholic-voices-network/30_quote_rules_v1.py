"""Dependency/first-person rule tier. Per-sentence commits and literal offsets.

Failed parses are unknown, never negative examples. Whole source sentences are
parsed even when a model window is cropped; model comparisons use only evidence
wholly inside that window. Historical/sacred entities are not living speakers.
"""
import argparse,collections,importlib,importlib.metadata,json,time
from voices_common import *
from speech_rules import attributed,first_person,quotes
ner=importlib.import_module('02_pilot_ner')

def tokens_from_doc(doc):
    return [dict(start=t.start_char,end=t.end_char,surface=t.text,sentence=si,
       words=[dict(id=w.id,head=w.head,deprel=w.deprel,lemma=w.lemma,upos=w.upos,feats=w.feats) for w in t.words])
       for si,sentence in enumerate(doc.sentences) for t in sentence.tokens]

def execute_sentence(nlp,text,base,full_text,mentions,author_qid):
    doc=ner.align_document_offsets(nlp(text),text);tokens=tokens_from_doc(doc)
    rows=attributed(text,tokens,mentions)
    for row in rows:
        for field in ['content_start','content_end','evidence_start','evidence_end']:row[field]+=base
    global_tokens=[{**t,'start':t['start']+base,'end':t['end']+base} for t in tokens]
    signal=first_person(full_text,global_tokens,'known_answer') is not None
    personal=first_person(full_text,global_tokens,author_qid)
    if personal:
        personal.update(evidence_start=base,evidence_end=base+len(text),content_start=base,
                        content_end=base+len(text),speech_verb='first_person_morphology')
        rows.append(personal)
    for row in rows:
        a,b=row['evidence_start'],row['evidence_end']
        if not 0<=a<b<=len(full_text):raise ValueError('Rule evidence offsets do not ground in source')
    return tokens,rows,signal

def materialize_windows(con):
    con.execute('''CREATE TABLE IF NOT EXISTS rule_window_results (item_id VARCHAR PRIMARY KEY,status VARCHAR,
      statements_json VARCHAR,ambiguous_subject BOOLEAN,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    ids=[r[0] for r in con.execute('SELECT item_id FROM candidates ANTI JOIN rule_window_results USING(item_id) ORDER BY item_id').fetchall()]
    for offset in range(0,len(ids),1000):
        batch=ids[offset:offset+1000]
        windows=con.execute('''SELECT item_id,doc_id,start_char,end_char,sentence_ids_json FROM candidates
          WHERE item_id IN (SELECT unnest(?))''',[batch]).fetchall()
        docs=list({w[1] for w in windows});results=collections.defaultdict(dict)
        for did,si,needs,status,raw in con.execute('''SELECT s.doc_id,s.sentence_id,s.needs_parse,r.status,r.statements_json
          FROM candidate_sentences s LEFT JOIN rule_sentence_results r USING(item_id)
          WHERE s.doc_id IN (SELECT unnest(?))''',[docs]).fetchall():results[did][si]=(needs,status,json.loads(raw) if raw else [])
        outputs=[]
        for item,did,a,b,raw_ids in windows:
            states=[results[did][si] for si in json.loads(raw_ids)]
            unknown=any(needs and status!='complete' for needs,status,_ in states)
            statements=[r for _,status,rr in states if status=='complete' for r in rr if a<=r['evidence_start']<r['evidence_end']<=b]
            # Deduplicate repeats across sentences without discarding distinct evidence.
            unique={(r['entity_id'],r['mode'],r['content_start'],r['content_end']):r for r in statements}
            needed=any(s[0] for s in states)
            outputs.append((item,'parse_unknown' if unknown else 'complete' if needed else 'not_applicable',
                json.dumps(list(unique.values()),ensure_ascii=False),bool(unknown or (needed and not unique)),CORPUS_HASH,CONFIG_HASH,utc()))
        with transaction(con):con.executemany('INSERT INTO rule_window_results VALUES (?,?,?,?,?,?,?)',outputs)
        con.execute('CHECKPOINT')

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--limit',type=int);parser.add_argument('--retry-failed',action='store_true');args=parser.parse_args()
    con=connect()
    assert con.execute('SELECT count(*) FROM candidate_docs').fetchone()[0]==MANIFEST['corpus']['rows']
    pin_stage(con,'speech_rules_v1',dict(code=file_sha(__file__),rules=file_sha(STUDY/'speech_rules.py'),
      processors='tokenize,pos,lemma,depparse',classla=importlib.metadata.version('classla'),
      resources={str(p.relative_to(Path.home()/'classla_resources')):file_sha(p)
                 for p in sorted((Path.home()/'classla_resources').rglob('*')) if p.is_file()}))
    con.execute('''CREATE TABLE IF NOT EXISTS rule_sentence_results (item_id VARCHAR PRIMARY KEY,status VARCHAR,
      seconds DOUBLE,first_person_signal BOOLEAN,parsed_json VARCHAR,statements_json VARCHAR,error_json VARCHAR,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    con.execute('''CREATE TABLE IF NOT EXISTS rule_parse_errors (item_id VARCHAR,error_json VARCHAR,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    if args.retry_failed:
        with transaction(con):
            con.execute("DELETE FROM rule_sentence_results WHERE status='failed'")
            con.execute('DROP TABLE IF EXISTS rule_window_results') # Deterministic derived view; raw attempts retained.
    saved,complete,failed=con.execute("""SELECT count(*),count(*) FILTER (WHERE status='complete'),
      count(*) FILTER (WHERE status='failed') FROM rule_sentence_results""").fetchone()
    needed=con.execute('SELECT count(*) FROM candidate_sentences WHERE needs_parse').fetchone()[0]
    print(utc(),'rule resume baseline',json.dumps(dict(saved=saved,complete=complete,failed=failed,needed=needed)),flush=True)
    import classla,torch
    torch.set_num_threads(4)
    if not torch.cuda.is_available():raise RuntimeError('CUDA required for this pinned rule run')
    attempted=0;failures_this_run=0
    with gpu_lock():
        ensure_ollama_idle()
        for kind in ['standard','nonstandard']:
            condition="s.platform='web'" if kind=='standard' else "s.platform<>'web'"
            ids=[r[0] for r in con.execute(f'''SELECT s.item_id FROM candidate_sentences s
              ANTI JOIN rule_sentence_results r USING(item_id) WHERE s.needs_parse AND {condition} ORDER BY s.item_id''').fetchall()]
            if not ids:continue
            print(utc(),'rule sentences pending',kind,len(ids),flush=True)
            nlp=classla.Pipeline('hr',type=kind,processors='tokenize,pos,lemma,depparse',use_gpu=True,verbose=False)
            smoke='Ivan Horvat je rekao: "Vjera traži odgovornost."'
            _,quoted,_=execute_sentence(nlp,smoke,0,smoke,
                [dict(start=0,end=11,surface='Ivan Horvat',entity_id='SYNTHETIC_PERSON',**{'class':'contemporary','type':'PER'})],None)
            own='Molim svakoga jutra.'
            _,personal,_=execute_sentence(nlp,own,0,own,[],'SYNTHETIC_AUTHOR')
            smoke_ok=any(r['entity_id']=='SYNTHETIC_PERSON' and r['mode']=='direct' for r in quoted) and any(r['mode']=='first_person' for r in personal)
            atomic_json(workdir()/('rule_model_smoke_'+kind+'.json'),dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
                config_hash=CONFIG_HASH,model_type=kind,passed=smoke_ok,synthetic=True,quote=quoted,first_person=personal))
            if not smoke_ok:raise RuntimeError('Constructed dependency/first-person model smoke failed; inspect saved diagnostics')
            consecutive=0
            for offset in range(0,len(ids),100):
                batch=ids[offset:offset+100]
                rows=con.execute('''SELECT s.item_id,s.text,s.start_char,d.text_clean,s.mentions_json,s.author_qid
                  FROM candidate_sentences s JOIN docs d USING(doc_id) WHERE s.item_id IN (SELECT unnest(?)) ORDER BY length(s.text),s.item_id''',[batch]).fetchall()
                for item,text,base,full,raw,author in rows:
                    started=time.perf_counter();error=None;tokens=[];statements=[];signal=False
                    try:tokens,statements,signal=execute_sentence(nlp,text,base,full,json.loads(raw),author)
                    except Exception as exc:error=dict(type=type(exc).__name__,message=str(exc)[:1500])
                    status='failed' if error else 'complete'
                    with transaction(con):
                        con.execute('INSERT INTO rule_sentence_results VALUES (?,?,?,?,?,?,?,?,?,?)',
                          [item,status,time.perf_counter()-started,signal,json.dumps(tokens,ensure_ascii=False),
                           json.dumps(statements,ensure_ascii=False),json.dumps(error),CORPUS_HASH,CONFIG_HASH,utc()])
                        if error:con.execute('INSERT INTO rule_parse_errors VALUES (?,?,?,?,?)',[item,json.dumps(error),CORPUS_HASH,CONFIG_HASH,utc()])
                    attempted+=1;failures_this_run+=int(error is not None);consecutive=consecutive+1 if error else 0
                    if error and (consecutive>=3 or error['type']=='OutOfMemoryError'):
                        con.execute('CHECKPOINT');raise RuntimeError('Rule parsing stopped; saved errors require resolution')
                    if args.limit and attempted>=args.limit:con.execute('CHECKPOINT');con.close();return
                con.execute('CHECKPOINT');print(utc(),'rule sentences saved',kind,offset+len(batch),'/',len(ids),
                    'failures_this_run',failures_this_run,flush=True)
            del nlp;torch.cuda.empty_cache()
    materialize_windows(con)
    n,failed=con.execute("SELECT count(*),count(*) FILTER (WHERE status='failed') FROM rule_sentence_results").fetchone()
    # An internal known-answer check conditional on linked AUTHOR and observed
    # first-person morphology; not semantic validation of real social posts.
    recovery=[]
    for platform,raws in con.execute('''SELECT s.platform,list(r.statements_json) FROM candidate_sentences s
      JOIN rule_sentence_results r USING(item_id) WHERE s.author_qid IS NOT NULL AND r.status='complete'
      AND r.first_person_signal GROUP BY s.platform''').fetchall():
        denominator=len(raws);recovered=sum(any(x['mode']=='first_person' for x in json.loads(raw)) for raw in raws)
        recovery.append(dict(platform=platform,eligible=denominator,recovered=recovered,share=recovered/denominator,
                             exclude_first_person=recovered/denominator<.85))
    atomic_json(workdir()/'speech_rule_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      sentences=n,parse_failures=failed,rule_tier_withheld=bool(n and failed/n>.02),author_recovery=recovery,
      windows=con.execute('SELECT count(*) FROM rule_window_results').fetchone()[0],
      ambiguous_windows=con.execute('SELECT count(*) FROM rule_window_results WHERE ambiguous_subject').fetchone()[0],
      caveat='Unknown parses are not zero speech. AUTHOR recovery is conditional mechanical consistency, not empirical accuracy; unlinked accounts are outside its denominator.'))
    con.close()
    if failed:raise RuntimeError('Saved parse failures require resolution before freezing the main samples')

if __name__=='__main__':main()
