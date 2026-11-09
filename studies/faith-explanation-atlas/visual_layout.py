"""Two-column atlas: a substantial figure and the complete existing prose per page."""
import html,json,re,hashlib
from reportlab.pdfgen import canvas
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib import colors
from reportlab.platypus import Paragraph,Spacer,Table,TableStyle
from svglib.svglib import svg2rlg
from reportlab.graphics import renderPDF
import fitz
from atlas_figures import build

def render(out,pages,quotes,qmeta,vr,split,a,d,c,persons,splitrows):
    figs=build(out,a,d,c,persons,splitrows)
    W,H=1080,850;left=40;fx=40;fy=148;fw=475;fh=556.64;tx=550;tw=485
    ink=colors.HexColor('#243337');green=colors.HexColor('#176e62');grey=colors.HexColor('#596566')
    raw=out/'layout-text.pdf';cv=canvas.Canvas(str(raw),pagesize=(W,H));cv.setTitle('Tko vjeri daje javni glas? · Vizualni atlas');cv.setAuthor('DigiKat')
    index=[];htmlpages=[];layout=[]
    def para(s,style):return Paragraph(html.escape(s),style)
    for n,p in enumerate(pages,1):
        index.append(dict(page=n,title=p['title'],source_locators=p['refs'],quotation_ids=';'.join(re.findall(r'QUOTE:(\d+)',p['body'])),figure=figs[n]['svg']))
        cv.setFillColor(colors.HexColor('#fcfcf8'));cv.rect(0,0,W,H,stroke=0,fill=1)
        cv.setFillColor(green);cv.setFont('SegoeBold',9);cv.drawString(40,H-43,p['section'])
        title=Paragraph(html.escape(p['title']),ParagraphStyle('title',fontName='PalatinoBold',fontSize=28,leading=34,textColor=ink))
        _,hh=title.wrap(995,90);title.drawOn(cv,40,H-67-hh)
        cv.setStrokeColor(colors.HexColor('#cbd7d0'));cv.line(40,H-128,1040,H-128)
        cv.line(526,70,526,H-148)
        fig=figs[n]
        h=[f'<section id="page-{n}"><header><div class="kicker">{html.escape(p["section"])}</div><h1>{html.escape(p["title"])}</h1></header><div class="spread"><figure><img src="{fig["svg"]}" alt="{html.escape(fig["title"],quote=True)}"><figcaption>{html.escape(fig["source"])}</figcaption></figure><article>']
        def flows(size):
            sty=ParagraphStyle('body',fontName='Palatino',fontSize=size,leading=size*1.39,spaceAfter=10,textColor=ink)
            qsty=ParagraphStyle('quote',parent=sty,fontName='PalatinoItalic',fontSize=size,leading=size*1.38,spaceBefore=8,spaceAfter=15,leftIndent=13,rightIndent=8,borderPadding=8,borderWidth=.5,borderColor=green)
            note=ParagraphStyle('note',fontName='Segoe',fontSize=8.3,leading=11.2,spaceAfter=9,textColor=grey)
            cell=ParagraphStyle('cell',parent=note,fontSize=8.6,leading=11.5)
            arr=[]
            for b in p['body'].split('\n\n'):
                if b.startswith('{{QUOTE:'):
                    i=int(re.search(r'\d+',b).group());arr += [para(quotes[i],qsty),para(qmeta[i],note)]
                elif b=='{{SPLIT_TABLE}}':
                    t=Table([[para(str(x),cell) for x in row] for row in split],colWidths=[155,115,100,115]);t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#e0ece9')),('LINEBELOW',(0,0),(-1,0),.6,green),('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7)]));arr += [t,Spacer(1,12)]
                elif b=='{{NETWORK_FIGURE}}':pass
                else:arr.append(para(b,sty))
            return arr
        def height(arr):return sum(f.wrap(tw,10000)[1]+f.getSpaceBefore()+f.getSpaceAfter() for f in arr)
        size=15.0;arr=flows(size)
        while height(arr)>625 and size>11.5:
            size-=.1;arr=flows(size)
        assert height(arr)<=625,(n,height(arr),size)
        y=H-148
        for f in arr:
            y-=f.getSpaceBefore();_,hh=f.wrap(tw,10000);f.drawOn(cv,tx,y-hh);y-=hh+f.getSpaceAfter()
        if n==31:
            dr=svg2rlg(str(out/'companion/network_outlets.svg'));scale=min(fw/dr.width,500/dr.height);dr.scale(scale,scale);dr.width*=scale;dr.height*=scale
            renderPDF.draw(dr,cv,fx+(fw-dr.width)/2,H-fy-55-dr.height)
            titlefig=para('31 / OPĆI POGLED · ZAJEDNIČKI MEDIJSKI PROSTOR',ParagraphStyle('nettitle',fontName='SegoeBold',fontSize=11,leading=15,textColor=green));_,nh=titlefig.wrap(fw,100);titlefig.drawOn(cv,fx,H-fy-nh)
            cap=para(fig['subtitle']+' '+fig['source'],ParagraphStyle('cap',fontName='Segoe',fontSize=9,leading=13,textColor=grey));_,ch=cap.wrap(fw,100);cap.drawOn(cv,fx,130)
        for b in p['body'].split('\n\n'):
            if b.startswith('{{QUOTE:'):
                i=int(re.search(r'\d+',b).group());h.append(f'<blockquote>{html.escape(quotes[i])}</blockquote><p class="note"><a href="{html.escape(vr[i]["url"],quote=True)}">{html.escape(qmeta[i])}</a></p>')
            elif b=='{{SPLIT_TABLE}}':h.append('<table>'+''.join('<tr>'+''.join('<td>'+html.escape(str(x))+'</td>' for x in row)+'</tr>' for row in split)+'</table>')
            elif b=='{{NETWORK_FIGURE}}':pass
            else:h.append('<p>'+html.escape(b)+'</p>')
        h.append(f'</article></div><footer>DIGIKAT · Privatno izdanje · {n:02d} / 35</footer></section>');htmlpages.append(''.join(h))
        cv.setStrokeColor(colors.HexColor('#cbd7d0'));cv.line(40,48,1040,48);cv.setFont('Segoe',8);cv.setFillColor(grey);cv.drawString(40,29,'DIGIKAT · Tko vjeri daje javni glas? · Vizualni atlas · Privatno izdanje');cv.drawRightString(1040,29,f'{n:02d} / 35');cv.showPage()
        layout.append(dict(page=n,body_font_size=round(size,2),body_bottom=round(y,2),figure=fig['svg']))
    cv.save();doc=fitz.open(raw)
    for n,fig in figs.items():
        if fig['pdf']:
            graphic=fitz.open(out/fig['pdf']);doc[n-1].show_pdf_page(fitz.Rect(fx,fy,fx+fw,fy+fh),graphic,0);graphic.close()
    pdf=out/'tko-vjeri-daje-javni-glas.pdf';doc.save(pdf,garbage=4,deflate=True);doc.close();raw.unlink()
    css='''*{box-sizing:border-box}body{margin:0;background:#e4eae6;color:#243337;font:18px/1.55 "Palatino Linotype",Georgia,serif}nav{max-width:1350px;margin:24px auto;padding:35px;background:#fcfcf8}nav ol{columns:3;column-gap:35px}nav a{color:#176e62;text-decoration:none}nav li{margin:0 0 8px;break-inside:avoid;font:14px/1.4 "Segoe UI",sans-serif}section{max-width:1350px;margin:24px auto;padding:42px 46px;background:#fcfcf8;box-shadow:0 3px 14px #24333715}header{border-bottom:1px solid #cbd7d0;margin-bottom:26px;padding-bottom:20px}.kicker{font:bold 12px "Segoe UI",sans-serif;letter-spacing:1px;color:#176e62}h1{font-size:37px;line-height:1.15;margin:14px 0 0}.spread{display:grid;grid-template-columns:1fr 1fr;gap:40px;align-items:start}figure{margin:0;position:sticky;top:20px}figure img{width:100%;height:auto}figcaption{font:11px/1.4 "Segoe UI",sans-serif;color:#596566;margin:10px 8px}article{border-left:1px solid #cbd7d0;padding-left:28px}p{margin:0 0 15px}blockquote{margin:16px 0;padding:12px 16px;border-left:3px solid #176e62;background:#eff4ef;font-style:italic}.note{font:12px/1.45 "Segoe UI",sans-serif;color:#596566}.source{padding-top:14px;border-top:1px solid #cbd7d0}table{width:100%;border-collapse:collapse;font:13px/1.4 "Segoe UI",sans-serif}td{padding:8px;border-bottom:1px solid #d8e2dc}tr:first-child{background:#e0ece9}footer{margin-top:26px;padding-top:12px;border-top:1px solid #cbd7d0;font:11px "Segoe UI",sans-serif;color:#596566}@media(max-width:850px){nav ol{columns:1}.spread{display:block}figure{position:static;margin-bottom:25px}article{border:0;padding:0}section,nav{margin:12px;padding:24px}h1{font-size:30px}}@media print{nav{display:none}figure{position:static}section{break-after:page;box-shadow:none;margin:0}}'''
    toc='<nav><h2>Vizualni atlas · 35 stranica, 35 prikaza</h2><p><a href="tko-vjeri-daje-javni-glas.pdf">Preuzmi PDF</a> · <a href="README.txt">Izvori i prilozi</a></p><ol>'+''.join(f'<li><a href="#page-{i}">{html.escape(p["title"])}</a></li>' for i,p in enumerate(pages,1))+'</ol></nav>'
    (out/'tko-vjeri-daje-javni-glas.html').write_text('<!doctype html><html lang="hr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Tko vjeri daje javni glas? · Vizualni atlas</title><style>'+css+'</style></head><body>'+toc+''.join(htmlpages)+'</body></html>',encoding='utf8')
    (out/'layout_verification.json').write_text(json.dumps(layout,ensure_ascii=False,indent=2),encoding='utf8')
    return index
