"""Surname blocking and complete-link compatibility; threshold sensitivity retained."""
import collections,hashlib,json
import pandas as pd
from voices_common import *
from name_forms import compatible

def cluster(forms,threshold):
    blocks=collections.defaultdict(list);isolated=[]
    for f in forms:
        words=f['nominative'].casefold().split()
        if len(words)<2 or f['status']!='agreed' or f['cue_class']=='conflicting':isolated.append([f])
        else:blocks[words[-1]].append(f)
    groups=isolated
    for surname,members in sorted(blocks.items()):
        local=[]
        for f in sorted(members,key=lambda r:(-r['documents'],r['form_id'])):
            matches=[g for g in local if all(compatible(f,other,threshold) for other in g)]
            # A bridge compatible with two established clusters does not merge them.
            if len(matches)==1:matches[0].append(f)
            else:local.append([f])
        groups.extend(local)
    aliases=[];entities=[]
    for members in groups:
        eid='E'+min(f['form_id'] for f in members)[:24]
        counts=collections.Counter()
        for f in members:counts[f['nominative']]+=f['documents']
        canonical=min(counts,key=lambda name:(-counts[name],name))
        entities.append((threshold,eid,canonical,json.dumps(sorted({f['cue_class'] for f in members})),
                         len(members),CORPUS_HASH,CONFIG_HASH,utc()))
        aliases.extend((threshold,f['form_id'],eid,CORPUS_HASH,CONFIG_HASH,utc()) for f in members)
    return aliases,entities

def main():
    con=connect()
    assert con.execute('SELECT count(*) FROM forms').fetchone()==con.execute('SELECT count(*) FROM form_lemmas').fetchone()
    pin_stage(con,'clusters_v1',dict(code=file_sha(__file__),rules=file_sha(STUDY/'name_forms.py'),thresholds=[.88,.9,.92],
      merge='complete-link, no ambiguous bridges, incompatible clergy/politics split',single_tokens='unresolved isolated forms'))
    con.execute('''CREATE TABLE IF NOT EXISTS aliases (threshold DOUBLE,form_id VARCHAR,entity_id VARCHAR,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(threshold,form_id))''')
    con.execute('''CREATE TABLE IF NOT EXISTS entities (threshold DOUBLE,entity_id VARCHAR,canonical VARCHAR,
      cue_classes_json VARCHAR,n_forms INTEGER,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,
      PRIMARY KEY(threshold,entity_id))''')
    frame=con.execute('''SELECT f.form_id,l.nominative,l.status,f.cue_class,count(DISTINCT m.doc_id) AS documents
      FROM forms f JOIN form_lemmas l USING(form_id) JOIN form_mentions m USING(form_id)
      GROUP BY ALL''').fetchdf()
    forms=frame.to_dict('records')
    for threshold in [.88,.9,.92]:
        if con.execute('SELECT count(*) FROM aliases WHERE threshold=?',[threshold]).fetchone()[0]==len(forms):continue
        print(utc(),'starting clusters',threshold,'forms',len(forms),flush=True)
        aliases,entities=cluster(forms,threshold)
        with transaction(con):
            con.execute('DELETE FROM aliases WHERE threshold=?',[threshold]);con.execute('DELETE FROM entities WHERE threshold=?',[threshold])
            af=pd.DataFrame(aliases,columns=['threshold','form_id','entity_id','corpus_sha256','config_hash','created_utc'])
            ef=pd.DataFrame(entities,columns=['threshold','entity_id','canonical','cue_classes_json','n_forms','corpus_sha256','config_hash','created_utc'])
            con.register('alias_input',af);con.register('entity_input',ef)
            con.execute('INSERT INTO aliases SELECT * FROM alias_input');con.execute('INSERT INTO entities SELECT * FROM entity_input')
            con.unregister('alias_input');con.unregister('entity_input')
        con.execute('CHECKPOINT');print(utc(),'clusters',threshold,len(entities),flush=True)
    con.execute('''CREATE TABLE IF NOT EXISTS entity_counts AS SELECT a.threshold,a.entity_id,
      count(*) AS mentions,count(DISTINCT m.doc_id) AS documents,count(DISTINCT d.source) AS outlets,
      count(DISTINCT d.platform) AS platforms,? AS corpus_sha256,? AS config_hash,? AS created_utc
      FROM aliases a JOIN form_mentions m USING(form_id) JOIN docs d USING(doc_id) GROUP BY a.threshold,a.entity_id''',
      [CORPUS_HASH,CONFIG_HASH,utc()])
    # Compare each baseline cluster's constituent forms with their alternative clusters.
    sensitivity=con.execute('''WITH top AS (SELECT * FROM entity_counts WHERE threshold=.9 ORDER BY documents DESC,entity_id LIMIT 300),
      mapped AS (SELECT DISTINCT t.entity_id,t.documents,b.threshold,b.entity_id AS alternative_id
        FROM top t JOIN aliases a ON a.entity_id=t.entity_id AND a.threshold=.9
        JOIN aliases b ON b.form_id=a.form_id AND b.threshold<>.9),
      overlap_counts AS (SELECT m.entity_id,m.documents,m.threshold,m.alternative_id,count(DISTINCT fm.doc_id) AS overlap
        FROM mapped m JOIN aliases a ON a.entity_id=m.entity_id AND a.threshold=.9
        JOIN aliases b ON b.form_id=a.form_id AND b.entity_id=m.alternative_id AND b.threshold=m.threshold
        JOIN form_mentions fm ON fm.form_id=a.form_id GROUP BY ALL),
      matched AS (SELECT * FROM overlap_counts QUALIFY row_number() OVER
        (PARTITION BY entity_id,threshold ORDER BY overlap DESC,alternative_id)=1)
      SELECT m.entity_id,m.documents,m.threshold,c.documents AS alternative_documents
        FROM matched m JOIN entity_counts c ON c.entity_id=m.alternative_id AND c.threshold=m.threshold
        ORDER BY m.entity_id,m.threshold''').fetchall()
    shifted={e for e,n,t,alt in sensitivity if abs(alt-n)/n>.05}
    denominator=min(300,con.execute('SELECT count(*) FROM entity_counts WHERE threshold=.9').fetchone()[0])
    atomic_json(workdir()/'cluster_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      check='M-ID-3',top_entities=denominator,shifted_over_five_percent=len(shifted),
      report_ranges=bool(denominator and len(shifted)/denominator>.1),
      detail=[dict(entity_id=e,baseline_documents=n,threshold=t,alternative_documents=alt) for e,n,t,alt in sensitivity],
      caveat='Unverified identity clusters. Single-token and morphologically ambiguous forms remain isolated; public naming requires Wikidata/office linkage and D6 thresholds.'))
    # Deterministic, private, unscored merged-form inspection sample.
    pairs=con.execute('''SELECT a.entity_id,f.surface,g.surface AS paired_surface
      FROM aliases a JOIN aliases b ON a.entity_id=b.entity_id AND a.threshold=b.threshold AND a.form_id<b.form_id
      JOIN forms f ON f.form_id=a.form_id JOIN forms g ON g.form_id=b.form_id
      WHERE a.threshold=.9 ORDER BY sha256(a.form_id || b.form_id || ?) LIMIT 500''',[str(CONFIG['seed'])]).fetchdf()
    atomic_json(workdir()/'cluster_pairs_private.json',pairs.to_dict('records'))
    con.execute('CHECKPOINT');con.close()

if __name__=='__main__':main()
