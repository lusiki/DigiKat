"""Required public byproducts, with source texts and private accounts excluded."""
import csv,io,json,importlib
from voices_common import *
from public_exports import safe_alias,public_edges,office_in_period
from office_register import read_cache,date_bounds,value
from aggregate_exports import export_platform_coverage
atomic_text=importlib.import_module('85_assemble_report').atomic_text


def main():
    report_path=workdir()/'report_data.json';data=json.loads(report_path.read_text(encoding='utf-8'))
    if data['corpus_sha256']!=CORPUS_HASH or data['config_hash']!=CONFIG_HASH:raise RuntimeError('Wrong release provenance')
    if data['evidence']['publication_audit']['level_a_identity_gate']!='passed':raise RuntimeError('Publication audit required')
    if data.get('synthetic_fixture'):raise RuntimeError('Constructed fixtures cannot generate actual public byproducts')
    allowed={p['entity_id']:p['public_name'] for p in data['values']['people']}
    con=connect()
    db_allowed={row[0] for row in con.execute('SELECT entity_id FROM network_people WHERE d6').fetchall()}
    if set(allowed)!=db_allowed:raise RuntimeError('D6 evidence changed')
    rows=con.execute('''SELECT r.qid,f.surface,count(DISTINCT r.doc_id) AS documents
      FROM resolved_mentions r JOIN form_mentions m ON r.doc_id=m.doc_id AND r.start_char=m.start_char AND r.end_char=m.end_char
      JOIN forms f USING(form_id) JOIN form_lemmas l USING(form_id)
      JOIN network_people n ON n.entity_id=r.qid AND n.d6
      WHERE r.origin='ner' AND r.life_class='contemporary' AND l.status='agreed'
      GROUP BY r.qid,f.surface HAVING count(DISTINCT r.doc_id)>=5 ORDER BY r.qid,f.surface''').fetchall()
    aliases=[dict(entity_qid=qid,canonical_name=allowed[qid],surface_form=surface,documents=documents)
      for qid,surface,documents in rows if safe_alias(surface)]
    con.close()
    snapshot_path=workdir()/'office_register.json';snapshot=json.loads(snapshot_path.read_text(encoding='utf-8'))
    if snapshot['corpus_sha256']!=CORPUS_HASH or snapshot['config_hash']!=CONFIG_HASH:raise RuntimeError('Wrong office snapshot')
    frozen_hash=data['evidence']['office_coverage_report']['register_sha256']
    if file_sha(snapshot_path)!=frozen_hash:raise RuntimeError('Office source differs from audited snapshot')
    entities,_,_=read_cache(workdir()/'public_register_cache')
    offices=[]
    for row in sorted(snapshot['offices'],key=lambda x:(x['office_qid'],x['entity_qid'],x['statement_id'])):
        if not office_in_period(row):continue
        original=next((claim for claim in entities.get(row['entity_qid'],{}).get('claims',{}).get('P39',[]) if claim.get('id')==row['statement_id']),None)
        if original is None:raise RuntimeError('Public source statement missing for release')
        ends=[date_bounds(value(s)) for s in original.get('qualifiers',{}).get('P582',[])];ends=[x for x in ends if x]
        end_kind='office_end' if len(ends)==1 else 'death_upper_bound' if row['end_latest'] else 'open'
        offices.append({key:row[key] for key in ['statement_id','entity_qid','name','office_qid','office_label_hr',
          'start_earliest','start_latest','end_earliest','end_latest']}|
          dict(place_qids=';'.join(p['qid'] for p in row['places']),end_basis=end_kind,source_public_page=row['source']))
    tables={
      'offices.csv':(offices,['statement_id','entity_qid','name','office_qid','office_label_hr','place_qids','start_earliest','start_latest','end_earliest','end_latest','end_basis','source_public_page']),
      'aliases_public.csv':(aliases,['entity_qid','canonical_name','surface_form','documents'])}
    for kind,network in data['evidence']['network_metrics']['networks'].items():
        tables['mention_'+kind+'_edges.csv']=(public_edges(network,allowed),['from_qid','to_qid','shared_contexts','independent_documents'])
    destination=STUDY/'data/public';destination.mkdir(parents=True,exist_ok=True);files={}
    for name,(rows,fields) in tables.items():
        # Formula-looking public strings remain literal CSV data; names are not
        # copied into spreadsheets by this exporter.
        output=io.StringIO(newline='');writer=csv.DictWriter(output,fieldnames=fields,lineterminator='\n')
        writer.writeheader();writer.writerows(rows);atomic_text(destination/name,output.getvalue())
        files[name]=dict(rows=len(rows),sha256=file_sha(destination/name),columns=fields)
    aggregate_parquet=export_platform_coverage(data,STUDY/'output/platform_coverage.parquet')
    manifest=dict(corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,report_data_sha256=file_sha(report_path),
      office_register_sha256=frozen_hash,code_sha256=file_sha(__file__),rules_sha256=file_sha(STUDY/'public_exports.py'),files=files,
      aggregate_parquet=aggregate_parquet,
      scope='Machine-derived public metadata and D6 aggregate mention edges. No source passages, document IDs, private account identifiers or speech claims.',
      office_limitations='Incomplete public office coverage; only usable dated claims potentially overlapping 2021–2026 and the documented maximum-tenure bound. Open ends are not proof of current office. Death bounds are distinguished from office-end dates.',
      alias_limitations='Only agreed morphological forms with at least five distinct contemporary documents and short multiword name shape. Other forms remain private; this is not a verified complete alias dictionary.',
      network_limitations='Only D6 endpoints; ties supported by fewer than five contexts or paragraph-document units omitted. These release edges differ from the full internal backbone. They do not express speech, support or influence.')
    atomic_json(destination/'release_manifest.json',manifest)
    atomic_text(destination/'README.md','''# Public byproducts of the Catholic voices/network study

These files contain machine-derived public metadata and aggregates. They are not human-validated identities, speech labels or evidence of influence. The full analysis settings and limitations are in the study README, CODEBOOK and report.

- `offices.csv`: dated public office statements potentially overlapping the study period. Date precision is preserved as earliest/latest bounds. `end_basis` distinguishes an office-end qualifier from a death upper bound and an open end. Coverage is incomplete; an open end does not prove current office. Public-register names are source metadata, not claims that those people occur in the corpus.
- `aliases_public.csv`: short, morphologically agreed multiword forms for the frozen D6 population, each supported by at least five contemporary documents. Rare, ambiguous, title-only and non-name-shaped forms are omitted. Counts are per form and must not be summed to infer distinct documents for a person.
- `mention_outlets_edges.csv`: pairs of D6 public identities sharing statistically retained source contexts. Counts refer to distinct internal sources; no private source identifiers are exported.
- `mention_paragraphs_edges.csv`: pairs sharing retained paragraph contexts, with distinct supporting document counts. Low-support ties are omitted from both lists. The exported graph is therefore a disclosure-filtered subset of the internal graph used for community calculations.
- `../../output/platform_coverage.parquet`: identity-free platform totals and the document-length eligibility split. A small cell suppresses its full column family across platforms, including both sides of the eligibility split. This prevents reconstruction from row or corpus totals. The manifest records the schema, hash and disclosure implementation.

No source passages, row-level document identifiers, private accounts or attributed speech are included. The release manifest records file hashes, column allowlists and the source evidence hashes. A future release must be re-audited against its own frozen corpus and settings.
''')
    atomic_json_stable(workdir()/'public_byproducts_report.json',dict(created_utc=utc(),corpus_sha256=CORPUS_HASH,config_hash=CONFIG_HASH,
      release_manifest_sha256=file_sha(destination/'release_manifest.json'),files=files,aggregate_parquet=aggregate_parquet,completed=True))
    print('Public aggregate byproducts prepared; repository disclosure scan and completion audit remain required.')


if __name__=='__main__':main()
