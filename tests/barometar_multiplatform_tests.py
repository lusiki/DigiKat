"""Identity/fallback regressions use fabricated records only."""
import importlib.util
from pathlib import Path
import unittest
import json
import sys
import tempfile
import duckdb

spec = importlib.util.spec_from_file_location("collector", Path(__file__).parents[1] / "studies/demokrscanstvo-barometar/multiplatform_collect.py")
collector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(collector)
sys.path.insert(0,str(Path(spec.origin).parent))
import multiplatform_release as builder


class CaptureIdentityTests(unittest.TestCase):
    def test_platform_namespaces_parent_urls_and_fallbacks(self):
        con = duckdb.connect()
        con.execute('''CREATE TABLE sample(ITEM_ID BIGINT,SOURCE_BATCH VARCHAR,SOURCE_TYPE VARCHAR,
          "FROM" VARCHAR,URL VARCHAR,"DATE" VARCHAR,"TIME" VARCHAR,TITLE VARCHAR,FULL_TEXT VARCHAR,MENTION_SNIPPET VARCHAR)''')
        common = ["new", "comment", "source", "https://example.org/parent", "2026-01-01", "12:00"]
        rows = [[1,*common,"", "first comment", ""], [2,*common,"", "second comment", ""],
                [1,"new","tv",*common[2:],"", "broadcast", ""],
                [None,"old","web",*common[2:],"title", "", "snippet"],
                [None,"old","web",*common[2:],"title", "", "snippet"],
                [None,"old","web",*common[2:],"title", "\u00a0", ""],
                [None,"old","web",*common[2:],"", " ", ""]]
        con.executemany("INSERT INTO sample VALUES (?,?,?,?,?,?,?,?,?,?)", rows)
        records = con.execute(collector.prepared_sql("sample")).fetchall()
        keys = [r[1] for r in records]
        self.assertEqual(len(set(keys[:3])),3)
        self.assertEqual(keys[3],keys[4])
        self.assertEqual([r[-1] for r in records], ["full_text"]*3+["snippet","snippet","title","none"])
        self.assertEqual(records[3][-2],"snippet")
        con.close()

    def test_release_reconciliation_zero_and_missing(self):
        with tempfile.TemporaryDirectory() as temp:
            root=Path(temp); work=root/'work'; folder=work/'snapshot'; decisions=folder/'classified'
            decisions.mkdir(parents=True)
            review=root/'assistant_review_55_2026-09-19';review.mkdir()
            (review/'assistant-coding-55.json').write_text('{}',encoding='utf-8')
            identity={'extraction':'fixture','definition':'fixture','adapter_sha256':'fixture'}
            collector.write_json(work/'active.json',{'folder':str(folder),'signature':'fixture','identity':{
                'source_bytes':1,'source_mtime_ns':1,'contract_sha256':'fixture','collector_sha256':'fixture'}})
            collector.write_json(work/'contract.json',{'definition_version':'fixture','policy':'fixture'})
            collector.write_json(work/'definitions.json',{'entries':[]})
            collector.write_json(work/'environment.json',{'fixture':True})
            collector.write_json(folder/'classification.json',{'folder':str(decisions),'identity':identity})
            collector.write_json(decisions/'complete.json',{'identity':identity,'months':['2026-01','2026-02','2026-03']})
            collector.write_json(folder/'audit.json',{'raw_records':32,'unique_records':30,'duplicates_removed':2,
                'eligible_records':30,'candidate_records':1})
            con=duckdb.connect()
            con.execute("CREATE TABLE den(platform VARCHAR,day VARCHAR,month VARCHAR,source_batch VARCHAR,text_basis VARCHAR,records BIGINT,eligible_records BIGINT,candidates BIGINT)")
            con.execute("INSERT INTO den VALUES ('web','2026-01-01','2026-01','new','full_text',10,10,1),('web','2026-03-01','2026-03','new','title',20,20,0)")
            con.execute(f"COPY den TO {collector.quote(folder/'denominator.parquet')} (FORMAT PARQUET)")
            con.execute("CREATE TABLE dec(record_key VARCHAR,day VARCHAR,month VARCHAR,platform VARCHAR,source_batch VARCHAR,text_basis VARCHAR,route_set VARCHAR,themes VARCHAR)")
            con.execute("INSERT INTO dec VALUES ('private-key','2026-01-01','2026-01','web','new','full_text','A1;B','work')")
            con.execute(f"COPY dec TO {collector.quote(decisions/'2026-01.parquet')} (FORMAT PARQUET)")
            con.close()
            destination=root/'public';builder.release(work,destination)
            con=duckdb.connect()
            result=con.execute(f"SELECT month,matching_records,per_10000 FROM read_csv_auto({collector.quote(destination/'monthly.csv')}) ORDER BY month").fetchall()
            self.assertEqual(result,[('2026-01',1,1000.0),('2026-02',0,None),('2026-03',0,0.0)])
            self.assertFalse(any('private-key' in p.read_text(encoding='utf-8') for p in destination.iterdir()))
            con.close()


if __name__ == "__main__":
    unittest.main()
