"""Independent arithmetic/provenance audit, without importing analysis functions."""
from pathlib import Path
import os,sys,json,csv,hashlib,re,math,unicodedata,platform,shutil,argparse
from collections import Counter,defaultdict
from concurrent.futures import ThreadPoolExecutor
import importlib.metadata as metadata
import duckdb

ROOT=Path(__file__).resolve().parents[3];CODE=Path(__file__).resolve().parent
WORK=Path(os.environ.get('DIGIKAT_BAROMETAR_WORKDIR','C:/Users/lsikic/Luka C/DigiKat_barometar_work'))
PRIVATE=WORK/'analytical-report-v1';OUT=ROOT/'output/demokrscanstvo-analysis/v1';PDF=ROOT/'output/pdf/demokrscanstvo-analiticki-izvjestaj.pdf'
BASE=ROOT/'data/barometar/demokrscanstvo-multiplatform/v1';THEME=ROOT/'data/barometar/demokrscanstvo-themes/v1'
def sha(p):
    h=hashlib.sha256()
    with Path(p).open('rb') as stream:
        for block in iter(lambda:stream.read(8*1024*1024),b''):h.update(block)
    return h.hexdigest()
def j(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def jl(p):return [json.loads(x) for x in Path(p).read_text(encoding='utf-8-sig').splitlines() if x]
def csvr(p):
    with Path(p).open(encoding='utf-8-sig',newline='') as stream:return list(csv.DictReader(stream))
def same(a,b):assert math.isclose(float(a),float(b),rel_tol=1e-11,abs_tol=1e-11),(a,b)
checks=[]
def passcheck(name,detail):checks.append({'check':name,'status':'PASS','detail':detail})
for folder in [BASE,THEME]:
    for name,digest in j(folder/'manifest.json')['files'].items():assert sha(folder/name)==digest
passcheck('Public release manifests','Every listed input artifact matches its SHA256')
assert sha(ROOT/'output/pdf/demokrscanstvo-plan-analize.pdf')=='a179e03737a4a9eb2107246727f948bc6890e7cb84b991ed066e32fb1d2cef60'
passcheck('Original plan preserved','PDF is byte-identical to the supplied plan')
active=j(WORK/'multiplatform-v1/active.json');classification=j(Path(active['folder'])/'classification.json')
thematic=j(WORK/'multiplatform-v1/thematic-active.json');folder=Path(thematic['folder'])
paths=sorted([p for p in Path(classification['folder']).iterdir() if p.is_file()]+list((Path(active['folder'])/'candidates').glob('*.parquet')))
print('Hashing',len(paths),'private checkpoint files;',round(sum(p.stat().st_size for p in paths)/1e9,2),'GB',flush=True)
with ThreadPoolExecutor(max_workers=4) as pool:hashes=list(pool.map(sha,paths))
assert Counter(hashes)==Counter(thematic['identity']['inputs'])
passcheck('Private checkpoint integrity',str(len(paths))+' current file hashes match the frozen thematic input multiset')
cache=jl(folder/'contexts.jsonl');assign={r['record_key']:r['topic'] for r in j(folder/'assignments.json')}
docs=j(PRIVATE/'grouped-documents.json');D={d['record_key']:d for d in docs};S=j(OUT/'summary.json')
assert len(D)==len(docs)==len(cache)==2306
assert set(D)==set(assign)=={d['record_key'] for d in cache}
for d in cache:
    for key in ['context_id','context','month','platform','text_basis']:assert d[key]==D[d['record_key']][key]
    t=assign[d['record_key']];assert D[d['record_key']]['topic']==(f't{t+1:02d}' if t>=0 else 'unassigned')
con=duckdb.connect();original=con.execute("SELECT record_key, route_set FROM read_parquet(?) WHERE regexp_matches(route_set,'(^|;)(A1|B|C)(;|$)')",[str(Path(classification['folder'])/'*.parquet')]).fetchall();con.close()
assert len(original)==2306 and len(dict(original))==2306
for k,route in original:assert D[k]['route_set']==route
passcheck('One-to-one source reconciliation','2306 original selected keys, routes, stored contexts and topic assignments agree')

def norm(x):return ' '.join(unicodedata.normalize('NFC',x).casefold().split())
groups=defaultdict(list)
for d in docs:
    key=hashlib.sha256((norm(d['title'])+'\n'+norm(d['stored_body'])).encode()).hexdigest()
    assert key==d['group'];groups[key].append(d)
reps=[min(v,key=lambda d:(d['text_basis']!='full_text',-len(d['stored_body']),d['record_key'])) for v in groups.values()]
assert len(groups)==S['exact_text_groups']==2253
unique={}
for d in sorted(docs,key=lambda d:d['record_key']):unique.setdefault(d['context_id'],d)
scopes={'publications':docs,'exact_text_groups':reps,'distinct_contexts':list(unique.values()),'a1':[d for d in docs if 'A1' in d['route_set'].split(';')],
 'additional_routes':[d for d in docs if 'A1' not in d['route_set'].split(';')],'stored_body':[d for d in docs if d['text_basis']=='full_text'],'web':[d for d in docs if d['platform']=='web']}
for r in csvr(OUT/'topic_sensitivity.csv'):
    selected=scopes[r['scope']];expected=sum(d['topic']==r['topic'] for d in selected)
    assert int(r['n'])==expected and int(r['denominator'])==len(selected);same(r['percent'],100*expected/len(selected))
passcheck('Topic counts and denominators','All seven scope tables independently rebuilt from record assignments and exact-text keys')
for r in csvr(OUT/'topic_profiles.csv'):
    kind=r['scope'];cat=r['category']
    def match(d):
        if kind=='year':return d['day'][:4]==cat
        if kind=='period':return ('2021-01 / 2024-03' if d['day']<'2024-04-01' else '2024-04 / 2026-09-10')==cat
        return d['platform']==cat and (kind!='platform_2025' or d['day'].startswith('2025'))
    selected=[d for d in docs if match(d)]
    assert int(r['denominator'])==len(selected);cnt=sum(d['topic']==r['topic'] for d in selected);assert int(r['n'])==cnt;same(r['percent'],100*cnt/len(selected))
passcheck('Temporal/platform topic tables','All topic-by-year/regime/platform and 2025 cells independently recomputed')
monthly=csvr(BASE/'monthly.csv');total=sum(int(r['eligible_records']) for r in monthly)
assert total==S['eligible']==41397670;same(S['pooled_per_10000'],10000*len(docs)/total)
assert sum(int(r['matching_records']) for r in monthly)==len(docs)
for r in csvr(OUT/'timeline.csv'):
    ds=[d for d in docs if d['month']==r['month']];rs=[x for x in monthly if x['month']==r['month']]
    denom=sum(int(x['eligible_records']) for x in rs);assert len(ds)==int(r['publications'])
    assert denom==int(r['eligible']);same(r['per_10000'],10000*len(ds)/denom)
    assert len({d['group'] for d in ds})==int(r['groups_with_presence']);assert len({d['context_id'] for d in ds})==int(r['distinct_contexts'])
for r in csvr(OUT/'platforms.csv'):
    rs=[x for x in monthly if x['platform']==r['platform']];ds=[d for d in docs if d['platform']==r['platform']]
    assert len(ds)==int(r['n']);same(r['percent'],100*len(ds)/len(docs))
    for outcol,incol in [('n_2025','matching_records'),('eligible_2025','eligible_records'),('days_2025','observed_days')]:assert int(r[outcol])==sum(int(x[incol]) for x in rs if x['month'].startswith('2025'))
passcheck('Rates and coverage','Monthly rate ratios, platform denominators and 2025 coverage reconcile to original monthly release')
for r in csvr(OUT/'annual.csv'):
    rs=[x for x in monthly if x['month'].startswith(r['year']) and (r['scope']=='all' or x['platform']=='web')]
    numerator=sum(int(x['matching_records']) for x in rs);denominator=sum(int(x['eligible_records']) for x in rs)
    assert int(r['n'])==numerator and int(r['eligible'])==denominator;same(r['per_10000'],10000*numerator/denominator)
passcheck('Annual aggregates','All annual rates are ratios of source sums; no unweighted rate averaging')
# Recalculate shingle similarities inside each reported near-copy group.
shingles={};word_lengths={};REP={d['record_key']:d for d in reps}
for key,d in REP.items():
    words=re.findall(r'[^\W_]+',norm(d['title']+' '+d['stored_body']));word_lengths[key]=len(words)
    shingles[key]={tuple(words[i:i+5]) for i in range(max(0,len(words)-4))}
membership=j(PRIVATE/'near_copy_memberships.json')
for cutoff,mapping in membership.items():
    assert set(mapping)==set(REP);gg=defaultdict(list)
    for key,g in mapping.items():gg[g].append(key)
    for members in gg.values():
        for i,a in enumerate(members):
            for b in members[i+1:]:
                sim=len(shingles[a]&shingles[b])/len(shingles[a]|shingles[b]);assert sim>=float(cutoff)-1e-12
                assert min(word_lengths[a],word_lengths[b])>=80 and min(word_lengths[a],word_lengths[b])/max(word_lengths[a],word_lengths[b])>=.8
    chosen=[min([REP[k] for k in members],key=lambda d:(d['text_basis']!='full_text',-len(d['stored_body']),d['record_key'])) for members in gg.values()]
    for r in csvr(OUT/'near_copy_sensitivity.csv'):
        if float(r['threshold'])==float(cutoff):
            cnt=sum(d['topic']==r['topic'] for d in chosen);assert cnt==int(r['n']) and len(chosen)==int(r['denominator']);same(r['percent'],100*cnt/len(chosen))
passcheck('Near-copy controls','Every member pair independently passes shingle/length rules; all sensitivity topic counts recomputed')

# Recompute every base lexical pair from the private sentence ledger with separate code.
units=j(PRIVATE/'sentence_units.json');N=len(units);marg=Counter();joint=Counter();support=defaultdict(set);shared=defaultdict(lambda:defaultdict(set))
for u in units:
    terms=set(u['terms']);marg.update(terms)
    assert D[u['record_key']][u['field']][u['start']-1:u['end']].strip()
    for a in terms:
        for b in terms:
            if a<b:
                joint[a,b]+=1;support[a,b].add(u['group']);shared[a,b][u['signature']].add(u['group'])
for r in csvr(OUT/'lexical_pairs.csv'):
    pair=(r['a'],r['b']);num=joint[pair];den=N
    assert int(r['sentence_units'])==den and int(r['cooccurrences'])==num
    assert int(r['a_sentences'])==marg[pair[0]] and int(r['b_sentences'])==marg[pair[1]]
    assert int(r['groups'])==len(support[pair]);score=math.log(num*den/(marg[pair[0]]*marg[pair[1]]))/math.log(den/num)
    same(r['npmi'],score);assert -1<=score<=1
    largest=max(shared[pair].values(),key=len)
    assert int(r['largest_shared_sentence_groups'])==len(largest)
    assert int(r['groups_after_removing_largest_shared_sentence_groups'])==len(support[pair]-largest)
    assert int(r['distinct_sentence_forms'])==len(shared[pair])
passcheck('Lexical numerator/denominator identities','Every NPMI, marginal, joint count, text support and shared-sentence control independently recalculated')
for r in csvr(OUT/'lexical_thresholds.csv'):
    pairs=csvr(OUT/'lexical_pairs.csv');threshold=int(r['min_groups'])
    assert int(r['positive_pairs'])==sum(int(p['groups'])>=threshold and float(p['npmi'])>0 for p in pairs)
passcheck('Lexical threshold counts','5/10/20 group counts reconcile')
local=defaultdict(list)
for u in units:local[u['group']].append(u)
adjacent=[]
for values in local.values():
    for a,b in zip(values,values[1:]):
        if a['field']!=b['field']:continue
        valid=(a['original_index']==b['original_index'] and b['sub']==a['sub']+1) or (b['original_index']==a['original_index']+1 and a['sub']==a['sub_count'] and b['sub']==1)
        if valid:adjacent.append({**a,'terms':list(set(a['terms'])|set(b['terms']))})
variants={'lexical_short_sentence_pairs.csv':[u for u in units if len(u['signature'].split())<=120],
          'lexical_adjacent_pairs.csv':adjacent,'lexical_distinct_sentence_pairs.csv':list({u['signature']:u for u in units}.values())}
for name,us in variants.items():
    total=len(us)
    for r in csvr(OUT/name):
        a,b=r['a'],r['b'];na=sum(a in u['terms'] for u in us);nb=sum(b in u['terms'] for u in us);both=[u for u in us if a in u['terms'] and b in u['terms']]
        assert int(r['sentence_units'])==total and int(r['cooccurrences'])==len(both)
        assert int(r['groups'])==len({u['group'] for u in both});same(r['npmi'],math.log(len(both)*total/(na*nb))/math.log(total/len(both)))
passcheck('Lexical scope sensitivity','Short, distinct and truly adjacent sentence numerators and denominators independently checked')
long=j(OUT/'long_text_summary.json');lr=j(PRIVATE/'long_assignments.json')
assert long['n']==len(lr)==140 and long['same']==sum(x['original']==x['long'] for x in lr)==94
assert long['context_reprojection_matches']==140
passcheck('Long-text projection','94 of 140 whole-text assignments unchanged; context-only re-projection reproduces all 140 original labels')
evalA=j(PRIVATE/'human-coder-A.json');evalB=j(PRIVATE/'human-coder-B.json');design=j(PRIVATE/'human-sampling-design.json')
assert len(evalA)==len(evalB)==len(design)==200 and evalA==evalB
assert all(not r['coder'] and not r['selection_relevance'] for r in evalA)
assert len({r['record_key'] for r in design})==200 and len({r['cluster'] for r in design})==200
assert not {r['record_key'] for r in design}&{d['record_key'] for d in j(PRIVATE/'development_review.json')}
status=j(OUT/'human_validation_status.json');assert status['coders_completed']==0
assert all(status[k] is None for k in ('precision','recall','kappa'))
passcheck('No fabricated human evaluation','Two blank 200-item packs; no completed coders or non-null performance metrics')

# Copy only authored methodological summaries, never the row-level evidence.
for name in ('README.md','qualitative_review.md'):shutil.copy2(CODE/name,OUT/name)
record_keys=set(D)
for p in OUT.rglob('*'):
    if p.is_file() and p.suffix in ('.csv','.json','.md','.svg'):
        content=p.read_text(encoding='utf-8-sig');assert not record_keys.intersection(re.findall(r'\b[0-9a-f]{64}\b',content)),p.name
passcheck('Aggregate package disclosure check','No actual archive record keys in public output text files; private row-level files remain outside repository')
assert all(r['page']>=2 and r['page']<=20 and r['source'] for r in j(OUT/'claim_register.json'))
passcheck('Claim-register integrity','All registered report blocks name their evidence source and page')

result={'status':'PASS','checks':checks,'human_validation_complete':False,'reviewer':'Codex AI','method':'independent recalculation plus frozen-input hash verification'}
if '--finalize' in sys.argv:
    qa=j(OUT/'pdf_qa.json');assert qa['status']=='PASS' and qa['pdf_sha256']==sha(PDF)
    result['pdf_qa_verified']=True
(OUT/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
runtime={'python_analysis':sys.version,'platform':platform.platform(),'packages':{m:metadata.version(m) for m in ['numpy','scipy','scikit-learn','duckdb','threadpoolctl']},
 'R':j(PRIVATE/'prepared.json')['R'],'udpipe':j(PRIVATE/'prepared.json')['udpipe'],'renv_status':'startup reported out-of-sync; project activation used, no bypass',
 'udpipe_model_sha256':j(PRIVATE/'prepared.json')['model_sha256']}
if (OUT/'pdf_qa.json').exists():runtime['rendering_packages']=j(OUT/'pdf_qa.json')['renderer_packages']
manifest={'schema':'demokrscanstvo-report-v1','date':'2026-09-19','source_plan_sha256':sha(ROOT/'output/pdf/demokrscanstvo-plan-analize.pdf'),
 'input_manifests':{str(p.relative_to(ROOT)).replace('\\','/'):sha(p) for p in [BASE/'manifest.json',THEME/'manifest.json']},
 'private_checkpoint_count':len(paths),'private_checkpoint_hash_multiset_verified':True,'runtime':runtime,
 'code':{p.name:sha(p) for p in sorted(CODE.iterdir()) if p.is_file()},
 'report':{'file':PDF.name,'sha256':sha(PDF),'pages':20},
 'files':{str(p.relative_to(OUT)).replace('\\','/'):sha(p) for p in sorted(OUT.rglob('*')) if p.is_file() and p.name!='manifest.json'}}
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'status':'PASS','check_families':len(checks),'private_inputs_hashed':len(paths),'pdf_sha256':manifest['report']['sha256']},ensure_ascii=False))
