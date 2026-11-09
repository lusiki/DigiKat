import json,tempfile,unittest
from pathlib import Path
from voices_common import atomic_json_stable,file_sha

class Stable(unittest.TestCase):
    def test_resume_does_not_invalidate_downstream_source_hash(self):
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'selection.json'
            atomic_json_stable(path,dict(created_utc='original',primary='model',n=2000))
            first=file_sha(path)
            atomic_json_stable(path,dict(created_utc='later',primary='model',n=2000))
            self.assertEqual(file_sha(path),first)
            atomic_json_stable(path,dict(created_utc='changed',primary='another',n=2000))
            self.assertNotEqual(file_sha(path),first)
            self.assertEqual(json.loads(path.read_text())['created_utc'],'changed')

if __name__=='__main__':unittest.main()
