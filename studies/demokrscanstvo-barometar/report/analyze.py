"""Reproducible report analysis. Row-level data never leave the private workdir."""
from pathlib import Path
import sys, json, re, hashlib, csv, math, unicodedata, argparse, os
from collections import Counter, defaultdict
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import adjusted_rand_score
from scipy.optimize import linear_sum_assignment

ROOT=Path(__file__).resolve().parents[3]
sys.path.insert(0,str(ROOT/'studies/demokrscanstvo-barometar'))
from thematic_build import load_inputs,fit,clean_terms,topic_terms
BASE=ROOT/'data/barometar/demokrscanstvo-multiplatform/v1'
THEMES=ROOT/'data/barometar/demokrscanstvo-themes/v1'
WORK=Path(os.environ.get('DIGIKAT_BAROMETAR_WORKDIR','C:/Users/lsikic/Luka C/DigiKat_barometar_work'))
PRIVATE=WORK/'analytical-report-v1'
OUT=ROOT/'output/demokrscanstvo-analysis/v1'
SEED=20260919

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def read(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def lines(p):return [json.loads(s) for s in Path(p).read_text(encoding='utf-8-sig').splitlines() if s]
def write(p,obj):
    Path(p).parent.mkdir(parents=True,exist_ok=True)
    Path(p).write_text(json.dumps(obj,ensure_ascii=False,indent=2,allow_nan=False)+'\n',encoding='utf-8')
def csvread(p):
    with Path(p).open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))
