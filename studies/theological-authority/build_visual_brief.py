"""Fifteen research graphs, derived only from the validated local workbook data."""
from pathlib import Path
from collections import defaultdict
from textwrap import fill
from xml.sax.saxutils import escape
import csv, json, math, hashlib
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
from matplotlib.patches import Patch
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.colors import HexColor
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
import fitz

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
OUT=HERE/'output/private/extended'
QA=ROOT/'tmp/pdfs/actor-visual-brief'
QA.mkdir(parents=True,exist_ok=True)
DATA=json.loads((OUT/'workbook_data.json').read_text(encoding='utf-8'))
S=[r for r in DATA['overall'] if r['scope']=='selected']
A=[r for r in DATA['annual'] if r['scope']=='selected']
G=['church_media','church_org','independent','clergy','community','devotional']
LABEL=['Crkveni mediji','Crkvene ustanove i računi','Neovisni katolički mediji','Svećenički profili','Zajednice i udruge','Pobožni i autorski kanali']
GL=dict(zip(G,LABEL))
COLORS=['#234e70','#507f77','#c47e45','#826294','#8a913b','#b95f70']
GC=dict(zip(G,COLORS))
P=['facebook','youtube','web','instagram','twitter','tiktok']
PL={'facebook':'Facebook','youtube':'YouTube','web':'Web','instagram':'Instagram','twitter':'X/Twitter','tiktok':'TikTok','forum':'Forumi','comment':'Komentari','reddit':'Reddit'}
INK='#233b48';MUTED='#5c6c73';BLUE='#2f6e96';ORANGE='#b87543';LINE='#dce3e6'
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10,'axes.titlesize':11,'axes.labelsize':10,
 'axes.spines.top':False,'axes.spines.right':False,'axes.spines.left':False,
 'axes.edgecolor':LINE,'axes.labelcolor':INK,'text.color':INK,'xtick.color':MUTED,'ytick.color':INK,
 'pdf.fonttype':42,'savefig.facecolor':'white','axes.axisbelow':True})
def num(x,d=0):return 'n/p' if x is None else f'{x:,.{d}f}'.replace(',','X').replace('.',',').replace('X','.')
def total(rows,k):return sum(r[k] or 0 for r in rows)
def ranked(rows):return sorted((r for r in rows if r['total_interactions'] is not None),key=lambda r:(-r['total_interactions'],r['source_id'].encode('utf-8')))
def agg(rows):
 return {g:{'sources':sum(r['actor_group']==g for r in rows),
    **{k:total([r for r in rows if r['actor_group']==g],k) for k in ['posts','interaction_n','total_interactions']}} for g in G}
ALL=agg(S);graphs=[]
def figure():return plt.subplots(figsize=(7.1,6.7))
def finish(fig,title,scope,caption,tall=False):
 i=len(graphs)+1;file=QA/f'graph-{i:02d}.pdf'
 fig.savefig(file);plt.close(fig)
 graphs.append(dict(number=i,title=title,scope=scope,caption=caption,file=str(file),tall=tall))
def percent_axis(ax):
 ax.set_xlim(0,100);ax.xaxis.set_major_formatter(FuncFormatter(lambda x,p:f'{x:g} %'));ax.grid(axis='x',color=LINE,lw=.6)
def shares(rows,title,caption):
 a=agg(rows);fig,ax=figure();y=np.arange(6)
 for off,key,color,label in [(-.17,'posts',ORANGE,'Udio objava'),(.17,'total_interactions',BLUE,'Udio interakcija')]:
  den=total(rows,key);v=[100*a[g][key]/den if den else 0 for g in G]
  ax.barh(y+off,v,height=.3,color=color,label=label)
  for yi,val,g in zip(y+off,v,G):ax.text(val+1,yi,('nema objava' if a[g]['posts']==0 else num(val,1)+' %'),va='center',fontsize=9)
 ax.set_yticks(y,[fill(GL[g],23) for g in G]);ax.invert_yaxis();percent_axis(ax)
 ax.set_xlabel('Udio unutar odabranih komunikatora (%)');ax.legend(frameon=False,loc='upper center',bbox_to_anchor=(.45,-.14),ncol=2,fontsize=9)
 fig.subplots_adjust(left=.31,right=.94,top=.96,bottom=.22)
 finish(fig,title,'Odabrani komunikatori | 2021.-2025.',caption)

