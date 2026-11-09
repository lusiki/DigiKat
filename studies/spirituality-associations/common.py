"""Shared study paths and deterministic text normalization."""
from pathlib import Path
import csv
import hashlib
import json
import re
import unicodedata

ROOT = Path(__file__).resolve().parent
PRIVATE = ROOT / 'output/private'
TABLES = ROOT / 'output/tables'
FIGURES = ROOT / 'output/figures'
for path in (PRIVATE, TABLES, FIGURES):
    path.mkdir(parents=True, exist_ok=True)

def norm(value):
    value = unicodedata.normalize('NFKD', str(value).casefold().replace('đ', 'd'))
    value = ''.join(c for c in value if not unicodedata.combining(c))
    return ' '.join(re.sub(r'[^a-z0-9]+', ' ', value).split())

def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()

def dump_json(path, obj):
    Path(path).write_text(json.dumps(obj, ensure_ascii=False, indent=2), encoding='utf-8')

def write_csv(path, rows, fields=None):
    rows = list(rows)
    fields = fields or (list(rows[0]) if rows else [])
    with open(path, 'w', newline='', encoding='utf-8') as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)

def read_csv(path):
    with open(path, encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))
