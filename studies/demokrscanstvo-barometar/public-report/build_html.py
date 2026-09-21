"""HTML edition of "Demokršćanstvo u medijskom prostoru".

The words, numbers and charts come from build.py itself: its make_pages() is run
again with the six layout helpers (p, h, cap, table, Takeaway, chart) swapped for
HTML emitters, so the web edition cannot drift from the PDF. The chart files are
the SVGs build.py already wrote; nothing here redraws them or touches the PDF.

Run from the repository root after build.py:
    python -X utf8 studies/demokrscanstvo-barometar/public-report/build_html.py
"""
from pathlib import Path
import base64
import html
import importlib.util
import re

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('public_report', HERE / 'build.py')
bld = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bld)

TITLE = 'Demokršćanstvo u medijskom prostoru'
SUBTITLE = 'Identitet, vrijednosti i društvena pitanja'
PUBLISHED = '19. rujna 2026.'
AUTHOR = '<a rel="author" href="https://www.lukasikic.info/">Luka Šikić</a>'
OUTFILE = bld.OUT / 'demokrscanstvo-u-medijskom-prostoru.html'


def text(raw):
    """The same normalisation build.py's p() applies, then HTML instead of ReportLab markup."""
    raw = re.sub('[‐-—]', '-', raw)
    assert '�' not in raw
    out = html.escape(raw, quote=False).replace('\n', '<br>')
    return re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', out)


# ---- HTML emitters with build.py's helper signatures ----
def p(raw, style='body', source=''):
    return ('p', style, text(raw))

def h(raw):
    return ('p', 'h2', text(raw))

def cap(raw):
    return ('p', 'small', text(raw))

def table(data, widths=None):
    return ('table', data)

def chart(name, maxheight=None):
    return ('chart', name)

def Takeaway(raw):
    return ('quote', text(raw))

def Spacer(*_):
    return None

def Paragraph(markup, _style):
    link = re.search(r'<link href="([^"]+)"[^>]*>(?:<u>)?(.*?)(?:</u>)?</link>', markup)
    assert link, markup
    return ('link', link.group(1), link.group(2))

for name, fn in dict(p=p, h=h, cap=cap, table=table, chart=chart,
                     Takeaway=Takeaway, Spacer=Spacer, Paragraph=Paragraph).items():
    setattr(bld, name, fn)


# ---- the exact series behind each chart, for its text alternative ----
def pct(x):
    return bld.dec(x) + '%'

def chart_data(name):
    T, P, TOPICS = bld.TOP, bld.PLAT, bld.TOPICS
    if name == '01-teme':
        order = sorted(TOPICS, key=lambda t: -int(T[t]['n']))
        return (['Tema', 'Tekstovi i objave', 'Udio'],
                [[T[t]['label'], bld.num(T[t]['n']), pct(T[t]['percent'])] for t in order])
    if name == '02-godine':
        years = sorted({r['category'] for r in bld.PROFILES if r['scope'] == 'year'})
        return (['Tema'] + [y + '.' for y in years],
                [[T[t]['label']] + [pct(bld.profile('year', y, t)['percent']) for y in years] for t in TOPICS])
    if name == '03-mediji':
        keys = [k for k in P if int(P[k]['n']) > 0]
        label = lambda k: 'X / Twitter' if k == 'twitter' else P[k]['label']
        return (['Medij ili platforma', 'Tekstovi i objave', 'Udio'],
                [[label(k), bld.num(P[k]['n']), pct(P[k]['percent'])] for k in keys])
    if name == '04-teme-mediji':
        keys = ['web', 'twitter', 'facebook', 'print', 'comment']
        heads = ['Web', 'X / Twitter', 'Facebook', 'Tisak', 'Komentari']
        return (['Tema'] + heads,
                [[T[t]['label']] + [pct(bld.profile('platform', k, t)['percent']) for k in keys] for t in TOPICS])
    raise KeyError(name)

ALT = {
    '01-teme': 'Stupčasti prikaz udjela deset tema među analiziranim tekstovima i objavama.',
    '02-godine': 'Tablica u boji s udjelom svake teme u tekstovima pojedine godine od 2021. do 2026.',
    '03-mediji': 'Broj tekstova s mrežnih stranica i broj tekstova i objava u ostalim medijima i na platformama.',
    '04-teme-mediji': 'Tablica u boji s udjelom svake teme u pet medija i platformi s najviše materijala.',
}


def html_table(head, body, caption=None):
    cap_html = f'<caption>{html.escape(caption)}</caption>' if caption else ''
    thead = '<tr>' + ''.join(f'<th scope="col">{html.escape(str(c))}</th>' for c in head) + '</tr>'
    rows = ''.join('<tr>' + ''.join(f'<td>{html.escape(str(c))}</td>' for c in r) + '</tr>' for r in body)
    return f'<div class="scroll" tabindex="0" role="region" aria-label="{html.escape(caption or head[0])}"><table>{cap_html}<thead>{thead}</thead><tbody>{rows}</tbody></table></div>'


def figure(name, caption_html):
    svg = (bld.FIG / (name + '.svg')).read_bytes()
    uri = 'data:image/svg+xml;base64,' + base64.b64encode(svg).decode('ascii')
    head, body = chart_data(name)
    return (f'<figure><img src="{uri}" alt="{html.escape(ALT[name])}">'
            + (f'<figcaption>{caption_html}</figcaption>' if caption_html else '')
            + f'<details><summary>Tekstualni prikaz podataka</summary>{html_table(head, body)}</details></figure>')


