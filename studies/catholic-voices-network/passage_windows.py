"""Bounded passage construction, shared by rule and model tiers."""
import hashlib,importlib,re
from wikidata_identity import norm
pilot=importlib.import_module('02_prepare_remaining')
SPEECH_HINT=re.compile(r'\b(?:reč|rek|kaz|izjav|istak|naglas|poruč|upozor|doda|pojasn|objasn|napi|smatr|tvrdi|podsje|zaklju|koment)\w*',re.I)
QUOTE=re.compile('[„“”"»«]')

def paragraph(text,at):return len(re.findall(r'\n\s*\n',text[:at]))

def create_windows(doc_id,text,bounds,mentions,author=''):
    if len(text)<300:return []
    anchors=[m for m in mentions if m.get('class')=='contemporary' or m.get('type')=='ORG']
    if author:
        for a,b in bounds:
            # First-person speech may occur late in a paragraph with no named
            # mention; expose every source sentence to the later morphology tier.
            anchors.append(dict(start=a,end=min(a+1,b)))
    selected={}
    for m in anchors:
        si=next((i for i,(a,b) in enumerate(bounds) if a<=m['start']<m['end']<=b),None)
        if si is None:continue
        span=pilot.window_bounds(text,bounds,si,m['start'],m['end'])
        if span is None:continue
        a,b=span
        mm=[{**p,'start':p['start']-a,'end':p['end']-a} for p in mentions if a<=p['start']<p['end']<=b]
        selected[(a,b)]=dict(item_id=f'{doc_id}:w{a}:{b}',start=a,end=b,text=text[a:b],
          paragraph_id=paragraph(text,m['start']),mentions=mm,author=author,
          sentence_ids=[i for i,(x,y) in enumerate(bounds) if x<b and y>a])
    return [selected[key] for key in sorted(selected)]

def org_id(surface):return 'ORG:'+hashlib.sha256(norm(surface).encode()).hexdigest()[:24]
