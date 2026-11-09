"""Public-identity count sensitivity, retaining splits and excluding identity collisions.

These are clustering scenarios, not confidence intervals. Public IDs stay frozen;
an alternative cluster is never allowed to join two already linked identities.
"""
import json
from functools import lru_cache
from voices_common import CORPUS_HASH, CONFIG_HASH, utc, transaction
from wikidata_identity import classification


def materialize_ranges(con):
    con.execute('''CREATE TABLE IF NOT EXISTS network_cluster_scenarios (
      threshold DOUBLE,entity_id VARCHAR,documents BIGINT,ambiguous_clusters BIGINT,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,
      PRIMARY KEY(threshold,entity_id))''')
    con.execute('''CREATE TABLE IF NOT EXISTS network_cluster_scenario_runs (
      threshold DOUBLE PRIMARY KEY,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    people=[r[0] for r in con.execute('SELECT entity_id FROM network_people WHERE d6 ORDER BY entity_id').fetchall()]
    facts={}
    for qid,raw in con.execute('SELECT qid,facts_json FROM entity_links WHERE qid IS NOT NULL').fetchall():
        facts.setdefault(qid,[]).append(json.loads(raw))

    @lru_cache(maxsize=100000)
    def contemporary(qid,date):
        return bool(facts.get(qid)) and all(classification(f.get('label',''),f,date)=='contemporary' for f in facts[qid])

    for threshold in [.88,.9,.92]:
        if con.execute('SELECT count(*) FROM network_cluster_scenario_runs WHERE threshold=?',[threshold]).fetchone()[0]:continue
        counts={qid:set() for qid in people};ambiguous={qid:set() for qid in people}
        if threshold==.9:
            for did,qid in con.execute('SELECT doc_id,entity_id FROM network_doc_entities').fetchall():counts[qid].add(did)
        else:
            # Greatest shared-document overlap, one alternative per baseline E.
            # Selecting all children would conceal the effect of a split.
            con.execute('''CREATE OR REPLACE TEMP TABLE scenario_matches AS
              WITH shared_counts AS (
                SELECT a.entity_id AS baseline_id,b.entity_id AS alternative_id,l.qid,
                  count(DISTINCT m.doc_id) AS overlap
                FROM aliases a JOIN aliases b ON a.form_id=b.form_id AND b.threshold=?
                JOIN entity_links l ON l.entity_id=a.entity_id AND l.qid IS NOT NULL
                JOIN form_mentions m ON m.form_id=a.form_id WHERE a.threshold=.9 GROUP BY ALL)
              SELECT * FROM shared_counts QUALIFY row_number() OVER
                (PARTITION BY baseline_id ORDER BY overlap DESC,alternative_id)=1''',[threshold])
            # Check every linked constituent, including non-D6 identities, not
            # just whichever alternative won the overlap comparison above.
            con.execute('''CREATE OR REPLACE TEMP TABLE scenario_conflicts AS
              SELECT b.entity_id AS alternative_id,count(DISTINCT l.qid)>1 AS conflicting
              FROM aliases a JOIN aliases b ON a.form_id=b.form_id AND b.threshold=?
              JOIN entity_links l ON l.entity_id=a.entity_id AND l.qid IS NOT NULL
              WHERE a.threshold=.9 GROUP BY b.entity_id''',[threshold])
            for qid,aid in con.execute('''SELECT DISTINCT m.qid,m.alternative_id FROM scenario_matches m
              JOIN scenario_conflicts c USING(alternative_id) WHERE c.conflicting''').fetchall():
                if qid in ambiguous:ambiguous[qid].add(aid)
            rows=con.execute('''SELECT DISTINCT s.qid,m.doc_id,d.date FROM scenario_matches s
              JOIN scenario_conflicts c USING(alternative_id)
              JOIN network_people n ON n.entity_id=s.qid AND n.d6
              JOIN aliases a ON a.entity_id=s.alternative_id AND a.threshold=?
              JOIN form_mentions m USING(form_id) JOIN docs d ON d.doc_id=m.doc_id
              WHERE NOT c.conflicting ORDER BY s.qid,m.doc_id''',[threshold]).fetchall()
            for qid,did,date in rows:
                if contemporary(qid,date):counts[qid].add(did)
            # Dated office assignments do not depend on name clustering.
            for did,qid in con.execute('''SELECT DISTINCT r.doc_id,r.qid FROM resolved_mentions r
              JOIN network_people n ON n.entity_id=r.qid AND n.d6
              WHERE r.origin='dated_title' AND r.life_class='contemporary' ''').fetchall():counts[qid].add(did)
        stamp=utc()
        with transaction(con):
            if people:con.executemany('INSERT INTO network_cluster_scenarios VALUES (?,?,?,?,?,?,?)',
              [(threshold,q,len(counts[q]),len(ambiguous[q]),CORPUS_HASH,CONFIG_HASH,stamp) for q in people])
            con.execute('INSERT INTO network_cluster_scenario_runs VALUES (?,?,?,?)',[threshold,CORPUS_HASH,CONFIG_HASH,stamp])
        con.execute('CHECKPOINT')


RANGES_QUERY='''SELECT entity_id,
  max(documents) FILTER(WHERE threshold=.9) AS baseline_documents,
  min(documents) AS minimum_documents,max(documents) AS maximum_documents,
  max(ambiguous_clusters) AS maximum_ambiguous_clusters,
  ? AS corpus_sha256,? AS config_hash,? AS created_utc
  FROM network_cluster_scenarios GROUP BY entity_id ORDER BY entity_id'''
