# Demokršćanstvo: od riječi do argumenta

Detaljan plan tekstualne dopune analitičkom izvještaju

Prijedlog za pregled | 19. rujna 2026. | Izdanje 1.0

Polazište: demokrscanstvo-analiticki-izvjestaj.pdf, izdanje 1.0, 20 stranica.

Ovaj dokument predlaže novu analizu. Brojevi o korpusu preuzeti su iz postojećeg izdanja i provjereni prema lokalnim datotekama; predloženi sadržajni nalazi još nisu izračunani.

<!-- PAGE: 02 | Sažetak i putokaz -->
# Što će dopuna objasniti

**Središnje pitanje:** Kada je demokršćanstvo u ovoj zbirci oznaka političkog identiteta, a kada postaje obrazloženje odnosa prema radu, solidarnosti, slobodi, obitelji, Europi i javnoj vlasti?

Predlaže se samostalna dopuna postojećem izvještaju. Ona polazi od njegovih nalaza i ispituje sadržaj koji se gubi u broju spominjanja i jednoj primarnoj temi. Mogući zaključci ostaju otvoreni: razvijeni argumenti mogu biti raspršeni kroz zbirku, koncentrirani u nekoliko izjava ili slabo vidljivi zbog načina odabira teksta.

| Modul | Pitanje i novi doprinos | Plan |
|---|---|---|
| M1. Prepoznatljiv rječnik | Koje riječi razlikuju kontekste i razdoblja, uz učestalost i rasprostranjenost? | str. 7 |
| M2. Fraze i odnosi | Koje su veze ponavljane formule, a koje vode do različitih obrazloženja? | str. 8 |
| M3. Načelo i primjena | Koje se vrijednosti izričito povezuju s problemom i prijedlogom ili prosudbom? | str. 9-10 |
| M4. Stav i govorni glas | Tko procjenjuje tradiciju, stranku ili politiku i razlikuju li se ti stavovi? | str. 11 |
| M5. Trajnost sadržaja | Pojavljuje li se određeni argument u više razdoblja, izvora i formulacija? | str. 12 |

## Preporučeni redoslijed

**Prvo:** M1 i M2, priprema kodiranja M3 te opisna provjera raspršenosti M5. Dostupni tekst i jezični međurezultati omogućuju početak bez nove pretrage arhive.

**Zatim:** M3 i ciljano kodiranje stava u M4 na uzorku s poznatim vjerojatnostima izbora. To je najveći sadržajni dobitak i glavno mjesto na kojem su potrebni neovisni čitatelji.

**Uvjetno:** hrvatski leksički sentiment i dodatni tematski model. Uključiti ih samo ako pilot pokaže korist za pitanje koje jednostavniji postupak nije razriješio.

**Za pregled:** predložena jezgra ima pet modula, osam vrsta prikaza i dvije razine izvedbe. Kriteriji kvalitete i rezervni ishodi nalaze se na str. 13-14; isporuke i radni slijed na str. 16.

<!-- PAGE: 03 | Provjereno polazište -->
# Dopuna počinje od postojećih podataka

Pregledani su izvorni PDF, njegov kod i agregati, manifesti te struktura i broj zapisa u privatnoj tekstualnoj datoteci. SHA256 izvornog PDF-a odgovara manifestu. Ova provjera potvrđuje polazište za plan; nije nova provjera svih interpretacija ni ponovno izvođenje cijele analize. [L1-L3]

| Dostupno i provjereno | Posljedica za novu analizu |
|---|---|
| 2.306 zapisa; 1. 1. 2021. - 10. 9. 2026. | Zamrznuti obuhvat. Ne proširivati ga neprimjetno na sve zapise o kršćanstvu ili politici. |
| 2.253 skupine jednakog naslova i tijela; 1.731 različit dokazni kontekst | Glavna jezična jedinica: predstavnik točnog teksta. Kontekst nije neovisna priča. |
| 2.211 pogodaka pravilom A1; 95 dodatnih | Pokazati osjetljivost na način uključivanja. Nazivlje koje bira korpus nije neovisno otkriće. |
| 2.290 zapisa s osnovom pohranjenog tijela; 16 s osnovom isječka | Dostupnost polja nije jamstvo cjelovitog članka ili prijepisa. |
| 2.198 nepraznih očišćenih tijela; 2.306 nepraznih naslova | Nakon uklanjanja ponovljenog naslova i šablona tijelo može biti prazno. Sačuvati smisleni naslov. |
| 7.467 rečeničnih jedinica u postojećoj leksičkoj analizi; 187.597 provjerenih položaja tokena | Postoje leme, glagoli, negacija i položaji. Novi prošireni prozori ipak traže dodatnu anotaciju. |
| Web: 1.811 zapisa; 2025. web 212, tisak 41, Facebook 14, X 11 | Detaljne usporedbe malih platformi nisu obećana jezgra. |

## Što izvještaj već radi

Postojeći izvještaj donosi vremensku vidljivost, deset NMF tema, kontrole kopija, NPMI odabranih pojmova i kvalitativne primjere primjene načela. Dopuna neće ponovno predstavljati te postupke kao novost. Dodaje pregled razlikovnog rječnika, izvorne fraze, sustavno kodiranje argumenta i njegovu raspršenost.

**Otvorena granica:** postojeće čitanje uz pomoć AI-ja i pripremljeni paket od 200 jedinica nisu dovršena ljudska validacija. Nema potvrđenih stopa točnosti ni populacijskih udjela novih sadržajnih oznaka. Novi nazivnici neće se preuzimati iz pripremljenog paketa. [L3]

<!-- PAGE: 04 | Izbor iz knjige -->
# Metode iz knjige, pitanja iz korpusa

Knjiga **Text Mining with R: A Tidy Approach** Julije Silge i Davida Robinsona daje metodološki okvir. Nije izvor tvrdnji o demokršćanstvu. U nastavku se njezini postupci prilagođavaju hrvatskom jeziku, selekciji korpusa i već provedenoj analizi. [1-6]

