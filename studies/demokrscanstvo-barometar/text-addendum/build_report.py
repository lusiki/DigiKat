"""Create a Croatian, data-driven 18-page PDF and an editable Markdown report."""
from analyze import ROOT,OUT,PRIVATE,LEX,read,write,table,sha
from pathlib import Path
from xml.sax.saxutils import escape
import csv, json, re, shutil
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, Table, TableStyle, Spacer
from svglib.svglib import svg2rlg

HERE=Path(__file__).resolve().parent
PDF=ROOT/'output/pdf/demokrscanstvo-tekstualna-dopuna-izvjestaj.pdf'
FIG=OUT/'figures';FIG.mkdir(exist_ok=True,parents=True)
INK='#173e43';COPPER='#a9643b';PAPER='#fcfbf7';MUTED='#526b6f';PALE='#eef2ef'
def rows(name):
    with (OUT/(name+'.csv')).open(encoding='utf-8',newline='') as f:return list(csv.DictReader(f))
def n(x):return f'{int(float(x)):,}'.replace(',','.')
def f(x,d=1):return f'{float(x):.{d}f}'.replace('.',',')
def mdtable(headers,data):return '\n'.join(['| '+' | '.join(headers)+' |','|'+'|'.join(['---']*len(headers))+'|']+['| '+' | '.join(str(c) for c in r)+' |' for r in data])
S=read(OUT/'summary.json');V={r['term']:r for r in rows('vocabulary_local')}
WIN={r['term']:r for r in rows('window_sensitivity')};P={(r['kind'],r['phrase']):r for r in rows('phrases')}
C={(r['contrast'],r['variant'],r['term']):r for r in rows('contrasts')}
D={(r['term'],r['regime']):r for r in rows('dispersion') if r['platform']=='web'}
R={frozenset((r['a'],r['b'])):r for r in rows('relations')}
CP={(r['term'],r['scope']):r for r in rows('concept_profiles')}
CASES={r['case']:r for r in read(OUT/'argument_cards.json')}
DESIGN=read(OUT/'contrast_design.json');HUMAN=read(OUT/'human_validation_status.json');REV=read(OUT/'content_review_status.json')

plt.rcParams.update({'font.family':'Calibri','font.size':11,'text.color':INK,'axes.labelcolor':INK,'xtick.color':MUTED,'ytick.color':INK,'axes.edgecolor':'#cdd9d4','figure.facecolor':PAPER,'axes.facecolor':PAPER,'svg.fonttype':'none'})
def save(fig,name):
    fig.savefig(FIG/(name+'.svg'),bbox_inches='tight',facecolor=PAPER)
    fig.savefig(FIG/(name+'.png'),dpi=180,bbox_inches='tight',facecolor=PAPER);plt.close(fig)
def clean(ax):
    ax.spines[['top','right','left']].set_visible(False);ax.tick_params(axis='y',length=0);ax.grid(axis='x',alpha=.18);ax.set_axisbelow(True)
def figures():
    terms=['vrijednost','stranka','politički','načelo','domoljublje','narodnjaštvo','obitelj','solidarnost','sloboda','odgovornost','rad','gospodarstvo','savjest','dostojanstvo','supsidijarnost']
    terms=[t for t in terms if t in V];yy=np.arange(len(terms))
    fig,axs=plt.subplots(1,2,figsize=(8.2,4.5),sharey=True,gridspec_kw={'width_ratios':[1.2,1]})
    for ax,key,scale,col,title in [(axs[0],'groups',1,INK,'Broj tekstova'),(axs[1],'mean_tfidf',1000,COPPER,'Prosječni TF-IDF × 1.000')]:
        val=[float(V[t][key])*scale for t in terms];ax.barh(yy,val,color=col,height=.48)
        for y,v in zip(yy,val):ax.text(v+max(val)*.02,y,n(v) if key=='groups' else f(v),va='center',fontsize=9)
        ax.set_xlim(0,max(val)*1.23);ax.set_title(title,loc='left',fontsize=12,pad=12);clean(ax)
    axs[0].set_yticks(yy,terms);axs[0].invert_yaxis();fig.tight_layout(w_pad=3);save(fig,'01-vocabulary')
    table('figure_vocabulary',[V[t] for t in terms])
    for idx,name,years in [(2,'web_2021_2023',('2021.','2023.')),(3,'web_jan_aug_2025_2026',('2025.','2026.'))]:
        base=[r for (co,var,t),r in C.items() if co==name and var=='base' and r['category']=='content' and int(r['combined_df'])>=10]
        chosen=sorted(base,key=lambda r:-float(r['weighted_log_odds']))[:6]+sorted(base,key=lambda r:float(r['weighted_log_odds']))[:6]
        fig,ax=plt.subplots(figsize=(8.2,4.5));vals=[float(r['weighted_log_odds']) for r in chosen]
        ax.barh(range(len(chosen)),vals,color=[INK if x>0 else COPPER for x in vals],height=.55)
        ax.set_yticks(range(len(chosen)),[r['term'] for r in chosen]);ax.invert_yaxis();ax.axvline(0,c=MUTED,lw=.7)
        for i,(r,val) in enumerate(zip(chosen,vals)):
            ax.text(val+(.12 if val>0 else -.12),i,r['a_df']+' / '+r['b_df'],va='center',ha='left' if val>0 else 'right',fontsize=10)
        lim=max(abs(x) for x in vals)*1.48;ax.set_xlim(-lim,lim);ax.set_xlabel('Težinski log-omjer: lijevo '+years[1]+'  |  desno '+years[0])
        clean(ax);fig.tight_layout();save(fig,f'{idx:02}-contrast');table(f'figure_contrast_{idx}',chosen)
    targets=['demokršćanski vrijednost','demokršćanski načelo','europski suradnja','priziv savjest','dostojanstvo radnik','opći dobro']
    chosen=[P[('dictionary' if ('dictionary',p) in P else 'ngram',p)] for p in targets]
    fig,axs=plt.subplots(1,2,figsize=(8.2,3.1),gridspec_kw={'width_ratios':[1.1,1]})
    for ax,rs in zip(axs,[chosen[:2],chosen[2:]]):
        for i,r in enumerate(rs):
            a=int(r['groups']);b=int(r['remaining_word_sequence_groups']);ax.plot([b,a],[i,i],c='#a6bcb5',lw=3);ax.scatter([a],[i],c=INK,s=44);ax.scatter([b],[i],c=COPPER,s=44);ax.text(a+max(int(x['groups']) for x in rs)*.05,i,f'{b} / {a}',va='center',fontsize=10)
        ax.set_yticks(range(len(rs)),[r['surface_example'] for r in rs]);ax.invert_yaxis();ax.set_xlim(0,max(int(x['groups']) for x in rs)*1.4);clean(ax);ax.set_xlabel('Preostalo / početno')
    fig.tight_layout(w_pad=2);save(fig,'04-phrase-controls')
    q=rows('quarterly');terms=['domoljublje','narodnjastvo','obitelj','solidarnost','supsidijarnost','savjest'];qs=sorted({r['quarter'] for r in q if r['platform']=='web'})
    lookup={(r['term'],r['quarter']):r for r in q if r['platform']=='web'}
    arr=np.array([[int(lookup[t,k]['groups']) for k in qs] for t in terms]);den=[int(lookup[terms[0],k]['eligible_groups']) for k in qs]
    fig,ax=plt.subplots(figsize=(9.5,4.4));cm=LinearSegmentedColormap.from_list('forest',[PAPER,'#cadbd3',INK]);ax.imshow(np.log1p(arr),cmap=cm,aspect='auto',vmin=0,vmax=np.log1p(arr.max()))
    for i in range(len(terms)):
        for j in range(len(qs)):ax.text(j,i,str(arr[i,j])+('*' if den[j]<20 else ''),ha='center',va='center',fontsize=9,color='white' if arr[i,j]>35 else INK)
    ax.set_yticks(range(len(terms)),[LEX[t]['label'] for t in terms]);ax.set_xticks(range(len(qs)),[k.replace('-','\n') for k in qs],fontsize=9)
    ax.axvline(qs.index('2024-Q2')-.5,c=COPPER,lw=2);ax.tick_params(length=0);ax.spines[:].set_visible(False)
    ax.set_xlabel('Granica prikupljanja: 1. 4. 2024.  |  2026-Q3 završava 10. 9.',labelpad=12);fig.tight_layout();save(fig,'05-quarterly')
    table('figure_quarter_denominators',[{'quarter':k,'eligible_groups':dd,'small':dd<20} for k,dd in zip(qs,den)])

