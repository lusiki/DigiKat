"""Qualify dated-resolution writes without weakening the scientific engine.

Default: constructed data only. --verify-actual requires the real writer and
supervisor to be stopped; acquires runner.lock before reading committed rows.
Actual text stays in memory or temporary ignored fixture DBs, never diagnostics.
"""
import argparse
import contextlib
import hashlib
import io
import json
import tempfile
import time
from pathlib import Path
import duckdb
import pandas as pd
import voices_common as common
from resolution_bulk import BulkConnection, reference, SCHEMAS, MIN_ACTUAL_DOCUMENTS, MIN_SPEEDUP

INPUTS = {
    'docs': [('doc_id','VARCHAR','object'),('text_clean','VARCHAR','object'),('date','VARCHAR','object')],
    'forms': [('form_id','VARCHAR','object'),('surface','VARCHAR','object')],
    'form_mentions': [('doc_id','VARCHAR','object'),('start_char','INTEGER','int32'),('end_char','INTEGER','int32'),('form_id','VARCHAR','object')],
    'aliases': [('threshold','DOUBLE','float64'),('form_id','VARCHAR','object'),('entity_id','VARCHAR','object')],
    'entities': [('threshold','DOUBLE','float64'),('entity_id','VARCHAR','object')],
    'entity_links': [('entity_id','VARCHAR','object'),('qid','VARCHAR','object'),('status','VARCHAR','object'),('facts_json','VARCHAR','object')],
}
OUTPUT_DDL = {
    'resolved_mentions': 'doc_id VARCHAR,start_char INTEGER,end_char INTEGER,surface VARCHAR,entity_id VARCHAR,cluster_entity_id VARCHAR,qid VARCHAR,life_class VARCHAR,origin VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(doc_id,start_char,end_char,origin)',
    'title_mentions': 'doc_id VARCHAR,start_char INTEGER,end_char INTEGER,surface VARCHAR,qid VARCHAR,status VARCHAR,offices_json VARCHAR,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR,PRIMARY KEY(doc_id,start_char,end_char)',
    'resolved_docs': 'doc_id VARCHAR PRIMARY KEY,corpus_sha256 VARCHAR,config_hash VARCHAR,created_utc VARCHAR',
}
ORDER = {'resolved_mentions':'doc_id,start_char,end_char,origin','title_mentions':'doc_id,start_char,end_char','resolved_docs':'doc_id'}


def create_inputs(path, rows):
    con = duckdb.connect(str(path)); con.execute('SET threads=4')
    with common.transaction(con):
        for table,schema in INPUTS.items():
            con.execute(f'CREATE TABLE {table} ({",".join(name+" "+sqltype for name,sqltype,_ in schema)})')
            frame = pd.DataFrame({name:pd.Series([row[i] for row in rows[table]],dtype=dtype)
                                  for i,(name,_,dtype) in enumerate(schema)})
            con.register('_fixture_source',frame)
            try:
                con.execute(f'INSERT INTO {table} SELECT * FROM _fixture_source')
            finally:
                con.unregister('_fixture_source')
    con.execute('CHECKPOINT'); con.close()


def output_rows(con, ids=None):
    where = ' WHERE doc_id IN (SELECT unnest(?))' if ids is not None else ''
    return {table:con.execute(f'SELECT * EXCLUDE(created_utc) FROM {table}{where} ORDER BY {ORDER[table]}',
                             [ids] if ids is not None else []).fetchall() for table in OUTPUT_DDL}