| Dio knjige | Što preuzimamo | Konkretna prilagodba |
|---|---|---|
| 1. Tidy text format | Jedan token u retku; povezivanje s metapodacima | Sačuvati izvorni oblik, lemu, rečenicu, polje, položaj i ključ tekstualne skupine. |
| 3. Učestalost i TF-IDF | Razlikovanje čestih i dokumentu svojstvenih riječi | Dokument je lokalni sadržaj jednog točnog teksta; rijetkost nije sadržajna važnost. |
| 4. N-grami i korelacije | Slijed riječi, supojavljivanje i binarna povezanost | Fraze graditi prije uklanjanja funkcijskih riječi; granice rečenica i negaciju sačuvati. |
| 2. Sentiment | Povezivanje riječi s leksikonom; provjera doprinosa pojedinih riječi | Hrvatski rječnik i pilot pokrivenosti. Ton teksta odvojiti od stava prema određenom cilju. |
| 5. Pretvorbe formata | Prijelaz između tablica i rijetkih matrica | Zadržati dokumente bez pogodaka u nazivnicima; koristiti brojanja ili težine prema metodi. |
| 6. Tematsko modeliranje | Pregled riječi po temi i tema po dokumentu | Postojeći NMF ostaje referenca. LDA je moguća dopunska provjera na brojanjima, ne obvezan novi model. |

## Dvije korisne nadogradnje

**Razlikovni rječnik:** tidylo nudi težinski log-omjer izgleda s regularizacijom. Koristit će se kao dopuna opisnom TF-IDF-u, uz sirove brojeve i provjeru utjecaja pojedinog teksta ili citata. Njegov rezultat služi rangiranju, a ne dokazu javne važnosti pojma. [7]

**Sadržajni kodni okvir:** Kompendij socijalnog nauka i platforma EPP-a iz 2012. pomažu sastaviti početne pojmove i negativne primjere. Jedan je doktrinarni, drugi politički izvor određenog aktera i vremena. Nijedan nije univerzalni test pripadnosti demokršćanstvu. [8-9]

**Izbor projekta:** preskačemo oblak riječi i samostalnu provjeru Zipfova zakona. Oni ovdje ne odgovaraju na ključno pitanje o vezi načela i konkretnog argumenta. Prioritet dobivaju usporedive tablice, kontekst i provjerljive veze.

<!-- PAGE: 05 | Sadržajne osi -->
# Koje napetosti vrijedi istražiti

Ovo su početne istraživačke osi, a ne unaprijed potvrđene dimenzije korpusa. Socijalna načela, političke oznake i područja javne politike vode se zasebno. Činjenica da se solidarnost ili obitelj spominju u tekstu nije sama po sebi dokaz demokršćanske argumentacije. [8-9; L1]

| Os | Što tražiti u raspoloživom tekstu | Što bi promijenilo početno tumačenje |
|---|---|---|
| Identitet i odgovornost | Samoodređenje; opravdavanje odluke; kritika nedosljednosti aktera | Isti akter ili iskaz odbija stranku, ali prihvaća načela. |
| Osoba i opće dobro | Dostojanstvo, prava, odgovornost zajednice; određeni korisnik ili problem | Pojam ostaje u sloganu ili označuje čast pojedine organizacije. |
| Solidarnost, rad i gospodarstvo | Radni uvjeti, siromaštvo, javna zaštita, odnos tržišta i odgovornosti | Solidarnost je samo dio naziva ili popisa vrijednosti. |
| Supsidijarnost i vlast | Obrazložen odnos osobe, obitelji, udruga, lokalne vlasti, države i EU-a | Razine vlasti samo su nabrojane, bez načela raspodjele odgovornosti. |
| Obitelj, savjest i sloboda | Obrazloženje konkretne prosudbe, prava ili mjere | Isti rječnik podupire različite ili suprotstavljene prosudbe. |
| Europa, nacija i pluralizam | Odnos europske suradnje, nacionalnog identiteta i demokratskog poretka | Navod o stranoj stranci ne govori o domaćem političkom stavu. |

## Tri provjerljive pretpostavke

**P1.** Formule identiteta mogu biti učestale zbog prenošenja malog broja izjava. Provjera: promjena njihova ranga nakon kontrole citata i najvećeg izvora. Stabilan rang u različitim formulacijama oslabio bi objašnjenje ponavljanjem.

**P2.** Načela mogu biti povezana s problemima i izvan tema čiji naziv zvuči programski. Provjera: kodirati primjenu neovisno o NMF temi; pokazati potvrđene i promašene veze.

**P3.** Negativan jezični ton može pratiti afirmaciju tradicije i kritiku stranke. Provjera: u istom iskazu odvojiti cilj procjene i govornika. Ako se takvi kontrasti ne potvrde, ne isticati ih kao opći obrazac.

Pitanja o odsutnim idejama ostaju ograničena na dostupni odabrani tekst. Za tvrdnju o cijelom javnom govoru potreban je zaseban dizajn obuhvata.

<!-- PAGE: 06 | Tekstualni sloj -->
# Svaki nalaz mora voditi natrag do teksta

**Glavna jedinica za leksičke module:** jedan predstavnik svake od 2.253 postojeće skupine jednakog teksta. Zadržati prethodno pravilo izbora predstavnika. Za broj medijskih objava ostaje jedinica arhivski zapis; nijedna od tih jedinica nije automatski jedna izjava ili priča. [L1-L2]

## Dva jasno odvojena opsega čitanja

**Lokalni opseg:** za usporedive jezične izračune koristiti izvorne rečenice koje dodiruju dokazne prozore. Preklapanja unutar polja objediniti. Po potrebi proširiti na jednu neposredno prethodnu i sljedeću rečenicu, ali prošireni opseg objaviti kao zasebnu osjetljivost.

**Širi opseg:** za kodiranje argumenta pročitati cijeli dostupni očišćeni tekst, uz naslov. Potvrditi vezu argumenta s demokršćanskim referentom; nepovezani odlomak istoga članka ne prenosi mu automatski značenje. Dugi prijepis i isječak dobivaju oznaku ograničenosti.

