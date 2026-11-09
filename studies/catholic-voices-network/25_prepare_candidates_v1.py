"""All eligible bounded windows; CPU tokenization, durable per document.

This freezes the actual passage population before selection or model agreement.
Short text and identity exclusions remain in the document-level denominators.
"""
import collections,importlib,importlib.metadata,json
from voices_common import *
from passage_windows import create_windows,org_id,SPEECH_HINT,QUOTE,paragraph
from wikidata_identity import norm,classification
from office_register import read_cache
ner=importlib.import_module('02_pilot_ner')

def main():
    import classla
    con=connect()
    assert con.execute('SELECT count(*) FROM resolved_docs').fetchone()[0]==MANIFEST['corpus']['rows']
    pin_stage(con,'candidate_windows_v1',dict(code=file_sha(__file__),windows=file_sha(STUDY/'passage_windows.py'),
      inherited_bounds=file_sha(STUDY/'02_prepare_remaining.py'),classla=importlib.metadata.version('classla'),
      minimum_document_chars=300,max_window_chars=1200,unit='mention sentence +/-2, within paragraph',
      author='exact linked public-person label/alias; eligible non-web posts only'))
    con.execute('''CREATE TABLE IF NOT EXISTS candidates (item_id VARCHAR PRIMARY KEY,doc_id VARCHAR,
      paragraph_id INTEGER,platform VARCHAR,era VARCHAR,start_char INTEGER,end_char INTEGER,text VARCHAR,
      author VARCHAR,author_qid VARCHAR,mentions_json VARCHAR,sentence_ids_json VARCHAR,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    con.execute('''CREATE TABLE IF NOT EXISTS candidate_sentences (item_id VARCHAR PRIMARY KEY,doc_id VARCHAR,
      sentence_id INTEGER,platform VARCHAR,start_char INTEGER,end_char INTEGER,text VARCHAR,mentions_json VARCHAR,
      author_qid VARCHAR,needs_parse BOOLEAN,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    con.execute('''CREATE TABLE IF NOT EXISTS candidate_docs (doc_id VARCHAR PRIMARY KEY,n_chars INTEGER,
      windows INTEGER,author_resolved BOOLEAN,exclusion VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    linked={qid:json.loads(raw) for qid,raw in con.execute("SELECT qid,facts_json FROM entity_links WHERE status='linked'").fetchall()}
    public,_,_=read_cache(workdir()/'public_register_cache');author_index=collections.defaultdict(set)
    for qid in linked:
        ent=public.get(qid,{})
        strings=[v['value'] for v in ent.get('labels',{}).values()]+[v['value'] for a in ent.get('aliases',{}).values() for v in a]
        for name in strings:
            if len(norm(name).split())>=2:author_index[norm(name)].add(qid)
    for kind in ['standard','nonstandard']:
        cond="d.platform='web'" if kind=='standard' else "d.platform<>'web'"
        ids=[r[0] for r in con.execute(f'SELECT d.doc_id FROM docs d ANTI JOIN candidate_docs c USING(doc_id) WHERE {cond} ORDER BY d.doc_id').fetchall()]
        if not ids:continue
        nlp=classla.Pipeline('hr',type=kind,processors='tokenize',use_gpu=False,verbose=False)
        for offset in range(0,len(ids),250):
            batch=ids[offset:offset+250]
            docs=con.execute('''SELECT doc_id,platform,era,text_clean,author,source,date FROM docs
              WHERE doc_id>=? AND doc_id<=? AND doc_id IN (SELECT unnest(?)) ORDER BY doc_id''',[batch[0],batch[-1],batch]).fetchall()
            mentions=collections.defaultdict(list)
            for did,a,b,surface,eid,category in con.execute('''SELECT doc_id,start_char,end_char,surface,entity_id,life_class
              FROM resolved_mentions WHERE doc_id>=? AND doc_id<=?''',[batch[0],batch[-1]]).fetchall():
                mentions[did].append(dict(start=a,end=b,surface=surface,entity_id=eid,**{'class':category,'type':'PER'}))
            for did,a,b,surface in con.execute("SELECT doc_id,start_char,end_char,surface FROM mentions WHERE type='ORG' AND doc_id>=? AND doc_id<=?",[batch[0],batch[-1]]).fetchall():
                mentions[did].append(dict(start=a,end=b,surface=surface,entity_id=org_id(surface),**{'class':'institution','type':'ORG'}))
            for did,platform,era,text,author,source,date in docs:
                choices=author_index.get(norm(author or ''),set()) or author_index.get(norm(source or ''),set())
                aqid=next(iter(choices)) if len(choices)==1 and platform!='web' else None
                if aqid and classification(author or source,linked[aqid],date)!='contemporary':aqid=None
                author_surface=(author if author_index.get(norm(author or '')) else source) if aqid else ''
                mm=mentions[did]
                eligible=any(m['class']=='contemporary' or m['type']=='ORG' for m in mm) or bool(aqid)
                bounds=[];windows=[];sentences=[]
                if len(text)>=300 and eligible:
                    parsed=ner.align_document_offsets(nlp(text),text)
                    bounds=[(s.tokens[0].start_char,s.tokens[-1].end_char) for s in parsed.sentences if s.tokens]
                    windows=create_windows(did,text,bounds,mm,author_surface)
                    used={i for w in windows for i in w['sentence_ids']}
                    contemporary_paragraphs={paragraph(text,m['start']) for m in mm if m['class']=='contemporary'}
                    # Parse original complete sentences even when a bounded model
                    # window shows only a fragment; offsets stay source-relative.
                    for si in sorted(used):
                        a,b=bounds[si];sm=[{**m,'start':m['start']-a,'end':m['end']-a} for m in mm if a<=m['start']<m['end']<=b]
                        needs=bool(aqid or (paragraph(text,a) in contemporary_paragraphs and (QUOTE.search(text[a:b]) or SPEECH_HINT.search(text[a:b]))))
                        sentences.append((f'{did}:s{si}',did,si,platform,a,b,text[a:b],json.dumps(sm,ensure_ascii=False),
                          aqid,needs,CORPUS_HASH,CONFIG_HASH,utc()))
                exclusion='short_text' if len(text)<300 else 'no_resolved_person_or_org' if not eligible else 'no_bounded_window' if not windows else ''
                with transaction(con):
                    for w in windows:con.execute('INSERT INTO candidates VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                      [w['item_id'],did,w['paragraph_id'],platform,era,w['start'],w['end'],w['text'],author_surface,aqid,
                       json.dumps(w['mentions'],ensure_ascii=False),json.dumps(w['sentence_ids']),CORPUS_HASH,CONFIG_HASH,utc()])
                    if sentences:con.executemany('INSERT INTO candidate_sentences VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)',sentences)
                    con.execute('INSERT INTO candidate_docs VALUES (?,?,?,?,?,?,?,?)',
                      [did,len(text),len(windows),bool(aqid),exclusion,CORPUS_HASH,CONFIG_HASH,utc()])
            con.execute('CHECKPOINT');print(utc(),'candidate windows prepared',kind,offset+len(batch),'/',len(ids),flush=True)
    rows=con.execute('''SELECT d.platform,d.era,count(*) AS documents,sum(c.windows) AS windows,
      count(*) FILTER (WHERE c.exclusion='short_text') AS short_text,
      count(*) FILTER (WHERE c.exclusion='no_resolved_person_or_org') AS no_eligible_identity,
      sum(c.author_resolved::INTEGER) AS author_resolved FROM candidate_docs c JOIN docs d USING(doc_id) GROUP BY d.platform,d.era''').fetchdf()
    atomic_json(workdir()/'candidate_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      complete=con.execute('SELECT count(*) FROM candidate_docs').fetchone()[0]==MANIFEST['corpus']['rows'],
      strata=rows.to_dict('records'),windows=con.execute('SELECT count(*) FROM candidates').fetchone()[0],
      sentences_needing_parse=con.execute('SELECT count(*) FROM candidate_sentences WHERE needs_parse').fetchone()[0],
      caveat='Person windows require a machine-resolved contemporary identity; ORG windows also eligible. Unresolved/historical mentions can occur as context. Rule parsing uses original complete sentences; model comparisons require evidence inside the bounded window. YouTube is available text only.'))
    con.close()

if __name__=='__main__':main()
