"""Build the public 18-slide carousel from versioned public evidence.

Run from the repository root. The HTML is the single source for screen and PDF.
No private corpus, analytical model or existing report is modified.
"""
from collections import Counter, defaultdict
from html import escape as esc
from pathlib import Path
import csv
import hashlib
import json
import re
from conference.theme import apply_conference_theme, CONFERENCE

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
OUT = ROOT / 'output/demokrscanstvo-carousel'
OUT.mkdir(parents=True, exist_ok=True)
STEM = 'demokrscanske-vrijednosti-karusel'
TITLE = ('Demokršćanske vrijednosti u digitalnom javnom prostoru: narativni okviri '
         'hrvatskih katoličkih medija od 2021. do 2026.')
AUTHOR = 'Luka Šikić'
BASE = 'https://lusiki.github.io/DigiKat/'
PAGE = BASE + 'pages/demokrscanstvo/index.html'
OVERVIEW = BASE + 'assets/izvjestaji/demokrscanstvo-u-medijskom-prostoru.html'
LANGUAGE = BASE + 'assets/izvjestaji/demokrscanstvo-od-rijeci-do-argumenta.html'
BARAKAT = 'https://www.glas-slavonije.hr/osijek/2024/08/29/vijecnik-haj-barakat-napustio-sdp-osjecam-da-ovdje-nisam-bio-dobrodosao-567954/'
CONSCIENCE = 'https://vlada.gov.hr/vijesti/aktualno-prijepodne-zahtjev-za-pomilovanjem-perkovica-i-mustaca-orkestrirana-akcija/35261'
STIER = 'https://www.tportal.hr/vijesti/clanak/stier-hdz-za-demokrscansku-europu-kakvu-je-zagovarao-ivan-pavao-ii-20240607'

INPUTS = [
    'data/digikat_corpus_manifest.json',
    'data/barometar/demokrscanstvo-multiplatform/v1/summary.json',
    'data/barometar/demokrscanstvo-themes/v1/topics.csv',
    'data/barometar/demokrscanstvo-themes/v1/topic_monthly.csv',
    'studies/demokrscanstvo-barometar/text-public/manuscript.md',
    'assets/izvjestaji/demokrscanstvo-od-rijeci-do-argumenta.meta.json',
]
readjson = lambda p: json.loads((ROOT / p).read_text(encoding='utf-8'))
rows = lambda p: list(csv.DictReader((ROOT / p).open(encoding='utf-8-sig')))
num = lambda n: f'{int(n):,}'.replace(',', '.')
pct = lambda n, d: f'{100 * n / d:.1f}'.replace('.', ',') + ' %'
corpus = readjson(INPUTS[0])['corpus']
summary = readjson(INPUTS[1])
topics = {r['topic']: r for r in rows(INPUTS[2])}
monthly = rows(INPUTS[3])
manuscript = (ROOT / INPUTS[4]).read_text(encoding='utf-8')
textmeta = readjson(INPUTS[5])
TOTAL = summary['matching_records']
TEXTS = textmeta['texts']
WORDS = {k: int(v.replace('.', '')) for k, v in re.findall(
    r'^\| (vrijednost|solidarnost|savjest|supsidijarnost) \| ([\d.]+) \|', manuscript, re.M)}
assert set(WORDS) == {'vrijednost', 'solidarnost', 'savjest', 'supsidijarnost'}
identity = ['t01', 't02', 't03', 't04']
identity_n = sum(int(topics[t]['records']) for t in identity)
platforms = {p['platform']: p for p in summary['platforms']}
year_counts = defaultdict(Counter)
platform_counts = defaultdict(Counter)
for row in monthly:
    n = int(row['records'])
    year_counts[row['month'][:4]][row['topic']] += n
    platform_counts[row['platform']][row['topic']] += n

claims = []
def claim(key, n, denominator, source):
    claims.append(dict(key=key, value=n, denominator=denominator, source=source))
    return n

def a(url, text, cls=''):
    return f'<a class="{cls}" href="{esc(url, quote=True)}">{text}</a>'

def bars(data, denominator, source, ceiling=None):
    top = ceiling or max(n for _, n in data)
    output = '<div class="bars">'
    for label, n in data:
        claim(label, n, denominator, source)
        output += (f'<div class="bar"><div class="bar-label"><span>{esc(label)}</span>'
                   f'<strong>{num(n)} <small>{pct(n, denominator)}</small></strong></div>'
                   f'<div class="bar-track" aria-hidden="true"><span style="width:{100*n/top:.4f}%"></span></div></div>')
    return output + '</div>'

