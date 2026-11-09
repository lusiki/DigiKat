"""Agreement is conditional on supplied candidates; neither model is truth."""
import collections,json
from active_protocol import protocol

FIELDS=['speaker_identity','mode','proposition_status','function','authority_cue','relation']

def kappa(a,b):
    if len(a)!=len(b):raise ValueError('Unpaired observations')
    n=len(a)
    if not n:return dict(n=0,observed_agreement=None,chance_agreement=None,kappa=None,degenerate=True)
    ca=collections.Counter(a);cb=collections.Counter(b)
    observed=sum(x==y for x,y in zip(a,b))/n
    chance=sum(ca[k]*cb[k] for k in ca.keys()|cb.keys())/(n*n)
    result=(observed-chance)/(1-chance) if chance<1-1e-12 else None
    return dict(n=n,observed_agreement=observed,chance_agreement=chance,kappa=result,degenerate=result is None)

def bundle_slots(text,author,author_qid,mentions):
    bundle=protocol.prepare(text,author,mentions);mapping={}
    for candidate in bundle['candidates']:
        surface=candidate['surface']
        ids={m.get('entity_id') for m in mentions if m['surface']==surface and m.get('entity_id')}
        if surface==author and author_qid:ids.add(author_qid)
        mapping[candidate['id']]=next(iter(ids)) if len(ids)==1 else 'UNRESOLVED_SLOT:'+str(candidate['id'])
    return bundle,mapping

def eligible_slots(mapping,mentions,author_qid):
    allowed={m.get('entity_id') for m in mentions if m.get('entity_id') and
             (m.get('class')=='contemporary' or m.get('type')=='ORG')}
    if author_qid:allowed.add(author_qid)
    return set(mapping.values()) & allowed

def field_labels(rows,mapping):
    """Collapse source-name aliases only when they share a supplied entity ID.

    Multiple functions/modes for one person remain sets. Missing output is not
    treated as missing data: it is the coder's none/not-stated decision. A failed
    response is excluded before this function, not replaced by empty rows.
    """
    grouped=collections.defaultdict(list)
    for row in rows:grouped[mapping[row['candidate_id']]].append(row)
    result={field:{} for field in FIELDS}
    for slot in sorted(set(mapping.values())):
        rr=grouped[slot];present=[r for r in rr if r['proposition_status'] in {'stated','announced_only'}]
        stated=[r for r in rr if r['proposition_status']=='stated']
        result['speaker_identity'][slot]=bool(present)
        result['mode'][slot]=tuple(sorted({r['mode'] for r in present})) or ('none',)
        result['proposition_status'][slot]=tuple(sorted({r['proposition_status'] for r in present})) or ('none',)
        for field in ['function','authority_cue']:
            result[field][slot]=tuple(sorted({r[field] for r in stated})) or ('not_stated',)
        relations=[]
        surfaces={r['surface']:mapping[r['candidate_id']] for r in rows}
        for row in stated:
            relation=row['relation']
            if relation['type']!='none':
                # Relation targets need not themselves have a returned speaker row.
                target=relation.get('target_slot') or surfaces.get(relation['target_surface']) or 'SURFACE:'+relation['target_surface']
                relations.append((relation['type'],target))
        result['relation'][slot]=tuple(sorted(set(relations))) or (('none',''),)
    return result

def pair_labels(primary,secondary,mapping):
    x=field_labels(primary,mapping);y=field_labels(secondary,mapping)
    return {field:([x[field][slot] for slot in sorted(x[field])],
                   [y[field][slot] for slot in sorted(y[field])]) for field in FIELDS}

def publication_level(k,grounding_failure,determinism,synthetic_passed):
    if not synthetic_passed or grounding_failure>.02 or determinism is None or determinism<.95 or k is None:return 'withdrawn'
    return 'B' if k>=.7 else 'C' if k>=.5 else 'withdrawn'

def canonical_output(rows):
    return json.dumps(sorted(rows,key=lambda r:r['candidate_id']),sort_keys=True,ensure_ascii=False)

def derived_levels(fields):
    required={'speaks':['speaker_identity','mode','proposition_status'],
      'interpretive':['speaker_identity','mode','proposition_status','function'],
      'authority':['speaker_identity','mode','proposition_status','authority_cue'],
      'relations':['speaker_identity','mode','proposition_status','relation']}
    def combine(names):
        values=[fields[f]['publication_level'] for f in names]
        return 'withdrawn' if 'withdrawn' in values else 'C' if 'C' in values else 'B'
    return {name:combine(names) for name,names in required.items()}
