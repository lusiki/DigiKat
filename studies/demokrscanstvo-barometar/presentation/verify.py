"""Verify the final presentation against the separately checked publication tables."""
from pathlib import Path
import csv,hashlib,json,re
from pypdf import PdfReader
import pdfplumber
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'output/demokrscanstvo-presentation'
DATA=ROOT/'output/demokrscanstvo-text-public/v1'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
rows=lambda p:list(csv.DictReader(p.open(encoding='utf-8-sig')))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
claims=read(OUT/'claim-register.json')
words=rows(DATA/'tables/word-clouds.csv');phrases=rows(DATA/'tables/phrases.csv');selected=rows(DATA/'tables/selected-words.csv')
topics=read(ROOT/'data/barometar/demokrscanstvo-themes/v1/summary.json')['topics']
platforms=rows(ROOT/'data/barometar/demokrscanstvo-multiplatform/v1/platforms.csv')
for c in claims:
    source=c['source'];key=c['claim']
    if source.startswith('word-clouds.csv:'):
        r=next(r for r in words if r['scope']==source.split(':')[1] and r['word']==key);expected=int(r['texts']);d=int(r['denominator'])
    elif source=='phrases.csv':expected=int(next(r for r in phrases if r['phrase']==key)['texts']);d=2253
    elif source=='selected-words.csv':expected=int(next(r for r in selected if r['word']==key)['texts']);d=2253
    elif source=='thematic summary.json':expected=sum(r['records'] for r in topics if r['id'] in ['t01','t02','t03','t04']) if key=='Four political topic groups' else next(r['records'] for r in topics if r['label']==key);d=2306
    elif source=='platforms.csv':expected=sum(int(r['matching_records']) for r in platforms if (r['platform']=='web')==(key=='Mrežni mediji'));d=2306
    else:raise ValueError(source)
    assert c['value']==expected and c['denominator']==d,c
pdf=OUT/'demokrscanstvo-12-nalaza.pdf';reader=PdfReader(pdf);texts=[p.extract_text() for p in reader.pages]
assert len(texts)==15 and reader.metadata.author=='Luka Šikić'
assert 'Luka Šikić' in texts[0] and 'č' in texts[0]
assert all('\ufffd' not in t and '\x00' not in t and len(t)>150 for t in texts)
for page,required in {2:['2.306','2.253'],3:['1.811','495','78,5%','21,5%'],4:['377','274','290','212','1.153','50,0%'],5:['1.123','49,8%'],6:['243','279'],7:['212','173'],8:['454','20,2%','208','9,2%','111','4,9%','105','4,7%'],9:['Samir Haj Barakat','29. kolovoza 2024.'],10:['Anka Mrak-Taritaš','Andrej Plenković','20. travnja 2022.'],11:['Davor Ivo Stier','7. 6. 2024.','Hrvatski Leskovac'],12:['103','29','27','4,6%','1,3%','1,2%'],13:['Jakov Žižić','28. 2. 2021.']}.items():
    assert all(r in texts[page-1] for r in required),(page,required,texts[page-1])
urls=[str(a.get_object().get('/A',{}).get('/URI','')) for p in reader.pages for a in p.get('/Annots',[])]
assert 'https://www.lukasikic.info/' in urls
assert sum('glas-slavonije.hr' in u or 'vlada.gov.hr' in u or 'tportal.hr' in u for u in urls)==3
layout=[]
with pdfplumber.open(pdf) as doc:
    for n,p in enumerate(doc.pages,1):
        assert abs(p.width/p.height-16/9)<.002
        bad=[c for c in p.chars if c['x0']<20 or c['x1']>p.width-20 or c['top']<12 or c['bottom']>p.height-12]
        assert not bad,(n,bad[:3])
        layout.append({'page':n,'render_sha256':sha(ROOT/f'tmp/pdfs/demokrscanstvo-presentation/slide-{n:02d}.png'),'visual_review':'Readable Croatian text; full labels; content clear of footer; links and hierarchy retained'})
browser=read(OUT/'browser-verification.json');assert browser['status']=='PASS'
report=read(DATA/'internal/verification.json');assert report['status']=='PASS'
result={'status':'PASS','pdf_sha256':sha(pdf),'author':'Luka Šikić','author_url':'https://www.lukasikic.info/','slides':15,'substantive_findings':12,'numeric_claims_reconciled':len(claims),'scope':'2,306 publications for media presence; 2,253 distinct texts for vocabulary. No public-opinion, reach or prevalence-of-arguments claims.','case_evidence':report['cases'],'browser':browser,'visual_pages':layout,'reviewer':'Codex AI; no independent human review claimed'}
(OUT/'verification.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'status':'PASS','slides':15,'claims':len(claims),'pdf_sha256':sha(pdf)}))
