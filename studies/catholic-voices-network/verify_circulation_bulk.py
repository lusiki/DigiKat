"""Check every inserted value, rollback, reopen and timing before bulk handoff.

Default uses only constructed private fixture DBs. --verify-actual additionally
opens the real DB; run only after its writer/supervisor have stopped.
"""
import argparse
import hashlib
import json
import struct
import tempfile
import time
from pathlib import Path
import duckdb
from circulation_bulk import BulkConnection, reference
import voices_common as common

DDL = {
    'circulation_bands': 'text_id INTEGER,band INTEGER,band_hash UBIGINT,shingle_count INTEGER,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(text_id,band)',
    'circulation_pair_checks': 'a INTEGER,b INTEGER,jaccard DOUBLE,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(a,b)',
    'circulation_membership': 'threshold DOUBLE,text_id INTEGER,family_id INTEGER,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(threshold,text_id)',
}


def pipeline_check():
    """Run unchanged whole algorithm twice through each connection type."""
    original_connect, original_atomic = reference.connect, reference.atomic_json
    results = {}
    try:
        with tempfile.TemporaryDirectory(prefix='circulation-flow-', dir=common.STUDY/'output/private') as temp:
            for kind in ['reference', 'bulk']:
                path = Path(temp)/(kind+'.duckdb')
                con = duckdb.connect(str(path))
                con.execute('CREATE TABLE docs(doc_id VARCHAR,text_clean VARCHAR)')
                con.execute('CREATE TABLE minhash_queue(text_sha256 VARCHAR,doc_id VARCHAR)')
                con.execute('CREATE TABLE minhash_signatures(text_sha256 VARCHAR,shingle_count INTEGER,signature BLOB,corpus_sha256 VARCHAR,config_hash VARCHAR)')
                base = 'Ovo je dovoljno dugačak hrvatski tekst za usporedbu istih riječi.'
                for index, text in enumerate([base, base.upper(), 'Kratko']):
                    doc_id = str(index); digest = hashlib.sha256(text.encode()).hexdigest()
                    count = len(reference.shingles(text))
                    signature = struct.pack('<128I', *range(128)) if count else None
                    con.execute('INSERT INTO docs VALUES (?,?)', [doc_id,text])
                    con.execute('INSERT INTO minhash_queue VALUES (?,?)', [digest,doc_id])
                    con.execute('INSERT INTO minhash_signatures VALUES (?,?,?,?,?)', [digest,count,signature,common.CORPUS_HASH,common.CONFIG_HASH])
                con.close()
                def connect_fixture():
                    raw = duckdb.connect(str(path))
                    return raw if kind == 'reference' else BulkConnection(raw)
                captures = []
                reference.connect = connect_fixture
                reference.atomic_json = lambda destination, payload: captures.append({k:v for k,v in payload.items() if k!='created_utc'})
                # No real workdir or DB is used: only the report destination path is evaluated.
                original_workdir = reference.workdir
                reference.workdir = lambda: Path(temp)
                try:
                    reference.main()
                    first = {}
                    for repeat in range(2):
                        reopened = duckdb.connect(str(path), read_only=True)
                        actual = {}
                        for table in ['circulation_texts','circulation_bands','circulation_candidates','circulation_pair_checks','circulation_membership']:
                            actual[table] = reopened.execute(f'SELECT * EXCLUDE(created_utc) FROM {table} ORDER BY 1,2').fetchall()
                        reopened.close()
                        if repeat == 0:
                            first = actual
                            reference.main()
                        else:
                            assert actual == first
                    assert captures[0] == captures[1]
                    assert captures[0]['candidate_pairs'] == 1
                    assert all(item['families'] == 2 for item in captures[0]['thresholds'])
                    results[kind] = (actual, captures[0])
                finally:
                    reference.workdir = original_workdir
        assert results['reference'] == results['bulk']
        return dict(full_algorithm_identical=True, unchanged_resume_identical=True,
                    candidate_pairs=1, thresholds=[.8,.85,.9])
    finally:
        reference.connect, reference.atomic_json = original_connect, original_atomic


