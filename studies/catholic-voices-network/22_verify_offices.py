"""Frozen office/register checks after official-title alias supplementation."""
import json
from voices_common import *
from office_register import read_cache
from dated_office_rules import holder,MAX_TENURE_YEARS
from office_titles import vocabulary

def main():
    register_path=workdir()/'office_register.json'
    register=json.loads(register_path.read_text(encoding='utf-8'))
    alias_path=workdir()/'office_title_aliases.json'
    aliases=json.loads(alias_path.read_text(encoding='utf-8'))
    assert aliases['register_sha256']==file_sha(register_path)
    audit=json.loads((workdir()/'office_directory_audit_v2.json').read_text(encoding='utf-8'))
    entities,_,_=read_cache(workdir()/'public_register_cache')
    pattern,mapping=vocabulary(register,entities,aliases['aliases'])
    checks=[]
    for date,expected in [('2025-04-20','Q450675'),('2025-04-22',None),('2025-05-07',None),('2025-05-09','Q6109517')]:
        actual=holder(register['offices'],'Q19546',date)
        checks.append(dict(date=date,expected=expected,actual=actual,passed=actual==expected))
    coverage=[]
    for entry in audit['entries']:
        if entry['retired']:continue
        offices={q for match in pattern.finditer(entry['role']) for q in mapping[match.lastgroup]['offices']}
        matched=len(entry['qid_matches'])==1 and any(holder(register['offices'],q,'2026-10-16')==entry['qid_matches'][0] for q in offices)
        coverage.append(dict(name=entry['name'],role=entry['role'],matched=matched,source=entry['url']))
    report=dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      register_sha256=file_sha(register_path),aliases_sha256=file_sha(alias_path),
      papal_checks=checks,papal_checks_passed=all(c['passed'] for c in checks),
      active_directory_entries=len(coverage),matched_titles=sum(c['matched'] for c in coverage),
      maximum_tenure_years=MAX_TENURE_YEARS,coverage=coverage,
      note='Official current-directory consistency/coverage only, not historical accuracy. All observed dates retained. Supplemental labels introduce no new tenure dates; unresolved roles stay unresolved.')
    atomic_json(workdir()/'office_coverage_report.json',report)
    print(json.dumps({k:v for k,v in report.items() if k not in {'coverage','papal_checks'}}))
    if not report['papal_checks_passed']:raise RuntimeError('Papal boundary audit failed')

if __name__=='__main__':main()
