"""Qualified decoder memory-lifetime repair around the unchanged rule adapter."""
import json

import dependency_memory
from dependency_memory_parallel import MemorySafeDependencyPipeline
import rules_parallel_standard as original
import voices_common as common


def source_hashes():
    return {name: common.file_sha(common.STUDY/name) for name in (
        'dependency_memory.py', 'dependency_memory_parallel.py',
        'rules_memory_safe.py', 'verify_rules_memory_safe.py')}


def validate_proof(proof):
    assert proof['passed'] is True
    assert proof['corpus_sha256'] == common.CORPUS_HASH
    assert proof['config_hash'] == common.CONFIG_HASH
    assert proof['source_hashes'] == source_hashes()
    assert proof['reference_decoder_sha256'] == dependency_memory.verify_reference()
    assert proof['original_parallel_proof_sha256'] == common.file_sha(
        common.workdir()/'rules_parallel_standard_parity.json')
    assert proof['fixed_standard_sentences'] == 2000
    assert proof['largest_completed_standard_sentences'] == 10
    assert proof['fixed_nonstandard_sentences'] == 50
    assert proof['identical_full_results'] and proof['identical_classla_documents']
    assert proof['identical_to_committed'] and proof['large_sentence']['passed']


def main():
    proof_path = common.workdir()/'rules_memory_safe_parity.json'
    proof = json.loads(proof_path.read_text(encoding='utf-8'))
    validate_proof(proof)
    saved_connect = original.reference.connect
    saved_parallel = original.ParallelDependencyPipeline

    def tracked_connect():
        con = saved_connect()
        hashes = source_hashes()
        common.pin_stage(con, 'rules_decoder_memory_v1', dict(
            decoder_sha256=hashes['dependency_memory.py'],
            worker_sha256=hashes['dependency_memory_parallel.py'],
            wrapper_sha256=hashes['rules_memory_safe.py'],
            verifier_sha256=hashes['verify_rules_memory_safe.py'],
            proof_sha256=common.file_sha(proof_path),
            reference_decoder_sha256=dependency_memory.verify_reference(),
            original_parallel_proof_sha256=proof['original_parallel_proof_sha256'],
            scope='Discard unused dense contraction history; identical calculations and expansion order; unchanged corpus/model/rules/transactions'))
        return con

    try:
        dependency_memory.install()
        original.reference.connect = tracked_connect
        original.ParallelDependencyPipeline = MemorySafeDependencyPipeline
        original.main()
    finally:
        original.reference.connect = saved_connect
        original.ParallelDependencyPipeline = saved_parallel
        dependency_memory.restore()


if __name__ == '__main__':
    main()