| Tablica | Minimalna polja i pravilo |
|---|---|
| documents | record_key, exact_group, datum, platforma, pravilo uključivanja, text_basis; naziv izvora naknadno povezati iz privatnih kandidata |
| sentences / tokens | field, sentence_id, izvorni raspon, token, lemma, upos, negacija; položaji vrijede u istom normaliziranom polju |
| phrase_hits | verzija rječnika, phrase_id, početak i kraj; fraza ne prelazi granicu polja ili izvorne rečenice |
| claims / codes | claim_id, exact_group, govornik, cilj, načelo, problem, veza, status, dokazni raspon, koder i verzija pravila |

## Hrvatski jezik i metapodaci

Zadržati dijakritike i izvorni oblik uz lemu. Provjeriti oblike demokršćanstva, supsidijarnosti, stranaka i osobnih imena. Hrvatski popis funkcijskih riječi prilagoditi zadatku: ne uklanjati automatski ne, nije, protiv, ali ni ključne glagole argumentacije. Fraze prepoznavati prije filtriranja tokena. [1, 3]

Sadašnja datoteka documents.jsonl nema source_name, URL ni autora. Naziv izvora može se povezati iz privatnih kandidata uz provjeru ključa 1:1; URL i autor nisu preduvjet jezgre. Izdavač nije govornik. Redci bez teksta ili s nepoznatim izvorom ostaju u evidenciji nedostajućih podataka. [L2]

<!-- PAGE: 07 | M1 / razlikovni rječnik -->
# Što je često, a što sadržajno razlikovno?

**Doprinos:** pokazati rječnik koji postojeća tematska karta ne prikazuje izravno. Za svaki pojam odvojiti broj pojavljivanja, broj tekstova, broj razdoblja i broj različitih formulacija. Riječ koju mnogo puta ponavlja jedan dugi tekst ne smije izgledati široko zastupljeno.

## Izračun i unaprijed određene usporedbe

1. Iz lokalnog opsega svakog predstavnika izvesti brojanja lema i zasebno brojanja fraza. Prikazati dokumentnu učestalost i učestalost na 10.000 zadržanih leksičkih tokena, uz navedeni nazivnik. Naslove ne dodavati ponovno ako su već dio tijela.
2. Izračunati TF-IDF po tekstualnoj skupini. Zbirni rang koristiti kao prosjek preko svih skupina, uključujući nule; sačuvati i pojedinačne rezultate. Za sadržajne osi prikazati 10-15 kandidata, uz potporu i kontrastne kontekste. Nazivlje uključivanja i vlastita imena prikazati zasebno. [2]
3. Primarni vremenski kontrast: web 2021. prema webu 2023., unutar starog režima. Polazni brojevi jesu 516 i 275 zapisa; broj predstavnika tek će se izvesti. Dopunski kontrast: siječanj-kolovoz 2025. prema istim mjesecima 2026., ako obje strane imaju barem 50 predstavnika. [L2]
4. Težinski log-omjer izgleda računati na istom rječniku i točno dvjema uspoređenim skupinama; prior iz njihova združenog korpusa. Uz rang pokazati broj tekstova i veličinu razlike. Prag z-vrijednosti ne koristiti kao dokaz statističke značajnosti. [7]
5. Nakon kodiranja M3 istražiti razlike između tekstova s potvrđenom primjenom i tekstova s identitetskom uporabom bez nađene primjene. Iz tog kontrasta izostaviti izravne riječi koje definiraju kodove; rezultat ipak ostaje opis uvjetovan kodiranjem.

## Kontrole i prikaz

U vremenskom kontrastu brojiti jednu skupinu teksta jednom u svakom razdoblju u kojem je zabilježena, prema svim članovima skupine. Navesti broj skupina prisutnih na obje strane i ponoviti usporedbu bez njih. Glavni popis traži najmanje 10 različitih tekstova; kontrolni pragovi su 5 i 20. Rijetka načela ulaze u zasebne kartice primjera; visok TF-IDF tipfelera nije nalaz.

Ponoviti rangove bez najdužeg potpornog teksta, bez najvećeg izvora i bez najraširenijeg jednakog citata; prikazati osjetljivost na površinski oblik naspram leme. Vremenski kontrast ostaje opis arhive i nakon tih kontrola.

**Izlaz:** poravnate ljestvice pojmova s brojem tekstova i razlikovnim rezultatom; dodatna tablica svih kandidata. **Rezervni ishod:** učestalosti i pregledani konteksti kada usporedive skupine nisu dovoljno velike.

<!-- PAGE: 08 | M2 / fraze i odnosi -->
# Od vrijednosne formule do jezične veze

**Pitanje:** jesu li solidarnost, Europa, obitelj ili sloboda povezane u više različitih obrazloženja ili se ponavlja ista politička formulacija? Postojeći NPMI ostaje referenca; novi doprinos jesu izvorni nizovi riječi i klasifikacija njihove funkcije. [3; L1]

## Operativni postupak

1. Iz potpunoga slijeda tokena unutar svake rečenice izvesti bigrame i trigrame. Izvorni niz sačuvati uz lematizirani. Fraze poput socijalnoga tržišnog gospodarstva i općega dobra prepoznati pravilima najduljega podudaranja. Četiri ili više riječi dodati samo kao unaprijed navedenu frazu.
2. Odvojiti usmjerene susjedne riječi od neusmjerenog supojavljivanja u rečenici. Niz nastao nakon brisanja međuriječi nije izvorni bigram. Povezivanje udaljenih dokaznih odlomaka nije dopušteno.
3. Potporu fraze brojiti jednom po točnom tekstu. Uz n navesti udio najveće jednake rečenice i broj tekstova preostalih nakon njezina uklanjanja. Zasebno provjeriti jednakost slijeda riječi bez interpunkcije.
4. Za unaprijed zamrznut skup pojmova usporediti NPMI s phi koeficijentom na istoj binarnoj matrici rečenica. U matrici moraju ostati i rečenice bez ijednog od odabranih pojmova; prazni redci ne smiju nestati pri pretvorbi. Nedefinirana vrijednost ostaje nedostajuća. [3, 5]
5. U glavnu tablicu ulaze veze s potporom barem 10 tekstova. Za svaku narativno istaknutu vezu pročitati do 10 različitih potpornih tekstova, sve ako ih je manje, uključujući barem jedan rubni ili negativni slučaj kada postoji.

