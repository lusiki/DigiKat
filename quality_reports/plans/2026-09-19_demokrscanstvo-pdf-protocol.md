# Demokršćanstvo u javnom govoru

## Analitički protokol i nacrt izvještaja

**Revidirani plan, izdanje 2.0 | 19. rujna 2026.**

Ovaj dokument utvrđuje pitanja, metode, kontrole i oblik budućeg analitičkog PDF-a. U ovom koraku provjereni su postojeći podaci, programska pravila i izvedivost. Nova analiza još se ne provodi. Plan zamjenjuje provedbeni dio ranijeg prijedloga `2026-09-19_demokrscanstvo-analytical-story.md`: prvo nastaje samostalan izvještaj, zatim slijedi njegova urednička procjena i tek potom odluka o odabranim sadržajima za barometar.

<!-- PAGE: 02 | Istraživačka priča -->
# Od političkog imena do javnog argumenta

**Središnje pitanje:** Kako se demokršćanstvo pojavljuje u zabilježenom javnom govoru: kao politički identitet, idejna tradicija i obrazloženje odgovora na društvena pitanja?

Vrijednost izvještaja proizlazi iz povezivanja triju razina: koliko je tradicija vidljiva, kakav joj sadržaj objave pridaju i u kojim se komunikacijskim okolnostima taj sadržaj pojavljuje. Niti jedan od tih nalaza nije unaprijed zadan.

| Dimenzija relevantnosti | Što ćemo opažati | Pitanje za čitatelja |
|---|---|---|
| Vidljivost | Broj uključenih objava i stopa unutar pripadajuće arhive | Koliko prostora zauzima ova rasprava? |
| Sadržajna širina | Teme i provjereno izražena načela | Koje se ideje povezuju s demokršćanstvom? |
| Primjena | Obrazložena veza načela i konkretnog problema | Što ta tradicija nudi u raspravama o društvu? |
| Komunikacijski kontekst | Platforma, uloga govornika, način pozivanja | Gdje i kako te ideje dobivaju značenje? |
| Trajnost i ponavljanje | Pojavljivanje kroz vrijeme, ponovljeni tekstovi i citati | Je li riječ o trajnoj raspravi ili odjeku nekoliko epizoda? |

Ovih pet dimenzija prikazujemo zasebno. Njihovo zbrajanje u jedan indeks relevantnosti prikrilo bi razliku između učestalog spominjanja i razvijenog argumenta. Podaci omogućuju priču o medijskom diskursu; podrška građana, doseg publike i politički utjecaj traže druge vrste podataka.

## Što je promijenjeno nakon provjere

- Ukupni brojevi po platformama više nisu osnova za obećanje detaljnih godišnjih usporedbi. U 2025. Facebook ima 14, a X 11 uključenih objava.
- Postojeća lematizacija ostaje ulaz za teme. Za veze riječi uvodi se zaseban sloj s rečenicama, izvornim položajima riječi, glagolima i negacijom.
- Postojeće oznake registra, zemljopisnog okvira i govornika ne preuzimaju se kao potvrđeni interpretativni nalazi.
- Razlikuju se objava, spojeni kontekst, izvorni odlomak i skupina srodnih tekstova. Broj 1.731 ne označuje broj različitih priča.
- Završni rezultat bit će samostalan PDF. Proširenje barometra dolazi nakon ocjene izvještaja.

**Preporuka:** tematska karta, načela i njihova primjena te kontrola ponavljanja čine jezgru. Mreža riječi, usporedbe platformi i glasovi ulaze u glavni izvještaj samo kada nude čitljiv i dovoljno potkrijepljen nalaz.

<!-- PAGE: 03 | Provjera podataka -->
# Što imamo na raspolaganju

Provjera 19. rujna 2026. obuhvatila je javne agregate, njihove SHA256 manifeste, postojeću dokumentaciju, klasifikacijski kod i strukturu privatnih međurezultata. Kontrolni zbrojevi obaju javnih izdanja odgovaraju datotekama. To potvrđuje integritet ulaza; valjanost novih interpretativnih oznaka provjeravat će se zasebno.

| Provjerena činjenica | Posljedica za plan |
|---|---|
| 2.306 uključenih objava; 1. 1. 2021. do 10. 9. 2026. | Konačan polazni skup za ovaj izvještaj. Ne ponavljamo pretragu cijele baze. |
| 41.397.670 pretraživih arhivskih zapisa | Nazivnik stopa vidljivosti. Tematske udjele računamo među uključenim objavama. |
| 2.211 objava uključeno eksplicitnim pravilom A1; 95 dodatnih drugim pravilima | Analiziramo cjelinu i A1 zasebno. Dodatnih 95 služe i za provjeru učinka selekcije. |
| 2.290 uključenih zapisa ima pohranjeno tijelo teksta; 16 isječak; nijedan samo naslov | Većina omogućuje kontekstualno čitanje. Naziv polja FULL_TEXT ne jamči potpun izvornik ili prijepis. |
| 2.306 spojenih konteksta; 1.731 različit spojeni kontekst | Identičnost konteksta smanjuje jezično ponavljanje, ali nije mjera identičnosti cijelog članka. |
| 10 NMF tema; 1.372 značajke; 1 nerazvrstana objava | Postoji upotrebljiva početna tematska karta. Nova interpretacija mora provjeriti granice tema. |
| ARI između postojećeg rješenja i tri druga početka: 0,53 do 0,66 | Stabilnost je umjerena. To nisu postoci točnosti ni ocjena kvalitete kodiranja. |

## Pristup tekstu je dovoljan; neke oznake tek treba izvesti

Privatni međurezultati povezuju identifikator zapisa, datum, platformu, izvor, naslov, pohranjeni tekst, pravila uključivanja i dokazne odlomke. Dostupno je 69 mjesečnih skupova kandidata i pripadajućih dokaznih datoteka. Povezivanje se ograničava na 2.306 uključenih zapisa.

