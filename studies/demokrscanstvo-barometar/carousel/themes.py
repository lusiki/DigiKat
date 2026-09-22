"""Theme and vocabulary views from existing public reports and aggregate tables."""
from html import escape, unescape
import re


def add_theme_slides(slide, bars, claim, topics, year_counts, total, texts,
                     lexical_html, topic_source, year_source, word_source, overview, language):
    num = lambda n: f'{int(n):,}'.replace(',', '.')
    pct = lambda n,d: f'{100*n/d:.1f}'.replace('.', ',')+' %'
    ordered = sorted((r for r in topics.values() if r['topic'] != 'unassigned'),
                     key=lambda r:-int(r['records']))
    assert len(ordered)==10
    top = int(ordered[0]['records'])
    columns = ['<div>'+bars([(r['label'],int(r['records'])) for r in ordered[i:i+5]],
                           total,topic_source,ceiling=top)+'</div>' for i in (0,5)]
    slide('theme-map','Projekt i podaci','Politički položaj ostaje u središtu karte',
          '<p class="lead">Politička pripadnost, vrijednosti i HDZ-ov identitet okupljaju najviše objava.</p>'
          +'<div class="theme-columns">'+''.join(columns)+'</div>'
          +f'<p class="note">Broj i udio među {num(total)} objava. Svaka ima jednu glavnu temu. '
          +f'Izvan prikazanih tema ostaje {num(int(topics["unassigned"]["records"]))} objava.</p>',
          'Pregled medijskog prostora, str. 5. Cijela tematska karta.',overview+'#p5')

    figure = re.search(r'<figure>(.*?)</figure>',lexical_html,re.S)[1]
    cloud = re.search(r'<svg\b.*?</svg>',figure,re.S)[0]
    word_rows = re.findall(r'<tr><td>(.*?)</td><td>([\d.]+)</td><td>(.*?)</td></tr>',figure)
    assert len(word_rows)==48
    for word,n,_ in word_rows: claim(unescape(word),int(n.replace('.','')),texts,word_source)
    # Preserve the published vector layout, recoloring only for the approved palette.
    fills = list(dict.fromkeys(re.findall(r'fill: rgb\([^)]*\)',cloud)))
    for i,fill in enumerate(fills):
        cloud = cloud.replace(fill,'fill: '+['#f5f7fa','#dfcb70','#bdcbdc'][i%3])
    cloud = cloud.replace('id="clip"','id="lexical-clip"').replace('#clip','#lexical-clip')
    cloud = cloud.replace('id="group"','id="lexical-group"')
    cloud = cloud.replace('aria-hidden="true"','role="img" aria-label="48 čestih riječi. Veća riječ pojavljuje se u više tekstova."')
    cloud = cloud.replace('<title>...</title>','<title>Koje riječi prate demokršćanstvo?</title>')
    cloud = cloud.replace('<desc>...</desc>','<desc>Najčešće su vrijednost, stranka i HDZ.</desc>')
    ranking=''.join(f'<div><span>{unescape(w)}</span><strong>{n}<small>{pct(int(n.replace(".","")),texts)}</small></strong></div>'
                    for w,n,_ in word_rows[:3])
    slide('vocabulary dark','Nalaz 01','Koje riječi prate demokršćanstvo?',
          f'<p class="lead">Rječnik u rečenicama povezanima s temom. Analiza obuhvaća {num(texts)} različita teksta.</p>'
          +'<div class="vocabulary-layout"><div class="word-cloud">'+cloud+'</div><div class="word-ranking">'
          +'<p class="chart-label">Broj tekstova s riječju</p>'+ranking+'</div></div>'
          +'<p class="note">Veća riječ pojavljuje se u više tekstova. Riječ se broji jednom po tekstu, uz objedinjene gramatičke oblike. '
          +'Položaj i boja nemaju dodatno značenje. Nazivi demokršćanstva i kršćanstva izostavljeni su radi prikaza konteksta.</p>',
          'Od riječi do argumenta, str. 3. Isti tekst broji se jednom.',language+'#p3')

    pairs=[('Domoljublje + narodnjaštvo','Politička tradicija i temeljne stranačke vrijednosti.'),
           ('Domoljublje + državotvornost','Država, nacionalni interesi i povijesno nasljeđe.'),
           ('Demokršćanstvo + konzervativizam','Sličnosti i granice između političkih tradicija.'),
           ('HDZ + savjest','Priziv savjesti i osobna odgovornost pri političkom izboru.'),
           ('Europa + solidarnost','Suradnja među članicama i mogućnosti razvoja.')]
    table='<table class="word-pairs"><thead><tr><th scope="col">Povezani pojmovi</th><th scope="col">Što se kroz njih raspravlja</th></tr></thead><tbody>'
    table+=''.join(f'<tr><th scope="row">{a}</th><td>{b}</td></tr>' for a,b in pairs)+'</tbody></table>'
    slide('connections','Nalaz 02','Riječi koje povezuju raspravu',
          '<p class="lead">Pojam demokršćanstva povezuje se s političkom tradicijom, nacionalnom pripadnošću i društvenim vrijednostima.</p>'
          +table+'<p class="takeaway">Iste riječi sudjeluju u različitim argumentima i ne podrazumijevaju iste političke zaključke.</p>',
          'Pregled medijskog prostora, str. 8. Odabrani parovi i njihovi konteksti, bez rangiranja učestalosti.',overview+'#p8')

    years=sorted(year_counts)
    assert years==['2021','2022','2023','2024','2025','2026']
    table='<div class="heatmap-scroll"><table class="year-heatmap"><thead><tr><th scope="col">Tema</th>'
    table+=''.join(f'<th scope="col">{y}.</th>' for y in years)+'</tr></thead><tbody>'
    for row in ordered:
        table+=f'<tr><th scope="row">{escape(row["label"])}</th>'
        for year in years:
            n=year_counts[year][row['topic']]; d=sum(year_counts[year].values())
            claim(row['label']+' '+year,n,d,year_source)
            share=n/d
            # Sequential navy ramp with explicit percentages, not color alone.
            alpha=min(1,share/.30)
            rgb=tuple(round(245+(v-245)*alpha) for v in (12,37,64))
            channels=[c/255 for c in rgb]
            linear=[c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4 for c in channels]
            luminance=sum(c*w for c,w in zip(linear,[.2126,.7152,.0722]))
            fg='#ffffff' if luminance<.179 else '#000000'
            table+=f'<td style="background:rgb{rgb};color:{fg}">{pct(n,d)}</td>'
        table+='</tr>'
    table+='</tbody></table></div>'
    slide('year-map','Nalaz 03','Različite godine, različite teme',
          '<p class="lead">Tamnija boja znači veći udio teme u objavama te godine. Udio od 25 % znači četvrtinu godišnjih objava.</p>'
          +table+'<p class="note">Udjeli unutar godine. Promjena obuhvata u travnju 2024. Podaci za 2026. do 10. rujna. '
          +'Brojevi ne mjere javnu potporu.</p>',
          'Pregled medijskog prostora, str. 7. Godišnji sastav uključenih objava.',overview+'#p7')
