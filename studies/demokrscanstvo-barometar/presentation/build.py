"""Build the editable, self-contained HTML presentation from frozen public tables.

Run render.mjs afterwards for the matching landscape PDF and browser checks.
No corpus, models or topic assignments are changed by this publication build.
"""
from pathlib import Path
import csv, html, json, re

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
PORTABLE=(HERE.parent/'tables/word-clouds.csv').exists()
OUT=HERE.parent if PORTABLE else ROOT/'output/demokrscanstvo-presentation';OUT.mkdir(parents=True,exist_ok=True)
DATA=HERE.parent if PORTABLE else ROOT/'output/demokrscanstvo-text-public/v1'
SLIDES=json.loads((HERE/'slides.json').read_text(encoding='utf-8'))
BASE='https://lusiki.github.io/DigiKat/'
AUTHOR='<a rel="author" href="https://www.lukasikic.info/">Luka Šikić</a>'
rows=lambda p:list(csv.DictReader(p.open(encoding='utf-8-sig')))
num=lambda n:f'{int(n):,}'.replace(',','.')
pct=lambda n,d:f'{100*int(n)/d:.1f}'.replace('.',',')+'%'
esc=html.escape
WORDS={r['lemma']:r for r in rows(DATA/'tables/word-clouds.csv') if r['scope']=='all'}
SELECT={r['lemma']:r for r in rows(DATA/'tables/selected-words.csv')}
TOP={r['topic']:r for r in rows(DATA/'tables/topics.csv')}
PHRASES=rows(DATA/'tables/phrases.csv')
PLAT=rows(DATA/'tables/platforms.csv' if PORTABLE else ROOT/'data/barometar/demokrscanstvo-multiplatform/v1/platforms.csv')
TOTAL=sum(int(r['matching_records']) for r in PLAT)
PUB=json.loads((DATA/'tables/publication-topics.json' if PORTABLE else ROOT/'data/barometar/demokrscanstvo-themes/v1/summary.json').read_text(encoding='utf-8'))
CLAIMS=[]

def claim(key,value,denominator,source):
    CLAIMS.append(dict(claim=key,value=value,denominator=denominator,source=source))
    return value

def bars(rr,denominator,unit,source):
    """An ordered labelled native chart with numbers available to screen readers."""
    top=max(n for _,n in rr)
    h='<div class="bars"><p class="unit">'+unit+'</p>'
    for label,n in rr:
        claim(label,n,denominator,source)
        h+=f'<div class="bar-row"><div class="bar-label"><span>{esc(label)}</span><strong>{num(n)} <small>({pct(n,denominator)})</small></strong></div><div class="track" aria-hidden="true"><span style="width:{100*n/top:.4f}%"></span></div></div>'
    return h+'</div>'

def cloud(key):
    rr=[r for r in rows(DATA/'tables/word-clouds.csv') if r['scope']==key]
    title='Rječnik svih tema' if key=='all' else TOP[key]['label']
    svg=(DATA/f'figures/cloud-{key}.svg').read_text(encoding='utf-8')
    svg=svg[svg.index('<svg'):].replace('<svg ','<svg aria-hidden="true" focusable="false" ',1)
    for r in rr:claim(r['word'],int(r['texts']),int(r['denominator']),f'word-clouds.csv:{key}')
    alt='; '.join(f'{r["word"]}: {num(r["texts"])} tekstova' for r in rr)
    return f'<figure class="cloud"><h3>{esc(title)}</h3><p class="unit">{num(rr[0]["denominator"])} različita teksta</p>{svg}<figcaption class="sr-only">{esc(alt)}</figcaption></figure>'