Datoteke kandidata nemaju zasebna polja za URL ni autora. Analiza autorskih potpisa ili javni katalog poveznica stoga nisu dio jezgre. Identitet izdavača nije dokaz o tome tko govori u citatu. Za televiziju, radio i video analiziramo raspoloživi tekstualni zapis, bez pretpostavke da obuhvaća cijelu emisiju ili snimku.

Spojeni kontekst može sadržavati više udaljenih odlomaka. Medijan je 48 riječi prema razmacima, a raspon 2 do 1.099; 131 kontekst ima najviše 20 takvih riječi. Izvorni dokazni prozori imaju do 80 tokena. Njihovo spajanje ne stvara jednu dopuštenu jedinicu za računanje blizine riječi.

<!-- PAGE: 04 | Opseg i izvedivost -->
# Platforme: mogućnosti se mijenjaju s razdobljem

Ukupni brojevi opisuju sastav zbirke. Posljednja cjelovita kalendarska godina otkriva koliko je materijala stvarno dostupno za vremenski usklađenu usporedbu. Godina 2025. služi kao provjera izvedivosti, a nije automatski konačno analitičko razdoblje.

| Platforma | Sve uključene objave | Uključene u 2025. | Razumna početna razina prikaza |
|---|---:|---:|---|
| Web | 1.811 | 212 | Teme, načela, vremenski obrasci |
| X | 137 | 11 | Profil cijelog razdoblja; odabrani primjeri |
| Facebook | 108 | 14 | Profil cijelog razdoblja; odabrani primjeri |
| Tisak | 72 | 41 | Sažet profil zajedničkog razdoblja |
| Komentari | 56 | 0 | Brojevi uz provjeru pokrivenosti |
| Televizija | 28 | 17 | Šire kategorije ili primjeri |
| Radio | 27 | 1 | Brojevi i kontekstualni primjeri |
| Reddit | 26 | 7 | Sažet opis cijelog razdoblja |
| Forumi | 20 | 2 | Brojevi i kontekstualni primjeri |
| YouTube | 11 | 2 | Brojevi i kontekstualni primjeri |
| Instagram | 8 | 0 | Brojevi; bez rangiranja udjela |
| TikTok | 2 | 2 | Dva pojedinačna opažanja |
| Bluesky / Threads | 0 / 0 | 0 / 0 | Obuhvat, bez sadržajnog profila |

## Tri razine izvedbe

**Izravno izvedivo:** ponovno upotrijebiti mjesečne brojeve i stope, postojeće teme te agregate platformi. Prikazati i 2026. s jasnim završetkom 10. rujna; godišnji ukupan broj ne uspoređivati s cijelom prethodnom godinom.

**Izvedivo uz novi analitički sloj:** rečenice i višerječni pojmovi, skupine ponovljenih tekstova, potvrđena načela i veze s društvenim pitanjima. To je središnji novi doprinos izvještaja.

**Uvjetno izvedivo:** finije razlike između platformi, atribucija govornika, stav prema cilju i pojedine zemljopisne usporedbe. Njihov opseg određuju raspoloživi dokazi i rezultati pilot-kodiranja.

**Pravilo prikaza:** manje od 20 analiziranih jedinica znači brojeve i primjere; od 20 do 49 sažet profil; od 50 mogućnost detaljnijeg prikaza uz provjeru pojedinih ćelija. To su urednička pravila ovog projekta, a ne jamstvo preciznosti. Nula uključenih objava razlikuje se od nedostatne pokrivenosti.

<!-- PAGE: 05 | Analitičke jedinice -->
# Jedna objava može nositi više ideja

| Jedinica | Upotreba | Pravilo brojanja |
|---|---|---|
| Arhivska objava | Vidljivost i izloženost ponavljanju u zbirci | Svaki uključeni zapis jednom; nazivnik ostaje 2.306 za cjelinu. |
| Izvorna rečenica ili odlomak | Jezične veze i dokaz za oznaku | Čuvati granice polja i položaj u izvornom tekstu; ukloniti preklapanja. |
| Spojeni dokazni kontekst | Postojeća tematska klasifikacija | Zadržati postojeći model; udaljene dijelove ne spajati u jezičnu blizinu. |
| Skupina gotovo istih tekstova | Provjera koliko nalaz ovisi o ponovnom objavljivanju | Jedan reprezentativan tekst po provjerenoj skupini, izabran po fiksnom pravilu. |
| Skupina zajedničkog citata | Provjera odjeka izjave kroz različite tekstove | Odvojena veza; različite članke ne proglašavati istom pričom. |

## Kako utvrditi ponavljanje

Najprije označiti potpuno jednake normalizirane tekstove. Zatim kandidirati slične tekstove pomoću preklapanja nizova riječi i sličnosti duljine. Za cijele tekstove i kratke citate primjenjuju se odvojena pravila. Prag se podešava na pilotu, provjerava na parovima neposredno iznad i ispod praga i potom zamrzava.

Spriječiti ulančavanje skupina u kojem su A i B slični, B i C slični, ali A i C nisu. Reprezentativni tekst birati prema potpunosti i zatim stabilnom identifikatoru, bez biranja teksta koji najbolje podupire željeni nalaz. Za svaku skupinu pohraniti veličinu, raspon datuma, platforme i razlog spajanja.

Naziv "skupina srodnih tekstova" namjerno je uži od tvrdnje o jednoj novinarskoj priči. Ako se pouzdano prepoznaju samo identične kopije, glavni rezultat prikazuje upravo tu jednostavniju kontrolu. Objave koje obrađuju isti događaj mogu predstavljati različite argumente.

## Novi kodni sloj

Za svaku oznaku pohraniti: predmet kodiranja, pozitivni dokaz, vrstu dokaza, izvorni raspon teksta, status odluke, verziju pravila i recenzenta. Razlikovati "potvrđeno", "nije nađeno u dostupnom tekstu" i "nije moguće procijeniti". Ta se stanja ne stapaju u nulu.

