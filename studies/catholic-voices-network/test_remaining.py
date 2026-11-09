import importlib,json,unittest
from llm_protocol import gates,SCHEMA,conforms
prep=importlib.import_module('02_prepare_remaining')
sketch=importlib.import_module('04_minhash')

class RemainingTests(unittest.TestCase):
    def test_window_cap_contains_target(self):
        text='a'*3000
        a,b=prep.window_bounds(text,[(0,3000)],0,2400,2410)
        self.assertLessEqual(b-a,1200);self.assertTrue(a<=2400<2410<=b)
    def test_window_stays_in_paragraph(self):
        text='Prvi.\n\nIvan govori.\n\nZadnji.'
        self.assertEqual(prep.window_bounds(text,[(0,5),(7,19),(21,28)],1,7,11),(7,19))
    def test_empty_speaker_array_valid(self):
        self.assertTrue(gates('{"speakers":[]}','Ivan je nazočio.','')['grounded'])
    def test_hallucinated_evidence_rejected(self):
        speaker=dict(surface='Ivan',entity_id=None,mode='direct',proposition_status='stated',
            proposition_summary='Misa je u deset.',function='institutional_info',authority_cue='none',
            relation=dict(target_surface='',type='none'),evidence='Nije u izvoru')
        value={'speakers':[speaker]}
        self.assertTrue(conforms(value,SCHEMA))
        self.assertFalse(gates(json.dumps(value),'Ivan je govorio.','')['grounded'])
        speaker['evidence']='Ivan';speaker['entity_id']='invented'
        self.assertIn('entity_id',gates(json.dumps(value),'Ivan je govorio.','')['errors'])
    def test_sketch_exact_normalized_and_short(self):
        a=sketch.signature(('x','Jedan dva tri četiri pet šest'))
        b=sketch.signature(('y','JEDAN, dva tri četiri pet šest.'))
        self.assertEqual(a[3],b[3]);self.assertEqual(len(a[3]),512)
        self.assertIsNone(sketch.signature(('z','samo dvije'))[3])

if __name__=='__main__':unittest.main()
