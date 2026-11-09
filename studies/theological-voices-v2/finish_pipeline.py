"""Complete the authorized study, withdrawing unsupported claims instead of hiding failures."""
import argparse
import json
import os
import time
import traceback
from datetime import datetime, timezone
from prepare import OUT, STUDY, save_json
from coder import get_config_hash, config
from archive_config import archive
import run_pipeline as runner

def read(name):
    path=OUT/name
    return json.loads(path.read_text(encoding='utf-8')) if path.exists() else {}

def resume():
    lock=OUT/'pipeline.pid'
    with lock.open('x',encoding='ascii') as f:f.write(str(os.getpid()))
    try:
        initial=get_config_hash();runner.RUN_CONFIG=initial
        runner.RUN_STARTED=datetime.now(timezone.utc).isoformat()
        runner.update('startup','running',completion_policy='Withdraw failed content claims; preserve complete accounting')
        archive()
        # A completed probe report with a failed expected rule is research evidence.
        # A missing report or incomplete run remains a technical error.
        try:runner.command('statement_boundary_probes',[str(STUDY/'diagnostics.py'),'probes'])
        except RuntimeError:
            probe=read('statement_probe_review.json')
            if (OUT/'STOP').exists() or probe.get('config_hash')!=initial or len(probe.get('checks',[]))!=4:raise
        runner.command('synthetic_diagnostics',[str(STUDY/'diagnostics.py'),'run'])
        diag=read('diagnostic_review.json')
        if diag.get('config_hash')!=initial or len(diag.get('checks',[]))!=30:
            raise RuntimeError('All 30 diagnostic outcomes must be preserved before development')
        runner.command('development_100',[str(STUDY/'coder.py'),'run','--set','development'])
        if read('candidate_freeze.json').get('config_hash')!=initial:
            save_json(OUT/'candidate_freeze.json',{'config_hash':initial,'created_at':datetime.now(timezone.utc).isoformat(),
                'configuration':config(),'meaning':'Candidate fixed before the independent fresh machine challenge; no human validation.'})
        runner.command('fresh_challenge_primary_30',[str(STUDY/'coder.py'),'run','--set','challenge'])
        runner.command('fresh_challenge_alternative_30',[str(STUDY/'coder.py'),'run','--set','challenge','--challenge'])
        runner.command('freeze_coder',[str(STUDY/'report_policy.py')])
        if get_config_hash()!=initial:raise RuntimeError('Coding configuration changed during checks')
        runner.command('main_sample_2000',[str(STUDY/'coder.py'),'run','--set','main'])
        runner.command('aggregate',[str(STUDY/'analyse.py')])
        runner.command('verify_analysis',[str(STUDY/'verify.py'),'analysis'])
        runner.command('build_pdf',[str(STUDY/'build_report.py')])
        runner.command('verify_pdf',[str(STUDY/'verify.py'),'pdf'])
        runner.update('visual_review','awaiting_visual_review',pdf=str(OUT/'report'/'tko-dobiva-rijec-o-vjeri-v2.pdf'),
            note='All 2,000 main outcomes saved; PDF rendered and mechanically checked. Actual page inspection remains required.',
            report_mode=read('report_policy.json')['report_mode'])
    except BaseException as e:
        runner.update('stopped','needs_attention',failed_stage=runner.LAST_STAGE,error=str(e),traceback=traceback.format_exc())
        raise
    finally:
        if lock.exists() and lock.read_text().strip()==str(os.getpid()):lock.unlink()

def after_current():
    # Never interrupt an inference or compete for the SQLite/model pipeline.
    expected=read('pipeline_status.json').get('config_hash')
    save_json(OUT/'completion_supervisor.json',{'pid':os.getpid(),'state':'waiting_for_current_controller',
        'config_hash':expected,'started_at':datetime.now(timezone.utc).isoformat()})
    while (OUT/'pipeline.pid').exists():time.sleep(15)
    current=read('pipeline_status.json')
    if current.get('state') in {'awaiting_visual_review','complete'}:
        save_json(OUT/'completion_supervisor.json',{'pid':os.getpid(),'state':'current_controller_finished',
            'updated_at':datetime.now(timezone.utc).isoformat()})
        return
    if current.get('config_hash')!=expected or get_config_hash()!=expected:
        raise RuntimeError('Configuration changed while waiting; refusing an implicit relabelled run')
    if (OUT/'STOP').exists():raise RuntimeError('STOP requested; completion supervisor will not override it')
    permitted={'statement_boundary_probes','synthetic_diagnostics','freeze_coder'}
    if current.get('state')!='needs_attention' or current.get('failed_stage') not in permitted:
        raise RuntimeError('Current run stopped for a technical error requiring inspection: '+str(current.get('error')))
    save_json(OUT/'completion_supervisor.json',{'pid':os.getpid(),'state':'resuming_with_explicit_claim_policy',
        'config_hash':expected,'updated_at':datetime.now(timezone.utc).isoformat()})
    resume()

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--after-current',action='store_true');args=parser.parse_args()
    after_current() if args.after_current else resume()
