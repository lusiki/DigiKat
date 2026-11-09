# Kodna knjiga 1.0 - nacrt za neovisni pilot

Status: operativna priprema, nije zamrznuta nakon ljudskog pilota. Codex AI primijenio je okvir samo na javno opisane kartice; nije kodirao populaciju.

## Jedinica i opseg

Jedan predstavnik točne skupine naslova i pohranjenog tijela. Pročitati cijeli dostupan očišćen tekst i naslov, potom zasebno procijeniti lokalni opseg. Prazno tijelo ne znači odsutnost smislenog naslova. Skraćen ili loše atribuiran iskaz može biti neprocjenjiv. Izdavač nije govornik. Tekst može sadržavati više glasova, ciljeva, načela i primjena.

## Odluke

- `referent`: izričit naziv demokršćanstva ili nedvosmislena veza u istom argumentu / nije nađen / neprocjenjivo. Sama riječ kršćanski, socijalni nauk, konzervativan ili ime člana HDZ-a nije dovoljna.
- `identity`: pripadnost ili pozicioniranje / opis tuđe pripadnosti / izričito odbijanje pripadnosti / nije nađeno / neprocjenjivo.
- `principle_named`: imenovano načelo uz referent; zaseban niz naziva. Popis nije obrazloženje.
- `principle_explained`: iskaz objašnjava sadržaj načela. Ne zahtijeva posebnu mjeru, ali traži jasan smisao i referent.
- `application`: potvrđeno / nije nađeno u dostupnom tekstu / nije moguće procijeniti. Potvrda zahtijeva povezanost referenta, načela, određenog problema i prosudbe ili mjere. Potrebni su dokazni raspon i obrazloženje kodera.
- `local_application`: iste kategorije na lokalnom opsegu, bez prenošenja informacije iz ostatka članka.
- `unassessable_reason`: kratak isječak / prekinut prijepis / nejasan govornik / nejasan referent / drugo.

## Zapis tvrdnje (claims)

Za svaku povezanu tvrdnju zabilježiti: claim_id, govornik, govorna uloga (citirani akter / autorski glas / kolektivno priopćenje / nejasno), cilj (tradicija / stranka ili osoba / načelo / politika / drugo), načelo, problem, prosudba, argumentacijska veza, stav (afirmacija / kritika / mješovito / opis / neodređeno), samopripadnost, kritika dosljednosti, field, start, end, bilješka i verzija pravila. Rasponi su jednobazni, uključivi Unicode položaji u normaliziranom polju, ne bajtovi izvornog članka.

Početna načela: dostojanstvo osobe, opće dobro, solidarnost, supsidijarnost, sloboda i odgovornost, pravednost, sudjelovanje. Posebno voditi programska uporišta: pluralizam, europska suradnja, socijalno tržišno gospodarstvo, odnos vjere i politike. Područja: rad i gospodarstvo; socijalna zaštita; obitelj i obrazovanje; savjest i prava; vlast; Europa i međunarodni odnosi; drugo uz bilješku. Nije test političke autentičnosti.

## Negativni i granični primjeri

- K05: poštovanje načela i odbijanje pripadnosti nisu proturječni kodovi.
- K06/K09: povezano kršćansko društveno obrazloženje bez demokršćanskog referenta ne potvrđuje strogi kod M3.
- K07: naslov preporučenog članka ne dokazuje argument glavnog teksta.
- K04: isti dokument može sadržavati lokalni popis i širu programsku primjenu.
- K02: negativan ton sukoba u ostatku članka ne određuje stav prema demokršćanskoj tradiciji.

## Ljudski postupak i objava

Dva čitatelja neovisno kodiraju 60 pilot-tekstova. Nakon usklađivanja definicija zamrznuti novu verziju, po potrebi ponovno kodirati zahvaćene jedinice. Zatim kodiraju istih 400 odabranih skupina bez AI oznaka i tuđih odluka. Čuvati prvotne i usuglašene odluke te razloge neslaganja. Uzorak iz punog okvira, seed 20260920, ponder N_h/n_h. Ne izostavljati tekstove bez rječničkih pogodaka. Pilot je razvojni, nije procjena prevalencije.

Prikazati matricu slaganja, udio slaganja i nominalni Krippendorffov alpha po osnovnom kodu. Plan traži alpha >= 0,80 i najmanje 20 pozitivnih slučajeva za glavni kvantitativni nalaz; nedefinirana mjera nije prolazak. Procjene iz usuglašenih kodova: stratifikacija, ponderi i korekcija konačnog okvira. Neprocjenjivo zasebno i u punom nazivniku; matrica načelo-problem nije particija. Automatizacija cijelog okvira zahtijeva zaseban netaknut test s preciznošću i odzivom >= 0,80 uz intervale i najmanje 20 referentnih pozitivnih primjera po kodu.