# 01: explicit inclusion flow (stages are nested, not additive).
fig,ax=figure();vals=[r['posts'] for r in DATA['flow']]
labels=['Ulazni zapisi','Datirani 2021.-2025.','Nakon obrade duplikata','Odabrane skupine aktera']
ax.barh(range(4),vals,color=[LINE,LINE,BLUE,ORANGE],height=.48)
for i,v in enumerate(vals):ax.text(v+9000,i,num(v),va='center',fontsize=11)
ax.set_yticks(range(4),[fill(l,22) for l in labels]);ax.invert_yaxis();ax.set_xlim(0,740000)
ax.xaxis.set_major_formatter(FuncFormatter(lambda x,p:num(x/1000)+' tis.'));ax.set_xlabel('Broj zapisa');ax.grid(axis='x',color=LINE,lw=.6)
fig.subplots_adjust(left=.32,right=.97,top=.9,bottom=.15)
finish(fig,'Od ulaznih podataka do odabranih aktera','Svi zapisi i odabrane skupine',
 'Od 612.065 ulaznih zapisa ostaje 601.036 zapisa nakon odabira godina i obrade duplikata. Odabrane skupine obuhvaćaju 153.015 objava; stupci su uzastopni koraci i ne zbrajaju se.')
# 02: source-label counts by draft group, with assignment provenance visible.
fig,ax=figure();left=np.zeros(6)
rules=[('existing_registry','Postojeći registar','#234e70'),
       ('inherited','Naslijeđeni popis','#507f77'),
       ('pattern','Obrazac naziva','#c47e45'),
       ('catalogue','Katalog oznaka','#826294')]
for kind,label,color in rules:
 def matches(rule):
  if kind=='existing_registry':return rule=='existing_registry'
  if kind=='pattern':return rule.endswith('_pattern')
  return rule.startswith(kind)
 values=[sum(r['actor_group']==g and matches(r['classification_rule']) for r in S) for g in G]
 ax.barh(range(6),values,left=left,color=color,height=.55,label=label)
 left+=values
assert list(left.astype(int))==[ALL[g]['sources'] for g in G]
assert sum(r['actor_group']=='devotional' and r['classification_rule']=='creator_pattern' for r in S)==483
for i,n in enumerate(left):ax.text(n+6,i,num(n),va='center')
ax.set_yticks(range(6),[fill(x,25) for x in LABEL]);ax.invert_yaxis();ax.set_xlim(0,max(left)*1.16)
ax.set_xlabel('Broj jedinstvenih parova platforma + oznaka izvora');ax.grid(axis='x',color=LINE,lw=.6)
ax.legend(frameon=False,ncol=2,loc='upper center',bbox_to_anchor=(.5,-.14),fontsize=9)
fig.subplots_adjust(left=.33,right=.97,bottom=.23,top=.96)
finish(fig,'Koliko je oznaka svrstano u koju skupinu?','722 para platforma + oznaka | radna klasifikacija | 2021.-2025.',
 'Oznake potječu iz postojećeg skupa objava, a boje pokazuju kako su razvrstane. Od 514 pobožnih i autorskih kanala, 483 su dodijeljena prema obrascu naziva; to nisu potvrđeni laički akteri.')
# 03: overall comparison, with cross-platform qualification.
shares(S,'Tko objavljuje, a tko prikuplja interakcije?',
 'Dva stupca za svaku skupinu uspoređuju njezin udio objava i interakcija. Ovo su sirovi zbrojevi preko platformi; za usporedbu aktera važniji su zasebni prikazi Facebooka, YouTubea i weba.')
