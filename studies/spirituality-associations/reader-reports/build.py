"""Typeset both Croatian manuscripts. Each PAGE is checked for overflow."""
from pathlib import Path
import html, json, re
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.pagesizes import A4
from reportlab.platypus import Paragraph, Spacer, Table, TableStyle, Image, Frame
from reportlab.pdfgen.canvas import Canvas
from PIL import Image as PILImage
import pandas as pd
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]; OUT=ROOT/'output/pdf'
W,H=A4; M=45; CW=W-2*M
INK='#173e43'; TEAL='#789d96'; ORANGE='#b6592b'; PAPER='#fcfbf7'; MUTED='#597476'
for name,file in [('Body','calibri.ttf'),('Bold','calibrib.ttf'),('Italic','calibrii.ttf'),('Title','georgia.ttf')]:
    pdfmetrics.registerFont(TTFont(name,'C:/Windows/Fonts/'+file))
pdfmetrics.registerFontFamily('Body',normal='Body',bold='Bold',italic='Italic',boldItalic='Bold')
styles={
    'body':ParagraphStyle('body',fontName='Body',fontSize=11,leading=15.2,textColor=INK,spaceAfter=10),
    'title':ParagraphStyle('title',fontName='Title',fontSize=24,leading=29,textColor=INK,spaceAfter=17),
    'h2':ParagraphStyle('h2',fontName='Bold',fontSize=13,leading=17,textColor=INK,spaceBefore=6,spaceAfter=7),
    'note':ParagraphStyle('note',fontName='Body',fontSize=8.6,leading=11.5,textColor=MUTED,spaceAfter=10),
    'quote':ParagraphStyle('quote',fontName='Title',fontSize=16,leading=22,textColor=INK,spaceBefore=8,spaceAfter=15,leftIndent=12,borderPadding=8),
    'cell':ParagraphStyle('cell',fontName='Body',fontSize=9.6,leading=13,textColor=INK),
    'head':ParagraphStyle('head',fontName='Bold',fontSize=9.6,leading=13,textColor=colors.white),
}
def markup(text):
    text=html.escape(text)
    text=re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',r'<link href="\2" color="#417d83"><u>\1</u></link>',text)
    text=re.sub(r'\*\*([^*]+)\*\*',r'<b>\1</b>',text)
    text=re.sub(r'\*([^*]+)\*',r'<i>\1</i>',text)
    return text
def table(lines):
    rows=[[s.strip() for s in l.strip().strip('|').split('|')] for l in lines]
    rows=[rows[0]]+rows[2:]
    widths=[CW/len(rows[0])]*len(rows[0])
    if len(widths)==2:widths=[CW*.35,CW*.65]
    if len(widths)==3:
        widths=[CW*.65,CW*.17,CW*.18] if rows[0][1] in ['Objave','Broj objava'] else [CW*.36,CW*.47,CW*.17]
    t=Table([[Paragraph(markup(v),styles['head' if i==0 else 'cell']) for v in row] for i,row in enumerate(rows)],colWidths=widths,hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor(INK)),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.HexColor('#eef2ed'),colors.HexColor(PAPER)]),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),8),('RIGHTPADDING',(0,0),(-1,-1),8),('TOPPADDING',(0,0),(-1,-1),8),('BOTTOMPADDING',(0,0),(-1,-1),8)]))
    return t
def flow(text):
    blocks=re.split(r'\n\s*\n',text.strip()); story=[]
    for block in blocks:
        block=block.strip()
        if not block:continue
        if block.startswith('|'):story.extend([table(block.splitlines()),Spacer(1,12)]);continue
        m=re.match(r'!\[([^\]]*)\]\(([^)]+)\)',block)
        if m:
            path=HERE/m[2]
            with PILImage.open(path) as im:w,h=im.size
            maxheight=185 if re.search(r'cloud-[1-6]\.png$',m[2]) else 275
            scale=min(CW/w,maxheight/h)
            story.extend([Image(str(path),w*scale,h*scale),Spacer(1,7),Paragraph(markup(m[1]),styles['note'])]);continue
        if block.startswith('## '):style='h2';block=block[3:]
        elif block.startswith('~ '):style='note';block=block[2:]
        elif block.startswith('> '):style='quote';block=block[2:]
        else:style='body'
        story.append(Paragraph(markup(block.replace('\n',' ')),styles[style]))
    return story
