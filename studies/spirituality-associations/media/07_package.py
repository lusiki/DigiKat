"""Package only aggregate tables and scientific figures after verification."""
from pathlib import Path
import sys,json,zipfile,importlib.metadata,platform,hashlib
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from common import ROOT,TABLES,FIGURES,dump_json,sha
T=TABLES/'media-v1';F=FIGURES/'media-v1'
def main():
    verified=json.loads((T/'verification.json').read_text());assert all(x['passed'] for x in verified['checks'])
    dump_json(T/'environment.json',{'python':platform.python_version(),'platform':platform.platform(),
        'packages':{k:importlib.metadata.version(k) for k in ['duckdb','pandas','numpy','matplotlib','scikit-learn','scipy','pyahocorasick','reportlab','pypdf','pymupdf']},
        'scripts':{p.name:sha(p) for p in (ROOT/'media').glob('*.py')}})
    target=ROOT.parents[1]/'output/spirituality-associations-media-landscape-supplement.zip'
    paths=sorted(list(T.glob('*.csv'))+list(T.glob('*.json'))+list(F.glob('*.png'))+list(F.glob('*.svg')))
    readme='''Spirituality-related associations: full-period exploratory media landscape
Study period: 1 January 2021 to 10 September 2026 (2026 partial).
Source: 42,267,474 records in the supplied read-only merged DetermDB snapshot.

This supplement contains aggregate tables, methods/provenance diagnostics and
ten scientific figures in PNG and SVG. The PDF report is delivered separately.
Candidate records and pairs are unresolved name-search observations, not verified
editorial coverage. No human frame, stance or precision estimates are supplied.

Start with annual_landscape.csv, summary.json, county_landscape.csv,
platform_landscape.csv and sensitivity.csv. monthly_landscape.csv preserves
date/platform scope; common_domain_panel.csv provides a common-source sensitivity.
Rates use raw candidate records / raw monitored records within the same scope.
The measured collection regime changes in January 2024.

Model topic shares are exploratory assignments, not coded frame prevalence.
See topic_model_runs.csv, topic_terms.csv, topic_shares.csv and topic_audit.json.
Human review remains uncompleted. The blank review-queue design is preparation only.

Reproduction scripts and detailed definitions are in the repository under
studies/spirituality-associations/media/. The private directory and all 1,325
organisation rows are retained locally under output/private/media/v1/ and are
intentionally excluded from this aggregate bundle. No article URLs, vendor text,
titles, item identifiers or personal contact information are included here.
'''
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as z:
        z.writestr('README.txt',readme)
        for p in paths:z.write(p,('tables/' if p.parent==T else 'figures/')+p.name)
        z.writestr('SHA256SUMS.txt','\n'.join(sha(p)+'  '+('tables/' if p.parent==T else 'figures/')+p.name for p in paths))
    print(target, target.stat().st_size,'bytes;',len(paths),'aggregate files')
if __name__=='__main__':main()