# 04: platform composition.
fig,ax=figure();left=np.zeros(6)
for g in G:
 v=[100*total([r for r in S if r['platform']==p and r['actor_group']==g],'total_interactions')/total([r for r in S if r['platform']==p],'total_interactions') for p in P]
 ax.barh(range(6),v,left=left,color=GC[g],label=GL[g],height=.52);left+=v
ax.set_yticks(range(6),[PL[p]+'\nN = '+num(total([r for r in S if r['platform']==p],'total_interactions')) for p in P]);ax.invert_yaxis();percent_axis(ax);ax.set_xlabel('Udio zabilježenih interakcija (%)')
ax.legend(frameon=False,ncol=2,loc='upper center',bbox_to_anchor=(.45,-.15),fontsize=9)
fig.subplots_adjust(left=.23,right=.94,top=.96,bottom=.25)
finish(fig,'Različite platforme, različiti akteri','Odabrani komunikatori | 2021.-2025.',
 'Svaki red prikazuje raspodjelu interakcija unutar jedne platforme. N označava ukupan broj zabilježenih interakcija; jednaka širina redaka ne znači jednaku količinu pažnje.')
# 05-07: comparable platform views.
for p in ['facebook','youtube','web']:
 shares([r for r in S if r['platform']==p],f'{PL[p]}: vrste aktera i pažnja',
  f'Prikaz uspoređuje udjele objava i interakcija samo na platformi {PL[p]}. Veći udio interakcija od udjela objava upućuje na više interakcija po objavi u zabilježenom uzorku, ali ne dokazuje teološki autoritet.')
# 08: all-source collection coverage.
platforms=['web','facebook','youtube','instagram','twitter','tiktok','forum','reddit','comment'];years=list(range(2021,2026))
cov={(r['platform'],r['year']):r['months_observed'] for r in DATA['coverage'] if r['scope']=='all'}
matrix=np.array([[cov[p,y] for y in years] for p in platforms]);fig,ax=figure()
im=ax.imshow(matrix,cmap='Blues',vmin=0,vmax=12,aspect='auto')
for i in range(9):
 for j in range(5):ax.text(j,i,f'{matrix[i,j]}/12',ha='center',va='center',color='white' if matrix[i,j]>=8 else INK)
ax.set_xticks(range(5),years);ax.set_yticks(range(9),[PL[p] for p in platforms]);ax.set_xlabel('Godina');ax.tick_params(length=0)
fig.subplots_adjust(left=.2,right=.98,bottom=.13,top=.97)
finish(fig,'Koliko je mjeseci stvarno obuhvaćeno?','Svi zabilježeni izvori | mjeseci s barem jednom objavom',
 'Broj u ćeliji pokazuje koliko mjeseci ima barem jednu objavu. Ni 12/12 ne dokazuje potpuno prikupljanje; praznine i promjena prikupljanja tijekom 2024. ograničavaju vremenske usporedbe.')
# 09: annual totals, platform-specific scales.
fig,axs=plt.subplots(3,1,figsize=(7.1,6.7),sharex=True)
for ax,p in zip(axs,['facebook','youtube','web']):
 v=[total([r for r in A if r['platform']==p and r['year']==y],'total_interactions') for y in years]
 ax.bar(years,v,color=BLUE,width=.55);ax.set_title(PL[p],loc='left');ax.yaxis.set_major_formatter(FuncFormatter(lambda x,p:num(x/1e6,1)));ax.set_ylabel('mil. interakcija');ax.grid(axis='y',color=LINE,lw=.6)
 for y,n in zip(years,v):ax.text(y,n+max(v)*.035,num(n/1e6,2),ha='center',fontsize=9)
 ax.set_ylim(0,max(v)*1.27)
