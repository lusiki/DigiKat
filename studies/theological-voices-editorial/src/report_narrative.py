"""Full editorial treatment requested after the initial short note."""
import csv
import io
import json
import re
from evidence_io import *
from manuscript import page_map as initial_page_map

PAGES=[]


def page(section, body, *, tint=False, location="main"):
    PAGES.append({"page":len(PAGES)+1,"location":location,
                  "typst":f'#spread(section: "{section}", tint: {str(tint).lower()})[\n{body}\n]'})


def dark(body, *, cover=False):
    PAGES.append({"page":len(PAGES)+1,"location":"cover" if cover else "main",
                  "typst":("#cover[" if cover else "#darkspread[")+"\n"+body+"\n]"})


PERIOD=r'#value("period_start") – #value("period_end")'
FRAME_SOURCE=r'''#source[Izvor: DigiKat, zamrznuti web okvir. Jedinica: deduplicirana web objava.
Baza: #value("frame_n") objava; PERIOD. Obuhvat arhiva nije jednak svemu objavljenom niti potvrđuje vjersku relevantnost svake objave.]'''
SOURCE_SOURCE=r'''#source[Izvor: DigiKat, tablica koncentracije izvora, provjerena prema zamrznutom okviru.
Jedinica: web objava; nazivnik udjela: #value("frame_n") objava. PERIOD.
Broj objava ne mjeri publiku, doseg ili utjecaj. Nije uvedena nova podjela izvora prema pripadnosti.]'''
REUSE_SOURCE=r'''#source[Izvor: DigiKat, spremljene skupine identičnog očišćenog tijela teksta.
Jedinica: objava; baza: #value("reuse_base") objava s najmanje #value("reuse_threshold") znakova.
PERIOD. Nisu utvrđeni autorstvo, prvi izdavač, smjer preuzimanja ni slične priče.]'''


