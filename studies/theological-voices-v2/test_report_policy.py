import copy
import unittest
from report_policy import decide, TASKS

class ReportPolicyTests(unittest.TestCase):
    def inputs(self):
        q={'sets':{name:{'articles':size,'task_validity_rates':{k:1 for k in TASKS},
                        'segmented_task_validity_rates':{k:1 for k in TASKS}}
                   for name,size in [('development',100),('challenge',30),('challenge_challenge',30)]}}
        d={'config_hash':'frozen','checks':[{'id':str(i),'case':'test','structural_status':'complete','failures':[]} for i in range(30)]}
        p={'config_hash':'frozen','checks':[{'id':str(i),'passed':True} for i in range(4)]}
        return q,d,p

    def test_clean_checks_still_do_not_claim_accuracy(self):
        result=decide('frozen',*self.inputs())
        self.assertTrue(result['model_content_numbers_eligible'])
        self.assertEqual(result['classification_accuracy'],'not measured')

    def test_semantic_failure_withdraws_content_numbers(self):
        q,d,p=self.inputs();d['checks'][0]['failures']=[{'field':'role','expected':'personal_experience','actual':['unresolved']}]
        result=decide('frozen',q,d,p)
        self.assertEqual(result['report_mode'],'limited_exploratory')
        self.assertFalse(result['model_content_numbers_eligible'])
        self.assertEqual(result['withdrawal_reasons'][0]['kind'],'synthetic_rule')

    def test_long_text_failure_is_not_hidden_by_overall_rate(self):
        q,d,p=self.inputs();q['sets']['development']['segmented_task_validity_rates']['speakers']=.8
        self.assertFalse(decide('frozen',q,d,p)['model_content_numbers_eligible'])

    def test_missing_development_cannot_be_called_complete(self):
        q,d,p=self.inputs();q['sets']['development']['articles']=99
        with self.assertRaises(RuntimeError):decide('frozen',q,d,p)

    def test_old_configuration_is_not_reused_as_a_pass(self):
        q,d,p=self.inputs();d['config_hash']='old'
        with self.assertRaises(RuntimeError):decide('frozen',q,d,p)

if __name__=='__main__':unittest.main()