## Čitanje funkcije

Svaki pregledani slučaj označiti kao nabrajanje vrijednosti, povezano obrazloženje, razlikovanje pojmova, osporavanje, navod bez jasne atribucije ili neodređeno. Ista fraza u citatu i njezino pobijanje ne daju jednak sadržajni nalaz.

**Izlaz:** ljestvica 15-20 fraza te kartice šest pregledanih odnosa. Ako mreža do 20 pojmova ostane čitljiva, debljina veze prikazuje samo jednu navedenu mjeru, a oznaka broj tekstova. Središnjost mreže neće se tumačiti kao ideološka važnost.

**Rezervni ishod:** tablica odnosa bez mreže. Veza koja nestane nakon uklanjanja jedne formulacije opisuje njezin odjek; nije dokaz široko raspršenog argumenta. Odsutna veza nije dokaz nespojivosti ideja.

<!-- PAGE: 09 | M3 / sadržajni kriteriji -->
# Kada načelo postaje javni argument?

**Glavni sadržajni modul** razdvaja spominjanje, objašnjenje načela i primjenu na konkretno pitanje. Jedan tekst može sadržavati više razina i više suprotstavljenih glasova. Ne ocjenjuje se politička ispravnost niti iskrenost aktera.

| Sloj koda | Kriterij za potvrdu | Granični slučaj |
|---|---|---|
| Demokršćanski referent | Izričit naziv ili nedvosmislena veza u okolnom iskazu | Kršćansko ili konzervativno nije automatski demokršćansko. |
| Identitetska uporaba | Pripadnost, pozicioniranje ili opis tradicije kao političke oznake | Spominjanje naziva stranke može biti samo vijest o događaju. |
| Načelo: imenovano / objašnjeno | Prepoznatljiv naziv / iskaz koji razlaže njegovo značenje | Personalističko vodstvo nije dokaz personalističkog načela. |
| Problem ili područje | Određeno društveno pitanje, institucija, odnos ili odluka | Općenito obećanje boljeg društva nije određena primjena. |
| Argumentacijska veza | Načelo služi kao izričit razlog, kriterij ili prigovor uz problem i prosudbu | Dvije riječi u istom odlomku nisu dovoljne. |
| Status | Potvrđeno; nije nađeno u dostupnom tekstu; nije moguće procijeniti | Prekratak isječak i nejasan govornik ne kodiraju se kao nula. |

## Početni sadržajni rječnik

**Načela i vrijednosti:** ljudsko dostojanstvo, opće dobro, solidarnost, supsidijarnost, sloboda i odgovornost, pravednost, sudjelovanje. Pojmovi služe pronalaženju kandidata; značenje potvrđuje iskaz. [8]

**Politička i programska uporišta:** demokratski pluralizam, europska suradnja, socijalno tržišno gospodarstvo te odnos religije i politike. Voditi ih odvojeno od socijalnih načela; EPP-ova platforma iz 2012. daje jedan dokumentirani primjer njihova povezivanja. [9]

**Područja primjene:** rad i gospodarstvo; siromaštvo i socijalna zaštita; obitelj i obrazovanje; savjest i prava; organizacija vlasti; Europa i međunarodni odnosi; druga područja otkrivena pilotom.

Nova kategorija može nastati tijekom pilota, uz definiciju i negativni primjer. Nakon zamrzavanja kodne knjige ne dodaje se samo zato što bi proizvela poželjan nalaz; promjena zahtijeva novu verziju i ponovno kodiranje zahvaćenih jedinica.

<!-- PAGE: 10 | M3 / dokaz i mjerenje -->
# Povezana tvrdnja, jasan nazivnik

Za svaki kandidat zapisati **tko govori, o kojem problemu, na koje se načelo poziva, kakvu prosudbu ili mjeru obrazlaže i gdje je dokaz u tekstu**. Rečenica je početni raspon; neposredni kontekst smije ga proširiti kada veza ostaje provjerljiva.

## Primjeri odluke za kodere

Sljedeći su primjeri namjerno konstruirani za kodnu knjigu. Nisu citati ni novi nalazi iz korpusa.

| Konstruirani iskaz | Predložena odluka |
|---|---|
| Naša je stranka demokršćanska; važne su nam obitelj i solidarnost. | Identitet i imenovanje vrijednosti; konkretna primjena nije nađena. |
| Zbog dostojanstva radnika, koje povezujemo s demokršćanskim načelima, tražimo sigurnije uvjete rada. | Povezana primjena: dostojanstvo, uvjeti rada, zahtjev i izričit razlog. |
| Stranka se zove demokršćanskom, ali svojim odlukama zanemaruje solidarnost. | Kritika dosljednosti. Primjena se potvrđuje tek ako dostupni kontekst određuje odluku ili problem. |
| Solidarnost je važna. U drugom dijelu članka piše o izborima. | Nema dokazane veze s izborima ni automatske atribucije demokršćanstvu. |

## Tri odvojena rezultata

**Udio tekstova s nađenom primjenom:** svaki odabrani točan tekst najviše jednom u brojniku; nazivnik su svi tekstovi obuhvaćeni procjenom. Na uzorku koristiti težine sa str. 13. Uz potvrđeno uvijek prikazati neprocjenjivo; ne brisati ga iz nazivnika bez prikaza alternativnog izračuna.

**Matrica načelo × problem:** ćelija broji tekstove s barem jednom potvrđenom vezom tog para. Više načela i problema može postojati u istom tekstu. Ćelije se ne zbrajaju u ukupan broj tekstova niti u 100%.

