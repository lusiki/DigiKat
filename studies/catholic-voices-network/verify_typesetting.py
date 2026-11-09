"""Render an explicitly synthetic layout smoke, not a study report.

Run using the reporting Python with PyMuPDF/Pillow, independently of GPU stages.
"""
import json,shutil,subprocess,tempfile
from pathlib import Path
from check_pdf import check
STUDY=Path(__file__).resolve().parent
QUARTO=Path('C:/Program Files/Quarto/bin/quarto.exe')

def main():
    destination=STUDY/'output/private/report-smoke';destination.mkdir(parents=True,exist_ok=True)
    build=Path(tempfile.mkdtemp(prefix='digikat-voices-typeset-'))
    for source in (STUDY/'typeset').iterdir():
        if source.is_file():shutil.copy2(source,build/source.name)
    shutil.copy2(STUDY/'refs.bib',build/'refs.bib')
    header=(STUDY/'REPORT_TEMPLATE.qmd').read_text(encoding='utf-8').split('---',2)[1]
    for token,value in {'report_title':'Provjera prijeloma','report_date':'2026-10-25','corpus_documents':'Probni prijelom','corpus_period':'Provjera izgleda',
                        'platforms':'Sve','corpus_sha_short':'nije istraživački rezultat'}.items():
        header=header.replace('{{scalar:'+token+'}}',value)
    header=header.replace('title: "Tko govori o vjeri?"','title: "Provjera prijeloma"')
    header=header.replace('cover-stat: "Probni prijelom objava"','cover-stat: "Probni dokument"')
    body='''
# Čitljivost i hrvatski znakovi

Ovo je provjera prijeloma, a ne izvještaj o rezultatima istraživanja. Provjeravaju se hrvatski znakovi č, ć, ž, š i đ, razmaci, tablice i obvezna napomena o strojnom prepoznavanju.

#### Tablica za provjeru čitljivosti

| Provjera | Očekivano ponašanje |
|:--|:--|
| Strojno prepoznavanje | Bez tvrdnje o točnosti |
| Prekinuta obrada | Nastavak iz spremljenih rezultata |
| Nedostajući podatci | Vidljivo označeni |

> Izvor: konstruirani sadržaj za provjeru prijeloma. Nema empirijskih rezultata.

# Metodološka napomena

U tekstu se razlikuju prepoznavanje imena, pripisivanje izjave i tumačenje vjere. Uspješno spremanje rezultata nije dokaz ispravnog tumačenja. Neuspjele provjere ostaju zabilježene.

Službeni se imenici koriste kao javni izvori podataka o dužnostima, uz odvojeno bilježenje ograničenja povijesne pokrivenosti [@hbkBishops2026; @bkbihBishops2026].

::: {#refs}
:::
'''
    (build/'typesetting-smoke.qmd').write_text('---'+header+'---\n'+body,encoding='utf-8')
    version=subprocess.check_output([str(QUARTO),'--version'],text=True).strip()
    if version!='1.9.38':raise RuntimeError('Unexpected Quarto version: '+version)
    for fmt in ['html','typst']:
        result=subprocess.run([str(QUARTO),'render','typesetting-smoke.qmd','--to',fmt],cwd=build,capture_output=True,text=True,encoding='utf-8')
        (destination/(fmt+'-render.log')).write_text(result.stdout+'\n'+result.stderr,encoding='utf-8')
        if result.returncode:raise RuntimeError('Render failed: '+fmt+'; inspect saved log')
    for extension in ['pdf','html']:shutil.copy2(build/('typesetting-smoke.'+extension),destination/('typesetting-smoke.'+extension))
    result=check(destination/'typesetting-smoke.pdf',destination/'qa')
    (destination/'build.json').write_text(json.dumps(dict(build=str(build),quarto=version,mechanical_pass=result['mechanical_pass']),indent=2),encoding='utf-8')
    print(json.dumps(dict(pages=result['pages'],mechanical_pass=result['mechanical_pass'],destination=str(destination))))

if __name__=='__main__':main()
