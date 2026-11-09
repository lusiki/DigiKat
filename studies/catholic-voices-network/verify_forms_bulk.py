"""Exact preparation/resume/transaction parity; actual mode requires idle DB.

Actual text is used only in in-memory fixtures and is never printed/exported.
"""
import argparse
import json
import tempfile
import time
from pathlib import Path
import duckdb
from forms_bulk import FormsBulkConnection, reference, INSERTS, UPSERT
import voices_common as common


def initialize(con):
    con.execute('CREATE TABLE docs(doc_id VARCHAR,text_clean VARCHAR,platform VARCHAR)')
    con.execute('CREATE TABLE mentions(doc_id VARCHAR,start_char INTEGER,end_char INTEGER,type VARCHAR)')
    reference.prepare(con)


def snapshot(con):
    return {table:con.execute(f'SELECT * EXCLUDE(created_utc) FROM {table} ORDER BY ALL').fetchall()
            for table in ['forms','form_mentions','form_docs']}


def transaction_checks(con):
    before = snapshot(con)
    form = list(con.execute('SELECT * FROM forms ORDER BY form_id LIMIT 1').fetchone())
    # A read between buffered upserts must observe the newest value; duplicate
    # keys must retain sequential last-write semantics, and rollback restores it.
    try:
        with common.transaction(con):
            first=list(form); first[1]='Prva provjera čćžšđ'
            second=list(form); second[1]='Druga provjera čćžšđ'
            con.execute(UPSERT,first);con.execute(UPSERT,second)
            assert con.execute('SELECT surface FROM forms WHERE form_id=?',[form[0]]).fetchone()[0]==second[1]
            raise RuntimeError('intentional fixture rollback')
    except RuntimeError as error:
        assert str(error)=='intentional fixture rollback'
    assert snapshot(con)==before
    existing=list(con.execute('SELECT * FROM form_mentions ORDER BY doc_id,start_char LIMIT 1').fetchone())
    fresh=list(existing);fresh[0]='never_committed'
    try:
        with common.transaction(con):
            changed=list(form);changed[1]='Must roll back'
            con.execute(UPSERT,changed)
            con.executemany(INSERTS['form_mentions'],[fresh,existing])
    except duckdb.ConstraintException:
        pass
    else:
        raise AssertionError('Duplicate mention unexpectedly accepted')
    assert snapshot(con)==before


def fixture_check():
    root=common.STUDY/'output/private';root.mkdir(parents=True,exist_ok=True)
    datasets=[]
    for start,end in [(0,800),(800,1600)]:
        docs=[];mentions=[]
        for i in range(start,end):
            name=f'Ivan Primjer{i%400}'
            text=f'Biskup {name} govori o događaju {i}.\n\nAna Šimić odgovara u kontekstu {i}.'
            did=f'{i:06d}'
            docs.append((did,text,'web' if i%2==0 else 'facebook'))
            for surface in [name,'Ana Šimić']:
                a=text.index(surface);mentions.append((did,a,a+len(surface),'PER'))
        datasets.append((docs,mentions))
    timings={};results={}
    with tempfile.TemporaryDirectory(prefix='forms-bulk-',dir=root) as temp:
        for kind in ['reference','bulk']:
            path=Path(temp)/(kind+'.duckdb')
            raw=duckdb.connect(str(path));raw.execute('SET threads=4');initialize(raw)
            con=raw if kind=='reference' else FormsBulkConnection(raw)
            elapsed=0
            for docs,mentions in datasets:
                raw.executemany('INSERT INTO docs VALUES (?,?,?)',docs)
                raw.executemany('INSERT INTO mentions VALUES (?,?,?,?)',mentions)
                started=time.perf_counter();reference.prepare(con);elapsed+=time.perf_counter()-started
            saved=snapshot(con);reference.prepare(con);assert snapshot(con)==saved
            assert len(saved['form_docs'])==1600 and len(saved['form_mentions'])==3200
            assert all(len(json.loads(row[5]))==3 for row in saved['forms'])
            transaction_checks(con)
            con.close()
            reopened=duckdb.connect(str(path),read_only=True)
            assert snapshot(reopened)==saved;reopened.close()
            timings[kind+'_seconds']=elapsed;results[kind]=saved
    assert results['reference']==results['bulk']
    return dict(passed=True,documents=1600,mentions=3200,forms=len(results['bulk']['forms']),
      exact_tables=True,context_limit_preserved=True,resume_identical=True,read_your_writes=True,
      duplicate_upsert_order=True,rollback_verified=True,reopen_verified=True,**timings)


