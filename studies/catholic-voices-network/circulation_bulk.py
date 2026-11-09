"""Execution adapter: unchanged circulation algorithm, typed bulk inserts.

All calculations and transaction boundaries remain in byte-preserved v1.
Only its three INSERT/executemany statements use typed pandas columns instead of per-row calls.
"""
import importlib
import json
import pandas as pd
import voices_common as common

reference = importlib.import_module('15_circulation_v1')
SCHEMAS = {
    'circulation_bands': [
        ('text_id', 'int32'), ('band', 'int32'), ('band_hash', 'uint64'),
        ('shingle_count', 'int32'), ('corpus_sha256', 'object'),
        ('config_hash', 'object'), ('created_utc', 'object')],
    'circulation_pair_checks': [
        ('a', 'int32'), ('b', 'int32'), ('jaccard', 'float64'),
        ('corpus_sha256', 'object'), ('config_hash', 'object'), ('created_utc', 'object')],
    'circulation_membership': [
        ('threshold', 'float64'), ('text_id', 'int32'), ('family_id', 'int32'),
        ('corpus_sha256', 'object'), ('config_hash', 'object'), ('created_utc', 'object')],
}
STATEMENTS = {
    ''.join(f'INSERT INTO {name} VALUES ({",".join("?" for _ in schema)})'.split()).lower(): name
    for name, schema in SCHEMAS.items()
}


class BulkConnection:
    def __init__(self, connection):
        self.connection = connection

    def __getattr__(self, name):
        return getattr(self.connection, name)

    def executemany(self, sql, rows):
        table_name = STATEMENTS.get(''.join(sql.split()).lower())
        if table_name is None:
            raise ValueError('Unregistered circulation batch statement')
        rows = list(rows)
        if not rows:
            return self
        schema = SCHEMAS[table_name]
        if any(len(row) != len(schema) for row in rows):
            raise ValueError('Circulation batch column count changed')
        table = pd.DataFrame({name: pd.Series([row[index] for row in rows], dtype=dtype)
                              for index, (name, dtype) in enumerate(schema)})
        self.connection.register('_circulation_insert_batch', table)
        try:
            self.connection.execute(f'INSERT INTO {table_name} SELECT * FROM _circulation_insert_batch')
        finally:
            self.connection.unregister('_circulation_insert_batch')
        return self


def main():
    proof_path = common.workdir()/'circulation_bulk_parity.json'
    proof = json.loads(proof_path.read_text(encoding='utf-8'))
    assert proof['passed'] and proof['actual_committed_bands_verified'] > 0
    assert proof['corpus_sha256'] == common.CORPUS_HASH
    assert proof['config_hash'] == common.CONFIG_HASH
    assert proof['adapter_sha256'] == common.file_sha(__file__)
    assert proof['reference_sha256'] == common.file_sha(reference.__file__)

    def connect_bulk():
        con = common.connect()
        common.pin_stage(con, 'circulation_bulk_v1', dict(
            adapter_sha256=common.file_sha(__file__), reference_sha256=common.file_sha(reference.__file__),
            proof_sha256=common.file_sha(proof_path), pandas_version=pd.__version__,
            scope='same rows, calculations and transactions; typed pandas INSERT SELECT only'))
        return BulkConnection(con)

    original_connect = reference.connect
    original_atomic = reference.atomic_json
    try:
        reference.connect = connect_bulk
        reference.atomic_json = common.atomic_json_stable
        reference.main()
    finally:
        reference.connect = original_connect
        reference.atomic_json = original_atomic


if __name__ == '__main__':
    main()