axs[-1].set_xticks(years,['2021','2022','2023','2024*','2025']);fig.subplots_adjust(left=.16,right=.98,top=.94,bottom=.09,hspace=.5)
finish(fig,'Kako se mijenja zabilježena pažnja?','Odabrani komunikatori | zasebna skala za svaku platformu',
 'Stupci prikazuju interakcije uz objave datirane u pojedinoj godini. *Godina 2024. ima praznine u prikupljanju; razlike među godinama mogu odražavati i promjene obuhvata, a ne samo ponašanje publike.')
# 10: composition across time.
fig,axs=plt.subplots(3,1,figsize=(7.1,6.7),sharex=True)
for ax,p in zip(axs,['facebook','youtube','web']):
 left=np.zeros(5)
 for g in G:
  v=[]
  for y in years:
   rr=[r for r in A if r['platform']==p and r['year']==y];den=total(rr,'total_interactions');v.append(100*total([r for r in rr if r['actor_group']==g],'total_interactions')/den)
  ax.bar(years,v,bottom=left,color=GC[g],width=.65);left+=v
 ax.set_title(PL[p],loc='left');ax.set_ylim(0,100);ax.set_yticks([0,50,100],['0 %','50 %','100 %'])
axs[-1].set_xticks(years,['2021','2022','2023','2024*','2025'])
fig.legend(handles=[Patch(color=GC[g],label=GL[g]) for g in G],loc='lower center',ncol=2,frameon=False,fontsize=9)
fig.subplots_adjust(left=.12,right=.98,top=.95,bottom=.18,hspace=.47)
finish(fig,'Mijenja li se sastav vodećih skupina?','Odabrani komunikatori | udio interakcija unutar platforme i godine',
 'Svaki stupac dijeli godišnje interakcije među šest skupina. Prikaz pomaže prepoznati promjene za daljnje istraživanje, ali ne prati isti skup izvora kroz vrijeme. *Obuhvat 2024. je nepotpun.')
# 11: concentration, disjoint segments.
fig,ax=figure();b=np.zeros(6)
for lo,hi,color,label in [(0,1,BLUE,'Prvi izvor'),(1,5,'#6594ad','Izvori 2-5'),(5,10,'#a4bfcd','Izvori 6-10'),(10,None,'#e0e8ec','Ostali')]:
 vals=[]
 for p in P:
  rr=ranked([r for r in S if r['platform']==p]);vals.append(100*total(rr[lo:hi],'total_interactions')/total(rr,'total_interactions'))
 ax.barh(range(6),vals,left=b,color=color,label=label,height=.55)
 for y,l,v in zip(range(6),b,vals):
  if v>=8:ax.text(l+v/2,y,num(v,1)+' %',ha='center',va='center',color='white' if lo==0 else INK,fontsize=9)
 b+=vals
ax.set_yticks(range(6),[PL[p]+f' (n={len(ranked([r for r in S if r["platform"]==p]))})' for p in P]);ax.invert_yaxis();percent_axis(ax);ax.set_xlabel('Udio zabilježenih interakcija (%)');ax.legend(frameon=False,ncol=2,loc='upper center',bbox_to_anchor=(.5,-.12))
fig.subplots_adjust(left=.25,right=.94,bottom=.22,top=.96)
finish(fig,'Koliko pažnje pripada malom broju izvora?','Odabrani komunikatori | izvori rangirani zasebno na svakoj platformi',
 'Red dijeli pažnju između prvog izvora, sljedeća četiri, sljedećih pet i ostalih. n je broj izvora s opaženim interakcijama. Velik prvi dio znači snažnu koncentraciju zabilježene pažnje.')
# 12: same overall top ten, annual ranks within platform.
top=ranked(S)[:50];top10=top[:10];amap={(r['source_id'],r['year']):r for r in A}
rankmat=np.array([[amap.get((s['source_id'],y),{}).get('platform_year_rank') or np.nan for y in years] for s in top10])
fig,ax=figure();cm=plt.get_cmap('Blues_r').copy();cm.set_bad('#eceff1')
im=ax.imshow(np.ma.masked_invalid(rankmat),cmap=cm,vmin=1,vmax=max(10,np.nanmax(rankmat)),aspect='auto')
for i in range(10):
 for j in range(5):
  v=rankmat[i,j];missing_label='nema\nobjava' if (top10[i]['source_id'],years[j]) not in amap else 'n/p'
  ax.text(j,i,missing_label if np.isnan(v) else str(int(v)),ha='center',va='center',color='white' if v<4 else INK,fontsize=9)
