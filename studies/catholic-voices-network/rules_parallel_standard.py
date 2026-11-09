"""Qualified standard-only execution adapter around the preserved rule engine.

Each sentence is parsed independently. Original rule decisions, ordering,
transactions, error history and window materialization stay in the reference.
Nonstandard parsing remains serial. This module cannot qualify itself.
"""
import contextlib
import importlib
import itertools
import json

import classla
import voices_common as common
from dependency_parallel import ParallelDependencyPipeline

reference = importlib.import_module('30_quote_rules_v1')
WORKERS = 4
THREADS = 4
PREFETCH = 16
MIN_SENTENCES = 2000
MIN_SPEEDUP = 1.2
POLICY = {'standard': 'parallel', 'nonstandard': 'serial'}
SMOKES = ('Ivan Horvat je rekao: "Vjera traži odgovornost."',
          'Molim svakoga jutra.')


def pending_texts(con):
    # Reference: lexical batches of 100 IDs, then length and ID within a batch.
    # Fetch once: the original engine uses this same fixed pending set. No
    # cursor can stay live while the original loop executes other SQL.
    rows = con.execute('''WITH pending AS (
        SELECT s.item_id,s.text,row_number() OVER (ORDER BY s.item_id)-1 AS ix
        FROM candidate_sentences s ANTI JOIN rule_sentence_results r USING(item_id)
        WHERE s.needs_parse AND s.platform='web')
        SELECT text FROM pending ORDER BY ix // 100,length(text),item_id''').fetchall()
    return itertools.chain(SMOKES, (row[0] for row in rows))


def create_pipeline(kind, texts, serial_factory):
    if POLICY.get(kind) == 'serial':
        return serial_factory()
    if POLICY.get(kind) != 'parallel':
        raise RuntimeError('Unknown rule model variant')
    return ParallelDependencyPipeline(texts, kind, workers=WORKERS,
                                      threads=THREADS, prefetch=PREFETCH)


@contextlib.contextmanager
def managed_lock(original_lock, pools):
    with original_lock():
        try:
            yield
        finally:
            for pool in pools:
                pool.close()


def source_hashes():
    return {name: common.file_sha(common.STUDY/name) for name in (
        'rules_parallel_standard.py', 'dependency_parallel.py',
        'morphology_parallel.py', '30_quote_rules_v1.py',
        'verify_rules_parallel_standard.py')}


def validate_proof(proof):
    assert proof['passed'] is True
    assert proof['corpus_sha256'] == common.CORPUS_HASH
    assert proof['config_hash'] == common.CONFIG_HASH
    assert proof['source_hashes'] == source_hashes()
    assert proof['sentences'] == MIN_SENTENCES
    assert proof['minimum_sentences'] == MIN_SENTENCES
    assert proof['execution_policy'] == POLICY
    assert proof['workers'] == WORKERS and proof['threads_per_worker'] == THREADS
    assert proof['prefetch'] == PREFETCH and proof['minimum_speedup'] == MIN_SPEEDUP
    assert proof['identical_full_results'] is True
    assert proof['identical_classla_documents'] is True
    assert proof['identical_to_committed'] is True
    assert proof['speedup'] >= MIN_SPEEDUP


def main():
    proof_path = common.workdir()/'rules_parallel_standard_parity.json'
    proof = json.loads(proof_path.read_text(encoding='utf-8'))
    validate_proof(proof)
    original_connect = reference.connect
    original_pipeline = classla.Pipeline
    original_lock = reference.gpu_lock
    active_connection = None
    pools = []

    def tracked_connect():
        nonlocal active_connection
        con = original_connect()
        saved = con.execute("SELECT settings_hash FROM stage_settings WHERE stage='speech_rules_v1'").fetchone()
        assert saved and saved[0] == proof['speech_stage_settings_hash']
        hashes = source_hashes()
        common.pin_stage(con, 'rules_parallel_standard_v1', dict(
            wrapper_sha256=hashes['rules_parallel_standard.py'],
            worker_sha256=hashes['dependency_parallel.py'],
            queue_sha256=hashes['morphology_parallel.py'],
            reference_sha256=hashes['30_quote_rules_v1.py'],
            verifier_sha256=hashes['verify_rules_parallel_standard.py'],
            proof_sha256=common.file_sha(proof_path), workers=WORKERS,
            threads_per_worker=THREADS, prefetch=PREFETCH,
            minimum_sentences=MIN_SENTENCES, minimum_speedup=MIN_SPEEDUP,
            execution_policy=POLICY,
            scope='Separate original standard-sentence calls; ordered results; original per-sentence commits; nonstandard serial'))
        active_connection = con
        return con

    def factory(*args, **kwargs):
        if (args != ('hr',) or set(kwargs) != {'type','processors','use_gpu','verbose'}
                or kwargs['processors'] != 'tokenize,pos,lemma,depparse'
                or kwargs['use_gpu'] is not True or kwargs['verbose'] is not False):
            raise RuntimeError('Unexpected rule pipeline configuration')
        for pool in pools:
            pool.close()
        kind = kwargs['type']
        if POLICY.get(kind) == 'serial':
            return create_pipeline(kind, None, lambda: original_pipeline(*args, **kwargs))
        pool = create_pipeline(kind, pending_texts(active_connection),
                               lambda: original_pipeline(*args, **kwargs))
        pools.append(pool)
        return pool

    try:
        reference.connect = tracked_connect
        classla.Pipeline = factory
        reference.gpu_lock = lambda: managed_lock(original_lock, pools)
        reference.main()
    finally:
        for pool in pools:
            pool.close()
        reference.connect = original_connect
        classla.Pipeline = original_pipeline
        reference.gpu_lock = original_lock


if __name__ == '__main__':
    main()