def num(n):return f'{int(n):,}'.replace(',','.')
def expand(text):
    topics=pd.read_csv(HERE/'tables/topics.csv').set_index('topic')
    words=pd.read_csv(HERE/'tables/word_document_frequency.csv')
    for i in range(1,7):
        text=text.replace('{{topic'+str(i)+'}}',num(topics.loc[i,'items']))
        text=text.replace('{{share'+str(i)+'}}',f"{topics.loc[i,'share_pct']:.1f}".replace('.',','))
    for term in ['projekt','projekta','program','pomoc','ljudi','radionice','susret']:
        row=words[(words.topic==0)&(words.term==term)]
        text=text.replace('{{word:'+term+'}}',num(row.iloc[0].publication_days))
    facts=json.loads((HERE/'tables/organisation_facts.json').read_text(encoding='utf-8'))
    for key,value in facts.items():text=text.replace('{{'+key+'}}',value)
    t=HERE.parent/'output/tables/media-v1'
    annual=pd.read_csv(t/'annual_landscape.csv')
    facts['annual_table']='| Godina | Broj objava |\n|---|---:|\n'+'\n'.join(f'| {r.year if r.year!=2026 else "2026. do 10. rujna"} | {num(r.candidate_items)} |' for r in annual.itertuples())
    for key,value in facts.items():text=text.replace('{{'+key+'}}',value)
    assert '{{' not in text,'Unexpanded fact: '+str(re.findall(r'\{\{.*?\}\}',text))
    return text
def build(stem,pdfstem,title,subtitle,short):
    text=expand((HERE/f'{stem}.md').read_text(encoding='utf-8'))
    parts=re.split(r'<!-- PAGE: (.*?) \| (.*?) -->',text)
    pages=[(parts[i],parts[i+1],parts[i+2]) for i in range(1,len(parts),3)]
    path=OUT/f'{pdfstem}.pdf';OUT.mkdir(parents=True,exist_ok=True)
    c=Canvas(str(path),pagesize=A4);c.setTitle(title);c.setAuthor('DigiKat');c.setSubject('Udruge iz područja duhovnosti; pokazatelji, organizacije, mediji i teme 2021-2026')
    total=len(pages)+1
    def bg():c.setFillColor(colors.HexColor(PAPER));c.rect(0,0,W,H,fill=1,stroke=0)
    bg();c.setFillColor(colors.HexColor(ORANGE));c.setFont('Bold',10);c.drawString(M,H-58,'DIGIKAT  /  UDRUGE I JAVNI PROSTOR')
    story=[Paragraph(markup(title),ParagraphStyle('cover',parent=styles['title'],fontSize=37,leading=44)),Spacer(1,15),Paragraph(markup(subtitle),ParagraphStyle('sub',parent=styles['body'],fontSize=16,leading=22)),Spacer(1,24),Paragraph('1. siječnja 2021. - 10. rujna 2026.',styles['body']),Paragraph('22. rujna 2026.',styles['body'])]
    frame=Frame(M,220,CW,H-350,leftPadding=0,bottomPadding=0,rightPadding=0,topPadding=0);frame.addFromList(story,c);assert not story,'Cover overflow'
    c.setStrokeColor(colors.HexColor(TEAL));c.line(M,205,W-M,205)
    for x,big,small in [(M,'1.325','udruga u popisu'),(M+178,'23.436','objava uz nazive udruga'),(M+354,'2021-2026','razdoblje pregleda')]:
        c.setFillColor(colors.HexColor(INK));c.setFont('Title',23);c.drawString(x,165,big);c.setFont('Body',9.2);c.drawString(x,145,small)
    note='Organizacije, aktivnosti i medijski kanali. Pregled pokazatelja s tematskim i jezičnim profilima vodećih naziva u analiziranim objavama.'
    p=Paragraph(note,styles['note']);pw,ph=p.wrap(CW,90);p.drawOn(c,M,66)
    c.showPage()
    for number,(kicker,heading,body) in enumerate(pages,2):
        bg();c.setFillColor(colors.HexColor(ORANGE));c.setFont('Bold',9);c.drawString(M,H-35,f'{number:02d}  /  {kicker.upper()}')
        story=[Paragraph(markup(heading),styles['title'])]+flow(body)
        frame=Frame(M,65,CW,H-122,leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0)
        frame.addFromList(story,c)
        if story:raise RuntimeError(f'Overflow {stem} page {number}: {heading}; {len(story)} blocks remain')
        c.setStrokeColor(colors.HexColor('#cedbd4'));c.line(M,44,W-M,44)
        c.setFillColor(colors.HexColor(MUTED));c.setFont('Body',7.3);c.drawString(M,30,'DIGIKAT  /  '+short.upper()+'  /  22. 9. 2026.');c.drawRightString(W-M,30,f'{number} / {total}');c.showPage()
    c.save()
    (HERE/f'{stem}-resolved.md').write_text(text,encoding='utf-8')
    print(path,'pages',total)
    return {'file':str(path.relative_to(ROOT)),'pages':total}
if __name__=='__main__':
    results=[build('overview','udruge-duhovnosti-u-medijskom-prostoru','Udruge iz područja duhovnosti u medijskom prostoru','Vodeće organizacije, medijski kanali i javne aktivnosti','Udruge u medijskom prostoru'),build('language','udruge-duhovnosti-od-rijeci-do-javne-uloge','Udruge iz područja duhovnosti: od riječi do javne uloge','Riječi, teme i medijski profili vodećih organizacija','Od riječi do javne uloge')]
    (HERE/'tables/reports.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
