"""Build the six-page Croatian briefing from the executed R results."""
from pathlib import Path
from xml.sax.saxutils import escape
import csv
import hashlib
import html
import json
import math

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

HERE = Path(__file__).resolve().parent
OUT = HERE / 'output' / 'private'
FIG = OUT / 'figures'
FIG.mkdir(exist_ok=True)
R = json.loads((OUT / 'results.json').read_text(encoding='utf-8'))
MAIN, CORE = R['main'][0], R['core'][0]
LABEL = R['group_labels']
GROUPS = ['church_media', 'church_org', 'independent', 'clergy', 'community', 'devotional']
SHORT = {'church_media': 'Crkveni mediji', 'church_org': 'Crkvene ustanove',
         'independent': 'Neovisni mediji', 'clergy': 'Svećenički profili',
         'community': 'Zajednice i udruge', 'devotional': 'Pobožni/autorski kanali'}
PLATFORM = {'web': 'Web', 'facebook': 'Facebook', 'youtube': 'YouTube',
            'instagram': 'Instagram', 'twitter': 'X/Twitter', 'tiktok': 'TikTok'}
INK, GREEN, COPPER, MUTED = '#193f43', '#42866d', '#b56c45', '#5e7275'
PAPER, LINE = '#fcfbf7', '#d8e0dc'
W, H = A4
M, CW = 44, W - 88

def num(n, digits=0):
    if n is None or (isinstance(n, float) and not math.isfinite(n)):
        return 'n/p'
    return f'{n:,.{digits}f}'.replace(',', 'X').replace('.', ',').replace('X', '.')

def pct(n, digits=1):
    return num(100*n, digits) + ' %'

def group(g):
    return next(x for x in R['actor_groups'] if x['group'] == g)

def gp(g, p):
    return next((x for x in R['group_platform'] if x['group'] == g and x['SOURCE_TYPE'] == p),
                {'posts': 0, 'sources': 0, 'interactions': 0})

def conc(p):
    return next(x for x in R['concentration'] if x['SOURCE_TYPE'] == p)

def sentiment(g, p, val, period='sentiment'):
    return next((x for x in R[period] if x['group'] == g and x['SOURCE_TYPE'] == p and x['sentiment'] == val), None)

def ratio(g, p, period='sentiment'):
    a, b = sentiment(g, p, 'negative', period), sentiment(g, p, 'neutral', period)
    return a['mean']/b['mean']

plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 9,
                     'axes.spines.top': False, 'axes.spines.right': False,
                     'axes.edgecolor': LINE, 'text.color': INK,
                     'axes.labelcolor': MUTED, 'xtick.color': MUTED, 'ytick.color': INK,
                     'figure.facecolor': PAPER, 'axes.facecolor': PAPER})

# Group shares use a separate denominator for each platform.
fig, ax = plt.subplots(figsize=(7.05, 2.7))
y = np.arange(len(GROUPS))
for delta, p, col in [(-.16, 'facebook', GREEN), (.16, 'youtube', COPPER)]:
    vals = [100*gp(g,p)['interactions']/conc(p)['interactions'] for g in GROUPS]
    ax.barh(y+delta, vals, .29, color=col, label=PLATFORM[p])
    for yy, v in zip(y+delta, vals):
        if v > 1.5:
            ax.text(v+.65, yy, num(v,1)+' %', va='center', fontsize=8)
ax.set_yticks(y, [SHORT[g] for g in GROUPS]); ax.invert_yaxis()
ax.set_xlim(0,76); ax.set_xlabel('Udio interakcija odabranih izvora na istoj platformi (%)')
ax.legend(frameon=False, loc='upper right'); ax.grid(axis='x', alpha=.15)
ax.set_axisbelow(True); fig.tight_layout(pad=.8)
fig.savefig(FIG/'actor_platform.png',dpi=220); plt.close(fig)

fig, ax = plt.subplots(figsize=(7.05, 2.85))
for p,col in [('facebook',GREEN),('youtube',COPPER),('web','#557c98')]:
    points = [x for x in R['lorenz'] if x['SOURCE_TYPE']==p and x['rank']<=50]
    ax.plot([0]+[x['rank'] for x in points],[0]+[100*x['cum'] for x in points],
            color=col,linewidth=2.2,label=PLATFORM[p])