ax.set_xticks(range(5),years);ax.set_yticks(range(10),[s['source']+' ['+PL[s['platform']]+']' for s in top10],fontsize=9);ax.tick_params(length=0);ax.set_xlabel('Godina | 1 = najviše interakcija na vlastitoj platformi')
fig.subplots_adjust(left=.4,right=.98,top=.96,bottom=.12)
finish(fig,'Jesu li isti izvori vodeći svake godine?','Deset izvora iz ukupnog popisa | godišnji rang unutar vlastite platforme',
 'Praćen je isti skup od deset izvora kroz svih pet godina. Manji broj znači viši položaj na istoj platformi; „nema objava” znači da u tom skupu nisu zabilježene objave, a n/p da rang nije dostupan.')
# 13: matched windows, distinguish output volume from interaction volume.
fig,axs=plt.subplots(3,1,figsize=(7.1,6.7),sharex=True)
season=[r for r in DATA['seasonal'] if r['scope']=='selected' and r['cohort'].startswith('Isti izvori')]
for ax,p in zip(axs,['facebook','youtube','web']):
 r0=next(r for r in season if r['platform']==p and r['year']==2024);r1=next(r for r in season if r['platform']==p and r['year']==2025)
 keys=['posts','total_interactions','mean_interactions'];v=[100*r1[k]/r0[k] for k in keys]
 ax.barh(range(3),v,color=[ORANGE,BLUE,'#6594ad'],height=.5);ax.axvline(100,color=MUTED,lw=1,ls='--');ax.set_yticks(range(3),['Broj objava','Ukupne interakcije','Prosjek po objavi']);ax.invert_yaxis();ax.set_title(PL[p],loc='left');ax.grid(axis='x',color=LINE,lw=.6)
 for i,n in enumerate(v):ax.text(n+2,i,num(n,1),va='center',fontsize=9)
 ax.set_xlim(0,180)
axs[-1].set_xlabel('Indeks za srpanj-prosinac 2025. (isto razdoblje 2024. = 100)')
fig.subplots_adjust(left=.3,right=.97,top=.94,bottom=.1,hspace=.6)
finish(fig,'Usporedba istih izvora u drugoj polovici godine','Odabrani izvori s najmanje 5 objava u oba prozora | 2024. i 2025.',
 'Vrijednost iznad 100 znači više nego u istom razdoblju 2024. Odvajanje broja objava od prosjeka po objavi pomaže protumačiti rast ukupnih interakcija. Dob objava i uvjeti opažanja nisu izjednačeni.')
# 14-15: the same overall top 50, grouped by platform. Keep the original
# overall selection rank visible while sorting within each platform by interactions.
with (OUT/'source_ranking.csv').open(encoding='utf-8-sig',newline='') as stream:
 top_detail=list(csv.DictReader(stream))[:50]
assert [r['source_id'] for r in top_detail]==[r['source_id'] for r in top]
assert all(int(r['posts'])>0 and int(r['reach_n'])<=int(r['posts']) and int(r['interaction_n'])<=int(r['posts']) for r in top_detail)
assert len({r['source_id'] for r in top_detail})==50
platform_order=['facebook','instagram','web','youtube']
platform_groups={p:sorted((r for r in top_detail if r['SOURCE_TYPE']==p),
 key=lambda r:(-float(r['interactions']),r['source_id'].encode('utf-8'))) for p in platform_order}
