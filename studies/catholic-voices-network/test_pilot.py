import unittest
from types import SimpleNamespace as NS
from importlib import import_module

pilot=import_module('02_pilot_ner')

class PilotTests(unittest.TestCase):
    def test_sample_includes_tiny_strata_without_overallocation(self):
        counts={('a','old'):1,('b','new'):10,('c','old'):10000}
        alloc=pilot.allocation(counts,100)
        self.assertEqual(sum(alloc.values()),100)
        self.assertTrue(all(1<=alloc[k]<=counts[k] for k in counts))

    def test_offsets_keep_inflected_surface(self):
        text='Govore o Ivanu.\n\nAna govori.'
        ent=NS(start_char=9,end_char=14,text='Ivanu',type='PER')
        doc=NS(sentences=[NS(ents=[ent])])
        self.assertEqual(pilot.spans_from_doc(doc,text)[0],(9,14,'Ivanu','PER',0,0))
        ent.text='Ivan'
        with self.assertRaises(ValueError): pilot.spans_from_doc(doc,text)

    def test_duplicate_annotation_is_one_source_mention(self):
        ent=NS(start_char=0,end_char=3,text='Ana',type='PER')
        doc=NS(sentences=[NS(ents=[ent,ent]),NS(ents=[ent])])
        self.assertEqual(len(pilot.spans_from_doc(doc,'Ana govori.')),1)

    def test_multiline_offsets_keep_repeated_names_separate(self):
        import classla
        nlp=classla.Pipeline('hr',processors='tokenize',use_gpu=False,verbose=False)
        text='Ana govori.\n\nAna govori opet.'
        doc=pilot.align_document_offsets(nlp(text),text)
        tokens=[t for s in doc.sentences for t in s.tokens if t.text=='Ana']
        self.assertEqual([t.start_char for t in tokens],[0,13])
        self.assertTrue(all(text[t.start_char:t.end_char]==t.text for s in doc.sentences for t in s.tokens))

if __name__=='__main__': unittest.main()
