import unittest,regex
from office_titles import phrase_pattern,match_titles

class Titles(unittest.TestCase):
    def setUp(self):
        self.register=dict(offices=[dict(office_qid='Q19546',entity_qid=q,places=[],date_usable=True,
          start_earliest=a,start_latest=a,end_earliest=b,end_latest=b) for q,a,b in
          [('Qold','2013-03-13','2025-04-21'),('Qnew','2025-05-08',None)]])
        self.pattern=regex.compile('(?P<t0>'+phrase_pattern('Sveti Otac')+')',regex.I)
        self.mapping={'t0':dict(title='Sveti Otac',offices=['Q19546'])}
    def match(self,text,date,people=()):return match_titles(text,date,people,self.register,self.pattern,self.mapping)
    def test_vacancy(self):
        self.assertIsNone(self.match('Sveti Otac je govorio.','2025-05-01')[0]['qid'])
        self.assertEqual(self.match('Sveti Otac je govorio.','2025-05-09')[0]['qid'],'Qnew')
    def test_named_historical_context_not_overwritten(self):
        text='Sveti Otac Franjo je govorio.'
        self.assertEqual(self.match(text,'2026-01-01',[(11,17)])[0]['status'],'named_context')
        self.assertIsNone(self.match('Godine 2022. Sveti Otac je govorio.','2026-01-01')[0]['qid'])
        self.assertIsNone(self.match('Godine 1400. Sveti Otac je govorio.','2026-01-01')[0]['qid'])
        self.assertIsNone(self.match('Godine 843. Sveti Otac je govorio.','2026-01-01')[0]['qid'])
    def test_inflected_geographic_title(self):
        pattern=regex.compile(phrase_pattern('zagrebački nadbiskup'),regex.I)
        self.assertIsNotNone(pattern.search('riječi zagrebačkoga nadbiskupa'))
        self.assertIsNone(pattern.search('splitski nadbiskup'))
    def test_ner_tagged_title_is_still_title_only(self):
        self.assertEqual(self.match('Sveti Otac je govorio.','2025-05-09',[(0,10)])[0]['qid'],'Qnew')
        self.assertIsNone(self.match('Sveti Otac Franjo je govorio.','2026-01-01')[0]['qid'])
        self.assertEqual(self.match('riječi Svetoga Oca','2025-05-09')[0]['qid'],'Qnew')
    def test_missing_date_cannot_select_holder(self):
        self.assertEqual(self.match('Sveti Otac je govorio.',None)[0]['status'],'missing_date')

if __name__=='__main__':unittest.main()
