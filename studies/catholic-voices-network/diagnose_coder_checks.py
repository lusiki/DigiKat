"""Export saved constructed-case outcomes; never rerun or relabel source passages."""
import json
from voices_common import *
from synthetic_suite import fixtures,windows

def main():
    con=connect()
    if not con.execute("SELECT count(*) FROM information_schema.tables WHERE table_name='coder_check_calls'").fetchone()[0]:
        con.close();return
    report={}
    for run, in con.execute("SELECT DISTINCT run FROM coder_check_calls WHERE starts_with(run,'synthetic_') ORDER BY run").fetchall():
        saved={item:dict(attempt=attempt,**json.loads(raw)) for item,attempt,raw in con.execute(
          'SELECT item_id,attempt,response_json FROM coder_check_calls WHERE run=? ORDER BY attempt',[run]).fetchall()}
        checks_path=workdir()/(run+'_report.json')
        checks=json.loads(checks_path.read_text(encoding='utf-8')) if checks_path.exists() else {}
        by_id={r['id']:r for r in checks.get('checks',[])}
        items=[]
        for case in fixtures():
            outputs=[]
            for i,text in enumerate(windows(case)):
                item=case['id']+'_'+str(i);result=saved.get(item)
                outputs.append(dict(item_id=item,actual_window=text,saved=result is not None,
                  mechanical_errors=result['errors'] if result else None,
                  expanded=result.get('expanded',[]) if result else [],
                  raw_response=result.get('payload',{}).get('response') if result else None))
            items.append(dict(id=case['id'],case=case['case'],expected=case['expected'],
              check=by_id.get(case['id']),author=case['author'],candidates=case['names'],outputs=outputs))
        report[run]=dict(completed_check=bool(checks),passed=checks.get('passed'),cases=items)
    atomic_json(workdir()/'constructed_coder_diagnosis.json',dict(created_utc=utc(),
      corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,runs=report,
      note='Constructed fixture diagnostics only. Saved outputs are unchanged; no real-corpus accuracy coding. Missing cases remain missing.'))
    con.close();print('Saved constructed-case diagnostic export; original calls unchanged.',flush=True)

if __name__=='__main__':main()
