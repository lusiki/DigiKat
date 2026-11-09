"""Preserve the exact source behind a coding configuration without overwriting it."""
import json
from datetime import datetime, timezone
from pathlib import Path

from prepare import STUDY, OUT, file_sha, save_json
from coder import config, get_config_hash


def archive():
    configuration=config();chash=get_config_hash()
    fields={'coder.py':'runner_hash','prepare.py':'prepare_hash','diagnostics.py':'diagnostics_hash',
            'CODEBOOK.md':'codebook_hash','assignment.json':'assignment_hash',
            'prepare_fresh_challenge.py':'challenge_selection_source_hash'}
    target=OUT/'configs'/chash/'source';target.mkdir(parents=True,exist_ok=True)
    files={}
    for name,key in fields.items():
        source=STUDY/name;expected=configuration[key]
        if file_sha(source)!=expected:raise RuntimeError('Source changed while archiving '+name)
        destination=target/name
        if destination.exists():
            if file_sha(destination)!=expected:raise RuntimeError('Refusing to overwrite archived source '+name)
        else:destination.write_bytes(source.read_bytes())
        if file_sha(destination)!=expected:raise RuntimeError('Archived source does not match '+name)
        files[name]=expected
    manifest=target.parent/'source_manifest.json'
    if not manifest.exists():
        save_json(manifest,{'config_hash':chash,'created_at':datetime.now(timezone.utc).isoformat(),'files':files,
                           'note':'Exact coding inputs; analysis and report builders are recorded separately.'})
    return {'config_hash':chash,'source_directory':str(target),'files':len(files)}


if __name__=='__main__':print(json.dumps(archive()))
