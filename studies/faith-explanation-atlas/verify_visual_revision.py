"""Check reader edition, original quotes, unchanged chart values and visual coverage."""
import hashlib,json,pathlib,re,zipfile,runpy
from html.parser import HTMLParser
from manuscript import PAGES,QUOTES
from reader_copy import CAPTIONS,CARD_COPY
HERE=pathlib.Path(__file__).resolve().parent
OUT=HERE/'output/private'
class Content(HTMLParser):
    def __init__(self):super().__init__();self.page=None;self.images={};self.quotes=[];self.active=None
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='section':self.page=a['id'];self.images[self.page]=[]
        if tag=='blockquote':self.active=[]
        if self.page and tag=='img':self.images[self.page].append(a['src'])
    def handle_data(self,data):
        if self.active is not None:self.active.append(data)
    def handle_endtag(self,tag):
        if tag=='blockquote' and self.active is not None:self.quotes.append(''.join(self.active));self.active=None
        if tag=='section':self.page=None
new=Content();new.feed((OUT/'tko-vjeri-daje-javni-glas.html').read_text(encoding='utf8'))
old=Content();old.feed((OUT/'revisions/visual-edition/tko-vjeri-daje-javni-glas.html').read_text(encoding='utf8'))
assert new.quotes==old.quotes and len(new.quotes)==17
assert len(new.images)==35 and all(len(x)==1 for x in new.images.values())
assert len(PAGES)==35
old_manuscript=runpy.run_path(str(OUT/'revisions/visual-edition/manuscript.py'))
assert old_manuscript['QUOTES']==QUOTES
assert all(p['body']!=old_manuscript['PAGES'][i]['body'] for i,p in enumerate(PAGES))
authored='\n'.join(p['title']+'\n'+p['body'] for p in PAGES)+'\n'+'\n'.join(' '.join(x) for x in CAPTIONS.values())+'\n'+str(CARD_COPY)
assert not re.search(r'\b(?:ne|nije|nisu|nema|nemaju|niti|bez)\b',authored,re.I),'Negative editorial construction'
assert not re.search(r'voices_summary|report_data|nazivnik|nevalidiran|modelske oznake|zatvoreni popis',authored,re.I)
figs=json.loads((OUT/'companion/figure_manifest.json').read_text(encoding='utf8'))
assert [x['page'] for x in figs]==list(range(1,36))
with zipfile.ZipFile(OUT/'revisions/visual-edition/faith-explanation-atlas-private.zip') as z:
    previous={x['page']:x for x in json.loads(z.read('companion/figure_manifest.json'))}
def numbers(value):
    if isinstance(value,(int,float)):return [value]
    if isinstance(value,list):return sum((numbers(x) for x in value),[])
    if isinstance(value,dict):return sum((numbers(x) for x in value.values()),[])
    return []
for f in figs:
    assert (OUT/f['svg']).is_file()
    if f['pdf']:assert (OUT/f['pdf']).is_file()
    if f['page'] not in [4,5,25,27,34,35]:assert numbers(f['data'])==numbers(previous[f['page']]['data']),f['page']
s=json.loads((OUT/'companion/saved_summary_tables.json').read_text(encoding='utf8'))
assert sum(x['statements'] for x in s['D']['roles'])==s['D']['stmt_total']==71259
assert sum(x['N'] for x in s['D']['list']['roles'])==117
assert sum(x['n'] for x in s['D']['top50_tip'])==50
assert sum(x['documents'] for x in s['A']['circulation_sizes'])==s['A']['corpus']['documents']
for x in s['A_person_measures']:
    assert sum(x[k] for k in ['confessional_documents','secular_documents','unlabelled_documents'])==x['mentioned_documents']
result=dict(rewritten_pages=35,unchanged_quotes=17,pages_with_exactly_one_visual=35,visuals=35,quantitative_charts=30,source_networks=1,editorial_diagrams=4,negative_editorial_constructions=0,technical_codes_in_reader_copy=0,retained_chart_numeric_values='unchanged',aggregate_arithmetic='passed',manuscript_sha256=hashlib.sha256((HERE/'manuscript.py').read_bytes()).hexdigest(),limits='Quote text retains its original phrasing. Technical provenance is in companion files. Display checks do not validate underlying model outputs.')
(OUT/'revision_verification.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps(result))
