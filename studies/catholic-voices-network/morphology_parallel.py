"""Experimental ordered pool of unchanged, single-context CLASSLA calls.

No contexts/sentences are combined. This module never opens the study database.
Production use requires separate full-output GPU parity and timing evidence.
"""
import collections
import concurrent.futures
import multiprocessing
import os
import threading

_pipeline = None


def _watch_parent():
    parent = multiprocessing.parent_process()
    if parent is None:
        return
    delay = threading.Event()
    while not delay.wait(1):
        if not parent.is_alive():
            os._exit(2)


def _initialize(kind, use_gpu, threads):
    global _pipeline
    # If an interrupted parent disappears, do not leave inference workers
    # occupying the GPU after its lock has been released by the OS.
    threading.Thread(target=_watch_parent, daemon=True).start()
    import classla
    import torch
    torch.set_num_threads(threads)
    if use_gpu and not torch.cuda.is_available():
        raise RuntimeError('CUDA required for GPU morphology parity')
    _pipeline = classla.Pipeline('hr', type=kind,
        processors='tokenize,pos,lemma', use_gpu=use_gpu, verbose=False)


def _analyze(text):
    if _pipeline is None:
        raise RuntimeError('Morphology worker was not initialized')
    return _pipeline(text)


class ParallelContextPipeline:
    """Bounded prefetch, original input order, and original document objects."""
    def __init__(self, texts, kind, *, workers=4, use_gpu=True, threads=4,
                 prefetch=None, executor=None):
        if workers < 1:
            raise ValueError('At least one worker is required')
        self.texts = iter(texts)
        self.prefetch = workers * 4 if prefetch is None else prefetch
        if self.prefetch < 1:
            raise ValueError('Prefetch must be positive')
        self.pending = collections.deque()
        self.exhausted = False
        self.closed = False
        self.executor = executor or concurrent.futures.ProcessPoolExecutor(
            max_workers=workers,
            mp_context=multiprocessing.get_context('spawn'),
            initializer=_initialize, initargs=(kind, use_gpu, threads))

    def _fill(self):
        while not self.exhausted and len(self.pending) < self.prefetch:
            try:
                text = next(self.texts)
            except StopIteration:
                self.exhausted = True
                break
            self.pending.append((text, self.executor.submit(_analyze, text)))

    def __call__(self, text):
        if self.closed:
            raise RuntimeError('Morphology context pool is closed or exhausted')
        try:
            self._fill()
            if not self.pending:
                raise RuntimeError('Morphology context pool exhausted before original loop')
            expected, future = self.pending.popleft()
            if text != expected:
                raise RuntimeError('Morphology context order changed; refusing mismatched result')
            document = future.result()
            self._fill()
            if self.exhausted and not self.pending:
                self.close()
            return document
        except BaseException:
            self.close()
            raise

    def close(self):
        if not self.closed:
            self.closed = True
            for _, future in self.pending:
                future.cancel()
            self.pending.clear()
            self.executor.shutdown(wait=True, cancel_futures=True)

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()
