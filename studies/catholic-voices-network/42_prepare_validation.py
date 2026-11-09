"""Freeze actual-passage agreement/repeatability samples; no main labels yet."""
import hashlib,importlib,json
from voices_common import *
from active_protocol import VERSION
selection=importlib.import_module('02_prepare_remaining')

def choose(reports):
    reasons=[]
    for model in ['qwen3:14b','qwen3:8b']:
        synthetic=reports.get('synthetic_'+VERSION+'_'+model.replace(':','_'),{})
        speed=reports.get('benchmark_'+VERSION+'_'+model.replace(':','_'),{})
        if synthetic.get('synthetic_gate_passed') and speed.get('throughput_gate_passed'):
            return model,reasons
        reasons.append(dict(model=model,synthetic_passed=synthetic.get('synthetic_gate_passed'),throughput_passed=speed.get('throughput_gate_passed')))
    return None,reasons

def main():
    con=connect();reports={}
    assert con.execute('SELECT count(*) FROM candidate_docs').fetchone()[0]==MANIFEST['corpus']['rows']
    assert con.execute("SELECT count(*) FROM rule_sentence_results WHERE status='failed'").fetchone()[0]==0
    assert con.execute('SELECT count(*) FROM candidate_sentences WHERE needs_parse').fetchone()==con.execute("SELECT count(*) FROM rule_sentence_results WHERE status='complete'").fetchone()
    for model in ['qwen3:14b','qwen3:8b']:
        for prefix in ['synthetic_'+VERSION+'_','benchmark_'+VERSION+'_']:
            key=prefix+model.replace(':','_');path=workdir()/(key+'_report.json')
            if path.exists():
                report=json.loads(path.read_text(encoding='utf-8'))
                if report['corpus_sha256']!=CORPUS_HASH or report['config_hash']!=CONFIG_HASH:raise RuntimeError('Stale coder checks')
                reports[key]=report
    primary,reasons=choose(reports)
    atomic_json_stable(workdir()/'model_selection.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,primary=primary,comparator='gemma3:12b',decisions=reasons,
      main_authorized=False,reason='Constructed and throughput gate only; actual-passage agreement and repeatability pending.'))
    if not primary:con.close();raise SystemExit('No primary model has passed both preliminary gates; repair before main coding.')
    assert con.execute('SELECT count(*) FROM candidates').fetchone()==con.execute('SELECT count(*) FROM rule_window_results').fetchone()
    if con.execute('SELECT count(*) FROM candidates').fetchone()[0]<2000:raise RuntimeError('Insufficient population for the preregistered 2000-window check')
    pin_stage(con,'actual_validation_selection_v1',dict(code=file_sha(__file__),seed=CONFIG['seed'],
      agreement=2000,repeatability=1000,strata='platform x era',primary=primary,comparator='gemma3:12b'))
    selection.select_ids(con,'candidates','true','agreement_sample',2000)
    selection.select_ids(con,'agreement_sample','true','repeatability_sample',1000)
    assert con.execute('SELECT count(*) FROM agreement_sample').fetchone()[0]==2000
    assert con.execute('SELECT count(*) FROM repeatability_sample').fetchone()[0]==1000
    ids=[r[0] for r in con.execute('SELECT item_id FROM agreement_sample ORDER BY item_id').fetchall()]
    strata=con.execute('''SELECT s.platform,s.era,count(*) AS windows,count(DISTINCT c.doc_id) AS documents,
      max(s.population_n) AS population_windows FROM agreement_sample s JOIN candidates c USING(item_id) GROUP BY s.platform,s.era''').fetchdf()
    atomic_json_stable(workdir()/'validation_sample_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,primary=primary,agreement_windows=2000,repeatability_windows=1000,
      selection_sha256=hashlib.sha256('\n'.join(ids).encode()).hexdigest(),strata=strata.to_dict('records'),
      note='Stratified window sample, not a human-labelled sample; a document can contribute multiple windows.'))
    con.execute('CHECKPOINT');con.close()

if __name__=='__main__':main()
