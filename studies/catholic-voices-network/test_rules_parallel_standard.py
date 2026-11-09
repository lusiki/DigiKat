import contextlib
import unittest
from unittest.mock import Mock, patch

import duckdb
import rules_parallel_standard as adapter


class RuleExecution(unittest.TestCase):
    def test_pending_order_matches_original_batches_and_excludes_saved_attempts(self):
        con = duckdb.connect()
        con.execute('CREATE TABLE candidate_sentences(item_id VARCHAR,text VARCHAR,needs_parse BOOLEAN,platform VARCHAR)')
        con.execute('CREATE TABLE rule_sentence_results(item_id VARCHAR,status VARCHAR)')
        rows = [(f's{i:04d}', 'x'*(1+(211-i)%19)+str(i), i != 21,
                 'web' if i != 22 else 'forum') for i in range(211)]
        con.executemany('INSERT INTO candidate_sentences VALUES (?,?,?,?)', rows)
        con.executemany('INSERT INTO rule_sentence_results VALUES (?,?)',
                        [('s0005','complete'),('s0102','failed')])
        ids = [r[0] for r in con.execute('''SELECT s.item_id FROM candidate_sentences s
            ANTI JOIN rule_sentence_results r USING(item_id)
            WHERE s.needs_parse AND s.platform='web' ORDER BY s.item_id''').fetchall()]
        expected = list(adapter.SMOKES)
        for offset in range(0,len(ids),100):
            expected.extend(r[0] for r in con.execute('''SELECT text FROM candidate_sentences
                WHERE item_id IN (SELECT unnest(?)) ORDER BY length(text),item_id''',
                [ids[offset:offset+100]]).fetchall())
        self.assertEqual(list(adapter.pending_texts(con)), expected)
        con.close()

    def test_cleanup_precedes_lock_release_on_early_exit(self):
        events = []
        @contextlib.contextmanager
        def lock():
            events.append('acquire')
            try:
                yield
            finally:
                events.append('release')
        pool = Mock()
        pool.close.side_effect = lambda: events.append('close')
        with self.assertRaisesRegex(RuntimeError, 'early exit'):
            with adapter.managed_lock(lock,[pool]):
                raise RuntimeError('early exit')
        self.assertEqual(events,['acquire','close','release'])

    def test_nonstandard_remains_serial_and_standard_uses_fixed_configuration(self):
        serial = Mock(return_value=object())
        with patch.object(adapter,'ParallelDependencyPipeline') as parallel:
            self.assertIs(adapter.create_pipeline('nonstandard',None,serial),serial.return_value)
            parallel.assert_not_called()
            texts = iter(['one','two'])
            self.assertIs(adapter.create_pipeline('standard',texts,serial),parallel.return_value)
            parallel.assert_called_once_with(texts,'standard',workers=4,threads=4,prefetch=16)
            serial.assert_called_once_with()
        with self.assertRaisesRegex(RuntimeError,'Unknown'):
            adapter.create_pipeline('unexpected',None,serial)


if __name__ == '__main__':
    unittest.main()