def fixture_check():
    stamp = '2026-10-26T00:00:00+00:00'
    provenance = (common.CORPUS_HASH, common.CONFIG_HASH, stamp)
    rows = {
        'circulation_bands': [(i//16+1, i%16, (2**64-1-i), 500, *provenance) for i in range(80000)],
        'circulation_pair_checks': [(i, i+1, None if i == 0 else i/1000, *provenance) for i in range(1000)],
        'circulation_membership': [(t, i, max(0, i-1), *provenance) for t in [.8, .85, .9] for i in range(20000)],
    }
    root = common.STUDY/'output/private'
    root.mkdir(parents=True, exist_ok=True)
    result = {}
    with tempfile.TemporaryDirectory(prefix='circulation-bulk-', dir=root) as temp:
        for kind in ['reference', 'bulk']:
            path = Path(temp)/(kind+'.duckdb')
            raw = duckdb.connect(str(path)); raw.execute('SET threads=4')
            con = raw if kind == 'reference' else BulkConnection(raw)
            timings = {}
            for table, schema in DDL.items():
                con.execute(f'CREATE TABLE {table} ({schema})')
                query = f'INSERT INTO {table} VALUES ({",".join("?" for _ in rows[table][0])})'
                start = time.perf_counter()
                with common.transaction(con):
                    con.executemany(query, rows[table])
                con.execute('CHECKPOINT')
                timings[table] = time.perf_counter()-start
                # A duplicate after a new row must leave no partial insertion.
                fresh = list(rows[table][0]); fresh[1 if table == 'circulation_membership' else 0] = 999999
                try:
                    with common.transaction(con):
                        con.executemany(query, [tuple(fresh), rows[table][0]])
                except duckdb.ConstraintException:
                    pass
                else:
                    raise AssertionError('Duplicate primary key unexpectedly accepted')
                assert con.execute(f'SELECT count(*) FROM {table}').fetchone()[0] == len(rows[table])
            con.close()
            reopened = duckdb.connect(str(path), read_only=True)
            for table, expected in rows.items():
                actual = reopened.execute(f'SELECT * FROM {table} ORDER BY 1,2').fetchall()
                assert actual == sorted(expected, key=lambda row: row[:2]), (kind, table)
            reopened.close()
            result[kind+'_seconds'] = timings
    result.update(passed=True, pipeline=pipeline_check(), rows_per_table={name: len(value) for name, value in rows.items()},
                  exact_values=True, unsigned_64_bit_preserved=True, null_preserved=True,
                  rollback_verified=True, reopen_verified=True)
    return result


def actual_check(fixture):
    path = common.workdir()/'circulation_bulk_parity.json'
    con = common.connect()
    pinned = con.execute("SELECT settings_json FROM stage_settings WHERE stage='circulation_bulk_v1'").fetchone()
    if pinned:
        settings = json.loads(pinned[0])
        assert common.file_sha(path) == settings['proof_sha256']
        con.close()
        return dict(cached=True, proof_sha256=common.file_sha(path))
    settings = json.loads(con.execute("SELECT settings_json FROM stage_settings WHERE stage='circulation_v1'").fetchone()[0])
    assert settings['code'] == common.file_sha(reference.__file__)
    texts = con.execute('''SELECT t.text_id,t.signature,t.shingle_count FROM circulation_texts t
      WHERE EXISTS (SELECT 1 FROM circulation_bands b WHERE b.text_id=t.text_id)
      ORDER BY t.text_id LIMIT 2000''').fetchall()
    assert len(texts) == 2000
    expected = []
    for tid, signature, count in texts:
        assert len(signature) == 512
        for band in range(16):
            value = struct.unpack('<Q',hashlib.blake2b(signature[band*32:(band+1)*32],digest_size=8).digest())[0]
            expected.append((tid, band, value, count, common.CORPUS_HASH, common.CONFIG_HASH))
    saved = con.execute('''SELECT text_id,band,band_hash,shingle_count,corpus_sha256,config_hash
      FROM circulation_bands WHERE text_id IN (SELECT unnest(?)) ORDER BY text_id,band''', [[r[0] for r in texts]]).fetchall()
    assert saved == expected
    totals = con.execute('SELECT count(*),count(DISTINCT text_id) FROM circulation_bands').fetchone()
    assert totals[0] == 16*totals[1]
    assert con.execute('SELECT count(*) FROM (SELECT text_id FROM circulation_bands GROUP BY text_id HAVING count(*)<>16)').fetchone()[0] == 0
    con.close()
    result = dict(created_utc=common.utc(), passed=True, corpus_sha256=common.CORPUS_HASH,
      config_hash=common.CONFIG_HASH, adapter_sha256=common.file_sha(common.STUDY/'circulation_bulk.py'),
      reference_sha256=common.file_sha(reference.__file__), verifier_sha256=common.file_sha(__file__),
      fixture=fixture, actual_committed_bands_verified=len(saved), committed_bands=totals[0],
      committed_texts=totals[1], caveat='Execution equivalence and local timing only; no recognition or duplicate-retrieval accuracy claim.')
    common.atomic_json(path, result)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--verify-actual', action='store_true')
    args = parser.parse_args()
    fixture = fixture_check()
    result = actual_check(fixture) if args.verify_actual else fixture
    if not args.verify_actual:
        common.atomic_json(common.STUDY/'output/private/circulation_bulk_fixture.json', result)
    print(json.dumps(result, ensure_ascii=False))


if __name__ == '__main__':
    main()
