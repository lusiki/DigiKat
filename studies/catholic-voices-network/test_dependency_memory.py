import unittest

import numpy as np
import dependency_memory as memory


class DecoderMemory(unittest.TestCase):
    def tearDown(self):
        memory.restore()

    def compare(self, scores):
        original = scores.copy()
        compact = scores.copy()
        expected = memory.REFERENCE_DECODE(original)
        actual = memory.compact_chuliu_edmonds(compact)
        np.testing.assert_array_equal(actual, expected)
        np.testing.assert_array_equal(compact, original)
        memory.restore()
        expected_root = memory.decoder.chuliu_edmonds_one_root(scores.copy())
        memory.install()
        actual_root = memory.decoder.chuliu_edmonds_one_root(scores.copy())
        np.testing.assert_array_equal(actual_root, expected_root)
        memory.restore()

    def test_random_and_tied_graphs_match_reference(self):
        rng = np.random.default_rng(20261028)
        for size in (2, 3, 10, 31, 80):
            for _ in range(12):
                self.compare(rng.normal(size=(size, size)))
                self.compare(rng.integers(-3, 4, size=(size, size)).astype(float))

    def test_many_disjoint_cycles_match_reference(self):
        for size in (11, 51, 151):
            scores = np.full((size, size), -10.0)
            scores[:, 0] = -5
            for i in range(1, size, 2):
                scores[i, i+1] = scores[i+1, i] = 10
            self.compare(scores)

    def test_reference_guard_and_install_restore(self):
        self.assertEqual(memory.verify_reference(), memory.REFERENCE_SHA256)
        memory.install()
        self.assertIs(memory.decoder.chuliu_edmonds, memory.compact_chuliu_edmonds)
        memory.restore()
        self.assertIs(memory.decoder.chuliu_edmonds, memory.REFERENCE_DECODE)


if __name__ == '__main__':
    unittest.main()
