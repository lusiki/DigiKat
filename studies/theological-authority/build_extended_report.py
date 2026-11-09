"""Twenty-page Croatian descriptive report; all numeric findings read from R output."""
from pathlib import Path
from xml.sax.saxutils import escape
import csv, html, json, math, zipfile
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, Table, TableStyle

HERE=Path(__file__).resolve().parent
BASE=HERE/'output/private'
OUT=BASE/'extended'
AGG=HERE/'output/extended'
FIG=OUT/'figures'
FIG.mkdir(exist_ok=True)
R=json.loads((BASE/'results.json').read_text(encoding='utf-8'))
E=json.loads((OUT/'results.json').read_text(encoding='utf-8'))
P={'web':'Web','facebook':'Facebook','youtube':'YouTube','instagram':'Instagram','tiktok':'TikTok','twitter':'X/Twitter','reddit':'Reddit','forum':'Forumi','comment':'Komentari'}
PLAT=list(P)
GS=['church_media','church_org','independent','clergy','community','devotional']
GL={'church_media':'Crkveni mediji','church_org':'Crkvene ustanove','independent':'Neovisni mediji','clergy':'Svećenički profili','community':'Zajednice i udruge','devotional':'Pobožni/autorski kanali'}
GC={'church_media':'CM','church_org':'CU','independent':'NM','clergy':'SP','community':'ZU','devotional':'PA'}
PC={'web':'Web','facebook':'FB','youtube':'YT','instagram':'IG','tiktok':'TT','twitter':'X'}
INK,GREEN,COPPER,MUTED='#193f43','#42866d','#b56c45','#5e7275'
PAPER,LINE='#fcfbf7','#d8e0dc'
PALETTE=['#193f43','#6a9389','#b56c45','#557c98','#bea868','#9e8195']
W,H=A4; M=42; CW=W-2*M

def num(x,d=0):
    if x is None or not math.isfinite(x): return 'n/p'
    return f'{x:,.{d}f}'.replace(',','X').replace('.',',').replace('X','.')
def pct(x,d=1): return num(100*x,d)+' %' if x is not None else 'n/p'
def div(a,b): return a/b if a is not None and b else None
def compact(x):
    if x is None:return 'n/p'
    if x>=1e6:return num(x/1e6,2)+' mil.'
    if x>=1e3:return num(x/1e3,1)+' tis.'
    return num(x)
def one(rows,**kw): return next((r for r in rows if all(r.get(k)==v for k,v in kw.items())),None)
def plat(p,scope='selected'):return one(E['platform'],SOURCE_TYPE=p,scope=scope)
def cp(p):return one(R['concentration'],SOURCE_TYPE=p)
def sg(g):return one(E['groups'],group=g)
def ap(p,y):return one(E['annual'],SOURCE_TYPE=p,year_calc=y,scope='selected')
def leaders(p):return [r for r in E['source_ranking'] if r['SOURCE_TYPE']==p and r['interaction_n']>0]
def share(g,p,metric='interactions'):
    a=one(E['group_platform'],SOURCE_TYPE=p,group=g)
    return div(a[metric],plat(p)[metric]) if a else 0
def ratio(g,p,period='sentiment'):
    a=one(R[period],SOURCE_TYPE=p,group=g,sentiment='negative')
    b=one(R[period],SOURCE_TYPE=p,group=g,sentiment='neutral')
    return div(a['mean'],b['mean']) if a and b else None

plt.rcParams.update({'font.family':'DejaVu Sans','font.size':9,'axes.spines.top':False,'axes.spines.right':False,
 'axes.edgecolor':LINE,'text.color':INK,'axes.labelcolor':MUTED,'xtick.color':MUTED,'ytick.color':INK,
 'figure.facecolor':PAPER,'axes.facecolor':PAPER,'savefig.facecolor':PAPER})
for p in PLAT[:6]:
    fig,ax=plt.subplots(figsize=(7.1,2.05))
    y=np.arange(6)
    for delta,metric,label,col in [(-.17,'posts','Objave',GREEN),(.17,'interactions','Interakcije',COPPER)]:
        vals=[100*(share(g,p,metric) or 0) for g in GS]
        ax.barh(y+delta,vals,.3,label=label,color=col)
    ax.set_yticks(y,[GL[g] for g in GS],fontsize=8);ax.invert_yaxis();ax.set_xlim(0,103)
    ax.set_xlabel('Udio unutar odabranih izvora na platformi (%)',fontsize=8)
    ax.legend(frameon=False,loc='lower right',fontsize=8);ax.grid(axis='x',alpha=.15);ax.set_axisbelow(True)
    fig.tight_layout(pad=.5);fig.savefig(FIG/f'actors_{p}.png',dpi=220);plt.close(fig)

months=[f'{y}-{m:02d}' for y in range(2021,2026) for m in range(1,13)]
fig,axs=plt.subplots(3,1,figsize=(7.1,4.3),sharex=True)
for ax,p,col in zip(axs,['web','facebook','youtube'],[GREEN,COPPER,'#557c98']):
    for scope,style,alpha in [('all','-',1),('selected','--',.8)]:
        vals=[]
        for month in months:
            r=one(E['monthly'],SOURCE_TYPE=p,month=month,scope=scope)
            vals.append(r['posts'] if r else np.nan)
        ax.plot(range(60),vals,style,color=col,alpha=alpha,lw=1.6,label='Sve objave' if scope=='all' else 'Odabrani izvori')
    ax.axvspan(36.5,40.5,color='#dbd5cc',alpha=.65);ax.axvline(42,color=MUTED,ls=':',lw=1)
    ax.set_ylabel(P[p],fontsize=9);ax.grid(alpha=.12)
axs[0].legend(frameon=False,fontsize=8,ncol=2,loc='upper left')
axs[-1].set_xticks([0,12,24,36,48,59],['I. 2021.','I. 2022.','I. 2023.','I. 2024.','I. 2025.','XII. 2025.'])
fig.tight_layout(pad=.7);fig.savefig(FIG/'monthly.png',dpi=220);plt.close(fig)

fig,axs=plt.subplots(1,3,figsize=(7.1,3.15),sharey=True)
for ax,p in zip(axs,['web','facebook','youtube']):
    bottom=np.zeros(5)
    for g,col in zip(GS,PALETTE):
        vals=[]
        for year in range(2021,2026):
            a=one(E['annual_groups'],SOURCE_TYPE=p,year_calc=year,group=g)
            den=ap(p,year)
            vals.append(100*a['interactions']/den['interactions'] if a and den and den['interactions'] else 0)
        ax.bar(range(5),vals,bottom=bottom,color=col,label=GL[g],width=.7);bottom+=vals
    ax.set_title(P[p],fontsize=10);ax.set_xticks(range(5),['21','22','23','24*','25']);ax.set_ylim(0,101)
axs[0].set_ylabel('Udio zabilježenih interakcija (%)',fontsize=8)
handles,legend_labels=axs[0].get_legend_handles_labels()
fig.legend(handles,legend_labels,loc='lower center',ncol=3,frameon=False,fontsize=7.5,bbox_to_anchor=(.5,0))
fig.tight_layout(rect=[0,.18,1,1],pad=.6);fig.savefig(FIG/'annual_shares.png',dpi=220);plt.close(fig)

for name,fn in [('Body','calibri.ttf'),('Bold','calibrib.ttf'),('Italic','calibrii.ttf'),('Title','georgia.ttf')]:
    pdfmetrics.registerFont(TTFont(name,'C:/Windows/Fonts/'+fn))
