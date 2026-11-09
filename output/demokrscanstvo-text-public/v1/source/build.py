"""Build a standalone public PDF, editable Markdown and accessible HTML.

All prose comes from manuscript.md. Tables and cloud sizes use prepared CSVs.
Cloud position and colour are decorative; frequency is encoded only by size.
"""
from pathlib import Path
from collections import defaultdict
import csv, hashlib, html, json, math, random, re, shutil, xml.etree.ElementTree as ET
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph, Flowable, Spacer, Table, TableStyle
from reportlab.graphics.shapes import Drawing, Rect, String, Line
from reportlab.graphics import renderSVG

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
OUT=ROOT/'output/demokrscanstvo-text-public/v1'
PORTABLE=(HERE.parent/'tables/topics.csv').exists()
if PORTABLE: OUT=HERE.parent
FIG=OUT/'figures'; FIG.mkdir(parents=True,exist_ok=True)
INTERNAL=OUT/'internal'; INTERNAL.mkdir(exist_ok=True)
PDF=ROOT/'output/pdf/demokrscanstvo-od-rijeci-do-argumenta.pdf'
if PORTABLE: PDF=OUT/'demokrscanstvo-od-rijeci-do-argumenta.pdf'
W,H=A4; M=45; CW=W-2*M
INK='#173e43'; COPPER='#94512f'; MUTED='#496268'; PAPER='#fcfbf7'; PALE='#eef2ef'; LINE='#cdd9d4'; GOLD='#e2b58a'
for name,fn in [('Body','calibri.ttf'),('BodyBold','calibrib.ttf'),('BodyItalic','calibrii.ttf'),('Display','georgia.ttf')]:
    pdfmetrics.registerFont(TTFont(name,'C:/Windows/Fonts/'+fn))
pdfmetrics.registerFontFamily('Body',normal='Body',bold='BodyBold',italic='BodyItalic',boldItalic='BodyBold')
ST={
 'body':ParagraphStyle('body',fontName='Body',fontSize=11.3,leading=15.1,textColor=colors.HexColor(INK),spaceAfter=9),
 'h1':ParagraphStyle('h1',fontName='Display',fontSize=24,leading=29,textColor=colors.HexColor(INK),spaceAfter=16),
 'h2':ParagraphStyle('h2',fontName='BodyBold',fontSize=13,leading=17,textColor=colors.HexColor(INK),spaceBefore=7,spaceAfter=6),
 'small':ParagraphStyle('small',fontName='Body',fontSize=9.4,leading=12.2,textColor=colors.HexColor(MUTED),spaceAfter=9),
 'cell':ParagraphStyle('cell',fontName='Body',fontSize=10.6,leading=13.6,textColor=colors.HexColor(INK)),
 'pull':ParagraphStyle('pull',fontName='Display',fontSize=16.5,leading=21.5,textColor=colors.HexColor(INK)),
 'panel':ParagraphStyle('panel',fontName='BodyBold',fontSize=12.2,leading=15,textColor=colors.HexColor(INK)),
 'panelbody':ParagraphStyle('panelbody',fontName='Body',fontSize=10.3,leading=13.3,textColor=colors.HexColor(INK)),
}
def rows(p):return list(csv.DictReader(p.open(encoding='utf-8-sig')))
def num(n):return f'{int(n):,}'.replace(',','.')
def dec(n):return f'{float(n):.1f}'.replace('.',',')
def markup(s):
    s=html.escape(s)
    s=re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',lambda m:f'<link href="{m[2]}" color="{COPPER}"><u>{m[1]}</u></link>',s)
    s=re.sub(r'\*\*(.+?)\*\*',r'<b>\1</b>',s)
    s=re.sub(r'\*(.+?)\*',r'<i>\1</i>',s)
    return s
def p(s,style='body'):return Paragraph(markup(s),ST[style])
TOP={r['topic']:r for r in rows(OUT/'tables/topics.csv')}
CLOUDS=defaultdict(list)
for r in rows(OUT/'tables/word-clouds.csv'):
    r['texts']=int(r['texts']);r['rank']=int(r['rank']);r['denominator']=int(r['denominator']); CLOUDS[r['scope']].append(r)
