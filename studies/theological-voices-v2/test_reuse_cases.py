import unittest
import pandas as pd
from reuse_cases import select_cases


class ReuseCaseTests(unittest.TestCase):
    def test_examples_preserve_identity_dates_and_thresholds(self):
        rows=[]
        for key,days,length in [('A',[1,1,1],1200),('B',[1,2,2],1300),('C',[1,2,2],100)]:
            for i,day in enumerate(days):
                rows.append({'publication_id':key+str(i),'outlet_id':str(i),'outlet_name':'source '+str(i),
                    'title':'synthetic','url':'https://example.invalid','text_length':length,'text_hash':key,
                    'published_at':f'2026-01-{day:02}'})
        frame=pd.DataFrame(rows)
        cases=select_cases(frame)
        self.assertEqual([c['text_hash'] for c in cases],['A','B'])
        self.assertEqual([c['span_days'] for c in cases],[0,1])
        self.assertEqual(cases,select_cases(frame.sample(frac=1,random_state=8)))
        for case in cases:
            self.assertEqual(case['publications'],3)
            self.assertEqual(case['outlets'],3)
            self.assertEqual({m['publication_id'] for m in case['display_members']},
                             {m['publication_id'] for m in case['members']})
        self.assertEqual(select_cases(frame.iloc[:2]),[])


if __name__=='__main__':unittest.main()
