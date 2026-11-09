"""2000 paired windows + 1000 repeated workflows, enforcing publication levels."""
import collections,json
from voices_common import *
from active_protocol import VERSION
from coded_calls import run_model,final_results,call_quality
from agreement_metrics import FIELDS,bundle_slots,eligible_slots,field_labels,kappa,publication_level,canonical_output,derived_levels

def analyse(rows,primary,secondary,repeated,repeat_ids,grounding,synthetic_passed):
    a={f:[] for f in FIELDS};b={f:[] for f in FIELDS};same=collections.Counter()
    ca={f:[] for f in FIELDS};cb={f:[] for f in FIELDS}
    paired=0;failed_pairs=0;exact=0;slots=0;eligible_count=0;context_count=0;positive_identity=collections.Counter()
    for item,text,author,author_qid,raw in rows:
        mentions=json.loads(raw)
        _,mapping=bundle_slots(text,author,author_qid,mentions)
        eligible=eligible_slots(mapping,mentions,author_qid)
        x=primary.get(item);y=secondary.get(item)
        x_ok=x is not None and not x['errors'];y_ok=y is not None and not y['errors']
        xl=field_labels(x['rows'],mapping) if x_ok else None
        if x_ok and y_ok:
            yl=field_labels(y['rows'],mapping);paired+=1
            eligible_count+=len(eligible);context_count+=len(set(mapping.values())-eligible)
            for f in FIELDS:
                for slot in sorted(eligible):
                    a[f].append(xl[f][slot]);b[f].append(yl[f][slot])
                    if 'stated' in xl['proposition_status'][slot] and 'stated' in yl['proposition_status'][slot]:
                        ca[f].append(xl[f][slot]);cb[f].append(yl[f][slot])
            for slot in eligible:
                xi=xl['speaker_identity'][slot];yi=yl['speaker_identity'][slot]
                positive_identity['both']+=xi and yi;positive_identity['primary']+=xi;positive_identity['secondary']+=yi
            slots+=len(mapping)
        else:failed_pairs+=1
        if item in repeat_ids:
            z=repeated.get(item)
            if x_ok and z is not None and not z['errors']:
                zl=field_labels(z['rows'],mapping)
                for f in FIELDS:same[f]+=xl[f]==zl[f]
                exact+=canonical_output(x['rows'])==canonical_output(z['rows'])
    metrics={}
    for f in FIELDS:
        result=kappa(a[f],b[f]);det=same[f]/len(repeat_ids) if repeat_ids else None
        conditional=kappa(ca[f],cb[f])
        gate_kappa=conditional['kappa'] if f in {'mode','function','authority_cue','relation'} else result['kappa']
        result.update(repeat_identical=same[f],repeat_denominator=len(repeat_ids),determinism=det,
          conditional_jointly_stated=conditional,kappa_for_gate=gate_kappa,
          publication_level=publication_level(gate_kappa,grounding,det,synthetic_passed))
        metrics[f]=result
    denominator=positive_identity['primary']+positive_identity['secondary']
    return dict(fields=metrics,paired_valid_windows=paired,failed_or_missing_pairs=failed_pairs,
      positive_speaker_agreement=2*positive_identity['both']/denominator if denominator else None,
      whole_output_repeat_identical=exact,whole_output_repeat_share=exact/len(repeat_ids) if repeat_ids else None,
      repeat_windows=len(repeat_ids),candidate_slots_before_alias_collapse=slots,
      eligible_candidate_observations=eligible_count,excluded_context_observations=context_count,
      all_required_determinism_passed=all(metrics[f]['determinism'] is not None and metrics[f]['determinism']>=.95 for f in FIELDS))

def main():
    con=connect();selection=json.loads((workdir()/'model_selection.json').read_text(encoding='utf-8'))
    if selection['corpus_sha256']!=CORPUS_HASH or selection['config_hash']!=CONFIG_HASH:raise RuntimeError('Stale model selection')
    primary=selection['primary'];secondary=selection['comparator']
    if not primary:raise RuntimeError('Preliminary model gate has not passed')
    pin_stage(con,'actual_agreement_v1',dict(code=file_sha(__file__),metrics=file_sha(STUDY/'agreement_metrics.py'),
      primary=primary,secondary=secondary,agreement_windows=2000,repeat_windows=1000))
    rows=con.execute('''SELECT c.item_id,c.text,c.author,c.author_qid,c.mentions_json FROM agreement_sample s
      JOIN candidates c USING(item_id) ORDER BY c.item_id''').fetchall()
    repeat_ids={r[0] for r in con.execute('SELECT item_id FROM repeatability_sample').fetchall()}
    assert len(rows)==2000 and len(repeat_ids)==1000
    run='actual_validation_v1'
    run_model(con,run,primary,rows,0)
    run_model(con,run,secondary,rows,0)
    run_model(con,run,primary,[r for r in rows if r[0] in repeat_ids],1)
    x=final_results(con,run,primary,0);y=final_results(con,run,secondary,0);z=final_results(con,run,primary,1)
    primary_quality=call_quality(con,run,primary,0);secondary_quality=call_quality(con,run,secondary,0)
    synthetic=json.loads((workdir()/('synthetic_'+VERSION+'_'+primary.replace(':','_')+'_report.json')).read_text(encoding='utf-8'))
    outcome=analyse(rows,x,y,z,repeat_ids,primary_quality['grounding_failure_share'],synthetic['synthetic_gate_passed'])
    field_levels={f:r['publication_level'] for f,r in outcome['fields'].items()}
    # Comparable valid pairs must cover at least 98% of the requested sample;
    # comparator failures cannot quietly remove hard cases from the agreement.
    paired_coverage=outcome['paired_valid_windows']/2000
    if paired_coverage<.98:
        for f in outcome['fields']:outcome['fields'][f]['publication_level']='withdrawn'
        field_levels={f:'withdrawn' for f in FIELDS}
    derived=derived_levels(outcome['fields'])
    main_allowed=outcome['all_required_determinism_passed'] and any(v in {'B','C'} for v in derived.values()) and paired_coverage>=.98
    report=dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      primary=primary,comparator=secondary,primary_quality=primary_quality,comparator_quality=secondary_quality,
      paired_coverage=paired_coverage,main_authorized=bool(main_allowed),field_levels=field_levels,derived_levels=derived,**outcome,
      caveat='Agreement conditional on shared source candidates and machine identities; neither model is truth. Only contemporary linked candidates, organizations and eligible linked AUTHOR enter agreement gates; historical/sacred/unresolved context cannot inflate agreement. Mode/function/authority/relation gates use jointly stated eligible slots, so shared absences cannot validate their content. Presence/proposition gates use all eligible slots. Repeatability still requires stable complete field outputs. No precision/recall estimate. Failed windows are counted, not coded as no speech. Degenerate kappa is uninformative and withdraws the field.')
    atomic_json_stable(workdir()/'model_agreement_report.json',report);con.execute('CHECKPOINT');con.close()
    print(json.dumps(dict(main_authorized=main_allowed,field_levels=field_levels,paired_coverage=paired_coverage)))
    if not outcome['all_required_determinism_passed']:raise SystemExit('Repeatability gate failed; fix/version the configuration before main coding.')

if __name__=='__main__':main()
