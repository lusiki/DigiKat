"""Typeset the generated research report as a portable PDF."""
import html
from pathlib import Path
import re
import matplotlib
from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, Table, TableStyle, KeepTogether
from common import ROOT

FONTS=Path(matplotlib.get_data_path())/'fonts/ttf'
for name,file in [('Research','DejaVuSans.ttf'),('ResearchBold','DejaVuSans-Bold.ttf'),('ResearchItalic','DejaVuSans-Oblique.ttf')]:
    pdfmetrics.registerFont(TTFont(name,str(FONTS/file)))
pdfmetrics.registerFontFamily('Research',normal='Research',bold='ResearchBold',italic='ResearchItalic',boldItalic='ResearchBold')

def markup(text):
    text=html.escape(text)
    def link(m):
        label,url=m.groups()
        if url.startswith('https://'):return f'<link href="{url}" color="#205978">{label}</link>'
        return label
    text=re.sub(r'\[([^\]]+)\]\(([^)]+)\)',link,text)
    text=re.sub(r'`([^`]+)`',r'<font size="9">\1</font>',text)
    text=re.sub(r'\*\*([^*]+)\*\*',r'<b>\1</b>',text)
    return text

def main():
    out=ROOT/'output/report';out.mkdir(exist_ok=True)
    target=out/'spirituality_associations_exploratory_report.pdf'
    styles={
     'title':ParagraphStyle('title',fontName='ResearchBold',fontSize=22,leading=28,textColor=colors.black,spaceAfter=16),
     'h2':ParagraphStyle('h2',fontName='ResearchBold',fontSize=14,leading=19,textColor=colors.black,spaceBefore=16,spaceAfter=9,keepWithNext=True),
     'body':ParagraphStyle('body',fontName='Research',fontSize=10.5,leading=15,spaceAfter=10),
     'cell':ParagraphStyle('cell',fontName='Research',fontSize=8.5,leading=11),
     'head':ParagraphStyle('head',fontName='ResearchBold',fontSize=8.5,leading=11),
    }
    width=letter[0]-108
    doc=SimpleDocTemplate(str(target),pagesize=letter,rightMargin=54,leftMargin=54,topMargin=49,bottomMargin=48,
                         title='Croatia spirituality associations and public visibility',author='DigiKat research project')
    lines=(ROOT/'EXPLORATORY_REPORT.md').read_text(encoding='utf-8').splitlines()
    story=[];i=0
    while i<len(lines):
        line=lines[i].strip()
        if not line:i+=1;continue
        if line.startswith('# '): story.append(Paragraph(markup(line[2:]),styles['title']))
        elif line.startswith('## '):story.append(Paragraph(markup(line[3:]),styles['h2']))
        elif line.startswith('!['):
            filename=re.search(r'\]\(([^)]+)\)',line).group(1);path=ROOT/filename
            with PILImage.open(path) as image: w,h=image.size
            story.append(Image(str(path),width=width,height=width*h/w));story.append(Spacer(1,8))
        elif line.startswith('|'):
            rows=[]
            while i<len(lines) and lines[i].strip().startswith('|'):
                cells=[c.strip() for c in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r'[:\-]+',c or '-') for c in cells):rows.append(cells)
                i+=1
            if len(rows[0])==4: ratios=[.47,.16,.16,.21]
            else:ratios=[.39,.23,.38]
            parsed=[[Paragraph(markup(c),styles['head'] if ri==0 else styles['cell']) for c in row] for ri,row in enumerate(rows)]
            table=Table(parsed,colWidths=[width*v for v in ratios],repeatRows=1,hAlign='LEFT')
            table.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#deebf2')),
               ('GRID',(0,0),(-1,-1),.4,colors.HexColor('#d9d9d9')),('VALIGN',(0,0),(-1,-1),'MIDDLE'),
               ('LEFTPADDING',(0,0),(-1,-1),7),('RIGHTPADDING',(0,0),(-1,-1),7),
               ('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7)]))
            story.extend([table,Spacer(1,12)]);continue
        else:
            paragraph=[line]
            while i+1<len(lines) and lines[i+1].strip() and not lines[i+1].startswith(('#','|','![')):
                i+=1;paragraph.append(lines[i].strip())
            story.append(Paragraph(markup(' '.join(paragraph)),styles['body']))
        i+=1
    def footer(canvas,doc):
        canvas.setFont('Research',8);canvas.setFillColor(colors.HexColor('#63727d'))
        canvas.drawString(54,27,'DigiKat  |  Exploratory research  |  19 September 2026')
        canvas.drawRightString(letter[0]-54,27,str(doc.page))
    doc.build(story,onFirstPage=footer,onLaterPages=footer)
    print(target)

if __name__=='__main__':main()
