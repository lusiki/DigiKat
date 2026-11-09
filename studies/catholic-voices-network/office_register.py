"""Normalize cached public facts without inventing tenure dates or identities."""
import datetime as dt,json,re
from pathlib import Path

def value(snak):return snak.get('datavalue',{}).get('value')
def label(entity):
    return next((entity.get('labels',{}).get(lang,{}).get('value') for lang in ['hr','bs','en']
                 if entity.get('labels',{}).get(lang,{}).get('value')),entity.get('id',''))
def claims(entity,prop):
    return [value(c.get('mainsnak',{})) for c in entity.get('claims',{}).get(prop,[])
            if c.get('rank')!='deprecated' and value(c.get('mainsnak',{})) is not None]
def date_bounds(v):
    if not isinstance(v,dict) or 'time' not in v:return None
    match=re.match(r'\+(\d{4})-(\d{2})-(\d{2})T',v['time'])
    if not match:return None
    y,m,d=map(int,match.groups());precision=v.get('precision',0)
    try:
        if precision>=11:return (dt.date(y,m,d).isoformat(),)*2
        if precision==10:
            import calendar
            return dt.date(y,m,1).isoformat(),dt.date(y,m,calendar.monthrange(y,m)[1]).isoformat()
        if precision==9:return dt.date(y,1,1).isoformat(),dt.date(y,12,31).isoformat()
    except ValueError:pass
    return None

def read_cache(folder):
    entities={};pairs=set();snapshots=[]
    for path in sorted(Path(folder).glob('*.json')):
        data=json.loads(path.read_text(encoding='utf-8'));response=data.get('response',{})
        entities.update({k:v for k,v in response.get('entities',{}).items() if 'missing' not in v})
        for row in response.get('results',{}).get('bindings',[]):
            pairs.add(tuple(row[k]['value'].rsplit('/',1)[-1] for k in ['person','office']))
        if response:snapshots.append(dict(file=path.name,retrieved_utc=data['retrieved_utc']))
    return entities,pairs,snapshots

def build(folder):
    entities,pairs,snapshots=read_cache(folder);rows=[];people={};missing=set();excluded=set()
    for person,office in sorted(pairs):
        if person not in entities or office not in entities:
            missing.update(q for q in [person,office] if q not in entities);continue
        ent=entities[person]
        if 'Q5' not in {v.get('id') for v in claims(ent,'P31') if isinstance(v,dict)}:
            excluded.add(person);continue
        people[person]=dict(qid=person,label=label(ent),
          labels={lang:x['value'] for lang,x in ent.get('labels',{}).items()},
          aliases={lang:[x['value'] for x in a] for lang,a in ent.get('aliases',{}).items()},
          descriptions={lang:x['value'] for lang,x in ent.get('descriptions',{}).items()},
          birth=[date_bounds(v) for v in claims(ent,'P569')],death=[date_bounds(v) for v in claims(ent,'P570')],
          occupation=[v['id'] for v in claims(ent,'P106') if isinstance(v,dict) and 'id' in v],
          canonization_status=[v.get('id') for v in claims(ent,'P411') if isinstance(v,dict)])
        for statement in ent.get('claims',{}).get('P39',[]):
            if statement.get('rank')=='deprecated' or value(statement.get('mainsnak',{}))!={'entity-type':'item','numeric-id':int(office[1:]),'id':office}:
                # Compare by QID below; entity values can omit numeric metadata.
                v=value(statement.get('mainsnak',{}))
                if statement.get('rank')=='deprecated' or not isinstance(v,dict) or v.get('id')!=office:continue
            qualifiers=statement.get('qualifiers',{})
            starts=[date_bounds(value(s)) for s in qualifiers.get('P580',[])];starts=[x for x in starts if x]
            ends=[date_bounds(value(s)) for s in qualifiers.get('P582',[])];ends=[x for x in ends if x]
            start=starts[0] if len(starts)==1 else None;end=ends[0] if len(ends)==1 else None
            if start and start[0]>'2026-12-31':continue
            if end and end[1]<'2021-01-01':continue
            places=[value(s).get('id') for s in qualifiers.get('P708',[]) if isinstance(value(s),dict)]
            death=[d for d in people[person]['death'] if d]
            # A death fact does not substitute for a known start. It can bound an open tenure.
            if not end and len(death)==1:end=death[0]
            if end and end[1]<'2021-01-01':continue
            rows.append(dict(statement_id=statement.get('id'),entity_qid=person,name=label(ent),
              office_qid=office,office_label_hr=label(entities[office]),
              office_labels={lang:x['value'] for lang,x in entities[office].get('labels',{}).items()},
              places=[dict(qid=q,label=label(entities.get(q,{'id':q}))) for q in places],
              start_earliest=start[0] if start else None,start_latest=start[1] if start else None,
              end_earliest=end[0] if end else None,end_latest=end[1] if end else None,
              date_usable=bool(start and len(starts)==1 and len(ends)<=1),
              date_note='Unknown start cannot establish a dated office holder; imprecise boundaries stay uncertain.',
              source='https://www.wikidata.org/wiki/'+person))
    return dict(offices=rows,people=list(people.values()),missing_entities=sorted(missing),
                excluded_nonhuman_or_untyped=sorted(excluded),snapshots=snapshots)

def holder(rows,office_qid,date,place_qid=None):
    """Unique definitely-active holder; ambiguous or uncertain boundary -> no identity."""
    possible=[];certain=[]
    for row in rows:
        if row['office_qid']!=office_qid:continue
        if place_qid and place_qid not in {p['qid'] for p in row['places']}:continue
        a,b=row['start_earliest'],row['end_latest']
        if (a and date<a) or (b and date>b):continue
        possible.append(row['entity_qid'])
        if row['date_usable'] and date>=row['start_latest'] and (not row['end_earliest'] or date<=row['end_earliest']):certain.append(row['entity_qid'])
    return certain[0] if len(set(possible))==1 and len(set(certain))==1 else None
