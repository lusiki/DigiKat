"""Isolated typography exercise. Every page explicitly says SYNTHETIC TEST."""
import json
from pathlib import Path
import pandas as pd
import build_report as b
import limited_report as limited
from prepare import OUT as actual_out

out=Path('tmp/pdfs/theological-v2-limited-layout').resolve()
out.mkdir(parents=True,exist_ok=True)
for module in [b,limited]:
    module.OUT=out;module.REPORT=out;module.FIG=out/'figures';module.PNG=out/'pages'
class TestReport(b.Report):
    def new(self,kicker,title,deck=''):
        super().new('SINTETSKI TEST / '+kicker,title,deck)
    def finish(self):
        self.c.setTitle('SYNTHETIC LAYOUT TEST — NOT THE REPORT')
        super().finish()
limited.Report=TestReport
def write(name,value):(out/name).write_text(json.dumps(value,ensure_ascii=False),encoding='utf-8')
frame=json.loads((actual_out/'freeze.json').read_text(encoding='utf-8'))
policy={'config_hash':'SYNTHETIC','model_content_numbers_eligible':False,'report_mode':'limited_exploratory','withdrawal_reasons':[{'synthetic':True}]}
write('report_policy.json',policy)
synthetic_members=[{'publication_id':f'SYNTHETIC-{i}','outlet_name':f'SINTETSKI IZVOR {i}',
    'published_at':f'2026-01-0{i}','title':'SINTETSKI NASLOV ZA PROVJERU PRIJELOMA: primjer dovoljno dugoga naslova za ogledni raspored stranice',
    'url':'https://example.invalid/synthetic-'+str(i)} for i in range(1,5)]
write('deterministic_reuse_cases.json',{'cases':[{'id':kind,'span_days':span,'publications':5,'outlets':5,
      'first_date':'2026-01-01','last_date':'2026-01-01' if span==0 else '2026-01-02',
      'text_hash':'SYNTHETIC-TEST-ONLY','display_members':[dict(m,published_at='2026-01-02' if span and i==3 else '2026-01-01') for i,m in enumerate(synthetic_members)]}
      for kind,span in [('same_day',0),('separated_dates',1)]]})
(out/'configs').mkdir(exist_ok=True)
write('configs/SYNTHETIC.json',{'configuration':{'version':'3.2.0-SYNTHETIC','think':False,
      'options':{'num_ctx':32768,'num_predict':8192,'temperature':0,'seed':20261017}},
      'environment':{'runtime':{'version':'SYNTHETIC'}}})
write('development_review.json',{'sets':{name:{'articles':count,'task_validity_rates':{k:.93 for k in ['topics','mentions','speakers','groups']},
    'segmented_articles':23,'topic_disagreements':26,'segmented_task_validity_rates':{k:.87 for k in ['topics','mentions','speakers','groups']}}
    for name,count in [('development',100),('challenge',30),('challenge_challenge',30)]}})
write('diagnostic_review.json',{'checks':[{'id':f'D{i:03}','case':'synthetic_test_case','structural_status':'complete',
    'failures':[{'test':True}] if i%4==0 else []} for i in range(30)]})
write('statement_probe_review.json',{'checks':[{'passed':i!=0} for i in range(4)]})
write('challenge_disagreements.json',{'comparisons':[{'relevance_disagreement':True,'role_disagreement':i%2==0,'source_completeness_disagreement':i%3==0} for i in range(30)]})
def read(name):
    if name=='source_concentration.csv':
        df=pd.read_csv(actual_out/'tables'/'frame_source.csv');df['share_pct']=100*df.publications/frame['publications'];return df
    return pd.read_csv(actual_out/'tables'/name)
limited.read=read
data={'config_hash':'SYNTHETIC','completed_main':2000,'sample':2000,'frame':frame,'top5_source_share_pct':45.5,
    'reuse':{'eligible_publications':250000,'publications_in_repeated_families':80000,'publications_in_cross_outlet_families':35000},
    'status_counts':{'complete':1800,'partial_processing':100,'failed':25,'missing_text':75},
    'input_delivery_counts':{'confirmed_full':1800,'incomplete_or_unconfirmed':125,'missing_text':75},
    'source_content_counts':{'complete':1500,'partial':350,'unresolved':70,'unavailable':75,'unreadable':5},
    'bases':{k:{'structurally_valid':1900} for k in ['topics','mentions','speakers','groups']}}
limited.build_limited(data,policy)
pdf=out/'tko-dobiva-rijec-o-vjeri-v2.pdf'
pdf.replace(out/'SYNTHETIC-layout-test.pdf')
print('SYNTHETIC layout exercise only; no actual main results were supplied.')