Tema, načelo, društveno pitanje, funkcija pozivanja i govorna uloga različite su varijable. Teme dobivaju primarnu NMF oznaku radi usporedivosti, dok se načela i pitanja mogu preklapati. Njihovi postoci zato ne moraju imati zbroj 100. Načelo prisutno u više odlomaka objave za prevalenciju se broji jednom.

<!-- PAGE: 06 | Tematska analiza -->
# O čemu se govori kada se govori o demokršćanstvu?

**Cilj:** pretvoriti postojeću kartu deset tema u pregled sadržajne širine, uz razliku između učestalih formulacija i različitih rasprava.

## Postupak

1. Zadržati postojeći TF-IDF/NMF model kao referentno rješenje. Prikazati svih deset tema i nerazvrstanu kategoriju. Ne uklapati zaseban model za svaku platformu.
2. Za svaku temu pročitati pet tipičnih i pet graničnih konteksta iz različitih skupina tekstova. Provjeriti razumljivost naziva, lematizaciju vlastitih imena i utjecaj ponovljenih slogana. Sačuvati i slučajeve koji proturječe predloženom naslovu teme.
3. Usporediti udjele po objavama i po reprezentativnim tekstovima. Tema koja se smanji nakon uklanjanja kopija i dalje je medijski vidljiva; smanjenje opisuje doprinos ponavljanja.
4. Provesti ograničene provjere: drugi početci modela; referentnih 10 prema 8 i 12 tema; kontekstualni prema duljem raspoloživom tekstu na usporedivom podskupu. Nije cilj pretraživati mnogo rješenja do dobivanja privlačne priče.
5. Usporedbu modela temeljiti na podudaranju rječnika, dodjele tekstova i čitanju primjera. Ako se dvije teme stalno miješaju, prikazati širu uredničku skupinu uz očuvane izvorne oznake u dodatku.

## Predviđeni izlazi

**Slika 1: dvije mjere tematske zastupljenosti.** Poravnati vodoravni stupci za objave i skupine tekstova. Isti redoslijed tema, apsolutni brojevi i postoci, zasebno navedeni nazivnici. Broj skupina tek će biti utvrđen.

**Slika 2: teme kroz vrijeme.** Matrica tema i usporedivih razdoblja s brojevima uz udjele. Rijetke mjesece sažeti u tromjesečja ili dulje blokove prema unaprijed utvrđenom pravilu. U strukturi uzorka ne prikazivati prividnu vremensku putanju na temelju jednog teksta.

**Tablice:** udjeli, promjena nakon kontrole ponavljanja, veličine skupina, granične dodjele i zapis razloga za uredničke nazive. Doprinosi NMF komponenti nisu vjerojatnosti istinitosti tema.

## Što možemo protumačiti

Ako identitetske teme ostanu zastupljene i među različitim tekstovima, to podupire zaključak o važnosti političkog samoodređenja unutar zbirke. Ako dio njih počiva na nekoliko ponovljenih izjava, priča se usmjerava na medijski odjek tih izjava. Za tvrdnju o primjeni načela potreban je zaseban kodni sloj; sam naziv teme to ne dokazuje.

**Rezervni ishod:** stabilan pregled širih tema i odabrani primjeri. Ne uvoditi novi složeni model samo zato što stvara vizualno privlačnije klastere. Metodološka uporišta: izvori 3 i 4, str. 16.

<!-- PAGE: 07 | Veze riječi i pojmova -->
# Koje se ideje susreću u istim rečenicama?

**Cilj:** otkriti jezična susjedstva oko demokršćanstva, solidarnosti, općeg dobra, obitelji, Europe i drugih pojmova koje potvrdi pilot. Javno ih nazivamo vezama ili supojavljivanjima, uz jasno značenje mjere.

## Precizno određen postupak

1. Ponovno anotirati izvorne dokazne odlomke: rečenice, riječi, leme, vrste riječi i položaji. Zadržati važne glagole i negaciju. Postojeća lista imenica, pridjeva i vlastitih imena ne sadrži potrebne granice.
2. Zamrznuti pojmovni rječnik nakon pilota. Izraze poput "opće dobro" i "socijalno tržišno gospodarstvo" tretirati kao cjeline; spriječiti dvostruko brojanje izraza i njegovih dijelova. Razdvojiti pojmove od imena ljudi i stranaka.
3. Osnovna jedinica jest izvorna rečenica unutar dokaznih odlomaka jednog reprezentativnog teksta po skupini. Istovjetne ili preklopljene rečenice unutar tog teksta ulaze jednom. Marginalne i zajedničke učestalosti imaju isti skup rečenica kao nazivnik, uključujući one bez odabranog para.
4. Za svaki par izračunati broj rečenica, broj različitih skupina tekstova i NPMI: log[p(a,b)/(p(a)p(b))] / -log[p(a,b)]. Računati samo definirane vrijednosti s 0 < p(a,b) < 1; nedostupna vrijednost nije nula. Pozitivna vrijednost označuje češće zajedničko pojavljivanje od očekivanog prema marginalnim učestalostima.
5. Za mrežu početno tražiti potporu barem deset skupina, pozitivnu vezu i potvrdu čitanjem. Provjeriti pragove pet i dvadeset skupina te pojedinačne susjedne rečenice kao zasebnu analizu osjetljivosti. Konačno pravilo zamrznuti prije završnog izračuna.

## Vizual i kontrola značenja

**Slika 3:** najviše 20 do 30 pojmova, grupiranih u čitljiva susjedstva. Veličina čvora predstavlja broj skupina tekstova, debljina veze NPMI. Boja označuje unaprijed opisanu vrstu pojma. Prateća tablica sadrži i sirove brojeve, razdoblja te potporu po platformama.

Za svaku vezu istaknutu u narativu pregledati do deset različitih potpornih skupina. Posebno označiti negiranje, citiranje, ironiju i suprotstavljanje: rečenica koja povezuje pojmove može ih upravo razdvajati. Veza koja nestaje uklanjanjem jednog citata prikazuje se kao njegov odjek.