def run_pair(rows, resources, expected=None):
    results = {}; original = (reference.connect,reference.workdir,reference.atomic_json)
    try:
        with tempfile.TemporaryDirectory(prefix='resolution-flow-',dir=common.STUDY/'output/private') as temp:
            for kind in ['reference','bulk']:
                path = Path(temp)/(kind+'.duckdb'); create_inputs(path,rows)
                def connect_fixture():
                    raw=duckdb.connect(str(path)); raw.execute('SET threads=4')
                    return raw if kind=='reference' else BulkConnection(raw)
                captures=[]
                reference.connect=connect_fixture
                reference.workdir=lambda:resources
                reference.atomic_json=lambda destination,payload:captures.append({k:v for k,v in payload.items() if k!='created_utc'})
                start=time.perf_counter()
                with contextlib.redirect_stdout(io.StringIO()):
                    reference.main()
                seconds=time.perf_counter()-start
                con=duckdb.connect(str(path),read_only=True)
                first=output_rows(con)
                settings=con.execute("SELECT settings_hash FROM stage_settings WHERE stage='resolved_mentions_v1'").fetchone()[0]
                con.close()
                with contextlib.redirect_stdout(io.StringIO()):
                    reference.main()
                con=duckdb.connect(str(path),read_only=True)
                assert output_rows(con)==first,'Completed fixture changed on resume'
                con.close()
                assert captures[0]==captures[1],'Completion report changed on unchanged resume'
                if expected is not None:
                    assert first==expected,'Recomputed resolution differs from committed corpus rows'
                results[kind]=dict(rows=first,report=captures[0],seconds=seconds,settings_hash=settings)
        assert results['reference']['rows']==results['bulk']['rows'],'Whole-pipeline output differs'
        assert results['reference']['report']==results['bulk']['report'],'Whole-pipeline report differs'
        assert results['reference']['settings_hash']==results['bulk']['settings_hash'],'Scientific settings differ'
        return dict(full_pipeline_identical=True,unchanged_resume_identical=True,
                    identical_to_committed=expected is not None,documents=len(rows['docs']),
                    output_rows={key:len(value) for key,value in results['reference']['rows'].items()},
                    reference_seconds=results['reference']['seconds'],bulk_seconds=results['bulk']['seconds'],
                    speedup=results['reference']['seconds']/results['bulk']['seconds'],
                    scientific_settings_hash=results['reference']['settings_hash'])
    finally:
        reference.connect,reference.workdir,reference.atomic_json=original


def write_semantics_check():
    stamp='2026-10-27T00:00:00+00:00'; provenance=(common.CORPUS_HASH,common.CONFIG_HASH,stamp)
    rows={
        'resolved_mentions':[('D1',0,8,'Ana Čović','Q1','E1','Q1','contemporary','ner',*provenance),
                             ('D2',4,9,'župnik','E2',None,None,'unresolved','ner',*provenance)],
        'title_mentions':[('D1',10,20,'Sveti Otac','Q6109517','resolved','["Q19546"]',*provenance),
                          ('D2',30,35,'župnik',None,'unresolved','[]',*provenance)],
        'resolved_docs':[('D1',*provenance),('D2',*provenance)],
    }
    for kind in ['reference','bulk']:
        with tempfile.TemporaryDirectory(prefix='resolution-writes-',dir=common.STUDY/'output/private') as temp:
            path=Path(temp)/'fixture.duckdb'; raw=duckdb.connect(str(path))
            con=raw if kind=='reference' else BulkConnection(raw)
            for table,ddl in OUTPUT_DDL.items():con.execute(f'CREATE TABLE {table} ({ddl})')
            with common.transaction(con):
                for table,data in rows.items():con.executemany(f'INSERT INTO {table} VALUES ({",".join("?" for _ in data[0])})',data)
            fresh=list(rows['resolved_mentions'][0]); fresh[0]='Dnew'
            try:
                with common.transaction(con):
                    con.executemany('INSERT INTO resolved_mentions VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',[fresh])
                    con.executemany('INSERT INTO title_mentions VALUES (?,?,?,?,?,?,?,?,?,?)',[rows['title_mentions'][0]])
            except duckdb.ConstraintException:pass
            else:raise AssertionError('Duplicate key unexpectedly accepted')
            for table,expected in rows.items():
                assert con.execute(f'SELECT * FROM {table} ORDER BY {ORDER[table]}').fetchall()==expected,'Cross-table rollback changed rows'
            if kind=='bulk':
                for sql,data in [('INSERT INTO unknown VALUES (?)',[(1,)]),('INSERT INTO resolved_docs VALUES (?,?,?,?)',[('short',)])]:
                    try:con.executemany(sql,data)
                    except ValueError:pass
                    else:raise AssertionError('Unexpected statement/shape accepted')
                con.executemany('INSERT INTO resolved_docs VALUES (?,?,?,?)',[])
            con.execute('CHECKPOINT');con.close()
            con=duckdb.connect(str(path),read_only=True)
            for table,expected in rows.items():
                assert con.execute(f'SELECT * FROM {table} ORDER BY {ORDER[table]}').fetchall()==expected,'Reopened rows differ'
            con.close()
    return dict(exact_values=True,null_and_unicode_preserved=True,cross_table_rollback=True,reopen_verified=True,unexpected_sql_and_shape_rejected=True)


