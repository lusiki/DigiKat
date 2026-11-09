"""Read-only progress server, bound to this computer. Never serves article text."""
from __future__ import annotations
import argparse, json, os, sqlite3, time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

STUDY=Path(__file__).resolve().parent
OUT=STUDY/'output'/'private'
UI=STUDY/'progress'/'index.html'
LABELS={
 'startup':'Starting the workflow','statement_boundary_probes':'Checking statements versus announcements',
 'synthetic_diagnostics':'Testing the coding rules',
 'development_100':'Developing the article coder','fresh_challenge_primary_30':'Checking fresh articles',
 'fresh_challenge_alternative_30':'Challenging the first results','freeze_coder':'Checking the coding configuration',
 'main_sample_2000':'Reading the 2,000-article sample','aggregate':'Calculating the findings',
 'verify_analysis':'Verifying the numbers and evidence','build_pdf':'Building the report',
 'verify_pdf':'Checking the PDF','visual_review':'Reviewing the rendered pages',
 'stopped':'The workflow needs attention','revision':'A correction was made'}
CASES={
 'mention_only':'Mentions without statements','unrelated_quote':'Unrelated quotations',
 'experience':'A believer’s own experience','prediction':'Predictions about other people',
 'theologian':'An explicitly identified theologian','priest_not_academic':'Priest versus academic theologian',
 'separated_attribution':'Identity and statement in separate passages','paywall':'A subscription teaser',
 'institution':'An institutional statement','mass_schedule':'A schedule versus interpretation',
 'ambiguous_source':'An unknown speaking capacity','narrator':'Unattributed narration',
 'expert_own_experience':'An expert’s own experience','headline_body_mismatch':'Different headline and body topics',
 'late_long_statement':'A statement at the end of a long article','long_separated_identity':'Attribution across a long article',
 'appended_recommendation':'Recommendations appended to an article','religious_sister':'A religious sister’s speaking role'}
SET_LABELS={'statement_probe':'Statement boundary check','diagnostic':'Rule test','development':'Development article','challenge':'Fresh challenge',
            'challenge_challenge':'Alternative challenge','main':'Main-sample article'}

def read_json(path,default=None):
    for attempt in range(2):
        try:return json.loads(path.read_text(encoding='utf-8'))
        except (OSError,ValueError):
            if not attempt:time.sleep(.02)
    return default if default is not None else {}

def parse_date(value):
    try:return datetime.fromisoformat(value.replace('Z','+00:00'))
    except (AttributeError,ValueError):return None

def rows(db,sql,args=()):return [dict(x) for x in db.execute(sql,args)]

