"""Read-only 2025 general-media inventory and conservative candidate retrieval.

This is a discovery screen. Neither lexical hits nor source domains establish
validated organisation visibility or editorial independence.
"""
import argparse
from collections import defaultdict, Counter
from datetime import datetime, timezone
import hashlib
import importlib.metadata
import json
from pathlib import Path
import re
import time
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode
import ahocorasick
import duckdb
from common import ROOT, PRIVATE, TABLES, read_csv, write_csv, dump_json, sha, norm

# Aliases are grounded in official website self-identification recorded in
# WEB_EVIDENCE.md. Shared Zdenac and yoga network labels are NOT assigned to branches.
ALIASES = {'8013':['udruga breza','udruge breza','udruzi breza','udrugu breza'],
           '4553':['skac palma','skac palme','skac palmi','skac palmu'],
           '58492':['skac split','skac st'],
           '42662':[],
           '42673':['udruga korablja','udruge korablja','udruzi korablja','udrugu korablja'],
           '14821':['hrvatsko budisticko drustvo padmasana','hrvatskog budistickog drustva padmasana'],
           '32947':['krscanski akademski krug','krscanskog akademskog kruga','krscanskom akademskom krugu']}
STOP = {'udruga','udruzenje','drustvo','centar','savez','klub','za','i','u','od','hrvatska','hrvatske','hrvatski'}

def rules_for(register):
    rules=[]
    for row in register:
        name=row['name_normalized']; substantive=[w for w in name.split() if w not in STOP]
        # Do not infer uniqueness from a short/generic association name.
        if len(name)>=18 and len(name.split())>=3 and len(substantive)>=2:
            rules.append({'association_id':row['association_id'],'phrase':name,'route':'full_registered_name'})
        for alias in ALIASES.get(row['association_id'],[]):
            rules.append({'association_id':row['association_id'],'phrase':alias,'route':'curated_alias'})
    return rules

def automaton_for(rules):
    lookup=defaultdict(list)
    for r in rules:
        lookup[r['phrase']].append(r)
    automaton=ahocorasick.Automaton()
    for phrase, entries in lookup.items():
        automaton.add_word(phrase,(phrase,entries))
    automaton.make_automaton()
    return automaton

def find_matches(text, automaton):
    found={}
    for end,(phrase,entries) in automaton.iter(text):
        start=end-len(phrase)+1
        if (start and text[start-1]!=' ') or (end+1<len(text) and text[end+1]!=' '):
            continue
        for rule in entries:
            key=(rule['association_id'],rule['route'])
            found.setdefault(key, {'association_id':rule['association_id'],'route':rule['route'],
                  'matched_phrase':phrase,'context':text[max(0,start-180):end+181]})
    return list(found.values())

def canonical_url(value):
    if not value:
        return ''
    try:
        p=urlsplit(value if '://' in value else 'https://'+value)
        params=[(k,v) for k,v in parse_qsl(p.query,keep_blank_values=True)
                if not k.lower().startswith('utm_') and k.lower() not in ('fbclid','gclid')]
        return urlunsplit(('',p.netloc.lower().removeprefix('www.'),p.path.rstrip('/'),urlencode(sorted(params)),''))
    except ValueError:
        return value

def fingerprint(path):
    stat=path.stat()
    return {'bytes':stat.st_size,'mtime_ns':stat.st_mtime_ns}

def build_sample(register):
    # Six deliberately equally weighted lexical strata, ten organisations each.
    # Focal cases are purposive. Remaining slots greedily expand county coverage
    # with SHA-256(seed|ID) as a reproducible tie-breaker, never visibility counts.
    focal={'8013','4553','58492','42673','14821','32947','31032','233887','32442','2939','9333','10420'}
    selected=[]; seen=Counter()
    groups=defaultdict(list)
    for row in register:
        groups[row['sampling_stratum']].append(row)
    for key in sorted(groups):
        candidates=groups[key]
        forced=sorted([r for r in candidates if r['association_id'] in focal],key=lambda r:r['association_id'])
        chosen=list(forced)
        for r in chosen: seen[r['county']]+=1
        while len(chosen)<10:
            rest=[r for r in candidates if r not in chosen]
            row=min(rest,key=lambda r:(seen[r['county']],hashlib.sha256(('20260919|'+r['association_id']).encode()).hexdigest()))
            chosen.append(row); seen[row['county']]+=1
        for row in chosen:
            selected.append({**row,'sample_reason':'purposive_website_case' if row['association_id'] in focal else 'county_diversity_hash_tiebreak'})
    return selected