CSS = ('body{margin:0;background:#fcfbf7;color:#173e43;font:18px/1.6 Calibri,Arial,sans-serif}'
       'main{max-width:960px;margin:auto;padding:36px 24px}h1,h2{font-family:Georgia,serif;line-height:1.2}'
       'h1{font-size:2.4em}h2{font-size:1.8em}h3{line-height:1.3}section{margin:70px 0}'
       'a{color:#94512f;text-underline-offset:3px}blockquote{background:#eef2ef;border-left:4px solid #94512f;'
       'margin:24px 0;padding:20px;font-family:Georgia,serif}table{border-collapse:collapse;width:100%;font-size:.94em}'
       'td,th{padding:9px;border-bottom:1px solid #cdd9d4;text-align:left}th{background:#eef2ef}figure{margin:20px 0}'
       'figure img{width:100%;height:auto;display:block}figcaption,.note{font-size:.92em;color:#496268}'
       'summary{cursor:pointer;text-decoration:underline}details{margin:14px 0}nav li{margin:8px 0}'
       'a:focus,summary:focus,.scroll:focus{outline:3px solid #94512f;outline-offset:4px}'
       '.kicker{margin:0 0 6px;color:#94512f;font-weight:bold;font-size:.8em;letter-spacing:.08em;text-transform:uppercase}'
       '.scroll{overflow-x:auto}.lead{font-family:Georgia,serif;font-size:1.25em;line-height:1.4}'
       '.stats{display:flex;flex-wrap:wrap;gap:12px 40px;margin:24px 0;padding:0;list-style:none}'
       '.stats strong{display:block;font-family:Georgia,serif;font-size:1.7em;font-weight:normal;color:#94512f}'
       '@media(max-width:650px){h1{font-size:2em}h2{font-size:1.5em}}'
       '@media print{details{display:block}section{break-before:page}nav{display:none}}')


def render_item(item, nxt):
    """nxt lets a chart take the caption that build.py places right after it."""
    kind = item[0]
    if kind == 'p':
        style, body = item[1], item[2]
        if style == 'h2':
            return f'<h3>{body}</h3>'
        if style == 'small':
            return f'<p class="note">{body}</p>'
        return f'<p class="body">{body}</p>'
    if kind == 'quote':
        return f'<blockquote>{item[1]}</blockquote>'
    if kind == 'table':
        return html_table(item[1][0], item[1][1:])
    if kind == 'chart':
        caption = nxt[2] if nxt and nxt[0] == 'p' and nxt[1] == 'small' else ''
        return figure(item[1], caption)
    if kind == 'link':
        return f'<p class="note"><a href="{html.escape(item[1])}">{html.escape(item[2])}</a></p>'
    raise ValueError(kind)


def main():
    bld.PAGES.clear()
    bld.make_pages()
    out = ['<!doctype html><html lang="hr"><head><meta charset="utf-8">'
           '<meta name="viewport" content="width=device-width, initial-scale=1">'
           f'<title>{TITLE}</title><style>{CSS}</style></head><body><main>',
           '<header>',
           f'<p>DigiKat | Hrvatsko katoličko sveučilište | {PUBLISHED}</p>',
           f'<h1>{TITLE}</h1><p>{SUBTITLE}</p><p>Autor: {AUTHOR}</p>',
           '<p>Tekstovi i objave od 1. 1. 2021. do 10. 9. 2026.</p>',
           '<ul class="stats">'
           f'<li><strong>{bld.num(bld.N)}</strong>tekstova i objava</li>'
           f'<li><strong>{len(bld.TOPICS)}</strong>tematskih skupina</li>'
           '<li><strong>2021. - 2026.</strong>promatrano razdoblje</li></ul>',
           '<p class="lead">Kako se demokršćanstvo pojavljuje u političkim porukama, javnim raspravama i društvenim pitanjima.</p>',
           '<p>Politička pripadnost. Sporovi oko vrijednosti. Solidarnost, savjest i zajednica.</p>',
           '</header>',
           '<nav aria-label="Sadržaj"><h2>Sadržaj</h2><ol>']
    for i, (_, title, _) in enumerate(bld.PAGES, 2):
        out.append(f'<li><a href="#p{i}">{text(title)}</a></li>')
    out.append('</ol></nav>')
    for i, (kicker, title, items) in enumerate(bld.PAGES, 2):
        items = [x for x in items[1:] if x is not None]   # items[0] is the page title
        out.append(f'<section id="p{i}" aria-labelledby="t{i}"><p class="kicker">{text(kicker)}</p>'
                   f'<h2 id="t{i}">{text(title)}</h2>')
        skip = False
        for j, item in enumerate(items):
            if skip:
                skip = False
                continue
            nxt = items[j + 1] if j + 1 < len(items) else None
            out.append(render_item(item, nxt))
            skip = item[0] == 'chart' and nxt is not None and nxt[0] == 'p' and nxt[1] == 'small'
        out.append('</section>')
    out.append('</main></body></html>')
    page = '\n'.join(out)
    assert 'Determ' not in page and '�' not in page
    OUTFILE.write_text(page, encoding='utf-8')
    print({'pages': len(bld.PAGES), 'charts': page.count('<figure>'), 'bytes': len(page.encode()),
           'output': str(OUTFILE)})


if __name__ == '__main__':
    main()
