import csv,hashlib,json,pathlib,re,zipfile
from html.parser import HTMLParser
OUT=pathlib.Path(__file__).resolve().parent/'output/private'
class Inspect(HTMLParser):
    def __init__(self):super().__init__();self.ids=set();self.links=[];self.img=[]
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if 'id' in a:self.ids.add(a['id'])
        if tag=='a':self.links.append(a.get('href',''))
        if tag=='img':self.img.append(a.get('src',''))
p=Inspect();p.feed((OUT/'tko-vjeri-daje-javni-glas.html').read_text(encoding='utf8'))
assert all(x[1:] in p.ids for x in p.links if x.startswith('#'))
assert all((OUT/x).is_file() for x in p.img)
assert len([x for x in p.ids if x.startswith('page-')])==35
assert len(p.img)==35
revision=json.loads((OUT/'revision_verification.json').read_text(encoding='utf8'))
v=json.loads((OUT/'verification.json').read_text(encoding='utf8'))
v['visual_review']='All 35 reader-edition PDF pages visually inspected by agent, including chart panels, rewritten explanations, legends, table and original quotations. No clipping or overlap found.'
v['html_static_checks']='35 section targets, exactly one local visual per section, all internal navigation targets and assets resolve. All 17 quotations match the previous visual edition.'
v['visual_revision']=revision
v['html_visual_review']='Unverified: isolated Chrome and Edge processes failed before rendering. See html-qa-* failure logs. PDF is the visually verified edition.'
(OUT/'verification.json').write_text(json.dumps(v,ensure_ascii=False,indent=2),encoding='utf8')
readme=OUT/'README.txt'
readme.write_text(readme.read_text(encoding='utf8').split('\nVISUAL REVISION\n')[0],encoding='utf8')
with readme.open('a',encoding='utf8') as f:f.write('''\nVISUAL REVISION
Reader edition: 35 pages with one visual each; 30 quantitative panels, one source network, four explanatory diagrams. All explanations, headings and captions were rewritten in plain Croatian at the user's request. Technical instructions and negative editorial definitions were removed from the reading pages. The original 17 quotations remain exact. The two technical opening diagrams were replaced with roster composition and collected-platform charts; later diagrams now explain message forms, interpretation and the findings.

Provenance remains in companion/figure_manifest.json (technical_source and plotted values), evidence_index.csv, methods_and_limits.txt and source_manifest.json. Technical companion material describes the original methods, limitations and diagnostic failures. Pages carry plain study labels, dates and quotation sources. Original editions remain locally under revisions/prose-edition and revisions/visual-edition, outside the ZIP.

Chart values retained from the previous visual edition are unchanged. New panels reuse saved roster and platform aggregates. No models, corpus processing, identity merging or network estimation was run. Source files are unchanged. New SVG text uses outlines for portability.

Rebuild: build_report.py; verify_report.py; verify_visual_revision.py; visually inspect rendered pages; finalize.py. To reapply the reader-copy definitions after editing reader_copy.py, first run apply_reader_copy.py.

FINAL VERIFICATION
All 35 reader-edition PDF pages visually checked. All 17 quotations match their saved full text after whitespace normalization. All 16 recorded source hashes unchanged. HTML navigation and assets pass static checks. Browser visual verification remains unavailable following the earlier Chrome and Edge renderer failures. PDF is the visually checked reading edition.
''')
review=dict(pdf_sha256=v['pdf_sha256'],reviewer='Codex agent',pages_reviewed=list(range(1,36)),method='Final rendered PNG contact sheets, four pages per image, all nine sheets inspected.',result='pass',limitations='Not a human review, live-source verification or model-accuracy estimate.')
(OUT/'visual_review.json').write_text(json.dumps(review,indent=2),encoding='utf8')
files=[OUT/'tko-vjeri-daje-javni-glas.pdf',OUT/'tko-vjeri-daje-javni-glas.html',OUT/'README.txt',OUT/'verification.json',OUT/'quotation_verification.json',OUT/'visual_review.json',OUT/'page_plan.json',OUT/'revision_verification.json',OUT/'layout_verification.json']+[f for f in (OUT/'companion').rglob('*') if f.is_file()]
manifest=[dict(file=f.relative_to(OUT).as_posix(),bytes=f.stat().st_size,sha256=hashlib.sha256(f.read_bytes()).hexdigest()) for f in files]
(OUT/'delivery_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf8')
files.append(OUT/'delivery_manifest.json')
with zipfile.ZipFile(OUT/'faith-explanation-atlas-private.zip','w',zipfile.ZIP_DEFLATED) as z:
    for f in files:z.write(f,f.relative_to(OUT))
print(json.dumps(dict(pdf_pages=35,quotations=17,delivery_files=len(files),zip_bytes=(OUT/'faith-explanation-atlas-private.zip').stat().st_size)))
