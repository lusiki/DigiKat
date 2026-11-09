"""Per-document life classes plus dated title-only matches, saved per document batch."""
import collections,json
from voices_common import *
from office_register import read_cache
from office_titles import vocabulary,match_titles
from wikidata_identity import classification,person_facts,norm

def main():
    con=connect()
    assert con.execute('SELECT count(*) FROM entity_links').fetchone()[0]>=min(1500,con.execute('SELECT count(*) FROM entities WHERE threshold=.9').fetchone()[0])
    register=json.loads((workdir()/'office_register.json').read_text(encoding='utf-8'))
    entities,_,_=read_cache(workdir()/'public_register_cache')
    alias_path=workdir()/'office_title_aliases.json';aliases=[]
    if alias_path.exists():
        alias_snapshot=json.loads(alias_path.read_text(encoding='utf-8'))
        if alias_snapshot['corpus_sha256']!=CORPUS_HASH or alias_snapshot['config_hash']!=CONFIG_HASH or alias_snapshot['register_sha256']!=file_sha(workdir()/'office_register.json') or alias_snapshot['dated_rules_sha256']!=file_sha(STUDY/'dated_office_rules.py'):
            raise RuntimeError('Official title alias snapshot is stale')
        aliases=alias_snapshot['aliases']
    pattern,mapping=vocabulary(register,entities,aliases)
    facts={q:person_facts(e) for q,e in entities.items() if e.get('id')}
    pin_stage(con,'resolved_mentions_v1',dict(code=file_sha(__file__),title_rules=file_sha(STUDY/'office_titles.py'),
      tenure_plausibility=file_sha(STUDY/'dated_office_rules.py'),
      official_aliases_sha=file_sha(alias_path) if alias_path.exists() else None,
      class_rules=file_sha(STUDY/'wikidata_identity.py'),register_sha=file_sha(workdir()/'office_register.json'),
      title_vocabulary=mapping,unknown_date_policy='role only',historical_context_policy='do not assign present incumbent'))
    con.execute('''CREATE TABLE IF NOT EXISTS resolved_mentions (doc_id VARCHAR,start_char INTEGER,end_char INTEGER,
      surface VARCHAR,entity_id VARCHAR,cluster_entity_id VARCHAR,qid VARCHAR,life_class VARCHAR,origin VARCHAR,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(doc_id,start_char,end_char,origin))''')
    con.execute('''CREATE TABLE IF NOT EXISTS title_mentions (doc_id VARCHAR,start_char INTEGER,end_char INTEGER,
      surface VARCHAR,qid VARCHAR,status VARCHAR,offices_json VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,
      PRIMARY KEY(doc_id,start_char,end_char))''')
    con.execute('''CREATE TABLE IF NOT EXISTS resolved_docs (doc_id VARCHAR PRIMARY KEY,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    pending=[r[0] for r in con.execute('SELECT doc_id FROM docs ANTI JOIN resolved_docs USING(doc_id) ORDER BY doc_id').fetchall()]
    for offset in range(0,len(pending),500):
        batch=pending[offset:offset+500]
        docs=con.execute('SELECT doc_id,text_clean,date FROM docs WHERE doc_id>=? AND doc_id<=? AND doc_id IN (SELECT unnest(?))',[batch[0],batch[-1],batch]).fetchall()
        named=collections.defaultdict(list)
        rows=con.execute('''SELECT m.doc_id,m.start_char,m.end_char,f.surface,a.entity_id,l.qid,l.status,l.facts_json
          FROM form_mentions m JOIN forms f USING(form_id) JOIN aliases a ON a.form_id=m.form_id AND a.threshold=.9
          LEFT JOIN entity_links l ON l.entity_id=a.entity_id WHERE m.doc_id>=? AND m.doc_id<=?''',[batch[0],batch[-1]]).fetchall()
        for row in rows:named[row[0]].append(row[1:])
        resolved=[];titles=[]
        for did,text,date in docs:
            people=named[did]
            for a,b,surface,eid,qid,status,raw in people:
                fact=json.loads(raw) if raw else {}
                category='sacred' if status=='sacred' else classification(surface,fact,date)
                resolved.append((did,a,b,surface,qid or eid,eid,qid,category,'ner',CORPUS_HASH,CONFIG_HASH,utc()))
            for hit in match_titles(text,date,[(r[0],r[1]) for r in people],register,pattern,mapping):
                a,b=hit['start'],hit['end'];qid=hit['qid']
                titles.append((did,a,b,hit['surface'],qid,hit['status'],json.dumps(hit['office_qids']),CORPUS_HASH,CONFIG_HASH,utc()))
                if qid:
                    category=classification(hit['surface'],facts.get(qid,{}),date)
                    # An NER span that is only the same generic title must not
                    # become a second unresolved candidate beside its dated QID.
                    resolved=[r for r in resolved if not (r[0]==did and r[8]=='ner' and r[7]=='unresolved' and a<=r[1]<r[2]<=b)]
                    resolved.append((did,a,b,hit['surface'],qid,None,qid,category,'dated_title',CORPUS_HASH,CONFIG_HASH,utc()))
        with transaction(con):
            if resolved:con.executemany('INSERT INTO resolved_mentions VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',resolved)
            if titles:con.executemany('INSERT INTO title_mentions VALUES (?,?,?,?,?,?,?,?,?,?)',titles)
            con.executemany('INSERT INTO resolved_docs VALUES (?,?,?,?)',[(did,CORPUS_HASH,CONFIG_HASH,utc()) for did,_,_ in docs])
        con.execute('CHECKPOINT')
        if offset%5000==0:print(utc(),'dated mention resolution',offset+len(batch),'/',len(pending),flush=True)
    counts=dict(con.execute('SELECT life_class,count(*) FROM resolved_mentions GROUP BY life_class').fetchall())
    statuses=dict(con.execute('SELECT status,count(*) FROM title_mentions GROUP BY status').fetchall())
    # Papal dates apply to title-based incumbency, not legitimate historical named references.
    violations=con.execute('''SELECT count(*) FROM title_mentions t JOIN docs d USING(doc_id) WHERE status='resolved'
      AND contains(offices_json,'"Q19546"') AND
      ((qid='Q450675' AND d.date>'2025-04-21') OR (qid='Q6109517' AND d.date<'2025-05-08'))''').fetchone()[0]
    atomic_json(workdir()/'identity_resolution_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,documents=con.execute('SELECT count(*) FROM resolved_docs').fetchone()[0],
      life_classes=counts,title_statuses=statuses,title_phrases=len(mapping),official_title_aliases=len(aliases),papal_title_date_violations=violations,
      caveat='Unknown/ambiguous titles remain roles. Vocabulary comes from available HR/BS office labels and aliases; coverage is incomplete. Named historical quotations are not incumbent-date violations.'))
    con.close()
    if violations:raise RuntimeError('Dated papal title violations require correction before networks')

if __name__=='__main__':main()
