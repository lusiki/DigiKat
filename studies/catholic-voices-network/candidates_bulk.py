"""Experimental same-transaction writes; production entry is unchanged.

Only candidate INSERTs are buffered, flushing before every other SQL operation.
Sentence executemany uses typed INSERT SELECT. Small batches stay unchanged.
"""
import importlib
import pandas as pd

reference=importlib.import_module('25_prepare_candidates_v1')
MIN_BULK_ROWS=5
SCHEMAS={
    'candidates': [('item_id','object'),('doc_id','object'),('paragraph_id','int32'),
        ('platform','object'),('era','object'),('start_char','int32'),('end_char','int32'),
        ('text','object'),('author','object'),('author_qid','object'),('mentions_json','object'),
        ('sentence_ids_json','object'),('corpus_sha256','object'),('config_hash','object'),('created_utc','object')],
    'candidate_sentences': [('item_id','object'),('doc_id','object'),('sentence_id','int32'),
        ('platform','object'),('start_char','int32'),('end_char','int32'),('text','object'),
        ('mentions_json','object'),('author_qid','object'),('needs_parse','bool'),
        ('corpus_sha256','object'),('config_hash','object'),('created_utc','object')],
}
INSERTS={name:f'INSERT INTO {name} VALUES ({",".join("?" for _ in fields)})' for name,fields in SCHEMAS.items()}
normalize=lambda sql:''.join(sql.split()).lower()
REGISTERED={normalize(sql):name for name,sql in INSERTS.items()}


class CandidatesBulkConnection:
    def __init__(self,connection):
        self.connection=connection
        self.pending=[]
        self.in_transaction=False

    def __getattr__(self,name):return getattr(self.connection,name)

    def _bulk(self,sql,rows):
        name=REGISTERED.get(normalize(sql))
        if name is None:raise ValueError('Unregistered candidate batch statement')
        rows=list(rows)
        if not rows:return
        schema=SCHEMAS[name]
        if any(len(row)!=len(schema) for row in rows):raise ValueError('Candidate batch width changed')
        if len(rows)<MIN_BULK_ROWS:
            self.connection.executemany(sql,rows)
            return
        frame=pd.DataFrame({column:pd.Series([row[i] for row in rows],dtype=dtype)
                            for i,(column,dtype) in enumerate(schema)})
        self.connection.register('_candidate_insert_batch',frame)
        try:self.connection.execute(f'INSERT INTO {name} SELECT * FROM _candidate_insert_batch')
        finally:self.connection.unregister('_candidate_insert_batch')

    def _flush(self):
        if self.pending:
            self._bulk(INSERTS['candidates'],self.pending)
            self.pending.clear()

    def execute(self,sql,parameters=None):
        normalized=normalize(sql)
        if normalized==normalize(INSERTS['candidates']):
            if not self.in_transaction:raise RuntimeError('Buffered candidate insert requires an explicit transaction')
            self.pending.append(tuple(parameters))
            return self
        if normalized=='rollback':self.pending.clear()
        else:self._flush()
        result=self.connection.execute(sql) if parameters is None else self.connection.execute(sql,parameters)
        if normalized=='begin':self.in_transaction=True
        if normalized in {'commit','rollback'}:self.in_transaction=False
        return result

    def executemany(self,sql,rows):
        self._flush()
        self._bulk(sql,rows)
        return self

    def close(self):
        if self.pending:raise RuntimeError('Uncommitted buffered candidate rows at close')
        self.connection.close()
