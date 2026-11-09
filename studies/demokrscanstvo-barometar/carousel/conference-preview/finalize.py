"""Verify and finalize the local conference preview without publishing it."""
from pathlib import Path
import hashlib
import json
import re
import fitz
from PIL import Image, ImageDraw
from pypdf import PdfReader, PdfWriter

ROOT = Path(__file__).resolve().parents[4]
OUT = ROOT / 'output/conference-carousel'
QA = ROOT / 'tmp/pdfs/conference-carousel'
STEM = 'demokrscanske-vrijednosti-konferencijska-verzija'
manifest = json.loads((OUT / 'manifest.json').read_text(encoding='utf-8'))
browser = json.loads((OUT / 'browser-verification.json').read_text(encoding='utf-8'))
assert browser['status'] == 'PASS' and browser['slides'] == 18
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
source = ROOT / manifest['source']
assert sha(source) == manifest['source_sha256']
assert sha(source.with_suffix('.pdf')) == manifest['source_pdf_sha256']

# Compare every analytical body exactly against the approved source. Only the
# explicitly added conference block and closing sentence may differ.
original = source.read_text(encoding='utf-8')
preview = (OUT / (STEM + '.html')).read_text(encoding='utf-8')
pattern = r'<div class="content">(.*?)</div><footer>'
old_bodies = re.findall(pattern, original, re.S)
new_bodies = re.findall(pattern, preview, re.S)
assert len(old_bodies) == len(new_bodies) == 18
for n, (old, new) in enumerate(zip(old_bodies, new_bodies), 1):
    new = re.sub(r'<div class="conference-heading">.*?</div>', '', new, flags=re.S)
    new = re.sub(r'<p class="conference-closing">.*?</p>', '', new, flags=re.S)
    assert old == new, ('Analytical content changed', n)
assert re.findall(r'<h2.*?</h2>', original) == re.findall(r'<h2.*?</h2>', preview)

pdf = OUT / (STEM + '.pdf')
reader = PdfReader(pdf)
writer = PdfWriter()
writer.clone_document_from_reader(reader)
writer.add_metadata({'/Author': manifest['author'], '/Title': manifest['title'],
                     '/Subject': manifest['conference'] + '. 24. rujna 2026. Konferencijska verzija.'})
temporary = pdf.with_suffix('.tmp.pdf')
writer.write(temporary)
temporary.replace(pdf)
doc = fitz.open(pdf)
assert len(doc) == 18
text = [' '.join(p.get_text().split()) for p in doc]
assert manifest['conference'] in text[0]
assert manifest['title'] in text[0]
assert 'Doc. dr. sc. Luka Šikić' in text[0]
assert '24. rujna 2026.' in text[0]
fonts = set()
links = []
for i, page in enumerate(doc, 1):
    assert abs(page.rect.width / page.rect.height - 16/9) < .002
    assert '\ufffd' not in text[i-1]
    for block in page.get_text('dict')['blocks']:
        for line in block.get('lines', []):
            for span in line['spans']:
                x0,y0,x1,y1 = span['bbox']
                assert x0 >= 18 and y0 >= 12 and x1 <= page.rect.width-18 and y1 <= page.rect.height-12, (i,span)
    for font in page.get_fonts():
        fonts.add(font[3])
        assert doc.extract_font(font[0])[3], ('Unembedded font', font)
    links.extend(link['uri'] for link in page.get_links() if 'uri' in link)
    page.get_pixmap(matrix=fitz.Matrix(4/3, 4/3), alpha=False).save(QA / f'slide-{i:02d}.png')
assert any('Georgia' in f for f in fonts) and any('Calibri' in f for f in fonts)
assert len(links) >= 25
assert PdfReader(pdf).trailer['/Root'].get('/StructTreeRoot') is not None
for start in (1, 10):
    sheet = Image.new('RGB', (1440, 900), '#e7ebee')
    for k in range(9):
        page_image = Image.open(QA / f'slide-{start+k:02d}.png')
        page_image.thumbnail((468, 263))
        x, y = (k % 3)*480+6, (k // 3)*300+23
        sheet.paste(page_image, (x, y))
        ImageDraw.Draw(sheet).text((x, y-19), str(start+k), fill='#152f49')
    sheet.save(QA / f'contact-{start:02d}.png')
Image.open(QA / 'slide-01.png').save(OUT / 'conference-cover.png')
result = dict(status='PASS', slides=18, unchanged_analytical_bodies=18,
              pdf_links=len(links), embedded_fonts=sorted(fonts),
              pdf_sha256=sha(pdf), html_sha256=sha(OUT / (STEM + '.html')),
              original_assets_unchanged=True, published=False)
(OUT / 'verification.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(result, ensure_ascii=False))
