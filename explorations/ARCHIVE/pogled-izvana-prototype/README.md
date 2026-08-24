# Eksplorativna analiza „Što iz crkvenoga života dospijeva u vijesti?”

## Pitanje

Koje teme prate i opći mediji, a koje uglavnom ostaju u katoličkom medijskom krugu?

## Odnos prema glavnom izvještaju

Izvještaj `explorations/okvir-katolicanstva-prototype/` opisuje cijeli razgovor o katoličanstvu. Prati izvore, načine govora, reakcije, događaje i promjene kroz vrijeme. Ovaj nastavak ne ponavlja tu strukturu. Uspoređuje izbor tema u dvama jasno omeđenim web-medijskim krugovima i zatim pokazuje kako se njihov odnos mijenja tijekom prepoznatih liturgijskih i papinskih događaja.

## Analitički obuhvat

- Katolički izvori obuhvaćaju tri skupine iz glavnog izvještaja. To su crkveni mediji i ustanove, katolički mediji drugih osnivača te pastoralni i vjerski kanali i stvaratelji.
- Opći informativni mediji čine provjeren panel nacionalnih, regionalnih i lokalnih web-medija iz `secular_outlets.csv`.
- Forumi, Reddit, osobni računi, politički portali i ostali nejasno razvrstani izvori ne ulaze u glavne nalaze.
- Tematska usporedba koristi svih šesnaest kategorija iz kanonskoga projektnog rječnika. One su za glavni prikaz spojene u šest širih tema.
- Događajni dio čita isti popis događajnih valova kao glavni izvještaj. Prikazuje samo prepoznate liturgijske i papinske događaje.
- Službeni korpus ostaje samo za čitanje. Svi generirani izlazi ostaju u `output/` ove eksploracije.
- Stupci s autorom i mrežnom adresom ne čitaju se.

## Glavni izlazi

Izvještaj ima tri slike.

1. Usporedba šest tema u katoličkim izvorima i općim informativnim medijima.
2. Osam pojedinačnih kategorija s najvećom razlikom udjela između dviju skupina.
3. Uobičajeni udio općih medija i njihov udio tijekom prepoznatih događajnih valova.

Javni agregati ne sadrže tekst, naslov, naziv izvora, autora ni mrežnu adresu. Privatni registar i predmemorija tematskih oznaka ostaju u `output/private/`.

## Pokretanje

Iz korijena repozitorija treba pokrenuti sljedeće naredbe.

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --no-init-file 'explorations/okvir-katolicanstva-prototype/analysis.R'
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --no-init-file 'explorations/pogled-izvana-prototype/analysis.R'
node explorations/pogled-izvana-prototype/qa-browser.mjs
```

Prvi korak obnavlja zajednički popis događajnih valova. Drugi čita službeni korpus, provjerava registar općih medija, dodjeljuje tematske kategorije i stvara javne agregate. Treći provjerava prikaz na stolnom i mobilnom zaslonu.

Prvi tematski prolaz traje nekoliko minuta. Privatna predmemorija ponovno se koristi dok se ne promijene korpus, registar ili tematski rječnik.

## Status

Ovo je radna eksploracija. Nije uključena u javnu navigaciju. Prije moguće objave potrebno je urednički potvrditi panel općih medija i pregledati računalno dodijeljene teme na odvojenom skupu objava.

