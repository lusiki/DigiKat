# DigiKat

![Status projekta](https://img.shields.io/badge/status-aktivan-green)
![Institucija](https://img.shields.io/badge/Hrvatsko_katoličko_sveučilište-blue)
[![Web](https://img.shields.io/badge/web-DigiKat-brightgreen)](https://lusiki.github.io/DigiKat/)
![Projektni materijali](https://img.shields.io/badge/projektni_materijali-CC_BY_4.0-lightgrey)

**Prikaz i analiza katoličke tematike u digitalnom medijskom prostoru** istraživački je projekt
Hrvatskoga katoličkog sveučilišta (2025.–2027.). Projekt računalnim metodama opisuje prisutnost,
aktere, teme i ton katoličkih sadržaja u hrvatskom digitalnom medijskom prostoru.

- [Mrežna stranica projekta](https://lusiki.github.io/DigiKat/)
- [Izvršni pregled](https://lusiki.github.io/DigiKat/pages/pregled/izvrsni-pregled.html)
- [Opis baze i metodologije](https://lusiki.github.io/DigiKat/pages/baza.html)

## Trenutačni podatkovni opseg

Objavljeni agregati obuhvaćaju **710.307 zapisa**, od siječnja 2021. do lipnja 2026., u devet
vrsta izvora: web, YouTube, Facebook, Twitter/X, Reddit, forumi, komentari, Instagram i TikTok.
Glavna baza ima 47 varijabli. Godina 2026. nepotpuna je i ne smije se tumačiti kao cijela
kalendarska godina.

Puni tekstovi, URL-ovi i redci glavne baze nisu javni zbog veličine, autorskih prava i uvjeta
izvornih platformi. Repozitorij zato sadrži:

- 14 javnih agregatnih `.rds` datoteka u `data/processed/`;
- tri javna, validirana sažetka za brzi prikaz NLP stranica u `data/page-ready/`;
- potpuno sintetički testni uzorak od 2.700 redaka u `data/sample/`;
- reproducibilni R kod, testove i Quarto izvore;
- jezične resurse pod njihovim izvornim licencama.

Detaljna pravila dostupnosti nalaze se u [DATA_AVAILABILITY.md](DATA_AVAILABILITY.md), a upute za
replikaciju u [REPLICATION.md](REPLICATION.md).

## Brzi početak

Preporučeno okruženje odgovara trenutačnom zaključanom stanju: R 4.6.0, Quarto 1.9.38 i Git.

```powershell
git clone https://github.com/lusiki/DigiKat.git
cd DigiKat
Rscript -e "renv::restore()"
Rscript tests/run_tests.R
Rscript R/check_disclosure.R
Rscript R/00_run_all.R --sample
```

Posljednja naredba izvodi cjelovit, nedestruktivan test na sintetičkim podacima. Ne mijenja glavnu
bazu ni produkcijske agregate.

## Siguran radni tijek

| Naredba | Zadano ponašanje |
|---|---|
| `Rscript R/00_run_all.R --sample` | sintetički test cijelog podatkovnog toka u privremenom direktoriju |
| `Rscript R/00_run_all.R` | provjera postavki, testova, agregata, NLP-a i semantičkoga spremišta bez zamjene podataka |
| `Rscript R/append_new_data.R` | samo pregled nove serije i JSON izvještaj |
| `Rscript R/append_new_data.R --apply` | nakon pregleda izrađuje provjerenu sigurnosnu kopiju i zamjenjuje glavnu bazu |
| `Rscript R/03_aggregate.R` | izrađuje i validira svih 14 agregata u privremenom direktoriju |
| `Rscript R/compare_aggregates.R --candidate-dir=PUTANJA` | samo čita i uspoređuje kandidata s produkcijskim agregatima |
| `Rscript R/03_aggregate.R --apply` | nakon izričite potvrde zamjenjuje `data/processed/` atomskom generacijom |
| `Rscript R/05_page_summaries.R --build` | jednom izračunava sažetke iz NLP uzoraka; stranice potom renderiraju bez učitavanja milijuna tokena |
| `Rscript R/04_nlp.R` | provjerava postojeću NLP generaciju i njezin manifest |
| `quarto render` | gradi cijelu stranicu u `docs/`; pokreće se samo iz korijena repozitorija |

Mutirajuće naredbe imaju zasebne zastavice kako pregled ili render ne bi slučajno prepisao glavnu bazu.

## Struktura repozitorija

| Putanja | Namjena |
|---|---|
| `R/` | numerirani podatkovni tok, zajedničke biblioteke, provjere i generatori |
| `pages/` | Quarto izvori mrežne stranice |
| `data/processed/` | javni agregati koje stranice samo čitaju |
| `data/page-ready/` | mali javni ulazi za grafikone i tablice na tri NLP stranice |
| `data/sample/` | sintetička reprodukcijska fikstura i manifest |
| `resources/` | rječnici, leksikoni, oznake izvora i UDPipe model |
| `studies/` | samostalne tematske studije; redci s tekstom ostaju u `output/private/` |
| `tests/` | regresijski testovi bez vanjskog testnog okvira |
| `docs/` | generirana GitHub Pages stranica; ne uređuje se ručno |
| `archive/` | povijesni prototipovi, nacrti i zamijenjene skripte |

## Doprinos i prijava pogreške

Prije slanja promjene pokrenite testove, provjeru otkrivanja podataka i relevantni render. Pravila za
prijedloge i rad s osjetljivim podacima opisana su u [CONTRIBUTING.md](CONTRIBUTING.md).

Za pitanja o pristupu podacima ili suradnji:

**doc. dr. sc. Luka Šikić**<br>
Hrvatsko katoličko sveučilište<br>
<luka.sikic@unicath.hr>

## Citiranje

> Šikić, L. i sur. (2025.–2027.). *Prikaz i analiza katoličke tematike u digitalnom medijskom
> prostoru (DigiKat).* Hrvatsko katoličko sveučilište. https://github.com/lusiki/DigiKat

Strojno čitljivi podaci za citiranje nalaze se u [CITATION.cff](CITATION.cff). Za jezične resurse
potrebno je citirati i njihove izvorne autore; vidi [resources/README.md](resources/README.md).