def statistic(n, label, extra='', cls=''):
    return f'<div class="stat {cls}"><strong>{n}</strong><span>{label}</span>{f"<p>{extra}</p>" if extra else ""}</div>'

def resource(url, title, desc):
    return f'<div class="resource"><h3>{a(url, title)}</h3><p>{desc}</p></div>'

slides = []
def slide(kind, chapter, title, body, source, url):
    slides.append(dict(kind=kind, chapter=chapter, title=title, body=body, source=source, url=url))

slide('cover dark', 'DigiKat', TITLE,
      '<div class="cover-title"><h1>Demokršćanske vrijednosti<br>u digitalnom javnom prostoru:</h1>'
      '<p class="cover-subtitle">narativni okviri hrvatskih<br>katoličkih medija od 2021. do 2026.</p></div>'
      '<div class="cover-author"><p>Doc. dr. sc. Luka Šikić</p>'
      '<span>Hrvatsko katoličko sveučilište</span></div>',
      'Podaci barometra do 10. rujna 2026.', PAGE)

slide('project', 'Projekt i podaci', 'DigiKat istražuje katoličke teme u javnosti',
      '<p class="lead narrow">Projekt Hrvatskoga katoličkog sveučilišta prati kako mediji govore '
      'o katoličkim temama i kako te teme žive u digitalnom javnom prostoru.</p>'
      '<div class="editorial-columns"><div><h3>Medijski prostor</h3><p>Tko objavljuje, o čemu govori '
      'i koje sadržaje publika prati?</p></div><div><h3>Jezik rasprave</h3><p>Kako se povezuju vjera, '
      'društvene vrijednosti i javna pitanja?</p></div></div>'
      '<p class="takeaway">Demokršćanstvo je jedna od tema kroz koje projekt povezuje medijski prostor i društvene ideje.</p>',
      'DigiKat. O projektu i istraživačkim pitanjima.', BASE + 'pages/about.html')

claim('Official DigiKat corpus', corpus['rows'], None, INPUTS[0])
claim('Official corpus platforms', corpus['platforms'], None, INPUTS[0])
slide('scope', 'Projekt i podaci', 'Katoličke teme u širem medijskom prostoru',
      '<div class="split"><div>' + statistic(num(corpus['rows']), 'objava u službenom korpusu DigiKata',
      f'{corpus["platforms"]} platformi<br>1. 1. 2021. – 11. 6. 2026.') + '</div>'
      '<div class="scope-copy"><h3>Posebna analiza demokršćanstva</h3><p>Barometar pretražuje širu medijsku '
      'arhivu i prati demokršćanske ideje te kršćansku socijalnu misao.</p>'
      '<p>Sljedeći nalazi uključuju katoličke i opće medije. Ne predstavljaju zasebnu analizu samo katoličkih nakladnika.</p></div></div>',
      'Službeni korpus DigiKata i dokumentacija barometra. Različiti obuhvati podataka.', BASE + 'pages/baza.html')

for label, n in [('Searchable archive', summary['eligible_records']), ('Selected publications', TOTAL), ('Distinct texts', TEXTS)]:
    claim(label, n, None, INPUTS[1] if label != 'Distinct texts' else INPUTS[5])
slide('selection', 'Projekt i podaci', 'Kako nastaje zbirka za ovu analizu',
      '<p class="lead">Izravno spominjanje demokršćanstva ili kršćanski utemeljen argument o javnom pitanju određuje ulazak u zbirku.</p>'
      '<ol class="selection-flow"><li><span>Pretraživa arhiva</span><strong>' + num(summary['eligible_records']) + '</strong>'
      '<p>zapisa na ' + str(summary['platform_count']) + ' platformi</p></li><li><span>Pregled medijskog prostora</span><strong>' + num(TOTAL) + '</strong>'
      '<p>uključenih objava</p></li><li><span>Analiza jezika</span><strong>' + num(TEXTS) + '</strong>'
      '<p>različita teksta</p></li></ol>'
      '<p class="takeaway">Za pregled brojimo objave. Za analizu jezika jednak tekst brojimo jednom.</p>'
      '<p class="note">Obuhvat arhive je od 1. 1. 2021. do 10. 9. 2026. Brojevi opisuju medijsku prisutnost, a ne potporu građana.</p>',
      'Barometar. Oba izvještaja čitaju istu zbirku iz različitih kutova.', PAGE + '#metoda')

