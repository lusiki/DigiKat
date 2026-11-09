import copy
from pathlib import Path
import tempfile
import unittest

import duckdb
from aggregate_exports import (PLATFORMS,COLUMNS,platform_rows,
    export_platform_coverage,verify_platform_coverage,read_coverage)


def fixture():
    return dict(corpus_sha256='a'*64,config_hash='b'*64,created_utc='2026-10-27T00:00:00+00:00',
        values=dict(platforms=[dict(platform=p,documents=100,long_documents=80,
                                   unique_texts=90) for p in sorted(PLATFORMS)]))


class AggregateExports(unittest.TestCase):
    def test_roundtrip_and_resume_preserve_schema_values_and_bytes(self):
        data=fixture()
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'coverage.parquet'
            manifest=export_platform_coverage(data,path);original=path.read_bytes()
            self.assertEqual(read_coverage(path),platform_rows(data))
            self.assertEqual(verify_platform_coverage(path,data,manifest)['rows'],9)
            self.assertEqual(export_platform_coverage(data,path),manifest)
            self.assertEqual(path.read_bytes(),original)
            changed=copy.deepcopy(data);changed['values']['platforms'][0]['long_documents']=79
            with self.assertRaisesRegex(ValueError,'differs'):
                export_platform_coverage(changed,path)

    def test_small_cells_and_complements_cannot_be_reconstructed_from_other_rows(self):
        for value in range(5):
            for field in ('long_documents','short_documents','documents'):
                data=fixture();first=data['values']['platforms'][0]
                if field=='documents':
                    first.update(documents=value,long_documents=value)
                elif field=='short_documents':
                    first['long_documents']=100-value
                else:
                    first['long_documents']=value
                rows=platform_rows(data)
                self.assertTrue(all(r['long_documents'] is None and r['short_documents'] is None
                                    and r['eligibility_counts_suppressed'] for r in rows))
                if field=='documents':
                    self.assertTrue(all(r['documents'] is None and r['document_counts_suppressed'] for r in rows))
                else:
                    self.assertTrue(all(r['documents']==100 and not r['document_counts_suppressed'] for r in rows))

    def test_next_day_report_resume_keeps_original_aggregate_timestamp_and_bytes(self):
        data=fixture()
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'coverage.parquet'
            manifest=export_platform_coverage(data,path);original=path.read_bytes()
            later=copy.deepcopy(data);later['created_utc']='2026-10-28T00:00:00+00:00'
            self.assertEqual(export_platform_coverage(later,path),manifest)
            self.assertEqual(path.read_bytes(),original)
            self.assertEqual({r['created_utc'] for r in read_coverage(path)},{data['created_utc']})
            verify_platform_coverage(path,later,manifest)
            for field in ('corpus_sha256','config_hash'):
                changed=copy.deepcopy(later);changed[field]='c'*64
                with self.assertRaisesRegex(ValueError,'differs'):
                    export_platform_coverage(changed,path)

    def test_unknown_platform_and_invalid_counts_rejected(self):
        data=fixture();data['values']['platforms'][0]['platform']='private.account'
        with self.assertRaisesRegex(ValueError,'platform'):platform_rows(data)
        for n,eligible in [(4,5),(100,-1),(100,1.5),(True,True)]:
            data=fixture();data['values']['platforms'][0].update(documents=n,long_documents=eligible)
            with self.assertRaisesRegex(ValueError,'counts'):platform_rows(data)

    def test_extra_identity_column_and_file_tampering_rejected(self):
        data=fixture()
        with tempfile.TemporaryDirectory() as directory:
            folder=Path(directory);path=folder/'coverage.parquet'
            manifest=export_platform_coverage(data,path)
            extra=folder/'extra.parquet'
            with duckdb.connect() as con:
                con.read_parquet(str(path)).project("*, 'private@example.test' AS email").write_parquet(str(extra))
            with self.assertRaisesRegex(ValueError,'schema'):read_coverage(extra)
            path.write_bytes(extra.read_bytes())
            with self.assertRaisesRegex(ValueError,'Changed Parquet'):
                verify_platform_coverage(path,data,manifest)


if __name__=='__main__':unittest.main()