PHRASES=rows(OUT/'tables/phrases.csv')
COMMENTS={
 't01':'Stranka i politička orijentacija stavljaju u prvi plan pitanje pripadnosti.',
 't02':'Domoljublje, državotvornost i narodnjaštvo čine prepoznatljiv jezik političkog nasljeđa.',
 't03':'Ime HDZ-a povezuje se s vrijednostima, ideologijom i svjetonazorom.',
 't04':'Desni centar označuje položaj, uz narodnjačke i domoljubne odrednice.',
 't05':'Obitelj je dio rječnika nacionalnog identiteta, interesa i zajednice.',
 't09':'Vrijednosti su zajednički naziv; život i obitelj približavaju područja rasprave.',
 't06':'Europa i europske institucije stoje uz izbore, kandidate i budućnost.',
 't08':'Katolički, sveučilište i zbornik upućuju na prostor stručnih i javnih razgovora.',
 't07':'Izborna skupina ističe političku scenu i aktere poput Miroslava Škore.',
 't10':'Njemački i CDU označuju stranački okvir; Zapad proširuje međunarodnu dimenziju.',
}
CLOUD_LAYOUT=[]
def save_svg(d,name):
    target=FIG/f'{name}.svg';renderSVG.drawToFile(d,str(target))
    tree=ET.parse(target);ns='http://www.w3.org/2000/svg'
    ET.register_namespace('',ns)
    for el in tree.iter('{'+ns+'}text'):
        style=el.get('style','');font=re.search(r'font-family:\s*(\w+)',style);size=re.search(r'font-size:\s*([\d.]+)',style)
        if font and size and el.text:
            width=pdfmetrics.stringWidth(el.text,font[1],float(size[1]))
            el.set('textLength',str(width));el.set('lengthAdjust','spacingAndGlyphs')
            style=style.replace('font-family: '+font[1]+';', 'font-family: Calibri, Arial, sans-serif; font-weight: '+('700' if font[1]=='BodyBold' else '400')+';')
            el.set('style',style)
    tree.write(target,encoding='utf-8',xml_declaration=True)

def cloud(key,width,height):
    rr=CLOUDS[key]; maxn=rr[0]['texts']; minfs=10.1 if key!='all' else 12
    base=30 if key!='all' else 43
    for factor in [1,.94,.88,.82,.76,.70,.64,.58]:
        placed=[]; rng=random.Random(20260919+sum(map(ord,key)))
        for r in rr:
            fs=max(minfs,base*math.sqrt(r['texts']/maxn)*factor)
            fs=min(fs,(width-10)/max(1,pdfmetrics.stringWidth(r['word'],'BodyBold',1)))
            tw=pdfmetrics.stringWidth(r['word'],'BodyBold',fs); th=fs*1.2
            candidates=[(width/2-tw/2,height/2-th/2)]
            # Search a deterministic spread of positions, favouring central space.
            candidates += [(rng.uniform(3,max(3,width-tw-3)),rng.uniform(3,max(3,height-th-3))) for _ in range(4500)]
            candidates.sort(key=lambda q:((q[0]+tw/2-width/2)/(width/2))**2+((q[1]+th/2-height/2)/(height/2))**2)
            found=False
            for x,y in candidates:
                box=(x,y,x+tw,y+th)
                if x<2 or y<2 or box[2]>width-2 or box[3]>height-2:continue
                if any(not (box[2]+2<=b[0] or box[0]>=b[2]+2 or box[3]+2<=b[1] or box[1]>=b[3]+2) for b,_,_,_ in placed):continue
                placed.append((box,r,fs,[INK,COPPER,MUTED][(r['rank']-1)%3]));found=True;break
            if not found:break
        if len(placed)==len(rr):break
    if len(placed)!=len(rr):raise ValueError(f'Cloud {key}: only {len(placed)}/{len(rr)} fit')
    d=Drawing(width,height)
    for box,r,fs,col in placed:
        d.add(String(box[0],box[1]+fs*.24,r['word'],fontName='BodyBold',fontSize=fs,fillColor=colors.HexColor(col)))
        CLOUD_LAYOUT.append({'scope':key,'word':r['word'],'texts':r['texts'],'box':box,'font_size':fs,'canvas':[width,height]})
    save_svg(d,f'cloud-{key}')
    return d

