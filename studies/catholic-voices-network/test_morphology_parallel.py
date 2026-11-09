import concurrent.futures
import contextlib
import unittest
from unittest.mock import Mock, patch
from morphology_parallel import ParallelContextPipeline


class Executor:
    def __init__(self, fail=None):
        self.calls = []
        self.closed = False
        self.fail = fail

    def submit(self, function, text):
        self.calls.append(text)
        future = concurrent.futures.Future()
        if text == self.fail:
            future.set_exception(RuntimeError('inference failed'))
        else:
            future.set_result(('document', text))
        return future

    def shutdown(self, **kwargs):
        self.closed = True


class OrderedPool(unittest.TestCase):
    def test_repeats_order_bounded_prefetch_and_cleanup(self):
        executor = Executor()
        texts = ['a', 'repeat', 'repeat', 'b', 'c', 'd']
        pool = ParallelContextPipeline(iter(texts), 'standard',
            executor=executor, prefetch=2)
        self.assertEqual(pool('a'), ('document', 'a'))
        self.assertEqual(executor.calls, texts[:3])
        self.assertEqual([pool(text) for text in texts[1:]],
                         [('document', text) for text in texts[1:]])
        self.assertTrue(executor.closed)
        self.assertTrue(pool.closed)
        with self.assertRaisesRegex(RuntimeError, 'exhausted'):
            pool('extra')

    def test_mismatch_closes_pool_instead_of_misassigning_result(self):
        executor = Executor()
        pool = ParallelContextPipeline(['expected'], 'standard', executor=executor)
        with self.assertRaisesRegex(RuntimeError, 'order changed'):
            pool('different')
        self.assertTrue(executor.closed)

    def test_failure_is_not_returned_as_an_empty_document(self):
        executor = Executor(fail='bad')
        pool = ParallelContextPipeline(['bad', 'unused'], 'standard', executor=executor)
        with self.assertRaisesRegex(RuntimeError, 'inference failed'):
            pool('bad')
        self.assertTrue(executor.closed)

    def test_early_exit_closes_pool(self):
        executor = Executor()
        with ParallelContextPipeline(['a', 'b'], 'standard', executor=executor) as pool:
            self.assertEqual(pool('a'), ('document', 'a'))
        self.assertTrue(executor.closed)

    def test_workers_close_before_gpu_lock_release_on_failure(self):
        from forms_morph_parallel import managed_gpu_lock
        events = []
        @contextlib.contextmanager
        def lock():
            events.append('acquire')
            try:
                yield
            finally:
                events.append('release')
        class Pool:
            def close(self):
                events.append('close workers')
        with self.assertRaisesRegex(RuntimeError, 'test failure'):
            with managed_gpu_lock(lock, [Pool()]):
                raise RuntimeError('test failure')
        self.assertEqual(events, ['acquire', 'close workers', 'release'])

    def test_nonstandard_route_uses_original_serial_factory(self):
        from forms_morph_parallel import create_context_pipeline
        expected = object()
        serial = Mock(return_value=expected)
        with patch('forms_morph_parallel.ParallelContextPipeline',
                   side_effect=AssertionError('Nonstandard must not create a pool')):
            self.assertIs(create_context_pipeline('nonstandard', None, serial), expected)
        serial.assert_called_once_with()

    def test_standard_route_uses_verified_pool_configuration(self):
        from forms_morph_parallel import create_context_pipeline
        texts = iter(['context'])
        serial = Mock(side_effect=AssertionError('Standard must use the qualified pool'))
        with patch('forms_morph_parallel.ParallelContextPipeline') as pool:
            self.assertIs(create_context_pipeline('standard', texts, serial), pool.return_value)
            pool.assert_called_once_with(texts, 'standard', workers=4,
                use_gpu=True, threads=4, prefetch=16)


if __name__ == '__main__':
    unittest.main()
