import unittest
from wikidata_identity import classification,role_matches,norm
class Identity(unittest.TestCase):
    def test_death_changes_document_class(self):
        facts=dict(qid='QX',birth=[('1936-12-17','1936-12-17')],death=[('2025-04-21','2025-04-21')])
        self.assertEqual(classification('Franjo',facts,'2024-01-01'),'contemporary')
        self.assertEqual(classification('Franjo',facts,'2026-01-01'),'historical')
        self.assertEqual(classification('Franjo',facts,'2025-04-21'),'date_uncertain')
    def test_uncertain_missing_data(self):
        self.assertEqual(classification('Ivan',{},'2026-01-01'),'unresolved')
        self.assertEqual(classification('Ivan',dict(qid='QX',birth=[('1800-01-01','1800-12-31')]),'2026-01-01'),'unresolved')
        self.assertEqual(classification('Isus Krist',{},'2026-01-01'),'sacred')
        self.assertEqual(classification('Ivan',dict(qid='QX'),None),'date_uncertain')
    def test_roles_do_not_follow_clerical_stereotypes(self):
        e=dict(descriptions={'en':{'value':'Croatian Roman Catholic priest'}})
        self.assertTrue(role_matches(e,{'clergy'}));self.assertFalse(role_matches(e,{'academic'}))
        self.assertEqual(norm('Dražen Kutleša'),'dražen kutleša')
    def test_unparsed_death_is_not_treated_as_alive(self):
        self.assertEqual(classification('Ivan',dict(qid='QX',death_recorded=True,death=[]),'2026-01-01'),'date_uncertain')
        self.assertEqual(classification('Ivan',dict(qid='QX',canonization_status=['Q123110154']),'2026-01-01'),'historical')
        self.assertEqual(classification('Ivan',dict(qid='QX',canonization_status=['Q43115']),'2026-01-01'),'contemporary')
if __name__=='__main__':unittest.main()