largest = sorted((r for r in topics.values() if r['topic'] != 'unassigned'), key=lambda r:int(r['records']), reverse=True)[:4]
slide('explore', 'Projekt i podaci', 'Tri ulaza u istu medijsku raspravu',
      '<div class="split"><div class="explore-questions"><div><h3>O čemu se govori?</h3><p>Tematska karta povezuje objave sličnog rječnika.</p></div>'
      '<div><h3>Kada se govori?</h3><p>Mjesečni prikaz otkriva raspored pozornosti kroz vrijeme.</p></div>'
      '<div><h3>Gdje se govori?</h3><p>Filtri platforme i godine otkrivaju različite naglaske.</p></div></div>'
      '<div><p class="chart-label">Četiri najveće tematske skupine</p>' + bars([(r['label'], int(r['records'])) for r in largest], TOTAL, INPUTS[2]) + '</div></div>'
      '<p class="note">Računalne skupine opisuju sličnost sadržaja. Nazivi tema ne označuju slaganje s demokršćanstvom.</p>',
      'Interaktivni barometar. Teme, vrijeme i platforme.', PAGE + '#teme')

claim('Identity groups combined', identity_n, TOTAL, INPUTS[2])
slide('identity dark', 'Nalaz 01', 'Politička pripadnost zauzima polovicu prostora',
      '<div class="split"><div>' + statistic(pct(identity_n, TOTAL), 'objava u četiri teme političkog identiteta',
      f'{num(identity_n)} od {num(TOTAL)} objava') + '</div><div>'
      + bars([(topics[t]['label'], int(topics[t]['records'])) for t in identity], TOTAL, INPUTS[2]) + '</div></div>'
      '<p class="takeaway">Demokršćansko ime služi određivanju vlastitog položaja i granica političke pripadnosti.</p>',
      'Pregled medijskog prostora, str. 5–6. Svaka objava ima jednu glavnu temu.', OVERVIEW + '#p6')

slide('values', 'Nalaz 02', 'Vrijednosti su česte. Pojedina načela mnogo rjeđa.',
      '<div class="split"><div>' + bars([(w.capitalize(), WORDS[w]) for w in ['vrijednost', 'solidarnost', 'supsidijarnost']], TEXTS, INPUTS[4]) + '</div>'
      '<div class="reading-copy"><p class="large-copy">Opći govor o vrijednostima širi je od izričitog imenovanja solidarnosti i supsidijarnosti.</p>'
      '<p>Broji se riječ u rečenicama povezanima s temom, najviše jednom po tekstu.</p></div></div>'
      '<p class="note">Rjeđa riječ sama po sebi ne dokazuje odsutnost ideje. Usporedba opisuje izričiti rječnik.</p>',
      f'Od riječi do argumenta, str. 12. Nazivnik je {num(TEXTS)} različita teksta.', LANGUAGE + '#p12')

years_body = '<div class="year-stories">'
for year, t in [('2022', 't03'), ('2024', 't06'), ('2025', 't09')]:
    counts = year_counts[year]
    assert counts[t] == max(counts.values())
    n, denominator = counts[t], sum(counts.values())
    claim('Leading topic ' + year, n, denominator, INPUTS[3])
    label = {'t03':'HDZ i demokršćanski identitet', 't06':'Europa i kršćanski korijeni', 't09':'Vrijednosti i svjetonazorski prijepori'}[t]
    years_body += f'<div><p class="year">{year}.</p><h3>{label}</h3><strong>{pct(n, denominator)}</strong><p>objava te godine</p></div>'
years_body += '</div>'
slide('years', 'Nalaz 03', 'Različite godine otvaraju različita pitanja',
      '<p class="lead">Najzastupljenija tema mijenja se od stranačkog identiteta prema Europi i vrijednosnim sporovima.</p>'
      + years_body + '<p class="note">Udjeli se čitaju unutar godine. Obuhvat prikupljanja promijenio se u travnju 2024. Prikaz ne mjeri promjenu javne potpore.</p>',
      'Pregled medijskog prostora, str. 7. Godišnji sastav uključenih objava.', OVERVIEW + '#p7')

