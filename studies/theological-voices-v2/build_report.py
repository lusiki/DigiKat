"""Build the local Croatian PDF exclusively from saved derived evidence.

Requires all 2,000 main articles to have finished. A built PDF is a review candidate
until the rendered pages have actually been visually inspected.
"""
from __future__ import annotations
import json, math, re
from importlib.metadata import version as package_version
from pathlib import Path
from xml.sax.saxutils import escape
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.ticker import FuncFormatter
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.utils import ImageReader
import fitz
from prepare import OUT, STUDY, CFG, save_json, file_sha
from analyse import ROLE_HR, THEME_HR

NAVY='#172D3D';CREAM='#F7F4ED';TEAL='#23847A';RED='#BB584E';GREY='#63717B';LINE='#D8DDD8'
W,H=595.2756,841.8898;M=46
REPORT=OUT/'report';FIG=REPORT/'figures';PNG=REPORT/'pages'

def n(x):return f'{int(round(x)):,}'.replace(',','.')
def p(x):return 'nije raspoloživo' if x is None or pd.isna(x) else f'{x:.1f}'.replace('.',',')+'\u00a0%'
def fpath(name):return OUT/'tables'/name
def read(name):return pd.read_csv(fpath(name))

def register_fonts():
    for name,file in [('Body','segoeui.ttf'),('Bold','segoeuib.ttf'),('Serif','pala.ttf'),('SerifBold','palab.ttf')]:
        pdfmetrics.registerFont(TTFont(name,str(Path('C:/Windows/Fonts')/file)))
    pdfmetrics.registerFontFamily('Body',normal='Body',bold='Bold',italic='Body',boldItalic='Bold')
    pdfmetrics.registerFontFamily('Serif',normal='Serif',bold='SerifBold',italic='Serif',boldItalic='SerifBold')

def bar(filename,labels,values,xlabel,color=TEAL,limit=None,count_labels=False):
    fig,ax=plt.subplots(figsize=(7.0,4.2));fig.patch.set_facecolor(CREAM);ax.set_facecolor(CREAM)
    vals=np.nan_to_num(np.asarray(values,dtype=float));y=np.arange(len(labels))
    ax.barh(y,vals,color=color,height=.62);ax.set_yticks(y,labels,fontsize=9);ax.invert_yaxis()
    ax.spines[['top','right','left']].set_visible(False);ax.spines['bottom'].set_color(LINE)
    ax.tick_params(axis='y',length=0,pad=9);ax.tick_params(axis='x',colors=GREY,labelsize=9)
    ax.grid(axis='x',alpha=.16);ax.set_axisbelow(True);ax.set_xlabel(xlabel,fontsize=10,color=NAVY,labelpad=10)
    ax.xaxis.set_major_formatter(FuncFormatter(lambda x,pos:n(x) if float(x).is_integer() else f'{x:.1f}'.replace('.',',')))
    xmax=limit or max(max(vals,default=0)*1.22,1);ax.set_xlim(0,xmax)
    for yi,val in zip(y,vals):ax.text(val+xmax*.012,yi,n(val) if count_labels else f'{val:.1f}'.replace('.',','),va='center',fontsize=9,color=NAVY)
    fig.tight_layout(pad=1.2);path=FIG/filename;fig.savefig(path,dpi=190,facecolor=CREAM);plt.close(fig);return path

def monthly(filename,df):
    # The frozen frame export saved its reindexed month as an unnamed CSV index.
    # Interpret that documented index without modifying the frozen input table.
    if 'month' not in df and 'Unnamed: 0' in df:
        df=df.rename(columns={'Unnamed: 0':'month'})
    if 'month' not in df:raise ValueError('Monthly frame table lacks its month index')
    fig,ax=plt.subplots(figsize=(7.0,4.2));fig.patch.set_facecolor(CREAM);ax.set_facecolor(CREAM)
    x=np.arange(len(df));ax.bar(x,df.publications,color=TEAL,width=.8)
    ticks=[i for i,s in enumerate(df.month.astype(str)) if s.endswith('-01')]
    ax.set_xticks(ticks,[str(df.month.iloc[i])[:4] for i in ticks]);ax.set_ylabel('Zabilježene web objave',fontsize=10)
    gap=[i for i,s in enumerate(df.month.astype(str)) if '2024-02'<=s<='2024-05']
    if gap:ax.axvspan(min(gap)-.5,max(gap)+.5,color=RED,alpha=.16,label='Nema tekstova u izvoru')
    change=df.index[df.month=='2024-07'].tolist()
    if change:ax.axvline(change[0]-.5,color=RED,linestyle='--',lw=1.3,label='Promjena prikupljanja')
    ax.spines[['top','right']].set_visible(False);ax.grid(axis='y',alpha=.15);ax.set_axisbelow(True)
    ax.yaxis.set_major_formatter(FuncFormatter(lambda x,pos:n(x)))
    ax.legend(frameon=False,fontsize=8,loc='upper left');fig.tight_layout(pad=1.4)
    path=FIG/filename;fig.savefig(path,dpi=190,facecolor=CREAM);plt.close(fig);return path

