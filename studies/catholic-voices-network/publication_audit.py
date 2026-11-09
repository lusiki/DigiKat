"""Audit primitives; zero observed contradictions never establishes accuracy."""
import re


def death_status(facts,date):
    if not date or not re.fullmatch(r'\d{4}-\d{2}-\d{2}',date):return 'missing_document_date'
    if not facts:return 'identity_facts_missing'
    deaths=[bound for f in facts for bound in f.get('death',[])]
    if any(date>b[1] for b in deaths):return 'after_recorded_death'
    if any(b[0]<=date<=b[1] for b in deaths):return 'death_date_uncertain'
    if deaths:return 'before_recorded_death'
    if any(f.get('death_recorded') for f in facts):return 'unparsed_recorded_death'
    return 'no_recorded_death'


def withdrawn_checks(model_gate):
    if model_gate['primary_synthetic_pass_exists'] or model_gate['main_authorized']:
        raise RuntimeError('A qualified model requires the actual-passage audit route; cannot reuse the withdrawal route')
    if any(v!='withdrawn' for v in model_gate['publication_levels'].values()):
        raise RuntimeError('Incomplete model withdrawal decision')
    return {
      'M-AG-1':dict(status='not_run',reason='No evaluated primary configuration passed the constructed prerequisite; no actual-passage kappa is available.'),
      'M-ST-1':dict(status='not_run',reason='Actual-passage repeatability follows the failed preliminary prerequisite.'),
      'M-AG-2':dict(status='not_applicable',reason='No qualified training labels; no classifier was trained or evaluated.'),
      'M-ROB-1':dict(status='not_applicable',reason='The speaks layer is withdrawn; there is no publishable speaks edge list to perturb. Mention graphs cannot substitute for it.'),
      'M-ROB-2':dict(status='not_applicable',reason='No qualified model tier exists, so rule-versus-rule-union-model rankings cannot be compared. Rule outputs remain private diagnostics.'),
      'S6':dict(status='omitted',reason='Optional first-edition module; no qualified proposition summaries exist.')}