**Tumačenje:** povezanost solidarnosti s radom može označavati jezični most prema socijalnim pitanjima; tek potvrđena argumentacijska veza omogućuje snažniji zaključak. Česta prisutnost selekcijske riječi "demokršćanstvo" ne dokazuje da je ona spontano središte javnog diskursa.

**Rezervni ishod:** nekoliko preglednih ljestvica susjednih pojmova i tablica parova. Bez zaključaka o "odsutnim vezama" i bez rangiranja ideološke važnosti prema središnjosti grafa. NPMI: izvor 5, str. 16.

<!-- PAGE: 08 | Načela i društvena pitanja -->
# Od vrijednosti do konkretne primjene

**Cilj:** utvrditi koja se načela prepoznatljivo izražavaju i kada služe obrazloženju nekog društvenog ili političkog stava. Kršćanska socijalna misao i demokršćanstvo ostaju povezana, ali različita analitička uporišta.

| Sloj | Početne kategorije | Potreban dokaz |
|---|---|---|
| Socijalna načela | Ljudsko dostojanstvo, opće dobro, solidarnost, supsidijarnost, sudjelovanje | Izričit naziv ili jasno obrazložena parafraza načela |
| Političke i društvene ideje | Socijalno tržišno gospodarstvo, demokratske institucije, savjest i vjerska sloboda, europska suradnja | Prepoznatljiv pojam ili argument; nije svaka pojedinačna riječ dovoljan signal |
| Društvena pitanja | Obitelj i skrb; rad; gospodarstvo i socijalna država; demokracija i slobode; Europa i mir; okoliš | Konkretan problem ili područje primjene u promatranom odlomku |
| Funkcija načela | Imenovanje, objašnjavanje, primjena | Za primjenu mora biti izražena veza između načela i problema, prosudbe ili predložene mjere |

Prve kategorije nadograđuju lokalne rječnike. Kompendij daje uporište socijalnim načelima, a program EPP-a primjer političkog samorazumijevanja [1, 2]. Ovi izvori ne služe ocjenjivanju "pravovjernosti" objava. Obitelj, domoljublje ili solidarnost sami po sebi ne čine tekst demokršćanskim; granica već odabranog skupa ostaje ista.

## Pravila za kodiranje

Odvojeno označiti izričito imenovanje i sadržajno izražavanje bez imena; ona mogu biti prisutna zajedno. Primjer načela nije sama riječ "dostojanstvo" u tituli, niti je svako prenošenje ovlasti dokaz supsidijarnosti. Za parafrazu treba opisati aktere, odnos i obrazloženje. Nejasne slučajeve zadržati kao neodređene.

Par načelo-pitanje potvrđuje se u istom povezanom argumentu, uz referencu na dokazni odlomak. Dva pojma u udaljenim dijelovima članka daju samo istodobnu prisutnost, ne i primjenu. Tvrdnja može biti afirmativna ili kritička; prisutnost načela i stav prema njemu odvojene su oznake.

## Predviđeni izlazi

**Slika 4:** točke za prevalenciju načela uz odvojene mjere imenovanja i sadržajnog izražavanja. Prikazati broj potvrđenih i broj neodređenih zapisa; ne stapati nedostatak teksta s odsutnošću načela.

**Slika 5:** matrica načelo-pitanje s brojem potvrđenih primjena. Svaka ćelija pokazuje broj objava i, u dodatku, broj skupina tekstova. Ukupan nazivnik i nazivnik među procjenjivim zapisima navode se zasebno. Za malu ćeliju dati broj, bez snažne boje koja bi sugerirala veliku razliku.

**Tumačenje:** matrica pokazuje gdje ideje dobivaju konkretnu javnu primjenu. Malo zabilježenih primjena nekog načela opisuje ovu zbirku i njezin izbor, a ne prazninu u tradiciji ili cjelokupnom javnom prostoru.

<!-- PAGE: 09 | Funkcija pozivanja i glasovi -->
# Što pozivanje na tradiciju radi u raspravi?

**Cilj:** razlikovati političku oznaku, objašnjenje i argument. Ovaj sloj daje pojmovima smisao koji sama učestalost riječi ne može prenijeti.

| Varijabla | Kategorije i pravilo |
|---|---|
| Funkcija pozivanja | Identitet/samopozicioniranje; povijesno ili idejno objašnjenje; obrazložena društvena ili politička primjena. Mogu se preklapati. |
| Osporavanje | Zasebna oznaka kritike, ironije ili osporavanja legitimnosti pozivanja na tradiciju; može pratiti bilo koju funkciju. |
| Cilj i stav | Samo uz jasan cilj: prema načelu, demokršćanstvu kao tradiciji ili konkretnom akteru. Podržavanje, osporavanje, miješano, opisno ili neodredivo. |
| Uloga govornika | Politička, crkvena, akademska, civilnodruštvena, novinarska, sudionička ili neodređena. Odvojiti citiranog govornika i autorski glas. |
| Zemljopisni okvir | Hrvatska, europska razina, druga imenovana zemlja, više okvira ili neodređeno. Sam hrvatski jezik nije dokaz domaćeg okvira. |

## Što postojeći kod ne može zamijeniti

U postojećem mehanizmu A1 sam aktivira oznaku supstancije; ujedno se odsutnost identitetskog signala može razvrstati kao "supstancijski" registar. Zato ta oznaka nije dokaz sadržajne primjene načela. Zemljopisni okvir podrazumijeva domaći kada nema stranog signala, a govornik se povezuje pravilom blizine. Sve tri varijable zahtijevaju novi pozitivni dokaz.

Ulogu kodirati uz konkretan iskaz. Osoba spomenuta u tekstu nije automatski govornik, a medij koji prenosi izjavu nije njezin zagovornik. Ako se u objavi pojavljuje više govornika, zadržati više uloga i prikazati udio objava s tom ulogom. Ako je potreban međusobno isključiv prikaz, unaprijed definirati kategoriju "više uloga".

## Izlazi koji imaju smisla za čitatelja