pdfmetrics.registerFontFamily('Body',normal='Body',bold='Bold',italic='Italic',boldItalic='Bold')
ST={
 'body':ParagraphStyle('body',fontName='Body',fontSize=11.5,leading=15.5,textColor=colors.HexColor(INK)),
 'small':ParagraphStyle('small',fontName='Body',fontSize=9.1,leading=11.7,textColor=colors.HexColor(MUTED)),
 'h2':ParagraphStyle('h2',fontName='Bold',fontSize=12,leading=15,textColor=colors.HexColor(INK)),
 'cell':ParagraphStyle('cell',fontName='Body',fontSize=9.3,leading=12,textColor=colors.HexColor(INK)),
 'head':ParagraphStyle('head',fontName='Bold',fontSize=9.1,leading=11.8,textColor=colors.white),
 'title':ParagraphStyle('title',fontName='Title',fontSize=22,leading=27,textColor=colors.HexColor(INK))}
PDF=OUT/'katolicki-akteri-platforme-doseg-vrijeme.pdf'
C=canvas.Canvas(str(PDF),pagesize=A4)
C.setTitle('Tko tumači vjeru u digitalnom javnom prostoru?')
C.setAuthor('DigiKat - deskriptivna reanaliza')
C.setSubject('Katolički akteri, platforme, procijenjeni doseg i promjene kroz vrijeme, 2021.-2025.')
PAGE=0;Y=0;HTML=[];LAYOUT=[]
def para(text,style='body',after=8):
    global Y
    par=Paragraph(text,ST[style]);_,h=par.wrap(CW,1100);par.drawOn(C,M,Y-h);Y-=h+after
    tag='h1' if style=='title' else 'h2' if style=='h2' else 'p'
    HTML.append(f'<{tag} class="{style}">{text}</{tag}>')
def table(headers,rows,widths=None,pad=5):
    global Y
    cells=[[Paragraph(escape(str(v)),ST['head']) for v in headers]]
    cells.extend([[Paragraph(escape(str(v)),ST['cell']) for v in row] for row in rows])
    t=Table(cells,colWidths=widths or [CW/len(headers)]*len(headers))
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor(INK)),
     ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.HexColor('#eef3ef'),colors.HexColor(PAPER)]),
     ('VALIGN',(0,0),(-1,-1),'MIDDLE'),('LEFTPADDING',(0,0),(-1,-1),5),('RIGHTPADDING',(0,0),(-1,-1),5),
     ('TOPPADDING',(0,0),(-1,-1),pad),('BOTTOMPADDING',(0,0),(-1,-1),pad),
     ('LINEBELOW',(0,-1),(-1,-1),.4,colors.HexColor(LINE))]))
    _,h=t.wrap(CW,1100);t.drawOn(C,M,Y-h);Y-=h+10
    HTML.append('<table><thead><tr>'+''.join('<th>'+html.escape(str(v))+'</th>' for v in headers)+'</tr></thead><tbody>')
    HTML.extend('<tr>'+''.join('<td>'+html.escape(str(v))+'</td>' for v in row)+'</tr>' for row in rows)
    HTML.append('</tbody></table>')
def chart(file,height):
    global Y
    C.drawImage(str(FIG/file),M,Y-height,width=CW,height=height,mask='auto');Y-=height+7
    HTML.append(f'<img src="figures/{file}" alt="Izračunati deskriptivni rezultati">')
def start(title,subtitle):
    global PAGE,Y
    if PAGE:end()
    PAGE+=1;C.setFillColor(colors.HexColor(PAPER));C.rect(0,0,W,H,fill=1,stroke=0)
    C.setFillColor(colors.HexColor(MUTED));C.setFont('Bold',8.2);C.drawString(M,H-32,'DIGIKAT / ISTRAŽIVAČKI IZVJEŠTAJ')
    C.setFont('Body',8.2);C.drawRightString(W-M,H-32,'2021.-2025. | 13. listopada 2026.')
    C.setStrokeColor(colors.HexColor(LINE));C.line(M,H-42,W-M,H-42);Y=H-62
    C.bookmarkPage(f'page{PAGE}');C.addOutlineEntry(title,f'page{PAGE}',0)
    HTML.append('<section>');para(title,'title',8);para(subtitle,'small',14)
def end():
    LAYOUT.append({'page':PAGE,'content_bottom':round(Y,1)})
    if Y<55:raise RuntimeError(f'Page {PAGE} overflows: {Y:.1f}')
    C.setStrokeColor(colors.HexColor(LINE));C.line(M,42,W-M,42)
    C.setFillColor(colors.HexColor(MUTED));C.setFont('Body',8)
    C.drawString(M,28,'Lokalni raniji presjek. Opis zabilježene pažnje; oznake aktera su indikativne.')
    C.drawRightString(W-M,28,f'{PAGE} / 20');C.showPage();HTML.append('</section>')
def link(label,path):
    return f'<a href="https://github.com/lusiki/DigiKat/blob/main/{path}" color="{GREEN}">{label}</a>'

main,core=R['main'][0],R['core'][0]
with (BASE/'all_sources.csv').open(encoding='utf-8-sig',newline='') as f:
    all_source_rows=list(csv.DictReader(f))
all_ranked=sorted((r for r in all_source_rows if int(r['observed'])>0),
                  key=lambda r:(-float(r['interactions']),r['source_id']))
all_top50=all_ranked[:50]
other_public=one(R['actor_groups'],group='public')
other_christian=one(R['actor_groups'],group='other_christian')
assert (core['posts']+other_public['posts']+other_christian['posts']==main['posts'])
assert sum(int(r['posts']) for r in all_source_rows)==main['posts']
start('Tko tumači vjeru u digitalnom javnom prostoru?',
      'Uvid za pitanje: Tko je preuzeo ulogu teologa u hrvatskom javnom prostoru? Katolički akteri, platforme, procijenjeni doseg i vrijeme u lokalnom skupu DigiKat.')
para('Odgovor koji podaci mogu dati','h2')
para('U digitalnom prostoru pažnju dijele institucionalni crkveni izvori, neovisni katolički mediji i autorski kanali. Njihov je odnos izrazito različit po platformama. Ova analiza pokazuje gdje je zabilježena pažnja i kojim se izvorima može posvetiti daljnje istraživanje autoriteta; ne utvrđuje da je netko zamijenio teologe.')
table(['Istraživačko pitanje','Izravan odgovor'],[
 ('Postoji li raščlamba po vrstama aktera?','Da, indikativna. Šest skupina izvedeno je iz postojećih popisa i pravila; identitet urednika i mandat nisu potpuno provjereni.'),
 ('Postoje li otvoreni agregati?','Da, djelomično. Javni CSV s vrstama aktera i javni platformski agregati postoje, ali opisuju noviji korpus. Ovdje su izračunati zasebni agregati lokalnog presjeka.'),
 ('Može li se dobiti prvih 50 izvora?','Da. Str. 18-20 daju 50 odabranih katoličkih kanala; zasebni CSV daje 50 vodećih oznaka izvora među svih 601.036 zapisa.')],[155,CW-155])
