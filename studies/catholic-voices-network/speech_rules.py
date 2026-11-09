"""Dependency-based attribution primitives. No name-near-quote shortcut."""
import re

SPEECH={'reći','kazati','izjaviti','istaknuti','naglasiti','poručiti','upozoriti',
        'dodati','pojasniti','objasniti','napisati','smatrati','tvrditi','podsjetiti',
        'zaključiti','komentirati','poručivati','izjavljivati','kazivati'}
QUOTE_PAIRS=[('„','“'),('"','"'),('»','«'),('‘','’')]

def quotes(text):
    spans=[]
    for left,right in QUOTE_PAIRS:
        for match in re.finditer(re.escape(left)+r'([^'+re.escape(right)+r']{2,})'+re.escape(right),text):
            spans.append((match.start(1),match.end(1)))
    return sorted(set(spans))

def attributed(text,tokens,mentions):
    """tokens carry global offsets, sentence, and words with UD id/head/lemma.

    Mention identities must have been classified contemporary by the caller;
    unresolved/historical mentions are deliberately ineligible here.
    """
    out=[];quote_spans=quotes(text)
    for si in sorted({t['sentence'] for t in tokens}):
        sentence=[t for t in tokens if t['sentence']==si]
        words={w['id']:{**w,'start':t['start'],'end':t['end']} for t in sentence for w in t['words']}
        children={i:[] for i in words}
        for w in words.values():
            if w['head'] in children:children[w['head']].append(w['id'])
        def subtree(root):
            found=set();pending=[root]
            while pending:
                key=pending.pop()
                if key in found:continue
                found.add(key);pending.extend(children.get(key,[]))
            return [words[k] for k in found]
        for verb in words.values():
            if (verb.get('lemma') or '').casefold() not in SPEECH:continue
            subjects=[w for w in words.values() if w['head']==verb['id'] and w.get('deprel','').split(':')[0]=='nsubj']
            eligible=[]
            for subject in subjects:
                subject_ids={subject['id']};pending=[subject['id']]
                while pending:
                    parent=pending.pop()
                    for child in children.get(parent,[]):
                        if child not in subject_ids and words[child].get('deprel','').split(':')[0] in {'flat','compound','conj'}:
                            subject_ids.add(child);pending.append(child)
                subject_words=[words[k] for k in subject_ids]
                eligible.extend(m for m in mentions if m.get('class')=='contemporary' and m.get('entity_id') and
                  any(m['start']<=w['start']<w['end']<=m['end'] for w in subject_words))
            eligible={m['entity_id']:m for m in eligible}
            if not eligible:continue
            sa=min(t['start'] for t in sentence);sb=max(t['end'] for t in sentence)
            nearby=[(a,b) for a,b in quote_spans if sa<=a<b<=sb and
                    min(abs(a-verb['end']),abs(b-verb['start']))<=200]
            if nearby:
                content=min(nearby,key=lambda q:min(abs(q[0]-verb['end']),abs(q[1]-verb['start'])))
                mode='direct'
            else:
                clauses=[w for w in words.values() if w['head']==verb['id'] and w.get('deprel','').split(':')[0] in {'ccomp','parataxis','obj'}]
                if not clauses:continue
                clause_words=[w for clause in clauses for w in subtree(clause['id'])]
                content=(min(w['start'] for w in clause_words),max(w['end'] for w in clause_words));mode='indirect'
            for eid,m in eligible.items():
                out.append(dict(entity_id=eid,mode=mode,content_start=content[0],content_end=content[1],
                  evidence_start=min(m['start'],verb['start'],content[0]),
                  evidence_end=max(m['end'],verb['end'],content[1]),speech_verb=verb['lemma']))
    return out

def first_person(text,tokens,author_entity):
    if not author_entity:return None
    quotation=quotes(text)
    # Require an unquoted finite first-person verb, not merely a quoted "ja".
    first=[t for t in tokens if not any(a<=t['start'] and t['end']<=b for a,b in quotation) and
           any('Person=1' in (w.get('feats') or '') and w.get('upos') in {'VERB','AUX'} for w in t['words'])]
    if not first:return None
    return dict(entity_id=author_entity,mode='first_person',evidence_start=0,evidence_end=len(text))