**Slika 6, uvjetno:** matrica teme i funkcije pozivanja. Ona odgovara na pitanje u kojim temama tradicija služi pripadanju, a u kojima konkretnom obrazlaganju. Kritiku prikazati odvojeno da se ne pomiješa s funkcijom argumenta.

**Glasovi, uvjetno:** jednostavan profil uloga po širokim temama, samo gdje je atribucija pouzdana. Ne izrađivati tablicu "najutjecajnijih" osoba ili izvora; za utjecaj nedostaju podaci.

**Tri kratka analitička portreta:** jedan tipičan obrazac, jedan različit ili manjinski obrazac i jedan slučaj koji komplicira glavni nalaz. Portreti su provjerene parafraze, označene kao primjeri. Ne izmišljati kompozitne citate niti ih koristiti kao zamjenu za brojčanu potporu.

**Rezervni ishod:** kvalitativni portreti bez postotaka za nepouzdane kategorije. Strože kodiranje ima prednost pred potpunom, ali slabo potkrijepljenom tablicom.

<!-- PAGE: 10 | Vrijeme, platforme i epizode -->
# Razlikuju li se mjesta i trenutci rasprave?

## Tri različita pitanja i tri nazivnika

**Obujam:** koliko je uključenih objava? **Relativna vidljivost:** koliko ih je na 10.000 pretraživih zapisa iste platforme i razdoblja? **Sadržaj:** koliki dio uključenih objava određene platforme govori o temi ili načelu? Svaki prikaz mora navesti točno koji nazivnik koristi.

Mjesečne stope za dulje razdoblje računati kao 10.000 puta zbroj uključenih podijeljen zbrojem pretraživih zapisa, a ne kao jednostavan prosjek mjesečnih stopa. Arhivsku stopu tumačiti kao gustoću u prikupljenom materijalu, bez pretvaranja u udio medijske publike.

## Usporedivost prije usporedbe

Promjenu prikupljanja 1. travnja 2024. označiti u svakom vremenskom prikazu. Novi postupak ima i ulazni filtar samostalne riječi "i". Različite ulazne politike i sastav izvora znače da nazivnici prije i poslije prijelaza nisu zamjenjivi. Promjenu preko tog datuma ne pripisivati automatski rastu ili padu javne relevantnosti.

Za svaku usporedbu unaprijed utvrditi zajedničke raspoložive mjesece, broj dana s podacima, duljinu teksta i broj objava/skupina. Datum prvog i zadnjeg zapisa ne jamči neprekinutu pokrivenost. Ne zbrajati različite platforme u jedinstvenu kategoriju samo radi dosezanja praga veličine.

**Slika 7, uvjetno:** tematski profil platformi u usporedivom razdoblju; izvorne platforme ostaju vidljive. Ako nema dovoljne potpore, upotrijebiti opis ukupne zbirke i zaseban pregled za 2025. Mali nazivnici ostaju uz brojeve, bez vizualnog natjecanja postotaka.

## Odabir epizoda bez biranja željenog zaključka

1. Nakon pregleda pokrivenosti rangirati mjesece po uključenim objavama unutar svakog usporedivog razdoblja. Spajati susjedne mjesece istog događaja; pregledati do tri vodeće nepovezane epizode. Usporediti jesu li vrhovi prisutni i u stopama.
2. Dodati jednu sadržajno različitu epizodu, označenu kao namjerno izabran kvalitativni primjer. Za brojčanu usporedbu koristiti jednako dug susjedni vremenski odsječak samo kada je pokrivenost usporediva.
3. Događaj imenovati nakon čitanja tekstova i provjere datuma. Usporediti dominantne teme, različite argumente te doprinos ponovljenih tekstova i citata. Sačuvati evidenciju svih razmotrenih epizoda i razloga konačnog izbora.

**Slika 8:** vremenska crta i do tri portreta epizoda; svaki s brojem objava, brojem skupina tekstova i opisom sadržaja. Isti citat na više platformi prikazuje dokumentiranu rasprostranjenost u zbirci. Arhivski datum ne dokazuje izvornu objavu, smjer širenja niti uzročni utjecaj.

<!-- PAGE: 11 | Kodiranje i provjera kvalitete -->
# Kontrola prije zaključivanja

**Način izvedbe:** lokalna jezična anotacija i prošireni rječnici daju prijedloge izričitih pojmova. Pravila blizine kandidiraju načelo-pitanje, ali tu vezu ne potvrđuju sama. Parafraze, funkciju i atribuciju provjerava čitatelj prema kodnoj knjizi. Automatski udjeli novih oznaka ulaze u izvještaj tek nakon uspješne evaluacije; ostali ostaju ručno provjereni opisi. Novi generativni model nije preduvjet analize.

## Razvojni pilot: oko 140 različitih skupina tekstova

Izabrati raznolik uzorak koji pokriva deset tema, glavne platforme, oba razdoblja prikupljanja, dodatna pravila uključivanja i kratke ili granične kontekste. Rijetke slučajeve namjerno uključiti češće. Pilot služi doradi pravila, primjerima i procjeni rada; njegovi udjeli nisu procjena cjeline.

Na pilotu utvrditi izvedivost razdvajanja kopija i citata, rječnik fraza, definicije načela, kriterij primjene, funkcije i uloge. Za svaku kategoriju zapisati pozitivan primjer, blizak negativan primjer i neodrediv slučaj. Nakon dorade zamrznuti pravila, parametre, slučajni početak i plan prikaza.

## Odvojena evaluacija: ciljano 200 novih skupina

Tek nakon zamrzavanja izdvojiti stratificiran slučajni uzorak među preostalim skupinama; nijedna skupina ne smije biti i u razvoju i u evaluaciji. Pohraniti vjerojatnosti izbora. Za ukupne metrike iz nerazmjernog uzorka koristiti pripadajuće težine i navesti opisuje li metrika skupine ili objave. To je provjera na neviđenim skupinama, ne procjena svih medija.

