import unittest,duckdb,importlib,json,tempfile
from pathlib import Path
from unittest.mock import patch
from network_inputs import source_policy,paragraph_numbers,materialize

class NetworkInputs(unittest.TestCase):
    def test_accounts_remain_distinct_without_public_names(self):
        a=source_policy('https://facebook.com/private.a','facebook',{})
        b=source_policy('https://facebook.com/private.b','facebook',{})
        self.assertFalse(a['public']);self.assertEqual(a['public_label'],b['public_label'])
        self.assertNotEqual(a['source_id'],b['source_id'])
        self.assertTrue(source_policy('hkm.hr','web',{})['public'])
        self.assertFalse(source_policy('','web',{})['public'])
    def test_d6_and_resumption(self):
        con=duckdb.connect()
        con.execute('CREATE TABLE docs(doc_id VARCHAR,text_clean VARCHAR,source VARCHAR,platform VARCHAR)')
        con.execute('CREATE TABLE resolved_mentions(doc_id VARCHAR,entity_id VARCHAR,start_char INTEGER,life_class VARCHAR,qid VARCHAR)')
        for i in range(20):
            did=str(i).zfill(3)
            con.execute('INSERT INTO docs VALUES (?,?,?,?)',[did,'A\n\nB',str(i%3),'web'])
            con.execute("INSERT INTO resolved_mentions VALUES (?, 'Q1',0,'contemporary','Q1'),(?, 'Q1',3,'contemporary','Q1'),(?, 'Q2',0,'historical','Q2'),(?, 'E3',0,'unresolved',NULL)",[did]*4)
        con.execute("INSERT INTO resolved_mentions VALUES ('000','Q4',0,'contemporary','Q4')")
        materialize(con,{})
        self.assertEqual(con.execute('SELECT entity_id,documents,outlets,mention_spans FROM network_people WHERE d6').fetchall(),[('Q1',20,3,40)])
        self.assertEqual(con.execute('SELECT count(*) FROM network_doc_entities').fetchone()[0],20)
        materialize(con,{})
        self.assertEqual(con.execute('SELECT count(*) FROM network_mention_paragraphs').fetchone()[0],41)
        self.assertEqual(paragraph_numbers('A\n\nB',[0,3]),[0,1])
        con.close()
    def test_full_export_is_byte_stable_after_reopen(self):
        stage=importlib.import_module('69_prepare_networks')
        with tempfile.TemporaryDirectory() as folder:
            folder=Path(folder);database=folder/'fixture.duckdb';con=duckdb.connect(str(database))
            con.execute('''CREATE TABLE docs AS SELECT lpad(cast(i AS VARCHAR),3,'0') AS doc_id,
              'A' AS text_clean,cast(i%3 AS VARCHAR) AS source,'web' AS platform,'post2024' AS era,
              '2025-01-01' AS date,1 AS n_chars,cast(i AS VARCHAR) AS text_sha256 FROM range(20) t(i)''')
            con.execute("CREATE TABLE resolved_mentions AS SELECT doc_id,'Q1' AS entity_id,0 AS start_char,'contemporary' AS life_class,'Q1' AS qid,'ner' AS origin FROM docs")
            con.execute("CREATE TABLE aliases AS SELECT t.threshold,'F1' AS form_id,'E1' AS entity_id FROM (VALUES (.88),(.9),(.92)) t(threshold)")
            con.execute("CREATE TABLE form_mentions AS SELECT doc_id,'F1' AS form_id FROM docs")
            con.execute("CREATE TABLE entity_links(entity_id VARCHAR,qid VARCHAR,facts_json VARCHAR)")
            con.execute('INSERT INTO entity_links VALUES (?,?,?)',['E1','Q1',json.dumps({'qid':'Q1','label':'Konstruirana Osoba'})])
            con.execute('CREATE TABLE resolved_docs AS SELECT doc_id FROM docs')
            con.execute('CREATE TABLE circulation_texts AS SELECT cast(text_sha256 AS INTEGER) AS text_id,text_sha256 FROM docs')
            con.execute('CREATE TABLE circulation_membership AS SELECT .85 AS threshold,text_id,text_id AS family_id FROM circulation_texts')
            con.close()
            (folder/'identity_resolution_report.json').write_text(json.dumps({'papal_title_date_violations':0}),encoding='utf-8')
            fake_public=({'Q1':{'id':'Q1','labels':{'hr':{'value':'Konstruirana Osoba'}}}},set(),[])
            with patch.object(stage,'connect',lambda:duckdb.connect(str(database))),patch.object(stage,'workdir',lambda:folder),patch.object(stage,'MANIFEST',{'corpus':{'rows':20}}),patch.object(stage,'read_cache',lambda path:fake_public):
                stage.main()
                first=(folder/'network_inputs_report.json').read_bytes()
                stage.main()
                self.assertEqual(first,(folder/'network_inputs_report.json').read_bytes())
                report=json.loads(first)
                self.assertEqual(report['files']['appearances']['rows'],20)
                self.assertEqual(report['public_people'],1)

if __name__=='__main__':unittest.main()
