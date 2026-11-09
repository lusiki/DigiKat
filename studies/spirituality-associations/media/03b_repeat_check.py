"""Sensitivity: suppress frequently repeated eight-token runs before thematic modelling."""
import os
for k in ['OMP_NUM_THREADS','OPENBLAS_NUM_THREADS','MKL_NUM_THREADS']:os.environ[k]='2'
from pathlib import Path
import sys,json,re,collections,hashlib
import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import NMF
from sklearn.metrics.pairwise import cosine_similarity
from scipy.optimize import linear_sum_assignment
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from common import ROOT,PRIVATE,TABLES,read_csv,write_csv,dump_json
import importlib.util
sp=importlib.util.spec_from_file_location('topics',Path(__file__).with_name('03_topics.py'));base=importlib.util.module_from_spec(sp);sp.loader.exec_module(base)
P=PRIVATE/'media/v1';T=TABLES/'media-v1'
def main():
    records=[json.loads(s) for s in (P/'pair_evidence.jsonl').open(encoding='utf-8')]
    byitem={}
    for r in records:
        if not r['restricted_candidate'] or len(r['context'].split())<15:continue
        if r['item_key'] not in byitem:byitem[r['item_key']]={**r,'contexts':[]}
        byitem[r['item_key']]['contexts'].append(r['context'])
    docs=list(byitem.values());phrases=sorted({r['phrase'] for r in read_csv(P/'rules.csv')},key=len,reverse=True)
    entity=re.compile(r'\b(?:'+'|'.join(re.escape(x) for x in phrases)+r')\b')
    tokens=[entity.sub(' ',re.sub(r'\b\w*\d\w*\b',' ',' '.join(dict.fromkeys(r['contexts'])))).split() for r in docs]
    def shingles(ts):return [hashlib.blake2b(' '.join(ts[i:i+8]).encode(),digest_size=8).digest() for i in range(max(0,len(ts)-7))]
    frequency=collections.Counter()
    for ts in tokens:frequency.update(set(shingles(ts)))
    repeated={s for s,c in frequency.items() if c>=20}
    stop=set(base.STOP)|{'iban','swift','bank','paypal','gmail','adresa','kontakt','kanal','subscribe','com','www','http','https'}
    texts=[];kept=[];audit=[]
    for r,ts in zip(docs,tokens):
        mask=np.zeros(len(ts),dtype=bool)
        for i,sh in enumerate(shingles(ts)):
            if sh in repeated:mask[i:i+8]=True
        retained=[t for i,t in enumerate(ts) if not mask[i] and t not in stop and re.fullmatch('[a-z]{3,}',t)]
        audit.append({'item_key':r['item_key'],'tokens':len(ts),'removed_repeated_tokens':int(mask.sum()),'retained_tokens':len(retained)})
        if len(retained)>=15:texts.append(' '.join(retained));kept.append(r)
    pd.DataFrame(audit).to_csv(P/'repeat_suppression_audit.csv',index=False)
    vec=TfidfVectorizer(ngram_range=(1,2),min_df=6,max_df=.65,max_features=6000,sublinear_tf=True)
    X=vec.fit_transform(texts);terms=np.array(vec.get_feature_names_out());runs=[];saved=None
    for k in [6,8]:
        hs=[]
        for seed in [17,71]:
            nmf=NMF(n_components=k,init='random',random_state=seed,max_iter=400,tol=.0005);W=nmf.fit_transform(X);H=nmf.components_;hs.append(H)
            runs.append({'topics':k,'seed':seed,'iterations':nmf.n_iter_,'error':nmf.reconstruction_err_})
            if k==6 and seed==17:saved=(nmf,W,H)
        sim=cosine_similarity(*hs);a,b=linear_sum_assignment(-sim)
        for run in runs[-2:]:run['aligned_cosine']=float(sim[a,b].mean())
        print('REPEAT-CHECK',k,'stability',sim[a,b].mean(),flush=True)
    write_csv(T/'repeat_check_models.csv',runs)
    model,W,H=saved;assign=np.where(W.sum(axis=1)>0,W.argmax(axis=1)+1,0)
    write_csv(T/'repeat_check_terms.csv',[{'topic':i+1,'terms':', '.join(terms[h.argsort()[-12:][::-1]])} for i,h in enumerate(H)])
    df=pd.DataFrame([{'item_key':r['item_key'],'topic':int(t),'platform':r['platform'],'year':r['year']} for r,t in zip(kept,assign)])
    df.to_csv(P/'repeat_check_assignments.csv',index=False)
    df.groupby(['topic','platform']).size().rename('items').reset_index().to_csv(T/'repeat_check_channels.csv',index=False)
    rows=[]
    for i,h in enumerate(H):
        ix=np.where(assign==i+1)[0];order=sorted(ix,key=lambda j:W[j,i],reverse=True)
        for rank,j in enumerate(order[:3]+order[-1:]):
            r=kept[j];rows.append({'topic':i+1,'rank':rank,'item_key':r['item_key'],'title':r['title'],'date':r['date'],'context':texts[j],'url':r['url']})
    write_csv(P/'repeat_check_examples.csv',rows)
    dump_json(T/'repeat_check_summary.json',{'input_items':len(docs),'retained_items':len(kept),'excluded_below_15_tokens':len(docs)-len(kept),
        'repeated_8grams_at_least_20_items':len(repeated),'input_tokens':sum(x['tokens'] for x in audit),
        'removed_repeated_tokens':sum(x['removed_repeated_tokens'] for x in audit),'model_k':6,
        'interpretation':'Sensitivity only: repeated substantive announcements can also be removed. This is not a validated cleaned corpus.',
        'selected_model_reason':'Six-topic diagnostic after six-topic initial model was most stable; eight-topic solution retained as sensitivity. Not preregistered.'})
    print('REPEAT CHECK COMPLETE',len(kept),flush=True)
if __name__=='__main__':main()
