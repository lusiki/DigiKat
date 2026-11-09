"""Constructed CPU benchmark only; no corpus access and no publication gate."""
import concurrent.futures
import hashlib
import importlib
import json
import os
import time
from voices_common import STUDY, atomic_json, file_sha, utc


def main():
    gazetteer = importlib.import_module('11_gazetteer_recall')
    pattern, source = gazetteer.patterns()
    filler = ('U ovoj konstruiranoj objavi opisuje se susret zajednice, razgovor '
              'i svakodnevni rad. Tekst nije preuzet iz korpusa. ')
    probe = ('Papa Franjo govorio je o milosrđu. Papa Lav XIV spominje solidarnost. '
             'Benedikt XVI naveden je u povijesnom pregledu. ')
    texts = [(filler * (5 + i % 70)) + probe + (filler * (i % 13)) for i in range(3000)]

    def match(text):
        return [(m.lastgroup, m.start(), m.end()) for m in pattern.finditer(text)]

    def block(items):
        return [match(text) for text in items]

    # One warmup avoids timing import/compilation as matching work.
    match(texts[0])
    start = time.perf_counter()
    serial = block(texts)
    serial_seconds = time.perf_counter() - start
    workers = min(4, max(1, (os.cpu_count() or 1) - 1))
    start = time.perf_counter()
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        parallel = [item for batch in pool.map(block, [texts[i:i+50] for i in range(0, len(texts), 50)]) for item in batch]
    parallel_seconds = time.perf_counter() - start
    exact = serial == parallel
    result = dict(created_utc=utc(), scope='constructed_cpu_performance_only',
                  corpus_accessed=False, qualifies_publication=False,
                  reference_code_sha256=file_sha(gazetteer.__file__),
                  name_list_sha256=file_sha(source), benchmark_code_sha256=file_sha(__file__),
                  texts=len(texts), characters=sum(map(len, texts)), cpu_count=os.cpu_count(),
                  workers=workers, serial_seconds=serial_seconds, parallel_seconds=parallel_seconds,
                  speedup=serial_seconds/parallel_seconds, identical_matches=exact,
                  matches=sum(map(len, serial)),
                  result_sha256=hashlib.sha256(json.dumps(serial, ensure_ascii=False).encode('utf-8')).hexdigest())
    atomic_json(STUDY/'output/private/gazetteer_thread_benchmark.json', result)
    print(json.dumps(result, ensure_ascii=False), flush=True)
    if not exact:
        raise SystemExit('Threaded matching changed constructed outputs')


if __name__ == '__main__':
    main()
