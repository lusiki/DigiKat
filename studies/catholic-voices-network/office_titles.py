"""Machine-built title vocabulary from public office labels and aliases.

Lexical inflection rules are not a hand-coded office-holder register. Generic
bishop/minister titles remain roles unless a unique dated place-specific office
is supported. Named and historical references are not rewritten as incumbents.
"""
import collections,re
import regex
from dated_office_rules import holder

def phrase_pattern(label):
    words=regex.findall(r'\p{L}+(?:[-–]\p{L}+)*|\d+',label.casefold())
    pieces=[]
    for word in words:
        if word=='ministar':part=r'minist(?:ar|ra|ru|rom|re)'
        elif word=='otac':part=r'(?:otac|oca|ocu|oče|ocem)'
        elif word=='predsjednik':part=r'predsjedni(?:k|ka|ku|kom|če|ca|ce|ci|cu|com)'
        elif len(word)>=5 and word[-1] in 'ai':part=regex.escape(word[:-1])+r'\p{L}{0,3}'
        elif len(word)>=5:part=regex.escape(word)+r'\p{L}{0,3}'
        else:part=regex.escape(word)
        pieces.append(part)
    return r'(?<!\p{L})'+r'\s+'.join(pieces)+r'(?!\p{L})'

def vocabulary(register,entities,official_aliases=()):
    vocabulary=collections.defaultdict(set)
    for row in register['offices']:
        if not row['date_usable']:continue
        qid=row['office_qid'];entity=entities.get(qid,{})
        if qid=='Q19546':
            for title in ['papa','Sveti Otac']:vocabulary[title.casefold()].add(qid)
            continue
        labels=[v['value'] for lang,v in entity.get('labels',{}).items() if lang in {'hr','bs'}]
        labels += [v['value'] for lang,items in entity.get('aliases',{}).items() if lang in {'hr','bs'} for v in items]
        for title in labels:
            title=title.casefold()
            # Qualifying geography/portfolio must be in the actual label; no
            # guessed conversion from an English diocese to a Croatian adjective.
            if len(title.split())<2 or not regex.search(r'biskup|minist|predsjedni',title):continue
            if title in {'dijecezanski biskup','pomoćni biskup','rimokatolički biskup','katolički biskup','predsjednik vlade'}:continue
            vocabulary[title].add(qid)
    dated_offices={row['office_qid'] for row in register['offices'] if row['date_usable']}
    for alias in official_aliases:
        if alias['office_qid'] not in dated_offices:raise ValueError('Official title alias has no dated office')
        vocabulary[alias['title'].casefold()].add(alias['office_qid'])
    ordered=sorted(vocabulary,key=lambda x:(-len(x),x))
    pattern=regex.compile('|'.join('(?P<t'+str(i)+'>'+phrase_pattern(title)+')' for i,title in enumerate(ordered)) or '(?!)',regex.I)
    return pattern,{f't{i}':dict(title=title,offices=sorted(vocabulary[title])) for i,title in enumerate(ordered)}

def match_titles(text,date,persons,register,pattern,mapping):
    found=[]
    for match in pattern.finditer(text):
        a,b=match.span();entry=mapping[match.lastgroup]
        if not date or not re.fullmatch(r'\d{4}-\d{2}-\d{2}',date):
            found.append(dict(start=a,end=b,surface=text[a:b],qid=None,status='missing_date',office_qids=entry['offices']))
            continue
        adjacent=any((x<b and y>a and (text[x:min(y,a)].strip() or text[max(x,b):y].strip()))
                     or (b<=x<=b+24 and not text[b:x].strip(' ,')) for x,y in persons)
        adjacent=adjacent or bool(regex.match(r'\s+\p{Lu}\p{Ll}{2,}',text[b:]))
        context=text[max(0,a-70):min(len(text),b+70)]
        historical=bool(regex.search(r'\b(?:pokojn\p{L}*|bivš\p{L}*|emeritus|arhiv\p{L}*)\b',context,regex.I))
        # Include medieval four-digit years and three-digit Croatian year
        # notation; an old date must not become the modern incumbent.
        years=[int(y.rstrip('.')) for y in re.findall(r'\b(?:1\d{3}|20\d{2})\b|\b[1-9]\d{2}\.(?!\d)',context)]
        historical=historical or any(y<int(date[:4]) for y in years)
        if adjacent:status='named_context';qid=None
        elif historical:status='historical_context';qid=None
        else:
            choices={holder(register['offices'],office,date) for office in entry['offices']}
            qid=next(iter(choices)) if len(choices)==1 and None not in choices else None
            status='resolved' if qid else 'ambiguous_or_undated'
        found.append(dict(start=a,end=b,surface=text[a:b],qid=qid,status=status,office_qids=entry['offices']))
    return found
