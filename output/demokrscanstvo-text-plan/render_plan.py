"""Render the separate Croatian textual-analysis plan in the report's visual style."""
from pathlib import Path
from xml.sax.saxutils import escape
import hashlib
import json
import re

from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, Table, TableStyle, Spacer

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
PDF = ROOT / 'output/pdf/demokrscanstvo-plan-tekstualne-dopune.pdf'
QA = ROOT / 'tmp/pdfs/demokrscanstvo-text-plan'
W, H = A4
M = 45
CW = W - 2 * M
INK = colors.HexColor('#173e43')
TEXT = colors.HexColor('#253b3e')
MUTED = colors.HexColor('#526b6f')
COPPER = colors.HexColor('#a9643b')
PAPER = colors.HexColor('#fcfbf7')
PALE = colors.HexColor('#eef2ef')
LINE = colors.HexColor('#cdd9d4')
GOLD = colors.HexColor('#e2b58a')

for name, file in [('Body', 'calibri.ttf'), ('BodyBold', 'calibrib.ttf'),
                   ('BodyItalic', 'calibrii.ttf'), ('Display', 'georgia.ttf')]:
    pdfmetrics.registerFont(TTFont(name, 'C:/Windows/Fonts/' + file))
pdfmetrics.registerFontFamily('Body', normal='Body', bold='BodyBold',
                            italic='BodyItalic', boldItalic='BodyBold')
ST = {
    'body': ParagraphStyle('body', fontName='Body', fontSize=11.2, leading=14.7,
                           textColor=TEXT, spaceAfter=8),
    'h1': ParagraphStyle('h1', fontName='Display', fontSize=23, leading=28,
                         textColor=INK, spaceAfter=14),
    'h2': ParagraphStyle('h2', fontName='BodyBold', fontSize=12.5, leading=16,
                         textColor=INK, spaceBefore=7, spaceAfter=6),
    'cell': ParagraphStyle('cell', fontName='Body', fontSize=10.5, leading=13.0,
                           textColor=TEXT),
    'head': ParagraphStyle('head', fontName='BodyBold', fontSize=9.8, leading=12.0,
                           textColor=colors.white),
    'small': ParagraphStyle('small', fontName='Body', fontSize=9.5, leading=12.4,
                            textColor=MUTED, spaceAfter=7),
}

def markup(s):
    s = re.sub('[\u2010-\u2014]', '-', s)
    s = escape(s)
    s = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', s)
    s = re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',
               r'<link href="\2" color="#a9643b"><u>\1</u></link>', s)
    return s

def para(s, style='body'):
    assert '\ufffd' not in s
    return Paragraph(markup(s), ST[style])

WIDTHS = {
    2: [.22, .64, .14], 3: [.44, .56], 4: [.24, .32, .44],
    5: [.23, .40, .37], 6: [.24, .76], 9: [.25, .41, .34],
    10: [.49, .51], 14: [.27, .39, .34], 15: [.23, .44, .33],
    16: [.24, .43, .33], 17: [.23, .39, .38]
}

def table(lines, pg):
    rows = []
    for line in lines:
        cells = [x.strip() for x in line.strip().strip('|').split('|')]
        if all(re.fullmatch(r'[:\- ]+', c) for c in cells):
            continue
        rows.append(cells)
    cols = len(rows[0])
    widths = WIDTHS.get(pg, [1/cols] * cols)
    data = [[para(c, 'head' if i == 0 else 'cell') for c in row]
            for i, row in enumerate(rows)]
    t = Table(data, colWidths=[CW * x for x in widths], hAlign='LEFT')
    rules = [('BACKGROUND', (0, 0), (-1, 0), INK),
             ('VALIGN', (0, 0), (-1, -1), 'TOP'),
             ('LEFTPADDING', (0, 0), (-1, -1), 8),
             ('RIGHTPADDING', (0, 0), (-1, -1), 8),
             ('TOPPADDING', (0, 0), (-1, -1), 6),
             ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
             ('LINEBELOW', (0, -1), (-1, -1), .6, LINE)]
    for i in range(1, len(rows)):
        if i % 2:
            rules.append(('BACKGROUND', (0, i), (-1, i), PALE))
    t.setStyle(TableStyle(rules))
    return t

def parse_page(raw, pg):
    lines = raw.strip().splitlines()
    items = []
    i = 0
    while i < len(lines):
        ln = lines[i].strip()
        if not ln:
            i += 1
            continue
        if ln.startswith('|'):
            block = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                block.append(lines[i]); i += 1
            items.extend([table(block, pg), Spacer(1, 11)])
            continue
        if ln.startswith('# '):
            items.append(para(ln[2:], 'h1')); i += 1; continue
        if ln.startswith('## '):
            items.append(para(ln[3:], 'h2')); i += 1; continue
        block = [ln]
        i += 1
        while i < len(lines) and lines[i].strip() and not lines[i].startswith(('#', '|')):
            # Reference entries and numbered procedures retain their own rows.
            if re.match(r'^\d+\. ', lines[i]):
                break
            block.append(lines[i].strip()); i += 1
        items.append(para(' '.join(block), 'small' if pg == 18 else 'body'))
    return items

