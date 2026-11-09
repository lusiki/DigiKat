"""Freeze publication eligibility before main coding; preserve failed machine checks."""
import json
from datetime import datetime, timezone
from pathlib import Path
from prepare import OUT, STUDY, save_json, file_sha
from coder import get_config_hash
from diagnostics import audit

TASKS=('topics','mentions','speakers','groups')
POLICY={
    'version':'1.0',
    'structural_target':0.95,
    'decision':'Any failed synthetic rule, statement probe, or essential-task processing target withdraws all model-derived numerical content claims from the reader-facing PDF. Full-frame deterministic results and processing diagnostics remain reportable.',
    'why_conservative':'Speaker roles, interpretation, experience and source completeness share dependent passes. Withholding all content estimates avoids presenting a dependent estimate as reliable after a failed primary check.',
    'main_run':'Read the entire unchanged 2,000-publication main sample even in limited exploratory mode. Preserve task-specific outputs, failures and audit tables. Never replace failed records or treat failure as absence.',
    'accuracy':'Not measured; a pass only establishes the stated machine checks, never empirical classification accuracy.',
}

def decide(config_hash, quality, diagnostic, probes):
    reasons=[]
    for label, value, count in [('diagnostics',diagnostic,30),('statement probes',probes,4)]:
        if value.get('config_hash')!=config_hash or len(value.get('checks',[]))!=count:
            raise RuntimeError(f'Incomplete or mismatched {label}; this is not an eligible research run')
    for name, expected in [('development',100),('challenge',30),('challenge_challenge',30)]:
        q=quality.get('sets',{}).get(name,{})
        if q.get('articles')!=expected:raise RuntimeError(f'{name} must account for exactly {expected} publications')
        rates=q.get('task_validity_rates',{})
        if set(rates)!=set(TASKS):raise RuntimeError(f'Missing task accounting for {name}')
        for task,rate in rates.items():
            if rate<.95:reasons.append({'kind':'processing_target','set':name,'task':task,'actual':rate,'target':.95})
        for task,rate in q.get('segmented_task_validity_rates',{}).items():
            if rate<.95:reasons.append({'kind':'long_text_processing','set':name,'task':task,'actual':rate,'target':.95})
    for c in diagnostic['checks']:
        if c['failures'] or c['structural_status']!='complete':
            reasons.append({'kind':'synthetic_rule','id':c['id'],'case':c['case'],
                            'structural_status':c['structural_status'],'failures':c['failures']})
    for c in probes['checks']:
        if not c['passed']:reasons.append({'kind':'statement_probe',**c})
    return {'config_hash':config_hash,'created_at':datetime.now(timezone.utc).isoformat(),
            'policy':POLICY,'report_mode':'limited_exploratory' if reasons else 'full_exploratory',
            'model_content_numbers_eligible':not reasons,'withdrawal_reasons':reasons,
            'human_validation':False,'classification_accuracy':'not measured'}

def freeze():
    chash,_,_=audit()
    read=lambda name:json.loads((OUT/name).read_text(encoding='utf-8'))
    result=decide(chash,read('development_review.json'),read('diagnostic_review.json'),read('statement_probe_review.json'))
    result['policy_code_sha256']=file_sha(Path(__file__))
    policy_archive=OUT/'configs'/chash/'report_policy_source.py'
    policy_archive.parent.mkdir(parents=True,exist_ok=True)
    policy_archive.write_bytes(Path(__file__).read_bytes())
    save_json(OUT/'report_policy.json',result)
    save_json(OUT/'configs'/chash/'report_policy_before_main.json',result)
    save_json(OUT/'coder_freeze.json',{'config_hash':chash,'main_authorized_by_checks':True,
        'authorization_meaning':'All required development and challenge articles were attempted under one frozen configuration. The saved report policy determines which claims may be published; failures are not declared passed.',
        'created_at':result['created_at'],'development_articles':100,'fresh_challenge_articles':30,
        'diagnostics':30,'machine_only':True,'classification_accuracy':'not measured',
        'report_mode':result['report_mode'],'report_policy_file':'report_policy.json',
        'configuration_file':f'configs/{chash}.json'})
    print(json.dumps({'report_mode':result['report_mode'],'withdrawal_reasons':len(result['withdrawal_reasons'])}))

if __name__=='__main__':freeze()
