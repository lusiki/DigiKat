# Demokršćanstvo: izvještaji i prezentacija

Autor: [Luka Šikić](https://www.lukasikic.info/). Izdanje: 19. rujna 2026.

- `javno/`: dva izvještaja i prezentacija, s PDF i raspoloživim HTML izdanjima.
- `izvor-analize-jezika/manuscript.md`: uređivi rukopis novog izvještaja. `source/build.py` ga pretvara u PDF i HTML uz priložene zbirne tablice (Python, ReportLab i fontovi Calibri/Georgia u sustavu Windows).
- `izvor-prezentacije/source/slides.json`: uređivi naslovi, tekstovi, citati i izvori svih slajdova. `build.py` sastavlja HTML iz priloženih zbirnih tablica. HTML se može i neposredno uređivati, čitati bez mreže i ispisati u PDF.
- `izvor-pregleda/`: uređivi Python izvor postojećeg izvještaja. Koristi ulaze projekta DigiKat navedene u README-u.
- `interna-provjera/`: provjere brojki, izvora, autora, poveznica, prijeloma i pristupačnosti, odvojene od javnih publikacija.
- `tekst-za-mreznu-stranicu.md`: kratak uvod i tri sažetka nalaza.

U HTML prezentaciji gumb „Prikaži slajdove” uključuje prikaz jednog slajda. Strelice mijenjaju slajd, a Escape vraća prikaz za čitanje. Mrežne poveznice trebaju internetsku vezu. Brojevi objava i različitih tekstova imaju zasebne nazivnike opisane u publikacijama.