class Report:
    def __init__(self,path):
        self.c=canvas.Canvas(str(path),pagesize=(W,H));self.page=0;self.review=[]
        self.c.setTitle('Tko dobiva riječ o vjeri? | DigiKat | Lokalno kodiranje 2.000 članaka')
        self.c.setAuthor('DigiKat - istraživačka izvedba lokalnim modelom')
    def para(self,text,x,y,width,size=11,font='Body',maxheight=None,color=NAVY):
        st=ParagraphStyle('p',fontName=font,fontSize=size,leading=size*1.38,textColor=HexColor(color),spaceAfter=0)
        # Only explicit <b> tags are authored; all external text is escaped by callers.
        a=Paragraph(text,st);_,height=a.wrap(width,1000)
        if maxheight is not None and height>maxheight+.1:
            raise ValueError(f'Page {self.page}: paragraph overflow ({height:.1f}>{maxheight}): {text[:90]}')
        a.drawOn(self.c,x,y-height);self.review.append({'page':self.page,'kind':'paragraph','x':x,'top':y,'width':width,'height':height})
        return y-height
    def new(self,kicker,title,deck=''):
        if self.page:self.c.showPage()
        self.page+=1;c=self.c;c.setFillColor(HexColor(CREAM));c.rect(0,0,W,H,fill=1,stroke=0)
        c.setFillColor(HexColor(TEAL));c.rect(M,H-47,28,3,fill=1,stroke=0)
        self.para(kicker.upper(),M,H-61,W-2*M,8.5,'Bold',25,TEAL)
        self.para(title,M,H-88,W-2*M,29,'SerifBold',100)
        if deck:self.para(deck,M,H-195,W-2*M,11.2,maxheight=79)
        c.setStrokeColor(HexColor(LINE));c.line(M,43,W-M,43)
        c.setFont('Body',8);c.setFillColor(HexColor(GREY));c.drawString(M,28,'DigiKat | Tko dobiva riječ o vjeri? | 2021.-2026.')
        c.drawRightString(W-M,28,str(self.page))
    def chart(self,path):self.c.drawImage(ImageReader(str(path)),M,297,width=W-2*M,height=301,mask='auto',preserveAspectRatio=True,anchor='c')
    def notes(self,left,right,source):
        gap=24;width=(W-2*M-gap)/2
        self.para('ŠTO POKAZUJE',M,273,width,8.5,'Bold',20,TEAL)
        self.para(left,M,252,width,10.4,maxheight=143)
        self.para('GRANICA TUMAČENJA',M+width+gap,273,width,8.5,'Bold',20,RED)
        self.para(right,M+width+gap,252,width,10.4,maxheight=143)
        self.para(source,M,91,W-2*M,7.7,maxheight=37,color=GREY)
    def textblocks(self,blocks,start=590):
        y=start
        for heading,body in blocks:
            self.para(heading,M,y,W-2*M,12,'Bold',30,TEAL);y-=24
            y=self.para(body,M,y,W-2*M,11,maxheight=160)-26
        if y<65:raise ValueError(f'Page {self.page}: text blocks exceed bottom margin')
    def finish(self):self.c.save();save_json(REPORT/'layout_boxes.json',self.review)

