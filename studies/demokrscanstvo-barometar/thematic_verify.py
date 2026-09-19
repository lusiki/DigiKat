"""Check aggregate counts, provenance and the public schema; no NLP dependencies."""
import argparse
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path
import re
from multiplatform_verify import Page


def verify(root, base, html=None):
    manifest=json.loads((root/'manifest.json').read_text(encoding='utf-8'))
    expected={'topic_monthly.csv','topics.csv','summary.json','README.md'}
    assert set(manifest['files'])==expected
    for name,checksum in manifest['files'].items():
        raw=(root/name).read_bytes()
        assert hashlib.sha256(raw).hexdigest()==checksum,name
        assert not re.search(r'\b[A-Za-z]:[/\\]|record_key|source_name|FULL_TEXT|ITEM_ID',raw.decode('utf-8')),name
    summary=json.loads((root/'summary.json').read_text(encoding='utf-8'))
    assert summary['schema']=='barometar-themes-v1'
    assert summary['base_manifest_sha256']==hashlib.sha256((base/'manifest.json').read_bytes()).hexdigest()
    def table(path):
        with path.open(encoding='utf-8') as handle:return list(csv.DictReader(handle))
    rows=table(root/'topic_monthly.csv');totals=Counter();cells=Counter()
    assert len(rows)==len({(r['platform'],r['month'],r['topic']) for r in rows})
    topics={t['id']:t for t in summary['topics']}
    assert len(topics)==len(summary['topics'])
    for row in rows:
        assert set(row)=={'platform','month','topic','records'}
        assert row['topic'] in topics and re.fullmatch(r'\d{4}-\d{2}',row['month'])
        n=int(row['records']);assert n>0
        totals[row['topic']]+=n;cells[row['platform'],row['month']]+=n
    source=table(base/'monthly.csv')
    expected_cells={(r['platform'],r['month']):int(r['matching_records']) for r in source}
    assert not set(cells)-set(expected_cells)
    assert all(cells[key]==value for key,value in expected_cells.items())
    assert sum(totals.values())==summary['records']
    assert 0<summary['distinct_contexts']<=summary['records']
    for topic in topics.values():
        assert set(topic)=={'id','label','editorial_note','records','share','terms'}
        assert topic['records']==totals[topic['id']]
        assert abs(topic['share']-100*topic['records']/summary['records'])<1e-8
        assert len(topic['terms'])<=10 and all(re.fullmatch(r'[^\W\d_]{3,}',t) for t in topic['terms'])
    topic_table=table(root/'topics.csv')
    assert len(topic_table)==len(topics) and {r['topic'] for r in topic_table}==set(topics)
    for row in topic_table:
        assert set(row)=={'topic','label','records','share'}
        assert int(row['records'])==topics[row['topic']]['records']
        assert abs(float(row['share'])-topics[row['topic']]['share'])<1e-6
    if html:
        page=Page();page.feed(html.read_text(encoding='utf-8'))
        match=re.search(r'<script id="mt-data" type="application/json">(.*?)</script>',html.read_text(encoding='utf-8'),re.S)
        assert match
        payload=json.loads(match.group(1))
        assert len(payload['topics'])==len(summary['topics'])
        for rendered,topic in zip(payload['topics'],summary['topics']):
            for key in ('id','label','editorial_note','records','terms'):assert rendered[key]==topic[key]
            assert abs(rendered['share']-topic['share'])<1e-8
        assert Counter({(r['platform'],r['month'],r['topic']):r['records'] for r in payload['monthly']})==Counter(
            {(r['platform'],r['month'],r['topic']):int(r['records']) for r in rows})
        assert not re.search(r'preliminar|Raniji pregled|AI asistent|Pretražena je cijela', ' '.join(page.text),re.I)
    return {'thematic_checks':'passed','records':summary['records'],'topics':summary['method']['n_components'],
            'platform_month_reconciliation':'exact','public_schema':'aggregate-only'}


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--root',type=Path,default=Path('data/barometar/demokrscanstvo-themes/v1'))
    parser.add_argument('--base',type=Path,default=Path('data/barometar/demokrscanstvo-multiplatform/v1'))
    parser.add_argument('--html',type=Path)
    args=parser.parse_args()
    print(json.dumps(verify(args.root,args.base,args.html),indent=2))
