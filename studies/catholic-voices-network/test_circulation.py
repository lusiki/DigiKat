import importlib,unittest,tempfile,hashlib
from pathlib import Path
from unittest.mock import patch
import duckdb
from circulation_bulk import BulkConnection
entry=importlib.import_module('15_circulation')
m=entry.reference
class Circulation(unittest.TestCase):
    def test_short_texts_do_not_match(self):
        self.assertIs(entry.shingles,m.shingles)
        self.assertIs(entry.jaccard,m.jaccard)
        self.assertIs(entry.components,m.components)
        self.assertIsNone(m.jaccard(m.shingles('jedna dva'),m.shingles('tri četiri')))
    def test_literal_content_and_order(self):
        a=m.shingles('Vjera nas poziva na pomoć slabijima u zajednici.')
        self.assertEqual(m.jaccard(a,m.shingles('VJERA nas poziva na pomoć slabijima u zajednici!')),1)
        self.assertEqual(m.jaccard(a,m.shingles('Zajednici u slabijima pomoć na poziva nas vjera')),0)
    def test_transitive_family_is_explicit(self):
        result=m.components([1,2,3,4],[(1,2),(2,3)])
        self.assertEqual(result,{1:1,2:1,3:1,4:4})
    def test_persisted_pipeline_and_resume(self):
        signature=importlib.import_module('04_minhash').signature
        a=' '.join('riječ'+str(i) for i in range(300))
        texts=[a,a.replace('riječ150','promjena'),'potpuno drugačiji tekst s drugim riječima','kratko','još kraće']
        with tempfile.TemporaryDirectory() as directory:
            db=Path(directory)/'fixture.duckdb';con=duckdb.connect(str(db))
            con.execute('CREATE TABLE docs (doc_id VARCHAR,text_clean VARCHAR,text_sha256 VARCHAR)')
            con.execute('CREATE TABLE minhash_queue (text_sha256 VARCHAR,doc_id VARCHAR)')
            con.execute('''CREATE TABLE minhash_signatures (text_sha256 VARCHAR,word_count INTEGER,
              shingle_count INTEGER,signature BLOB,seconds DOUBLE,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
            hashes=[]
            for i,text in enumerate(texts):
                h=hashlib.sha256(text.encode()).hexdigest();hashes.append(h)
                con.execute('INSERT INTO docs VALUES (?,?,?)',[str(i),text,h])
                con.execute('INSERT INTO minhash_queue VALUES (?,?)',[h,str(i)])
                con.execute('INSERT INTO minhash_signatures VALUES (?,?,?,?,?,?,?,?)',
                    [*signature((h,text)),m.CORPUS_HASH,m.CONFIG_HASH,m.utc()])
            con.close()
            # The entry now requires a real parity proof. Exercise the archived
            # unchanged algorithm directly on this isolated fixture, including
            # a resume through the production bulk connection adapter.
            for bulk in (False,True):
                def fixture_connection():
                    raw=duckdb.connect(str(db))
                    return BulkConnection(raw) if bulk else raw
                for _ in range(2):
                    with patch.object(m,'connect',fixture_connection),patch.object(m,'workdir',lambda:Path(directory)):
                        m.main()
            con=duckdb.connect(str(db))
            families=dict(con.execute('''SELECT t.text_sha256,c.family_id FROM circulation_membership c
              JOIN circulation_texts t USING(text_id) WHERE threshold=.85''').fetchall())
            self.assertEqual(families[hashes[0]],families[hashes[1]])
            self.assertEqual(len(set(families.values())),4)
            self.assertEqual(con.execute('SELECT count(*) FROM circulation_membership').fetchone()[0],15)
            con.close()
if __name__=='__main__':unittest.main()