para('Glavni nalazi','h2')
para(f'Analitički skup obuhvaća <b>{num(main["posts"])} zapisa</b> iz 2021.-2025. Tablica vrsta aktera na str. 3 prikazuje samo <b>{num(core["posts"])} zapisa ({pct(core["posts"]/main["posts"])})</b> s {num(core["sources"])} parova platforma/naziv koje su postojeći popisi svrstali u šest skupina. Preostalih {num(main["posts"]-core["posts"])} zapisa ostaje u analitičkom skupu, ali nije u toj šestorednoj usporedbi.')
para(f'Na webu crkveni mediji nose {pct(share("church_media","web"))} interakcija odabranih izvora. Na Facebooku neovisni mediji nose {pct(share("independent","facebook"))}, a na YouTubeu pobožni/autorski kanali {pct(share("devotional","youtube"))}. Visoka vidljivost autorskih kanala stoga se pojavljuje uz snažnu institucionalnu i medijsku prisutnost.')
para('Pet vodećih oznaka izvora među svim zapisima','h2')
table(['Izvor / platforma','Radna skupina','Interakcije'],[
    (r['source']+' / '+PC.get(r['SOURCE_TYPE'],P.get(r['SOURCE_TYPE'],r['SOURCE_TYPE'])),
     r['group_label'],num(float(r['interactions']))) for r in all_ranked[:5]],
     [204,193,CW-397],pad=4)
para('Ovo je rang zabilježenih oznaka izvora u punom skupu, uključujući opće medije. Oznaka "ostali i nerazvrstani" ne govori tumači li pojedini autor vjeru. Cijela ljestvica od 50 u zasebnom je CSV-u.','small')
para('Doseg je procjena po objavi, a vremenske razlike ovise i o prikupljanju. Negativan sentiment nije dosljedno povezan s većim angažmanom na svim platformama i unutar istih izvora. To ograničava jednostavnu tezu o općoj prednosti konfliktnih neinstitucionalnih glasova.')
para('Str. 2-5: obuhvat, izbor skupina i otvoreni podaci; 6-12: platforme; 13-16: doseg i vrijeme; 17: ton; 18-20: 50 odabranih kanala.','small')

start('Podaci, jedinice i granice zaključivanja','Što je analizirano i što pojedina mjera znači.')
table(['Korak','Broj zapisa'],[
 ('Lokalni ulazni presjek',num(R['input']['raw_rows'])),
 ('Isključeno izvan razdoblja 2021.-2025.',num(R['input']['excluded_outside_period'])),
 ('Uklonjeni ponovljeni zapisi iste platforme i URL-a',num(R['input']['duplicate_captures_removed'])),
 ('Analitički skup',num(main['posts'])),
 ('Objave šest odabranih skupina',num(core['posts']))],[CW-105,105])
para('Kako se 601.036 zapisa dijeli?','h2')
table(['Obuhvat nakon datuma i uklanjanja duplikata','Objave','Udio svih zapisa'],[
 ('Šest izdvojenih skupina kanala',num(core['posts']),pct(core['posts']/main['posts'])),
 ('Ostali i nerazvrstani izvori',num(other_public['posts']),pct(other_public['posts']/main['posts'])),
 ('Zasebni međukršćanski izvor',num(other_christian['posts']),pct(other_christian['posts']/main['posts'])),
 ('Ukupno',num(main['posts']),'100 %')],[CW-174,75,99],pad=4)
para('Podjela je po nazivu izvora, a ne po sadržajnoj provjeri svake objave. Šest skupina nije zaseban korpus niti svih 601.036 zapisa; u ostatku su i opći mediji koji objavljuju o katoličkim temama.','small')
para('Lokalna datoteka sadrži raniji presjek akumulatora. Službeni noviji korpus od 413.985 zapisa nije dostupan na ovom računalu. Njegovi javni agregati imaju drugi obuhvat i nisu pribrojeni rezultatima ove analize. Dio lokalnog skupa može biti periferno povezan s katoličkom tematikom; ovdje nije ponovljen službeni postupak uključivanja u korpus.')
para('Jedinica izvora jest kombinacija platforme i normaliziranog naziva. Isti medij na webu i Facebooku računa se dvaput. Spojena je samo jedna već dokumentirana inačica naziva unutar platforme. Izvor koji objavi propovijed nije nužno njezin autor; kanal i teolog koji u njemu govori nisu ista analitička jedinica.')
table(['Mjera','Operacionalizacija i ograničenje'],[
 ('Objave','Zapisi koje je sustav prikupio za temu; nisu sve objave računa.'),
 ('Angažman','Zabilježeno polje INTERACTIONS. Sastav mjere ovisi o platformi. Nula i nedostajuća vrijednost ostaju različite.'),
 ('Doseg','Polje REACH, procjena za pojedinu objavu. Zbroj dopušta višestruko brojanje istih osoba; metodologija procjene nije dokumentirana u ovom presjeku.'),
 ('Vrijeme','Datum objave, a ne datum mjerenja reakcija. Razlike uključuju trajanje izloženosti i promjene prikupljanja.'),
 ('Autoritet','Ovim podacima nije izravno mjeren: nema pouzdane procjene teološkog obrazovanja, mandata ni prihvaćanja tumačenja od publike.')],[82,CW-82])
para(f'Ponovljeni URL zadržava zapis s najvećim dostupnim angažmanom, a doseg iz tog istog zapisa. Prazni URL-ovi ostaju zasebni. Godina je izvedena iz datuma; pronađeno je {num(R["input"]["stored_year_disagreements"])} odstupanja u pohranjenoj godini. To je obrada presjeka, ne longitudinalno praćenje iste objave.','small')

start('Koje vrste aktera razlikujemo?','Ovih šest redaka obuhvaća samo 153.015 od 601.036 zapisa (25,5 %); to nije raspodjela cijeloga skupa.')
table(['Skupina','Izvori','Objave','Interakcije','Udio*'],[
 (GL[g],num(sg(g)['sources']),num(sg(g)['posts']),num(sg(g)['interactions']),pct(sg(g)['interactions']/core['interactions'])) for g in GS],
 [165,48,74,95,CW-382])
para('*Udio u interakcijama šest skupina, zbrojenima preko platformi; pregled veličine, a ne usporediva mjera društvenog utjecaja.','small')
para(f'Izvan ove tablice ostaje {num(other_public["posts"])} zapisa ostalih/nerazvrstanih izvora i {num(other_christian["posts"])} zapisa međukršćanskog izvora. Među pedeset vodećih oznaka izvora iz punog skupa {num(sum(r["group"]=="public" for r in all_top50))} je u skupini ostali/nerazvrstani. Zbog toga se šestoredna tablica ne smije čitati kao iscrpna mapa javnih tumača vjere.','small')
para('Crkveni mediji i crkvene ustanove','h2')
para('Prva skupina okuplja medijske kanale povezane s crkvenim ustanovama; druga biskupije, redove, župe i druge službene račune. Vlasništvo ili institucionalna pripadnost nisu dokaz da svaka objava izražava obvezujući crkveni nauk. Neovisni mediji čine zasebnu skupinu i kada prenose institucionalne poruke.')
para('Svećenici, laici i nepoznati urednici','h2')
para('Svećenički profili izdvojeni su ondje gdje ih prepoznaju postojeći popisi ili bilješke registra. Pobožni/autorski kanali obuhvaćaju brendirane i osobne izvore čiji status urednika često nije poznat. Zato se ova skupina ne može izjednačiti s laicima, a sam naziv kanala ne dokazuje njegov institucionalni mandat.')
reg=one(R['classification_coverage'],rule='existing_registry')
para(f'Prednost ima izričita oznaka iz registra izvora; zatim se koriste postojeći katalozi i obrasci naziva. Registar izravno pokriva {num(reg["sources"])} izvora i {pct(reg["posts"]/core["posts"])} objava odabranog skupa. Ostalo se oslanja na manje izravna pravila. To je širok istraživački odabir, a ne potvrđeni imenik katoličkih aktera.')
para('Ista oznaka vrste primijenjena je na cijelo razdoblje; moguće promjene vlasništva ili uredništva nisu rekonstruirane. Obuhvat je digitalni prostor zahvaćen tematskim upitom, uključujući regionalne izvore, a ne reprezentativan uzorak stanovnika Hrvatske.','small')
cl=one(E['group_concentration'],group='clergy')
para(f'Kanal pulherissimus čini {pct(cl["top1_share"])} interakcija skupine svećeničkih profila: obilježja te skupine pretežno su obilježja jednoga kanala. Novi Život vodi se zasebno kao međukršćanski izvor prema registru i nije u katoličkom odabiru. Nerazvrstani izvori nisu automatski sekularni.','small')
para('Primijenjeni izvori: '+link('registar skupina','explorations/okvir-katolicanstva-prototype/source-groups.csv')+', '+link('katalog izvora','resources/dictionaries/source_labels.csv')+' i '+link('postojeći klasifikator','studies/catholic-influencers/actor_classification.R')+'. Oznake ne uključuju novu biografsku provjeru.','small')

