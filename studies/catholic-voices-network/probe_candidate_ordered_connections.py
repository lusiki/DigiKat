"""Constructed three-table execution probe; never opens the study database.

This variant uses sequential DK document IDs, matching the exporter key shape.
The earlier connection probe used only document markers. This one includes
window and sentence keys, original per-document transactions and 250-document
checkpoints. Results cannot authorize a production change by themselves.
"""
import hashlib,json,shutil,tempfile,time
from pathlib import Path
import duckdb
from candidates_bulk import SCHEMAS,INSERTS
from voices_common import STUDY,atomic_json,file_sha

SEED_DOCUMENTS=100000
NEW_DOCUMENTS=20000
REOPEN_DOCUMENTS=5000
COUNTS={'candidates':4,'candidate_sentences':10}
DOC_INSERT='INSERT INTO candidate_docs VALUES (?,?,?,?,?,?,?,?)'


def connect(path):
    con=duckdb.connect(str(path));con.execute('SET threads=4');return con


def create_seed(path):
    con=connect(path)
    for table,fields in SCHEMAS.items():
        con.execute('CREATE TABLE '+table+' ('+','.join(name+' '+dict(object='VARCHAR',int32='INTEGER',bool='BOOLEAN')[dtype]
            for name,dtype in fields)+',PRIMARY KEY(item_id))')
        values=[]
        for name,dtype in fields:
            if name=='item_id':value="'DK'||lpad((i+1)::VARCHAR,7,'0')||':'||j::VARCHAR"
            elif name=='doc_id':value="'DK'||lpad((i+1)::VARCHAR,7,'0')"
            elif dtype=='int32':value='j::INTEGER'
            elif dtype=='bool':value='j%2=0'
            elif name=='text':value="repeat('Konstruirana provjera. ',20)"
            elif name=='author_qid':value='NULL'
            else:value="'constructed'"
            values.append(value)
        con.execute('INSERT INTO '+table+' SELECT '+','.join(values)+' FROM range(?) d(i) CROSS JOIN range(?) s(j)',
            [SEED_DOCUMENTS,COUNTS[table]])
    con.execute('CREATE TABLE candidate_docs(doc_id VARCHAR PRIMARY KEY,n_chars INTEGER,windows INTEGER,author_resolved BOOLEAN,exclusion VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR)')
    con.execute("INSERT INTO candidate_docs SELECT 'DK'||lpad((i+1)::VARCHAR,7,'0'),500,4,false,'','corpus','config','stamp' FROM range(?) d(i)",[SEED_DOCUMENTS])
    con.execute('CHECKPOINT');con.close()


def output_rows(table,did):
    rows=[]
    for j in range(COUNTS[table]):
        row=[]
        for name,dtype in SCHEMAS[table]:
            if name=='item_id':value=f'{did}:{j}'
            elif name=='doc_id':value=did
            elif dtype=='int32':value=j
            elif dtype=='bool':value=j%2==0
            elif name=='text':value='Konstruirana provjera. '*20
            elif name=='author_qid':value=None
            else:value='constructed'
            row.append(value)
        rows.append(row)
    return rows


def run_branch(path,reopen):
    con=connect(path);slices=[];categories={}
    started=slice_started=time.perf_counter()
    def timed(key,function,*args):
        tick=time.perf_counter()
        result=function(*args)
        categories[key]=categories.get(key,0.)+time.perf_counter()-tick
        return result
    for i in range(NEW_DOCUMENTS):
        did=f'DK{SEED_DOCUMENTS+i+1:07d}'
        windows=output_rows('candidates',did);sentences=output_rows('candidate_sentences',did)
        con.execute('BEGIN')
        for row in windows:timed('windows',con.execute,INSERTS['candidates'],row)
        timed('sentences',con.executemany,INSERTS['candidate_sentences'],sentences)
        timed('document_insert',con.execute,DOC_INSERT,[did,500,4,False,'','corpus','config','stamp'])
        timed('commit',con.execute,'COMMIT')
        if (i+1)%250==0:timed('checkpoint',con.execute,'CHECKPOINT')
        if reopen and (i+1)%REOPEN_DOCUMENTS==0:
            tick=time.perf_counter();con.close();con=connect(path)
            categories['reopen_seconds']=categories.get('reopen_seconds',0.)+time.perf_counter()-tick
        if (i+1)%2500==0:
            now=time.perf_counter();sample=dict(documents=i+1,seconds=now-slice_started,**categories)
            slices.append(sample);print(json.dumps(dict(reopen=reopen,**sample)),flush=True)
            categories={};slice_started=now
    elapsed=time.perf_counter()-started;con.close();con=duckdb.connect(str(path),read_only=True)
    digests={}
    for table in [*SCHEMAS,'candidate_docs']:
        count=con.execute('SELECT count(*) FROM '+table).fetchone()[0]
        expected=(SEED_DOCUMENTS+NEW_DOCUMENTS)*COUNTS.get(table,1)
        assert count==expected,(table,count,expected)
        fields=[r[0] for r in con.execute('DESCRIBE '+table).fetchall()]
        digests[table]=dict(rows=count,digest=con.execute('SELECT sum(hash('+','.join(fields)+'))::VARCHAR FROM '+table).fetchone()[0])
    con.close()
    return dict(reopen=reopen,seconds=elapsed,slices=slices,row_digests=digests)


def main():
    with tempfile.TemporaryDirectory(dir=STUDY/'output/private',prefix='candidate-three-table-') as folder:
        base=Path(folder);source=base/'seed.duckdb';create_seed(source)
        # Warm parameter conversion before either timed branch.
        warm=duckdb.connect();warm.execute('SELECT ?',[1]).fetchone();warm.close()
        results=[]
        for reopen in [False,True]:
            path=base/('reopen.duckdb' if reopen else 'continuous.duckdb')
            shutil.copyfile(source,path);results.append(run_branch(path,reopen))
            atomic_json(STUDY/'output/private'/(Path(__file__).stem+'-branches.json'),dict(
                constructed=True,production_authorized=False,complete=len(results)==2,
                source_sha256=file_sha(__file__),results=results))
        assert results[0]['row_digests']==results[1]['row_digests']
    atomic_json(STUDY/'output/private/candidate_ordered_connection_probe.json',dict(
        constructed=True,production_authorized=False,seed_documents=SEED_DOCUMENTS,new_documents=NEW_DOCUMENTS,
        reopen_documents=REOPEN_DOCUMENTS,rows_per_document=COUNTS,duckdb_version=duckdb.__version__,
        source_sha256=file_sha(__file__),results=results,speedup=results[0]['seconds']/results[1]['seconds'],
        scope='Sequential DK keys; three-table SQL timing only. Same per-document commits and 250-document checkpoints. No tokenization, actual corpus or whole-engine qualification. Ordered single timing comparison; not an isolated causal proof.'))


if __name__=='__main__':main()
