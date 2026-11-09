"""Fail-closed artifact checks; visual review must match the actual final files."""
import hashlib,json,re
from report_contract import sha


def require_document_coverage(con,tables,expected_total):
    """Equal row counts cannot hide a missing document and an unexpected ID."""
    reference,distinct=con.execute('SELECT count(*),count(DISTINCT doc_id) FROM docs').fetchone()
    if reference!=expected_total or distinct!=expected_total:
        raise ValueError('Corpus document reference is incomplete or has duplicate/null IDs')
    coverage={}
    for table in tables:
        if not re.fullmatch(r'[a-z_][a-z0-9_]*',table):raise ValueError('Invalid coverage table name')
        count=con.execute('SELECT count(*) FROM '+table).fetchone()[0]
        if count!=expected_total:raise ValueError('Incomplete full-corpus table: '+table)
        missing=con.execute('SELECT count(*) FROM docs ANTI JOIN '+table+' USING(doc_id)').fetchone()[0]
        unexpected=con.execute('SELECT count(*) FROM '+table+' ANTI JOIN docs USING(doc_id)').fetchone()[0]
        if missing or unexpected:raise ValueError('Document IDs differ from corpus: '+table)
        coverage[table]=count
    return coverage


def require_pinned_files(settings,contracts):
    """Check current files against database pins, without opening a database."""
    indexed={}
    for stage,digest,raw in settings:
        if stage in indexed or hashlib.sha256(raw.encode('utf-8')).hexdigest()!=digest:
            raise ValueError('Duplicate or damaged stage pin: '+stage)
        indexed[stage]=json.loads(raw)
    evidence={}
    for stage,files in contracts.items():
        if stage not in indexed:raise ValueError('Missing execution pin: '+stage)
        evidence[stage]={}
        for key,path in files.items():
            if not path.is_file():raise ValueError('Missing pinned file: '+str(path))
            digest=sha(path)
            if indexed[stage].get(key)!=digest:
                raise ValueError('Changed pinned file: '+stage+'/'+key+' '+str(path))
            evidence[stage][key]=dict(path=str(path),sha256=digest)
    return evidence


def execution_file_contracts(study,workdir):
    """Current qualified adapters; older rejected experiments are not required."""
    contracts={}
    for stage,adapter,reference,proof in [
      ('circulation_bulk_v1','circulation_bulk.py','15_circulation_v1.py','circulation_bulk_parity.json'),
      ('forms_bulk_v1','forms_bulk.py','20_forms_v1.py','forms_bulk_parity.json'),
      ('resolved_mentions_bulk_v1','resolution_bulk.py','24_resolve_mentions_v1.py','resolution_bulk_parity.json')]:
        contracts[stage]=dict(adapter_sha256=study/adapter,reference_sha256=study/reference,
                              proof_sha256=workdir/proof)
    contracts['gazetteer_parallel_v1']=dict(code_sha=study/'gazetteer_parallel.py',
      reference_sha=study/'11_gazetteer_recall_v1.py',parity_sha=workdir/'gazetteer_actual_parity.json')
    contracts['forms_morph_parallel_long_v1']=dict(wrapper_sha256=study/'forms_morph_parallel_long.py',
      parallel_code_sha256=study/'morphology_parallel.py',reference_sha256=study/'20_forms_v1.py',
      proof_sha256=workdir/'forms_morph_parallel_long_parity.json')
    contracts['candidate_runtime_profile_v1']=dict(code=study/'candidate_runtime_profile.py',
      reference=study/'25_prepare_candidates_v1.py',
      proof=study/'output/private/candidate_runtime_profile_fixture.json')
    contracts['rules_parallel_standard_v1']=dict(wrapper_sha256=study/'rules_parallel_standard.py',
      worker_sha256=study/'dependency_parallel.py',queue_sha256=study/'morphology_parallel.py',
      reference_sha256=study/'30_quote_rules_v1.py',verifier_sha256=study/'verify_rules_parallel_standard.py',
      proof_sha256=workdir/'rules_parallel_standard_parity.json')
    from pathlib import Path
    from dependency_memory import decoder
    contracts['rules_decoder_memory_v1']=dict(decoder_sha256=study/'dependency_memory.py',
      worker_sha256=study/'dependency_memory_parallel.py',wrapper_sha256=study/'rules_memory_safe.py',
      verifier_sha256=study/'verify_rules_memory_safe.py',
      proof_sha256=workdir/'rules_memory_safe_parity.json',
      reference_decoder_sha256=Path(decoder.__file__),
      original_parallel_proof_sha256=workdir/'rules_parallel_standard_parity.json')
    return contracts


def require_visual_review(render,review,pdf,html):
    if render.get('preview') or not render.get('mechanical_pass'):raise ValueError('Final mechanical render required')
    if not 25<=render['pages']<=35:raise ValueError('Final page count outside plan')
    hashes=dict(pdf_sha256=sha(pdf),html_sha256=sha(html))
    if any(render.get(k)!=v or review.get(k)!=v for k,v in hashes.items()):raise ValueError('Stale final artifact or visual review')
    if review.get('scope')!='actual_final_report':raise ValueError('Constructed preview is not final review')
    if sorted(review.get('reviewed_pages',[]))!=list(range(1,render['pages']+1)):
        raise ValueError('Every final PDF page must be visually reviewed')
    if not review.get('pdf_passed') or not review.get('html_passed') or review.get('unresolved_issues'):
        raise ValueError('Unresolved visual issues or missing HTML inspection')
    return hashes
