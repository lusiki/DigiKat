"""Constructed full-document integration smoke, never an empirical result."""
import argparse,importlib,json,os,subprocess,tempfile
from pathlib import Path
from voices_common import STUDY,ROOT,CORPUS_HASH,CONFIG_HASH


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--render',action='store_true');args=parser.parse_args()
    fixture_dir=STUDY/'output/private/figure-smoke'
    if not (fixture_dir/'constructed_figure_data.json').exists():raise RuntimeError('Run verify_report_figures.R first')
    data=json.loads((fixture_dir/'constructed_figure_data.json').read_text(encoding='utf-8'))
    network=json.loads((fixture_dir/'constructed_network_report.json').read_text(encoding='utf-8'))
    data['synthetic_fixture']=True
    data['presentation']=dict(report_title='Konstruirana provjera izvještaja',report_date='2026-10-25',
      corpus_period='Konstruirani datumi',corpus_sha_short='konstruirani-podatci',legacy_invalid_json=10,legacy_invalid_json_at_limit=10)
    data['constants'].update(era_split='2024-01-01',minimum_speech_chars=300,d6_documents=20,d6_sources=3,
      minimum_cell=5,ner_proxy_threshold=.9,cluster_change_threshold=.05)
    data['constants'].update(form_context_limit=3,public_link_limit=1500,author_threshold=.85,
      agreement_main=.7,agreement_appendix=.5,repeat_threshold=.95,grounding_failure_limit=.02)
    data['values']['corpus']=dict(documents=84,platforms=2,short_documents=4)
    data['values']['scope']=dict(eligible_people=8,documents_with_public_person=80,parsed_rule_sentences=80)
    data['values']['name_forms']=dict(forms=71,statuses=dict(agreed=60,ambiguous=8,unaligned=3))
    data['values']['public_name_linkage']=dict(selected=71,statuses=dict(linked=20,unresolved=48,ambiguous=3),linked=20,without_accepted_link=51)
    data['values']['role_cues']=[dict(cue_class='clergy',spans=20,documents=15)]
    for p in data['values']['platforms']:p.update(long_documents=p['documents'],unique_texts=p['documents'])
    for p in data['values']['people']:p.update(outlets=40,platforms=1,mention_spans=40)
    data['values']['circulation']=[dict(threshold=n,families=80,repeated_families=0,excess_appearances=4,cross_platform_families=0) for n in [.8,.85,.9]]
    evidence=data['evidence'];evidence['mention_network_report']=network
    evidence['office_coverage_report']=dict(matched_titles=0,active_directory_entries=1,maximum_tenure_years=110,
      coverage=[dict(role='Konstruirana složena služba',matched=False)])
    evidence['gazetteer_report']=dict(platforms=[dict(platform='web',gazetteer_hits=40,ner_overlap=35,lower_bound_label=True)])
    evidence['cluster_report']=dict(top_entities=8,shifted_over_five_percent=8,report_ranges=True)
    evidence['speech_rule_report']=dict(author_recovery=[dict(platform='facebook',eligible=10,recovered=9)])
    audit=evidence['publication_audit'];audit.update(level_b='withdrawn',benchmark_database_reconciliation=[])
    codes=['M-GR-1','M-GR-2','M-GR-3','M-GR-4','M-ID-1','M-ID-2','M-ID-3','M-ID-4','M-REC-1','M-SP-1','M-AG-1','M-ST-1','M-AG-2','M-ROB-1','M-ROB-2']
    audit['checks']={code:dict(check_id=code) for code in codes}
    audit['checks']['M-ID-2'].update(direct_statements=40,violations=0)
    audit['checks']['M-ID-1'].update(resolved_papal_titles=10,violations=0)
    audit['checks']['M-ID-4'].update(pairs=500)
    for config in evidence['model_gate_summary']['configurations']:
        config.update(cases=54,synthetic_gate_passed=False,benchmark=None)
        if config['protocol']=='v4' and config['model'].startswith('qwen'):
            config['benchmark']=dict(n=300,json_valid_first=1.0,mechanically_accepted_first=.9,final_failed=30,effective_seconds_per_window=3.0)
            audit['benchmark_database_reconciliation'].append(dict(model=config['model'],calls=330,mechanical_failures=60,mechanical_failure_share=60/330))
    destination=STUDY/'output/private/report-narrative-smoke';destination.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='digikat-report-data-smoke-') as folder:
        path=Path(folder)/'report_data.json';path.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
        saved=destination/'constructed_report_data.json';saved.write_bytes(path.read_bytes())
        env={**os.environ,'DIGIKAT_VOICES_WORKDIR':folder,'DIGIKAT_VOICES_REPORT_DIR':str(destination),
             'LC_ALL':'English_United States.utf8','PYTHONUTF8':'1'}
        subprocess.run(['C:/Program Files/R/R-4.6.0/bin/Rscript.exe','--vanilla',str(STUDY/'81_report_figures.R')],cwd=ROOT,env=env,check=True)
    from report_narrative import generate
    from report_contract import assemble
    figures=json.loads((destination/'figures_manifest.json').read_text(encoding='utf-8'))
    registry=generate(data,saved,destination,figures)
    text,usage=assemble((STUDY/'REPORT_TEMPLATE.qmd').read_text(encoding='utf-8'),registry,destination)
    assert 'Konstruirana provjera izvještaja' in text and 'OVI BROJEVI NISU REZULTATI' in text
    assert '| Nedostatno poravnanje ili izostala lema | <5 |' in text
    assert '| Prihvaćena veza s javnim identitetom | 20 |' in text
    assert '| Bez prihvaćene veze | 51 |' in text
    assert len(usage['used_figures'])==10 and len(usage['used_fragments'])==10
    registry_path=destination/'report_registry.json';registry_path.write_text(json.dumps(registry,ensure_ascii=False,indent=2),encoding='utf-8')
    subprocess.run([os.sys.executable,str(STUDY/'85_assemble_report.py'),str(registry_path)],cwd=ROOT,check=True)
    if args.render:
        subprocess.run(['C:/Python314/python.exe',str(STUDY/'86_render_report.py'),str(registry_path),'--preview'],cwd=ROOT,check=True)
    print('Constructed narrative and table registry verified:',destination)


if __name__=='__main__':main()