def narrative():
    PAGES.clear()
    dark(r'''
  #cover-label[DIGIKAT · ISTRAŽIVAČKI IZVJEŠTAJ]
  #cover-title[Katoličke teme\ u arhivu DigiKat]
  #cover-deck[Objave, izvori i ponavljanje identičnog teksta,\ #value("period_years")]
  #cover-space()
  #cover-deck[Što #value("frame_n") zabilježenih web objava\ može reći o izvorima i ponavljanju teksta]
  #gap()
  COVER_WAVE
  #cover-note[Visina crte pokazuje broj objava u mjesecu. Praznina označuje prekid u prikupljanju. Razdoblje završava #value("period_end")]
  #cover-space()
  #cover-note[Zamrznuti web okvir DigiKat · #value("sources_n") identifikatora izvora\ Od #value("period_start") do #value("period_end")]
  #gap()
  #cover-label[RADNO ISTRAŽIVAČKO IZDANJE]
  #cover-note[Čeka ljudski urednički pregled prije vanjske distribucije.]
''',cover=True)

    page("Uvod · prizor iz arhiva",r'''
  #kicker[Počnimo od onoga što možemo provjeriti]
  #headline[Isti tekst, isti datum,\ #value("case_same_day_outlets") izvora]
  #deck[U zamrznutom okviru ovi zapisi imaju potpuno jednako očišćeno tijelo teksta. Svaki je zasebna objava na zasebnom izvoru.]
  SAME_DAY_ROWS
  #hr()
  #bigprose[#value("case_same_day_publications") objava ne znači jednako toliko različitih tekstova.]
  #prose[To je početna razlika ovog izvještaja: brojimo objave, promatramo izvore i provjeravamo tekstualnu istovjetnost. Iz toga ne slijedi tko je autor, tko je prvi objavio tekst ili koliko je bilo neovisnih uredničkih odluka.]
  #source[Izvor: spremljeni deterministički primjer DigiKat, provjeren prema cijelim tijelima teksta u zamrznutom okviru. Prikazani su svi članovi skupine: #value("case_same_day_publications") objava na #value("case_same_day_outlets") izvora. Datum je naveden uz svaki zapis; nazivi vode na spremljene URL-ove. Naslovi služe identifikaciji, ne tumačenju sadržaja. Namjeran odabir, bez procjene učestalosti.]
''',tint=True)

    page("Uvod · sažetak",r'''
  #kicker[Ako pročitate samo jednu stranicu]
  #headline[Što novi podaci pokazuju]
  #deck[Glavni nalazi opisuju raspodjelu objava među izvorima i doslovno ponavljanje arhiviranog teksta. Ostali prikazi razrađuju njihov opseg i granice.]
  #section-rule[Glavni nalaz · izvori]
  #take[Koncentracija objava][#value("source_top5_share")][Skupina od #value("top_group_size") najzastupljenijih izvora nosi ovaj udio u svim zabilježenim web objavama. Riječ je o sastavu arhiva, a ne o udjelu publike.]
  #section-rule[Glavni nalaz · tekst]
  #take[Identičan arhivirani tekst][#value("reuse_share")][Ovaj udio prihvatljivih objava dijeli očišćeno tijelo teksta s drugom objavom. Mjera ne obuhvaća preoblikovanja ni djelomična preuzimanja.]
  #section-rule[Granice koje prate nalaze]
  #columns[
    #subhead[Prikupljanje nije jednoliko]
    #prose[Praznina u dobavljačkom toku i promjena režima prikupljanja ograničavaju vremenske usporedbe. Viši stupac preko te granice nije dokaz rasta medijske pozornosti.]
  ][
    #subhead[Pitanje teologa ostaje otvoreno]
    #prose[Izvor objave nije govornik u tekstu. Spremljena politika povukla je modelske procjene uloga, tumačenja, tema i iskustava; one ne postaju zaključci ovog izvještaja.]
  ]
  #source[Izvori: zamrznuti okvir, tablica koncentracije, skupine identičnog teksta i spremljena politika objavljivanja DigiKat. Baze: #value("frame_n") objava za izvore; #value("reuse_base") za ponavljanje. PERIOD.]
''')

    page("Uvod · kako čitati",r'''
  #kicker[Prije čitanja]
  #headline[Objava, izvor, tekst i glas\ nisu ista jedinica]
  #deck[Izvještaj zadržava razliku između onoga što arhiv bilježi i onoga što bi zasebna analiza govora tek trebala utvrditi.]
  #section-rule[Pojmovi]
  #method-row[*Objava*][Zaseban zapis nakon uklanjanja duplikata. Isti tekst može ostati u različitim objavama.]
  #hr()
  #method-row[*Izvor*][Mjesto objave, označeno spremljenim identifikatorom i nazivom. Izvor nije automatski autor ni govornik.]
  #hr()
  #method-row[*Identičan tekst*][Jednako cijelo očišćeno tijelo teksta, uz spremljeni prag duljine. Naslov ne određuje podudaranje.]
  #hr()
  #method-row[*Glas i tumačenje*][Pripisana izjava i njezino značenje zahtijevaju zaseban dokaz. Ovdje se ne objavljuju procjene njihove zastupljenosti.]
  #gap()
  #note-box[Kako čitati boje][Plavozelena boja označuje količinu objava i tekstualne skupine. Crvena upozorava na granicu mjerenja. Tamne stranice otvaraju cjeline; podaci i nazivnici ostaju uz svaki nalaz.]
  #source[Metodološka osnova: spremljene definicije, okvir i politika objavljivanja DigiKat. Brojevi u glavnom tekstu temelje se na punom okviru; obrada uzorka prikazana je u dodatku. Izvještaj ne uvodi nova pravila prepoznavanja govornika, novu klasifikaciju izvora ni novo kodiranje članaka.]
''',tint=True)

    dark(r'''
  #act-label[ČIN I · PONUDA OBJAVA]
  #act-title[Što je u arhivu]
  #cover-space()
  #act-number[#value("frame_n")]
  #act-caption[dedupliciranih web objava]
  #gap()
  #cover-deck[Broj zabilježenih objava opisuje opseg dohvata.\ Njegove granice moraju biti jednako vidljive kao i njegovi stupci.]
  #cover-space()
  #act-note[Izvor: DigiKat, zamrznuti okvir. Jedinica: web objava. PERIOD. Hrvatska i bosanskohercegovačka regionalna građa; arhiv nije cjelokupno novinarstvo.]
''')

    page("I · objave",r'''
  #kicker[Kada su objave zabilježene?]
  #headline[Kalendar arhiva ima\ prekid koji ne smijemo prešutjeti]
  #deck[Mjesečni brojevi pokazuju raspored pohranjenih objava. Crveno područje označuje razdoblje za koje dobavljački tok nema teksta.]
  #section-rule[Broj zabilježenih web objava po mjesecu]
  #small[Gornja granica zajedničke skale: #value("month_axis_max") objava.]
  #gap()
  MONTHLY_BARS
  #note[Praznina: #value("gap_date") Posljednji mjesec obuhvaćen je samo do #value("period_end")]
  #gap()
  #columns[
    #subhead[Što stupci govore]
    #prose[Prikazuju broj zapisa u pojedinom mjesecu nakon uklanjanja duplikata. Iz njih se može opisati raspored objava unutar zamrznutog arhiva.]
  ][
    #subhead[Što ne smijemo dodati]
    #prose[Promjenu količine preko promjene režima prikupljanja ne tumačimo kao promjenu medijske pozornosti. Nepotpuna završna godina nije ravnopravna punim godinama.]
  ]
  FRAME_SOURCE
''')

    page("I · granice prikupljanja",r'''
  #kicker[Jednako pravilo nije jednak obuhvat]
  #headline[Promjena prikupljanja\ mijenja ono što možemo usporediti]
  #deck[U spremljenim metapodacima objave pripadaju ranijem ili kasnijem režimu prikupljanja. Prijelaz je oko #value("change_date")]
  #period-row[Raniji režim][#value("era_pre2024_n")][Broj objava s ranijom spremljenom oznakom prikupljanja. Oznaka je preuzeta iz okvira, a ne naknadno izvedena samo iz kalendarske godine.]
  #period-row[Kasniji režim][#value("era_post2024_n")][Broj objava s kasnijom spremljenom oznakom prikupljanja. Različit obuhvat izvora i način prikupljanja mogu oblikovati razliku u količini.]
  #note-box[Praznina je problem zbirke][Dobavljački tok nema tekst za razdoblje #value("gap_date") To nije opaženi izostanak izvještavanja. Jednako pravilo uključivanja ne uspostavlja usporediv obuhvat prije i nakon promjene.]
  #prose[Zato ove zbrojeve ne prikazujemo kao rast ili pad interesa za vjeru. Najprije je potrebno razjasniti kako je sadržaj prikupljan i što je moglo ostati izvan dohvata.]
  #source[Izvori: službeni zapis o ograničenjima prikupljanja i tablica po spremljenoj eri DigiKat. Jedinica: web objava; baza: #value("frame_n") objava. PERIOD. Oznaka ere nije nova skupina izvora ni izjednačavanje kalendarskih razdoblja.]
''',tint=True)

    dark(r'''
  #act-label[ČIN II · IZVORI]
  #act-title[Gdje se objavljuje]
  #cover-space()
  #act-number[#value("source_top5_share")]
  #act-caption[objava dolazi iz skupine\ od #value("top_group_size") izvora]
  #gap()
  #cover-deck[Arhiv ima mnogo izvora, ali njihove količine nisu jednake. Koncentracija se ovdje mjeri brojem objava.]
  #cover-space()
  #act-note[Izvor: DigiKat, tablica koncentracije. Baza: #value("frame_n") objava. PERIOD. Udio u arhivu nije udio publike, dosega ili utjecaja.]
''')

    page("II · koncentracija izvora",r'''
  #kicker[Koji izvori nose najviše objava?]
  #headline[Najzastupljeniji izvori nose\ #value("source_top5_share") zabilježenih objava]
  #deck[Ukupno #value("source_top5_n") objava dolazi iz prikazane skupine. Svaki postotak koristi isti nazivnik: puni zamrznuti okvir.]
  TOP_SOURCE_ROWS
  #hr()
  #infoline[Svi ostali zapisi izvora zajedno][#value("source_rest_n") · #value("source_rest_share")]
  #columns[
    #subhead[Najveći izvor]
    #prose[hkm.hr ima #value("source_1_n") objava, odnosno #value("source_1_share") ukupnog okvira. Velika količina jednog izvora snažno oblikuje sastav arhiva.]
  ][
    #subhead[Granica zaključka]
    #prose[Iz broja objava ne slijedi koliko ljudi čita izvor, koliko mu vjeruje ili tko u tim tekstovima dobiva riječ.]
  ]
  SOURCE_SOURCE
''')

    page("II · raspodjela izvora",r'''
  #kicker[Koliko izvora čini velik dio okvira?]
  #headline[#value("sources_for_half") izvora dovoljno je\ za polovicu zabilježenih objava]
  #deck[Izvore poredamo prema broju objava i zbrajamo njihove zapise. Tako se vidi koliko brzo vrh popisa obuhvaća velik dio svih zapisa.]
  CUMULATIVE_ROWS
  #hr()
  #columns[
    #subhead[Dug popis izvora]
    #prose[U okviru postoji #value("sources_n") jedinstvenih identifikatora izvora. Velik broj različitih izvora može postojati uz veliku koncentraciju objava na vrhu popisa.]
  ][
    #subhead[Ista baza, drugo pitanje]
    #prose[Zbroj pokazuje koliko objava prikupljamo dodavanjem sljedećih izvora. Ne govori kolika je raznolikost stavova, autora ili teoloških pristupa.]
  ]
  #source[Izvor: zamrznuti okvir DigiKat; grupiranje po postojećem identifikatoru izvora, bez nove taksonomije. Jedinica stupaca: udio objava; nazivnik: #value("frame_n"). PERIOD. Granica polovice odnosi se na broj objava; nije mjera uredničke ili idejne raznolikosti.]
''',tint=True)

    dark(r'''
  #act-label[ČIN III · PONAVLJANJE TEKSTA]
  #act-title[Objave i tekstovi]
  #cover-space()
  #act-number[#value("reuse_share")]
  #act-caption[prihvatljivih objava dijeli\ potpuno jednako tijelo teksta]
  #gap()
  #cover-deck[Objava ostaje zaseban zapis i kad je njezin tekst isti kao u drugoj objavi. Ta razlika omogućuje usku, provjerljivu mjeru ponavljanja.]
  #cover-space()
  #act-note[Izvor: DigiKat, skupine identičnog teksta. Baza: #value("reuse_base") objava s najmanje #value("reuse_threshold") znakova. PERIOD. Mjera ne obuhvaća slične priče niti dokazuje smjer preuzimanja.]
''')

    page("III · opseg ponavljanja",r'''
  #kicker[Koliko se spremljeni tekst ponavlja?]
  #headline[#value("reuse_n") objava dijeli tekst\ s drugom objavom]
  #deck[Među objavama s najmanje #value("reuse_threshold") znakova to je #value("reuse_share") prihvatljivih objava. Ponavljanje je utvrđeno na cijelom očišćenom tijelu teksta.]
  #columns[
    #mini-stat[#value("reuse_base")][Objave koje ulaze u nazivnik]
  ][
    #mini-stat[#value("reuse_families")][Skupine ponovljenog teksta]
  ]
  #gap()
  #section-rule[Udio u prihvatljivim objavama]
  #proportional-bar(raw("reuse_n"), raw("reuse_base"))
  #note[Plavozelena boja označuje #value("reuse_n") objava u skupinama ponavljanja; ostatak je bez takvog podudaranja unutar primijenjene mjere.]
  #gap()
  #note-box[Zašto je baza manja od cijelog okvira?][Izvan izračuna je #value("reuse_excluded") objava kraćih od spremljenog praga. Ne mijenjamo prag niti njihovo neuključivanje proglašavamo odsutnošću ponavljanja.]
  #prose[Broj skupina i broj objava nisu zamjenjivi. Svaka skupina okuplja objave s istim tijelom teksta; zbroj njezinih članova ulazi u broj ponovljenih objava.]
  REUSE_SOURCE
''')

    page("III · isti i različiti izvori",r'''
  #kicker[Gdje se pojavljuju jednaka tijela teksta?]
  #headline[Ponavljanje je češće\ unutar istog identifikatora izvora]
  #deck[Ovdje mijenjamo nazivnik: promatramo samo #value("reuse_n") objava koje već pripadaju skupinama ponavljanja.]
  #columns[
    #mini-stat[#value("same_source_n")][Objave u skupinama unutar istog izvora]
  ][
    #mini-stat[#value("cross_n")][Objave u skupinama s različitim izvorima]
  ]
  #gap()
  #proportional-bar(raw("same_source_n"), raw("reuse_n"))
  #infoline[Unutar istog izvora][#value("same_source_repeat_share")]
  #infoline[Skupine s različitim izvorima][#value("cross_repeat_share")]
  #hr()
  #columns[
    #subhead[Skupine i članovi]
    #prose[Prvi dio čini #value("same_source_families") skupina teksta; drugi #value("cross_families"). Skupina koja uključuje različite izvore može sadržavati i više objava istog izvora.]
  ][
    #subhead[Povratak na cijelu bazu]
    #prose[Objave u skupinama s različitim izvorima čine #value("cross_share") svih prihvatljivih objava. To je drukčiji nazivnik od udjela prikazanih iznad.]
  ]
  #source[Izvor: DigiKat, spremljene skupine identičnog teksta. Jedinica: objava. Nazivnik gornjih udjela: #value("reuse_n") ponovljenih objava; šira baza: #value("reuse_base"). PERIOD. Pripadnost istoj tekstualnoj skupini ne utvrđuje izvornog autora ni put preuzimanja.]
''',tint=True)

    page("III · veličina tekstualnih skupina",r'''
  #kicker[Koliko objava okuplja ista tekstualna skupina?]
  #headline[U #value("family_pairs_share") skupina\ tekst se pojavljuje u paru]
  #deck[Skupina može imati malo ili mnogo objava. Ovdje brojimo njezine članove, a ne broj različitih izvora.]
  #section-rule[Objave po skupini · broj takvih skupina]
  FAMILY_ROWS
  #hr()
  #prose[Veće skupine postoje, ali su rjeđe. Ovaj prikaz broji skupine identičnog teksta, bez obzira na to pojavljuju li se unutar istog ili različitih izvora.]
  #source[Izvor: DigiKat, tablica skupina identičnog teksta, provjerena prema zamrznutom okviru. Jedinica: tekstualna skupina; baza: #value("reuse_families") skupina s ukupno #value("reuse_n") objava. PERIOD. Veličina skupine nije broj različitih izvora niti mjera uredničke povezanosti.]
''')

    page("III · dokumentirani primjer",r'''
  #kicker[Ponavljanje može prijeći granicu datuma]
  #headline[Isti tekst na\ susjedne datume]
  #deck[Ova spremljena skupina ima #value("case_separated_dates_publications") objave na #value("case_separated_dates_outlets") izvora. Datumi i URL-ovi razlikuju zapise; očišćena tijela teksta su jednaka.]
  SEPARATED_ROWS
  #gap()
  #note-box[Datum nije dokaz porijekla][Ranije zabilježen datum ne utvrđuje prvog autora ni prvog izdavača. Arhiv može sadržavati samo dio relevantnih objava, a ovdje nije provjeravana povijest objavljivanja izvan arhiva.]
  #prose[Naslovi su identifikatori odabranih zapisa. Ne rekonstruiramo argumente tih tekstova niti njihovim naslovima dokazujemo vjersku relevantnost.]
  #source[Izvor: spremljeni deterministički primjer DigiKat; lokalno provjereni članstvo, duljine, otisci i jednakost cijelih očišćenih tijela. Jedinica: objava u odabranoj skupini; broj članova i datumi navedeni su na stranici. Namjeran primjer, ne reprezentativan uzorak. Nazivi izvora povezuju se sa spremljenim URL-ovima.]
''',tint=True)

    page("III · granice mjere",r'''
  #kicker[Što znači „identično”?]
  #headline[Ista tijela teksta\ nisu isto što i iste priče]
  #deck[Mjera je namjerno uska. Razlikuje cijele spremljene tekstove, a ne događaje, argumente ili sve oblike preuzimanja.]
  #section-rule[Što ulazi u mjeru]
  #method-row[*Cijelo očišćeno tijelo*][Jednak tekstualni otisak i spremljena duljina od najmanje #value("reuse_threshold") znakova.]
  #hr()
  #method-row[*Različiti naslovi*][Naslov ne određuje podudaranje. Isto tijelo može biti spremljeno uz drukčiji naslov.]
  #section-rule[Što ostaje izvan nje]
  #method-row[*Parafraze i dijelovi teksta*][Slična tema ili djelomično podudaranje nisu dovoljni za pripadnost istoj skupini.]
  #hr()
  #method-row[*Smjer i autorstvo*][Jednak tekst ne govori tko je od koga preuzeo sadržaj ili tko ga je napisao.]
  #hr()
  #method-row[*Urednička neovisnost*][Tekstualna istovjetnost ne objašnjava vlasništvo, suradnju, dopuštenje za prijenos ili uredničku odluku.]
  #gap()
  #bigprose[Udio identičnog teksta ne treba čitati kao udio svih preuzetih ili sličnih priča.]
  REUSE_SOURCE
''')

    dark(r'''
  #act-label[ČIN IV · ISTRAŽIVAČKO PITANJE]
  #act-title[Tko tumači vjeru?]
  #cover-space()
  #act-word[Ostaje otvoreno.]
  #act-caption[Broj objava i jednakost teksta\ ne određuju govornu ulogu.]
  #gap()
  #cover-deck[Motivacija istraživanja ostaje važna. Za odgovor o akademskim teolozima potreban je dokaz koji razlikuje spomen, pripisanu izjavu i tumačenje vjere.]
  #cover-space()
  #act-note[Osnova: spremljena politika objavljivanja DigiKat i statusi tvrdnji. Modelske procjene govornika, uloga, tumačenja, tema i iskustva povučene su nakon nezadovoljenih provjera. Iz toga se ne izvodi ni prisutnost ni odsutnost teologa.]
''')

    dark(r'''
  #act-label[ZAVRŠNICA · OPAŽANJA]
  #summary-title[Što možemo ponijeti]
  #columns[
    #dark-stat[#value("source_top5_share")][Koncentracija na vrhu popisa][Udio skupine od #value("top_group_size") izvora u svim zabilježenim web objavama. Baza: #value("frame_n").]
  ][
    #dark-stat[#value("reuse_share")][Doslovno ponovljen arhivirani tekst][Udio objava koje dijele cijelo očišćeno tijelo s drugom objavom. Baza: #value("reuse_base") prihvatljivih objava.]
  ]
  #gap()
  #cover-deck[Ovi nalazi opisuju ponudu objava i svojstvo spremljenih tekstova. Ne predstavljaju rang-listu tumača vjere.]
  #cover-space()
  #act-note[Izvori: DigiKat, tablica koncentracije i skupine identičnog teksta. PERIOD. Koncentracija ne mjeri utjecaj; identičnost ne utvrđuje smjer preuzimanja. Praznina i promjena prikupljanja ograničavaju vremenske usporedbe.]
''')

    page("Završnica · sljedeća pitanja",r'''
  #kicker[Prijedlozi za sljedeće istraživanje]
  #headline[Što treba provjeriti\ prije sljedećeg zaključka]
  #deck[Ovo su preporuke za daljnji rad, a ne dodatni empirijski nalazi završene studije.]
  #section-rule[Za pitanje o teolozima]
  #bigprose[Odvojiti spomen, izjavu i tumačenje.]
  #prose[Pripisanu izjavu treba razlikovati od same najave da će netko govoriti. Govornu ulogu treba potkrijepiti tekstom, a ne izvoditi je iz imena, svećeničkog statusa ili pretpostavljenih kvalifikacija.]
  #section-rule[Za vremenske usporedbe]
  #bigprose[Najprije usporediti obuhvat prikupljanja.]
  #prose[Prije tvrdnje o promjeni medijske pozornosti potrebno je razjasniti izvore, trajanje i način prikupljanja u uspoređivanim razdobljima. Kalendarska godina sama po sebi ne osigurava usporedivost.]
  #section-rule[Za šire preuzimanje sadržaja]
  #bigprose[Zasebno definirati sličnost i porijeklo.]
  #prose[Preoblikovane priče zahtijevaju drugu, provjerenu mjeru. Pitanje prvog izdavača zahtijeva podatke o povijesti objavljivanja. Završeni izračun identičnog teksta ne odgovara ni na jedno od tih pitanja.]
  #source[Preporuke proizlaze iz opsega dopuštenih mjera i spremljenih ograničenja DigiKat. Nove provjere nisu provedene za ovo izdanje. Nisu ponovno kodirani članci, tražena imena osoba niti uvedeni novi klasifikatori.]
''',tint=True)

    page("Metodološki dodatak",r'''
  #kicker[Podaci i pravila]
  #headline[Metoda i granice]
  #columns[
    #section-rule[Okvir]
    #prose[Službeni zamrznuti web okvir sadrži #value("frame_n") dedupliciranih objava iz razdoblja PERIOD. Sadrži hrvatsku i bosanskohercegovačku regionalnu građu te naslijeđena ograničenja tematskog dohvata.]
    #section-rule[Duplikati]
    #prose[Uklonjeni su prema izvoru, URL-u očišćenom od parametara praćenja i datumu. Kad URL nedostaje, koriste se izvor, datum, naslov i identičan tekst. Zadržano je najdulje tijelo, zatim zapis s najmanjim identifikatorom.]
    #section-rule[Tekst]
    #prose[Čišćenje obuhvaća HTML entitete, završetke redaka, NUL znakove i vanjske praznine. Predlošci stranica nisu uklanjani. Prag za ponavljanje ostaje #value("reuse_threshold") znakova.]
  ][
    #section-rule[Izvori]
    #prose[Nazivi i identifikatori preuzeti su iz studije. Spremljena tablica može čuvati različita velika i mala slova kao zasebne retke uz isti identifikator. Ukupan broj izvora i kumulativni prikaz koriste postojeće identifikatore.]
    #section-rule[Primjeri]
    #prose[Preuzete su već odabrane tekstualne skupine. Jednakost cijelih tijela provjerena je lokalno. Prikazuju se kratki naslovi, nazivi izvora, datumi i URL-ovi, bez odlomaka tijela teksta i bez tumačenja sadržaja.]
    #section-rule[Usporedbe]
    #prose[Dobavljački tok nema tekst za razdoblje #value("gap_date") Oko #value("change_date") mijenja se prikupljanje. Jednako pravilo uključivanja ne čini obuhvat usporedivim.]
  ]
  #source[Autoritativni zapisi: freeze.json, source_audit.json, claims.json, report_policy.json i spremljene tablice. Glavni nalazi koriste puni okvir; uzorak se pojavljuje u dodatku o obradi. Primjeri su ilustrativni. Nova klasifikacija izvora, nova semantička obrada i otkrivanje sličnih priča nisu dio izdanja.]
''',location="appendix")

    page("Dodatak · obrada",r'''
  #kicker[Završeno ne znači sadržajno potvrđeno]
  #headline[Obrada uzorka\ i granice klasifikacije]
  #deck[Ovi brojevi opisuju tehničke ishode spremljene obrade. Ne procjenjuju koliko su uloge, teme ili govornici ispravno prepoznati.]
  #panel[
    #infoline[Glavni uzorak][#value("sample_n") objava]
    #infoline[Strukturno potpuni ishodi][#value("complete_n")]
    #infoline[Djelomična obrada][#value("partial_n")]
    #infoline[Potpuno neuspjeli ishodi][#value("failed_n")]
    #infoline[Ishodi bez teksta][#value("missing_n")]
    #infoline[Konfiguracija završene obrade][#value("coding_version")]
  ]
  #section-rule[Zašto su procjene povučene]
  #prose[Spremljene provjere zabilježile su pogreške u razlikovanju pripisane izjave od drugih sadržaja, u prepoznavanju pogođenih skupina i u obradi duljih tekstova. Pravilo studije zato povlači sve ovisne modelske procjene sadržaja.]
  #section-rule[Što tehnička provjera ne potvrđuje]
  #prose[Dostava punog teksta, pronalazak označenog odlomka i uspješna struktura rezultata ne potvrđuju ispravno razumijevanje značenja. Nije provedena ljudska validacija članaka niti izmjerena klasifikacijska točnost.]
  #source[Izvori: spremljeni glavni manifest, ishodi obrade, konfiguracija, politika i dijagnostički pregledi DigiKat. Jedinica: ishod obrade objave; nazivnik: #value("sample_n") objava iz razdoblja PERIOD. Dijagnostika nije glavni empirijski nalaz o religijskoj komunikaciji.]
''',tint=True,location="appendix")

    page("Dodatak · provjerljivost",r'''
  #kicker[Od podataka do stranice]
  #headline[Svaka brojka ima\ svoj trag do izvora]
  #deck[Tehnička provjera ovog izvještaja provjerava slijed podataka i prikaza. Ona ne daje novu potvrdu točnosti povučenih klasifikacija.]
  #section-rule[Sačuvani dokazi]
  #method-row[*Izvori i otisci*][Manifest bilježi pročitane datoteke i njihove kontrolne otiske. Izvorne studije i arhiv ostaju nepromijenjeni.]
  #hr()
  #method-row[*Tvrdnje i nazivnici*][Registar povezuje vrijednosti s računom, mjernom jedinicom, razdobljem, nazivnikom i izvornim statusom objavljivanja.]
  #hr()
  #method-row[*Grafikoni i PDF*][Grafičke serije koriste iste registrirane vrijednosti. Brojevi u sastavljenom PDF-u uspoređuju se s očekivanim prikazom.]
  #hr()
  #method-row[*Vizualni pregled*][Svaka završna stranica pregledava se kao slika. Pregled vrijedi za točno određenu datoteku PDF-a.]
  #gap()
  #note-box[Status ovog izdanja][Radno istraživačko izdanje čeka ljudski urednički pregled. Završena AI provjera rasporeda nije ljudsko uredničko odobrenje. Vanjska distribucija ili uporaba kao odobrene institucionalne publikacije zahtijeva odobrenje nositelja projekta.]
  #source[Prateći lokalni paket: registar tvrdnji, manifest izvora, karta prilagodbe izvornog izvještaja, okoliš i fontovi, manifest figura, zapis provjera i zaseban zapis vizualnog pregleda. README sadrži točne naredbe za ponovnu izradu. Svaka promjena PDF-a zahtijeva novi pregled.]
''',location="appendix")

    for start,end in ((1,25),(26,50)):
        page("Imenik · izvori",rf'''
  #kicker[Izvori prema broju zabilježenih objava]
  #headline[Od #value("source_{start}_rank"). do #value("source_{end}_rank"). mjesta]
  #deck[Nazivi izvora preuzeti su iz spremljene tablice. Udjeli se odnose na sve objave zamrznutog web okvira.]
  #directory-header()
  DIRECTORY_{start}_{end}
  #source[Izvor: DigiKat, spremljena tablica koncentracije. Jedinica: web objava; nazivnik: #value("frame_n"). PERIOD. Redoslijed nije rang-lista dosega, utjecaja ili govornika. Nije uvedena podjela izvora prema katoličkoj ili nekatoličkoj pripadnosti.]
''',tint=start>1)
    return PAGES


