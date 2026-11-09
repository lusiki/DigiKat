"""Croatian narrative. Empirical display values may only appear as references."""
import csv
import io
import json
import re
from evidence_io import *


PAGES = [
("cover", r'''
#cover[
  #cover-label[DIGIKAT · KRATKA ISTRAŽIVAČKA BILJEŠKA]
  #cover-title[Katoličke teme\ u arhivu DigiKat]
  #cover-deck[Objave, izvori i ponavljanje identičnog teksta,\ #value("period_years")]
  #cover-space()
  #cover-big[#value("source_top5_share")]
  #cover-deck[zabilježenih objava dolazi iz skupine\ od #value("top_group_size") najzastupljenijih izvora.]
  #gap()
  #cover-note[Udio u zamrznutom okviru od #value("frame_n") web objava. Riječ je o broju objava, a ne o dosegu ili utjecaju izvora.]
  #cover-space()
  #cover-note[Od #value("period_start") do #value("period_end")\ Izvor: DigiKat, zamrznuti okvir i tablica koncentracije izvora.]
  #gap()
  #cover-label[RADNO ISTRAŽIVAČKO IZDANJE]
  #cover-note[Čeka ljudski urednički pregled prije vanjske distribucije.]
]
'''),
("main", r'''
#spread(section: "Obuhvat")[
  #kicker[Što ovaj arhiv predstavlja?]
  #headline[Zabilježene objave,\ uz vidljive granice prikupljanja]
  #deck[DigiKat omogućuje opis ponude pohranjenih web objava. Taj okvir nije popis svega što je objavljeno u hrvatskom novinarstvu.]
  #columns[
    #big[#value("frame_n")]
    #prose[dedupliciranih web objava]
  ][
    #big[#value("sources_n")]
    #prose[jedinstvenih identifikatora izvora]
  ]
  #gap()
  #subhead[Kalendar pohranjenih objava]
  #small[Gornja granica skale: #value("month_axis_max") objava.]
  #monthchart[
    MONTH_BARS
    #yearlabels(value("year_2021"), value("year_2022"), value("year_2023"), value("year_2024"), value("year_2025"), value("year_2026"))
  ]
  #note[Visina stupca pokazuje broj objava u mjesecu na zajedničkoj skali. Crveno područje označuje prazninu u prikupljanju: #value("gap_date") Zadnji stupac obuhvaća razdoblje samo do #value("period_end")]
  #hr()
  #prose[Dobavljački tok nema tekst za razdoblje #value("gap_date") To nije dokaz izostanka izvještavanja. Oko #value("change_date") mijenja se režim prikupljanja; jednako pravilo uključivanja ne čini obuhvat usporedivim prije i nakon promjene.]
  #prose[Arhiv uključuje hrvatsku i bosanskohercegovačku regionalnu građu te naslijeđena ograničenja tematskog dohvata. Pripadnost arhivu sama po sebi ne potvrđuje sadržajnu vjersku relevantnost svake objave.]
  #source[Izvori: freeze.json; source_audit.json; frame_month.csv; frame_collection_era.csv. Jedinica: deduplicirana web objava. Baza: #value("frame_n"); od #value("period_start") do #value("period_end") Rast preko promjene režima nije pokazatelj rasta medijske pozornosti; nepotpuna završna godina nije usporediva s punim godinama.]
]
'''),
("main", r'''
#spread(section: "Izvori")[
  #kicker[Gdje se koncentrira broj objava?]
  #headline[Najzastupljeniji izvori nose\ #value("source_top5_share") zabilježenih objava]
  #deck[Skupina od #value("top_group_size") izvora objavila je #value("source_top5_n") od ukupno #value("frame_n") pohranjenih web objava.]
  SOURCE_ROWS
  #hr()
  #infoline[Svi ostali zapisi izvora zajedno][#value("source_rest_n") · #value("source_rest_share")]
  #gap()
  #columns[
    #subhead[Što pokazuje koncentracija]
    #prose[hkm.hr najveći je izvor po broju objava u ovom okviru. Njegov udio iznosi #value("source_1_share"). Velik broj zapisa nekog izvora snažno oblikuje sastav arhiva.]
  ][
    #subhead[Što iz nje ne slijedi]
    #prose[Broj objava ne govori koliko je ljudi sadržaj vidjelo, kojemu izvoru vjeruju ili tko u tekstovima tumači vjeru. Naziv portala ne određuje govornu ulogu osobe.]
  ]
  #source[Izvor: source_concentration.csv, provjereno prema zamrznutom okviru. Jedinica: web objava; nazivnici svih udjela: #value("frame_n") objava. Razdoblje: #value("period_start") – #value("period_end") Nazivi i identifikatori izvora preuzeti su iz studije; nisu uvedene skupine katoličkih i nekatoličkih medija.]
]
'''),
("main", r'''
#spread(section: "Identičan tekst", tint: true)[
  #kicker[Koliko se spremljeni tekst ponavlja?]
  #headline[#value("reuse_share") prihvatljivih objava\ dijeli identičan arhivirani tekst]
  #deck[Identičnost se provjerava na cijelom očišćenom tijelu teksta. U izračun ulaze objave s najmanje #value("reuse_threshold") znakova.]
  #columns[
    #big[#value("reuse_n")]
    #prose[objava dijeli tekst s drugom objavom]
  ][
    #big[#value("reuse_families")]
    #prose[skupina identičnog teksta]
  ]
  #gap()
  #panel[
    #infoline[Baza za izračun ponavljanja][#value("reuse_base") objava]
    #infoline[Kraći tekstovi izvan te baze][#value("reuse_excluded") objava]
    #hr()
    #infoline[Objave u skupinama s različitim izvorima][#value("cross_n")]
    #infoline[Udio u istoj bazi prihvatljivih objava][#value("cross_share")]
    #infoline[Skupine koje obuhvaćaju različite izvore][#value("cross_families")]
  ]
  #prose[Objave na različitim izvorima podskup su svih objava s ponovljenim tekstom. Ponavljanje unutar istog izvora također ulazi u ukupnu mjeru. Svaka objava ostaje zaseban zapis; broj skupina nije broj objava.]
  #prose[Ovo je uska mjera doslovne istovjetnosti. Promijenjen naslov uz isto tijelo teksta ne sprječava podudaranje, ali izmjena tijela može ga spriječiti. Slične priče, parafraze i djelomična preuzimanja nisu obuhvaćeni.]
  #source[Izvori: claims.json; exact_reuse_families.csv; report_data.json; zamrznuti okvir. Jedinica udjela: objava; baza: #value("reuse_base") objava s najmanje #value("reuse_threshold") znakova. Od #value("period_start") do #value("period_end") Identitet teksta ne utvrđuje autorstvo, smjer preuzimanja, prvog izdavača, plagijat ni uredničku neovisnost.]
]
'''),
("main", r'''
#spread(section: "Dokumentirani primjeri")[
  #kicker[Kako izgleda identičnost u zapisima?]
  #headline[Isti spremljeni tekst,\ različiti izvori i datumi]
  #deck[Primjeri su namjerno odabrani prema tekstualnom otisku i metapodacima. Naslovi služe samo za identifikaciju zapisa; nisu dokaz njihova sadržajnog značenja.]
  #subhead[Na isti datum: #value("case_same_day_publications") objava na #value("case_same_day_outlets") izvora]
  SAME_DAY_ROWS
  #note[Prikazan je spremljeni izbor članova skupine. Nazivi izvora vode na izvorne URL-ove iz arhiva.]
  #hr()
  #subhead[Na susjedne datume: #value("case_separated_dates_publications") objave na #value("case_separated_dates_outlets") izvora]
  SEPARATED_ROWS
  #source[Izvor: deterministic_reuse_cases.json; članstvo, duljine, otisci i jednakost tijela teksta provjereni su lokalno prema zamrznutom okviru. Jedinica: pojedinačna objava u namjerno odabranoj skupini; broj članova naveden je uz primjer. Primjeri nisu reprezentativni i ne pokazuju tko je prvi objavio tekst. Izvadci naslova ne služe tumačenju sadržaja.]
]
'''),
("main", r'''
#spread(section: "Značenje i sljedeća pitanja", tint: true)[
  #kicker[Što smo saznali, a što ostaje otvoreno?]
  #headline[Ponuda objava je mjerljiva.\ Uloga teologa ostaje otvorena.]
  #deck[Pitanje tko tumači vjeru ostaje istraživačka motivacija. Ovi podaci ne daju pouzdan odgovor o položaju akademskih teologa.]
  #subhead[Opažanja iz dopuštenih podataka]
  #panel[
    #infoline[Koncentracija na najzastupljenijim izvorima][#value("source_top5_share")]
    #small[Udio skupine od #value("top_group_size") izvora u svim zabilježenim objavama.]
    #gap()
    #infoline[Identično tijelo teksta u drugoj objavi][#value("reuse_share")]
    #small[Udio među objavama koje zadovoljavaju spremljeni prag duljine teksta.]
  ]
  #prose[Izvori su mjesta objave; govornici su osobe ili ustanove kojima tekst pripisuje izjavu. Ni koncentracija izvora ni jednakost teksta ne mjere tko govori, u kojoj ulozi i tumači li pritom vjeru.]
  #prose[Spremljena pravila objavljivanja povukla su modelske procjene govornika, uloga, tumačenja, tema i iskustava nakon nezadovoljenih provjera. Zato se ovdje ne izvodi zaključak ni o prisutnosti ni o odsutnosti teologa.]
  #subhead[Preporuke za sljedeće istraživanje]
  #prose[Za pitanje o teolozima potreban je zasebno provjeren način razlikovanja spomena, pripisane izjave i tumačenja vjere. Stručnu ulogu treba potvrđivati iz dokaza, a ne iz samog imena ili svećeničkog statusa.]
  #prose[Za usporedbe kroz vrijeme najprije treba razjasniti usporedivost prikupljanja. Za šire preuzimanje sadržaja trebalo bi zasebno definirati i provjeriti mjeru sličnosti; ova bilješka ne uvodi takvu analizu.]
  #source[Izvori opažanja: claims.json; source_concentration.csv; exact_reuse_families.csv. Baze: koncentracija #value("frame_n") objava; ponavljanje #value("reuse_base") objava. Razdoblje: #value("period_start") – #value("period_end") Status povučenih procjena: report_policy.json i claims.json. Preporuke su istraživački smjerovi, a ne empirijski nalazi.]
]
'''),
("appendix", r'''
#spread(section: "Metodološki dodatak")[
  #kicker[Što je dopušteno objaviti?]
  #headline[Okvir, jedinice i granice zaključivanja]
  #subhead[Podaci i priprema]
  #prose[Obuhvaćene su web objave iz službenog zamrznutog korpusa DigiKat, od #value("period_start") do #value("period_end") Glavni nalazi koriste puni okvir, a ne uzorak za modelsku obradu.]
  #prose[Duplikati zapisa uklonjeni su prema izvoru, URL-u očišćenom od parametara praćenja i datumu. Ako URL nedostaje, korišteni su izvor, datum, naslov i identičan tekst. Zadržano je najdulje tijelo teksta, a zatim zapis s najmanjim identifikatorom.]
  #prose[Čišćenje obuhvaća HTML entitete, završetke redaka, uklanjanje NUL znakova i vanjskih praznina. Predlošci stranica nisu uklanjani. Isti tekst znači jednak otisak cijelog očišćenog tijela uz prag od #value("reuse_threshold") znakova; odabrani primjeri dodatno su provjereni usporedbom samih tijela.]
  #subhead[Pravila korištenja rezultata]
  #method-row[Brojevi objava i koncentracija izvora][Dopušteni unutar zamrznutog okvira.]
  #method-row[Identičan tekst i odabrani primjeri][Dopuštena uska mjera; primjeri su ilustrativni.]
  #method-row[Obrada i dijagnostika][Samo metodološki dodatak; nisu glavni nalazi.]
  #method-row[Govornici, teolozi, tumačenje, teme i iskustvo][Procjene su povučene; ne objavljuju se.]
  #method-row[Interakcije, stare rang-liste i podjela izvora prema pripadnosti][Izostavljeni iz ovog izdanja.]
  #hr()
  #prose[Tablice izvora čuvaju spremljene nazive uz identifikator izvora; različita velika i mala slova mogu ostati zasebni redci. Ukupan broj izvora temelji se na jedinstvenim identifikatorima. Nije izrađena nova klasifikacija izvora.]
  #source[Autoritativni zapisi: freeze.json; source_audit.json; claims.json; report_policy.json. Baze: #value("frame_n") web objava; #value("reuse_base") prihvatljivih objava za ponavljanje. Praznina #value("gap_date") i promjena režima oko #value("change_date") ograničavaju vremenske usporedbe. Arhiv nije popis svega objavljenog niti potvrda vjerske relevantnosti svake objave.]
]
'''),
("appendix", r'''
#spread(section: "Obrada i provjerljivost", tint: true)[
  #kicker[Metodološki dodatak]
  #headline[Završena obrada nije potvrda\ točnosti klasifikacije]
  #deck[Brojevi u ovom dodatku opisuju tehničke ishode spremljenog uzorka. Ne procjenjuju koliko su pojedine uloge, teme ili glasovi pravilno prepoznati.]
  #panel[
    #infoline[Glavni uzorak][#value("sample_n") objava]
    #infoline[Strukturno potpuni ishodi][#value("complete_n")]
    #infoline[Djelomična obrada][#value("partial_n")]
    #infoline[Potpuno neuspjeli ishodi][#value("failed_n")]
    #infoline[Ishodi bez teksta][#value("missing_n")]
    #infoline[Konfiguracija završene obrade][#value("coding_version")]
  ]
  #subhead[Zašto nema procjene o teolozima]
  #prose[Spremljene provjere zabilježile su pogreške u razlikovanju pripisane izjave od drugih tekstualnih sadržaja, u prepoznavanju pogođenih skupina i u obradi duljih tekstova. Pravilo studije zato povlači sve ovisne modelske procjene sadržaja. Nije provedena ljudska validacija članaka niti izmjerena klasifikacijska točnost.]
  #prose[Dostava punog teksta, pronalazak označenog odlomka i tehnički prolaz programa ne potvrđuju ispravno značenje klasifikacije. Takve provjere ne mogu zamijeniti valjanu procjenu govorne uloge.]
  #subhead[Trag do podataka i status izdanja]
  #prose[Prateći paket sadrži registar tvrdnji, otiske izvora, provjeru vrijednosti, odluku o kratkom formatu i kartu prilagodbe izvornog izvještaja. Nisu ponovno kodirani članci niti su mijenjani završeni rezultati studije.]
  #prose[Ovo je radno istraživačko izdanje koje čeka ljudski urednički pregled. Završena tehnička i vizualna provjera ove bilješke ne znači da su povučene klasifikacije potvrđene. Vanjska distribucija zahtijeva uredničko odobrenje nositelja projekta.]
  #source[Izvori: report_data.json; main_manifest.csv; articles.csv; report_policy.json; diagnostic_review.json; development_review.json; statement_probe_review.json. Jedinica: ishod obrade objave. Nazivnik: glavni uzorak od #value("sample_n") objava iz razdoblja #value("period_start") – #value("period_end") Pojam „strukturno potpun” ne znači sadržajno točan.]
]
'''),
]


