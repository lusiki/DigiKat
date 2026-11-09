import unittest
from public_exports import safe_alias,public_edges,office_in_period

class PublicExports(unittest.TestCase):
    def test_alias_is_not_passage_or_account(self):
        self.assertTrue(safe_alias('mons. Ivana Horvata'))
        self.assertTrue(safe_alias('I. Horvat'))
        for value in ['@ivan.horvat','https://example.test/ivan','Ivan je rekao: Molimo.','Ivan','Ivan Horvat 123']:
            self.assertFalse(safe_alias(value))
    def test_edge_gate_precedes_export(self):
        network={'edges':[dict(from_='unused',**{'from':'Q1','to':'Q2'},shared_contexts=8,independent_documents=4,display=True),
          dict(**{'from':'Q1','to':'Q2'},shared_contexts=8,independent_documents=5,display=True)]}
        self.assertEqual(len(public_edges(network,{'Q1','Q2'})),1)
        with self.assertRaises(ValueError):public_edges(network,{'Q1'})
    def test_unknown_or_ancient_start_not_dated_release(self):
        row=dict(date_usable=True,start_earliest='2020-01-01',start_latest='2020-01-01',end_latest=None)
        self.assertTrue(office_in_period(row))
        row['start_latest']='1600-01-01';row['start_earliest']='1600-01-01'
        self.assertFalse(office_in_period(row))

if __name__=='__main__':unittest.main()
