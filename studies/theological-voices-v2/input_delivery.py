"""Audit actual model requests, distinct from merely planned passage coverage."""
import json
import sqlite3
from prepare import OUT, save_json
from coder import get_config_hash


def audit(db, results, config_hash):
    lookup={r['publication_id']:r for r in results}
    expected={pid:{k:v for k,v in r['passages'].items() if k!='H001'} for pid,r in lookup.items()}
    delivered={pid:set() for pid in lookup};headlines={pid:False for pid in lookup}
    responses={pid:0 for pid in lookup}
    query="""SELECT publication_id,request_json FROM calls
             WHERE set_name='main' AND config_hash=?
               AND coalesce(json_extract(response_json,'$.eval_count'),0)>0"""
    for pid,raw in db.execute(query,(config_hash,)):
        if pid not in lookup:continue
        responses[pid]+=1
        request=json.loads(raw)
        users=[m['content'] for m in request.get('messages',[]) if m.get('role')=='user']
        # First user message contains supplied source, not a later retry instruction.
        source=users[0] if users else ''
        for key,value in expected[pid].items():
            if key not in delivered[pid] and f'[{key}] {value}' in source:delivered[pid].add(key)
        title=lookup[pid]['passages'].get('H001')
        if title is not None and f'[H001] {title}' in source:headlines[pid]=True
    rows=[]
    for pid,r in lookup.items():
        missing=set(expected[pid])-delivered[pid]
        title_ok='H001' not in r['passages'] or headlines[pid]
        status='missing_text' if r['status']=='missing_text' else (
            'confirmed_full' if expected[pid] and not missing and title_ok else 'incomplete_or_unconfirmed')
        rows.append({'publication_id':pid,'expected_body_passages':len(expected[pid]),
            'confirmed_body_passages':len(delivered[pid]),'headline_confirmed':headlines[pid],
            'requests_with_model_output':responses[pid], 'coverage_status':status,
            'unconfirmed_body_ids':json.dumps(sorted(missing)), 'processing_status':r['status']})
    return sorted(rows,key=lambda r:r['publication_id'])


if __name__=='__main__':
    chash=get_config_hash();db=sqlite3.connect((OUT/'coding.sqlite').as_uri()+'?mode=ro',uri=True)
    results=[json.loads(r[0]) for r in db.execute("SELECT result_json FROM articles WHERE set_name='main' AND config_hash=?",(chash,))]
    rows=audit(db,results,chash);counts={k:sum(r['coverage_status']==k for r in rows)
        for k in ['confirmed_full','incomplete_or_unconfirmed','missing_text']}
    save_json(OUT/'input_delivery_checkpoint.json',{'config_hash':chash,'records':len(rows),'counts':counts,
        'note':'Actual recorded requests with model output; confirms supplied input, not understanding or accuracy.'})
    print(json.dumps({'saved_records':len(rows),'input_delivery':counts}));db.close()
