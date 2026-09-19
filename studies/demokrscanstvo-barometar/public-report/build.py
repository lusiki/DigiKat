"""Public Croatian edition. Read-only reuse of the verified analytical aggregates.

Run from the repository root: python -X utf8 studies/demokrscanstvo-barometar/public-report/build.py
No original report, source data or website output is replaced.
"""
from pathlib import Path
import csv
import json
import re
import hashlib
import textwrap
from xml.sax.saxutils import escape

import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib import font_manager as fm
from matplotlib.colors import LinearSegmentedColormap
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, Table, TableStyle, Spacer, Flowable
from svglib.svglib import svg2rlg

ROOT = Path(__file__).resolve().parents[3]
DATA = ROOT / 'output/demokrscanstvo-analysis/v1'
OUT = ROOT / 'output/demokrscanstvo-public/v2'
FIG = OUT / 'figures'
QA = ROOT / 'tmp/pdfs/demokrscanstvo-public'
PDF = ROOT / 'output/pdf/demokrscanstvo-u-medijskom-prostoru.pdf'
for folder in (OUT, FIG, QA, PDF.parent):
    folder.mkdir(parents=True, exist_ok=True)

def js(name):
    return json.loads((DATA / (name + '.json')).read_text(encoding='utf-8-sig'))

def rows(name):
    with (DATA / (name + '.csv')).open(encoding='utf-8-sig', newline='') as stream:
        return list(csv.DictReader(stream))

def num(x):
    return f'{int(x):,}'.replace(',', '.')

def dec(x, digits=1):
    return f'{float(x):.{digits}f}'.replace('.', ',')

def share(x, total):
    return dec(100 * int(x) / int(total))

S = js('summary')
TOP = {r['topic']: r for r in rows('topic_sensitivity') if r['scope'] == 'publications'}
PLAT = {r['platform']: r for r in rows('platforms')}
PROFILES = rows('topic_profiles')
EPISODES = {r['month']: r for r in rows('episode_selection') if r['selected'] == 'True'}
TOPICS = [f't{i:02d}' for i in range(1, 11)]
N = S['records']
IDENTITY = sum(int(TOP[t]['n']) for t in ('t01', 't02', 't03', 't04'))
assert sum(int(r['n']) for r in TOP.values()) == N
assert sum(int(r['n']) for r in PLAT.values()) == N

def profile(scope, category, topic):
    return next(r for r in PROFILES if (r['scope'], r['category'], r['topic']) == (scope, str(category), topic))

INK = '#173e43'
COPPER = '#a9643b'
MUTED = '#526b6f'
PAPER = '#fcfbf7'
PALE = '#eef2ef'
LINE = '#cdd9d4'
GOLD = '#e2b58a'
W, H = A4
M = 45
CW = W - 2 * M

for name, filename in [('Body', 'calibri.ttf'), ('BodyBold', 'calibrib.ttf'),
                       ('BodyItalic', 'calibrii.ttf'), ('Display', 'georgia.ttf')]:
    pdfmetrics.registerFont(TTFont(name, 'C:/Windows/Fonts/' + filename))
pdfmetrics.registerFontFamily('Body', normal='Body', bold='BodyBold', italic='BodyItalic', boldItalic='BodyBold')
for filename in ('calibri.ttf', 'calibrib.ttf'):
    fm.fontManager.addfont('C:/Windows/Fonts/' + filename)
plt.rcParams.update({
    'font.family': 'Calibri', 'font.size': 11, 'axes.spines.top': False,
    'axes.spines.right': False, 'axes.spines.left': False,
    'axes.edgecolor': LINE, 'text.color': INK, 'axes.labelcolor': INK,
    'xtick.color': MUTED, 'ytick.color': INK, 'savefig.facecolor': PAPER,
    'axes.facecolor': PAPER, 'figure.facecolor': PAPER, 'svg.fonttype': 'path',
    'xtick.labelsize': 10.7, 'ytick.labelsize': 11.1,
})
ST = {
    'body': ParagraphStyle('body', fontName='Body', fontSize=11.4, leading=15.1, textColor=colors.HexColor('#253b3e'), spaceAfter=11),
    'small': ParagraphStyle('small', fontName='Body', fontSize=9.6, leading=12.5, textColor=colors.HexColor(MUTED), spaceAfter=10),
    'h1': ParagraphStyle('h1', fontName='Display', fontSize=24, leading=28.5, textColor=colors.HexColor(INK), spaceAfter=17),
    'h2': ParagraphStyle('h2', fontName='BodyBold', fontSize=13.1, leading=17, textColor=colors.HexColor(INK), spaceBefore=7, spaceAfter=7),
    'cell': ParagraphStyle('cell', fontName='Body', fontSize=10.6, leading=14, textColor=colors.HexColor(INK)),
    'head': ParagraphStyle('head', fontName='BodyBold', fontSize=10.6, leading=13.5, textColor=colors.white),
    'pull': ParagraphStyle('pull', fontName='Display', fontSize=17.5, leading=23, textColor=colors.HexColor(INK), spaceAfter=0),
}
PAGES = []
CLAIMS = []

def p(raw, style='body', source=''):
    raw = re.sub('[\u2010-\u2014]', '-', raw)
    assert '\ufffd' not in raw
    if source:
        CLAIMS.append({'page': len(PAGES) + 2, 'text': raw, 'source': source})
    markup = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', escape(raw).replace('\n', '<br/>'))
    return Paragraph(markup, ST[style])

def h(raw):
    return p(raw, 'h2')

def cap(raw):
    return p(raw, 'small')

