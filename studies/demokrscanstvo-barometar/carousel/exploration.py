"""Six exploratory slides backed by the published aggregate evidence."""
from html import escape

num = lambda n: f'{int(n):,}'.replace(',', '.')
pct = lambda n,d: f'{100*n/d:.1f}'.replace('.', ',')+' %'
MONTHS = ['siječanj','veljača','ožujak','travanj','svibanj','lipanj',
          'srpanj','kolovoz','rujan','listopad','studeni','prosinac']

def month_label(value):
    year,month = value.split('-')
    return f'{MONTHS[int(month)-1].capitalize()} {year}.'

def monthly_chart(rows):
    width,height,left,right,top,bottom = 1280,340,60,22,34,48
    plot_w,plot_h = width-left-right,height-top-bottom
    ceiling=150
    x=lambda i: left+plot_w*i/(len(rows)-1)
    y=lambda n: top+plot_h*(1-n/ceiling)
    peak=max(rows,key=lambda r:r['articles'])
    parts=[f'<svg class="time-chart" viewBox="0 0 {width} {height}" role="img" '
           f'aria-label="Mjesečni broj web članaka. Najaktivniji mjesec: {month_label(peak["month"])} '
           f'Broj članaka: {peak["articles"]}. Promjena obuhvata prikupljanja u travnju 2024.">']
    for n in [0,50,100,150]:
        parts.append(f'<line x1="{left}" y1="{y(n):.2f}" x2="{width-right}" y2="{y(n):.2f}" class="chart-grid"/>'
                     f'<text x="{left-13}" y="{y(n)+6:.2f}" text-anchor="end" class="chart-tick">{n}</text>')
    points=' '.join(f'{x(i):.2f},{y(row["articles"]):.2f}' for i,row in enumerate(rows))
    area=f'{left},{y(0)} '+points+f' {x(len(rows)-1)},{y(0)}'
    parts.append(f'<polygon points="{area}" class="chart-area"/><polyline points="{points}" class="chart-series"/>')
    change=next(i for i,r in enumerate(rows) if r['month']=='2024-04')
    parts.append(f'<line x1="{x(change):.2f}" x2="{x(change):.2f}" y1="{top}" y2="{y(0)}" class="chart-break"/>'
                 f'<text x="{x(change)+10:.2f}" y="20" class="chart-tick">Promjena obuhvata · 4. 2024.</text>')
    for i,row in enumerate(rows):
        if row['month'].endswith('-01'):
            parts.append(f'<text x="{x(i):.2f}" y="{height-12}" class="chart-tick">{row["month"][:4]}.</text>')
    for row in sorted(rows,key=lambda r:-r['articles'])[:3]:
        i=rows.index(row)
        parts.append(f'<circle cx="{x(i):.2f}" cy="{y(row["articles"]):.2f}" r="5" class="chart-peak"/>'
                     f'<text x="{x(i):.2f}" y="{y(row["articles"])-14:.2f}" text-anchor="middle" class="chart-value">{row["articles"]}</text>')
    parts.append('</svg>')
    return ''.join(parts)

