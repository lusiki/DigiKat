import json,unittest
import coder_protocol_v3 as v3
import coder_protocol_v4 as v4

class EmptyCandidates(unittest.TestCase):
    def test_no_empty_enum_in_request_schema(self):
        bundle=v4.prepare('Nepotpisana rečenica o vjeri.','',[])
        encoded=json.dumps(v4.schema(bundle))
        self.assertNotIn('"enum": []',encoded)
        self.assertFalse(v4.validate('{"s":[]}',bundle)[1])
        self.assertTrue(v4.validate('{"s":[{}]}',bundle)[1])
    def test_nonempty_protocol_is_unchanged(self):
        bundle=v4.prepare('Ana govori.','',[dict(surface='Ana')])
        self.assertEqual(v3.schema(bundle),v4.schema(bundle))
        self.assertEqual(v3.PROMPT,v4.PROMPT)

if __name__=='__main__':unittest.main()