def build():
    d=json.loads((OUT/'report_data.json').read_text(encoding='utf-8'))
    if d['preview'] or d['completed_main']!=CFG['sample_size']:raise RuntimeError('A complete main run is required; no preview may masquerade as final report')
    frozen=json.loads((OUT/'coder_freeze.json').read_text(encoding='utf-8'))
    if frozen['config_hash']!=d['config_hash']:raise RuntimeError('Analysis/configuration mismatch')
    policy=d.get('report_policy',{})
    if policy and not policy['model_content_numbers_eligible']:
        from limited_report import build_limited
        return build_limited(d,policy)
    for folder in [REPORT,FIG,PNG]:folder.mkdir(parents=True,exist_ok=True)
    register_fonts();pdf=REPORT/'tko-dobiva-rijec-o-vjeri-v2.pdf';r=Report(pdf)
    frame=d['frame'];N=frame['publications'];B=d['bases']['speakers']['complete_article_valid']
    roles=read('speaker_roles.csv').sort_values('article_prevalence_weighted_pct',ascending=False)
    top=roles.iloc[0];theologian=roles[roles.role=='academic_theologian'].iloc[0]
    source=read('source_concentration.csv');month=read('frame_month.csv');a=read('articles.csv')
    common=f'Izvor: DigiKat, {CFG["period_start"]} - {CFG["period_end"]}. Strojno kodiranje: Qwen3 14B, lokalno. Udio je ponderiran prema uzorkovanju; potpuni slučajevi.'

    r.new('Istraživački izvještaj / drugo izdanje','Tko dobiva riječ<br/>o vjeri?',
          f'{n(N)} dohvaćenih web objava. Glavni uzorak od {n(d["sample"])} publikacija. Pitanje je čiji iskazi ulaze u članke i tko u njima tumači vjeru.')
    r.para(p(top.article_prevalence_weighted_pct),M,565,490,65,'SerifBold',100,TEAL)
    r.para(f'potpunih, valjano obrađenih članaka nosi glas iz najčešće prepoznate uloge: <b>{escape(top.label.lower())}</b>.',M,455,485,17,'Serif',100)
    r.notes('Izvještaj razlikuje imenovanje, pripisani iskaz i tumačenje vjere. Teolog je uloga potkrijepljena tekstom, a ne pretpostavljena kvalifikacija.',
            'Kodiranje je isključivo strojno. Nema ljudske validacije ni izmjerene točnosti. Opažena prisutnost u medijima nije društveni utjecaj.',
            common+f' Nazivnik: {n(B)} članaka s potpunim izvorom i valjanim zadatkom za govornike.')

    r.new('Kako čitati / tri razine dokaza','Objava, glas i iskustvo imaju različite baze',
          'Brojevi iz cijelog okvira, procjene iz uzorka i odabrani primjeri ne predstavljaju istu vrstu dokaza.')
    r.textblocks([('Cijeli dohvaćeni okvir',f'{n(frame["export_records"])} izvoznih redaka pretvoreno je u {n(N)} publikacija. Uklonjeno je {n(frame["duplicates_removed"])} ponovljenih zahvata iste publikacije. Objave istog teksta u različitim medijima ostaju zasebne.'),
      ('Vjerojatnosni uzorak',f'Odabrano je {n(d["sample"])} publikacija, proporcionalno kalendarskim tromjesečjima. Razvojnih 100 članaka, 30 svježih izazovnih članaka, 30 sintetskih primjera i četiri dodatna kontrasta nisu članovi glavnog uzorka.'),
      ('Tekstualni dokaz','Cijeli arhivirani tekst dobio je stabilne oznake odlomaka. Navod identiteta i navod iskaza mogu biti odvojeni. Izvorne odlomke dohvaća program; model ne stvara citate.')])

    r.new('Glavni nalazi / vodič za čitanje','Vidljivost u tekstu nije potvrda autoriteta',
          'Nalazi opisuju prikupljene članke i strojno prepoznate uloge. Ne određuju tko ima pravo govoriti o vjeri.')
    r.textblocks([('Gdje se objavljuje',f'Pet najzastupljenijih izvora nosi {p(d["top5_source_share_pct"])} dohvaćenih web objava. To je koncentracija zabilježene ponude, ne publike.'),
      ('Tko dobiva riječ',f'Najčešća uloga prema prisutnosti u članku jest {escape(top.label.lower())}: {p(top.article_prevalence_weighted_pct)}. Akademski teolozi prepoznati su u {p(theologian.article_prevalence_weighted_pct)} potpunih članaka s valjanim rezultatom.'),
      ('Što ostaje otvoreno','Razlike među vrstama glasova traže sadržajnu provjeru. Neizrečena kvalifikacija ostaje nerazriješena, a modelom neprepoznat glas nije dokaz da taj glas u javnosti ne postoji.')])

    r.new('Vidljivost / vrijeme','Kalendar prikupljanja određuje što možemo usporediti',
          'Mjesečne količine opisuju snimku arhiva. Praznina u 2024. i promjena prikupljanja prekidaju jednostavnu vremensku usporedbu.')
    r.chart(monthly('01-months.png',month))
    r.notes('Stupci pokazuju sve publikacije u okviru, prije uzorkovanja. U 2026. obuhvat završava 11. lipnja.',
            'Od veljače do svibnja 2024. izvor nema tekstove. Promjena prikupljanja u 2024. onemogućuje tumačenje skoka kao rasta medijske pažnje.',
            f'Izvor: tables/frame_month.csv. Jedinica: publikacija. Baza: {n(N)}. Nije udio u ukupnom hrvatskom novinarstvu.')

    r.new('Vidljivost / izvori','Prikupljena ponuda koncentrirana je po izvorima',
          f'Prvih pet izvora čini {p(d["top5_source_share_pct"])} okvira. Na slici je deset izvora s najviše dohvaćenih publikacija.')
    z=source.head(10);r.chart(bar('02-sources.png',z.outlet_name,z.share_pct,'Udio u cijelom dohvaćenom okviru (%)'))
    r.notes('Uzorkovanje prati stvarnu mješavinu publikacija u okviru. Svaki izvor zato nema jednak broj članaka u uzorku.',
            'Pokrivenost dobavljača, izdavačka aktivnost i ponovljeni sadržaj mogu pridonijeti koncentraciji. Količina objava nije doseg.',
            f'Izvor: tables/source_concentration.csv. Baza: {n(N)} publikacija iz {n(frame["sources"])} izvornih oznaka.')

    langs=read('frame_language.csv');locs=read('frame_location.csv')
    r.new('Obuhvat / jezik i prostor','Hrvatski medijski prostor promatramo kroz prikupljenu građu',
          'Zadržane su izvorne jezične i lokacijske oznake. Zbirka uključuje regionalno preklapanje, a ne popis svih hrvatskih medija.')
    z=locs.sort_values('publications',ascending=False).head(7)
    r.chart(bar('03-location.png',z.location.fillna('Bez oznake'),100*z.publications/N,'Udio po izvornoj lokacijskoj oznaci (%)'))
    r.notes('Lokacijske oznake odnose se na zapise dobavljača. Kombinirane oznake ostaju kombinirane i ne pretvaraju se u jednu državu.',
            'Iz imena osobe ne zaključujemo o nacionalnosti. Isti tekst može govoriti o događajima izvan Hrvatske; to nije provjera lokacije svakog opisanog događaja.',
            f'Izvor: tables/frame_location.csv i frame_language.csv. Jedinica: publikacija; baza {n(N)}. Oznake nisu neovisno potvrđene.')

    r.new('Uzorkovanje / raspored','Svako tromjesečje ulazi razmjerno svojoj veličini',
          'Slučajni odabir bez zamjene i spremljene vjerojatnosti uključivanja omogućuju ponavljanje uzorka i provjeru pondera.')
    alloc=read('sample_allocation.csv');r.chart(bar('04-sampling.png',alloc.stratum,alloc.n_h,'Broj odabranih članaka',color=NAVY))
    r.notes('Ponder je broj publikacija u tromjesečju podijeljen brojem uzorkovanih publikacija. Zbroj pondera glavnog uzorka jednak je veličini okvira.',
            'Uzorak od 2.000 članaka nije jamstvo točnosti. Rijetke uloge i mali izvori mogu biti preslabo zastupljeni za zasebne zaključke.',
            'Izvor: tables/sample_allocation.csv i main_manifest.csv. Sjeme: 20261017. Razvoj i izazovni skup odvojeni su od glavnog uzorka.')

    r.new('Kvaliteta izvora / što je čitljivo','Nepotpun tekst nije članak bez govornika',
          'Za sadržajne udjele koristimo potpune izvore i valjane rezultate pojedinog zadatka. Ostali zapisi ostaju vidljivi u evidenciji.')
    status_names={'complete':'Prividno potpun','partial':'Djelomičan','unresolved':'Nerazriješen','unavailable':'Nedostupan','unreadable':'Nečitljiv'}
    status=d['source_content_counts'];r.chart(bar('05-source-quality.png',[status_names.get(k,k) for k in status],list(status.values()),'Broj članaka glavnog uzorka',color=NAVY))
    r.notes(f'Baza za rezultate govornika iznosi {n(B)} članaka. Iz nje su isključene i nerazriješene odluke o pripisivanju iskaza ({n(d.get("unresolved_speaker_articles",0))} članaka). Zapisi nisu zamijenjeni drugim primjerima.',
            'Model procjenjuje potpunost arhiviranog teksta. To nije usporedba sa živom izvornom stranicom. Ponderiranje ne uklanja pristranost zbog nepotpunih izvora.',
            f'Izvor: tables/articles.csv. Baza: svih {n(d["sample"])} odabranih publikacija. Pojedini zadaci imaju zasebne valjane baze.')

    rel=read('relevance.csv');rl={'none':'Bez relevantnosti','incidental':'Usputna referenca','secondary':'Sadržajno sporedna','central':'Središnja tema','unresolved':'Nerazriješeno'}
    r.new('Sadržaj / relevantnost','Ulazak u arhiv ne znači da je vjera glavna tema',
          'Široki okvir namjerno uključuje rubne i pogrešne zahvate. Model razlikuje usputnu referencu od sadržajnog razmatranja.')
    r.chart(bar('06-relevance.png',[rl[k] for k in rel.category],rel.weighted_pct,'Ponderirani udio potpunih valjanih članaka (%)'))
    r.notes('Kategorije opisuju mjesto religijske teme u članku. Naslov se obrađuje zasebno i sam ne određuje središnju temu.',
            'Za segmentirane tekstove središnjost cijelog članka ostaje nerazriješena. Neslaganja dvaju strojnih prolaza spremljena su; nisu mjera pogreške.',
            common+f' Baza: {n(d["bases"]["topics"]["complete_article_valid"])} članaka; tables/relevance.csv.')

    themes=read('themes.csv').sort_values('weighted_pct',ascending=False)
    r.new('Sadržaj / teme','Glavna tema razlikuje nauk od izvještavanja o ustanovi',
          'Teme se dodjeljuju prema sadržaju. Objava o imenovanju biskupa i tekst koji objašnjava uskrsnuće nisu ista vrsta govora o vjeri.')
    r.chart(bar('07-themes.png',[THEME_HR[k] for k in themes.category],themes.weighted_pct,'Ponderirani udio potpunih valjanih članaka (%)'))
    r.notes('Nauk, duhovnost, etika, institucije i javni život tvore odvojene kategorije. Nerazriješeno ostaje zasebna kategorija.',
            'Tematska klasifikacija ne govori je li članak teološki kvalitetan niti jesu li njegove tvrdnje istinite. Segmentirani tekstovi nemaju prisilno izabranu glavnu temu.',
            common+f' Baza: {n(d["bases"]["topics"]["complete_article_valid"])}; tables/themes.csv.')

    r.new('Glasovi / prisutnost u članku','Čiji se iskaz pojavljuje u članku?',
          'Svaki članak s barem jednim govornikom u ulozi broji se jednom za tu ulogu. Jedan članak može sadržavati više različitih uloga.')
    z=roles.head(12);r.chart(bar('08-role-prevalence.png',z.label,z.article_prevalence_weighted_pct,'Ponderirani udio članaka s ulogom (%)'))
    r.notes(f'Najčešće je prepoznata uloga {escape(top.label.lower())}. Graf prikazuje dvanaest najzastupljenijih uloga; potpuna tablica sadrži sve kategorije.',
            'Zbroj postotaka ne mora biti 100 %. Uloga se određuje prema konkretnom iskazu. Crkvena titula ne znači automatski akademsku teologiju.',
            common+f' Baza: {n(B)}. Mjera: prevalencija u članku. tables/speaker_roles.csv.')

    r.new('Glasovi / tri nazivnika','Tri govornika u jednoj ulozi nisu tri članka',
          'Udio pojavljivanja aktera, udio prisutnosti uloga i prevalencija u člancima odgovaraju na različita pitanja.')
    z=roles.head(5)
    r.textblocks([('Pojavljivanja aktera u ulozi','Tri različita biskupa u jednom članku daju tri pojavljivanja. Svaki par akter-uloga unutar članka broji se jednom. To nije broj jedinstvenih osoba u cijelom korpusu.'),
      ('Prisutnost uloge','Ista tri biskupa daju jednu prisutnost uloge biskupa u tome članku. Nazivnik je zbroj svih parova članak-uloga.'),
      ('Prevalencija u člancima',f'Taj članak ulazi jednom u brojnik, a baza uključuje sve potpune valjano obrađene članke, i one bez govornika. Za akademske teologe ove mjere iznose: pojavljivanja {p(theologian.actor_role_share_weighted_pct)}, prisutnosti uloga {p(theologian.role_presence_share_weighted_pct)}, članci {p(theologian.article_prevalence_weighted_pct)}.')])

    interp=read('interpreter_roles.csv').sort_values('article_prevalence_weighted_pct',ascending=False)
    r.new('Tumačenje / sadržaj iskaza','Govoriti o Crkvi nije uvijek tumačiti vjeru',
          'Tumačenje zahtijeva objašnjenje ili primjenu nauka, Pisma, religijskog morala ili duhovnog značenja u pripisanom iskazu.')
    z=interp.head(10);r.chart(bar('09-interpreters.png',z.label,z.article_prevalence_weighted_pct,'Ponderirani udio članaka s tumačem u ulozi (%)'))
    r.notes('Ova uža mjera izostavlja samu najavu mise, izvještaj o imenovanju ili administrativnu informaciju bez tumačenja vjere.',
            'Model utvrđuje funkciju iskaza. Ne potvrđuje teološku ispravnost, formalno poslanje ili stvarnu stručnost osobe. Rijetke uloge ne podnose fine usporedbe.',
            common+f' Baza: {n(d["interpretation_base"]["n"])} članaka s razriješenom oznakom tumačenja za sve glasove. tables/interpreter_roles.csv.')

    r.new('Akademska teologija / oprezna identifikacija','Teologa prepoznajemo kada ga tekst tako uspostavi',
          f'Akademska teološka uloga prepoznata je u {p(theologian.article_prevalence_weighted_pct)} potpunih valjanih članaka; riječ je o {n(theologian.article_role_n)} neponderiranih članaka u uzorku.')
    r.textblocks([('Uvjet za oznaku','Tekst mora navesti teologa, profesoricu teologije ili teološki fakultet i pokazati da osoba govori u toj ulozi. Sam naziv profesor, svećenik ili biskup nije dovoljan.'),
      ('Što mjera ne govori','Ovo nije popis kvalificiranih teologa. Osoba može imati teološko obrazovanje koje članak ne navodi, ili može govoriti u političkoj, pastoralnoj ili osobnoj ulozi.'),
      ('Istraživačka posljedica','Nalaz može usmjeriti naknadno istraživanje načina na koji mediji predstavljaju sugovornike. Ne dokazuje da je neka druga skupina preuzela teološki autoritet.')])

    overlap=read('experience_overlap.csv');labels=[]
    for x in overlap.to_dict('records'):
        labels.append(('Skupina opisana' if x['described'] else 'Bez opisane skupine')+' / '+('vlastito iskustvo' if x['experience_voice'] else 'bez vlastitog iskustva'))
    r.new('Iskustvo / presjek dviju pojava','Opisati posljedicu i dati riječ nisu ista pojava',
          'Opis pogođene skupine i iskaz o vlastitom iskustvu mogu se pojaviti zajedno, odvojeno ili oba izostati.')
    r.chart(bar('10-experience.png',labels,overlap.weighted_pct,'Ponderirani udio zajedničke valjane baze (%)'))
    r.notes('Iskustveni iskaz odnosi se na ono što je govornik sam doživio, radio ili pretrpio. Predviđanje o životu drugih ne ulazi u tu oznaku.',
            'Neovisno se bilježi skupina kojoj tekst pripisuje posljedicu. Modelom neprepoznato iskustvo nije dokaz da ljudi nemaju iskustvo ili mogućnost javnog govora.',
            common+f' Baza: {n(overlap.denominator.iloc[0])} članaka s valjanim zadacima i razriješenim iskustvom. tables/experience_overlap.csv.')

    reuse=d['reuse'];share=100*reuse['publications_in_repeated_families']/reuse['eligible_publications']
    r.new('Kruženje / identičan tekst','Ponovljen tekst ostaje više medijskih objava',
          f'{p(share)} publikacija s najmanje 400 znakova dijeli identičan očišćeni tekst s još jednom publikacijom u okviru.')
    r.chart(bar('11-reuse.png',['U ponovljenim tekstovima','U ponavljanju između izvora'],
      [share,100*reuse['publications_in_cross_outlet_families']/reuse['eligible_publications']],
      'Udio publikacija s najmanje 400 znakova (%)',color=NAVY))
    r.notes('Jednakost se utvrđuje cijelim očišćenim tijelom teksta, ne sličnim naslovom. Sve legitimne objave ostaju u mjeri medijske ponude.',
            'Identičan tekst nije dokaz smjera preuzimanja ni izvornog autora. Blago izmijenjene priče nisu obuhvaćene ovom konzervativnom mjerom.',
            f'Izvor: tables/exact_reuse_families.csv i frame.parquet. Baza: {n(reuse["eligible_publications"])} publikacija. Cijeli okvir, bez modela.')

    cases=json.loads((OUT/'cases.json').read_text(encoding='utf-8'))
    case_titles={'academic_interpretation':'Teološka uloga vidljiva u tekstu','experienced_consequence':'Iskustvo iz prve osobe','mentions_without_voice':'Spomen bez prepoznatog glasa'}
    for case in cases:
        for si,span in enumerate(case['passages']):
            kicker=f'Primjer / namjerni odabir / dokaz {si+1} od {len(case["passages"])}'
            r.new(kicker,case_titles[case['kind']],escape(case['title'][:245]))
            r.para(escape(case['outlet'])+' | '+case['date'],M,590,W-2*M,10,'Bold',30,TEAL)
            r.para(escape(span['id'])+' - '+escape(span['text']),M,557,W-2*M,11,'Serif',260)
            vr=', '.join(dict.fromkeys(ROLE_HR[v['role']] for v in case['voices'])) or 'Nema prepoznatog pripisanog glasa'
            r.notes('Strojni zapis: '+escape(vr)+'. Prikazani odlomak povezuje se s odabranom osobom ili iskazom; ostali dokazi spremljeni su u evidenciji.',
                    'Odabir je namjeran i nije nova procjena učestalosti. Tvrdnje u izvornom tekstu ovdje nisu neovisno provjerene. Odlomak sam ne dokazuje odsutnost glasa iz cijelog članka.',
                    'Izvor: '+case['publication_id']+'; cases.json i tables/evidence_passages.csv. Prikazan je cijeli označeni odlomak.')
            r.c.linkURL(case['url'],(M,564,W-M,590),relative=0,thickness=0)

    r.new('Zaključak / što nalaz dopušta','Vidljivost glasova otvara pitanja o uredničkom izboru',
          'Opažanja su početak istraživanja predstavljanja vjere u medijima. Preporuke nisu dodatni empirijski nalazi.')
    r.textblocks([('Za istraživanje','Provjeriti kako mediji navode stručnost sugovornika i po kojim ih pitanjima uključuju. Razdvojiti akademsku kompetenciju, pastoralnu službu i vidljivost u medijima.'),
      ('Za uredničku praksu','Pri izboru sugovornika izrijekom navesti u kojoj ulozi govori i što potkrepljuje njegov iskaz. Priče o posljedicama mogu se dopuniti iskazima ljudi koji ih opisuju iz vlastitog iskustva.'),
      ('Za sljedeću analizu','Ako je potrebno tvrditi da je netko preuzeo ulogu teologa, treba dodatno istražiti mandate, kompetencije, uređivačke odluke i promjenu kroz usporedivo prikupljena razdoblja. Ovaj izvještaj to ne utvrđuje.')])

    quality=json.loads((OUT/'development_review.json').read_text(encoding='utf-8'))
    r.new('Metoda / lokalni model i provjere','Strojne provjere nisu ljudska validacija',
          'Model je Qwen3 14B, Q4_K_M, izvršen u lokalnom Ollama okruženju. Članci nisu poslani plaćenom API-ju.')
    r.textblocks([('Razvoj i svježi izazov','Razvoj obuhvaća 100 članaka, 30 sintetskih primjera i četiri dodatna kontrasta najave i stvarnog iskaza. Odvojeni skup od 30 članaka prolazi osnovnu i promijenjenu lokalnu konfiguraciju. Ni jedna nije referentna istina.'),
      ('Operativni prag','Uvjet za glavnu obradu jest najmanje 95 % strukturno valjanih rezultata po bitnom zadatku u razvoju i izazovnom skupu. Provjeravaju se oznake odlomaka, potpuna pokrivenost teksta i dijagnostičke situacije.'),
      ('Granice','Nema izmjerene preciznosti, odziva, F1 ni točnosti. Odvojeno se izvode izdvajanje, provjera atribucije i klasifikacija glasova; svi prolazi istog modela mogu dijeliti pogrešku. Ponderi ne ispravljaju takve pogreške ni nedostupne tekstove.')])

    challenge=json.loads((OUT/'challenge_disagreements.json').read_text(encoding='utf-8'))
    comparisons=challenge['comparisons'];qsets=quality['sets']
    task_names={'topics':'teme','mentions':'spomeni','speakers':'govornici','groups':'skupine'}
    def rates(name):
        z=qsets[name]
        return ', '.join(f'{task_names[k]} {p(100*v)}' for k,v in z['task_validity_rates'].items())
    r.new('Dodatak / stvarni ishodi provjera','Valjan izlaz još ne jamči ispravno tumačenje',
          'Udio strukturno valjanih zadataka pokazuje je li postupak izvršen prema pravilima zapisa. Ne pokazuje koliko je klasifikacija točno.')
    long_rates=qsets['development'].get('segmented_task_validity_rates',{})
    long_note=(f' Za {n(qsets["development"]["segmented_articles"])} višesegmentnih članaka najmanja valjanost po zadatku iznosi {p(100*min(long_rates.values()))}.' if long_rates else '')
    r.textblocks([('Razvojni članci',f'Na {n(qsets["development"]["articles"])} razvojnih članaka valjanost iznosi: {rates("development")}.{long_note} To nisu usporedbe s ljudskim referentnim oznakama.'),
      ('Svježi strojni izazov',f'Za {n(qsets["challenge"]["articles"])} odvojenih članaka osnovna konfiguracija daje: {rates("challenge")}. Promijenjena konfiguracija daje: {rates("challenge_challenge")}. Isti članci nisu dodatna neovisna opažanja.'),
      ('Neslaganja ostaju u evidenciji',f'Od {n(len(comparisons))} uspoređenih članaka konfiguracije se razlikuju u relevantnosti za {n(sum(x["relevance_disagreement"] for x in comparisons))}, skupu uloga za {n(sum(x["role_disagreement"] for x in comparisons))}, a potpunosti izvora za {n(sum(x["source_completeness_disagreement"] for x in comparisons))}. Osnovna konfiguracija zadržana je bez proglašavanja njezinih oznaka istinitima.')])
    r.para('Izvor: development_review.json i challenge_disagreements.json. Jedinica: članak u zasebnom razvojnom ili izazovnom skupu. Strojne provjere, bez ljudske validacije.',M,91,W-2*M,7.7,maxheight=37,color=GREY)

    base_rows=d['bases'];r.new('Dodatak / nazivnici po zadatku','Svaki zadatak zadržava vlastitu evidenciju uspjeha',
          f'Svih {n(d["sample"])} izabranih članaka ostaje u evidenciji. Neuspjeli zadatak nije negativan sadržajni nalaz.')
    task_hr={'topics':'Relevantnost i teme','mentions':'Imenovane osobe i organizacije','speakers':'Pripisani govornici','groups':'Opisane pogođene skupine'}
    r.chart(bar('12-task-bases.png',[task_hr[k] for k in base_rows],[v['complete_article_valid'] for v in base_rows.values()],
                'Potpuni izvori s valjanim rezultatom',color=NAVY))
    r.notes('Odvojeno se čuvaju uspješni pozitivni i negativni nalazi, sadržajna neodređenost, djelomičan izvor, pogreška obrade i nedostajući tekst.',
            'Tablica pogrešaka razlaže neuspjeh prema izvoru, vremenu, duljini, segmentiranju i potpunosti izvora. Pristranost neuspjeha ostaje moguća.',
            'Izvor: denominators.json; tables/failure_patterns.csv; tables/task_attempts.csv. Puni sirovi odgovori i svi pokušaji ostaju u coding.sqlite.')

    r.new('Dodatak / ponavljanje postupka','Od izvornog zapisa do brojke postoji trag',
          'Ovo izdanje reproducira se iz spremljenog okvira, uzorka, konfiguracije, odgovora modela i tablica. Ranije izdanje ostaje zasebno.')
    r.textblocks([('Što je spremljeno','assignment.json i CODEBOOK.md određuju zadatak. source_audit.json i freeze.json određuju ulaz. main_manifest.csv navodi izbor, vjerojatnosti i pondere. coding.sqlite čuva zahtjeve, odgovore, pokušaje i tekstualne dokaze.'),
      ('Kako se ponovno gradi','Iz korijena projekta: python studies/theological-voices-v2/analyse.py; zatim python studies/theological-voices-v2/build_report.py. Dovršeni lokalni odgovori koriste se bez novog zaključivanja modela.'),
      ('Što je isporuka','PDF, tablice članaka, spomena, glasova i posljedica; tablice rezultata; registar nazivnika; claim-to-evidence zapisi; slučajevi; izvorni programi i verzije. Lokalni tekstovi članaka ne objavljuju se s izvještajem.')])
    r.finish()
    render_final(pdf)

