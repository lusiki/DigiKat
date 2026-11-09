"""Check persisted parse/offset plumbing before continuing beyond 100 sentences."""
import json
from voices_common import *

def main():
    con=connect()
    n_needed=con.execute('SELECT count(*) FROM candidate_sentences WHERE needs_parse').fetchone()[0]
    rows=con.execute('''SELECT s.text,r.status,r.parsed_json FROM candidate_sentences s
      JOIN rule_sentence_results r USING(item_id)''').fetchall()
    failed=0;bad_offsets=0
    for text,status,raw in rows:
        if status!='complete':failed+=1;continue
        for token in json.loads(raw):
            if text[token['start']:token['end']]!=token['surface']:bad_offsets+=1
    passed=len(rows)>=min(100,n_needed) and failed==0 and bad_offsets==0
    atomic_json(workdir()/'rule_smoke_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,sentences=len(rows),failed=failed,bad_token_offsets=bad_offsets,passed=passed,
      note='Mechanical source alignment only; semantic attribution accuracy remains unmeasured.'))
    con.close()
    if not passed:raise SystemExit('Rule parsing smoke failed; persisted outputs require diagnosis before full continuation.')
    print('Rule parsing smoke passed:',len(rows),'sentences.')

if __name__=='__main__':main()
