"""Sensitivity audit on unfiltered source exports, the 15th of each 2025 month.

Days are a fixed calendar diagnostic, not a probability sample. A candidate is
a row matching the same conservative name rules as the database screen.
"""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import time
import duckdb
from common import PRIVATE, TABLES, read_csv, write_csv, dump_json, sha

def main():
    p=argparse.ArgumentParser(); p.add_argument('--source-dir',required=True); args=p.parse_args()
    root=Path(args.source_dir)
    rules=read_csv(PRIVATE/'matching_rules.csv')
    pattern='(^| )('+'|'.join(re.escape(x) for x in sorted({r['phrase'] for r in rules},key=lambda s:(-len(s),s)))+')($| )'
    c=duckdb.connect(); c.execute('SET threads=2'); c.execute("SET memory_limit='3GB'")
    rows=[]; provenance=[]
    for month in range(1,13):
        date=f'2025-{month:02}-15'; path=root/f'v2-{date}.json'
        if not path.exists():
            provenance.append({'source_file':path.name,'status':'missing'}); continue
        before=path.stat()
        query='''WITH base AS (SELECT type AS platform,
          trim(regexp_replace(replace(strip_accents(lower(coalesce(title,'')||' '||coalesce(fullText,''))),'đ','d'),'[^a-z0-9]+',' ','g')) AS normalized_text,
          regexp_matches(coalesce(title,'')||' '||coalesce(fullText,'')||' '||coalesce(mention,''),
             '(^|[^\\p{L}\\p{N}_])[iIıİ]([^\\p{L}\\p{N}_]|$)') AS retained
          FROM read_json(?,format='array',columns={id:'BIGINT',type:'VARCHAR',title:'VARCHAR',fullText:'VARCHAR',mention:'VARCHAR'})),
          tagged AS (SELECT *,regexp_matches(normalized_text,?) AS candidate FROM base)
          SELECT platform,count(*) AS raw_rows,count(*) FILTER (WHERE retained) AS retained_rows,
            count(*) FILTER (WHERE candidate) AS candidate_rows,
            count(*) FILTER (WHERE candidate AND retained) AS retained_candidate_rows
          FROM tagged GROUP BY 1 ORDER BY 1'''
        output=c.execute(query,[path.as_posix(),pattern]).fetchdf()
        for row in output.to_dict('records'): rows.append({'date':date,**row})
        after=path.stat(); assert (before.st_size,before.st_mtime_ns)==(after.st_size,after.st_mtime_ns)
        provenance.append({'source_file':path.name,'status':'read','bytes':before.st_size,'mtime_ns':before.st_mtime_ns,'sha256':sha(path)})
        print('Filter audit',date,'rows',int(output.raw_rows.sum()),'candidates',int(output.candidate_rows.sum()),flush=True)
    c.close()
    write_csv(TABLES/'filter_sensitivity_12days.csv',rows)
    sums={key:sum(r[key] for r in rows) for key in ['raw_rows','retained_rows','candidate_rows','retained_candidate_rows']}
    dump_json(TABLES/'filter_audit.json',{'design':'15th of each month in 2025; fixed calendar diagnostic; not a probability sample',
        'days_read':sum(p['status']=='read' for p in provenance),'totals':sums,
        'candidate_rows_lost':sums['candidate_rows']-sums['retained_candidate_rows'],
        'candidate_retention_pct':100*sums['retained_candidate_rows']/sums['candidate_rows'] if sums['candidate_rows'] else None,
        'all_row_retention_pct':100*sums['retained_rows']/sums['raw_rows'],
        'rules_sha256':sha(PRIVATE/'matching_rules.csv'),'run_utc':datetime.now(timezone.utc).isoformat()})
    dump_json(PRIVATE/'filter_source_manifest.json',provenance)

if __name__=='__main__': main()