def main():
    p=argparse.ArgumentParser()
    p.add_argument('--database',required=True)
    p.add_argument('--inventory-only',action='store_true')
    args=p.parse_args()
    path=Path(args.database); before=fingerprint(path)
    register=read_csv(PRIVATE/'register.csv'); rules=rules_for(register)
    write_csv(PRIVATE/'matching_rules.csv',rules)
    sample=build_sample(register)
    write_csv(PRIVATE/'pilot_60.csv',sample)
    dump_json(TABLES/'matching_design.json',{'register_rows':len(register),'organisations_with_rules':len({r['association_id'] for r in rules}),
              'rules':len(rules),'pilot_n':len(sample),'pilot_counties':len({r['county'] for r in sample}),
              'pilot_strata':dict(Counter(r['sampling_stratum'] for r in sample)), 'seed':'20260919',
              'rule_sha256':sha(PRIVATE/'matching_rules.csv'),'pilot_sha256':sha(PRIVATE/'pilot_60.csv')})
    c=duckdb.connect(str(path),read_only=True)
    c.execute("SET threads=4"); c.execute("SET memory_limit='4GB'")
    spill=PRIVATE/'duckdb_temp';spill.mkdir(exist_ok=True)
    c.execute('SET temp_directory=?',[spill.as_posix()])
    started=time.monotonic()
    total=c.execute('SELECT count(*), min(DATE), max(DATE) FROM main.media_data_all').fetchone()
    coverage=c.execute('''SELECT substr(DATE,1,7) AS month, SOURCE_TYPE AS platform,
      count(*) AS monitored_rows, count(DISTINCT DATE) AS days,
      count(*) FILTER (WHERE length(trim(coalesce(FULL_TEXT,'')))>0) AS rows_with_body,
      count(*) FILTER (WHERE length(trim(coalesce(TITLE,'')||coalesce(FULL_TEXT,'')))>0) AS rows_with_search_text,
      count(*) FILTER (WHERE I_FILTERED) AS i_filtered_rows
      FROM main.media_data_all WHERE DATE >= '2025-01-01' AND DATE < '2026-01-01'
      GROUP BY 1,2 ORDER BY 1,2''').fetchdf()
    coverage.to_csv(TABLES/'media_coverage_2025.csv',index=False,encoding='utf-8')
    days=[r[0] for r in c.execute("SELECT DISTINCT DATE FROM main.media_data_all WHERE DATE >= '2025-01-01' AND DATE < '2026-01-01' ORDER BY 1").fetchall()]
    dump_json(TABLES/'media_snapshot.json',{'database_file':path.name,'table':'main.media_data_all','read_only':True,
      'file_fingerprint':before,'snapshot_rows':total[0],'snapshot_start':total[1],'snapshot_end':total[2],
      'schema':[{'field':r[0],'storage_type':r[1]} for r in c.execute('DESCRIBE main.media_data_all').fetchall()],
      'search_start':'2025-01-01','search_end_exclusive':'2026-01-01','days_2025':len(days),
      'rows_2025':int(coverage.monitored_rows.sum()),'search_fields':['TITLE','FULL_TEXT'],
      'normalization':'lowercase, strip accents, d-stroke to d, non-alphanumerics to spaces',
      'retrieval_status':'unvalidated candidates','run_utc':datetime.now(timezone.utc).isoformat(),
      'duckdb_version':duckdb.__version__,'python_packages':{x:importlib.metadata.version(x) for x in ['pyahocorasick','pandas']}})
    print('Inventory:',total,'2025 rows',int(coverage.monitored_rows.sum()),'days',len(days),flush=True)
    if args.inventory_only:
        c.close(); return
    cache=PRIVATE/'media_candidates'; cache.mkdir(exist_ok=True)
    cache_signature={'source':before,'rules_sha256':sha(PRIVATE/'matching_rules.csv'),'version':1}
    signature_path=cache/'signature.json'
    if signature_path.exists() and json.loads(signature_path.read_text())!=cache_signature:
        raise RuntimeError('Candidate cache belongs to another snapshot/rule set. Preserve it and use a new cache directory.')
    dump_json(signature_path,cache_signature)
    automaton=automaton_for(rules)
    # Tab between fields becomes a space: full text supplies body and title.
    normal="trim(regexp_replace(replace(strip_accents(lower(coalesce(TITLE,'') || ' ' || coalesce(FULL_TEXT,''))), 'đ','d'),'[^a-z0-9]+',' ','g'))"
    for month in range(1,13):
        outfile=cache/f'2025-{month:02}.parquet'
        if outfile.exists():
            with outfile.open('rb') as stream:
                header=stream.read(4)
                if outfile.stat().st_size>=8:
                    stream.seek(-4,2); footer=stream.read(4)
                else: footer=b''
            if header==footer==b'PAR1': continue
            outfile.replace(outfile.with_suffix('.interrupted'))
        lo=f'2025-{month:02}-01'; hi=f'2025-{month+1:02}-01' if month<12 else '2026-01-01'
        # Aho-Corasick scans all names in one linear pass. A giant RE2 alternation
        # was benchmarked and rejected because it scales poorly on long articles.
        sql=f'''SELECT DATE,SOURCE_TYPE,"FROM",URL,ITEM_ID,TITLE,FULL_TEXT,{normal} AS normalized_text
          FROM main.media_data_all WHERE DATE>=? AND DATE<?'''
        cursor=c.execute(sql,[lo,hi]); found=[]; scanned=0
        while batch:=cursor.fetchmany(1024):
            for row in batch:
                if find_matches(row[-1],automaton): found.append(row)
            scanned+=len(batch)
        expected=int(coverage.loc[coverage.month==lo[:7],'monitored_rows'].sum())
        assert scanned==expected,(lo,scanned,expected)
        writer=duckdb.connect()
        writer.execute('''CREATE TABLE candidates(DATE VARCHAR,SOURCE_TYPE VARCHAR,"FROM" VARCHAR,
                           URL VARCHAR,ITEM_ID BIGINT,TITLE VARCHAR,FULL_TEXT VARCHAR,normalized_text VARCHAR)''')
        if found: writer.executemany('INSERT INTO candidates VALUES (?,?,?,?,?,?,?,?)',found)
        temp=outfile.with_suffix('.partial')
        writer.execute('COPY candidates TO ? (FORMAT PARQUET, COMPRESSION ZSTD)',[temp.as_posix()])
        writer.close(); temp.replace(outfile)
        print('Retrieved',lo,'scanned',scanned,'candidates',len(found),'elapsed seconds',round(time.monotonic()-started),flush=True)
    c.close()
    assert before==fingerprint(path),'Source database changed during scan'
    assert len(list(cache.glob('2025-*.parquet')))==12,'Incomplete monthly retrieval'
    automaton=automaton_for(rules)
    local=duckdb.connect()
    cursor=local.execute('SELECT * FROM read_parquet(?)',[str(cache/'*.parquet')])
    fields=[d[0] for d in cursor.description]
    hits=[]; seen=set(); candidates=0
    while batch:=cursor.fetchmany(1000):
        for values in batch:
            row=dict(zip(fields,values)); candidates+=1
            canonical=canonical_url(row['URL'])
            record_key=('url:'+canonical) if canonical else ('id:'+str(row['ITEM_ID']) if row['ITEM_ID'] else 'sha:'+hashlib.sha256((str(row['DATE'])+str(row['TITLE'])+str(row['FULL_TEXT'])).encode()).hexdigest())
            host=urlsplit(row['URL'] or '').hostname or ''
            for m in find_matches(row['normalized_text'],automaton):
                dedup=(m['association_id'],record_key,m['route'])
                if dedup in seen: continue
                seen.add(dedup)
                hits.append({**m,'record_key':record_key,'date':row['DATE'],'month':row['DATE'][:7],
                    'platform':row['SOURCE_TYPE'],'source_domain':host.lower().removeprefix('www.'),
                    'url':row['URL'],'title':row['TITLE'],'review_status':'not_human_validated'})
    local.close()
    write_csv(PRIVATE/'candidate_matches.csv',hits)
    by_org=defaultdict(list)
    for h in hits: by_org[h['association_id']].append(h)
    rule_ids={r['association_id'] for r in rules}
    summary=[]
    for r in register:
        found=by_org[r['association_id']]
        summary.append({'association_id':r['association_id'],'name':r['name'],'county':r['county'],
           'sampling_stratum':r['sampling_stratum'],'search_status':'screened' if r['association_id'] in rule_ids else 'held_for_identity_rules',
           'candidate_items':len({h['record_key'] for h in found}),'candidate_months':len({h['month'] for h in found}),
           'candidate_web_domains':len({h['source_domain'] for h in found if h['platform']=='web' and h['source_domain']}),
           'visibility_status':'unvalidated_candidate' if found else ('not_observed_under_rules' if r['association_id'] in rule_ids else 'not_yet_searched')})
    write_csv(PRIVATE/'organisation_screen.csv',summary)
    for label, group in [('all_register',summary),('pilot_60',[r for r in summary if r['association_id'] in {s['association_id'] for s in sample}])]:
        write_csv(TABLES/f'{label}_screen_summary.csv',[{'group':label,'status':status,'associations':n} for status,n in Counter(r['visibility_status'] for r in group).items()])
    county_rows=[]
    for county in sorted({r['county'] for r in summary}):
        rs=[r for r in summary if r['county']==county]
        county_rows.append({'county':county,'listed':len(rs),'screened':sum(r['search_status']=='screened' for r in rs),
            'with_candidates':sum(r['candidate_items']>0 for r in rs),'not_observed_under_rules':sum(r['visibility_status']=='not_observed_under_rules' for r in rs),
            'held_for_rules':sum(r['search_status']=='held_for_identity_rules' for r in rs)})
    write_csv(TABLES/'county_candidate_screen.csv',county_rows)
    monthly=[]
    for (month,platform),den in coverage.groupby(['month','platform']):
        group=[h for h in hits if h['month']==month and h['platform']==platform]
        monthly.append({'month':month,'platform':platform,'monitored_rows':int(den.monitored_rows.iloc[0]),
             'candidate_unique_items':len({h['record_key'] for h in group}), 'candidate_organisations':len({h['association_id'] for h in group})})
    write_csv(TABLES/'candidate_month_platform.csv',monthly)
    review=[]
    # Up to two candidates per observed organisation, selected deterministically.
    # This is a development audit, not a probability sample for precision estimates.
    for org, group in sorted(by_org.items()):
        unique={h['record_key']:h for h in group}
        chosen=sorted(unique.values(),key=lambda h:hashlib.sha256(('audit|'+h['record_key']).encode()).hexdigest())[:2]
        for h in chosen:
            review.append({**h,'identity_label':'','channel_type':'','prominence':'','coder':'','notes':''})
    write_csv(PRIVATE/'human_review_queue.csv',review)
    totals={'raw_candidate_rows':candidates,'unique_candidate_items':len({h['record_key'] for h in hits}),
       'organisation_item_pairs':len({(h['association_id'],h['record_key']) for h in hits}),
       'organisations_with_candidates':sum(bool(group) for group in by_org.values()),'organisations_screened':len(rule_ids),
       'organisations_held_for_rules':len(register)-len(rule_ids),'human_review_queue_rows':len(review),
       'source_unchanged':before==fingerprint(path),'elapsed_seconds':round(time.monotonic()-started,2),
       'candidate_matches_sha256':sha(PRIVATE/'candidate_matches.csv')}
    dump_json(TABLES/'candidate_audit.json',totals)
    print(json.dumps(totals,indent=2),flush=True)

if __name__=='__main__': main()
