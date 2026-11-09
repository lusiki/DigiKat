# Demokršćanstvo: od riječi do argumenta

Javni izvještaj na temelju zamrznute tekstualne analize DigiKatova medijskog materijala. Izvještaj opisuje 2.253 različita teksta iz 2.306 zapisa, s deset postojećih tematskih skupina. Javni prikazi ne preuzimaju broj zapisa 2.306 kao nazivnik za rječnik ili teme.

## Objavljivanje

- `demokrscanstvo-od-rijeci-do-argumenta.pdf`: završni javni PDF.
- `report.html`: samostalna HTML verzija bez mrežnih ovisnosti, s potpunim tekstualnim tablicama svih riječi u oblacima i podataka na grafikonima.
- `website-copy.md`: uvod i tri nalaza za stranicu uz preuzimanje.

Datoteke u mapi `internal` namijenjene su uredničkoj provjeri i nisu dio javnog izvještaja.

## Uređivanje

`manuscript.md` je izvor za prijelom PDF-a, s oznakama prijeloma stranica i blokovima `::: topics` / `::: chain`. `report.md` je uobičajeni Markdown s proširenim prikazima i poveznicama na SVG slike. `tables` sadrži brojčanu podlogu, a `figures` vektorske slike koje se mogu zasebno urediti. U SVG oblacima položaj i boja nemaju statističko značenje. Sve riječi ostaju tekst, uključujući u PDF-u.

Paket sadrži skriptu `source/build.py`. Iz mape paketa može se pokrenuti naredba:

```
python source/build.py
```

Potrebni su Python, ReportLab i fontovi Calibri/Georgia na Windowsu. Skripta koristi samo javne agregate iz mape `tables`; za ponovni prijelom ne treba privatni medijski korpus. Dobiveni PDF sprema se u korijen paketa. Za potpuno identičan izgled koristiti iste verzije fontova. Izvorni postupak analize (`prepare.py`) ostaje u projektnom repozitoriju i traži pristup privatnim ulazima; ne treba ga pokretati radi uređivanja izvještaja.

## Reprodukcija u repozitoriju

```
python studies/demokrscanstvo-barometar/text-public/prepare.py
python studies/demokrscanstvo-barometar/text-public/build.py
python studies/demokrscanstvo-barometar/text-public/verify.py
```

Prethodni izvještaji, plan, ulazni tekstovi i objavljena mrežna stranica ostaju sačuvani. Paket priprema sadržaj za objavu; sam ne objavljuje stranicu.
