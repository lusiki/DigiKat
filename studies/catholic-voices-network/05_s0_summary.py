"""Reconcile persisted results and write the combined S0 status."""
import json
from voices_common import *

def main():
    con=connect()
    paths={'ner':'pilot_report.json','parsing':'pilot_parse_report.json','llm':'pilot_llm_report.json','minhash':'minhash_report.json'}
    reports={k:json.loads((workdir()/p).read_text(encoding='utf-8')) for k,p in paths.items()}
    assert reports['ner']['ner_complete'] and reports['parsing']['complete'] and reports['minhash']['complete']
    assert con.execute('SELECT count(*) FROM docs LEFT JOIN minhash_signatures USING(text_sha256) WHERE minhash_signatures.text_sha256 IS NULL').fetchone()[0]==0
    assert con.execute('SELECT count(*) FROM minhash_signatures WHERE signature IS NOT NULL AND octet_length(signature)<>512').fetchone()[0]==0
    assert con.execute('SELECT count(*) FROM minhash_signatures WHERE (word_count<5)<>(signature IS NULL)').fetchone()[0]==0
    assert con.execute('SELECT count(*) FROM pilot_window_candidates w JOIN pilot_llm_sample USING(item_id) WHERE length(text)>1200').fetchone()[0]==0
    assert con.execute('''SELECT count(*) FROM pilot_window_candidates w JOIN pilot_llm_sample s USING(item_id)
      JOIN docs d ON d.doc_id=w.doc_id WHERE substr(d.text_clean,w.start_char+1,w.end_char-w.start_char)<>w.text''').fetchone()[0]==0
    assert con.execute('''SELECT count(*) FROM (SELECT item_id FROM pilot_quote_sample UNION SELECT item_id FROM pilot_morph_sample) s
      LEFT JOIN pilot_parse_results r USING(item_id) WHERE r.item_id IS NULL''').fetchone()[0]==0
    for r in reports['llm']['results']:assert r['processed']==300
    models={r['model'] for r in reports['llm']['results']}
    assert all({r['mode'] for r in reports['llm']['results'] if r['model']==m}=={'single','parallel4'} for m in models)
    choices=[r for r in reports['llm']['results'] if r['mode']=='parallel4' and r['gate']=='pass']
    selected='qwen3:14b' if any(r['model']=='qwen3:14b' for r in choices) else ('qwen3:8b' if choices else None)
    atomic_json(workdir()/'s0_status.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      requested_stages_complete=True,persisted_checks='passed',selected_throughput_model=selected,
      reports=reports,ready_for_main_llm=False,
      next='S4 synthetic suite, cross-model agreement and determinism remain mandatory before main LLM coding; S1 NER not launched by this runner.',
      human_validation=False))
    con.close();print(f'{utc()} Requested S0 stages complete; throughput model={selected}; summary saved.',flush=True)

if __name__=='__main__':main()
