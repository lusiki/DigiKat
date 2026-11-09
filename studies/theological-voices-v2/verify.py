"""Nontrivial checks of sample arithmetic, task bases, evidence and delivered PDF."""
import argparse, json, sqlite3, re
import numpy as np
import pandas as pd
from pypdf import PdfReader
from prepare import OUT, CFG, file_sha, save_json
from coder import get_config_hash, CHALLENGE_BUNDLE

def analysis():
    freeze=json.loads((OUT/'freeze.json').read_text(encoding='utf-8'));checks=[]
    def check(name,condition):
        checks.append({'check':name,'passed':bool(condition)})
        if not condition:raise AssertionError(name)
    for name,h in freeze['files'].items():check('immutable '+name,file_sha(OUT/name)==h)
    challenge_freeze=json.loads((OUT/f'{CHALLENGE_BUNDLE}_freeze.json').read_text(encoding='utf-8'))
    for name,h in challenge_freeze['files'].items():check('immutable fresh challenge '+name,file_sha(OUT/name)==h)
    check('original freeze unchanged after new challenge',file_sha(OUT/'freeze.json')==challenge_freeze['original_freeze_sha256'])
    new_challenge=pd.read_parquet(OUT/f'{CHALLENGE_BUNDLE}_inputs.parquet')
    check('fresh challenge has 30 distinct publications',len(new_challenge)==30 and new_challenge.publication_id.is_unique)
    for name in ['main','development','challenge']:
        earlier=pd.read_csv(OUT/f'{name}_manifest.csv',encoding='utf-8-sig')
        check('fresh challenge disjoint from '+name,not set(earlier.publication_id)&set(new_challenge.publication_id))
    source=json.loads((OUT/'source_audit.json').read_text(encoding='utf-8'))
    check('original corpus unchanged',file_sha(source['input_path'])==source['sha256'])
    s=pd.read_parquet(OUT/'main_inputs.parquet');a=pd.read_csv(OUT/'tables'/'articles.csv')
    r=pd.read_csv(OUT/'tables'/'speaker_roles.csv');v=pd.read_csv(OUT/'tables'/'voices.csv')
    overlap=pd.read_csv(OUT/'tables'/'experience_overlap.csv')
    check('sample size',len(s)==CFG['sample_size']);check('unique publications',s.publication_id.is_unique)
    check('weight sum',np.isclose(s.sampling_weight.sum(),freeze['publications']))
    check('probabilities and weights',np.allclose(s.inclusion_probability*s.sampling_weight,1))
    check('all main accounted',set(a.publication_id)==set(s.publication_id))
    check('no unattempted',not (a.processing_status=='not_attempted').any())
    check('positive and negative articles share base',int(a.speakers_base.sum())==int(r.valid_articles.iloc[0]))
    check('uncertain attribution is excluded from speaker rates',not (a.speakers_base & (a.speaker_decision_status=='unresolved')).any())
    check('uncertain interpretation is excluded from interpreter rates',not (a.interpretation_base & ~a.interpretation_flags_resolved).any())
    check('unknown experience cannot become a negative finding',not (a.experience_base & a.experience_voice.isna()).any())
    for col in ['actor_role_share_weighted_pct','role_presence_share_weighted_pct']:
        if r[col].notna().any():check(col+' sums to 100',np.isclose(r[col].sum(),100))
    check('article prevalence bounded',r.article_prevalence_weighted_pct.dropna().between(0,100).all())
    check('overlap partition',overlap.n.sum()==overlap.denominator.iloc[0])
    if overlap.weighted_pct.notna().any():check('weighted overlap partition',np.isclose(overlap.weighted_pct.sum(),100))
    check('actor count reconciliation',r.actor_role_n.sum()==len(v[v.complete_article_base].drop_duplicates(['publication_id','actor_key','role'])))
    db=sqlite3.connect(OUT/'coding.sqlite');chash=get_config_hash();count=0;verified_results=[]
    for row in db.execute("SELECT result_json FROM articles WHERE set_name='main' AND config_hash=?",(chash,)):
        z=json.loads(row[0]);count+=1;verified_results.append(z)
        supplied={p for seg in z['segments'] for p in seg['input_passage_ids']}
        check(z['publication_id']+' full text covered',supplied==set(z['passages'])-{'H001'})
        for field in ['voices','mentions','affected_groups']:
            for item in z[field]:
                for k in ['evidence_ids','identity_ids','statement_ids','classification_evidence_ids']:
                    if k in item:check(z['publication_id']+' '+field+' evidence',set(item[k])<=set(z['passages']) and bool(item[k]))
    check('all main rows in database',count==CFG['sample_size'])
    from input_delivery import audit as audit_input_delivery
    delivery=audit_input_delivery(db,verified_results,chash);db.close()
    saved_delivery=pd.read_csv(OUT/'tables'/'input_delivery.csv').set_index('publication_id')
    check('actual input audit covers all main records',len(delivery)==CFG['sample_size'] and set(saved_delivery.index)==set(s.publication_id))
    for row in delivery:
        check('actual input delivery '+row['publication_id'],row['processing_status']!='complete' or row['coverage_status']=='confirmed_full')
        saved=saved_delivery.loc[row['publication_id']]
        check('saved input audit '+row['publication_id'],all(str(saved[k])==str(row[k])
              for k in ['coverage_status','expected_body_passages','confirmed_body_passages']))
    reuse=json.loads((OUT/'deterministic_reuse_cases.json').read_text(encoding='utf-8'))['cases']
    metadata=pd.read_parquet(OUT/'frame.parquet',columns=['publication_id','text_hash','text_length','outlet_id','outlet_name','published_at','title','url'])
    for case in reuse:
        family=metadata[metadata.text_hash==case['text_hash']]
        check('reuse family IDs '+case['id'],set(family.publication_id)=={m['publication_id'] for m in case['members']})
        check('reuse counts '+case['id'],len(family)==case['publications'] and family.outlet_id.nunique()==case['outlets'])
        days=pd.to_datetime(family.published_at).dt.normalize()
        check('reuse date span '+case['id'],int((days.max()-days.min()).days)==case['span_days'])
        check('reuse date endpoints '+case['id'],str(days.min().date())==case['first_date'] and str(days.max().date())==case['last_date'])
        check('reuse display is a subset '+case['id'],{m['publication_id'] for m in case['display_members']}<=set(family.publication_id))
        check('reuse body length rule '+case['id'],bool((family.text_length>=1000).all()))
        indexed=family.set_index('publication_id')
        for member in case['display_members']:
            original=indexed.loc[member['publication_id']]
            check('reuse visible metadata '+member['publication_id'],all(str(member[k])==str(original[k])
                  for k in ['outlet_name','published_at','title','url']))
    policy_path=OUT/'report_policy.json'
    if policy_path.exists():
        policy=json.loads(policy_path.read_text(encoding='utf-8'))
        check('report policy matches frozen coder',policy['config_hash']==chash)
        claims=json.loads((OUT/'claims.json').read_text(encoding='utf-8'))
        if not policy['model_content_numbers_eligible']:
            check('all model content claims withdrawn',all(x.get('publication_status')=='withheld' for x in claims
                  if x['id'] not in {'frame','source_concentration','exact_reuse'} and not x['id'].startswith('exact_reuse_case_')))
    save_json(OUT/'analysis_verification.json',{'checks':checks,'passed':len(checks),'failed':0,'human_validation':False})
    print(f'PASS {len(checks)} analysis/evidence checks')

