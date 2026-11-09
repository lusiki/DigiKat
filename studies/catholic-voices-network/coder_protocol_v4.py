"""v4 fixes invalid JSON Schema when the supplied candidate list is empty.

Prompt, nonempty-case schema and semantic rules are unchanged from v3. The v3
requests/results and exact archived driver remain available for diagnosis.
"""
import json
import coder_protocol_v3 as v3
from llm_protocol import obj
PROMPT=v3.PROMPT
prepare=v3.prepare
expand=v3.expand
conforms=v3.conforms

def schema(bundle):
    if bundle['candidates']:return v3.schema(bundle)
    return obj(dict(s=dict(type='array',maxItems=0,items=dict(type='object',properties={},additionalProperties=False))))

def validate(raw,bundle):
    try:value=json.loads(raw)
    except (TypeError,ValueError):return None,['json']
    if not conforms(value,schema(bundle)):return None,['schema']
    return v3.validate(raw,bundle)
