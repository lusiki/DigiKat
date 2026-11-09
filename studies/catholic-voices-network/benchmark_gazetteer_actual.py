"""Compare parallel matching against completed v1 rows; DB must be idle.

Corpus text stays in this process. Outputs contain aggregate timing/parity only.
"""
import argparse
import concurrent.futures
import hashlib
import json
import time
import gazetteer_parallel as candidate
from voices_common import *


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--minimum-committed', type=int, required=True)
    args = parser.parse_args()
    con = connect()
    pinned = con.execute("SELECT settings_json FROM stage_settings WHERE stage='gazetteer_parallel_v1'").fetchone()
    if pinned:
        path = workdir()/'gazetteer_actual_parity.json'
        assert file_sha(path) == json.loads(pinned[0])['parity_sha']
        con.close()
        print(json.dumps(dict(cached=True, proof_sha256=file_sha(path))), flush=True)
        return
    completed = con.execute('SELECT count(*) FROM gazetteer_docs').fetchone()[0]
    assert completed >= args.minimum_committed
    ner = con.execute("SELECT count(*) FROM ner_docs WHERE status='complete'").fetchone()[0]
    assert ner == MANIFEST['corpus']['rows']
    ids = [r[0] for r in con.execute('SELECT doc_id FROM gazetteer_docs ORDER BY doc_id LIMIT 2000').fetchall()]
    docs, mentions = candidate.load_batch(con, ids)
    pattern, source = candidate.reference.patterns()
    start = time.perf_counter()
    serial = candidate.match_batch(pattern, docs, mentions)
    serial_seconds = time.perf_counter()-start
    start = time.perf_counter()
    with concurrent.futures.ThreadPoolExecutor(max_workers=candidate.WORKERS) as pool:
        parallel = candidate.match_batch(pattern, docs, mentions, pool)
    parallel_seconds = time.perf_counter()-start
    committed = con.execute('''SELECT doc_id,person_key,start_char,end_char,ner_overlap FROM forms_gazetteer
      WHERE doc_id IN (SELECT unnest(?))''', [ids]).fetchall()
    identical = sorted(serial) == sorted(committed)
    parallel_identical = sorted(serial) == sorted(parallel)
    result = dict(created_utc=utc(), corpus_sha256=CORPUS_HASH, config_hash=CONFIG_HASH,
      scope='execution parity on already committed v1 corpus rows; not recognition accuracy',
      reference_code_sha256=file_sha(candidate.reference.__file__), parallel_code_sha256=file_sha(candidate.__file__),
      benchmark_code_sha256=file_sha(__file__),
      name_list_sha256=file_sha(source), rows=len(docs), hits=len(serial),
      completed_documents=completed, minimum_pre_handoff_logged_documents=args.minimum_committed,
      complete_ner_documents=ner, serial_seconds=serial_seconds, parallel_seconds=parallel_seconds,
      speedup=serial_seconds/parallel_seconds, workers=candidate.WORKERS,
      identical_to_committed=identical, identical_parallel=parallel_identical,
      result_sha256=hashlib.sha256(json.dumps(sorted(serial), ensure_ascii=False).encode('utf-8')).hexdigest())
    con.execute('CHECKPOINT')
    con.close()
    atomic_json(workdir()/'gazetteer_actual_parity.json', result)
    print(json.dumps(result, ensure_ascii=False), flush=True)
    if not identical or not parallel_identical:
        raise SystemExit('Parity failed: keep original driver and inspect diagnostics')


if __name__ == '__main__':
    main()