**Dubina obrazloženja:** prikazati odvojeno samo imenovanje, razlaganje značenja i konkretnu primjenu, uz preklapanja. Ne praviti jedinstveni bodovni indeks kvalitete, autentičnosti ili relevantnosti demokršćanstva.

**Izlaz:** matrica veza i četiri do šest kontrastnih kartica argumenta, uključujući negativni primjer. Bez dostatne pouzdanosti ljudskog kodiranja ostaju kartice i precizno ograničen opis pregledanog materijala.

<!-- PAGE: 11 | M4 / ton i cilj procjene -->
# Kritika čega, iz čije perspektive?

Jedinstvena ocjena pozitivnog ili negativnog teksta može pomiješati tradiciju, stranku, osobu i konkretnu mjeru. Zato je jezgra ovoga modula **stav prema određenom cilju**, a leksički sentiment samo moguća pomoćna mjera. [4; L1, str. 14]

## Primarna analiza: kodiranje iskaza

Za svaki interpretabilni iskaz kodirati cilj: demokršćanska tradicija, konkretna stranka ili osoba, načelo, javna politika ili drugi cilj. Govornu ulogu odrediti iz atribucije: citirani akter, autorski/novinarski glas, kolektivno priopćenje ili nejasno. Ne zaključivati govornika iz pukog spomena imena.

Stav prema cilju: afirmacija, kritika/odbacivanje, mješovit stav, opis bez vrednovanja ili neodređeno. Odvojeno označiti samopripadnost i osporavanje dosljednosti. Neslaganje sa strankom nije automatski negativan stav prema tradiciji.

**Prikaz:** tablica kontrasta unutar istog iskaza ili tekstualne skupine, s brojem potvrđenih slučajeva. Za udjele koristiti tekstove s procjenjivim ciljem i jasno navesti taj uži nazivnik, uz udio neprocjenjivih u punom uzorku. Bez rangiranja građana, publika ili političkog utjecaja.

## Dopunski pilot: hrvatski leksički sentiment

Lokalno postoji CroSentiLex; LiLaH je mogući drugi resurs nakon provjere potrebnih kategorija. Engleski AFINN, Bing i NRC iz primjera knjige ne primjenjuju se izravno na hrvatski tekst. Prije uporabe provjeriti format, duplikate, proturječne oznake i verziju resursa. [4; L4]

U pilotu mjeriti pokrivenost tokena, broj prepoznatih riječi po rečenici i doprinos najutjecajnijih riječi. Probni rezultat tona jest (broj pozitivnih - broj negativnih) / broj prepoznatih polarnih tokena. Kada je taj nazivnik nula, rezultat je nedostajući. Slaba pokrivenost zasebno se označuje.

Provjeriti ne, nije, nikad, bez, navodnike, ironiju i suprotne veznike. Ne okretati mehanički polaritet svih riječi nakon negacije. Ako se izvodi sentiment, iz razvojnog materijala izdvojiti barem 80 raznolikih iskaza, po mogućnosti unutar 60 pilot-tekstova sa str. 13. Usporediti rezultat s čitanjem, dokumentirati pogreške i zamrznuti pravila prije neovisne provjere.

**Uvjet uključivanja:** ton ulazi u dopunu samo ako donese interpretabilnu informaciju povrh kodiranog stava. U protivnom ostaju nalaz o ograničenju leksikona i primjeri; ne objavljuje se prividna ljestvica podrške demokršćanstvu.

<!-- PAGE: 12 | M5 / raspršenost i vrijeme -->
# Trajan argument ili kratki odjek?

**Pitanje:** pojavljuje li se isti sadržaj u više tekstova, formulacija i razdoblja? Nadogradnja se odnosi na trajnost konkretnoga jezičnog ili kodiranog sadržaja; osnovna vremenska serija vidljivosti već postoji. [L1-L2]

## Četiri mjere koje se čitaju zajedno

**Raspon kroz vrijeme:** broj tromjesečja s pojavom / broj tromjesečja s dostupnim uključenim tekstovima unutar prikazanog režima i platforme. Uz to prikazati broj potpornih tekstova po ćeliji. Prisutnost skupine pratiti kroz sve njezine zapise, ne samo datum predstavnika; jednom po ćeliji, uz nezbrojivost kroz vrijeme. Mjera ne izjednačuje mali i veliki uzorak.

**Koncentracija izvora:** udio potpore koji dolazi iz najvećeg imenovanog izvora i broj ostalih izvora. Nepoznati izvori zasebno; rezultat nije broj različitih govornika. Povezivanje source_name potrebno je prije ove mjere.

**Koncentracija formulacije:** udio tekstova koji sadrže najčešću jednaku potpornu rečenicu, uz kontrolu nizom riječi bez interpunkcije. Rukom pregledati vodeće primjere parafraza; automatska različitost teksta ne dokazuje različitost argumenta.

**Osjetljivost na vrh:** izostaviti najbrojniji potporni mjesec, najveći izvor i vodeću formulaciju, svako zasebno. Zabilježiti mijenja li se smjer usporedbe i koliko potpore ostaje. Ne birati samo kontrolu koja održava prvotni zaključak.

## Pravila usporedbe

Vremenske prikaze razdvojiti na režime prije i od 1. travnja 2024. Posljednji mjesec završava 10. rujna 2026. Za usporedbu posljednjih godina koristiti jednake pune mjesece; nepotpunu 2026. ne uspoređivati s cijelom 2025. Arhivski datum ne dokazuje datum nastanka ni smjer širenja izjave.

Primarni opis na webu; druge platforme zasebno prema veličini i pokrivenosti. U ćelijama s manje od 20 jedinica pokazati broj i oznaku malog obuhvata. Nula se razlikuje od nepostojanja usporedivih podataka. Načela kodirana samo na uzorku ne pretvarati u glatku mjesečnu seriju.

## Uloga postojećih tema

