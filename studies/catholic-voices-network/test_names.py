import unittest
from name_forms import clean_name,features,compatible
class Names(unittest.TestCase):
    def test_titles_and_diacritics(self):
        self.assertEqual(clean_name('prof. dr. Ana Markić'),'Ana Markić')
        self.assertEqual(clean_name('mons. Dražen Kutleša'),'Dražen Kutleša')
    def test_role_conflict(self):
        a=dict(nominative='Ivan Marić',cue_class='clergy');b={**a,'cue_class':'politics'}
        self.assertFalse(compatible(a,b))
        self.assertFalse(compatible(a,{**a,'nominative':'Ivo Marić'}))
    def test_nearby_title_not_remote_role(self):
        text='Ministar je otišao. Biskup Ivan Marić je govorio.'
        start=text.index('Ivan');f=features(text,start,start+len('Ivan Marić'),'standard')
        self.assertEqual(f['cue_class'],'clergy')
        self.assertEqual(f['context'][f['start']:f['end']],'Ivan Marić')
    def test_ambiguous_single_name(self):
        a=dict(nominative='Franjo',cue_class='clergy');self.assertFalse(compatible(a,a))
    def test_context_offsets_across_paragraphs(self):
        text='Uvod.\n\nPrvi dio.\n\nBiskup Ivan Marić govori.\n\nKraj.'
        start=text.index('Ivan');f=features(text,start,start+len('Ivan Marić'),'standard')
        self.assertEqual(f['context'],'Biskup Ivan Marić govori.')
        self.assertEqual(f['context'][f['start']:f['end']],'Ivan Marić')
    def test_complete_link_cannot_bridge_conflicting_roles(self):
        import importlib
        cluster=importlib.import_module('21_cluster').cluster
        forms=[dict(form_id=str(i),nominative='Ivan Marić',status='agreed',cue_class=role,documents=10-i)
               for i,role in enumerate(['clergy','other','politics'])]
        aliases,entities=cluster(forms,.9)
        assigned={a[1]:a[2] for a in aliases}
        self.assertNotEqual(assigned['0'],assigned['2'])
    def test_form_preparation_clustering_and_resume(self):
        import importlib,tempfile
        from pathlib import Path
        from unittest.mock import patch
        import duckdb
        from forms_bulk import FormsBulkConnection
        prep=importlib.import_module('20_forms');clustering=importlib.import_module('21_cluster')
        texts=['Biskup Ivan Marić govori.','Biskup Ivan Marić ponavlja.',
               'Ministar Ivan Marić govori.','Ivan Marić govori.']
        with tempfile.TemporaryDirectory() as directory:
            db=Path(directory)/'fixture.duckdb';con=duckdb.connect(str(db))
            con.execute('CREATE TABLE docs (doc_id VARCHAR,text_clean VARCHAR,platform VARCHAR,source VARCHAR)')
            con.execute('CREATE TABLE mentions (doc_id VARCHAR,start_char INTEGER,end_char INTEGER,type VARCHAR)')
            for i,text in enumerate(texts):
                start=text.index('Ivan');con.execute('INSERT INTO docs VALUES (?,?,?,?)',[str(i),text,'web','example.test'])
                con.execute('INSERT INTO mentions VALUES (?,?,?,?)',[str(i),start,start+10,'PER'])
            prep.prepare(FormsBulkConnection(con));prep.prepare(con)
            self.assertEqual(con.execute('SELECT count(*) FROM form_mentions').fetchone()[0],4)
            self.assertEqual(con.execute('SELECT count(*) FROM forms').fetchone()[0],3)
            con.execute("CREATE TABLE form_lemmas AS SELECT form_id,'Ivan Marić' AS nominative,'agreed' AS status FROM forms")
            con.close()
            for _ in range(2):
                with patch.object(clustering,'connect',lambda:duckdb.connect(str(db))),patch.object(clustering,'workdir',lambda:Path(directory)):
                    clustering.main()
            con=duckdb.connect(str(db))
            self.assertEqual(con.execute('SELECT count(*) FROM entities WHERE threshold=.9').fetchone()[0],2)
            self.assertEqual(con.execute('SELECT max(documents) FROM entity_counts WHERE threshold=.9').fetchone()[0],3)
            con.close()
if __name__=='__main__':unittest.main()
