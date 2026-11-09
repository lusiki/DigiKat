"""Collect provenance-bearing official pages and join DZS population denominators."""
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
from html.parser import HTMLParser
import json
import re
from urllib.request import Request, urlopen
from urllib.parse import urlsplit
from common import PRIVATE, TABLES, read_csv, write_csv, dump_json, sha

SOURCES = [
 ('zdenac','https://zdenac.org/o-nama'),
 ('breza','https://breza.hr/o-nama/'),
 ('padmasana','https://padmasana.hr/en/o-nama/'),
 ('yoga','https://www.yoga-in-daily-life.hr/o-nama'),
 ('yoga_centres','https://www.yoga-in-daily-life.hr/centri'),
 ('skac_palma','https://www.skac.hr/upoznaj-skac/'),
 ('korablja','https://korablja-arka.hr/tko-smo/'),
 ('krakr','https://www.krakr.hr/index.php/o-nama/sto-je-krscanski-akademski-krug.html'),
 ('matica_samobor','https://www.matica.hr/ogranci/ogranak-matice-hrvatske-u-samoboru/'),
 ('matica_hvar','https://www.matica.hr/ogranci/ogranak-matice-hrvatske-u-hvaru/'),
 ('skac_split_attempt','https://skac.st/o-nama/'),
 ('dzs_population_2025','https://podaci.dzs.hr/2026/hr/121477'),
]

class Tables(HTMLParser):
    def __init__(self):
        super().__init__(); self.tables=[]; self.table=None; self.row=None; self.cell=None
    def handle_starttag(self,tag,attrs):
        if tag=='table': self.table=[]
        elif tag=='tr' and self.table is not None: self.row=[]
        elif tag in ('td','th') and self.row is not None: self.cell=[]
    def handle_data(self,data):
        if self.cell is not None: self.cell.append(data)
    def handle_endtag(self,tag):
        if tag in ('td','th') and self.cell is not None:
            self.row.append(' '.join(' '.join(self.cell).split())); self.cell=None
        elif tag=='tr' and self.row is not None:
            self.table.append(self.row); self.row=None
        elif tag=='table' and self.table is not None:
            self.tables.append(self.table); self.table=None

def collect(entry):
    key,url=entry; folder=PRIVATE/'source/web'; folder.mkdir(exist_ok=True)
    path=folder/(key+'.html')
    result={'source_key':key,'url':url,'retrieved_utc':datetime.now(timezone.utc).isoformat()}
    try:
        if not path.exists():
            request=Request(url,headers={'User-Agent':'DigiKatResearch/0.1 (public organisation profile research)'})
            with urlopen(request,timeout=35) as response:
                raw=response.read(3_000_000)
                result.update(http_status=response.status,final_url=response.url)
            path.write_bytes(raw)
        else:
            raw=path.read_bytes(); result['http_status']='cached'
            result['cache_read_utc']=result['retrieved_utc']
            result['retrieved_utc']=datetime.fromtimestamp(path.stat().st_mtime,timezone.utc).isoformat()
        decoded=raw.decode('utf-8',errors='replace')
        blocked=any(x in decoded.lower() for x in ('please wait while your request is being verified','verify you are human','cf-chl-'))
        result.update(status='access_challenge' if blocked else 'downloaded',bytes=len(raw),sha256=sha(path))
    except Exception as error:
        result.update(status='fetch_failed',error=str(error))
    return result

def main():
    records=list(ThreadPoolExecutor(max_workers=4).map(collect,SOURCES))
    write_csv(PRIVATE/'web_collection_log.csv',records,sorted({k for r in records for k in r}))
    path=PRIVATE/'source/web/dzs_population_2025.html'
    if not path.exists(): path=PRIVATE/'source/dzs_population_2025.html'
    parser=Tables(); parser.feed(path.read_text(encoding='utf-8'))
    table=next(t for t in parser.tables if any('Županija' in ' '.join(r) and '2025.' in ' '.join(r) for r in t))
    pop={}
    for cells in table:
        if len(cells)>=6 and re.fullmatch(r'[\d\s]+',cells[-1]):
            pop[cells[0].strip()]=int(re.sub(r'\s','',cells[-1]))
    counties=read_csv(TABLES/'county_inventory.csv')
    assert set(r['county'] for r in counties)==set(pop)-{'Republika Hrvatska'},(list(pop),counties)
    assert sum(v for k,v in pop.items() if k!='Republika Hrvatska')==pop['Republika Hrvatska']
    for row in counties:
        n=int(row['associations']); population=pop[row['county']]
        row.update(population_mid2025=population,associations_per_100000=round(n/population*100000,4),
           population_share_pct=round(population/pop['Republika Hrvatska']*100,4),
           representation_ratio=round((n/1325)/(population/pop['Republika Hrvatska']),4))
    write_csv(TABLES/'county_population_adjusted.csv',counties)
    dump_json(TABLES/'enrichment_audit.json',{'population_source':'DZS STAN-2026-3-1 table 1',
         'population_reference':'mid-2025','population_publication':'2026-09-04','register_reference':'2026-09-11',
         'population_national':pop['Republika Hrvatska'],'population_counties':len(counties),
         'national_associations_per_100000':1325/pop['Republika Hrvatska']*100000,
         'source_html_sha256':sha(path),'web_pages_attempted':len(records)-1,
         'collection_status_counts':{s:sum(r['status']==s for r in records) for s in {r['status'] for r in records}}})
    print(json.dumps(records,ensure_ascii=False,indent=2))

if __name__=='__main__': main()