def card(cid):
    c=CASES[cid]
    return f"## {cid}. {c['title']}\n\n**{c['date']} | {c['source']}**\n\n**Glas i načelo:** {c['speaker']}. {c['principle'].capitalize()}. **Problem:** {c['problem']}.\n\n{c['judgment']} **Odluka AI čitanja:** {c['status']}. {c['limit']}\n"

def content():
    pages=[]
    def add(kicker,body,sources):pages.append((kicker,body.strip(),sources))
    ph=P['ngram','demokršćanski vrijednost'];worker=P['dictionary','dostojanstvo radnik']
    add('Nalazi i putokaz',f'''# Ime tradicije nije dokaz argumenta

Razvijeni argumenti u ovoj zbirci postoje. Njihovu učestalost ne možemo izjednačiti s brojem riječi, fraza ili tematskih oznaka. Nova dopuna povezuje leksičku rasprostranjenost s čitanjem načela, problema i govornog glasa.

## Široka formula i uski odjek

Fraza **demokršćanske vrijednosti** pojavljuje se u **{n(ph['groups'])}** različitih tekstova. Nakon uklanjanja svih tekstova s njezinom najraširenijom jednakom rečenicom ostaje ih **{n(ph['remaining_groups'])}**. Ta se formula ne svodi na jednu kopiranu rečenicu, ali njezina prisutnost još ne potvrđuje objašnjeno načelo.

Nasuprot tome, **dostojanstvo radnika** ima potporu u **{n(worker['groups'])}** tekstova, a nakon iste kontrole u **{n(worker['remaining_groups'])}**. Početni broj prije svega prati prijenos jedne formulacije.

## Konkretna primjena traži vezu

Pregledani iskazi povezuju solidarnost s europskim razvojem, supsidijarnost s razinama vlasti i demokršćanske vrijednosti s odlukom o prizivu savjesti. Srodan kršćanski argument bez jasnoga demokršćanskog referenta ostaje granični slučaj.

## Jedan tekst, više stavova

Poštovanje načela može pratiti odbijanje stranačke pripadnosti. Afirmacija tradicije može pratiti kritiku aktera koji se na nju pozivaju. Zato iz ukupnog jezičnog tona ne izvodimo potporu demokršćanstvu.

**Kako čitati izvještaj:** rječnik i usporedbe na str. 4-6; fraze i odnosi na str. 7-9; argumenti i stav na str. 10-12; vrijeme i kontrole na str. 13-15; metode, kodiranje i izvori na str. 16-18.

**Status:** izvedena računalna i istraživačka jezgra plana. Kartice je pročitao Codex AI. Neovisno ljudsko kodiranje nije provedeno; nema procijenjenih udjela primjene ni mjera pouzdanosti sadržajnih oznaka.''',['phrases.csv','argument_cards.json','human_validation_status.json'])
    add('Korpus i opseg',f'''# Što je doista analizirano

Zadržan je obuhvat prethodnog izdanja: arhiva od 1. 1. 2021. do 10. 9. 2026. Prvi uključeni zapis u ovoj zbirci nosi datum {S['date_min']}. Izvještaj opisuje odabrani arhivski materijal, a ne sav hrvatski javni govor.

{mdtable(['Jedinica ili provjera','Rezultat'],[
['Arhivski zapisi / točne tekstualne skupine',n(S['records'])+' / '+n(S['exact_groups'])],
['Predstavnici A1 / dodatni putovi',n(S['rep_a1'])+' / '+n(S['exact_groups']-S['rep_a1'])],
['Lokalne / proširene rečenične jedinice',n(S['local']['sentences'])+' / '+n(S['expanded']['sentences'])],
['Lokalni / prošireni zadržani tokeni',n(S['local_retained_tokens'])+' / '+n(S['expanded_retained_tokens'])],
['Predstavnici s praznim očišćenim tijelom',n(S['rep_empty_body'])+'; smisleni naslov ostaje'],
['Nepovezani ili nepoznati izvori',n(S['missing_sources'])+' od '+n(S['records'])],
['Rečenice bez odabranih 25 pojmova',n(S['zero_concept_sentences'])+'; ostaju u nazivniku odnosa']])}

**Lokalni opseg** obuhvaća izvorne rečenice koje dodiruju dokazne prozore uključivanja. Jednak normalizirani tekst rečenice broji se jednom unutar predstavnika; naslovi se ne dodaju ponovno kao zaseban tokenizirani dokument. Polja i izvorne granice rečenica ostaju razdvojeni.

**Prošireni opseg** dodaje jednu prethodnu i sljedeću izvornu rečenicu. Dodatno je anotirano {n(read(OUT/'manifest.json')['R_preparation']['new_sentences'])} različitih rečenica. Za argumentacijske kartice pročitani su naslov i cijelo dostupno očišćeno tijelo, uz provjeru referenta.

Broj tekstova nije broj neovisnih priča ni govornika. Datum je arhivski, a pohranjeno tijelo nije jamstvo cjelovitog izvornog članka. Nazivi izvora povezani su po ključu 1:1 iz privatnih kandidata.''',['summary.json','manifest.json'])
    add('M1 / rječnik',f'''# Raširenost i razlikovnost nisu isto

Ovih petnaest lema izabrano je za čitanje političkog identiteta i društvenih načela. Broj tekstova pokazuje rasprostranjenost; prosječni TF-IDF ističe relativno svojstven rječnik. Nema objedinjavanja u bodovni indeks ideološke važnosti.

![01-vocabulary]

**Nazivnik:** {n(S['exact_groups'])} nepraznih lokalnih dokumenata. Prosjek TF-IDF-a uključuje nule svih dokumenata. Na slici je radi čitljivosti pomnožen s 1.000. Cijela tablica s brojem pojavljivanja, učestalošću na 10.000 tokena i potporom po izvorima prati izdanje.

**Lema i pojam nisu ista jedinica.** Lema domoljublje pojavljuje se u {n(V['domoljublje']['groups'])} tekstova, a šira rječnička obitelj, koja obuhvaća i pridjevske oblike, u {n(WIN['domoljublje']['local_groups'])}. Isto vrijedi za Europa i europski te obitelj i obiteljski.

Selekcijsko nazivlje i vlastita imena vode se zasebno: demokršćanski ima {n(V['demokršćanski']['groups'])}, a HDZ kao lema {n(V['hdz']['groups'])} tekstova. Njihova učestalost djelomice proizlazi iz načina odabira zbirke.''',['vocabulary_local.csv','window_sensitivity.csv','figure_vocabulary.csv'])
    for name,idx,title,intro,interpret in [
      ('web_2021_2023',2,'Od izbora do zbornika i javnih polemika','Primarna usporedba ostaje unutar istoga režima prikupljanja: web 2021. prema webu 2023. Prikazano je šest najviše rangiranih lema na svakoj strani, uz najmanje deset potpornih tekstova ukupno.',
       'Lema izbor upućuje na različite izborne kontekste 2021. Zbornik 2023. prati predstavljanje publikacije o demokršćanstvu, a autokratski ponavljanu izjavu iz rujna. Lema rad ima više značenja, uključujući zaposlenje i radove u zborniku. Njezina veća učestalost nije sama po sebi jačanje socijalnog programa.'),
      ('web_jan_aug_2025_2026',3,'Novije razdoblje mijenja rječnik','Dopunska usporedba obuhvaća samo siječanj-kolovoz 2025. i iste pune mjesece 2026. Obje skupine zadovoljavaju uvjet od barem pedeset predstavnika. Prag potpore i način rangiranja isti su kao na prethodnoj stranici.',
       'Sigurnost i obrana 2025. uključuju različite kontekste, među njima europsku i transatlantsku politiku. Godinu kasnije ističu se politički, desni i centar, uz tekstove o pozicioniranju i suradnji stranaka. To je promjena sastava i rječnika odabranih tekstova; iz nje ne izvodimo promjenu uvjerenja građana.')]:
        meta=next(d for d in DESIGN if d['contrast']==name);sample=next(r for (co,var,t),r in C.items() if co==name and var=='base')
        add('M1 / vremenski kontrast',f'''# {title}

{intro}

![{idx:02}-contrast]

**Brojevi uz stupce:** tekstovi s lemom u prvoj / drugoj godini. Nazivnici su **{n(meta['a_groups'])} / {n(meta['b_groups'])}** tekstova i **{n(sample['a_tokens'])} / {n(sample['b_tokens'])}** zadržanih tokena. Riječi koje određuju uključivanje i vlastita imena izostavljeni su iz prikaza.

{interpret}

**Kontrola:** na obje strane prisutno je {n(meta['shared_groups'])} jednakih skupina; račun je ponovljen bez njih. Najveći izvor u usporedbi jest {meta['largest_source']}; njegovo izostavljanje zasebna je provjera. Rezultat služi opisnom rangiranju, bez testa statističke značajnosti.''',['contrasts.csv','contrast_design.json',f'figure_contrast_{idx}.csv'])
    selected=[('demokršćanski vrijednost','Demokršćanske vrijednosti'),('desni centar','Desni centar'),('demokršćanski stranka','Demokršćanska stranka'),('demokršćanski načelo','Demokršćanska načela'),('kršćanski demokracija','Kršćanska demokracija'),('temeljan načelo','Temeljna načela'),('nacionalan interes','Nacionalni interes'),('narodnjački vrijednost','Narodnjačke vrijednosti'),('obiteljski vrijednost','Obiteljske vrijednosti'),('demokršćanski svjetonazor','Demokršćanski svjetonazor'),('demokršćanski europa','Demokršćanska Europa'),('priziv savjest','Priziv savjesti'),('europski suradnja','Europska suradnja'),('opći dobro','Opće dobro'),('dostojanstvo radnik','Dostojanstvo radnika')]
    pr=[(label,P[('dictionary' if ('dictionary',term) in P else 'ngram',term)]) for term,label in selected]
    add('M2 / izvorne fraze',f'''# Formule koje se mogu prepoznati

Izvorni bigrami i trigrami nastaju prije filtriranja funkcijskih riječi. Interpunkcija prekida niz. Ispod je sadržajni izbor petnaest fraza, a ne rang svih gramatičkih nizova. Fleksijski oblici spajaju se po lemi.

{mdtable(['Fraza','Tekstovi','Bez rečenice','Bez niza riječi'],[[label,n(r['groups']),n(r['remaining_groups']),n(r['remaining_word_sequence_groups'])] for label,r in pr])}

**Kako čitati kontrole:** za svaku se frazu uklanjaju svi tekstovi koji sadrže njezinu najrašireniju potpornu rečenicu. Zadnji stupac ponavlja postupak nakon zanemarivanja interpunkcije pri utvrđivanju jednakosti rečenice. To su zasebne kontrole, ne uzastopna oduzimanja.

Broji se najviše jednom po točnom tekstu; nazivnik zbirke jest {n(S['exact_groups'])}. Fraze ostaju u glavnoj tablici ako početno imaju barem deset tekstova. Drugi, kontrolirani broj smije pasti ispod toga praga. Rijetke fraze nalaze se u popratnoj tablici.''',['phrases.csv'])
    add('M2 / ponavljanje',f'''# Jedna formulacija može nositi gotovo sav nalaz

Broj različitih članaka može prikriti zajednički izvor rečenice. Slika uspoređuje početnu potporu s potporom nakon uklanjanja tekstova s najraširenijim jednakim nizom riječi. Lijevi i desni panel imaju različite ljestvice.

![04-phrase-controls]

**Dostojanstvo radnika:** jedna rečenica pojavljuje se u {n(worker['largest_sentence_groups'])} od {n(worker['groups'])} tekstova ({f(worker['largest_sentence_percent'])}%). To je snažan odjek, uz malu preostalu potporu. Sve te lokalne pojave nalaze se izvan predstavnika odabranih pravilom A1.

**Priziv savjesti:** od {n(P['dictionary','priziv savjest']['groups'])} tekstova ostaje {n(P['dictionary','priziv savjest']['remaining_groups'])} nakon kontrole rečenice, ali samo {n(P['dictionary','priziv savjest']['remaining_word_sequence_groups'])} kada jednakost zanemari interpunkciju. Različiti navodnici i interpunkcija nisu različiti argumenti.

**Europska suradnja:** kontrola niza riječi ostavlja {n(P['dictionary','europski suradnja']['remaining_word_sequence_groups'])} od {n(P['dictionary','europski suradnja']['groups'])} tekstova. Fraza može biti vidljiva kroz velik broj objava, a ostati vezana uz jednu izjavu.

**Granica kontrole:** preostali tekstovi još mogu sadržavati parafraze istoga iskaza. Obrnuto, rijetka točna fraza ne dokazuje da srodne ideje nedostaju drugim riječima.''',['phrases.csv','concept_profiles.csv'])
    pairlist=[('domoljublje','narodnjastvo'),('domoljublje','drzavotvornost'),('demokrscanstvo','konzervativizam'),('obitelj','vrijednosti'),('europa','solidarnost'),('hdz','savjest')]
    labels=['Domoljublje / narodnjaštvo','Domoljublje / državotvornost','Demokršćanstvo / konzervativizam','Obitelj / vrijednosti','Europa / solidarnost','HDZ / savjest']
    rr=[R[frozenset(p)] for p in pairlist]
    add('M2 / odnosi i njihova funkcija',f'''# Bliske riječi mogu se slagati ili osporavati

NPMI i phi računani su na istih {n(S['local']['sentences'])} rečeničnih jedinica. Uključene su i rečenice bez pojma. Mjere opisuju supojavljivanje, a njihova se veličina ne tumači kao ideološka važnost.

{mdtable(['Odnos','Tekstovi','NPMI','Phi','Preostalo*'],[[label,n(r['groups']),f(r['npmi'],2),f(r['phi'],2),n(r['remaining_word_sequence_groups'])] for label,r in zip(labels,rr)])}

*Nakon uklanjanja tekstova s najraširenijim jednakim nizom riječi potporne rečenice.

**Domoljublje i narodnjaštvo:** popisi identiteta, ali i kritika uporabe tih oznaka kao političkoga pokrića. **Domoljublje i državotvornost:** stranačka baština i samopis; susreće se i autorsko osporavanje formule.

**Demokršćanstvo i konzervativizam:** uz zajedničko svrstavanje pojavljuje se njihovo izričito razlikovanje. **Obitelj i vrijednosti:** opći iskazi odgovornosti, konkretni zahtjevi i kritika dosljednosti; u jednom primjeru drugi je referent američki političar.

**Europa i solidarnost:** među primjerima su razvojni argument, popis vrijednosti i naziv Caritas Europa. **HDZ i savjest:** dvije različite uporabe, priziv savjesti liječnika i poziv biračima da glasaju po savjesti.

Codex AI pročitao je {n(REV['relation_sentence_cases'])} odabranih rečeničnih slučajeva iz {n(REV['distinct_relation_texts'])} tekstova, uz njihove postojeće dokazne kontekste. Za pet odnosa pročitano je po deset različitih tekstova; za HDZ/savjest pet, koliko je ostalo različitih nizova u postupku odabira. To nije reprezentativno kodiranje funkcija.''',['relations.csv','relation_review_scope.csv','content_review_status.json'])
    add('M3 / anatomija argumenta','# Tri jasne veze u pročitanim tekstovima\n\nKartice su rezultat čitanja cijeloga dostupnog teksta. Opisuju argument kako ga akter iznosi; ne potvrđuju njegovu činjeničnu ili normativnu ispravnost.\n\n'+card('K01')+'\n'+card('K02')+'\n'+card('K03'),['argument_cards.json'])
    add('M3 / granice potvrde','# Širi tekst pomaže, ali ne popunjava praznine\n\n'+card('K04')+'\n'+card('K06')+'\n'+card('K07')+'\n**Još jedan kontrolni slučaj (K09):** rasprava o općem dobru i zapošljavanju preko stranačkih veza poziva se na socijalni nauk. Veza s demokršćanskim referentom u dostupnom tekstu nije utvrđena. Sadržajna bliskost nije dovoljan uvjet M3.', ['argument_cards.json'])
    add('M4 / glas i cilj procjene',f'''# Kritika aktera može čuvati načela

{card('K05')}

{card('K08')}

{mdtable(['Isti slučaj','Cilj 1','Cilj 2'],[
['K05','Načela: poštovanje','Vlastita pripadnost / ulazak u HDZ: odbijanje'],
['K08','Tradicija: afirmacija socijalnog sadržaja','Samoproglašeni akteri: kritika razumijevanja'],
['K02','Demokršćanske vrijednosti: vlastito uporište','Zabrana priziva savjesti: odbijanje']])}

Čitanje podupire mogućnost različitih stavova unutar istog teksta. Ne znamo koliko je takvih slučajeva u cijeloj zbirci. Leksički sentiment nije izveden: bez neovisno kodiranog pilota nije pokazano da bi globalni ton dodao korisnu informaciju povrh razlikovanja cilja i govornika.''',['argument_cards.json','summary.json'])
    add('M5 / vrijeme',f'''# Trajnost riječi nije trajnost istoga argumenta

Matrica prati leksički sadržaj na webu. Broj u ćeliji označuje različite točne tekstove s pojavom pojma; boja koristi logaritamski prikaz broja radi vidljivosti manjih ćelija. Skupina se prati po svim svojim zapisima, ne samo po datumu predstavnika.

![05-quarterly]

Domoljublje se javlja u **{D['domoljublje','before']['quarters_present']} od {D['domoljublje','before']['quarters_available']}** tromjesečja prije promjene prikupljanja i u **{D['domoljublje','after']['quarters_present']} od {D['domoljublje','after']['quarters_available']}** nakon nje. Solidarnost je prisutna u **{D['solidarnost','before']['quarters_present']}/{D['solidarnost','before']['quarters_available']}** odnosno **{D['solidarnost','after']['quarters_present']}/{D['solidarnost','after']['quarters_available']}** tromjesečja. To su rasponi leksičke pojave, a ne vremenske serije potvrđenih načela.

**Granica režima:** bakrena crta označuje 1. 4. 2024. Zadnje je tromjesečje nepotpuno. Zvjezdica označuje nazivnik manji od dvadeset tekstova: u 2024-Q1 uključeno je samo {next(r['eligible_groups'] for r in rows('figure_quarter_denominators') if r['quarter']=='2024-Q1')} web-tekstova. Nula je opažena odsutnost rječničkoga pogotka među uključenim tekstovima, a ne dokaz odsutnosti ideje u javnosti.

Brojevi tekstova kroz tromjesečja nisu aditivni. Broj svih uključenih web-tekstova po ćeliji nalazi se u agregatu figure_quarter_denominators; raspršenost manjih platformi dostupna je odvojeno.''',['quarterly.csv','dispersion.csv','figure_quarter_denominators.csv'])
    dispterms=['domoljublje','obitelj','solidarnost','supsidijarnost','opce_dobro','savjest']
    dd=[]
    for t in dispterms:
        for reg,label in [('before','prije'),('after','od 4/2024')]:
            r=D[t,reg];dd.append([LEX[t]['label']+' / '+label,n(r['groups']),n(r['named_sources']),n(r['remaining_word_groups']),n(r['remaining_peak_month_groups'])])
    add('M5 / koncentracija',f'''# Izvori su brojni; vršni mjeseci ipak znače mnogo

{mdtable(['Pojam / režim','Tekstovi','Izvori','Bez niza','Bez vrha'],dd)}

Tablica je za web. Izvori su imenovani izdavači ili izvori zapisa, ne neovisni govornici. Kontrole odvojeno uklanjaju sve tekstove s vodećom rečenicom bez interpunkcije ili s prisutnošću u najbrojnijem potpornom mjesecu. Nazivnici režima: {n(D['solidarnost','before']['eligible_groups'])} / {n(D['solidarnost','after']['eligible_groups'])} tekstova.

Za solidarnost prije travnja 2024. početna potpora iznosi {n(D['solidarnost','before']['groups'])}, a bez vršnog mjeseca {D['solidarnost','before']['peak_month']} ostaje {n(D['solidarnost','before']['remaining_peak_month_groups'])}. Nakon granice od {n(D['solidarnost','after']['groups'])} tekstova bez vrha {D['solidarnost','after']['peak_month']} ostaje {n(D['solidarnost','after']['remaining_peak_month_groups'])}.

Pojmovi se pojavljuju u više razdoblja i izvora, ali potpora nije ravnomjerna. Za opće dobro i supsidijarnost nakon granice brojevi su mali; ne pretvaramo ih u rang platformi ili tvrdnju o rastu i padu ideološke važnosti.''',['dispersion.csv'])
    controls=[]
    for name,t in [('web_2021_2023','izbor'),('web_2021_2023','zbornik'),('web_2021_2023','rad'),('web_jan_aug_2025_2026','sigurnost'),('web_jan_aug_2025_2026','rad')]:
        rs=[C[name,var,t] for var in ['base','no_largest_source','no_longest_supporting_text','no_largest_supporting_sentence']]
        controls.append([t+(' 21/23' if name=='web_2021_2023' else ' 25/26')]+[f(x['weighted_log_odds'],2) for x in rs])
    add('Kontrole i interpretacija',f'''# Koji zaključci opstaju, a koji se sužavaju?

{mdtable(['Lema / godine','Osnova','Bez izvora','Bez dugog','Bez rečenice'],controls)}

Prikazan je težinski log-omjer. Pozitivno znači prvu, negativno drugu godinu. Svaka kontrola počinje od osnovnog korpusa. Za rad 2025./2026. mala početna razlika mijenja predznak bez najvećeg izvora; ne tumačimo je kao pouzdan smjer. Zbornik nakon uklanjanja vodeće rečenice pada na {C['web_2021_2023','no_largest_supporting_sentence','zbornik']['combined_df']} tekstova, ispod glavnoga praga potpore.

**A1 prema svim putovima:** solidarnost ima {CP['solidarnost','a1_representative']['groups']} / {n(S['rep_a1'])} predstavnika A1, prema {CP['solidarnost','all']['groups']} / {n(S['exact_groups'])} ukupno. Dostojanstvo rada ima {CP['dostojanstvo_rada','a1_representative']['groups']} u A1 i {CP['dostojanstvo_rada','all']['groups']} ukupno. Sadržaj dopunskih putova ne smije se predstavljati kao rezultat samo izričitoga naziva.

**Širi prozor:** solidarnost raste s {WIN['solidarnost']['local_groups']} na {WIN['solidarnost']['expanded_groups']}, savjest s {WIN['savjest']['local_groups']} na {WIN['savjest']['expanded_groups']}, a sloboda sa {WIN['sloboda']['local_groups']} na {WIN['sloboda']['expanded_groups']} tekstova. To je osjetljivost rječničkoga dosega, ne broj novih potvrđenih argumenata.

**P1, ponavljanje:** dio rječnika ostaje širok i nakon uklanjanja jedne formulacije; neke fraze gotovo nestaju. **P2, primjena izvan programske teme:** kartica K02 pripada postojećoj temi HDZ i demokršćanski identitet ({CASES['K02']['topic']}), a K03 temi Politička pripadnost i ideje ({CASES['K03']['topic']}). Tematski naziv ne isključuje primjenu, ali bez ljudskog uzorka nema usporedbe udjela. **P3, različiti ciljevi:** kontrasti postoje u pročitanim slučajevima; njihova rasprostranjenost ostaje otvorena.

Tablice dodatno sadrže pragove 5/10/20 tekstova, površinske oblike, preklapanje godina i postojeće približne skupine na pragovima 0,85/0,90/0,95. Te kontrole nisu validacija priča ni parafraza.''',['contrasts.csv','concept_profiles.csv','window_sensitivity.csv','contrast_ranks.csv','near_copy_content_sensitivity.csv','argument_cards.json'])
    add('Metode i ponovljivost',f'''# Jedinice i nazivnici ostaju vidljivi

**Priprema.** Fiksni predstavnici preuzeti su iz prethodne analize. Izvori su spojeni po ključu 1:1. UDPipe je korišten kroz projektni R za dopunske rečenice; izračuni i izvještaj izvedeni su u Pythonu. Izvorno izdanje, arhiva i mrežne stranice projekta nisu mijenjani.

**Tokeni.** Čuvaju se izvorni oblik, lema, vrsta riječi, polje i položaj. Leksički račun uključuje imenice, vlastita imena, pridjeve, glagole i priloge; zadržane su negacije te bez, protiv i ali. Izostavljene su leme biti, htjeti, moći, imati, kazati i reći. Fraze se izvode iz neskraćenoga slijeda. Nazivi i selekcijske riječi odvojeni su pri prikazu, a ostaju u zajedničkom token nazivniku.

**TF-IDF.** tf = broj pojavljivanja leme / svi zadržani tokeni dokumenta. idf = ln(N / broj dokumenata s lemom). Njihov se umnožak prosječuje preko svih {n(S['exact_groups'])} skupina, uključujući nule. N je broj nepraznih dokumenata; u ovoj izvedbi svi imaju zadržane tokene. Ovo nije TF-IDF prijašnjega NMF modela. [1]

**Dvije skupine.** Za lemu s brojanjima cA i cB prior je a = cA + cB; ukupni prior A jednak je zbroju svih tokena obiju skupina. Razlika log-izgleda jest ln[(cA+a)/(nA+A-cA-a)] - ln[(cB+a)/(nB+A-cB-a)]. Dijeli se korijenom iz 1/(cA+a) + 1/(cB+a). To je izravni regularizirani kontrast dviju skupina, implementiran eksplicitno; nije poziv funkcije tidylo ni njezin skup-prema-zbirci rezultat. [3]

**Odnosi.** Binarna matrica rečenica uključuje redove bez pojmova. NPMI = ln[pAB/(pA pB)] / -ln(pAB). Phi je koeficijent tablice 2 × 2: oba / samo prvi / samo drugi / nijedan. Nedefinirane vrijednosti ostaju prazne. U tablicu glavnih odnosa ulazi potpora od barem deset tekstova. [2]

**Jezična provjera.** Pregled je pokazao pogrešnu lemu demokršćati za dio oblika demokršćani. Nije interpretirana kao zasebna sadržajna riječ; obiteljsko pravilo demokršć- zadržava te pojave. Stroge fraze mogu propustiti inačice poput socijalno s drukčijom lemom ili interpunkcijom. Površinski kontrolni račun i tablica morfoloških oblika čuvaju trag te osjetljivosti.

**Provjera raspona.** Lokalno je provjereno {n(S['local']['positions_checked'])}, a prošireno {n(S['expanded']['positions_checked'])} položaja tokena. Ne pripisujemo neovisnost rečenicama istog članka. Nema intervala za promjenu javnog mnijenja, uzročnih zaključaka ni procjene autentičnosti aktera.''',['summary.json','lexicon.json','manifest.json','morphology_audit.csv'])
    sample=rows('sampling_design')
    add('M3-M4 / kodiranje i uzorak',f'''# Priprema je završena; ljudske odluke nisu

Kodna knjiga traži demokršćanski referent, načelo, određen problem i izričitu argumentacijsku vezu. Imenovanje, objašnjenje i primjena odvojene su oznake. Za svaki iskaz zasebno se vode govornik, cilj, stav i dokazni raspon; neprocjenjivo nije nula.

Pripremljen je razvojni pilot od {HUMAN['pilot_prepared']} tekstova te stratificirani uzorak od **{HUMAN['sample']}** točnih skupina iz cijelog okvira. Stratum određuju pravilo, platforma i režim fiksnog predstavnika. Osnovna dodjela min(10, N_h), zatim proporcionalno preostalom kapacitetu, uz najveće ostatke i seed {HUMAN['seed']}.

{mdtable(['Pravilo / platforma / režim','N_h','n_h','Ponder'],[[r['stratum'].replace('other','ostalo').replace('before','prije').replace('after','poslije').replace('|',' / '),r['N_h'],r['n_h'],f(r['weight'],2)] for r in sample])}

Zbroj pondera jest **{n(HUMAN['weight_sum'])}**. Prazan stratum izostavljen je iz tablice. Za svakog čitatelja postoji odvojena datoteka bez AI odluka, s naslovom, tijelom i lokalnim opsegom. Pripadnost skupine većem broju režima ili platformi sačuvana je u privatnom dizajnu.

Dva čitatelja trebaju dovršiti **{HUMAN['independent_human_codings_required']} neovisnih kodiranja**, uz pilot i usuglašavanje. Dovršeno ljudskih kodiranja: **{HUMAN['independent_human_codings_completed']}**. Kodna knjiga stoga ostaje nacrt za pilot.

Plan za glavni kvantitativni nalaz traži alpha najmanje 0,80 i najmanje dvadeset pozitivnih slučajeva po kodu. Nakon ispunjenja tih uvjeta slijede ponderirane procjene, stratifikacija i korekcija konačnog okvira. U ovoj dopuni nema populacijske matrice načelo × problem, sadržajnih udjela ni izmišljenih metrika slaganja.''',['sampling_design.csv','human_validation_status.json','codebook.md'])
    add('Izvori i isporuka',f'''# Izvještaj ima provjerljiv trag

**[1] Silge, J. i Robinson, D. Text Mining with R, poglavlje 3.** Definicija relativne frekvencije i TF-IDF-a. [Učestalost i TF-IDF](https://www.tidytextmining.com/tfidf).

**[2] Isti autori, poglavlje 4.** Izvorni n-grami i odnosi riječi. [N-grami i povezanost](https://www.tidytextmining.com/ngrams).

**[3] Monroe, B. L., Colaresi, M. P. i Quinn, K. M. (2008).** Fightin' Words, Political Analysis 16, 372-403, DOI 10.1093/pan/mpn018. Regularizirani log-izgledi; provedba specificirana na str. 16. [Dokumentacija tidylo i bibliografski izvor](https://juliasilge.github.io/tidylo/reference/bind_log_odds.html).

**Projektni izvori:** odobreni plan demokrscanstvo-plan-tekstualne-dopune.pdf, izdanje 1.0, 18 str.; prethodni analitički izvještaj 1.0, 20 str.; zamrznuti agregati i privatni tekstualni međurezultati. Kriptografski sažeci ulaza nalaze se u manifestu. Datumi i nazivi izdavača na karticama potječu iz privatne arhive, ne iz nove mrežne pretrage.

## Što prati ovaj PDF

Agregatni paket sadrži rječnik, lokalne i proširene frekvencije, TF-IDF, vremenske kontraste i njihove kontrole, fraze, NPMI i phi, tromjesečja, koncentraciju izvora i formulacija, uzorkovni dizajn, nacrt kodne knjige, slike u PNG/SVG formatu, uređivi tekst izvještaja, registar tvrdnji i provjere.

Privatno ostaju izvorni tekstovi, identifikatori, pojedinačni TF-IDF, rečenični i frazni rasponi, trag kartica, razvojni pilot i dva prazna koderska paketa. Za reprodukciju tekstualnih koraka potreban je pristup toj radnoj mapi. Agregati su dovoljni za ponovno crtanje i slaganje PDF-a nakon pripreme sadržajnih kartica.

## Granice ovoga izdanja

M1 i M2 izvedeni su računalno uz pregled konteksta; M5 prati leksički sadržaj. M3 i M4 donose namjerno odabrane kartice koje je pročitao Codex AI i pripremu ljudskog uzorka. Ljudska pouzdanost, prevalencija i automatizirano širenje sadržajnih kodova nisu potvrđeni. Dodatni sentiment i LDA nisu izvođeni jer njihovi uvjeti nisu uspostavljeni.

Iz podataka ne zaključujemo koliko građana podupire demokršćanstvo, jesu li akteri dosljedni u praksi ni koliko su njihove ideje politički utjecajne. Najjača tvrdnja ostaje pojava određenog rječnika i provjerljivih argumenata u ovoj odabranoj zbirci.

**Izdanje 1.0 | 19. rujna 2026. | DigiKat**\nAnaliza, pisanje i grafička priprema uz pomoć Codex AI-ja.''',['manifest.json','README.md','human_validation_status.json'])
    assert len(pages)==17,len(pages)
    return pages

