"""Build a private, self-contained research visual from validated workbook data."""
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent
PRIVATE=HERE/'output/private/extended'
d=json.loads((PRIVATE/'workbook_data.json').read_text(encoding='utf-8'))
overall=[r for r in d['overall'] if r['scope']=='selected']
annual=[r for r in d['annual'] if r['scope']=='selected']
ids={r['source_id']:i for i,r in enumerate(overall)}
fields=['posts','interaction_n','total_interactions','mean_interactions','median_interactions',
        'months_observed','first_observed','last_observed','platform_rank','platform_share']
def vals(r,annual=False):
    return [r.get(('platform_year_rank' if f=='platform_rank' else 'platform_year_share') if annual and f in ('platform_rank','platform_share') else f) for f in fields]
payload=dict(
 input=d['input'],
 sources=[[r['source_id'],r['source'],r['platform'],r['actor_group'],r['classification_rule'],r['classification_confidence'],*vals(r)] for r in overall],
 annual=[[ids[r['source_id']],r['year'],*vals(r,True)] for r in annual],
 coverage=[r for r in d['coverage'] if r['scope']=='selected'],
 seasonal=[r for r in d['seasonal'] if r['scope']=='selected'],
 selected_posts=sum(r['posts'] for r in overall),all_posts=601036)
template=(HERE/'research_visual.html.in').read_text(encoding='utf-8')
encoded=json.dumps(payload,ensure_ascii=False,separators=(',',':')).replace('</','<\\/')
result=template.replace('<!--RESEARCH_DATA-->', '<script type="application/json" id="research-data">'+encoded+'</script>')
assert len(result.encode('utf-8'))<1_000_000
assert '<html' not in result.lower() and '<!doctype' not in result.lower()
target=PRIVATE/'akteri-vjera-istrazivanje.html'
target.write_text(result,encoding='utf-8')
print(f'{target}: {len(result.encode("utf-8"))} bytes; {len(overall)} sources; {len(annual)} annual rows')
