import unittest
from passage_windows import create_windows

class Windows(unittest.TestCase):
    def test_no_cross_paragraph_or_short_text(self):
        text='Ivan govori o vjeri. '+('Detalji rasprave. '*25)+'\n\nDrugi odlomak.'
        first=text.index('\n\n');bounds=[(0,20),(21,first),(first+2,len(text))]
        m=dict(start=0,end=4,surface='Ivan',entity_id='Q1',**{'class':'contemporary','type':'PER'})
        w=create_windows('D',text,bounds,[m])[0]
        self.assertNotIn('Drugi',w['text']);self.assertEqual(w['mentions'][0]['start'],0)
        self.assertEqual(create_windows('S','Ivan govori.',[(0,12)],[m]),[])
    def test_historical_only_is_not_a_contemporary_candidate(self):
        text='Augustin '+('riječi '*60)
        m=dict(start=0,end=8,surface='Augustin',entity_id='Q1',**{'class':'historical','type':'PER'})
        self.assertEqual(create_windows('D',text,[(0,len(text))],[m]),[])
        self.assertEqual(len(create_windows('D',text,[(0,len(text))],[m],author='Ana Babić')),1)
    def test_cap_keeps_anchor_and_literal_offsets(self):
        text=('uvod '*300)+'Ivan Marić '+('kraj '*300);a=text.index('Ivan')
        m=dict(start=a,end=a+10,surface='Ivan Marić',entity_id='Q1',**{'class':'contemporary','type':'PER'})
        w=create_windows('D',text,[(0,len(text))],[m])[0]
        self.assertLessEqual(len(w['text']),1200)
        p=w['mentions'][0];self.assertEqual(w['text'][p['start']:p['end']],p['surface'])
        self.assertEqual(w['sentence_ids'],[0]) # Rule tier can parse the original complete sentence separately.

if __name__=='__main__':unittest.main()