def add_exploration_slides(slide,bars,statistic,claim,data,source,url):
    total=data['scope']['web_articles']
    slide('people', 'Nalaz 05', 'Odabrane javne osobe u člancima',
        f'<p class="lead">U {num(total)} web članaka brojimo spominjanje šest odabranih javnih osoba.</p>'
        '<div class="split"><div>'+bars([(r['name'],r['articles']) for r in data['people']],total,source)+'</div>'
        '<div class="reading-copy"><h3>Jedan članak, jedno brojanje</h3>'
        '<p>Članak se po osobi broji jednom. U istom se članku može pojaviti više imena.</p>'
        '<p>Traži se puno ime i prezime, uz padežne oblike, u naslovu ili dostupnom tekstu.</p></div></div>'
        '<p class="note">Prikaz obuhvaća odabrane osobe. Spominjanje ne pokazuje da one zagovaraju demokršćanstvo.</p>',
        'Podaci uz karusel. Udio web članaka koji spominju pojedinu osobu.',url)

    displayed=data['sources'][:6]
    sources_n=claim('Distinct web sources',data['scope']['web_sources'],None,source)
    displayed_n=claim('Articles from six leading sources',sum(r['articles'] for r in displayed),total,source)
    slide('outlets dark','Nalaz 06','Koji izvori objavljuju najviše članaka?',
        f'<p class="lead">Prikazano je šest izvora s najviše članaka u web zbirci.</p>'
        '<div class="split"><div>'+bars([(r['source'],r['articles']) for r in displayed],total,source)+'</div><div>'
        +statistic(num(sources_n),'različitih web izvora',
                   f'Šest prikazanih izvora objavilo je {num(displayed_n)} članaka ({pct(displayed_n,total)}).')+'</div></div>'
        '<p class="note">Broj članaka opisuje zastupljenost izvora u zbirci. Ne mjeri veličinu publike.</p>',
        f'Podaci uz karusel. Nazivnik je {num(total)} web članaka.',url)

    for row in data['monthly']: claim('Web articles '+row['month'],row['articles'],None,source)
    slide('timeline','Nalaz 07','Broj web članaka kroz vrijeme',
        f'<p class="lead">Mjesečni raspored {num(total)} članaka pokazuje kada se tema češće pojavljuje u prikupljenom materijalu.</p>'
        +monthly_chart(data['monthly'])+
        '<p class="note">Obuhvat prikupljanja promijenio se u travnju 2024. Podaci za 2026. sežu do 10. rujna. '
        'Brojevi ne mjere javnu potporu.</p>',
        'Mjesečni broj web članaka. Zbirka od 1. 1. 2021. do 10. 9. 2026.',url)

    peaks=data['peak_months']
    peak_sum=claim('Articles in four busiest web months',sum(r['articles'] for r in peaks),total,source)
    slide('peaks','Nalaz 08','Četiri mjeseca s najviše članaka',
        '<div class="split"><div>'+statistic(pct(peak_sum,total),'svih web članaka u četiri mjeseca',
             f'{num(peak_sum)} od {num(total)} članaka')+'</div><div>'
        +bars([(month_label(r['month']),r['articles']) for r in peaks],total,source)+'</div></div>'
        '<p class="note">Rang se odnosi na broj prikupljenih web članaka, uz različit obuhvat prikupljanja kroz vrijeme.</p>',
        'Podaci uz karusel. Rang mjeseci u web zbirci.',url)

    body='<div class="peak-themes">'
    for p in peaks[:3]:
        leading=p['topics'][0]
        claim('Leading web peak topic '+p['month'],leading['articles'],p['articles'],source)
        body+=(f'<div><p class="peak-month">{month_label(p["month"])}<span>{num(p["articles"])} članaka ukupno</span></p>'
               f'<h3>{escape(leading["label"])}</h3><p class="peak-count"><strong>{num(leading["articles"])}</strong>'
               f'<span>{pct(leading["articles"],p["articles"])} u tom mjesecu</span></p></div>')
    body+='</div>'
    slide('peak-topics','Nalaz 09','Koje teme prevladavaju u vršnim mjesecima?',
        '<p class="lead">Tri najaktivnija mjeseca razlikuju se po svojoj najzastupljenijoj temi.</p>'+body+
        '<p class="note">Svaki članak ima jednu glavnu tematsku oznaku. Udjeli se računaju zasebno unutar svakog mjeseca.</p>',
        'Podaci uz karusel i postojeće tematske oznake članaka.',url)

    day=data['peak_day']
    claim('Busiest web day articles',day['articles'],None,source)
    claim('Busiest web day sources',day['sources'],None,source)
    dd=f'{int(day["day"][8:])}. {int(day["day"][5:7])}. {day["day"][:4]}.'
    slide('daily dark','Nalaz 10','Dnevni vrhunac okuplja više izvora',
        '<div class="split"><div>'+statistic(num(day['articles']),f'članaka objavljeno {dd}',
            f'Članci dolaze iz {num(day["sources"])} različitih izvora.')+'</div><div>'
        '<p class="chart-label">Tri najzastupljenije teme toga dana</p>'
        +bars([(r['label'],r['articles']) for r in day['topics'][:3]],day['articles'],source)+'</div></div>'
        '<p class="takeaway">Više izvora može izvještavati o istom događaju. Broj članaka nije broj zasebnih događaja.</p>',
        'Podaci uz karusel. Dan s najviše članaka u promatranoj web zbirci.',url)
