"""Rule-based official-directory coverage audit and dated-event discovery.

Only public bishop biographies are fetched. Observed appointment/consecration/
possession dates are kept distinct; none silently replaces a tenure boundary.
The frozen Wikidata snapshot is never overwritten by a current directory.
"""
import collections,hashlib,json,re,time
from html.parser import HTMLParser
from urllib.parse import urljoin,urlsplit
import requests
from voices_common import *
from office_register import read_cache
from dated_office_rules import holder,MAX_TENURE_YEARS
from office_titles import vocabulary
from wikidata_identity import norm

DIRECTORIES=['https://hbk.hr/biskupi/','https://www.bkbih.ba/info.php?id=2']
PREFIX=re.compile(r'^(?:(?:mons|dr|mr|sc)\.\s*|kardinal\s*)+',re.I)
MONTHS='siječnja|veljače|ožujka|travnja|svibnja|lipnja|srpnja|kolovoza|rujna|listopada|studenoga|prosinca'
DATE=re.compile(r'\b\d{1,2}\.\s*(?:(?:'+MONTHS+r')\s+|\d{1,2}\.\s*)\d{4}\.?',re.I)
EVENTS={'appointment':r'imenovan\w*','possession':r'preuze\w*|ustolič\w*|naslijed\w*',
        'ordination':r'zaređen\w*|ređenj\w*|posvećen\w*','retirement':r'umirov\w*|razriješ\w*|odreknu\w*'}

class Page(HTMLParser):
    def __init__(self):super().__init__();self.links=[];self.parts=[];self.anchor=None;self.skip=0
    def handle_starttag(self,tag,attrs):
        if tag in {'script','style','noscript'}:self.skip+=1
        if tag=='a' and not self.skip:self.anchor=[dict(attrs).get('href',''),[]]
    def handle_endtag(self,tag):
        if tag in {'script','style','noscript'}:self.skip=max(0,self.skip-1)
        if tag=='a' and self.anchor:
            self.links.append((self.anchor[0],re.sub(r'\s+',' ',' '.join(self.anchor[1])).strip()));self.anchor=None
    def handle_data(self,data):
        if self.skip:return
        self.parts.append(data)
        if self.anchor:self.anchor[1].append(data)
    @property
    def text(self):return re.sub(r'\s+',' ',' '.join(self.parts)).strip()

def directory_entries(html,base):
    page=Page();page.feed(html);out={}
    for url,title in page.links:
        if not re.match(r'^(?:mons\.|kardinal\b)',title,re.I) or ',' not in title:continue
        name,role=title.split(',',1);name=PREFIX.sub('',name).strip();role=role.strip()
        url=urljoin(base,url)
        if urlsplit(url).hostname not in {'hbk.hr','www.hbk.hr','bkbih.ba','www.bkbih.ba'}:continue
        if 2<=len(name.split())<=5 and re.search(r'biskup|ordinarij|vizitator',role,re.I):
            out[url]=dict(name=name,role=role,url=url,directory=base,retired='u miru' in role)
    return list(out.values())

def dated_events(text):
    result=[]
    for match in DATE.finditer(text):
        context=text[max(0,match.start()-180):min(len(text),match.end()+180)]
        kinds=[key for key,pattern in EVENTS.items() if re.search(pattern,context,re.I)]
        if kinds:result.append(dict(date_text=match.group(),start=match.start(),end=match.end(),
          nearby_event_types=kinds,context=context,tenure_boundary_accepted=False))
    return result

def fetch(url):
    folder=workdir()/'official_office_cache';folder.mkdir(exist_ok=True)
    path=folder/(hashlib.sha256(url.encode()).hexdigest()+'.json')
    if path.exists():return json.loads(path.read_text(encoding='utf-8'))
    time.sleep(.5)
    r=requests.get(url,headers={'User-Agent':'DigiKatResearch/1.0 (public office register)'},timeout=(15,60));r.raise_for_status()
    r.encoding='utf-8';page=Page();page.feed(r.text)
    data=dict(url=url,final_url=r.url,retrieved_utc=utc(),html=r.text,text=page.text)
    atomic_json(path,data);return data

def main():
    register=json.loads((workdir()/'office_register.json').read_text(encoding='utf-8'))
    entities,_,_=read_cache(workdir()/'public_register_cache');pattern,mapping=vocabulary(register,entities)
    index=collections.defaultdict(set)
    for person in register['people']:
        names=list(person['labels'].values())+[v for a in person['aliases'].values() for v in a]
        for name in names:index[norm(name)].add(person['qid'])
    rows=[];errors=[]
    for url in DIRECTORIES:
        page=fetch(url);entries=directory_entries(page['html'],url)
        if not entries:raise RuntimeError('Official directory extraction returned no people: '+url)
        for row in entries:
            qids=sorted(index.get(norm(row['name']),set()));row['qid_matches']=qids
            matches=list(pattern.finditer(row['role']));office_ids=sorted({q for m in matches for q in mapping[m.lastgroup]['offices']})
            row['recognized_offices']=office_ids
            row['unique_holder_matches_at_corpus_end']=bool(len(qids)==1 and any(holder(register['offices'],q,'2026-10-16')==qids[0] for q in office_ids))
            try:
                profile=fetch(row['url']);row['dated_event_candidates']=dated_events(profile['text'])
                row['profile_retrieved_utc']=profile['retrieved_utc']
            except requests.RequestException as exc:
                row['dated_event_candidates']=[];errors.append(dict(url=row['url'],error=str(exc)))
            rows.append(row)
    active=[r for r in rows if not r['retired']]
    report=dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      register_sha256=file_sha(workdir()/'office_register.json'),directories=DIRECTORIES,
      directory_entries=len(rows),active_directory_entries=len(active),
      active_exact_unique_person_matches=sum(len(r['qid_matches'])==1 for r in active),
      active_current_title_dated_matches=sum(r['unique_holder_matches_at_corpus_end'] for r in active),
      profiles_with_date_candidates=sum(bool(r['dated_event_candidates']) for r in rows),
      maximum_tenure_years=MAX_TENURE_YEARS,
      errors=errors,entries=rows,
      note='Current official-directory coverage diagnostic, not validation of 2021–2026 history. Directory roles cannot be backdated. Biographical dates are candidates only: appointment, ordination and possession are not interchangeable. No inferred tenure was merged into the frozen register.')
    atomic_json(workdir()/'office_directory_audit_v2.json',report)
    print(json.dumps({k:v for k,v in report.items() if k not in {'entries'}}),flush=True)

if __name__=='__main__':main()
