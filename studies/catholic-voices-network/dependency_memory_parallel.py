"""Original worker initialization and queue, with a qualified decoder stack."""
import concurrent.futures
import multiprocessing

from dependency_parallel import _initialize
from morphology_parallel import ParallelContextPipeline


def _initialize_memory(kind, use_gpu, threads):
    _initialize(kind, use_gpu, threads)
    from dependency_memory import install
    install()


class MemorySafeDependencyPipeline(ParallelContextPipeline):
    def __init__(self, texts, kind, *, workers=4, use_gpu=True, threads=4, prefetch=16):
        executor = concurrent.futures.ProcessPoolExecutor(
            max_workers=workers, mp_context=multiprocessing.get_context('spawn'),
            initializer=_initialize_memory, initargs=(kind, use_gpu, threads))
        super().__init__(texts, kind, workers=workers, use_gpu=use_gpu,
                         threads=threads, prefetch=prefetch, executor=executor)