def table(data, widths):
    cells = [[Paragraph(escape(str(cell)).replace('\n', '<br/>'), ST['head' if i == 0 else 'cell'])
              for cell in row] for i, row in enumerate(data)]
    result = Table(cells, colWidths=[CW * w for w in widths], hAlign='LEFT')
    rules = [('BACKGROUND', (0, 0), (-1, 0), colors.HexColor(INK)),
             ('VALIGN', (0, 0), (-1, -1), 'TOP'),
             ('LEFTPADDING', (0, 0), (-1, -1), 9), ('RIGHTPADDING', (0, 0), (-1, -1), 9),
             ('TOPPADDING', (0, 0), (-1, -1), 9), ('BOTTOMPADDING', (0, 0), (-1, -1), 9),
             ('LINEBELOW', (0, -1), (-1, -1), .6, colors.HexColor(LINE))]
    for i in range(1, len(data)):
        if i % 2:
            rules.append(('BACKGROUND', (0, i), (-1, i), colors.HexColor(PALE)))
    result.setStyle(TableStyle(rules))
    return result

class Takeaway(Flowable):
    def __init__(self, text):
        super().__init__()
        self.paragraph = p(text, 'pull')
    def wrap(self, width, height):
        self.width = width
        _, self.ph = self.paragraph.wrap(width - 35, height)
        self.height = self.ph + 31
        return self.width, self.height
    def draw(self):
        self.canv.setFillColor(colors.HexColor(PALE))
        self.canv.rect(0, 0, self.width, self.height, fill=1, stroke=0)
        self.canv.setFillColor(colors.HexColor(COPPER))
        self.canv.rect(0, 0, 3, self.height, fill=1, stroke=0)
        self.paragraph.drawOn(self.canv, 18, 16)
    def getSpaceBefore(self):
        return 8
    def getSpaceAfter(self):
        return 16

def page(kicker, title, items):
    PAGES.append((kicker, title, [p(title, 'h1')] + items))

def chart(name, maxheight=360):
    drawing = svg2rlg(str(FIG / (name + '.svg')))
    scale = min(CW / drawing.width, maxheight / drawing.height)
    drawing.scale(scale, scale)
    drawing.width *= scale
    drawing.height *= scale
    return drawing

def wrap(label, width=29):
    return '\n'.join(textwrap.wrap(label, width))

def save_chart(fig, name):
    fig.savefig(FIG / (name + '.svg'), bbox_inches='tight', pad_inches=.16)
    fig.savefig(FIG / (name + '.png'), dpi=180, bbox_inches='tight', pad_inches=.16)
    plt.close(fig)

def make_figures():
    # Publication counts only. The exact-group series is intentionally not reused.
    order = sorted(TOPICS, key=lambda t: -int(TOP[t]['n']))
    fig, ax = plt.subplots(figsize=(7.1, 5.25), layout='constrained')
    values = [float(TOP[t]['percent']) for t in order]
    ax.barh(range(10), values, color=[INK if i < 4 else '#789b93' for i in range(10)], height=.65)
    ax.set_yticks(range(10), [wrap(TOP[t]['label']) for t in order])
    ax.invert_yaxis()
    ax.set_xlim(0, 22.5)
    ax.set_xticks([0, 5, 10, 15, 20], ['0%', '5%', '10%', '15%', '20%'])
    ax.set_xlabel('Udio među analiziranim tekstovima i objavama', labelpad=9)
    for i, t in enumerate(order):
        ax.text(values[i] + .25, i, f'{dec(values[i])}%  |  {num(TOP[t]["n"])}', va='center', fontsize=10.7)
    ax.grid(axis='x', alpha=.17)
    ax.set_axisbelow(True)
    save_chart(fig, '01-teme')

    years = sorted({r['category'] for r in PROFILES if r['scope'] == 'year'})
    arr = np.array([[float(profile('year', year, t)['percent']) for year in years] for t in TOPICS])
    cmap = LinearSegmentedColormap.from_list('teal', ['#f1f5f1', '#789b93', INK])
    fig, ax = plt.subplots(figsize=(7.1, 5.35), layout='constrained')
    ax.imshow(arr, cmap=cmap, vmin=0, vmax=30, aspect='auto')
    ax.set_yticks(range(10), [wrap(TOP[t]['label']) for t in TOPICS])
    ax.set_xticks(range(len(years)), [y + '.' + ('\ndo 10. 9.' if y == '2026' else '') for y in years])
    ax.tick_params(axis='both', length=0, pad=8)
    for i in range(10):
        for j in range(len(years)):
            ax.text(j, i, dec(arr[i, j]) + '%', ha='center', va='center', fontsize=10.8,
                    color='white' if arr[i, j] >= 19 else INK)
    save_chart(fig, '02-godine')

    keys = [k for k in PLAT if int(PLAT[k]['n']) > 0]
    fig, axes = plt.subplots(1, 2, figsize=(7.1, 4.0), gridspec_kw={'width_ratios': [1, 1.75]}, layout='constrained')
    ax = axes[0]
    ax.set_axis_off()
    ax.text(.47, .64, num(PLAT['web']['n']), transform=ax.transAxes,
            ha='center', va='center', fontsize=32, fontweight='bold', color=INK)
    ax.text(.47, .51, 'tekstova s mrežnih\nstranica', transform=ax.transAxes,
            ha='center', va='center', fontsize=12, color=MUTED, linespacing=1.4)
    ax.text(.47, .31, dec(PLAT['web']['percent']) + '%', transform=ax.transAxes,
            ha='center', va='center', fontsize=25, color=COPPER)
    ax.text(.47, .22, 'analiziranog materijala', transform=ax.transAxes,
            ha='center', va='center', fontsize=11, color=MUTED)
    ax.set_title('Mrežni mediji', loc='left', fontsize=12, color=INK, pad=14)
    ax = axes[1]
    other = [k for k in keys if k != 'web']
    ax.barh(range(len(other)), [int(PLAT[k]['n']) for k in other], color=COPPER, height=.62)
    ax.set_yticks(range(len(other)), ['X / Twitter' if k == 'twitter' else PLAT[k]['label'] for k in other])
    ax.invert_yaxis()
    ax.set_xlim(0, 172)
    ax.set_xticks([0, 50, 100, 150])
    for i, k in enumerate(other):
        ax.text(int(PLAT[k]['n']) + 3, i, num(PLAT[k]['n']), va='center', fontsize=10.5)
    ax.set_title('Ostali mediji i platforme', loc='left', fontsize=12, color=INK, pad=14)
    ax.set_xlabel('Broj tekstova i objava', labelpad=8)
    ax.grid(axis='x', alpha=.17)
    ax.set_axisbelow(True)
    save_chart(fig, '03-mediji')

    keys = ['web', 'twitter', 'facebook', 'print', 'comment']
    arr = np.array([[float(profile('platform', k, t)['percent']) for k in keys] for t in TOPICS])
    fig, ax = plt.subplots(figsize=(7.1, 5.35), layout='constrained')
    ax.imshow(arr, cmap=cmap, vmin=0, vmax=35, aspect='auto')
    ax.set_yticks(range(10), [wrap(TOP[t]['label']) for t in TOPICS])
    ax.set_xticks(range(5), ['Web', 'X / Twitter', 'Facebook', 'Tisak', 'Komentari'])
    ax.tick_params(axis='both', length=0, pad=8)
    for i in range(10):
        for j in range(5):
            ax.text(j, i, dec(arr[i, j]) + '%', ha='center', va='center', fontsize=10.8,
                    color='white' if arr[i, j] >= 22 else INK)
    save_chart(fig, '04-teme-mediji')


