"""Shared durable storage for local-only analysis. Corpus/config pins match the R export."""
from __future__ import annotations
import contextlib, hashlib, json, os, sys
from datetime import datetime, timezone
from pathlib import Path
import duckdb

STUDY = Path(__file__).resolve().parent
ROOT = STUDY.parent.parent
CONFIG = json.loads((STUDY / 'config.json').read_text(encoding='utf-8'))
MANIFEST = json.loads((ROOT / 'data/digikat_corpus_manifest.json').read_text(encoding='utf-8'))
CONFIG_HASH = hashlib.sha256((STUDY / 'config.json').read_bytes()).hexdigest()
CORPUS_HASH = MANIFEST['corpus']['sha256']

def utc(): return datetime.now(timezone.utc).isoformat()

def file_sha(path):
    digest=hashlib.sha256()
    with Path(path).open('rb') as f:
        for block in iter(lambda:f.read(1024*1024), b''): digest.update(block)
    return digest.hexdigest()

def workdir():
    value = os.environ.get('DIGIKAT_VOICES_WORKDIR', '')
    if not value: raise RuntimeError('DIGIKAT_VOICES_WORKDIR must be set')
    path = Path(value).resolve()
    if not Path(value).is_absolute() or path == ROOT or ROOT in path.parents or 'dropbox' in (x.lower() for x in path.parts):
        raise RuntimeError('Workdir must be outside Git and Dropbox')
    return path

def connect():
    con = duckdb.connect(str(workdir() / 'voices.duckdb'))
    con.execute('SET threads=4')
    if con.execute('SELECT corpus_sha256, config_hash FROM run_metadata').fetchall() != [(CORPUS_HASH, CONFIG_HASH)]:
        con.close(); raise RuntimeError('Corpus/config mismatch; do not mix runs')
    if con.execute('SELECT count(*) FROM docs').fetchone()[0] != MANIFEST['corpus']['rows']:
        con.close(); raise RuntimeError('Export incomplete')
    return con

@contextlib.contextmanager
def transaction(con):
    con.execute('BEGIN')
    try:
        yield
        con.execute('COMMIT')
    except BaseException:
        con.execute('ROLLBACK'); raise

def atomic_json(path, payload):
    path = Path(path)
    temp = path.with_suffix(path.suffix + '.tmp')
    with temp.open('w', encoding='utf-8') as f:
        json.dump(payload, f, ensure_ascii=False, indent=2, allow_nan=False)
        f.flush(); os.fsync(f.fileno())
    os.replace(temp, path)

def atomic_json_stable(path,payload):
    """Keep the original timestamp/hash when an immutable result is unchanged."""
    path=Path(path)
    if path.exists() and isinstance(payload,dict):
        old=json.loads(path.read_text(encoding='utf-8'))
        without_time=lambda value:{k:v for k,v in value.items() if k!='created_utc'}
        if isinstance(old,dict) and without_time(old)==without_time(payload):
            return old
    atomic_json(path,payload)
    return payload

def pin_stage(con, stage, settings):
    encoded = json.dumps(settings, sort_keys=True, ensure_ascii=False)
    digest = hashlib.sha256(encoded.encode('utf-8')).hexdigest()
    con.execute('''CREATE TABLE IF NOT EXISTS stage_settings
        (stage VARCHAR PRIMARY KEY, settings_hash VARCHAR, settings_json VARCHAR,
         corpus_sha256 VARCHAR, config_hash VARCHAR, created_utc VARCHAR)''')
    saved = con.execute('SELECT settings_hash FROM stage_settings WHERE stage=?', [stage]).fetchone()
    if saved and saved[0] != digest: raise RuntimeError(f'{stage} settings changed; use a new stage version')
    if not saved: con.execute('INSERT INTO stage_settings VALUES (?,?,?,?,?,?)', [stage,digest,encoded,CORPUS_HASH,CONFIG_HASH,utc()])
    return digest

def ensure_ollama_idle():
    import requests
    try: models = requests.get('http://127.0.0.1:11434/api/ps', timeout=10).json()['models']
    except requests.ConnectionError: return
    if models: raise RuntimeError('Ollama has loaded models. Unload them before CLASSLA (shared GPU).')

@contextlib.contextmanager
def gpu_lock():
    # A kernel file lock, released even after a crash. All study GPU stages use it.
    import msvcrt
    with (workdir() / 'gpu.lock').open('a+b') as f:
        if f.tell() == 0: f.write(b'0'); f.flush()
        f.seek(0)
        msvcrt.locking(f.fileno(), msvcrt.LK_NBLCK, 1)
        try: yield
        finally:
            f.seek(0); msvcrt.locking(f.fileno(), msvcrt.LK_UNLCK, 1)