ax.set_xlim(0,50); ax.set_ylim(0,102)
ax.set_xlabel('Broj vodećih izvora na platformi')
ax.set_ylabel('Kumulativni udio interakcija (%)')
ax.legend(frameon=False,loc='lower right'); ax.grid(alpha=.2)
fig.tight_layout(pad=.8); fig.savefig(FIG/'concentration.png',dpi=220); plt.close(fig)

for name, fn in [('Body','calibri.ttf'),('Bold','calibrib.ttf'),('Italic','calibrii.ttf'),('Title','georgia.ttf')]:
    pdfmetrics.registerFont(TTFont(name, 'C:/Windows/Fonts/'+fn))
pdfmetrics.registerFontFamily('Body',normal='Body',bold='Bold',italic='Italic',boldItalic='Bold')
STYLE = {
 'body': ParagraphStyle('body',fontName='Body',fontSize=11.6,leading=15.8,textColor=colors.HexColor(INK)),
 'small': ParagraphStyle('small',fontName='Body',fontSize=9.4,leading=12.5,textColor=colors.HexColor(MUTED)),
 'h2': ParagraphStyle('h2',fontName='Bold',fontSize=12,leading=15.8,textColor=colors.HexColor(INK)),
 'cell': ParagraphStyle('cell',fontName='Body',fontSize=9.3,leading=11.8,textColor=colors.HexColor(INK)),
 'head': ParagraphStyle('head',fontName='Bold',fontSize=9,leading=11.4,textColor=colors.white),
 'title': ParagraphStyle('title',fontName='Title',fontSize=23,leading=28,textColor=colors.HexColor(INK))
}
PDF = OUT / 'katolicki-akteri-istrazivacki-uvid.pdf'
C = canvas.Canvas(str(PDF),pagesize=A4)
C.setTitle('Katolički akteri i raspodjela digitalne pažnje')
C.setAuthor('DigiKat - istraživački pregled')
C.setSubject('Eksplorativna i deskriptivna analiza lokalnog skupa podataka 2021.-2025.')
Y = H-73
PAGE = 0
HTML = []
LAYOUT = []

def start(title, subtitle):
    global Y,PAGE
    if PAGE:
        end()
    PAGE+=1
    C.setFillColor(colors.HexColor(PAPER)); C.rect(0,0,W,H,fill=1,stroke=0)
    C.setFillColor(colors.HexColor(MUTED)); C.setFont('Bold',8.4)
    C.drawString(M,H-34,'DIGIKAT  /  ISTRAŽIVAČKI UVID')
    C.setFont('Body',8.4); C.drawRightString(W-M,H-34,'2021.-2025.  |  13. listopada 2026.')
    C.setStrokeColor(colors.HexColor(LINE)); C.line(M,H-44,W-M,H-44)
    Y=H-65
    HTML.append('<section>')
    para(title,'title',after=8)
    para(subtitle,'small',after=15)

def para(text,style='body',after=8):
    global Y
    p=Paragraph(text,STYLE[style]); _,hh=p.wrap(CW,1000)
    C.setFillColor(colors.HexColor(INK)); p.drawOn(C,M,Y-hh);Y-=hh+after
    tag='h1' if style=='title' else 'h2' if style=='h2' else 'p'
    HTML.append(f'<{tag} class="{style}">{text}</{tag}>')

def table(headers,rows,widths=None):
    global Y
    widths = widths or [CW/len(headers)]*len(headers)
    cells=[[Paragraph(escape(str(v)),STYLE['head']) for v in headers]]
    cells += [[Paragraph(escape(str(v)),STYLE['cell']) for v in row] for row in rows]
    t=Table(cells,colWidths=widths,hAlign='LEFT')
    t.setStyle(TableStyle([
      ('BACKGROUND',(0,0),(-1,0),colors.HexColor(INK)),
      ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.HexColor('#eef3ef'),colors.HexColor(PAPER)]),
      ('VALIGN',(0,0),(-1,-1),'MIDDLE'),('LEFTPADDING',(0,0),(-1,-1),6),
      ('RIGHTPADDING',(0,0),(-1,-1),6),('TOPPADDING',(0,0),(-1,-1),6),
      ('BOTTOMPADDING',(0,0),(-1,-1),6),
      ('LINEBELOW',(0,-1),(-1,-1),.4,colors.HexColor(LINE))]))
    _,hh=t.wrap(CW,1000); t.drawOn(C,M,Y-hh);Y-=hh+11
    HTML.append('<table><thead><tr>'+''.join('<th>'+html.escape(str(v))+'</th>' for v in headers)+'</tr></thead><tbody>')
    HTML.extend('<tr>'+''.join('<td>'+html.escape(str(v))+'</td>' for v in row)+'</tr>' for row in rows)
    HTML.append('</tbody></table>')

