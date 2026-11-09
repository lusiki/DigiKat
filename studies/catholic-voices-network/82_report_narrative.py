"""Create registered Croatian narrative only from complete saved report evidence."""
import argparse,importlib,json
from pathlib import Path
from voices_common import workdir,STUDY,CORPUS_HASH,CONFIG_HASH
from report_contract import sha,assemble
from report_narrative import generate
atomic_text=importlib.import_module('85_assemble_report').atomic_text


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--data',type=Path);parser.add_argument('--output',type=Path);args=parser.parse_args()
    source=args.data or workdir()/'report_data.json';base=args.output or STUDY/'output/private/report'
    data=json.loads(source.read_text(encoding='utf-8'))
    if data['corpus_sha256']!=CORPUS_HASH or data['config_hash']!=CONFIG_HASH:raise RuntimeError('Wrong report provenance')
    audit=data['evidence']['publication_audit']
    if audit['level_a_identity_gate']!='passed' or audit['level_b']!='withdrawn':raise RuntimeError('Narrative route requires completed Level-A audit and explicit model withdrawal')
    figures=json.loads((base/'figures_manifest.json').read_text(encoding='utf-8'))
    if figures['report_data_sha256']!=sha(source):raise RuntimeError('Figures belong to different report evidence')
    registry=generate(data,source,base,figures)
    assemble((STUDY/'REPORT_TEMPLATE.qmd').read_text(encoding='utf-8'),registry,base)
    atomic_text(base/'report_registry.json',json.dumps(registry,ensure_ascii=False,indent=2))
    print('Croatian fragments, evidence-linked tables and claims registry saved; final rendering and review remain required.')


if __name__=='__main__':main()
