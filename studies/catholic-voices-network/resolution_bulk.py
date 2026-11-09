"""Qualified write adapter around the byte-preserved dated-resolution engine.

Only three executemany INSERTs change. Classification, title rules, batches,
transaction boundaries and completed-document markers stay in the reference.
Production requires exact whole-pipeline and committed-result parity first.
"""
import importlib
import json
import pandas as pd
import voices_common as common

reference = importlib.import_module('24_resolve_mentions_v1')
MIN_ACTUAL_DOCUMENTS = 2000
MIN_SPEEDUP = 1.2
SCHEMAS = {
    'resolved_mentions': [('doc_id','object'),('start_char','int32'),('end_char','int32'),
        ('surface','object'),('entity_id','object'),('cluster_entity_id','object'),
        ('qid','object'),('life_class','object'),('origin','object'),
        ('corpus_sha256','object'),('config_hash','object'),('created_utc','object')],
    'title_mentions': [('doc_id','object'),('start_char','int32'),('end_char','int32'),
        ('surface','object'),('qid','object'),('status','object'),('offices_json','object'),
        ('corpus_sha256','object'),('config_hash','object'),('created_utc','object')],
    'resolved_docs': [('doc_id','object'),('corpus_sha256','object'),
        ('config_hash','object'),('created_utc','object')],
}
STATEMENTS = {''.join(f'INSERT INTO {name} VALUES ({",".join("?" for _ in schema)})'.split()).lower():name
              for name,schema in SCHEMAS.items()}


class BulkConnection:
    def __init__(self, connection):
        self.connection = connection

    def __getattr__(self, name):
        return getattr(self.connection, name)

    def executemany(self, sql, rows):
        name = STATEMENTS.get(''.join(sql.split()).lower())
        if name is None:
            raise ValueError('Unregistered dated-resolution batch statement')
        rows = list(rows)
        if not rows:
            return self
        schema = SCHEMAS[name]
        if any(len(row) != len(schema) for row in rows):
            raise ValueError('Dated-resolution batch column count changed')
        frame = pd.DataFrame({column:pd.Series([row[i] for row in rows],dtype=dtype)
                              for i,(column,dtype) in enumerate(schema)})
        self.connection.register('_resolution_insert_batch',frame)
        try:
            self.connection.execute(f'INSERT INTO {name} SELECT * FROM _resolution_insert_batch')
        finally:
            self.connection.unregister('_resolution_insert_batch')
        return self


def main():
    proof_path = common.workdir()/'resolution_bulk_parity.json'
    proof = json.loads(proof_path.read_text(encoding='utf-8'))
    assert proof['passed'] and proof['fixture']['passed']
    assert proof['actual_documents_verified'] >= MIN_ACTUAL_DOCUMENTS
    assert proof['actual']['full_pipeline_identical'] and proof['actual']['identical_to_committed']
    assert proof['actual']['unchanged_resume_identical']
    assert proof['actual']['speedup'] >= MIN_SPEEDUP
    assert proof['minimum_actual_documents'] == MIN_ACTUAL_DOCUMENTS
    assert proof['minimum_speedup'] == MIN_SPEEDUP
    assert proof['corpus_sha256'] == common.CORPUS_HASH and proof['config_hash'] == common.CONFIG_HASH
    assert proof['adapter_sha256'] == common.file_sha(__file__)
    assert proof['reference_sha256'] == common.file_sha(reference.__file__)
    assert proof['verifier_sha256'] == common.file_sha(common.STUDY/'verify_resolution_bulk.py')

    def connect_bulk():
        con = common.connect()
        saved = con.execute("SELECT settings_hash FROM stage_settings WHERE stage='resolved_mentions_v1'").fetchone()
        assert saved and saved[0] == proof['scientific_settings_hash']
        common.pin_stage(con,'resolved_mentions_bulk_v1',dict(
            adapter_sha256=common.file_sha(__file__),reference_sha256=common.file_sha(reference.__file__),
            proof_sha256=common.file_sha(proof_path),pandas_version=pd.__version__,
            scope='Identical dated-resolution rows and per-500-document transactions; typed INSERT SELECT only'))
        return BulkConnection(con)

    original_connect, original_atomic = reference.connect, reference.atomic_json
    try:
        reference.connect = connect_bulk
        reference.atomic_json = common.atomic_json_stable
        reference.main()
    finally:
        reference.connect, reference.atomic_json = original_connect, original_atomic


if __name__ == '__main__':
    main()