def content(s):
    kind=s['kind'];text=f'<p class="interpretation">{esc(s.get("text",""))}</p>'
    if kind=='cover':return f'<p class="cover-sub">{s["subtitle"]}</p><p class="cover-text">{s["text"]}</p><p class="author">{AUTHOR}<br><span>www.lukasikic.info</span></p><p class="period">1. 1. 2021. – 10. 9. 2026.</p>'
    if kind=='scope':return text+f'<div class="columns scope"><div><strong class="big">{num(TOTAL)}</strong><h3>objava za pregled prostora</h3><p>Brojimo pojavljivanja na uključenim platformama.</p></div><div><strong class="big">2.253</strong><h3>različita teksta za jezik i argumente</h3><p>Jednake tekstove ovdje brojimo jednom.</p></div></div><p class="note">Riječi brojimo u odlomcima o demokršćanstvu. Jedan tekst može sadržavati više riječi ili izraza.</p>'
    if kind=='platforms':
        web=int(next(r for r in PLAT if r['platform']=='web')['matching_records'])
        return '<div class="columns"><div>'+bars([('Mrežni mediji',web),('Sve ostale platforme',TOTAL-web)],TOTAL,'Udio u svih 2.306 objava','platforms.csv')+'</div><div>'+text+'<p class="big accent">'+pct(web,TOTAL)+'</p><p class="note">objava dolazi s weba</p></div></div>'
    if kind=='identity':
        ids=['t01','t02','t03','t04'];ts=[r for r in PUB['topics'] if r['id'] in ids];n=sum(int(r['records']) for r in ts)
        claim('Four political topic groups',n,TOTAL,'thematic summary.json')
        return '<div class="columns"><div>'+bars([(r['label'],r['records']) for r in ts],TOTAL,'Broj objava i udio u svih 2.306','thematic summary.json')+'</div><div>'+text+f'<p class="big accent">{pct(n,TOTAL)}</p><p class="note">{num(n)} od {num(TOTAL)} objava</p></div></div>'
    if kind=='vocabulary':return '<div class="columns cloud-overall"><div>'+cloud('all')+'</div><div>'+text+f'<p class="statline"><strong>{num(WORDS["vrijednost"]["texts"])}</strong> tekstova s riječju „vrijednost”<br>49,8% od 2.253</p><p class="note">Veća riječ znači više tekstova. Boja i položaj služe čitljivosti.</p></div></div>'
    if kind in ('political_clouds','public_clouds'):
        keys=['t02','t03'] if kind=='political_clouds' else ['t06','t08']
        return '<div class="columns clouds">'+''.join(cloud(k) for k in keys)+'</div>'+text
    if kind=='phrases':return '<div class="columns"><div>'+bars([(r['phrase'],int(r['texts'])) for r in PHRASES[:4]],2253,'Broj tekstova i udio u svih 2.253','phrases.csv')+'</div><div>'+text+'<p class="note">Prikazana su četiri najčešća izraza među osam analiziranih.</p></div></div>'
    if kind in ('barakat','conscience'):
        note='Primjer razlikuje osobno uvjerenje i političku pripadnost.' if kind=='barakat' else 'Spor povezuje pravo liječnika i dostupnost zdravstvene usluge. Citat sam ne razrješava pitanje dostupnosti.'
        return f'<div class="columns case"><div><blockquote>„{esc(s["quote"])}”</blockquote><p class="attribution">{esc(s["attribution"])}</p></div><div>{text}<p class="note">{note}</p></div></div>'
    if kind=='stier':return text+'<ol class="chain"><li><span>Načelo</span><strong>Europska solidarnost</strong></li><li><span>Instrument</span><strong>Suradnja i fondovi EU-a</strong></li><li><span>Lokalna primjena</span><strong>Pruga i obrana od poplava</strong></li></ol><p class="note">Stier navodi drugi kolosijek Hrvatski Leskovac–Karlovac i obranu od poplava u Karlovačkoj županiji. Primjer prikazuje njegov argument, bez procjene ekonomskog učinka.</p>'
    if kind=='principles':return '<div class="columns"><div>'+bars([(SELECT[k]['word'],int(SELECT[k]['texts'])) for k in ['solidarnost','savjest','supsidijarnost']],2253,'Broj tekstova i udio u svih 2.253','selected-words.csv')+'</div><div>'+text+'<p class="note">Broj pojavljivanja riječi ne mjeri važnost načela ni broj svih rasprava o toj ideji.</p></div></div>'
    if kind=='zizic':return text+'<div class="columns concepts"><div><h3>Razine odlučivanja</h3><p>Lokalna i regionalna vlast<br>Država<br>Europska suradnja</p></div><div><h3>Sadržaj javne politike</h3><p>U njegovu tumačenju država ispravlja tržišne ishode radi općeg dobra. Supsidijarnost otvara pitanje raspodjele ovlasti.</p></div></div>'
    if kind=='comparison':return text+'<table class="comparison"><caption class="sr-only">Tri različite javne primjene</caption><thead><tr><th>Govornik i povod</th><th>Uloga demokršćanskog jezika</th></tr></thead><tbody><tr><td>Haj Barakat · izlazak iz SDP-a</td><td>Razlikovanje načela i pripadnosti</td></tr><tr><td>Plenković · saborska rasprava</td><td>Obrazlaganje priziva savjesti</td></tr><tr><td>Stier · europska kampanja</td><td>Povezivanje solidarnosti i ulaganja</td></tr></tbody></table>'
    return text+f'<ul class="reading"><li><a href="{BASE}pages/demokrscanstvo/">Medijski barometar demokršćanstva</a><span>Teme, kretanja, platforme i javna pitanja</span></li><li><a href="{BASE}assets/izvjestaji/demokrscanstvo-u-medijskom-prostoru.pdf">Demokršćanstvo u medijskom prostoru</a><span>Pregled medijskog prostora · 14 stranica</span></li><li><a href="{BASE}assets/izvjestaji/demokrscanstvo-od-rijeci-do-argumenta.html">Demokršćanstvo: od riječi do argumenta</a><span>Jezik i javni argumenti · 12 stranica</span></li></ul><p class="end-author">Autor izvještaja i prezentacije: {AUTHOR}</p>'

