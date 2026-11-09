"""Read-only XLSX validation and lossless manual-coding preservation.

openpyxl is used only to read; artifact-tool authors the workbook.
"""
import csv
import hashlib
import json
import math
import sys
from pathlib import Path
from datetime import date, datetime
import openpyxl

ROOT = Path(__file__).resolve().parents[2]
PRIVATE = ROOT / 'studies/theological-authority/output/private/extended'
BOOK = PRIVATE / 'katolicke-teme-i-komunikacijski-akteri-2021-2025.xlsx'
MANUAL = PRIVATE.parent / 'manual-coding'
CSV = MANUAL / 'kodiranje.csv'
BASE = MANUAL / 'last-export.json'
FIELDS = ['scope','source_id','source','platform','proposed_actor_group','reviewed_actor_group',
 'institutional_mandate','individual_clergy_status','individual_lay_status','organisation_community_channel',
 'theological_education','authority_invoked','interprets_faith_or_doctrine','status_valid_from',
 'status_valid_to','evidence_reference','reviewer','review_date','notes']
EDITABLE = FIELDS[5:]

def norm(v):
    if v is None: return ''
    if isinstance(v,(date,datetime)): return v.strftime('%Y-%m-%d')
    return str(v)

def keyed(rows):
    result = {}
    for row in rows:
        key = row['source_id']
        if not key or key in result: raise ValueError('Missing or duplicate coding source_id')
        result[key] = row
    return result

def merge_coding(current, baseline, workbook):
    """Three-way cell merge; never silently resolve conflicting edits."""
    result = {k:dict(v) for k,v in current.items()}
    for key, row in workbook.items():
        target = result.setdefault(key,dict(row))
        for field in EDITABLE:
            old = norm(baseline.get(key,{}).get(field))
            left, right = norm(target.get(field)), norm(row.get(field))
            if left != old and right != old and left != right:
                raise ValueError(f'Conflicting CSV/workbook edits: {key}, {field}. Both files preserved.')
            if right != old: target[field] = right
    return result

def prepare():
    data = json.loads((PRIVATE/'workbook_data.json').read_text(encoding='utf-8'))
    current = keyed(list(csv.DictReader(CSV.open(encoding='utf-8-sig',newline='')))) if CSV.exists() else {}
    baseline = keyed(json.loads(BASE.read_text(encoding='utf-8'))) if BASE.exists() else {}
    book_rows = {}
    if BOOK.exists():
        wb = openpyxl.load_workbook(BOOK,read_only=True,data_only=False)
        values = wb['Kodiranje'].iter_rows(values_only=True)
        headers = next(values)
        # Coding headers deliberately retain exact machine keys.
        book_rows = keyed([{k:norm(v) for k,v in zip(headers,r)} for r in values if any(v is not None for v in r)])
        wb.close()
    current = merge_coding(current,baseline,book_rows)
    for src in data['metadata']:
        key = src['source_id']
        if key not in current:
            current[key] = {f:'' for f in FIELDS}
            current[key].update(scope='all',source_id=key,source=src['source'],platform=src['platform'],
                                proposed_actor_group=src['actor_group'])
    rows = sorted(current.values(),key=lambda r:r['source_id'])
    MANUAL.mkdir(exist_ok=True)
    # Write only on actual changes, preserving the canonical manual file byte-for-byte otherwise.
    import io
    stream = io.StringIO(newline='')
    writer = csv.DictWriter(stream,fieldnames=FIELDS,lineterminator='\n')
    writer.writeheader(); writer.writerows(rows)
    encoded = ('\ufeff'+stream.getvalue()).encode('utf-8')
    if not CSV.exists() or CSV.read_bytes()!=encoded:
        if CSV.exists():
            backup = MANUAL / ('kodiranje-'+hashlib.sha256(CSV.read_bytes()).hexdigest()[:16]+'.csv')
            if not backup.exists(): backup.write_bytes(CSV.read_bytes())
        CSV.write_bytes(encoded)
    (PRIVATE/'coding_data.json').write_text(json.dumps(rows,ensure_ascii=False),encoding='utf-8')
    print(f'Manual coding preserved: {len(rows)} sources')

def verify():
    data = json.loads((PRIVATE/'workbook_data.json').read_text(encoding='utf-8'))
    spec = json.loads((PRIVATE/'workbook_spec.json').read_text(encoding='utf-8'))
    wb = openpyxl.load_workbook(BOOK,read_only=False,data_only=False)
    assert wb.sheetnames == [s['name'] for s in spec]
    for sheet in spec:
        ws = wb[sheet['name']]
        assert ws.freeze_panes is not None
        assert ws.tables and all(t.autoFilter is not None for t in ws.tables.values())
        assert ws.max_row==len(sheet['rows'])+1
        assert [c.value for c in ws[1]]==sheet['labels']
        for values, expected in zip(ws.iter_rows(min_row=2),sheet['rows']):
            for cell, value, field in zip(values,expected,sheet['fields']):
                actual = cell.value
                if value is None or value=='': assert actual is None,(ws.title,cell.coordinate,actual)
                elif field in ('first_observed','last_observed'):
                    assert norm(actual)==value,(ws.title,cell.coordinate,actual,value)
                elif isinstance(value,(int,float)):
                    assert isinstance(actual,(int,float)) and math.isclose(actual,value,rel_tol=1e-12,abs_tol=1e-9)
                else: assert actual==value,(ws.title,cell.coordinate,actual,value)
    wb.close()
    # File hash is checked independently of the R analysis.
    with open(data['input']['path'],'rb') as handle:
        actual_hash = hashlib.file_digest(handle,'sha256').hexdigest()
    assert actual_hash==data['input']['sha256']
    BASE.write_text((PRIVATE/'coding_data.json').read_text(encoding='utf-8'),encoding='utf-8')
    report = dict(sheets=len(spec),all_cells_roundtrip=True,filters_and_frozen_headers=True,
                  input_sha256=actual_hash,manual_coding_sha256=hashlib.sha256(CSV.read_bytes()).hexdigest())
    (PRIVATE/'workbook_validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report))

if __name__=='__main__':
    {'prepare':prepare,'verify':verify}[sys.argv[1]]()
