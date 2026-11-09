import unittest
from publication_audit import death_status,withdrawn_checks

class PublicationAudit(unittest.TestCase):
    def test_death_precision_and_absence(self):
        facts=[{'death':[['2025-01-01','2025-12-31']]}]
        self.assertEqual(death_status(facts,'2026-01-01'),'after_recorded_death')
        self.assertEqual(death_status(facts,'2025-02-01'),'death_date_uncertain')
        self.assertEqual(death_status(facts,'2024-12-31'),'before_recorded_death')
        self.assertEqual(death_status([], '2025-01-01'),'identity_facts_missing')
        self.assertEqual(death_status([{}], '2025-01-01'),'no_recorded_death')
        self.assertEqual(death_status([{'death_recorded':True}], '2025-01-01'),'unparsed_recorded_death')
        self.assertEqual(death_status(facts,None),'missing_document_date')

    def test_withdrawal_is_explicit_not_fabricated_robustness(self):
        gate=dict(primary_synthetic_pass_exists=False,main_authorized=False,publication_levels={'speaks':'withdrawn'})
        checks=withdrawn_checks(gate)
        self.assertEqual(checks['M-ROB-1']['status'],'not_applicable')
        self.assertEqual(checks['M-AG-1']['status'],'not_run')
        gate['primary_synthetic_pass_exists']=True
        with self.assertRaises(RuntimeError):withdrawn_checks(gate)

if __name__=='__main__':unittest.main()
