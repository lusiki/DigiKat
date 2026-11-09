"""Textual addendum: deterministic descriptive analysis of frozen private inputs.

No semantic truth labels are inferred from counts. Private texts and row IDs stay
outside the repository. Run with Python 3.14; standard library only.
"""
from pathlib import Path
from collections import Counter, defaultdict
from itertools import combinations
import csv, hashlib, json, math, os, random, re, sys, unicodedata

ROOT = Path(__file__).resolve().parents[3]
WORK = Path(os.environ.get('DIGIKAT_BAROMETAR_WORKDIR', 'C:/Users/lsikic/Luka C/DigiKat_barometar_work'))
OLD = WORK/'analytical-report-v1'
PRIVATE = WORK/'text-addendum-v1'
OUT = ROOT/'output/demokrscanstvo-text-addendum/v1'
SEED = 20260920
read = lambda p: json.loads(Path(p).read_text(encoding='utf-8-sig'))
lines = lambda p: [json.loads(s) for s in Path(p).read_text(encoding='utf-8-sig').splitlines() if s]
sha = lambda p: hashlib.sha256(Path(p).read_bytes()).hexdigest()
canon = lambda s: re.sub(r'\s+', ' ', unicodedata.normalize('NFC',s).casefold()).strip()
def write(p,x):
    p=Path(p);p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(x,ensure_ascii=False,indent=2,allow_nan=False)+'\n',encoding='utf-8')
def table(name,rows,folder=OUT):
    rows=list(rows)
    if not rows: return
    folder.mkdir(parents=True,exist_ok=True)
    with (folder/(name+'.csv')).open('w',encoding='utf-8',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]),lineterminator='\n');w.writeheader();w.writerows(rows)

# Keep the pre-existing 25 concept definitions frozen for comparability.
LEX = read(ROOT/'output/demokrscanstvo-analysis/v1/lexicon.json')
FOCUS = ['domoljublje','drzavotvornost','narodnjastvo','obitelj','konzervativizam',
         'vrijednosti','europa','solidarnost','supsidijarnost','opce_dobro',
         'ljudsko_dostojanstvo','dostojanstvo_rada','radnik','socijalna_drzava',
         'trzisno_gospodarstvo','savjest','vjerska_sloboda','demokracija','sloboda']
PAIRS = [('domoljublje','drzavotvornost'),('domoljublje','narodnjastvo'),
         ('demokrscanstvo','konzervativizam'),('europa','solidarnost'),
         ('hdz','savjest'),('obitelj','vrijednosti')]
PHRASES = [('socijalan','tržišni','gospodarstvo'),('socijalan','tržišni','ekonomija'),
           ('opći','dobro'),('ljudski','dostojanstvo'),('dostojanstvo','ljudski','osoba'),
           ('dostojanstvo','radnik'),('dostojanstvo','rad'),('vjerski','sloboda'),
           ('sloboda','savjest'),('priziv','savjest'),('priziv','na','savjest'),
           ('socijalan','država'),('kršćanski','demokracija'),('desni','centar'),
           ('demokratski','pluralizam'),('europski','suradnja'),
           ('socijalan','tržišni','gospodarski','sustav')]
KEEP_POS={'NOUN','PROPN','ADJ','VERB','ADV'}
PRESERVE={'ne','nije','nisam','nikada','nikad','niti','bez','protiv','ali'}
STOP={'biti','htjeti','moći','imati','kazati','reći'} # verbal speech scaffolding; other argument verbs retained
SELECT = re.compile(r'^(?:demokršć|demokrsc|kršć|kršcan|demokrs)')
def category(term,proper):
    if SELECT.match(term):return 'selection'
    if term in {'hdz','epp','cdu','cdu/csu','sdp','hsu','hds','hss','hsls','nhr'} or proper:return 'proper_name'
    return 'content'
def lemma(t):return canon(t.get('lemma') or t['token'])
def keep(t):
    l=lemma(t)
    return bool(re.search(r'[^\W\d_]',l)) and (l in PRESERVE or (t['upos'] in KEEP_POS and l not in STOP))