def assemble():
    records=json.loads((OUT/"claim_register.json").read_text(encoding="utf-8"))["records"]
    month_ids=[r["id"] for r in records if re.fullmatch(r"month_\d{4}_\d{2}",r["id"])]
    years='#yearlabels('+', '.join(f'value("year_{y}")' for y in range(2021,2027))+')'
    wave='#monthbars('+', '.join(f'wavebar(raw("{cid}"))' for cid in month_ids)+')'
    monthly='#monthbars('+', '.join(f'full-monthbar(raw("{cid}"))' for cid in month_ids)+')\n'+years
    top="\n".join(f'#source-row(value("source_{i}_name"), raw("source_{i}_n"), value("source_{i}_n"), value("source_{i}_share"))' for i in range(1,6))
    cum="\n".join(f'#cumulative-row([Prvih #value("cumulative_{i}_k") izvora], value("cumulative_{i}_share"), raw("cumulative_{i}_n"), raw("frame_n"))' for i in (5,20,50,100))
    sizes=[int(r["id"].split("_")[1]) for r in records if re.fullmatch(r"family_\d+_groups",r["id"])]
    family="\n".join(f'#size-row([#value("family_{i}_size") {"objave" if i in (2,3,4) else "objava"}], value("family_{i}_groups"), raw("family_{i}_groups"), raw("family_2_groups"))' for i in sizes)
    def cases(kind,count):
        return "\n".join(f'#source-entry(value("case_{kind}_{i}_outlet_name"), value("case_{kind}_{i}_published_at"), value("case_{kind}_{i}_title"), raw("case_{kind}_{i}_url"))' for i in range(count))
    pages=narrative()
    for p in pages:
        replacements={"COVER_WAVE":wave,"MONTHLY_BARS":monthly,"TOP_SOURCE_ROWS":top,
                      "CUMULATIVE_ROWS":cum,"FAMILY_ROWS":family,
                      "SAME_DAY_ROWS":cases("same_day",5),"SEPARATED_ROWS":cases("separated_dates",3),
                      "FRAME_SOURCE":FRAME_SOURCE,"SOURCE_SOURCE":SOURCE_SOURCE,
                      "REUSE_SOURCE":REUSE_SOURCE,"PERIOD":PERIOD}
        for start,end in ((1,25),(26,50)):
            replacements[f"DIRECTORY_{start}_{end}"]="\n".join(
                f'#directory-row(value("source_{i}_rank"), value("source_{i}_name"), value("source_{i}_n"), value("source_{i}_share"))' for i in range(start,end+1))
        for key,val in replacements.items():p["typst"]=p["typst"].replace(key,val)
        p["typst"]=p["typst"].strip()
    write_json(OUT/"manuscript.json",{"schema_version":"1.0","pages":pages})
    write_text(OUT/"publication.typ",'#import "../../src/template.typ": *\n\n'+"\n\n".join(p["typst"] for p in pages)+"\n")
    def fig(fid,page,ids,labels,unit,axis):
        return {"id":fid,"page":page,"series":[{"claim_ids":ids,"unit":unit}],"label_claim_ids":labels,"axis":axis}
    figs=[
      fig("cover_monthly_wave",1,month_ids,[],"publications",{"minimum":0,"maximum_claim_id":"month_axis_max","ticks":[],"visible_numeric_labels":[],"gap":"no line; collection gap"}),
      fig("monthly_supply",6,month_ids,[f"year_{y}" for y in range(2021,2027)],"publications",
          {"minimum":0,"maximum":10000,"maximum_claim_id":"month_axis_max","ticks":[],"visible_numeric_labels":["month_axis_max"],"gap":"null; shaded collection gap"}),
      fig("source_concentration",9,[f"source_{i}_n" for i in range(1,6)],
          [f"source_{i}_{s}" for i in range(1,6) for s in ("name","n","share")],"publications",
          {"minimum":0,"maximum_claim_id":"source_1_n","ticks":[],"visible_numeric_labels":[]}),
      fig("cumulative_sources",10,[f"cumulative_{i}_n" for i in (5,20,50,100)]+["frame_n"],
          [f"cumulative_{i}_{s}" for i in (5,20,50,100) for s in ("k","share")],"publications",
          {"minimum":0,"maximum_claim_id":"frame_n","ticks":[],"visible_numeric_labels":[],
           "complement":"frame_n - each cumulative count; unlabelled remainder"}),
      fig("reuse_extent",12,["reuse_n","reuse_base"],["reuse_n"],"publications",
          {"minimum":0,"maximum_claim_id":"reuse_base","ticks":[],"visible_numeric_labels":[],"complement":"reuse_base - reuse_n"}),
      fig("within_repeated",13,["same_source_n","reuse_n","cross_n"],
          ["same_source_repeat_share","cross_repeat_share"],"repeated publications",
          {"minimum":0,"maximum_claim_id":"reuse_n","ticks":[],"visible_numeric_labels":[],"complement":"cross_n = reuse_n - same_source_n"}),
      fig("family_size",14,[f"family_{i}_groups" for i in sizes],
          [f"family_{i}_{s}" for i in sizes for s in ("size","groups")],"exact-text families",
          {"minimum":0,"maximum_claim_id":"family_2_groups","ticks":[],"visible_numeric_labels":[]}),
    ]
    write_json(OUT/"figure_manifest.json",{"schema_version":"1.0","figures":figs})
    return pages


