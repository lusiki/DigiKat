"""Fixed 2,000 actual standard sentences: serial/parallel/committed parity.

Run only with the study runner lock held and no other study database connection.
Read-only database access; no text or model output leaves this machine.
Timing includes each pipeline's startup and shutdown. Full tokens, dependency
heads/labels, literal offsets, rule statements and first-person signals compared.
"""
import gc
import hashlib
import json
import time

import classla
import duckdb
import torch
import voices_common as common
import rules_parallel_standard as adapter
from dependency_parallel import ParallelDependencyPipeline


def digest(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True,
                                    separators=(',', ':')).encode()).hexdigest()


def main():
    proof_path = common.workdir()/'rules_parallel_standard_parity.json'
    if proof_path.exists():
        raise RuntimeError('Qualification already recorded; preserve it')
    con = duckdb.connect(str(common.workdir()/'voices.duckdb'), read_only=True)
    try:
        pin = con.execute("SELECT settings_hash,settings_json FROM stage_settings WHERE stage='speech_rules_v1'").fetchone()
        assert pin and json.loads(pin[1])['code'] == common.file_sha(adapter.reference.__file__)
        # Select the first needed standard IDs, independent of parse success.
        # Existing rows must all be complete; do not cherry-pick successful rows.
        rows = con.execute('''WITH sample AS (
            SELECT s.* FROM candidate_sentences s
            WHERE s.needs_parse AND s.platform='web' ORDER BY s.item_id LIMIT ?)
            SELECT s.item_id,s.text,s.start_char,d.text_clean,s.mentions_json,s.author_qid,
                   r.status,r.parsed_json,r.statements_json,r.first_person_signal
            FROM sample s JOIN docs d USING(doc_id)
            LEFT JOIN rule_sentence_results r USING(item_id) ORDER BY s.item_id''',
            [adapter.MIN_SENTENCES]).fetchall()
        assert len(rows) == adapter.MIN_SENTENCES
        assert all(row[6] == 'complete' for row in rows)
    finally:
        con.close()
    proof = dict(created_utc=common.utc(), corpus_sha256=common.CORPUS_HASH,
        config_hash=common.CONFIG_HASH, passed=False, status='starting',
        source_hashes=adapter.source_hashes(), speech_stage_settings_hash=pin[0],
        sentences=len(rows), minimum_sentences=adapter.MIN_SENTENCES,
        sample_sha256=digest([r[0] for r in rows]), selection='First 2000 needed standard item IDs',
        execution_policy=adapter.POLICY, workers=adapter.WORKERS,
        threads_per_worker=adapter.THREADS, prefetch=adapter.PREFETCH,
        minimum_speedup=adapter.MIN_SPEEDUP)
    common.atomic_json(proof_path, proof)
    torch.set_num_threads(adapter.THREADS)
    outputs = {}
    raw_documents = {}
    try:
        with common.gpu_lock():
            common.ensure_ollama_idle()
            for mode in ('serial', 'parallel'):
                started = time.perf_counter()
                if mode == 'serial':
                    pipeline = classla.Pipeline('hr',type='standard',
                        processors='tokenize,pos,lemma,depparse',use_gpu=True,verbose=False)
                else:
                    pipeline = ParallelDependencyPipeline((r[1] for r in rows), 'standard',
                        workers=adapter.WORKERS,threads=adapter.THREADS,prefetch=adapter.PREFETCH)
                results = []
                documents = []
                def recorded_pipeline(text):
                    document = pipeline(text)
                    documents.append(digest(document.to_dict()))
                    return document
                try:
                    for index, row in enumerate(rows, 1):
                        _, text, base, full, raw, author, *_ = row
                        result = adapter.reference.execute_sentence(recorded_pipeline,text,base,full,json.loads(raw),author)
                        results.append(result)
                        if index % 250 == 0:
                            print(common.utc(), mode, index, '/', len(rows), flush=True)
                finally:
                    if mode == 'parallel':
                        pipeline.close()
                    del pipeline
                    gc.collect()
                    torch.cuda.empty_cache()
                outputs[mode] = results
                raw_documents[mode] = documents
                proof[mode+'_seconds'] = time.perf_counter()-started
                proof[mode+'_result_sha256'] = digest(results)
                proof[mode+'_documents_sha256'] = digest(documents)
                proof['status'] = mode+'_complete'
                common.atomic_json(proof_path, proof)
        committed = [(json.loads(r[7]),json.loads(r[8]),r[9]) for r in rows]
        proof['identical_full_results'] = outputs['serial'] == outputs['parallel']
        proof['identical_classla_documents'] = raw_documents['serial'] == raw_documents['parallel']
        proof['identical_to_committed'] = outputs['serial'] == committed
        proof['mismatched_parallel_sentences'] = sum(a != b for a,b in zip(outputs['serial'],outputs['parallel']))
        proof['mismatched_committed_sentences'] = sum(a != b for a,b in zip(outputs['serial'],committed))
        proof['speedup'] = proof['serial_seconds']/proof['parallel_seconds']
        proof['passed'] = (proof['identical_full_results'] and proof['identical_classla_documents'] and proof['identical_to_committed']
                           and proof['speedup'] >= adapter.MIN_SPEEDUP)
        proof['status'] = 'complete'
        proof['finished_utc'] = common.utc()
        common.atomic_json(proof_path, proof)
        print(json.dumps(proof), flush=True)
    except BaseException as exc:
        proof.update(status='failed',error_type=type(exc).__name__,error=str(exc)[:1000])
        common.atomic_json(proof_path, proof)
        raise
    if not proof['passed']:
        raise RuntimeError('Parallel rules qualification failed; retain serial production')


if __name__ == '__main__':
    main()
