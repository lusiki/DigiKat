import json,unittest
import coder_protocol_v3 as p
from synthetic_suite import fixtures,windows,assess

class Protocol(unittest.TestCase):
    def setUp(self):
        self.bundle=p.prepare('Ana je rekla: "Vjera nas uči strpljenju."','',[{'surface':'Ana'}])
        self.row=dict(p=0,m=1,q=1,f=1,a=0,e=[0],r=0,target=-1,t='Vjera potiče strpljenje.')
    def test_strict_ids(self):
        for key,value in [('p',False),('target',False),('p',[]),('e',[False]),('e',[]),('m',0)]:
            row={**self.row,key:value};self.assertTrue(p.validate(json.dumps({'s':[row]}),self.bundle)[1])
    def test_valid_grounded_expansion(self):
        value,errors=p.validate(json.dumps({'s':[self.row]}),self.bundle)
        self.assertFalse(errors);self.assertEqual(p.expand(value,self.bundle)[0]['evidence_units'][0]['text'],self.bundle['units'][0]['text'])
    def test_frozen_suite_shape(self):
        cases=fixtures();self.assertEqual(len(cases),54)
        self.assertTrue(all(len(w)<=1200 for c in cases for w in windows(c)))
        long=next(c for c in cases if c['case']=='long_separated_identity')
        self.assertNotIn('Milosrđe nas poziva',''.join(windows(long)))
        self.assertIn('stated_count',assess(long,[]))
    def test_absent_speaker(self):
        bundle=p.prepare('Nema pripisanih izjava.','',[])
        self.assertFalse(p.validate('{"s":[]}',bundle)[1])
        self.assertTrue(p.validate(json.dumps({'s':[self.row]}),bundle)[1])
    def test_relation_target_must_occur_in_passage(self):
        bundle=p.prepare('Ana govori o vjeri.','Ivo',[dict(surface='Ana')])
        row={**self.row,'r':1,'target':1}
        self.assertIn('relation_target_not_in_passage',p.validate(json.dumps({'s':[row]}),bundle)[1])

if __name__=='__main__':unittest.main()
