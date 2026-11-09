"""Supplementary controls and documented AI content-review decisions."""
from analyze import *
from sklearn.feature_extraction.text import CountVectorizer

def nearcopies(docs):
    # Fixed sensitivity rules, not a calibrated or human-validated story detector.
    texts=[' '.join(re.findall(r'[^\W_]+',canon(d['title']+' '+d['stored_body']))) for d in docs]
    vec=CountVectorizer(tokenizer=str.split,token_pattern=None,lowercase=False,ngram_range=(5,5),binary=True,min_df=1,dtype=np.int32)
    X=vec.fit_transform(texts); sizes=np.asarray(X.sum(axis=1)).ravel(); lengths=np.array([len(s.split()) for s in texts])
    common=(X@X.T).tocoo(); pairs={};candidates=[]
    for i,j,n in zip(common.row,common.col,common.data):
        if i>=j or min(lengths[i],lengths[j])<80:continue
        ratio=min(lengths[i],lengths[j])/max(lengths[i],lengths[j])
        if ratio<.8:continue
        sim=float(n/(sizes[i]+sizes[j]-n))
        if sim>=.8:pairs[int(i),int(j)]=sim;candidates.append((int(i),int(j),sim,ratio))
    counts=[];bythreshold={};summaries=[]
    order=sorted(range(len(docs)),key=lambda i:(-lengths[i],docs[i]['record_key']))
    for cutoff in (.85,.90,.95):
        groups=[];membership={}
        for i in order:
            possible=set(membership[j] for j in membership if pairs.get(tuple(sorted((i,j))),0)>=cutoff)
            group=next((g for g in sorted(possible) if all(pairs.get(tuple(sorted((i,j))),0)>=cutoff for j in groups[g])),None)
            if group is None:group=len(groups);groups.append([])
            groups[group].append(i);membership[i]=group
        # Representatives prefer stored bodies, completeness, then stable key.
        reps=[docs[sorted(g,key=lambda i:(docs[i]['text_basis']!='full_text',-len(docs[i]['stored_body']),docs[i]['record_key']))[0]] for g in groups]
        count=Counter(d['topic'] for d in reps)
        for topic in sorted({d['topic'] for d in docs}):counts.append({'threshold':cutoff,'topic':topic,'n':count[topic],'denominator':len(reps),'percent':100*count[topic]/len(reps)})
        bythreshold[str(cutoff)]={docs[i]['record_key']:membership[i] for i in membership}
        summaries.append({'threshold':cutoff,'groups':len(groups),'largest_group':max(map(len,groups)),'multi_topic_groups':sum(len({docs[i]['topic'] for i in g})>1 for g in groups)})
    table('near_copy_sensitivity',counts);table('near_copy_summary',summaries)
    write(PRIVATE/'near_copy_memberships.json',bythreshold)
    # Deterministic boundary packet, no requirement to accept grouping as gold.
    picked=[]
    for lower,upper in [(.85,.9),(.9,.95),(.95,1.001)]:
        for i,j,sim,ratio in sorted([p for p in candidates if lower<=p[2]<upper],key=lambda p:abs(p[2]-.9))[:5]:
            picked.append({'similarity':sim,'length_ratio':ratio,'a':docs[i]['record_key'],'b':docs[j]['record_key'],
              'a_title':docs[i]['title'],'b_title':docs[j]['title'],'a_context':docs[i]['context'],'b_context':docs[j]['context']})
    write(PRIVATE/'near_copy_review.json',picked)
    return summaries