def cover(c):
    c.setFillColor(PAPER); c.rect(0, 0, W, H, fill=1, stroke=0)
    c.setFillColor(INK); c.rect(0, 267, W, H - 267, fill=1, stroke=0)
    c.setFillColor(GOLD); c.setFont('BodyBold', 10)
    c.drawString(M, H - 62, 'DIGIKAT   /   PLAN TEKSTUALNE DOPUNE')
    c.setFillColor(colors.white); c.setFont('Display', 35)
    c.drawString(M, H - 151, 'Demokršćanstvo:')
    c.drawString(M, H - 199, 'od riječi do argumenta')
    c.setFont('Body', 17); c.setFillColor(colors.HexColor('#e1ebe5'))
    c.drawString(M, H - 245, 'Detaljan plan analize za pregled')
    c.setStrokeColor(GOLD); c.setLineWidth(1.5); c.line(M, H - 278, M+80, H - 278)
    c.setFillColor(colors.white); c.setFont('Body', 11.5)
    c.drawString(M, H - 312, 'Samostalna dopuna analitičkom izvještaju 1.0')
    c.drawString(M, H - 333, 'Metodološko uporište: Text Mining with R')
    c.drawString(M, H - 354, 'Julia Silge i David Robinson  |  19. rujna 2026.')
    for x, val, label in [(M, '2.306', 'zapisa u polaznoj zbirci'),
                           (M+178, '2.253', 'skupine jednakih tekstova'),
                           (M+350, '5', 'analitičkih modula')]:
        c.setFillColor(GOLD); c.setFont('Display', 25); c.drawString(x, 340, val)
        c.setFillColor(colors.white); c.setFont('Body', 9.5); c.drawString(x, 319, label)
    p = para('Koje ideje nose političko ime i kada postaju obrazloženje javne odluke?', 'h1')
    _, hh = p.wrap(CW, 200); p.drawOn(c, M, 231 - hh)
    p = para('Rječnik, fraze, načela, stavovi i trajnost sadržaja.\n'
             'Provjereno polazište; predložena analiza još nije izvedena.', 'body')
    _, hh = p.wrap(CW, 100); p.drawOn(c, M, 115 - hh)
    c.setFillColor(MUTED); c.setFont('Body', 8.5)
    c.drawString(M, 29, 'PRIJEDLOG 1.0  /  Hrvatski tekst i vizualni kontinuitet s izvornim izvještajem')

def frame(c, pg, kicker, total):
    c.setFillColor(PAPER); c.rect(0, 0, W, H, fill=1, stroke=0)
    c.setFillColor(COPPER); c.setFont('BodyBold', 9.2)
    c.drawString(M, H - 36, f'{pg:02d}  /  {kicker.upper()}')
    c.setStrokeColor(LINE); c.setLineWidth(.6); c.line(M, 44, W-M, 44)
    c.setFillColor(MUTED); c.setFont('Body', 8.2)
    c.drawString(M, 29, 'DIGIKAT  /  PLAN TEKSTUALNE DOPUNE 1.0  /  19. 9. 2026.')
    c.drawRightString(W-M, 29, f'{pg} / {total}')

def main():
    source = (HERE/'plan.md').read_text(encoding='utf-8')
    chunks = re.split(r'<!-- PAGE: (\d+) \| (.+?) -->', source)
    pages = [(int(chunks[i]), chunks[i+1], parse_page(chunks[i+2], int(chunks[i])))
             for i in range(1, len(chunks), 3)]
    assert [p[0] for p in pages] == list(range(2, 19))
    QA.mkdir(parents=True, exist_ok=True)
    PDF.parent.mkdir(parents=True, exist_ok=True)
    layout = []
    for pg, kicker, items in pages:
        height = sum(o.getSpaceBefore() + o.wrap(CW, 10000)[1] + o.getSpaceAfter() for o in items)
        layout.append({'page': pg, 'content_height': round(height, 2),
                       'bottom_y': round(H-61-height, 2)})
    (QA/'layout.json').write_text(json.dumps(layout, indent=2), encoding='utf-8')
    over = [p for p in layout if p['bottom_y'] < 59]
    if over:
        raise ValueError('Page overflow: ' + json.dumps(over))
    c = canvas.Canvas(str(PDF), pagesize=A4, pageCompression=1)
    c.setTitle('Demokršćanstvo: od riječi do argumenta - plan tekstualne dopune')
    c.setAuthor('DigiKat; priprema plana uz pomoć Codex AI-ja')
    c.setSubject('Prijedlog analize zamrznute zbirke; metodološko uporište Text Mining with R')
    c.setViewerPreference('DisplayDocTitle', 'true')
    c.bookmarkPage('cover'); c.addOutlineEntry('Naslovnica', 'cover', 0)
    cover(c); c.showPage()
    for pg, kicker, items in pages:
        c.bookmarkPage('p'+str(pg)); c.addOutlineEntry(kicker, 'p'+str(pg), 0)
        frame(c, pg, kicker, 18)
        y = H-61
        for obj in items:
            y -= obj.getSpaceBefore()
            _, hh = obj.wrap(CW, 10000)
            y -= hh
            obj.drawOn(c, M, y)
            y -= obj.getSpaceAfter()
        c.showPage()
    c.save()
    print(json.dumps({'pdf': str(PDF), 'pages': 18,
                      'lowest_bottom': min(p['bottom_y'] for p in layout),
                      'sha256': hashlib.sha256(PDF.read_bytes()).hexdigest()}, ensure_ascii=False))

if __name__ == '__main__':
    main()
