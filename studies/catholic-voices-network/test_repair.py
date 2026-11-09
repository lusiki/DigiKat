import json,unittest,importlib
from repair_protocol import prepare,validate,expand,units
gaz=importlib.import_module('11_gazetteer_recall')

class RepairTests(unittest.TestCase):
    def test_evidence_is_retrieved_without_rewriting(self):
        text='Ivan je rekao: „Misa je u deset.“'
        bundle=prepare(text,'',[dict(surface='Ivan')])
        raw=json.dumps({'s':[dict(p=0,m=1,q=1,f=6,a=0,e=[0],r=0,target=-1,t='Misa je u deset.')]})
        value,errors=validate(raw,bundle);self.assertEqual(errors,[])
        self.assertEqual(expand(value,bundle)[0]['evidence_units'][0]['text'],text)
    def test_missing_and_wrong_identifier_rejected(self):
        bundle=prepare('Ivan govori.','',[dict(surface='Ivan')])
        for row in [dict(p=9,m=1,q=1,f=0,a=0,e=[0],r=0,target=-1,t=''),
                    dict(p=0,m=1,q=1,f=0,a=0,e=[9],r=0,target=-1,t='')]:
            self.assertTrue(validate(json.dumps({'s':[row]}),bundle)[1])
    def test_units_cover_every_character(self):
        text=('Riječ. \n'*100)+'Kraj.'
        uu=units(text);self.assertEqual(''.join(u['text'] for u in uu),text)
        self.assertTrue(all(text[u['start']:u['end']]==u['text'] for u in uu))
    def test_gazetteer_inflection(self):
        import regex
        pat=regex.compile(gaz.NB+gaz.inflect('Kutleša')+gaz.NE)
        self.assertIsNotNone(pat.fullmatch('Kutleše'))
        self.assertIsNone(pat.search('Pretkutleša'))

if __name__=='__main__':unittest.main()
