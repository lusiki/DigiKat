"""Unattended, resumable local batch with fail-closed research gates."""
from __future__ import annotations
import argparse, json, os, subprocess, sys, time, traceback
from datetime import datetime, timezone
from pathlib import Path
from prepare import STUDY, OUT, save_json, file_sha
from coder import get_config_hash, config
from archive_config import archive

ROOT=STUDY.parents[1]
RUN_CONFIG=None
RUN_STARTED=None
LAST_STAGE=None
STAGE_STARTED=None

def update(stage,state,**extra):
    global LAST_STAGE,STAGE_STARTED
    now=datetime.now(timezone.utc).isoformat()
    changed=LAST_STAGE!=stage
    if changed:STAGE_STARTED=now;LAST_STAGE=stage
    value={'stage':stage,'state':state,'pid':os.getpid(),'updated_at':now,'config_hash':RUN_CONFIG,
           'run_started_at':RUN_STARTED,'stage_started_at':STAGE_STARTED,**extra}
    save_json(OUT/'pipeline_status.json',value);print(json.dumps(value),flush=True)
    if changed or state!='running':
        with open(OUT/'progress_events.jsonl','a',encoding='utf-8') as event:
            event.write(json.dumps({k:v for k,v in value.items() if k not in {'traceback','command'}},ensure_ascii=False)+'\n')

def command(stage,args):
    update(stage,'running',command=args)
    with open(OUT/'pipeline.log','a',encoding='utf-8',buffering=1) as log:
        log.write('\n'+datetime.now(timezone.utc).isoformat()+' '+stage+'\n')
        proc=subprocess.Popen([sys.executable,*args],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,
                              env={**os.environ,'PYTHONIOENCODING':'utf-8','PYTHONUNBUFFERED':'1'})
        while proc.poll() is None:
            time.sleep(15)
            update(stage,'running',child_pid=proc.pid,command=args)
        if proc.returncode:raise RuntimeError(f'{stage} exited {proc.returncode}; inspect pipeline.log')
    if (OUT/'STOP').exists():raise RuntimeError('STOP file present; halted at safe boundary. Completed results remain reusable.')

def run():
    global RUN_CONFIG,RUN_STARTED
    OUT.mkdir(parents=True,exist_ok=True)
    pidfile=OUT/'pipeline.pid'
    # Atomic lock prevents two controllers writing one run. Stale locks must be inspected explicitly.
    with open(pidfile,'x',encoding='ascii') as f:f.write(str(os.getpid()))
    try:
        initial=get_config_hash();RUN_CONFIG=initial;RUN_STARTED=datetime.now(timezone.utc).isoformat()
        update('startup','running',config_hash=initial)
        archive()
        command('statement_boundary_probes',[str(STUDY/'diagnostics.py'),'probes'])
        command('synthetic_diagnostics',[str(STUDY/'diagnostics.py'),'run'])
        diag=json.loads((OUT/'diagnostic_review.json').read_text(encoding='utf-8'))
        if len(diag['checks'])!=30 or any(x['failures'] or x['structural_status']!='complete' for x in diag['checks']):
            raise RuntimeError('Synthetic diagnostic gate failed. Main sample has NOT started.')
        command('development_100',[str(STUDY/'coder.py'),'run','--set','development'])
        save_json(OUT/'candidate_freeze.json',{'config_hash':initial,'created_at':datetime.now(timezone.utc).isoformat(),
          'configuration':config(),'meaning':'Final candidate fixed before fresh automated challenge; no human validation.'})
        command('fresh_challenge_primary_30',[str(STUDY/'coder.py'),'run','--set','challenge'])
        command('fresh_challenge_alternative_30',[str(STUDY/'coder.py'),'run','--set','challenge','--challenge'])
        command('freeze_coder',[str(STUDY/'diagnostics.py'),'freeze'])
        if get_config_hash()!=initial:raise RuntimeError('Configuration changed during gates; a new labelled run is required')
        command('main_sample_2000',[str(STUDY/'coder.py'),'run','--set','main'])
        command('aggregate',[str(STUDY/'analyse.py')])
        command('verify_analysis',[str(STUDY/'verify.py'),'analysis'])
        command('build_pdf',[str(STUDY/'build_report.py')])
        command('verify_pdf',[str(STUDY/'verify.py'),'pdf'])
        update('visual_review','awaiting_visual_review',config_hash=initial,
               pdf=str(OUT/'report'/'tko-dobiva-rijec-o-vjeri-v2.pdf'),
               note='All main articles processed; PDF built and pages rendered. Actual visual inspection is still required before delivery.')
    except BaseException as e:
        update('stopped','needs_attention',failed_stage=LAST_STAGE,error=str(e),traceback=traceback.format_exc())
        raise
    finally:
        if pidfile.exists() and pidfile.read_text().strip()==str(os.getpid()):pidfile.unlink()

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('command',choices=['run','status']);a=p.parse_args()
    if a.command=='run':run()
    else:
        for f in ['pipeline_status.json','status.json']:
            if (OUT/f).exists():print((OUT/f).read_text(encoding='utf-8'))
