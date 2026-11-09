"""Freeze a new, disjoint machine challenge for the performance-only v3.2 revision."""
import json
from datetime import datetime, timezone
from pathlib import Path
import numpy as np
import pandas as pd
from prepare import OUT, file_sha, save_json, proportional

SEED = 2026101801
NAME = 'challenge_v32'


def main():
    target = OUT / (NAME + '_freeze.json')
    if target.exists():
        raise SystemExit('Challenge already frozen; reuse it without overwrite.')
    original = json.loads((OUT / 'freeze.json').read_text(encoding='utf-8'))
    assert file_sha(OUT / 'frame.parquet') == original['files']['frame.parquet']
    excluded = set()
    for name in ['main', 'development', 'challenge']:
        manifest = pd.read_csv(OUT / f'{name}_manifest.csv', encoding='utf-8-sig')
        excluded.update(manifest.publication_id)
    metadata = pd.read_parquet(OUT / 'frame.parquet', columns=['publication_id', 'stratum'])
    eligible = metadata[~metadata.publication_id.isin(excluded)]
    selected, allocation = proportional(eligible, 30, np.random.default_rng(SEED))
    full = pd.read_parquet(OUT / 'frame.parquet', filters=[('publication_id', 'in', selected.publication_id.tolist())])
    extra = [c for c in selected.columns if c not in full.columns or c == 'publication_id']
    sample = full.merge(selected[extra], on='publication_id', validate='one_to_one').sort_values('selection_order')
    assert len(sample) == 30 and sample.publication_id.is_unique
    assert not set(sample.publication_id) & excluded
    names = [NAME + '_inputs.parquet', NAME + '_manifest.csv', NAME + '_allocation.csv']
    sample.to_parquet(OUT / names[0], index=False)
    sample.drop(columns=['body_raw', 'body_clean', 'dedup_key']).to_csv(OUT / names[1], index=False, encoding='utf-8-sig')
    allocation.to_csv(OUT / names[2], index=False, encoding='utf-8-sig')
    save_json(target, {'created_at': datetime.now(timezone.utc).isoformat(), 'seed': SEED,
              'purpose': 'Fresh challenge after performance-only v3.2 change; all original frozen files remain unchanged.',
              'excluded_sets': ['main', 'development', 'challenge'], 'excluded_publications': len(excluded),
              'eligible_publications': len(eligible), 'size': len(sample),
              'original_freeze_sha256': file_sha(OUT / 'freeze.json'),
              'selection_source_sha256': file_sha(Path(__file__)),
              'files': {name: file_sha(OUT / name) for name in names}})
    print(json.dumps({'frozen': str(target), 'size': len(sample), 'excluded': len(excluded)}))


if __name__ == '__main__':
    main()
