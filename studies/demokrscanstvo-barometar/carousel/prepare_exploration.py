"""Read frozen records and publish aggregate evidence for slides 10–15.

No corpus mutation, classification changes, raw article export or inferred stance.
Run separately from build.py; the carousel itself reads only the public aggregate.
"""
from pathlib import Path
from collections import Counter, defaultdict
import argparse
import csv
import hashlib
import json
import os
import re
import unicodedata

ROOT = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--workdir', type=Path, default=Path(os.environ.get(
    'DIGIKAT_BAROMETAR_WORKDIR', 'C:/Users/lsikic/Luka C/DigiKat_barometar_work')))
args = parser.parse_args()
paths = [args.workdir/'analytical-report-v1/grouped-documents.json',
         args.workdir/'text-addendum-v1/sources.json']
docs = json.loads(paths[0].read_text(encoding='utf-8-sig'))
sources = {r['record_key']:r['source_name'] for r in json.loads(paths[1].read_text(encoding='utf-8-sig'))}
assert len(docs) == len({d['record_key'] for d in docs}) == len(sources) == 2306
assert len({d['group'] for d in docs}) == 2253
web = [d for d in docs if d['platform'] == 'web']
assert len(web) == 1811 and all(sources[d['record_key']] for d in web)

readcsv = lambda p: list(csv.DictReader(p.open(encoding='utf-8-sig')))
public_months = ROOT/'data/barometar/demokrscanstvo-multiplatform/v1/monthly.csv'
public_topics = ROOT/'data/barometar/demokrscanstvo-themes/v1/topic_monthly.csv'
topic_labels = ROOT/'data/barometar/demokrscanstvo-themes/v1/topics.csv'
labels = {r['topic']:r['label'] for r in readcsv(topic_labels)}
monthly = Counter(d['month'] for d in web)
topic_monthly = Counter((d['month'],d['topic']) for d in web)
public_web = [r for r in readcsv(public_months) if r['platform']=='web']
assert sum(int(r['matching_records']) for r in public_web) == len(web)
assert all(int(r['eligible_records']) > 0 for r in public_web), 'No-coverage months must be gaps, not measured zeros.'
assert all(monthly[r['month']] == int(r['matching_records']) for r in public_web)
expected_topics = {(r['month'],r['topic']):int(r['records']) for r in readcsv(public_topics) if r['platform']=='web'}
assert +Counter(expected_topics) == +topic_monthly

def normalize(text):
    return ' '.join(''.join(c for c in unicodedata.normalize('NFKD',text.casefold())
                           if not unicodedata.combining(c)).replace('đ','d').split())

# Six explicitly selected public figures, not an exhaustive named-entity ranking.
# Full given name + family name prevents ambiguous surname-only assignments.
people = [
    ('Andrej Plenković', r'\bandrej[a-z]*\s+plenkovic[a-z]*\b'),
    ('Franjo Tuđman', r'\bfranj[a-z]*\s+tudman[a-z]*\b'),
    ('Miroslav Škoro', r'\bmiroslav[a-z]*\s+skor[a-z]*\b'),
    ('Ivan Penava', r'\bivan[a-z]*\s+penav[a-z]*\b'),
    ('Zoran Milanović', r'\bzoran[a-z]*\s+milanovic[a-z]*\b'),
    ('Davor Ivo Stier', r'\bdavor[a-z]*\s+(?:ivo[a-z]*\s+)?stier[a-z]*\b'),
]
texts = {d['record_key']:normalize(d['title']+' '+d['body']) for d in web}
actor_rows, audit = [], []
for name, pattern in people:
    matched = [d for d in web if re.search(pattern,texts[d['record_key']])]
    actor_rows.append(dict(name=name, articles=len(matched), denominator=len(web), pattern=pattern))
    forms = Counter(m for d in matched for m in set(re.findall(pattern,texts[d['record_key']])))
    audit.append(dict(name=name,articles=len(matched),forms=dict(forms),
                      example_titles=[d['title'] for d in matched[:8]]))
actor_rows.sort(key=lambda r:(-r['articles'],r['name']))

outlet_counts = Counter(sources[d['record_key']] for d in web)
ranked_outlets = sorted(outlet_counts.items(),key=lambda x:(-x[1],x[0]))
peaks = []
for month,n in sorted(monthly.items(),key=lambda x:(-x[1],x[0]))[:4]:
    subset = [d for d in web if d['month']==month]
    counts = Counter(d['topic'] for d in subset)
    peaks.append(dict(month=month,articles=n,sources=len({sources[d['record_key']] for d in subset}),
                      distinct_texts=len({d['group'] for d in subset}),
                      topics=[dict(topic=t,label=labels[t],articles=k) for t,k in counts.most_common()]))
day_counts = Counter(d['day'] for d in web)
day,n = sorted(day_counts.items(),key=lambda x:(-x[1],x[0]))[0]
subset = [d for d in web if d['day']==day]
result = dict(
    title='Podaci uz karusel o demokršćanstvu u medijima',
    scope=dict(included_publications=len(docs),web_articles=len(web),
               distinct_web_texts=len({d['group'] for d in web}),web_sources=len(outlet_counts),
               full_text_articles=sum(d['text_basis']=='full_text' for d in web),
               snippet_articles=sum(d['text_basis']=='snippet' for d in web),
               data_from='2021-01-01',data_through='2026-09-10',collection_break='2024-04-01'),
    methods=dict(
        unit='Jedna uključena web objava. Jednaki tekstovi na različitim izvorima ostaju zasebne objave.',
        people='Odabrane javne osobe, ne iscrpan popis. Puno ime i prezime u naslovu ili dostupnom tekstu, uz padežne oblike. Članak se po osobi broji jednom. Spominjanje ne označava potporu demokršćanstvu. Moguć je propust kada je navedeno samo prezime.',
        sources='Izvor prema pohranjenoj oznaci; broj članaka, ne procjena publike ili utjecaja.',
        time='Broj uključenih članaka po arhivskom datumu. Promjena obuhvata u travnju 2024. i nepotpuna 2026. ograničavaju usporedbe razdoblja.',
        topics='Preuzete postojeće tematske oznake. Svaki članak ima jednu glavnu temu.'),
    people=actor_rows,
    sources=[dict(source=s,articles=n) for s,n in ranked_outlets[:8]],
    monthly=[dict(month=r['month'],articles=int(r['matching_records'])) for r in sorted(public_web,key=lambda r:r['month'])],
    peak_months=peaks,
    peak_day=dict(day=day,articles=n,sources=len({sources[d['record_key']] for d in subset}),
                  distinct_texts=len({d['group'] for d in subset}),
                  topics=[dict(topic=t,label=labels[t],articles=k) for t,k in Counter(d['topic'] for d in subset).most_common()]),
    provenance=dict(private_inputs={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},
                    public_inputs={str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest()
                                   for p in [public_months,public_topics,topic_labels]},
                    monthly_and_topic_counts_reconciled=True))
# Keep title-level matching inspection local. The publication contains aggregates only.
qa = ROOT/'output/demokrscanstvo-carousel'
qa.mkdir(parents=True,exist_ok=True)
(qa/'person-matching-audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf-8')
target = ROOT/'assets/izvjestaji/demokrscanske-vrijednosti-karusel-podaci.json'
target.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps(dict(articles=len(web),people=actor_rows,peak_day=result['peak_day'],output=str(target)),ensure_ascii=False))