start('Jesu li raščlambe otvoreno dostupne?','Da, djelomično. Provjereni javni resursi i novi prilozi ovog izvještaja.')
para('Postojeći otvoreni agregati','h2')
table(['Resurs u javnom repozitoriju','Što sadrži','Što ne daje'],[
 ('actor_counts.csv','Vrste aktera, šire skupine, pouzdanost, broj izvora i objava te interakcije.','Potpunu novu tipologiju po platformi, dosegu i mjesecu.'),
 ('platform_summary / platform_monthly','Godišnji i mjesečni broj objava, interakcije i doseg po platformama.','Vrste aktera unutar svake platforme.'),
 ('source_summary / top_sources_by_year','Godišnje rezultate nazvanih izvora.','Zaseban stupac platforme i pouzdanu podjelu klerici/laici.'),
 ('*_actors / top_*_sources','Kratke popise imenovanih izvora s metrikama.','Iscrpan registar aktera ni jedinstveni top 50 svih platformi.')],[145,183,CW-328])
para('Izravne poveznice: '+link('CSV po vrstama aktera','studies/catholic-influencers/output/tables/actor_counts.csv')+'; '+link('manifest 14 agregata i njihove sheme','data/processed/manifest.json')+'; '+link('podrijetlo ranije analize aktera','studies/catholic-influencers/output/analysis_input_manifest.json')+'. Dostupnost je provjerena 13. listopada 2026.','small')
para('Različiti obuhvati','h2')
para('Javni platformski agregati temelje se na službenom korpusu od 413.985 zapisa do lipnja 2026. Ranija analiza aktera isključuje TikTok i obuhvaća 413.788 zapisa. Ovaj izvještaj koristi lokalni raniji presjek, završava s 2025. i zadržava TikTok. Oznake i ukupni brojevi zato nisu neposredno zamjenjivi.')
para('Što je sada pripremljeno za dijeljenje','h2')
para('Novi paket agregata sadrži tablice vrsta aktera i platformi, procijenjeni doseg, godišnje i mjesečne prikaze, usporedbe istih izvora te podatke o pokrivenosti. CSV datoteke nemaju nazive pojedinačnih izvora, tekstove objava ni njihove URL-ove. Uz njih dolaze opis stupaca i manifest ulaznog presjeka.')
para('Zasebni prilozi daju prvih 50 odabranih kanala i prvih 50 oznaka izvora iz punog skupa. Drugi popis uključuje opće i nerazvrstane izvore, a poneka oznaka ne predstavlja prepoznatljiv pojedinačni račun. Polja za mandat i obrazovanje ostaju prazna; prilozi su lokalni.','small')

start('Pregled svih platformi','Obuhvat skupa i dostupnost metrika prije usporedbe aktera.')
table(['Platforma','Sve objave','Odabrane objave','Odabrani izvori','Interakcije dostupne*','Doseg dostupan*'],[
 (P[p],num(plat(p,'all')['posts']),num(plat(p)['posts'] if plat(p) else 0),num(plat(p)['sources'] if plat(p) else 0),
 pct(div(plat(p,'all')['interaction_n'],plat(p,'all')['posts'])),pct(div(plat(p,'all')['reach_n'],plat(p,'all')['posts']))) for p in PLAT],
 [73,82,87,69,100,CW-411])
para('*Udio svih zapisa na platformi s upotrebljivom metrikom. Nula posto označuje nedostupnost podatka, ne odsutnost reakcija ili publike. Izvori su parovi platforma/naziv.','small')
para('Dva analitička obuhvata','h2')
para(f'Sve platforme zajedno sadrže {num(main["posts"])} zapisa. Šest skupina čini {pct(core["posts"]/main["posts"])} tog broja. Ostatak uključuje opće medije, druge kršćanske izvore, javnu raspravu i nerazvrstane račune. Taj je širi skup kontekst vidljivosti katoličkih tema, ali nije imenik katoličkih tumača.')
para('Za podjelu interakcija među vrstama aktera nazivnik je uvijek odabrani skup na istoj platformi. Za pokrivenost prikupljanja koristi se i širi skup. Usporedba ta dva obuhvata sprječava da se medijsko izvještavanje o Crkvi automatski pripiše crkvenim ili katoličkim akterima.')
para('Platforme nisu jedinstvena ljestvica utjecaja','h2')
para('Web, Facebook i YouTube nose glavninu raspoloživih objava i metrika odabranih izvora. Instagram, TikTok i X/Twitter nude znatno užu osnovu. Forumi, Reddit i komentari zasebni su oblici sudjelovanja; njihove oznake izvora često predstavljaju skupna mjesta razgovora, a ne pojedinačne autoritete.')
para('Brojčano veći angažman na jednoj platformi može proizići iz drukčije definicije interakcije, obuhvata, trajanja dostupnosti i formata. Zato se primarno uspoređuju akteri unutar platforme, a zajednički top 50 služi odabiru slučajeva za istraživanje.','small')

