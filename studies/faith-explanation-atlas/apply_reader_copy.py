"""Apply the approved plain-language direction to manuscript and chart labels."""
from pathlib import Path
import pprint,re
from manuscript import PAGES,QUOTES
from reader_copy import PAGES_COPY
HERE=Path(__file__).resolve().parent
for n,p in enumerate(PAGES,1):
    p['title'],p['body']=PAGES_COPY[n]
    if 6<=n<=13:p['section']='PORTRETI · PAPE I BISKUPI'
    if 14<=n<=19:p['section']='PORTRETI · SVEĆENICI I DRUGI JAVNI GLASOVI'
    if n in [4,5]:p['section']='JAVNI PROSTOR'
    if n==35:p['section']='ZAVRŠNI POGLED'
PAGES[3]['refs']='D · report_data.json / list.roles; original voices.csv roster: 117 persons.'
PAGES[4]['refs']='A · report_data.json / values.platforms and values.corpus; 611583 documents.'
PAGES[24]['refs']='B · Q500, Q2370, complete saved articles. Editorial explanation diagram; no frequency claim.'
PAGES[26]['refs']='B · Q636, Q2449, Q1591, Q2742. Editorial genre examples; Q2742 is a priest’s reported recollection of an off-camera conversation.'
PAGES[34]['refs']='D · roles and sample.believers; C · source_1_n. Conclusions restricted to the displayed groups and frames.'
content='"""Reader manuscript. Source locators are retained for the companion index."""\nPAGES = '+pprint.pformat(PAGES,width=115,sort_dicts=False)+'\n\nQUOTES = '+pprint.pformat(QUOTES,width=115,sort_dicts=False)+'\n'
(HERE/'manuscript.py').write_text(content,encoding='utf8')
f=HERE/'atlas_figures.py';s=f.read_text(encoding='utf8')
lines=s.splitlines()
for i,line in enumerate(lines):
    if line.startswith('    cards(4,'):
        lines[i]="    roster_roles=sorted(d['list']['roles'],key=lambda x:x['N'],reverse=True)\n    bars(4,*CAPTIONS[4][:2],[ROLE[x['role']] for x in roster_roles],[x['N'] for x in roster_roles],'D · report_data.json / list.roles',xlabel='Broj osoba')"
    if line.startswith('    cards(5,'):
        lines[i]="    platforms=sorted(a['values']['platforms'],key=lambda x:x['documents'],reverse=True)\n    bars(5,*CAPTIONS[5][:2],[x['platform'] for x in platforms],[x['documents'] for x in platforms],'A · values.platforms / documents',xlabel='Broj prikupljenih objava')"
    if line.startswith('    panels='):
        lines[i]="    panels=[('Biskupi i pape',87,'svih zabilježenih izjava'),('Ostali mediji',d['bishop_other_share'],'biskupskih izjava izvan\\nkatoličkih izvora'),('Anonimni kanali',48,'24 od 50 katoličkih kanala'),('Vjernici govore',2,'3 od 150 katoličkih objava')]"
    if line.startswith("    e=dict(page=31"):
        lines[i]="    e=dict(page=31,title=CAPTIONS[31][0],subtitle=CAPTIONS[31][1],source=CAPTIONS[31][2],technical_source='A · figures/network_outlets.svg; unchanged original network',kind='unchanged source network',data=None,svg='companion/network_outlets.svg',pdf=None);manifest.append(e);figures[31]=e"
s='\n'.join(lines)+'\n'
for old,new in [
    ("'Konfesionalni'","'Vjerski mediji'"),("'Sekularni'","'Sekularni mediji'"),("'Neoznačeni'","'Otvorena oznaka'"),
    ("'Dokumenti sa spomenom'","'Objave s imenom osobe'"),("'Udio dokumenata (%)'","'Udio objava (%)'"),
    ("'Broj dokumenata / obitelji'","'Broj objava / skupina'"),("'Broj obitelji / dokumenata'","'Broj skupina / objava'"),
    ("'Dokumenti u okviru C'","'Broj objava'"),
    ("x['size_group']+' dok.'","x['size_group']+' obj.'"),
    ("['Dokumenti','Obitelji sličnih tekstova']","['Sve objave','Skupine sličnih tekstova']"),
    ("['Obitelji','Dokumenti']","['Skupine sličnih tekstova','Sve objave']"),
    ("'Katolička skupina'","'Katolički izvori'"),
    ("'Svih pet vidioca\\nsa zatvorenog popisa'","'Pet praćenih\\nvidioca'"),
    ("'Katolički: 95 tumačećih objava'","'Katolički izvori · 95 objava'"),("'Ostali: 96 tumačećih objava'","'Ostali izvori · 96 objava'"),
    ("'Osobe na popisu (117)'","'Praćene osobe (117)'"),("'Izjave u sažetku (71 259)'","'Zabilježene izjave (71 259)'"),
    ("'Romana Guardinija' for", "'Romano Guardini' for"),
    ("[x['name'] for x in rr]","['Romano Guardini' if x['name']=='Romana Guardinija' else x['name'] for x in rr]"),
    ("[z.replace('-','\\n') for z in q]","[z[-1]+'. tr.\\n'+z[:4] for z in q]"),
    ("[x['current'] for x in adj]","[x['current'][:4]+' · '+x['current'][-1]+'.' for x in adj]"),
    ("'Kendallov τ'","'Sličnost redoslijeda'"),
    ("'2025-Q1 → Q2\\nτ = 0,10'","'Proljeće 2025.\\n0,10'"),
]:s=s.replace(old,new)
f.write_text(s,encoding='utf8')
# Keep quote source/date readable while preserving full source metadata separately.
f=HERE/'build_report.py';s=f.read_text(encoding='utf8')
s=s.replace('qmeta[i]=f"Q{i} · {r[\'outlet_name\']} · {r[\'published_at\']}"','qmeta[i]=f"{r[\'outlet_name\']} · {r[\'published_at\']}"')
s=s.replace("split=[['Osoba','Konfesionalni','Sekularni','Neoznačeni']]","split=[['Osoba','Vjerski mediji','Sekularni mediji','Otvorena oznaka']]")
f.write_text(s,encoding='utf8')
print('Rewrote 35 pages and simplified reader-facing labels; quotations preserved.')
