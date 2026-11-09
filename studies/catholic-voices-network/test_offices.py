import unittest
from office_register import date_bounds,holder

def row(q,a,b=None):
    return dict(entity_qid=q,office_qid='Q1',places=[],start_earliest=a,start_latest=a,
                end_earliest=b,end_latest=b,date_usable=a is not None)
class Offices(unittest.TestCase):
    def test_date_precision(self):
        self.assertEqual(date_bounds(dict(time='+2025-00-00T00:00:00Z',precision=9)),('2025-01-01','2025-12-31'))
        self.assertIsNone(date_bounds(dict(time='+0000-00-00T00:00:00Z',precision=0)))
    def test_succession_and_vacancy(self):
        rows=[row('QA','2013-03-13','2025-04-21'),row('QB','2025-05-08')]
        self.assertEqual(holder(rows,'Q1','2025-04-20'),'QA')
        self.assertIsNone(holder(rows,'Q1','2025-05-01'))
        self.assertEqual(holder(rows,'Q1','2025-05-09'),'QB')
    def test_ambiguity(self):
        self.assertIsNone(holder([row('QA','2020-01-01'),row('QB','2024-01-01')],'Q1','2025-01-01'))
        self.assertIsNone(holder([row('QA',None)],'Q1','2025-01-01'))
    def test_uncertain_boundary(self):
        r=row('QA','2025-01-01');r['start_latest']='2025-12-31'
        self.assertIsNone(holder([r],'Q1','2025-06-01'))
        self.assertEqual(holder([r],'Q1','2026-01-01'),'QA')
    def test_ancient_open_tenure_does_not_block_modern_office(self):
        from dated_office_rules import holder as bounded
        rows=[row('Qancient','1400-01-01'),row('Qmodern','2024-01-01')]
        self.assertEqual(bounded(rows,'Q1','2025-01-01'),'Qmodern')
        # Missing start and overlapping recent tenure still prevent assignment.
        self.assertIsNone(bounded(rows+[row('Qunknown',None)],'Q1','2025-01-01'))
        self.assertIsNone(bounded(rows+[row('Qrecent','2000-01-01')],'Q1','2025-01-01'))

if __name__=='__main__':unittest.main()