Dva čitatelja s odgovarajućim jezičnim i sadržajnim znanjem neovisno kodiraju taj uzorak, bez uvida u računalni prijedlog i međusobne oznake. Nakon mjerenja slaganja usklađuju nesuglasice s dokumentiranim obrazloženjem. Provjeriti i dio članova višestrukih skupina kako reprezentativni tekst ne bi prikrio sadržajnu razliku.

Za binarne oznake prikazati matricu pogrešaka, preciznost, odziv, broj potvrđenih pozitivnih slučajeva te slaganje čitatelja. Cohenov kappa i slaganje na pozitivnim slučajevima tumače se zajedno s učestalošću oznake. AI ponovni prolaz može pomoći u otkrivanju nedosljednosti, ali nije zamjena za dva neovisna čitatelja.

## Odluke o prihvatu

- Za automatske udjele važnih novih kategorija postaviti projektni cilj preciznosti najmanje 0,85 i odziva najmanje 0,75, uz prikaz neizvjesnosti. To su unaprijed odabrani ciljevi, a ne univerzalni standard.
- Za procjenu pojedine kategorije tražiti barem 20 potvrđenih i 20 predviđenih pozitivnih slučajeva; mogu se preklapati. To je prag za smislen pregled, ne jamstvo pouzdane procjene. Ako potpora nedostaje, proširiti unaprijed opisan evaluacijski uzorak ili prijeći na ručno potvrđene primjere.
- Ako se pravila promijene na temelju evaluacije, ta evaluacija postaje razvojna. Za novu procjenu izdvojiti nov, netaknut skup; ne popravljati metriku ponovnim korištenjem istih slučajeva.
- Ako drugi čitatelj nije dostupan, završiti agregate i opisne teme te sadržajni dio ograničiti na transparentno ručno pregledane nalaze. U tehničkom dodatku točno navesti tko je što provjerio.

**Tri odvojene provjere:** programska ispravnost čuva brojeve; sadržajno kodiranje čuva značenje; analiza osjetljivosti provjerava koliko zaključak ovisi o odabranim pravilima.

<!-- PAGE: 12 | Kontrole i odluke -->
# Što mora preživjeti provjeru osjetljivosti

| Kontrola | Konkretan postupak | Ako se zaključak promijeni |
|---|---|---|
| Ponavljanje | Objave prema jednom tekstu po skupini; odvojena provjera zajedničkih citata | Promjenu opisati kao učinak ponavljanja, bez brisanja stvarne vidljivosti. |
| Pravilo odabira | Cjelina prema A1; dodatnih 95 opisati zasebno | Zaključak ograničiti na pripadajući način uključivanja. |
| Opseg teksta | Svi uključeni prema 2.290 s tijelom teksta; kontekst prema duljem tekstu na istom podskupu | Navesti koje nalaze određuje raspoloživi tekst, a koje širi sadržaj članka. |
| Sastav zbirke | Web zasebno; zajednička razdoblja; udjeli platformi | Preformulirati opći nalaz u nalaz za konkretnu platformu ili razdoblje. |
| Tematski model | Ograničen broj početaka i 8/10/12 tema; čitanje graničnih slučajeva | Spajanje u šire tematske cjeline ili izostavljanje nestabilne usporedbe. |
| Jezične veze | Prag 5/10/20 skupina; rečenica prema susjednim rečenicama; utjecaj jednog citata | Prikazati stabilna susjedstva ili zamijeniti mrežu tablicom. |
| Kodni sloj | Neovisni čitatelji, pogreške i neodredivi slučajevi po kategoriji | Pojednostavniti kategoriju, dodatno pregledati ili izostaviti automatski udio. |

## Negativni i granični primjeri

Posebno provjeriti naslove bez sadržajnog obrazloženja, generičko "dobro" koje ne znači opće dobro, naslovne titule s riječju dostojanstvo, spomen aktera bez njegova iskaza, ironiju i odbacivanje demokršćanskog identiteta. Takvi slučajevi provjeravaju značenje oznaka. Kontrole ne proširuju zamrznuti obuhvat zbirke.

## Neizvjesnost bez prividne preciznosti

Za konačne opisne brojeve ovog skupa ne dodavati intervale koji bi sugerirali slučajan uzorak svih medija. Ako se koristi ponovno uzorkovanje radi stabilnosti modela ili udjela, uzorkovati cijele skupine tekstova uz čuvanje platforme i razdoblja gdje veličine to dopuštaju. Takav raspon opisuje stabilnost unutar zbirke i ne pokriva pogrešku selekcije ili kodiranja.

Usporedbe temeljiti na veličini i postojanosti razlike, uz broj jedinica. Ne pretraživati desetke malih ćelija radi statističke značajnosti. Za svaki budući glavni nalaz unaprijed povezati jednu ključnu kontrolu koja bi ga mogla osporiti.

**Registar tvrdnji:** identifikator nalaza, točan tekst tvrdnje, tablica/izračun, jedinica i nazivnik, ključna provjera, alternativno objašnjenje i odluka o uvrštavanju. Svaka rečenica s brojčanim nalazom u PDF-u mora imati taj trag.

<!-- PAGE: 13 | Interpretativni doprinos -->
# Koju širu priču podaci mogu otkriti?

Sljedeća tumačenja predstavljaju mogućnosti koje treba provjeriti, a ne očekivane rezultate. Izvještaj se organizira oko potvrđenih obrazaca, uključujući nalaze koji ne odgovaraju početnim očekivanjima.

