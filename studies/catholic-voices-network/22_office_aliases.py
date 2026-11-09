"""Conservative official-directory title aliases; never infer new tenure dates."""
import json,re
from voices_common import *
from dated_office_rules import holder

def specific_bishop_office(label):
    label=label.casefold()
    if re.search(r'titular|naslovn|coadjutor|koadjutor|auxiliary|pomoćn',label):return False
    if re.search(r'\b(?:archbishop|bishop) of\b',label):return True
    generic={'dijecezanski biskup','katolički nadbiskup','katolički biskup','rimokatolički biskup','biskup','nadbiskup'}
    return bool(re.search(r'biskup',label) and label not in generic and len(label.split())>=2)

def derive(audit,register):
    accepted=[];rejected=[]
    for entry in audit['entries']:
        if entry['retired'] or entry['unique_holder_matches_at_corpus_end']:continue
        title=entry['role'].split(',')[0].strip().casefold()
        # Current generic military/auxiliary roles do not identify a jurisdiction
        # from the text itself; titular sees are not local diocesan appointments.
        if not re.search('biskup',title) or re.search(r'vojni|pomoćn|naslovn|vizitator|upravitelj',title):
            rejected.append(dict(name=entry['name'],reason='generic_or_composite_role'));continue
        if len(entry['qid_matches'])!=1:continue
        qid=entry['qid_matches'][0]
        offices={row['office_qid'] for row in register['offices'] if row['entity_qid']==qid
          and row['date_usable'] and specific_bishop_office(row['office_label_hr'])
          and holder(register['offices'],row['office_qid'],'2026-10-16')==qid}
        if len(offices)!=1:
            rejected.append(dict(name=entry['name'],reason='no_unique_dated_specific_office',offices=sorted(offices)));continue
        accepted.append(dict(title=title,office_qid=next(iter(offices)),public_person_qid=qid,
          source=entry['url'],directory=entry['directory'],observed_utc=entry['profile_retrieved_utc'],
          method='Exact public-person name match; one uniquely held dated specific bishop office; official role wording. No new dates.'))
    return accepted,rejected

def main():
    audit_path=workdir()/'office_directory_audit_v2.json';register_path=workdir()/'office_register.json'
    audit=json.loads(audit_path.read_text(encoding='utf-8'));register=json.loads(register_path.read_text(encoding='utf-8'))
    if audit['register_sha256']!=file_sha(register_path):raise RuntimeError('Office audit is stale')
    accepted,rejected=derive(audit,register)
    result=dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      code_sha256=file_sha(__file__),dated_rules_sha256=file_sha(STUDY/'dated_office_rules.py'),
      register_sha256=file_sha(register_path),audit_sha256=file_sha(audit_path),aliases=accepted,rejected=rejected,
      caveat='Machine-linked title aliases only; unvalidated. Current directories do not supply historical tenure boundaries. Ambiguous/generic/composite roles remain unresolved.')
    path=workdir()/'office_title_aliases.json'
    if path.exists():
        previous=json.loads(path.read_text(encoding='utf-8'));result['created_utc']=previous['created_utc']
        if previous!=result:raise RuntimeError('Frozen title aliases differ; use a new version before identity resolution')
    atomic_json(path,result);print(json.dumps(dict(accepted=len(accepted),rejected=len(rejected))),flush=True)

if __name__=='__main__':main()
