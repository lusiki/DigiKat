"""Reconciliation, complete ranking, metric missingness and rendered PDF checks."""
from pathlib import Path
import csv, hashlib, json, math, re, zipfile
import fitz
from PIL import Image, ImageDraw
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
OUT=HERE/'output/private/extended'
AGG=HERE/'output/extended'
E=json.loads((OUT/'results.json').read_text(encoding='utf-8'))
R=json.loads((HERE/'output/private/results.json').read_text(encoding='utf-8'))
q={}
def total(rows,col):return sum(r[col] or 0 for r in rows)
platform=E['platform'];selected=[r for r in platform if r['scope']=='selected']
sources=E['source_ranking'];ranked=[r for r in sources if r['interaction_n']>0]
q['main_reconciles']=total([r for r in platform if r['scope']=='all'],'posts')==R['main'][0]['posts']
q['selected_reconciles']=total(selected,'posts')==R['core'][0]['posts']==total(sources,'posts')
q['three_scope_parts_reconcile']=sum(r['posts'] for r in R['actor_groups'])==R['main'][0]['posts'] and sum(r['posts'] for r in R['actor_groups'] if r['group'] in ['public','other_christian'])+R['core'][0]['posts']==R['main'][0]['posts']
q['reach_reconciles']=total(selected,'reach_total')==total(sources,'reach_total')
q['interactions_reconcile']=total(selected,'interactions')==R['core'][0]['interactions']==total(ranked,'interactions')
q['no_missing_metric_rank']=all(r['rank'] is None and r['platform_rank'] is None for r in sources if r['interaction_n']==0)
q['ranking_contiguous']=list(range(1,len(ranked)+1))==[r['rank'] for r in ranked]
q['top50_matches_base']=[r['source_id'] for r in ranked[:50]]==[r['source_id'] for r in R['top_sources']]
q['rankings_within_platform']=all([r['platform_rank'] for r in ranked if r['SOURCE_TYPE']==p]==list(range(1,1+sum(r['SOURCE_TYPE']==p for r in ranked))) for p in ['web','facebook','youtube','instagram','tiktok','twitter'])
q['unavailable_is_na']=all(r['interactions'] is None and r['reach_total'] is None for r in platform if r['SOURCE_TYPE'] in ['reddit','forum','comment'])
q['reach_coverage_valid']=all(0<=r['reach_n']<=r['posts'] for r in platform)
q['four_month_gap']=E['missing_months']==['2024-02','2024-03','2024-04','2024-05']
q['cohort_same_sources']=all(len(set(r['sources'] for r in E['cohort_matched'] if r['SOURCE_TYPE']==p))==1 for p in ['web','facebook','youtube'])
q['monthly_totals']=total([r for r in E['monthly'] if r['scope']=='selected'],'posts')==R['core'][0]['posts']
q['annual_totals']=total([r for r in E['annual'] if r['scope']=='selected'],'posts')==R['core'][0]['posts']
q['rank_overlap_recomputed']=len(set(r['source_id'] for r in ranked[:50]) & set(r['source_id'] for r in E['source_year'] if r['year_calc']==2025))==E['rank_overlap'][0]['overlap']
with (OUT/'top-50-izvora.csv').open(encoding='utf-8-sig',newline='') as f:top=list(csv.DictReader(f,delimiter=';'))
q['csv50_exact']=len(top)==50 and all(a['source_id']==b['source_id'] and float(a['interactions'])==b['interactions'] and int(a['rank'])==b['rank'] for a,b in zip(top,ranked))
with (OUT/'top-50-sve-oznake-izvora.csv').open(encoding='utf-8-sig',newline='') as f:full_top=list(csv.DictReader(f,delimiter=';'))
q['full_corpus_top50']=len(full_top)==50 and [int(r['rank']) for r in full_top]==list(range(1,51)) and all(float(full_top[i]['interactions'])>=float(full_top[i+1]['interactions']) for i in range(49))
q['full_scope_not_confused_with_selected']=full_top[0]['source_id']!=top[0]['source_id'] and sum(r['group']=='public' for r in full_top)==33
q['unverified_fields_blank']=all(not row[c] for row in top for c in ['institutional_mandate','theological_education','authority_invoked','research_notes'])
with zipfile.ZipFile(AGG/'agregati-za-dijeljenje.zip') as z:
    q['zip_no_identities']=True
    for name in z.namelist():
        if name.endswith('.csv'):
            header=next(csv.reader(z.read(name).decode('utf-8-sig').splitlines()))
            if set(header) & {'source_id','source','FROM','FULL_TEXT','URL','AUTHOR'}:q['zip_no_identities']=False
pdf=fitz.open(OUT/'katolicki-akteri-platforme-doseg-vrijeme.pdf')
q['twenty_pages']=len(pdf)==20
qa=ROOT/'tmp/pdfs/theological-authority-extended';qa.mkdir(parents=True,exist_ok=True)
texts=[];geometry=[]
for i,p in enumerate(pdf):
    txt=p.get_text();texts.append(txt)
    p.get_pixmap(matrix=fitz.Matrix(1.2,1.2)).save(qa/f'page-{i+1:02d}.png')
    for block in p.get_text('dict')['blocks']:
        if block['type']!=0:continue
        for line in block['lines']:
            for span in line['spans']:
                x0,y0,x1,y1=span['bbox']
                if not(x0>=37 and x1<=p.rect.width-35 and y0>=19 and y1<=p.rect.height-19):geometry.append((i+1,span['text'],span['bbox']))
q['geometry_inside_page']=not geometry
q['croatian_valid']=all('\ufffd' not in t for t in texts) and 'Svećenički' in ''.join(texts)
q['all_50_in_pdf']=all(r['source'] in ''.join(texts[-3:]).replace('\n',' ') for r in ranked[:50])
q['denominators_visible']=all(s in ''.join(texts[:3]) for s in ['601.036','153.015','441.969','6.052','25,5 %'])
q['no_empty_pages']=all(len(t)>1000 for t in texts)
q['html_images_present']=all((OUT/p).exists() for p in re.findall(r'<img src="([^"]+)"',(OUT/'izvjestaj.html').read_text(encoding='utf-8')))
h=hashlib.sha256()
with (ROOT/R['input']['path']).open('rb') as f:
    for chunk in iter(lambda:f.read(8*1024*1024),b''):h.update(chunk)
q['input_unchanged']=h.hexdigest()==R['input']['sha256']
# Contact sheets support page-by-page visual review; full images retained.
for start in range(0,20,4):
    sheet=Image.new('RGB',(900,1330),'#dfe5e0');draw=ImageDraw.Draw(sheet)
    for off in range(4):
        im=Image.open(qa/f'page-{start+off+1:02d}.png');im.thumbnail((438,620))
        x=10+(off%2)*450;y=25+(off//2)*660
        sheet.paste(im,(x,y));draw.text((x,y-18),f'Page {start+off+1}',fill='black')
    sheet.save(qa/f'contact-{start//4+1}.png')
res={'checks':q,'passed':sum(q.values()),'page_characters':[len(t) for t in texts],'geometry_issues':geometry,
 'render_engine':'PyMuPDF (Poppler not installed)','visual_review':'pending'}
(OUT/'verification.json').write_text(json.dumps(res,indent=2),encoding='utf-8')
print(json.dumps(res,ensure_ascii=True,indent=2))
assert all(q.values()),[k for k,v in q.items() if not v]
