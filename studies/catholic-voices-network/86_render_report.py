"""Quarto/Typst render after evidence gates; final visual inspection remains explicit.

Use the local reporting Python with PyMuPDF and Pillow. This never publishes a
website or sends corpus data anywhere.
"""
import argparse,importlib,json,re,shutil,subprocess,tempfile
from pathlib import Path
from report_contract import assemble,sha,FOOTER
from check_pdf import check
atomic_text=importlib.import_module('85_assemble_report').atomic_text
STUDY=Path(__file__).resolve().parent
QUARTO=Path('C:/Program Files/Quarto/bin/quarto.exe')

def main():
    parser=argparse.ArgumentParser();parser.add_argument('registry',type=Path);parser.add_argument('--preview',action='store_true');args=parser.parse_args()
    registry=json.loads(args.registry.read_text(encoding='utf-8'));base=args.registry.parent
    saved=json.loads((base/'report_assembly_checks.json').read_text(encoding='utf-8'))
    source=base/'tko-govori-o-vjeri.qmd';template=STUDY/'REPORT_TEMPLATE.qmd'
    if saved['registry_sha256']!=sha(args.registry) or saved['qmd_sha256']!=sha(source) or saved['template_sha256']!=sha(template):
        raise RuntimeError('Report assembly is stale')
    reconstructed,_=assemble(template.read_text(encoding='utf-8'),registry,base)
    if source.read_text(encoding='utf-8')!=reconstructed:raise RuntimeError('Report differs from registered fragments')
    version=subprocess.check_output([str(QUARTO),'--version'],text=True).strip()
    if version!='1.9.38':raise RuntimeError('Pinned Quarto 1.9.38 required')
    build=Path(tempfile.mkdtemp(prefix='digikat-voices-report-'))
    for path in (STUDY/'typeset').iterdir():
        if path.is_file():shutil.copy2(path,build/path.name)
    shutil.copy2(STUDY/'refs.bib',build/'refs.bib')
    for figure in registry.get('figures',{}).values():
        relative=Path(figure['path'])
        if relative.is_absolute() or '..' in relative.parts:raise RuntimeError('Figure must be inside report directory')
        target=build/relative;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(base/relative,target)
    stem='tko-govori-o-vjeri'+('-preview' if args.preview else '')
    (build/(stem+'.qmd')).write_text(reconstructed,encoding='utf-8')
    for fmt in ['html','typst']:
        result=subprocess.run([str(QUARTO),'render',stem+'.qmd','--to',fmt],cwd=build,capture_output=True,text=True,encoding='utf-8')
        atomic_text(base/(stem+'-'+fmt+'.log'),result.stdout+'\n'+result.stderr)
        if result.returncode:raise RuntimeError('Render failed: '+fmt+'; inspect saved log')
    html=(build/(stem+'.html')).read_text(encoding='utf-8')
    if len(re.findall(r'<h1(?:\s|>)',html))!=1:raise RuntimeError('HTML must have one document H1')
    if FOOTER not in html:raise RuntimeError('HTML lacks the machine-only notice')
    if any(c not in html for c in 'čćžšđ'):raise RuntimeError('Check Croatian HTML encoding')
    if len(re.findall(r'<img(?:\s|>)',html))!=len(registry.get('figures',{})):
        raise RuntimeError('HTML figure count differs from registry')
    pdf=build/(stem+'.pdf');qa=base/'qa'/sha(pdf)[:16]
    pdf_result=check(pdf,qa,final=not args.preview)
    for extension in ['html','pdf']:
        target=base/(stem+'.'+extension);temporary=target.with_suffix('.'+extension+'.tmp')
        shutil.copy2(build/target.name,temporary);temporary.replace(target)
    checks=dict(registry_sha256=sha(args.registry),qmd_sha256=sha(source),
      pdf_sha256=sha(base/(stem+'.pdf')),html_sha256=sha(base/(stem+'.html')),
      quarto=version,preview=args.preview,pages=pdf_result['pages'],mechanical_pass=True,
      qa_directory=str(qa.relative_to(base)),visual_review='pending',ready_for_delivery=False,
      note='Inspect every final page and HTML layout, record the reviewed PDF/HTML hashes, then run the full completion audit.')
    atomic_text(base/(stem+'-render_checks.json'),json.dumps(checks,ensure_ascii=False,indent=2));print(json.dumps(checks))

if __name__=='__main__':main()