assert sum(map(len,platform_groups.values()))==50
def source_panel(platforms,title):
 rows=[]
 for p in platforms:
  rows.append(('group',p,None))
  rows.extend(('source',p,r) for r in platform_groups[p])
 fig,ax=plt.subplots(figsize=(7.1,8.0))
 ax.set_xlim(0,100);ax.set_ylim(len(rows)+.8,-1.15);ax.axis('off')
 ax.text(1,-.6,'Ukupni rang i oznaka izvora',fontsize=8.4,fontweight='bold',va='center')
 ax.text(53,-.6,'Objave / članci',fontsize=8.4,fontweight='bold',ha='right',va='center')
 ax.text(75,-.6,'Doseg (zbroj)',fontsize=8.4,fontweight='bold',ha='right',va='center')
 ax.text(99,-.6,'Interakcije (zbroj)',fontsize=8.4,fontweight='bold',ha='right',va='center')
 ax.hlines(-.18,0,100,color=LINE,lw=1)
 for y,(kind,p,r) in enumerate(rows):
  if kind=='group':
   ax.axhspan(y-.25,y+.55,color='#edf2f4',zorder=0)
   ax.text(1,y+.15,f'{PL[p]}  |  {len(platform_groups[p])} izvora',fontsize=9.2,fontweight='bold',va='center')
   continue
  n_posts=int(r['posts']);n_reach=int(r['reach_n']);n_interactions=int(r['interaction_n'])
  name=f'{int(r["rank"]):02d}. {r["source"]}'
  ax.text(1,y,name if len(name)<42 else fill(name,40),fontsize=8.2,va='center')
  ax.text(53,y,num(n_posts),ha='right',va='center',fontsize=8.3)
  reach=None if n_reach==0 or r['reach_total'] in ('NA','') else float(r['reach_total'])
  reach_label=('n/p' if reach is None else num(reach))+('*' if n_reach<n_posts else '')
  ax.text(75,y,reach_label,ha='right',va='center',fontsize=8.3)
  platform_max=max(float(item['interactions']) for item in platform_groups[p])
  ax.barh(y,18*float(r['interactions'])/platform_max,left=81,height=.54,
          color='#d5e5ed',edgecolor='none',zorder=0)
  interactions_label=num(float(r['interactions']))+('*' if n_interactions<n_posts else '')
  ax.text(99,y,interactions_label,ha='right',va='center',fontsize=8.3,zorder=2)
  ax.hlines(y+.48,0,100,color=LINE,lw=.45)
 fig.subplots_adjust(left=.015,right=.985,top=.99,bottom=.01)
 finish(fig,title,'Odabrani ukupni top 50 | unutar platforme: interakcije silazno | 2021.-2025.',
  'Objave su web članci, videozapisi ili objave na mrežama. Doseg je zbroj procjena, a ne broj jedinstvenih ljudi; * označuje da mjera nedostaje za dio objava. Trake uspoređuju interakcije samo unutar iste platforme.',True)
source_panel(['facebook','instagram','web'],'Popis izvora: Facebook, Instagram i web')
source_panel(['youtube'],'Popis izvora: YouTube')

assert len(graphs)==15 and len(top)==50
for name,file in [('Body','calibri.ttf'),('Bold','calibrib.ttf'),('Title','georgia.ttf')]:pdfmetrics.registerFont(TTFont(name,'C:/Windows/Fonts/'+file))
style=ParagraphStyle('body',fontName='Body',fontSize=11,leading=15,textColor=HexColor(INK))
small=ParagraphStyle('small',fontName='Body',fontSize=9,leading=12,textColor=HexColor(MUTED))
title_style=ParagraphStyle('title',fontName='Title',fontSize=21,leading=26,textColor=HexColor(INK))
W,H=595.276,841.89
c=canvas.Canvas(str(QA/'layout.pdf'),pagesize=(W,H))
c.setTitle('Katolički komunikatori: 15 grafova za istraživanje');c.setAuthor('DigiKat - istraživački pregled')
def para(text,x,y,width,st):
 p=Paragraph(escape(text),st);_,h=p.wrap(width,1000);p.drawOn(c,x,H-y-h);return h