def table(name,rows):
    assert rows,name
    with (OUT/(name+'.csv')).open('w',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');w.writeheader();w.writerows(rows)
def canon(s):return re.sub(r'\s+',' ',unicodedata.normalize('NFC',s).casefold()).strip()
def textgroup(d):return hashlib.sha256((canon(d['title'])+'\n'+canon(d['stored_body'])).encode()).hexdigest()
def topid(i):return f't{i+1:02d}' if i>=0 else 'unassigned'
def model_stage():
    OUT.mkdir(parents=True,exist_ok=True);PRIVATE.mkdir(parents=True,exist_ok=True)
    checks=[]
    for folder in (BASE,THEMES):
        for name,h in read(folder/'manifest.json')['files'].items():
            assert sha(folder/name)==h,(folder,name)
            checks.append({'check':folder.parent.name+'/'+name,'status':'PASS','detail':h})
    folder,records,ids,tokens,identity=load_inputs(WORK/'multiplatform-v1')
    docs=lines(PRIVATE/'documents.jsonl');D={d['record_key']:d for d in docs}
    assert len(D)==len(docs)==len(records)==2306
    A=read(folder/'assignments.json'); old={d['record_key']:d['topic'] for d in A}
    for r in records:
        d=D[r['record_key']]
        assert d['context_id']==r['context_id'] and d['context']==r['context']
        for col in ('platform','month','text_basis'):assert d[col]==r[col]
        d['topic']=topid(old[d['record_key']]);d['group']=textgroup(d)
        d['a1']='A1' in d['route_set'].split(';')
        d['period']='2021-01 / 2024-03' if d['day']<'2024-04-01' else '2024-04 / 2026-09-10'
        d['words']=len(d['stored_body'].split());d['context_words']=len(d['context'].split())
    # Complete field text plus title defines exact groups. Short bodies retain title.
    groups=defaultdict(list)
    for d in docs:groups[d['group']].append(d)
    reps=[sorted(v,key=lambda d:(d['text_basis']!='full_text',-len(d['stored_body']),d['record_key']))[0] for v in groups.values()]
    reps.sort(key=lambda d:d['record_key'])
    cgroups=defaultdict(list)
    for d in docs:cgroups[d['context_id']].append(d)
    creps=[sorted(v,key=lambda d:d['record_key'])[0] for v in cgroups.values()]
    write(PRIVATE/'grouped-documents.json',docs)
    write(PRIVATE/'representatives.json',[d['record_key'] for d in reps])
    vector=TfidfVectorizer(tokenizer=str.split,preprocessor=None,token_pattern=None,lowercase=False,min_df=5,max_df=.85,max_features=6000,sublinear_tf=True,norm='l2')
    X=vector.fit_transform(' '.join(tokens[x]) for x in ids)
    m,W,H=fit(X,10);labels=W.argmax(axis=1);nz=np.asarray(X.getnnz(axis=1))>0;labels[~nz]=-1
    index={key:i for i,key in enumerate(ids)}
    assert all(labels[index[d['context_id']]]==old[d['record_key']] for d in docs)
    checks.append({'check':'Exact model assignment reproduction','status':'PASS','detail':'2306 / 2306; 1731 fit contexts; 1372 features'})
    sensitivities=[]; alternatives=[]
    terms=topic_terms(H,vector.get_feature_names_out())
    for k,seed,init in [(8,SEED,'nndsvda'),(12,SEED,'nndsvda'),(10,23,'random'),(10,71,'random'),(10,113,'random')]:
        alt,V,G=fit(X,k,seed,init);y=V.argmax(axis=1);y[~nz]=-1
        ari=float(adjusted_rand_score(labels[nz],y[nz]));cos=H@G.T
        a,b=linear_sum_assignment(-cos)
        sensitivities.append({'comparison':f'k={k}; seed={seed}; init={init}','contexts':int(nz.sum()),'ari':ari,'iterations':int(alt.n_iter_),
            'mean_matched_component_cosine':float(np.mean(cos[a,b]))})
        alternatives.append({'k':k,'seed':seed,'terms':topic_terms(G,vector.get_feature_names_out()),'mapping':[{'topic':topid(int(i)),'alternative':int(j)+1,'cosine':float(cos[i,j])} for i,j in zip(a,b)]})
    table('model_stability',sensitivities);write(OUT/'alternative_topic_terms.json',alternatives)
    np.savez_compressed(PRIVATE/'model.npz',H=H,W=W,ids=np.array(ids,dtype=str),vocabulary=np.array(vector.get_feature_names_out(),dtype=str),idf=vector.idf_)
    labels_public=read(THEMES/'summary.json')['topics'];td={x['id']:x for x in labels_public}
    # Counts and scope sensitivity use the frozen model, never refit per subgroup.
    subsets={'publications':docs,'exact_text_groups':reps,'distinct_contexts':creps,'a1': [d for d in docs if d['a1']],
             'additional_routes':[d for d in docs if not d['a1']],'stored_body':[d for d in docs if d['text_basis']=='full_text'],
             'web':[d for d in docs if d['platform']=='web']}
    topic_rows=[]
    for name,selected in subsets.items():
        counts=Counter(d['topic'] for d in selected)
        for t in td:
            topic_rows.append({'scope':name,'topic':t,'label':td[t]['label'],'n':counts[t],'denominator':len(selected),'percent':100*counts[t]/len(selected)})
    table('topic_sensitivity',topic_rows)
    monthly=csvread(BASE/'monthly.csv')
    for row in monthly:
        for k in row:
            if k not in ('platform','month','per_10000','full_text_per_10000'):row[k]=int(row[k])
    own=Counter((d['platform'],d['month']) for d in docs)
    for r in monthly:assert own[r['platform'],r['month']]==r['matching_records']
    assert sum(r['eligible_records'] for r in monthly)==41397670
    assert sum(d['a1'] for d in docs)==2211
    checks.append({'check':'Keys / contexts / routes / platform-month counts','status':'PASS','detail':'one-to-one joins; all 966 platform-month cells reconcile'})
    timeline=[]
    for month in sorted({r['month'] for r in monthly}):
        rows=[r for r in monthly if r['month']==month]; ds=[d for d in docs if d['month']==month]
        E=sum(r['eligible_records'] for r in rows);n=len(ds)
        timeline.append({'month':month,'publications':n,'eligible':E,'per_10000':10000*n/E if E else '',
          'groups_with_presence':len({d['group'] for d in ds}),'distinct_contexts':len({d['context_id'] for d in ds}),
          'web_n':sum(d['platform']=='web' for d in ds),'web_eligible':sum(r['eligible_records'] for r in rows if r['platform']=='web'),
          'period':'before' if month<'2024-04' else 'after'})
    table('timeline',timeline)
    annual=[]
    for year in sorted({r['month'][:4] for r in monthly}):
        rs=[r for r in monthly if r['month'].startswith(year)]
        for scope in ['all','web']:
            selected=rs if scope=='all' else [r for r in rs if r['platform']=='web']
            E=sum(r['eligible_records'] for r in selected);n=sum(r['matching_records'] for r in selected)
            annual.append({'year':year,'scope':scope,'n':n,'eligible':E,'per_10000':10000*n/E,'partial':year=='2026','break_year':year=='2024'})
    table('annual',annual)
    pt=[]
    for p in read(BASE/'summary.json')['platforms']:
        rs=[r for r in monthly if r['platform']==p['platform'] and r['month'].startswith('2025')]
        ds=[d for d in docs if d['platform']==p['platform']]
        pt.append({'platform':p['platform'],'label':read(BASE/'summary.json')['platform_labels'][p['platform']],
          'n':len(ds),'percent':100*len(ds)/len(docs),'exact_groups':len({d['group'] for d in ds}),'eligible':p['eligible_records'],
          'per_10000':10000*len(ds)/p['eligible_records'],'n_2025':sum(r['matching_records'] for r in rs),
          'eligible_2025':sum(r['eligible_records'] for r in rs),'days_2025':sum(r['observed_days'] for r in rs),
          'months_2025':sum(r['eligible_records']>0 for r in rs),'median_body_words':float(np.median([d['words'] for d in ds])) if ds else '',
          'first_day':p['first_day'],'last_day':p['last_day']})
    table('platforms',pt)
    scope_rows=[]
    for kind in ['year','period','platform','platform_2025']:
        categories=sorted(set(d['day'][:4] if kind=='year' else d['period'] if kind=='period' else d['platform'] for d in docs))
        for cat in categories:
            ds=[d for d in docs if (d['day'][:4] if kind=='year' else d['period'] if kind=='period' else d['platform'])==cat and (kind!='platform_2025' or d['day'].startswith('2025'))]
            if not ds:continue
            count=Counter(d['topic'] for d in ds)
            for t in td:scope_rows.append({'scope':kind,'category':cat,'topic':t,'n':count[t],'denominator':len(ds),'percent':100*count[t]/len(ds)})
    table('topic_profiles',scope_rows)
    dist=Counter(len(v) for v in groups.values())
    table('exact_group_sizes',[{'size':k,'groups':v,'publications':k*v} for k,v in sorted(dist.items())])
    gtop=sorted(groups.values(),key=lambda v:(-len(v),v[0]['group']))
    write(PRIVATE/'largest_groups.json',[{'size':len(v),'months':dict(Counter(d['month'] for d in v)),'topics':dict(Counter(d['topic'] for d in v)),
      'context':v[0]['context'],'representative':v[0]['record_key']} for v in gtop[:25]])
    # Fixed review sample: strongest 5 + least separated 5 per topic, one exact-text group each.
    reviewed=[];used=set()
    for t in range(10):
        candidates=[d for d in reps if d['topic']==topid(t)]
        for d in candidates:
            w=W[index[d['context_id']]];s=np.sort(w)
            d['_strength']=float(w[t]);d['_margin']=float((s[-1]-s[-2])/s[-1]) if s[-1]>0 else 0
        for label,sortkey in [('typical',lambda d:(-d['_strength'],d['record_key'])),('boundary',lambda d:(d['_margin'],d['record_key']))]:
            selected=[d for d in sorted(candidates,key=sortkey) if d['group'] not in used][:5]
            for d in selected:reviewed.append({'review_kind':label,**d});used.add(d['group'])
    rng=np.random.default_rng(SEED)
    remaining=[d for d in reps if d['group'] not in used]
    # Forty deliberately enriched cases: non-A1, principle words, sparse platforms, then random fill.
    conditions=[lambda d:not d['a1'],lambda d:bool(re.search('solidarn|supsidij|dostojanst|opć.{0,3} dobr|tržišn|socijaln',d['context'],re.I)),lambda d:d['platform'] not in ('web','facebook','twitter')]
    for condition in conditions:
        candidates=[d for d in remaining if d['group'] not in used and condition(d)]
        for j in rng.permutation(len(candidates))[:13]:
            d=candidates[j];reviewed.append({'review_kind':'enriched',**d});used.add(d['group'])
    for d in sorted(remaining,key=lambda d:hashlib.sha256((str(SEED)+d['group']).encode()).hexdigest()):
        if len(reviewed)>=140:break
        if d['group'] not in used:reviewed.append({'review_kind':'fill',**d});used.add(d['group'])
    assert len(reviewed)==140
    write(PRIVATE/'development_review.json',reviewed)
    write(PRIVATE/'long_text_ids.json',[d['record_key'] for d in reviewed])
    # Publish only aggregates, never IDs or text.
    summary={'records':len(docs),'exact_text_groups':len(groups),'distinct_contexts':len(cgroups),
       'extra_exact_copies':len(docs)-len(groups),'publications_in_repeated_groups':sum(len(v) for v in groups.values() if len(v)>1),
       'max_group_size':max(map(len,groups.values())),'cross_topic_exact_groups':sum(len({d['topic'] for d in v})>1 for v in groups.values()),
       'a1':sum(d['a1'] for d in docs),'stored_body':sum(d['text_basis']=='full_text' for d in docs),
       'eligible':41397670,'pooled_per_10000':2306/41397670*10000,'short_contexts_le20':sum(d['context_words']<=20 for d in docs),
       'median_body_words':float(np.median([d['words'] for d in docs])),
       'human_validation_complete':False,'interpretive_prevalence_released':False,
       'input_manifests':{str(p.relative_to(ROOT)):sha(p) for p in (BASE/'manifest.json',THEMES/'manifest.json')},
       'seed':SEED,'topic_fit_reproduced':True,'model_features':X.shape[1],
       'development_size':len(reviewed),'group_definition':'exact casefolded NFC whitespace-normalized stored title + title-stripped stored body; punctuation retained',
       'created':'2026-09-19'}
    write(OUT/'summary.json',summary);table('checks',checks)
    print(json.dumps(summary,ensure_ascii=False,indent=2))

if __name__=='__main__':model_stage()
