"""Reconcile candidates and derive full-period descriptive tables, without validation claims."""
from pathlib import Path
import sys,json,re,hashlib,html,collections,importlib.util
from urllib.parse import urlsplit
import pandas as pd
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from common import ROOT,PRIVATE,TABLES,FIGURES,norm,read_csv,dump_json,write_csv,sha
spec=importlib.util.spec_from_file_location('screen',ROOT/'02_media.py')
screen=importlib.util.module_from_spec(spec);spec.loader.exec_module(screen)
P=PRIVATE/'media/v1';T=TABLES/'media-v1';F=FIGURES/'media-v1';F.mkdir(parents=True,exist_ok=True)
RISK={'63362':'proverb','254009':'ordinary_phrase','14844':'generic_phrase_or_section_join','33791':'shared_cross_border_name'}
OWN={'8013':{'breza.hr'},'4553':{'skac.hr'},'58492':{'skac.st'},'42673':{'korablja-arka.hr'},'14821':{'padmasana.hr'},'32947':{'krakr.hr'}}
TAIL=re.compile(r'\b(?:procitajte (?:jos|takoder)|povezane (?:vijesti|objave)|vezani clanci|related (?:articles|posts)|najnovije (?:vijesti|objave)|preporucujemo vam)\b')
def digest(x):return hashlib.sha256(x.encode()).hexdigest()[:24]
def domain(url):
    try:return (urlsplit(url if '://' in url else 'https://'+url).hostname or '').lower().removeprefix('www.')
    except ValueError:return ''