def graph(data,labelkey,name,width=CW,height=340):
    d=Drawing(width,height); left=205;right=width-66;top=height-10; rowh=(height-42)/len(data)
    maxn=max(int(r['texts']) for r in data)
    for i,r in enumerate(data):
        y=top-(i+.65)*rowh
        label=p(r[labelkey],'cell');_,ph=label.wrap(left-12,100)
        # Render Paragraphs through a wrapper flowable instead of SVG label wrapping.
        import textwrap
        lines=textwrap.wrap(r[labelkey],35 if name=='topics' else 37)
        for j,line in enumerate(lines):
            d.add(String(left-9,y+(len(lines)-1)*6.5-j*13,line,fontName='Body',fontSize=10.5,textAnchor='end',fillColor=colors.HexColor(INK)))
        n=int(r['texts']);bw=(right-left)*n/maxn
        d.add(Rect(left,y-5,bw,12,fillColor=colors.HexColor(INK if i%2==0 else '#587e75'),strokeColor=None))
        d.add(String(left+bw+6,y-2,f'{num(n)} | {dec(100*n/2253)}%',fontName='Body',fontSize=9.7,fillColor=colors.HexColor(INK)))
    d.add(String(left,5,'Broj različitih tekstova | udio od 2.253',fontName='Body',fontSize=10,fillColor=colors.HexColor(MUTED)))
    save_svg(d,name)
    return d

class Pull(Flowable):
    def __init__(self,s):Flowable.__init__(self);self.par=p(s,'pull');self.spaceBefore=7;self.spaceAfter=13
    def wrap(self,w,h):self.width=w;self.ph=self.par.wrap(w-33,h)[1];self.height=self.ph+28;return self.width,self.height
    def draw(self):
        self.canv.setFillColor(colors.HexColor(PALE));self.canv.rect(0,0,self.width,self.height,fill=1,stroke=0)
        self.canv.setFillColor(colors.HexColor(COPPER));self.canv.rect(0,0,3,self.height,fill=1,stroke=0)
        self.par.drawOn(self.canv,17,14)

