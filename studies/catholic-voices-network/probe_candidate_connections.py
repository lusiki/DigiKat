"""Constructed long-connection timing probe, never a production authorization."""
import hashlib,json,shutil,tempfile,time
from pathlib import Path
import duckdb
from voices_common import STUDY,atomic_json


def main():
    results=[]
    with tempfile.TemporaryDirectory(dir=STUDY/'output/private',prefix='candidate-connection-probe-') as folder:
        base=Path(folder);source=base/'seed.duckdb'
        c=duckdb.connect(str(source));c.execute('SET threads=4')
        c.execute('CREATE TABLE candidate_docs(doc_id VARCHAR PRIMARY KEY,n_chars INTEGER,windows INTEGER,author_resolved BOOLEAN,exclusion VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)')
        c.execute("INSERT INTO candidate_docs SELECT md5('seed'||i::VARCHAR)||md5('seed'||i::VARCHAR),500,4,false,'','corpus','config','stamp' FROM range(100000) r(i)")
        c.execute('CHECKPOINT');c.close()
        for kind in ['continuous','reopen_5000']:
            path=base/(kind+'.duckdb');shutil.copyfile(source,path)
            c=duckdb.connect(str(path));c.execute('SET threads=4')
            slices=[];started=time.perf_counter();slice_started=started;inserts=0.;commits=0.;checkpoints=0.;reopens=0.
            for i in range(20000):
                c.execute('BEGIN')
                tick=time.perf_counter()
                c.execute('INSERT INTO candidate_docs VALUES (?,?,?,?,?,?,?,?)',
                    [hashlib.sha256(str(i).encode()).hexdigest(),500,4,False,'','corpus','config','stamp'])
                inserts+=time.perf_counter()-tick
                tick=time.perf_counter();c.execute('COMMIT');commits+=time.perf_counter()-tick
                if (i+1)%250==0:
                    tick=time.perf_counter();c.execute('CHECKPOINT');checkpoints+=time.perf_counter()-tick
                if kind=='reopen_5000' and (i+1)%5000==0:
                    tick=time.perf_counter();c.close();c=duckdb.connect(str(path));c.execute('SET threads=4');reopens+=time.perf_counter()-tick
                if (i+1)%2000==0:
                    now=time.perf_counter()
                    slices.append(dict(documents=i+1,seconds=now-slice_started,insert_seconds=inserts,commit_seconds=commits,checkpoint_seconds=checkpoints,reopen_seconds=reopens))
                    print(json.dumps(dict(kind=kind,**slices[-1])),flush=True)
                    slice_started=now;inserts=commits=checkpoints=reopens=0.
            elapsed=time.perf_counter()-started
            assert c.execute('SELECT count(*) FROM candidate_docs').fetchone()[0]==120000
            c.close()
            c=duckdb.connect(str(path),read_only=True)
            digest=c.execute('SELECT sum(hash(doc_id,n_chars,windows,author_resolved,exclusion,corpus_sha256,config_hash,created_utc))::VARCHAR FROM candidate_docs').fetchone()[0]
            c.close();results.append(dict(kind=kind,seconds=elapsed,slices=slices,row_digest=digest))
        assert results[0]['row_digest']==results[1]['row_digest']
    atomic_json(STUDY/'output/private/candidate_connection_probe.json',dict(constructed=True,production_authorized=False,
        scope='Single-table long-connection probe with unchanged per-document transactions; not a whole-engine or corpus benchmark',
        duckdb_version=duckdb.__version__,results=results,speedup=results[0]['seconds']/results[1]['seconds']))


if __name__=='__main__':main()
