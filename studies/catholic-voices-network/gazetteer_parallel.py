"""Same frozen gazetteer algorithm; parallel pure matching, one DB writer.

The byte-preserved v1 owns the scientific pattern/setting pin. This execution
version adds a separate immutable pin and reuses committed v1 rows only after
checking the completed-corpus parity benchmark.
"""
import concurrent.futures
import importlib
import json
from voices_common import *

reference = importlib.import_module('11_gazetteer_recall_v1')
WORKERS = 4


def match_document(pattern, row, mentions):
    did, text, date = row
    hits = []
    for match in pattern.finditer(text):
        if match.lastgroup == 'lav14' and date < '2025-05-08':
            continue
        overlap = any(a < match.end() and b > match.start() for a, b in mentions)
        hits.append((did, match.lastgroup, match.start(), match.end(), overlap))
    return hits


def load_batch(con, ids):
    docs = con.execute('''SELECT doc_id,text_clean,date FROM docs
      WHERE doc_id>=? AND doc_id<=? AND doc_id IN (SELECT unnest(?))''',
      [ids[0], ids[-1], ids]).fetchall()
    mentions = {did: [] for did in ids}
    for did, a, b in con.execute('''SELECT doc_id,start_char,end_char FROM mentions
      WHERE type='PER' AND doc_id>=? AND doc_id<=?''', [ids[0], ids[-1]]).fetchall():
        if did in mentions:
            mentions[did].append((a, b))
    return docs, mentions


def match_batch(pattern, docs, mentions, pool=None):
    job = lambda row: match_document(pattern, row, mentions[row[0]])
    results = map(job, docs) if pool is None else pool.map(job, docs)
    return [hit for rows in results for hit in rows]


def main():
    con = connect()
    pattern, source = reference.patterns()
    assert con.execute("SELECT count(*) FROM ner_docs WHERE status='complete'").fetchone()[0] == MANIFEST['corpus']['rows']
    pin_stage(con, 'gazetteer_v1', dict(source_sha=file_sha(source), code_sha=file_sha(reference.__file__),
      overlap='at least one shared source character with a PER span',
      title_only='excluded from named-span proxy; handled by dated office layer'))
    benchmark = json.loads((workdir()/'gazetteer_actual_parity.json').read_text(encoding='utf-8'))
    assert benchmark['identical_to_committed'] and benchmark['identical_parallel']
    assert benchmark['rows'] > 0 and benchmark['corpus_sha256'] == CORPUS_HASH
    assert benchmark['config_hash'] == CONFIG_HASH
    assert benchmark['parallel_code_sha256'] == file_sha(__file__)
    assert benchmark['reference_code_sha256'] == file_sha(reference.__file__)
    assert benchmark['name_list_sha256'] == file_sha(source)
    pin_stage(con, 'gazetteer_parallel_v1', dict(code_sha=file_sha(__file__), reference_sha=file_sha(reference.__file__),
      workers=WORKERS, concurrency='pure immutable-string matching only; single main-thread DB writer',
      parity_sha=file_sha(workdir()/'gazetteer_actual_parity.json')))
    con.execute('''CREATE TABLE IF NOT EXISTS forms_gazetteer (doc_id VARCHAR,person_key VARCHAR,
      start_char INTEGER,end_char INTEGER,ner_overlap BOOLEAN,corpus_sha256 VARCHAR,config_hash VARCHAR,
      created_utc VARCHAR,PRIMARY KEY(doc_id,person_key,start_char,end_char))''')
    con.execute('''CREATE TABLE IF NOT EXISTS gazetteer_docs (doc_id VARCHAR PRIMARY KEY,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    ids = [r[0] for r in con.execute('''SELECT d.doc_id FROM docs d LEFT JOIN gazetteer_docs g USING(doc_id)
      WHERE g.doc_id IS NULL ORDER BY d.doc_id''').fetchall()]
    initial = con.execute('SELECT count(*) FROM gazetteer_docs').fetchone()[0]
    with concurrent.futures.ThreadPoolExecutor(max_workers=WORKERS) as pool:
        for offset in range(0, len(ids), 500):
            batch = ids[offset:offset+500]
            docs, mentions = load_batch(con, batch)
            hits = match_batch(pattern, docs, mentions, pool)
            with transaction(con):
                if hits:
                    con.executemany('INSERT INTO forms_gazetteer VALUES (?,?,?,?,?,?,?,?)',
                      [(*hit, CORPUS_HASH, CONFIG_HASH, utc()) for hit in hits])
                con.executemany('INSERT INTO gazetteer_docs VALUES (?,?,?,?)',
                  [(did, CORPUS_HASH, CONFIG_HASH, utc()) for did in batch])
            con.execute('CHECKPOINT')
            if offset % 5000 == 0:
                print(f'{utc()} gazetteer saved {initial+offset+len(batch)}/{MANIFEST["corpus"]["rows"]} documents; matching threads={WORKERS}', flush=True)
    rows = con.execute('''SELECT d.platform,count(*),sum(CASE WHEN g.ner_overlap THEN 1 ELSE 0 END)
      FROM forms_gazetteer g JOIN docs d USING(doc_id) GROUP BY d.platform ORDER BY d.platform''').fetchall()
    atomic_json_stable(workdir()/'gazetteer_report.json', dict(created_utc=utc(), corpus_sha256=CORPUS_HASH, config_hash=CONFIG_HASH,
      check='M-REC-1', scope='known names, full-body text, overlap proxy; not measured recall',
      platforms=[dict(platform=p,gazetteer_hits=n,ner_overlap=k,share=k/n,lower_bound_label=k/n<.9) for p,n,k in rows]))
    con.close()


if __name__ == '__main__':
    main()
