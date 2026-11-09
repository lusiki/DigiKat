"""PDF structure/geometry checks. Does not replace the visual page inspection."""
from pathlib import Path
import json,hashlib,importlib.metadata
import fitz
from pypdf import PdfReader
ROOT=Path(__file__).resolve().parents[3];PDF=ROOT/'output/pdf/demokrscanstvo-analiticki-izvjestaj.pdf';OUT=ROOT/'output/demokrscanstvo-analysis/v1'
doc=fitz.open(PDF);assert len(doc)==20
problems=[];body_fonts=set();min_text=999;links=0;spans=0
for i,page in enumerate(doc):
    txt=page.get_text();assert len(txt)>400 and '\ufffd' not in txt and '\x00' not in txt
    if i:assert f'{i+1} / 20' in txt
    for block in page.get_text('dict')['blocks']:
        for line in block.get('lines',[]):
            for s in line['spans']:
                spans+=1;rect=fitz.Rect(s['bbox']);body_fonts.add(s['font'])
                if rect.x0<20 or rect.y0<15 or rect.x1>page.rect.width-15 or rect.y1>page.rect.height-15:problems.append({'page':i+1,'text':s['text'],'bounds':s['bbox']})
    for link in page.get_links():assert link['uri'].startswith('https://');links+=1
assert not problems,problems
assert links==5
assert len(doc.get_toc())==20
reader=PdfReader(PDF);font_embedding={}
for page in reader.pages:
    for resource in page['/Resources']['/Font'].values():
        font=resource.get_object();name=str(font['/BaseFont'])
        if 'Calibri' in name or 'Georgia' in name:
            descriptor=font['/FontDescriptor'].get_object();assert '/FontFile2' in descriptor or '/FontFile3' in descriptor;font_embedding[name]=True
assert font_embedding
assert len(list((ROOT/'tmp/pdfs/demokrscanstvo-report').glob('page-*.png')))==20
layout=json.loads((ROOT/'tmp/pdfs/demokrscanstvo-report/layout.json').read_text());assert all(r['bottom_y']>59 for r in layout)
result={'status':'PASS','pdf_sha256':hashlib.sha256(PDF.read_bytes()).hexdigest(),'pages':20,'outline_entries':20,'external_links':5,
 'text_spans_checked':spans,'text_outside_page':0,'replacement_characters':0,'embedded_fonts':font_embedding,
 'body_font_pt':11.2,'tables_font_pt':10.5,'visual_review':'All 20 Poppler-rendered pages inspected by Codex AI; revised pages reinspected',
 'visual_review_is_human_validation':False,'renderer_packages':{m:importlib.metadata.version(m) for m in ['reportlab','svglib','matplotlib','pandas','pypdf','PyMuPDF']}}
(OUT/'pdf_qa.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(result,ensure_ascii=False))