| Mogući nalaz | Doprinos razumijevanju | Provjera i alternativno objašnjenje |
|---|---|---|
| Ime tradicije često se pojavljuje, a konkretne primjene rjeđe | Razlika između javne prepoznatljivosti identiteta i razvijenosti obrazlaganja | Selektivnost A1 i kratki odlomci mogu favorizirati ime. Provjeriti dulji tekst i dodatna pravila. |
| Socijalna načela povezuju se s radom, skrbi ili gospodarstvom | Pokazuje na kojim područjima idejna tradicija postaje konkretan javni argument | Zajedničke riječi nisu dovoljne. Pregledati stvarnu argumentacijsku vezu. |
| Europski i domaći okviri koriste različit rječnik | Otkriva različite načine predstavljanja iste tradicije | Učinak prijevoda, nekoliko stranih događaja ili različitih platformi; usporediti slične uvjete. |
| Kritika se poziva na demokršćanska načela | Tradicija može služiti kao mjerilo procjene aktera i dosljednosti | Odvojiti osporavanje aktera od odbacivanja načela ili tradicije. |
| Društvene platforme nose sažet identitetski jezik | Upućuje na odnos komunikacijskog formata i načina pozivanja | Kratkoća teksta, citati i mali uzorci mogu objasniti razliku; ne pripisivati je publici. |
| Jedna tema gubi udio nakon kontrole kopija | Velik dio vidljivosti stvara medijsko ponavljanje ograničenog sadržaja | Preneseni citat može biti uklopljen u različite argumente; odvojiti citat od cijelog teksta. |
| Načelo je rijetko, ali prisutno u različitim razdobljima i temama | Mali broj može imati široku i trajnu sadržajnu ulogu | Potrebne su različite skupine tekstova i potvrđeni primjeri; rijetkost povećava osjetljivost na pogreške. |

## Kako će izgledati završni komentar uz sliku

Svaka slika dobiva tri povezana elementa: opaženi obrazac, njegovo značenje za istraživačko pitanje i provjeru koja određuje koliko široko ga možemo tumačiti. Tehničke pojedinosti nalaze se u dodatku, a uz sliku samo jedinica, razdoblje i nazivnik koji su potrebni za razumijevanje.

U glavnom tekstu koristiti jasne tvrdnje poput "u analiziranim objavama prevladava..." kada podaci to potvrde. Nove obrasce ne prikazivati kao unaprijed poznatu povijest demokršćanstva. Zaključak može biti i da neka popularna pretpostavka o medijskoj prisutnosti nije potkrijepljena ovom zbirkom.

<!-- PAGE: 14 | Provedba i isporuke -->
# Od provjerenog ulaza do gotovog izvještaja

| Korak | Rad i kontrolna točka | Isporuka |
|---|---|---|
| 1. Zamrzavanje ulaza | Evidentirati manifeste, 2.306 ključeva, dostupnost teksta i pokrivenost; provjeriti spajanje 1:1 | Inventar podataka, konfiguracija, matrica izvedivosti |
| 2. Razvojni pilot | Oko 140 skupina; pravila kopija/citata, fraze, načela i funkcije; zamrznuti odluke | Kodna knjiga, privatni primjeri, zapis odluka i procjena rada |
| 3. Evaluacija i dorada opsega | Odvojenih oko 200 skupina; neovisno kodiranje i provjera važnih oznaka | Izvještaj kvalitete; popis prihvaćenih i ograničenih modula |
| 4. Analiza i osjetljivost | Teme, veze riječi, načela, ponavljanje; uvjetno platforme i glasovi | Verzijske agregatne tablice, registar tvrdnji, 6 do 8 nacrta slika |
| 5. Tumačenje i uredništvo | Provjeriti svaku važnu tvrdnju i kontraprimjer; odabrati najkorisnije slike | Hrvatski rukopis s 3 glavna nalaza i do 3 portreta epizoda |
| 6. Oblikovanje i završna provjera | Provjeriti zbrojeve, natpise, izvore, privatnost, prijelom i čitljivost svake stranice | Samostalan PDF, agregati i tehnički dodatak |
| 7. Vaša procjena PDF-a | Procijeniti jasnoću, informativnost i najbolji doprinos barometru | Odluka o sadržajima za kasniju integraciju |

## Datoteke i ponovljivost

Predloženi budući analitički izdvojeni sloj: verzionirana konfiguracija i kodna knjiga; tablice tema, načela, primjena, funkcija, platformi, razdoblja i jezičnih parova; izvještaj kontrole; izvorne vektorske slike; manifest s kontrolnim zbrojevima. Svaka tablica ima jedinicu, nazivnik, filter, broj neodredivih slučajeva i vezu na izdanje ulaza.

Izvorni tekst, položaji dokaznih odlomaka, identifikatori, pripadnost skupinama i koderske odluke ostaju u privatnom radnom prostoru. Javni paket sadrži samo dopuštene agregate i pregledane parafraze. Imena izvora, računa, pojedinačni URL-ovi i tekstovi ne uvode se kroz novi PDF kao sporedni izlaz.

## Procjena rada i ovisnosti

Radna procjena iznosi 7 do 12 analitičkih radnih dana, ovisno o kvaliteti grupiranja i kodiranja, te približno 25 do 45 sati ukupnog ljudskog kodiranja i usklađivanja. To nije kalendarski rok; nakon pilota procjena se zamjenjuje opaženim vremenom po jedinici. Pohranjeni podaci i postojeći lokalni jezični model dovoljni su za početak, bez nove nabave podataka ili obvezne vanjske usluge.

Ako kodiranje načela ostane zahtjevno, prednost imaju uži, pouzdaniji nalazi i dobra interpretacija. Ne povećavati složenost modela samo radi popunjavanja planiranog broja slika ili stranica.

<!-- PAGE: 15 | Nacrt konačnog PDF-a -->
# Izvještaj koji se može čitati i dijeliti

**Radni naslov:** Demokršćanstvo u javnom govoru: identitet, načela i društvena pitanja. Preporučeni opseg je 18 do 22 stranice, uključujući sažetak, grafike, metode i izvore. Broj stranica prati vrijednost potvrđenih nalaza.