platform_notes={
 'web':('Institucionalna vidljivost preko medija',
 'Web odražava objavljivačku infrastrukturu: uredništva, arhive i veliku učestalost objava. Dominacija institucionalnog portala ne znači da su svi autori na njemu institucionalni glasnogovornici. Isto vrijedi i za teologe koji gostuju na neovisnim portalima.',
 'Web-interakcije u ovom skupu gotovo uvijek odgovaraju zbroju dostupnih lajkova, komentara i dijeljenja. To ne daje mjeru čitanosti članka. Doseg i reakcije zato ostaju odvojeni pokazatelji.'),
 'facebook':('Mediji i pobožne zajednice dijele pažnju',
 'Facebook povezuje medijsku distribuciju s komunikacijom zajednica. Nazivi poput VJERA ili Kapljice ljubavi Božje upućuju na kanal i prepoznatljiv stil, ali sami ne otkrivaju tko uređuje stranicu niti s kojim mandatom tumači vjeru.',
 'Na svim objavama s dostupnim sastavnicama INTERACTIONS odgovara zbroju lajkova, komentara i dijeljenja. Reakcija može označavati potporu, polemiku ili distribuciju sadržaja; nije mjera prihvaćenog vjerskog autoriteta.'),
 'youtube':('Autorski i pobožni kanali kao posrednici',
 'YouTube je najizraženije mjesto autorskih i pobožnih kanala u ovom odabiru. Kanal može okupljati propovijedi više svećenika, glazbu, molitve i kratka tumačenja. Ulogu javnog tumača stoga treba razlikovati od uloge distributera tuđega tumačenja.',
 'Broj pregleda pohranjen je zasebno od interakcija. Videoobjava dugo skuplja preglede i reakcije, pa usporedbe starih i novijih godišta nisu usporedbe jednake izloženosti. Svećenički segment ovdje izrazito ovisi o kanalu pulherissimus.'),
 'instagram':('Mali odabir i dominacija jednoga medija',
 'Ovaj presjek ne pokriva dovoljno široko katoličke profile na Instagramu da bi se opisala cijela scena. Mali broj prepoznatih izvora odražava prikupljanje i postojeći katalog. Ne može se zaključiti da ostali laički ili svećenički profili nisu aktivni.',
 'INTERACTIONS odgovara zbroju lajkova i komentara. Polje pregleda treba čitati uz udio nultih vrijednosti i dostupnost po razdoblju. Visoki udio jednog izvora opisuje ovaj odabir, ne tržišni udio u cjelokupnoj platformi.'),
 'tiktok':('Kratki video uz vrlo ograničen uzorak',
 'TikTok se zadržava u analizi iako ga prethodna javna studija aktera isključuje. Ovdje je riječ o malom skupu zapisa i malom broju prepoznatih izvora; pojedina objava može snažno promijeniti rangove i prosjeke.',
 'Brojevi nisu osnova za tvrdnju o rastu ili padu katoličkoga TikToka. Postojeći naziv osobnog računa ne daje automatski informaciju o teološkom obrazovanju ili institucionalnom mandatu. Zasebno polje VIEW_COUNT ovdje nije raspoloživo.'),
 'twitter':('Uska mjerena prisutnost, širi javni kontekst',
 'X/Twitter u tematskom skupu uključuje mnogo općega javnog govora i političkih reakcija. Odabrani katolički izvori obuhvaćaju samo dio tog prostora. Političko pozivanje na katoličanstvo nije samo po sebi dokaz uloge teološkoga tumača.',
 'Ukupne interakcije su malene pa razlike nekoliko objava mogu bitno promijeniti rang. Imena računa i registri nisu dokaz kontinuiteta vlasnika kroz cijelo razdoblje; zato identitet ovdje ostaje vezan uz zabilježeni naziv izvora.')}
for p in PLAT[:6]:
    a,b=plat(p),plat(p,'all');ls=leaders(p);title,interpret,metricnote=platform_notes[p]
    start(P[p]+': '+title,'Profil odabranih šest skupina na platformi; potpuni godišnji nizovi nalaze se u agregatima.')
    table(['Objave / izvori','Interakcije ukupno','Medijan interakcija','Doseg: medijan / dostupnost'],[
     (num(a['posts'])+' / '+num(a['sources']),num(a['interactions']),num(a['interaction_median']),num(a['reach_median'])+' / '+pct(a['reach_n']/a['posts']))],
     [121,124,114,CW-359])
    para(f'Odabrani izvori čine {pct(a["posts"]/b["posts"])} zapisa na platformi. Razdioba objava i interakcija pokazuje razlikuje li se produktivnost skupine od pažnje koju okuplja.','small')
    chart(f'actors_{p}.png',147)
    table(['Vodeći izvor','Vrsta','Objave','Interakcije','Medijan'],[
     (r['source'],GC[r['group']],num(r['posts']),num(r['interactions']),num(r['interaction_median'])) for r in ls[:4]],
     [220,39,70,103,CW-432])
    para('CM crkveni mediji; CU ustanove; NM neovisni mediji; SP svećenički profili; ZU zajednice; PA pobožni/autorski kanali.','small',5)
    para(interpret)
    c=cp(p)
    para(f'Prvi izvor okuplja {pct(c["top1"])} interakcija, a vodećih {num(min(10,c["sources"]))} izvora {pct(c["top10"])}. Zbroj procijenjenih dosega iznosi {compact(a["reach_total"])}; riječ je o zbroju procjena po objavama, uz moguće višestruko brojanje publike.')
    years=[ap(p,y) for y in [2021,2023,2025]]
    table(['Godina','Objave','Interakcije','Medijan dosega','Dostupnost dosega'],[
        (str(year),num(r['posts']) if r else 'nema zapisa',num(r['interactions']) if r else 'n/p',num(r['reach_median']) if r else 'n/p',pct(r['reach_n']/r['posts']) if r else 'n/p')
        for year,r in zip([2021,2023,2025],years)],[56,101,119,118,CW-394],pad=4)
    para('Vremenski orijentiri, ne procjena rasta platforme. Praznine i promjena obuhvata objašnjene su na str. 14-16.','small',4)
    para(metricnote,'small')

start('Reddit, forumi i komentari','Rasprava publike vidljiva je u tekstovima, ali nema usporedivih mjera dosega i angažmana.')
table(['Mjesto razgovora','Zapisi','Oznake izvora','Mjeseci sa zapisima','Zapisi s tekstom'],[
 (P[p],num(plat(p,'all')['posts']),num(plat(p,'all')['sources']),num(plat(p,'all')['months']),pct(plat(p,'all')['text_n']/plat(p,'all')['posts'])) for p in ['reddit','forum','comment']],
 [117,84,99,113,CW-413])
para('U ove tri kategorije dostupnost polja INTERACTIONS i REACH nije dovoljna za rangiranje. Nedostajuće vrijednosti prikazane su kao n/p, a ne kao nula. Zbog toga te kategorije ne ulaze u ljestvicu angažmana. To nije zaključak da u njima nema reakcija ili utjecaja.')
para('Zašto se oznaka izvora drukčije tumači','h2')
para('Forum ili subreddit okuplja velik broj nepovezanih autora. Agregiranje pod oznakom forum.hr ili croatia može biti korisno za opis mjesta razgovora, ali takva oznaka nije jedan javni tumač vjere. Kod komentara se oznaka platforme može pojaviti umjesto stabilnog identiteta autora.')
para('Kako ovaj dio informira istraživačko pitanje','h2')
para('Tekstovi mogu pokazati kako se prenosi, osporava ili traži vjersko tumačenje. To je druga strana odnosa autoriteta: recepcija i pregovaranje značenja. Sama učestalost pojavljivanja teme ne pokazuje kome sudionici vjeruju niti tko ima teološko znanje.')
table(['Moguće iz postojećih podataka','Ovim pregledom nije utvrđeno'],[
 ('Broj prikupljenih zapisa i njihova vremenska raspodjela.','Broj različitih osoba koje su sadržaj vidjele.'),
 ('Dostupnost teksta za eventualno kasnije čitanje.','Potpuna mapa pojedinačnih autora i njihovih identiteta.'),
 ('Položaj razgovora u širem tematskom skupu.','Prihvaćanje ili odbacivanje teološkog autoriteta konkretnog aktera.')],[CW/2,CW/2])
