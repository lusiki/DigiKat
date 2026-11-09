"""Evidence-linked scalar/fragment registry and fail-closed report assembly."""
import hashlib,json,math,re
from pathlib import Path

TOKEN=re.compile(r'\{\{(scalar|fragment|figure):([a-z][a-z0-9_]*)\}\}')
FOOTER='Imena i izjave prepoznati automatski; nije provedena ljudska provjera.'
FINAL_STATUSES={'complete','withheld','not_applicable'}

def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()

def pointer(value,path):
    if not path:return value
    if not path.startswith('/'):raise ValueError('JSON pointer must start with /')
    for key in path[1:].split('/'):
        key=key.replace('~1','/').replace('~0','~')
        value=value[int(key)] if isinstance(value,list) else value[key]
    return value

def format_hr(value,kind='integer',digits=1,suppress_small=False):
    if kind=='text':return str(value)
    if kind=='label':
        # Public labels are data, not Markdown/HTML/citation instructions.
        import html
        return re.sub(r'([\\|\[\]*_#@`])',r'\\\1',html.escape(str(value),quote=False))
    if isinstance(value,bool) or not isinstance(value,(int,float)) or not math.isfinite(value):
        raise ValueError('Numeric scalar must be finite, not boolean')
    if suppress_small and 0<=value<5:return '<5'
    if kind=='integer':
        if value!=int(value):raise ValueError('Integer display would round a noninteger value')
        return f'{int(value):,}'.replace(',','\u00a0')
    if kind not in {'number','percent'}:raise ValueError('Unknown numeric format')
    display=f'{value*100 if kind=="percent" else value:,.{digits}f}'
    display=display.replace(',','\u00a0').replace('.',',')
    return display+('\u00a0%' if kind=='percent' else '')

def resolve_proof(proof,sources):
    source=sources[proof['source']]
    return pointer(source,proof['pointer'])

def check_numeric_tokens(text,label):
    prose=TOKEN.sub('',text)
    prose=re.sub(r'\[@[^\]]+\]|@[A-Za-z][A-Za-z0-9_:-]*','',prose)
    prose=re.sub(r'https?://[^\s)>]+','',prose)
    if re.search(r'\d',prose):raise ValueError('Unregistered literal number in '+label)

def verify_registry(registry,base):
    base=Path(base);sources={};errors=[]
    for key,entry in registry['sources'].items():
        path=Path(entry['path']);path=path if path.is_absolute() else base/path
        if not path.exists() or sha(path)!=entry['sha256']:
            errors.append('source_missing_or_changed:'+key);continue
        sources[key]=json.loads(path.read_text(encoding='utf-8'))
    if errors:raise ValueError('; '.join(errors))
    rendered={}
    for key,entry in registry['scalars'].items():
        if 'ratio' in entry:
            numerator=resolve_proof(entry['ratio']['numerator'],sources)
            denominator=resolve_proof(entry['ratio']['denominator'],sources)
            if denominator<=0:raise ValueError('Undefined denominator: '+key)
            expected=numerator/denominator
        else:expected=resolve_proof(entry['proof'],sources)
        if entry['value']!=expected:raise ValueError('Scalar does not match evidence: '+key)
        rendered[key]=format_hr(entry['value'],entry.get('format','integer'),entry.get('digits',1),entry.get('suppress_small',False))
    for key,claim in registry['claims'].items():
        if claim['level'] not in {'A','B','C'}:raise ValueError('Invalid claim level: '+key)
        if not claim['evidence'] or any(e not in registry['scalars'] and e not in registry.get('figures',{}) for e in claim['evidence']):
            raise ValueError('Claim lacks registered evidence: '+key)
        if claim['level'] in {'B','C'}:
            actual=resolve_proof(claim['publication_gate'],sources)
            if actual not in {'B','C'} or (claim['level']=='B' and actual!='B'):
                raise ValueError('Claim exceeds publication gate: '+key)
    for key,fragment in registry['fragments'].items():
        if fragment['status'] not in FINAL_STATUSES:raise ValueError('Unfinished section: '+key)
        path=base/fragment['path']
        if sha(path)!=fragment['sha256']:raise ValueError('Fragment changed: '+key)
        check_numeric_tokens(path.read_text(encoding='utf-8'),'fragment '+key)
        for claim in fragment['claims']:
            if claim not in registry['claims']:raise ValueError('Unknown fragment claim: '+claim)
            if registry['claims'][claim]['level']=='C' and fragment.get('location')!='appendix':
                raise ValueError('Exploratory claim outside appendix: '+claim)
        if fragment['status']=='withheld' and not fragment.get('reason'):
            raise ValueError('Withheld section requires its reason: '+key)
    for key,figure in registry.get('figures',{}).items():
        if not figure.get('title') or not figure.get('source_note') or not figure.get('alt'):
            raise ValueError('Figure missing reader-facing explanation: '+key)
        for field in ['title','source_note','alt']:check_numeric_tokens(figure[field],'figure '+key+' '+field)
        if not figure.get('data_proofs'):raise ValueError('Figure lacks data evidence: '+key)
        if sha(base/figure['path'])!=figure['sha256']:raise ValueError('Figure changed: '+key)
        for proof in figure['data_proofs']:resolve_proof(proof,sources)
    return rendered

def assemble(template,registry,base):
    base=Path(base);scalars=verify_registry(registry,base);used=set()
    narrative=re.sub(r'\A---\r?\n.*?\r?\n---\r?\n','',template,flags=re.S)
    check_numeric_tokens(narrative,'template body')
    def expand(text,allow_fragments):
        def replace(match):
            kind,key=match.groups();used.add((kind,key))
            if kind=='scalar':return scalars[key]
            if kind=='fragment':
                if not allow_fragments:raise ValueError('Nested fragments are forbidden')
                return expand((base/registry['fragments'][key]['path']).read_text(encoding='utf-8'),False)
            figure=registry['figures'][key]
            title=expand(figure['title'],False);note=expand(figure['source_note'],False);alt=expand(figure['alt'],False)
            return f'::: {{.keep-figure}}\n\n#### {title}\n\n![{alt}]({figure["path"]})\n\n> {note}\n\n:::\n'
        return TOKEN.sub(replace,text)
    result=expand(template,True)
    if '{{' in result or '}}' in result:raise ValueError('Unresolved report token')
    if '\ufffd' in result or '\x00' in result:raise ValueError('Broken text encoding')
    if FOOTER not in result:raise ValueError('Missing machine-only statement')
    if any(('fragment',k) not in used for k in registry['fragments']):raise ValueError('Registered section omitted from template')
    for key,claim in registry['claims'].items():
        if not any(key in f['claims'] for f in registry['fragments'].values()):raise ValueError('Claim not placed in a section: '+key)
    return result,dict(used_scalars=sorted(k for kind,k in used if kind=='scalar'),
      used_figures=sorted(k for kind,k in used if kind=='figure'),
      used_fragments=sorted(k for kind,k in used if kind=='fragment'),claims=len(registry['claims']))
