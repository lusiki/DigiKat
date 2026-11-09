"""GPU parsing benchmark and model-derived inflection load on frozen sentence samples."""
import importlib, importlib.metadata, json, time
from voices_common import *
ner=importlib.import_module('02_pilot_ner')

def report(con):
    data={}
    for label,table in [('quote','pilot_quote_sample'),('morphology','pilot_morph_sample')]:
        rows=con.execute(f'''SELECT s.platform,s.era,count(*),count(r.item_id),
          sum(r.n_chars),sum(r.seconds),sum(r.person_mentions),sum(r.aligned_mentions),sum(r.changed_mentions)
          FROM {table} s LEFT JOIN pilot_parse_results r USING(item_id)
          GROUP BY s.platform,s.era ORDER BY s.platform,s.era''').fetchall()
        fields=['platform','era','selected','processed','characters','seconds','person_mentions','aligned_mentions','changed_mentions']
        data[label]=[dict(zip(fields,r)) for r in rows]
        for row in data[label]:
            row['chars_per_second']=row['characters']/row['seconds'] if row['seconds'] else None
            row['changed_share_among_aligned']=row['changed_mentions']/row['aligned_mentions'] if row['aligned_mentions'] else None
    complete=all(r['selected']==r['processed'] for group in data.values() for r in group)
    atomic_json(workdir()/'pilot_parse_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,complete=complete,benchmarks=data,human_validation=False,
      note='1000 quote-bearing and 1000 person-bearing sentences, stratified by platform/era; samples may overlap. Inflection is surface vs model lemma, not verified nominative identity.'))

def main():
    import classla,torch
    torch.set_num_threads(4)
    if not torch.cuda.is_available():raise RuntimeError('CUDA unavailable')
    con=connect()
    pin_stage(con,'pilot_parse_v1',dict(processors='tokenize,pos,lemma,depparse',
      code_sha=file_sha(__file__),classla=importlib.metadata.version('classla'),
      resources={str(p.relative_to(Path.home()/'classla_resources')):file_sha(p) for p in sorted((Path.home()/'classla_resources').rglob('*')) if p.is_file()}))
    con.execute('''CREATE TABLE IF NOT EXISTS pilot_parse_results (item_id VARCHAR PRIMARY KEY,
      n_chars INTEGER,seconds DOUBLE,person_mentions INTEGER,aligned_mentions INTEGER,changed_mentions INTEGER,
      parsed_json VARCHAR,forms_json VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    with gpu_lock():
        ensure_ollama_idle()
        for kind in ('standard','nonstandard'):
            cond="s.platform='web'" if kind=='standard' else "s.platform<>'web'"
            rows=con.execute(f'''SELECT s.item_id,s.text,s.start_char,s.mentions_json FROM pilot_sentences s
              JOIN (SELECT item_id FROM pilot_quote_sample UNION SELECT item_id FROM pilot_morph_sample) q USING(item_id)
              LEFT JOIN pilot_parse_results r USING(item_id) WHERE r.item_id IS NULL AND {cond}
              ORDER BY length(s.text),s.item_id''').fetchall()
            if not rows:continue
            nlp=classla.Pipeline('hr',type=kind,processors='tokenize,pos,lemma,depparse',use_gpu=True,verbose=False)
            nlp('Ivan govori o vjeri.')
            for i,(item_id,text,base,mm) in enumerate(rows,1):
                start=time.perf_counter();doc=ner.align_document_offsets(nlp(text),text);seconds=time.perf_counter()-start
                tokens=[]
                for si,s in enumerate(doc.sentences):
                    for t in s.tokens:
                        tokens.append(dict(start=t.start_char,end=t.end_char,surface=t.text,
                          lemma=' '.join(w.lemma or w.text for w in t.words),sentence=si,
                          words=[dict(id=w.id,head=w.head,deprel=w.deprel,upos=w.upos,feats=w.feats) for w in t.words]))
                persons=[m for m in json.loads(mm) if m['type']=='PER'];forms=[]
                for m in persons:
                    a,b=m['start']-base,m['end']-base
                    tt=[t for t in tokens if a<=t['start']<t['end']<=b]
                    aligned=bool(tt and tt[0]['start']==a and tt[-1]['end']==b)
                    lemma=' '.join(t['lemma'] for t in tt) if aligned else None
                    changed=aligned and ' '.join(m['surface'].casefold().split())!=' '.join(lemma.casefold().split())
                    forms.append(dict(surface=m['surface'],lemma=lemma,aligned=aligned,changed=changed))
                with transaction(con):
                    con.execute('INSERT INTO pilot_parse_results VALUES (?,?,?,?,?,?,?,?,?,?,?)',
                      [item_id,len(text),seconds,len(persons),sum(f['aligned'] for f in forms),sum(f['changed'] for f in forms),
                       json.dumps(tokens,ensure_ascii=False),json.dumps(forms,ensure_ascii=False),CORPUS_HASH,CONFIG_HASH,utc()])
                if i%25==0: con.execute('CHECKPOINT');report(con);print(f'{utc()} parsed {kind} {i}/{len(rows)}',flush=True)
            del nlp;torch.cuda.empty_cache()
    report(con);con.execute('CHECKPOINT');con.close()

if __name__=='__main__':main()