para('Ove kategorije ostaju u mjesečnim i godišnjim agregatima šireg skupa. Nisu nasilno pridružene katoličkim akterima samo zbog vjerske teme razgovora. Redditov zaseban rezultat glasanja, ondje gdje postoji, nije izjednačen s INTERACTIONS.','small')
para('Naslijeđena pravila naziva izdvajaju tri Redditove oznake s pet zapisa kao kandidate u odabranom skupu. To nije potvrda njihova katoličkog identiteta ni uloge javnih tumača; bez metrika ne ulaze u ljestvicu.','small')

start('Doseg: veličina, raspodjela i značenje','Polje REACH opisuje objavu; zbroj nije broj jedinstvenih primatelja.')
table(['Platforma','Zbroj dosega','Medijan / objava','Dostupnost','Nule među dostupnim'],[
 (P[p],compact(plat(p)['reach_total']),num(plat(p)['reach_median'],1),pct(plat(p)['reach_n']/plat(p)['posts']),pct(plat(p)['reach_zero_n']/plat(p)['reach_n'])) for p in PLAT[:6]],
 [87,104,115,95,CW-401])
ytflag=one(E['metric_flags'],SOURCE_TYPE='youtube')
para(f'Na YouTubeu se REACH podudara s VIEW_COUNT u {pct(ytflag["reach_equals_views"]/ytflag["reach_and_views"])} svih zapisa s oba podatka. To pokazuje da ove dvije varijable u presjeku uglavnom nisu neovisne mjere. Pregled videa nije nužno različita osoba, a zbroj pregleda preko videa dodatno ponavlja publiku.')
para('Jesu li isti izvori vodeći po obje mjere?','h2')
reach_leads=[]
for p in ['web','facebook','youtube']:
    rows=sorted([r for r in leaders(p) if r['reach_total'] is not None],key=lambda r:-r['reach_total'])[:2]
    reach_leads.extend([(P[p],r['source'],compact(r['reach_total']),num(r['platform_rank']),pct(r['reach_coverage'])) for r in rows])
table(['Platforma','Vodeći po dosegu','Zbroj dosega','Rang po angažmanu*','Dostupnost'],reach_leads,[67,165,97,98,CW-427])
para('*Rang unutar platforme. Doseg i interakcije zbrajaju se samo preko dostupnih vrijednosti; izvori se razlikuju i po broju objava.','small')
para('Web i Facebook imaju snažno preklapanje vodećih izvora po dosegu i reakcijama. YouTube pokazuje izraženije razlike: kanal s velikim brojem pregleda ne mora imati jednako visok rang po interakcijama. Za odabir istraživačkih slučajeva vrijedi zadržati obje mjere, uz volumen i medijan po objavi.')
para(f'Pokrivenost dosega kod odabranih YouTube izvora raste s {pct(ap("youtube",2021)["reach_n"]/ap("youtube",2021)["posts"])} u 2021. na {pct(ap("youtube",2025)["reach_n"]/ap("youtube",2025)["posts"])} u 2025. Rast zbroja dosega zato nije čista promjena publike. Omjer interakcija i dosega ovdje se ne pretvara u jedinstvenu stopu angažmana.','small')

start('Vrijeme: najprije pokrivenost prikupljanja','Mjesečni broj zapisa, prekid 2024. i promjena ulaznog izvora.')
chart('monthly.png',286)
para('Siva zona označuje veljaču-svibanj 2024., kada nema zapisa u lokalnom skupu. To nisu mjeseci bez katoličke komunikacije. Točkasta linija označuje srpanj 2024., od kada prevladava novi ulazni izvor filtered_religious; raniji original_dta završava 4. srpnja.','small')
table(['Godina','Sve objave','Odabrane objave','Odabrani izvori','Mjeseci'],[
 (str(y)+('*' if y==2024 else ''),num(one(E['annual_all'],year_calc=y,scope='all')['posts']),num(one(E['annual_all'],year_calc=y,scope='selected')['posts']),num(one(E['annual_all'],year_calc=y,scope='selected')['sources']),num(one(E['annual_all'],year_calc=y,scope='all')['months'])) for y in range(2021,2026)],
 [63,113,120,120,CW-416])
para('Skok broja zapisa i izvora nakon sredine 2024. može odražavati proširen ili promijenjen dohvat. Pojava izvora prvi put u bazi nije dokaz da je tada nastao. Godina 2024. ima osam zastupljenih mjeseci; njezini ukupni rezultati nisu usporedivi s punom godinom.')
para('Krivulje opisuju prikupljene zapise. Praznine su prikazane kao nedostajući podaci, bez interpolacije. Nema podataka o jednakoj vjerojatnosti uključivanja računa ni o jednakom vremenu mjerenja reakcija. Stoga se ovdje ne procjenjuje stopa rasta hrvatske katoličke digitalne javnosti.','small')

start('Kako se mijenja sastav pažnje?','Udio vrsta aktera u interakcijama, zasebno unutar svake platforme.')
chart('annual_shares.png',229)
para('*2024. obuhvaća osam mjeseci i promjenu prikupljanja. Udio se računa samo među šest odabranih skupina, na istoj platformi i u istoj godini.','small')
def annual_share(p,g,y):
    a=one(E['annual_groups'],SOURCE_TYPE=p,year_calc=y,group=g)
    return a['interactions']/ap(p,y)['interactions'] if a else 0
contrasts=[('web','church_media'),('web','independent'),('facebook','independent'),('facebook','devotional'),('youtube','devotional'),('youtube','clergy')]
table(['Platforma / skupina','Udio 2023.','Udio 2025.','Razlika, postotni bodovi'],[
 (P[p]+' / '+GL[g],pct(annual_share(p,g,2023)),pct(annual_share(p,g,2025)),num(100*(annual_share(p,g,2025)-annual_share(p,g,2023)),1)) for p,g in contrasts],
 [235,77,77,CW-389])
para('Ove usporedbe opisuju promjenu sastava zabilježene pažnje, uz promijenjen sastav dostupnih izvora. Rast udjela može se pojaviti zbog pada drugih skupina ili promjene prikupljanja, i bez povećanja reakcija kod istih računa.')
over=E['rank_overlap'][0]['overlap']
para(f'Od pedeset vodećih izvora za cijelo razdoblje, <b>{num(over)}</b> nalazi se i među prvih pedeset za 2025. Zajednički petogodišnji popis zato daje stabilan početni pregled, ali dio izvora relevantnih za najnoviju godinu ostaje izvan njega. CSV sadrži i godišnji rang te rang unutar platforme.')
para('Strukturu je korisno čitati kao položaj medijskih posrednika i autorskih kanala. Promjena njihovih udjela sama po sebi ne pokazuje prijenos teološke kompetencije ili legitimnosti s jedne skupine na drugu.','small')

start('Promjene među istim izvorima','Srpanj-prosinac 2024. i srpanj-prosinac 2025.; najmanje pet zapisa po izvoru u oba razdoblja.')
matched=E['cohort_matched']
def co(p,y):return one(matched,SOURCE_TYPE=p,period=str(y)+'H2')
rows=[]
for p in ['web','facebook','youtube']:
    a,b=co(p,2024),co(p,2025)
    rows.append((P[p]+' ('+num(a['sources'])+')',num(a['posts'])+' / '+num(b['posts']),pct(b['interactions']/a['interactions']-1),num(a['interaction_mean'],1)+' / '+num(b['interaction_mean'],1),num(a['reach_mean'],0)+' / '+num(b['reach_mean'],0)))
