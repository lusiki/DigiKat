# Interni zapis provjere

Izvještaj: **Demokršćanstvo: od riječi do argumenta**. Datum: 19. rujna 2026. Javni PDF ima 12 stranica. Ovaj zapis nije dio javne publikacije.

## Rezultat

Prošlo je svih **19 računalnih provjera**. Registar ima **256 brojčanih redaka** koji povezuju riječi, teme, izraze i zbirne tvrdnje s podlogom. Svih **12 konačno renderiranih stranica** pregledano je zasebno. Nisu ostali uočeni problemi s čitljivošću, hrvatskim znakovima, preklapanjem ili rezanjem sadržaja.

SHA-256 pregledanog PDF-a: `8bc603616b34ad49d550b8b20628619a58ee9a81152035dc5eaaf24068554bac`.

## Brojčane tvrdnje

- Potvrđeno je 2.306 izvornih zapisa i 2.253 skupine jednakoga teksta. Javni udjeli koriste 2.253.
- Svih 228 riječi na 11 oblaka ponovno je izračunano iz izvornih tokena kao skup različitih tekstova. Ukupni rječnik usklađen je s postojećom tablicom učestalosti.
- Provjereno je deset tematskih zbrojeva, jedan nerazvrstani tekst i zbroj četiriju političkih skupina: 1.105 / 2.253 = 49,0%.
- Osam izraza povezano je s izvornom tablicom susjednih lematiziranih nizova. „Demokršćanske vrijednosti” imaju 454 teksta, odnosno 20,2%.
- Provjerene su brojke u prozi i tablicama, uključujući vrijednost 1.123, stranka 830, HDZ 818, solidarnost 103, savjest 29 i supsidijarnost 27. Web-uvod i tri sažetka koriste iste brojke i iste primjere.
- Sve veličine riječi monotono prate broj tekstova unutar pojedinog oblaka. Položaj i boja nemaju analitičko značenje. Prostorne granice svih riječi provjerene su bez preklapanja.

Potpuni rezultati: [verification.json](verification.json), [claim-register.csv](claim-register.csv), [preparation.json](preparation.json).

## Sadržaj, imena, navodi i datumi

Ponovno su pročitana četiri cijela dostupna arhivska teksta. Glavni portreti ciljano su odabrani; njihovi zaključci nisu prikazani kao udjeli u cijelom korpusu.

| Izvor | Provjerene točke | Tumačenje u izvještaju |
|---|---|---|
| Glas Slavonije / Dario Kuštro, 29. 8. 2024. na mreži; 30. 8. 2024. tisak | Samir Haj Barakat, Ivan Anušić, lijeva uvjerenja, odbijanje prelaska u HDZ i doslovni navod | Poštovanje načela razlikuje se od stranačkog članstva. Optužbe o unutarstranačkim izborima pripisane su sugovorniku. |
| Kamenjar/Hina, 20. 4. 2022.; javna potvrda Vlada/Hina | Anka Mrak-Taritaš, Andrej Plenković, dostupnost usluge, doslovni navod i najava provjere | Razlikovana su pitanja dostupnosti i liječničkog priziva savjesti. Nije dodana tvrdnja o razriješenom organizacijskom problemu. |
| Telegram/Hina, 7. 6. 2024.; javni isti izvještaj tportal/Hina | Davor Ivo Stier, Hrvatski Leskovac - Karlovac, Karlovačka županija, europski fondovi i solidarnost | Infrastrukturni primjeri prikazani su kao kandidatovo obrazloženje, bez neprovjerene procjene gospodarskog učinka. |
| Otvoreno, 28. 2. 2021. | Jakov Žižić, Mate Mijić, zajednica, tržište, opće dobro i razine vlasti | Razlike među idejnim tradicijama pripisane su Žižićevu tumačenju. Izvorni URL nije potvrđen; naveden je naslov i datum arhivskog teksta. |

Javne poveznice provjerene pri pripremi:

- [Glas Slavonije: Haj Barakat](https://www.glas-slavonije.hr/osijek/2024/08/29/vijecnik-haj-barakat-napustio-sdp-osjecam-da-ovdje-nisam-bio-dobrodosao-567954/).
- [Vlada RH/Hina: aktualno prijepodne, 20. 4. 2022.](https://vlada.gov.hr/vijesti/aktualno-prijepodne-zahtjev-za-pomilovanjem-perkovica-i-mustaca-orkestrirana-akcija/35261).
- [tportal/Hina: Stier, 7. 6. 2024.](https://www.tportal.hr/vijesti/clanak/stier-hdz-za-demokrscansku-europu-kakvu-je-zagovarao-ivan-pavao-ii-20240607).

## Prijelom i pristupačnost

Provjereni su svi završni prikazi PNG koje je proizveo Poppler. Evidencija pojedine stranice i sažeci slika: [visual-qa.json](visual-qa.json). Automatska provjera znakova nije našla zamjenske znakove, a nijedan PDF glif ne izlazi iz zadane margine. Najniži rub sadržaja ostaje na 72,6 pt, iznad podnožja. Tijelo je 11,3 pt; oblačne riječi najmanje 10,1 pt. Svi grafički sadržaji imaju prateći opis jedinice i tumačenje.

PDF sadrži odabirivi tekst, ugrađene fontove, hrvatski jezik i knjižne oznake. Nije certificiran kao PDF/UA. HTML sadrži semantičke naslove, navigaciju i 13 otvorivih tablica sa svim vrijednostima 11 oblaka i dvaju grafikona. Njegova struktura i tekstualne alternative računalno su provjereni; nije provedeno testiranje s čitačem zaslona. SVG riječi čuvaju zadanu širinu i uz zamjenski font.

## Ponovljivost i opseg provjere

Pokrenut je isporučeni `source/build.py` samo s agregatima i rukopisom iz paketa. Dobiveni PDF byte-po-byte jednak je pregledanom PDF-u: [portable-build.json](portable-build.json). Izvorne provjere analize i reproducibilnosti zadržane su u mapi `baseline`. Točne metode, odabir riječi, pretrage, model i granice tumačenja nalaze se u [technical-methods.md](technical-methods.md).

Sadržajno čitanje i vizualni pregled proveo je Codex AI. Neovisno ljudsko dvostruko kodiranje nije provedeno; nisu izračunati ni objavljeni udjeli potvrđene primjene načela, političke potpore ili pouzdanost kodera. Zbog toga se provjera brojki i prijeloma ne prikazuje kao ljudska validacija semantičkih klasifikacija. Privatna tijela članaka i pojedinačni redci korpusa nisu uključeni u publikacijski paket.
