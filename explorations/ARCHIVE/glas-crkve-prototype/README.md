# Nastavak analize „Kada se govori o katoličanstvu — i tko tada govori?”

## Mjesto u projektu

Ovo je uski nastavak glavnog izvještaja [`Kako se govori o katoličanstvu`](../okvir-katolicanstva-prototype/). Glavni izvještaj pokazuje tko govori, kojim okvirima, uz koje objave publika reagira i kada nastaju najveći događajni vrhunci. Ovaj nastavak produbljuje samo posljednje pitanje: koje su skupine izvora nosile najveće prepoznate vrhunce i čiji se ritam najviše mijenja oko ponavljajućih blagdana?

Izvještaj ne uvodi vlastite „glasove”. Izravno preuzima četiri kanonske skupine, njihove oznake, redoslijed i boje iz `explorations/_okvir_engine/okvir_lib.R`:

1. Crkveni mediji i ustanove
2. Katolički mediji drugih osnivača
3. Pastoralni i vjerski kanali i stvaratelji
4. Ostali mediji i javni izvori

Politički i zagovarački portali ostaju podskupina ostalih medija i javnih izvora. Nisu zasebna skupina na istoj analitičkoj razini.

## Što izvještaj prikazuje

- referentnu raspodjelu svih objava prema četirima skupinama izvora
- sastav osam najvećih prepoznatih događajnih vrhunaca
- procijenjenu promjenu dnevnog broja objava oko Uskrsa, Velike Gospe, Svih svetih i Božića
- kratak zaključak s tri brojčano provjerljiva nalaza

Iz javnog prikaza uklonjeni su SPS, naslijeđeni narativni rječnici, posebna portalna granica, RIK uz kalendare, pokazatelji V1–V4 i obje višestupčane tablice. Ti instrumenti odgovaraju drugim istraživačkim pitanjima i ne pripadaju ovomu nastavku.

## Analitička pravila

`analysis.R` učitava puni službeni korpus i zajedničku biblioteku glavnog izvještaja. Prije izrade rezultata uspoređuje broj objava i reakcija u svakoj skupini s `okvir-katolicanstva-prototype/output/actor_totals.csv`. Izračun se prekida ako se agregati razlikuju.

Događajni vrhunci koriste isti deterministički postupak kao glavni izvještaj: dnevni broj objava standardizira se unutar godine, dani iznad tri standardne devijacije spajaju se u susjedne lukove, a naziv se dodaje samo kada se luk podudara s unaprijed navedenim liturgijskim ili papinskim događajem.

Liturgijski ritam procjenjuje se nad dnevnim brojem objava po skupini i platformi. Model uspoređuje prozor od dva dana prije do dva dana poslije blagdana s drugim prikupljenim danima te uzima u obzir dan u tjednu, polugodište i platformu. Intervali se dobivaju blok-bootstrapom po tjednima. Uskrs 2025. izostavljen je jer se njegov prozor preklapa sa smrću pape Franje.

## Pokretanje

Iz korijena repozitorija:

```powershell
& 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' --no-init-file 'explorations/glas-crkve-prototype/analysis.R'
node explorations/glas-crkve-prototype/qa-browser.mjs
```

Analiza zapisuje samo agregate u `output/`:

- `analysis-data.js`
- `analysis-summary.txt`
- `actor_totals.csv`
- `event_composition.csv`
- `rhythm_effects.csv`

`qa-browser.mjs` provjerava široki i mobilni prikaz, broj figura, odsutnost tablica, prazne grafikone, JavaScript pogreške i horizontalno prelijevanje stranice.

## Granice tumačenja

Skupina izvora nije ocjena sadržaja ni potvrda crkvenoga odobrenja. Događajni luk opisuje vremensko podudaranje i ne dokazuje da je imenovani događaj uzrokovao svaku objavu. Reakcije publike namjerno ostaju u glavnom izvještaju jer se ne mogu jednostavno usporediti među platformama i kratkim događajnim prozorima.