def concepts(ts):
    txt=' '.join(lemma(t) for t in ts if t['upos']!='PUNCT')
    found={k for k,v in LEX.items() if re.search(v['lemma_regex'],txt)}
    if 'vjerska_sloboda' in found and not re.search(LEX['sloboda']['lemma_regex'],re.sub(LEX['vjerska_sloboda']['lemma_regex'],'',txt)):found.discard('sloboda')
    if 'demokrscanstvo' in found and not re.search(LEX['demokracija']['lemma_regex'],re.sub(r'\bkršćansk\w* demokrac\w*','',txt)):found.discard('demokracija')
    return found

def load():
    docs=read(OLD/'grouped-documents.json');D={d['record_key']:d for d in docs}
    assert len(D)==len(docs)==2306
    reps=[D[k] for k in read(OLD/'representatives.json')]
    assert len(reps)==2253 and len({d['group'] for d in reps})==2253
    sources=read(PRIVATE/'sources.json');S={r['record_key']:r['source_name'] or None for r in sources}
    assert len(S)==len(sources)==len(D) and set(S)==set(D)
    for d in docs:d['source_name']=S[d['record_key']]
    members=defaultdict(list)
    for d in docs:members[d['group']].append(d)
    annotations={r['sentence_id']:r['tokens'] for folder in (OLD,PRIVATE) for p in sorted((folder/'sentence-tokens').glob('*.jsonl')) for r in lines(p)}
    extended={d['record_key']:d['sentences'] for d in lines(PRIVATE/'expanded-sentences.jsonl')}
    return docs,reps,members,annotations,extended

def units_for(reps,annotations,extended=None):
    units=[];checked=0;duplicate_sentences=0
    for d in reps:
        seen=set()
        for s in extended[d['record_key']] if extended else d['sentences']:
            ts=annotations[s['sentence_id']];subs=defaultdict(list)
            assert d[s['field']][s['start']-1:s['end']]==s['text']
            for t in ts:
                assert s['text'][t['start']-1:t['end']]==t['token'];checked+=1
                subs[t['sentence_id']].append(t)
            for sub,words in subs.items():
                text=s['text'][words[0]['start']-1:words[-1]['end']];sig=canon(text)
                if sig in seen:duplicate_sentences+=1;continue
                seen.add(sig)
                u={'record_key':d['record_key'],'group':d['group'],'field':s['field'],
                   'sentence_index':s['sentence_index'],'sub':sub,
                   'start':s['start']+words[0]['start']-1,'end':s['start']+words[-1]['end']-1,
                   'text':text,'signature':sig,'word_signature':' '.join(re.findall(r'[^\W_]+',sig)),
                   'tokens':words,'terms':sorted(concepts(words))}
                assert d[u['field']][u['start']-1:u['end']]==text
                units.append(u)
    return units,{'sentences':len(units),'positions_checked':checked,'duplicate_sentences_omitted':duplicate_sentences,'distinct_sentences':len({u['signature'] for u in units})}

def counters(units,reps):
    counts={d['group']:Counter() for d in reps};surface={g:Counter() for g in counts};pos=defaultdict(Counter)
    term_sents=defaultdict(lambda:defaultdict(set))
    for u in units:
        for t in u['tokens']:
            if keep(t):
                counts[u['group']][lemma(t)]+=1;surface[u['group']][canon(t['token'])]+=1
                pos[lemma(t)][t['upos']]+=1;term_sents[lemma(t)][u['signature']].add(u['group'])
    return counts,surface,pos,term_sents

