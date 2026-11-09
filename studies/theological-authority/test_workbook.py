"""Independent ranking, history and coding-merge regression checks."""
import json
import unittest
from collections import defaultdict
from workbook_io import PRIVATE, merge_coding

class WorkbookChecks(unittest.TestCase):
    def test_manual_merge(self):
        old={'a':{'source_id':'a','notes':'original','reviewer':''}}
        csv={'a':{'source_id':'a','notes':'original','reviewer':'Tim'}}
        xlsx={'a':{'source_id':'a','notes':'čitanje vjere','reviewer':''}}
        merged=merge_coding(csv,old,xlsx)
        self.assertEqual(merged['a']['notes'],'čitanje vjere')
        self.assertEqual(merged['a']['reviewer'],'Tim')
        self.assertEqual(merge_coding(merged,merged,merged),merged)
        conflict={'a':{'source_id':'a','notes':'different'}}
        with self.assertRaises(ValueError): merge_coding(conflict,old,xlsx)
        cleared={'a':{'source_id':'a','notes':''}}
        self.assertEqual(merge_coding(old,old,cleared)['a']['notes'],'')

    def test_actual_tables(self):
        d=json.loads((PRIVATE/'workbook_data.json').read_text(encoding='utf-8'))
        for key,rank,share,context in [('annual','platform_year_rank','platform_year_share',('scope','platform','year')),
                                      ('overall','platform_rank','platform_share',('scope','platform'))]:
            buckets=defaultdict(list)
            for row in d[key]: buckets[tuple(row[c] for c in context)].append(row)
            for rows in buckets.values():
                observed=[r for r in rows if r['interaction_n']>0]
                expected=sorted(observed,key=lambda r:(-r['total_interactions'],r['source_id'].encode('utf-8')))
                self.assertEqual([r[rank] for r in expected],list(range(1,len(expected)+1)))
                denominator=sum(r['total_interactions'] for r in observed)
                for row in rows:
                    if row['interaction_n']==0:
                        for field in ('total_interactions','mean_interactions','median_interactions',rank,share):
                            self.assertIsNone(row[field])
                    elif denominator:
                        self.assertAlmostEqual(row[share],row['total_interactions']/denominator)
        history=d['history']
        self.assertEqual(len(history),250)
        self.assertEqual({r['source_id'] for r in history},{r['source_id'] for r in d['shortlist']})
        self.assertTrue(any((r['platform_year_rank'] or 0)>50 for r in history))
        for source in {r['source_id'] for r in history}:
            self.assertEqual({r['year'] for r in history if r['source_id']==source},set(range(2021,2026)))
        annual=defaultdict(lambda:[0,0])
        for r in d['annual']:
            a=annual[r['scope'],r['source_id']]
            a[0]+=r['posts'];a[1]+=r['total_interactions'] or 0
        for r in d['overall']:
            self.assertEqual(annual[r['scope'],r['source_id']],[r['posts'],r['total_interactions'] or 0])

if __name__=='__main__': unittest.main()
