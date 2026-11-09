import importlib,unittest,duckdb
report_data=importlib.import_module('80_report_data')
collect=report_data.collect

class ReportData(unittest.TestCase):
    def test_distinct_documents_and_text_families(self):
        con=duckdb.connect()
        con.execute('''CREATE TABLE docs AS SELECT cast(i AS VARCHAR) AS doc_id,400 AS n_chars,
          CASE WHEN i<3 THEN 'web' ELSE 'facebook' END AS platform,'post2024' AS era,
          '2025-01-01' AS date,CASE WHEN i<3 THEN 'a' ELSE 'b' END AS text_sha256,
          CASE WHEN i<3 THEN 'site.test' ELSE 'account' END AS source FROM range(1,5) t(i)''')
        con.execute("CREATE TABLE resolved_mentions AS SELECT doc_id,'contemporary' AS life_class,'ner' AS origin,'Q1' AS qid,0 AS start_char,1 AS end_char FROM docs")
        con.execute("CREATE TABLE form_mentions AS SELECT doc_id,0 AS start_char,1 AS end_char,'F1' AS form_id FROM docs")
        con.execute("CREATE TABLE forms AS SELECT 'F1' AS form_id,'clergy' AS cue_class")
        con.execute("CREATE TABLE form_lemmas AS SELECT 'F1' AS form_id,'agreed' AS status")
        con.execute("CREATE TABLE entities AS SELECT .9 AS threshold,'E1' AS entity_id")
        con.execute("CREATE TABLE entity_counts AS SELECT .9 AS threshold,'E1' AS entity_id,4 AS documents")
        con.execute("CREATE TABLE entity_links AS SELECT 'E1' AS entity_id,'linked' AS status,'Q1' AS qid")
        con.execute("CREATE TABLE network_doc_entities AS SELECT doc_id,'Q1' AS entity_id FROM docs")
        con.execute("CREATE TABLE network_people AS SELECT 'Q1' AS entity_id,4 AS documents,2 AS outlets,2 AS platforms,8 AS mention_spans,true AS d6")
        con.execute("CREATE TABLE network_cluster_scenarios AS SELECT 'Q1' AS entity_id,4 AS documents,0 AS ambiguous_clusters FROM range(3)")
        con.execute('''CREATE TABLE network_sources AS SELECT DISTINCT source,platform,
          CASE WHEN platform='web' THEN source ELSE 'facebook — ostali izvori' END AS public_label,
          platform='web' AS publish FROM docs''')
        con.execute("CREATE TABLE circulation_texts AS SELECT 'a' AS text_sha256,1 AS text_id UNION ALL SELECT 'b',2")
        con.execute('''CREATE TABLE circulation_membership AS SELECT threshold,text_id,1 AS family_id
          FROM (VALUES (.8),(.85),(.9)) t(threshold) CROSS JOIN circulation_texts''')
        con.execute("CREATE TABLE title_mentions AS SELECT doc_id,'unresolved' AS status FROM docs")
        con.execute('CREATE TABLE candidates AS SELECT doc_id FROM docs')
        con.execute("CREATE TABLE rule_sentence_results AS SELECT doc_id,'complete' AS status FROM docs")
        result=collect(con)
        self.assertEqual(result['corpus']['documents'],4)
        self.assertEqual(result['corpus']['unique_texts'],2)
        self.assertEqual(result['circulation'][1]['families'],1)
        self.assertEqual(result['circulation'][1]['excess_appearances'],3)
        self.assertEqual(result['scope']['documents_with_public_person'],4)
        self.assertEqual(result['people'][0]['documents'],4)
        self.assertEqual(result['role_cues'],[])
        self.assertEqual(sum(r['documents'] for r in result['person_platform_eras']),4)
        self.assertTrue(all(r['public_label']!='account' for r in result['source_distribution']))
        self.assertEqual(result['name_forms'],dict(forms=1,statuses=dict(agreed=1)))
        self.assertEqual(result['public_name_linkage'],dict(selected=1,statuses=dict(linked=1),linked=1,without_accepted_link=0))
        report_data.check_linkage_report(result['public_name_linkage'],dict(selected=1,statuses=dict(linked=1)))
        with self.assertRaisesRegex(RuntimeError,'differs from the database'):
            report_data.check_linkage_report(result['public_name_linkage'],dict(selected=1,statuses=dict(unresolved=1)))
        con.execute('DELETE FROM entity_links')
        with self.assertRaisesRegex(RuntimeError,'Incomplete or unexpected public-name linkage'):
            collect(con)
        con.execute("INSERT INTO entity_links VALUES ('E1','linked',NULL)")
        with self.assertRaisesRegex(RuntimeError,'Invalid public-name linkage status'):
            collect(con)
        con.execute('DELETE FROM form_lemmas')
        with self.assertRaisesRegex(RuntimeError,'Incomplete normalization evidence'):
            collect(con)
        con.close()

if __name__=='__main__':unittest.main()
