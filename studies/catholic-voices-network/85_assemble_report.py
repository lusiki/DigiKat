"""Assemble only completed/explicitly withheld sections with verified evidence."""
import argparse,json,os
from pathlib import Path
from report_contract import assemble,sha
STUDY=Path(__file__).resolve().parent

def atomic_text(path,text):
    path=Path(path);temporary=path.with_suffix(path.suffix+'.tmp')
    with temporary.open('w',encoding='utf-8',newline='\n') as f:
        f.write(text);f.flush();os.fsync(f.fileno())
    os.replace(temporary,path)

def main():
    parser=argparse.ArgumentParser();parser.add_argument('registry',type=Path);args=parser.parse_args()
    registry=json.loads(args.registry.read_text(encoding='utf-8'));base=args.registry.parent
    template=STUDY/'REPORT_TEMPLATE.qmd'
    output,usage=assemble(template.read_text(encoding='utf-8'),registry,base)
    target=base/'tko-govori-o-vjeri.qmd';atomic_text(target,output)
    atomic_text(base/'claims.json',json.dumps(registry['claims'],ensure_ascii=False,indent=2))
    checks=dict(registry_sha256=sha(args.registry),template_sha256=sha(template),qmd_sha256=sha(target),
      claims_sha256=sha(base/'claims.json'),evidence_and_generation_passed=True,**usage,
      remaining='Final page/encoding/HTML checks and visual review are required after rendering.')
    atomic_text(base/'report_assembly_checks.json',json.dumps(checks,ensure_ascii=False,indent=2))
    print(json.dumps(checks))

if __name__=='__main__':main()