W,H=A4;M=45;CW=W-2*M
for name,file in [('Body','calibri.ttf'),('BodyBold','calibrib.ttf'),('BodyItalic','calibrii.ttf'),('Display','georgia.ttf')]:pdfmetrics.registerFont(TTFont(name,'C:/Windows/Fonts/'+file))
pdfmetrics.registerFontFamily('Body',normal='Body',bold='BodyBold',italic='BodyItalic',boldItalic='BodyBold')
ST={'body':ParagraphStyle('body',fontName='Body',fontSize=12,leading=16.2,textColor=colors.HexColor(INK),spaceAfter=10),
    'h1':ParagraphStyle('h1',fontName='Display',fontSize=23,leading=28,textColor=colors.HexColor(INK),spaceAfter=14),
    'h2':ParagraphStyle('h2',fontName='BodyBold',fontSize=12.5,leading=16,textColor=colors.HexColor(INK),spaceBefore=7,spaceAfter=6),
    'cell':ParagraphStyle('cell',fontName='Body',fontSize=10.5,leading=13.2,textColor=colors.HexColor(INK)),
    'head':ParagraphStyle('head',fontName='BodyBold',fontSize=9.8,leading=12.2,textColor=colors.white)}
def para(s,style='body'):
    s=re.sub('[\u2010-\u2014]','-',s);s=escape(s);s=re.sub(r'\*\*(.+?)\*\*',r'<b>\1</b>',s)
    s=re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',r'<link href="\2" color="#a9643b"><u>\1</u></link>',s)
    return Paragraph(s,ST[style])