def chart(name,height):
    global Y
    C.drawImage(str(FIG/name),M,Y-height,width=CW,height=height,mask='auto')
    Y-=height+7
    HTML.append(f'<img src="figures/{name}" alt="Grafički prikaz izračunatih rezultata">')

def end():
    LAYOUT.append({'page':PAGE,'content_bottom':round(Y,1)})
    if Y<55:
        raise RuntimeError(f'Page {PAGE} overflows: content bottom {Y}')
    C.setStrokeColor(colors.HexColor(LINE));C.line(M,43,W-M,43)
    C.setFont('Body',8);C.setFillColor(colors.HexColor(MUTED))
    C.drawString(M,29,'Eksplorativni pregled za istraživački rad. Oznake aktera su indikativne.')
    C.drawRightString(W-M,29,f'{PAGE} / 6')
    C.showPage();HTML.append('</section>')

social_top=R['social_concentration'][0]
start('Katolički akteri i raspodjela digitalne pažnje',
      'Deskriptivni prilog pitanju: Tko je preuzeo ulogu teologa u hrvatskom javnom prostoru?')
para('Uvid u dostupni skup podataka pokazuje gdje se okuplja pažnja i koji se izvori pojavljuju među vodećima. '
     'Popis može poslužiti kao polazište za istraživanje javnih tumača vjere. Interakcije pritom ne mjere '
     'teološku stručnost, povjerenje publike ni prihvaćanje nečijega tumačenja.')
para('Tri nalaza važna za istraživanje','h2')
para(f'<b>Pažnja se okuplja oko malog broja izvora.</b> Deset vodećih društvenomrežnih izvora u '
     f'odabranom skupu prikuplja {pct(social_top["top10"])} zabilježenih interakcija; prvih pedeset '
     f'{pct(social_top["top50"])}. To su računi i kanali, a ne pedeset međusobno neovisnih osoba.')
para('<b>Vrsta izvora i platforma zajedno određuju sliku.</b> Na webu se ističe Hrvatska katolička mreža, '
     'na Facebooku Laudato, a na YouTubeu kanal pulherissimus. Isti medijski brend može imati vrlo različit '
     'položaj na različitim platformama.')
para('<b>Negativan sentiment nema jedinstvenu vezu s angažmanom.</b> Kod pobožnih i autorskih kanala '
     'zbirni rezultati YouTubea i Facebooka idu u različitim smjerovima. Usporedba unutar istih izvora '
     'dodatno ublažava jednostavnu tvrdnju da negativnost privlači više pažnje.')
para('Što je stvarno analizirano','h2')
table(['Korak','Broj zapisa'],[
 ['Dostupna lokalna datoteka, do 6. siječnja 2026.',num(R['input']['raw_rows'])],
 ['Izostavljeno izvan razdoblja 2021.-2025.',num(R['input']['excluded_outside_period'])],
 ['Uklonjeni ponovljeni parovi platforma i URL',num(R['input']['duplicate_captures_removed'])],
 ['Analitički skup nakon vremenskog odabira i spajanja',num(MAIN['posts'])],
 ['Objave indikativno razvrstanih katoličkih komunikatora',num(CORE['posts'])],
], [CW*.77,CW*.23])
para('Ulaz je raniji lokalni skup DigiKat podataka, a ne noviji službeni korpus od 413.985 zapisa. '
     'Analiza je ponovno izvedena iz dostupne datoteke. Za ponovljeni URL na istoj platformi zadržan je '
     'zapis s najvećim raspoloživim brojem interakcija. Godine su izvedene iz datuma objave.','small')

