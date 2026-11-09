"""Synthetic, local DuckDB integration; never runs GPU or sends text externally."""
import importlib,json,tempfile,unittest
from pathlib import Path
from unittest.mock import patch
import duckdb

class Handoff(unittest.TestCase):
    def test_dated_title_author_windows_and_unknown_parse_survive_resume(self):
        resolve=importlib.import_module('24_resolve_mentions_v1')
        prepare=importlib.import_module('25_prepare_candidates_v1')
        rules=importlib.import_module('30_quote_rules')
        with tempfile.TemporaryDirectory() as directory:
            folder=Path(directory);db=folder/'fixture.duckdb';cache=folder/'public_register_cache';cache.mkdir()
            people={q:dict(id=q,labels={'hr':dict(value=name)},claims={}) for q,name in
                    [('Qold','Raniji Papa'),('Qnew','Novi Papa'),('Qperson','Ana Babić')]}
            people['Q19546']=dict(id='Q19546',labels={'hr':dict(value='papa')})
            (cache/'entities_fixture.json').write_text(json.dumps(dict(retrieved_utc='synthetic',response=dict(entities=people))),encoding='utf-8')
            register=dict(offices=[dict(office_qid='Q19546',entity_qid=q,places=[],date_usable=True,
               start_earliest=a,start_latest=a,end_earliest=b,end_latest=b) for q,a,b in
               [('Qold','2013-03-13','2025-04-21'),('Qnew','2025-05-08',None)]])
            (folder/'office_register.json').write_text(json.dumps(register),encoding='utf-8')
            con=duckdb.connect(str(db))
            con.execute('CREATE TABLE docs (doc_id VARCHAR,text_clean VARCHAR,date VARCHAR,platform VARCHAR,era VARCHAR,author VARCHAR,source VARCHAR)')
            con.execute('CREATE TABLE forms (form_id VARCHAR,surface VARCHAR)')
            con.execute('CREATE TABLE form_mentions (doc_id VARCHAR,start_char INTEGER,end_char INTEGER,form_id VARCHAR)')
            con.execute('CREATE TABLE aliases (threshold DOUBLE,form_id VARCHAR,entity_id VARCHAR)')
            con.execute('CREATE TABLE entities (threshold DOUBLE,entity_id VARCHAR)')
            con.execute('CREATE TABLE entity_links (entity_id VARCHAR,qid VARCHAR,status VARCHAR,facts_json VARCHAR)')
            con.execute('CREATE TABLE mentions (doc_id VARCHAR,start_char INTEGER,end_char INTEGER,surface VARCHAR,type VARCHAR)')
            texts=['Sveti Otac je rekao: "Vjera nas poziva na milosrđe." '+('Objavljeni su detalji susreta. '*20),
                   ('Program je počeo ujutro. '*15)+'Molim svakoga jutra. Vjera mi je pomogla u žalovanju.']
            con.executemany('INSERT INTO docs VALUES (?,?,?,?,?,?,?)',[
                ('D1',texts[0],'2026-01-01','web','after2024','','example.test'),
                ('D2',texts[1],'2026-01-01','facebook','after2024','Ana Babić','Synthetic account')])
            con.execute("INSERT INTO forms VALUES ('F1','Sveti Otac')")
            con.execute("INSERT INTO form_mentions VALUES ('D1',0,10,'F1')")
            con.execute("INSERT INTO aliases VALUES (.9,'F1','E1')")
            con.execute("INSERT INTO entities VALUES (.9,'E1'),(.9,'E2')")
            con.execute("INSERT INTO entity_links VALUES ('E1',NULL,'unresolved','{}')")
            con.execute('INSERT INTO entity_links VALUES (?,?,?,?)',['E2','Qperson','linked',json.dumps(dict(qid='Qperson',birth=[],death=[]))])
            con.close()
            for _ in range(2):
                with patch.object(resolve,'connect',lambda:duckdb.connect(str(db))),patch.object(resolve,'workdir',lambda:folder):resolve.main()
            con=duckdb.connect(str(db))
            self.assertEqual(con.execute('SELECT qid,origin FROM resolved_mentions').fetchall(),[('Qnew','dated_title')])
            con.close()
            for _ in range(2):
                with patch.object(prepare,'connect',lambda:duckdb.connect(str(db))),patch.object(prepare,'workdir',lambda:folder),patch.object(prepare,'MANIFEST',{'corpus':{'rows':2}}):prepare.main()
            con=duckdb.connect(str(db))
            self.assertEqual(con.execute('SELECT count(*) FROM candidate_docs').fetchone()[0],2)
            self.assertGreater(con.execute("SELECT count(*) FROM candidate_sentences WHERE doc_id='D2' AND contains(text,'Molim') AND needs_parse").fetchone()[0],0)
            con.execute('CREATE TABLE rule_sentence_results (item_id VARCHAR,status VARCHAR,statements_json VARCHAR)')
            con.execute("INSERT INTO rule_sentence_results SELECT item_id,'failed','[]' FROM candidate_sentences WHERE needs_parse")
            rules.materialize_windows(con)
            self.assertGreater(con.execute("SELECT count(*) FROM rule_window_results WHERE status='parse_unknown'").fetchone()[0],0)
            count=con.execute('SELECT count(*) FROM rule_window_results').fetchone()[0]
            rules.materialize_windows(con)
            self.assertEqual(con.execute('SELECT count(*) FROM rule_window_results').fetchone()[0],count)
            con.close()

if __name__=='__main__':unittest.main()
