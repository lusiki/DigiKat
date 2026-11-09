import importlib,json,unittest
from agreement_metrics import kappa,publication_level,bundle_slots,field_labels

class Agreement(unittest.TestCase):
    def test_chance_adjustment_and_degeneracy(self):
        self.assertAlmostEqual(kappa(['a','a','b','b'],['a','b','a','b'])['kappa'],0)
        self.assertAlmostEqual(kappa(['a','b'],['b','a'])['kappa'],-1)
        self.assertIsNone(kappa(['none']*20,['none']*20)['kappa'])
        self.assertEqual(kappa(['a','b'],['a','b'])['kappa'],1)
    def test_failed_gates_cannot_be_overridden_by_agreement(self):
        self.assertEqual(publication_level(.99,.03,1,True),'withdrawn')
        self.assertEqual(publication_level(.99,0,.94,True),'withdrawn')
        self.assertEqual(publication_level(.99,0,1,False),'withdrawn')
        self.assertEqual(publication_level(.6,0,1,True),'C')
        self.assertEqual(publication_level(None,0,1,True),'withdrawn')
    def test_shared_aliases_and_ambiguous_names(self):
        bundle,mapping=bundle_slots('Ivan i Marić govore.','',None,[dict(surface='Ivan',entity_id='Q1'),dict(surface='Marić',entity_id='Q1')])
        self.assertEqual(len(set(mapping.values())),1)
        labels=field_labels([],mapping);self.assertEqual(labels['speaker_identity'],{'Q1':False})
        _,ambiguous=bundle_slots('Ivan govori.','',None,[dict(surface='Ivan',entity_id='Q1'),dict(surface='Ivan',entity_id='Q2')])
        self.assertTrue(ambiguous[0].startswith('UNRESOLVED_SLOT:'))
    def test_primary_selection_is_not_a_publication_gate(self):
        choose=importlib.import_module('42_prepare_validation').choose
        self.assertIsNone(choose({})[0])
        reports={'synthetic_v4_qwen3_8b':{'synthetic_gate_passed':True},'benchmark_v4_qwen3_8b':{'throughput_gate_passed':True}}
        self.assertEqual(choose(reports)[0],'qwen3:8b')
    def test_shared_absences_do_not_validate_function_content(self):
        analyse=importlib.import_module('43_model_agreement').analyse
        row=dict(candidate_id=0,surface='Ana',mode='direct',proposition_status='stated',
          function='pastoral',authority_cue='none',relation=dict(type='none',target_surface=''),proposition_summary='Primjer',evidence_units=[])
        source=[];x={};y={}
        for i in range(20):
            item=str(i);source.append((item,'Ana govori.','',None,json.dumps([dict(surface='Ana',entity_id='Q1',type='PER',**{'class':'contemporary'})])))
            rr=[] if i<18 else [row]
            x[item]=dict(errors=[],rows=rr)
            y[item]=dict(errors=[],rows=rr if i!=19 else [{**row,'function':'testimony'}])
        result=analyse(source,x,y,x,set(x),0,True)
        f=result['fields']['function']
        self.assertGreater(f['kappa'],.7)
        self.assertEqual(f['kappa_for_gate'],0)
        self.assertEqual(f['publication_level'],'withdrawn')
    def test_failed_repeat_is_not_identical_empty_output(self):
        analyse=importlib.import_module('43_model_agreement').analyse
        source=[('a','Ana govori.','',None,json.dumps([dict(surface='Ana',entity_id='Q1')]))]
        failed={'a':dict(errors=['json'],rows=[])}
        result=analyse(source,failed,failed,failed,{'a'},1,False)
        self.assertEqual(result['fields']['speaker_identity']['determinism'],0)
    def test_historical_context_does_not_inflate_gate_sample(self):
        analyse=importlib.import_module('43_model_agreement').analyse
        mentions=[dict(surface='Ana',entity_id='Q1',type='PER',**{'class':'contemporary'}),
                  dict(surface='Augustin',entity_id='Q2',type='PER',**{'class':'historical'})]
        source=[('a','Ana i Augustin.','',None,json.dumps(mentions))]
        empty={'a':dict(errors=[],rows=[])}
        result=analyse(source,empty,empty,empty,{'a'},0,True)
        self.assertEqual(result['fields']['speaker_identity']['n'],1)
        self.assertEqual(result['excluded_context_observations'],1)

if __name__=='__main__':unittest.main()
