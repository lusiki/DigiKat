"""Sentence-bounded lexical associations, not principle/stance classification."""
from analyze import *
from itertools import combinations
from sklearn.decomposition import non_negative_factorization
from threadpoolctl import threadpool_limits

# Frozen after reading 140 development contexts. Whole lemmas / enumerated phrases.
LEX={
 'demokrscanstvo':('Demokršćanstvo',r'\b(?:demokršć\w*|demokrsc\w*|kršćansk\w* demokrac\w*)\b'),
 'domoljublje':('Domoljublje',r'\bdomoljub\w*\b'),
 'drzavotvornost':('Državotvornost',r'\bdržavotvor\w*\b'),
 'narodnjastvo':('Narodnjaštvo',r'\bnarodnja\w*\b'),
 'obitelj':('Obitelj',r'\bobitelj\w*\b'),
 'konzervativizam':('Konzervativizam',r'\bkonzervati\w*\b'),
 'vrijednosti':('Vrijednosti',r'\bvrijednost\w*\b'),
 'europa':('Europa',r'\beurop\w*\b'),
 'solidarnost':('Solidarnost',r'\bsolidarn\w*\b'),
 'supsidijarnost':('Supsidijarnost',r'\b(?:supsidijarn\w*|subsidi?jarn\w*)\b'),
 'opce_dobro':('Opće dobro',r'\bopć\w* dobr\w*\b'),
 'ljudsko_dostojanstvo':('Ljudsko dostojanstvo',r'\b(?:ljudsk\w* dostojanstv\w*|dostojanstv\w* (?:ljudsk\w* )?(?:osob\w*|čovjek\w*))\b'),
 'dostojanstvo_rada':('Dostojanstvo rada',r'\bdostojanstv\w* (?:rad\w*|radnik\w*)\b'),
 'radnik':('Radnik',r'\bradni[kc]\w*\b'),
 'socijalna_drzava':('Socijalna država',r'\bsocijal\w* držav\w*\b'),
 'trzisno_gospodarstvo':('Tržišno gospodarstvo',r'\b(?:tržišn\w* (?:gospodarstv\w*|ekonomij\w*))\b'),
 'savjest':('Savjest',r'\bsavjest\w*\b'),
 'vjerska_sloboda':('Vjerska sloboda',r'\bvjersk\w* slobod\w*\b'),
 'demokracija':('Demokracija',r'\bdemokracij\w*\b'),
 'izbori':('Izbori / izbor',r'\bizbor\w*\b'),
 'sloboda':('Sloboda',r'\bslobod\w*\b'),
 'hdz':('HDZ',r'\bhdz\b'),
 'epp':('EPP',r'\bepp\b'),
 'cdu':('CDU',r'\bcdu\b'),
 'desni_centar':('Desni centar',r'\bdesn\w* centar\b'),
}
def concepts(tokens):
    txt=' '.join((t.get('lemma') or t['token']).casefold() for t in tokens if t['upos']!='PUNCT')
    out={k for k,(_,pattern) in LEX.items() if re.search(pattern,txt)}
    # A multiword phrase subsumes its component in that occurrence, but another
    # distinct occurrence of the component in the sentence is retained.
    if 'vjerska_sloboda' in out:
        reduced=re.sub(LEX['vjerska_sloboda'][1],'',txt)
        if not re.search(LEX['sloboda'][1],reduced):out.discard('sloboda')
    if 'demokrscanstvo' in out:
        reduced=re.sub(r'\bkršćansk\w* demokrac\w*\b','',txt)
        if not re.search(LEX['demokracija'][1],reduced):out.discard('demokracija')
    return out

