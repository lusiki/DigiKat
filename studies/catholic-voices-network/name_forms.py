"""Conservative surface/cue preparation; these are features, not verified roles."""
import hashlib,re,unicodedata
import regex

TITLE=r'(?:prof\.|dr\.|mons\.|msgr\.|vlč\.|fra|don|s\.|pap\p{L}{0,2}|kardinal\p{L}{0,3}|nadbiskup\p{L}{0,3}|biskup\p{L}{0,3}|župnik\p{L}{0,3}|svećenik\p{L}{0,3}|minist\p{L}{0,5}|predsjedni\p{L}{0,5}|profesor\p{L}{0,4}|teolog\p{L}{0,4}|teologinj\p{L}{0,3}|sestr\p{L}{0,2})'
LEADING=regex.compile(r'^(?:'+TITLE+r'\s+)+',regex.I)
CUE=regex.compile(r'(?<!\p{L})'+TITLE+r'(?!\p{L})',regex.I)

def clean_name(text):
    return ' '.join(LEADING.sub('',unicodedata.normalize('NFC',text)).strip(' ,;:„“"').split())

def features(text,start,end,kind):
    surface=text[start:end];stripped=clean_name(surface)
    left=text[max(0,start-80):start]
    # Only the short immediate prefix; do not transfer a remote title across punctuation.
    left=regex.split(r'[,;!?\n]|(?<!\b(?:prof|mons|msgr|vlč|dr))\.',left)[-1]
    left=' '.join(left.split()[-4:])
    cues=[m.group() for m in CUE.finditer(left+' '+surface)]
    cue=' '.join(sorted(set(c.casefold() for c in cues)))
    clergy=bool(regex.search(r'\bpap|biskup|kardinal|župnik|svećenik|\bfra\b|\bdon\b|mons|vlč|sestr',cue))
    politics=bool(regex.search(r'minist|predsjedni',cue))
    cue_class='conflicting' if clergy and politics else 'clergy' if clergy else 'politics' if politics else 'other'
    gender='female' if regex.search(r'sestr|profesoric|teologinj|ministric|predsjednic',cue) else None
    key=hashlib.sha256((surface+'\0'+cue_class+'\0'+kind).encode('utf-8')).hexdigest()
    a=max(0,start-160);b=min(len(text),end+160)
    base=a
    for match in re.finditer(r'\n\s*\n',text[a:b]):
        x,y=base+match.start(),base+match.end()
        if y<=start:a=y
        elif x>=end:b=x;break
    return dict(form_id=key,surface=surface,stripped=stripped,cue=cue,cue_class=cue_class,
                gender_hint=gender,model_type=kind,context=text[a:b],start=start-a,end=end-a)

def compatible(a,b,threshold=.9):
    from rapidfuzz.distance import JaroWinkler
    if {a['cue_class'],b['cue_class']}=={'clergy','politics'}:return False
    if 'conflicting' in {a['cue_class'],b['cue_class']}:return False
    x=a['nominative'].casefold().split();y=b['nominative'].casefold().split()
    if len(x)<2 or len(y)<2 or x[-1]!=y[-1]:return False
    initial=lambda s:len(s.rstrip('.'))==1
    if x[0]!=y[0] and not ((initial(x[0]) or initial(y[0])) and x[0][0]==y[0][0]):return False
    return JaroWinkler.normalized_similarity(' '.join(x),' '.join(y))>=threshold
