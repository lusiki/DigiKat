"""End-to-end denominator test with synthetic records in disposable storage."""
import contextlib
import io
import json
import sqlite3
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import pandas as pd
import analyse


class AnalysisTest(unittest.TestCase):
    def test_uncertainty_partial_and_missing_sources_have_distinct_bases(self):
        with tempfile.TemporaryDirectory() as folder:
            out=Path(folder);(out/'tables').mkdir()
            sample=pd.DataFrame([{'publication_id':key,'outlet_name':'Synthetic source','outlet_id':'test',
              'published_at':'2026-01-01','stratum':'2026Q1','sampling_weight':1.,'inclusion_probability':1.,
              'text_length':100,'input_hash':key,'title':'Synthetic input','url':'https://example.invalid/'+key,
              'text_hash':key} for key in 'ABCDEF'])
            sample.to_parquet(out/'main_inputs.parquet')
            sample.to_parquet(out/'frame.parquet')
            pd.DataFrame([{'outlet_name':'Synthetic source','outlet_id':'test','publications':6}]).to_csv(out/'tables'/'frame_source.csv',index=False)
            (out/'freeze.json').write_text(json.dumps({'source_sha256':'synthetic-only','publications':6}),encoding='utf-8')
            (out/'report_policy.json').write_text(json.dumps({'config_hash':'synthetic',
                'model_content_numbers_eligible':False,'report_mode':'limited_exploratory'}),encoding='utf-8')
            db=sqlite3.connect(out/'coding.sqlite')
            db.executescript('''CREATE TABLE articles(set_name TEXT,config_hash TEXT,result_json TEXT);
              CREATE TABLE calls(set_name TEXT,publication_id TEXT,segment INTEGER,task TEXT,attempt INTEGER,
                status TEXT,error TEXT,seconds REAL,config_hash TEXT,request_json TEXT,response_json TEXT);''')
            def voice(key,role,interpretation,experience):
                return {'name':'Synthetic '+key,'organisation':'','actor_key':key,'role':role,
                  'identity_ids':['P0001'],'statement_ids':['P0001'],'mode':'direct',
                  'interprets_faith':interpretation,'own_experience':experience}
            results={}
            for key in 'ABCDEF':
                available=key!='F';complete=key not in 'DF'
                results[key]={'publication_id':key,'status':'complete' if available else 'missing_text',
                  'source_content':'complete' if complete else 'partial' if key=='D' else 'unavailable',
                  'segments_expected':1 if available else 0,'relevance':'central','main_theme':'worship_spirituality',
                  'mentions':[],'voices':[],'affected_groups':[],'passages':{'P0001':'Synthetic test evidence.'},
                  'task_validity':{task:available for task in ['topics','mentions','speakers','groups']},
                  'complete_article_base':{task:complete for task in ['topics','mentions','speakers','groups']},
                  'speaker_decision_status':'resolved','unresolved_speaker_decisions':[]}
            results['A']['voices']=[voice('A','academic_theologian','yes','yes')]
            results['A']['affected_groups']=[{'group':'Synthetic group','consequence':'Synthetic consequence','evidence_ids':['P0001']}]
            results['C']['voices']=[{**voice('C','unresolved','unresolved','unresolved'),
                                    'model_proposed_role':'other','role_adjustment':'Unestablished capacity'}]
            results['D']['voices']=[voice('D','priest_religious','no','no')]
            results['E'].update(speaker_decision_status='unresolved',unresolved_speaker_decisions=[{'candidate_index':0}])
            results['E']['complete_article_base']['speakers']=False
            results['F'].pop('speaker_decision_status')
            results['F']['passages']={}
            for result in results.values():
                db.execute('INSERT INTO articles VALUES (?,?,?)',('main','synthetic',json.dumps(result)))
                if result['status']!='missing_text':
                    db.execute('INSERT INTO calls(set_name,publication_id,config_hash,request_json,response_json) VALUES(?,?,?,?,?)',
                        ('main',result['publication_id'],'synthetic',json.dumps({'messages':[{'role':'user','content':'[P0001] Synthetic test evidence.'}]}),json.dumps({'eval_count':1})))
            db.commit();db.close()
            with patch.object(analyse,'OUT',out),patch.object(analyse,'CFG',{'sample_size':6,'run_id':'synthetic'}), \
                 patch.object(analyse,'get_config_hash',return_value='synthetic'),contextlib.redirect_stdout(io.StringIO()):
                analyse.main()
            summary=json.loads((out/'report_data.json').read_text(encoding='utf-8'))
            self.assertEqual(summary['bases']['speakers']['structurally_valid'],5)
            self.assertEqual(summary['bases']['speakers']['complete_article_valid'],3)
            self.assertEqual(summary['interpretation_base']['n'],2)
            self.assertEqual(summary['experience_base']['n'],2)
            self.assertEqual(summary['no_speaker_complete'],1)
            self.assertEqual(summary['status_counts']['missing_text'],1)
            self.assertEqual(summary['input_delivery_counts'],{'confirmed_full':5,'missing_text':1})
            self.assertEqual(summary['unresolved_speaker_articles'],1)
            claims=json.loads((out/'claims.json').read_text(encoding='utf-8'))
            self.assertTrue(all(x['publication_status']=='withheld' for x in claims if x['id'].startswith(('role_','interpretation_','theme_','experience_'))))
            self.assertTrue(all(x['publication_status']=='eligible_exploratory' for x in claims if x['id'] in {'frame','source_concentration','exact_reuse'}))
            voices=pd.read_csv(out/'tables'/'voices.csv').set_index('publication_id')
            self.assertEqual(voices.loc['C','model_proposed_role'],'other')
            roles=pd.read_csv(out/'tables'/'speaker_roles.csv').set_index('role')
            interpreters=pd.read_csv(out/'tables'/'interpreter_roles.csv').set_index('role')
            self.assertAlmostEqual(roles.loc['academic_theologian','article_prevalence_weighted_pct'],100/3)
            self.assertEqual(interpreters.loc['academic_theologian','article_prevalence_weighted_pct'],50)
            overlap=pd.read_csv(out/'tables'/'experience_overlap.csv')
            self.assertTrue((overlap.denominator==2).all())
            self.assertEqual(overlap.n.sum(),2)


if __name__=='__main__':unittest.main()
