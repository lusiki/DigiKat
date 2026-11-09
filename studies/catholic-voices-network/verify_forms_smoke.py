"""Mechanical alignment gate after the first bounded morphology run."""
from voices_common import *

def main():
    con=connect()
    total=con.execute('SELECT count(*) FROM forms').fetchone()[0]
    by_model=dict(con.execute('SELECT model_type,count(*) FROM forms GROUP BY model_type').fetchall())
    rows=con.execute('SELECT status,count(*) FROM form_lemmas GROUP BY status').fetchall()
    counts=dict(rows);n=sum(counts.values());bad=counts.get('unaligned',0)
    passed=n>=min(100,total) and n>0 and bad/n<=.02
    atomic_json(workdir()/'forms_smoke_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,
      config_hash=CONFIG_HASH,checked=n,unaligned=bad,passed=passed,
      total_forms=total,remaining_forms=total-n,forms_by_model=by_model,
      note='Mechanical token/span alignment gate only. Ambiguous lemmas stay unresolved; identity accuracy is unmeasured.'))
    con.close()
    if not passed:raise SystemExit('Morphology alignment smoke gate failed; inspect saved form_lemmas before continuing.')
    print(f'Morphology smoke passed: {n-bad}/{n} forms aligned; {total-n}/{total} forms remain. Identity accuracy unmeasured.')

if __name__=='__main__':main()
