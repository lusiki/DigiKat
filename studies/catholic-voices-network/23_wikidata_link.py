"""Link up to 1500 frequent entities: public facts, exact names, consistent roles.

No article, passage, URL or account identifier is sent. Search is limited to
multi-token name forms with explicit public-role cues; others use the cached
public office register only. Uncertain/multiple matches remain unresolved.
"""
import argparse,collections,importlib,json
from voices_common import *
from office_register import read_cache,label,claims
from wikidata_identity import norm,names,is_human,role_matches,person_facts,SACRED
fetch=importlib.import_module('22_offices_fetch')

def main():
    p=argparse.ArgumentParser();p.add_argument('--limit',type=int,default=1500);args=p.parse_args()
    if not 1<=args.limit<=1500:raise ValueError('Plan caps name-linking queries at 1500 entities')
    con=connect();cached,_,_=read_cache(workdir()/'public_register_cache')
    register=json.loads((workdir()/'office_register.json').read_text(encoding='utf-8'))
    office_humans={r['entity_qid'] for r in register['offices']};index=collections.defaultdict(set)
    papal_humans={r['entity_qid'] for r in register['offices'] if r['office_qid']=='Q19546'}
    for qid in office_humans:
        if qid in cached and is_human(cached[qid]):
            for n in names(cached[qid]):index[n].add(qid)
    pin_stage(con,'wikidata_links_v1',dict(code=file_sha(__file__),rules=file_sha(STUDY/'wikidata_identity.py'),
      public_cache_code=file_sha(STUDY/'22_offices_fetch.py'),max_entities=1500,
      policy='exact alias/full-name match plus role consistency; no ambiguous acceptance; no text uploaded'))
    con.execute('''CREATE TABLE IF NOT EXISTS entity_links (entity_id VARCHAR PRIMARY KEY,qid VARCHAR,status VARCHAR,
      facts_json VARCHAR,candidates_json VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    selected=con.execute('''SELECT e.entity_id,e.canonical,e.cue_classes_json FROM entities e JOIN entity_counts c
      ON c.entity_id=e.entity_id AND c.threshold=e.threshold WHERE e.threshold=.9
      ORDER BY c.documents DESC,e.entity_id LIMIT ?''',[args.limit]).fetchall()
    done={r[0] for r in con.execute('SELECT entity_id FROM entity_links').fetchall()}
    for i,(eid,canonical,cues) in enumerate(selected,1):
        if eid in done:continue
        aliases=[r[0] for r in con.execute('''SELECT DISTINCT l.nominative FROM aliases a JOIN form_lemmas l USING(form_id)
            WHERE a.threshold=.9 AND a.entity_id=?''',[eid]).fetchall()]
        candidates=set();roles=set(json.loads(cues))&{'clergy','politics'}
        cue_strings=[r[0] for r in con.execute('''SELECT DISTINCT m.cue FROM aliases a JOIN form_mentions m USING(form_id)
          WHERE a.threshold=.9 AND a.entity_id=? AND m.cue<>'' LIMIT 30''',[eid]).fetchall()]
        import re
        if re.search(r'prof|teolog',' '.join(cue_strings)):roles.add('academic')
        normalized={norm(n) for n in aliases+[canonical]}
        sacred=any(n in SACRED for n in normalized)
        for n in normalized:
            # A bare given name does not uniquely establish an identity, even if
            # only one person with that name happens to be in this register.
            if len(n.split())>=2:candidates.update(index.get(n,set()))
            elif re.search(r'\bpap',' '.join(cue_strings)):
                # A papal given name plus an explicit pope cue can match a
                # unique registered pope; its life class remains date-specific.
                candidates.update(index.get(n,set()) & papal_humans)
        search_evidence=[]
        if not sacred and roles and len(norm(canonical).split())>=2:
            response=fetch.cached('identity_search',eid,fetch.API,dict(action='wbsearchentities',search=canonical,
              language='hr',uselang='hr',format='json',limit=5))
            search_evidence=response.get('search',[])
            new_ids=[r['id'] for r in search_evidence]
            if new_ids:
                response=fetch.cached('identity_entities',eid,fetch.API,dict(action='wbgetentities',ids='|'.join(new_ids),
                  props='labels|aliases|descriptions|claims',languages='hr|en|bs',format='json'))
                cached.update(response.get('entities',{}));candidates.update(new_ids)
        acceptable=[]
        for qid in candidates:
            entity=cached.get(qid,{})
            if not is_human(entity) or not normalized.intersection(names(entity)):continue
            extra=[]
            for prop in ['P106','P39']:
                for value in claims(entity,prop):
                    if isinstance(value,dict) and value.get('id') in cached:extra.append(label(cached[value['id']]))
            consistent=role_matches(entity,roles,extra) if roles else qid in office_humans
            if consistent:acceptable.append(qid)
        qid=acceptable[0] if len(acceptable)==1 and not sacred else None
        status='sacred' if sacred else 'linked' if qid else 'ambiguous' if len(acceptable)>1 else 'unresolved'
        facts=person_facts(cached[qid]) if qid else {}
        with transaction(con):con.execute('INSERT INTO entity_links VALUES (?,?,?,?,?,?,?,?)',
          [eid,qid,status,json.dumps(facts,ensure_ascii=False),json.dumps(dict(acceptable=sorted(acceptable),
           searched=search_evidence,role_cues=sorted(roles)),ensure_ascii=False),CORPUS_HASH,CONFIG_HASH,utc()])
        if i%25==0:con.execute('CHECKPOINT');print(utc(),'public-name linkage',i,'/',len(selected),flush=True)
    summary=dict(con.execute('SELECT status,count(*) FROM entity_links GROUP BY status').fetchall())
    atomic_json(workdir()/'wikidata_link_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,selected=len(selected),statuses=summary,
      naming_policy='Linked public figure AND at least 20 documents AND 3 outlets; life status evaluated per document.',
      limitations='Exact-match conservative linking, public-role-cued searches only; no verified identity accuracy. Single given names and office-title-only mentions require a separate dated office resolution layer.'))
    con.execute('CHECKPOINT');con.close()

if __name__=='__main__':main()
