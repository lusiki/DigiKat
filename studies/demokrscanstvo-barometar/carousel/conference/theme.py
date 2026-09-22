"""Apply the approved conference design to the evidence-driven carousel."""
from pathlib import Path
import base64
import re

HERE = Path(__file__).resolve().parent
CONFERENCE = 'Izazovi i budućnost demokršćanstva u Hrvatskoj i Europi'


def apply_conference_theme(html):
    image_uri = 'data:image/jpeg;base64,' + base64.b64encode((HERE / 'flag.jpg').read_bytes()).decode('ascii')
    css = (HERE / 'style.css').read_text(encoding='utf-8')
    css += '\n:root{--conference-image:url("' + image_uri + '")}\n'
    html = html.replace('</style>', css + '</style>', 1)
    html = html.replace('<span>Hrvatsko katoličko sveučilište</span></div><div class="content">',
                        '<span>24. rujna 2026. · Zagreb</span></div><div class="content">', 1)
    html = html.replace('<div class="cover-title">',
        '<div class="conference-heading"><p class="event-label">Izlaganje na znanstveno-stručnom skupu</p>'
        '<p class="event-title">Izazovi i budućnost demokršćanstva<br>u Hrvatskoj i Europi</p></div>'
        '<div class="cover-title">', 1)
    html = html.replace('<span>DigiKat</span><span>',
        '<span>DigiKat</span><span class="conference-context">Zagreb · 24. rujna 2026.</span><span>')
    html = html.replace('<span class="conference-context">Zagreb · 24. rujna 2026.</span>', '', 1)
    html = html.replace('>Podaci do 10. rujna 2026.</a>',
        '><span class="conference-venue">24. rujna 2026. · Zagreb, Hrvatsko katoličko sveučilište</span>'
        '<span class="data-date">Podaci do 10. rujna 2026.</span></a>', 1)
    closing = '<p class="conference-closing">Izlaganje na skupu „' + CONFERENCE + '”.</p>'
    html, count = re.subn(r'(<section class="slide reading dark".*?)(</div><footer>)',
                          lambda m: m[1] + closing + m[2], html, count=1, flags=re.S)
    assert count == 1 and html.count('class="slide ') == 18
    return html
