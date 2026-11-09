import json
import sqlite3
import unittest
from input_delivery import audit


class DeliveryTests(unittest.TestCase):
    def test_tail_title_and_actual_response_are_required(self):
        db=sqlite3.connect(':memory:')
        db.execute('CREATE TABLE calls(set_name,config_hash,publication_id,request_json,response_json)')
        result={'publication_id':'A','status':'complete','passages':{'H001':'Title','P0001':'First.','P0002':'Important final passage.'}}
        def call(source,output=True):
            db.execute('INSERT INTO calls VALUES(?,?,?,?,?)',('main','cfg','A',
                json.dumps({'messages':[{'role':'user','content':source}]}),json.dumps({'eval_count':10} if output else {})))
        call('[H001] Title\n[P0001] First.')
        call('[P0002] Important final passage.',False)
        row=audit(db,[result],'cfg')[0]
        self.assertEqual(row['coverage_status'],'incomplete_or_unconfirmed')
        self.assertEqual(row['confirmed_body_passages'],1)
        call('[P0002] Important final passage.')
        self.assertEqual(audit(db,[result],'cfg')[0]['coverage_status'],'confirmed_full')
        self.assertEqual(audit(db,[result],'other')[0]['coverage_status'],'incomplete_or_unconfirmed')
        missing={'publication_id':'B','status':'missing_text','passages':{'H001':'Only a title'}}
        self.assertEqual(audit(db,[missing],'cfg')[0]['coverage_status'],'missing_text')
        db.close()


if __name__=='__main__':unittest.main()