start('Kakvi su izvori zastupljeni?',
      'Postojeći registri i pravila repozitorija daju radnu podjelu, uz vidljive granice klasifikacije.')
para(f'Postojeće oznake izdvajaju {num(CORE["sources"])} izvora, odnosno parova naziva i platforme, '
     f's {num(CORE["posts"])} objava. To je {pct(CORE["posts"]/MAIN["posts"])} analitičkog skupa. '
     'Ostatak čine opći mediji, drugi javni izvori i nerazvrstani zapisi; ne smije ga se u cijelosti zvati sekularnim.')
table(['Vrsta izvora','Izvori','Objave','Udio objava¹'],
      [[LABEL[g],num(group(g)['sources']),num(group(g)['posts']),pct(group(g)['posts']/CORE['posts'])] for g in GROUPS],
      [CW*.49,CW*.13,CW*.19,CW*.19])
para('¹ Udio unutar odabranog skupa katoličkih komunikatora. Isti akter na dvije platforme računa se dvaput.','small',after=4)
chart('actor_platform.png',195)
para('Na Facebooku većina interakcija odabranih izvora pripada pobožnim/autorskim kanalima i neovisnim medijima. '
     'Na YouTubeu posebno se ističu pobožni/autorski kanali i jedan izrazito vidljiv svećenički kanal. '
     'Broj objava i udio pažnje stoga opisuju različite položaje u istom prostoru.')
reg=next(x for x in R['classification_coverage'] if x['rule']=='existing_registry')
para(f'Iz eksplicitnog registra potječe razvrstavanje {pct(reg["posts"]/CORE["posts"])} odabranih objava; '
     'ostatak se oslanja na postojeće popise, katalog i obrasce naziva. Pobožni kanal nije automatski laički '
     'influencer. Oznake ne dokazuju obrazovanje ili institucionalni mandat.','small')

start('Izvori s najviše zabilježenih interakcija',
      'Prvih dvanaest u zajedničkom opisnom popisu. Cjelovitih pedeset nalazi se u zasebnom prilogu.')
para('Rang je izračunan iz izvornog polja INTERACTIONS. Web i društvene mreže prikazani su zajedno radi '
     'izbora kandidata za istraživanje, a platforma je navedena u svakom retku. Brojevi nisu jedinstvena publika '
     'i nisu standardizirana mjera utjecaja; web i društvene objave mogu prenositi isti sadržaj.')
top=R['top_sources'][:12]
table(['#','Izvor','Platforma','Objave','Interakcije','Medijan²'],
 [[num(x['rank']),x['source'],PLATFORM[x['SOURCE_TYPE']],num(x['posts']),num(x['interactions']),num(x['median'],1)] for x in top],
 [24,153,62,63,99,CW-401])
para('² Medijan interakcija po objavi s dostupnim podatkom. Nula je opažena vrijednost i razlikuje se od nedostajućeg podatka. '
     'Ukupni broj favorizira izvore s više objava; medijan opisuje tipičnu objavu.','small')
para('Kako čitati ovaj popis','h2')
para('Hrvatska katolička mreža ističe se velikim brojem web objava. Osobni i pobožni kanali mogu imati '
     'znatno manje objava, uz veći medijan interakcija. Bitno.net i Laudato pojavljuju se kroz zasebne web i '
     'Facebook izvore: te retke ne treba tumačiti kao različite organizacije.')
cl=group('clergy')
pul=next(x for x in R['top_sources'] if x['key']=='pulherissimus')
para(f'Posebno je važan kanal pulherissimus: čini {pct(pul["interactions"]/cl["interactions"])} interakcija '
     'skupine svećeničkih profila. Rezultat te skupine zato pretežno opisuje jedan kanal. Njegovo svrstavanje '
     'oslanja se na bilješku o svećeničkom uredniku iz postojećeg registra.')
para('Novi Život zadržan je kao granični slučaj izvan katoličkog odabira, jer ga noviji repozitorijski registar '
     f'opisuje kao međukršćanski portal. U ovom skupu ima {num(R["noncatholic_boundary"][0]["interactions"])} '
     'interakcija, pa bi drukčija klasifikacija bitno promijenila popis.','small')

