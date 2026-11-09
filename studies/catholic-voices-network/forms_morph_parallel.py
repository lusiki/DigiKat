"""Separately gated standard-model pool around the unchanged form engine.

The original engine retains context selection, name extraction, ambiguity
decisions and every per-form transaction. No inference batching is introduced.
The nonstandard model retains its original serial execution.
"""
import contextlib
import json
import classla
import forms_bulk
from morphology_parallel import ParallelContextPipeline
import voices_common as common

WORKERS = 4
THREADS = 4
PREFETCH = 16
MIN_SPEEDUP = 1.2
EXECUTION_POLICY = {'standard': 'parallel', 'nonstandard': 'serial'}


def create_context_pipeline(kind, texts, serial_factory):
    if kind not in EXECUTION_POLICY:
        raise ValueError('Unknown morphology model variant')
    if EXECUTION_POLICY[kind] == 'serial':
        return serial_factory()
    return ParallelContextPipeline(texts, kind, workers=WORKERS,
        use_gpu=True, threads=THREADS, prefetch=PREFETCH)


@contextlib.contextmanager
def managed_gpu_lock(original_lock, pools):
    with original_lock():
        try:
            yield
        finally:
            # Close children while the parent still owns the GPU lock, also
            # on --limit, inference failure, or an interrupted Python stack.
            for pool in pools:
                pool.close()


def main():
    proof_path = common.workdir()/'forms_morph_parallel_standard_parity.json'
    proof = json.loads(proof_path.read_text(encoding='utf-8'))
    assert proof['passed'] and proof['committed_standard_forms_verified'] >= 500
    assert set(proof['models']) == {'standard', 'nonstandard'}
    assert all(item['forms'] >= 500 and item['identical_tokens_tags_lemmas_offsets']
               and item['identical_form_results']
               for item in proof['models'].values())
    assert proof['models']['standard']['speedup'] >= MIN_SPEEDUP
    assert proof['execution_policy'] == EXECUTION_POLICY
    assert all(proof['models'][kind]['execution_method'] == mode
               for kind, mode in EXECUTION_POLICY.items())
    assert proof['models']['standard']['identical_to_committed'] is True
    assert proof['corpus_sha256'] == common.CORPUS_HASH
    assert proof['config_hash'] == common.CONFIG_HASH
    assert proof['wrapper_sha256'] == common.file_sha(__file__)
    assert proof['parallel_code_sha256'] == common.file_sha(common.STUDY/'morphology_parallel.py')
    assert proof['reference_sha256'] == common.file_sha(forms_bulk.reference.__file__)
    assert proof['workers'] == WORKERS and proof['threads_per_worker'] == THREADS
    assert proof['prefetch'] == PREFETCH and proof['minimum_speedup'] == MIN_SPEEDUP
    original_connect = common.connect
    original_pipeline = classla.Pipeline
    original_lock = forms_bulk.reference.gpu_lock
    active_connection = None
    pools = []

    def tracked_connect():
        nonlocal active_connection
        con = original_connect()
        saved = con.execute("SELECT settings_hash FROM stage_settings WHERE stage='forms_v1'").fetchone()
        assert saved and saved[0] == proof['forms_stage_settings_hash']
        common.pin_stage(con, 'forms_morph_parallel_standard_v1', dict(
            wrapper_sha256=common.file_sha(__file__),
            parallel_code_sha256=proof['parallel_code_sha256'],
            reference_sha256=proof['reference_sha256'],
            proof_sha256=common.file_sha(proof_path), workers=WORKERS,
            threads_per_worker=THREADS, prefetch=PREFETCH, execution_policy=EXECUTION_POLICY,
            scope='Standard: unchanged separate-context CLASSLA calls in ordered spawned workers; nonstandard: original serial pipeline; original decisions and per-form commits'))
        active_connection = con
        return con

    def pipeline_factory(*args, **kwargs):
        if (args != ('hr',) or kwargs.get('processors') != 'tokenize,pos,lemma'
                or kwargs.get('use_gpu') is not True or kwargs.get('verbose') is not False
                or set(kwargs) != {'type', 'processors', 'use_gpu', 'verbose'}):
            raise RuntimeError('Unexpected pipeline configuration in parallel form engine')
        for pool in pools:
            pool.close()
        kind = kwargs['type']
        serial_factory = lambda: original_pipeline(*args, **kwargs)
        if EXECUTION_POLICY.get(kind) == 'serial':
            return create_context_pipeline(kind, None, serial_factory)
        rows = active_connection.execute('''SELECT f.form_id,f.examples_json FROM forms f
            ANTI JOIN form_lemmas l USING(form_id) WHERE f.model_type=? ORDER BY f.form_id''', [kind]).fetchall()
        texts = (example['text'] for _, raw in rows for example in json.loads(raw))
        pool = create_context_pipeline(kind, texts, serial_factory)
        pools.append(pool)
        return pool

    try:
        common.connect = tracked_connect
        classla.Pipeline = pipeline_factory
        forms_bulk.reference.gpu_lock = lambda: managed_gpu_lock(original_lock, pools)
        forms_bulk.main()
    finally:
        for pool in pools:
            pool.close()
        common.connect = original_connect
        classla.Pipeline = original_pipeline
        forms_bulk.reference.gpu_lock = original_lock


if __name__ == '__main__':
    main()