table(['Platforma (isti izvori)','Objave 2024. / 2025.','Promjena ukupnih interakcija','Prosjek interakcija po objavi 2024. / 2025.','Prosjek dosega po objavi 2024. / 2025.'],rows,
 [90,112,93,110,CW-405])
para('Jednaki sezonski prozori smanjuju razliku u trajanju razdoblja. Zadržavanje istih izvora smanjuje utjecaj ulaska novih računa u bazu. Time se ipak ne uklanjaju razlike u temama, broju uhvaćenih objava, starosti sadržaja i mjerenju reakcija.')
para('Promjena kod tipičnog izvora','h2')
table(['Platforma','Izvori s rastom prosjeka interakcija','Medijan promjene prosjeka interakcija','Izvori s rastom prosjeka dosega'],[
 (P[p],pct(one(E['cohort_source_changes'],SOURCE_TYPE=p)['interaction_increase_share']),num(one(E['cohort_source_changes'],SOURCE_TYPE=p)['mean_interaction_change_median'],1),pct(one(E['cohort_source_changes'],SOURCE_TYPE=p)['reach_increase_share'])) for p in ['web','facebook','youtube']],
 [89,150,143,CW-382])
para('U drugoj tablici svaki izvor ima jednaku težinu. Prva tablica veći utjecaj daje izvorima s više objava. Razlika je sadržajno važna: rast ukupnih reakcija može pratiti češće objavljivanje bez usporednog rasta reakcija na tipičnu objavu.')
para(f'Na Facebooku ukupne interakcije istih izvora rastu za {pct(co("facebook",2025)["interactions"]/co("facebook",2024)["interactions"]-1)}, a prosjek po objavi za {pct(co("facebook",2025)["interaction_mean"]/co("facebook",2024)["interaction_mean"]-1)}. Na YouTubeu ukupne interakcije padaju za {pct(1-co("youtube",2025)["interactions"]/co("youtube",2024)["interactions"])}, uz manje zabilježenih objava i niži prosjek po objavi.')
para('Doseg ne daje jedinstven smjer: medijan dosega YouTube objave raste s '+num(co('youtube',2024)['reach_median'],1)+' na '+num(co('youtube',2025)['reach_median'],1)+', dok prosjek pada. To je opis raspodjele, a ne dokaz algoritamske promjene.','small')
oldn=one(E['cohort_origin'],period='2024H2',data_source='original_dta')['posts']
newn=one(E['cohort_origin'],period='2024H2',data_source='filtered_religious')['posts']
para(f'Usporedba obuhvaća samo web, Facebook i YouTube jer drugi kanali nemaju izvore koji ispunjavaju prag u oba razdoblja. U prvom prozoru ostaje {num(oldn)} zapisa ranijeg ulaznog izvora, uz {num(newn)} iz novijega. Analiza je deskriptivna i selektivna; iz nje se ne procjenjuje uzrok promjene.','small')

start('Ton, teme i pitanje teološkog autoriteta','Postojeće automatske oznake daju tragove, uz snažnu ovisnost o platformi i izvoru.')
para('Donja tablica uspoređuje prosječne interakcije negativnih i neutralnih objava iste skupine. Vrijednost iznad 1 znači veći prosjek negativnih objava. Pozitivne i neoznačene objave ostaju u zasebnim agregatima, izvan ovog omjera.','small')
table(['Skupina / platforma','2021.-2025.','Samo 2025.'],[
 (GL[g]+' / '+P[p],num(ratio(g,p),2),num(ratio(g,p,'sentiment_2025'),2))
 for g,p in [('devotional','facebook'),('devotional','youtube'),('independent','facebook'),('independent','youtube')]],
 [CW-170,85,85])
ws=one(R['within_source'],SOURCE_TYPE='youtube',group='devotional')
para(f'Prednost negativnih objava kod pobožnih/autorskih YouTube kanala slabi kada se izdvoji 2025. Pri usporedbi unutar istoga kanala, među {num(ws["sources"])} kanala s najmanje pet negativnih i pet neutralnih objava, samo {pct(ws["share_negative_higher"])} ima viši prosjek negativnih objava. Sastav izvora može stvarati razliku vidljivu u skupnom prosjeku.')
para('Tematski tragovi iz postojećih rječnika','h2')
theme_keys=[('DUHOVNOST_I_LITURGIJA','Duhovnost / liturgija'),('TEOLOGIJA_I_DOKTRINA','Teologija / doktrina'),('UNUTARCRKVENI_PRIJEPORI_I_IDEOLOGIJE','Unutarcrkveni prijepori')]
theme_rows=[]
for g in ['church_media','independent','clergy','devotional']:
    theme_rows.append([GL[g]]+[pct(one(R['themes'],group=g,theme=k)['share']) for k,label in theme_keys])
table(['Skupina']+[label for k,label in theme_keys],theme_rows,[166,115,115,CW-396])
para('Udio objava s rječničkim podudaranjem u prvih 3.000 znakova teksta; kategorije se preklapaju. Obuhvat su objave s tekstom unutar skupine, preko svih platformi. Jedna riječ ne dokazuje da objava tumači nauk, osporava Crkvu ili nastupa s autoritetom.','small')
para('Što to znači za glavno pitanje','h2')
para('Nalazi podupiru istraživanje pluralnih posrednika vjerskoga govora i koncentracije pažnje. Ne pokazuju nestanak institucionalnih teologa ni jednostavnu zamjenu klerika laicima. Za daljnje čitanje posebno su informativni vodeći institucionalni i neovisni mediji, autorski kanali s velikom pažnjom te izvori čiji se rang po dosegu razlikuje od ranga po reakcijama.')
para('Polja za obrazovanje, mandat i izvore autoriteta u priloženoj tablici ostaju otvorena upravo zato što se te karakteristike ne mogu pouzdano izvesti iz metrika, naziva kanala ili automatskog sentimenta.','small')

top=[r for r in E['source_ranking'] if r['interaction_n']>0][:50]
for page_index,(begin,finish) in enumerate([(0,17),(17,34),(34,50)]):
    start(f'Odabrani kanali: mjesta {begin+1}-{finish}',
          'Prema zbroju zabilježenih interakcija, 2021.-2025. Odabrane skupine; ista organizacija na različitim platformama ima zaseban redak.')
    table(['Rang','Izvor / platforma','Vrsta','Objave','Interakcije','Doseg: zbroj'],[
     (num(r['rank']),r['source']+' / '+PC[r['SOURCE_TYPE']],GC[r['group']],num(r['posts']),num(r['interactions']),compact(r['reach_total'])) for r in top[begin:finish]],
     [34,212,36,61,89,CW-432],pad=6)
    para('CM crkveni mediji; CU crkvene ustanove; NM neovisni katolički mediji; SP svećenički profili; ZU zajednice i udruge; PA pobožni/autorski kanali. FB Facebook; YT YouTube; IG Instagram.','small')
    if page_index==0:
        para(f'Ljestvica uključuje {num(R["all_concentration"][0]["sources"])} izvora s dostupnim interakcijama; prvih pedeset nosi {pct(R["all_concentration"][0]["top50"])} njihova zbroja. Različite definicije platformskih interakcija ograničavaju tumačenje zajedničkoga ranga.','small')
        para('Doseg je zbroj dostupnih procjena, nije deduplicirana publika. Tablica služi početnom odabiru slučajeva; nije ljestvica teološke kompetencije.','small')
    elif page_index==1:
        para('Nazivi i vrste preneseni su iz postojećih resursa. Oznaka vrste odnosi se na kanal, ne na svakog gosta, autora ili propovjednika u njegovim objavama. Posebno je potreban oprez kod skupine PA, koja nije provjeren popis laičkih osoba.','small')
        para('Potpuni CSV daje točne zbrojeve dosega, dostupnost metrika, prosjek i medijan interakcija, vremenski raspon, rang unutar platforme i rang za 2025.','small')
    else:
        para('Uz ovu ljestvicu priložena je i odvojena ljestvica 50 oznaka izvora među svih 601.036 zapisa, kao i popisi po platformi i društvenim mrežama. Rang punog skupa uključuje opće medije i ne dokazuje teološku ulogu izvora.','small')
        para('Prilozi za nastavak rada: imenovani CSV s praznim poljima za mandat, teološko obrazovanje i pozivanje na autoritet; paket agregata bez identiteta; HTML inačica izvještaja; reproducibilne R i Python skripte s manifestom podrijetla.','small')