def snapshot():
    now=datetime.now(timezone.utc)
    pipeline=read_json(OUT/'pipeline_status.json');freeze=read_json(OUT/'freeze.json')
    review=read_json(OUT/'diagnostic_review.json');config_hash=pipeline.get('config_hash') or review.get('config_hash')
    configuration=read_json(OUT/'configs'/f'{config_hash}.json').get('configuration',{})
    policy=read_json(OUT/'report_policy.json')
    if policy.get('config_hash')!=config_hash:policy={}
    sets={};calls=[];recent=[];history=[];call_summary={'requests':0,'retries':0,'failed_requests':0,'seconds':0}
    dbpath=OUT/'coding.sqlite'
    if dbpath.exists():
        db=sqlite3.connect(dbpath.as_uri()+'?mode=ro',uri=True,timeout=3);db.row_factory=sqlite3.Row
        try:
            if not config_hash:
                last=db.execute('SELECT config_hash FROM calls ORDER BY created_at DESC LIMIT 1').fetchone()
                if last:config_hash=last[0]
            for row in rows(db,"""SELECT set_name,count(*) AS done,
              sum(json_extract(result_json,'$.status')='complete') AS complete,
              sum(json_extract(result_json,'$.status')='partial_processing') AS partial,
              sum(json_extract(result_json,'$.status')='failed') AS failed,
              sum(json_extract(result_json,'$.status')='missing_text') AS missing,
              coalesce(sum(json_extract(result_json,'$.elapsed_seconds')),0) AS seconds
              FROM articles WHERE config_hash=? GROUP BY set_name""",(config_hash,)):
                sets[row['set_name']]=row
            cs=rows(db,"""SELECT count(*) AS requests,coalesce(sum(attempt>0),0) AS retries,
              coalesce(sum(status!='valid'),0) AS failed_requests,coalesce(sum(seconds),0) AS seconds
              FROM calls WHERE config_hash=?""",(config_hash,))
            if cs:call_summary=cs[0]
            recent=rows(db,"""SELECT set_name,segment,task,attempt,status,seconds,created_at
              FROM calls WHERE config_hash=? ORDER BY created_at DESC LIMIT 7""",(config_hash,))
            for x in recent:x['label']=SET_LABELS.get(x['set_name'],x['set_name'])
            history=rows(db,"""SELECT config_hash,count(*) AS requests,round(sum(seconds),1) AS seconds,
              max(created_at) AS last_activity FROM calls GROUP BY config_hash ORDER BY last_activity DESC""")
        finally:db.close()
    checks=review.get('checks',[]) if review.get('config_hash')==config_hash else []
    diag_done=len(checks);diag_pass=sum(not c['failures'] and c['structural_status']=='complete' for c in checks)
    failures=[{'label':CASES.get(c['case'],c['case']),'id':c['id'],'details':c['failures'],
               'processing':c['structural_status']} for c in checks if c['failures'] or c['structural_status']!='complete']
    main=sets.get('main',{});dev=sets.get('development',{});ch1=sets.get('challenge',{});ch2=sets.get('challenge_challenge',{})
    active=pipeline.get('stage','startup')
    if active=='stopped':active=pipeline.get('failed_stage') or ('synthetic_diagnostics' if failures else 'startup')
    stage_index={'synthetic_diagnostics':2,'development_100':3,'fresh_challenge_primary_30':4,
      'fresh_challenge_alternative_30':4,'freeze_coder':4,'main_sample_2000':5,'aggregate':6,
      'verify_analysis':6,'build_pdf':7,'verify_pdf':7,'visual_review':8}.get(active,2)
    state=pipeline.get('state','not_started');heartbeat=parse_date(pipeline.get('updated_at'))
    age=(now-heartbeat).total_seconds() if heartbeat else None
    stale=bool(state=='running' and (age is None or age>90))
    analysis=read_json(OUT/'analysis_verification.json');pdfcheck=read_json(OUT/'report'/'mechanical_verification.json')
    visual=read_json(OUT/'report'/'visual_review.json')
    pdfpath=OUT/'report'/'tko-dobiva-rijec-o-vjeri-v2.pdf'
    definitions=[
      ('Prepare the corpus',1 if freeze else 0,1, f'{freeze.get("publications",0):,} distinct web publications'),
      ('Freeze the sample',freeze.get('main_size',0),2000,'Random sample, proportional by quarter'),
      ('Test the coding rules',diag_done,30,f'{diag_pass} passed · {len(failures)} need attention'),
      ('Develop on real articles',dev.get('done',0),100,'A separate development set'),
      ('Run a fresh challenge',ch1.get('done',0)+ch2.get('done',0),60,'30 articles, two local configurations'),
      ('Read the main sample',main.get('done',0),2000,'Each article is read and verified'),
      ('Calculate and verify findings',int(analysis.get('failed')==0),1,'Check weights, counts and evidence links'),
      ('Build and check the PDF',int(bool(pdfcheck)),1,'Generate and render every page'),
      ('Review the final pages',int(visual.get('status')=='complete'),1,'Visual review before delivery')]
    stages=[]
    for i,(label,done,total,detail) in enumerate(definitions):
        completed=done>=total and (i!=2 or diag_pass==30)
        phase_state='complete' if completed else 'pending'
        if i==2 and diag_done==30 and failures and stage_index>2:
            phase_state='complete_with_issues'
        if i==stage_index and state=='running':phase_state='stale' if stale else 'running'
        elif i==stage_index and state=='needs_attention':phase_state='needs_attention'
        elif i==8 and state=='awaiting_visual_review':phase_state='needs_review'
        stages.append({'label':label,'done':done,'total':total,'detail':detail,'state':phase_state})
    inference=read_json(OUT/'inference_status.json')
    if inference.get('config_hash')!=config_hash:inference={}
    started=parse_date(inference.get('started_at'))
    current_request=None
    if inference.get('state')=='running' and state=='running' and not stale:
        current_request={'label':SET_LABELS.get(inference.get('set'),'Article'),
          'task':{'extract':'Reading and extracting evidence','verify':'Verifying statements and attribution',
                  'classify':'Classifying capacity, interpretation and experience'}.get(inference.get('task'),'Processing evidence'),
          'segment':inference.get('segment'), 'attempt':inference.get('attempt'),
          'started_at':inference.get('started_at'),'elapsed_seconds':max(0,(now-started).total_seconds()) if started else 0}
    events=[]
    try:
        for line in (OUT/'progress_events.jsonl').read_text(encoding='utf-8').splitlines()[-25:]:
            try:
                x=json.loads(line);events.append({'time':x.get('updated_at'),'label':LABELS.get(x.get('stage'),x.get('stage')),
                  'state':x.get('state'),'detail':x.get('note') or x.get('error') or ''})
            except ValueError:pass
    except OSError:pass
    eta=None
    if main.get('done',0)>=10 and state=='running' and stage_index==5 and not stale:
        eta={'remaining_seconds':(2000-main['done'])*main.get('seconds',0)/main['done'],
             'basis_articles':main['done'],'note':'Rough estimate from completed main articles, including retries; article length varies.'}
    return {'generated_at':now.isoformat(),'title':'Tko dobiva riječ o vjeri?','version':configuration.get('version'),
      'state':state,'stale':stale,'stage':LABELS.get(active,active),'active_stage_index':stage_index,
      'heartbeat_at':pipeline.get('updated_at'),'run_started_at':pipeline.get('run_started_at'),
      'stage_started_at':pipeline.get('stage_started_at'),'error':pipeline.get('error'),
      'frame':{'publications':freeze.get('publications',0),'sample':freeze.get('main_size',0),
               'period':'1 Jan 2021 – 11 Jun 2026'},'stages':stages,
      'diagnostics':{'done':diag_done,'passed':diag_pass,'target':30,'failures':failures},
      'main':{'done':main.get('done',0),'target':2000,'complete':main.get('complete',0),
              'partial':main.get('partial',0),'failed':main.get('failed',0),'missing':main.get('missing',0)},
       'requests':call_summary,'current_request':current_request,'recent_requests':recent,'eta':eta,
       'report_policy':{'mode':policy.get('report_mode'),'withdrawn':policy.get('model_content_numbers_eligible') is False},
      'events':list(reversed(events))[:12],
      'history':[{'version':read_json(OUT/'configs'/f'{h["config_hash"]}.json').get('configuration',{}).get('version','Earlier'),
                  'requests':h['requests'],'seconds':h['seconds'],'current':h['config_hash']==config_hash} for h in history],
      'report':{'available':pdfpath.exists(),'reviewed':visual.get('status')=='complete','pages':pdfcheck.get('pages')},
      'model':'Qwen3 14B · runs on this computer','refresh_seconds':5}