def vocabulary(counts,reps,members,pos,term_sents,scope):
    total=Counter();df=Counter();N=sum(bool(c) for c in counts.values());den=sum(sum(c.values()) for c in counts.values())
    tfidf=Counter();private=[]
    for g,c in counts.items():total.update(c);df.update(c.keys())
    for g,c in counts.items():
        nt=sum(c.values())
        for t,n in c.items():
            val=n/nt*math.log(N/df[t]);tfidf[t]+=val
            private.append({'group':g,'term':t,'n':n,'tfidf':val})
    if scope=='local':table('document-tfidf',private,PRIVATE)
    rows=[]
    for t,n in total.items():
        gs={g for g,c in counts.items() if c[t]};sp=Counter()
        for g in gs:
            for src in {d['source_name'] for d in members[g] if d['source_name']}:sp[src]+=1
        longest=max(gs,key=lambda g:(sum(counts[g].values()),g))
        best=max(term_sents[t].values(),key=len)
        rows.append({'term':t,'category':category(t,pos[t]['PROPN']>sum(pos[t].values())/2),
          'occurrences':n,'groups':df[t],'all_groups':len(counts),'nonempty_groups':N,
          'percent':100*df[t]/len(counts),'per_10000':10000*n/den,'token_denominator':den,
          'mean_tfidf':tfidf[t]/len(counts),'sentence_forms':len(term_sents[t]),
          'quarters':len({quarter(d['day']) for g in gs for d in members[g]}),'sources':len(sp),
          'largest_source_groups':max(sp.values(),default=0),'groups_after_largest_sentence':len(gs-best),
          'occurrences_without_longest_supporting_text':n-counts[longest][t]})
    rows.sort(key=lambda r:(-r['groups'],-r['mean_tfidf'],r['term']))
    for i,r in enumerate(sorted(rows,key=lambda r:(-r['mean_tfidf'],r['term'])),1):r['tfidf_rank']=i
    table('vocabulary_'+scope,rows)
    return rows

