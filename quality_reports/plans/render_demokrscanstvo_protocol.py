"""Render the reviewed Croatian analytical protocol. No empirical computation."""
from pathlib import Path
import re
import json
from xml.sax.saxutils import escape

from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, Table, TableStyle, Spacer, Flowable

ROOT = Path(__file__).resolve().parents[2]
SOURCE = Path(__file__).with_name('2026-09-19_demokrscanstvo-pdf-protocol.md')
OUTPUT = ROOT / 'output/pdf/demokrscanstvo-plan-analize.pdf'
QA = ROOT / 'tmp/pdfs/demokrscanstvo-plan'
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
WHITE = colors.white

for name, filename in [('Body','calibri.ttf'),('BodyBold','calibrib.ttf'),
                       ('BodyItalic','calibrii.ttf'),('Display','georgia.ttf'),
                       ('DisplayBold','georgiab.ttf')]:
    pdfmetrics.registerFont(TTFont(name, f'C:/Windows/Fonts/{filename}'))
pdfmetrics.registerFontFamily('Body', normal='Body', bold='BodyBold', italic='BodyItalic', boldItalic='BodyBold')
pdfmetrics.registerFontFamily('Display', normal='Display', bold='DisplayBold', italic='Display', boldItalic='DisplayBold')

def inline(raw):
    # Source text uses Markdown inline markers, with no raw HTML.
    value = escape(raw)
    value = re.sub(r'\[([^]]+)\]\((https?://[^)]+)\)', lambda m: f'<link href="{m[2]}" color="#a9643b"><u>{m[1]}</u></link>', value)
    value = re.sub(r'\*\*(.+?)\*\*', r'<b>\1</b>', value)
    value = re.sub(r'`([^`]+)`', r'<font color="#173e43">\1</font>', value)
    return value

def styles(size=10.5):
    return {
      'body': ParagraphStyle('body',fontName='Body',fontSize=size,leading=size*1.32,textColor=TEXT,spaceAfter=8),
      'h1': ParagraphStyle('h1',fontName='Display',fontSize=24,leading=28.5,textColor=INK,spaceAfter=14),
      'h2': ParagraphStyle('h2',fontName='BodyBold',fontSize=12.2,leading=16,textColor=INK,spaceBefore=8,spaceAfter=5),
      'list': ParagraphStyle('list',fontName='Body',fontSize=size,leading=size*1.30,textColor=TEXT,leftIndent=12,firstLineIndent=-12,spaceAfter=5),
      'cell': ParagraphStyle('cell',fontName='Body',fontSize=size-.65,leading=(size-.65)*1.24,textColor=TEXT),
      'thead': ParagraphStyle('thead',fontName='BodyBold',fontSize=size-.75,leading=(size-.75)*1.2,textColor=WHITE),
    }

COLS = {
  2:[.22,.39,.39],3:[.46,.54],4:[.20,.17,.17,.46],5:[.22,.32,.46],
  8:[.19,.41,.40],9:[.24,.76],12:[.19,.43,.38],13:[.30,.32,.38],
  14:[.22,.47,.31],15:[.29,.17,.54]
}

