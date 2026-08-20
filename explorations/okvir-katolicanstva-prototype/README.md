# Eksplorativna analiza „Kako se govori o Crkvi?”

## Pitanje

Tko govori o Crkvi u hrvatskome digitalnom prostoru, koje teme bira, gdje govor postaje oštriji, tko preuzima prostor tijekom velikih događaja i vidi li se dosljedna promjena?

## Status

Ovo je stvarna, ponovljiva eksplorativna analiza istraživačkoga korpusa projekta DigiKat. Jedinstveni izvještaj 19. kolovoza 2026. apsorbirao je prototipe `glas-crkve-prototype` i `pogled-izvana-prototype`. Njihov kod sada živi samo u `explorations/ARCHIVE/`, a svi izvorni CSV-ovi i sažeci sačuvani su u `explorations/ARCHIVE/2026-08-19_pre-merge/`.

Izvještaj je 20. kolovoza 2026. promoviran na javnu stranicu projekta. Ova mapa ostaje ponovljivi analitički izvor, a pregledani statički paket objavljuje se pod `assets/izvjestaji/kako-se-govori-o-crkvi/`.

## Šest poglavlja

1. **Tko govori?** Usporedba udjela objava i reakcija za četiri skupine izvora.
2. **O čemu se govori?** Kanonskih šesnaest tematskih kategorija sažeto je u šest tema. „Izvana” uvijek znači četvrtu skupinu, „Ostali mediji i javni izvori”.
3. **Kako se govori?** Pet internih okvira javno se prikazuje samo kao binarna mjera oštrijega i ostaloga govora. Ton riječi i jezik sukoba uspoređuju se po šest tema i četiri skupine.
4. **Kada se govori i tko tada govori?** Dani s neuobičajeno mnogo objava, tablica velikih događaja, sastav osam odabranih događaja i ritam objavljivanja oko blagdana.
5. **Mijenja li se što?** Udio web objava crkvenih medija i ustanova procjenjuje se odvojeno unutar dva načina prikupljanja.
6. **Što to znači?** Pet rečenica sinteze i jedna neutralna rečenica o praktičnome čitanju nalaza.

## Ulazi i zaštita podataka

- `data/digikat_corpus.rds` čita se bez stupaca `AUTHOR` i `URL`.
- `output/nlp-15pct/` sadrži privatni stratificirani uzorak i tokene za tekstualne mjere.
- `R/lib/thematic_dictionaries.R` ostaje nepromijenjeni izvor kanonskih tematskih kategorija.
- `_okvir_engine/okvir_lib.R` sadrži jedinu definiciju šest tema, klasifikatora izvora, događajnih valova i modela ritma.
- `source-groups.csv` sadrži provjerene odluke o skupinama izvora.
- `secular_outlets.csv` koristi se samo za dijagnostički agregat. Taj panel nije prikazan na javnoj stranici.

Redni identifikatori, tematske oznake pojedinačnih objava i pregled naziva izvora ostaju pod `output/private/`. Javni dio `output/` sadrži samo agregate. Generator odbija zapisati rezultat ako pronađe mrežne adrese, tekst objave ili nazive zabranjenih stupaca.

## Pokretanje

Iz korijena repozitorija, uz pauziranu Dropbox sinkronizaciju tijekom prvoga tematskog prolaza:

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --vanilla 'explorations/okvir-katolicanstva-prototype/build-15pct-nlp.R'
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --vanilla 'explorations/okvir-katolicanstva-prototype/analysis.R'
node explorations/okvir-katolicanstva-prototype/qa-browser.mjs
```

Prva naredba gradi privatnu generaciju samo ako ona ne postoji. Druga izračunava svih devet figura, tablicu, dijagnostičke CSV-ove, `analysis-data.js` i `analysis-summary.txt`. Treća provjerava široki i mobilni prikaz, pogreške JavaScripta, prazne grafikone, prelijevanje i broj prikazanih elemenata te sprema snimke u `output/`.

Nakon izračuna otvorite [`index.html`](index.html). Stranica namjerno prekida učitavanje ako generirani rezultati nedostaju.

## Reconciliation

`actor_totals.csv`, `event_arcs.csv` i `rhythm_effects.csv` moraju biti byte-for-byte jednaki kopijama prije spajanja. `theme_selection.csv` namjerno se razlikuje jer četvrta skupina zamjenjuje kurirani panel općih informativnih medija. Ishod svake provjere zapisuje se u `output/reconciliation.csv` i `output/analysis-summary.txt`.
