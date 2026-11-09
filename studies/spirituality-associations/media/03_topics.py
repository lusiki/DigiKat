"""Exploratory TF-IDF/NMF on restricted candidate contexts; no coded frame estimates."""
import os
for key in ['OMP_NUM_THREADS','OPENBLAS_NUM_THREADS','MKL_NUM_THREADS']:os.environ[key]='2'
from pathlib import Path
import sys,json,re,warnings
import pandas as pd
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import NMF
from sklearn.metrics.pairwise import cosine_similarity
from scipy.optimize import linear_sum_assignment
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from common import ROOT,PRIVATE,TABLES,read_csv,dump_json,write_csv
P=PRIVATE/'media/v1';T=TABLES/'media-v1'
STOP='a ako ali bi bila bili bilo bio biti bez cemo ce da do dok ga gdje i ih ili ima iz ja je jer jesu jos ju kako kada kao kod koja koje kojeg kojem koji kojim kojih koju kroz li me medu mi moze na nakon nam nas nase ne nego neka neke neki niti nije nisu no od on ona oni ono ovu o pa po pod prije pri preko prema sa sam samo se si smo s su sve svi svojih svoj svoje svojoj ta tako te ti to toga tome tu u uz vam vas vec vi za zar zbog zato biti god godine godina dana dan sati hrvatske hrvatska hrvatski zagreb udruge udruga udrugu udruzi drustvo drustva centar centra clan clanovi clanova predsjednik predsjednica rekao rekla istaknuo istaknula posto ovom ovom tom tijekom te dok the and of in to for on with is from com www hr https http facebook youtube vise foto video objavljeno izvor procitajte prilog'.split()
def main():
    records=[json.loads(s) for s in (P/'pair_evidence.jsonl').open(encoding='utf-8')]
    selected=[r for r in records if r['restricted_candidate'] and len(r['context'].split())>=15]
    phrases=sorted({r['phrase'] for r in read_csv(P/'rules.csv')},key=len,reverse=True)
    entity=re.compile(r'\b(?:'+'|'.join(re.escape(x) for x in phrases)+r')\b')
    def masked(text):return entity.sub(' ',re.sub(r'\b\d+\b',' ',text))
    byitem={}
    for r in selected:
        if r['item_key'] not in byitem:byitem[r['item_key']]={**r,'contexts':[]}
        byitem[r['item_key']]['contexts'].append(r['context'])
    docs=list(byitem.values());texts=[masked(' '.join(dict.fromkeys(r['contexts']))) for r in docs]
    vector=TfidfVectorizer(stop_words=STOP,ngram_range=(1,2),min_df=6,max_df=.65,max_features=6500,token_pattern=r'(?u)\b[a-z]{3,}\b',sublinear_tf=True)
    X=vector.fit_transform(texts);terms=np.array(vector.get_feature_names_out())
    runs=[];models={};topic_terms=[]
    for k in [6,8,10,12]:
        hs=[]
        for seed in [17,71]:
            model=NMF(n_components=k,init='random',random_state=seed,max_iter=400,tol=.0005)
            with warnings.catch_warnings(record=True) as ws:W=model.fit_transform(X)
            H=model.components_;hs.append(H)
            runs.append({'topics':k,'seed':seed,'iterations':model.n_iter_,'reconstruction_error':model.reconstruction_err_,
                         'warnings':';'.join(str(w.message) for w in ws)})
            if seed==17:models[k]=(model,W,H)
            for i,h in enumerate(H):topic_terms.append({'k':k,'seed':seed,'topic':i+1,'terms':', '.join(terms[h.argsort()[-12:][::-1]])})
        sim=cosine_similarity(hs[0],hs[1]);a,b=linear_sum_assignment(-sim)
        for r in runs[-2:]:r['aligned_mean_cosine_between_seeds']=float(sim[a,b].mean())
        print('NMF',k,'stability',round(float(sim[a,b].mean()),3),flush=True)
    write_csv(T/'topic_model_runs.csv',runs);write_csv(T/'topic_terms.csv',topic_terms)
    model,W,H=models[8];tot=W.sum(axis=1);assign=np.where(tot>0,W.argmax(axis=1)+1,0)
    strength=np.divide(W.max(axis=1),tot,out=np.zeros(len(docs)),where=tot>0)
    df=pd.DataFrame([{'item_key':r['item_key'],'year':r['year'],'platform':r['platform'],'story_hash':r['story_hash'],
                    'topic':int(t),'max_weight_share':float(v)} for r,t,v in zip(docs,assign,strength)])
    df.to_csv(P/'topic_assignments.csv',index=False)
    profiles=[]
    for label,s in [('all_restricted_passages',df),('web_restricted_passages',df[df.platform=='web']),
                    ('one_per_exact_text_group',df.drop_duplicates('story_hash'))]:
        for topic,n in s.topic.value_counts().items():profiles.append({'corpus':label,'topic':topic,'items':n,'denominator':len(s),'share_pct':100*n/len(s)})
    write_csv(T/'topic_shares.csv',profiles)
    df.groupby(['topic','platform']).size().rename('items').reset_index().to_csv(T/'topic_platform.csv',index=False)
    examples=[]
    for t in range(1,9):
        ix=np.where(assign==t)[0]
        order=sorted(ix,key=lambda i:W[i,t-1],reverse=True)
        for rank,i in enumerate(order[:4]+order[-1:]):
            r=docs[i];examples.append({'topic':t,'rank':rank,'item_key':r['item_key'],'association_id':r['association_id'],
                'date':r['date'],'title':r['title'],'url':r['url'],'context':texts[i],'weight':float(W[i,t-1]),'max_weight_share':float(strength[i])})
    write_csv(P/'topic_reading_examples.csv',examples)
    # Whole cleaned text is a separate fit in the same vocabulary for direct alignment.
    Xfull=vector.transform([masked(r['clean_text'][:30000]) for r in docs])
    full=NMF(n_components=8,init='random',random_state=17,max_iter=400,tol=.0005).fit(Xfull)
    sim=cosine_similarity(H,full.components_);a,b=linear_sum_assignment(-sim)
    write_csv(T/'topic_fulltext_alignment.csv',[{'passage_topic':int(i+1),'fulltext_topic':int(j+1),'cosine':float(sim[i,j]),
        'fulltext_terms':', '.join(terms[full.components_[j].argsort()[-12:][::-1]])} for i,j in zip(a,b)])
    import sklearn,scipy
    dump_json(T/'topic_audit.json',{'documents':len(docs),'vocabulary':len(terms),'restricted_pairs_with_context':len(selected),
        'selected_k':8,'selection_reason':'Fixed eight-topic display within the predeclared exploratory 6/8/10/12 grid; interpret after representative readings.',
        'zero_weight_items':int((assign==0).sum()),'low_dominance_below_0_4':int((strength<.4).sum()),
        'fulltext_aligned_mean_cosine':float(sim[a,b].mean()),'fulltext_iterations':int(full.n_iter_),'lemmatized':False,'input':'accent-folded surface forms, name masking, ±450-character match contexts',
        'sklearn':sklearn.__version__,'scipy':scipy.__version__,'human_coded':False})
    print('TOPICS COMPLETE',len(docs),flush=True)
if __name__=='__main__':main()
