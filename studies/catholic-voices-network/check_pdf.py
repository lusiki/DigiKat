"""PDF structural/encoding checks and page rasters for mandatory visual QA.

Run with the local reporting Python (PyMuPDF/Pillow); no GPU/LLM dependencies.
"""
import argparse,json,re
from pathlib import Path
import fitz
from PIL import Image,ImageOps,ImageDraw
from report_contract import FOOTER,sha

def check(pdf,destination,final=False):
    destination=Path(destination);destination.mkdir(parents=True,exist_ok=True)
    document=fitz.open(pdf);issues=[];pages=[];thumbs=[]
    if final and not 25<=len(document)<=35:issues.append('Final report must contain 25–35 pages')
    for i,page in enumerate(document):
        text=page.get_text();compact=re.sub(r'\s+','',text)
        if '\ufffd' in text:issues.append(f'page {i+1}: replacement character')
        if 0<i<len(document)-1 and re.sub(r'\s+','',FOOTER) not in compact:
            issues.append(f'page {i+1}: missing machine-only footer')
        outside=[]
        for block in page.get_text('dict')['blocks']:
            for line in block.get('lines',[]):
                for span in line['spans']:
                    box=fitz.Rect(span['bbox'])
                    if not (page.rect+(-2,-2,2,2)).contains(box):outside.append(span['text'][:80])
        if outside:issues.append(f'page {i+1}: text beyond page bounds')
        target=destination/f'page-{i+1:02d}.png';page.get_pixmap(matrix=fitz.Matrix(1.35,1.35),alpha=False).save(target)
        thumb=Image.open(target).convert('RGB');thumb.thumbnail((380,540))
        panel=Image.new('RGB',(400,570),'#dddddd');panel.paste(thumb,((400-thumb.width)//2,12))
        ImageDraw.Draw(panel).text((10,550),str(i+1),fill='black');thumbs.append(panel)
        pages.append(dict(page=i+1,text_characters=len(text),outside=outside,raster=target.name))
    for start in range(0,len(thumbs),8):
        batch=thumbs[start:start+8];sheet=Image.new('RGB',(1600,570*((len(batch)+3)//4)),'white')
        for j,thumb in enumerate(batch):sheet.paste(thumb,((j%4)*400,(j//4)*570))
        sheet.save(destination/f'contact-{start//8+1:02d}.png')
    result=dict(pdf_sha256=sha(pdf),pages=len(document),final_page_range_required=final,
      mechanical_pass=not issues,issues=issues,page_details=pages,
      visual_review='pending; inspect full-page rasters/contact sheets before delivery')
    (destination/'pdf_checks.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    document.close()
    if issues:raise RuntimeError('; '.join(issues))
    return result

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('pdf');parser.add_argument('destination');parser.add_argument('--final',action='store_true')
    args=parser.parse_args();print(json.dumps(check(args.pdf,args.destination,args.final),ensure_ascii=False))
