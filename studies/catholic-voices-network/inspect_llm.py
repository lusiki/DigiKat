"""Print only aggregate model diagnostics, never corpus text or names."""
import collections,json
from voices_common import *
con=connect()
rows=con.execute('SELECT model,mode,attempt,raw_json,checks_json,error_type FROM pilot_llm_calls').fetchall()
counts=collections.Counter()
for model,mode,attempt,raw,check,error in rows:
    p=json.loads(raw);c=json.loads(check)
    counts[(model,mode,attempt,','.join(c['errors']),str(p.get('done_reason')),str(error))]+=1
print(json.dumps([dict(model=m,mode=mo,attempt=a,errors=e,done_reason=d,error_type=er,n=n)
  for (m,mo,a,e,d,er),n in counts.items()],indent=2))
con.close()