start('Koliko je pažnja koncentrirana?',
      'Koncentracija se računa unutar svake platforme i odabranoga skupa izvora s raspoloživim interakcijama.')
chart('concentration.png',219)
table(['Platforma','Izvori³','Prvi izvor','Prvih 10','Prvih 50'],
 [[PLATFORM[p],num(conc(p)['sources']),pct(conc(p)['top1']),pct(conc(p)['top10']),pct(conc(p)['top50'])]
  for p in ['web','facebook','youtube']],
 [CW*.24,CW*.13,CW*.21,CW*.21,CW*.21])
para('³ Uključeni su izvori s barem jednim opaženim podatkom o interakcijama, uključujući opažene nule. '
     'Izvori bez podataka ne dobivaju nulti angažman. Krivulja pokazuje koliki udio interakcija pripada vodećim izvorima.','small')
para(f'Na Facebooku deset izvora prikuplja {pct(conc("facebook")["top10"])} interakcija, a na YouTubeu '
     f'{pct(conc("youtube")["top10"])}. Na webu koncentracija je još viša: prvih deset izvora obuhvaća '
     f'{pct(conc("web")["top10"])} zabilježenih interakcija odabranih komunikatora.')
para('Takva raspodjela opravdava fokus na ograničen broj izvora u sljedećoj fazi istraživanja. Ipak, popis '
     'najvidljivijih treba čitati zajedno s manje vidljivim institucionalnim i akademskim glasovima. '
     'Njihov manji broj interakcija ne govori koliko ih publika smatra stručnima.')
para('Zašto su platforme odvojene','h2')
para('Facebookovo polje interakcija u dostupnim usporedivim zapisima odgovara zbroju lajkova, komentara i '
     'dijeljenja. YouTube nema istu dostupnost sastavnica, a web može bilježiti društvene reakcije vezane uz '
     'članak. Zato su platformske koncentracije informativnije od jedne zajedničke usporedbe. '
     'Instagram, TikTok i X imaju malo razvrstanih izvora i ostaju u prilogu.','small')

start('Sentiment i angažman nisu isti obrazac svugdje',
      'Deskriptivna usporedba automatski označenih negativnih i neutralnih objava. Bez testiranja uzročnosti.')
para('Postojeće automatske oznake sentimenta omogućuju brz pregled. Sljedeća tablica odvaja Facebook i '
     'YouTube te prikazuje skupine s barem 20 objava s dostupnim interakcijama u obje kategorije. '
     'Pozitivne objave uključene su u prateću tablicu rezultata; ovdje je fokus na istraživačkom pitanju o negativnosti.')
rows=[]
for p in ['facebook','youtube']:
    for g in ['independent','church_org','devotional','clergy','community']:
        a,b=sentiment(g,p,'negative'),sentiment(g,p,'neutral')
        if not a or not b or min(a['observed'],b['observed'])<20: continue
        rows.append([PLATFORM[p],SHORT[g],num(a['observed'])+' / '+num(b['observed']),
                     num(a['median'],1)+' / '+num(b['median'],1),num(a['mean'],1)+' / '+num(b['mean'],1)])
table(['Platforma','Vrsta izvora','Broj objava N / U','Medijan N / U','Prosjek N / U'],rows,
      [CW*.14,CW*.28,CW*.21,CW*.18,CW*.19])
para('N = negativne; U = neutralne. Primjer: 108 / 33 znači medijan od 108 interakcija za negativne i 33 za '
     'neutralne objave. Prosjeci su osjetljivi na vrlo popularne objave.','small')
para(f'Kod pobožnih/autorskih kanala na YouTubeu prosjek negativnih objava iznosi '
     f'{num(ratio("devotional","youtube"),2)} puta prosjek neutralnih. Na Facebooku isti omjer iznosi '
     f'{num(ratio("devotional","facebook"),2)}: negativne objave ondje imaju niži prosjek. '
     'Ni među neovisnim medijima tablica ne pokazuje opću prednost negativnih objava.')