def make_table(lines, page, st):
    rows = [[x.strip() for x in line.strip().strip('|').split('|')] for line in lines]
    rows = [r for r in rows if not all(re.fullmatch(r':?-+:?', c.replace(' ','')) for c in r)]
    cells=[]
    for i,row in enumerate(rows):
        cells.append([Paragraph(inline(c) if i==0 else (f'<b>{inline(c)}</b>' if j==0 else inline(c)),st['thead' if i==0 else 'cell']) for j,c in enumerate(row)])
    widths=COLS.get(page,[1/len(rows[0])]*len(rows[0]))
    tab=Table(cells,colWidths=[CW*w for w in widths],hAlign='LEFT')
    commands=[('BACKGROUND',(0,0),(-1,0),INK),('VALIGN',(0,0),(-1,-1),'TOP'),
      ('LEFTPADDING',(0,0),(-1,-1),9),('RIGHTPADDING',(0,0),(-1,-1),9),
      ('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7),
      ('LINEBELOW',(0,-1),(-1,-1),.6,LINE)]
    for i in range(1,len(rows)):
        if i%2: commands.append(('BACKGROUND',(0,i),(-1,i),PALE))
        commands.append(('LINEBELOW',(0,i),(-1,i),.25,LINE))
    tab.setStyle(TableStyle(commands))
    return tab

def flowables(md, page, size):
    st=styles(size)
    output=[]
    lines=md.strip().splitlines()
    i=0
    while i<len(lines):
        line=lines[i].strip()
        if not line: i+=1; continue
        if line.startswith('|'):
            chunk=[]
            while i<len(lines) and lines[i].strip().startswith('|'):
                chunk.append(lines[i]); i+=1
            output.extend([make_table(chunk,page,st),Spacer(1,10)])
            continue
        if line.startswith('# '):
            output.append(Paragraph(inline(line[2:]),st['h1']))
        elif line.startswith('## '):
            output.append(Paragraph(inline(line[3:]),st['h2']))
        elif line.startswith('- '):
            output.append(Paragraph('•  '+inline(line[2:]),st['list']))
        elif re.match(r'^\d+\. ',line):
            output.append(Paragraph(inline(line),st['list']))
        else:
            output.append(Paragraph(inline(line),st['body']))
        i+=1
    return output

def height(items):
    return sum(f.getSpaceBefore()+f.wrap(CW,10000)[1]+f.getSpaceAfter() for f in items)

def cover(c):
    c.setFillColor(PAPER); c.rect(0,0,W,H,fill=1,stroke=0)
    c.setFillColor(INK); c.rect(0,267,W,H-267,fill=1,stroke=0)
    # Editorial geometry reflects the three analytical layers; no fictitious data.
    c.saveState(); c.setStrokeColor(colors.HexColor('#315960')); c.setLineWidth(.7)
    for r in [70,105,140,175]: c.circle(W-10,H-165,r,stroke=1,fill=0)
    c.restoreState()
    c.setFillColor(GOLD); c.setFont('BodyBold',10)
    c.drawString(M,H-61,'DIGIKAT   /   MEDIJSKI BAROMETAR DEMOKRŠĆANSTVA')
    c.setFillColor(WHITE); c.setFont('Display',38)
    c.drawString(M,H-158,'Demokršćanstvo')
    c.drawString(M,H-207,'u javnom govoru')
    c.setFont('Body',17); c.setFillColor(colors.HexColor('#e1ebe5'))
    c.drawString(M,H-253,'Identitet, načela i društvena pitanja')
    c.setStrokeColor(GOLD); c.setLineWidth(1.5); c.line(M,H-285,M+77,H-285)
    c.setFillColor(WHITE); c.setFont('BodyBold',12)
    c.drawString(M,H-324,'ANALITIČKI PROTOKOL I NACRT IZVJEŠTAJA')
    c.setFont('Body',11)
    c.drawString(M,H-344,'Revidirani plan 2.0  |  19. rujna 2026.')
    columns=[(M,'2.306','uključenih objava'),(M+180,'10','postojećih tema'),(M+328,'2021 - 2026','razdoblje zbirke')]
    for x,value,label in columns:
        c.setFillColor(GOLD); c.setFont('Display',23 if len(value)<9 else 21); c.drawString(x,333,value)
        c.setFillColor(WHITE); c.setFont('Body',10); c.drawString(x,312,label)
    p=Paragraph('Plan za izvještaj koji povezuje medijsku vidljivost, sadržaj ideja i njihovu primjenu u javnim raspravama.',ParagraphStyle('cover',fontName='Display',fontSize=17,leading=23,textColor=INK))
    _,hh=p.wrap(CW,200); p.drawOn(c,M,228-hh)
    p=Paragraph('Najprije analiza i samostalan PDF. Zatim procjena njegove jasnoće i vrijednosti, pa odabir sadržaja za barometar.',ParagraphStyle('coverbody',fontName='Body',fontSize=11,leading=15,textColor=MUTED))
    _,hh=p.wrap(CW-30,150); p.drawOn(c,M,142-hh)
    c.setFillColor(COPPER); c.setFont('BodyBold',9)
    c.drawString(M,58,'PITANJA  /  METODE  /  KONTROLE  /  VIZUALI  /  TUMAČENJE')
    c.setFillColor(MUTED); c.setFont('Body',8.5); c.drawString(M,36,'Dokument planiranja. Novi empirijski rezultati nisu dio ovog izdanja.')

def frame(c,page,kicker):
    c.setFillColor(PAPER); c.rect(0,0,W,H,fill=1,stroke=0)
    c.setFillColor(COPPER); c.setFont('BodyBold',9.3)
    c.drawString(M,H-36,f'{page:02d}  /  {kicker.upper()}')
    c.setStrokeColor(LINE); c.setLineWidth(.6); c.line(M,44,W-M,44)
    c.setFont('Body',8.2); c.setFillColor(MUTED)
    c.drawString(M,29,'DIGIKAT  /  ANALITIČKI PROTOKOL 2.0  /  19. 9. 2026.')
    c.setFont('BodyBold',8.5); c.drawRightString(W-M,29,f'{page} / 16')

def main():
    source=SOURCE.read_text(encoding='utf-8')
    for bad in '\u2010\u2011\u2012\u2013\u2014\ufffd':
        assert bad not in source, f'Unsupported dash/replacement {ord(bad):x}'
    sections=re.split(r'<!-- PAGE: (\d+) \| ([^>]+) -->',source)
    assert (len(sections)-1)//3==15
    OUTPUT.parent.mkdir(parents=True,exist_ok=True); QA.mkdir(parents=True,exist_ok=True)
    c=canvas.Canvas(str(OUTPUT),pagesize=A4,pageCompression=1)
    c.setTitle('Demokršćanstvo u javnom govoru - analitički protokol')
    c.setAuthor('DigiKat')
    c.setSubject('Revidirani plan analize i nacrt samostalnog izvještaja; 19. rujna 2026.')
    c.setKeywords('demokršćanstvo, mediji, kršćanska socijalna misao, analitički plan')
    c.setViewerPreference('DisplayDocTitle', 'true')
    c.bookmarkPage('cover'); c.addOutlineEntry('Naslovnica','cover',0)
    cover(c); c.showPage()
    layout=[]
    for idx in range(1,len(sections),3):
        page=int(sections[idx]); kicker=sections[idx+1].strip(); md=sections[idx+2]
        c.bookmarkPage(f'p{page}'); c.addOutlineEntry(kicker,f'p{page}',0)
        frame(c,page,kicker)
        available=H-61-60
        size=11.2
        while size>=9.9:
            items=flowables(md,page,size); hh=height(items)
            if hh<=available: break
            size=round(size-.1,1)
        if hh>available: raise ValueError(f'Page {page} overflows: {hh:.1f} > {available:.1f}')
        y=H-61
        for item in items:
            y-=item.getSpaceBefore()
            _,h=item.wrap(CW,10000); y-=h; item.drawOn(c,M,y)
            y-=item.getSpaceAfter()
        layout.append({'page':page,'body_font':size,'content_height':round(hh,2),'bottom_y':round(y,2)})
        c.showPage()
    c.save()
    (QA/'layout.json').write_text(json.dumps(layout,indent=2),encoding='utf-8')
    print(json.dumps({'output':str(OUTPUT),'pages':16,'layout':layout},ensure_ascii=False,indent=2))

if __name__=='__main__': main()
