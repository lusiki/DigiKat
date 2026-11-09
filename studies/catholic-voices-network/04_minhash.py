"""CPU-only, 128-permutation five-word sketches; one signature per exact-text hash."""
import argparse, concurrent.futures, importlib.metadata, re, time
import numpy as np
from datasketch import MinHash
from voices_common import *

def signature(row):
    text_hash,text=row;started=time.perf_counter()
    words=re.findall(r'\w+',text.casefold(),flags=re.UNICODE)
    shingles={' '.join(words[i:i+5]).encode('utf-8') for i in range(max(0,len(words)-4))}
    if not shingles:return text_hash,len(words),0,None,time.perf_counter()-started
    mh=MinHash(num_perm=128,seed=CONFIG['seed'],scheme='affine32',gpu_mode='disable')
    ordered=sorted(shingles)
    for i in range(0,len(ordered),512):mh.update_batch(ordered[i:i+512])
    return text_hash,len(words),len(shingles),mh.hashvalues.astype('<u4').tobytes(),time.perf_counter()-started

def report(con):
    unique=con.execute('SELECT count(*) FROM minhash_queue').fetchone()[0]
    done,short=con.execute('SELECT count(*),count(*) FILTER (WHERE signature IS NULL) FROM minhash_signatures').fetchone()
    covered=con.execute('SELECT count(*) FROM docs JOIN minhash_signatures USING(text_sha256)').fetchone()[0]
    atomic_json(workdir()/'minhash_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,unique_texts=unique,completed_signatures=done,documents_covered=covered,
      texts_shorter_than_five_words=short,complete=done==unique,permutations=128,shingle_words=5,
      note='Null signatures for fewer than five words must never form a shared empty near-duplicate family. Exact text repeats reuse one signature. Near-duplicate family clustering remains a separate step.'))

def main():
    p=argparse.ArgumentParser();p.add_argument('--limit',type=int);p.add_argument('--workers',type=int,default=4);args=p.parse_args()
    con=connect()
    pin_stage(con,'minhash_v1',dict(num_perm=128,seed=CONFIG['seed'],words=5,normalization='casefold unicode word regex',
      scheme='affine32',storage='little-endian uint32',datasketch=importlib.metadata.version('datasketch'),code_sha=file_sha(__file__)))
    con.execute('''CREATE TABLE IF NOT EXISTS minhash_signatures (text_sha256 VARCHAR PRIMARY KEY,
      word_count INTEGER,shingle_count INTEGER,signature BLOB,seconds DOUBLE,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)''')
    with transaction(con):
        con.execute('''CREATE TABLE IF NOT EXISTS minhash_queue AS SELECT text_sha256,min(doc_id) AS doc_id,
          any_value(corpus_sha256) AS corpus_sha256,any_value(config_hash) AS config_hash,
          ? AS created_utc FROM docs GROUP BY text_sha256''',[utc()])
    pending=con.execute('''SELECT q.text_sha256,q.doc_id FROM minhash_queue q LEFT JOIN minhash_signatures s
      USING(text_sha256) WHERE s.text_sha256 IS NULL ORDER BY q.doc_id''').fetchall()
    if args.limit:pending=pending[:args.limit]
    print(f'{utc()} MinHash pending unique texts: {len(pending)}',flush=True)
    with concurrent.futures.ProcessPoolExecutor(max_workers=args.workers) as pool:
        for offset in range(0,len(pending),250):
            batch=pending[offset:offset+250]
            ids=[doc_id for _,doc_id in batch]
            texts=con.execute('''SELECT text_sha256,text_clean FROM docs
              WHERE doc_id>=? AND doc_id<=? AND doc_id IN (SELECT unnest(?))''',[ids[0],ids[-1],ids]).fetchall()
            results=list(pool.map(signature,texts,chunksize=10))
            with transaction(con):
                con.executemany('INSERT INTO minhash_signatures VALUES (?,?,?,?,?,?,?,?)',
                  [(*r,CORPUS_HASH,CONFIG_HASH,utc()) for r in results])
            con.execute('CHECKPOINT')
            if offset%2500==0 or offset+len(batch)==len(pending):
                report(con);print(f'{utc()} MinHash committed {offset+len(batch)}/{len(pending)} pending texts',flush=True)
    report(con);con.close()

if __name__=='__main__':main()