def associations(units):
    N=len(units);marg=Counter();joint=Counter();support=defaultdict(set);sentgroup=defaultdict(lambda:defaultdict(set))
    for u in units:
        terms=set(u['terms']);marg.update(terms)
        for pair in combinations(sorted(terms),2):
            joint[pair]+=1;support[pair].add(u['group']);sentgroup[pair][u['signature']].add(u['group'])
    rows=[]
    for (a,b),n in joint.items():
        p=n/N
        score=math.log(p/((marg[a]/N)*(marg[b]/N)))/-math.log(p) if 0<p<1 else None
        maxset=max(sentgroup[a,b].values(),key=len)
        # Remove every group containing the single most widespread shared sentence.
        rows.append({'a':a,'b':b,'a_label':LEX[a][0],'b_label':LEX[b][0],'sentence_units':N,'a_sentences':marg[a],
          'b_sentences':marg[b],'cooccurrences':n,'groups':len(support[a,b]),'npmi':score,
          'distinct_sentence_forms':len(sentgroup[a,b]),'largest_shared_sentence_groups':len(maxset),
          'groups_after_removing_largest_shared_sentence_groups':len(support[a,b]-maxset)})
    return sorted(rows,key=lambda r:(-r['groups'],r['a'],r['b']))

def main():
    docs=read(PRIVATE/'grouped-documents.json');D={d['record_key']:d for d in docs}
    reps=[D[k] for k in read(PRIVATE/'representatives.json')]
    annotations={r['sentence_id']:r['tokens'] for p in sorted((PRIVATE/'sentence-tokens').glob('*.jsonl')) for r in lines(p)}
    units=[];review=[];checked=0
    for d in reps:
        seen=set();local=[]
        for source in d['sentences']:
            text=source['text'];tokens=annotations[source['sentence_id']]
            subs=defaultdict(list)
            for t in tokens:
                assert text[t['start']-1:t['end']]==t['token'];checked+=1
                subs[t['sentence_id']].append(t)
            for sub,ts in subs.items():
                sig=canon(text[ts[0]['start']-1:ts[-1]['end']])
                if sig in seen:continue
                seen.add(sig)
                u={'record_key':d['record_key'],'group':d['group'],'field':source['field'],'original_index':source['sentence_index'],
                  'sub':sub,'sub_count':len(subs),'start':source['start']+ts[0]['start']-1,'end':source['start']+ts[-1]['end']-1,
                  'terms':sorted(concepts(ts)),'signature':sig,'platform':d['platform'],'month':d['month'],
                  'negation':any((t.get('lemma') or '').casefold() in ('ne','niti','nikada','nije') for t in ts)}
                assert d[source['field']][u['start']-1:u['end']]==text[ts[0]['start']-1:ts[-1]['end']]
                units.append(u);local.append(u)
        # Adjacent original evidence sentences, both actually selected, same field.
        for a,b in zip(local,local[1:]):
            if a['field']==b['field'] and ((a['original_index']==b['original_index'] and b['sub']==a['sub']+1) or (b['original_index']==a['original_index']+1 and a['sub']==a['sub_count'] and b['sub']==1)):
                review.append({**a,'terms':sorted(set(a['terms'])|set(b['terms'])),'signature':a['signature']+'\n'+b['signature']})
    rows=associations(units);table('lexical_pairs',rows)
    table('lexical_adjacent_pairs',associations(review))
    unique={u['signature']:u for u in units};table('lexical_distinct_sentence_pairs',associations(list(unique.values())))
    table('lexical_short_sentence_pairs',associations([u for u in units if len(u['signature'].split())<=120]))
    word_units=[{**u,'signature':' '.join(re.findall(r'[^\W_]+',u['signature']))} for u in units]
    table('lexical_word_sequence_pairs',associations(word_units))
    table('lexical_thresholds',[{'min_groups':n,'positive_pairs':sum(r['groups']>=n and (r['npmi'] or 0)>0 for r in rows),
       'positive_pairs_surviving_shared_sentence_removal':sum(r['groups_after_removing_largest_shared_sentence_groups']>=n and (r['npmi'] or 0)>0 for r in rows)} for n in (5,10,20)])
    write(OUT/'lexicon.json',{k:{'label':v[0],'lemma_regex':v[1]} for k,v in LEX.items()})
    write(PRIVATE/'sentence_units.json',units)
    # Supply a fixed supporting/negative evidence packet, still private.
    focus=[('domoljublje','drzavotvornost'),('domoljublje','narodnjastvo'),('demokrscanstvo','konzervativizam'),('europa','solidarnost'),('hdz','savjest')]
    packets=[]
    for a,b in focus:
        cand=[u for u in units if {a,b}<=set(u['terms'])]
        cand.sort(key=lambda u:(not u['negation'],u['signature'],u['group']))
        selected=[];seen=set()
        for u in cand:
            if u['signature'] not in seen:
                selected.append(u);seen.add(u['signature'])
            if len(selected)==10:break
        packets.append({'pair':[a,b],'examples':selected})
    write(PRIVATE/'pair_review.json',packets)
    summary={'sentence_units':len(units),'distinct_sentence_forms':len(unique),'exact_text_representatives':len(reps),
       'tokens_offset_checked':checked,'adjacent_units':len(review),'lexicon_size':len(LEX),'human_semantic_validation':False}
    write(OUT/'lexical_summary.json',summary)
    # Fixed topic model projection: same vocabulary and IDF, no full-text refit.
    longfiles=list((PRIVATE/'long-tokens').glob('*.json'))
    if len(longfiles)==140:
        model=np.load(PRIVATE/'model.npz');vocab=model['vocabulary'].tolist()
        vector=TfidfVectorizer(tokenizer=str.split,preprocessor=None,token_pattern=None,lowercase=False,sublinear_tf=True,norm='l2',vocabulary={s:i for i,s in enumerate(vocab)})
        vector.fit([' '.join(vocab)]);vector.idf_=model['idf']
        long=[read(p) for p in sorted(longfiles,key=lambda p:int(p.stem))]
        X=vector.transform(' '.join(clean_terms(d['lemmas'])) for d in long)
        with threadpool_limits(limits=2):
            W,H,niter=non_negative_factorization(X,H=model['H'],n_components=10,update_H=False,init='custom',random_state=SEED,max_iter=1200,tol=1e-4)
        assert niter<1200
        pred=W.argmax(axis=1);pred[np.asarray(X.getnnz(axis=1))==0]=-1
        original=[int(D[d['record_key']]['topic'][1:])-1 for d in long]
        _,_,_,context_tokens,_=load_inputs(WORK/'multiplatform-v1')
        context_matrix=vector.transform(' '.join(context_tokens[D[d['record_key']]['context_id']]) for d in long)
        with threadpool_limits(limits=2):
            context_W,_,context_iterations=non_negative_factorization(context_matrix,H=model['H'],n_components=10,update_H=False,init='custom',random_state=SEED,max_iter=1200,tol=1e-4)
        context_pred=context_W.argmax(axis=1)
        projection_matches=int(sum(a==b for a,b in zip(original,context_pred)))
        table('long_text_sensitivity',[{'topic':topid(i),'n':sum(x==i for x in original),'same':sum(a==i and b==i for a,b in zip(original,pred)),
               'changed':sum(a==i and b!=i for a,b in zip(original,pred))} for i in range(10)])
        write(OUT/'long_text_summary.json',{'n':140,'same':int(sum(a==b for a,b in zip(original,pred))),'ari':float(adjusted_rand_score(original,pred)),
          'iterations':int(niter),'context_reprojection_matches':projection_matches,'context_reprojection_iterations':int(context_iterations),'sample':'purposive development sample; not a prevalence estimate or held-out test','method':'project whole masked title/body into original context-trained vocabulary, IDF and L2-normalized NMF components'})
        write(PRIVATE/'long_assignments.json',[{'record_key':d['record_key'],'original':topid(a),'long':topid(int(b))} for d,a,b in zip(long,original,pred)])
    print(json.dumps(summary,ensure_ascii=False))

if __name__=='__main__':main()