def make_pages():
    page('Ključni nalazi', 'Politički identitet, vrijednosti i javni argumenti', [
        p('Demokršćanstvo se u analiziranim medijskim tekstovima pojavljuje kao političko određenje, skup vrijednosti i način obrazlaganja društvenih odluka. Rasprava se kreće od pitanja tko pripada toj tradiciji do toga što ona znači za rad, obitelj, savjest i europsku suradnju.'),
        h('Politička pripadnost zauzima središnje mjesto'),
        p(f'Četiri teme povezane s političkom pripadnošću, domoljubljem, HDZ-ovim identitetom i desnim centrom zajedno obuhvaćaju {num(IDENTITY)} tekstova i objava, odnosno {share(IDENTITY, N)}% analiziranog materijala. Demokršćansko ime služi predstavljanju vlastitog položaja, traženju političkih saveznika i povlačenju granice prema drugim opcijama.', source='topic_sensitivity.csv: publications t01-t04; qualitative_review.md'),
        h('Vrijednosti su i zajednički jezik i povod za spor'),
        p(f'Tema vrijednosti i svjetonazorskih prijepora obuhvaća {num(TOP["t09"]["n"])} tekstova i objava ({dec(TOP["t09"]["percent"])}%). U raspravi se susreću pozivi na obitelj, nacionalni identitet i savjest, ali i prigovori da političari ne postupaju u skladu s načelima na koja se pozivaju.', source='topic_sensitivity.csv: publications t09; development t05/t09 and 139'),
        h('Socijalna načela dobivaju konkretan sadržaj'),
        p('Solidarnost se povezuje s položajem radnika i europskom suradnjom, opće dobro sa zapošljavanjem i političkom odgovornošću, a supsidijarnost s odnosima između razina vlasti. Takvi primjeri otvaraju sadržaj demokršćanstva izvan same stranačke oznake.', source='development_review.json: 104,111,119,125'),
        Takeaway('U raspravi se istodobno pregovara o pripadnosti tradiciji i o tome što njezina načela traže od politike.'),
        cap('U izvještaju: pregled tema, tri mjesečna portreta, primjeri društvenih načela te prikaz medija i platformi na kojima se rasprava pojavljuje.'),
    ])

    page('O podacima', 'Kako su prikupljeni tekstovi', [
        p(f'Izvještaj se temelji na {num(N)} tekstova i objava koje je projekt DigiKat izdvojio iz materijala prikupljenog praćenjem medija. Obuhvaćeno je razdoblje od 1. siječnja 2021. do 10. rujna 2026.', source='summary.json; base summary data_from/data_through'),
        h('Od medijske objave do tematskog pregleda'),
        table([
            ['Korak', 'Što to znači'],
            ['Prikupljanje', 'Polazište su članci s mrežnih stranica, objave na društvenim mrežama, komentari, forumi te tekstovi iz tiska, radija i televizije.'],
            ['Pretraživanje', 'U naslovima i tekstovima traže se spominjanja demokršćanstva i povezana obrazlaganja javnih pitanja kroz kršćanske društvene ideje.'],
            ['Povezivanje sadržaja', 'Tekstovi su računalno raspoređeni u deset tematskih skupina. Čitanje odabranih primjera daje tim skupinama sadržaj i pokazuje o čemu se u raspravi govori.'],
            ['Prikaz rezultata', 'Brojevi pokazuju koliko je analiziranih tekstova i objava povezano s pojedinom temom. Primjeri približavaju konkretne izjave i argumente.'],
        ], [.25, .75]), Spacer(1, 13),
        h('Što ulazi u priču o demokršćanstvu'),
        p('Obuhvaćeni su tekstovi koji izričito govore o demokršćanstvu, ali i oni koji kršćanska društvena načela povezuju s političkim i društvenim pitanjima. Zbog toga se uz stranke i izbore pojavljuju rad, dostojanstvo osobe, obitelj, savjest, socijalni nauk i europska solidarnost.'),
        p('U materijalu su zastupljeni različiti glasovi: političari, novinari, stručnjaci, crkveni predstavnici i sudionici mrežnih rasprava. Njihove izjave uključuju podršku, objašnjavanje, kritiku i osporavanje demokršćanskog identiteta.'),
        cap('Izvor: medijski materijal projekta DigiKat. Razdoblje: 1. 1. 2021. - 10. 9. 2026. U nastavku se izraz „tekstovi i objave” odnosi na analizirani materijal.'),
    ])

    portraits = [
        ('2021-05', 'Svibanj 2021. | izbori i vjerodostojnost identiteta',
         'Predizborne rasprave povezuju demokršćanstvo s domoljubljem, državotvornošću i narodnjaštvom. Andrej Plenković poziva se na načela koja pripisuje Tuđmanovu HDZ-u, dok Zlatko Hasanbegović osporava vjerodostojnost Plenkovićeva demokršćanskog identiteta. U drugim se tekstovima otvara pitanje udaljava li se HDZ od očekivanja svojeg biračkog tijela. Demokršćanstvo tako postaje jezik borbe za političko nasljeđe: jedni njime naglašavaju kontinuitet, a drugi tvrde da je taj kontinuitet prekinut. Uz hrvatsku izbornu raspravu pojavljuju se i prava te položaj Hrvata u Bosni i Hercegovini.'),
        ('2022-06', 'Lipanj 2022. | otvorenost stranke i spor oko obitelji',
         'Tekstovi o HDZ-u prenose poruke o novom vodstvu, desnom centru i demokršćanskim vrijednostima. U stranačkom predstavljanju domoljublje i državotvornost stoje uz rad, solidarnost, toleranciju i otvorenost prema svijetu. Istodobno Ivan Penava kritizira stranački program, tvrdeći da se udaljava od obitelji kao jezgre demokršćanskog svjetonazora. Spor se zato vodi i oko širine političke ponude i oko granica prihvatljivog društvenog programa. Ista tradicija služi kao argument za otvorenost, ali i kao mjerilo prema kojem protivnici ocjenjuju stranačku dosljednost.'),
        ('2024-06', 'Lipanj 2024. | Europa, nacionalni interesi i solidarnost',
         'U kampanji za Europski parlament demokršćanske vrijednosti povezuju se s nacionalnim interesima, suverenizmom i položajem Hrvatske u europskoj obitelji. Od kandidata se traži sposobnost pregovaranja o hrvatskim prioritetima. Davor Ivo Stier pritom naglašava Europu solidarnosti i tvrdi da takva suradnja Hrvatskoj omogućuje rast i razvoj. Demokršćanstvo se u tim porukama predstavlja kao veza između nacionalne pripadnosti i europske suradnje. Uz kampanjske izjave pojavljuju se i šire rasprave o povijesnom nasljeđu te budućnosti demokršćanske ideje.'),
    ]
    items = [p('Tri mjeseca s velikim brojem tekstova približavaju različite povode za raspravu. Svaki donosi više glasova i nekoliko povezanih pitanja o tome što demokršćanstvo znači u političkom životu.')]
    for month, title, body in portraits:
        items += [h(title), cap(f'{num(EPISODES[month]["publications"])} tekstova i objava u tom mjesecu'),
                  p(body, source=f'episode_review.json: {month}; development t05 for June 2022')]
    page('Tri vremenska portreta', 'Iza vrha nije nužno jedan razgovor', items)

    page('Tematska karta', 'Politički položaj ostaje u središtu karte', [
        p('Najviše tekstova okuplja se oko političke pripadnosti. Odmah uz nju stoje vrijednosti i svjetonazorski prijepori te odnos HDZ-a prema demokršćanskom identitetu.'),
        chart('01-teme', 401),
        cap(f'Udio svake teme među {num(N)} analiziranih tekstova i objava. Uz svaki stupac naveden je i broj tekstova. Jedna objava ostaje izvan deset prikazanih tema.'),
        p(f'Politička pripadnost i ideje obuhvaćaju {num(TOP["t01"]["n"])} tekstova, vrijednosti i prijepori {num(TOP["t09"]["n"])} tekstova, a HDZ-ov demokršćanski identitet {num(TOP["t03"]["n"])}. U toj se raspravi političko predstavljanje susreće s pitanjem odgovara li djelovanje aktera vrijednostima koje ističu.', source='topic_sensitivity.csv: publications t01,t09,t03; topic_content_review.csv'),
        p('Ostatak karte otvara obitelj, Europu, izbore, međunarodnu politiku i idejnu povijest. Medijski govor o demokršćanstvu tako povezuje dnevne političke sporove sa širim pitanjima društvenog uređenja.'),
    ])

    page('Pripadnost i politički identitet', 'Tko se poziva na demokršćanstvo i zašto', [
        p('Demokršćanski identitet u tekstovima ima nekoliko uloga. Političari njime opisuju vlastitu stranku, traže srodne partnere ili objašnjavaju zašto se od određene političke opcije udaljavaju. Protivnici isti naziv koriste kako bi propitali vjerodostojnost takvog predstavljanja.'),
        table([['Tema', 'Tekstovi i objave', 'Udio'],
               *[[TOP[t]['label'], num(TOP[t]['n']), dec(TOP[t]['percent']) + '%'] for t in ('t01', 't02', 't03', 't04')],
               ['Zajedno', num(IDENTITY), share(IDENTITY, N) + '%']], [.57, .24, .19]), Spacer(1, 12),
        h('Nasljeđe i kontinuitet'),
        p('Niz domoljublje, državotvornost, narodnjaštvo i demokršćanstvo povezuje suvremeno stranačko predstavljanje s povijesnim nasljeđem. U porukama HDZ-a taj niz opisuje temeljna načela stranke i njezinu vezu s hrvatskim nacionalnim interesima.', source='episode_review.json: 2021-05; pair_review.json domoljublje pairs'),
        h('Suradnja i političke granice'),
        p('Pozivanje na demokršćanski svjetonazor pojavljuje se i pri traženju suradnje na desnom centru. Zajedničko ime tada označuje krug mogućih partnera. U drugim izjavama ono služi upravo razgraničenju: netko može poštovati demokršćanska načela, a ipak ne smatrati da pripada toj političkoj tradiciji.', source='topic_content_review.csv: t04; development t05 Bilić and 1,3,4'),
        Takeaway('Demokršćansko ime može biti poziv na zajedništvo, ali i predmet spora o tome tko ga uvjerljivo zastupa.'),
    ])

    page('Teme kroz godine', 'Različite godine, različite teme', [
        p('Prikaz pokazuje koje su teme zastupljene među analiziranim tekstovima pojedine godine. Tamnija boja znači veći udio: 25% znači da je toj temi pripala četvrtina tekstova iz te godine.'),
        chart('02-godine', 385),
        cap('Postoci se čitaju unutar svake godine. Razdoblje za 2026. završava 10. rujna.'),
        p(f'U tekstovima iz 2022. najzastupljenija je tema HDZ-a i demokršćanskog identiteta ({dec(profile("year", "2022", "t03")["percent"])}%). U tekstovima iz 2024. ističu se Europa i kršćanski korijeni ({dec(profile("year", "2024", "t06")["percent"])}%), a u onima iz 2025. vrijednosti i svjetonazorski prijepori ({dec(profile("year", "2025", "t09")["percent"])}%).', source='topic_profiles.csv: year'),
        p('Ti naglasci povezuju tematsku kartu s konkretnim raspravama: stranačkim identitetom, europskom kampanjom te pitanjima vrijednosti. Demokršćanstvo se u različitim tekstovima pojavljuje kroz različite javne povode.'),
    ])

    page('Jezik vrijednosti', 'Riječi koje povezuju raspravu', [
        p('Pojmovi uz demokršćanstvo pokazuju koje se ideje dovode u vezu. U istim se rečenicama susreću nacionalna pripadnost, politička tradicija, savjest i solidarnost. Značenje tih veza postaje jasnije kada se prati što sudionici njima žele reći.'),
        table([
            ['Povezani pojmovi', 'Što se kroz njih raspravlja'],
            ['Domoljublje + narodnjaštvo', 'Pripadnost političkoj tradiciji i predstavljanje temeljnih stranačkih vrijednosti.'],
            ['Domoljublje + državotvornost', 'Odnos prema državi, nacionalnim interesima i povijesnom nasljeđu.'],
            ['Demokršćanstvo + konzervativizam', 'Sličnosti, razlike i granice između političkih tradicija.'],
            ['HDZ + savjest', 'Priziv savjesti, političke odluke i pozivi biračima da glasaju prema svojoj savjesti.'],
            ['Europa + solidarnost', 'Suradnja među članicama, pripadnost europskoj zajednici i mogućnosti razvoja.'],
        ], [.38, .62]), Spacer(1, 13),
        h('Iste riječi sudjeluju u različitim argumentima'),
        p('Domoljublje i demokršćanstvo mogu se pojaviti u predstavljanju stranačkih načela, ali i u prigovoru da ih stranka napušta. Savjest se povezuje i s konkretnim pitanjem priziva savjesti i s osobnom odgovornošću pri političkom izboru. U raspravama o Europi solidarnost dobiva značenje suradnje i zajedničkog razvoja.', source='lexical_pairs.csv: five selected pairs; pair_review.json; qualitative_review.md'),
        Takeaway('Vrijednosni rječnik povezuje sudionike rasprave, čak i kada se razilaze oko političkih zaključaka.'),
    ])

    page('Načela u društvenim pitanjima', 'Od vrijednosti do konkretnog zahtjeva', [
        p('U dijelu tekstova načela postaju obrazloženje određenog stava ili prijedloga. Sljedeći primjeri pokazuju kako se govor o demokršćanstvu i kršćanskim društvenim idejama veže uz svakodnevna javna pitanja.'),
        h('Rad i solidarnost | svibanj 2026.'),
        p('U čestitki za Praznik rada Andrej Plenković povezuje kršćansko načelo solidarnosti i dostojanstvo radnika s gospodarskim jačanjem Hrvatske i većom produktivnošću. Radnici i radnice pritom su pozvani na zajedničko djelovanje s Vladom. Solidarnost je dio političkog obrazloženja odnosa prema radu i razvoju.', source='development_review.json: 104'),
        h('Opće dobro i zapošljavanje | travanj 2024.'),
        p('Tekst o političkom djelovanju polazi od dostojanstva osobe i općeg dobra kako bi kritizirao stranački probitak i ideološku isključivost. Iz tih načela izvodi zahtjev za slobodom izražavanja i zapošljavanjem prema stručnosti i sposobnosti. Kršćanske društvene ideje služe kao mjerilo postupanja u javnom životu.', source='development_review.json: 111'),
        h('Supsidijarnost i vlast | veljača 2021.'),
        p('Politolog Jakov Žižić u razgovoru s Matom Mijićem objašnjava demokršćanstvo kroz zajednicu, solidarnost i raspodjelu vlasti. Supsidijarnost povezuje s lokalnom i regionalnom samoupravom te europskim institucijama. Time raspravu o identitetu premješta na pitanje gdje se i na kojoj razini donose odluke.', source='development_review.json: 125'),
        h('Savjest i politička odluka | travanj 2022.'),
        p('Plenković se poziva na demokršćanske vrijednosti kada obrazlaže stav HDZ-a da neće zabranjivati priziv savjesti. Načelo se ovdje veže uz određen politički izbor i javni spor. Pozivanje na tradiciju dobiva prepoznatljivu sadržajnu posljedicu.', source='development_review.json: 139'),
        cap('Primjeri su prepričani prema analiziranim medijskim tekstovima. Imena i datumi omogućuju praćenje povoda rasprave.'),
    ])

    page('Različiti glasovi', 'Kritika aktera ne znači odbacivanje tradicije', [
        p('Odnos prema demokršćanstvu i odnos prema stranci koja se njime predstavlja mogu se razlikovati. U tekstovima se ta razlika vidi kroz poštovanje načela, osobno političko određenje i kritiku stranačkog djelovanja.'),
        h('Poštovanje načela uz drukčiju političku pripadnost'),
        p('Samir Haj Barakat nakon izlaska iz SDP-a u kolovozu 2024. objašnjava da poštuje demokršćanska načela, ali ne pripada demokršćanskom političkom spektru. Ujedno odbacuje pretpostavku da njegov odlazak znači prelazak u HDZ. Njegova izjava razdvaja odnos prema ideji od odluke o stranačkom članstvu.', source='development_review.json: 1,3,4'),
        h('Demokršćanski svjetonazor uz odbacivanje HDZ-a'),
        p('U jednoj mrežnoj raspravi iz travnja 2024. sudionik se određuje kao demokršćanin, a istodobno snažno kritizira HDZ i želi njegov odlazak s vlasti. Vlastitu pripadnost tradiciji ne vezuje uz podršku stranci. Demokršćanski identitet u takvom iskazu postaje polazište za politički izbor koji se protivi HDZ-u.', source='development_review.json: 133'),
        h('Spor oko dosljednosti'),
        p('Kritike poput Penavine u lipnju 2022. polaze od tvrdnje da obitelj treba biti središnji dio demokršćanskog svjetonazora. Stranački se program zatim prosuđuje prema tom očekivanju. Sudionici se tako mogu pozivati na istu tradiciju, a iz nje izvoditi različite zahtjeve prema politici.', source='development_review.json: t05 typical June 2022'),
        Takeaway('Pripadnost ideji, podrška stranci i ocjena njezina djelovanja tri su različita odnosa u istoj javnoj raspravi.'),
    ])

    page('Mediji i platforme', 'Mrežni mediji nose najveći dio materijala', [
        p(f'Na mrežne stranice otpada {num(PLAT["web"]["n"])} tekstova, odnosno {dec(PLAT["web"]["percent"])}% analiziranog materijala. Slijede X / Twitter s {num(PLAT["twitter"]["n"])} objava i Facebook sa {num(PLAT["facebook"]["n"])}. Prisutni su i tisak, komentari čitatelja te radijski i televizijski tekstovi.', source='platforms.csv'),
        chart('03-mediji', 311),
        cap('Lijevo je izdvojen udio mrežnih stranica. Stupci prikazuju broj tekstova i objava u ostalim medijima i na platformama.'),
        h('Rasprava prolazi kroz više medijskih oblika'),
        p('Vijesti prenose političke izjave i kampanjske poruke, razgovori otvaraju idejne razlike, a mrežne objave i komentari daju prostor osobnom određenju i kritici. U tim se oblicima susreću službeno predstavljanje političara, novinarski prikaz i reakcije sudionika rasprave.', source='development_review.json: mixed-platform examples; episode_review.json'),
        p('Zato pregled medija dopunjuje pregled tema. Ista demokršćanska oznaka može se pojaviti u stranačkoj poruci, stručnom razgovoru, vijesti o javnom nastupu ili komentaru koji osporava političku vjerodostojnost.'),
    ])

    page('Teme prema medijima', 'Na platformama se ističu različiti naglasci', [
        p('Svaki stupac pokazuje kako su teme raspoređene među analiziranim tekstovima tog medija ili platforme. Primjerice, 30% znači približno tri od deset tekstova. Prikazano je pet skupina s najviše materijala.'),
        chart('04-teme-mediji', 380),
        cap('Udio tema unutar pojedinog medija ili platforme. Tamnija boja označuje veću zastupljenost.'),
        p(f'Na X-u / Twitteru ističu se domoljublje i državotvornost ({dec(profile("platform", "twitter", "t02")["percent"])}%) te HDZ-ov identitet ({dec(profile("platform", "twitter", "t03")["percent"])}%). Na Facebooku najzastupljenija je tema desnog centra i suradnje stranaka ({dec(profile("platform", "facebook", "t04")["percent"])}%). U komentarima je na prvom mjestu odnos HDZ-a i demokršćanskog identiteta ({dec(profile("platform", "comment", "t03")["percent"])}%).', source='topic_profiles.csv: platform'),
        p('Na mrežnim stranicama rasprava se širi preko svih prikazanih tema. Uz političko pozicioniranje nalaze se obitelj, europska pitanja, idejna tradicija i međunarodna politika.'),
    ])

    page('Europa i idejna tradicija', 'Od europske obitelji do društvenog uređenja', [
        p(f'Europa i kršćanski korijeni čine zasebnu temu s {num(TOP["t06"]["n"])} tekstova i objava ({dec(TOP["t06"]["percent"])}%). Idejna tradicija i javne rasprave okupljaju još {num(TOP["t08"]["n"])} ({dec(TOP["t08"]["percent"])}%). U tim se tekstovima demokršćanstvo razmatra kao političko nasljeđe, ali i kao odgovor na pitanja suvremenog društva.', source='topic_sensitivity.csv: publications t06,t08'),
        h('Europa kao prostor solidarnosti'),
        p('U lipnju 2024. Stier demokršćansku Europu opisuje kroz solidarnost i suradnju. Taj koncept povezuje s hrvatskim razvojem i pripadnošću europskoj zajednici, a suprotstavlja ga politikama koje naziva sebičnima. Nacionalni interes i europska povezanost u njegovu se argumentu međusobno podupiru.', source='development_review.json: 119; episode_review.json: 2024-06'),
        h('Demokršćanstvo i konzervativizam'),
        p('U razgovoru iz veljače 2021. Žižić razliku između demokršćanstva i liberalnog konzervativizma objašnjava odnosom prema zajednici. Demokršćanstvu pripisuje snažniji naglasak na solidarnosti i djelovanju za zajedničku dobrobit. Takva rasprava otvara socijalna i gospodarska pitanja koja se lako izgube kada se političke tradicije svode na položaj na ljevici ili desnici.', source='development_review.json: 125'),
        h('Knjige i javni razgovori šire prostor teme'),
        p('Izvještaji o predstavljanju zbornika „Demokršćanstvo: izvori, postignuća i perspektive” u siječnju 2023. prenose raspravu o odnosu demokršćanstva prema državi, drugim političkim idejama i Europi. Uz dnevnu politiku tako se pojavljuje i pitanje kako razumjeti povijest te društvene mogućnosti te tradicije.', source='development_review.json: t08 typical January 2023, excluding flagged index 74'),
        Takeaway('Europska i idejna dimenzija povezuju demokršćanstvo s pitanjima solidarnosti, zajednice i uređenja vlasti.'),
    ])

    page('Završni pogled', 'Tradicija čije se značenje pregovara u javnosti', [
        p('Analizirani tekstovi prikazuju demokršćanstvo kao živ dio političkog jezika. Njegovo se ime koristi u stranačkom predstavljanju, izbornom nadmetanju i sporovima oko vjerodostojnosti. Istodobno služi objašnjavanju društvenih načela i promišljanju odnosa pojedinca, zajednice i vlasti.'),
        h('Politička oznaka ima sadržajne posljedice'),
        p('Kada se akter odredi kao demokršćanin, otvara se i pitanje što takvo određenje podrazumijeva. Rasprave o obitelji, radu, savjesti i Europi pokazuju kako se od imena tradicije dolazi do očekivanja prema javnom djelovanju.'),
        h('Zajedničke vrijednosti ne uklanjaju neslaganje'),
        p('Solidarnost, dostojanstvo, domoljublje i opće dobro mogu biti točke prepoznavanja, ali i mjerila kritike. Sudionici se razilaze oko njihova značenja, političkih posljedica i toga tko ih dosljedno zastupa. U tome se vidi važan dio medijskog života demokršćanstva.'),
        h('Medijski prostor povezuje više vrsta razgovora'),
        p('Uz kampanjske poruke i stranačke polemike postoje stručna objašnjenja, prikazi knjiga, crkveni društveni argumenti i osobni stavovi na mrežama. Zajedno otvaraju raspravu koja seže od političke pripadnosti do načina na koji bi društvo trebalo biti uređeno.'),
        Takeaway('Demokršćanstvo u medijskom prostoru povezuje pitanje „tko smo” s pitanjem „kako trebamo djelovati”.'),
        Spacer(1, 10),
        cap('DigiKat | Prikaz i analiza katoličke tematike u digitalnom medijskom prostoru\nHrvatsko katoličko sveučilište\nDemokršćanstvo u medijskom prostoru | 19. rujna 2026.'),
        Paragraph('<link href="https://lusiki.github.io/DigiKat/" color="#a9643b"><u>Više o projektu DigiKat</u></link>', ST['small']),
    ])


