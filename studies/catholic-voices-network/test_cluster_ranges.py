import unittest,json,duckdb
from cluster_ranges import materialize_ranges,RANGES_QUERY

class ClusterRanges(unittest.TestCase):
    def fixture(self,collision=False):
        con=duckdb.connect()
        con.execute("CREATE TABLE docs AS SELECT cast(i AS VARCHAR) AS doc_id,'2025-01-01' AS date FROM range(1,8) t(i)")
        con.execute("CREATE TABLE network_people AS SELECT 'Q1' AS entity_id,true AS d6")
        con.execute("CREATE TABLE network_doc_entities AS SELECT doc_id,'Q1' AS entity_id FROM docs WHERE doc_id<>'6'")
        con.execute("CREATE TABLE entity_links(entity_id VARCHAR,qid VARCHAR,facts_json VARCHAR)")
        con.execute('INSERT INTO entity_links VALUES (?,?,?)',['E1','Q1',json.dumps({'qid':'Q1','label':'Constructed One'})])
        if collision:con.execute('INSERT INTO entity_links VALUES (?,?,?)',['E2','Q2',json.dumps({'qid':'Q2','label':'Constructed Two'})])
        con.execute('CREATE TABLE aliases(threshold DOUBLE,form_id VARCHAR,entity_id VARCHAR)')
        con.executemany('INSERT INTO aliases VALUES (?,?,?)',[(.9,'F1','E1'),(.9,'F2','E1'),(.9,'F3','E2'),
          (.88,'F1','A1'),(.88,'F2','A1'),(.88,'F3','A1'),(.92,'F1','B1'),(.92,'F2','B2'),(.92,'F3','B3')])
        con.execute('CREATE TABLE form_mentions(doc_id VARCHAR,form_id VARCHAR)')
        con.executemany('INSERT INTO form_mentions VALUES (?,?)',[(str(i),'F1' if i<=2 else 'F2' if i<=5 else 'F3') for i in range(1,7)])
        con.execute("CREATE TABLE resolved_mentions AS SELECT '7' AS doc_id,'Q1' AS qid,'dated_title' AS origin,'contemporary' AS life_class")
        return con

    def test_split_not_recombined_and_resume_preserves_checkpoint(self):
        con=self.fixture();materialize_ranges(con)
        rows=con.execute('SELECT threshold,documents FROM network_cluster_scenarios ORDER BY threshold').fetchall()
        self.assertEqual(rows,[(.88,7),(.9,6),(.92,4)])
        self.assertEqual(con.execute(RANGES_QUERY,['c','s','t']).fetchone()[1:4],(6,4,7))
        before=con.execute('SELECT * FROM network_cluster_scenarios ORDER BY threshold').fetchall()
        materialize_ranges(con)
        self.assertEqual(before,con.execute('SELECT * FROM network_cluster_scenarios ORDER BY threshold').fetchall());con.close()

    def test_nonpublic_linked_identity_prevents_merge(self):
        con=self.fixture(collision=True);materialize_ranges(con)
        self.assertEqual(con.execute('SELECT documents,ambiguous_clusters FROM network_cluster_scenarios WHERE threshold=.88').fetchone(),(1,1));con.close()

    def test_additional_document_after_death_excluded(self):
        con=self.fixture()
        con.execute("UPDATE docs SET date='2026-01-01' WHERE doc_id='6'")
        con.execute('UPDATE entity_links SET facts_json=?',[json.dumps({'qid':'Q1','label':'Constructed One','death_recorded':True,'death':[['2025-12-31','2025-12-31']]})])
        materialize_ranges(con)
        self.assertEqual(con.execute('SELECT documents FROM network_cluster_scenarios WHERE threshold=.88').fetchone()[0],6);con.close()

if __name__=='__main__':unittest.main()
