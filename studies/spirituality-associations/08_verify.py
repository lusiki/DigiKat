"""Reconcile independent source extraction, retrieval outputs and reporting claims."""
from collections import Counter,defaultdict
from datetime import datetime,timezone
import importlib
import importlib.metadata
import json
from pathlib import Path
import subprocess
import sys
import duckdb
from common import ROOT,PRIVATE,TABLES,read_csv,write_csv,dump_json,sha,norm

def main():
    m=importlib.import_module('02_media')
    register=read_csv(PRIVATE/'register.csv'); raw=json.loads((PRIVATE/'source/associations_parsed.json').read_text(encoding='utf-8'))
    by_id={r['association_id']:r for r in register}
    assert len(register)==len(by_id)==len(raw)
    for r in raw:
        actual=by_id[r['id']]
        assert norm(r['name'])==actual['name_normalized'] and r['county']==actual['county'] and int(r['page'])==int(actual['pdf_page'])
    audit=json.loads((TABLES/'register_audit.json').read_text(encoding='utf-8'))
    assert audit['cover_total']==len(register) and audit['row_discrepancies']==0 and audit['county_totals_reconcile']
    for source in audit['source_files']:assert sha(PRIVATE/'source'/source['stored_file'])==source['sha256']
    county=read_csv(TABLES/'county_population_adjusted.csv');counts=Counter(r['county'] for r in register)
    assert len(county)==21 and sum(int(r['associations']) for r in county)==len(register)
    for r in county:
        assert counts[r['county']]==int(r['associations'])==int(r['pdf_footer_total'])
        assert abs(float(r['associations_per_100000'])-int(r['associations'])/int(r['population_mid2025'])*100000)<.0001
    # Independent Python/SQL normalization agreement on every registered name.
    c=duckdb.connect()
    c.execute('CREATE TABLE names(original VARCHAR)');c.executemany('INSERT INTO names VALUES (?)',[(r['name'],) for r in register])
    normalized=c.execute("SELECT original, trim(regexp_replace(replace(strip_accents(lower(original)),'đ','d'),'[^a-z0-9]+',' ','g')) FROM names").fetchall()
    assert all(norm(a)==b for a,b in normalized),'Python and SQL normalization differ'
    # Small behaviour checks target genuine ambiguity and normalization hazards.
    rules=[{'association_id':'1','phrase':'udruga breza','route':'test'},
           {'association_id':'2','phrase':'krscanski akademski krug','route':'test'}]
    autom=m.automaton_for(rules)
    assert len(m.find_matches(norm('UDRUGA “BREZA”'),autom))==1
    assert not m.find_matches(norm('xudruga Breza'),autom)
    assert not m.find_matches(norm('udruga Brezanska'),autom)
    assert not m.find_matches(norm('breza kraj puta'),autom)
    assert len(m.find_matches(norm('Kršćanski akademski krug'),autom))==1
    assert m.canonical_url('https://www.example.hr/a/?utm_source=x&id=2#top')==m.canonical_url('http://example.hr/a?id=2')
    assert m.canonical_url('https://example.hr/a?id=2')!=m.canonical_url('https://example.hr/a?id=3')
    assert {r['association_id'] for r in m.build_sample(register)}=={r['association_id'] for r in read_csv(PRIVATE/'pilot_60.csv')}
    assert len(read_csv(PRIVATE/'pilot_60.csv'))==60
    stored_rules=read_csv(PRIVATE/'matching_rules.csv');assert stored_rules==m.rules_for(register)
    cache=PRIVATE/'media_candidates'
    cache_audit=[]
    for month in range(1,13):
        path=cache/f'2025-{month:02}.parquet';assert path.exists()
        rows=c.execute('SELECT DATE,normalized_text FROM read_parquet(?)',[str(path)]).fetchall()
        auto=m.automaton_for(stored_rules)
        assert all(date.startswith(f'2025-{month:02}') and m.find_matches(t,auto) for date,t in rows)
        cache_audit.append({'month':f'2025-{month:02}','raw_candidates':len(rows),'sha256':sha(path)})
    write_csv(TABLES/'monthly_cache_audit.csv',cache_audit)
    c.close()
    hits=read_csv(PRIVATE/'candidate_matches.csv'); orgs=read_csv(PRIVATE/'organisation_screen.csv')
    assert len({(r['association_id'],r['record_key'],r['route']) for r in hits})==len(hits)
    assert len(orgs)==len(register)
    rule_ids={r['association_id'] for r in stored_rules};perorg=defaultdict(set)
    for r in hits:assert r['association_id'] in rule_ids;perorg[r['association_id']].add(r['record_key'])
    for r in orgs:
        assert int(r['candidate_items'])==len(perorg[r['association_id']])
        assert (r['search_status']=='screened')==(r['association_id'] in rule_ids)
    ca=json.loads((TABLES/'candidate_audit.json').read_text())
    assert sum(r['raw_candidates'] for r in cache_audit)==ca['raw_candidate_rows']
    assert len({r['record_key'] for r in hits})==ca['unique_candidate_items']
    assert len({r['association_id'] for r in hits})==ca['organisations_with_candidates']
    assert len({(r['association_id'],r['record_key']) for r in hits})==ca['organisation_item_pairs']
    assert sum(int(r['candidate_items']) for r in orgs)==ca['organisation_item_pairs']
    assert ca['source_unchanged']
    claim=json.loads((TABLES/'report_claims.json').read_text())
    assert claim['candidate_items']==ca['unique_candidate_items'] and claim['register']==len(register)
    assert claim['candidate_organisations']+claim['screened_no_candidate']+claim['held']==len(register)
    human=read_csv(PRIVATE/'human_review_queue.csv')
    assert all(not r['coder'] and not r['identity_label'] for r in human),'Do not silently manufacture human validation'
    sensitivity=read_csv(TABLES/'filter_sensitivity_12days.csv')
    assert len({r['date'] for r in sensitivity})==12
    for r in sensitivity:
        assert 0<=int(r['retained_candidate_rows'])<=int(r['candidate_rows'])<=int(r['raw_rows'])
        assert int(r['retained_candidate_rows'])<=int(r['retained_rows'])<=int(r['raw_rows'])
    # Private artifacts must remain ignored by the actual repository rules.
    repo=ROOT.parents[1]
    for file in [PRIVATE/'register.csv',PRIVATE/'candidate_matches.csv',PRIVATE/'directory.html',PRIVATE/'source/associations_register.pdf']:
        result=subprocess.run(['git','check-ignore',str(file)],cwd=repo,capture_output=True)
        assert result.returncode==0,f'Not ignored: {file}'
    forbidden={'url','title','full_text','body','context','email','registered_seat','record_key','association_id'}
    for path in TABLES.glob('*.csv'):
        rows=read_csv(path)
        if rows:assert not (set(rows[0])&forbidden),f'Private columns in aggregate: {path.name}'
    result={'status':'passed','run_utc':datetime.now(timezone.utc).isoformat(),
      'checks':['PDF JSON identity reconciliation','source SHA-256','county totals and density arithmetic',
       'all-name SQL Python normalization equivalence','word boundaries and alias behaviour','URL dedup safeguards',
       '60-case sample reproduction','rule reproduction','12 monthly candidate files and dates','candidate count reconciliation',
       'source fingerprint unchanged','report claim reconciliation','no invented human labels','12-day filter bounds',
       'private paths gitignored','aggregate schemas'],
      'python':sys.version,'dependencies':{p:importlib.metadata.version(p) for p in ['duckdb','pandas','numpy','matplotlib','pymupdf','pyahocorasick','reportlab']},
      'code_sha256':{p.name:sha(p) for p in sorted(ROOT.glob('*.py'))},
      'aggregate_sha256':{p.name:sha(p) for p in sorted(TABLES.glob('*')) if p.name not in ('verification.json',)}}
    dump_json(TABLES/'verification.json',result)
    print('PASS:',len(result['checks']),'verification groups')

if __name__=='__main__': main()
