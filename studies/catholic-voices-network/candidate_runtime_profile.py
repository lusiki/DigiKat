"""Timing-only execution around the byte-preserved passage engine.

Every SQL command, tokenizer call, window calculation and transaction is passed
through unchanged. Diagnostics contain aggregate timings, never corpus text.
"""
import collections,importlib,json,time
import voices_common as common

reference=importlib.import_module('25_prepare_candidates_v1')


class Timings:
    def __init__(self,callback):
        self.callback=callback;self.started=time.perf_counter()
        self.seconds=collections.defaultdict(float);self.calls=collections.Counter()
        self.previous_seconds={};self.previous_calls={};self.previous_time=self.started

    def call(self,key,function,*args,**kwargs):
        started=time.perf_counter()
        try:return function(*args,**kwargs)
        finally:
            self.seconds[key]+=time.perf_counter()-started;self.calls[key]+=1

    def emit(self,closed=False):
        now=time.perf_counter()
        interval=dict(seconds=now-self.previous_time,
          categories={k:dict(seconds=v-self.previous_seconds.get(k,0),calls=self.calls[k]-self.previous_calls.get(k,0))
                      for k,v in self.seconds.items()})
        result=dict(created_utc=common.utc(),closed=closed,elapsed_seconds=now-self.started,
          cumulative={k:dict(seconds=v,calls=self.calls[k]) for k,v in self.seconds.items()},interval=interval)
        self.callback(result)
        self.previous_time=now;self.previous_seconds=dict(self.seconds);self.previous_calls=dict(self.calls)


def sql_category(sql):
    normalized=' '.join(sql.lower().split())
    if normalized=='checkpoint':return 'sql_checkpoint'
    if normalized in {'begin','commit','rollback'}:return 'sql_'+normalized
    for table in ['candidates','candidate_sentences','candidate_docs']:
        if normalized.startswith('insert into '+table+' '):return 'sql_insert_'+table
    if normalized.startswith('select'):return 'sql_read'
    return 'sql_other'


class TimedConnection:
    def __init__(self,connection,timings):self.connection=connection;self.timings=timings
    def __getattr__(self,name):return getattr(self.connection,name)
    def execute(self,sql,parameters=None):
        arguments=(sql,) if parameters is None else (sql,parameters)
        result=self.timings.call(sql_category(sql),self.connection.execute,*arguments)
        if sql_category(sql)=='sql_checkpoint':self.timings.emit()
        return result
    def executemany(self,sql,parameters):
        return self.timings.call(sql_category(sql),self.connection.executemany,sql,parameters)
    def close(self):
        result=self.timings.call('sql_close',self.connection.close)
        self.timings.emit(closed=True)
        return result


def run_with_timings(connect,callback):
    import classla
    timings=Timings(callback)
    original_connect=reference.connect;original_pipeline=classla.Pipeline
    original_windows=reference.create_windows
    class TimedPipeline:
        def __init__(self,*args,**kwargs):
            self.pipeline=timings.call('tokenizer_initialize',original_pipeline,*args,**kwargs)
        def __call__(self,*args,**kwargs):
            return timings.call('tokenizer_call',self.pipeline,*args,**kwargs)
        def __getattr__(self,name):return getattr(self.pipeline,name)
    try:
        reference.connect=lambda:TimedConnection(connect(),timings)
        classla.Pipeline=TimedPipeline
        reference.create_windows=lambda *args,**kwargs:timings.call('create_windows',original_windows,*args,**kwargs)
        reference.main()
    finally:
        reference.connect=original_connect;classla.Pipeline=original_pipeline;reference.create_windows=original_windows


def main():
    proof_path=common.STUDY/'output/private/candidate_runtime_profile_fixture.json'
    proof=json.loads(proof_path.read_text(encoding='utf-8'))
    assert proof['passed'] and proof['profile_sha256']==common.file_sha(__file__)
    assert proof['reference_sha256']==common.file_sha(reference.__file__)
    assert proof['verifier_sha256']==common.file_sha(common.STUDY/'verify_candidate_runtime_profile.py')
    baseline={}
    def connect():
        con=common.connect()
        saved=con.execute("SELECT settings_json FROM stage_settings WHERE stage='candidate_windows_v1'").fetchone()
        assert saved and json.loads(saved[0])['code']==common.file_sha(reference.__file__)
        baseline.update(dict(con.execute('''SELECT d.platform,count(*) FROM candidate_docs c JOIN docs d USING(doc_id) GROUP BY d.platform''').fetchall()))
        common.pin_stage(con,'candidate_runtime_profile_v1',dict(code=common.file_sha(__file__),
          reference=common.file_sha(reference.__file__),proof=common.file_sha(proof_path),
          scope='Aggregate timing only; unchanged SQL, tokenizer, windows, commits and checkpoints'))
        return con
    def callback(result):
        common.atomic_json(common.workdir()/'candidate_runtime_profile.json',dict(**result,
          corpus_sha256=common.CORPUS_HASH,config_hash=common.CONFIG_HASH,baseline_documents_by_platform=baseline,
          profile_sha256=common.file_sha(__file__),reference_sha256=common.file_sha(reference.__file__),
          caveat='Elapsed timings only. No identity/attribution accuracy claim. Unclassified elapsed time includes other Python work.'))
    run_with_timings(connect,callback)


if __name__=='__main__':main()
