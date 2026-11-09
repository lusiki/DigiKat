"""Rebuild Croatian reader-report aggregates from the frozen exploratory release.

No database access, new identity labels, or model refit. Restricted text stays private.
"""
from pathlib import Path
import collections, hashlib, importlib.util, json, re
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
STUDY = HERE.parent
ROOT = STUDY.parents[1]
P = STUDY/'output/private/media/v1'
T = STUDY/'output/tables/media-v1'
A = HERE/'tables'
F = HERE/'figures'
for folder in (A,F): folder.mkdir(parents=True,exist_ok=True)
spec = importlib.util.spec_from_file_location('base_topics',STUDY/'media/03_topics.py')
base = importlib.util.module_from_spec(spec); spec.loader.exec_module(base)
INK='#173e43'; TEAL='#789d96'; ORANGE='#b6592b'; PAPER='#fcfbf7'
PALETTE=[INK, '#417d83', '#9fbbb0', ORANGE, '#d2a577', '#7e829b']
CLOUD_PALETTE=[INK, '#417d83', '#52786c', ORANGE, '#916337', '#656985']
LABELS={1:'Projekti i partnerstva',2:'Vjerski susreti i najave',3:'Razgovorni jezik i pomoć',4:'Ratno sjećanje i branitelji',5:'Manjinska kultura i Istra',6:'Festivali i radionice'}
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10,'text.color':INK,'axes.labelcolor':INK,'xtick.color':INK,'ytick.color':INK,'axes.edgecolor':'#c5d4d0','figure.facecolor':PAPER,'axes.facecolor':PAPER,'savefig.facecolor':PAPER})
def num(x): return f'{int(x):,}'.replace(',','.')
def save(name,fig):
    fig.savefig(F/f'{name}.png',dpi=220,bbox_inches='tight'); fig.savefig(F/f'{name}.svg',bbox_inches='tight'); plt.close(fig)
def bars(name,labels,values,xlabel,percentage=False):
    fig,ax=plt.subplots(figsize=(8,3.7)); yy=np.arange(len(labels))
    ax.barh(yy,values,color=[INK if i<3 else TEAL for i in yy],height=.65)
    ax.set_yticks(yy,labels);ax.invert_yaxis();ax.set_xlim(0,max(values)*1.23)
    for y,v in zip(yy,values):ax.text(v+max(values)*.015,y,(f'{v:.1f}%'.replace('.',',') if percentage else num(v)),va='center',fontsize=10)
    ax.set_xlabel(xlabel);ax.spines[['top','right','left']].set_visible(False);ax.tick_params(axis='y',length=0);ax.set_axisbelow(True);ax.grid(axis='x',alpha=.18)
    save(name,fig)

