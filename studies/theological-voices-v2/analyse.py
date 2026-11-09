"""Compute all results from the frozen sample and persisted task outputs."""
from __future__ import annotations
import argparse, json, sqlite3
from pathlib import Path
import numpy as np
import pandas as pd
from prepare import OUT, STUDY, CFG, save_json, file_sha
from coder import ROLES, THEMES, get_config_hash

ROLE_HR={'pope':'Papa','bishop':'Biskupi i kardinali','priest_religious':'Svećenici i redovništvo',
 'academic_theologian':'Akademski teolozi','catechist':'Vjeroučitelji i kateheti',
 'lay_religious_communicator':'Laički vjerski komunikatori','religious_institution':'Vjerske ustanove',
 'political_government':'Politika i javna vlast','research_expert':'Ostali stručnjaci',
 'civil_society':'Civilno društvo','commercial':'Poslovni predstavnici',
 'personal_experience':'Osobno iskustvo sudionika','journalist':'Novinari kao sugovornici',
 'other':'Ostale uloge','unresolved':'Nerazriješena uloga'}
THEME_HR={'teaching_scripture':'Nauk, teologija i Pismo','worship_spirituality':'Bogoslužje i duhovnost',
 'ethics_family':'Etika i obitelj','church_governance':'Crkva kao ustanova',
 'politics_public_life':'Politika i javni život','solidarity_social':'Solidarnost i društvo',
 'education_culture':'Obrazovanje i kultura','history_identity':'Povijest i identitet',
 'other':'Ostalo','unresolved':'Nerazriješeno'}

def pct(x,n):return 100*x/n if n else None
def csv(df,name):df.to_csv(OUT/'tables'/name,index=False,encoding='utf-8-sig')

def article_flag(voices,field):
    """A known positive is positive; an unresolved remainder cannot prove absence."""
    values=[v[field] for v in voices]
    if 'yes' in values:return True
    if 'unresolved' in values:return None
    return False

def role_measures(articles, voices, prefix=''):
    """All three distinct measures; actor = conservative surface identity within article."""
    base=articles[articles.speakers_base].copy()
    v=voices[voices.publication_id.isin(base.publication_id)].copy() if len(voices) else voices.copy()
    if len(v):
        v=v.drop_duplicates(['publication_id','actor_key','role'])
        presence=v.drop_duplicates(['publication_id','role'])
        av=len(v);awv=v.sampling_weight.sum();pv=len(presence);pwv=presence.sampling_weight.sum()
    else:presence=v.copy();av=awv=pv=pwv=0
    rows=[]
    for role in ROLES:
        a=v[v.role==role] if len(v) else v
        p=presence[presence.role==role] if len(presence) else presence
        aw=float(a.sampling_weight.sum()) if len(a) else 0
        pw=float(p.sampling_weight.sum()) if len(p) else 0
        rows.append({'role':role,'label':ROLE_HR[role],'actor_role_n':len(a),'actor_role_weighted':aw,
          'actor_role_denominator':av,'actor_role_weighted_denominator':float(awv),
          'actor_role_share_pct':pct(len(a),av),'actor_role_share_weighted_pct':pct(aw,awv),
          'article_role_n':len(p),'article_role_weighted':pw,'article_role_denominator':pv,
          'article_role_weighted_denominator':float(pwv),'role_presence_share_pct':pct(len(p),pv),
          'role_presence_share_weighted_pct':pct(pw,pwv),'valid_articles':len(base),
          'valid_articles_weighted':float(base.sampling_weight.sum()),'article_prevalence_pct':pct(len(p),len(base)),
          'article_prevalence_weighted_pct':pct(pw,base.sampling_weight.sum())})
    return pd.DataFrame(rows)

def category_table(a,col,basecol):
    b=a[a[basecol]];den=len(b);wden=float(b.sampling_weight.sum())
    records=[]
    for k,sub in b.groupby(col):
        records.append({'category':k,'n':len(sub),'weighted_n':float(sub.sampling_weight.sum()),
          'denominator':den,'weighted_denominator':wden,'pct':pct(len(sub),den),
          'weighted_pct':pct(sub.sampling_weight.sum(),wden)})
    return pd.DataFrame(records)