def page_map():
    initial_page_map()
    path=OUT/"page_map.csv"
    with path.open(encoding="utf-8",newline="") as stream:
        reader=csv.DictReader(stream);fields=reader.fieldnames;rows=list(reader)
    mapping={
      1:("adapt","Naslovnica","Što zabilježene objave govore o izvorima i tekstu?","frame_n","Tamna naslovnica i mjesečni ritam vraćeni prema izvorniku; novo obećanje ostaje unutar dokaza."),
      2:("replace","Uvodni slučaj","Kako se isto tijelo pojavljuje na više izvora?","case_same_day_publications","Uvodni prizor dobiva zasebnu stranicu sa spremljenim novim primjerom."),
      3:("adapt","Sažetak","Koji su glavni nalazi i njihove granice?","source_top5_share;reuse_share","Izvorna funkcija sažetka vraćena; broj glavnih nalaza nije umjetno povećan."),
      4:("adapt","Kako čitati","Što razlikuje objavu, izvor, tekst i glas?","frame_n;reuse_threshold","Zadržana pojmovna stranica; nedopuštene taksonomije zamijenjene mjernim jedinicama."),
      5:("replace","Čin I · objave","Koliki je obuhvat zamrznutog okvira?","frame_n","Tamna razdjelnica s registriranim brojem i pravilnom jedinicom."),
      6:("replace","Kalendar objava","Kako su objave raspoređene po mjesecima?","frame_n","Interakcije zamijenjene grafom mjesečnih objava s vidljivom prazninom."),
      8:("replace","Granice prikupljanja","Kako režim prikupljanja ograničava usporedbu?","era_pre2024_n;era_post2024_n","Sačuvana funkcija detaljnog prikaza izvora podataka, bez starog platformskog rezultata."),
      10:("adapt","Koncentracija izvora","Gdje se koncentrira broj objava?","source_top5_share;sources_for_half","Vraćena analitička obrada koncentracije: vrh popisa i kumulativni prikaz."),
      11:("replace","Čin II · izvori","Gdje se objavljuje?","source_top5_share","Tamna razdjelnica; nedopuštene uloge zamijenjene dopuštenim izvornim brojanjima."),
      18:("adapt","Čin III · tekst","Koliko se ponavlja identičan arhivirani tekst?","reuse_share","Vraćena cjelina o ponavljanju, uz drukčiju i izričito užu mjeru."),
      19:("replace","Primjer na susjedne datume","Što dokazuju tekstualna jednakost i datumi?","case_separated_dates_publications","Zasebna stranica dokumentiranog novog primjera; bez tvrdnje o putu preuzimanja."),
      20:("replace","Opseg, izvori i veličina skupina","Kako se raspoređuje identičan tekst?","reuse_share;cross_repeat_share;family_pairs_share","Nova mjera razrađena u potporne prikaze, bez proglašavanja novih neovisnih nalaza."),
      22:("replace","Čin IV · otvoreno pitanje","Što ostaje neodgovoreno o teolozima?","","Tamna razdjelnica izričito ostavlja istraživačko pitanje otvorenim."),
      27:("adapt","Završnica · opažanja","Što možemo zaključiti iz dopuštenih mjera?","source_top5_share;reuse_share","Vraćena tamna vizualna sinteza umjesto skraćenog bilješkastog završetka."),
      28:("adapt","Sljedeća pitanja","Koji je sljedeći potreban dokaz?","","Zadržana stranica preporuka, odvojena od opažanja."),
      29:("replace","Sljedeća pitanja","Kako provjeriti uloge, usporedivost i porijeklo?","","Nisu preuzeta stara predviđanja bez oslonca u novim podacima."),
      30:("adapt","Završnica i otvoreno pitanje","Na koja pitanja novi podaci odgovaraju?","source_top5_share;reuse_share","Odgovori prilagođeni opsegu novog istraživanja."),
      31:("adapt","Metoda, obrada i provjerljivost","Kako povezati izvore, tvrdnje i prikaz?","frame_n;reuse_base;sample_n","Kompaktan metodološki dodatak; dijagnostika ostaje izvan glavnih nalaza."),
      32:("replace","Imenik izvora · početak","Koji izvori imaju najviše zabilježenih objava?","source_1_n;source_25_n","Vraćen stvarni imenik, temeljen na novim brojanjima umjesto starih interakcija."),
      33:("replace","Imenik izvora · nastavak","Koji izvori slijede na popisu?","source_26_n;source_50_n","Druga stranica imenika bez nove klasifikacije izvora."),
    }
    for row in rows:
        p=int(row["original_page"])
        if p in mapping:
            vals=mapping[p]
            for key,val in zip(("treatment","new_section","new_question","supporting_claim_ids","decision_reason"),vals):row[key]=val
    buf=io.StringIO(newline="");writer=csv.DictWriter(buf,fieldnames=fields);writer.writeheader();writer.writerows(rows)
    write_text(path,buf.getvalue())


if __name__=="__main__":
    assemble();page_map()
    print("Full editorial narrative generated.")