WIDTHS={3:[.58,.42],7:[.46,.16,.19,.19],9:[.44,.14,.14,.12,.16],12:[.16,.39,.45],14:[.42,.14,.13,.15,.16],15:[.32,.17,.17,.17,.17],17:[.58,.13,.13,.16]}
def mtable(block,pg):
    data=[]
    for line in block:
        cells=[x.strip() for x in line.strip().strip('|').split('|')]
        if all(re.fullmatch(r'[:\- ]+',s) for s in cells):continue
        data.append([para(c,'head' if not data else 'cell') for c in cells])
    widths=WIDTHS.get(pg,[1/len(data[0])]*len(data[0]));assert len(widths)==len(data[0]),(pg,len(data[0]))
    t=Table(data,colWidths=[CW*x for x in widths],hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor(INK)),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7),('TOPPADDING',(0,0),(-1,-1),6),('BOTTOMPADDING',(0,0),(-1,-1),6),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.HexColor(PALE),colors.HexColor(PAPER)]),('LINEBELOW',(0,-1),(-1,-1),.5,colors.HexColor('#cdd9d4'))]))
    return t
def parse(raw,pg):
    lines=raw.strip().splitlines();items=[];i=0
    while i<len(lines):
        ln=lines[i].strip()
        if not ln:i+=1;continue
        if ln.startswith('!['):
            d=svg2rlg(str(FIG/(ln[2:-1]+'.svg')));scale=CW/d.width;d.scale(scale,scale);d.width=CW;d.height*=scale;items.extend([d,Spacer(1,12)]);i+=1;continue
        if ln.startswith('|'):
            block=[]
            while i<len(lines) and lines[i].strip().startswith('|'):block.append(lines[i]);i+=1
            items.extend([mtable(block,pg),Spacer(1,10)]);continue
        if ln.startswith('# '):items.append(para(ln[2:],'h1'));i+=1;continue
        if ln.startswith('## '):items.append(para(ln[3:],'h2'));i+=1;continue
        block=[ln];i+=1
        while i<len(lines) and lines[i].strip() and not lines[i].startswith(('#','|','![')):block.append(lines[i].strip());i+=1
        items.append(para(' '.join(block)))
    return items