def render_final(pdf):
    source_dir=REPORT/'build_source';source_dir.mkdir(exist_ok=True)
    source_manifest={}
    for name in ['build_report.py','limited_report.py','analyse.py','verify.py','report_policy.py','reuse_cases.py','input_delivery.py']:
        original=STUDY/name
        (source_dir/name).write_bytes(original.read_bytes())
        source_manifest[name]=file_sha(original)
    save_json(source_dir/'manifest.json',source_manifest)
    doc=fitz.open(pdf);page_records=[]
    for i,page in enumerate(doc):
        image=PNG/f'page-{i+1:02d}.png';page.get_pixmap(matrix=fitz.Matrix(1.35,1.35),alpha=False).save(image)
        text=page.get_text()
        if '\ufffd' in text:raise ValueError(f'Replacement character on page {i+1}')
        if len(text.strip())<80:raise ValueError(f'Unexpectedly empty page {i+1}')
        page_records.append({'page':i+1,'png':str(image),'text_characters':len(text)})
    save_json(REPORT/'render_check.json',{'pdf':str(pdf),'pages':len(doc),'sha256':file_sha(pdf),'rendered_pages':page_records,
      'builder_sha256':file_sha(Path(__file__)),'analysis_sha256':file_sha(STUDY/'analyse.py'),
      'build_source_manifest':source_manifest,
      'packages':{name:package_version(name) for name in ['reportlab','matplotlib','PyMuPDF','pypdf','pandas','numpy']},
      'mechanical_layout_checks':True,'visual_review':'PENDING - rendered images must actually be inspected',
      'numbers_from':'report_data.json and tables; no article counts estimated by model',
      'report_policy':json.loads((OUT/'report_policy.json').read_text(encoding='utf-8')) if (OUT/'report_policy.json').exists() else None})
    print(json.dumps({'pdf':str(pdf),'pages':len(doc),'visual_review':'pending'},ensure_ascii=False))

if __name__=='__main__':build()
