"""Summarize completed configurations without turning failed gates into findings."""
import json
from voices_common import *

def main():
    plan=ROOT/'quality_reports/plans/2026-10-25_catholic-voices-network-machine-only.md'
    assert '52/54' in plan.read_text(encoding='utf-8')
    records=[];sources={}
    for version in ['v4','v5']:
        for model in ['qwen3:14b','qwen3:8b','gemma3:12b']:
            stem='synthetic_'+version+'_'+model.replace(':','_');path=workdir()/(stem+'_report.json')
            if not path.exists():raise RuntimeError('Constructed check still missing: '+stem)
            report=json.loads(path.read_text(encoding='utf-8'))
            assert report['corpus_sha256']==CORPUS_HASH and report['config_hash']==CONFIG_HASH
            assert report['n']==54 and len(report['checks'])==54
            assert report['passed']==sum(r['passed'] for r in report['checks'])
            assert report['synthetic_gate_passed']==(report['passed']>=52)
            sources[path.name]=file_sha(path)
            record=dict(protocol=version,model=model,cases=54,passed=report['passed'],
              synthetic_gate_passed=report['synthetic_gate_passed'],source=path.name,
              suite_sha256=report['suite_hash'],failed_case_ids=[r['id'] for r in report['checks'] if not r['passed']])
            speed_path=workdir()/('benchmark_'+version+'_'+model.replace(':','_')+'_report.json')
            if speed_path.exists():
                speed=json.loads(speed_path.read_text(encoding='utf-8'))
                assert speed['corpus_sha256']==CORPUS_HASH and speed['config_hash']==CONFIG_HASH
                sources[speed_path.name]=file_sha(speed_path)
                record['benchmark']={k:speed[k] for k in ['n','completed','calls','json_valid_first',
                  'mechanically_accepted_first','final_failed','unfinished','effective_seconds_per_window','throughput_gate_passed']}
            else:record['benchmark']=None
            records.append(record)
    assert len({r['suite_sha256'] for r in records})==1
    primary=[r for r in records if r['model'].startswith('qwen3:')]
    any_synthetic=any(r['synthetic_gate_passed'] for r in primary)
    status='preliminary_gate_failed' if not any_synthetic else 'further_checks_required'
    report=dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      plan_sha256=file_sha(plan),source_sha256=sources,synthetic_required=52,synthetic_total=54,
      configurations=records,primary_synthetic_pass_exists=any_synthetic,status=status,
      main_authorized=False,publication_levels={key:'withdrawn' if not any_synthetic else 'pending' for key in ['speaks','interpretive','authority','relations']},
      cross_model_agreement='not_run; preliminary prerequisite failed' if not any_synthetic else 'pending',
      distillation='not_authorized_without_qualified_labels',
      decision='Continue identity/mention/circulation networks and report quality failures. These configurations cannot support model-derived speech or interpretation findings.' if not any_synthetic else 'Require throughput, grounding, actual-passage agreement and repeatability before main coding.',
      verification='Reconciled atomic reports and fixed-suite assertions; final completion audit must also reconcile database calls.',
      caveat='Failure of these configurations is not proof that a model can never perform the task. Complete JSON and literal source IDs do not establish semantic correctness.')
    atomic_json_stable(workdir()/'model_gate_summary.json',report)
    print(json.dumps(dict(status=status,configurations=[{k:r[k] for k in ['protocol','model','passed']} for r in records],main_authorized=False)))

if __name__=='__main__':main()