def cover(c):
    c.setFillColor(colors.HexColor(PAPER))
    c.rect(0, 0, W, H, fill=1, stroke=0)
    c.setFillColor(colors.HexColor(INK))
    c.rect(0, 267, W, H - 267, fill=1, stroke=0)
    c.setFillColor(colors.HexColor(GOLD))
    c.setFont('BodyBold', 10)
    c.drawString(M, H - 62, 'DIGIKAT   /   ANALITIČKI IZVJEŠTAJ')
    c.setFillColor(colors.white)
    c.setFont('Display', 37)
    c.drawString(M, H - 153, 'Demokršćanstvo')
    c.setFont('Display', 32)
    c.drawString(M, H - 201, 'u medijskom prostoru')
    c.setFont('Body', 17)
    c.setFillColor(colors.HexColor('#e1ebe5'))
    c.drawString(M, H - 248, 'Identitet, vrijednosti i društvena pitanja')
    c.setStrokeColor(colors.HexColor(GOLD))
    c.setLineWidth(1.5)
    c.line(M, H - 280, M + 80, H - 280)
    c.setFont('Body', 12)
    c.setFillColor(colors.white)
    c.drawString(M, H - 315, 'Tekstovi i objave od 1. 1. 2021. do 10. 9. 2026.')
    c.drawString(M, H - 337, '19. rujna 2026.')
    c.setFont('BodyBold', 13)
    c.drawString(M, H - 380, 'Luka Šikić')
    c.linkURL('https://www.lukasikic.info/', (M, H-384, M+100, H-365), relative=0)
    c.setFont('Body', 10)
    c.drawString(M, H - 399, 'www.lukasikic.info')
    c.linkURL('https://www.lukasikic.info/', (M, H-403, M+110, H-388), relative=0)
    for x, val, label in [(M, num(N), 'tekstova i objava'), (M + 185, str(len(TOPICS)), 'tematskih skupina'), (M + 352, '2021. - 2026.', 'promatrano razdoblje')]:
        c.setFillColor(colors.HexColor(GOLD))
        c.setFont('Display', 25 if x < M + 300 else 19)
        c.drawString(x, 340, val)
        c.setFillColor(colors.white)
        c.setFont('Body', 10)
        c.drawString(x, 319, label)
    headline = p('Kako se demokršćanstvo pojavljuje u političkim porukama, javnim raspravama i društvenim pitanjima.', 'h1')
    _, height = headline.wrap(CW, 200)
    headline.drawOn(c, M, 229 - height)
    sub = p('Politička pripadnost. Sporovi oko vrijednosti. Solidarnost, savjest i zajednica.', 'body')
    _, height = sub.wrap(CW, 80)
    sub.drawOn(c, M, 111 - height)
    c.setFont('Body', 9)
    c.setFillColor(colors.HexColor(MUTED))
    c.drawString(M, 29, 'DigiKat | Hrvatsko katoličko sveučilište')