web_n = platforms['web']['matching_records']
claim('Web publications', web_n, TOTAL, INPUTS[1])
platform_body = '<div class="split"><div>' + statistic(pct(web_n, TOTAL), 'uključenih objava dolazi s weba', f'{num(web_n)} od {num(TOTAL)} objava') + '</div><div class="platform-stories">'
for platform, label, t in [('twitter','X / Twitter','t02'), ('facebook','Facebook','t04'), ('comment','Komentari','t03')]:
    n = platform_counts[platform][t]
    d = sum(platform_counts[platform].values())
    claim('Platform leading topic ' + platform, n, d, INPUTS[3])
    platform_body += f'<div><h3>{label} <span>{pct(n,d)}</span></h3><p>{topics[t]["label"]}</p></div>'
platform_body += '</div></div><p class="note">Desno su vodeće teme unutar manjih platformskih zbirki. Razdoblja i dostupnost teksta razlikuju se među platformama.</p>'
slide('platforms', 'Nalaz 04', 'Platforme otkrivaju različite naglaske', platform_body,
      'Pregled medijskog prostora, str. 11–12. Prikaz opisuje prikupljeni materijal.', OVERVIEW + '#p12')

slide('disagreement', 'Nalaz 05', 'Zajednička tradicija ostavlja prostor sporu',
      '<p class="lead">U lipnju 2022. demokršćanstvo ulazi u raspravu o širini stranačke ponude i dosljednosti programu.</p>'
      '<div class="editorial-columns"><div><h3>Stranačko predstavljanje HDZ-a</h3><p>Domoljublje i državotvornost stoje uz rad, solidarnost, toleranciju i otvorenost prema svijetu.</p></div>'
      '<div><h3>Penavina kritika programa</h3><p>Ivan Penava tvrdi da se stranka udaljava od obitelji kao jezgre demokršćanskog svjetonazora.</p></div></div>'
      '<p class="takeaway">Ista tradicija služi predstavljanju politike i propitivanju njezine vjerodostojnosti.</p>',
      'Pregled medijskog prostora, str. 4 i 10. Prikaz pripisuje stavove njihovim govornicima.', OVERVIEW + '#p4')

slide('belonging dark', 'Nalaz 06', 'Poštovanje načela i stranačka pripadnost',
      '<blockquote>„Poštujem demokršćanska načela,<br>ali ne pripadam demokršćanskom spektru”</blockquote>'
      '<p class="attribution">Samir Haj Barakat, 29. kolovoza 2024.</p>'
      '<p class="large-copy narrow">Nakon izlaska iz SDP-a zadržava lijeva uvjerenja i odbacuje prelazak u HDZ.</p>'
      '<p class="takeaway">Odnos prema ideji može se razlikovati od odluke o stranačkom članstvu.</p>',
      'Dario Kuštro, Glas Slavonije. Od riječi do argumenta, str. 9.', BARAKAT)

slide('common-good', 'Nalaz 07', 'Opće dobro ulazi u pitanje zapošljavanja',
      '<p class="lead">Jedan tekst iz travnja 2024. povezuje dostojanstvo osobe s kritikom stranačkog probitka i ideološke isključivosti.</p>'
      '<div class="argument"><div><span>Polazište</span><h3>Dostojanstvo osobe</h3><p>Vrijednost osobe u javnom životu.</p></div>'
      '<div><span>Mjerilo</span><h3>Opće dobro</h3><p>Odgovornost prema zajednici.</p></div>'
      '<div><span>Javni zahtjev</span><h3>Stručnost i sposobnost</h3><p>Kriteriji za zapošljavanje.</p></div></div>'
      '<p class="takeaway">Načelo dobiva konkretan sadržaj u pitanju tko dobiva posao i prema kojim kriterijima.</p>',
      'Pregled medijskog prostora, str. 9. Sažetak jednog argumenta iz analiziranog teksta.', OVERVIEW + '#p9')

slide('subsidiarity', 'Nalaz 08', 'Supsidijarnost otvara pitanje tko odlučuje',
      '<p class="lead">Politolog Jakov Žižić demokršćanstvo tumači kroz zajednicu, solidarnost i raspodjelu vlasti.</p>'
      '<ol class="levels"><li><strong>Lokalna</strong><span>razina</span></li><li><strong>Regionalna</strong><span>razina</span></li>'
      '<li><strong>Državna</strong><span>razina</span></li><li><strong>Europska</strong><span>razina</span></li></ol>'
      '<p class="large-copy">Rasprava o demokršćanstvu obuhvaća i podjelu ovlasti među tim razinama.</p>'
      '<p class="note">Prikaz slijedi Žižićevo tumačenje u razgovoru s Matom Mijićem od 28. veljače 2021.</p>',
      'Od riječi do argumenta, str. 12. Intervju na portalu Otvoreno.', LANGUAGE + '#p12')

