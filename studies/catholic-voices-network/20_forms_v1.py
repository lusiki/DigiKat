"""S2 forms: contexts and CLASSLA lemmas, durable at each stage.

Normalize up to three distinct occurrence contexts per surface/cue/model group;
disagreeing lemmas stay ambiguous rather than choosing a convenient identity.
This caching deviation from per-occurrence morphology is reported explicitly.
"""
import argparse,collections,importlib,importlib.metadata,json,time
from voices_common import *
from name_forms import features,clean_name
ner=importlib.import_module('02_pilot_ner')

def prepare(con):
    con.execute('''CREATE TABLE IF NOT EXISTS form_mentions (doc_id VARCHAR,start_char INTEGER,end_char INTEGER,
      form_id VARCHAR,cue VARCHAR,gender_hint VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,
      PRIMARY KEY(doc_id,start_char,end_char))''')
    con.execute('''CREATE TABLE IF NOT EXISTS forms (form_id VARCHAR PRIMARY KEY,surface VARCHAR,stripped VARCHAR,
      cue_class VARCHAR,model_type VARCHAR,examples_json VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    con.execute('''CREATE TABLE IF NOT EXISTS form_docs (doc_id VARCHAR PRIMARY KEY,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    ids=[r[0] for r in con.execute('SELECT doc_id FROM docs ANTI JOIN form_docs USING(doc_id) ORDER BY doc_id').fetchall()]
    for offset in range(0,len(ids),500):
        batch=ids[offset:offset+500]
        docs={i:(text,'standard' if p=='web' else 'nonstandard') for i,text,p in con.execute(
          'SELECT doc_id,text_clean,platform FROM docs WHERE doc_id>=? AND doc_id<=? AND doc_id IN (SELECT unnest(?))',
          [batch[0],batch[-1],batch]).fetchall()}
        mentions=con.execute("SELECT doc_id,start_char,end_char FROM mentions WHERE type='PER' AND doc_id>=? AND doc_id<=? ORDER BY doc_id,start_char",[batch[0],batch[-1]]).fetchall()
        new={};outputs=[]
        for doc,a,b in mentions:
            if doc not in docs:continue
            text,kind=docs[doc];f=features(text,a,b,kind);key=f['form_id']
            example=dict(doc_id=doc,text=f['context'],start=f['start'],end=f['end'])
            if key not in new:new[key]=(f,[])
            if len(new[key][1])<3 and example not in new[key][1]:new[key][1].append(example)
            outputs.append((doc,a,b,key,f['cue'],f['gender_hint'],CORPUS_HASH,CONFIG_HASH,utc()))
        existing={key:json.loads(raw) for key,raw in con.execute('SELECT form_id,examples_json FROM forms WHERE form_id IN (SELECT unnest(?))',[list(new)]).fetchall()} if new else {}
        with transaction(con):
            if outputs:con.executemany('INSERT INTO form_mentions VALUES (?,?,?,?,?,?,?,?,?)',outputs)
            for key,(f,examples) in new.items():
                prior=existing.get(key,[])
                for ex in examples:
                    if len(prior)<3 and not any(ex['text']==p['text'] and ex['start']==p['start'] for p in prior):prior.append(ex)
                con.execute('INSERT OR REPLACE INTO forms VALUES (?,?,?,?,?,?,?,?,?)',
                  [key,f['surface'],f['stripped'],f['cue_class'],f['model_type'],json.dumps(prior,ensure_ascii=False),CORPUS_HASH,CONFIG_HASH,utc()])
            con.executemany('INSERT INTO form_docs VALUES (?,?,?,?)',[(i,CORPUS_HASH,CONFIG_HASH,utc()) for i in batch])
        con.execute('CHECKPOINT')
        if offset%5000==0:print(utc(),'form contexts',offset+len(batch),'/',len(ids),flush=True)

def main():
    p=argparse.ArgumentParser();p.add_argument('--prepare-only',action='store_true');p.add_argument('--limit',type=int);args=p.parse_args()
    con=connect()
    assert con.execute("SELECT count(*) FROM ner_docs WHERE status='complete'").fetchone()[0]==MANIFEST['corpus']['rows']
    pin_stage(con,'forms_v1',dict(code=file_sha(__file__),rules=file_sha(STUDY/'name_forms.py'),contexts_per_form=3,
      processors='tokenize,pos,lemma',classla=importlib.metadata.version('classla'),
      model_files={str(p.relative_to(Path.home()/'classla_resources')):file_sha(p)
                   for p in sorted((Path.home()/'classla_resources').rglob('*')) if p.is_file()},
      caveat='Up to three source contexts per surface/cue/model form; disagreement retained as ambiguous, not majority-resolved.'))
    prepare(con)
    if args.prepare_only:con.close();return
    import classla,torch
    torch.set_num_threads(4)
    if not torch.cuda.is_available():raise RuntimeError('CUDA required for this pinned morphology run')
    con.execute('''CREATE TABLE IF NOT EXISTS form_lemmas (form_id VARCHAR PRIMARY KEY,nominative VARCHAR,
      status VARCHAR,details_json VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    completed=0
    with gpu_lock():
        ensure_ollama_idle()
        for kind in ['standard','nonstandard']:
            rows=con.execute('''SELECT f.form_id,f.stripped,f.examples_json FROM forms f
              ANTI JOIN form_lemmas l USING(form_id) WHERE f.model_type=? ORDER BY f.form_id''',[kind]).fetchall()
            if not rows:continue
            nlp=classla.Pipeline('hr',type=kind,processors='tokenize,pos,lemma',use_gpu=True,verbose=False)
            for key,stripped,raw in rows:
                details=[];lemmas=[]
                for ex in json.loads(raw):
                    doc=ner.align_document_offsets(nlp(ex['text']),ex['text']);tokens=[]
                    for sentence in doc.sentences:
                        for token in sentence.tokens:
                            if ex['start']<=token.start_char<token.end_char<=ex['end']:tokens.append(token)
                    aligned=bool(tokens and tokens[0].start_char==ex['start'] and tokens[-1].end_char==ex['end'])
                    lemma=clean_name(' '.join(w.lemma or w.text for t in tokens for w in t.words)) if aligned else None
                    details.append(dict(doc_id=ex['doc_id'],aligned=aligned,lemma=lemma))
                    if lemma:lemmas.append(lemma)
                unique={x.casefold():x for x in lemmas}
                status='agreed' if len(unique)==1 and len(lemmas)==len(details) else 'ambiguous' if len(unique)>1 else 'unaligned'
                nominative=next(iter(unique.values())) if status=='agreed' else stripped
                with transaction(con):con.execute('INSERT INTO form_lemmas VALUES (?,?,?,?,?,?,?)',
                  [key,nominative,status,json.dumps(details,ensure_ascii=False),CORPUS_HASH,CONFIG_HASH,utc()])
                completed+=1
                if completed%100==0:
                    con.execute('CHECKPOINT');print(utc(),'form lemmas newly saved',completed,flush=True)
                if args.limit and completed>=args.limit:con.close();return
            del nlp;torch.cuda.empty_cache()
    summary=con.execute('SELECT status,count(*) FROM form_lemmas GROUP BY status').fetchall()
    atomic_json(workdir()/'forms_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      forms=sum(n for _,n in summary),statuses=dict(summary),
      caveat='Agreement across at most three bounded source contexts, not verified nominative identity. Ambiguous forms do not merge by guessed lemma.'))
    con.execute('CHECKPOINT');con.close()

if __name__=='__main__':main()
