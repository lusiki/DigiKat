"""Deliver edited public reports, slides, editable sources and separate QA."""
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,zipfile
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2]
OUT=ROOT/'output/demokrscanstvo-izvjestaji-i-prezentacija';OUT.mkdir(exist_ok=True)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
def cp(src,dest):
    dest=OUT/dest;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/src,dest)
for stem in ['demokrscanstvo-u-medijskom-prostoru','demokrscanstvo-od-rijeci-do-argumenta','demokrscanstvo-12-nalaza']:
    cp(f'assets/izvjestaji/{stem}.pdf',f'javno/{stem}.pdf')
    html=ROOT/f'assets/izvjestaji/{stem}.html'
    if html.exists():cp(str(html.relative_to(ROOT)),f'javno/{stem}.html')
shutil.copytree(ROOT/'output/demokrscanstvo-text-public/v1',OUT/'izvor-analize-jezika',ignore=shutil.ignore_patterns('internal'),dirs_exist_ok=True)
# Separate verification from public publication sources in the combined package.
shutil.copytree(ROOT/'output/demokrscanstvo-text-public/v1/internal',OUT/'interna-provjera/analiza-jezika',dirs_exist_ok=True)
for name in ['build.py','slides.json','style.css','presentation.js']:
    cp(f'studies/demokrscanstvo-barometar/presentation/{name}',f'izvor-prezentacije/source/{name}')
for name in ['word-clouds.csv','selected-words.csv','topics.csv','phrases.csv']:
    cp(f'output/demokrscanstvo-text-public/v1/tables/{name}',f'izvor-prezentacije/tables/{name}')
cp('data/barometar/demokrscanstvo-multiplatform/v1/platforms.csv','izvor-prezentacije/tables/platforms.csv')
cp('data/barometar/demokrscanstvo-themes/v1/summary.json','izvor-prezentacije/tables/publication-topics.json')
for key in ['all','t02','t03','t06','t08']:
    cp(f'output/demokrscanstvo-text-public/v1/figures/cloud-{key}.svg',f'izvor-prezentacije/figures/cloud-{key}.svg')
subprocess.run([sys.executable,'-X','utf8',str(OUT/'izvor-prezentacije/source/build.py')],check=True)
assert sha(OUT/'izvor-prezentacije/demokrscanstvo-12-nalaza.html')==sha(OUT/'javno/demokrscanstvo-12-nalaza.html')
for name in ['build.py','README.md']:
    cp(f'studies/demokrscanstvo-barometar/public-report/{name}',f'izvor-pregleda/{name}')
for name in ['verification.json','claim-register.json','browser-verification.json']:
    cp(f'output/demokrscanstvo-presentation/{name}',f'interna-provjera/prezentacija/{name}')
cp('output/demokrscanstvo-public/v2/qa.json','interna-provjera/pregled/qa.json')
cp('output/demokrscanstvo-public/v2/claim_sources.json','interna-provjera/pregled/claim_sources.json')
cp('studies/demokrscanstvo-barometar/presentation/website-copy.md','tekst-za-mreznu-stranicu.md')
cp('quality_reports/2026-09-19_demokrscanstvo-publication-verification.md','interna-provjera/provjera-publikacija.md')
(OUT/'README.md').write_text('''# Demokršćanstvo: izvještaji i prezentacija

Autor: [Luka Šikić](https://www.lukasikic.info/). Izdanje: 19. rujna 2026.

- `javno/`: dva izvještaja i prezentacija, s PDF i raspoloživim HTML izdanjima.
- `izvor-analize-jezika/manuscript.md`: uređivi rukopis novog izvještaja. `source/build.py` ga pretvara u PDF i HTML uz priložene zbirne tablice (Python, ReportLab i fontovi Calibri/Georgia u sustavu Windows).
- `izvor-prezentacije/source/slides.json`: uređivi naslovi, tekstovi, citati i izvori svih slajdova. `build.py` sastavlja HTML iz priloženih zbirnih tablica. HTML se može i neposredno uređivati, čitati bez mreže i ispisati u PDF.
- `izvor-pregleda/`: uređivi Python izvor postojećeg izvještaja. Koristi ulaze projekta DigiKat navedene u README-u.
- `interna-provjera/`: provjere brojki, izvora, autora, poveznica, prijeloma i pristupačnosti, odvojene od javnih publikacija.
- `tekst-za-mreznu-stranicu.md`: kratak uvod i tri sažetka nalaza.

U HTML prezentaciji gumb „Prikaži slajdove” uključuje prikaz jednog slajda. Strelice mijenjaju slajd, a Escape vraća prikaz za čitanje. Mrežne poveznice trebaju internetsku vezu. Brojevi objava i različitih tekstova imaju zasebne nazivnike opisane u publikacijama.
''',encoding='utf-8')
manifest={str(p.relative_to(OUT)).replace('\\','/'):sha(p) for p in OUT.rglob('*') if p.is_file() and p.name!='manifest.json'}
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
target=ROOT/'output/demokrscanstvo-izvjestaji-i-prezentacija.zip'
with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(OUT.rglob('*')):
        if p.is_file():z.write(p,str(p.relative_to(OUT)).replace('\\','/'))
with zipfile.ZipFile(target) as z:assert z.testzip() is None
print(json.dumps({'package':str(target),'bytes':target.stat().st_size,'portable_html':'byte-identical','files':len(manifest)},ensure_ascii=False))