def text_aggregates(return_documents=False):
    byitem={}
    with (P/'pair_evidence.jsonl').open(encoding='utf-8') as f:
        for line in f:
            r=json.loads(line)
            if not r['restricted_candidate'] or len(r['context'].split())<15:continue
            byitem.setdefault(r['item_key'],[]).append(r['context'])
    phrases=sorted(set(pd.read_csv(P/'rules.csv').phrase),key=len,reverse=True)
    entity=re.compile(r'\b(?:'+'|'.join(re.escape(x) for x in phrases)+r')\b')
    tokens={k:entity.sub(' ',re.sub(r'\b\w*\d\w*\b',' ',' '.join(dict.fromkeys(v)))).split() for k,v in byitem.items()}
    def shingles(ts):return [hashlib.blake2b(' '.join(ts[i:i+8]).encode(),digest_size=8).digest() for i in range(max(0,len(ts)-7))]
    freq=collections.Counter()
    for ts in tokens.values():freq.update(set(shingles(ts)))
    repeated={s for s,n in freq.items() if n>=20}
    stop=set(base.STOP)|{'iban','swift','bank','paypal','gmail','adresa','kontakt','kanal','subscribe','com','www','http','https'}
    assignments=pd.read_csv(P/'repeat_check_assignments.csv').set_index('item_key')
    counts={i:collections.Counter() for i in range(7)}
    # Display exclusions remove residual function words and isolated retrieval-name fragments.
    display_stop=set('sto ove ovog ovih ovoga kojoj kojima koje koji kako kad neka nije ovo danas svojim svoje svih svima svega sada ima imaju biti biti ce nas nasa nase nasi vrlo jos vec vise nesto netko zato jer te od do se ili bila bio bilo ali tako samo skac palma breza korablja matice matica krug kruga hrvatskoj zagrebu istarske zupanije grada prof fra ika'.split())
    retained=set(); documents={}
    for key,ts in tokens.items():
        mask=np.zeros(len(ts),dtype=bool)
        for i,sh in enumerate(shingles(ts)):
            if sh in repeated:mask[i:i+8]=True
        words=[t for i,t in enumerate(ts) if not mask[i] and t not in stop and re.fullmatch('[a-z]{3,}',t)]
        if len(words)<15:continue
        retained.add(key); topic=int(assignments.loc[key,'topic'])
        unique=set(words)-display_stop
        documents[key]=unique
        counts[0].update(sorted(unique)); counts[topic].update(sorted(unique))
    assert retained==set(assignments.index)
    assert len(retained)==18938
    rows=[{'topic':topic,'term':term,'publication_days':count} for topic,c in counts.items() for term,count in c.most_common()]
    pd.DataFrame(rows).to_csv(A/'word_document_frequency.csv',index=False)
    totals=assignments.topic.value_counts().sort_index()
    pd.DataFrame([{'topic':i,'label':LABELS[i],'items':int(n),'share_pct':n/len(retained)*100} for i,n in totals.items()]).to_csv(A/'topics.csv',index=False)
    (A/'lexical_method.json').write_text(json.dumps({'input_context_items':len(tokens),'retained_items':len(retained),'repeated_8grams':len(repeated),'count_unit':'word once per candidate publication-day; accent-folded surface forms; not lemmatised','display_stop':sorted(display_stop),'topic_model':'existing six-topic repeat-suppression diagnostic; no refit','human_validated':False},ensure_ascii=False,indent=2),encoding='utf-8')
    return (counts,documents) if return_documents else counts

FONT=Path(matplotlib.get_data_path())/'fonts/ttf/DejaVuSans.ttf'
ACCENTS={'pomoc':'pomoć','ljudi':'ljudi','djeca':'djeca','djecu':'djecu','odrzati':'održati','zivot':'život','zivota':'života','zajednistvo':'zajedništvo','svecenik':'svećenik','clanovi':'članovi','ucenici':'učenici','skole':'škole','skola':'škola','podrucju':'području','drustva':'društva','drustvo':'društvo','branitelja':'branitelja','sudjelovali':'sudjelovali','podrske':'podrške','podrsku':'podršku','odrzan':'održan','odrzana':'održana','odrzava':'održava','sredisnja':'središnja','zupanija':'županija','medunarodni':'međunarodni','razlicitih':'različitih','djecje':'dječje','knjizevnosti':'književnosti','obicno':'obično','vecer':'večer','mjeseca':'mjeseca','ucenja':'učenja','zajednicki':'zajednički','svijest':'svijest','zeli':'želi','moze':'može','mogu':'mogu','hrvatskih':'hrvatskih'}
ACCENTS.update({'nacin':'način','mozete':'možete','pomoci':'pomoći','sjecanja':'sjećanja','zupaniji':'županiji','opcine':'općine','zupe':'župe','madarsko':'mađarsko'})
def cloud(counter,name,limit=40):
    # Deterministic horizontal cloud. Font size encodes document frequency.
    canvas=Image.new('RGB',(1600,650),PAPER); draw=ImageDraw.Draw(canvas)
    taken=[]; shown=[]; words=counter.most_common(limit); vmax=words[0][1]
    rng=np.random.default_rng(23)
    for rank,(word,value) in enumerate(words):
        font=ImageFont.truetype(str(FONT),int(25+65*(value/vmax)**.7))
        label=ACCENTS.get(word,word); bb=draw.textbbox((0,0),label,font=font);w,h=bb[2],bb[3]-bb[1]
        placed=False
        for attempt in range(3500):
            if rank==0 and attempt==0:x,y=(1600-w)//2,(650-h)//2
            else:x=int(rng.integers(15,max(16,1585-w)));y=int(rng.integers(15,max(16,635-h)))
            box=(x-8,y-7,x+w+8,y+h+7)
            if any(not(box[2]<b[0] or box[0]>b[2] or box[3]<b[1] or box[1]>b[3]) for b in taken):continue
            draw.text((x,y-bb[1]),label,font=font,fill=CLOUD_PALETTE[rank%len(CLOUD_PALETTE)]);taken.append(box);shown.append((word,value));placed=True;break
        if not placed:continue
    canvas.save(F/f'{name}.png')
    return shown

