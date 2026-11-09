"""Verified look-ahead inference batching around the byte-preserved form engine.

The original loop still chooses contexts, extracts lemmas, decides agreement,
and commits each form. This adapter supplies its next context documents in
batches without changing their tokenization or sentence boundaries.
"""
import collections
import itertools
import json
import classla
import forms_bulk
from morphology_batch import analyze_contexts
import voices_common as common

BATCH_SIZE=16


class LookaheadPipeline:
    def __init__(self,pipeline,texts,batch_size=BATCH_SIZE):
        self.pipeline=pipeline
        self.texts=iter(texts)
        self.batch_size=batch_size
        self.ready=collections.deque()

    def __call__(self,text):
        if not self.ready:
            texts=list(itertools.islice(self.texts,self.batch_size))
            if not texts:
                raise RuntimeError('Morphology look-ahead exhausted before original loop')
            documents=analyze_contexts(self.pipeline,texts)
            assert len(documents)==len(texts)
            self.ready.extend(zip(texts,documents))
        expected,document=self.ready.popleft()
        if text!=expected:
            raise RuntimeError('Morphology context order changed; refusing mismatched result')
        return document


def main():
    path=common.workdir()/'forms_morph_batch_parity.json'
    proof=json.loads(path.read_text(encoding='utf-8'))
    assert proof['passed'] and proof['committed_standard_forms_verified']>=500
    assert set(proof['models'])=={'standard','nonstandard'}
    assert all(item['forms']>=500 and item['identical_tokens_tags_lemmas_offsets'] and
               item['identical_form_results'] for item in proof['models'].values())
    assert proof['corpus_sha256']==common.CORPUS_HASH and proof['config_hash']==common.CONFIG_HASH
    assert proof['wrapper_sha256']==common.file_sha(__file__)
    assert proof['batch_code_sha256']==common.file_sha(common.STUDY/'morphology_batch.py')
    assert proof['reference_sha256']==common.file_sha(forms_bulk.reference.__file__)
    assert proof['batch_size']==BATCH_SIZE
    original_connect=common.connect
    original_pipeline=classla.Pipeline
    active_connection=None

    def tracked_connect():
        nonlocal active_connection
        con=original_connect()
        saved=con.execute("SELECT settings_hash FROM stage_settings WHERE stage='forms_v1'").fetchone()
        assert saved and saved[0]==proof['forms_stage_settings_hash']
        common.pin_stage(con,'forms_morph_batch_v1',dict(
          wrapper_sha256=common.file_sha(__file__),batch_code_sha256=proof['batch_code_sha256'],
          reference_sha256=proof['reference_sha256'],proof_sha256=common.file_sha(path),
          context_batch_size=BATCH_SIZE,scope='Separate original tokenization/sentences; batch existing POS/lemma loaders; original per-form decisions and commits'))
        active_connection=con
        return con

    def pipeline_factory(*args,**kwargs):
        if args!=('hr',) or kwargs.get('processors')!='tokenize,pos,lemma' or kwargs.get('use_gpu') is not True:
            raise RuntimeError('Unexpected pipeline configuration in batched form engine')
        kind=kwargs['type']
        rows=active_connection.execute('''SELECT f.form_id,f.examples_json FROM forms f
          ANTI JOIN form_lemmas l USING(form_id) WHERE f.model_type=? ORDER BY f.form_id''',[kind]).fetchall()
        texts=(example['text'] for _,raw in rows for example in json.loads(raw))
        return LookaheadPipeline(original_pipeline(*args,**kwargs),texts)

    try:
        common.connect=tracked_connect
        classla.Pipeline=pipeline_factory
        forms_bulk.main()
    finally:
        common.connect=original_connect
        classla.Pipeline=original_pipeline


if __name__=='__main__':main()
