# Plan — dodavanje tematskog istraživanja "Costlier Candles, Quiet Prophets" (inflation-salience)

**Datum:** 2026-07-02 · **Fast-track napomena:** jedna nova stranica po postojećem, petkrat ponovljenom obrascu
(`pages/studije/*.qmd`) + jedan novi navbar unos — CLAUDE.md tretira novu analitičku/tematsku stranicu i
`_quarto.yml` nav izmjenu kao plan-first, stoga ovaj kratki plan prije izvedbe.

## Cilj

Dodati šesti unos u "Tematska istraživanja" za rad *"Costlier Candles, Quiet Prophets: How Religion Meets
Inflation in the Croatian Digital Media Space, 2021–2026"* (studies/inflation-salience/PAPER_v1.md), s punim
tekstom na https://raw.githack.com/lusiki/Katoliq_vs_inflation/master/paper/paper.html (korisnički zadana
poveznica).

## Izvor sadržaja

- Puni tekst rada pročitan iz `studies/inflation-salience/PAPER_v1.md` (lokalni izvor, 470 redaka) — WebFetch na
  raw.githack URL vratio je samo naslov (stranica dinamički skraćena), pa se sadržaj stranice temelji na
  lokalnoj radnoj verziji rada, koja je izvor istine za taj rad.
- Postojeća house-memory `cooccurrence-not-engagement` potvrđuje da je ovaj rad upravo studija koja je
  empirijski utvrdila da co-occurrence nije engagement (~7x precjenjivanje) — ključni metodološki nalaz treba
  odražavati u "Ključni nalaz".

## Obrazac (5 postojećih stranica u pages/studije/)

Svaka: YAML (title/subtitle/date: last-modified/categories) → lead pasus → `## Istraživačko pitanje` →
`## Podaci i metode` → `## Ključni nalaz` → `## Status` (s Poveznica linkom na raw.githack pun tekst +
forward-link na `../schedule.qmd`).

## Sadržaj nove stranice — pages/studije/inflacija-i-religija.qmd

- **Title:** "Poskupjele svijeće, tihi proroci" (hrvatski prijevod naslova rada, prema voice-and-style.md
  Croatian-first pravilu za navbar/H1 — puni engleski naslov rada citira se u tekstu/statusu)
- **Subtitle:** informativan, ne ponavlja title — navodi da rad mjeri stvarnu religijsko-ekonomsku poveznicu
  nasuprot slučajnom suspominjanju
- **Categories:** `["Tematsko istraživanje", "Nacrt u izradi"]` (PAPER_v1 je "working manuscript, first
  complete version", autorstvo/redoslijed još nije finaliziran — status najbliži "Nacrt u izradi" korišten za
  trzista-paznje)
- **Istraživačko pitanje:** kada se inflacija pojavi u religijski salijentnom hrvatskom digitalnom diskursu,
  tko o njoj govori i u kojem registru — mjeri se stvarna poveznica, ne samo suspominjanje
- **Podaci i metode:** korpus 710.307 objava (siječanj 2021.–lipanj 2026.), 8.019 objava spominje inflaciju,
  proximity filter (±220 znakova, religijski leksikon od 95 pojmova) daje 1.450 kandidata, kodiranje triju
  neovisnih anotatora (IAA 0,97) potvrđuje 652 stvarno povezanih, od čega 520 domaćih (izmjereni core = 0,07%
  korpusa). HICP korelacija za H1.
- **Ključni nalaz:** religija se s inflacijom susreće pretežito kao ekonomski objekt (≈72% — trošak
  religijskog života + Crkva-kao-institucija), dobrotvorni rad 17%, strukturni/pravednosni CST-registar
  marginalan (2,9%, do ≈8% šire). Medijska pažnja prati stvarne cijene (r ≈ 0,73 s HICP-om), ali proročki glas
  pravednosti tu pažnju ne ispunjava. Metodološka napomena: naivno brojanje suspominjanja precijenilo bi pojavu
  za red veličine (≈8.000 nasuprot 520 mjerenih) — co-occurrence nije engagement.
- **Status:** Radni nacrt (prva potpuna verzija, 2026-07-01), autor Luka Šikić, autorstvo/redoslijed u
  finalizaciji. Poveznica na raw.githack pun tekst + forward-link na `../schedule.qmd`.

## Izmjene

1. Novi `pages/studije/inflacija-i-religija.qmd` (isti obrazac kao 5 postojećih).
2. Jedan novi red u `_quarto.yml` navbar meniju "Tematska istraživanja" (nakon postojećih 5 unosa).

## Verifikacija

- `quarto render pages/studije/inflacija-i-religija.qmd` iz root direktorija — čist render, provjera č/ć/ž/š/đ
  u izlaznom HTML-u.
- Provjera da render NIJE promijenio ništa izvan `docs/pages/studije/` (nema scattera) — quarto-verification.md §8.
- Provjera brojeva u tekstu 1:1 protiv `PAPER_v1.md` (nema hand-typed grešaka u prepisivanju).
- Provjera da je novi navbar unos ispravno pozicioniran i da postojećih 5 unosa nije dirano.

## Odbačene alternative

- Ne koristiti WebFetch sadržaj kao izvor (nepotpun/skraćen) — koristiti lokalni `PAPER_v1.md` kao pouzdaniji
  izvor istine za rad koji je dio ovog repozitorija (`studies/inflation-salience/`).
- Ne prevoditi cijeli engleski naslov rada u title — koristiti kraći hrvatski naslov u navbaru/H1 (kraće, u duhu
  ostalih 5 unosa koji imaju hrvatske naslove), a engleski naslov rada spomenuti u Status odjeljku uz poveznicu.