def footer(page):
 c.setStrokeColor(HexColor(LINE));c.line(42,43,W-42,43);c.setFont('Body',8);c.setFillColor(HexColor(MUTED))
 c.drawString(42,29,'DigiKat | raniji lokalni presjek | 2021.-2025.');c.drawRightString(W-42,29,str(page))
c.setFillColor(HexColor(BLUE));c.rect(42,H-62,44,4,fill=1,stroke=0)
para('Katolički komunikatori',42,95,510,ParagraphStyle('cover',parent=title_style,fontSize=29,leading=36))
para('15 grafova za istraživanje aktera, pažnje i mogućih izvora teološkog autoriteta',42,150,490,ParagraphStyle('cover-sub',parent=style,fontSize=17,leading=23))
para('2021.-2025. | raniji lokalni presjek DigiKat podataka',42,235,510,style)
for y,heading,body in [
 (300,'Što prikazuju grafovi?','Vrste aktera, zabilježene interakcije, raspodjelu pažnje, vremenske promjene i popis 50 izvora za daljnje čitanje.'),
 (390,'Što ovdje znači izvor?','Izvor je par platforme i normalizirane oznake FROM iz zapisa. Primjerice, web račun i Facebook profil broje se zasebno. Polazni podaci su povijesni lokalni presjek datoteke data/merged_comprehensive.rds; skupine su nacrt iz registara, popisa i obrazaca naziva.'),
 (495,'Što je sljedeće istraživačko pitanje?','Za procjenu teološkog autoriteta treba čitati objave: tumači li akter nauk, na što se poziva i ima li institucionalni mandat? Visok angažman sam ne daje te odgovore.')]:
 para(heading,42,y,510,ParagraphStyle('head',parent=style,fontName='Bold',fontSize=13));para(body,42,y+25,510,style)
para('Podaci: 612.065 ulaznih zapisa, datiranih od 2021-01-01 do 2026-01-06. Odabrani kalendarski prozor ne jamči potpunost prikupljanja. Noviji službeni korpus s 413.985 zapisa nije korišten.',42,610,510,small)
para('Javni agregati po vrstama aktera postoje u zasebnoj analizi službenog korpusa. Ovaj pregled koristi podatke radne knjige i ne spaja njihove rezultate.',42,665,510,small)
c.linkURL('https://github.com/lusiki/DigiKat/blob/main/studies/catholic-influencers/output/tables/actor_counts.csv',(42,H-727,553,H-709),relative=0)
para('Otvoreni agregati: github.com/lusiki/DigiKat - actor_counts.csv (poveznica)',42,710,510,small)
para('SHA-256 ulaza: '+DATA['input']['sha256'],42,745,510,ParagraphStyle('hash',parent=small,fontSize=7.5,leading=10))
footer(1);c.showPage()
rectangles=[]
for g in graphs:
 c.setFont('Bold',10);c.setFillColor(HexColor(BLUE));c.drawString(42,H-52,f'GRAF {g["number"]:02d} / 15')
 para(g['title'],42,70,511,title_style);para(g['scope'],42,125 if not g['tall'] else 115,511,small)
 rect=fitz.Rect(42,155,553,659) if not g['tall'] else fitz.Rect(42,139,553,716)
 rectangles.append(rect)
 para(g['caption'],42,686 if not g['tall'] else 730,511,style)
 footer(g['number']+1);c.showPage()
c.save()
doc=fitz.open(QA/'layout.pdf')
for i,g in enumerate(graphs):
 chart=fitz.open(g['file']);doc[i+1].show_pdf_page(rectangles[i],chart,0);chart.close()
target=OUT/'katolicki-komunikatori-15-grafova.pdf'
doc.save(target,garbage=4,deflate=True);doc.close()
(QA/'graphs.json').write_text(json.dumps(graphs,ensure_ascii=False,indent=2),encoding='utf-8')
print(target)