class CloudGrid(Flowable):
    def __init__(self,keys):
        Flowable.__init__(self);self.keys=keys;self.spaceAfter=8
        self.pw=(CW-23)/2;self.rowh=253;self.height=math.ceil(len(keys)/2)*self.rowh;self.width=CW
    def wrap(self,w,h):return self.width,self.height
    def draw(self):
        for i,key in enumerate(self.keys):
            x=(i%2)*(self.pw+23);y=self.height-(i//2)*self.rowh
            title=p(TOP[key]['label'],'panel');_,hh=title.wrap(self.pw,50); title.drawOn(self.canv,x,y-hh)
            self.canv.setFillColor(colors.HexColor(MUTED));self.canv.setFont('Body',9.4)
            self.canv.drawString(x,y-40,f'{num(TOP[key]["texts"])} tekstova u skupini')
            CLOUD_DRAWINGS[key].drawOn(self.canv,x,y-178)
            top=' · '.join(f'{r["word"]} {num(r["texts"])}' for r in CLOUDS[key][:3])
            cp=p(top,'small');_,ch=cp.wrap(self.pw,100);cp.drawOn(self.canv,x,y-184-ch)
            comment=p(COMMENTS[key],'panelbody');_,bh=comment.wrap(self.pw,100);comment.drawOn(self.canv,x,y-213-bh)
            if bh>30 and len(self.keys)>2:raise ValueError(f'Long panel comment {key}: {bh}')

class Chain(Flowable):
    def __init__(self,labels):Flowable.__init__(self);self.labels=labels;self.width=CW;self.height=75;self.spaceBefore=5;self.spaceAfter=6
    def wrap(self,w,h):return self.width,self.height
    def draw(self):
        bw=(CW-32)/3
        for i,label in enumerate(self.labels):
            x=i*(bw+16);self.canv.setFillColor(colors.HexColor(PALE));self.canv.roundRect(x,0,bw,70,5,fill=1,stroke=0)
            self.canv.setFillColor(colors.HexColor(COPPER));self.canv.setFont('BodyBold',10);self.canv.drawString(x+12,53,str(i+1))
            q=p(label,'cell');_,hh=q.wrap(bw-24,70);q.drawOn(self.canv,x+12,43-hh)
            if i<2:
                self.canv.setFont('BodyBold',16);self.canv.setFillColor(colors.HexColor(COPPER));self.canv.drawCentredString(x+bw+8,31,'›')

def make_table(lines):
    cells=[[s.strip() for s in line.strip('|').split('|')] for line in lines]
    cells=[r for r in cells if not all(re.fullmatch(r'[:\- ]+',s) for s in r)]
    widths=[CW*.55,CW*.25,CW*.20] if len(cells[0])==3 else [CW*.30,CW*.70]
    content=[[p(v,'cell') for v in row] for row in cells]
    t=Table(content,colWidths=widths,hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor(PALE)),('LINEBELOW',(0,0),(-1,0),.7,colors.HexColor(LINE)),('LINEBELOW',(0,1),(-1,-1),.4,colors.HexColor(LINE)),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),9),('RIGHTPADDING',(0,0),(-1,-1),9),('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7)]))
    t.spaceBefore=4;t.spaceAfter=12;return t

def blocks(text):
    lines=text.strip().splitlines();i=0;bs=[]
    while i<len(lines):
        line=lines[i].strip()
        if not line:i+=1;continue
        if line.startswith('|'):
            group=[]
            while i<len(lines) and lines[i].startswith('|'):group.append(lines[i]);i+=1
            bs.append(('table',group));continue
        if line.startswith('::: topics '):bs.append(('topics',line[11:].split(',')))
        elif line.startswith('::: chain '):bs.append(('chain',line[10:].split(' | ')))
        elif line.startswith('# '):bs.append(('h1',line[2:]))
        elif line.startswith('## '):bs.append(('h2',line[3:]))
        elif line.startswith('> '):bs.append(('pull',line[2:]))
        elif line.startswith('~ '):bs.append(('small',line[2:]))
        elif line.startswith('!['):
            m=re.fullmatch(r'!\[(.*?)\]\((.*?)\)',line);bs.append(('figure',(m[1],Path(m[2]).stem)))
        else:
            ll=[line]
            while i+1<len(lines) and lines[i+1].strip() and not lines[i+1].startswith(('#','~ ','> ',':::','![','|')):i+=1;ll.append(lines[i].strip())
            bs.append(('body',' '.join(ll)))
        i+=1
    return bs

def cover(c):
    c.setFillColor(colors.HexColor(PAPER));c.rect(0,0,W,H,fill=1,stroke=0)
    c.setFillColor(colors.HexColor(INK));c.rect(0,248,W,H-248,fill=1,stroke=0)
    c.setFillColor(colors.HexColor(GOLD));c.setFont('BodyBold',10);c.drawString(M,H-61,'DIGIKAT / ANALITIČKI IZVJEŠTAJ')
    c.setFillColor(colors.white);c.setFont('Display',36);c.drawString(M,H-153,'Demokršćanstvo')
    c.setFont('Display',30);c.drawString(M,H-201,'Od riječi do argumenta')
    c.setFont('Body',16);c.setFillColor(colors.HexColor('#e1ebe5'));c.drawString(M,H-250,'Politička pripadnost, vrijednosti i javne odluke')
    c.setStrokeColor(colors.HexColor(GOLD));c.setLineWidth(1.5);c.line(M,H-280,M+80,H-280)
    c.setFont('Body',12);c.setFillColor(colors.white);c.drawString(M,H-316,'Medijski tekstovi od 1. 1. 2021. do 10. 9. 2026.')
    c.drawString(M,H-338,'19. rujna 2026.')
    c.setFont('BodyBold',13);c.drawString(M,H-380,'Luka Šikić')
    c.linkURL('https://www.lukasikic.info/',(M,H-384,M+100,H-365),relative=0)
    c.setFont('Body',10);c.drawString(M,H-399,'www.lukasikic.info')
    c.linkURL('https://www.lukasikic.info/',(M,H-403,M+110,H-388),relative=0)
    for x,val,label in [(M,'2.253','različita teksta i objave'),(M+190,'10','tematskih skupina'),(M+357,'3','detaljna primjera')]:
        c.setFont('Display',27);c.setFillColor(colors.HexColor(GOLD));c.drawString(x,339,val)
        c.setFont('Body',10);c.setFillColor(colors.white);c.drawString(x,318,label)
    q=p('Od jezika političkog identiteta do rasprave o savjesti, solidarnosti i javnim potrebama.','h1');_,hh=q.wrap(CW,200);q.drawOn(c,M,211-hh)
    q=p('Oblak riječi · Tematski rječnici · Konkretni javni argumenti','body');_,hh=q.wrap(CW,80);q.drawOn(c,M,89-hh)
    c.setFillColor(colors.HexColor(MUTED));c.setFont('Body',9);c.drawString(M,29,'DigiKat | Hrvatsko katoličko sveučilište')

def frame(c,n,kicker,total):
    c.setFillColor(colors.HexColor(PAPER));c.rect(0,0,W,H,fill=1,stroke=0)
    c.setFillColor(colors.HexColor(COPPER));c.setFont('BodyBold',9.2);c.drawString(M,H-36,f'{n:02d} / {kicker.upper()}')
    c.setStrokeColor(colors.HexColor(LINE));c.setLineWidth(.6);c.line(M,44,W-M,44)
    c.setFillColor(colors.HexColor(MUTED));c.setFont('Body',8.2);c.drawString(M,29,'DIGIKAT / DEMOKRŠĆANSTVO: OD RIJEČI DO ARGUMENTA / 19. 9. 2026.')
    c.drawRightString(W-M,29,f'{n} / {total}')

def html_inline(s):
    s=html.escape(s);s=re.sub(r'\[([^\]]+)\]\((https?://[^)]+)\)',r'<a href="\2">\1</a>',s)
    s=re.sub(r'\*\*(.+?)\*\*',r'<strong>\1</strong>',s);return re.sub(r'\*(.+?)\*',r'<em>\1</em>',s)
def cloud_html(key):
    title='Sve teme' if key=='all' else TOP[key]['label']
    n=CLOUDS[key][0]['denominator']
    alt=f'{title}: broj tekstova {num(n)}. '+', '.join(f'{r["word"]}: {num(r["texts"])}' for r in CLOUDS[key][:3])+'.'
    # SVGs are inline; HTML remains one self-contained file.
    svg=(FIG/f'cloud-{key}.svg').read_text(encoding='utf-8')
    svg=svg[svg.index('<svg'):];svg=svg.replace('<svg ','<svg aria-hidden="true" focusable="false" ',1)
    tb='<table><caption>Sve prikazane riječi i broj tekstova</caption><thead><tr><th>Riječ</th><th>Tekstovi</th><th>Udio u skupini</th></tr></thead><tbody>'+''.join(f'<tr><td>{html.escape(r["word"])}</td><td>{num(r["texts"])}</td><td>{dec(100*r["texts"]/n)}%</td></tr>' for r in CLOUDS[key])+'</tbody></table>'
    return f'<figure><h3>{html.escape(title)}</h3><p>{num(n)} tekstova.</p>{svg}<figcaption>{html.escape(alt)}</figcaption><details><summary>Tekstualni prikaz podataka</summary>{tb}</details></figure>'
def public_html(pages):
    h=['<!doctype html><html lang="hr"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Demokršćanstvo: od riječi do argumenta</title><style>body{margin:0;background:#fcfbf7;color:#173e43;font:18px/1.6 Calibri,Arial,sans-serif}main{max-width:960px;margin:auto;padding:36px 24px}h1,h2{font-family:Georgia,serif;line-height:1.2}h1{font-size:2.4em}h2{font-size:1.8em}h3{line-height:1.3}section{margin:70px 0}a{color:#94512f;text-underline-offset:3px}blockquote{background:#eef2ef;border-left:4px solid #94512f;margin:24px 0;padding:20px;font-family:Georgia,serif}table{border-collapse:collapse;width:100%;font-size:.94em}td,th{padding:9px;border-bottom:1px solid #cdd9d4;text-align:left}th{background:#eef2ef}figure{margin:20px 0}svg{width:100%;height:auto}figcaption,.note{font-size:.92em;color:#496268}.grid{display:grid;grid-template-columns:1fr 1fr;gap:28px}.grid svg{max-height:260px}.grid figure{margin:0}summary{cursor:pointer;text-decoration:underline}details{margin:14px 0}nav li{margin:8px 0}a:focus,summary:focus{outline:3px solid #94512f;outline-offset:4px}@media(max-width:650px){.grid{grid-template-columns:1fr}h1{font-size:2em}}@media print{details{display:block}section{break-before:page}nav{display:none}}</style><main><header><p>DigiKat | Hrvatsko katoličko sveučilište | 19. rujna 2026.</p><h1>Demokršćanstvo: od riječi do argumenta</h1><p>Politička pripadnost, vrijednosti i javne odluke</p></header><nav aria-label="Sadržaj"><h2>Sadržaj</h2><ol>']
    h[0]=h[0].replace('</header>', '<p>Autor: <a rel="author" href="https://www.lukasikic.info/">Luka Šikić</a></p></header>')
    for i,(k,bs) in enumerate(pages,2):h.append(f'<li><a href="#p{i}">{html.escape(bs[0][1])}</a></li>')
    h.append('</ol></nav>')
    for i,(k,bs) in enumerate(pages,2):
        h.append(f'<section id="p{i}" aria-labelledby="h{i}">')
        for kind,s in bs:
            if kind=='h1':h.append(f'<h2 id="h{i}">{html_inline(s)}</h2>')
            elif kind=='h2':h.append(f'<h3>{html_inline(s)}</h3>')
            elif kind=='pull':h.append(f'<blockquote>{html_inline(s)}</blockquote>')
            elif kind in ('body','small'):h.append(f'<p class="{"note" if kind=="small" else "body"}">{html_inline(s)}</p>')
            elif kind=='table':
                cells=[[v.strip() for v in line.strip('|').split('|')] for line in s];cells=[r for r in cells if not all(re.fullmatch(r'[:\- ]+',v) for v in r)]
                h.append('<table><thead><tr>'+''.join('<th scope="col">'+html_inline(v)+'</th>' for v in cells[0])+'</tr></thead><tbody>')
                for row in cells[1:]:h.append('<tr>'+''.join('<td>'+html_inline(v)+'</td>' for v in row)+'</tr>')
                h.append('</tbody></table>')
            elif kind=='figure':
                alt,name=s
                if name=='cloud-all':h.append(cloud_html('all'))
                else:
                    svg=(FIG/f'{name}.svg').read_text(encoding='utf-8');svg=svg[svg.index('<svg'):].replace('<svg ','<svg aria-hidden="true" ',1)
                    data=sorted(TOP.values(),key=lambda r:-int(r['texts'])) if name=='topics' else PHRASES;lk='label' if name=='topics' else 'phrase'
                    tab='<table><thead><tr><th>Naziv</th><th>Tekstovi</th><th>Udio od 2.253</th></tr></thead><tbody>'+''.join(f'<tr><td>{r[lk]}</td><td>{num(r["texts"])}</td><td>{dec(100*int(r["texts"])/2253)}%</td></tr>' for r in data)+'</tbody></table>'
                    h.append(f'<figure>{svg}<figcaption>{html.escape(alt)}</figcaption><details><summary>Tekstualni prikaz podataka</summary>{tab}</details></figure>')
            elif kind=='topics':
                h.append('<div class="grid">')
                for key in s:h.append('<div>'+cloud_html(key)+f'<p>{COMMENTS[key]}</p></div>')
                h.append('</div>')
            elif kind=='chain':h.append('<ol>'+''.join(f'<li>{html.escape(x)}</li>' for x in s)+'</ol>')
        h.append('</section>')
    h.append('</main></html>');(OUT/'report.html').write_text('\n'.join(h),encoding='utf-8')

def main():
    global CLOUD_DRAWINGS
    CLOUD_DRAWINGS={key:cloud(key,CW if key=='all' else (CW-23)/2,230 if key=='all' else 130) for key in CLOUDS}
    graphs={'cloud-all':CLOUD_DRAWINGS['all'],'topics':graph(sorted(TOP.values(),key=lambda r:-int(r['texts'])),'label','topics',height=350),'phrases':graph(PHRASES,'phrase','phrases',height=290)}
    source_path=OUT/'manuscript.md' if PORTABLE else HERE/'manuscript.md'
    source=source_path.read_text(encoding='utf-8')
    chunks=re.split(r'<!-- PAGE: (.*?) -->',source);pages=[(chunks[i],blocks(chunks[i+1])) for i in range(1,len(chunks),2)]
    c=canvas.Canvas(str(PDF),pagesize=A4,pageCompression=1,invariant=1,lang='hr-HR')
    c.setTitle('Demokršćanstvo: od riječi do argumenta');c.setAuthor('Luka Šikić');c.setSubject('Politička pripadnost, vrijednosti i javne odluke');c.setViewerPreference('DisplayDocTitle','true')
    c.bookmarkPage('cover');c.addOutlineEntry('Naslovnica','cover',0);cover(c);c.showPage()
    layout=[]
    for n,(k,bs) in enumerate(pages,2):
        items=[]
        for kind,s in bs:
            if kind in ('h1','h2','body','small'):items.append(p(s,kind))
            elif kind=='pull':items.append(Pull(s))
            elif kind=='figure':items.append(graphs[s[1]])
            elif kind=='table':items.append(make_table(s))
            elif kind=='topics':items.append(CloudGrid(s))
            elif kind=='chain':items.append(Chain(s))
        heights=[o.getSpaceBefore()+o.wrap(CW,10000)[1]+o.getSpaceAfter() for o in items]
        used=sum(heights)
        if used>H-61-59:raise ValueError(f'Page {n}: {bs[0][1]} uses {used:.1f} > {H-120:.1f}')
        frame(c,n,k,len(pages)+1);c.bookmarkPage(f'p{n}');c.addOutlineEntry(bs[0][1],f'p{n}',0)
        y=H-61
        for obj in items:
            y-=obj.getSpaceBefore();_,hh=obj.wrap(CW,10000);y-=hh;obj.drawOn(c,M,y);y-=obj.getSpaceAfter()
        layout.append({'page':n,'title':bs[0][1],'height':used,'bottom_y':y});c.showPage()
    c.save()
    # Expand custom cloud and chain blocks into portable, editable Markdown.
    portable=source
    for keys in re.findall(r'^::: topics (.+)$',source,re.M):
        parts=[]
        for key in keys.split(','):
            rs=CLOUDS[key];parts += [f'## {TOP[key]["label"]}',f'{num(rs[0]["denominator"])} tekstova u skupini.',f'![Oblak riječi za temu {TOP[key]["label"]}](figures/cloud-{key}.svg)',COMMENTS[key],'| Riječ | Broj tekstova | Udio u skupini |','|---|---:|---:|']
            parts += [f'| {r["word"]} | {num(r["texts"])} | {dec(100*r["texts"]/r["denominator"])}% |' for r in rs]
            parts.append('')
        portable=portable.replace('::: topics '+keys,'\n\n'.join(parts))
    portable=re.sub(r'^::: chain (.+)$',lambda m:' → '.join(m[1].split(' | ')),portable,flags=re.M)
    portable=re.sub(r'^~ ', '',portable,flags=re.M)
    portable=re.sub(r'<!-- PAGE: .*? -->\n','',portable)
    (OUT/'report.md').write_text(portable,encoding='utf-8')
    public_html(pages)
    (INTERNAL/'layout.json').write_text(json.dumps(layout,ensure_ascii=False,indent=2),encoding='utf-8')
    (INTERNAL/'cloud-layout.json').write_text(json.dumps(CLOUD_LAYOUT,ensure_ascii=False,indent=2),encoding='utf-8')
    if not PORTABLE: shutil.copy2(HERE/'manuscript.md',OUT/'manuscript.md')
    print(json.dumps({'pdf':str(PDF),'pages':len(pages)+1,'lowest_bottom':min(r['bottom_y'] for r in layout),'clouds':len(CLOUDS)},ensure_ascii=False))

if __name__=='__main__':main()
