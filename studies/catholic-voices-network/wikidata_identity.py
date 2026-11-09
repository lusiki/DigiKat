"""Conservative identity classes and source-consistent public-name matching."""
import re,unicodedata
from office_register import claims,date_bounds,label

SACRED={'isus','isus krist','krist','marija','gospa','bog','duh sveti','djevica marija',
        'blažena djevica marija','sveti petar','sveti pavao','sveti ivan','sveti jakov',
        'apostol petar','apostol pavao','apostol ivan','apostol jakov','apostoli'}
ROLE_PATTERNS={
 'clergy':r'bishop|archbishop|cardinal|\bpope\b|priest|clerg|friar|\bnun\b|biskup|\bpapa\b|svećenik|redovn|župnik|kardinal|franciscan|franjev',
 'politics':r'president|minister|politician|predsjed|minist|politič',
 'academic':r'professor|theologian|philosopher|sociolog|researcher|scholar|profesor|teolog|istraživa|znanstven'}

def norm(name):return ' '.join(re.sub(r'[^\w\s]',' ',unicodedata.normalize('NFC',name).casefold()).split())
def names(entity):
    return {norm(v['value']) for v in entity.get('labels',{}).values()}|{
      norm(v['value']) for items in entity.get('aliases',{}).values() for v in items}
def is_human(entity):return any(isinstance(v,dict) and v.get('id')=='Q5' for v in claims(entity,'P31'))

def role_matches(entity,roles,extra_labels=()):
    evidence=' '.join([v.get('value','') for v in entity.get('descriptions',{}).values()]+list(extra_labels)).casefold()
    return any(re.search(ROLE_PATTERNS[r],evidence) for r in roles if r in ROLE_PATTERNS)

def person_facts(entity):
    return dict(qid=entity['id'],label=label(entity),
      birth=[b for v in claims(entity,'P569') if (b:=date_bounds(v))],
      death=[b for v in claims(entity,'P570') if (b:=date_bounds(v))],
      birth_recorded=bool(claims(entity,'P569')),death_recorded=bool(claims(entity,'P570')),
      occupations=[v.get('id') for v in claims(entity,'P106') if isinstance(v,dict)],
      offices=[v.get('id') for v in claims(entity,'P39') if isinstance(v,dict)],
      canonization_status=[v.get('id') for v in claims(entity,'P411') if isinstance(v,dict)])

def classification(name,facts,date):
    if norm(name) in SACRED:return 'sacred'
    if not facts or not facts.get('qid'):return 'unresolved'
    if not date or not re.fullmatch(r'\d{4}-\d{2}-\d{2}',date):return 'date_uncertain'
    # Exact public taxonomy verified in cached Wikidata search on 2026-10-25.
    # Generic "saint" Q43115 explicitly need not mean formally canonized.
    if 'Q123110154' in facts.get('canonization_status',[]):return 'historical'
    deaths=facts.get('death',[])
    if facts.get('death_recorded') and not deaths:return 'date_uncertain'
    if deaths:
        if any(date>d[1] for d in deaths):return 'historical'
        if any(d[0]<=date<=d[1] for d in deaths):return 'date_uncertain'
    births=facts.get('birth',[])
    if facts.get('birth_recorded') and not births:return 'unresolved'
    if births and any(date<b[1] for b in births):return 'date_uncertain'
    if not deaths and births and int(date[:4])-min(int(b[0][:4]) for b in births)>110:return 'unresolved'
    # Absence of a death claim is a machine assumption, not verified survival.
    return 'contemporary'
