"""Offline GPU parity/timing with 500 standard and 5,000 nonstandard forms.

Run only after the actual identity writer and its supervisor are stopped.
Never prints/exports corpus text or predicted words, and never changes form rows.
"""
import gc
import hashlib
import json
import time
import classla
import torch
import forms_bulk
from forms_morph_parallel_long import (WORKERS, THREADS, PREFETCH, MIN_SPEEDUP,
    EXECUTION_POLICY, MIN_FORMS, create_context_pipeline)
from verify_forms_morph_batch_gpu import run_sample
import voices_common as common


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True,
        ensure_ascii=False).encode('utf-8')).hexdigest()


def main():
    output = common.workdir()/'forms_morph_parallel_long_parity.json'
    cpu_path = common.STUDY/'output/private/morphology_parallel_cpu.json'
    cpu = json.loads(cpu_path.read_text(encoding='utf-8'))
    assert cpu['passed'] and cpu['parallel_code_sha256'] == common.file_sha(common.STUDY/'morphology_parallel.py')
    assert len(cpu['models']) == 2 and all(row['identical_tokens_tags_lemmas_offsets'] for row in cpu['models'])
    con = common.connect()
    pinned = con.execute("SELECT settings_json FROM stage_settings WHERE stage='forms_morph_parallel_long_v1'").fetchone()
    if pinned:
        assert common.file_sha(output) == json.loads(pinned[0])['proof_sha256']
        con.close()
        print(json.dumps(dict(cached=True, proof_sha256=common.file_sha(output))))
        return
    settings_hash, settings_json = con.execute(
        "SELECT settings_hash,settings_json FROM stage_settings WHERE stage='forms_v1'").fetchone()
    assert json.loads(settings_json)['code'] == common.file_sha(forms_bulk.reference.__file__)
    samples = {
        'standard': con.execute('''SELECT f.form_id,f.stripped,f.examples_json FROM forms f
            JOIN form_lemmas l USING(form_id) WHERE f.model_type='standard' ORDER BY f.form_id LIMIT 500''').fetchall(),
        'nonstandard': con.execute('''SELECT f.form_id,f.stripped,f.examples_json FROM forms f
            WHERE f.model_type='nonstandard' ORDER BY f.form_id LIMIT 5000''').fetchall(),
    }
    assert all(len(rows) == MIN_FORMS[kind] for kind, rows in samples.items())
    stored = {key: (name, status, json.loads(details)) for key, name, status, details in con.execute(
        'SELECT form_id,nominative,status,details_json FROM form_lemmas WHERE form_id IN (SELECT unnest(?))',
        [[row[0] for row in samples['standard']]]).fetchall()}
    assert len(stored) == 500
    completed = con.execute('SELECT count(*) FROM form_lemmas').fetchone()[0]
    prepared = con.execute('SELECT count(*) FROM form_docs').fetchone()[0]
    assert prepared == common.MANIFEST['corpus']['rows']
    con.close()
    torch.set_num_threads(THREADS)
    assert torch.cuda.is_available()
    results = {}
    with common.gpu_lock():
        common.ensure_ollama_idle()
        for kind, rows in samples.items():
            print(common.utc(), kind, 'GPU serial baseline:', len(rows), 'actual forms', flush=True)
            pipeline = classla.Pipeline('hr', type=kind,
                processors='tokenize,pos,lemma', use_gpu=True, verbose=False)
            torch.cuda.synchronize()
            started = time.perf_counter()
            original, original_fingerprints = run_sample(pipeline, rows)
            torch.cuda.synchronize()
            serial_seconds = time.perf_counter() - started
            matches_stored = original == stored if kind == 'standard' else None
            if kind == 'standard':
                assert matches_stored, 'Serial baseline differs from committed forms'
            del pipeline
            gc.collect()
            torch.cuda.empty_cache()
            print(common.utc(), kind, 'testing production route:', EXECUTION_POLICY[kind], flush=True)
            texts = (example['text'] for _, _, raw in rows for example in json.loads(raw))
            started = time.perf_counter()
            candidate = create_context_pipeline(kind, texts,
                lambda: classla.Pipeline('hr', type=kind, processors='tokenize,pos,lemma',
                    use_gpu=True, verbose=False))
            try:
                parallel, parallel_fingerprints = run_sample(candidate, rows)
                torch.cuda.synchronize()
            finally:
                if EXECUTION_POLICY[kind] == 'parallel':
                    candidate.close()
                del candidate
                gc.collect()
                torch.cuda.empty_cache()
            parallel_seconds = time.perf_counter() - started
            result = dict(forms=len(rows), contexts=len(original_fingerprints),
                serial_seconds=serial_seconds,
                candidate_seconds_including_startup_and_shutdown=parallel_seconds,
                execution_method=EXECUTION_POLICY[kind],
                speedup=serial_seconds/parallel_seconds,
                identical_tokens_tags_lemmas_offsets=original_fingerprints == parallel_fingerprints,
                identical_form_results=original == parallel,
                identical_to_committed=matches_stored,
                serial_output_sha256=digest(original), candidate_output_sha256=digest(parallel),
                serial_fingerprint_sha256=digest(original_fingerprints),
                candidate_fingerprint_sha256=digest(parallel_fingerprints))
            results[kind] = result
            print(common.utc(), kind, json.dumps(result), flush=True)
            if not (result['identical_tokens_tags_lemmas_offsets'] and result['identical_form_results']):
                common.atomic_json(common.workdir()/'forms_morph_parallel_long_failure.json',
                    dict(created_utc=common.utc(), passed=False, reason='full-output parity', models=results))
                raise RuntimeError('Single-context process-pool GPU parity failed; do not switch production')
    if any(row['speedup'] < MIN_SPEEDUP for row in results.values()):
        common.atomic_json(common.workdir()/'forms_morph_parallel_long_failure.json',
            dict(created_utc=common.utc(), passed=False, reason='insufficient measured speedup', models=results))
        raise RuntimeError('Insufficient GPU speedup; retain the current execution')
    proof = dict(created_utc=common.utc(), passed=True,
        corpus_sha256=common.CORPUS_HASH, config_hash=common.CONFIG_HASH,
        wrapper_sha256=common.file_sha(common.STUDY/'forms_morph_parallel_long.py'),
        parallel_code_sha256=common.file_sha(common.STUDY/'morphology_parallel.py'),
        reference_sha256=common.file_sha(forms_bulk.reference.__file__),
        verifier_sha256=common.file_sha(__file__),
        sample_runner_sha256=common.file_sha(common.STUDY/'verify_forms_morph_batch_gpu.py'),
        cpu_proof_sha256=common.file_sha(cpu_path), forms_stage_settings_hash=settings_hash,
        workers=WORKERS, threads_per_worker=THREADS, prefetch=PREFETCH,
        minimum_speedup=MIN_SPEEDUP, minimum_forms=MIN_FORMS,
        execution_policy=EXECUTION_POLICY, models=results,
        sample_selection="First ordered form IDs; 500 committed standard and first 5000 nonstandard, including the earlier first 500. No form rows modified.",
        timing_protocol="Serial excludes pipeline startup; candidate includes startup and shutdown. Speedup must be at least 1.2 in both models.",
        committed_standard_forms_verified=500, committed_form_lemmas=completed,
        prepared_documents=prepared, torch_version=torch.__version__,
        gpu=torch.cuda.get_device_name(),
        caveat='Sampled exact execution parity and local timing; not identity accuracy or a guarantee for untested contexts. Original per-form commits remain unchanged.')
    common.atomic_json(output, proof)
    print('Both production routes passed full-output parity and speed gates. No form result was modified.', flush=True)


if __name__ == '__main__':
    main()