def pdf():
    report=OUT/'report';path=report/'tko-dobiva-rijec-o-vjeri-v2.pdf';reader=PdfReader(path)
    render=json.loads((report/'render_check.json').read_text(encoding='utf-8'))
    assert len(reader.pages)==render['pages']
    assert all(__import__('pathlib').Path(p['png']).exists() for p in render['rendered_pages'])
    assert all('\ufffd' not in p.extract_text() for p in reader.pages)
    boxes=json.loads((report/'layout_boxes.json').read_text(encoding='utf-8'))
    assert all(b['top']-b['height']>=50 for b in boxes)
    data=json.loads((OUT/'report_data.json').read_text(encoding='utf-8'))
    text='\n'.join(p.extract_text() for p in reader.pages)
    from build_report import n
    assert n(data['sample']) in text and n(data['frame']['publications']) in text
    assert 'Nema ljudske validacije' in re.sub(r'\s+',' ',text)
    policy=data.get('report_policy',{})
    if policy and not policy['model_content_numbers_eligible']:
        assert 'limited_exploratory' in text
        assert 'Brojčane tvrdnje o sadržaju povučene' in re.sub(r'\s+',' ',text)
    save_json(report/'mechanical_verification.json',{'pages':len(reader.pages),'all_pages_rendered':True,
      'no_replacement_glyph':True,'layout_boxes_within_margins':True,'cover_totals_match_tables':True,
      'visual_review':'still required; mechanical checks are not visual inspection'})
    print(f'PASS PDF mechanical checks ({len(reader.pages)} pages); visual review pending')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('stage',choices=['analysis','pdf']);args=p.parse_args();globals()[args.stage]()
