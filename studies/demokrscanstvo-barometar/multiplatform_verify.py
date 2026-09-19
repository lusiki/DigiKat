"""Validate the real aggregate release and optionally its rendered page."""
import argparse
import csv
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import re


class Page(HTMLParser):
    def __init__(self):
        super().__init__();self.links=[];self.ids=[];self.in_payload=False;self.payload='';self.text=[]
    def handle_starttag(self,tag,attrs):
        attrs=dict(attrs)
        if 'id' in attrs:self.ids.append(attrs['id'])
        if tag in ('a','script','img','link'):
            for key in ('href','src'):
                if key in attrs:self.links.append(attrs[key])
        if tag=='script' and attrs.get('id')=='mp-data':self.in_payload=True
    def handle_endtag(self,tag):
        if tag=='script':self.in_payload=False
    def handle_data(self,text):
        self.text.append(text)
        if self.in_payload:self.payload+=text


def verify(root, html=None):
    manifest=json.loads((root/'manifest.json').read_text(encoding='utf-8'))
    summary=json.loads((root/'summary.json').read_text(encoding='utf-8'))
    assert summary['synthetic'] is False and summary['human_validation_complete'] is False
    assert summary['assistant_review']['human_validation'] is False
    assert summary['raw_records']-summary['duplicates_removed']==summary['unique_records']
    tables={}
    forbidden={'record_key','doc_key','source_name','TITLE','FULL_TEXT','URL','AUTHOR','ITEM_ID','source_row'}
    for name,expected in manifest['files'].items():
        path=root/name
        assert path.parent==root and path.is_file()
        assert hashlib.sha256(path.read_bytes()).hexdigest()==expected,name
        text=path.read_text(encoding='utf-8')
        assert not re.search(r'[A-Za-z]:[/\\]|Luka C[/\\]|DetermDB[/\\]',text),name
        if name.endswith('.csv'):
            rows=list(csv.DictReader(text.splitlines()))
            if rows:assert not (set(rows[0]) & forbidden),name
            tables[name]=rows
    m=tables['monthly.csv'];p=tables['platforms.csv'];a=tables['text_availability.csv']
    assert len({(r['platform'],r['month']) for r in m})==len(m)
    assert len({r['platform'] for r in m})==summary['platform_count']==len(p)
    for column in ('matching_records','narrow_records','eligible_records'):
        assert sum(int(r[column]) for r in m)==summary[column]==sum(int(r[column]) for r in p)
    assert sum(int(r['records']) for r in a)==summary['unique_records']
    for r in m:
        n,d=int(r['matching_records']),int(r['eligible_records'])
        assert 0<=int(r['narrow_records'])<=n<=d<=int(r['records'])
        assert 0<=int(r['full_text_narrow_records'])<=int(r['full_text_matches'])<=int(r['full_text_records'])<=d
        if d:assert abs(float(r['per_10000'])-10000*n/d)<1e-8
        else:assert r['per_10000']==''
    for row in p:
        part=[r for r in m if r['platform']==row['platform']]
        assert sum(int(r['matching_records']) for r in part)==int(row['matching_records'])
    result={'aggregate_checks':'passed','monthly_rows':len(m),'platforms':len(p),
        'matching_records':summary['matching_records'],'source_text_or_ids_in_public_tables':False}
    if html:
        page=Page();page.feed(html.read_text(encoding='utf-8'))
        assert len(page.ids)==len(set(page.ids)), 'Duplicate HTML IDs'
        payload=json.loads(page.payload)
        assert len(payload['monthly'])==len(m)
        assert sum(r['matching_records'] for r in payload['monthly'])==summary['matching_records']
        missing=[]
        for link in page.links:
            if link.startswith(('#','http:','https:','mailto:','data:','tel:','javascript:','/')):continue
            target=(html.parent/link.split('#')[0].split('?')[0]).resolve()
            if not target.exists():missing.append(link)
        # Report inherited site links separately; every new resource must exist.
        assert not [x for x in missing if 'barometar' in x or 'demokrscanstvo' in x],missing
        visible=' '.join(page.text)
        assert 'SINTETIČKI PODACI' not in visible
        assert 'Stvarni podaci' in visible and 'Neovisna ljudska validacija još nije provedena' in visible
        assert not re.search(r'Error in |Execution halted|Traceback \(most recent',visible)
        result.update(rendered_checks='passed',inherited_missing_links=missing)
    return result


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--root',type=Path,default=Path('data/barometar/demokrscanstvo-multiplatform/v1'))
    parser.add_argument('--html',type=Path)
    args=parser.parse_args()
    print(json.dumps(verify(args.root,args.html),ensure_ascii=False,indent=2))
