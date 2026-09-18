// Compact adaptation of the annual-report Typst visual system. The source
// report's cover and pagination are deliberately omitted for a two-page brief.
#let accent = rgb("#0f4c5c")
#let paper = rgb("#f5f4f0")
#let ink = rgb("#14181d")
#let sans = "Source Sans 3"
#let serif = "Source Serif 4"
#let mono = "IBM Plex Mono"
#let data = json("summary.json")
#set document(title: "Medijski barometar demokršćanstva", author: "Luka Šikić")
#set page(paper: "a4", margin: (x: 22mm, y: 20mm), fill: paper,
  footer: context [#set text(font: sans, size: 8pt, fill: accent)
    DigiKat · Radni metodološki sažetak #h(1fr) #counter(page).display("1 / 1", both: true)])
#set text(font: serif, size: 10.4pt, fill: ink, lang: "hr", hyphenate: false)
#set par(leading: .58em, spacing: .85em)
#show heading: it => block(above: 1.2em, below: .45em, sticky: true)[
  #text(font: sans, size: 13pt, weight: "bold", fill: accent)[#it.body]]

#text(font: sans, size: 9pt, tracking: 1pt, fill: accent)[DIGIKAT · HRVATSKO KATOLIČKO SVEUČILIŠTE]
#v(10pt)
#text(font: serif, size: 29pt, weight: "bold", fill: accent)[Medijski barometar\ demokršćanstva]
#v(7pt)
#text(font: sans, size: 11pt)[Luka Šikić · Metoda i plan provjere]
#v(7pt)
#text(font: sans, size: 9pt)[Izazovi i budućnost demokršćanstva u Hrvatskoj i Europi\
  Hrvatsko katoličko sveučilište, 24. rujna 2026.]
#v(12pt)
#block(fill: accent, inset: 12pt, width: 100%)[
  #set text(font: sans, fill: white, size: 10.5pt)
  #strong[Status: metodološki sažetak, bez empirijskih nalaza.]
  Ljudsko kodiranje zasebnoga uzorka još nije završeno. Ovaj sažetak ne donosi
  procjenu preciznosti pravila, razinu zastupljenosti ni zaključak o promjeni kroz vrijeme.
]

= Što barometar mjeri?
Barometar ispituje koliko hrvatski mrežni mediji pišu o demokršćanstvu kao
političkoj tradiciji te o kršćanskoj socijalnoj misli primijenjenoj na javna pitanja.
Obuhvaćeni su izvještaji, kritika i pripisani argumenti aktera. Pokazatelji govore o
zastupljenosti teme. Iz njih se ne izvode potpora stranci, uvjerenje izdavača ili doseg objave.

#grid(columns: (1fr, 1fr), gutter: 14pt,
  block(fill: white, inset: 12pt)[
    #text(font: sans, weight: "bold", fill: accent)[Medijska zastupljenost]
    #parbreak()
    Broj uključenih članaka na 10.000 prihvatljivih članaka u istom razdoblju.
  ],
  block(fill: white, inset: 12pt)[
    #text(font: sans, weight: "bold", fill: accent)[Širina prisutnosti]
    #parbreak()
    Postotak medija stalnog panela s barem jednim uključenim člankom.
  ])

