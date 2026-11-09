"""All-year, read-only field-specific name screen. Resume by completed month."""
from pathlib import Path
import sys, json, hashlib, time, importlib.util, argparse
from datetime import datetime, timezone
import duckdb, ahocorasick
import pandas as pd
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from common import ROOT, PRIVATE, TABLES, read_csv, write_csv, dump_json, sha, norm
spec = importlib.util.spec_from_file_location('old_screen', ROOT/'02_media.py')
old = importlib.util.module_from_spec(spec); spec.loader.exec_module(old)
OUT = PRIVATE/'media/v1'; OUT.mkdir(parents=True, exist_ok=True)
TAB = TABLES/'media-v1'; TAB.mkdir(parents=True, exist_ok=True)
DB = Path(r'C:\Users\lsikic\Luka C\DetermDB\determDB_merged.duckdb')
def fp():
    s=DB.stat(); return {'bytes':s.st_size,'mtime_ns':s.st_mtime_ns}
def normalize_sql(field):
    return f"trim(regexp_replace(replace(strip_accents(lower(coalesce({field},''))),'đ','d'),'[^a-z0-9]+',' ','g'))"
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--year');ap.add_argument('--prepare-only',action='store_true');args=ap.parse_args()
    begin=time.monotonic(); before=fp()
    register=read_csv(PRIVATE/'register.csv'); rules=old.rules_for(register)
    if not args.year:write_csv(OUT/'rules.csv',rules)
    signature={'database':before,'rules_sha256':sha(OUT/'rules.csv'),'version':1,'fields':['TITLE','FULL_TEXT','MENTION_SNIPPET']}
    if (OUT/'signature.json').exists():
        assert json.loads((OUT/'signature.json').read_text())==signature, 'Snapshot/rule change: create a fresh version.'
    if not args.year:dump_json(OUT/'signature.json',signature)
    c=duckdb.connect(str(DB),read_only=True)
    c.execute('SET threads=4');c.execute("SET memory_limit='4GB'")
    c.execute('SET temp_directory=?',[(OUT/('temp_'+(args.year or 'parent'))).as_posix()])
    total=c.sql('SELECT count(*),min(DATE),max(DATE) FROM media_data_all').fetchone()
    manifest={'database_file':DB.name,'fingerprint_before':before,
        'read_only':True,'rows':total[0],'start':total[1],'end':total[2],
        'register_sha256':sha(PRIVATE/'register.csv'),'rule_sha256':sha(OUT/'rules.csv'),
        'plan_sha256':sha(ROOT.parents[1]/'output/pdf/spirituality-associations-media-research-plan.pdf'),
        'registered_organisations':len(register),'searched_organisations':len({r['association_id'] for r in rules}),
        'schema':[{'field':r[0],'type':r[1]} for r in c.sql('DESCRIBE media_data_all').fetchall()],
        'run_utc':datetime.now(timezone.utc).isoformat(),'duckdb':duckdb.__version__}
    if not args.year:dump_json(TAB/'manifest.json',manifest)
    if not (TAB/'daily_coverage.csv').exists():
        c.sql('''SELECT DATE as date,SOURCE_TYPE as platform,SOURCE_BATCH as batch,I_FILTERED as i_filtered,
            count(*) as rows FROM media_data_all GROUP BY ALL ORDER BY ALL''').fetchdf().to_csv(TAB/'daily_coverage.csv',index=False)
    daily=pd.read_csv(TAB/'daily_coverage.csv');months=sorted(daily.date.str[:7].unique())
    if args.prepare_only:
        c.close();print('INVENTORY READY',total,flush=True);return
    auto=old.automaton_for(rules)
    anchors=ahocorasick.Automaton()
    for word in sorted({max(r['phrase'].split(),key=len) for r in rules}):anchors.add_word(word,word)
    anchors.make_automaton()
    cache=OUT/'months';cache.mkdir(exist_ok=True)
    for month in months:
        if args.year and not month.startswith(args.year):continue
        dest=cache/f'{month}.jsonl'
        if dest.exists() and (cache/f'{month}.audit.json').exists():continue
        lo=month+'-01'; hi=str((pd.Timestamp(lo)+pd.offsets.MonthBegin()).date())
        # Inventory derives from exactly the same month as the matching scan.
        c.execute('''SELECT substr(DATE,1,7) AS month,SOURCE_TYPE AS platform,count(*) AS rows,
          count(*) FILTER (WHERE length(trim(coalesce(TITLE,'')))>0) AS with_title,
          count(*) FILTER (WHERE length(trim(coalesce(FULL_TEXT,'')))>0) AS with_body,
          count(*) FILTER (WHERE length(trim(coalesce(MENTION_SNIPPET,'')))>0) AS with_snippet,
          count(*) FILTER (WHERE length(trim(coalesce(URL,'')))>0) AS with_url,
          count(*) FILTER (WHERE I_FILTERED) AS i_filtered_rows
          FROM media_data_all WHERE DATE>=? AND DATE<? GROUP BY 1,2 ORDER BY 1,2''',[lo,hi]).fetchdf().to_csv(cache/f'{month}.coverage.csv',index=False)
        c.execute('''SELECT substr(DATE,1,7) AS month,
          lower(regexp_replace(regexp_extract(URL,'^(?:https?://)?([^/:?#]+)',1),'^www\\.','')) AS domain,
          count(*) AS rows,count(DISTINCT DATE) AS days
          FROM media_data_all WHERE DATE>=? AND DATE<? AND SOURCE_TYPE='web'
          GROUP BY 1,2 ORDER BY 1,2''',[lo,hi]).fetchdf().to_csv(cache/f'{month}.sources.csv',index=False)
        fields=['DATE','SOURCE_TYPE','FROM','URL','ITEM_ID','SOURCE_BATCH','I_FILTERED','TITLE','FULL_TEXT','MENTION_SNIPPET']
        # Cheap accent-folding + an Aho anchor is lossless for the phrase rules;
        # punctuation/whitespace normalization is needed only after an anchor hit.
        sql='SELECT '+','.join('"'+x+'"' for x in fields)+','+','.join("replace(strip_accents(lower(coalesce("+f+",''))),'đ','d')" for f in fields[-3:])+' FROM media_data_all WHERE DATE>=? AND DATE<?'
        cur=c.execute(sql,[lo,hi]); scanned=hits=0
        with dest.with_suffix('.partial').open('w',encoding='utf-8') as f:
            while batch:=cur.fetchmany(1024):
                for row in batch:
                    matches=[]
                    for field,text in zip(fields[-3:],row[-3:]):
                        if next(anchors.iter(text),None) is None:continue
                        text=norm(text)
                        for m in old.find_matches(text,auto):
                            m['field']=field
                            m['offset_normalized']=text.find(m['matched_phrase'])
                            matches.append(m)
                    if matches:
                        rec=dict(zip(fields,row[:len(fields)]));rec['matches']=matches
                        rec['row_hash']=hashlib.sha256(json.dumps(row[:len(fields)],ensure_ascii=False).encode()).hexdigest()
                        f.write(json.dumps(rec,ensure_ascii=False)+'\n');hits+=1
                scanned+=len(batch)
        expected=int(daily.loc[daily.date.str.startswith(month),'rows'].sum());assert scanned==expected
        dest.with_suffix('.partial').replace(dest)
        dump_json(cache/f'{month}.audit.json',{'month':month,'scanned':scanned,'raw_candidates':hits,'elapsed':round(time.monotonic()-begin,1)})
        print(month,'scanned',scanned,'candidates',hits,'elapsed',round(time.monotonic()-begin),flush=True)
    c.close();assert fp()==before,'Source changed during scan'
    if args.year:
        print('YEAR COMPLETE',args.year,flush=True);return
    pd.concat([pd.read_csv(cache/f'{m}.coverage.csv') for m in months]).to_csv(TAB/'monthly_coverage.csv',index=False)
    pd.concat([pd.read_csv(cache/f'{m}.sources.csv') for m in months]).to_csv(OUT/'monthly_web_sources.csv',index=False)
    dump_json(TAB/'scan_audit.json',{'months':len(months),'scanned':sum(json.loads((cache/f'{m}.audit.json').read_text())['scanned'] for m in months),
        'source_unchanged':True,'fingerprint_after':fp(),'finalize_invocation_seconds':round(time.monotonic()-begin,1),
        'timing_note':'Monthly audits retain worker elapsed times; this final invocation can resume entirely from cache.'})
    print('SCAN COMPLETE',flush=True)
if __name__=='__main__':main()
