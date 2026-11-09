"""Standalone vector charts generated from released aggregates."""
from pathlib import Path
import json,textwrap
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import font_manager as fm
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.ticker import FuncFormatter
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'output/demokrscanstvo-analysis/v1';FIG=OUT/'figures';FIG.mkdir(exist_ok=True)
INK='#173e43';COPPER='#a9643b';PALE='#dae6df';MUTED='#607376'
for f in ['calibri.ttf','calibrib.ttf']:fm.fontManager.addfont('C:/Windows/Fonts/'+f)
plt.rcParams.update({'font.family':'Calibri','font.size':11,'axes.spines.top':False,'axes.spines.right':False,
    'axes.spines.left':False,'axes.edgecolor':'#cdd9d4','text.color':INK,'axes.labelcolor':INK,'xtick.color':MUTED,'ytick.color':INK,
    'savefig.facecolor':'white','svg.fonttype':'path','axes.titleweight':'bold','axes.titlesize':12,'xtick.labelsize':10,'ytick.labelsize':10.4})
def read(name):return pd.read_csv(OUT/(name+'.csv'))
def save(fig,name):
    for ax in fig.axes:
        if name in ('02-topics','03-repetition','07-lexical'):
            ax.xaxis.set_major_formatter(FuncFormatter(lambda v,pos: f'{v:g}'.replace('.',',')))
    fig.savefig(FIG/(name+'.svg'),bbox_inches='tight',pad_inches=.12)
    fig.savefig(FIG/(name+'.png'),dpi=180,bbox_inches='tight',pad_inches=.12);plt.close(fig)
def wrap(x,n=30):return '\n'.join(textwrap.wrap(x,n))

t=read('timeline');x=pd.to_datetime(t.month);br=pd.Timestamp('2024-04-01')
fig,axes=plt.subplots(2,1,figsize=(7.1,4.1),sharex=True,layout='constrained')
for ax,col,title in zip(axes,['publications','per_10000'],['Broj automatski uključenih zapisa','Zapisi na 10.000 pretraživih zapisa']):
    for mask in (x<br,x>=br):ax.plot(x[mask],t.loc[mask,col],color=INK,lw=1.6)
    ax.axvline(br,color=COPPER,ls='--',lw=1);ax.set_ylim(bottom=0);ax.set_title(title,loc='left',pad=9);ax.grid(axis='y',alpha=.2)
    ax.axvspan(pd.Timestamp('2026-09-01'),pd.Timestamp('2026-10-01'),color=PALE)
axes[0].annotate('Promjena arhive\n1. 4. 2024.',(br,110),xytext=(24,0),textcoords='offset points',fontsize=10,color=COPPER,bbox={'facecolor':'white','edgecolor':'none','alpha':.93,'pad':2})
axes[1].set_xlim(pd.Timestamp('2021-01-01'),pd.Timestamp('2026-10-01'))
save(fig,'01-timeline')

t=read('topic_sensitivity');a=t[t.scope=='publications'].set_index('topic');b=t[t.scope=='exact_text_groups'].set_index('topic')
order=a.sort_values('n',ascending=False).index.tolist();ys=np.arange(len(order))
fig,ax=plt.subplots(figsize=(7.1,5.1),layout='constrained')
ax.barh(ys-.16,a.loc[order,'percent'],height=.3,color=INK,label='Objave (n = 2.306)')
ax.barh(ys+.16,b.loc[order,'percent'],height=.3,color=COPPER,label='Točni tekstovi (n = 2.253)')
ax.set_yticks(ys,[wrap(a.loc[k,'label'],30) for k in order]);ax.invert_yaxis();ax.set_xlim(0,21.5);ax.set_xlabel('Udio primarne teme (%)')
for y,k in enumerate(order):ax.text(a.loc[k,'percent']+.2,y-.16,str(int(a.loc[k,'n'])),va='center',fontsize=9.8)
ax.legend(frameon=False,loc='lower right',fontsize=10);ax.grid(axis='x',alpha=.16);save(fig,'02-topics')

near=read('near_copy_sensitivity');fig,ax=plt.subplots(figsize=(7.1,3.8),layout='constrained')
chosen=['t02','t01','t09','t08','t10'];y=np.arange(len(chosen))
for j,(scope,label,color) in enumerate([('publications','Objave',INK),('exact_text_groups','Točni tekstovi',COPPER),('distinct_contexts','Različiti konteksti','#8c9572')]):
    s=t[t.scope==scope].set_index('topic');ax.scatter(s.loc[chosen,'percent'],y+(j-1)*.16,label=label,s=45,color=color)
for i,k in enumerate(chosen):
    v=near[near.topic==k]['percent'];ax.plot([v.min(),v.max()],[i+.33,i+.33],color='#927052',lw=2)
