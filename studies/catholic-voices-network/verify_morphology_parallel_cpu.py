"""Constructed CPU-only preflight; no actual DB or GPU access."""
import os
os.environ['CUDA_VISIBLE_DEVICES'] = ''
import gc
import importlib
import json
import time
import classla
import torch
from morphology_batch import fingerprint
from morphology_parallel import ParallelContextPipeline
from voices_common import STUDY, atomic_json, file_sha, utc

ner = importlib.import_module('02_pilot_ner')


def main():
    torch.set_num_threads(2)
    examples = [
        'Biskup Ivan Marić govorio je o pomoći susjedima.',
        'S Anom Šimić razgovarali smo nakon susreta. Ona je odgovorila.',
        '„Ovo je važan razgovor”, rekao je mons. Dražen Kutleša.',
        'Predavanje Josipa Bozanića najavljeno je za sutra.',
        'Petar, Ivan i Marija dolaze u Zagreb; fra Marko ostaje.',
        'PAPA FRANJO: „Budimo blizu jedni drugima!”',
        'Čćžšđ — Ana-Maria i Ivo Horvat, prof. dr. Jurić.',
        'Uvod.\n\nNadbiskup Tomo Vukšić govori.\n\nDrugi odlomak.',
    ]
    texts = [text + f' To je primjer broj {i}.' for i in range(8) for text in examples]
    results = []
    for kind in ['standard', 'nonstandard']:
        print(utc(), kind, 'CPU single-context process-pool preflight', flush=True)
        pipeline = classla.Pipeline('hr', type=kind,
            processors='tokenize,pos,lemma', use_gpu=False, verbose=False)
        started = time.perf_counter()
        expected = [fingerprint(ner.align_document_offsets(pipeline(text), text)) for text in texts]
        serial_seconds = time.perf_counter() - started
        del pipeline
        gc.collect()
        started = time.perf_counter()
        with ParallelContextPipeline(texts, kind, workers=4,
                use_gpu=False, threads=2) as pool:
            actual = [fingerprint(ner.align_document_offsets(pool(text), text)) for text in texts]
        parallel_seconds = time.perf_counter() - started
        identical = actual == expected
        results.append(dict(model_type=kind, contexts=len(texts),
            identical_tokens_tags_lemmas_offsets=identical,
            serial_seconds=serial_seconds,
            parallel_seconds_including_startup=parallel_seconds))
        print(utc(), kind, json.dumps(results[-1]), flush=True)
        if not identical:
            raise RuntimeError('CPU single-context process-pool parity failed')
    result = dict(created_utc=utc(), passed=True, models=results,
        parallel_code_sha256=file_sha(STUDY/'morphology_parallel.py'),
        scope='Constructed CPU preflight only; not GPU/production authorization or accuracy evidence')
    atomic_json(STUDY/'output/private/morphology_parallel_cpu.json', result)
    print(json.dumps(result), flush=True)


if __name__ == '__main__':
    main()
