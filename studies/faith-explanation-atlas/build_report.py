"""Read-only evidence assembly and rendering. Never imports analytical study code."""
import csv,hashlib,html,json,pathlib,re,shutil,sys
import pyarrow.parquet as pq
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib import colors
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import SimpleDocTemplate,Paragraph,Spacer,PageBreak,Table,TableStyle,Image,KeepTogether
from reportlab.lib.enums import TA_LEFT
from manuscript import PAGES,QUOTES
sys.stdout.reconfigure(encoding='utf8')
ROOT=pathlib.Path(__file__).resolve().parents[2]
OUT=ROOT/'studies/faith-explanation-atlas/output/private'
COMP=OUT/'companion';COMP.mkdir(parents=True,exist_ok=True)
B=ROOT/'studies/theological-voices-v2/output/private'
D=ROOT/'studies/theological-voices/output/private'
AP=pathlib.Path('C:/Users/lsikic/Luka C/DigiKat_voices_work')
CP=ROOT/'studies/theological-voices-editorial/output/private'
used={}
def read(p):
    data=p.read_bytes();used[str(p.resolve())]=dict(sha256=hashlib.sha256(data).hexdigest(),bytes=len(data));return data
def js(p):return json.loads(read(p).decode('utf-8-sig'))
def cs(p):return list(csv.DictReader(read(p).decode('utf-8-sig').splitlines()))
def writecsv(p,rows):
    if not rows:return
    with p.open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
def dump(p,obj):p.write_text(json.dumps(obj,ensure_ascii=False,indent=2),encoding='utf8')
def fmt(n):return f'{int(n):,}'.replace(',','\u00a0')
a=js(AP/'report_data.json');d=js(D/'report_data.json');c=js(CP/'report_data.json')['claims'];reg=js(AP/'office_register.json')
dr=cs(D/'voices_summary.csv');persons={x['id']:x for x in dr}
ar={x['entity_id']:x for x in a['values']['people']}
vr=cs(B/'tables/voices.csv')
read(B/'main_inputs.parquet');full=pq.read_table(B/'main_inputs.parquet').to_pandas().set_index('publication_id')
read(B/'diagnostic_review.json');read(B/'statement_probe_review.json');read(B/'report_policy.json');read(B/'deterministic_reuse_cases.json')
read(ROOT/'studies/catholic-voices-network/output/private/report/tko-govori-o-vjeri.qmd')
read(ROOT/'quality_reports/2026-11-02_faith-explanation-atlas-plan-review.md')
roster=cs(ROOT/'studies/theological-voices/voices.csv')
writecsv(COMP/'population_A_110_public_presence.csv',a['values']['people'])
(COMP/'population_D_117_closed_list.csv').write_bytes(read(ROOT/'studies/theological-voices/voices.csv'))
writecsv(COMP/'population_A_1394_reference_only.csv',[{k:json.dumps(v,ensure_ascii=False) if isinstance(v,(list,dict)) else v for k,v in x.items()} for x in reg['people']])
(COMP/'D_voices_summary_116_rows.csv').write_bytes(read(D/'voices_summary.csv'))
summaries=dict(D={k:d[k] for k in ['scope','list','roles','stmt_total','women_stmt','bishop_other_share','label','echo_sequences','sample','top50_tip','top50_obrazovanje','pulherissimus']},A={k:a['values'][k] for k in ['corpus','scope','platforms','source_distribution','circulation_sizes']},A_person_measures=a['evidence']['network_metrics']['measures'],A_adjacent_top20=a['evidence']['network_metrics']['adjacent_top20'],C={k:v for k,v in c.items() if k.startswith('source_') or k in ['frame_n','sources_n']})
dump(COMP/'saved_summary_tables.json',summaries)
writecsv(COMP/'D_role_summary.csv',d['roles'])
writecsv(COMP/'A_person_measures.csv',a['evidence']['network_metrics']['measures'])
sourcefig=ROOT/'studies/catholic-voices-network/output/private/report/figures/network_outlets.svg'
(COMP/'network_outlets.svg').write_bytes(read(sourcefig))
# Use the unchanged figure as printed in the reviewed source PDF, avoiding SVG conversion differences.
import fitz
sourcepdf=ROOT/'studies/catholic-voices-network/output/private/report/tko-govori-o-vjeri.pdf'
read(sourcepdf)
sd=fitz.open(sourcepdf)
hits=[]
for i,p in enumerate(sd):
    t=p.get_text()
    if 'zajedničkih izvora' in t.lower() or 'mreža izvora' in t.lower():hits.append((i,t[:150]))