| Dio budućeg izvještaja | Predložene stranice | Glavni sadržaj |
|---|---|---|
| Naslovnica i ključni nalazi | 1 do 3 | Jasna istraživačka priča, tri potvrđena nalaza i vodič kroz materijal |
| Vidljivost i tematska karta | 4 do 7 | Vremenska crta, teme, razlika objava i skupina tekstova |
| Jezik i ideje | 8 do 10 | Čitljiva susjedstva pojmova, objašnjenje značenja odabranih veza |
| Načela u primjeni | 11 do 14 | Prevalencija načela, matrica primjena, funkcija pozivanja |
| Platforme i epizode | 15 do 17 | Samo izvedive usporedbe i do tri provjerena portreta |
| Sinteza, metode i izvori | 18 do 22 | Što smo doznali, jedinstven tehnički dodatak, izvori i rječnik mjera |

## Vizualni jezik

Urednički oblikovan A4 dokument: svijetla podloga, tamna petrolejska boja i umjeren bakreni naglasak, serifni naslovi i čitljiv tekst bez serifa. Vektorske slike, ugrađeni fontovi s hrvatskim znakovima, dovoljno bjeline, izravne oznake podataka i boje provjerene u sivim tonovima. Glavni tekst približno 11 pt; ključni natpisi grafikona barem 9,5 pt.

Jedna glavna poruka po slici. Brojeve i postotke poravnati, osi ne skraćivati radi dramatičnosti, a veličinu čvora ili intenzitet boje vezati uz jednu jasno imenovanu mjeru. Mreža je opcionalna; dobra tablica ili niz usporedivih stupaca imaju prednost ako se njima priča lakše razumije.

## Urednička provjera prije predaje

Svaki glavni nalaz mora imati reproduktivan izračun, jasan nazivnik i pregled koji potvrđuje smisao oznake. Svaka slika mora odgovoriti na javno zanimljivo pitanje. Pročitati hrvatski tekst kao cjelinu, provjeriti parafraze i reference, otvoriti svaku renderiranu stranicu te provjeriti rubove, prelamanje, hrvatske znakove, broj stranice i poveznice.

U glavnoj priči nalaze se nalazi i njihovo značenje. Metodološke pojedinosti okupljene su na jednom mjestu; kratki natpisi daju čitatelju informacije potrebne uz konkretnu sliku. Tako izvještaj može biti autoritativan i čitljiv, uz provjerljivo podrijetlo svake tvrdnje.

**Odluka nakon čitanja:** odabrati 3 do 5 modula koji najbolje povećavaju razumijevanje. U barometar prenositi provjerene agregate i jasne vizuale, uz dostupnu verziju PDF-a. Ovaj plan ne pokreće izmjene stranice.

<!-- PAGE: 16 | Izvori i revizijski trag -->
# Uporišta i završna provjera plana

## Pojmovna i metodološka literatura

**1. Papinsko vijeće Iustitia et Pax (2004). Kompendij socijalnog nauka Crkve.** Odjeljci 160 do 163 i 189 podupiru početni izbor socijalnih načela. Dokument je doktrinarno uporište za kodnu knjigu, a nije empirijski kriterij pripadnosti svake demokršćanske tradicije. [Izvornik](https://www.vatican.va/roman_curia/pontifical_councils/justpeace/documents/rc_pc_justpeace_doc_20060526_compendio-dott-soc_en.html)

**2. European People's Party (2012). Party Platform.** Primjer političkog samoodređenja i povezivanja vrijednosti s političkim područjima. Služi dopuni pojmovnog okvira, uz jasno razlikovanje stranačkog programa i analitičke definicije. [Izvornik](https://www.epp.eu/files/uploads/2015/09/Platform2012_EN1.pdf)

**3. scikit-learn. Topic extraction with Non-negative Matrix Factorization and Latent Dirichlet Allocation.** Službena dokumentacija postupka TF-IDF/NMF, provjerena 19. rujna 2026. Lokalno izdanje navodi točne parametre i verzije. [Dokumentacija](https://scikit-learn.org/stable/auto_examples/applications/plot_topics_extraction_with_nmf_lda.html)

**4. Belford, M., Mac Namee, B. i Greene, D. (2017). Stability of Topic Modeling via Matrix Factorization.** Metodološko uporište za razdvajanje stabilnosti tematskog rješenja i njegove sadržajne interpretacije. [Rad](https://arxiv.org/abs/1702.07186)

**5. Bouma, G. (2009). Normalized (Pointwise) Mutual Information in Collocation Extraction.** Uporište mjere NPMI. Pragovi potpore i način prikaza u ovom protokolu projektne su odluke. [Autorski rukopis](https://svn.spraakdata.gu.se/repos/gerlof/pub/www/Docs/npmi-pfd.pdf)

## Lokalni izvori za provjeru izvedivosti

- `data/barometar/demokrscanstvo-multiplatform/v1/`: summary.json, platforms.csv, monthly.csv, manifest.json.
- `data/barometar/demokrscanstvo-themes/v1/`: summary.json i manifest.json.
- `studies/demokrscanstvo-barometar/MULTIPLATFORM.md` i `THEMATIC.md`: postojeća metoda, izvori i ograničenja obuhvata.
- `R/lib/barometar_engine.R`: pravila registra, zemljopisnog okvira i govornika; lokalni rječnici concept_families.yaml i domain_themes.yaml.
- Privatni međurezultati: provjereni broj uključenih zapisa, tekstualna osnova, shema kandidata i anotacija te duljina spojenih konteksta. U ovom dokumentu prikazani su isključivo agregati.

## Što je provjereno u ovoj reviziji

Usklađeni su opseg uzorka i nazivnici, provjereni manifesti, razdvojene analitičke jedinice te ispravljene pretpostavke o platformama, jezičnim anotacijama i postojećim interpretativnim oznakama. Plan je zatim provjeren na sadržajnu izvedivost, kružno zaključivanje, razumljivost izlaza i povezanost svake slike s pitanjem.

To je dokumentirana provjera plana prema dostupnim ulazima i kodu. Ne predstavlja neovisnu stručnu recenziju ni provedenu evaluaciju budućih oznaka. U ovoj fazi nije izvršeno novo modeliranje, promijenjen obuhvat podataka niti izmijenjen barometar.
