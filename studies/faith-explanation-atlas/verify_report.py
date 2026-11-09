import hashlib,json,pathlib,re,sys
import fitz
from PIL import Image,ImageOps,ImageDraw
sys.stdout.reconfigure(encoding='utf8')
OUT=pathlib.Path(__file__).resolve().parent/'output/private'
qa=OUT/'qa';qa.mkdir(exist_ok=True)
doc=fitz.open(OUT/'tko-vjeri-daje-javni-glas.pdf')
plan=json.loads((OUT/'page_plan.json').read_text(encoding='utf8'))
assert len(doc)==len(plan)==35
stats=[];alltext=''
for i,p in enumerate(doc):
    txt=p.get_text();alltext+=txt
    assert '{{' not in txt and '\ufffd' not in txt
    # Each planned heading must be on its intended physical page.
    def ws(s):return re.sub(r'\s+',' ',s).strip()
    assert ws(plan[i]['title']) in ws(txt),(i,plan[i]['title'])
    blocks=p.get_text('dict')['blocks'];outside=[]
    for b in blocks:
        if b['type']!=0:continue
        x0,y0,x1,y1=b['bbox']
        if x0<20 or x1>p.rect.width-15 or y0<15 or y1>p.rect.height-15:outside.append(b['bbox'])
    assert not outside,(i,outside)
    pix=p.get_pixmap(matrix=fitz.Matrix(1.2,1.2));pix.save(qa/f'page-{i+1:02d}.png')
    stats.append(dict(page=i+1,words=len(txt.split()),text_blocks=len(blocks),bounds_ok=True))
for start in range(0,len(doc),4):
    canvas=Image.new('RGB',(2000,1630),'#d8dfdc');draw=ImageDraw.Draw(canvas)
    for j in range(4):
        n=start+j+1
        if n>len(doc):break
        im=Image.open(qa/f'page-{n:02d}.png');im.thumbnail((980,772));x=10+(j%2)*1000;y=28+(j//2)*810
        canvas.paste(im,(x,y));draw.text((x,y-20),f'Page {n}',fill='black')
    canvas.save(qa/f'contact-{start//4+1:02d}.png')
manifest=json.loads((OUT/'companion/source_manifest.json').read_text(encoding='utf8'))
for p,v in manifest.items():assert hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()==v['sha256'],p
quotes=json.loads((OUT/'quotation_verification.json').read_text(encoding='utf8'))
assert all(q['exact_normalized_whitespace_match'] for q in quotes)
checks=dict(pages=len(doc),total_words=len(alltext.split()),page_checks=stats,quote_checks=len(quotes),source_files_unchanged=len(manifest),pdf_sha256=hashlib.sha256((OUT/'tko-vjeri-daje-javni-glas.pdf').read_bytes()).hexdigest(),visual_review='pending',scope='Layout and provenance verification only; not model accuracy or human validation')
(OUT/'verification.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2),encoding='utf8')
print(json.dumps({k:v for k,v in checks.items() if k!='page_checks'}))
