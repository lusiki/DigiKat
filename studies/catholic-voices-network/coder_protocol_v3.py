"""Versioned strict protocol; v2 repair artifacts remain reproducible."""
import json
import repair_protocol as v2

PROMPT=v2.PROMPT+'''
Scope: statements about religion, faith, religious practice, Church institutions,
or their social/public activity. Omit a football coach's unrelated match comment.
For a signed first-person post, AUTHOR can identify the speaker only when the
text contains their own first-person statement. An institution speaking as "we"
has mode 4, not personal testimony. Do not turn a quoted third party into AUTHOR.
For an announced talk with no visible content use q=2, f=0, a=0 and m=0.
Use f=4 only for the speaker's own lived experience, not a prediction about others.
Clerical titles do not imply academic expertise. Explicit professor/theologian
attribution supports academic authority; do not infer it from the name.
An empty result is preferable to attributing unsupported narrator prose.'''
prepare=v2.prepare
schema=v2.schema
expand=v2.expand

def conforms(value,spec):
    kind=spec.get('type')
    if kind=='integer' and type(value) is not int:return False
    if kind=='object':
        if type(value) is not dict or set(value)!=set(spec['properties']):return False
        return all(conforms(value[k],s) for k,s in spec['properties'].items())
    if kind=='array':
        if type(value) is not list or not spec.get('minItems',0)<=len(value)<=spec.get('maxItems',10**9):return False
        return all(conforms(x,spec['items']) for x in value)
    if kind=='string' and (type(value) is not str or not spec.get('minLength',0)<=len(value)<=spec.get('maxLength',10**9)):return False
    if 'enum' in spec and value not in spec['enum']:return False
    return True

def validate(raw,bundle):
    try:value=json.loads(raw)
    except (ValueError,TypeError):return None,['json']
    if not conforms(value,schema(bundle)):return None,['schema']
    value,errors=v2.validate(raw,bundle)
    for row in value['s']:
        if row['q']==1 and row['m']==0:errors.append('stated_without_mode')
        if row['q']!=1 and row['r']!=0:errors.append('relation_without_statement')
        if len(set(row['e']))!=len(row['e']):errors.append('duplicate_evidence')
        if row['r'] and bundle['candidates'][row['target']].get('author_only'):
            errors.append('relation_target_not_in_passage')
    return value,sorted(set(errors))
