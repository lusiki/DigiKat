"""Named web appearances, outlets and lexical profiles from frozen private evidence.

The ranked unit is an organisation x canonical web URL with a prominent name
match, using the existing restricted selector and documented contextual rules.
No new database scan, source mutation, topic refit or human labels.
"""
from pathlib import Path
from collections import Counter
import hashlib, json, re, sys
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import prepare as base

HERE=base.HERE; P=base.P; A=base.A
NAMES={1147:'Udruga slijepih Međimurske županije',4553:'SKAC Palma',
15343:'Hrvatsko društvo katoličkih novinara',62177:'Moje mjesto pod suncem',
15417:'Hrvatsko katoličko liječničko društvo',53291:'Matica hrvatska u Jastrebarskom',
60490:'Ime dobrote',8013:'Breza',14130:'Sunce',53102:'Alfa Albona',
58492:'SKAC Split',42673:'Korablja',57750:'Humanitarna udruga fra Mladen Hrkać'}
DISPLAY_STOP=set('image larger view webmaster posted vijesti sklopu hdkn hkld alfa albona sunce mladen hrkac gordana jelic skrabe nikole hrvatskoga hrvatskog hrvatsko katolickih katolickog katolicko novinara lijecnickog svibnja lipnja rujna listopada studenoga prosinca sijecnja veljace ozujka travnja srpnja kolovoza petak cetvrtak srijedu utorak ponedjeljak subotu nedjelju godinu godine godina'.split())
base.ACCENTS.update({'vjezbe':'vježbe','medimurske':'međimurske','cakovec':'Čakovec','siromastva':'siromaštva','drustvenih':'društvenih','podruznica':'podružnica','podruznice':'podružnice','uzivo':'uživo','zastite':'zaštite','okolis':'okoliš','okolisa':'okoliša','bolnickom':'bolničkom','kazaliste':'kazalište','urednistvo':'uredništvo','ljecenje':'liječenje','lijecenje':'liječenje'})
PROFILE_TERMS={4553:['mlade','prijave','duhovne','vjezbe'],1147:['slijepih','aktivnosti','provodi','projekta'],
62177:['siromastva','program','djece','dijaloga'],15343:['komunikacija','medija','nagrade','priznanja'],
15417:['podruznica','zivota','medicine','skup'],53291:['program','poetsko','glazbeni','kazaliste'],
60490:['progledaj','srcem','misa','radionice'],14130:['otpada','mora','okolisa','organizira'],
53102:['projekta','mladih','radionice','aktivnosti'],57750:['projekta','provodi','volonterka','bolnickom']}
ARCHIVE=re.compile(r'/(?:tag|tags|category|categories|author|page|oznaka|oznake|kategorija|kategorije)/',re.I)
BREZA=re.compile(r'\b(?:osije\w*|breza hr|zemlja bez granica|socijalno terapij\w*)\b')
SUNCE_PROGRAM=re.compile(r'\b(?:cekade|socijaln\w*|sirom\w*|rijek\w*|rijeck\w*|inkluz\w*)\b')

def n(x):return base.num(x)
def pct(x):return f'{x:.1f}'.replace('.',',')
def table(headers,rows):
    return '\n'.join(['| '+' | '.join(headers)+' |','| '+' | '.join(['---']*len(headers))+' |']+['| '+' | '.join(map(str,r))+' |' for r in rows])

def profile_chart(top,theme):
    labels={1147:'Slijepi Međimurje',15343:'Katolički novinari',15417:'Katolički liječnici',53291:'Matica Jastrebarsko',57750:'Udruga fra Mladen Hrkać'}
    ids=list(top.association_id);totals=theme.groupby('association_id').analysed_publications.first()
    fig,ax=plt.subplots(figsize=(8,4.6));left=np.zeros(len(ids))
    for topic in range(1,7):
        vals=[float(theme[(theme.association_id==i)&(theme.topic==topic)].share_pct.sum()) for i in ids]
        ax.barh(range(len(ids)),vals,left=left,color=base.PALETTE[topic-1],label=base.LABELS[topic]);left+=vals
    ax.set_yticks(range(len(ids)),[labels.get(i,NAMES[i])+' (n='+n(totals.get(i,0))+')' for i in ids],fontsize=10)
    ax.invert_yaxis();ax.set_xlim(0,100);ax.set_xlabel('Udio tekstualno analiziranih objava (%)',fontsize=10)
    ax.spines[['top','right','left']].set_visible(False)
    ax.legend(loc='upper center',bbox_to_anchor=(.35,-.19),ncol=2,frameon=False,fontsize=10)
    base.save('organisation-topics',fig)

