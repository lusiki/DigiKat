"""Check report outputs and render all pages for visual inspection."""
from pathlib import Path
import csv
import hashlib
import json
import re
import fitz

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = HERE/'output/private'
r = json.loads((OUT/'results.json').read_text(encoding='utf-8'))
main,core = r['main'][0],r['core'][0]
checks = {}
checks['sample_flow'] = r['input']['raw_rows']-r['input']['excluded_outside_period']-r['input']['duplicate_captures_removed']==main['posts']
checks['groups_reconcile'] = sum(x['posts'] for x in r['actor_groups'])==main['posts']
checks['platforms_reconcile'] = sum(x['posts'] for x in r['platforms'])==main['posts']
checks['core_reconciles'] = sum(x['posts'] for x in r['actor_groups'] if x['group'] not in ['public','other_christian'])==core['posts']
top = r['top_sources']
checks['top50_sorted_unique'] = len(top)==50 and len({x['source_id'] for x in top})==50 and all(top[i]['interactions']>=top[i+1]['interactions'] for i in range(49))
checks['theme_denominators'] = all(0<=x['hits']<=x['posts'] and abs(x['hits']/x['posts']-x['share'])<1e-9 for x in r['themes'])
checks['concentration_monotone'] = all(0<=x['top1']<=x['top5']<=x['top10']<=x['top50']<=1 for x in r['concentration'])
with (OUT/'top-50-izvora.csv').open(encoding='utf-8-sig',newline='') as f:
    rows=list(csv.DictReader(f,delimiter=';'))
checks['companion_50'] = len(rows)==50
checks['csv_matches_analysis'] = all(int(a['Zabilježene interakcije'])==b['interactions'] and a['Izvor']==b['source'] for a,b in zip(rows,top))
checks['uncoded_fields_empty'] = all(not x[k] for x in rows for k in x if 'za dopunu' in k)
pdf=fitz.open(OUT/'katolicki-akteri-istrazivacki-uvid.pdf')
checks['six_pages'] = len(pdf)==6
qa=ROOT/'tmp/pdfs/theological-authority';qa.mkdir(parents=True,exist_ok=True)
texts=[]
for i,p in enumerate(pdf):
    text=p.get_text();texts.append(text)
    assert len(text)>700
    p.get_pixmap(matrix=fitz.Matrix(1.3,1.3)).save(qa/f'page-{i+1}.png')
    for block in p.get_text('dict')['blocks']:
        if block['type']!=0: continue
        for line in block['lines']:
            for span in line['spans']:
                x0,y0,x1,y1=span['bbox']
                assert x0>=39 and x1<=p.rect.width-38 and y0>=20 and y1<=p.rect.height-20,(i,span)
checks['croatian_text'] = all('\ufffd' not in t for t in texts) and 'svećenički' in ''.join(texts).lower()
checks['pdf_readable_geometry'] = True
checks['html_images_present'] = all((OUT / p).exists() for p in re.findall(r'<img src="([^"]+)"',(OUT/'izvjestaj.html').read_text(encoding='utf-8')))
digest=hashlib.sha256()
with (ROOT/r['input']['path']).open('rb') as f:
    for chunk in iter(lambda:f.read(8*1024*1024),b''):digest.update(chunk)
checks['input_unchanged'] = digest.hexdigest()==r['input']['sha256']
assert all(checks.values()), checks
result={'checks':checks,'passed':len(checks),'page_characters':[len(t) for t in texts],
        'visual_review':'Rendered pages require visual inspection by the authoring agent.'}
(OUT/'verification.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
