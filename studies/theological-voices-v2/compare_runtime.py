"""Compare saved local timings without reading article text into the report author."""
import json
import sqlite3
import statistics
from datetime import datetime, timezone
from pathlib import Path
from prepare import OUT, save_json, file_sha
from coder import get_config_hash


def main():
    old = '8b436ead349d42ef897c6c5a95eaa0ef49fc3480c8c8b394bb99518c40394e2c'
    new = get_config_hash()
    db = sqlite3.connect((OUT / 'coding.sqlite').as_uri() + '?mode=ro', uri=True)
    sets = {}
    identities = []
    for config_hash in [old, new]:
        rows = [json.loads(r[0]) for r in db.execute(
            "SELECT result_json FROM articles WHERE set_name='development' AND config_hash=?", (config_hash,))]
        if len(rows) != 100:
            raise RuntimeError('Both full development sets are required')
        identities.append({r['publication_id']: r['input_hash'] for r in rows})
        seconds = [r.get('elapsed_seconds', 0) for r in rows]
        long = [r for r in rows if r['segments_expected'] > 1]
        sets[config_hash] = {'articles': len(rows), 'total_seconds_including_retries': sum(seconds),
            'median_seconds': statistics.median(seconds), 'structurally_complete': sum(r['status'] == 'complete' for r in rows),
            'segmented_articles': len(long),
            'task_valid_counts': {k: sum(r['task_validity'][k] for r in rows) for k in ['topics', 'mentions', 'speakers', 'groups']},
            'segmented_task_valid_counts': {k: sum(r['task_validity'][k] for r in long) for k in ['topics', 'mentions', 'speakers', 'groups']}}
    assert identities[0] == identities[1], 'Paired runtime comparison needs identical article inputs'
    probe = json.loads((OUT / 'performance_probe_no_thinking' / 'review.json').read_text(encoding='utf-8'))
    baseline_seconds = 0
    for case in probe['checks']:
        responses = [json.loads(r[0]) for r in db.execute(
            "SELECT response_json FROM calls WHERE set_name='diagnostic' AND publication_id=? AND config_hash=?", (case['id'], old))]
        baseline_seconds += sum(r.get('eval_duration', 0) for r in responses) / 1e9
    result = {'created_at': datetime.now(timezone.utc).isoformat(), 'source_sha256': file_sha(Path(__file__)),
        'paired_development': sets,
        'development_runtime_ratio_old_over_new': sets[old]['total_seconds_including_retries'] / sets[new]['total_seconds_including_retries'],
        'synthetic_probe': {'cases': len(probe['checks']), 'old_generation_seconds': baseline_seconds,
                            'new_generation_seconds': sum(c['eval_seconds'] for c in probe['checks'])},
        'note': 'Timing includes retries. Development deliberately oversamples long/short texts; it is not a main-sample runtime forecast. Faster processing does not establish accuracy, and all failed checks remain recorded.'}
    save_json(OUT / 'performance_comparison.json', result)
    print(json.dumps({'paired_articles': 100, 'runtime_ratio': result['development_runtime_ratio_old_over_new']}))
    db.close()


if __name__ == '__main__':
    main()
