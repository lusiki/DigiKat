"""Closed-list recall proxy, ported from v1; not a measure of corpus-wide recall."""
import csv,json
import regex
from voices_common import *

CUES=dict(biskup=r'(?:kardinal|nadbiskup|biskup|nuncij)\p{L}{0,3}|mons\.|msgr\.',
 svecenik=r'don|fra|vlč\.|p\.|pater|mons\.|msgr\.|velečasn\p{L}{0,3}|svećenik\p{L}{0,3}|župnik\p{L}{0,3}|provincijal\p{L}{0,3}',
 akademski=r'prof\.|profesor\p{L}{0,4}|dr\.|teolog\p{L}{0,4}|teologinj\p{L}{0,2}|dekan\p{L}{0,3}|rektor\p{L}{0,3}|don|fra|p\.|mons\.|s\.',
 laik=r'teolog\p{L}{0,4}|teologinj\p{L}{0,2}|aktivist\p{L}{0,4}|publicist\p{L}{0,4}|novinar\p{L}{0,3}|kolumnist\p{L}{0,4}',
 redovnica=r's\.|sestr\p{L}{1,2}|časn\p{L}{1,2}\s+sestr\p{L}{1,2}')
NB=r'(?<!\p{L})';NE=r'(?!\p{L})'

def inflect(word):
    if word[-1:] in 'aeiou':
        stem=regex.escape(word[:-1])
        return stem+(r'(?:a|e|i|o|u|om|em|ja|ju|jem)' if len(word[:-1])<=3 else r'\p{L}{1,3}')
    return regex.escape(word)+r'\p{L}{0,3}'

def patterns():
    source=ROOT/'studies/theological-voices/voices.csv'
    rows=list(csv.DictReader(source.open(encoding='utf-8-sig')));parts=[]
    for row in rows:
        if row['cue']=='special':continue
        pattern=NB+inflect(row['first'])+r'\s+(?:\p{Lu}\p{L}+\s+)?'+inflect(row['surname'])+NE
        cue=CUES.get(row['role']) if row['cue']=='auto' else (None if row['cue']=='none' else row['cue'])
        if cue:pattern+='|'+NB+'(?:'+cue+r')\s+'+inflect(row['surname'])+NE
        parts.append('(?P<'+row['id']+'>'+pattern+')')
    parts.extend([
      r'(?P<franjo>'+NB+r'pap\p{L}{0,3}\s+Franj\p{L}{0,2}'+NE+r'|Bergoglio\p{L}{0,2})',
      r'(?P<lav14>'+NB+r'pap\p{L}{0,3}\s+Lav\p{L}{0,2}(?!\s+XIII)'+NE+r'|Prevost\p{L}{0,2}|Leon\p{L}{0,2}\s+XIV)',
      r'(?P<benedikt16>'+NB+r'pap\p{L}{0,3}\s+Benedikt\p{L}{0,2}|Ratzinger\p{L}{0,2}|Benedikt\p{L}{0,2}\s+XVI)'])
    return regex.compile('|'.join(parts)),source

def main():
    con=connect();pattern,source=patterns()
    assert con.execute("SELECT count(*) FROM ner_docs WHERE status='complete'").fetchone()[0]==MANIFEST['corpus']['rows']
    pin_stage(con,'gazetteer_v1',dict(source_sha=file_sha(source),code_sha=file_sha(__file__),
      overlap='at least one shared source character with a PER span',title_only='excluded from named-span proxy; handled by dated office layer'))
    con.execute('''CREATE TABLE IF NOT EXISTS forms_gazetteer (doc_id VARCHAR,person_key VARCHAR,
      start_char INTEGER,end_char INTEGER,ner_overlap BOOLEAN,corpus_sha256 VARCHAR,config_hash VARCHAR,
      created_utc VARCHAR,PRIMARY KEY(doc_id,person_key,start_char,end_char))''')
    con.execute('''CREATE TABLE IF NOT EXISTS gazetteer_docs (doc_id VARCHAR PRIMARY KEY,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    ids=[r[0] for r in con.execute('SELECT d.doc_id FROM docs d LEFT JOIN gazetteer_docs g USING(doc_id) WHERE g.doc_id IS NULL ORDER BY d.doc_id').fetchall()]
    for offset in range(0,len(ids),500):
        batch=ids[offset:offset+500]
        docs=con.execute('SELECT doc_id,text_clean,date FROM docs WHERE doc_id>=? AND doc_id<=? AND doc_id IN (SELECT unnest(?))',[batch[0],batch[-1],batch]).fetchall()
        mentions={i:[] for i in batch}
        for i,a,b in con.execute("SELECT doc_id,start_char,end_char FROM mentions WHERE type='PER' AND doc_id>=? AND doc_id<=?",[batch[0],batch[-1]]).fetchall():
            if i in mentions:mentions[i].append((a,b))
        hits=[]
        for i,text,date in docs:
            for m in pattern.finditer(text):
                if m.lastgroup=='lav14' and date<'2025-05-08':continue
                found=any(a<m.end() and b>m.start() for a,b in mentions[i])
                hits.append((i,m.lastgroup,m.start(),m.end(),found,CORPUS_HASH,CONFIG_HASH,utc()))
        with transaction(con):
            if hits:con.executemany('INSERT INTO forms_gazetteer VALUES (?,?,?,?,?,?,?,?)',hits)
            con.executemany('INSERT INTO gazetteer_docs VALUES (?,?,?,?)',[(i,CORPUS_HASH,CONFIG_HASH,utc()) for i in batch])
        con.execute('CHECKPOINT')
        if offset%5000==0:print(f'{utc()} gazetteer saved {offset+len(batch)}/{len(ids)} pending documents',flush=True)
    rows=con.execute('''SELECT d.platform,count(*),sum(CASE WHEN g.ner_overlap THEN 1 ELSE 0 END)
      FROM forms_gazetteer g JOIN docs d USING(doc_id) GROUP BY d.platform ORDER BY d.platform''').fetchall()
    atomic_json(workdir()/'gazetteer_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      check='M-REC-1',scope='known names, full-body text, overlap proxy; not measured recall',
      platforms=[dict(platform=p,gazetteer_hits=n,ner_overlap=k,share=k/n,lower_bound_label=k/n<.9) for p,n,k in rows]))
    con.close()

if __name__=='__main__':main()