def main():
    register=pd.read_csv(P/'organisation_landscape.csv').set_index('association_id')
    selected=[]; audit=Counter()
    for line in (P/'pair_evidence.jsonl').open(encoding='utf-8'):
        r=json.loads(line); oid=int(r['association_id'])
        if r['platform']!='web' or not r['restricted_candidate'] or not r['title_or_lead']:continue
        audit['prominent_restricted_web_pairs']+=1
        if ARCHIVE.search(r['url'] or '') or 'je poveznica prema kojoj' in r['context']:
            audit['archive_pages_removed']+=1;continue
        if oid==8013 and not BREZA.search(r['context']):
            audit['breza_without_osijek_context']+=1;continue
        if oid==62177 and not SUNCE_PROGRAM.search(r['context']):
            audit['sunce_program_without_local_social_context']+=1;continue
        selected.append({k:r[k] for k in ['item_key','url_key','date','domain','association_id']})
    d=pd.DataFrame(selected);d['association_id']=d.association_id.astype(int)
    d=d.sort_values(['date','item_key']).drop_duplicates(['association_id','url_key'])
    ranked=d.groupby('association_id').agg(web_publications=('url_key','size'),web_domains=('domain','nunique'))
    ranked['name']=[NAMES.get(i,register.loc[i,'name']) for i in ranked.index]
    ranked=ranked.sort_values(['web_publications','name'],ascending=[False,True]).reset_index()
    ranked.insert(0,'rank',range(1,len(ranked)+1))
    ranked.to_csv(A/'organisation_ranking.csv',index=False)
    top=ranked.head(10); ids=list(top.association_id)
    focal=d[d.association_id.isin(ids)]
    outlets=focal.groupby(['association_id','domain']).size().rename('web_publications').reset_index()
    outlets=outlets.merge(top[['association_id','name','web_publications']].rename(columns={'web_publications':'organisation_total'}),on='association_id')
    outlets['share_pct']=100*outlets.web_publications/outlets.organisation_total
    outlets=outlets.sort_values(['association_id','web_publications','domain'],ascending=[True,False,True])
    outlets.to_csv(A/'organisation_outlets.csv',index=False)
    global_outlets=d.drop_duplicates('url_key').groupby('domain').size().sort_values(ascending=False).rename('web_publications').reset_index()
    global_outlets.to_csv(A/'prominent_web_outlets.csv',index=False)
    _,documents=base.text_aggregates(return_documents=True)
    assignments=pd.read_csv(P/'repeat_check_assignments.csv')[['item_key','topic']]
    linked=focal.merge(assignments,on='item_key',validate='many_to_one')
    theme=linked.groupby(['association_id','topic']).size().rename('web_publications').reset_index()
    totals=linked.groupby('association_id').size()
    theme['analysed_publications']=theme.association_id.map(totals)
    theme['share_pct']=100*theme.web_publications/theme.analysed_publications
    theme['label']=theme.topic.map(base.LABELS)
    theme.to_csv(A/'organisation_topics.csv',index=False)
    frequencies=[];facts={}
    for row in top.itertuples():
        org=row.association_id; subset=focal[focal.association_id==org]
        counts=Counter()
        for key in subset.item_key:
            if key in documents:counts.update(sorted(documents[key]))
        denom=int(totals.get(org,0))
        for word,count in counts.most_common():
            frequencies.append({'association_id':org,'term':word,'web_publications':count,'analysed_publications':denom,'share_pct':100*count/denom})
        sources=outlets[outlets.association_id==org].head(3)
        th=theme[theme.association_id==org].sort_values('web_publications',ascending=False).iloc[0]
        display=[(w,c) for w,c in counts.most_common() if w not in DISPLAY_STOP][:8]
        facts[str(org)]={'name':row.name,'n':n(row.web_publications),'domains':n(row.web_domains),'lexical_n':n(denom),
            'sources':'; '.join(f'{r.domain} ({n(r.web_publications)})' for r in sources.itertuples()),
            'top_source':sources.iloc[0].domain,'top_source_n':n(sources.iloc[0].web_publications),'top_source_pct':pct(sources.iloc[0].share_pct),
            'topic':th['label'],'topic_n':n(th.web_publications),'topic_pct':pct(th.share_pct),
            'words':', '.join(f'{base.ACCENTS.get(w,w)} ({n(c)})' for w,c in display)}
    worddf=pd.DataFrame(frequencies);worddf.to_csv(A/'organisation_words.csv',index=False)
    # Compact facts and tables expanded by the PDF builder; no row keys or texts.
    snippets={}
    for oid,data in facts.items():
        for key,value in data.items():snippets[f'org:{oid}:{key}']=str(value)
    snippets['rank_table']=table(['Naziv','Objave','Domene'],[[r.name,n(r.web_publications),n(r.web_domains)] for r in top.itertuples()])
    snippets['outlet_table']=table(['Naziv','Tri najzastupljenije domene (broj objava)'],[[facts[str(i)]['name'],facts[str(i)]['sources']] for i in ids])
    snippets['profile_topic_table']=table(['Naziv','Najizraženija tema','Udio'],[[facts[str(i)]['name'],facts[str(i)]['topic'],facts[str(i)]['topic_pct']+'%'] for i in ids])
    index=worddf.set_index(['association_id','term']).web_publications
    snippets['profile_word_table']=table(['Naziv','Odabrane riječi (broj objava)'],[[facts[str(i)]['name'],', '.join(base.ACCENTS.get(w,w)+' ('+n(index.loc[(i,w)])+')' for w in PROFILE_TERMS[i])] for i in ids])
    snippets.update({'rank_n':n(len(d)),'rank_unique':n(d.url_key.nunique()),'rank_orgs':n(d.association_id.nunique()),
        'rank_top10_share':pct(100*top.web_publications.sum()/len(d)),
        'rank_top10_n':n(top.web_publications.sum())})
    for r in outlets.itertuples():snippets[f'outlet:{r.association_id}:{r.domain}']=n(r.web_publications)
    for r in worddf.itertuples():snippets[f'orgword:{r.association_id}:{r.term}']=n(r.web_publications)
    for r in theme.itertuples():
        snippets[f'orgtopic:{r.association_id}:{r.topic}:n']=n(r.web_publications)
        snippets[f'orgtopic:{r.association_id}:{r.topic}:pct']=pct(r.share_pct)
    (A/'organisation_facts.json').write_text(json.dumps(snippets,ensure_ascii=False,indent=2),encoding='utf-8')
    base.bars('top-organisations',top.name.tolist(),top.web_publications.tolist(),'Mrežne objave s nazivom u naslovu ili uvodu')
    base.bars('top-outlets',global_outlets.head(8).domain.tolist(),global_outlets.head(8).web_publications.tolist(),'Mrežne objave s istaknutim nazivima udruga')
    profile_chart(top,theme)
    # Private membership makes every aggregate reproducible without exposing URLs.
    d.to_csv(P/'reader_rank_membership.csv',index=False)
    method={'unit':'organisation x canonical web URL; earliest retained publication-day',
        'selection':'existing restricted_candidate and title_or_lead; web only; exclude archive URL paths and explicit tag-page text',
        'title_or_lead':'name occurs in title or first 800 normalised body characters',
        'context_rules':{'8013':BREZA.pattern,'62177':SUNCE_PROGRAM.pattern},
        'selection_audit':dict(audit),'rank_pairs':len(d),'unique_web_urls':d.url_key.nunique(),'names':d.association_id.nunique(),
        'word_unit':'once per retained text context; existing name masking and repeat suppression',
        'word_display_exclusions':sorted(DISPLAY_STOP),
        'profile_table_terms':PROFILE_TERMS,
        'topic_denominator':'organisation-specific retained text contexts, printed as n; frozen six-topic assignments',
        'human_validation_claimed':False,
        'inputs':{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in [P/'pair_evidence.jsonl',P/'repeat_check_assignments.csv',P/'rules.csv']}}
    (A/'organisation_method.json').write_text(json.dumps(method,ensure_ascii=False,indent=2),encoding='utf-8')
    print(top.to_string(index=False))
    print(json.dumps(facts,ensure_ascii=False,indent=2))
    print('Rank pairs / unique URLs / names',len(d),d.url_key.nunique(),d.association_id.nunique())

if __name__=='__main__':
    if '--figures-only' in sys.argv:profile_chart(pd.read_csv(A/'organisation_ranking.csv').head(10),pd.read_csv(A/'organisation_topics.csv'))
    else:main()
