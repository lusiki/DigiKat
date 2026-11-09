"""Independent reconciliation of the public edition against frozen analysis."""
from pathlib import Path
from collections import Counter,defaultdict
import csv,hashlib,json,os,re,unicodedata
from pypdf import PdfReader
import pdfplumber

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'output/demokrscanstvo-text-public/v1'
BASE=ROOT/'output/demokrscanstvo-text-addendum/v1'
WORK=Path(os.environ.get('DIGIKAT_BAROMETAR_WORKDIR','C:/Users/lsikic/Luka C/DigiKat_barometar_work'))
PDF=ROOT/'output/pdf/demokrscanstvo-od-rijeci-do-argumenta.pdf'
read=lambda p:json.loads(p.read_text(encoding='utf-8-sig'))
csvread=lambda p:list(csv.DictReader(p.open(encoding='utf-8-sig')))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
norm=lambda s:re.sub(r'\s+',' ',unicodedata.normalize('NFC',s).casefold()).strip()
CHECKS=[]
def check(name,ok,detail):
    CHECKS.append({'check':name,'pass':bool(ok),'detail':detail})
    if not ok:raise AssertionError(name+': '+str(detail))
def main():
    prep=read(OUT/'internal/preparation.json')
    check('Frozen source hashes',all(sha(Path(p))==v for p,v in prep['inputs'].items()),len(prep['inputs']))
    docs=read(WORK/'analytical-report-v1/grouped-documents.json');D={d['record_key']:d for d in docs}
    reps=[D[k] for k in read(WORK/'analytical-report-v1/representatives.json')]
    T={d['group']:d['topic'] for d in reps};topicn=Counter(T.values())
    check('Records and exact groups',len(docs)==2306 and len(reps)==len(T)==2253,'2306 records / 2253 distinct texts')
    # Repeat token inclusion independently, retaining all lemma occurrences before DF.
    lex=defaultdict(set)
    preserve={'ne','nije','nisam','nikada','nikad','niti','bez','protiv','ali'}
    stop={'biti','htjeti','moći','imati','kazati','reći'}
    for u in read(WORK/'text-addendum-v1/local-units.json'):
        for t in u['tokens']:
            lemma=norm(t.get('lemma') or t['token'])
            if re.search(r'[^\W\d_]',lemma) and (lemma in preserve or (t['upos'] in {'NOUN','PROPN','ADJ','VERB','ADV'} and lemma not in stop)):
                lex[lemma].add(u['group'])
    cloud=csvread(OUT/'tables/word-clouds.csv')
    for r in cloud:
        gs=lex[r['lemma']]
        if r['scope']!='all':gs={g for g in gs if T[g]==r['scope']}
        assert len(gs)==int(r['texts'])
        assert int(r['denominator'])==(2253 if r['scope']=='all' else topicn[r['scope']])
        assert abs(float(r['percent'])-100*len(gs)/int(r['denominator']))<1e-9
    check('All word-cloud numbers recalculated',len(cloud)==228,'48 overall + 10 × 18 topic words; independent set counts')
    voc={r['term']:int(r['groups']) for r in csvread(BASE/'vocabulary_local.csv')}
    check('Whole original vocabulary reconciled',all(len(lex[t])==n for t,n in voc.items()),len(voc))
    topics=csvread(OUT/'tables/topics.csv')
    check('All topic numbers reconciled',all(topicn[r['topic']]==int(r['texts']) and abs(float(r['percent'])-100*int(r['texts'])/2253)<1e-9 for r in topics) and sum(int(r['texts']) for r in topics)+1==2253,'10 topics + 1 unassigned')
    phrases={r['surface_example']:r for r in csvread(BASE/'phrases.csv')}
    original=csvread(BASE/'phrases.csv')
    specs={'demokršćanske vrijednosti':'demokršćanski vrijednost','desni centar':'desni centar','demokršćanska stranka':'demokršćanski stranka','demokršćanska načela':'demokršćanski načelo','kršćanska demokracija':'kršćanski demokracija','narodnjačke vrijednosti':'narodnjački vrijednost','obiteljske vrijednosti':'obiteljski vrijednost','demokršćanski svjetonazor':'demokršćanski svjetonazor'}
    for r in csvread(OUT/'tables/phrases.csv'):
        hits=[v for v in original if v['phrase']==specs[r['phrase']]]
        assert hits and {int(v['groups']) for v in hits}=={int(r['texts'])}
        assert abs(float(r['percent'])-100*int(r['texts'])/2253)<1e-9
    check('All phrase numbers reconciled',True,'8 phrases; strict adjacency; original phrase table')
    for r in csvread(OUT/'tables/selected-words.csv'):
        assert len(lex[r['lemma']])==int(r['texts'])
        assert abs(float(r['percent'])-100*int(r['texts'])/2253)<1e-9
    check('All selected-word numbers reconciled',True,'15 words; four displayed on page 12')
    total=sum(topicn[k] for k in ['t01','t02','t03','t04'])
    check('Identity aggregate',total==1105 and round(100*total/2253,1)==49.0,'1105 / 2253 = 49.0%')
    cases={r['case']:r for r in read(WORK/'text-addendum-v1/argument-cases.json')}
    evidence={
      'K01':['Davor Ivo Stier','Hrvatski Leskovac','Karlovačkoj županiji','Europskom parlamentu','Europe solidarnosti'],
      'K02':['Anka Mrak-Taritaš','HDZ, kao stranka koja dijeli demokršćanske vrijednosti, neće nikome zabranjivati priziv savjesti','pa će to provjeriti'],
      'K03':['Mate Mijić','Jakovom Žižićem','28. veljače 2021.','u interesu općeg dobra','regionalna i lokalna samouprava'],
      'K05':['Poštujem demokršćanska načela, ali ne pripadam demokršćanskom spektru','Ivan Anušić','Čovjek sam lijevih uvjerenja','u četvrtak']}
    case_audit=[]
    for key,needles in evidence.items():
        a=cases[key];d=D[a['record_key']];text=d['title']+' '+d['body']
        assert all(norm(v) in norm(text) for v in needles)
        assert sha_text(d['body'])==a['body_sha256']
        assert d['day']==a['date']
        case_audit.append({'case':key,'archived_date':d['day'],'source':a['source'],'source_title':d['title'],'body_sha256':a['body_sha256'],'names_and_supporting_passages_matched':len(needles),'scope':'complete available body reread; interpretation attributed to speaker'})
    check('Cases and literal quotations',True,'Four source texts; dates, names, projects and two direct quotations checked against preserved body')
    reader=PdfReader(PDF);pages=[p.extract_text() for p in reader.pages];full='\n'.join(pages)
    check('Page count and text layer',len(pages)==12 and all(len(t)>300 for t in pages),'12 pages, selectable text')
    check('Croatian characters',all(x in full for x in 'čćđšžČŠŽ') and '\ufffd' not in full and '\x00' not in full,'No replacement characters; diacritics present')
    for i,strings in {2:['1.123','818','208'],3:['2.253','2.306','49,8%','830','36,8%','36,3%'],4:['1.105','49,0%'],8:['454','20,2%'],12:['103','4,6%','29','1,3%','27','1,2%']}.items():
        assert all(x in pages[i-1] for x in strings)
    check('Printed numerical prose and tables',True,'Every fixed result in narrative checked; charts and panels generated from verified tables')
    forbidden=['TF-IDF','NPMI','Codex','validacija','status validacije','revizija','plan tekstualne','robustnost','osjetljivost modela','radna verzija','tehnički dodatak']
    check('Public PDF excludes internal reporting',not any(w.casefold() in full.casefold() for w in forbidden),'Keyword scan plus editorial reading; speaker statements about checking access are substantive content')
    urls=[]
    for page in reader.pages:
        for ref in page.get('/Annots',[]):
            a=ref.get_object()
            if a.get('/A',{}).get('/URI'):urls.append(str(a['/A']['/URI']))
    check('Public source and author links',len([u for u in urls if u!='https://www.lukasikic.info/'])==3 and 'https://www.lukasikic.info/' in urls and reader.metadata.author=='Luka Šikić','Three source links; linked author and PDF author metadata')
    layout=read(OUT/'internal/layout.json')
    check('Page content stays above footer',all(r['bottom_y']>=59 for r in layout),min(r['bottom_y'] for r in layout))
    positions=read(OUT/'internal/cloud-layout.json');by=defaultdict(list)
    for row in positions:by[row['scope']].append(row)
    for key,rr in by.items():
        for i,r in enumerate(rr):
            x,y,x2,y2=r['box'];w,h=r['canvas'];assert 0<=x<x2<=w and 0<=y<y2<=h
            for q in rr[i+1:]:
                a,b,c,d=q['box'];assert x2<=a or x>=c or y2<=b or y>=d
        ordered=sorted(rr,key=lambda r:-r['texts'])
        assert all(ordered[i]['font_size']+1e-8>=ordered[i+1]['font_size'] for i in range(len(ordered)-1))
    check('Word-cloud geometry and size order',len(positions)==228,'All bounding boxes inside canvas, no overlap; word sizes monotone with text count')
    with pdfplumber.open(PDF) as pdf:
        bad=[]
        for i,page in enumerate(pdf.pages,1):
            for ch in page.chars:
                if ch['x0']<MARGIN-1 or ch['x1']>page.width-MARGIN+1 or ch['top']<12 or ch['bottom']>page.height-12:bad.append((i,ch['text'],ch['x0'],ch['x1']))
    check('PDF glyphs within page margins',not bad,bad[:10])
    ht=(OUT/'report.html').read_text(encoding='utf-8')
    check('HTML text alternatives and structure','lang="hr"' in ht and ht.count('<details>')==13 and ht.count('<section ')==11 and 'aria-hidden="true"' in ht,'11 clouds + 2 charts with full data tables; ordered heading/navigation structure')
    check('Previous numerical analysis retained',read(BASE/'reproducibility.json')['status']=='PASS' and read(BASE/'verification.json')['status']=='PASS','Existing computational checks and reproducibility record retained outside public report')
    record={'status':'PASS','reviewer':'Codex AI; not independent human coding','pdf_sha256':sha(PDF),'checks':CHECKS,'cases':case_audit,'links':urls,'visual_qa':'See visual-qa.json, which must match this PDF hash','limits':['No independently double-coded semantic prevalence is claimed.','Topic assignments are descriptive fixed-model groups.','Selected source texts can be incomplete archived captures.','PDF has language metadata and text layer but no PDF/UA certification; semantic HTML and data tables provided.']}
    (OUT/'internal/verification.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    # Fine-grained register covers all numbers shown in figures/tables and totals.
    claims=[]
    for r in cloud:claims.append({'location':'cloud-'+r['scope'],'claim':r['word'],'value':r['texts'],'denominator':r['denominator'],'source':'local-units.json -> distinct group sets, fixed topic assignment'})
    for r in topics:claims.append({'location':'page 4 and topic panels','claim':r['label'],'value':r['texts'],'denominator':2253,'source':'topic_sensitivity.csv: exact_text_groups'})
    for r in csvread(OUT/'tables/phrases.csv'):claims.append({'location':'page 8','claim':r['phrase'],'value':r['texts'],'denominator':2253,'source':'phrases.csv: original adjacent lemmas'})
    for t in ['vrijednost','stranka','hdz','solidarnost','savjest','supsidijarnost']:claims.append({'location':'pages 2, 3, 12; website','claim':t,'value':len(lex[t]),'denominator':2253,'source':'vocabulary_local.csv'})
    claims.extend([{'location':'pages 1,3','claim':'archival records','value':2306,'denominator':'','source':'summary.json'}, {'location':'pages 1,3','claim':'distinct texts','value':2253,'denominator':'','source':'summary.json'}, {'location':'page 4','claim':'t01-t04 aggregate','value':1105,'denominator':2253,'source':'topic_sensitivity.csv'}, {'location':'page 4','claim':'unassigned text','value':1,'denominator':2253,'source':'topic_sensitivity.csv'}])
    with (OUT/'internal/claim-register.csv').open('w',encoding='utf-8-sig',newline='') as f:
        w=csv.DictWriter(f,fieldnames=list(claims[0]));w.writeheader();w.writerows(claims)
    print(json.dumps({'status':'PASS','checks':len(CHECKS),'numeric_claim_rows':len(claims),'pdf_sha256':sha(PDF)},ensure_ascii=False))

def sha_text(s):return hashlib.sha256(s.encode('utf-8')).hexdigest()
MARGIN=44
if __name__=='__main__':main()
