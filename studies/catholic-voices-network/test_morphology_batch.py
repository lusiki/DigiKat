import unittest
from unittest.mock import patch
from forms_morph_batch import LookaheadPipeline


class Lookahead(unittest.TestCase):
    def test_order_and_repeated_contexts(self):
        calls=[]
        def analyze(pipeline,texts):
            calls.append(list(texts));return [('document',text) for text in texts]
        texts=['first','repeat','repeat','last']
        with patch('forms_morph_batch.analyze_contexts',analyze):
            pipeline=LookaheadPipeline(object(),iter(texts),batch_size=3)
            self.assertEqual([pipeline(text) for text in texts],[('document',text) for text in texts])
            self.assertEqual(calls,[texts[:3],texts[3:]])
            with self.assertRaisesRegex(RuntimeError,'exhausted'):pipeline('extra')

    def test_context_mismatch_is_rejected(self):
        with patch('forms_morph_batch.analyze_contexts',lambda pipeline,texts:list(texts)):
            pipeline=LookaheadPipeline(object(),['expected'])
            with self.assertRaisesRegex(RuntimeError,'order changed'):pipeline('different')


if __name__=='__main__':unittest.main()
