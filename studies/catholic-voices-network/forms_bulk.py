"""Keep the frozen name-form algorithm; batch its database writes only.

Repeated form upserts are buffered inside the original explicit transaction.
They flush before every other SQL operation, preserving read-your-writes and
rollback. Morphology calls and per-form commits are unchanged.
"""
import importlib
import json
import pandas as pd
import voices_common as common

reference = importlib.import_module('20_forms_v1')
SCHEMAS = {
    'form_mentions': [('doc_id','object'),('start_char','int32'),('end_char','int32'),
        ('form_id','object'),('cue','object'),('gender_hint','object'),
        ('corpus_sha256','object'),('config_hash','object'),('created_utc','object')],
    'forms': [(name,'object') for name in ['form_id','surface','stripped','cue_class',
        'model_type','examples_json','corpus_sha256','config_hash','created_utc']],
    'form_docs': [(name,'object') for name in ['doc_id','corpus_sha256','config_hash','created_utc']],
}
INSERTS = {name:f'INSERT INTO {name} VALUES ({",".join("?" for _ in fields)})' for name,fields in SCHEMAS.items()}
UPSERT = 'INSERT OR REPLACE INTO forms VALUES (?,?,?,?,?,?,?,?,?)'
normalize = lambda sql: ''.join(sql.split()).lower()
REGISTERED = {normalize(sql):name for name,sql in INSERTS.items()}
REGISTERED[normalize(UPSERT)] = 'forms'


class FormsBulkConnection:
    def __init__(self, connection):
        self.connection = connection
        self.pending_forms = []
        self.in_transaction = False

    def __getattr__(self,name):
        return getattr(self.connection,name)

    def _bulk(self,sql,rows):
        name = REGISTERED.get(normalize(sql))
        if name is None:
            raise ValueError('Unregistered form batch statement')
        rows = list(rows)
        if not rows:return
        schema = SCHEMAS[name]
        if any(len(row)!=len(schema) for row in rows):
            raise ValueError('Form batch column count changed')
        table = pd.DataFrame({column:pd.Series([row[index] for row in rows],dtype=dtype)
                              for index,(column,dtype) in enumerate(schema)})
        self.connection.register('_forms_insert_batch',table)
        try:
            prefix = 'INSERT OR REPLACE' if normalize(sql)==normalize(UPSERT) else 'INSERT'
            self.connection.execute(f'{prefix} INTO {name} SELECT * FROM _forms_insert_batch')
        finally:
            self.connection.unregister('_forms_insert_batch')

    def _flush(self):
        if not self.pending_forms:return
        # The frozen algorithm has one row per form key in a batch. Preserve
        # sequential last-write semantics even for an unexpected repeated key.
        if len({row[0] for row in self.pending_forms}) != len(self.pending_forms):
            for row in self.pending_forms:self.connection.execute(UPSERT,row)
        else:
            self._bulk(UPSERT,self.pending_forms)
        self.pending_forms.clear()

    def execute(self,sql,parameters=None):
        normalized = normalize(sql)
        if normalized == normalize(UPSERT):
            if not self.in_transaction:
                raise RuntimeError('Buffered form upsert requires an explicit transaction')
            self.pending_forms.append(tuple(parameters))
            return self
        if normalized == 'rollback':
            self.pending_forms.clear()
        else:
            self._flush()
        result = self.connection.execute(sql) if parameters is None else self.connection.execute(sql,parameters)
        if normalized == 'begin':self.in_transaction = True
        if normalized in {'commit','rollback'}:self.in_transaction = False
        return result

    def executemany(self,sql,rows):
        self._flush()
        self._bulk(sql,rows)
        return self

    def close(self):
        if self.pending_forms:
            raise RuntimeError('Uncommitted buffered form rows at close')
        self.connection.close()


def main():
    path = common.workdir()/'forms_bulk_parity.json'
    proof = json.loads(path.read_text(encoding='utf-8'))
    assert proof['passed'] and proof['actual_documents_verified'] > 0
    assert proof['corpus_sha256']==common.CORPUS_HASH and proof['config_hash']==common.CONFIG_HASH
    assert proof['adapter_sha256']==common.file_sha(__file__)
    assert proof['reference_sha256']==common.file_sha(reference.__file__)
    assert proof['rules_sha256']==common.file_sha(common.STUDY/'name_forms.py')
    def connect_bulk():
        con = common.connect()
        common.pin_stage(con,'forms_bulk_v1',dict(adapter_sha256=common.file_sha(__file__),
          reference_sha256=common.file_sha(reference.__file__),proof_sha256=common.file_sha(path),
          pandas_version=pd.__version__,scope='Same features, contexts, morphology and transactions; typed bulk inserts and transactional form-upsert buffering only'))
        return FormsBulkConnection(con)
    original_connect = reference.connect
    try:
        reference.connect = connect_bulk
        reference.main()
    finally:
        reference.connect = original_connect


if __name__=='__main__':main()