css=(HERE/'style.css').read_text(encoding='utf-8')
js=(HERE/'presentation.js').read_text(encoding='utf-8')
h=['<!doctype html><html lang="hr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="author" content="Luka Šikić"><meta name="description" content="Dvanaest nalaza o demokršćanstvu u medijima: teme, rječnik, politička pripadnost i konkretni javni argumenti."><title>Demokršćanstvo u medijima: 12 ključnih nalaza — Luka Šikić</title><style>'+css+'</style></head><body><a class="skip" href="#slajd-1">Preskoči na prezentaciju</a><nav class="toolbar" aria-label="Upravljanje prezentacijom"><a href="'+BASE+'pages/demokrscanstvo/">← Barometar</a><button id="mode" type="button" hidden>Prikaži slajdove</button><button id="prev" type="button" hidden>← Prethodni</button><span id="position" role="status" aria-live="polite"></span><button id="next" type="button" hidden>Sljedeći →</button><a href="demokrscanstvo-12-nalaza.pdf" download>Preuzmi PDF</a></nav><details class="contents"><summary>Sadržaj prezentacije</summary><ol>'+''.join(f'<li><a href="#slajd-{i}">{esc(s["title"])}</a></li>' for i,s in enumerate(SLIDES,1))+'</ol><p>U prikazu slajdova koristite strelice. Escape vraća prikaz za čitanje.</p></details><main id="deck">']
for i,s in enumerate(SLIDES,1):
    label='DigiKat / '+('12 ključnih nalaza' if i==1 else f'Nalaz {i-2:02d} / 12' if 3<=i<=14 else 'O podacima' if i==2 else 'Za daljnje čitanje')
    source=esc(s['source'])
    if s.get('url'):source=f'<a href="{esc(s["url"],quote=True)}">{source}</a>'
    h.append(f'<section class="slide {s["kind"]}" id="slajd-{i}" tabindex="-1" aria-labelledby="title-{i}"><p class="eyebrow">{label}</p><h{1 if i==1 else 2} id="title-{i}">{esc(s["title"])}</h{1 if i==1 else 2}><div class="content">{content(s)}</div><footer><span>{source}</span><span>{i} / {len(SLIDES)}</span></footer></section>')
h.append('</main><script>'+js+'</script></body></html>')
(OUT/'demokrscanstvo-12-nalaza.html').write_text('\n'.join(h),encoding='utf-8')
(OUT/'claim-register.json').write_text(json.dumps(CLAIMS,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps({'slides':len(SLIDES),'findings':12,'numeric_claims':len(CLAIMS),'output':str(OUT)},ensure_ascii=False))