def fixture_check():
    writes=write_semantics_check()
    with tempfile.TemporaryDirectory(prefix='resolution-resources-',dir=common.STUDY/'output/private') as temp:
        resources=Path(temp);cache=resources/'public_register_cache';cache.mkdir()
        people={q:dict(id=q,labels={'hr':dict(value=name)},claims={}) for q,name in
                [('Q450675','Raniji Papa'),('Q6109517','Novi Papa')]}
        people['Q19546']=dict(id='Q19546',labels={'hr':dict(value='papa')})
        common.atomic_json(cache/'fixture.json',dict(retrieved_utc='constructed',response=dict(entities=people)))
        register=dict(offices=[dict(office_qid='Q19546',entity_qid=q,places=[],date_usable=True,
            start_earliest=a,start_latest=a,end_earliest=b,end_latest=b) for q,a,b in
            [('Q450675','2013-03-13','2025-04-21'),('Q6109517','2025-05-08',None)]])
        common.atomic_json(resources/'office_register.json',register)
        names=['Sveti Otac','Ana Izmišljena','Ivan Raniji','Netko Nepoznat','Isus']
        rows=dict(docs=[],form_mentions=[],forms=[(f'F{i}',name) for i,name in enumerate(names)],
                  aliases=[(.9,f'F{i}',f'E{i}') for i in range(5)],entities=[(.9,f'E{i}') for i in range(5)],
                  entity_links=[('E0',None,'unresolved','{}'),
                    ('E1','Qana','linked',json.dumps(dict(qid='Qana',birth=[['1980-01-01','1980-12-31']],death=[]))),
                    ('E2','Qivan','linked',json.dumps(dict(qid='Qivan',birth=[['1900-01-01','1900-12-31']],death=[['1980-01-01','1980-01-01']]))),
                    ('E3',None,'unresolved','{}'),('E4',None,'sacred','{}')])
        for i in range(1200):
            did=f'D{i:05d}'
            text='Sveti Otac spominje: Ana Izmišljena, Ivan Raniji, Netko Nepoznat i Isus.'
            date=['2024-01-01','2026-01-01','2025-04-25',None][i%4]
            rows['docs'].append((did,text,date))
            for j,name in enumerate(names):
                a=text.index(name);rows['form_mentions'].append((did,a,a+len(name),f'F{j}'))
        pipeline=run_pair(rows,resources)
    return dict(passed=True,writes=writes,pipeline=pipeline)


@contextlib.contextmanager
def exclusive_runner():
    import msvcrt
    with (common.workdir()/'runner.lock').open('a+b') as lock:
        if lock.tell()==0:lock.write(b'0');lock.flush()
        lock.seek(0);msvcrt.locking(lock.fileno(),msvcrt.LK_NBLCK,1)
        try:yield
        finally:
            lock.seek(0);msvcrt.locking(lock.fileno(),msvcrt.LK_UNLCK,1)