def quarter(day):return day[:4]+'-Q'+str((int(day[5:7])-1)//3+1)
def zscore(ca,cb,na,nb):
    prior=ca+cb;nt=na+nb
    if not prior or min(na+nt-ca-prior,nb+nt-cb-prior)<=0:return None,None
    delta=math.log((ca+prior)/(na+nt-ca-prior))-math.log((cb+prior)/(nb+nt-cb-prior))
    return delta,delta/math.sqrt(1/(ca+prior)+1/(cb+prior))

def contrasts(counts,surface,reps,members,pos,term_sents):
    specs=[('web_2021_2023',lambda d:d['platform']=='web' and d['day'][:4]=='2021',lambda d:d['platform']=='web' and d['day'][:4]=='2023'),
           ('web_jan_aug_2025_2026',lambda d:d['platform']=='web' and '2025-01-01'<=d['day']<'2025-09-01',lambda d:d['platform']=='web' and '2026-01-01'<=d['day']<'2026-09-01')]
    result=[];meta=[]
    for name,fa,fb in specs:
        A={g for g,ds in members.items() if any(fa(d) for d in ds)};B={g for g,ds in members.items() if any(fb(d) for d in ds)}
        both=A&B;sc=Counter(d['source_name'] for ds in members.values() for d in ds if (fa(d) or fb(d)) and d['source_name'])
        top_source=sc.most_common(1)[0][0]
        source_groups={g for g,ds in members.items() if any((fa(d) or fb(d)) and d['source_name']==top_source for d in ds)}
        meta.append({'contrast':name,'a_groups':len(A),'b_groups':len(B),'shared_groups':len(both),
                     'a_records':sum(fa(d) for ds in members.values() for d in ds),'b_records':sum(fb(d) for ds in members.values() for d in ds),
                     'largest_source':top_source,'source_groups_removed':len(source_groups),'eligible':min(len(A),len(B))>=50})
        if min(len(A),len(B))<50:continue
        variants={'base':(A,B,counts),'no_overlap':(A-both,B-both,counts),
                  'no_largest_source':(A-source_groups,B-source_groups,counts),'surface':(A,B,surface),
                  'a1':({g for g in A if any(fa(d) and d['a1'] for d in members[g])},{g for g in B if any(fb(d) and d['a1'] for d in members[g])},counts)}
        for variant,(aa,bb,C) in variants.items():
            ca=Counter();cb=Counter();da=Counter();db=Counter()
            for g in aa:ca.update(C[g]);da.update(C[g].keys())
            for g in bb:cb.update(C[g]);db.update(C[g].keys())
            na=sum(ca.values());nb=sum(cb.values())
            for t in sorted(ca.keys()|cb.keys()):
                delta,z=zscore(ca[t],cb[t],na,nb)
                support={g for g in aa|bb if C[g][t]}
                result.append({'contrast':name,'variant':variant,'term':t,
                  'category':category(t,pos[t]['PROPN']>sum(pos[t].values())/2) if variant!='surface' else 'surface',
                  'a_groups':len(aa),'b_groups':len(bb),'a_tokens':na,'b_tokens':nb,'a_count':ca[t],'b_count':cb[t],
                  'a_df':da[t],'b_df':db[t],'combined_df':len(support),'a_per_10000':10000*ca[t]/na,'b_per_10000':10000*cb[t]/nb,
                  'delta_log_odds':delta,'weighted_log_odds':z,'a_df_percent':100*da[t]/len(aa),'b_df_percent':100*db[t]/len(bb)})
        # Term-specific influential-document and repeated-sentence controls.
        allterms={t for g in A|B for t in counts[g]}
        na=sum(sum(counts[g].values()) for g in A);nb=sum(sum(counts[g].values()) for g in B)
        for t in sorted(allterms):
            gs={g for g in A|B if counts[g][t]}
            if len(gs)<5:continue
            long=max(gs,key=lambda g:(sum(counts[g].values()),g))
            sig,best=max(((s,v&gs) for s,v in term_sents[t].items()),key=lambda x:(len(x[1]),x[0]))
            for variant,removed in [('no_longest_supporting_text',{long}),('no_largest_supporting_sentence',best)]:
                aa=A-removed;bb=B-removed
                ca=sum(counts[g][t] for g in aa);cb=sum(counts[g][t] for g in bb)
                n_a=na-sum(sum(counts[g].values()) for g in A&removed);n_b=nb-sum(sum(counts[g].values()) for g in B&removed)
                delta,z=zscore(ca,cb,n_a,n_b)
                result.append({'contrast':name,'variant':variant,'term':t,'category':category(t,pos[t]['PROPN']>sum(pos[t].values())/2),
                  'a_groups':len(aa),'b_groups':len(bb),'a_tokens':n_a,'b_tokens':n_b,'a_count':ca,'b_count':cb,
                  'a_df':sum(counts[g][t]>0 for g in aa),'b_df':sum(counts[g][t]>0 for g in bb),'combined_df':len(gs-removed),
                  'a_per_10000':10000*ca/n_a,'b_per_10000':10000*cb/n_b,'delta_log_odds':delta,'weighted_log_odds':z,
                  'a_df_percent':100*sum(counts[g][t]>0 for g in aa)/len(aa),'b_df_percent':100*sum(counts[g][t]>0 for g in bb)/len(bb)})
    table('contrasts',result);write(OUT/'contrast_design.json',meta)
    return result,meta

def phrases(units):
    occurrences=Counter();support=defaultdict(set);sentences=defaultdict(lambda:defaultdict(set));words=defaultdict(lambda:defaultdict(set));forms=defaultdict(Counter);hits=[]
    for u in units:
        ts=u['tokens']
        for i,t in enumerate(ts):
            candidates=[]
            for n in (2,3):
                seg=ts[i:i+n]
                if len(seg)==n and all(re.search(r'[^\W\d_]',v['token']) and v['upos'] not in {'PUNCT','SYM','NUM'} for v in seg):candidates.append((n,tuple(lemma(v) for v in seg),'ngram'))
            matching=[p for p in PHRASES if tuple(lemma(v) for v in ts[i:i+len(p)])==p]
            if matching:
                p=max(matching,key=len);candidates.append((len(p),p,'dictionary'))
            for n,p,kind in candidates:
                key=(kind,' '.join(p));occurrences[key]+=1;support[key].add(u['group']);sentences[key][u['signature']].add(u['group']);words[key][u['word_signature']].add(u['group'])
                form=u['text'][ts[i]['start']-ts[0]['start']:ts[i+n-1]['end']-ts[0]['start']+1]
                forms[key][form]+=1
                if kind=='dictionary':hits.append({'group':u['group'],'record_key':u['record_key'],'field':u['field'],'start':u['start']+ts[i]['start']-ts[0]['start'],'end':u['start']+ts[i+n-1]['end']-ts[0]['start'],'phrase_id':' '.join(p),'dictionary_version':'1.0'})
    rows=[]
    for (kind,p),n in occurrences.items():
        key=(kind,p);gs=support[key];best=max(sentences[key].values(),key=len);bw=max(words[key].values(),key=len)
        rows.append({'kind':kind,'phrase':p,'surface_example':forms[key].most_common(1)[0][0],
                     'n_words':len(p.split()),'occurrences':n,'groups':len(gs),'sentence_forms':len(sentences[key]),
                     'largest_sentence_groups':len(best),'largest_sentence_percent':100*len(best)/len(gs),
                     'remaining_groups':len(gs-best),'remaining_word_sequence_groups':len(gs-bw)})
    rows.sort(key=lambda r:(-r['groups'],r['phrase'],r['kind']));table('phrases',[r for r in rows if r['groups']>=5 or r['kind']=='dictionary'])
    write(PRIVATE/'phrase-hits.json',hits)
    return rows

def associations(units,reps,members):
    N=len(units);marg=Counter();joint=Counter();support=defaultdict(set);ss=defaultdict(lambda:defaultdict(set));ws=defaultdict(lambda:defaultdict(set))
    for u in units:
        marg.update(u['terms'])
        for pair in combinations(sorted(u['terms']),2):
            joint[pair]+=1;support[pair].add(u['group']);ss[pair][u['signature']].add(u['group']);ws[pair][u['word_signature']].add(u['group'])
    rows=[]
    for pair,n in joint.items():
        a,b=pair;na=marg[a];nb=marg[b];p=n/N;den=math.sqrt(na*nb*(N-na)*(N-nb))
        best=max(ss[pair].values(),key=len);bw=max(ws[pair].values(),key=len)
        rows.append({'a':a,'b':b,'a_label':LEX[a]['label'],'b_label':LEX[b]['label'],'sentences':N,
          'both':n,'a_only':na-n,'b_only':nb-n,'neither':N-na-nb+n,'groups':len(support[pair]),
          'npmi':math.log(n*N/(na*nb))/-math.log(p) if 0<p<1 else None,'phi':(n*N-na*nb)/den if den else None,
          'sentence_forms':len(ss[pair]),'largest_sentence_groups':len(best),'remaining_groups':len(support[pair]-best),
          'remaining_word_sequence_groups':len(support[pair]-bw)})
    rows.sort(key=lambda r:(-r['groups'],r['a'],r['b']));table('relations',rows)
    packet=[]
    for pair in PAIRS:
        candidates=[u for u in units if set(pair)<=set(u['terms'])]
        candidates.sort(key=lambda u:(not any(lemma(t) in PRESERVE for t in u['tokens']),u['signature'],u['group']))
        chosen=[];gs=set();sigs=set();bags=[]
        # Greedy lexical diversity avoids filling the review with punctuation variants.
        while candidates and len(chosen)<10:
            available=[u for u in candidates if u['group'] not in gs and u['word_signature'] not in sigs]
            if not available:break
            def diversity(u):
                bag=set(u['word_signature'].split())
                return min((1-len(bag&b)/len(bag|b) for b in bags),default=0)
            u=max(available,key=lambda u:(diversity(u),bool(re.search(r'\b(?:ne|nije|nisu|protiv)\b',u['signature'])),-len(u['text']),u['signature']))
            chosen.append({k:v for k,v in u.items() if k!='tokens'});gs.add(u['group']);sigs.add(u['word_signature']);bags.append(set(u['word_signature'].split()))
        packet.append({'pair':list(pair),'examples':chosen})
    write(PRIVATE/'relation-review.json',packet)
    return rows

def dispersion(units,members):
    term_groups=defaultdict(set);sigs=defaultdict(lambda:defaultdict(set));ws=defaultdict(lambda:defaultdict(set))
    for u in units:
        for t in u['terms']:
            term_groups[t].add(u['group']);sigs[t][u['signature']].add(u['group']);ws[t][u['word_signature']].add(u['group'])
    rows=[];cells=[];controls=[];near=read(OLD/'near_copy_memberships.json')
    repkeys={d['group']:d['record_key'] for d in read(OLD/'grouped-documents.json') if d['record_key'] in set(read(OLD/'representatives.json'))}
    for platform in sorted({d['platform'] for ds in members.values() for d in ds}):
        for regime in ('before','after'):
            eligible={g:[d for d in ds if d['platform']==platform and ('before' if d['day']<'2024-04-01' else 'after')==regime] for g,ds in members.items()}
            eligible={g:ds for g,ds in eligible.items() if ds};quarters=sorted({quarter(d['day']) for ds in eligible.values() for d in ds})
            if not eligible:continue
            for t in FOCUS:
                gs=term_groups[t]&set(eligible);src=defaultdict(set);months=defaultdict(set)
                for g in gs:
                    for d in eligible[g]:src[d['source_name']].add(g);months[d['month']].add(g)
                named={k:v for k,v in src.items() if k};largest=max(named,key=lambda s:(len(named[s]),s)) if named else None
                best=max((v&gs for v in sigs[t].values()),key=len,default=set());bw=max((v&gs for v in ws[t].values()),key=len,default=set())
                peak=max(months,key=lambda m:(len(months[m]),m)) if months else None
                qsupport={q:{g for g in gs if any(quarter(d['day'])==q for d in eligible[g])} for q in quarters}
                rows.append({'term':t,'label':LEX[t]['label'],'platform':platform,'regime':regime,
                  'groups':len(gs),'eligible_groups':len(eligible),'quarters_present':sum(bool(v) for v in qsupport.values()),'quarters_available':len(quarters),
                  'named_sources':len(named),'unknown_source_groups':len(src.get(None,set())),
                  'largest_source':largest,'largest_source_groups':len(named[largest]) if largest else 0,
                  'largest_source_percent':100*len(named[largest])/len(gs) if largest and gs else None,
                  'largest_sentence_groups':len(best),'remaining_sentence_groups':len(gs-best),'remaining_word_groups':len(gs-bw),
                  'peak_month':peak,'remaining_peak_month_groups':len(gs-months[peak]) if peak else 0,
                  'remaining_source_groups':len(gs-named[largest]) if largest else len(gs)})
                for q,v in qsupport.items():
                    denom={g for g,ds in eligible.items() if any(quarter(d['day'])==q for d in ds)}
                    cells.append({'term':t,'label':LEX[t]['label'],'platform':platform,'regime':regime,'quarter':q,'groups':len(v),'eligible_groups':len(denom),'small_cell':len(denom)<20,'partial_quarter':q=='2026-Q3'})
                if platform=='web':
                    for threshold,mapping in near.items():controls.append({'term':t,'regime':regime,'threshold':threshold,'exact_groups':len(gs),'near_copy_clusters_with_hit':len({mapping[repkeys[g]] for g in gs})})
    table('dispersion',rows);table('quarterly',cells);table('near_copy_content_sensitivity',controls)
    return rows,cells

def sampling(reps,members):
    strata=defaultdict(list)
    for d in reps:
        h=('A1' if d['a1'] else 'other')+'|'+('web' if d['platform']=='web' else 'other')+'|'+('before' if d['day']<'2024-04-01' else 'after')
        strata[h].append(d)
    Nh={h:len(ds) for h,ds in strata.items()};nh={h:min(10,n) for h,n in Nh.items()}
    remaining=400-sum(nh.values());capacity={h:Nh[h]-nh[h] for h in Nh};C=sum(capacity.values())
    quota={h:remaining*capacity[h]/C for h in Nh}
    for h,q in quota.items():nh[h]+=math.floor(q)
    for h in sorted(Nh,key=lambda h:(-(quota[h]-math.floor(quota[h])),h))[:400-sum(nh.values())]:nh[h]+=1
    rng=random.Random(SEED);sample=[];design=[]
    for h in sorted(strata):
        ds=sorted(strata[h],key=lambda d:d['record_key']);chosen=rng.sample(ds,nh[h])
        design.append({'stratum':h,'N_h':Nh[h],'n_h':nh[h],'pi':nh[h]/Nh[h],'weight':Nh[h]/nh[h]})
        for d in chosen:sample.append({'record_key':d['record_key'],'group':d['group'],'stratum':h,'N_h':Nh[h],'n_h':nh[h],'weight':Nh[h]/nh[h],
         'multiple_regimes':len({x['day']<'2024-04-01' for x in members[d['group']]})>1,'multiple_platforms':len({x['platform'] for x in members[d['group']]})>1})
    assert len(sample)==len({x['group'] for x in sample})==400
    assert math.isclose(sum(x['weight'] for x in sample),2253,abs_tol=1e-8)
    table('sampling_design',design);write(PRIVATE/'sampling-design.json',{'seed':SEED,'algorithm':'Python random.Random.sample; sorted keys; largest remainders, lexical tie-break','units':sample})
    D={d['record_key']:d for d in reps};packs=[]
    for i,s in enumerate(sample,1):
        d=D[s['record_key']]
        packs.append({'unit_id':f'T{i:03}','record_key':d['record_key'],'title':d['title'],'body':d['body'],
                      'local_text':'\n'.join(x['text'] for x in d['sentences']),
                      'codes':{'referent':None,'identity':None,'principle_named':None,'principle_explained':None,'application':None,
                      'unassessable_reason':None,'local_application':None,'claims':[]},'coder':None,'codebook_version':'1.0-draft'})
    write(PRIVATE/'coder-A.json',packs);write(PRIVATE/'coder-B.json',packs)
    # Development pilot: maximum lexical diversity then document key; not an estimate.
    development=read(OLD/'development_review.json');development.sort(key=lambda d:(-len(re.findall(r'supsid|solidar|dostojanst|savjest|opć.{0,4}dob|\bne\b',d['context'].lower())),d['record_key']))
    write(PRIVATE/'pilot-60.json',[{'record_key':d['record_key'],'title':d['title'],'body':d['body'],'codes':None} for d in development[:60]])
    status={'population':2253,'sample':400,'seed':SEED,'weight_sum':sum(s['weight'] for s in sample),'pilot_prepared':60,
            'independent_human_codings_required':800,'independent_human_codings_completed':0,'codebook_status':'draft; pilot not coded',
            'alpha':None,'application_prevalence':None,'reason':'No independent human decisions supplied; explicit computational-core fallback in approved plan.'}
    write(OUT/'human_validation_status.json',status)
    return status

def main():
    OUT.mkdir(parents=True,exist_ok=True);PRIVATE.mkdir(parents=True,exist_ok=True)
    docs,reps,members,anno,extended=load()
    local,lstat=units_for(reps,anno);expanded,estat=units_for(reps,anno,extended)
    assert lstat['sentences']==7467 and lstat['positions_checked']==187597
    for us in (local,expanded):assert {u['group'] for u in us}=={d['group'] for d in reps}
    counts,surface,pos,term_sents=counters(local,reps)
    v=vocabulary(counts,reps,members,pos,term_sents,'local')
    ec,es,ep,et=counters(expanded,reps);ev=vocabulary(ec,reps,members,ep,et,'expanded')
    c,cm=contrasts(counts,surface,reps,members,pos,term_sents)
    ph=phrases(local);rel=associations(local,reps,members);disp,q=dispersion(local,members);status=sampling(reps,members)
    expterms=defaultdict(set);locterms=defaultdict(set)
    for u in expanded:
        for t in u['terms']:expterms[t].add(u['group'])
    for u in local:
        for t in u['terms']:locterms[t].add(u['group'])
    table('window_sensitivity',[{'term':t,'label':LEX[t]['label'],'local_groups':len(locterms[t]),'expanded_groups':len(expterms[t]),'added_groups':len(expterms[t]-locterms[t]),'lost_groups':len(locterms[t]-expterms[t])} for t in LEX])
    write(PRIVATE/'local-units.json',local)
    write(OUT/'lexicon.json',{'version':'1.0','concepts':LEX,'dictionary_phrases':[list(p) for p in PHRASES],
          'kept_pos':sorted(KEEP_POS),'preserved_function_words':sorted(PRESERVE),'excluded_lemmas':sorted(STOP),
          'ngram_rule':'2/3 adjacent tokens before stop filtering; punctuation is a boundary; no field/sentence crossing',
          'concept_rule':'Inherited lemma regex with punctuation removed, with original sentence retained for semantic checking',
          'dictionary_rule':'longest match at each start; subphrase at later start may overlap; spans retained privately'})
    summary={'records':len(docs),'exact_groups':len(reps),'record_a1':sum(d['a1'] for d in docs),'rep_a1':sum(d['a1'] for d in reps),
       'record_empty_body':sum(not d['body'].strip() for d in docs),'rep_empty_body':sum(not d['body'].strip() for d in reps),
       'missing_sources':sum(not d['source_name'] for d in docs),'local':lstat,'expanded':estat,
       'local_retained_tokens':sum(sum(c.values()) for c in counts.values()),'expanded_retained_tokens':sum(sum(c.values()) for c in ec.values()),
       'empty_local_lexical_documents':sum(not c for c in counts.values()),'empty_expanded_lexical_documents':sum(not c for c in ec.values()),
       'relations_with_10_groups':sum(r['groups']>=10 for r in rel),
       'zero_concept_sentences':sum(not u['terms'] for u in local),'date_min':min(d['day'] for d in docs),'date_max':max(d['day'] for d in docs),
       'sentiment':'Not run: no human pilot; no evidence that a global tone score improves target-specific stance reading.',
       'lda':'Not run: conditional module; existing NMF retained.'}
    write(OUT/'summary.json',summary)
    # Snapshot original release input hashes, actual runtime and code; later QA adds report hashes.
    inputs=[ROOT/'output/pdf/demokrscanstvo-plan-tekstualne-dopune.pdf',ROOT/'output/pdf/demokrscanstvo-analiticki-izvjestaj.pdf',OLD/'grouped-documents.json',OLD/'representatives.json',OLD/'prepared.json',OLD/'near_copy_memberships.json',PRIVATE/'sources.json',PRIVATE/'expanded-sentences.jsonl']
    manifest={'release':'1.0','seed':SEED,'inputs':{str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else 'private/'+p.name:sha(p) for p in inputs},
              'annotation_hashes':{str(p.relative_to(folder)):sha(p) for folder in (OLD,PRIVATE) for p in (folder/'sentence-tokens').glob('*.jsonl')},
              'python':sys.version,'R_preparation':read(PRIVATE/'prepared.json'),'implementation':'Python standard library descriptive statistics; R UDPipe preparation',
              'human_validation':False}
    # Avoid same relative annotation filenames colliding across the two input folders.
    manifest['annotation_hashes']={folder.name+'/'+str(p.relative_to(folder)):sha(p) for folder in (OLD,PRIVATE) for p in (folder/'sentence-tokens').glob('*.jsonl')}
    write(OUT/'manifest.json',manifest)
    print(json.dumps(summary,ensure_ascii=False,indent=2))

if __name__=='__main__':main()