def main():
    docs=read(PRIVATE/'grouped-documents.json');D={d['record_key']:d for d in docs}
    reps=[D[k] for k in read(PRIVATE/'representatives.json')]
    print('near-copy',nearcopies(reps),flush=True)
    development=read(PRIVATE/'development_review.json')
    # Decisions made from actual context and (where specified) full-text inspection.
    findings={74:('related_item','The main programme concerns a different subject; a recommended programme supplies the match.'),
      100:('related_item','The doctrinal phrase is a related-story link; the main item discusses shop opening rules without that argument.'),
      101:('false_anchor','Personalistic party leadership in US politics is not Christian personalism or Christian democracy.'),
      107:('uncertain_attribution','The bishop reference occurs as a related item; the principal argument is attributed to a parliamentary resolution. Do not count as confirmed Christian principle application.')}
    private=[]
    for i,(status,reason) in findings.items():private.append({'record_key':development[i]['record_key'],'development_index':i,'status':status,'reason':reason,'reviewer':'Codex AI','full_text_read':True,'human_validated':False})
    write(PRIVATE/'content_flags.json',private)
    # Remove exact-context counterparts as a conservative diagnostic; never alter input selection.
    flagged_contexts={development[i]['context_id'] for i in findings}
    affected=[d for d in docs if d['context_id'] in flagged_contexts]
    kept=[d for d in docs if d['context_id'] not in flagged_contexts];count=Counter(d['topic'] for d in kept)
    table('flagged_case_sensitivity',[{'topic':t,'n':count[t],'denominator':len(kept),'percent':100*count[t]/len(kept)} for t in sorted({d['topic'] for d in docs})])
    pair_examples=sum(len(r['examples']) for r in read(PRIVATE/'pair_review.json'))
    write(OUT/'content_review_summary.json',{'development_contexts_read':140,'topic_typical':50,'topic_boundary':50,'additional_diverse':40,'supporting_pair_examples_read':pair_examples,
      'flagged_full_text_cases':4,'flagged_context_counterparts':len(affected),'remaining_for_sensitivity':len(kept),
      'reviewer':'Codex AI; no independent human coders','scope':f'context reading for all 140; full-text reading of four selection-risk cases; {pair_examples} supporting sentence examples',
      'counts_are_not_error_rate':True,'automatic_principle_prevalence_released':False})
    # Broad phrase review decisions, not unit-level truth labels or performance metrics.
    decisions=[
      ('t01','Political positioning is clear in typical cases; explicit refusal of Christian-democratic affiliation must not become endorsement.'),
      ('t02','Repeated national identity lists dominate typical cases; boundary cases include criticism and substantive worker-dignity arguments.'),
      ('t03','HDZ debate includes satire, criticism, and ideologically sympathetic criticism; source endorsement cannot be inferred.'),
      ('t04','Typical cases repeat party-cooperation statements; criticism of opportunism and denials also occur.'),
      ('t05','A shared June 2022 quote dominates strongest cases; not a gold class of family-policy application.'),
      ('t06','European campaign rhetoric is typical; boundaries include survey reporting, which is not a new survey result of this analysis.'),
      ('t07','An electoral concession quote repeats strongly; the category also includes church appeals before elections.'),
      ('t08','Book/conference coverage is central; related-story boilerplate and substantive economic discussion are both present.'),
      ('t09','Values language includes cultural disputes and electoral rhetoric; it is not a single substantive principle.'),
      ('t10','International political reporting is typical; domestic energy/digital-policy texts appear on the boundary.')]
    table('topic_content_review',[{'topic':t,'typical_contexts_read':5,'boundary_contexts_read':5,'reviewer':'Codex AI','decision':s} for t,s in decisions])
    timeline=csvread(OUT/'timeline.csv')
    episode=[];pack=[]
    # Three highest nonadjacent months overall, with within-period ranks and explicit break.
    ranked=sorted(timeline,key=lambda r:(-int(r['publications']),r['month']))
    selected=[]
    def monthnum(s):return int(s[:4])*12+int(s[5:7])
    for r in ranked:
        if all(abs(monthnum(r['month'])-monthnum(s['month']))>1 for s in selected):selected.append(r)
        if len(selected)==3:break
    for r in timeline:
        periodrows=[x for x in timeline if x['period']==r['period']]
        rank=sorted(periodrows,key=lambda x:-int(x['publications'])).index(r)+1
        isselected=r in selected
        ds=[d for d in docs if d['month']==r['month']];tc=Counter(d['topic'] for d in ds)
        episode.append({**r,'within_period_count_rank':rank,'selected':isselected,'leading_topic':tc.most_common(1)[0][0],'leading_topic_n':tc.most_common(1)[0][1],
          'selection_reason':'among top three nonadjacent count peaks; raw archive counts, not causal events' if isselected else 'not selected'})
        if isselected:
            bycontext=defaultdict(list)
            for d in ds:bycontext[d['context_id']].append(d)
            top=sorted(bycontext.values(),key=lambda v:(-len(v),v[0]['context_id']))[:6]
            pack.append({'month':r['month'],'examples':[{'n':len(v),'record_key':v[0]['record_key'],'topic':v[0]['topic'],'context':v[0]['context']} for v in top]})
    table('episode_selection',episode);write(PRIVATE/'episode_review.json',pack)
    print('content flags counterparts',len(affected),'episodes',[r['month'] for r in selected])

if __name__=='__main__':main()