Deset NMF tema služi navigaciji i provjeri gdje argumenti presijecaju postojeće kategorije. Novi LDA model razmatra se samo ako pilot duljih koherentnih tekstova otkrije nerazriješenu sadržajnu podjelu. Koristi brojanja, unaprijed zadane k = 8, 10, 12 i tri početka; dokumentira stabilnost i primjere. Kratki spojeni prozori i promjena etikete nisu razlog za novi model. [6]

<!-- PAGE: 13 | Validacija i uzorak -->
# Kako do udjela kojima se može vjerovati

**Leksički moduli mogu se izvesti odmah.** Kvantifikacija složenih sadržajnih kodova traži dokumentiranu procjenu čitatelja. Postojeći razvojni skup od 140 konteksta koristan je za učenje pravila. Postojećih 200 slijepih jedinica potječe iz preostalih 1.556 približnih klastera; njihovi ponderi ne predstavljaju svih 2.253 točnih tekstova. [L3]

## Predloženi novi dizajn za M3 i M4

**Pilot:** dvije osobe neovisno kodiraju 60 tekstova iz razvojnog materijala, ciljano uključujući rijetke pojmove, negaciju i nejasnu atribuciju. Usklađuju definicije i dopunjuju negativne primjere. Pilot nije procjena udjela.

**Glavni uzorak:** 400 točnih tekstualnih skupina iz punog okvira od 2.253. Stratumi: A1 naspram ostalih putova × web naspram ostalih platformi × režim prije/od 1. 4. 2024. Pripadnost skupine odrediti metapodacima njezina fiksnog predstavnika. Za grupu s više režima ili platformi sačuvati i zasebnu oznaku višestruke prisutnosti.

U svakom nepraznom stratumu prvo dodijeliti min(10, N_h), zatim ostatak do 400 proporcionalno preostalom broju jedinica, metodom najvećih ostataka uz ograničenje kapaciteta. Nasumični izbor bez vraćanja, zabilježen seed 20260920. Težina w_h = N_h / n_h. Uzorak se bira iz cijelog okvira, a ne samo iz tekstova s rječničkim pogotkom.

Dva čitatelja kodiraju istih 400 tekstova bez prikazanih AI oznaka i rezultata drugog čitatelja. Sačuvati prvotne odluke, slaganje, razloge neslaganja i usuglašenu odluku. To znači **800 neovisnih kodiranja**, uz pilot i razrješenje sporova; vrijeme po jedinici izmjeriti u pilotu.

## Pouzdanost, procjena i neizvjesnost

Za osnovne kodove prikazati matricu slaganja, postotak slaganja i Krippendorffov alpha, s brojem slučajeva po klasi. Predloženi projektni kriterij za kvantitativni glavni nalaz jest alpha ≥ 0,80; ako je mjera nedefinirana ili broj pozitivnih slučajeva manji od 20, zadržati oprezan prikaz brojeva i primjera. To su projektna pravila za pregled, ne univerzalni standardi.

Udjele računati iz usuglašenih kodova s težinama i intervalima koji uvažavaju stratificirani izbor te konačan okvir. Interval opisuje nesigurnost uzorkovanja unutar zamrznute zbirke; ne pokriva pogreške odabira arhive ili kodiranja.

Novi uzorak može sadržavati ranije pročitane razvojne tekstove: valjan je za opisnu procjenu uz slijepo ljudsko čitanje, ali nije automatski neovisni test klasifikatora. Eventualni klasifikator mora imati zaseban netaknut test, bez podijeljenih kopija i citata između razvoja i testa.

<!-- PAGE: 14 | Kontrole i granice tvrdnji -->
# Što mora izdržati svaki važan nalaz

| Rizik | Obvezna provjera | Ako nalaz ne izdrži |
|---|---|---|
| Korpus je izabran riječima koje zatim analiziramo | Cjelina prema A1; selekcijsko nazivlje odvojeno od ostalih riječi | Nalaz označiti kao povezan s pravilom uključivanja. |
| Ista izjava dominira različitim člancima | Točni tekstovi, najčešća rečenica, niz riječi bez interpunkcije, postojeći pragovi sličnosti | Prikazati odjek formulacije; ne tvrditi širinu argumenta. |
| Lokalni prozor izostavlja obrazloženje | Na istim kodiranim tekstovima usporediti lokalni i cijeli dostupni opseg | Prikazati koliko je kodova osjetljivo na skraćenje; ne zaključiti odsutnost. |
| Duljina i sastav izvora stvaraju razliku | Udio tekstova, normalizirana učestalost, web zasebno, izostavljanje najvećeg izvora | Sužavanje zaključka na uspoređeni sastav zbirke. |
| Lema ili šablona proizvodi lažni pojam | Površinski oblik, izvorni raspon, pregled vodećih i rubnih pogodaka | Ispraviti izvedeni sloj uz novu verziju; izvorno izdanje sačuvati. |
| Mali uzorak stvara uvjerljivu sliku | Brojevi uz sve udjele; jednake vremenske granice; neprocjenjivo vidljivo | Brojevi i kartice umjesto rangiranja i glatkih krivulja. |
| Ljudsko i automatsko čitanje ne daju iste kodove | Odvojeni pilot i test; metrike po kodu, ne samo ukupno slaganje | Automatski sloj ostaje tražilica kandidata. |

## Dodatno pravilo za automatizaciju sadržajnih oznaka

Ako se nakon pilota predloži automatsko kodiranje svih tekstova, za svaki kod tražiti neovisnu provjeru preciznosti i odziva, s najmanje 20 pozitivnih referentnih slučajeva. Početni projektni prag za oba pokazatelja jest 0,80; prikazati intervale i stvarne brojeve pogrešaka. Prolazak nije jamstvo za druge platforme ili razdoblja.

Rijetki kodovi ostaju ručno pregledani. Udio automatskih oznaka ne izjednačavati s procijenjenim stvarnim udjelom bez obrade klasifikacijskih pogrešaka. Glavna procjena sadržaja može ostati na ponderiranom ljudskom uzorku i kada postoji klasifikator.

