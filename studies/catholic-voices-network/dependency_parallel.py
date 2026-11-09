"""Ordered, separate-sentence dependency calls; no study database access.

Production use requires an exact-output and throughput qualification. Reuse the
already qualified bounded queue and parent-death cleanup without changing it.
"""
import concurrent.futures
import multiprocessing
import threading

import morphology_parallel


def _initialize(kind, use_gpu, threads):
    threading.Thread(target=morphology_parallel._watch_parent, daemon=True).start()
    import classla
    import torch
    torch.set_num_threads(threads)
    if use_gpu and not torch.cuda.is_available():
        raise RuntimeError('CUDA required for dependency worker')
    morphology_parallel._pipeline = classla.Pipeline(
        'hr', type=kind, processors='tokenize,pos,lemma,depparse',
        use_gpu=use_gpu, verbose=False)


class ParallelDependencyPipeline(morphology_parallel.ParallelContextPipeline):
    def __init__(self, texts, kind, *, workers=4, use_gpu=True, threads=4,
                 prefetch=16):
        executor = concurrent.futures.ProcessPoolExecutor(
            max_workers=workers, mp_context=multiprocessing.get_context('spawn'),
            initializer=_initialize, initargs=(kind, use_gpu, threads))
        super().__init__(texts, kind, workers=workers, use_gpu=use_gpu,
                         threads=threads, prefetch=prefetch, executor=executor)