ax.set_yticks(y,[wrap(a.loc[k,'label'],27) for k in chosen]);ax.invert_yaxis();ax.set_xlim(0,20);ax.set_xlabel('Udio (%)');ax.legend(frameon=False,loc='lower right',fontsize=9.5)
ax.grid(axis='x',alpha=.18);save(fig,'03-repetition')

p=read('topic_profiles');p=p[p.scope=='year'];topics=[f't{i:02d}' for i in range(1,11)];years=sorted(p.category.astype(str).unique())
arr=np.array([[float(p[(p.topic==k)&(p.category.astype(str)==y)].percent.iloc[0]) for y in years] for k in topics])
counts=np.array([[int(p[(p.topic==k)&(p.category.astype(str)==y)].n.iloc[0]) for y in years] for k in topics])
cm=LinearSegmentedColormap.from_list('teal',['#f1f5f1','#789b93',INK])
fig,ax=plt.subplots(figsize=(7.1,5),layout='constrained');im=ax.imshow(arr,cmap=cm,vmin=0,vmax=30,aspect='auto')
ax.set_xticks(range(len(years)),[y+('*' if y=='2026' else '†' if y=='2024' else '')+'\nn='+str(int(p[p.category.astype(str)==y].denominator.iloc[0])) for y in years]);ax.set_yticks(range(10),[wrap(a.loc[k,'label'],29) for k in topics])
for i in range(10):
    for j in range(6):ax.text(j,i,f'{arr[i,j]:.1f}%\n{counts[i,j]}'.replace('.',','),ha='center',va='center',fontsize=9.7,color='white' if arr[i,j]>=19 else INK)
save(fig,'04-topic-time')

fig,ax=plt.subplots(figsize=(7.1,3.3),layout='constrained');names=['Sve objave','Samo A1','Dodatna pravila'];scopes=['publications','a1','additional_routes'];vals=[]
for scope in scopes:
    r=t[(t.scope==scope)&(t.topic=='t08')].iloc[0];vals.append(r.percent)
ax.barh(names,vals,color=[INK,'#77948b',COPPER]);ax.invert_yaxis();ax.set_xlim(0,55);ax.set_xlabel('Tema "Idejna tradicija i javne rasprave" (%)')
for y,s in enumerate(scopes):
    r=t[(t.scope==s)&(t.topic=='t08')].iloc[0];ax.text(r.percent+.8,y,f'{r.percent:.1f}%  ({int(r.n)}/{int(r.denominator)})'.replace('.',','),va='center',fontsize=10.5)
save(fig,'05-selection')

p=read('topic_profiles');p=p[p.scope=='platform'];platforms=['web','twitter','facebook','print','comment'];arr=np.array([[p[(p.topic==k)&(p.category==x)].percent.iloc[0] for x in platforms] for k in topics]);pc=read('platforms').set_index('platform')
fig,ax=plt.subplots(figsize=(7.1,5),layout='constrained');ax.imshow(arr,cmap=cm,vmin=0,vmax=60,aspect='auto')
ax.set_xticks(range(5),[pc.loc[x,'label']+f'\nn={int(pc.loc[x,"n"])}' for x in platforms]);ax.set_yticks(range(10),[wrap(a.loc[k,'label'],29) for k in topics])
for i in range(10):
    for j in range(5):
        r=p[(p.topic==topics[i])&(p.category==platforms[j])].iloc[0]
        ax.text(j,i,f'{arr[i,j]:.0f}%\n{int(r.n)}',ha='center',va='center',fontsize=9.8,color='white' if arr[i,j]>=38 else INK)
save(fig,'06-platform-topics')

l=read('lexical_pairs');pairs=[('domoljublje','narodnjastvo'),('domoljublje','drzavotvornost'),('demokrscanstvo','konzervativizam'),('hdz','savjest'),('europa','solidarnost')]
rows=[l[(l.a==aa)&(l.b==bb)].iloc[0] for aa,bb in pairs]
fig,ax=plt.subplots(figsize=(7.1,3.7),layout='constrained');ys=np.arange(5)
ax.hlines(ys,0,[r.npmi for r in rows],color=PALE,lw=5);ax.scatter([r.npmi for r in rows],ys,color=INK,s=65)
ax.set_yticks(ys,[r.a_label+' +\n'+r.b_label for r in rows]);ax.invert_yaxis();ax.set_xlim(0,.98);ax.set_xlabel('NPMI (veća vrijednost = jače relativno supojavljivanje)')
for i,r in enumerate(rows):ax.text(r.npmi+.025,i,f'{r.npmi:.2f} | {int(r.groups)} tekstova'.replace('.',','),va='center',fontsize=10)
save(fig,'07-lexical')
print('Seven vector charts written.')