def frame(c, number, kicker, total):
    c.setFillColor(colors.HexColor(PAPER))
    c.rect(0, 0, W, H, fill=1, stroke=0)
    c.setFillColor(colors.HexColor(COPPER))
    c.setFont('BodyBold', 9.2)
    c.drawString(M, H - 36, f'{number:02d}  /  {kicker.upper()}')
    c.setStrokeColor(colors.HexColor(LINE))
    c.setLineWidth(.6)
    c.line(M, 44, W - M, 44)
    c.setFillColor(colors.HexColor(MUTED))
    c.setFont('Body', 8.2)
    c.drawString(M, 29, 'DIGIKAT  /  DEMOKRŠĆANSTVO U MEDIJSKOM PROSTORU  /  19. 9. 2026.')
    c.drawRightString(W - M, 29, f'{number} / {total}')

def main():
    make_figures()
    make_pages()
    c = canvas.Canvas(str(PDF), pagesize=A4, pageCompression=1, invariant=1, lang='hr-HR')
    c.setTitle('Demokršćanstvo u medijskom prostoru')
    c.setAuthor('Luka Šikić')
    c.setSubject('Identitet, vrijednosti i društvena pitanja u medijskim tekstovima od 2021. do 2026.')
    c.setViewerPreference('DisplayDocTitle', 'true')
    c.bookmarkPage('cover')
    c.addOutlineEntry('Naslovnica', 'cover', 0)
    cover(c)
    c.showPage()
    layout = []
    for number, (kicker, title, items) in enumerate(PAGES, 2):
        height = sum(obj.getSpaceBefore() + obj.wrap(CW, 10000)[1] + obj.getSpaceAfter() for obj in items)
        available = H - 61 - 60
        if height > available:
            raise ValueError(f'Page {number} ({title}): {height:.1f}pt > {available:.1f}pt')
        frame(c, number, kicker, len(PAGES) + 1)
        c.bookmarkPage('p' + str(number))
        c.addOutlineEntry(title, 'p' + str(number), 0)
        y = H - 61
        for obj in items:
            y -= obj.getSpaceBefore()
            _, hgt = obj.wrap(CW, 10000)
            y -= hgt
            obj.drawOn(c, M, y)
            y -= obj.getSpaceAfter()
        layout.append({'page': number, 'title': title, 'height': height, 'bottom_y': y})
        c.showPage()
    c.save()
    (QA / 'layout.json').write_text(json.dumps(layout, ensure_ascii=False, indent=2), encoding='utf-8')
    (OUT / 'claim_sources.json').write_text(json.dumps(CLAIMS, ensure_ascii=False, indent=2), encoding='utf-8')
    used = ['summary.json', 'topic_sensitivity.csv', 'topic_profiles.csv', 'platforms.csv',
            'episode_selection.csv', 'lexical_pairs.csv', 'qualitative_review.md']
    metadata = {
        'edition': 'public-v2', 'pages': len(PAGES) + 1, 'records': N,
        'source_hashes': {name: hashlib.sha256((DATA / name).read_bytes()).hexdigest() for name in used},
        'pdf_sha256': hashlib.sha256(PDF.read_bytes()).hexdigest(),
        'builder_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'original_technical_pdf_sha256': hashlib.sha256((ROOT / 'output/pdf/demokrscanstvo-analiticki-izvjestaj.pdf').read_bytes()).hexdigest(),
    }
    (OUT / 'build.json').write_text(json.dumps(metadata, indent=2), encoding='utf-8')
    print(json.dumps({'pdf': str(PDF), 'pages': len(PAGES) + 1, 'lowest_bottom': min(p['bottom_y'] for p in layout)}, ensure_ascii=False))

if __name__ == '__main__':
    main()
