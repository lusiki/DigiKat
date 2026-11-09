"""Freeze sentence benchmarks and 300 bounded LLM windows from the existing pilot."""
import importlib, json, re
from voices_common import *
ner=importlib.import_module('02_pilot_ner')
QUOTE=re.compile('[„“”"»«]')

def window_bounds(text, sentences, index, mention_start, mention_end):
    paragraph_start=0; paragraph_end=len(text)
    for match in re.finditer(r'\n\s*\n',text):
        if match.end()<=mention_start: paragraph_start=match.end()
        elif match.start()>=mention_end:
            paragraph_end=match.start(); break
    start=max(paragraph_start,sentences[max(0,index-2)][0])
    end=min(paragraph_end,sentences[min(len(sentences)-1,index+2)][1])
    cap=CONFIG['max_passage_characters']
    if mention_end-mention_start>cap: return None
    if end-start>cap:
        start=max(start,min(mention_start-400,end-cap))
        start=max(start,mention_end-cap)
        end=min(end,start+cap)
    assert start<=mention_start<mention_end<=end and end-start<=cap
    return start,end

def select_ids(con, source, where, target, n):
    con.execute(f'''CREATE TABLE IF NOT EXISTS {target} (item_id VARCHAR PRIMARY KEY,
      platform VARCHAR,era VARCHAR,population_n INTEGER,sample_n INTEGER,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    counts={(p,e):int(k) for p,e,k in con.execute(f'SELECT platform,era,count(*) FROM {source} WHERE {where} GROUP BY platform,era').fetchall()}
    n=min(n,sum(counts.values()))
    if con.execute(f'SELECT count(*) FROM {target}').fetchone()[0]: return
    alloc=ner.allocation(counts,n) if n<sum(counts.values()) else counts
    with transaction(con):
        for (p,e),nh in sorted(alloc.items()):
            ids=con.execute(f'''SELECT item_id FROM {source} WHERE {where} AND platform=? AND era=?
              ORDER BY sha256(item_id || ?) LIMIT ?''',[p,e,str(CONFIG['seed']),nh]).fetchall()
            con.executemany(f'INSERT INTO {target} VALUES (?,?,?,?,?,?,?,?)',
              [(i,p,e,counts[p,e],nh,CORPUS_HASH,CONFIG_HASH,utc()) for i, in ids])

def main():
    import classla
    con=connect()
    pin_stage(con,'remaining_pilot_selection_v1',dict(quote_sentences=1000,person_sentences=1000,
        llm_windows=300,window='mention sentence +/-2 within paragraph; center crop at 1200',
        seed=CONFIG['seed'],code_sha=file_sha(__file__)))
    con.execute('''CREATE TABLE IF NOT EXISTS pilot_sentences (item_id VARCHAR PRIMARY KEY,
      doc_id VARCHAR,sentence_id INTEGER,platform VARCHAR,era VARCHAR,start_char INTEGER,end_char INTEGER,
      text VARCHAR,has_quote BOOLEAN,has_person BOOLEAN,mentions_json VARCHAR,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    con.execute('''CREATE TABLE IF NOT EXISTS pilot_window_candidates (item_id VARCHAR PRIMARY KEY,
      doc_id VARCHAR,platform VARCHAR,era VARCHAR,start_char INTEGER,end_char INTEGER,text VARCHAR,
      author VARCHAR,mentions_json VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    con.execute('''CREATE TABLE IF NOT EXISTS pilot_prepared_docs (doc_id VARCHAR PRIMARY KEY,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    for kind in ('standard','nonstandard'):
        nlp=classla.Pipeline('hr',type=kind,processors='tokenize',use_gpu=False,verbose=False)
        cond="d.platform='web'" if kind=='standard' else "d.platform<>'web'"
        docs=con.execute(f'''SELECT d.doc_id,d.platform,d.era,d.text_clean,d.author FROM docs d
          JOIN pilot_sample s USING(doc_id) LEFT JOIN pilot_prepared_docs r USING(doc_id)
          WHERE r.doc_id IS NULL AND {cond} ORDER BY d.doc_id''').fetchall()
        for k,(doc_id,p,e,text,author) in enumerate(docs,1):
            mentions=con.execute("SELECT start_char,end_char,surface,type FROM pilot_mentions WHERE doc_id=? AND type IN ('PER','ORG') ORDER BY start_char",[doc_id]).fetchall()
            parsed=ner.align_document_offsets(nlp(text),text) if text.strip() else None
            bounds=[(s.tokens[0].start_char,s.tokens[-1].end_char) for s in parsed.sentences if s.tokens] if parsed else []
            sentences=[]; windows=[]
            for si,(a,b) in enumerate(bounds):
                mm=[dict(start=x,end=y,surface=s,type=t) for x,y,s,t in mentions if a<=x<y<=b]
                if QUOTE.search(text[a:b]) or any(m['type']=='PER' for m in mm):
                    sentences.append((f'{doc_id}:s{si}',doc_id,si,p,e,a,b,text[a:b],bool(QUOTE.search(text[a:b])),
                      any(m['type']=='PER' for m in mm),json.dumps(mm,ensure_ascii=False),CORPUS_HASH,CONFIG_HASH,utc()))
                if mm and len(text)>=300:
                    x,y=mm[0]['start'],mm[0]['end']
                    wb=window_bounds(text,bounds,si,x,y)
                    if wb:
                        wa,wb=wb
                        wm=[dict(surface=s,type=t,entity_id=None) for x,y,s,t in mentions if wa<=x<y<=wb]
                        windows.append((f'{doc_id}:w{wa}:{wb}',doc_id,p,e,wa,wb,text[wa:wb],author,
                          json.dumps(wm,ensure_ascii=False),CORPUS_HASH,CONFIG_HASH,utc()))
            # One seeded candidate window per document avoids document-length oversampling.
            if windows: windows=[min(windows,key=lambda row:hashlib.sha256((row[0]+str(CONFIG['seed'])).encode()).hexdigest())]
            with transaction(con):
                if sentences: con.executemany('INSERT INTO pilot_sentences VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)',sentences)
                if windows: con.executemany('INSERT INTO pilot_window_candidates VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',windows)
                con.execute('INSERT INTO pilot_prepared_docs VALUES (?,?,?,?)',[doc_id,CORPUS_HASH,CONFIG_HASH,utc()])
            if k%250==0: con.execute('CHECKPOINT'); print(f'{utc()} prepared {kind} {k}/{len(docs)}',flush=True)
    select_ids(con,'pilot_sentences','has_quote','pilot_quote_sample',1000)
    select_ids(con,'pilot_sentences','has_person','pilot_morph_sample',1000)
    select_ids(con,'pilot_window_candidates','true','pilot_llm_sample',300)
    assert con.execute('SELECT count(*) FROM pilot_llm_sample').fetchone()[0]==300
    con.execute('CHECKPOINT');con.close()
    print('Frozen quote, morphology and LLM benchmark samples.',flush=True)

if __name__=='__main__':main()