def assemble():
    source_rows = "\n".join(
        f'#source-row(value("source_{i}_name"), raw("source_{i}_n"), value("source_{i}_n"), value("source_{i}_share"))'
        for i in range(1, 6))
    register_data=json.loads((OUT/"claim_register.json").read_text(encoding="utf-8"))
    month_ids=[r["id"] for r in register_data["records"] if re.fullmatch(r"month_\d{4}_\d{2}",r["id"])]
    month_bars="#monthbars(" + ", ".join(f'monthbar("{cid}")' for cid in month_ids) + ")"
    def case_rows(kind, count):
        return "\n".join(
            f'#case-row(value("case_{kind}_{i}_outlet_name"), value("case_{kind}_{i}_published_at"), '
            f'value("case_{kind}_{i}_title"), raw("case_{kind}_{i}_url"))' for i in range(count))
    pages=[]
    for i,(location,body) in enumerate(PAGES,1):
        body=body.replace("SOURCE_ROWS",source_rows).replace("MONTH_BARS",month_bars)
        body=body.replace("SAME_DAY_ROWS",case_rows("same_day",4)).replace("SEPARATED_ROWS",case_rows("separated_dates",3))
        pages.append({"page":i,"location":location,"typst":body.strip()})
    write_json(OUT/"manuscript.json",{"schema_version":"1.0","pages":pages})
    write_text(OUT/"publication.typ",'#import "../../src/template.typ": *\n\n' +
               "\n\n".join(p["typst"] for p in pages) + "\n")
    figures={
        "schema_version":"1.0",
        "figures":[
            {"id":"monthly_supply","page":2,"series":[{"claim_ids":month_ids,"unit":"publications",
              "gap_encoding":"null/red collection-gap band; not zero reporting"}],
             "label_claim_ids":[f"year_{y}" for y in range(2021,2027)],
             "axis":{"minimum":0,"maximum":10000,"maximum_claim_id":"month_axis_max",
                     "ticks":[],"visible_numeric_labels":["month_axis_max"],
                     "reason":"Shared monthly scale; its maximum is explicitly labelled."}},
            {"id":"source_concentration","page":3,
             "series":[{"claim_ids":[f"source_{i}_n" for i in range(1,6)],"unit":"publications"}],
             "label_claim_ids":[f"source_{i}_{s}" for i in range(1,6) for s in ("name","n","share")],
             "axis":{"minimum":0,"maximum_claim_id":"source_1_n","ticks":[],"visible_numeric_labels":[]}},
        ],
    }
    write_json(OUT/"figure_manifest.json",figures)
    return pages