print('Source network page candidates',hits)
# Extract SVG into a ReportLab drawing if available, keeping the complete figure.
from svglib.svglib import svg2rlg
drawing=svg2rlg(str(COMP/'network_outlets.svg'))
scale=min(450/drawing.width,275/drawing.height);drawing.scale(scale,scale);drawing.width*=scale;drawing.height*=scale
quote_rows=[];checks=[]
def ws(s):return re.sub(r'\s+',' ',s).strip()
qmeta={}
for i,q in QUOTES.items():
    r=vr[i];body=full.loc[r['publication_id'],'body_clean']
    ok=ws(q) in ws(body);checks.append(dict(row=i,publication_id=r['publication_id'],exact_normalized_whitespace_match=ok))
    if not ok: raise ValueError(f'Quotation mismatch {i}')
    passage_ids=[p['id'] for p in json.loads(r['statement_passages']) if ws(q) in ws(p['text'])]
    if not passage_ids:
        passage_ids=json.loads(r['statement_ids'])
    qmeta[i]=f"{r['outlet_name']} · {r['published_at']}"
    quote_rows.append(dict(display_id=f'Q{i}',original_csv_data_row_zero_based=i,publication_id=r['publication_id'],name=r['name'],outlet=r['outlet_name'],published_at=r['published_at'],title=r['title'],url=r['url'],original_mode=r['mode'],original_interprets_faith=r['interprets_faith'],original_role=r['role'],task_valid=r['task_valid'],complete_article_base=r['complete_article_base'],statement_ids=r['statement_ids'],display_text=q,full_text_location='studies/theological-voices-v2/output/private/main_inputs.parquet',input_hash=r['input_hash'],full_saved_text_editorially_read=True,quote_check='exact after whitespace normalization',omissions='No editorial internal omission; original ellipses preserved where present.',note='Source excerpt; reported speech retains intermediary attribution. Q2377 is a short-passage exception; Q1591 an institutional-text exception.'))
writecsv(COMP/'displayed_passages.csv',quote_rows)
# Restricted display companion deliberately carries only displayed text, not all private context passages.
for i in [1605,1746,577,123,124,128]:
    r=vr[i]
    quote_rows.append(dict(display_id=f'R{i}',original_csv_data_row_zero_based=i,publication_id=r['publication_id'],name=r['name'],outlet=r['outlet_name'],published_at=r['published_at'],title=r['title'],url=r['url'],original_mode=r['mode'],original_interprets_faith=r['interprets_faith'],original_role=r['role'],task_valid=r['task_valid'],complete_article_base=r['complete_article_base'],statement_ids=r['statement_ids'],display_text='',full_text_location='studies/theological-voices-v2/output/private/main_inputs.parquet',input_hash=r['input_hash'],full_saved_text_editorially_read=True,quote_check='Not quoted',omissions='Not applicable',note='Discussed limitation or diagnostic, not a positive explanation example.'))
writecsv(COMP/'passage_evidence_index.csv',quote_rows)
measures={x['entity_id']:x for x in a['evidence']['network_metrics']['measures']}
portraitids=['Q450675','Q6109517','Q1256070','Q335206','Q1232284','Q365529','Q741036','Q23711406']
split=[['Osoba','Vjerski mediji','Sekularni mediji','Vrsta medija: ?']]
splitrows=[]
for eid in portraitids:
    m=measures[eid];den=m['mentioned_documents'];values=[m[k] for k in ['confessional_documents','secular_documents','unlabelled_documents']]
    assert sum(values)==den
    split.append([ar[eid]['public_name']]+[f'{100*v/den:.1f}'.replace('.',',')+' %' for v in values])
    splitrows.append(dict(entity_id=eid,name=ar[eid]['public_name'],denominator_documents=den,confessional_documents=values[0],secular_documents=values[1],unlabelled_documents=values[2]))
