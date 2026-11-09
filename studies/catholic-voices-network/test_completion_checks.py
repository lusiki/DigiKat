import hashlib,json,tempfile,unittest
import duckdb
from pathlib import Path
from completion_checks import require_visual_review,require_pinned_files,require_document_coverage
from report_contract import sha

class CompletionChecks(unittest.TestCase):
    def test_equal_counts_cannot_hide_wrong_document_ids(self):
        con=duckdb.connect()
        try:
            con.execute("CREATE TABLE docs AS SELECT * FROM (VALUES ('a'),('b')) t(doc_id)")
            con.execute("CREATE TABLE processed AS SELECT * FROM (VALUES ('a'),('wrong')) t(doc_id)")
            with self.assertRaisesRegex(ValueError,'Document IDs differ'):
                require_document_coverage(con,['docs','processed'],2)
            con.execute("UPDATE processed SET doc_id='b' WHERE doc_id='wrong'")
            self.assertEqual(require_document_coverage(con,['docs','processed'],2),{'docs':2,'processed':2})
            con.execute("UPDATE processed SET doc_id='a' WHERE doc_id='b'")
            with self.assertRaisesRegex(ValueError,'Document IDs differ'):
                require_document_coverage(con,['processed'],2)
            con.execute("UPDATE processed SET doc_id=NULL")
            with self.assertRaisesRegex(ValueError,'Document IDs differ'):
                require_document_coverage(con,['processed'],2)
            con.execute("DELETE FROM processed")
            with self.assertRaisesRegex(ValueError,'Incomplete full-corpus'):
                require_document_coverage(con,['processed'],2)
            con.execute("UPDATE docs SET doc_id='a'")
            with self.assertRaisesRegex(ValueError,'reference is incomplete'):
                require_document_coverage(con,['docs'],2)
        finally:con.close()

    def test_execution_source_and_proof_must_match_saved_pin(self):
        with tempfile.TemporaryDirectory() as folder:
            source=Path(folder)/'engine.py';proof=Path(folder)/'parity.json'
            source.write_text('original engine',encoding='utf-8');proof.write_text('{"passed":true}',encoding='utf-8')
            raw=json.dumps(dict(code=sha(source),proof=sha(proof)))
            saved=[('execution',hashlib.sha256(raw.encode()).hexdigest(),raw)]
            contracts={'execution':dict(code=source,proof=proof)}
            evidence=require_pinned_files(saved,contracts)
            self.assertEqual(evidence['execution']['code']['sha256'],sha(source))
            with self.assertRaisesRegex(ValueError,'Missing execution pin'):require_pinned_files([],contracts)
            with self.assertRaisesRegex(ValueError,'Duplicate or damaged'):require_pinned_files(saved+saved,contracts)
            with self.assertRaisesRegex(ValueError,'Duplicate or damaged'):
                require_pinned_files([('execution','0'*64,raw)],contracts)
            source.write_text('changed engine',encoding='utf-8')
            with self.assertRaisesRegex(ValueError,'Changed pinned file'):require_pinned_files(saved,contracts)
            source.write_text('original engine',encoding='utf-8');proof.write_text('{"passed":false}',encoding='utf-8')
            with self.assertRaisesRegex(ValueError,'Changed pinned file'):require_pinned_files(saved,contracts)
            proof.unlink()
            with self.assertRaisesRegex(ValueError,'Missing pinned file'):require_pinned_files(saved,contracts)

    def test_preview_stale_or_incomplete_review_cannot_complete(self):
        with tempfile.TemporaryDirectory() as folder:
            pdf=Path(folder)/'test.pdf';html=Path(folder)/'test.html'
            pdf.write_bytes(b'constructed');html.write_text('constructed',encoding='utf-8')
            render=dict(preview=False,mechanical_pass=True,pages=25,pdf_sha256=sha(pdf),html_sha256=sha(html))
            review=dict(scope='actual_final_report',pdf_sha256=sha(pdf),html_sha256=sha(html),
              reviewed_pages=list(range(1,26)),pdf_passed=True,html_passed=True,unresolved_issues=[])
            require_visual_review(render,review,pdf,html)
            render['preview']=True
            with self.assertRaises(ValueError):require_visual_review(render,review,pdf,html)
            render['preview']=False;review['reviewed_pages'].pop()
            with self.assertRaises(ValueError):require_visual_review(render,review,pdf,html)
            review['reviewed_pages'].append(25);pdf.write_bytes(b'changed')
            with self.assertRaises(ValueError):require_visual_review(render,review,pdf,html)

if __name__=='__main__':unittest.main()