**Najjača dopuštena tvrdnja:** određena argumentacija pojavljuje se u pregledanom ili procijenjenom dijelu odabrane arhivske zbirke. Ovim podacima ne mjerimo potporu građana, iskrenost političara, uzročni učinak ideja ni reprezentativan udio svih medija.

<!-- PAGE: 15 | Vizualni nacrt dopune -->
# Jedna istraživačka priča, osam prikaza

Vizualni jezik slijedi izvorni PDF: topla svijetla podloga, tamnozelena tipografija, bakreni naglasci, serifni naslovi i čitljive tablice. Svaki prikaz počinje pitanjem, a završava jedinicom, nazivnikom, izvorom i najvažnijom granicom tumačenja.

| Prikaz | Sadržaj i vizualni oblik | Uvjet za prikaz |
|---|---|---|
| A. Rječnik tradicije | Dvije poravnate ljestvice: raširenost i razlikovnost; broj tekstova uz pojam | M1; zamrznut rječnik i dvije usporedive skupine |
| B. Formule i fraze | Točkasti prikaz potpore prije i nakon uklanjanja vodeće formulacije | M2; isti nazivnik i navedeni preostali broj |
| C. Karta odnosa | Mala matrica ili mreža do 20 pojmova; mjera veze i potpora | M2; pregledan smisao istaknutih veza |
| D. Načela i problemi | Matrica potvrđenih veza; udjeli samo uz ponderiranje i pouzdanost | M3; validirani kodovi, vidljiva višestruka pripadnost |
| E. Anatomija argumenta | Kartice: načelo, problem, prosudba, govornik, dokaz i protuprimjer | M3; čitanje dostupnog konteksta |
| F. Dva cilja, različit stav | Usporedne oznake stava prema tradiciji i akteru u istom slučaju | M4; jasna atribucija; bez prosječnog sentimenta teksta |
| G. Trajnost sadržaja | Matrica tromjesečja uz broj potpornih tekstova i granicu režima | M5; za kodirani uzorak samo dovoljno velike cjeline |
| H. Koliko je priča stabilna? | Sažeta tablica nalaza, kontrola i promjene tumačenja | Svi moduli; uključiti i neuspjele provjere |

## Predložena struktura konačne dopune

**Otvaranje, 2 stranice:** istraživačko pitanje, nova vrijednost u odnosu na izvještaj i sažetak stvarnih nalaza. **Rječnik i formule, 3-4 stranice:** A-C. **Načela, argumenti i stav, 4-5 stranica:** D-F. **Trajnost i provjere, 2-3 stranice:** G-H. **Metode i izvori, 3-4 stranice:** jedinice, kodna knjiga, uzorak i ograničenja. Ukupno približno 14-18 stranica, ovisno o potpori nalazima.

Ne popunjavati predloške izmišljenim postocima ili primjerima koji se prikazuju kao stvarni. U ovom planu nema simuliranih empirijskih grafikona. U konačnom dokumentu isti pojam zadržava istu oznaku, a svaki citirani ili parafrazirani slučaj ima privatni dokazni trag.

<!-- PAGE: 16 | Provedba i isporuke -->
# Radni slijed s jasnim završecima

| Korak | Posao i ovisnost | Mjerljiv izlaz |
|---|---|---|
| 1. Zamrznuti specifikaciju | Zabilježiti verziju plana, ulaze, opsege teksta i kriterije prikaza | manifest ulaza, registar pitanja i jedinica |
| 2. Povezati i urediti tekst | Iskoristiti postojeće predstavnike i tokene; povezati izvor; anotirati proširenja | documents, tokens, tablica nedostajućeg i izvještaj povezivanja |
| 3. Izvesti M1 i M2 | Zamrznuti fraze i pravila nakon pregleda pogrešaka | rječnički profili, fraze, tablice veza, kartice kandidata |
| 4. Pilotirati kodnu knjigu | Dva čitatelja; definicije načela, veze, cilja i atribucije | codebook v1, pilot odluke i razlozi izmjena |
| 5. Kodirati glavni uzorak | Nasumičnih 400 skupina; dvije neovisne odluke po jedinici | dizajn uzorka, koderske odluke, slaganje i usuglašeni kodovi |
| 6. Sastaviti M3-M5 | Ponderirane procjene i raspršenost; provjere stabilnosti | tablice nalaza s nazivnicima, neizvjesnošću i rezervnim ishodom |
| 7. Urediti dopunu | Odabrati prikaze koji odgovaraju na pitanja; provjeriti svaku tvrdnju | samostalan PDF, izvori, agregati, registar tvrdnji i provjera svih stranica |

## Dvije razine izvedbe

**Računalna i istraživačka jezgra:** M1, M2, leksička raspršenost M5, kodna knjiga i odabrani argumentacijski primjeri s navedenim načinom čitanja. Ako ljudski čitatelji nisu uključeni, rezultat nosi taj status i ne prikazuje potvrđene udjele složenih kodova.

**Puna sadržajna dopuna:** prethodno plus neovisno kodiranje M3/M4 i ponderirane procjene. Potreban je angažman dvaju čitatelja; trošak se procjenjuje prema pilotu, broju i duljini tekstova. Neizvediv dopunski model ne zaustavlja osnovne module.

## Organizacija novih izlaza

Predloženi kod: studies/demokrscanstvo-barometar/text-addendum/. Agregati i dokumentacija: output/demokrscanstvo-text-addendum/v1/. Tekstovi, identifikatori, rasponi i pojedinačne koderske odluke ostaju u novoj privatnoj radnoj mapi.

Izlazni paket uključuje README, manifest, verziju rječnika i kodne knjige, renv/sessionInfo za R, seed, tablice, slike i registar tvrdnji. Postojeći PDF i njegova zamrznuta izdanja ostaju referentno polazište. Ovaj sadašnji dokument jest plan za pregled, a ne izvršena dopuna.

<!-- PAGE: 17 | Mjere i tehnički ugovor -->
# Jedinice, nazivnici i provedba u R-u