within=next(x for x in R['within_source'] if x['group']=='devotional' and x['SOURCE_TYPE']=='youtube')
para(f'Kad se uspoređuju isti YouTube izvori s barem pet negativnih i pet neutralnih objava, negativne '
     f'imaju viši prosjek u {pct(within["share_negative_higher"],0)} od {num(within["sources"])} kanala. '
     f'U samoj 2025. zbirni YouTube omjer pada na {num(ratio("devotional","youtube","sentiment_2025"),2)}. '
     'Zbirni rezultat stoga ovisi i o sastavu izvora i razdoblju.')
para('Oznake nisu ručno provjeravane za ovaj izvještaj. Negativan jezik može opisivati patnju, grijeh ili '
     'društveni problem, a ne napad na Crkvu. Iz ovih brojeva ne slijedi da negativnost uzrokuje angažman '
     'ili da neinstitucionalni akteri sustavno dobivaju više pažnje zbog negativnosti.','small')

start('Što ovaj pregled otvara za istraživanje?',
      'Postojeći rječnici daju dodatne tragove o sadržaju, bez tvrdnje da prepoznaju teološki autoritet.')
para('Pretraženi su početci riječi iz postojećih DigiKat rječnika u prvih 3.000 znakova svake raspoložive '
     'objave odabranih izvora. Tablica prikazuje udio objava s barem jednim podudaranjem. Kategorije se preklapaju.')
themes=['TEOLOGIJA_I_DOKTRINA','POLITIKA_I_ODNOS_S_DRZAVOM','UNUTARCRKVENI_PRIJEPORI_I_IDEOLOGIJE']
rows=[]
for g in GROUPS:
    rows.append([SHORT[g]]+[pct(next(x['share'] for x in R['themes'] if x['group']==g and x['theme']==t)) for t in themes])
table(['Vrsta izvora','Teologija i nauk','Politika i država','Unutarcrkveni prijepori'],rows,
      [CW*.37,CW*.21,CW*.21,CW*.21])
para('Rječnik teologije uključuje i riječi poput grijeh, spasenje i evanđelje. Politički rječnik uključuje '
     'zakon i vladu. Podudaranje zato nije dokaz stručnog tumačenja ili političkog stava, a izostanak '
     'podudaranja ne znači izostanak teme.','small')
para('Tri korisna smjera čitanja nalaza','h2')
para('<b>Promatrati različite oblike javne prisutnosti.</b> Crkveni medij, uredništvo neovisnog portala i '
     'pobožni kanal okupljaju pažnju na različite načine. Popis pedeset izvora konkretizira koga uključiti '
     'u daljnje istraživanje, dok medijan i ukupni angažman pomažu razlikovati tipičan od iznimnog odaziva.')
para('<b>Prepoznati da kanal nije nužno govornik.</b> Uredništvo može objavljivati teologe, svećenike i laike. '
     'Klasifikacija izdavača zato ne pokazuje čiji argument dobiva pažnju. Postojeći popis osobito je koristan '
     'za kasniju identifikaciju autora, gostiju i citiranih tumača.')
para('<b>Ostaviti pitanje zamjene otvorenim.</b> Ovi nalazi opisuju raspodjelu pažnje. Ne dokazuju da su '
     'teolozi izgubili autoritet, da su laici zauzeli njihovo mjesto ili da velik angažman znači odobravanje publike.')
para('Opseg i izvori','h2')
para('Obuhvat ovisi o prikupljanju, koje se mijenjalo oko 2024.; razlike kroz godine nisu čisti trendovi '
     'javne pažnje. Riječ je o tematskom skupu, ne o svim objavama svakog izvora ili reprezentativnom uzorku '
     'stanovnika Hrvatske. Sadrži i regionalne izvore. Obrazovanje i formalni mandat nisu novokodirani. '
     'Korišteni su lokalni skup merged_comprehensive, registar source-groups, katalog source_labels, '
     'pravila studije catholic-influencers i zajednički tematski rječnici. Potpuna sljedivost, tablice i '
     'ponovljiva skripta priloženi su u radnoj mapi.','small')
end();C.save()
assert PAGE==6

