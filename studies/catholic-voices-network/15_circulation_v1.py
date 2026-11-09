"""MinHash candidate retrieval, exact shingle verification, circulation components.

16 bands x 8 hashes. Exact five-word Jaccard >= .85 defines an edge; components
are circulation families, not claims of authorship. Empty sketches never match.
Candidate retrieval is approximate. All exact-text duplicates share a family.
"""
import collections,hashlib,json,re,struct
from voices_common import *

def shingles(text):
    words=re.findall(r'\w+',text.casefold(),flags=re.UNICODE)
    return {' '.join(words[i:i+5]) for i in range(max(0,len(words)-4))}

def jaccard(a,b):return len(a&b)/len(a|b) if a or b else None

def components(ids,edges):
    parent={i:i for i in ids}
    def root(x):
        while parent[x]!=x:parent[x]=parent[parent[x]];x=parent[x]
        return x
    for a,b in edges:
        ra,rb=root(a),root(b)
        if ra!=rb:parent[max(ra,rb)]=min(ra,rb)
    return {i:root(i) for i in ids}

def main():
    con=connect()
    assert con.execute('SELECT count(*) FROM minhash_queue').fetchone()==con.execute('SELECT count(*) FROM minhash_signatures').fetchone()
    pin_stage(con,'circulation_v1',dict(code=file_sha(__file__),bands=16,rows_per_band=8,
      exact_jaccard=.85,sensitivity=[.8,.9],family='connected components; exact text duplicates always share a node'))
    con.execute('''CREATE TABLE IF NOT EXISTS circulation_texts AS
      SELECT CAST(row_number() OVER (ORDER BY s.text_sha256) AS INTEGER) AS text_id,s.text_sha256,
        q.doc_id,s.shingle_count,s.signature,s.corpus_sha256,s.config_hash,? AS created_utc
      FROM minhash_signatures s JOIN minhash_queue q USING(text_sha256)''',[utc()])
    con.execute('''CREATE TABLE IF NOT EXISTS circulation_bands
      (text_id INTEGER,band INTEGER,band_hash UBIGINT,shingle_count INTEGER,
       corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(text_id,band))''')
    pending=con.execute('''SELECT t.text_id,t.signature,t.shingle_count FROM circulation_texts t
      WHERE t.signature IS NOT NULL AND NOT EXISTS (SELECT 1 FROM circulation_bands b WHERE b.text_id=t.text_id)
      ORDER BY t.text_id''').fetchall()
    for offset in range(0,len(pending),5000):
        rows=[]
        for tid,sig,n in pending[offset:offset+5000]:
            assert len(sig)==512
            for band in range(16):
                h=struct.unpack('<Q',hashlib.blake2b(sig[band*32:(band+1)*32],digest_size=8).digest())[0]
                rows.append((tid,band,h,n,CORPUS_HASH,CONFIG_HASH,utc()))
        with transaction(con):con.executemany('INSERT INTO circulation_bands VALUES (?,?,?,?,?,?,?)',rows)
        con.execute('CHECKPOINT')
        print(utc(),'circulation bands',offset+len(pending[offset:offset+5000]),'/',len(pending),flush=True)
    # .8 count-ratio bound also supports sensitivity at .8. No hard candidate cap/drop.
    con.execute('''CREATE TABLE IF NOT EXISTS circulation_candidates AS SELECT DISTINCT
      a.text_id AS a,b.text_id AS b,? AS corpus_sha256,? AS config_hash,? AS created_utc
      FROM circulation_bands a JOIN circulation_bands b ON a.band=b.band AND a.band_hash=b.band_hash
      AND a.text_id<b.text_id AND least(a.shingle_count,b.shingle_count)>=.8*greatest(a.shingle_count,b.shingle_count)''',
      [CORPUS_HASH,CONFIG_HASH,utc()])
    con.execute('''CREATE TABLE IF NOT EXISTS circulation_pair_checks (a INTEGER,b INTEGER,jaccard DOUBLE,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(a,b))''')
    con.execute('CHECKPOINT')
    cache=collections.OrderedDict()
    def get(tid):
        if tid in cache:cache.move_to_end(tid);return cache[tid]
        text=con.execute('SELECT d.text_clean FROM circulation_texts t JOIN docs d ON d.doc_id=t.doc_id WHERE t.text_id=?',[tid]).fetchone()[0]
        cache[tid]=shingles(text)
        if len(cache)>256:cache.popitem(last=False)
        return cache[tid]
    done=con.execute('SELECT count(*) FROM circulation_pair_checks').fetchone()[0]
    while True:
        batch=con.execute('''SELECT c.a,c.b FROM circulation_candidates c LEFT JOIN circulation_pair_checks p
          ON p.a=c.a AND p.b=c.b WHERE p.a IS NULL ORDER BY c.a,c.b LIMIT 1000''').fetchall()
        if not batch:break
        results=[(a,b,jaccard(get(a),get(b)),CORPUS_HASH,CONFIG_HASH,utc()) for a,b in batch]
        with transaction(con):con.executemany('INSERT INTO circulation_pair_checks VALUES (?,?,?,?,?,?)',results)
        done+=len(results);con.execute('CHECKPOINT')
        if done%5000==0:print(utc(),'circulation exact pairs saved',done,flush=True)
    ids=[r[0] for r in con.execute('SELECT text_id FROM circulation_texts').fetchall()]
    con.execute('''CREATE TABLE IF NOT EXISTS circulation_membership (threshold DOUBLE,text_id INTEGER,family_id INTEGER,
      corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(threshold,text_id))''')
    summary=[]
    for threshold in [.8,.85,.9]:
        mapping=components(ids,con.execute('SELECT a,b FROM circulation_pair_checks WHERE jaccard>=?',[threshold]).fetchall())
        with transaction(con):
            con.execute('DELETE FROM circulation_membership WHERE threshold=?',[threshold])
            con.executemany('INSERT INTO circulation_membership VALUES (?,?,?,?,?,?)',
              [(threshold,i,f,CORPUS_HASH,CONFIG_HASH,utc()) for i,f in mapping.items()])
        counts=collections.Counter(mapping.values())
        summary.append(dict(threshold=threshold,families=len(counts),families_with_multiple_unique_texts=sum(n>1 for n in counts.values()),
                            max_unique_texts_in_family=max(counts.values())))
    con.execute('CHECKPOINT')
    atomic_json(workdir()/'circulation_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,candidate_pairs=done,thresholds=summary,
      caveat='Approximate LSH retrieval; verified edges use exact five-word Jaccard. Components permit indirect chains. Earliest captured text does not establish original authorship.'))
    con.close()

if __name__=='__main__':main()