def main(preview=False):
    freeze=json.loads((OUT/'freeze.json').read_text(encoding='utf-8'))
    chash=get_config_hash();db=sqlite3.connect(OUT/'coding.sqlite')
    results=[json.loads(r[0]) for r in db.execute('SELECT result_json FROM articles WHERE set_name=? AND config_hash=?',('main',chash))]
    if len(results)!=CFG['sample_size'] and not preview:raise RuntimeError(f'Only {len(results)} of {CFG["sample_size"]} main articles finished')
    smp=pd.read_parquet(OUT/'main_inputs.parquet')
    lookup={r['publication_id']:r for r in results}
    articles=[];voices=[];mentions=[];groups=[];evidence=[]
    for r in smp.to_dict('records'):
        pid=r['publication_id'];z=lookup.get(pid);common={k:r[k] for k in ['publication_id','outlet_name','outlet_id',
          'published_at','stratum','sampling_weight','inclusion_probability','text_length','input_hash','title','url']}
        a={**common,'processing_status':z['status'] if z else 'not_attempted','source_content':z['source_content'] if z else 'unresolved',
           'segments':z['segments_expected'] if z else 0,'mechanical_source_flags':json.dumps(z.get('mechanical_quality_flags',[]) if z else []),
           'relevance':z.get('relevance','unresolved') if z else 'unresolved',
           'main_theme':z.get('main_theme','unresolved') if z else 'unresolved','topic_disagreement':z.get('topic_disagreement',False) if z else False,
           'voices_n':len(z['voices']) if z else None,'mentions_n':len(z['mentions']) if z else None,
           'groups_described':bool(z['affected_groups']) if z else None,
           'speaker_decision_status':z.get('speaker_decision_status','not_processed') if z else 'not_processed',
           'unresolved_speaker_decisions':len(z.get('unresolved_speaker_decisions',[])) if z else None,
           'experience_voice':article_flag(z['voices'],'own_experience') if z and z['task_validity'].get('speakers') else None,
           'interpretation_voice':article_flag(z['voices'],'interprets_faith') if z and z['task_validity'].get('speakers') else None,
           'interpretation_flags_resolved':all(v['interprets_faith']!='unresolved' for v in z['voices']) if z else False}
        for task in ['topics','mentions','speakers','groups']:
            a[task+'_valid']=bool(z and z['task_validity'].get(task,False))
            a[task+'_base']=bool(z and z.get('complete_article_base',{}).get(task,False))
        a['experience_base']=a['speakers_base'] and a['experience_voice'] is not None
        a['interpretation_base']=a['speakers_base'] and a['interpretation_flags_resolved']
        articles.append(a)
        if not z:continue
        for field,target in [('voices',voices),('mentions',mentions),('affected_groups',groups)]:
            for i,item in enumerate(z[field]):
                t={**common,**item,'item_index':i,'task_valid':a[{'voices':'speakers','mentions':'mentions','affected_groups':'groups'}[field]+'_valid'],
                   'complete_article_base':a[{'voices':'speakers','mentions':'mentions','affected_groups':'groups'}[field]+'_base']}
                if field=='voices':t['actor_key']=item.get('actor_key',item['name'].strip().casefold()+'|'+item['organisation'].strip().casefold())
                for ids_key in ['evidence_ids','identity_ids','statement_ids','classification_evidence_ids']:
                    if ids_key in item:
                        t[ids_key]=json.dumps(item[ids_key],ensure_ascii=False)
                        spans=[{'id':x,'text':z['passages'][x]} for x in item[ids_key]]
                        t[ids_key.replace('_ids','_passages')]=json.dumps(spans,ensure_ascii=False)
                        evidence.extend({'publication_id':pid,'item_type':field,'item_index':i,'span_type':ids_key,**p} for p in spans)
                target.append(t)
    a=pd.DataFrame(articles)
    v=pd.DataFrame(voices) if voices else pd.DataFrame(columns=['publication_id','actor_key','role','sampling_weight',
             'interprets_faith','own_experience','complete_article_base','task_valid']).astype({'complete_article_base':'bool','task_valid':'bool'})
    csv(a,'articles.csv');csv(v,'voices.csv');csv(pd.DataFrame(mentions),'mentions.csv');csv(pd.DataFrame(groups),'affected_groups.csv')
    csv(pd.DataFrame(evidence),'evidence_passages.csv')
    roles=role_measures(a,v);csv(roles,'speaker_roles.csv')
    interpreters=role_measures(a.assign(speakers_base=a.interpretation_base),v[v.interprets_faith=='yes'] if len(v) else v);csv(interpreters,'interpreter_roles.csv')
    rel=category_table(a,'relevance','topics_base');csv(rel,'relevance.csv')
    themes=category_table(a,'main_theme','topics_base');csv(themes,'themes.csv')
    both=a[a.experience_base & a.groups_base]
    overlap=[]
    for described in [False,True]:
        for experienced in [False,True]:
            x=both[(both.groups_described==described)&(both.experience_voice==experienced)]
            overlap.append({'described':described,'experience_voice':experienced,'n':len(x),'weighted_n':float(x.sampling_weight.sum()),
              'denominator':len(both),'weighted_denominator':float(both.sampling_weight.sum()),
              'pct':pct(len(x),len(both)),'weighted_pct':pct(x.sampling_weight.sum(),both.sampling_weight.sum())})
    csv(pd.DataFrame(overlap),'experience_overlap.csv')
    failures=[]
    for variable in ['outlet_name','stratum','source_content','segments']:
        for label,z in a.groupby(variable):
            failures.append({'dimension':variable,'category':str(label),'sample_n':len(z),
              **{task+'_invalid':int((~z[task+'_valid']).sum()) for task in ['topics','mentions','speakers','groups']},
              'complete_speaker_base':int(z.speakers_base.sum())})
    a['length_band']=pd.cut(a.text_length,[-1,399,1999,4999,9999,19999,np.inf],labels=['<400','400-1999','2000-4999','5000-9999','10000-19999','20000+'])
    for label,z in a.groupby('length_band',observed=True):
        failures.append({'dimension':'length_band','category':str(label),'sample_n':len(z),
          **{task+'_invalid':int((~z[task+'_valid']).sum()) for task in ['topics','mentions','speakers','groups']},
          'complete_speaker_base':int(z.speakers_base.sum())})
    csv(pd.DataFrame(failures),'failure_patterns.csv')
    calls=pd.read_sql_query('SELECT set_name,publication_id,segment,task,attempt,status,error,seconds,config_hash FROM calls',db)
    csv(calls,'task_attempts.csv')
    from input_delivery import audit as audit_input_delivery
    delivery=pd.DataFrame(audit_input_delivery(db,results,chash))
    csv(delivery,'input_delivery.csv');db.close()
    frame=pd.read_parquet(OUT/'frame.parquet',columns=['publication_id','text_length','text_hash','outlet_name','outlet_id','published_at','title','url'])
    from reuse_cases import build as build_reuse_cases
    reuse_cases=build_reuse_cases(frame,OUT)
    eligible=frame[frame.text_length>=400];fam=eligible.groupby('text_hash').agg(n=('publication_id','size'),outlets=('outlet_id','nunique'))
    repeated=fam[fam.n>1];cross=fam[(fam.n>1)&(fam.outlets>1)]
    source=pd.read_csv(OUT/'tables'/'frame_source.csv');source['share_pct']=100*source.publications/len(frame)
    csv(source,'source_concentration.csv')
    bases={task:{'attempted':len(a),'structurally_valid':int(a[task+'_valid'].sum()),
       'complete_article_valid':int(a[task+'_base'].sum()),'weighted_complete_base':float(a.loc[a[task+'_base'],'sampling_weight'].sum())}
       for task in ['topics','mentions','speakers','groups']}
    summary={'run_id':CFG['run_id'],'config_hash':chash,'preview':preview,'frame':freeze,
      'analysis_sha256':file_sha(Path(__file__)),'analysis_packages':{'pandas':pd.__version__,'numpy':np.__version__},
      'sample':len(a),'completed_main':len(results),'bases':bases,'status_counts':a.processing_status.value_counts().to_dict(),
      'input_delivery_counts':delivery.coverage_status.value_counts().to_dict(),
      'source_content_counts':a.source_content.value_counts().to_dict(),'segmented_sample':int((a.segments>1).sum()),
      'unresolved_speaker_articles':int((a.speaker_decision_status=='unresolved').sum()),
      'interpretation_base':{'n':int(a.interpretation_base.sum()),'weighted_n':float(a.loc[a.interpretation_base,'sampling_weight'].sum())},
      'experience_base':{'n':int(a.experience_base.sum()),'weighted_n':float(a.loc[a.experience_base,'sampling_weight'].sum())},
      'topic_disagreements':int(a.topic_disagreement.sum()),'roles':roles.to_dict('records'),'interpreter_roles':interpreters.to_dict('records'),
      'relevance':rel.to_dict('records'),'themes':themes.to_dict('records'),'overlap':overlap,
      'top_source':source.iloc[0].to_dict(),'top5_source_share_pct':float(source.head(5).share_pct.sum()),
      'reuse':{'eligible_publications':len(eligible),'repeated_families':len(repeated),'publications_in_repeated_families':int(repeated.n.sum()),
        'cross_outlet_families':len(cross),'publications_in_cross_outlet_families':int(cross.n.sum())},
      'main_call_seconds':float(calls.loc[(calls.set_name=='main')&(calls.config_hash==chash),'seconds'].sum()),
      'no_speaker_complete':int(((a.voices_n==0)&a.speakers_base).sum()),
      'input_sha256':freeze['source_sha256'],'identities':'Conservative same surface name + stated organisation within article; no cross-article person ranking. Unresolved aliases may split appearances.'}
    # Purposeful cases: interpretation in text-supported academic role, experience, and a limiting zero-speaker case.
    cases=[];used=set()
    for kind,predicate in [('academic_interpretation',lambda z:any(v['role']=='academic_theologian' and v['interprets_faith']=='yes' for v in z['voices'])),
                           ('experienced_consequence',lambda z:bool(z['affected_groups']) and any(v['own_experience']=='yes' for v in z['voices'])),
                           ('mentions_without_voice',lambda z:len(z['mentions'])>=2 and not z['voices'])]:
        for row in a.sort_values('text_length').to_dict('records'):
            if row['publication_id'] in used or not row['speakers_base'] or row['text_length']<600:continue
            z=lookup[row['publication_id']]
            if not predicate(z):continue
            focus=[v for v in z['voices'] if (kind=='academic_interpretation' and v['role']=='academic_theologian' and v['interprets_faith']=='yes') or
                   (kind=='experienced_consequence' and v['own_experience']=='yes')][:1]
            ids=[]
            for x in focus:ids+=x['identity_ids'][:1]+x['statement_ids'][:1]
            if not ids:
                for x in z['mentions'][:2]:ids+=x['evidence_ids'][:1]
            ids=list(dict.fromkeys(ids))
            cases.append({'kind':kind,'publication_id':row['publication_id'],'title':row['title'],'url':row['url'],
              'outlet':row['outlet_name'],'date':row['published_at'],'voices':focus,'groups':z['affected_groups'],
              'passages':[{'id':x,'text':z['passages'][x]} for x in ids],
              'selection':'purposeful illustration from main sample; no extra prevalence denominator',
              'limitation':'local model selection and coding, no independent verification of article claims'})
            used.add(row['publication_id']);break
    save_json(OUT/'cases.json',cases)
    denom=[{'id':task+'_complete','definition':'Sample article with all task segments valid and apparently complete source'+
            ('; no explicitly unresolved candidate statement decisions' if task=='speakers' else ''),**base} for task,base in bases.items()]
    denom += [{'id':'frame_publications','n':len(frame),'definition':'Deduplicated in-window web publications in official captured corpus'},
              {'id':'interpretation_complete',**summary['interpretation_base'],'definition':'Complete valid speaker article with all retained voices resolved on interpretation'},
              {'id':'experience_complete',**summary['experience_base'],'definition':'Complete valid speaker article with resolved presence or absence of an experience voice'},
              {'id':'actor_role','n':int(roles.actor_role_denominator.iloc[0]),'weighted_n':float(roles.actor_role_weighted_denominator.iloc[0]),'definition':'Distinct article/surface actor/capacity appearances'},
              {'id':'article_role','n':int(roles.article_role_denominator.iloc[0]),'weighted_n':float(roles.article_role_weighted_denominator.iloc[0]),'definition':'Distinct article/capacity presences'}]
    save_json(OUT/'denominators.json',denom)
    claims=[]
    def claim(key,wording,table,num,den,scope,ids=None):
        claims.append({'id':key,'proposed_wording':wording,'supporting_table':table,'numerator':num,'denominator':den,
          'scope':scope,'article_ids':ids or [],'evidence_passages':'tables/evidence_passages.csv for identified cases',
          'alternative_explanations':'Collection coverage, retrieval selection, archive completeness and model error can affect the result.',
          'classification_limitations':'Machine-only local coding; no measured accuracy. Exact counts are exact only for the frozen retrieved frame.',
          'reader_implication':'Treat observed voice visibility as a guide to targeted research, not proof of theological credentials or social influence.',
          'confidence':'Frame counts reproducible; coded results exploratory because semantic error is unmeasured.'})
    claim('frame',f"U dohvaćenom okviru nalazi se {len(frame)} web objava.",'tables/frame_month.csv',len(frame),len(frame),'full frame')
    claim('source_concentration','Pet izvora nosi izračunani udio zabilježenih objava.','tables/source_concentration.csv',int(source.head(5).publications.sum()),len(frame),'full frame')
    for role in dict.fromkeys(['academic_theologian',str(roles.sort_values('article_prevalence_weighted_pct',ascending=False).iloc[0].role)]):
        row=roles[roles.role==role].iloc[0]
        claim('role_'+role,'Modelom utvrđena prisutnost uloge: '+ROLE_HR[role],'tables/speaker_roles.csv',float(row.article_role_weighted),float(row.valid_articles_weighted),'weighted complete-case sample')
    claim('exact_reuse','Dio objava dijeli identičan očišćeni tekst.','tables/exact_reuse_families.csv',int(repeated.n.sum()),len(eligible),'full frame, text >=400 characters')
    for case in reuse_cases:
        claim('exact_reuse_case_'+case['id'],'Odabrane objave imaju identičan spremljeni tekst.',
              'deterministic_reuse_cases.json',case['publications'],None,'purposeful full-frame metadata illustration',
              [x['publication_id'] for x in case['members']])
        claims[-1].update(evidence_passages='Frozen frame rows and exact text_hash; full bodies remain in frame.parquet',
            classification_limitations=case['limitation'],reader_implication='Text identity is distinct from copying direction and authorship.',
            confidence='Exact frozen-text identity; no semantic interpretation or live-page validation.')
    for row in interpreters.to_dict('records'):
        claim('interpretation_'+row['role'],'Modelom prepoznato tumačenje u ulozi: '+row['label'],'tables/interpreter_roles.csv',
              row['article_role_weighted'],row['valid_articles_weighted'],'weighted complete-case sample; interpretation flags resolved')
    for row in themes.to_dict('records'):
        claim('theme_'+row['category'],'Modelom prepoznata glavna tema: '+THEME_HR[row['category']],'tables/themes.csv',
              row['weighted_n'],row['weighted_denominator'],'weighted complete-case topic sample; unresolved is a separate category')
    for row in overlap:
        claim(f'experience_{int(row["described"])}_{int(row["experience_voice"])}','Presjek opisane skupine i iskustvenog glasa.',
              'tables/experience_overlap.csv',row['weighted_n'],row['weighted_denominator'],
              'weighted joint complete-case sample with resolved article-level experience')
    for case in cases:claim('case_'+case['kind'],'Ilustrativni slučaj: '+case['title'],'cases.json',None,None,'purposeful case',[case['publication_id']])
    policy_path=OUT/'report_policy.json'
    if policy_path.exists():
        policy=json.loads(policy_path.read_text(encoding='utf-8'))
        if policy['config_hash']!=chash:raise RuntimeError('Report policy/configuration mismatch')
        summary['report_policy']=policy
        for item in claims:
            model_claim=item['id'] not in {'frame','source_concentration','exact_reuse'} and not item['id'].startswith('exact_reuse_case_')
            item['publication_status']='withheld' if model_claim and not policy['model_content_numbers_eligible'] else 'eligible_exploratory'
            if item['publication_status']=='withheld':
                item['withdrawal_reason']='Primary machine checks failed; see report_policy.json. Retained for audit, not a report finding.'
    save_json(OUT/'claims.json',claims);save_json(OUT/'report_data.json',summary)
    print(json.dumps({'sample':len(a),'finished':len(results),'bases':bases,'cases':len(cases)},indent=2))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--preview',action='store_true');args=p.parse_args();main(args.preview)
