"""Display-only views of saved aggregates; no corpus/model/network computation."""
import json, textwrap
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter, MaxNLocator
from matplotlib.patches import FancyBboxPatch
import numpy as np
from reader_copy import CAPTIONS, CARD_COPY

INK='#243337'; GREEN='#176e62'; GOLD='#bf7d36'; PALE='#a6c9be'; GREY='#a6afb2'; RED='#af5e52'
COLORS=[GREEN,GOLD,PALE,GREY,RED,'#698fa5','#b9a3bd']
plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11,'axes.titleweight':'bold','axes.labelcolor':INK,'text.color':INK,'xtick.color':INK,'ytick.color':INK,'axes.edgecolor':'#cbd5d1','svg.fonttype':'path','pdf.fonttype':42,'axes.spines.top':False,'axes.spines.right':False})
ROLE={'biskup':'Biskupi','papa':'Pape','svecenik':'Svećenici','akademski':'Fakultetski teolozi','laik':'Laici','redovnica':'Redovnice','vidjelac':'Vidioci'}
def nf(v):return f'{v:,.0f}'.replace(',',' ')
def tick(v):return nf(v) if abs(v-round(v))<1e-8 else f'{v:.1f}'.replace('.',',')
def build(out,a,d,c,persons,splitrows):
    dest=out/'companion/figures';dest.mkdir(exist_ok=True)
    manifest=[]; figures={}; roles={x['role']:x for x in d['roles']}
    def start(num,title,subtitle,source,kind='saved aggregate',data=None):
        technical_source=source
        title,subtitle,source=CAPTIONS[num]
        fig=plt.figure(figsize=(6.4,7.5),facecolor='#f3f6f3')
        fig.text(.055,.958,f'{num:02d} / OPĆI POGLED',fontsize=9,color=GREEN,weight='bold')
        fig.text(.055,.91,textwrap.fill(title,34),fontsize=18,weight='bold',va='top')
        fig.text(.055,.79,textwrap.fill(subtitle,64),fontsize=10,va='top',linespacing=1.5)
        entry=dict(page=num,title=title,subtitle=subtitle,source=source,technical_source=technical_source,kind=kind,data=data)
        return fig,entry
    def finish(fig,e):
        n=e['page']; stem=f'figure-{n:02d}'
        fig.text(.055,.025,textwrap.fill(e['source'],91),fontsize=7.5,va='bottom',color='#566361',linespacing=1.4)
        for ext in ['svg','pdf']:fig.savefig(dest/f'{stem}.{ext}',facecolor=fig.get_facecolor())
        plt.close(fig);e['svg']=f'companion/figures/{stem}.svg';e['pdf']=f'companion/figures/{stem}.pdf';manifest.append(e);figures[n]=e
    def axis(fig,rect=(.35,.16,.56,.53)):
        ax=fig.add_axes(rect,facecolor='#f3f6f3');ax.set_axisbelow(True);ax.grid(axis='x',color='#dbe3de',lw=.6);ax.spines['left'].set_visible(False);ax.tick_params(axis='y',length=0);ax.xaxis.set_major_formatter(FuncFormatter(lambda v,p:tick(v)));ax.xaxis.set_major_locator(MaxNLocator(nbins=4,integer=True));return ax
    def bars(n,title,sub,labels,vals,src,highlight=None,xlabel='Broj izjava',data=None):
        fig,e=start(n,title,sub,src,data=data or dict(labels=labels,values=vals,unit=xlabel))
        ax=axis(fig);yy=np.arange(len(vals));cc=[GREEN if highlight is None or lab in highlight else GREY for lab in labels]
        ax.barh(yy,vals,height=.58,color=cc);ax.set_yticks(yy,labels,fontsize=10);ax.invert_yaxis();ax.set_xlim(0,max(vals)*1.27);ax.set_xlabel(xlabel,fontsize=10,labelpad=12)
        for y,v in zip(yy,vals):ax.text(v+max(vals)*.025,y,tick(v),va='center',fontsize=10,weight='bold')
        finish(fig,e)
    def cards(n,title,sub,items,src):
        items=CARD_COPY[n]
        fig,e=start(n,title,sub,src,kind='editorial diagram',data=items)
        ax=fig.add_axes([.055,.105,.89,.59]);ax.set_axis_off()
        height=.85/len(items)
        for i,(head,body) in enumerate(items):
            y=.96-i*(.95/len(items));ax.add_patch(FancyBboxPatch((0,y-height),1,height,boxstyle='round,pad=0.008,rounding_size=0.015',facecolor='white',edgecolor='#d7e0db'))
            ax.text(.045,y-.045,head,va='top',fontsize=13,weight='bold',color=GREEN)
            ax.text(.045,y-.105,textwrap.fill(body,55),va='top',fontsize=10,linespacing=1.5)
        finish(fig,e)
    def pair(n,title,sub,labels,v1,v2,legend,src,xlabel='Broj objava',data=None):
        fig,e=start(n,title,sub,src,data=data or dict(labels=labels,series=[v1,v2],legend=legend,unit=xlabel))
        ax=axis(fig,(.35,.24,.56,.43));y=np.arange(len(labels));m=max(v1+v2)
        for delta,vals,color,lab in [(-.18,v1,GREEN,legend[0]),(.18,v2,GOLD,legend[1])]:
            ax.barh(y+delta,vals,.3,color=color,label=lab)
            for yy,v in zip(y+delta,vals):ax.text(v+m*.025,yy,f'{v:.1f}'.replace('.',',') if isinstance(v,float) else nf(v),va='center',fontsize=9)
        ax.set_yticks(y,labels,fontsize=10);ax.invert_yaxis();ax.set_xlim(0,m*1.28);ax.set_xlabel(xlabel,fontsize=10);fig.legend(*ax.get_legend_handles_labels(),loc='lower left',bbox_to_anchor=(.055,.102),frameon=False,fontsize=9);finish(fig,e)
    sortedroles=sorted(d['roles'],key=lambda x:x['statements'],reverse=True)
    bars(1,'Služba oblikuje javni glas','Raspodjela izjava unutar zatvorenog popisa. Ponavljanja i citati ostaju u brojevima.',[ROLE[x['role']] for x in sortedroles],[x['statements'] for x in sortedroles],'D · roles / statements; 71 259 izjava; sažetak 116 od 117 osoba. Pravilo ime + glagol, ne mjera kvalitete argumenta.')
    bars(2,'Jedan nadbiskup, 25 teologa','Isto pravilo prepoznavanja govora, ista studija i isto razdoblje.', ['Dražen\nKutleša','25 fakultetskih\nteologa zajedno'],[int(persons['kutlesa']['statements']),roles['akademski']['statements']],'D · voices_summary / kutlesa; roles / akademski. Do 11. 6. 2026. Osoba se uspoređuje s izričito označenom skupinom.')
    fig,e=start(3,'Četiri napetosti u četiri mjere','Svaki panel ima vlastiti nazivnik. Postotci se ne zbrajaju.','D · roles, bishop_other_share, top50_tip, sample.believers. Uzorak i kanali: nevalidirane modelske oznake.',data=[['biskupi i pape',61995,71259],['biskupske izjave izvan katoličke skupine',d['bishop_other_share'],100],['anonimni kanali',24,50],['vjernici govore',3,150]])
    panels=[('Biskupi i pape',87,'svih zabilježenih izjava'),('Ostali mediji',d['bishop_other_share'],'biskupskih izjava izvan\nkatoličkih izvora'),('Anonimni kanali',48,'24 od 50 katoličkih kanala'),('Vjernici govore',2,'3 od 150 katoličkih objava')]
    for j,(head,val,detail) in enumerate(panels):
        ax=fig.add_axes([.075+(j%2)*.47,.42-(j//2)*.29,.39,.23]);ax.set_axis_off();ax.text(0,.98,head,va='top',fontsize=10,weight='bold');ax.text(0,.52,f'{val:.0f} %',fontsize=33,color=GREEN,weight='bold');ax.barh(.3,100,height=.06,color='#dce5df');ax.barh(.3,val,height=.06,color=GREEN);ax.set_xlim(0,100);ax.set_ylim(0,1);ax.text(0,.16,detail,va='top',fontsize=9)
    finish(fig,e)
    roster_roles=sorted(d['list']['roles'],key=lambda x:x['N'],reverse=True)
    bars(4,*CAPTIONS[4][:2],[ROLE[x['role']] for x in roster_roles],[x['N'] for x in roster_roles],'D · report_data.json / list.roles',xlabel='Broj osoba')
    platforms=sorted(a['values']['platforms'],key=lambda x:x['documents'],reverse=True)
    bars(5,*CAPTIONS[5][:2],[x['platform'] for x in platforms],[x['documents'] for x in platforms],'A · values.platforms / documents',xlabel='Broj prikupljenih objava')
    popes=sorted([x for x in persons.values() if x['role']=='papa'],key=lambda x:int(x['statements']),reverse=True)
    bars(6,'Papinski glasovi u istom arhivu','Ukupni brojevi uključuju povijesne citate i prijenose. Razdoblja službe nisu jednaka.',[x['name'] for x in popes],[int(x['statements']) for x in popes],'D · voices_summary; do 11. 6. 2026. Lav XIV. broji se od izbora; Franjo i Benedikt XVI. uključuju posmrtno citiranje.')
    temporal=a['evidence']['network_metrics']['temporal'];q=sorted({x['quarter'] for x in temporal if x['quarter']>='2025-Q1'})
    fig,e=start(7,'Smjena središta u vremenu','Dokumenti sa spomenom dvojice papa u spremljenim vremenskim ćelijama. Odsutnost točke nije nula.','A · network_metrics.temporal / documents. 2026-Q4 završava 16. 10.; nije cijelo tromjesečje. Datum objave nije datum govora.',data=[x for x in temporal if x['entity_id'] in ['Q450675','Q6109517'] and x['quarter']>='2025-Q1'])
    ax=axis(fig,(.15,.19,.77,.49));ax.grid(axis='y',color='#dbe3de');ax.grid(axis='x',visible=False)
    for eid,label,col in [('Q450675','Franjo',GREEN),('Q6109517','Lav XIV.',GOLD)]:
        lookup={x['quarter']:x['documents'] for x in temporal if x['entity_id']==eid};ax.plot(range(len(q)),[lookup.get(z,np.nan) for z in q],marker='o',lw=2.4,color=col,label=label)
    ax.set_xticks(range(len(q)),[z[-1]+'. tr.\n'+z[:4] for z in q],fontsize=8);ax.set_ylabel('Objave s imenom osobe');ax.legend(frameon=False);ax.set_ylim(bottom=0);finish(fig,e)
    bishops=sorted([x for x in persons.values() if x['role']=='biskup'],key=lambda x:int(x['statements']),reverse=True)[:10]
    bars(8,'Vrh biskupske prisutnosti u govoru','Deset najvećih brojeva izjava među 40 biskupa zatvorenog popisa.',[x['name'] for x in bishops],[int(x['statements']) for x in bishops],'D · voices_summary / role=biskup; statements. Broj uključuje ponovljene prijenose.',highlight={persons['kutlesa']['name']})
    def shares(n,highlight=None):
        fig,e=start(n,'Oko polovice ostaje neoznačeno','Osam punih portreta, isti nazivnik: svi dokumenti sa spomenom pojedine osobe.','A · network_metrics.measures. Tri izvorne oznake; neoznačeni dokumenti nisu pripisani sekularnima.',data=splitrows)
        ax=axis(fig,(.28,.25,.65,.42));left=np.zeros(len(splitrows))
        for key,lab,col in [('confessional_documents','Vjerski mediji',GREEN),('secular_documents','Sekularni mediji',GOLD),('unlabelled_documents','Vrsta medija: ?',GREY)]:
            vals=np.array([100*x[key]/x['denominator_documents'] for x in splitrows]);ax.barh(range(len(vals)),vals,left=left,color=col,height=.65,label=lab)
            for j,v in enumerate(vals):
                if v>=7:ax.text(left[j]+v/2,j,f'{v:.0f}',ha='center',va='center',fontsize=8,color='white' if col==GREEN else INK)
            left+=vals
        labels=[x['name'].replace('Papa ','') for x in splitrows];ax.set_yticks(range(len(labels)),labels,fontsize=10);ax.invert_yaxis();ax.set_xlim(0,100);ax.set_xlabel('Udio objava (%)');fig.legend(*ax.get_legend_handles_labels(),loc='lower left',bbox_to_anchor=(.055,.105),fontsize=8.5,frameon=False,ncol=3,columnspacing=1,handlelength=1.3)
        if highlight:
            for tick,row in zip(ax.get_yticklabels(),splitrows):
                if row['entity_id']==highlight:tick.set_weight('bold');tick.set_color(GREEN)
        finish(fig,e)
    shares(9,'Q335206')
    people={x['entity_id']:x for x in a['values']['people']};eids=[x['entity_id'] for x in splitrows]
    ordered=sorted([people[x] for x in eids],key=lambda x:x['outlets'],reverse=True)
    bars(10,'Koliko izvora nosi pojedini glas?','Broj izvora sa spomenom među osam punih portreta. To nije broj vlastitih nastupa.',[x['public_name'] for x in ordered],[x['outlets'] for x in ordered],'A · values.people / outlets. Do 16. 10. 2026. Izvor nije nužno samostalno uredništvo.',highlight={people['Q1232284']['public_name']},xlabel='Broj izvora')
    selected=sorted([people[x] for x in eids[2:]],key=lambda x:x['documents'],reverse=True)
    bars(11,'Biskupi u dokumentima','Šest biskupskih portreta prema broju dokumenata sa spomenom; izbor portreta, ne svi biskupi.',[x['public_name'] for x in selected],[x['documents'] for x in selected],'A · values.people / documents. Mjera prisutnosti, odvojena od D-ovih izjava.',highlight={people['Q365529']['public_name']},xlabel='Objave s imenom osobe')
    plat={}
    for x in a['values']['person_platform_eras']:
        if x['entity_id']=='Q741036':plat[x['platform']]=plat.get(x['platform'],0)+x['documents']
    pp=sorted(plat.items(),key=lambda x:x[1],reverse=True)
    bars(12,'Košićeva prisutnost po platformama','Zbroj dvaju spremljenih razdoblja po platformi. Količina sadržaja ovisi i o prikupljanju.',[x[0] for x in pp],[x[1] for x in pp],'A · person_platform_eras / Q741036. Prikaz zbraja postojeće agregate; nema obrade korpusa.',xlabel='Objave s imenom osobe')
    meas={x['entity_id']:x for x in a['evidence']['network_metrics']['measures']}
    pair(13,'Dokumenti i obitelji sličnih tekstova','Šest biskupskih portreta. Obitelji mogu sadržavati posredne veze sličnosti.',[people[x]['public_name'] for x in eids[2:]],[meas[x]['mentioned_documents'] for x in eids[2:]],[meas[x]['families'] for x in eids[2:]],['Sve objave','Skupine sličnih tekstova'],'A · network_metrics.measures. Razlika nije broj dokazano prepisanih članaka.',xlabel='Broj objava / skupina')
    priests=sorted([x for x in persons.values() if x['role']=='svecenik'],key=lambda x:int(x['statements']),reverse=True)[:10]
    bars(14,'Svećenički glasovi izvan episkopata','Deset najvećih spremljenih brojeva. Izvorni agregat Sente nije ovdje razdvojen na seniora i juniora.',[x['name'] for x in priests],[int(x['statements']) for x in priests],'D · voices_summary / svecenik. 31 redak od 32 osobe popisa; nedostajući redak nije nula.',highlight={persons['sente']['name'],persons['tpervan']['name']})
    bars(15,'Koliki dio spomena nosi trag govora?','Po skupinama zatvorenog popisa: izjave / spomeni. Pravilo ne mjeri semantičku točnost ni kvalitetu.',[ROLE[x['role']] for x in sortedroles],[round(x['stmt_rate'],1) for x in sortedroles],'D · roles / stmt_rate. Zaokruženo na jednu decimalu; izvorna pravila i kategorije ostaju.',xlabel='Izjave na 100 spomena')
    ids=['sente','tpervan','stojic','vukman','vuckovic','grbes']
    bars(16,'Brojevi postoje i kad odlomak izostaje','Šest svećeničkih portreta. Broj izjava ne jamči prikladan odlomak u zasebnom uzorku B.',[persons[x]['name'] for x in ids],[int(persons[x]['statements']) for x in ids],'D · voices_summary. B za Vukmana donosi izvještaj s događaja, za Vučkovića najavu; nijedno ne zamjenjuje vlastito objašnjenje.',highlight={persons['vukman']['name'],persons['vuckovic']['name']})
    ids=['grbes','markic','baloban','matulic','loncar','vucetic']
    fig,e=start(17,'Glasovi prelaze granice katoličkih izvora','Šest odabranih srednjih portreta. D-ova operativna podjela nije A-ova oznaka medija.', 'D · voices_summary / statements, secular_statements. Ostali su svi izvori izvan D-ove označene katoličke skupine.',data=[persons[x] for x in ids])
    ax=axis(fig,(.31,.22,.61,.44));vv=np.array([int(persons[x]['secular_statements'])/int(persons[x]['statements'])*100 for x in ids]);ax.barh(range(6),100-vv,color=GREEN,label='Katolički izvori');ax.barh(range(6),vv,left=100-vv,color=GOLD,label='Ostali izvori')
    for i,v in enumerate(vv):ax.text(101,i,f'{v:.0f} %',va='center',fontsize=9)
    ax.set_yticks(range(6),[persons[x]['name'] for x in ids],fontsize=10);ax.invert_yaxis();ax.set_xlim(0,115);ax.set_xticks([0,50,100]);ax.set_xlabel('Udio izjava (%)');ax.legend(loc='upper left',bbox_to_anchor=(-.3,-.2),frameon=False,fontsize=9);finish(fig,e)
    academics=sorted([x for x in persons.values() if x['role']=='akademski'],key=lambda x:int(x['statements']),reverse=True)[:10]
    bars(18,'Akademski krug ima vlastiti vrh','Deset najvećih brojeva među 25 fakultetskih teologa s izvornog popisa.',[x['name']+('\n(posmrtni citati)' if x['id']=='ivancic' else '') for x in academics],[int(x['statements']) for x in academics],'D · voices_summary / akademski. Izvorna skupina popisa; nije popis svih javnih teologa. Ivančićevi brojevi su posmrtni citati.',highlight={persons['baloban']['name'],persons['matulic']['name']})
    pair(19,'Zastupljenost nije govorna težina','Udio žena na zatvorenom popisu i u njegovim zabilježenim izjavama.', ['Žene'],[round(13/117*100,1)],[round(710/71259*100,1)],['Na popisu: 13 / 117','U izjavama: 710 / 71 259'],'D · list / women_stmt. Popis je unaprijed odabran; sažetak ima 116 osoba. Nije procjena cijele javnosti.',xlabel='Udio (%)')
    chan={'anonimni_poboznji_kanal':'Anonimni pobožni\nkanali','neovisni_katolicki_medij':'Neovisni katolički\nmediji','institucijski_medij':'Institucijski mediji','crkvena_ustanova':'Crkvene ustanove','zajednica_udruga':'Zajednice i udruge','svecenik_redovnik':'Svećenik / redovnik','laicki_autor':'Laički autori'}
    tt=sorted(d['top50_tip'],key=lambda x:x['n'],reverse=True)
    bars(20,'Gotovo polovica kanala je anonimna','Vrste 50 najangažiranijih katoličkih kanala prema spremljenim modelskim oznakama.',[chan[x['tip']] for x in tt],[x['n'] for x in tt],'D · top50_tip. Nevalidirane modelske oznake; izbor prema angažmanu, ne reprezentativni uzorak svih kanala.',xlabel='Broj kanala')
    pair(21,'O vjernicima se češće govori','Dvije zasebne skupine po 150 objava. Opisani i govore mogu se preklapati.', ['Katolički\nizvori','Ostali\nizvori'],[53,75],[3,12],['Vjernici opisani','Vjernici govore'],'D · sample.believers. Nevalidirano modelsko kodiranje; broj objava, ne broj osoba.',xlabel='Objave od 150 u svakoj skupini')
    bars(22,'Trag citiranja nije sadašnji nastup','Jedan posthumni glas i cijela skupina vidioca prikazani su odvojeno, s istim D-ovim pravilom.', ['Tomislav Ivančić\n(posmrtni citati)','Pet praćenih\nvidioca'],[int(persons['ivancic']['statements']),roles['vidjelac']['statements']],'D · voices_summary / ivancic; roles / vidjelac. Ivančić je umro 2017.; građa počinje 2021. Ne uspoređuju se živi nastupi.')
    names=['Tomáš Halík','Karl Rahner','Hans Küng','Romana Guardinija'];rr=[x for x in d['label']['top'] if x['name'] in names]
    bars(23,'Oznaka teolog vodi i prema tradiciji','Četiri javna autora spomenuta u eseju; odabrani primjeri, ne potpuna ljestvica oznake.',['Romano Guardini' if x['name']=='Romana Guardinija' else x['name'] for x in rr],[x['posts'] for x in rr],'D · label.top. 1 571 objava s oznakom; 58 vezano uz fakultetski popis. Brojevi su objave s imenom, ne izjave.',xlabel='Objave uz oznaku teolog')
    auth=d['sample']['autoritet'];keys=['pismo','predaja_sveci','uciteljstvo','osobno_iskustvo','nacija_povijest','znanost_razum'];labels=['Sveto pismo','Predaja / sveci','Učiteljstvo','Osobno iskustvo','Nacija / povijest','Znanost / razum'];lookup={(x['stratum'],x['a']):x['N'] for x in auth}
    pair(24,'Na što se objašnjenje oslanja?','Šest zajedničkih oznaka. Više oznaka može pripasti jednoj objavi; prikazani su brojevi, ne udjeli.',labels,[lookup['katolicki',x] for x in keys],[lookup['ostali',x] for x in keys],['Katolički izvori · 95 objava','Ostali izvori · 96 objava'],'D · sample.autoritet / interp_n. Nevalidirano modelsko kodiranje. Izvorni spremljeni postotci imaju nedosljedne nazivnike i nisu korišteni.')
    cards(25,*CAPTIONS[25][:2],CARD_COPY[25],'B: Q500, Q2370. Editorial attribution diagram.')
    keys=['osobno_iskustvo','nacija_povijest','znanost_razum'];labs=['Osobno iskustvo','Nacija / povijest','Znanost / razum']
    pair(26,'Rjeđi oslonci objašnjavanja','Odabrane leće starijega kodiranja. Njihova prisutnost ne ocjenjuje snagu argumenta.',labs,[lookup['katolicki',x] for x in keys],[lookup['ostali',x] for x in keys],['Katolički izvori · 95 objava','Ostali izvori · 96 objava'],'D · sample.autoritet / interp_n. Nevalidirane, preklapajuće modelske oznake; nisu procjene cijelog korpusa.')
    cards(27,*CAPTIONS[27][:2],CARD_COPY[27],'B: Q636, Q2449, Q1591, Q2742. Editorial genre diagram.')
    labs=[c[f'source_{i}_name']['value'] for i in range(1,11)];vals=[c[f'source_{i}_n']['value'] for i in range(1,11)]
    bars(28,'Koncentracija počinje s HKM-om','Deset najzastupljenijih izvora u zasebnom uredničkom web okviru.',labs,vals,'C · source_1 … source_10 / n. Okvir 282 701 dokument, 1 993 izvora. Prvih pet: 29,5 %. Prisutnost ne dokazuje podrijetlo.',xlabel='Broj objava')
    shares(29)
    sizes=a['values']['circulation_sizes']
    pair(30,'Velike obitelji, mnoge pojavnosti','Broj obitelji i njihovih dokumenata po veličini obitelji sličnih tekstova.',[x['size_group']+' obj.' for x in sizes],[x['families'] for x in sizes],[x['documents'] for x in sizes],['Skupine sličnih tekstova','Sve objave'],'A · circulation_sizes. Približna sličnost, ne nužno identičan tekst. 147 obitelji s 50+ dokumenata nosi 26 779 dokumenata.',xlabel='Broj skupina / objava')
    # The original network is embedded unchanged by the page renderer.
    e=dict(page=31,title=CAPTIONS[31][0],subtitle=CAPTIONS[31][1],source=CAPTIONS[31][2],technical_source='A · figures/network_outlets.svg; unchanged original network',kind='unchanged source network',data=None,svg='companion/network_outlets.svg',pdf=None);manifest.append(e);figures[31]=e
    adj=a['evidence']['network_metrics']['adjacent_top20']
    fig,e=start(32,'Najveći pomak poretka: proljeće 2025.','Kendallov τ među zajedničkim osobama susjednih top-20 poredaka. Niže znači slabije podudaranje.',f"A · network_metrics.adjacent_top20. Zajedničkih osoba: {min(x['common_entities'] for x in adj)}–{max(x['common_entities'] for x in adj)}; u označenom prijelazu 14. Odvojena razdoblja prikupljanja. 2026-Q4 nepotpun.",data=adj)
    ax=axis(fig,(.16,.24,.77,.43));xx=list(range(len(adj)));vv=[x['kendall_tau'] for x in adj];ax.plot(xx,vv,'o',color=GREEN,ms=5)
    for era in sorted({x['era'] for x in adj}):
        ii=[i for i,x in enumerate(adj) if x['era']==era];ax.plot(ii,[vv[i] for i in ii],color=PALE,lw=1.5,zorder=0)
    idx=next(i for i,x in enumerate(adj) if x['previous']=='2025-Q1' and x['current']=='2025-Q2');ax.scatter([idx],[vv[idx]],color=RED,s=75,zorder=4);ax.annotate('Proljeće 2025.\n0,10',xy=(idx,vv[idx]),xytext=(idx-2,.34),fontsize=10,color=RED,arrowprops={'arrowstyle':'-','color':RED});ax.set_xticks(xx,[x['current'][:4]+' · '+x['current'][-1]+'.' for x in adj],rotation=90,fontsize=7);ax.set_ylim(0,1);ax.set_ylabel('Sličnost redoslijeda');ax.grid(axis='x',visible=False);ax.grid(axis='y',color='#dbe3de');finish(fig,e)
    roster={x['role']:x['N'] for x in d['list']['roles']}
    pair(33,'Broj ljudi i težina njihova glasa','Usporedba sastava popisa i raspodjele izjava. Nazivnici su različiti i izričito odvojeni.',[ROLE[x['role']] for x in sortedroles],[round(100*roster[x['role']]/117,1) for x in sortedroles],[round(x['stmt_share'],1) for x in sortedroles],['Praćene osobe (117)','Zabilježene izjave (71 259)'],'D · list.roles / roles.stmt_share. Sažetak ima 116 osoba. Nije procjena stanovništva ni ukupne javnosti.',xlabel='Udio (%)')
    cards(34,*CAPTIONS[34][:2],CARD_COPY[34],'Editorial reading guide based on the displayed passages.')
    cards(35,*CAPTIONS[35][:2],CARD_COPY[35],'D: roles, sample.believers. C: source_1_n.')
    (out/'companion/figure_manifest.json').write_text(json.dumps(sorted(manifest,key=lambda x:x['page']),ensure_ascii=False,indent=2),encoding='utf8')
    assert set(figures)==set(range(1,36))
    return figures
