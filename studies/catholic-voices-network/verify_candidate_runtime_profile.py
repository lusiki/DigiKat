"""Whole-engine equality and unchanged-resume check on constructed CPU inputs."""
import contextlib,hashlib,io,json,shutil,tempfile
from pathlib import Path
import duckdb
import voices_common as common
from candidate_runtime_profile import reference,run_with_timings


def main():
    original=(reference.connect,reference.workdir,reference.MANIFEST,reference.atomic_json)
    results={};timings=[]
    try:
        with tempfile.TemporaryDirectory(dir=common.STUDY/'output/private',prefix='candidate-profile-verify-') as folder:
            base=Path(folder);cache=base/'public_register_cache';cache.mkdir()
            common.atomic_json(cache/'fixture.json',dict(retrieved_utc='constructed',response=dict(entities={
                'Qperson':dict(id='Qperson',labels={'hr':dict(value='Ana Babić')},claims={})})))
            source=base/'inputs.duckdb';con=duckdb.connect(str(source))
            con.execute('CREATE TABLE docs(doc_id VARCHAR,platform VARCHAR,era VARCHAR,text_clean VARCHAR,author VARCHAR,source VARCHAR,date VARCHAR)')
            con.execute('CREATE TABLE resolved_mentions(doc_id VARCHAR,start_char INTEGER,end_char INTEGER,surface VARCHAR,entity_id VARCHAR,life_class VARCHAR)')
            con.execute('CREATE TABLE mentions(doc_id VARCHAR,start_char INTEGER,end_char INTEGER,surface VARCHAR,type VARCHAR)')
            con.execute('CREATE TABLE entity_links(qid VARCHAR,status VARCHAR,facts_json VARCHAR)')
            con.execute('INSERT INTO entity_links VALUES (?,?,?)',['Qperson','linked',json.dumps(dict(qid='Qperson',birth=[],death=[]))])
            cases=[
                ('web','Ana Babić je rekla: "Vjera nas poziva na milosrđe." '+('Objavljeni su detalji susreta. '*20),'','Ana Babić','contemporary',None),
                ('facebook',('Program je počeo ujutro. '*15)+'Molim svakoga jutra. Vjera mi je pomogla u žalovanju.','Ana Babić',None,None,None),
                ('web','Ana Babić govori.','','Ana Babić','contemporary',None),
                ('web','Ivan Raniji je nekada govorio. '+('Povijesni tekst. '*30),'','Ivan Raniji','historical',None),
                ('web','Zajednica mira ima obavijest. '+('Članovi sudjeluju u susretu. '*25)+'\n\nDrugi odlomak ostaje odvojen.','',None,None,'Zajednica mira'),
                ('facebook','Zajednica mira kaže: "'+('Želimo mir i odgovornost, '*65)+'suradnju."','',None,None,'Zajednica mira'),
            ]
            for i in range(60):
                platform,text,author,person,life,org=cases[i%len(cases)];did=f'D{i:04d}'
                con.execute('INSERT INTO docs VALUES (?,?,?,?,?,?,?)',[did,platform,'post2024',text,author,'constructed.test','2026-01-01'])
                if person:
                    a=text.index(person);con.execute('INSERT INTO resolved_mentions VALUES (?,?,?,?,?,?)',[did,a,a+len(person),person,'Qperson',life])
                if org:
                    a=text.index(org);con.execute('INSERT INTO mentions VALUES (?,?,?,?,?)',[did,a,a+len(org),org,'ORG'])
            con.execute('CREATE TABLE resolved_docs AS SELECT doc_id FROM docs');con.execute('CHECKPOINT');con.close()
            reference.workdir=lambda:base;reference.MANIFEST={'corpus':{'rows':60}}
            for kind in ['reference','profile']:
                path=base/(kind+'.duckdb');shutil.copyfile(source,path)
                def connect():
                    c=duckdb.connect(str(path));c.execute('SET threads=4');return c
                reference.connect=connect;reports=[]
                def capture(destination,payload):
                    cleaned={k:v for k,v in payload.items() if k!='created_utc'}
                    cleaned['strata']=sorted(cleaned['strata'],key=lambda r:(r['platform'],r['era']))
                    reports.append(cleaned)
                reference.atomic_json=capture;snapshots=[];pins=[]
                for _ in range(2):
                    with contextlib.redirect_stdout(io.StringIO()):
                        if kind=='reference':reference.main()
                        else:run_with_timings(connect,timings.append)
                    c=connect()
                    snapshots.append({table:c.execute(f'SELECT * EXCLUDE(created_utc) FROM {table} ORDER BY {key}').fetchall()
                        for table,key in [('candidates','item_id'),('candidate_sentences','item_id'),('candidate_docs','doc_id')]})
                    pins.append(c.execute("SELECT settings_hash FROM stage_settings WHERE stage='candidate_windows_v1'").fetchone()[0]);c.close()
                assert snapshots[0]==snapshots[1] and reports[0]==reports[1] and pins[0]==pins[1],'Unchanged resume differs'
                results[kind]=dict(rows=snapshots[0],report=reports[0],pin=pins[0])
            assert results['reference']==results['profile'],'Timing wrapper changed whole-engine outputs'
            assert any(r['closed'] for r in timings)
            assert any(r['cumulative'].get('tokenizer_call',{}).get('calls',0)>0 for r in timings)
            assert any(r['cumulative'].get('sql_commit',{}).get('calls',0)==60 for r in timings)
            assert any(r['cumulative'].get('sql_checkpoint',{}).get('calls',0)==2 for r in timings)
            proof=dict(created_utc=common.utc(),passed=True,constructed=True,documents=60,
              whole_engine_outputs_identical=True,unchanged_resume_identical=True,
              sql_commits_and_checkpoints_preserved=True,model_types=['standard','nonstandard'],
              profile_sha256=common.file_sha(common.STUDY/'candidate_runtime_profile.py'),
              reference_sha256=common.file_sha(reference.__file__),verifier_sha256=common.file_sha(__file__),
              output_rows={k:len(v) for k,v in results['reference']['rows'].items()},
              output_sha256=hashlib.sha256(json.dumps(results['reference']['rows'],ensure_ascii=False,sort_keys=True).encode()).hexdigest(),
              scientific_settings_hash=results['reference']['pin'],
              note='Timing-only wrapper; no performance improvement or empirical accuracy claim. Only creation timestamps and unordered report-stratum ordering excluded from comparison.')
            common.atomic_json(common.STUDY/'output/private/candidate_runtime_profile_fixture.json',proof)
            print(json.dumps(proof))
    finally:reference.connect,reference.workdir,reference.MANIFEST,reference.atomic_json=original


if __name__=='__main__':main()
