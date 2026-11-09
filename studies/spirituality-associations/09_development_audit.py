"""Join private AI development notes; never write human validation labels."""
from collections import Counter
import json
from common import PRIVATE,TABLES,read_csv,write_csv,dump_json,sha

def main():
    source=PRIVATE/'ai_development_labels.json'
    labels=json.loads(source.read_text(encoding='utf-8'))
    hits=read_csv(PRIVATE/'candidate_matches.csv');result=[]
    for label in labels:
        matches=[r for r in hits if r['association_id']==label['association_id'] and r['url']==label['url']]
        assert matches,(label['association_id'],label['url'])
        result.append({**matches[0],**label,'reviewer_type':'AI_development_reading','human_validation':False})
    write_csv(PRIVATE/'ai_development_review.csv',result)
    dump_json(TABLES/'development_audit_summary.json',{'selection':'purposive examples of ambiguity and apparently substantive hits; not a precision sample',
      'reviewer_type':'AI','human_validated':False,'examples':len(result),
      'assessments':dict(Counter(r['identity_assessment'] for r in result)),'private_labels_sha256':sha(source)})
    print('Saved',len(result),'AI development readings; human coding untouched.')

if __name__=='__main__':main()
