"""Isolated synthetic performance probe; never changes the active frozen run."""
import json
import time
from datetime import datetime, timezone
from pathlib import Path
import coder
import diagnostics
from prepare import save_json, sha, file_sha


def main():
    parent = coder.get_config_hash()
    production = coder.OUT
    probe = production / 'performance_probe_no_thinking'
    probe.mkdir(exist_ok=True)
    configuration = {**coder.config(), 'think': False,
                     'purpose': 'isolated synthetic runtime probe, not authorized for main coding',
                     'parent_config_hash': parent, 'probe_source_hash': file_sha(Path(__file__))}
    config_hash = sha(json.dumps(configuration, ensure_ascii=False, sort_keys=True))
    save_json(probe / 'configuration.json', {'config_hash': config_hash,
              'configuration': configuration, 'environment': coder.runtime_snapshot()})
    original_api = coder.api

    def probe_api(path, payload=None, timeout=600):
        if path == '/api/chat':
            payload['think'] = False
        return original_api(path, payload, timeout)

    coder.OUT = probe
    coder.api = probe_api
    db = coder.connect()
    selected = {'D031', 'D041', 'D110', 'X03'}
    rows = [r for r in diagnostics.fixtures() if r['publication_id'] in selected]
    save_json(probe / 'synthetic_inputs.json', rows)
    checks = []
    for row in rows:
        pid = row['publication_id']
        old = db.execute('SELECT result_json FROM articles WHERE set_name=? AND publication_id=? AND config_hash=?',
                         ('performance_probe', pid, config_hash)).fetchone()
        started = time.monotonic()
        if old:
            result = json.loads(old[0])
        else:
            result = coder.code_article(db, row, 'performance_probe', config_hash, challenge=True)
            db.execute('INSERT INTO articles VALUES(?,?,?,?,?,?)',
                       ('performance_probe', pid, config_hash, row['input_hash'],
                        json.dumps(result, ensure_ascii=False), datetime.now(timezone.utc).isoformat()))
            db.commit()
        actual = {'voices': len(result['voices']),
                  'has_experience': any(v['own_experience'] == 'yes' for v in result['voices']),
                  'has_interpretation': any(v['interprets_faith'] == 'yes' for v in result['voices']),
                  'has_groups': bool(result['affected_groups']), 'content': result['source_content'],
                  'relevance': result.get('relevance')}
        roles = {v['role'] for v in result['voices']}
        failures = []
        for key, expected in row['expected'].items():
            passed = expected in roles if key == 'role' else expected not in roles if key == 'forbidden_role' else actual[key] == expected
            if not passed:
                failures.append({'field': key, 'expected': expected,
                                 'actual': sorted(roles) if key in {'role', 'forbidden_role'} else actual[key]})
        responses = [json.loads(x[0]) for x in db.execute(
            'SELECT response_json FROM calls WHERE publication_id=? AND config_hash=?', (pid, config_hash))]
        check = {'id': pid, 'structural_status': result['status'], 'failures': failures,
                 'elapsed_seconds_including_queue': result.get('elapsed_seconds'),
                 'eval_seconds': sum(x.get('eval_duration', 0) for x in responses) / 1e9,
                 'prompt_eval_seconds': sum(x.get('prompt_eval_duration', 0) for x in responses) / 1e9,
                 'output_tokens': sum(x.get('eval_count', 0) for x in responses),
                 'thinking_chars': sum(len(x.get('message', {}).get('thinking', '')) for x in responses)}
        checks.append(check)
        save_json(probe / 'review.json', {'config_hash': config_hash, 'parent_config_hash': parent,
                  'checks': checks, 'complete': len(checks) == len(rows),
                  'note': 'Four constructed examples only. Not accuracy evidence or production authorization.'})
        print(json.dumps(check), flush=True)
    db.close()


if __name__ == '__main__':
    main()