def main():
    counts=text_aggregates()
    displayed=[]
    for i in range(7):
        for term,n in cloud(counts[i],f'cloud-{i}',40 if i==0 else 22): displayed.append({'topic':i,'term':term,'publication_days':n})
    pd.DataFrame(displayed).to_csv(A/'cloud_displayed_terms.csv',index=False)
    s=json.loads((T/'summary.json').read_text())
    county=pd.read_csv(T/'county_landscape.csv').sort_values('registered',ascending=False).head(7)
    bars('geography',county.county.tolist(),county.registered.tolist(),'Broj registriranih sjedišta')
    platform=pd.read_csv(T/'platform_landscape.csv').sort_values('candidate_items',ascending=False)
    labels={'web':'Mrežne stranice','facebook':'Facebook','youtube':'YouTube','radio':'Radio','print':'Tisak','tv':'Televizija','forum':'Forumi'}
    top=platform.head(6)
    bars('platforms',[labels[x] for x in top.platform],top.candidate_items.tolist(),'Objave povezane s nazivima udruga')
    topics=pd.read_csv(A/'topics.csv').sort_values('items',ascending=False)
    bars('topics',topics.label.tolist(),topics['share_pct'].tolist(),'Udio u 18.938 tekstualnih konteksta (%)',True)
    monthly=pd.read_csv(T/'monthly_landscape.csv').groupby('month',as_index=False)[['candidate_items','rows']].sum()
    fig,ax=plt.subplots(figsize=(8,3.3))
    dates=pd.to_datetime(monthly.month)
    ax.plot(dates,monthly.candidate_items,color=INK,lw=1.7)
    ax.set_ylabel('Objave uz nazive udruga');ax.spines[['top','right']].set_visible(False)
    ax.set_xlim(dates.min(),pd.Timestamp('2026-10-01'));fig.tight_layout();save('timeline',fig)
    channels=pd.read_csv(T/'repeat_check_channels.csv')
    groups=['web','facebook','youtube','radio','print']
    fig,ax=plt.subplots(figsize=(8,4.3));left=np.zeros(len(groups));denoms=[]
    for g in groups:denoms.append(int(channels[channels.platform==g]['items'].sum()))
    for i in range(1,7):
        v=[channels[(channels.platform==g)&(channels.topic==i)]['items'].sum()/d*100 for g,d in zip(groups,denoms)]
        ax.barh(range(len(groups)),v,left=left,color=PALETTE[i-1],label=LABELS[i]);left+=v
    ax.set_yticks(range(len(groups)),[labels[g]+' (n='+num(d)+')' for g,d in zip(groups,denoms)]);ax.invert_yaxis();ax.set_xlabel('Udio unutar analiziranog dijela platforme (%)');ax.set_xlim(0,100);ax.spines[['top','right','left']].set_visible(False)
    ax.legend(loc='upper center',bbox_to_anchor=(.35,-.21),ncol=2,frameon=False,fontsize=9);save('topic-platforms',fig)
    annual=pd.read_csv(T/'annual_landscape.csv');assert annual.candidate_items.sum()==23436;assert platform.candidate_items.sum()==23436
    assert int(topics['items'].sum())==18938
    manifest={'source_snapshot_records':int(annual.monitored_records.sum()),'register_entries':1325,'candidate_items':23436,'topic_items':18938,'human_validated_pairs':0,'source_hashes':{str(f.relative_to(STUDY)):hashlib.sha256(f.read_bytes()).hexdigest() for f in [T/'summary.json',T/'annual_landscape.csv',T/'repeat_check_channels.csv',P/'repeat_check_assignments.csv',P/'pair_evidence.jsonl']}}
    (A/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print('Prepared Croatian figures, word frequencies and checked denominators.')
    print(pd.read_csv(A/'topics.csv').to_string(index=False))
    print('Top words:',counts[0].most_common(15))
if __name__=='__main__':main()