def page_map():
    # All 34 original editorial functions are mapped, including omitted material.
    sections=[
      ("Naslovnica","Tko je preuzeo ulogu teologa?","adapt","Naslovnica","Što arhiv mjeri?","source_top5_share","Zadržan vizualni identitet; naslov i obećanje promijenjeni prema dopuštenim dokazima."),
      ("Uvodni primjer","Kako ista poruka prolazi portalima?","replace","Dokumentirani primjeri","Koji zapisi imaju identično tijelo?","case_same_day_publications;case_separated_dates_publications","Stari slučaj zamijenjen spremljenim determinističkim primjerima."),
      ("Deset zaključaka","Koji su glavni zaključci?","adapt","Značenje i sljedeća pitanja","Što dopušteni nalazi utvrđuju?","source_top5_share;reuse_share","Sažetak sveden na neovisne dopuštene nalaze."),
      ("Pitanja i pojmovi","Kako razlikovati vrste dokaza?","adapt","Obuhvat i metoda","Što je objava, izvor i identičan tekst?","frame_n;reuse_threshold","Zadržana objašnjavajuća funkcija."),
    ]
    original=[
      ("Pozornost – razdjelnica","Kome pripadaju interakcije?"),
      ("Pozornost – platforme","Koje skupine dobivaju interakcije?"),
      ("Pozornost – autorstvo","Koji izvori imaju vidljivog autora?"),
      ("Pozornost – kanal","Koliki je doprinos pojedinog kanala?"),
      ("Pozornost – nauk","Tko govori o nauku?"),
      ("Pozornost – koncentracija","Koliko je izvora potrebno za većinu interakcija?"),
      ("Glasovi – razdjelnica","Tko daje izjave?"),
      ("Glasovi – postava","Tko govori o vjeri?"),
      ("Glasovi – uloge","Koje uloge daju izjave?"),
      ("Glasovi – spomen i izjava","Kako se razlikuju spominjanje i govor?"),
      ("Glasovi – teolozi","Koga tekst naziva teologom?"),
      ("Glasovi – godine","Mijenja li se postava kroz vrijeme?"),
      ("Glasovi – žene","Koliki je udio žena na starom popisu?"),
      ("Jeka – razdjelnica","Gdje se izjave prenose?"),
      ("Jeka – put poruke","Kako se poruka pojavljuje na više izvora?"),
      ("Jeka – objave i priče","Koliko objava ponavlja priču?"),
      ("Jeka – laici","Gdje se čuju laici?"),
      ("Tišina – razdjelnica","Koliko se pojavljuju akademski teolozi?"),
      ("Tišina – tumačenje","Tko tumači vjeru?"),
      ("Tišina – autoritet","Na što se tumačenja pozivaju?"),
      ("Tišina – vjernici","Govori li se s vjernicima?"),
      ("Tišina – izdvojena tvrdnja","Koliko običnih vjernika dobiva riječ?"),
      ("Sažetak","Koje brojeve pamtiti?"),
      ("Preporuke","Kako dobiti više tumača?"),
      ("Predviđanja","Što provjeriti u sljedećem izdanju?"),
      ("Istraživačka pitanja","Koji su odgovori na početna pitanja?"),
      ("Metoda","Kako su dobiveni rezultati?"),
      ("Imenik izvora","Koji izvori imaju najviše interakcija?"),
      ("Imenik izvora – nastavak","Koji su daljnji izvori na rang-listi?"),
      ("Imenik osoba","Koje osobe imaju najviše izjava?"),
    ]
    for p,(sec,q) in enumerate(original,5):
        if p==10:
            rest=("adapt","Izvori","Kako je raspodijeljen broj zabilježenih objava?","source_top5_share","Urednička funkcija koncentracije zadržana; interakcije zamijenjene brojem objava.")
        elif p in (19,20):
            rest=("replace","Identičan tekst","Koliko se ponavlja cijelo arhivirano tijelo teksta?","reuse_share","Staro prepoznavanje priča nije ista mjera; koristi se samo spremljena jednakost teksta.")
        elif p in (27,28,29,30):
            rest=("replace","Značenje i sljedeća pitanja","Što znamo, što ostaje otvoreno?","source_top5_share;reuse_share","Novi zaključci razdvojeni od preporuka; pitanje teologa ostaje otvoreno.")
        elif p==31:
            rest=("adapt","Metodološki dodatak","Koje su baze, pravila i ograničenja?","frame_n;reuse_base;sample_n","Metoda je usklađena sa završenom studijom i statusom povučenih procjena.")
        else:
            rest=("omit","","","","Stari društveni angažman, klasifikacije izvora, osobe ili modelske procjene nisu prihvatljiv dokaz za novo izdanje.")
        sections.append((sec,q,*rest))
    output=io.StringIO(newline="")
    writer=csv.writer(output)
    writer.writerow(["original_page","original_section","original_question","treatment","new_section",
                     "new_question","supporting_claim_ids","decision_reason"])
    for i,row in enumerate(sections,1):writer.writerow((i,*row))
    write_text(OUT/"page_map.csv",output.getvalue())


if __name__=="__main__":
    assemble()
    page_map()
    print("Narrative and page map generated.")