| Rezultat | Definicija | Kritična provjera |
|---|---|---|
| Dokumentna učestalost | Broj točnih tekstova s pojmom / svi analizirani točni tekstovi istog opsega | Tekst se broji jednom; nedostajući opseg nije nula. |
| Normalizirana frekvencija | 10.000 × broj pojavljivanja / broj zadržanih tokena | Jednaka pravila filtriranja; zasebno objaviti nazivnike. |
| TF-IDF | tf(t,d) = n(t,d) / zbroj svih n u d; idf(t) = ln(N / df(t)); umnožak tf i idf | N i df iz istog zamrznutog skupa nepraznih dokumenata. Ovo nije postojeća sublinearna NMF težina. |
| NPMI | ln[p(a,b)/(p(a)p(b))] / -ln[p(a,b)] | Isti svemir rečenica; samo 0 < p(a,b) < 1. |
| Phi | (a×d - b×c) / sqrt[(a+b)(c+d)(a+c)(b+d)] | a: oba pojma; b/c: samo jedan; d: nijedan. Nulti nazivnik ostaje nedostajući. |
| Udio potvrđene primjene | Zbroj w_i × I(potvrđeno) / zbroj w_i | Ponderi iz uzorka svih točnih tekstova; neprocjenjivo posebno prikazano. |
| Potpora para načelo-problem | Tekstovi s barem jednom potvrđenom vezom toga para | Matrica je višestruka; njezine ćelije nisu particija korpusa. |

## Predloženi alati, bez nepotrebne promjene postojećeg sustava

**dplyr / tidyr:** povezivanje i sažeci; **udpipe:** postojeće hrvatske leme i nova proširenja; **tidytext:** frekvencije, bind_tf_idf() i pretvorbe matrica; **tidylo:** bind_log_odds(); **ggplot2:** prikazi. Za phi koristiti eksplicitnu matricu s potpunim svemirom rečenica ili provjeriti da poziv widyr daje isti nazivnik. [1-3, 5, 7]

**survey:** procjene uz stratume, pondere i korekciju konačne populacije. **topicmodels::LDA():** samo uvjetna provjera na brojanjima. Postojeće NMF komponente i IDF ostaju pohranjene bez zamjene. Zaključati stvarno korištene verzije u provedbi, ne preuzimati pretpostavljene verzije iz primjera knjige. [6]

**Obvezne strojne provjere:** jedinstvenost ključeva; spajanje 1:1; poklapanje tokena i izvornog raspona; nepovezivanje polja; točno brojanje fraza; očuvanje praznih jedinica u nazivniku; zbroj pondera 2.253; reproducibilnost izračuna i brojki prikazanih u PDF-u.

<!-- PAGE: 18 | Izvori i status -->
# Literatura i trag provjere

Metode su odabrane iz pregledanih mrežnih poglavlja; formulacije pitanja, uzorkovanje, pragovi i odluke o prikazu prijedlog su ovoga projekta. Poveznice provjerene 19. rujna 2026.

1. **Silge, J. i Robinson, D. Text Mining with R, pogl. 1.** Tidy text i veza tokena s metapodacima. [Otvoriti poglavlje](https://www.tidytextmining.com/tidytext).
2. **Isti autori, pogl. 3.** Učestalost, dokumentna učestalost i TF-IDF. [Otvoriti poglavlje](https://www.tidytextmining.com/tfidf).
3. **Isti autori, pogl. 4, osobito 4.1 i 4.2.2.** N-grami, odnosi riječi i phi. [Otvoriti poglavlje](https://www.tidytextmining.com/ngrams).
4. **Isti autori, pogl. 2.** Leksički sentiment, ograničenja negacije i veličine jedinice. [Otvoriti poglavlje](https://www.tidytextmining.com/sentiment).
5. **Isti autori, pogl. 5.** Pretvorbe između tablica i matrica. [Otvoriti poglavlje](https://www.tidytextmining.com/dtm).
6. **Isti autori, pogl. 6.** LDA i pregled pripadnosti riječi i dokumenata temama. [Otvoriti poglavlje](https://www.tidytextmining.com/topicmodeling).
7. **tidylo, dokumentacija bind_log_odds().** Regularizirani težinski log-omjer izgleda; usporedba skupa s ostalima. [Otvoriti dokumentaciju](https://juliasilge.github.io/tidylo/reference/bind_log_odds.html).
8. **Papinsko vijeće Iustitia et Pax (2004). Kompendij socijalnog nauka Crkve.** Poglavlje IV, posebno 160-163, 164-170, 185-196; pojmovno uporište, ne klasifikator politike. [Otvoriti izvor](https://www.vatican.va/roman_curia/pontifical_councils/justpeace/documents/rc_pc_justpeace_doc_20060526_compendio-dott-soc_en.html).
9. **European People's Party (2012). Party Platform.** Dio I; političko samorazumijevanje jednoga aktera, povijesno datiran dokument. [Otvoriti izvor](https://www.epp.eu/files/uploads/2015/09/Platform2012_EN1.pdf).

## Lokalni izvori

**L1.** demokrscanstvo-analiticki-izvjestaj.pdf, 20 str., izdanje 1.0, 19. 9. 2026. SHA256 provjeren prema report manifestu; nije mijenjan.

**L2.** output/demokrscanstvo-analysis/v1/: summary.json, manifest.json, annual.csv, platforms.csv, lexical_summary.json, lexicon.json; privatni documents.jsonl i prepared.json; kod prepare.R. Broj 2.198 odnosi se na neprazno očišćeno polje body, provjereno za ovaj plan.

**L3.** human_validation_status.json i qualitative_review.md; postojeći protokol 2.0. Izričito razlikuju razvojno čitanje, pripremljeni uzorak i dovršenu validaciju.

**L4.** resources/README.md i PROVENANCE.csv; lokalni CroSentiLex i LiLaH. Njihova dostupnost nije dokaz valjanosti za politički stav u ovom korpusu.

**Status dokumenta:** dovršen prijedlog za pregled. Izrađeno uz pomoć Codex AI-ja. Nova sadržajna analiza, ljudsko kodiranje i predloženi grafikoni još nisu izvedeni.
