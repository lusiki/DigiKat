"""Identity-free Parquet coverage export; conservative complementary suppression."""
import os
from datetime import datetime
from pathlib import Path

import duckdb
from voices_common import file_sha

PLATFORMS = {'web','facebook','instagram','twitter','youtube','comment','forum','reddit','tiktok'}
COLUMNS = ['platform','documents','long_documents','short_documents',
           'document_counts_suppressed','eligibility_counts_suppressed',
           'corpus_sha256','config_hash','created_utc']


def platform_rows(data, *, created_utc=None):
    created_utc = data['created_utc'] if created_utc is None else created_utc
    if datetime.fromisoformat(created_utc).tzinfo is None:
        raise ValueError('Aggregate creation timestamp must include its timezone')
    source = data['values']['platforms']
    if len(source) != len(PLATFORMS) or {r['platform'] for r in source} != PLATFORMS:
        raise ValueError('Exactly the nine corpus platform labels are required')
    for row in source:
        n, eligible = row['documents'], row['long_documents']
        if type(n) is not int or type(eligible) is not int or not 0 <= eligible <= n:
            raise ValueError('Invalid platform coverage counts')
    # Suppress the entire column family if any member is small. A known corpus
    # total or a row total must not reconstruct one suppressed platform cell.
    hide_documents = any(r['documents'] < 5 for r in source)
    hide_eligibility = hide_documents or any(
        min(r['long_documents'], r['documents']-r['long_documents']) < 5 for r in source)
    return [dict(platform=r['platform'],
        documents=None if hide_documents else r['documents'],
        long_documents=None if hide_eligibility else r['long_documents'],
        short_documents=None if hide_eligibility else r['documents']-r['long_documents'],
        document_counts_suppressed=hide_documents,
        eligibility_counts_suppressed=hide_eligibility,
        corpus_sha256=data['corpus_sha256'], config_hash=data['config_hash'],
        created_utc=created_utc) for r in sorted(source,key=lambda r:r['platform'])]


def read_coverage(path):
    with duckdb.connect() as con:
        result = con.execute('SELECT * FROM read_parquet(?) ORDER BY platform',[str(path)])
        columns = [column[0] for column in result.description]
        if columns != COLUMNS:
            raise ValueError('Unexpected Parquet schema; only identity-free coverage columns are allowed')
        return [dict(zip(columns,row)) for row in result.fetchall()]


def export_platform_coverage(data, path):
    path = Path(path)
    expected = platform_rows(data)
    if path.exists():
        actual = read_coverage(path)
        timestamps = {row['created_utc'] for row in actual}
        if len(timestamps) != 1:
            raise ValueError('Inconsistent saved aggregate creation timestamps')
        # The report can be regenerated on a later day without changing these
        # counts. Keep the aggregate's original creation time and exact bytes;
        # the enclosing release manifest binds it to the current report hash.
        expected = platform_rows(data,created_utc=timestamps.pop())
        if actual != expected:
            raise ValueError('Existing Parquet coverage differs from frozen report evidence')
    else:
        path.parent.mkdir(parents=True,exist_ok=True)
        temporary = path.with_suffix(path.suffix+'.tmp')
        with duckdb.connect() as con:
            con.execute('''CREATE TABLE coverage(platform VARCHAR,documents BIGINT,
                long_documents BIGINT,short_documents BIGINT,document_counts_suppressed BOOLEAN,
                eligibility_counts_suppressed BOOLEAN,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
            con.executemany('INSERT INTO coverage VALUES (?,?,?,?,?,?,?,?,?)',
                            [[row[key] for key in COLUMNS] for row in expected])
            con.table('coverage').write_parquet(str(temporary),compression='zstd')
        if read_coverage(temporary) != expected:
            raise ValueError('Parquet round-trip changed coverage values')
        with temporary.open('r+b') as stream:
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary,path)
    return dict(rows=len(expected),columns=COLUMNS,sha256=file_sha(path),
        created_utc=expected[0]['created_utc'],
        code_sha256=file_sha(__file__),
        scope='Identity-free full-corpus platform coverage; no people, accounts, URLs, document IDs or text.',
        suppression='If any cell is below five, suppress its full column family across platforms; both sides of the length split are suppressed together.')


def verify_platform_coverage(path, data, manifest):
    expected = platform_rows(data,created_utc=manifest['created_utc'])
    if manifest['columns'] != COLUMNS or manifest['rows'] != len(expected):
        raise ValueError('Changed Parquet manifest schema or count')
    if manifest['sha256'] != file_sha(path) or manifest['code_sha256'] != file_sha(__file__):
        raise ValueError('Changed Parquet file or disclosure implementation')
    if read_coverage(path) != expected:
        raise ValueError('Parquet coverage does not reproduce from report evidence')
    return dict(rows=len(expected),columns=COLUMNS,sha256=file_sha(path))
