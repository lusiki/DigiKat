import json,unittest
import coder_protocol_v5 as p

class Readable(unittest.TestCase):
    def test_author_is_preserved_even_when_named(self):
        named=p.prepare('Ana kaže da moli.','Ana',[{'surface':'Ana','type':'PER'}])
        self.assertEqual(named['author_candidate_id'],0)
        self.assertFalse(named['candidates'][0]['author_only'])
        self.assertEqual(named['candidates'][0]['entity_type'],'PER')
        absent=p.prepare('Molim svakoga jutra.','Ana',[])
        self.assertEqual(absent['author_candidate_id'],0)
        self.assertTrue(absent['candidates'][0]['author_only'])
    def test_readable_labels_preserve_validation(self):
        bundle=p.prepare('Ana kaže: "Molim."','',[{'surface':'Ana'}])
        row=dict(p=0,m='direct',q='stated',f='testimony',a='experience',e=[0],r='none',target=-1,t='Moli.')
        value,errors=p.validate(json.dumps({'s':[row]}),bundle)
        self.assertEqual(errors,[]);self.assertEqual(p.expand(value,bundle)[0]['mode'],'direct')
        row['target']=0
        self.assertIn('relation_none',p.validate(json.dumps({'s':[row]}),bundle)[1])
    def test_empty_candidates(self):
        bundle=p.prepare('Nema izjave.','',[])
        self.assertEqual(p.validate('{"s":[]}',bundle)[1],[])

if __name__=='__main__':unittest.main()
