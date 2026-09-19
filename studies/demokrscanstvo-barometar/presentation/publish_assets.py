"""Prepare checked publication resources; does not render or deploy the website."""
from pathlib import Path
import hashlib,json,shutil
from PIL import Image
from pypdf import PdfReader,PdfWriter
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'output/demokrscanstvo-presentation'
ASSETS=ROOT/'assets/izvjestaji';ASSETS.mkdir(exist_ok=True)
AUTHOR='Luka Šikić';URL='https://www.lukasikic.info/'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
# Chrome keeps accessible document structure and links; add the named author.
p=OUT/'demokrscanstvo-12-nalaza.pdf'
r=PdfReader(p)
if r.metadata.author!=AUTHOR:
    w=PdfWriter();w.clone_document_from_reader(r)
    w.add_metadata({'/Author':AUTHOR,'/Title':'Demokršćanstvo u medijima: 12 ključnih nalaza','/Subject':'Politička pripadnost, vrijednosti i javni argumenti'})
    temp=p.with_suffix('.tmp.pdf');w.write(temp);temp.replace(p)
specs=[
 ('demokrscanstvo-u-medijskom-prostoru','Demokršćanstvo u medijskom prostoru',ROOT/'output/pdf/demokrscanstvo-u-medijskom-prostoru.pdf',ROOT/'tmp/pdfs/demokrscanstvo-public-authored-01.png',14,2306),
 ('demokrscanstvo-od-rijeci-do-argumenta','Demokršćanstvo: od riječi do argumenta',ROOT/'output/pdf/demokrscanstvo-od-rijeci-do-argumenta.pdf',ROOT/'tmp/pdfs/demokrscanstvo-text-public-final-01.png',12,2253),
 ('demokrscanstvo-12-nalaza','Demokršćanstvo u medijima: 12 ključnih nalaza',p,ROOT/'tmp/pdfs/demokrscanstvo-presentation/cover.png',15,None)]
for stem,title,pdf,cover,pages,records in specs:
    reader=PdfReader(pdf);assert len(reader.pages)==pages and reader.metadata.author==AUTHOR
    target=ASSETS/(stem+'.pdf');shutil.copy2(pdf,target)
    im=Image.open(cover)
    if records:im.resize((420,round(im.height*420/im.width)),Image.Resampling.LANCZOS).save(ASSETS/(stem+'.webp'),format='WEBP',quality=84,method=6)
    else:im.save(ASSETS/(stem+'.webp'),format='WEBP',lossless=True)
    meta=dict(title=title,author=AUTHOR,author_url=URL,published='2026-09-19',data_from='2021-01-01',data_through='2026-09-10',pages=pages,bytes=target.stat().st_size,pdf_sha256=sha(target),cover_sha256=sha(ASSETS/(stem+'.webp')))
    if stem.endswith('prostoru'):meta['records']=records
    elif stem.endswith('argumenta'):meta.update(texts=records,source_records=2306)
    else:meta.update(findings=12)
    (ASSETS/(stem+'.meta.json')).write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
shutil.copy2(OUT/'demokrscanstvo-12-nalaza.html',ASSETS/'demokrscanstvo-12-nalaza.html')
shutil.copy2(ROOT/'output/demokrscanstvo-text-public/v1/report.html',ASSETS/'demokrscanstvo-od-rijeci-do-argumenta.html')
print(json.dumps({'resources':11,'author':AUTHOR,'url':URL},ensure_ascii=False))