def actual_check(fixture):
    proof_path=common.workdir()/'resolution_bulk_parity.json'
    if proof_path.exists():
        proof=json.loads(proof_path.read_text(encoding='utf-8'))
        assert proof['passed'] and proof['adapter_sha256']==common.file_sha(common.STUDY/'resolution_bulk.py')
        assert proof['reference_sha256']==common.file_sha(reference.__file__)
        assert proof['verifier_sha256']==common.file_sha(__file__)
        return dict(cached=True,proof_sha256=common.file_sha(proof_path))
    con=common.connect()
    try:
        settings=con.execute("SELECT settings_hash,settings_json FROM stage_settings WHERE stage='resolved_mentions_v1'").fetchone()
        assert settings and json.loads(settings[1])['code']==common.file_sha(reference.__file__)
        ids=[r[0] for r in con.execute('SELECT doc_id FROM resolved_docs ORDER BY doc_id LIMIT ?',[MIN_ACTUAL_DOCUMENTS]).fetchall()]
        assert len(ids)==MIN_ACTUAL_DOCUMENTS
        rows={
            'docs':con.execute('SELECT doc_id,text_clean,date FROM docs WHERE doc_id IN (SELECT unnest(?)) ORDER BY doc_id',[ids]).fetchall(),
            'form_mentions':con.execute('SELECT doc_id,start_char,end_char,form_id FROM form_mentions WHERE doc_id IN (SELECT unnest(?)) ORDER BY doc_id,start_char,end_char',[ids]).fetchall(),
            'forms':con.execute('SELECT DISTINCT f.form_id,f.surface FROM forms f JOIN form_mentions m USING(form_id) WHERE m.doc_id IN (SELECT unnest(?)) ORDER BY f.form_id',[ids]).fetchall(),
            'aliases':con.execute('SELECT DISTINCT a.threshold,a.form_id,a.entity_id FROM aliases a JOIN form_mentions m USING(form_id) WHERE a.threshold=.9 AND m.doc_id IN (SELECT unnest(?)) ORDER BY a.form_id',[ids]).fetchall(),
            'entities':con.execute('SELECT DISTINCT a.threshold,a.entity_id FROM aliases a JOIN form_mentions m USING(form_id) WHERE a.threshold=.9 AND m.doc_id IN (SELECT unnest(?)) ORDER BY a.entity_id',[ids]).fetchall(),
            'entity_links':con.execute('SELECT entity_id,qid,status,facts_json FROM entity_links ORDER BY entity_id').fetchall(),
        }
        expected=output_rows(con,ids)
        committed=con.execute('SELECT count(*) FROM resolved_docs').fetchone()[0]
    finally:con.close()
    actual=run_pair(rows,common.workdir(),expected)
    assert actual['scientific_settings_hash']==settings[0],'Sample changes scientific settings'
    assert actual['speedup']>=MIN_SPEEDUP,'Whole-pipeline speed threshold not met'
    proof=dict(created_utc=common.utc(),passed=True,corpus_sha256=common.CORPUS_HASH,config_hash=common.CONFIG_HASH,
        adapter_sha256=common.file_sha(common.STUDY/'resolution_bulk.py'),reference_sha256=common.file_sha(reference.__file__),
        verifier_sha256=common.file_sha(__file__),scientific_settings_hash=settings[0],
        minimum_actual_documents=MIN_ACTUAL_DOCUMENTS,minimum_speedup=MIN_SPEEDUP,
        actual_documents_verified=len(ids),committed_documents_retained=committed,
        sample_policy='First 2000 committed doc_ids in lexical order; all their input/output rows; no selection by result',
        sample_ids_sha256=hashlib.sha256(json.dumps(ids).encode()).hexdigest(),fixture=fixture,actual=actual,
        caveat='Execution parity and local timing, not identity accuracy. Only nondeterministic created_utc fields excluded from whole-run comparison; direct write checks include timestamps.')
    common.atomic_json(proof_path,proof)
    return proof


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--verify-actual',action='store_true');args=parser.parse_args()
    fixture=fixture_check()
    if args.verify_actual:
        with exclusive_runner():result=actual_check(fixture)
    else:
        result=fixture
        common.atomic_json(common.STUDY/'output/private/resolution_bulk_fixture.json',result)
    print(json.dumps(result,ensure_ascii=False))


if __name__=='__main__':main()
