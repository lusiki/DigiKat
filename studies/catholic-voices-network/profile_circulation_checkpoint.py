"""Offline, read-only circulation workload/query profile. No text is exported.

Run only with the actual writer and its supervisor stopped. This script does
not change the stage algorithm or write any circulation rows.
"""
import collections
import importlib
import json
import time
from voices_common import *

reference = importlib.import_module('15_circulation_v1')
PENDING_QUERY = '''SELECT c.a,c.b FROM circulation_candidates c LEFT JOIN circulation_pair_checks p
  ON p.a=c.a AND p.b=c.b WHERE p.a IS NULL ORDER BY c.a,c.b LIMIT 1000'''


def main():
    con = connect()
    total = con.execute('SELECT count(*) FROM circulation_candidates').fetchone()[0]
    done = con.execute('SELECT count(*) FROM circulation_pair_checks').fetchone()[0]
    start = time.perf_counter()
    batch = con.execute(PENDING_QUERY).fetchall()
    original_query_seconds = time.perf_counter()-start
    last = con.execute('SELECT a,b FROM circulation_pair_checks ORDER BY a DESC,b DESC LIMIT 1').fetchone()
    holes = con.execute('''SELECT count(*) FROM circulation_candidates c
      WHERE (c.a,c.b)<=(?,?) AND NOT EXISTS
      (SELECT 1 FROM circulation_pair_checks p WHERE p.a=c.a AND p.b=c.b)''',list(last)).fetchone()[0] if last else 0
    start = time.perf_counter()
    seek = con.execute('''SELECT a,b FROM circulation_candidates
      WHERE (a,b)>(?,?) ORDER BY a,b LIMIT 1000''',list(last)).fetchall() if last else batch
    seek_query_seconds = time.perf_counter()-start
    assert holes == 0 and batch == seek
    cache = collections.OrderedDict()
    fetches = 0
    def get(tid):
        nonlocal fetches
        if tid in cache:
            cache.move_to_end(tid)
            return cache[tid]
        text = con.execute('''SELECT d.text_clean FROM circulation_texts t
          JOIN docs d ON d.doc_id=t.doc_id WHERE t.text_id=?''',[tid]).fetchone()[0]
        fetches += 1
        cache[tid] = reference.shingles(text)
        if len(cache)>256:
            cache.popitem(last=False)
        return cache[tid]
    start = time.perf_counter()
    expected = [(a,b,reference.jaccard(get(a),get(b))) for a,b in batch]
    original_compute_seconds = time.perf_counter()-start
    ids = sorted({tid for pair in batch for tid in pair})
    start = time.perf_counter()
    texts = con.execute('''SELECT t.text_id,d.text_clean FROM circulation_texts t
      JOIN docs d ON d.doc_id=t.doc_id WHERE t.text_id IN (SELECT unnest(?))''',[ids]).fetchall()
    sets = {tid:reference.shingles(text) for tid,text in texts}
    alternative = [(a,b,reference.jaccard(sets[a],sets[b])) for a,b in batch]
    prefetch_compute_seconds = time.perf_counter()-start
    assert alternative == expected
    con.close()
    result = dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      code_sha256=file_sha(__file__),candidate_pairs=total,completed_pairs=done,remaining_pairs=total-done,
      batch_rows=len(batch),distinct_texts=len(ids),original_individual_fetches=fetches,
      original_query_seconds=original_query_seconds,seek_query_seconds=seek_query_seconds,
      original_compute_seconds=original_compute_seconds,prefetch_compute_seconds=prefetch_compute_seconds,
      completed_prefix_verified=holes==0,identical_pending_batch=batch==seek,identical_jaccards=alternative==expected,
      caveat='Offline execution profile only; scientific settings and committed comparisons are unchanged.')
    atomic_json(workdir()/'circulation_checkpoint_profile.json',result)
    print(json.dumps(result))


if __name__ == '__main__':main()