writecsv(COMP/'displayed_outlet_shares.csv',splitrows)
def subst(m):
    key=m.group(1);bits=key.split(':')
    if bits[0]=='D':return fmt(persons[bits[1]][bits[2]])
    if bits[0]=='DROLE':return fmt(next(x for x in d['roles'] if x['role']==bits[1])[bits[2]])
    if bits[0]=='DLIST':return fmt(d['list'][bits[1]])
    if bits[0]=='A':return fmt(a['values'][bits[1]][bits[2]])
    if bits[0]=='PERSON':return fmt(ar[bits[1]][bits[2]])
    if bits[0]=='C':return c[bits[1]]['display']
    if key=='REGISTER':return fmt(len(reg['people']))
    if key=='DTOTAL':return fmt(d['stmt_total'])
    return m.group(0)
for p in PAGES:p['body']=re.sub(r'\{\{([^}]+)\}\}',subst,p['body'])
FONTS=pathlib.Path('C:/Windows/Fonts')
for name,file in [('Palatino','pala.ttf'),('PalatinoBold','palab.ttf'),('PalatinoItalic','palai.ttf'),('Segoe','segoeui.ttf'),('SegoeBold','segoeuib.ttf')]:pdfmetrics.registerFont(TTFont(name,str(FONTS/file)))
ink=colors.HexColor('#243337');accent=colors.HexColor('#1d665f');muted=colors.HexColor('#596566')
styles={
 'body':ParagraphStyle('body',fontName='Palatino',fontSize=11.2,leading=15.7,spaceAfter=10,textColor=ink),
 'title':ParagraphStyle('title',fontName='PalatinoBold',fontSize=25,leading=29,spaceAfter=20,textColor=ink),
 'kicker':ParagraphStyle('kicker',fontName='SegoeBold',fontSize=8.6,leading=12,spaceAfter=13,textColor=accent),
 'quote':ParagraphStyle('quote',fontName='PalatinoItalic',fontSize=11.1,leading=15.5,spaceBefore=10,spaceAfter=16,leftIndent=15,rightIndent=10,borderPadding=9,borderColor=accent,borderWidth=0.6,textColor=ink),
 'note':ParagraphStyle('note',fontName='Segoe',fontSize=8.1,leading=11.3,spaceAfter=9,textColor=muted),
 'cell':ParagraphStyle('cell',fontName='Segoe',fontSize=8,leading=11,textColor=ink),
}
styles['coverbody']=ParagraphStyle('coverbody',parent=styles['body'],fontSize=14,leading=21,textColor=colors.HexColor('#e6efea'),spaceAfter=20)
styles['covertitle']=ParagraphStyle('covertitle',parent=styles['title'],fontSize=40,leading=46,textColor=colors.white,spaceAfter=32)
styles['coverkicker']=ParagraphStyle('coverkicker',parent=styles['kicker'],textColor=colors.HexColor('#93c5b4'))
def par(t,style='body'):return Paragraph(html.escape(t),styles[style])
from visual_layout import render
index=render(OUT,PAGES,QUOTES,qmeta,vr,split,a,d,c,persons,splitrows)
pdf=OUT/'tko-vjeri-daje-javni-glas.pdf'
writecsv(COMP/'evidence_index.csv',index)
dump(COMP/'source_manifest.json',used)
dump(OUT/'quotation_verification.json',checks)
dump(OUT/'page_plan.json',[dict(page=i,title=p['title'],section=p['section']) for i,p in enumerate(PAGES,1)])
missing=[x['id'] for x in roster if x['id'] not in persons]
readme=f'''TKO VJERI DAJE JAVNI GLAS? — private local edition, 2026-11-02

Open tko-vjeri-daje-javni-glas.pdf or the navigable HTML file. No website was published.

Source hierarchy: D closed-list statements; A public presence/networks/time; B editorial passage display only; C sources and exact reuse. B's withdrawn numerical content claims remain withdrawn. This is an editorial synthesis, not new analysis or model validation.

COMPANION
population_A_110_public_presence.csv — {len(ar)} observed public identities under A's inclusion rules.
population_D_117_closed_list.csv — {len(roster)} original selected persons, unchanged source file.
population_A_1394_reference_only.csv — {len(reg['people'])} register records; not observed speakers. Nested original fields remain JSON strings.
D_voices_summary_116_rows.csv — unchanged original summary, {len(dr)} rows. Roster-only IDs: {missing}. No inferred zero added.
displayed_passages.csv — {len(QUOTES)} displayed excerpts with original row indices, publication IDs, dates, attribution labels, URLs and text locators. Only displayed text is reproduced; potentially identifying private context is not copied.
passage_evidence_index.csv — those excerpts plus discussed limitation/diagnostic rows, without their surrounding private material.
saved_summary_tables.json, D_role_summary.csv, A_person_measures.csv — saved results, not rerun analysis. Counts across studies must not be summed.
displayed_outlet_shares.csv — existing three-category counts behind the displayed percentages, denominator per person.
evidence_index.csv — every page and its source locators.
network_outlets.svg — unchanged figure from A. No new network computation.
source_manifest.json — source paths, bytes and SHA-256 digests. Hashes checked after production.

PRESERVED SOURCES
A report and figures: {ROOT/'studies/catholic-voices-network/output/private/report'}
A saved aggregates and register: {AP}
A full mention inventory: {AP/'voices.duckdb'} (8,037,060 mention records and 705,095 detected strings in the saved plan; no query or export in this edition). The unpublished 31,458 rule-tier statement candidates are excluded.
D: {D}; original roster at {ROOT/'studies/theological-voices/voices.csv'}
B full saved cleaned texts: {B/'main_inputs.parquet'}, located by publication_id and input_hash. Original voices table at {B/'tables/voices.csv'}. Coding database retained in place; not opened here.
C: {CP}

EDITORIAL EXCEPTIONS
Eight extended and twelve medium portraits retained. No invented passage fills a gap. Tanjić is represented by institutional reporting; Vukman by an event report; Vučković by an announcement; Markić has no displayed own passage. Sente junior is explicitly separated from senior; D's aggregate is not repaired or claimed disambiguated. Lončar's institutional passage retains its original interprets_faith=no label. The short Lav XIV response is deliberately retained despite the proposed approximate 300-character candidate preference. Vučetić's model role is not adopted as a biography. Historical authors in the label discussion and saint diagnostics are cited authorities, not contemporary voices. Posthumous counts are explicitly qualified.
Quotations were read in their complete saved cleaned articles. All displayed strings match after whitespace normalization. Quotes are excerpts, not whole articles; no internal editorial omissions were introduced. Existing ellipses remain. Sources' original punctuation is retained even when it differs from house prose style. Page 27 records the indirect report of an off-camera papal conversation, not a verified transcript. No live-page or historical-fact verification was performed.

METHOD BOUNDARY
No new model runs, corpus processing, identity merges, thematic coding, analytic sampling, database queries, network estimation or publication. Selection of saved rows was solely for display. Scripts read saved tables and calculate display percentages from existing counts. R 4.6.0 read sample.rds successfully (300 rows), with locale warnings. The report itself uses CSV/JSON/Parquet, not RDS.

BUILD
python studies/faith-explanation-atlas/build_report.py
python studies/faith-explanation-atlas/verify_report.py
Python, ReportLab, PyArrow, PyMuPDF, Pillow, svglib, and local Palatino/Segoe fonts are used. No analytical source code is imported.
'''
(OUT/'README.txt').write_text(readme,encoding='utf8')
print(json.dumps(dict(planned_pages=len(PAGES),actual_pdf_pages=len(fitz.open(pdf)),quotes=len(QUOTES),missing_summary_ids=missing),ensure_ascii=False))
