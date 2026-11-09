"""Check PDF content, source identities, data provenance and page geometry."""
from pathlib import Path
import csv,json,hashlib,re
import fitz
from PIL import Image,ImageOps,ImageDraw
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
OUT=HERE/'output/private/extended'
QA=ROOT/'tmp/pdfs/actor-visual-brief'
d=json.loads((OUT/'workbook_data.json').read_text(encoding='utf-8'))
pdf=fitz.open(OUT/'katolicki-komunikatori-15-grafova.pdf')
assert len(pdf)==16
issues=[]
for i,p in enumerate(pdf):
 text=p.get_text()
 assert '\ufffd' not in text
 if i:assert f'GRAF {i:02d} / 15' in text
 for block in p.get_text('dict')['blocks']:
  if block['type']:continue
  for line in block['lines']:
   for span in line['spans']:
    x0,y0,x1,y1=span['bbox']
    if not (20<=x0<x1<=p.rect.width-20 and 20<=y0<y1<=p.rect.height-19):issues.append((i+1,span['text'],span['bbox']))
assert not issues,issues
normalize=lambda s:re.sub(r'\s+',' ',s).strip()
ranking_text=normalize(' '.join(p.get_text() for p in list(pdf)[-2:]))
for r in d['shortlist']:
 assert normalize(r['source']) in ranking_text,r['source']
 assert f'{r["total_interactions"]:,.0f}'.replace(',','.') in ranking_text
with (OUT/'source_ranking.csv').open(encoding='utf-8-sig',newline='') as stream:
 detail=list(csv.DictReader(stream))[:50]
assert [r['source_id'] for r in detail]==[r['source_id'] for r in d['shortlist']]
for page_number,platforms in [(14,{'facebook','instagram','web'}),(15,{'youtube'})]:
 text=normalize(pdf[page_number].get_text())
 rows=[r for r in detail if r['SOURCE_TYPE'] in platforms]
 assert len(rows)==(27 if page_number==14 else 23)
 for row in rows:
  assert normalize(row['source']) in text,row['source']
  for key in ('posts','reach_total','interactions'):
   assert f'{float(row[key]):,.0f}'.replace(',','.') in text,(row['source_id'],key,row[key])
assert 'Svećenički' in ''.join(p.get_text() for p in pdf)
assert d['input']['sha256'] in pdf[0].get_text()
assert all(f'{r["posts"]:,.0f}'.replace(',','.') in pdf[1].get_text() for r in d['flow'])
selected=[r for r in d['overall'] if r['scope']=='selected']
assert sum(r['posts'] for r in selected)==153015
assert sum(r['posts'] for r in d['overall'] if r['scope']=='all')==601036
for r in d['seasonal']:
 if r['interaction_n']:
  assert abs(r['mean_interactions']-r['total_interactions']/r['interaction_n'])<1e-8
with (ROOT/d['input']['path']).open('rb') as handle:assert hashlib.file_digest(handle,'sha256').hexdigest()==d['input']['sha256']
for start in range(0,16,4):
 sheet=Image.new('RGB',(1200,1740),'#dce3e6')
 for j in range(4):
  image=Image.open(QA/f'page-{start+j+1:02d}.png')
  image.thumbnail((580,830))
  x=(j%2)*600+10;y=(j//2)*870+30
  sheet.paste(image,(x,y));ImageDraw.Draw(sheet).text((x,y-20),f'Stranica {start+j+1}',fill='#233b48')
 sheet.save(QA/f'contact-{start//4+1}.png')
report=dict(pages=16,graphs=15,all_50_sources=True,all_50_totals=True,croatian_text=True,geometry=True,input_sha256=d['input']['sha256'])
(OUT/'15-graphs-validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report))
