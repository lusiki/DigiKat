"""Guard against misleading progress across revisions, stops and stale heartbeats."""
import json
import sqlite3
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest.mock import patch

import progress_server as progress


class ProgressTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.out = Path(self.temp.name)
        self.override = patch.object(progress, 'OUT', self.out)
        self.override.start()
        self.now = datetime.now(timezone.utc)
        self.pipeline = {'stage': 'main_sample_2000', 'state': 'running',
                         'config_hash': 'current', 'updated_at': self.now.isoformat()}
        self.save('pipeline_status.json', self.pipeline)
        self.save('freeze.json', {'publications': 282701, 'main_size': 2000})
        self.save('configs/current.json', {'configuration': {'version': 'test-current'}})
        self.save('inference_status.json', {'config_hash': 'current', 'state': 'running',
                  'set': 'main', 'task': 'extract', 'segment': 1, 'attempt': 1,
                  'started_at': self.now.isoformat()})
        db = sqlite3.connect(self.out / 'coding.sqlite')
        db.executescript('''CREATE TABLE articles(set_name TEXT, config_hash TEXT, result_json TEXT);
          CREATE TABLE calls(config_hash TEXT, set_name TEXT, segment INTEGER, task TEXT,
          attempt INTEGER, status TEXT, seconds REAL, created_at TEXT);''')
        for config, count in [('current', 10), ('obsolete', 80)]:
            for _ in range(count):
                db.execute('INSERT INTO articles VALUES (?,?,?)', ('main', config,
                           json.dumps({'status': 'complete', 'elapsed_seconds': 120})))
            db.execute('INSERT INTO calls VALUES (?,?,?,?,?,?,?,?)',
                       (config, 'main', 0, 'extract', 0, 'valid', 120, self.now.isoformat()))
        db.commit()
        db.close()

    def tearDown(self):
        self.override.stop()
        self.temp.cleanup()

    def save(self, name, value):
        path = self.out / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value), encoding='utf-8')

    def test_revision_does_not_inherit_old_successes(self):
        self.save('diagnostic_review.json', {'config_hash': 'obsolete', 'checks': [
            {'id': 'old', 'case': 'mention_only', 'structural_status': 'complete', 'failures': []}] * 30})
        value = progress.snapshot()
        self.assertEqual(value['main']['done'], 10)
        self.assertEqual(value['diagnostics']['passed'], 0)
        self.assertEqual(value['requests']['requests'], 1)
        self.assertEqual(len(value['history']), 2)
        self.assertEqual(value['eta']['remaining_seconds'], 1990 * 120)

    def test_stale_controller_does_not_claim_current_work(self):
        self.pipeline['updated_at'] = (self.now - timedelta(minutes=3)).isoformat()
        self.save('pipeline_status.json', self.pipeline)
        value = progress.snapshot()
        self.assertTrue(value['stale'])
        self.assertIsNone(value['current_request'])
        self.assertIsNone(value['eta'])
        self.assertEqual(value['main']['done'], 10)
        self.assertEqual(value['stages'][5]['state'], 'stale')

    def test_failed_gate_is_not_a_completed_stage(self):
        self.pipeline.update(stage='stopped', state='needs_attention',
                             failed_stage='synthetic_diagnostics', error='A check failed')
        self.save('pipeline_status.json', self.pipeline)
        checks = [{'id': str(i), 'case': 'mention_only', 'structural_status': 'complete', 'failures': []}
                  for i in range(30)]
        checks[-1]['failures'] = [{'field': 'voices', 'expected': 0, 'actual': 1}]
        self.save('diagnostic_review.json', {'config_hash': 'current', 'checks': checks})
        value = progress.snapshot()
        self.assertEqual(value['diagnostics']['passed'], 29)
        self.assertEqual(value['stages'][2]['state'], 'needs_attention')
        self.assertIsNone(value['current_request'])
        self.assertIsNone(value['eta'])
        self.assertEqual(value['error'], 'A check failed')

    def test_pdf_creation_does_not_imply_visual_review(self):
        report = self.out / 'report'
        report.mkdir()
        (report / 'tko-dobiva-rijec-o-vjeri-v2.pdf').write_bytes(b'test placeholder')
        self.save('report/mechanical_verification.json', {'pages': 24})
        self.pipeline.update(stage='visual_review', state='awaiting_visual_review')
        self.save('pipeline_status.json', self.pipeline)
        value = progress.snapshot()
        self.assertTrue(value['report']['available'])
        self.assertFalse(value['report']['reviewed'])
        self.assertEqual(value['stages'][8]['state'], 'needs_review')


if __name__ == '__main__':
    unittest.main()
