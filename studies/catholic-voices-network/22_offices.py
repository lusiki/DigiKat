"""Build the normalized public snapshot; import after the NER database writer exits."""
import argparse,json
from voices_common import *
from office_register import build,holder

def main():
    p=argparse.ArgumentParser();p.add_argument('--snapshot-only',action='store_true');args=p.parse_args()
    folder=workdir()/'public_register_cache'
    manifest=json.loads((folder/'manifest.json').read_text(encoding='utf-8'))
    if not manifest['complete']:raise RuntimeError('Public retrieval incomplete; rerun 22_offices_fetch.py')
    snapshot=workdir()/'office_register.json'
    existing=json.loads(snapshot.read_text(encoding='utf-8')) if snapshot.exists() else None
    code_hash=file_sha(STUDY/'office_register.py');source_hash=file_sha(folder/'manifest.json')
    if existing and existing.get('register_code')==code_hash and existing.get('fetch_manifest_sha')==source_hash:
        # Freeze the snapshot, including its retrieval lineage. Later name-link
        # caches and fresh timestamps must not invalidate completed stages.
        result=existing
    else:
        result=build(folder)
        result.update(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
          register_code=code_hash,fetch_manifest_sha=source_hash)
        atomic_json(snapshot,result)
    rows=result['offices']
    audit=dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      statements=len(rows),people=len(result['people']),dated_usable=sum(r['date_usable'] for r in rows),
      missing_entities=len(result['missing_entities']),
      excluded_nonhuman_or_untyped=len(result['excluded_nonhuman_or_untyped']),
      pope_date_examples={date:holder(rows,'Q19546',date) for date in ['2025-04-20','2025-04-22','2025-05-07','2025-05-09']},
      caveat='Broad machine-discovered register. Undated positions are not current incumbencies. Coverage audit and title mapping remain required.')
    atomic_json(workdir()/'office_register_audit.json',audit);print(json.dumps(audit,ensure_ascii=False))
    if args.snapshot_only:return
    con=connect();pin_stage(con,'office_register_v1',dict(source=result['fetch_manifest_sha'],code=result['register_code']))
    con.execute('''CREATE TABLE IF NOT EXISTS offices (statement_id VARCHAR PRIMARY KEY,entity_qid VARCHAR,
      office_qid VARCHAR,office_label_hr VARCHAR,place_json VARCHAR,start_earliest VARCHAR,start_latest VARCHAR,
      end_earliest VARCHAR,end_latest VARCHAR,date_usable BOOLEAN,source VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    with transaction(con):
        for r in rows:con.execute('INSERT OR IGNORE INTO offices VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
          [r['statement_id'],r['entity_qid'],r['office_qid'],r['office_label_hr'],json.dumps(r['places'],ensure_ascii=False),
           r['start_earliest'],r['start_latest'],r['end_earliest'],r['end_latest'],r['date_usable'],r['source'],CORPUS_HASH,CONFIG_HASH,utc()])
    con.execute('CHECKPOINT');con.close()

if __name__=='__main__':main()