end()
assert PAGE==20
C.save()
all50_rows=[]
for i,r in enumerate(all_top50,1):
    all50_rows.append({'rank':i,'source':r['source'],'SOURCE_TYPE':r['SOURCE_TYPE'],
        'group':r['group'],'group_label':r['group_label'],'source_id':r['source_id'],
        'posts':r['posts'],'posts_with_interactions':r['observed'],
        'interactions':r['interactions'],'median_interactions':r['median'],
        'date_first':r['date_first'],'date_last':r['date_last'],
        'selected_six_groups':'yes' if r['core']=='TRUE' else 'no',
        'actor_identity_verified':'no',
        'note':'Raw source label; review whether this identifies an actor.'})
with (OUT/'top-50-sve-oznake-izvora.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(all50_rows[0]),delimiter=';')
    w.writeheader();w.writerows(all50_rows)
css='body{background:#e8ede9;color:'+INK+';font:17px/1.55 Calibri,Arial,sans-serif;margin:0}section{background:'+PAPER+';max-width:900px;margin:24px auto;padding:44px}h1{font:30px/1.2 Georgia,serif}h2{font-size:20px}table{border-collapse:collapse;width:100%;font-size:14px;margin:16px 0}th{background:'+INK+';color:white;text-align:left}td,th{padding:8px;border-bottom:1px solid '+LINE+'}tr:nth-child(even){background:#eef3ef}.small{font-size:14px;color:'+MUTED+'}img{width:100%;height:auto}a{color:'+GREEN+'}@media print{section{break-after:page;margin:0}}'
(OUT/'izvjestaj.html').write_text('<!doctype html><html lang="hr"><meta charset="utf-8"><title>Katolički akteri: platforme, doseg i vrijeme</title><style>'+css+'</style><body>'+''.join(HTML)+'</body></html>',encoding='utf-8')
(OUT/'build.json').write_text(json.dumps({'pages':PAGE,'layout':LAYOUT,'pdf':str(PDF)},indent=2),encoding='utf-8')
# An identity-free local sharing package. No new publication is performed.
for name in ['actor_groups','concentration','sentiment','sentiment_2025','within_source','themes','metric_audit']:
    (AGG/(name+'.csv')).write_bytes((HERE/'output'/(name+'.csv')).read_bytes())
(AGG/'public_availability.json').write_bytes((HERE/'public_availability.json').read_bytes())
readme='''DigiKat: agregati proširenog istraživačkog izvještaja
Razdoblje: 2021.-2025. Lokalni raniji presjek, nije noviji službeni korpus.
Ovaj paket je izrađen lokalno za dijeljenje; nije objavljen na webu.

Datoteke su UTF-8 CSV s decimalnom točkom. NA označuje nedostupno, ne nulu.
Manifest sadrži identitet ulaza, hash i verzije resursa/paketa.
platform: mjere za scope=all (svi zapisi) i selected (šest skupina).
groups, group_platform: vrste aktera i njihove platforme.
annual, annual_groups, annual_all: godišnje mjere; year_calc je godina datuma.
monthly, monthly_origin: mjesečne mjere i ulazni izvori. Prazni mjeseci nisu
imputirani nulama. Veljača-svibanj 2024. nema zapisa u ulaznom presjeku.
cohort_matched: isti izvori s >=5 objava u oba prozora srpanj-prosinac
2024. i 2025. cohort_all: svi odabrani izvori u istim prozorima.
cohort_source_changes: svakom izvoru jednaka težina; razlike prosjeka.
classification: naslijeđeno pravilo i pokrivenost. group_concentration:
koncentracija interakcija unutar skupina. rank_overlap: preklapanje top 50.
raw_metrics, metric_flags, metric_audit: dostupnost/sastav metrika.
sentiment, sentiment_2025: svi postojeći sentimenti uključujući unknown.
within_source: negativno/neutralno, >=5 objava obiju oznaka kod istog izvora.
themes: rječnički tragovi u prvih 3000 znakova; preklapajuće kategorije.
concentration: odabrani izvori s dostupnim interakcijama, unutar platforme.
actor_groups: osnovna podjela cijelog skupa, s ostalim/nerazvrstanim izvorima.
public_schema, public_availability: odvojeni pregled postojećih javnih resursa.

STUPCI: posts=broj zapisa; sources=broj parova platforma/naziv;
interaction_n=zapisi s interakcijama; interactions=zbroj dostupnih reakcija;
interaction_mean/median=prosjek/medijan dostupnih reakcija po objavi;
reach_n=zapisi s dosegom; reach_total=zbroj dostupnih procjena dosega;
reach_mean/median=prosjek/medijan po objavi; reach_zero_n=zabilježene nule;
views_n/views_total=broj zapisa i zbroj zasebnog polja pregleda;
text_n=zapisi s tekstom; months=broj mjeseci sa zapisima; first/last=datumi.
U osnovnim tablicama observed, mean i median odnose se na interakcije.
Udjeli su 0-1, promjene prosjeka apsolutne. Brojevi izvora nisu aditivni
preko mjeseci/godina. Nazivi autora i sadržaj objava nisu uključeni.

SKUPINE: church_media=crkveni mediji; church_org=crkvene ustanove;
independent=neovisni katolički mediji; clergy=svećenički profili;
community=zajednice/udruge; devotional=pobožni/autorski kanali.
public=ostali/nerazvrstani, nije sinonim za sekularne izvore;
other_christian=međukršćanski granični slučaj iz postojećeg registra.

OGRANIČENJA: REACH nije jedinstvena publika. Platformske metrike nisu
izravno usporedive. Reddit/forum/comment nemaju upotrebljiv doseg i
interakcije. Odabir aktera je indikativan. Godina 2024. je nepotpuna i
obuhvaća promjenu prikupljanja. Nalazi su deskriptivni, bez kauzalnih tvrdnji.
Osnovne stare tablice actor_groups/sentiment/metric_audit koriste osnovnu
shemu; kada nema dostupnih interakcija, njihov zbroj može biti 0 uz
observed=0. U novim tablicama takav zbroj je NA.
'''
(AGG/'PROCITAJ.txt').write_text(readme,encoding='utf-8-sig')
with zipfile.ZipFile(AGG/'agregati-za-dijeljenje.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(AGG.iterdir()):
        if p.suffix in ['.csv','.json','.txt']:z.write(p,p.name)
print(json.dumps({'pdf':str(PDF),'pages':PAGE,'layout':LAYOUT},ensure_ascii=True))
