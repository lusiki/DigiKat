"""Prepare full-corpus Level-A inputs independently of the LLM publication gate."""
import json
from voices_common import *
from network_inputs import materialize,read_labels
from office_register import read_cache,label
from cluster_ranges import materialize_ranges,RANGES_QUERY

def main():
    con=connect()
    assert con.execute('SELECT count(*) FROM resolved_docs').fetchone()[0]==MANIFEST['corpus']['rows']
    identity=json.loads((workdir()/'identity_resolution_report.json').read_text(encoding='utf-8'))
    if identity['papal_title_date_violations']:raise RuntimeError('Resolve dated identity violations before networks')
    assert con.execute('SELECT count(*) FROM circulation_membership WHERE threshold=.85').fetchone()==con.execute('SELECT count(*) FROM circulation_texts').fetchone()
    pin_stage(con,'network_inputs_v1',dict(code=file_sha(__file__),rules=file_sha(STUDY/'network_inputs.py'),
      range_rules=file_sha(STUDY/'cluster_ranges.py'),identity_rules=file_sha(STUDY/'wikidata_identity.py'),
      labels=file_sha(ROOT/'resources/dictionaries/source_labels.csv'),
      population='contemporary linked public people, >=20 documents, >=3 nonempty source values',
      paragraph='blank-line separated, identical to candidate-window paragraph definition',
      privacy='separate internal source IDs, aggregate display only'))
    materialize(con,read_labels())
    materialize_ranges(con)
    snapshot_time=con.execute('SELECT created_utc FROM network_input_snapshot').fetchone()[0]
    public_entities,_,_=read_cache(workdir()/'public_register_cache')
    public_names=[]
    for qid, in con.execute('SELECT entity_id FROM network_people WHERE d6 ORDER BY entity_id').fetchall():
        name=label(public_entities.get(qid,{'id':qid}))
        if name==qid:raise RuntimeError('Missing public label for an eligible identity: '+qid)
        public_names.append(dict(entity_id=qid,public_name=name,source='https://www.wikidata.org/wiki/'+qid))
    names_path=workdir()/'network_public_names.json'
    names_snapshot=dict(created_utc=snapshot_time,corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,people=public_names)
    if names_path.exists() and json.loads(names_path.read_text(encoding='utf-8'))!=names_snapshot:
        raise RuntimeError('Frozen public labels changed; use a new network input version')
    atomic_json(names_path,names_snapshot)
    names={r['entity_id']:r['public_name'] for r in public_names}
    destination=workdir()/'network_inputs';destination.mkdir(exist_ok=True)
    queries={
      'cluster_ranges':RANGES_QUERY,
      'people':'SELECT * FROM network_people WHERE d6 ORDER BY entity_id',
      'sources':'SELECT * FROM network_sources ORDER BY platform,source_id',
      'paragraphs':'''SELECT p.* FROM network_mention_paragraphs p JOIN network_people n USING(entity_id) WHERE n.d6 ORDER BY p.doc_id,p.entity_id,p.paragraph_id''',
      'appearances':'''SELECT p.*,d.platform,d.era,d.date,s.source_id,s.label,
        m.family_id FROM network_doc_entities p JOIN docs d USING(doc_id)
        JOIN network_sources s ON s.source=d.source AND s.platform=d.platform
        JOIN circulation_texts t ON t.text_sha256=d.text_sha256
        JOIN circulation_membership m ON m.text_id=t.text_id AND m.threshold=.85 ORDER BY p.doc_id,p.entity_id''',
      'denominators':'''SELECT platform,era,substr(date,1,4)||'-Q'||cast(ceil(cast(substr(date,6,2) AS INTEGER)/3.0) AS INTEGER) AS quarter,
        count(*) AS documents,count(*) FILTER(WHERE n_chars>=300) AS long_documents,
        ? AS corpus_sha256,? AS config_hash,? AS created_utc FROM docs GROUP BY platform,era,quarter ORDER BY platform,era,quarter'''}
    files={}
    for key,sql in queries.items():
        target=destination/(key+'.csv');temporary=target.with_suffix('.csv.tmp')
        frame=con.execute(sql,[CORPUS_HASH,CONFIG_HASH,snapshot_time] if key in {'denominators','cluster_ranges'} else []).fetchdf()
        if key=='people':frame['public_name']=frame['entity_id'].map(names)
        frame.to_csv(temporary,index=False,encoding='utf-8',lineterminator='\n')
        with temporary.open('rb+') as f:os.fsync(f.fileno())
        os.replace(temporary,target)
        files[key]=dict(rows=len(frame),sha256=file_sha(target),path=target.name)
    summary=dict(created_utc=snapshot_time,corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      documents=con.execute('SELECT count(*) FROM network_mention_docs').fetchone()[0],
      public_people=con.execute('SELECT count(*) FROM network_people WHERE d6').fetchone()[0],
      below_d6_people=con.execute('SELECT count(*) FROM network_people WHERE NOT d6').fetchone()[0],
      files=files,publication_level='A',
      public_names_sha256=file_sha(names_path),
      caveat='Private intermediate inputs. Unresolved/historical/sacred people excluded from named networks. All text lengths included in mentions. Hidden sources retain separate internal identities. Paragraphs are blank-line separated; missing blank lines can make a whole text one paragraph. No speech or influence claim.')
    atomic_json(workdir()/'network_inputs_report.json',summary)
    con.execute('CHECKPOINT');con.close();print(json.dumps(summary))

if __name__=='__main__':main()
