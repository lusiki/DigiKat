"""Finalize the carousel PDF metadata, render QA pages and prepare public assets.

Run verify.py and inspect every PDF page before committing the public artifacts.
Only the explicitly retired presentation filenames are removed.
"""
from pathlib import Path
import hashlib
import json
import shutil
import fitz
from PIL import Image, ImageDraw
from pypdf import PdfReader, PdfWriter

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'output/demokrscanstvo-carousel'
QA = ROOT / 'tmp/pdfs/demokrscanstvo-carousel'
ASSETS = ROOT / 'assets/izvjestaji'
STEM = 'demokrscanske-vrijednosti-karusel'
manifest = json.loads((OUT / 'manifest.json').read_text(encoding='utf-8'))
browser = json.loads((OUT / 'browser-verification.json').read_text(encoding='utf-8'))
assert browser['status'] == 'PASS' and browser['slides'] == 18
pdf = OUT / (STEM + '.pdf')
reader = PdfReader(pdf)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.add_metadata({'/Author':manifest['author'], '/Title':manifest['title'],
                     '/Subject':manifest['conference'] + '. 24. rujna 2026. Konferencijska verzija.'})
temp = OUT / (STEM + '.tmp.pdf')
writer.write(temp)
temp.replace(pdf)
QA.mkdir(parents=True, exist_ok=True)
doc = fitz.open(pdf)
assert len(doc) == 18
for i, page in enumerate(doc, 1):
    page.get_pixmap(matrix=fitz.Matrix(4/3,4/3), alpha=False).save(QA / f'slide-{i:02d}.png')
for start in (1,10):
    sheet = Image.new('RGB',(1440,900),'#dce4df')
    for k in range(9):
        im = Image.open(QA / f'slide-{start+k:02d}.png')
        im.thumbnail((468,263))
        x,y = (k%3)*480+6,(k//3)*300+23
        sheet.paste(im,(x,y))
        ImageDraw.Draw(sheet).text((x,y-19),str(start+k),fill='#173e43')
    sheet.save(QA / f'contact-{start:02d}.png')
ASSETS.mkdir(exist_ok=True)
shutil.copy2(pdf, ASSETS / pdf.name)
# Public text assets use LF on every OS so metadata hashes survive Git checkout.
(ASSETS / (STEM + '.html')).write_text(
    (OUT / (STEM + '.html')).read_text(encoding='utf-8'), encoding='utf-8', newline='\n')
cover = Image.open(QA / 'slide-01.png').resize((1200, 675), Image.Resampling.LANCZOS)
cover.save(ASSETS / (STEM + '.webp'), format='WEBP', quality=74, method=6)
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
meta = dict(title=manifest['title'],author=manifest['author'],byline=manifest['byline'],
            author_url='https://www.lukasikic.info/',published='2026-09-22',
            data_from='2021-01-01',data_through='2026-09-10',pages=len(doc),findings=10,
            conference=manifest['conference'],conference_date=manifest['conference_date'],
            design='conference-navy-neutral-white-yellow-gold',
            bytes=pdf.stat().st_size,pdf_sha256=sha(pdf),
            cover_sha256=sha(ASSETS / (STEM + '.webp')),
            data_sha256=sha(ASSETS / (STEM + '-podaci.json')),
            html_sha256=sha(ASSETS / (STEM + '.html')))
(ASSETS / (STEM + '.meta.json')).write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
finaldir = ROOT / 'output/pdf'
finaldir.mkdir(exist_ok=True)
shutil.copy2(pdf, finaldir / pdf.name)
# Exact authorized retirement only; no recursive deletion or wildcard.
for suffix in ('.pdf','.html','.webp','.meta.json'):
    for directory in (ASSETS, ROOT / 'docs/assets/izvjestaji'):
        old = directory / ('demokrscanstvo-12-nalaza' + suffix)
        if old.exists():
            old.unlink()
print(json.dumps(dict(pages=len(doc),bytes=pdf.stat().st_size,pdf_sha256=sha(pdf)),ensure_ascii=False))
