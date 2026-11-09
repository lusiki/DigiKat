"""Constructed checkpoint-cost probe only; never opens the actual study DB."""
import json,tempfile,time
from pathlib import Path
import duckdb
from candidates_bulk import SCHEMAS
from voices_common import STUDY,atomic_json


def main():
    results=[]
    for initial in [5000,100000]:
        with tempfile.TemporaryDirectory(dir=STUDY/'output/private',prefix='candidate-checkpoint-probe-') as folder:
            path=Path(folder)/'fixture.duckdb'
            con=duckdb.connect(str(path));con.execute('SET threads=4')
            for table,fields in SCHEMAS.items():
                con.execute('CREATE TABLE '+table+' ('+','.join(c+' '+dict(object='VARCHAR',int32='INTEGER',bool='BOOLEAN')[t] for c,t in fields)+',PRIMARY KEY(item_id))')
            con.execute('CREATE TABLE candidate_docs(doc_id VARCHAR PRIMARY KEY,n_chars INTEGER,windows INTEGER,author_resolved BOOLEAN,exclusion VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)')
            def append(a,b):
                con.execute('BEGIN')
                for table,fields in SCHEMAS.items():
                    per=4 if table=='candidates' else 20
                    expr=[]
                    for name,dtype in fields:
                        if name=='item_id':value="'D'||i::VARCHAR||':'||j::VARCHAR"
                        elif name=='doc_id':value="'D'||i::VARCHAR"
                        elif dtype=='int32':value='j::INTEGER'
                        elif dtype=='bool':value='j%2=0'
                        elif name=='text':value="repeat('Konstruirana provjera. ',20)"
                        elif name=='author_qid':value='NULL'
                        else:value="'constructed'"
                        expr.append(value)
                    con.execute('INSERT INTO '+table+' SELECT '+','.join(expr)+' FROM range(?,?) d(i) CROSS JOIN range(?) s(j)',[a,b,per])
                con.execute("INSERT INTO candidate_docs SELECT 'D'||i::VARCHAR,500,4,false,'','corpus','config','stamp' FROM range(?,?) d(i)",[a,b])
                con.execute('COMMIT')
            started=time.perf_counter();append(0,initial);con.execute('CHECKPOINT');build=time.perf_counter()-started
            checks=[]
            for batch in range(8):
                started=time.perf_counter();append(initial+batch*250,initial+(batch+1)*250);write=time.perf_counter()-started
                started=time.perf_counter();con.execute('CHECKPOINT');cp=time.perf_counter()-started
                checks.append(dict(write_seconds=write,checkpoint_seconds=cp))
            result=dict(initial_documents=initial,initial_sentences=20*initial,build_seconds=build,database_bytes=path.stat().st_size,batches=checks)
            results.append(result);print(json.dumps(result),flush=True)
            con.close()
    atomic_json(STUDY/'output/private/candidate_checkpoint_probe.json',dict(constructed=True,production_authorized=False,
        scope='Checkpoint overhead only; vectorized fixture construction is not a whole-pipeline benchmark',results=results,duckdb_version=duckdb.__version__))


if __name__=='__main__':main()
