"""Prospective blind human coding pack. Does not simulate completed validation."""
from analyze import *

docs=read(PRIVATE/'grouped-documents.json');D={d['record_key']:d for d in docs}
reps=[D[k] for k in read(PRIVATE/'representatives.json')]
membership=read(PRIVATE/'near_copy_memberships.json')['0.85']
seen={d['record_key'] for d in read(PRIVATE/'development_review.json')}
seen.update(u['record_key'] for p in read(PRIVATE/'pair_review.json') for u in p['examples'])
seen.update(u['record_key'] for p in read(PRIVATE/'episode_review.json') for u in p['examples'])
seen.update(x[k] for x in read(PRIVATE/'near_copy_review.json') for k in ('a','b'))
# Map every reviewed record to an exact representative before near-cluster exclusion.
representative_by_group={d['group']:d['record_key'] for d in reps}
contaminated={membership[representative_by_group[D[k]['group']]] for k in seen}
seencontexts={D[k]['context_id'] for k in seen}
clusters=defaultdict(list)
for d in reps:
    if membership[d['record_key']] not in contaminated:clusters[membership[d['record_key']]].append(d)
eligible=[]
for cluster,members in sorted(clusters.items()):
    if any(d['context_id'] in seencontexts for d in members):continue
    d=sorted(members,key=lambda d:(d['text_basis']!='full_text',-len(d['stored_body']),d['record_key']))[0]
    eligible.append((cluster,d))
strata=defaultdict(list)
for c,d in eligible:strata[d['topic']].append((c,d))
alloc={t:min(20,len(v)) for t,v in strata.items()}
while sum(alloc.values())>200:
    t=max(alloc,key=lambda t:(alloc[t],len(strata[t])));alloc[t]-=1
while sum(alloc.values())<200:
    t=max((t for t in strata if alloc[t]<len(strata[t])),key=lambda t:len(strata[t])-alloc[t]);alloc[t]+=1
rng=np.random.default_rng(SEED+1);selected=[];design=[]
for t,items in sorted(strata.items()):
    for i in rng.permutation(len(items))[:alloc[t]]:
        cluster,d=items[i];blindid=f'H{len(selected)+1:03d}'
        selected.append({'item':blindid,'title':d['title'],'text':d['body'],'context':d['context'],
            'selection_relevance':'','explicit_principles':[],'paraphrased_principles':[],
            'applications':[],'function':[],'speaker_roles':[],'uncertain_reason':'','evidence_spans':[],'coder':''})
        design.append({'item':blindid,'record_key':d['record_key'],'cluster':cluster,'stratum':t,
                       'eligible_clusters_in_stratum':len(items),'selected_clusters_in_stratum':alloc[t],
                       'inclusion_probability':alloc[t]/len(items),'weight':len(items)/alloc[t]})
assert len(selected)==200
write(PRIVATE/'human-coder-A.json',selected);write(PRIVATE/'human-coder-B.json',selected);write(PRIVATE/'human-sampling-design.json',design)
write(OUT/'human_validation_status.json',{'status':'not performed','pack_items':200,'eligible_clusters':len(eligible),
 'design':'stratified by frozen primary topic, one representative per exploratory 0.85 near-copy cluster; previously reviewed exact/near/context counterparts excluded',
 'population':'remaining eligible clusters only; weights do not generalize to the entire archive',
 'precision':None,'recall':None,'kappa':None,'coders_completed':0})
print('Prepared two blank blinded packs of 200 items; no human results claimed.')
