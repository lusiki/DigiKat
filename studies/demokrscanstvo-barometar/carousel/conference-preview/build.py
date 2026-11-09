"""Create a separate conference design preview from the approved carousel HTML.

Reads the poster and published carousel. Never writes public assets or site pages.
The only textual additions are the conference context on the cover and closing.
"""
from pathlib import Path
import argparse
import base64
import hashlib
import json
import re
import fitz

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = ROOT / 'output/conference-carousel'
STEM = 'demokrscanske-vrijednosti-konferencijska-verzija'
SOURCE = ROOT / 'assets/izvjestaji/demokrscanske-vrijednosti-karusel.html'
CONFERENCE = 'Izazovi i budućnost demokršćanstva u Hrvatskoj i Europi'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--poster', type=Path, default=Path(
    'C:/Users/lsikic/Desktop/Konferencija - Izazovi i budućnost kršćanske demokracije u Hrvatskoj i Europi - Poster.pdf'))
args = parser.parse_args()
OUT.mkdir(parents=True, exist_ok=True)
document = fitz.open(args.poster)
# Original 1024 x 1536 flag photograph, identified visually in the supplied PDF.
flags = [im for im in document[0].get_images(full=True) if im[2:4] == (1024, 1536)]
assert len(flags) == 1, 'Poster artwork changed; inspect it before extracting.'
flag = document.extract_image(flags[0][0])
image_uri = 'data:image/jpeg;base64,' + base64.b64encode(flag['image']).decode('ascii')
css = HERE.joinpath('style.css').read_text(encoding='utf-8')
css += '\n:root{--conference-image:url("' + image_uri + '")}\n'
html = SOURCE.read_text(encoding='utf-8')
html = html.replace('</style>', css + '</style>', 1)
html = html.replace('demokrscanske-vrijednosti-karusel.pdf', STEM + '.pdf')
html = html.replace('<span>Hrvatsko katoličko sveučilište</span></div><div class="content">',
                    '<span>24. rujna 2026. · Zagreb</span></div><div class="content">', 1)
html = html.replace('<div class="cover-title">',
    '<div class="conference-heading"><p class="event-label">Izlaganje na znanstveno-stručnom skupu</p>'
    '<p class="event-title">Izazovi i budućnost demokršćanstva<br>u Hrvatskoj i Europi</p></div>'
    '<div class="cover-title">', 1)
html = html.replace('<span>DigiKat</span><span>',
    '<span>DigiKat</span><span class="conference-context">Zagreb · 24. rujna 2026.</span><span>')
# The cover already carries the full event details; omit its repeated small date.
html = html.replace('<span class="conference-context">Zagreb · 24. rujna 2026.</span>', '', 1)
html = html.replace('>Podaci barometra do 10. rujna 2026.</a>',
    '><span class="conference-venue">24. rujna 2026. · Zagreb, Hrvatsko katoličko sveučilište</span>'
    '<span class="data-date">Podaci barometra do 10. rujna 2026.</span></a>', 1)
closing = ('<p class="conference-closing">Izlaganje na skupu „' + CONFERENCE + '”.</p>')
html, replacements = re.subn(r'(<section class="slide reading dark".*?)(</div><footer>)',
                             lambda m: m[1] + closing + m[2], html, count=1, flags=re.S)
assert replacements == 1
assert html.count('class="slide ') == 18
assert 'Izlaganje na znanstveno-stručnom skupu' in html
(OUT / (STEM + '.html')).write_text(html, encoding='utf-8', newline='\n')
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
manifest = dict(
    status='design preview, not published', slides=18,
    conference=CONFERENCE, event_date='2026-09-24',
    venue='Zagreb, Hrvatsko katoličko sveučilište, Ilica 244',
    source=str(SOURCE.relative_to(ROOT)), source_sha256=sha(SOURCE),
    poster=str(args.poster), poster_sha256=sha(args.poster),
    flag_sha256=hashlib.sha256(flag['image']).hexdigest(),
    source_pdf_sha256=sha(SOURCE.with_suffix('.pdf')),
    title='Demokršćanske vrijednosti u digitalnom javnom prostoru: narativni okviri hrvatskih katoličkih medija od 2021. do 2026.',
    author='Luka Šikić', output=str(OUT / (STEM + '.html')))
(OUT / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(dict(slides=18, output=str(OUT), conference=CONFERENCE), ensure_ascii=False))