slide('conscience', 'Nalaz 09', 'Savjest i dostupnost zdravstvene usluge',
      '<p class="lead">U Saboru 20. travnja 2022. sudionici rasprave naglašavaju različite obveze zdravstvenog sustava.</p>'
      '<div class="editorial-columns"><div><h3>Anka Mrak-Taritaš</h3><p>Upozorava na bolnice u kojima, prema njezinu iskazu, zbog priziva savjesti nije moguće obaviti pobačaj.</p></div>'
      '<div><h3>Andrej Plenković</h3><p>Poziva se na demokršćanske vrijednosti u obrani priziva savjesti i najavljuje provjeru dostupnosti usluge.</p></div></div>'
      '<p class="takeaway">Pozivanje na vrijednosti otvara pitanje kako organizirati javnu uslugu uz zaštitu osobnog uvjerenja.</p>',
      'Hina / Vlada RH, 20. 4. 2022. Od riječi do argumenta, str. 10.', CONSCIENCE)

slide('solidarity dark', 'Nalaz 10', 'Europska solidarnost dobiva lokalnu adresu',
      '<p class="lead">U europskoj kampanji u lipnju 2024. Davor Ivo Stier povezuje demokršćansku Europu s razvojem Hrvatske.</p>'
      '<div class="argument"><div><span>Načelo</span><h3>Solidarnost</h3><p>Suradnja među članicama.</p></div>'
      '<div><span>Institucije</span><h3>Europski fondovi</h3><p>Zajednička sredstva za razvoj.</p></div>'
      '<div><span>Javne potrebe</span><h3>Pruga i zaštita od poplava</h3><p>Hrvatski Leskovac – Karlovac i Karlovačka županija.</p></div></div>'
      '<p class="note">Slijed prikazuje Stierovo kampanjsko obrazloženje. Medijska izjava sama ne dokazuje učinak projekata.</p>',
      'Hina, 7. 6. 2024. Od riječi do argumenta, str. 11.', STIER)

slide('synthesis', 'Završni pogled', 'Što demokršćansko ime znači za javno djelovanje?',
      '<div class="synthesis-rows"><div><h3>Pripadnost</h3><p>Tko se predstavlja kao demokršćanin i tko mu to osporava?</p></div>'
      '<div><h3>Načela</h3><p>Koju ulogu imaju solidarnost, savjest i opće dobro?</p></div>'
      '<div><h3>Odluke</h3><p>Što iz tih načela slijedi za zapošljavanje, zdravstvo ili europsku suradnju?</p></div></div>'
      '<p class="takeaway">Za razumijevanje narativnog okvira važno je povezati govornika, načelo i konkretan javni zahtjev.</p>',
      'Sinteza dvaju izvještaja. Primjeri ilustriraju argumente, bez procjene njihove ukupne učestalosti.', PAGE + '#izvjestaj')

slide('resources', 'Daljnje istraživanje', 'DigiKat kao prostor za daljnje istraživanje',
      '<div class="resource-columns"><div>'
      + resource(BASE + 'pages/mapa/index.html', 'Mapa medijskog prostora', 'Izvori, teme, jezik i promjene kroz vrijeme.')
      + resource(BASE + 'pages/baza.html', 'Službeni korpus i metodologija', 'Obuhvat podataka, pravila uključivanja i mogućnosti pristupa.')
      + resource(BASE + 'pages/izvori/index.html', 'Katalog izvora', 'Profili medija i platformi u promatranom prostoru.')
      + '</div><div>'
      + resource(BASE + 'pages/pregled/izvrsni-pregled.html', 'Izvršni pregled', 'Glavni nalazi projekta na jednom mjestu.')
      + resource(BASE + 'pages/studije/index.html', 'Tematska istraživanja', 'Povezane studije o katoličkim temama u javnosti.')
      + resource(BASE + 'assets/izvjestaji/godisnji-pregled-2025.html', 'Godišnji pregled 2025.', 'Šira medijska slika jedne godine.')
      + '</div></div>', 'Naslovi su poveznice na javne resurse projekta.', BASE)