def cover(c):
    c.setFillColor(colors.HexColor(PAPER));c.rect(0,0,W,H,fill=1,stroke=0)
    c.setFillColor(colors.HexColor(INK));c.rect(0,263,W,H-263,fill=1,stroke=0)
    c.setFillColor(colors.HexColor('#e2b58a'));c.setFont('BodyBold',10);c.drawString(M,H-62,'DIGIKAT   /   TEKSTUALNA DOPUNA')
    c.setFillColor(colors.white);c.setFont('Display',35);c.drawString(M,H-151,'Demokršćanstvo:');c.drawString(M,H-199,'od riječi do argumenta')
    c.setFont('Body',17);c.setFillColor(colors.HexColor('#e1ebe5'));c.drawString(M,H-245,'Analitički izvještaj o tekstualnom sadržaju')
    c.setStrokeColor(colors.HexColor('#e2b58a'));c.setLineWidth(1.5);c.line(M,H-278,M+80,H-278)
    c.setFont('Body',12);c.setFillColor(colors.white);c.drawString(M,H-313,'Rječnik, fraze, argumenti i trajnost sadržaja');c.drawString(M,H-335,'Zamrznuta zbirka 2021.-2026.  |  Izdanje 1.0')
    for x,val,label in [(M,n(S['exact_groups']),'točnih tekstova'),(M+178,n(S['local']['sentences']),'lokalnih rečenica'),(M+350,str(REV['full_available_bodies_read']),'kartica čitanja')]:
        c.setFont('Display',27);c.setFillColor(colors.HexColor('#e2b58a'));c.drawString(x,340,val);c.setFont('Body',10);c.setFillColor(colors.white);c.drawString(x,318,label)
    for y,txt,sty in [(229,'Razvijeni argumenti postoje. Njihova učestalost ostaje otvoreno pitanje.','h1'),(123,'Izvedena računalna i istraživačka jezgra odobrenog plana. Sadržajne kartice: Codex AI; neovisno ljudsko kodiranje nije provedeno.','body')]:
        p=para(txt,sty);_,hh=p.wrap(CW,200);p.drawOn(c,M,y-hh)
    c.setFont('Body',8.5);c.setFillColor(colors.HexColor(MUTED));c.drawString(M,29,'19. RUJNA 2026.  /  SAMOSTALNA DOPUNA ANALITIČKOM IZVJEŠTAJU 1.0')
