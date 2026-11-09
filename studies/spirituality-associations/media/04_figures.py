"""Export scientific figures from reconciled tables; no interactive network decoration."""
from pathlib import Path
import sys,json
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from common import PRIVATE,TABLES,FIGURES
P=PRIVATE/'media/v1';T=TABLES/'media-v1';F=FIGURES/'media-v1';F.mkdir(parents=True,exist_ok=True)
TEAL='#216775';COPPER='#aa6243';INK='#203844';LIGHT='#d9e5e6';GREY='#8b989d'
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':10,'axes.spines.top':False,'axes.spines.right':False,
    'axes.labelcolor':INK,'text.color':INK,'xtick.color':INK,'ytick.color':INK,'axes.edgecolor':'#bcc8ca',
    'figure.facecolor':'white','axes.facecolor':'white','grid.color':'#e3e9ea','savefig.dpi':180})
def save(name,fig):
    fig.savefig(F/(name+'.png'),bbox_inches='tight');fig.savefig(F/(name+'.svg'),bbox_inches='tight');plt.close(fig)
def main():
    m=pd.read_csv(T/'monthly_landscape.csv');m['date']=pd.to_datetime(m.month+'-01')
    a=pd.read_csv(T/'annual_landscape.csv');s=json.loads((T/'summary.json').read_text())
    d=m.groupby('date')[['rows','raw_candidate_records','candidate_items']].sum()
    fig,ax=plt.subplots(2,1,figsize=(10,5.7),sharex=True)
    ax[0].bar(d.index,d.rows/1e6,width=24,color=TEAL);ax[0].set_ylabel('Monitored records (millions)')
    ax[1].bar(d.index,d.raw_candidate_records,width=24,color=COPPER);ax[1].set_ylabel('Raw candidate records')
    for x in ax:x.axvline(pd.Timestamp('2024-01-01'),color=INK,linestyle='--',lw=1);x.axvspan(pd.Timestamp('2026-09-01'),pd.Timestamp('2026-09-30'),color=GREY,alpha=.2)
    ax[0].annotate('New collection regime',xy=(pd.Timestamp('2024-01-01'),d.rows.max()/1e6),xytext=(5,12),textcoords='offset points',fontsize=9)
    ax[1].set_xlabel('Month; September 2026 contains 10 days')
    ax[1].set_xlim(pd.Timestamp('2020-12-15'),pd.Timestamp('2026-10-01'))
    fig.tight_layout();save('coverage_and_candidates',fig)
    fig,ax=plt.subplots(figsize=(9,3.6));labels=['All register entries','Name rules available','Names with candidates','Searched without a hit','Held for identity rules']
    vals=[1325,s['searched_names'],s['candidate_names'],s['searched_zero'],s['held_names']]
    bars=ax.barh(labels[::-1],vals[::-1],color=[GREY,LIGHT,COPPER,TEAL,INK]);ax.set_xlim(0,1500)
    for b,n in zip(bars,vals[::-1]):ax.text(n+15,b.get_y()+b.get_height()/2,f'{n:,}',va='center')
    ax.set_xlabel('Organisations; categories are not all nested');fig.tight_layout();save('search_funnel',fig)
    county=pd.read_csv(T/'county_landscape.csv').sort_values('registered')
    fig,ax=plt.subplots(figsize=(10,7));y=np.arange(len(county))
    ax.barh(y,county.candidate_names,color=TEAL,label='Name has candidates')
    ax.barh(y,county.searched-county.candidate_names,left=county.candidate_names,color=LIGHT,label='Searched, no hit')
    ax.barh(y,county.registered-county.searched,left=county.searched,color=GREY,label='Held for identity rules')
    ax.set_yticks(y,county.county);ax.set_xlabel('Registered organisations, by county of seat');ax.legend(fontsize=8,loc='lower right')
    fig.tight_layout();save('county_search_landscape',fig)
    pa=pd.read_csv(P/'pairs.csv',dtype={'association_id':str});org=pd.read_csv(P/'organisation_landscape.csv',dtype={'association_id':str})
    searched=org.loc[org.search_status=='searched','association_id']
    fig,ax=plt.subplots(figsize=(7.8,4.6));ax.plot([0,1],[0,1],color=GREY,linestyle=':',label='Equal distribution')
    for label,sub,color in [('All candidates',pa,TEAL),('Restricted screen',pa[pa.restricted_candidate],COPPER),('Title / lead',pa[pa.title_or_lead],INK)]:
        ct=sub.groupby('association_id').size().reindex(searched,fill_value=0).sort_values().to_numpy()
        ax.plot(np.arange(len(ct)+1)/len(ct),np.r_[0,np.cumsum(ct)/ct.sum()],label=label,color=color,lw=2)
    ax.set_xlabel('Cumulative share of searched names');ax.set_ylabel('Cumulative share of candidate pairs');ax.legend(fontsize=9)
    fig.tight_layout();save('candidate_concentration',fig)
    pan=pd.read_csv(T/'common_domain_panel.csv');pan['date']=pd.to_datetime(pan.month+'-01')
    web=m[m.platform=='web'].set_index('date')
    fig,ax=plt.subplots(figsize=(10,4.2));ax.plot(web.index,web.raw_candidate_records_per_10000,color=GREY,lw=1.5,label='All monitored web domains')
    ax.plot(pan.date,pan.raw_candidates_per_10000,color=TEAL,lw=2,label=f'Common observed panel ({s["common_panel_domains"]} domains)')
    ax.axvline(pd.Timestamp('2024-01-01'),color=COPPER,linestyle='--',lw=1);ax.set_ylabel('Raw candidate records per 10,000 raw web records')
    ax.set_xlabel('Month; descriptive search yield, not validated visibility');ax.legend(fontsize=9);fig.tight_layout();save('common_panel_yield',fig)
    plat=pd.read_csv(T/'platform_landscape.csv').query('candidate_items>0').sort_values('candidate_items')
    fig,ax=plt.subplots(figsize=(9,4.4));b=ax.barh(plat.platform,plat.candidate_items,color=TEAL)
    for bar,n in zip(b,plat.candidate_items):ax.text(n+max(plat.candidate_items)*.012,bar.get_y()+bar.get_height()/2,f'{n:,}',va='center',fontsize=9)
    ax.set_xlim(0,max(plat.candidate_items)*1.16);ax.set_xlabel('Candidate publication-days');fig.tight_layout();save('platforms',fig)
    dom=pd.read_csv(T/'web_domain_landscape.csv').head(12).sort_values('candidate_items')
    fig,ax=plt.subplots(figsize=(9,4.6));ax.barh(dom.domain,dom.candidate_items,color=TEAL);ax.set_xlabel('Candidate web publication-days; domains are not affiliation codes')
    fig.tight_layout();save('web_domains',fig)
    labels={'8013':'Breza','4553':'SKAC Palma','58492':'SKAC Split','42673':'Korablja','32947':'Kršćanski akademski krug','14821':'Padmasana','10420':'Joga u svakodnevnom životu Rijeka','14665':'Matica hrvatska, Hvar branch'}
    oy=pd.read_csv(P/'organisation_year.csv',dtype={'association_id':str}).pivot(index='association_id',columns='year',values='candidate_items').reindex(labels).fillna(0)
    fig,ax=plt.subplots(figsize=(10,4.8));mat=oy.to_numpy();im=ax.imshow(np.log1p(mat),aspect='auto',cmap='GnBu')
    ax.set_xticks(range(len(oy.columns)),[str(x)+('*' if x==2026 else '') for x in oy.columns]);ax.set_yticks(range(len(labels)),list(labels.values()))
    for i in range(mat.shape[0]):
        for j in range(mat.shape[1]):ax.text(j,i,f'{int(mat[i,j])}',ha='center',va='center',fontsize=9,color='white' if np.log1p(mat[i,j])>np.log1p(mat).max()*.65 else INK)
    ax.set_xlabel('Candidate publication-days; colour uses log(1 + count). *Through 10 September.');fig.tight_layout();save('selected_profiles',fig)
    tp=pd.read_csv(T/'topic_platform.csv');tp['channel']=tp.platform.where(tp.platform.isin(['web','facebook','youtube']),'other')
    topic_ids=list(range(1,9))+([0] if (tp.topic==0).any() else [])
    pivot=tp.groupby(['topic','channel'])['items'].sum().unstack(fill_value=0).reindex(topic_ids,fill_value=0)
    pct=100*pivot/pivot.sum(axis=0)
    fig,ax=plt.subplots(figsize=(8.5,4.7));im=ax.imshow(pct,aspect='auto',cmap='GnBu',vmin=0)
    ax.set_xticks(range(len(pivot.columns)),[f'{c}\n(n={pivot[c].sum():,})' for c in pivot.columns]);ax.set_yticks(range(len(topic_ids)),[f'Exploratory topic {i}' if i else 'Unassigned' for i in topic_ids])
    for i in range(len(topic_ids)):
        for j in range(len(pivot.columns)):ax.text(j,i,f'{pct.iloc[i,j]:.1f}%',ha='center',va='center',color='white' if pct.iloc[i,j]>pct.max().max()*.6 else INK,fontsize=9)
    fig.colorbar(im,ax=ax,label='Share of modelled channel subset (%)');fig.tight_layout();save('topic_channels',fig)
    om=pd.read_csv(P/'organisation_month.csv',dtype={'association_id':str});months=sorted(m.month.unique())
    fig,ax=plt.subplots(3,1,figsize=(10,6),sharex=True)
    for axis,oid in zip(ax,['8013','4553','42673']):
        ct=om[om.association_id==oid].set_index('month').candidate_items.reindex(months,fill_value=0)
        axis.bar(pd.to_datetime(ct.index+'-01'),ct,width=24,color=TEAL);axis.set_ylabel(labels[oid]);axis.axvline(pd.Timestamp('2024-01-01'),color=COPPER,linestyle='--',lw=1)
    ax[-1].set_xlabel('Month; candidate items and collection break, not verified event counts');fig.tight_layout();save('case_timelines',fig)
    print('FIGURES COMPLETE',len(list(F.glob('*.png'))))
if __name__=='__main__':main()