# A QR code is encoded link data, not a decorative illustration.
from reportlab.graphics.barcode.qr import QrCodeWidget
qr = QrCodeWidget(PAGE)
qr.qr.make()
matrix = qr.qr.modules
size = len(matrix)
cells = ''.join(f'M{x+4} {y+4}h1v1h-1z' for y,row in enumerate(matrix) for x,on in enumerate(row) if on)
qrsvg = f'<svg viewBox="0 0 {size+8} {size+8}" role="img" aria-label="QR kod za otvaranje barometra"><rect width="100%" height="100%" fill="white"/><path d="{cells}" fill="#173e43"/></svg>'
slide('reading dark', 'Izvori i čitanje', 'Izvještaji, podaci i izvorni argumenti',
      '<div class="reading-layout"><div>'
      + resource(OVERVIEW, 'Demokršćanstvo u medijskom prostoru', 'Tematska karta, mediji i vremenski portreti rasprave.')
      + resource(LANGUAGE, 'Demokršćanstvo: od riječi do argumenta', 'Rječnik, načela i detaljno čitanje javnih argumenata.')
      + resource(PAGE + '#metoda', 'Barometar i otvorene zbirne tablice', 'Interaktivni prikaz, definicije i podaci za preuzimanje.')
      + f'<p class="originals">Izvorni primjeri: {a(BARAKAT,"Haj Barakat")}, {a(CONSCIENCE,"priziv savjesti")}, {a(STIER,"europska solidarnost")}.</p>'
      + '</div><div class="qr-link">' + a(PAGE, qrsvg) + '<p>Barometar demokršćanstva</p>'
      '<span>lusiki.github.io/DigiKat</span></div></div>',
      'Doc. dr. sc. Luka Šikić. Hrvatsko katoličko sveučilište. Izdanje 22. rujna 2026.', 'https://www.lukasikic.info/')

assert len(slides) == 18
css = (HERE / 'style.css').read_text(encoding='utf-8')
js = (HERE / 'carousel.js').read_text(encoding='utf-8')
parts = [f'<!doctype html><html lang="hr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
         f'<meta name="author" content="{AUTHOR}"><meta name="description" content="Karusel povezuje projekt DigiKat, podatke i deset nalaza o demokršćanstvu u medijima.">'
         f'<title>{TITLE}</title><style>{css}</style></head><body><a class="skip" href="#slajd-1">Preskoči na karusel</a>'
         f'<nav class="toolbar" aria-label="Upravljanje karuselom">{a(PAGE,"Barometar")}'
         '<button id="mode" type="button" hidden>Prikaži slajdove</button><button id="prev" type="button" hidden>Prethodni</button>'
         '<span id="position" role="status" aria-live="polite"></span><button id="next" type="button" hidden>Sljedeći</button>'
         f'<a href="{STEM}.pdf" download>Preuzmi PDF</a></nav>'
         '<details class="contents"><summary>Sadržaj karusela</summary><ol>'
         + ''.join(f'<li>{a(f"#slajd-{i}",esc(s["title"]))}</li>' for i,s in enumerate(slides,1))
         + '</ol><p>U prikazu slajdova koristite strelice. Escape vraća prikaz za čitanje.</p></details><main id="deck">']
for i, s in enumerate(slides, 1):
    heading = '' if i == 1 else f'<h2 id="title-{i}">{esc(s["title"])}</h2>'
    parts.append(f'<section class="slide {s["kind"]}" id="slajd-{i}" tabindex="-1" aria-label="{esc(s["title"],quote=True)}">'
                 f'<div class="masthead"><span>DigiKat</span><span>{esc(s["chapter"]) if i > 1 else "Hrvatsko katoličko sveučilište"}</span></div>'
                 f'{heading}<div class="content">{s["body"]}</div>'
                 f'<footer><span>{a(s["url"],esc(s["source"]))}</span><span>{i:02d} / {len(slides)}</span></footer></section>')
parts.append(f'</main><script>{js}</script></body></html>')
(OUT / (STEM + '.html')).write_text(apply_conference_theme('\n'.join(parts)), encoding='utf-8', newline='\n')
(OUT / 'claims.json').write_text(json.dumps(claims, ensure_ascii=False, indent=2), encoding='utf-8')
(OUT / 'manifest.json').write_text(json.dumps(dict(
    title=TITLE, author=AUTHOR, byline='Doc. dr. sc. Luka Šikić', slides=len(slides), findings=10,
    conference=CONFERENCE, conference_date='2026-09-24',
    design_inputs={str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
                   for p in sorted((HERE/'conference').glob('*')) if p.is_file()},
    inputs={p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in INPUTS},
    slide_titles=[s['title'] for s in slides]), ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(dict(slides=len(slides), numeric_claims=len(claims), output=str(OUT)), ensure_ascii=False))