def frame(c,pg,kicker):
    c.setFillColor(colors.HexColor(PAPER));c.rect(0,0,W,H,fill=1,stroke=0);c.setFillColor(colors.HexColor(COPPER));c.setFont('BodyBold',9.2);c.drawString(M,H-36,f'{pg:02d}  /  '+kicker.upper())
    c.setStrokeColor(colors.HexColor('#cdd9d4'));c.line(M,44,W-M,44);c.setFillColor(colors.HexColor(MUTED));c.setFont('Body',8.2);c.drawString(M,29,'DIGIKAT  /  TEKSTUALNA DOPUNA 1.0  /  19. 9. 2026.');c.drawRightString(W-M,29,f'{pg} / 18')
def main():
    figures();pages=content();objects=[(i,k,parse(body,i),body,sources) for i,(k,body,sources) in enumerate(pages,2)]
    layout=[]
    for pg,k,items,_,_ in objects:
        hh=sum(o.getSpaceBefore()+o.wrap(CW,10000)[1]+o.getSpaceAfter() for o in items);layout.append({'page':pg,'height':hh,'bottom':H-61-hh})
    write(OUT/'layout_qa.json',layout)
    over=[r for r in layout if r['bottom']<58]
    if over:raise ValueError('Overflow: '+json.dumps(over))
    c=canvas.Canvas(str(PDF),pagesize=A4,pageCompression=1);c.setTitle('Demokršćanstvo: od riječi do argumenta - tekstualna dopuna');c.setAuthor('DigiKat; analiza i priprema uz pomoć Codex AI-ja');c.setSubject('Izvedena računalna analiza uz ograničeno AI čitanje; ljudska validacija nije provedena');c.setViewerPreference('DisplayDocTitle','true')
    c.bookmarkPage('p1');c.addOutlineEntry('Naslovnica','p1',0);cover(c);c.showPage()
    for pg,k,items,_,_ in objects:
        c.bookmarkPage('p'+str(pg));c.addOutlineEntry(k,'p'+str(pg),0);frame(c,pg,k);y=H-61
        for obj in items:y-=obj.getSpaceBefore();_,hh=obj.wrap(CW,10000);y-=hh;obj.drawOn(c,M,y);y-=obj.getSpaceAfter()
        c.showPage()
    c.save()
    (OUT/'report.md').write_text('# Demokršćanstvo: od riječi do argumenta\n\nAnalitička tekstualna dopuna | 19. rujna 2026.\n\n'+'\n\n'.join(f'<!-- PAGE {pg}: {k} -->\n\n{body}' for pg,k,_,body,_ in objects),encoding='utf-8')
    write(OUT/'claim_register.json',[{'page':pg,'section':k,'text':body,'aggregate_sources':sources,'semantic_status':'AI reading only; no human prevalence','unit':'exact text groups unless sentence counts explicitly stated'} for pg,k,_,body,sources in objects])
    shutil.copy2(HERE/'codebook.md',OUT/'codebook.md')
    print(json.dumps({'pdf':str(PDF),'pages':18,'lowest_content_y':min(r['bottom'] for r in layout),'sha256':sha(PDF)},ensure_ascii=False))

if __name__=='__main__':main()