class Handler(BaseHTTPRequestHandler):
    def log_message(self,*args):pass
    def do_GET(self):
        path=urlsplit(self.path).path
        try:
            if path=='/':content=UI.read_bytes();mime='text/html; charset=utf-8'
            elif path=='/api/status':content=json.dumps(snapshot(),ensure_ascii=False).encode('utf-8');mime='application/json; charset=utf-8'
            elif path=='/report.pdf':
                p=OUT/'report'/'tko-dobiva-rijec-o-vjeri-v2.pdf'
                if not p.exists():self.send_error(404);return
                content=p.read_bytes();mime='application/pdf'
            elif path=='/favicon.ico':self.send_response(204);self.end_headers();return
            else:self.send_error(404);return
            self.send_response(200);self.send_header('Content-Type',mime);self.send_header('Content-Length',str(len(content)))
            self.send_header('Cache-Control','no-store');self.send_header('X-Content-Type-Options','nosniff');self.end_headers()
            self.wfile.write(content)
        except (BrokenPipeError,ConnectionResetError):pass
        except Exception:
            self.send_error(503,'Progress data temporarily unavailable; retry in a moment.')

def main():
    p=argparse.ArgumentParser();p.add_argument('--port',type=int,default=8767);args=p.parse_args()
    server=ThreadingHTTPServer(('127.0.0.1',args.port),Handler)
    info={'url':f'http://127.0.0.1:{args.port}/','pid':os.getpid(),'started_at':datetime.now(timezone.utc).isoformat()}
    (OUT/'progress_server.json').write_text(json.dumps(info,indent=2),encoding='utf-8')
    print(info['url'],flush=True)
    try:server.serve_forever(poll_interval=.5)
    finally:server.server_close()

if __name__=='__main__':main()