def actual_check(fixture):
    path=common.workdir()/'forms_bulk_parity.json'
    con=common.connect()
    pinned=con.execute("SELECT settings_json FROM stage_settings WHERE stage='forms_bulk_v1'").fetchone()
    if pinned:
        assert common.file_sha(path)==json.loads(pinned[0])['proof_sha256']
        con.close();return dict(cached=True,proof_sha256=common.file_sha(path))
    settings=json.loads(con.execute("SELECT settings_json FROM stage_settings WHERE stage='forms_v1'").fetchone()[0])
    assert settings['code']==common.file_sha(reference.__file__)
    ids=[row[0] for row in con.execute('SELECT doc_id FROM form_docs ORDER BY doc_id LIMIT 500').fetchall()]
    assert len(ids)==500
    docs=con.execute('SELECT doc_id,text_clean,platform FROM docs WHERE doc_id IN (SELECT unnest(?)) ORDER BY doc_id',[ids]).fetchall()
    mentions=con.execute("SELECT doc_id,start_char,end_char,type FROM mentions WHERE type='PER' AND doc_id IN (SELECT unnest(?)) ORDER BY doc_id,start_char",[ids]).fetchall()
    actual_mentions=con.execute('SELECT * EXCLUDE(created_utc) FROM form_mentions WHERE doc_id IN (SELECT unnest(?)) ORDER BY ALL',[ids]).fetchall()
    keys=sorted({row[3] for row in actual_mentions})
    forms=con.execute('SELECT * FROM forms WHERE form_id IN (SELECT unnest(?)) ORDER BY form_id',[keys]).fetchall()
    committed_docs=con.execute('SELECT count(*) FROM form_docs').fetchone()[0]
    committed_mentions=con.execute('SELECT count(*) FROM form_mentions').fetchone()[0]
    con.close()
    results={};timings={}
    for kind in ['reference','bulk']:
        raw=duckdb.connect(':memory:');raw.execute('SET threads=4');initialize(raw)
        raw.executemany('INSERT INTO docs VALUES (?,?,?)',docs)
        raw.executemany('INSERT INTO mentions VALUES (?,?,?,?)',mentions)
        raw.executemany(INSERTS['forms'],forms)
        adapter=raw if kind=='reference' else FormsBulkConnection(raw)
        started=time.perf_counter();reference.prepare(adapter);timings[kind+'_seconds']=time.perf_counter()-started
        saved=snapshot(adapter)
        assert saved['form_mentions']==actual_mentions
        assert saved['forms']==[row[:-1] for row in forms]
        reference.prepare(adapter);assert snapshot(adapter)==saved
        results[kind]=saved;adapter.close()
    assert results['reference']==results['bulk']
    result=dict(created_utc=common.utc(),passed=True,corpus_sha256=common.CORPUS_HASH,
      config_hash=common.CONFIG_HASH,adapter_sha256=common.file_sha(common.STUDY/'forms_bulk.py'),
      reference_sha256=common.file_sha(reference.__file__),rules_sha256=common.file_sha(common.STUDY/'name_forms.py'),
      verifier_sha256=common.file_sha(__file__),fixture=fixture,actual_documents_verified=len(ids),
      actual_mentions_verified=len(actual_mentions),actual_forms_verified=len(forms),
      committed_docs=committed_docs,committed_mentions=committed_mentions,
      identical_to_committed=True,identical_bulk=True,actual_timings=timings,
      caveat='Execution/storage parity only; no name-recognition, nominative or identity accuracy claim.')
    common.atomic_json(path,result)
    return result


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--verify-actual',action='store_true');args=parser.parse_args()
    fixture=fixture_check()
    result=actual_check(fixture) if args.verify_actual else fixture
    if not args.verify_actual:common.atomic_json(common.STUDY/'output/private/forms_bulk_fixture.json',result)
    print(json.dumps(result,ensure_ascii=False))


if __name__=='__main__':main()
