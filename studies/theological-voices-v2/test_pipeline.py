"""Small scientific-method tests: text coverage, inclusion weights and distinct bases."""
import unittest
from unittest.mock import patch
import numpy as np
import pandas as pd
from coder import split_passages, segments, dedup_voices, source_quality_flags, accepted_voice, code_article, normalized_voice, uncertain_voice
from prepare import proportional
from analyse import role_measures, article_flag

class PipelineTests(unittest.TestCase):
    def test_long_text_tail_and_coverage(self):
        text=('Ovo je odlomak. '+('Dodatna rečenica s hrvatskim znakovima čćžšđ. '*300))+'\nVažan iskaz na samom kraju.'
        p=split_passages(text);b=segments(p)
        self.assertGreater(len(b),1)
        self.assertIn('Važan iskaz na samom kraju.',list(p.values())[-1])
        self.assertEqual({x for seg in b for x in seg},set(p))

    def test_proportional_allocation_and_weights(self):
        d=pd.DataFrame({'stratum':['2021Q1']*710+['2021Q2']*290+['2021Q3']*13,'id':range(1013)})
        s,a=proportional(d,200,np.random.default_rng(71))
        self.assertEqual(len(s),200);self.assertTrue(s.id.is_unique)
        self.assertTrue(np.isclose(s.sampling_weight.sum(),len(d)))
        self.assertTrue(np.allclose(s.inclusion_probability*s.sampling_weight,1))
        self.assertEqual(int(a.n_h.sum()),200)

    def test_census_if_small(self):
        d=pd.DataFrame({'stratum':['2021Q1']*4+['2021Q2']*3,'id':range(7)})
        s,_=proportional(d,200,np.random.default_rng(71))
        self.assertEqual(len(s),7);self.assertTrue((s.sampling_weight==1).all())

    def test_three_speaker_denominators(self):
        a=pd.DataFrame([{'publication_id':'a','speakers_base':True,'sampling_weight':2},
                        {'publication_id':'b','speakers_base':True,'sampling_weight':3},
                        {'publication_id':'c','speakers_base':True,'sampling_weight':5},
                        {'publication_id':'failed','speakers_base':False,'sampling_weight':20}])
        v=pd.DataFrame([{'publication_id':'a','actor_key':str(i),'role':'bishop','sampling_weight':2} for i in range(3)]+
                       [{'publication_id':'b','actor_key':'x','role':'academic_theologian','sampling_weight':3}])
        r=role_measures(a,v).set_index('role')
        self.assertEqual(r.loc['bishop','actor_role_n'],3)
        self.assertEqual(r.loc['bishop','article_role_n'],1)
        self.assertAlmostEqual(r.loc['bishop','actor_role_share_weighted_pct'],100*6/9)
        self.assertEqual(r.loc['bishop','role_presence_share_weighted_pct'],40)
        self.assertEqual(r.loc['bishop','article_prevalence_weighted_pct'],20)
        self.assertEqual(r.loc['bishop','valid_articles'],3)

    def test_unnamed_roles_are_not_automatically_same_person(self):
        def voice(name,pid):
            return {'name':name,'organisation':'','role':'personal_experience','identity_ids':[pid],
              'statement_ids':[pid],'mode':'direct','interprets_faith':'no','own_experience':'yes'}
        self.assertEqual(len(dedup_voices([voice('jedna vjernica','P0001'),voice('jedna vjernica','P0008')])),2)
        merged=dedup_voices([voice('Ana Markić','P0001'),voice('Ana Markić','P0008')])
        self.assertEqual(len(merged),1)
        self.assertEqual(set(merged[0]['statement_ids']),{'P0001','P0008'})

    def test_recommendation_boundary_is_not_silently_complete(self):
        self.assertEqual(source_quality_flags('Gotov članak.\nPREPORUČUJEMO DRUGU VIJEST: Drugi sadržaj.'),['appended_recommendation_marker'])
        self.assertEqual(source_quality_flags('Gotov članak.\nPročitajte i: Druga vijest.'),['appended_recommendation_marker'])
        self.assertEqual(source_quality_flags('Profesor je preporučio čitanje i rekao: pročitajte i zaključak.'),[])

    def test_announcements_cannot_count_as_confirmed_statements(self):
        base={'proposition_status':'stated','proposition_summary':'Molitva povezuje zajednicu.',
              'topic_related':'yes','attribution_established':'yes','mode':'paraphrase'}
        self.assertTrue(accepted_voice(base))
        for field,value in [('proposition_status','announcement_only'),('proposition_status','unresolved'),
                            ('proposition_summary','  '),('attribution_established','unresolved')]:
            self.assertFalse(accepted_voice({**base,field:value}))

    def test_uncertain_statement_is_not_a_valid_zero_speaker_article(self):
        candidate={'name':'Ana','organisation':'','identity_ids':['P0001'],'statement_ids':['P0001'],'mode':'paraphrase'}
        extracted={'candidates':[candidate],'mentions':[],'affected_groups':[],
                   'content':'complete','relevance':'central','main_theme':'worship_spirituality','headline_relevance':'central'}
        voice={**candidate,'candidate_index':0,'proposition_status':'unresolved','proposition_summary':'',
               'topic_related':'yes','attribution_established':'unresolved','role':'unresolved',
               'interprets_faith':'unresolved','own_experience':'no'}
        verified={'voices':[voice],'affected_groups':[],'rejected_candidates':[],
                  'content_check':'complete','topic_check':'central'}
        meta={'field_errors':{},'seconds':0}
        row={'publication_id':'TEST','input_hash':'test','title':'Test',
             'body_clean':'Ana je razgovarala o molitvi.','outlet_name':'Test','published_at':'2026-01-01'}
        with patch('coder.infer',side_effect=[(extracted,meta),(verified,meta)]):
            result=code_article(None,row,'test','test')
        self.assertTrue(result['task_validity']['speakers'])
        self.assertEqual(result['speaker_decision_status'],'unresolved')
        self.assertFalse(result['complete_article_base']['speakers'])
        self.assertEqual(len(result['unresolved_speaker_decisions']),1)

    def test_unresolved_experience_is_not_absence(self):
        self.assertIsNone(article_flag([{'own_experience':'no'},{'own_experience':'unresolved'}],'own_experience'))
        self.assertTrue(article_flag([{'own_experience':'yes'},{'own_experience':'unresolved'}],'own_experience'))
        self.assertFalse(article_flag([{'own_experience':'no'}],'own_experience'))
        self.assertFalse(article_flag([],'own_experience'))

    def test_unestablished_capacity_preserves_unknown_and_original_proposal(self):
        proposed={'role':'other','capacity_basis':'unresolved'}
        normalized=normalized_voice(proposed)
        self.assertEqual(normalized['role'],'unresolved')
        self.assertEqual(normalized['model_proposed_role'],'other')
        self.assertEqual(proposed['role'],'other')
        explicit={'role':'other','capacity_basis':'explicit_occupation_office_or_organisation'}
        self.assertEqual(normalized_voice(explicit),explicit)

    def test_lived_experience_does_not_require_an_occupation(self):
        proposed={'role':'personal_experience','capacity_basis':'unresolved','own_experience':'yes'}
        normalized=normalized_voice(proposed)
        self.assertEqual(normalized['role'],'personal_experience')
        self.assertEqual(normalized['capacity_basis'],'explicit_personal_experience')
        self.assertEqual(proposed['capacity_basis'],'unresolved')
        self.assertEqual(normalized_voice({**proposed,'own_experience':'unresolved'})['role'],'unresolved')

    def test_definite_rejection_is_not_an_uncertain_voice(self):
        negative={'proposition_status':'no_statement','topic_related':'unresolved',
                  'attribution_established':'no','mode':'unresolved'}
        self.assertFalse(uncertain_voice(negative))
        self.assertFalse(accepted_voice({**negative,'proposition_summary':''}))

    def test_unknown_capacity_cannot_veto_verified_speech(self):
        candidate={'name':'neimenovani sudionik','organisation':'','identity_ids':['P0001'],'statement_ids':['P0001'],'mode':'direct'}
        extracted={'candidates':[candidate],'mentions':[],'affected_groups':[],
                   'content':'complete','relevance':'central','main_theme':'ethics_family','headline_relevance':'central'}
        verified={'voices':[{**candidate,'candidate_index':0,'proposition_status':'stated',
                   'proposition_summary':'Vjera zahtijeva pomoć slabijima.','topic_related':'yes','attribution_established':'yes'}],
                  'affected_groups':[],'rejected_candidates':[],'content_check':'complete','topic_check':'central'}
        classified={'voices':[{'voice_index':0,'capacity_basis':'unresolved','role':'other',
                    'interprets_faith':'yes','own_experience':'no','classification_evidence_ids':['P0001']}], 'reason':'Unknown capacity'}
        meta={'field_errors':{},'seconds':1}
        row={'publication_id':'TEST','input_hash':'test','title':'Test',
             'body_clean':'Neimenovani sudionik rekao je da vjera zahtijeva pomoć slabijima.',
             'outlet_name':'Test','published_at':'2026-01-01'}
        with patch('coder.infer',side_effect=[(extracted,meta),(verified,meta),(classified,meta)]) as inference:
            result=code_article(None,row,'test','test')
        self.assertEqual(inference.call_count,3)
        self.assertEqual(result['voices'][0]['role'],'unresolved')
        self.assertEqual(result['voices'][0]['interprets_faith'],'yes')
        self.assertTrue(result['complete_article_base']['speakers'])
        self.assertEqual(result['elapsed_seconds'],3)
        with patch('coder.infer',side_effect=[(extracted,meta),(verified,meta),(None,{'status':'failed','seconds':1})]):
            failed=code_article(None,row,'test','test')
        self.assertFalse(failed['task_validity']['speakers'])
        self.assertTrue(failed['task_validity']['groups'])
        self.assertFalse(failed['complete_article_base']['speakers'])

if __name__=='__main__':unittest.main()
