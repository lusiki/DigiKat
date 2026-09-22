"""Check final PDF evidence, geometry, links, publication integrity and language."""
from pathlib import Path
import hashlib
import json
import re
from html.parser import HTMLParser
import fitz
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'output/demokrscanstvo-carousel'
STEM = 'demokrscanske-vrijednosti-karusel'
pdf = ROOT / 'assets/izvjestaji' / (STEM + '.pdf')
reader = PdfReader(pdf)
texts = [' '.join(p.extract_text().split()) for p in reader.pages]
manifest = json.loads((OUT/'manifest.json').read_text(encoding='utf-8'))
meta = json.loads(pdf.with_suffix('.meta.json').read_text(encoding='utf-8'))
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
assert len(texts) == meta['pages'] == 18
assert reader.metadata.author == 'Luka Šikić'
assert reader.metadata.title == manifest['title']
assert manifest['title'] in texts[0]
assert 'Doc. dr. sc. Luka Šikić' in texts[0]
assert manifest['conference'] == meta['conference']
assert manifest['conference'] in texts[0]
assert '24. rujna 2026.' in texts[0]
assert all('\ufffd' not in t and '\x00' not in t for t in texts)
assert sha(pdf) == meta['pdf_sha256']
assert sha(pdf.with_suffix('.html')) == meta['html_sha256']
assert sha(pdf.with_name(STEM+'-podaci.json')) == meta['data_sha256']
for path, digest in manifest['inputs'].items():
    assert sha(ROOT/path) == digest, path
for path, digest in manifest['design_inputs'].items():
    assert sha(ROOT/path) == digest, path

# Independently retained expected values from the reviewed reports. These checks
# protect denominators and the title/scope distinction, not implementation details.
expected = {
    3:['413.985','9 platformi','Ne predstavljaju zasebnu analizu samo katoličkih nakladnika'],
    4:['41.397.670','2.306','2.253','14 platformi'],
    5:['377','335','290','274'],
    6:['50,0 %','1.153','2.306'],
    7:['1.123','103','27','49,8 %','4,6 %','1,2 %'],
    8:['2022.','2024.','2025.','24,4 %','24,8 %','25,9 %'],
    9:['78,5 %','1.811','29,9 %','22,2 %','28,6 %'],
    10:['1.811','Andrej Plenković','691','Franjo Tuđman','248','Miroslav Škoro','163','Ivan Penava','158','Zoran Milanović','156','Davor Ivo Stier','78'],
    11:['239','index.hr','74','dragovoljac.com','70','direktno.hr','66','369','20,4 %'],
    12:['1.811','132','119','109','2021.','2026.'],
    13:['24,9 %','451','1.811','132','119','109','91'],
    14:['Izbori i konzervativna scena','53','40,2 %','28','23,5 %','48','44,0 %'],
    15:['39','11. 6. 2022.','26','20','51,3 %','10','25,6 %'],
}
for p, required in expected.items():
    for value in required:
        assert value in texts[p-1], (p,value)

urls = [str(a.get_object().get('/A',{}).get('/URI','')) for p in reader.pages for a in p.get('/Annots',[])]
assert 'https://www.lukasikic.info/' in urls
assert any('demokrscanske-vrijednosti-karusel-podaci.json' in u for u in urls)
assert len(urls) >= 25
assert not re.search(r'baromet\w*|naglaske', ' '.join(texts), re.I)
for removed in ['Zajednička tradicija ostavlja prostor sporu','Poštovanje načela i stranačka pripadnost',
                'Opće dobro ulazi u pitanje zapošljavanja','Supsidijarnost otvara pitanje tko odlučuje',
                'Savjest i dostupnost zdravstvene usluge','Europska solidarnost dobiva lokalnu adresu']:
    assert removed not in ' '.join(texts)

evidence=json.loads((ROOT/'assets/izvjestaji/demokrscanske-vrijednosti-karusel-podaci.json').read_text(encoding='utf-8'))
assert sum(r['articles'] for r in evidence['monthly']) == evidence['scope']['web_articles'] == 1811
assert sum(p['articles'] for p in evidence['peak_months']) == 451
assert evidence['peak_day']['articles'] == sum(r['articles'] for r in evidence['peak_day']['topics']) == 39
for path,digest in evidence['provenance']['public_inputs'].items():
    assert sha(ROOT/path)==digest,path
doc = fitz.open(pdf)
font_names = set()
for n,page in enumerate(doc,1):
    assert abs(page.rect.width/page.rect.height-16/9)<.002
    for b in page.get_text('dict')['blocks']:
        for line in b.get('lines',[]):
            for span in line['spans']:
                x0,y0,x1,y1 = span['bbox']
                assert x0>=18 and y0>=12 and x1<=page.rect.width-18 and y1<=page.rect.height-12,(n,span)
    for f in page.get_fonts():
        font_names.add(f[3])
        assert doc.extract_font(f[0])[3], ('Font not embedded',f)
assert any('Georgia' in f for f in font_names)
assert any('Calibri' in f for f in font_names)
assert reader.trailer['/Root'].get('/StructTreeRoot') is not None

class Links(HTMLParser):
    def __init__(self): super().__init__(); self.urls=[]
    def handle_starttag(self,tag,attrs):
        if tag=='a':
            url=dict(attrs).get('href','')
            if url.startswith('https://lusiki.github.io/DigiKat/'):
                self.urls.append(url.split('/DigiKat/',1)[1].split('#',1)[0])
parser=Links(); parser.feed(pdf.with_suffix('.html').read_text(encoding='utf-8'))
for path in set(parser.urls):
    target=ROOT/'docs'/path
    if not path or path.endswith('/'):target=target/'index.html'
    assert target.exists(),('Missing project resource',path)
browser=json.loads((OUT/'browser-verification.json').read_text(encoding='utf-8'))
assert browser['status']=='PASS'
result=dict(status='PASS',slides=18,findings=10,pdf_sha256=sha(pdf),
            pdf_links=len(urls),embedded_fonts=sorted(font_names),tagged=True,
            title=manifest['title'],scope='Broader media discussion, including general and Catholic media',
            visual_review='Separate inspection of all rendered pages required')
(OUT/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,ensure_ascii=False))