= Tri puta prepoznavanja
#table(columns: (31mm, 1fr), stroke: (bottom: .5pt + rgb("#d8d5cc")), inset: 7pt,
  [#strong[A1 · Tradicija]], [Izravno imenovanje demokršćanstva kao tradicije, ideje ili vrijednosnog usmjerenja.],
  [#strong[B · Socijalni nauk]], [Prepoznatljiv nauk ili dokument primijenjen na političko ili javnopolitičko pitanje.],
  [#strong[C · Argument]], [Kršćansko uporište i političko pitanje povezani s jednim snažnim ili razlikovnim pojmom, odnosno najmanje dvjema obiteljima općih pojmova.])
Sam stranački naziv, crkveni događaj ili opća riječ poput solidarnosti nije dovoljan.
D zasebno označava uključene članke čiji je kvalificirajući argument pripisan
vremenski dokumentiranom demokršćanskom akteru.

= Stalni panel i usporedivost
Stalni panel obuhvaća #data.panel_outlets odabranih uredničkih medija.
Članci se razgraničavaju zajedničkim pravilom prihvatljivosti i uklanjanjem ponovljenih
zapisa. Dani s nedostatnim tijelima članaka označavaju se kao neopaženi, a ne kao nule.
Promjena prikupljanja 1. travnja 2024. ostaje označen prekid. Usporedivost se zasebno
provjerava rekonstrukcijom lipnja 2024. iz oba izvora uz isti panel i pravila.

#pagebreak()
#text(font: sans, size: 9pt, tracking: 1pt, fill: accent)[PROVJERA PRIJE TUMAČENJA]
= Razvoj, zamrzavanje i ljudska evaluacija
Pravila se razvijaju na odvojenom dijelu članaka. Definicija se zamrzava prije
pregleda vremenskih pokazatelja. Zatim se iz preostalog dijela izvlači novi uzorak,
uz isključenje svih razvojno pregledanih članaka. Dva čovjeka neovisno kodiraju
zajednički dio uzorka, a istraživač obrazlaže razrješenje svakog neslaganja.

Plan obuhvaća do 60 slučajeva po glavnom putu, zasebne dijagnostičke skupine te
100 mogućih propuštenih slučajeva unutar unaprijed određenog okvira. Uključivanje u
širi pokazatelj zahtijeva procijenjenu preciznost najmanje 0,80 i slaganje kodera
za kvalifikaciju od najmanje 0,70 prema Cohenovoj kapi. To su unaprijed zadani
pragovi, a ne postignuti rezultati.

= Što se može zaključiti nakon provjere?
Objavljivi rezultat opisivat će učestalost i rasprostranjenost teme unutar stalnog
panela. Užim obuhvatom pratit će se samo imenovana demokršćanska tradicija. Širi
obuhvat uključivat će dodatne putove koji prođu ljudsku provjeru. Neuspješan put
ostaje izvan glavnih pokazatelja. Ako ne prođe ni A1, empirijski se barometar ne objavljuje.

Tematska područja mogu se preklapati. Načela su zasebne oznake relevantnih odlomaka.
Analize osjetljivosti pokazuju
što se mijenja izostavljanjem konfesionalnih medija, političkih portala, crkvenih
govornika ili slučajeva u kojima rječnik prepoznaje samo HDZ kao registriranog aktera.
Izostavljanje skupina medija mijenja panel i nazivnik. Provjere govornika mijenjaju
samo broj uključenih članaka. Posljednja provjera ovisi o ograničenom registru naziva i uloga.

= Ograničenja
Stalan panel nije popis svih hrvatskih medija. Pravila mogu propustiti parafraze,
pogrešno pripisati govor ili zamijeniti značenje višeznačnog izraza. Provjera
mogućih propusta odnosi se samo na svoj okvir. Odziv cijeloga panela nije procijenjen.
Mali brojevi, djelomična razdoblja i promjena prikupljanja ograničavaju tumačenje promjena.

= Reproducibilnost i status izdanja
Izvorni članci ostaju u ograničenoj bazi. Javni paket predviđa samo provjerene skupne
tablice, definiciju, verzije i provjere. Objavljivanje izvedenih podataka ovisi i o
potvrdi uvjeta izvora. Izvorni tekstovi, naslovi, poveznice i brojnici pojedinih medija
ne ulaze u javni paket.

#block(fill: white, inset: 12pt, width: 100%)[
  #set text(font: sans, size: 9pt)
  #strong[Radna verzija:] #data.release_version \
  #strong[Panel:] #data.panel_version · #data.panel_outlets medija \
  #strong[Definicija:] #text(font: mono, size: 8pt)[#data.definition_version] \
  #strong[Referentni rez izvora:] #data.data_through \
  #strong[Empirijska validacija:] nije završena
]
#text(font: sans, size: 8.5pt)[Codex je korišten za pripremu koda, prijedlog rječnika i
razvojnu provjeru pravila. Ljudske oznake i konačno znanstveno tumačenje odgovornost su istraživača.]
#text(font: sans, size: 8.5pt)[Citiranje: Šikić, L. (2026). Medijski barometar demokršćanstva:
metoda i plan provjere. Radni konferencijski sažetak. DigiKat, Hrvatsko katoličko sveučilište.]
