"""Cache public Wikidata snapshots independently of the corpus database/GPU.

Broad discovery deliberately retains all dated offices for citizens of HR/BiH;
downstream selection must inspect office/occupation facts, not assume clergy.
Missing dates remain missing, never fabricated from current office holders.
"""
import hashlib,json,time
import requests
from voices_common import workdir,atomic_json,utc,CORPUS_HASH,CONFIG_HASH,file_sha

API='https://www.wikidata.org/w/api.php'
SPARQL='https://query.wikidata.org/sparql'
HEADERS={'User-Agent':'DigiKatResearch/1.0 (Croatian academic media study; public office register)',
         'Accept':'application/json'}
SEARCHES=['pope','Croatian Bishops Conference','Bishops Conference of Bosnia and Herzegovina',
          'President of Croatia','Prime Minister of Croatia','apostolic nuncio to Croatia',
          'apostolic nuncio to Bosnia and Herzegovina']
PREFIX='''PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>
PREFIX p: <http://www.wikidata.org/prop/>
PREFIX ps: <http://www.wikidata.org/prop/statement/>
PREFIX pq: <http://www.wikidata.org/prop/qualifier/>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
'''

def cached(kind,key,url,params):
    folder=workdir()/'public_register_cache';folder.mkdir(exist_ok=True)
    request=dict(url=url,params=params)
    digest=hashlib.sha256(json.dumps(request,sort_keys=True).encode()).hexdigest()
    path=folder/(kind+'_'+key+'_'+digest[:16]+'.json')
    if path.exists():return json.loads(path.read_text(encoding='utf-8'))['response']
    for attempt in range(5):
        try:
            time.sleep(2)
            r=requests.get(url,params=params,headers=HEADERS,timeout=(15,90))
            if r.status_code==429:
                delay=max(15*(attempt+1),float(r.headers.get('Retry-After','30')))
                print(utc(),kind,key,'rate limited; waiting',delay,'seconds',flush=True)
                while delay>0:
                    pause=min(delay,30);time.sleep(pause);delay-=pause
            r.raise_for_status()
            response=r.json()
            if 'error' in response:raise RuntimeError(str(response['error']))
            atomic_json(path,dict(retrieved_utc=utc(),request=request,response=response))
            return response
        except (requests.RequestException,ValueError,RuntimeError):
            if attempt==4:raise
            time.sleep(2**attempt)

def query(where):
    return PREFIX+'''SELECT DISTINCT ?person ?office ?start ?end ?place ?rank WHERE {
    '''+where+'''
    ?person p:P39 ?statement. ?statement ps:P39 ?office.
    OPTIONAL { ?statement pq:P580 ?start. }
    OPTIONAL { ?statement pq:P582 ?end. }
    OPTIONAL { ?statement pq:P708 ?place. }
    OPTIONAL { ?statement <http://wikiba.se/ontology#rank> ?rank. }
    FILTER(!BOUND(?start) || ?start <= "2026-12-31T23:59:59Z"^^xsd:dateTime)
    FILTER(!BOUND(?end) || ?end >= "2021-01-01T00:00:00Z"^^xsd:dateTime)
    }'''

def main():
    folder=workdir()/'public_register_cache';folder.mkdir(exist_ok=True)
    discovery=[];errors=[];queries=[];all_qids={'Q224','Q225'}
    for name in SEARCHES:
        try:
            found=cached('search',hashlib.sha256(name.encode()).hexdigest()[:10],API,
                         dict(action='wbsearchentities',search=name,language='en',format='json',limit=5))
            discovery.append(dict(search=name,results=found.get('search',[])))
            # Exact label/alias matching only; search ranking alone is not a match.
            ids=[r['id'] for r in found.get('search',[]) if
                 r.get('label','').casefold()==name.casefold() or
                 r.get('match',{}).get('text','').casefold()==name.casefold()]
            all_qids.update(ids)
            for qid in ids:
                queries.append(('office_'+qid,query('VALUES ?office { wd:'+qid+' }')))
                queries.append(('organization_'+qid,query('?office wdt:P361* wd:'+qid+'.')))
        except Exception as e:errors.append(dict(stage='search',key=name,error=str(e)))
    for country in ['Q224','Q225']:
        queries.extend([
          ('citizens_'+country,query('?person wdt:P27 wd:'+country+'.')),
          ('jurisdiction_'+country,query('?office wdt:P1001 wd:'+country+'.')),
          ('diocese_'+country,query('?statement pq:P708 ?diocese. ?diocese wdt:P17 wd:'+country+'.')),
          ('office_diocese_'+country,query('?office wdt:P2389 ?diocese. ?diocese wdt:P17 wd:'+country+'.'))])
    snapshots=[]
    for key,sparql in dict(queries).items():
        try:
            response=cached('sparql',key,SPARQL,dict(query=sparql,format='json'))
            rows=response['results']['bindings'];snapshots.append(dict(key=key,rows=len(rows)))
            for row in rows:
                for col in ['person','office','place']:
                    qid=row.get(col,{}).get('value','').rsplit('/',1)[-1]
                    if qid.startswith('Q') and qid[1:].isdigit():all_qids.add(qid)
            print(utc(),key,len(rows),'public office statements cached',flush=True)
        except Exception as e:errors.append(dict(stage='sparql',key=key,error=str(e)))
        atomic_json(folder/'progress.json',dict(created_utc=utc(),queries=snapshots,errors=errors))
    qids=sorted(all_qids)
    for offset in range(0,len(qids),50):
        batch=qids[offset:offset+50]
        try:cached('entities',str(offset),API,dict(action='wbgetentities',ids='|'.join(batch),
             props='labels|aliases|descriptions|claims',languages='hr|en|bs',format='json'))
        except Exception as e:errors.append(dict(stage='entities',key=batch,error=str(e)))
    manifest=dict(created_utc=utc(),code_sha256=file_sha(__file__),
      corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,queries=snapshots,entities_requested=len(qids),
      discovery=discovery,errors=errors,complete=not errors,
      coverage='Discovery snapshot, not a complete office register; missing dates and jurisdictions need explicit audit.')
    old_path=folder/'manifest.json'
    if old_path.exists():
        old_manifest=json.loads(old_path.read_text(encoding='utf-8'))
        if {k:v for k,v in old_manifest.items() if k!='created_utc'}=={k:v for k,v in manifest.items() if k!='created_utc'}:
            manifest['created_utc']=old_manifest['created_utc']
    atomic_json(old_path,manifest)
    if errors:raise SystemExit('Public register retrieval incomplete; saved successes retained. Rerun to retry.')

if __name__=='__main__':main()
