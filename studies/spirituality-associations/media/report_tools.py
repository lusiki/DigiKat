"""Consistent PDF and Markdown report construction with explicit page sections."""
from pathlib import Path
import html,re
import matplotlib
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate,Paragraph,Spacer,Table,TableStyle,Image,PageBreak,KeepTogether
from PIL import Image as PILImage
WIDTH,HEIGHT=A4;MARGIN=47;CW=WIDTH-2*MARGIN
INK=colors.HexColor('#203844');TEAL=colors.HexColor('#216775');MUTED=colors.HexColor('#63747b')
FONT=Path(matplotlib.get_data_path())/'fonts/ttf'
for name,file in [('Report','DejaVuSans.ttf'),('ReportBold','DejaVuSans-Bold.ttf'),('ReportItalic','DejaVuSans-Oblique.ttf')]:
    pdfmetrics.registerFont(TTFont(name,str(FONT/file)))
pdfmetrics.registerFontFamily('Report',normal='Report',bold='ReportBold',italic='ReportItalic',boldItalic='ReportBold')
ST={
 'title':ParagraphStyle('title',fontName='ReportBold',fontSize=25,leading=31,textColor=INK,spaceAfter=16),
 'h1':ParagraphStyle('h1',fontName='ReportBold',fontSize=17,leading=22,textColor=TEAL,spaceAfter=14,keepWithNext=True),
 'h2':ParagraphStyle('h2',fontName='ReportBold',fontSize=11,leading=15,textColor=INK,spaceBefore=10,spaceAfter=6,keepWithNext=True),
 'body':ParagraphStyle('body',fontName='Report',fontSize=9.4,leading=14.3,textColor=INK,spaceAfter=9,allowWidows=0,allowOrphans=0),
 'small':ParagraphStyle('small',fontName='Report',fontSize=7.6,leading=11,textColor=MUTED,spaceAfter=7),
 'cell':ParagraphStyle('cell',fontName='Report',fontSize=7.6,leading=10.4,textColor=INK),
 'head':ParagraphStyle('head',fontName='ReportBold',fontSize=7.7,leading=10.5,textColor=colors.white),
 'kicker':ParagraphStyle('kicker',fontName='ReportBold',fontSize=10,leading=15,textColor=TEAL,spaceAfter=14)}
def markup(s):
    t=html.escape(str(s))
    t=re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',r'<link href="\2" color="#216775"><u>\1</u></link>',t)
    t=re.sub(r'\*\*([^*]+)\*\*',r'<b>\1</b>',t)
    return t
def footer(c,doc):
    c.saveState();c.setStrokeColor(colors.HexColor('#d4dfe1'));c.line(MARGIN,HEIGHT-32,WIDTH-MARGIN,HEIGHT-32)
    c.setFont('ReportBold',7.2);c.setFillColor(TEAL);c.drawString(MARGIN,HEIGHT-23,'DIGIKAT  /  ORGANISATIONS AND MEDIA')
    c.setFont('Report',7.2);c.setFillColor(MUTED);c.drawRightString(WIDTH-MARGIN,HEIGHT-23,'2021 - 2026 | Exploratory research')
    c.line(MARGIN,34,WIDTH-MARGIN,34);c.drawString(MARGIN,22,'Full merged dataset | Internal analytical report | 19 September 2026')
    c.drawRightString(WIDTH-MARGIN,22,str(doc.page));c.restoreState()
class Report:
    def __init__(self):self.story=[];self.md=[];self.section=0
    def p(self,text,style='body'):
        self.story.append(Paragraph(markup(text),ST[style]));self.md.append(str(text)+'\n')
    def title(self,text):self.p(text,'title')
    def h2(self,text):self.p(text,'h2')
    def page(self,title):
        if self.story:self.story.append(PageBreak())
        self.section+=1;self.story.append(Paragraph(markup(title),ST['h1']));self.md.append('\n## '+title+'\n')
    def table(self,headers,rows,widths=None):
        data=[[Paragraph(markup(v),ST['head']) for v in headers]]+[[Paragraph(markup(v),ST['cell']) for v in row] for row in rows]
        t=Table(data,colWidths=[CW*x for x in widths] if widths else [CW/len(headers)]*len(headers),repeatRows=1,hAlign='LEFT')
        t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),TEAL),('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#eff4f4')]),
            ('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),6),('RIGHTPADDING',(0,0),(-1,-1),6),
            ('TOPPADDING',(0,0),(-1,-1),6),('BOTTOMPADDING',(0,0),(-1,-1),6),('LINEBELOW',(0,-1),(-1,-1),.4,colors.HexColor('#ccd8da'))]))
        self.story.extend([t,Spacer(1,10)])
        self.md+=['| '+' | '.join(str(x) for x in headers)+' |','| '+' | '.join('---' for _ in headers)+' |']
        self.md+=['| '+' | '.join(str(x).replace('|','/') for x in row)+' |' for row in rows];self.md.append('')
    def figure(self,path,caption,maxheight=300):
        with PILImage.open(path) as img:w,h=img.size
        scale=min(CW/w,maxheight/h)
        self.story.append(Image(str(path),width=w*scale,height=h*scale,hAlign='CENTER'))
        self.p(caption,'small');self.md.append(f'![{caption}]({path.as_posix()})\n')
    def write(self,pdf,md):
        pdf.parent.mkdir(parents=True,exist_ok=True)
        SimpleDocTemplate(str(pdf),pagesize=A4,leftMargin=MARGIN,rightMargin=MARGIN,topMargin=48,bottomMargin=48,
            title='Spirituality-related associations in the media space, 2021-2026',author='DigiKat research workspace',
            subject='Full-period descriptive and exploratory landscape; provisional media search results').build(self.story,onFirstPage=footer,onLaterPages=footer)
        md.write_text('\n'.join(self.md),encoding='utf-8')