def main():
    manifest=json.loads((T/'manifest.json').read_text());audit=json.loads((T/'scan_audit.json').read_text())
    assert audit['scanned']==manifest['rows'] and audit['months']==69
    register=pd.read_csv(PRIVATE/'register.csv',dtype={'association_id':str}).fillna('')
    reg=register.set_index('association_id').to_dict('index');rules=read_csv(P/'rules.csv');rule_ids={r['association_id'] for r in rules}
    raw=[]
    for file in sorted((P/'months').glob('*.jsonl')):
        raw.extend(json.loads(line) for line in file.open(encoding='utf-8'))
    seen=set();unique=[];raw_month=collections.Counter();raw_platform=collections.Counter();raw_domains=collections.Counter()
    for row in raw:
        raw_month[(row['DATE'][:7],row['SOURCE_TYPE'])]+=1
        raw_platform[row['SOURCE_TYPE']]+=1
        if row['SOURCE_TYPE']=='web':raw_domains[(row['DATE'][:7],domain(row['URL'] or ''))]+=1
        if row['row_hash'] not in seen:unique.append(row);seen.add(row['row_hash'])
    groups=collections.defaultdict(list)
    for row in unique:
        url=screen.canonical_url(row['URL'] or '')
        # Day is retained because reused/updated URLs do not prove a single article.
        base='url:'+url if url else ('id:'+str(row['ITEM_ID']) if row['ITEM_ID'] else 'text:'+digest((row['TITLE'] or '')+' '+(row['FULL_TEXT'] or '')))
        key=digest(row['SOURCE_TYPE']+'|'+row['DATE']+'|'+base)
        row['url_key']=digest(row['SOURCE_TYPE']+'|'+base);row['item_key']=key;groups[key].append(row)
    items=[];pairs=[];details=[]
    for key,versions in groups.items():
        row=max(versions,key=lambda r:len(r['FULL_TEXT'] or ''));body=norm(row['FULL_TEXT'] or '')
        title=norm(row['TITLE'] or '');host=domain(row['URL'] or '')
        tail=TAIL.search(body);end=tail.start() if tail else len(body)
        cleaned=body[:end]
        text_hash=digest(body) if len(body)>=200 else 'short:'+key
        item={'item_key':key,'url_key':row['url_key'],'date':row['DATE'],'month':row['DATE'][:7],'year':int(row['DATE'][:4]),
              'platform':row['SOURCE_TYPE'],'domain':host,'source_label':row['FROM'] or '',
              'body_chars':len(body),'title_chars':len(title),'versions':len(versions),'story_hash':text_hash,
              'tail_marker':bool(tail),'url_missing':not bool(row['URL'])}
        items.append(item)
        by_org=collections.defaultdict(list)
        for v in versions:
            for m in v['matches']:by_org[m['association_id']].append((v,m))
        for org,evidence in by_org.items():
            fields={m['field'] for v,m in evidence};routes={m['route'] for v,m in evidence}
            title_hit='TITLE' in fields;body_hit='FULL_TEXT' in fields
            lead=False;pre_tail=False;contexts=[];expanded=[]
            for v,m in evidence:
                text=norm(v[m['field']] or '');pos=m['offset_normalized'];stop=TAIL.search(text) if m['field']=='FULL_TEXT' else None
                early=m['field']=='FULL_TEXT' and pos<800
                lead|=early
                pre_tail|=m['field']=='TITLE' or (m['field']=='FULL_TEXT' and (not stop or pos<stop.start()))
                if m['field']=='FULL_TEXT' and (not stop or pos<stop.start()):
                    contexts.append(text[max(0,pos-450):pos+len(m['matched_phrase'])+450])
                expanded.append({**m,'row_hash':v['row_hash']})
            clean_context=' '.join(dict.fromkeys(contexts))[:3000]
            if not clean_context and title_hit:clean_context=title
            strong=pre_tail and org not in RISK and not all(m['matched_phrase']=='skac st' for v,m in evidence)
            relationship='current_documented_own_domain' if host in OWN.get(org,set()) else 'unresolved'
            pair={'association_id':org,'item_key':key,'url_key':item['url_key'],'date':item['date'],'month':item['month'],
                  'year':item['year'],'platform':item['platform'],'domain':host,'story_hash':text_hash,
                  'title_hit':title_hit,'lead_hit':lead,'title_or_lead':title_hit or lead,
                  'body_hit':body_hit,'snippet_only':not title_hit and not body_hit,
                  'pre_tail':pre_tail,'restricted_candidate':strong,'known_risk':RISK.get(org,''),
                  'alias_only':routes=={'curated_alias'},'relationship':relationship,
                  'identity_state':'unresolved','human_identity':'','human_relevance':''}
            pairs.append(pair)
            details.append({**pair,'title':row['TITLE'],'url':row['URL'],'context':clean_context,'evidence':expanded,
                            'full_text':row['FULL_TEXT'],'clean_text':cleaned,'body_chars':len(body)})
    it=pd.DataFrame(items);pa=pd.DataFrame(pairs)
    it.to_csv(P/'items.csv',index=False);pa.to_csv(P/'pairs.csv',index=False)
    with (P/'pair_evidence.jsonl').open('w',encoding='utf-8') as f:
        for row in details:f.write(json.dumps(row,ensure_ascii=False)+'\n')
    case_specs=[('C1','10420','2021-01-19','mojarijeka.hr',''),('C2','58492','2021-01-09','splitv-portal.com',''),
                ('C3','4553','2021-01-15','hkm.hr','pokore'),('C4','42673','2024-02-08','youtube.com','argumenti'),
                ('C5','32947','2021-01-08','ks.hr',''),('C6','8013','2021-01-21','gastronaut.hr',''),
                ('C7','14665','2021-05-11','matica.hr','sinju')]
    cases=[]
    for case,oid,date,host,needle in case_specs:
        matches=[x for x in details if x['association_id']==oid and x['date']==date and x['domain']==host and needle in norm(x['title'] or '')]
        assert matches,('Missing inspected case',case)
        chosen=max(matches,key=lambda x:len(x['full_text'] or ''))
        cases.append({'case_id':case,'coder_type':'AI_purposive_reading','human_validation':False,**chosen})
    with (P/'inspected_cases.jsonl').open('w',encoding='utf-8') as f:
        for row in cases:f.write(json.dumps(row,ensure_ascii=False)+'\n')
    screen_rows=[]
    for org,r in reg.items():
        s=pa[pa.association_id==org];w=s[s.platform=='web'];counts=s.groupby('month').size()
        screen_rows.append({'association_id':org,'name':r['name'],'county':r['county'],'sampling_stratum':r['sampling_stratum'],
            'search_status':'searched' if org in rule_ids else 'held_for_identity',
            'candidate_items':len(s),'candidate_url_keys':s.url_key.nunique(),'candidate_years':s.year.nunique(),
            'candidate_months':s.month.nunique(),'web_items':len(w),'web_domains':w.domain[w.domain!=''].nunique(),
            'title_or_lead_items':int(s.title_or_lead.sum()),'restricted_candidates':int(s.restricted_candidate.sum()),
            'exact_text_groups':s.story_hash.nunique(),'peak_month':counts.idxmax() if len(counts) else '',
            'peak_month_items':int(counts.max()) if len(counts) else 0,
            'candidate_status':'candidates' if len(s) else ('searched_zero' if org in rule_ids else 'not_searched'),
            'historical_eligibility':'not_reconstructed','identity_state':'unresolved'})
    orgs=pd.DataFrame(screen_rows);orgs.to_csv(P/'organisation_landscape.csv',index=False)
    # The disclosure-safe distribution intentionally omits named organisation rankings.
    status=orgs.groupby('candidate_status').size().rename('organisations').reset_index();status.to_csv(T/'funnel.csv',index=False)
    county=orgs.groupby('county').agg(registered=('association_id','size'),searched=('search_status',lambda s:sum(s=='searched')),
        candidate_names=('candidate_items',lambda s:sum(s>0)),candidate_pairs=('candidate_items','sum'),
        restricted_pairs=('restricted_candidates','sum'),title_lead_pairs=('title_or_lead_items','sum')).reset_index()
    county['candidate_names_pct_registered']=100*county.candidate_names/county.registered
    county.to_csv(T/'county_landscape.csv',index=False)
    coverage=pd.read_csv(T/'monthly_coverage.csv');coverage['year']=coverage.month.str[:4].astype(int)
    days=pd.read_csv(T/'daily_coverage.csv');days['year']=days.date.str[:4].astype(int)
    monthly=[]
    for _,r in coverage.iterrows():
        s=it[(it.month==r.month)&(it.platform==r.platform)];ps=pa[(pa.month==r.month)&(pa.platform==r.platform)]
        monthly.append({**r.to_dict(),'raw_candidate_records':raw_month[(r.month,r.platform)],'candidate_items':len(s),
            'candidate_names':ps.association_id.nunique(),'candidate_pairs':len(ps),
            'restricted_pairs':int(ps.restricted_candidate.sum()),'title_lead_pairs':int(ps.title_or_lead.sum()),
            'raw_candidate_records_per_10000':10000*raw_month[(r.month,r.platform)]/r.rows})
    monthly=pd.DataFrame(monthly);monthly.to_csv(T/'monthly_landscape.csv',index=False)
    annual=[]
    for y,s in coverage.groupby('year'):
        v=it[it.year==y];q=pa[pa.year==y];dy=days[days.year==y]
        annual.append({'year':y,'monitored_records':int(s.rows.sum()),'observed_days':dy.date.nunique(),
            'raw_candidate_records':sum(n for (m,p),n in raw_month.items() if m.startswith(str(y))),
            'candidate_items':len(v),'candidate_pairs':len(q),'candidate_names':q.association_id.nunique(),
            'restricted_pairs':int(q.restricted_candidate.sum()),'title_lead_pairs':int(q.title_or_lead.sum()),
            'web_items':int((v.platform=='web').sum()),'web_domains':v.loc[v.platform=='web','domain'].nunique(),
            'i_filtered_pct':100*s.i_filtered_rows.sum()/s.rows.sum()})
    annual=pd.DataFrame(annual);annual['raw_candidates_per_10000']=10000*annual.raw_candidate_records/annual.monitored_records
    annual.to_csv(T/'annual_landscape.csv',index=False)
    comparable=[]
    for y in sorted(annual.year):
        dy=days[(days.year==y)&(days.date.str[5:]<='09-10')]
        q=pa[(pa.year==y)&(pa.date.str[5:]<='09-10')];v=it[(it.year==y)&(it.date.str[5:]<='09-10')]
        rc=sum(1 for r in raw if r['DATE'].startswith(str(y)) and r['DATE'][5:]<='09-10')
        comparable.append({'year':int(y),'start':f'{y}-01-01','end':f'{y}-09-10','days':dy.date.nunique(),
            'monitored_records':int(dy.rows.sum()),'raw_candidates':rc,'candidate_items':len(v),'candidate_names':q.association_id.nunique(),
            'raw_candidates_per_10000':10000*rc/dy.rows.sum()})
    write_csv(T/'same_calendar_window.csv',comparable)
    platform=[]
    for p,s in coverage.groupby('platform'):
        v=it[it.platform==p];q=pa[pa.platform==p]
        platform.append({'platform':p,'monitored_records':int(s.rows.sum()),'raw_candidates':raw_platform[p],
            'candidate_items':len(v),'candidate_names':q.association_id.nunique(),'title_lead_pairs':int(q.title_or_lead.sum()),
            'body_available_pct':100*s.with_body.sum()/s.rows.sum(),'candidate_body_available_pct':100*(v.body_chars>0).mean() if len(v) else None})
    pd.DataFrame(platform).to_csv(T/'platform_landscape.csv',index=False)
    pa.groupby(['association_id','year']).size().rename('candidate_items').reset_index().to_csv(P/'organisation_year.csv',index=False)
    observed=pa.groupby(['association_id','year']).size().to_dict()
    complete_year=[]
    for oid,r in reg.items():
        for y in range(2021,2027):
            complete_year.append({'association_id':oid,'name':r['name'],'county':r['county'],'year':y,
                'candidate_items':observed.get((oid,y),0) if oid in rule_ids else None,
                'search_status':'searched' if oid in rule_ids else 'held_for_identity',
                'historical_eligibility':'not_reconstructed','period':'through_September_10' if y==2026 else 'full_calendar_year'})
    write_csv(P/'organisation_year_complete.csv',complete_year)
    pa.groupby(['association_id','month']).size().rename('candidate_items').reset_index().to_csv(P/'organisation_month.csv',index=False)
    pa.groupby(['association_id','domain']).size().rename('pairs').reset_index().to_csv(P/'organisation_domains.csv',index=False)
    # Comparable observed web-domain panel: at least 100 monitored records in each of all 69 months.
    source=pd.read_csv(P/'monthly_web_sources.csv').fillna('')
    good=source[(source.rows>=100)&(source.domain!='')].groupby('domain').month.nunique()
    panel=set(good[good==69].index)
    pan=[]
    for m,s in source[source.domain.isin(panel)].groupby('month'):
        num=sum(raw_domains[(m,d)] for d in panel)
        pan.append({'month':m,'year':int(m[:4]),'panel_domains':len(panel),'monitored_web_records':int(s.rows.sum()),
                    'raw_candidate_records':num,'raw_candidates_per_10000':10000*num/s.rows.sum()})
    pd.DataFrame(pan).to_csv(T/'common_domain_panel.csv',index=False)
    write_csv(T/'common_domain_members.csv',[{'domain':d} for d in sorted(panel)])
    web=it[it.platform=='web'];sources=web.groupby('domain').agg(candidate_items=('item_key','size'),months=('month','nunique')).reset_index()
    sources=sources.merge(pa[pa.platform=='web'].groupby('domain').association_id.nunique().rename('candidate_names'),on='domain')
    sources.sort_values('candidate_items',ascending=False).to_csv(T/'web_domain_landscape.csv',index=False)
    scenarios=[]
    for label,s in [('all_candidate_pairs',pa),('web_candidate_pairs',pa[pa.platform=='web']),
                    ('title_or_lead',pa[pa.title_or_lead]),('restricted_screen',pa[pa.restricted_candidate]),
                    ('restricted_web',pa[pa.restricted_candidate&(pa.platform=='web')]),
                    ('url_only_collapse',pa.drop_duplicates(['association_id','url_key'])),
                    ('exact_text_collapse',pa.drop_duplicates(['association_id','story_hash']))]:
        ct=s.groupby('association_id').size().reindex(sorted(rule_ids),fill_value=0).sort_values().to_numpy();n=len(ct)
        scenarios.append({'scenario':label,'pairs':len(s),'items':s.item_key.nunique(),'names':s.association_id.nunique(),
            'top10_share_pct':100*ct[-10:].sum()/ct.sum(),'gini_searched_names':float((2*np.arange(1,n+1)-n-1).dot(ct)/(n*ct.sum()))})
    pd.DataFrame(scenarios).to_csv(T/'sensitivity.csv',index=False)
    persistence=orgs[orgs.candidate_items>0].copy()
    persistence['months_band']=pd.cut(persistence.candidate_months,[0,1,3,12,36,69],labels=['1','2-3','4-12','13-36','37-69'])
    persistence.groupby('months_band',observed=False).size().rename('names').reset_index().to_csv(T/'persistence.csv',index=False)
    # Audit reused URL keys and text disagreement, without assuming these are distinct articles.
    repeated=it.groupby('url_key').agg(items=('item_key','size'),dates=('date','nunique'),texts=('story_hash','nunique'))
    summary={'raw_candidates':len(raw),'exact_unique_records':len(unique),'candidate_items':len(it),'pairs':len(pa),
        'candidate_names':pa.association_id.nunique(),'searched_names':len(rule_ids),'held_names':len(reg)-len(rule_ids),
        'searched_zero':int((orgs.candidate_status=='searched_zero').sum()),'url_only_items':it.url_key.nunique(),
        'exact_text_groups':it.story_hash.nunique(),'recurring_url_keys':int((repeated.dates>1).sum()),
        'recurring_url_keys_multiple_texts':int(((repeated.dates>1)&(repeated.texts>1)).sum()),
        'snippet_only_pairs':int(pa.snippet_only.sum()),'alias_only_pairs':int(pa.alias_only.sum()),
        'restricted_pairs':int(pa.restricted_candidate.sum()),'title_lead_pairs':int(pa.title_or_lead.sum()),
        'own_domain_pairs':int((pa.relationship=='current_documented_own_domain').sum()),
        'common_panel_domains':len(panel),'known_risk_pairs':int((pa.known_risk!='').sum()),
        'body_available_items':int((it.body_chars>0).sum()),'median_candidate_months':float(persistence.candidate_months.median()),
        'source_unchanged':audit['source_unchanged'],'historical_eligibility_reconstructed':False,'human_validated_pairs':0}
    dump_json(T/'summary.json',summary)
    # Deterministic AI development reading queue: top-count, documented and ordinary cases across years.
    focal=set(OWN)|{'10420','14665'}|set(orgs.nlargest(12,'candidate_items').association_id)
    review=[]
    detail_by={(x['association_id'],x['item_key']):x for x in details}
    for org in sorted(focal):
        for y in sorted(it.year.unique()):
            eligible=[x for x in details if x['association_id']==org and x['year']==y]
            chosen=sorted(eligible,key=lambda x:(not x['title_hit'],not x['lead_hit'],digest(x['item_key'])))[:2]
            for x in chosen:review.append({k:x[k] for k in ['association_id','item_key','date','platform','domain','title','url','context','known_risk']})
    write_csv(P/'ai_reading_queue.csv',review)
    # Fresh blank queue at the exact-text cluster level, excluding all development clusters.
    dev_keys={x['item_key'] for x in review}
    dev_keys|={x['item_key'] for x in cases}
    legacy=json.loads((PRIVATE/'ai_development_labels.json').read_text(encoding='utf-8'))
    legacy_urls={screen.canonical_url(x['url']) for x in legacy}
    legacy_urls|={screen.canonical_url(x['url']) for x in read_csv(PRIVATE/'human_review_queue.csv') if x['url']}
    dev_keys|={x['item_key'] for x in details if screen.canonical_url(x['url'] or '') in legacy_urls}
    dev_stories=set(pa.loc[pa.item_key.isin(dev_keys),'story_hash'])
    ev=pa[~pa.story_hash.isin(dev_stories)].sort_values(['date','item_key']).drop_duplicates('story_hash').copy()
    ev['stratum']=ev.year.astype(str)+'|'+np.where(ev.platform=='web','web','other')
    held=[]
    for st,s in ev.groupby('stratum'):
        s=s.copy();s['sortkey']=s.item_key.map(lambda k:digest('holdout-v1|'+k));n=min(40,len(s))
        for _,r in s.sort_values('sortkey').head(n).iterrows():
            for _,pair in pa[pa.story_hash==r.story_hash].drop_duplicates(['association_id','story_hash']).iterrows():
                held.append({**pair.to_dict(),'stratum':st,'inclusion_probability':n/len(s),'sampling_unit':'exact_text_cluster',
                 'reviewer_1_identity':'','reviewer_2_identity':'','reviewer_1_relevance':'','reviewer_2_relevance':'','adjudication':''})
    write_csv(P/'future_review_queue.csv',held)
    dump_json(T/'review_queue_design.json',{'sample_pairs':len(held),'sample_exact_text_clusters':len({r['story_hash'] for r in held}),
        'excluded_development_clusters':len(dev_stories),'draw':'40 clusters per first-observed year x web/other stratum, SHA256 seeded ordering',
        'scope':'Preparation only. Near-copy leakage and full route-risk stratification still need assessment before independent evaluation.',
        'human_annotations_completed':0})
    # Searchable local all-frame directory without vendor text or article URLs.
    records=orgs.to_dict('records');payload=json.dumps(records,ensure_ascii=False).replace('</','<\\/')
    page='''<!doctype html><html lang="en"><meta charset="utf-8"><title>Organisation media landscape</title>
    <style>body{font:15px system-ui;max-width:1500px;margin:35px auto;color:#203844}input,select{padding:10px;margin:8px}table{border-collapse:collapse;width:100%}th,td{padding:9px;border-bottom:1px solid #ddd;text-align:left}th{position:sticky;top:0;background:#edf3f3}p{max-width:1000px}.note{background:#fff0d8;padding:15px}</style>
    <h1>Spirituality-related associations: media search landscape</h1><p>All 1,325 register entries; 1 January 2021 to 10 September 2026. Counts are unresolved name-search candidates. Web domains are not verified editorial outlets. Historical eligibility is not reconstructed. A search zero is not proof of no coverage.</p>
    <p class="note">Use this internal directory to choose cases for review. It is not a verified visibility ranking. See the analytical report for collection breaks and sensitivity checks.</p>
    <input id="q" placeholder="Search name or county" size="45"><select id="s"><option value="">All search states</option><option>candidates</option><option>searched_zero</option><option>not_searched</option></select><span id="count"></span>
    <table><thead><tr><th>Name / register ID</th><th>County</th><th>Search state</th><th>Candidate items</th><th>Title / lead</th><th>Restricted screen</th><th>Months</th><th>Web domains</th></tr></thead><tbody id="rows"></tbody></table><script>const data=PAYLOAD;const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));function show(){const d=data.filter(r=>(r.name+' '+r.county).toLocaleLowerCase().includes(q.value.toLocaleLowerCase())&&(!s.value||r.candidate_status===s.value)).sort((a,b)=>a.name.localeCompare(b.name,'hr'));document.getElementById('count').textContent=d.length+' organisations';document.getElementById('rows').innerHTML=d.map(r=>'<tr><td>'+esc(r.name)+'<br><small>'+r.association_id+'</small></td>'+[r.county,r.candidate_status,r.candidate_items,r.title_or_lead_items,r.restricted_candidates,r.candidate_months,r.web_domains].map(v=>'<td>'+esc(v)+'</td>').join('')+'</tr>').join('')}q.oninput=show;s.onchange=show;show();</script></html>'''.replace('PAYLOAD',payload)
    (P/'organisation_directory.html').write_text(page,encoding='utf-8')
    print(json.dumps(summary,indent=2),flush=True)
if __name__=='__main__':main()