CSS='''body{margin:0;background:#e8eeeb;color:#193f43;font:17px/1.55 Calibri,Arial,sans-serif}main{max-width:900px;margin:auto}section{background:#fcfbf7;margin:25px 0;padding:45px 50px;box-shadow:0 2px 10px #0001}h1{font:32px/1.2 Georgia,serif}h2{font-size:21px;margin-top:24px}.small{font-size:14px;color:#5e7275}table{border-collapse:collapse;width:100%;font-size:14px;margin:16px 0}th{background:#193f43;color:white;text-align:left}td,th{padding:9px;border-bottom:1px solid #d8e0dc}tr:nth-child(even){background:#eef3ef}img{width:100%;height:auto}@media print{section{break-after:page;margin:0;box-shadow:none}body{background:white}}'''
(OUT/'izvjestaj.html').write_text('<!doctype html><html lang="hr"><meta charset="utf-8"><title>Katolički akteri i digitalna pažnja</title><style>'+CSS+'</style><main>'+''.join(HTML)+'</main></html>',encoding='utf-8')

# Reader-facing top fifty: preserve source-platform units and classification provenance.
FIELDS=['Rang','Izvor','Platforma','Vrsta izvora','Broj objava','Zabilježene interakcije','Medijan interakcija',
        'Dostupnost interakcija (%)','Rang unutar platforme','Interakcije 2025.','Podloga klasifikacije',
        'Institucionalni mandat - za dopunu','Teološko obrazovanje - za dopunu','Napomene - za dopunu']
RULES={'existing_registry':'Postojeći registar','institution_pattern':'Obrazac institucionalnog naziva',
       'creator_pattern':'Obrazac autorskog/pobožnog naziva','catalogue_confessional':'Postojeći katalog',
       'independent_pattern':'Obrazac neovisnog medija','inherited_creator_list':'Naslijeđeni popis autora',
       'inherited_institution_list':'Naslijeđeni popis ustanova','inherited_media_list':'Naslijeđeni popis medija'}
toprows=[]
for x in R['top_sources']:
    toprows.append([x['rank'],x['source'],PLATFORM[x['SOURCE_TYPE']],LABEL[x['group']],x['posts'],
                    x['interactions'],x['median'],round(100*x['coverage'],2),x['platform_rank'],
                    x['interactions_2025'],RULES[x['rule']],'','',''])
with (OUT/'top-50-izvora.csv').open('w',encoding='utf-8-sig',newline='') as f:
    wr=csv.writer(f,delimiter=';');wr.writerow(FIELDS);wr.writerows(toprows)
intro='''<h1>Prvih 50 izvora po zabilježenim interakcijama</h1><p>Razdoblje 2021.-2025. Jedinica je naziv izvora na pojedinoj platformi. Popis uključuje web i društvene mreže te služi izboru kandidata za istraživanje. Rang nije standardizirana mjera utjecaja ili jedinstvene publike. Isti akter može imati više redaka. Klasifikacija je indikativna i preuzeta iz repozitorijskih resursa.</p><p>Pripadajući <a href="izvjestaj.html">izvještaj</a> objašnjava obuhvat i metode. <a href="top-50-izvora.csv">Preuzmi tablicu za daljnje kodiranje</a>. Prazna polja u CSV-u ostavljena su za mandat, obrazovanje i napomene; te informacije nisu istraživane u ovom pregledu.</p>'''
headers=FIELDS[:11]
companion=['<table><thead><tr>'+''.join('<th>'+html.escape(v)+'</th>' for v in headers)+'</tr></thead><tbody>']
for row in toprows:
    companion.append('<tr>'+''.join('<td>'+html.escape(str(v))+'</td>' for v in row[:11])+'</tr>')
companion.append('</tbody></table>')
(OUT/'top-50-izvora.html').write_text('<!doctype html><html lang="hr"><meta charset="utf-8"><title>Top 50 izvora</title><style>'+CSS+'main{max-width:1500px}section{overflow:auto}thead{position:sticky;top:0}</style><main><section>'+intro+''.join(companion)+'</section></main></html>',encoding='utf-8')
qa={'pages':PAGE,'layout':LAYOUT,'input_sha256':R['input']['sha256'],
    'pdf_sha256':hashlib.sha256(PDF.read_bytes()).hexdigest(),'top50_rows':len(toprows)}
(OUT/'build.json').write_text(json.dumps(qa,indent=2),encoding='utf-8')
print(json.dumps(qa,indent=2))
