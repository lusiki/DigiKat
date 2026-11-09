"""Generate Croatian report sections with registered scalar/table evidence."""
import json,re
from pathlib import Path
from report_contract import pointer,sha,TOKEN,assemble


class Narrative:
    def __init__(self,data,path,base,figures):
        self.data=data;self.base=Path(base);self.base.mkdir(parents=True,exist_ok=True)
        self.registry=dict(sources={'report':dict(path=str(Path(path).resolve()),sha256=sha(path))},
          scalars={},claims={},fragments={},figures={})
        for key,figure in figures.items():
            self.registry['figures'][key]={k:v for k,v in figure.items() if k!='data_pointers'}
            self.registry['figures'][key]['data_proofs']=[dict(source='report',pointer=p) for p in figure['data_pointers']]
        self.counter=0

    def scalar(self,path,key=None,kind=None,sensitive=False,digits=1):
        value=pointer(self.data,path)
        if value is None:return 'nije procijenjeno'
        if key is None:self.counter+=1;key='value_'+str(self.counter)
        if kind is None:kind='label' if isinstance(value,str) else 'integer'
        self.registry['scalars'][key]=dict(value=value,proof=dict(source='report',pointer=path),
          format=kind,digits=digits,suppress_small=sensitive)
        return '{{scalar:'+key+'}}'

    def ratio(self,numerator,denominator,key=None,digits=1,sensitive=True):
        n=pointer(self.data,numerator);d=pointer(self.data,denominator)
        if not d:return 'nije procijenjeno'
        # A ratio must not reveal a suppressed count through multiplication.
        if sensitive and (n<5 or d<5):return 'mali broj; udio nije prikazan'
        if key is None:self.counter+=1;key='value_'+str(self.counter)
        self.registry['scalars'][key]=dict(value=n/d,format='percent',digits=digits,
          ratio=dict(numerator=dict(source='report',pointer=numerator),denominator=dict(source='report',pointer=denominator)))
        return '{{scalar:'+key+'}}'

    def complementary_counts(self,paths):
        # Even a previously disclosed total must not reconstruct a small cell.
        if any(pointer(self.data,path)<5 for path in paths):
            return ['nije prikazano']*len(paths)
        return [self.scalar(path,sensitive=True) for path in paths]

    def table(self,title,headers,rows,note):
        if not rows:return '\n\n#### '+title+'\n\nNema prihvatljivih podataka za ovu tablicu.\n\n> '+note+'\n'
        content='\n\n#### '+title+'\n\n| '+' | '.join(headers)+' |\n| '+' | '.join([':--']*len(headers))+' |\n'+''.join('| '+' | '.join(row)+' |\n' for row in rows)+'\n> '+note+'\n'
        return '\n\n::: {.keep-table}\n'+content+'\n:::\n' if len(rows)<=8 else content

    def section(self,key,text,status='complete',reason=None):
        text=text.strip()+'\n';directory=self.base/'fragments';directory.mkdir(exist_ok=True)
        path=directory/(key+'.md');path.write_text(text,encoding='utf-8',newline='\n')
        evidence=sorted({name for kind,name in TOKEN.findall(text) if kind in {'scalar','figure'}})
        claims=[]
        if evidence:
            claim=key+'_evidence';claims=[claim]
            self.registry['claims'][claim]=dict(level='A',evidence=evidence,
              statement='Descriptive evidence and publication-scope explanation in section '+key+'; no model-coded speech finding.')
        fragment=dict(path='fragments/'+key+'.md',sha256=sha(path),status=status,claims=claims,
          location='appendix' if key=='exploratory' else 'main')
        if reason:fragment['reason']=reason
        self.registry['fragments'][key]=fragment


def generate(data,data_path,base,figure_manifest):
    b=Narrative(data,data_path,base,figure_manifest['figures']);s=b.scalar;r=b.ratio;t=b.table
    for key,path in dict(report_title='/presentation/report_title',report_date='/presentation/report_date',
      corpus_period='/presentation/corpus_period',corpus_sha_short='/presentation/corpus_sha_short',
      corpus_documents='/values/corpus/documents',platforms='/values/corpus/platforms').items():s(path,key,kind='text' if key not in {'corpus_documents','platforms'} else 'integer')
    corpus=s('/values/corpus/documents','corpus_documents');platforms=s('/values/corpus/platforms','platforms')
    scope=s('/values/scope/eligible_people');short=s('/values/corpus/short_documents',sensitive=True)
    minimum=s('/constants/minimum_speech_chars');cut=s('/constants/era_split')
    orientation=f'''
Ovaj izvještaj opisuje javno vidljive osobe u digitalnom katoličkom korpusu. Polazi od {corpus} prikupljenih objava na {platforms} platformi. Razlikuje tri pitanja: čije se ime pojavljuje, komu je pripisana izjava i tko u toj izjavi tumači vjeru. Pojavljivanje imena samo po sebi odgovara samo na prvo pitanje.

**Glavni ishod ovoga izdanja jest opis spominjanja i zajedničkog pojavljivanja.** Ispitane konfiguracije jezičnih modela nisu zadovoljile unaprijed zadanu konstruiranu provjeru. Zato se njihove oznake govorenja, tumačenja, autoriteta i odnosa ne objavljuju kao nalazi. Neuspjeh nije zamijenjen nulama niti je istraživačko pitanje prešutno proglašeno riješenim.

Imena i izjave prepoznati automatski; nije provedena ljudska provjera.

## Jedinica promatranja

Objava je redak u korpusu. Ista osoba može biti spomenuta više puta u jednoj objavi, a isti tekst može biti zabilježen na više mjesta. Broj objava sa spomenom osobe zato se razlikuje od broja pojavljivanja njezina imena i od broja obitelji sličnih tekstova. U tablicama se navodi koja je jedinica upotrijebljena.

Korpus nije popis svih javnih rasprava o vjeri niti reprezentativan uzorak stanovništva. Zastupljenost platforme ovisi i o dostupnosti, pravilima prikupljanja i obliku pohranjenog teksta. Brojevi opisuju ovaj korpus, a ne ukupnu publiku, vjerovanje, povjerenje ili utjecaj osobe.

## Što se može čitati kao nalaz

Za imenovane prikaze primjenjuju se javna identifikacija i minimalna zastupljenost. U tom je skupu {scope} osoba. Ostala imena, povijesne osobe, sveti likovi i nerazriješeni identiteti ne postaju imenovani čvorovi mreže suvremenih javnih osoba.

Za prepoznavanje spomena koriste se i kratke objave. Sloj kandidata za izjave traži najmanje {minimum} znakova; u korpusu je {short} kraćih objava. To ograničenje ne smije se prenijeti na nazivnik svih spominjanja. Dostupan tekst s YouTubea nije jednak izgovorenom sadržaju videa.

Promjena prikupljanja na datum {cut} razdvaja vremenska razdoblja. Vremenski prikazi koriste udjele i rangove unutar razdoblja. Sirovi volumeni preko te granice ne tumače se kao rast ili pad javne prisutnosti.

{{{{figure:platforms}}}}
'''
    rows=[]
    for i,_ in enumerate(data['values']['platforms']):
        p=f'/values/platforms/{i}'
        rows.append([s(p+'/platform'),s(p+'/documents',sensitive=True),s(p+'/long_documents',sensitive=True),s(p+'/unique_texts',sensitive=True)])
    orientation+=t('Obuhvat platformi',['Platforma','Sve objave','Objave za sloj izjava','Različiti tekstovi'],rows,
      'Izvor: službeni korpus. Različit tekst određen je punim tekstualnim sažetkom. Jednake objave nisu izbrisane iz nazivnika. Mali brojevi skriveni su i u izvedenim udjelima.')
    if data.get('synthetic_fixture'):orientation='**KONSTRUIRANA PROVJERA PRIJEL0MA: OVI BROJEVI NISU REZULTATI ISTRAŽIVANJA.**\n\n'.replace('PRIJEL0MA','PRIJELOMA')+orientation
    b.section('orientation',orientation)

    mentions=f'''
U ovom poglavlju osoba je prisutna ako je njezin identitet automatski povezan s barem jednim spomenom u objavi. Više spomena iste osobe u istom tekstu daje jednu objavu u stupcu prisutnosti. To nije broj nastupa, izjava ni zasebnih publika.

Ukupno {s('/values/scope/documents_with_public_person',sensitive=True)} objava sadrži barem jednu osobu iz javno prikazivog skupa. Njihov udio u svim objavama iznosi {r('/values/scope/documents_with_public_person','/values/corpus/documents')}. Zbroj redaka po osobama može biti veći od toga jer jedna objava može spominjati više osoba.

## Poredak i širina prisutnosti

Poredak se temelji na broju objava, a širina na različitim izvorima i platformama. Velik broj spomena u malom broju izvora i prisutnost u različitim izvorima različite su značajke. Ni jedna od njih sama ne određuje društvenu važnost ili autoritet.

{{{{figure:people}}}}
'''
    rows=[]
    for i,person in enumerate(data['values']['people'][:20]):
        p=f'/values/people/{i}';count=s(p+'/documents',sensitive=True)
        if data['display_policy']['range_counts']:
            count+=' ('+s(p+'/minimum_documents',sensitive=True)+' – '+s(p+'/maximum_documents',sensitive=True)+')'
        rows.append([s(p+'/public_name'),count,s(p+'/outlets',sensitive=True),s(p+'/platforms',sensitive=True)])
    mentions+=t('Vodeće osobe prema objavama sa spomenom',['Javna osoba','Objave; mogući raspon','Izvori','Platforme'],rows,
      'Izvor: automatski povezani suvremeni identiteti. Ako se prikazuje, raspon potječe iz promjene praga grupiranja imena. On nije interval pouzdanosti. Izvori su različite neprazne vrijednosti izvora; mali brojevi nisu objavljeni.')
    mentions+='''
## Različite platforme, različiti nazivnici

Sljedeći prikaz uspoređuje prisutnost unutar platforme i razdoblja. Udio je broj objava koje spominju osobu podijeljen svim objavama iste platforme u istom razdoblju. Jednaka boja zato ne znači jednak apsolutan broj objava. Prazno polje može predstavljati mali izostavljeni broj ili izostanak zapisa; ne dokazuje potpunu odsutnost osobe iz javnog prostora.

{{figure:platform_presence}}

## Nerazriješena imena ostaju dio opisa ograničenja

Automatsko prepoznavanje imena prethodi povezivanju identiteta. Ime može biti ispravno označeno u tekstu, a ipak ostati nepovezano s javnim zapisom. Obrnuto, javni zapis ne dokazuje da je svaki jednak niz znakova ista osoba. Zbog toga se nerazriješeni spomeni ne preraspodjeljuju najbližoj poznatoj osobi.

{{figure:identity_classes}}
'''
    cue_labels={'clergy':'Crkveni signal','politics':'Politički signal','conflicting':'Nesuglasni signali','other':'Bez razlikovnog signala'}
    rows=[]
    for i,item in enumerate(data['values']['role_cues']):
        p=f'/values/role_cues/{i}'
        rows.append([cue_labels[item['cue_class']],s(p+'/spans',sensitive=True),s(p+'/documents',sensitive=True)])
    mentions+=t('Neimenovani spomeni prema signalima uloge',['Signal uz ime','Spomeni','Objave'],rows,
      'Izvor: neposredne titule uz prepoznato ime izvan javno imenovanog skupa. Signal jezičnog oblika nije provjerena društvena uloga. Jedna objava može imati više različitih signala; imena nisu objavljena.')
    b.section('mentions',mentions)

    speech=f'''
**Ovo izdanje ne daje rang-listu govornika.** Računalni sustav može ispravno pročitati tekst i vratiti valjan odgovor, a ipak pogrešno zaključiti tko u tekstu govori. U konstruiranim provjerama ostali su problemi poput zamjene najave događaja za već izrečenu tvrdnju, pripisivanja tuđeg citata imenovanom sudioniku i dvostrukog brojanja punog imena i njegove titule.

Prag za nastavak glavnog kodiranja bio je {s('/constants/synthetic_required')} prolaznih slučajeva od {s('/constants/synthetic_cases')}. Nijedna ispitana primarna konfiguracija nije ga dosegnula. Broj uspješno spremljenih odgovora zato nije prikazan kao broj pouzdano kodiranih izjava.

## Što znači neuspjela provjera

Valjan računalni format znači da se odgovor može učitati. Doslovan dokazni odsječak znači da model nije izmislio taj niz riječi. Međutim, ni jedno ni drugo ne jamči da odsječak doista pripada navedenom govorniku ili da sadrži tvrdnju umjesto najave. Semantička provjera ispituje upravo te razlike.

Prvotno opširniji izlaz imao je i problem prekidanja odgovora zbog ograničenja duljine. Sažetiji protokoli uklonili su taj konkretni tehnički problem u izmjerenim probama, ali nisu zadovoljili uvjet sadržajnog razlikovanja. Neuspjeh određene konfiguracije ne znači da svaki lokalni model u svakom mogućem postupku nužno mora pogriješiti.

U izvornoj dijagnozi spremljeno je {s('/presentation/legacy_invalid_json')} nevaljanih računalnih odgovora; njih {s('/presentation/legacy_invalid_json_at_limit')} završilo je na postavljenoj granici duljine. To je opis tehničkog prekida. Odvojeno je zabilježen i odbijeni zahtjev s neispravnom shemom za praznu listu kandidata; ta je programska pogreška popravljena prije kasnijih završenih provjera. Ni jedan od tih tehničkih kvarova nije dokaz da model ne razumije sadržaj. Kasnije semantičke pogreške zaseban su razlog povlačenja nalaza.

{{{{figure:model_checks}}}}

## Pravila pripisivanja kao zaseban dijagnostički sloj

Pravilima su obrađene rečenice s mogućim pripisivanjem govora. Prati se gramatički subjekt glagola govorenja, citirani ili zavisni sadržaj te poznati potpisnik kod prvog lica. Spremljeno je {s('/values/scope/parsed_rule_sentences',sensitive=True)} dovršenih parsiranja rečenica. To je obujam obrade, ne broj potvrđenih izjava.

Pravila su uža od čitanja svih mogućih načina pripisivanja. Izostanak pravila može značiti neprepoznat oblik rečenice, a ne odsutnost govora. U ovom izdanju ni taj sloj samostalno ne zaobilazi uvjete za objavu govornih nalaza. Njegovi rezultati služe provjeri postupka i ostaju odvojeni od objavljenih mreža spominjanja.
'''
    b.section('speech',speech,'withheld','No evaluated primary model passed the constructed prerequisite; rule-only outputs do not override the preregistered speech publication gate.')

    b.section('interpretation','''
**Udjeli tumačenja vjere, vrste autoriteta i odnosi među govornicima povučeni su iz nalaza ovoga izdanja.** Za te bi zaključke najprije trebalo pouzdano odrediti govornika i izrečeni sadržaj, a zatim razlikovati vrstu iskaza. Greška u prvom koraku prenosi se na sve sljedeće oznake.

Predviđene kategorije razlikuju objašnjenje nauka, objašnjenje prakse, pastoralni iskaz, svjedočanstvo, politički komentar, institucionalnu obavijest i ostalo. One opisuju funkciju konkretnog iskaza, a ne trajnu osobinu osobe. Naslov radnog mjesta ili crkvena služba sami po sebi ne određuju kojoj kategoriji pripada izjava.

Vrsta autoriteta trebala je označavati uporište vidljivo u iskazu, primjerice pozivanje na službu, akademsko znanje, iskustvo ili svete tekstove. Takva oznaka ne bi bila mjera stvarnog autoriteta, povjerenja publike ili istinitosti izrečenoga. Bez prolaznih provjera ni te se uže oznake ne objavljuju.

## Zašto nema zamjenskog rangiranja

Broj spomena ne pretvara se u broj tumačenja. Osoba može biti čest predmet vijesti, a da joj u njima nije dana riječ. Zajedničko pojavljivanje dviju osoba ne dokazuje da se podupiru, kritiziraju ili citiraju. Zato iz mreže spominjanja nisu izvedene mreže podrške, kritike ili citiranja.

Nije treniran klasifikator na oznakama konfiguracija koje su pale prethodnu provjeru. Takva bi obuka proširila iste nesigurne oznake na ostatak korpusa, a ne osigurala njihovu opravdanost. Nema ni objavljenog indeksa odnosa konfesionalnih i sekularnih govornih pojavljivanja jer nema prihvatljive govorne osnove za taj nazivnik.

Praznina u ovom poglavlju znači da odgovor nije ustanovljen primijenjenim postupkom. Ne znači da u korpusu nema tumačenja vjere ili da određene osobe nemaju tumačiteljsku ulogu.
''','withheld','Interpretive, authority and relation fields depend on the withdrawn speech/model layers.')

    networks='''
Mreže u ovom poglavlju povezuju osobe prema zajedničkom pojavljivanju. Prva mreža pita pojavljuju li se dvije osobe u istim izvorima. Druga pita pojavljuju li se u istim odlomcima. To su različite razine konteksta: dijeljenje izvora ne zahtijeva da su osobe ikad spomenute u istoj objavi.

## Izvori i osobe

Čvor osobe ulazi u početnu dvodijelnu mrežu ako je javno povezan suvremeni identitet koji zadovoljava uvjete objave. Veza osobe s izvorom označava prisutnost, a ne broj ponavljanja. Tako se učestalost odvojeno prikazuje opisnim mjerama, dok statistički model mreže koristi binarni odnos.

{{figure:sources}}

Skriveni računi nisu spojeni u jedan izvor tijekom računanja. Spojeni su samo u oznaku prikaza unutar platforme. Da su prije računanja spojeni, osobe koje se nikad nisu pojavile na istom računu mogle bi dobiti umjetnu zajedničku vezu.

{{figure:network_outlets}}

## Zajednički odlomci

Odlomak je određen praznim retkom u pohranjenom tekstu. Kad praznih redaka nema, cijeli tekst može postati jedan kontekst zajedničkog pojavljivanja. Dugačak pregledni tekst zato može spojiti osobe koje se u užoj rečeničnoj okolini ne pojavljuju zajedno. Takva je veza dokumentirana karakteristika ovog postupka, ne dokaz njihove stvarne međusobne veze.

{{figure:network_paragraphs}}
'''
    rows=[]
    for kind,label in [('outlets','Zajednički izvori'),('paragraphs','Zajednički odlomci')]:
        p='/evidence/mention_network_report/networks/'+kind
        rows.append([label,s(p+'/people',sensitive=True),s(p+'/contexts',sensitive=True),s(p+'/edges',sensitive=True),s(p+'/isolates',sensitive=True),s(p+'/communities',sensitive=True)])
    networks+=t('Puna statistički filtrirana mreža',['Sloj','Osobe','Konteksti','Veze','Izolirane osobe','Zajednice'],rows,
      'Izvor: pune mreže prije izostavljanja malih veza iz prikaza. Grafike prikazuju samo vodeći podskup osoba i dopuštene veze. Izolirana osoba nema zadržanu vezu u ovom sloju; nije nužno društveno izolirana.')
    networks+='''
## Kako čitati boje i posredničke položaje

Boje označavaju zajednice dobivene algoritmom Leiden na punoj filtriranoj mreži [@traag2019leiden]. Zajednica je skup s razmjerno gustim vezama prema primijenjenom kriteriju. Nije automatski škola mišljenja, organizacija ili suglasnost o vjeri. Nazivi zajednica ne proizlaze iz ručnog čitanja i zato nisu izmišljeni sadržajni opisi skupina.

Posrednički položaj mjeri prolazak najkraćih putova kroz čvor u izračunanoj mreži. Njegovo značenje ovisi o tome što veza predstavlja. Ovdje veza predstavlja zajednički izvor ili odlomak, pa posredništvo ne može biti dokaz posredovanja među ljudima, komunikacijske kontrole ili društvenog utjecaja.

Statističko filtriranje uspoređuje opažene preklape s modelom koji uzima u obzir nejednaku povezanost osoba i konteksta. Primjenjuje se korekcija za višestruke usporedbe. Zadržana veza stoga označava neočekivaniji preklop unutar tog modela, a ne sadržajno provjeren odnos među osobama [@neal2021alternatives; @neal2026backbone].
'''
    b.section('networks',networks)

    temporal='''
Vremenski prikaz opisuje promjenu relativne prisutnosti u prikupljenom korpusu. Svaki udio ima svoj tromjesečni nazivnik. Veći udio može nastati zbog više objava o osobi, zbog manje drugih objava ili zbog promijenjenog sastava izvora. Sam graf ne razlikuje te mogućnosti.

{{figure:temporal}}

## Stabilnost poretka unutar razdoblja

Uspoređuju se samo susjedna dostupna tromjesečja unutar istog razdoblja prikupljanja. Praznina u tromjesečjima prekida usporedbu. Kendallov koeficijent računa se samo za osobe koje su u vodećem skupu u oba tromjesečja; zato je uz njega nužno navesti broj zajedničkih osoba. Visoka suglasnost poretka preostalih osoba ne znači da nije bilo ulazaka i izlazaka.
'''
    rows=[]
    for i,item in enumerate(data['evidence']['network_metrics']['adjacent_top20']):
        p=f'/evidence/network_metrics/adjacent_top20/{i}'
        common=item['common_entities'];tau='mali zajednički skup' if common<5 else s(p+'/kendall_tau',kind='number',digits=2)
        rows.append([s(p+'/previous')+' → '+s(p+'/current'),s(p+'/common_entities',sensitive=True),tau,
          s(p+'/previous_top_survival',kind='percent') if item['previous_top_n']>=5 and common>=5 else 'mali skup'])
    temporal+=t('Susjedna tromjesečja: zajedničke osobe i promjene poretka',['Tromjesečja','Zajedničke osobe','Kendallov koeficijent','Zadržavanje prethodnog skupa'],rows,
      'Izvor: rangovi po broju objava sa spomenom unutar razdoblja. Jednaki brojevi dobivaju prosječan rang. Male zajedničke skupine i nedefinirani koeficijenti nisu prikazani kao pouzdane procjene.')
    temporal+='''
## Događaji kao mogući kontekst, bez uzročnog zaključka

Vrhunac prisutnosti može biti povod za naknadno istraživanje događaja, ali ovo izdanje ne pridružuje događaj samo zato što je vremenski blizu promjeni. Nije proveden neovisan postupak koji bi odvojio stvarnu promjenu javne pozornosti od promjene prikupljanja ili kruženja istog teksta.

Za čitanje pojedinog tromjesečja zajedno treba gledati platformu, broj različitih izvora i ponavljanje tekstova. Rang je relativan: pomak osobe može nastati i promjenom drugih osoba u istom skupu. U ovom se izvještaju ti pomaci ne nazivaju rastom utjecaja ili povjerenja.
'''
    b.section('temporal',temporal)

    circulation='''
Jednak ili vrlo sličan tekst može biti zabilježen više puta. Takve objave ostaju u korpusu jer opisuju dostupnu distribuciju, ali se dodatno povezuju u obitelji tekstova. Time se razlikuje broj zabilježenih objava od broja različitih skupina sadržaja.

{{figure:circulation}}

## Osjetljivost na prag sličnosti

MinHash služi pronalaženju kandidata za slične tekstove; za pronađene parove izračunava se točan Jaccardov preklop nizova riječi. Obitelji se zatim tvore kao povezane komponente. To znači da dva krajnja teksta mogu pripadati istoj obitelji preko međuteksta, iako njihov izravni preklop ne prelazi prag [@broder1997resemblance].
'''
    rows=[]
    for i,_ in enumerate(data['values']['circulation']):
        p=f'/values/circulation/{i}'
        rows.append([s(p+'/threshold',kind='number',digits=2),s(p+'/families',sensitive=True),s(p+'/repeated_families',sensitive=True),
          s(p+'/excess_appearances',sensitive=True),s(p+'/cross_platform_families',sensitive=True)])
    circulation+=t('Obitelji pri različitim pragovima',['Prag','Obitelji','Ponavljane obitelji','Dodatne objave unutar obitelji','Više platformi'],rows,
      'Izvor: povezane komponente potvrđenih parova tekstova. Dodatne objave znače broj objava iznad jedne po obitelji. One nisu dokaz preuzimanja, plagiranja ili izvornog autorstva.')
    circulation+='''
## Najranije zabilježeno nije nužno izvorno

Vrijeme prve dostupne objave može biti kasnije od stvarnog nastanka teksta. Izvorni tekst možda nije u korpusu, a datum zapisa može se odnositi na objavu, prijenos ili prikupljanje. Zato se najranija zabilježena verzija ne pripisuje kao izvorni doprinos određene osobe ili medija.

Prepoznavanje obitelji također ima granice. Približno pronalaženje kandidata ne jamči pronalazak svakog sličnog para. Kratki tekstovi, promjena redoslijeda ili veća prerada mogu promijeniti preklop. Obitelji služe opisu kruženja prema objavljenim pravilima, a ne potpunoj rekonstrukciji puta širenja.
'''
    b.section('circulation',circulation)

    methods=f'''
## Podatci i slijed obrade

Analiza je vezana uz jednu verziju službenog korpusa, označenu sažetkom {s('/presentation/corpus_sha_short')}. Pohranjeni su izvorni identifikatori redaka, postavke obrade, inačice programa i dokazi o dovršenim koracima. Sadržaj korpusa nije poslan vanjskom jezičnom modelu. Upiti javnim izvorima odnose se na javna imena, dužnosti i podatke o identitetima.

CLASSLA odvojeno obrađuje standardni i nestandardni tekst. Prepoznati raspon mora odgovarati doslovnom položaju u izvornom tekstu. Pogreška obrade ostaje pogreška, a ne negativan nalaz da osoba ili izjava ne postoji [@ljubesic2024classla].

Radi izvedivosti morfološki su obrađena najviše {s('/constants/form_context_limit')} različita konteksta po obliku, signalu uloge i vrsti modela. To je odstupanje od obrade svake pojedine pojave; nesuglasni rezultati ostaju nerazriješeni. Javno povezivanje pokušano je za vodećih najviše {s('/constants/public_link_limit')} osnovnih skupina imena. Rijetka imena izvan tog skupa nemaju jednak postupak provjere identiteta.

Rezultati se spremaju u transakcijama s oznakom dovršenosti. Nakon prekida ponovno se obrađuju samo nezavršene jedinice. Čuvanje baze i pripadajućeg dnevnika omogućuje nastavak nakon uobičajenog prekida; ne zamjenjuje neovisnu sigurnosnu kopiju u slučaju fizičkog kvara diska.
'''
    form_labels={'agreed':'Podudarni rezultati u svim zadržanim kontekstima',
      'ambiguous':'Različiti rezultati među kontekstima',
      'unaligned':'Nedostatno poravnanje ili izostala lema'}
    rows=[[form_labels[status],s('/values/name_forms/statuses/'+status,sensitive=True)]
      for status in sorted(data['values']['name_forms']['statuses'])]
    methods+=t('Ishodi normalizacije oblika imena',['Ishod','Oblici'],rows,
      'Izvor: završeni zapisi normalizacije, usklađeni sa završnim izvještajem obrade. Jedinica je oblik uz signal uloge i vrstu modela, a ne osoba ili spomen. Podudarnost među kontekstima nije provjera točnosti imena ili identiteta. Nepodudarni i nedostatno poravnati oblici ne spajaju se prema nagađanoj lemi; male su ćelije skrivene.')
    counts=b.complementary_counts(['/values/public_name_linkage/linked','/values/public_name_linkage/without_accepted_link'])
    methods+=t('Obuhvat povezivanja javnih imena',['Ishod','Skupine imena'],
      [['Prihvaćena veza s javnim identitetom',counts[0]],['Bez prihvaćene veze',counts[1]]],
      'Izvor: svi odabrani zapisi povezivanja, usklađeni sa završnim izvještajem. Skupine nisu različite osobe: više skupina može upućivati na isti identitet. Drugi redak obuhvaća nerazriješene, višeznačne i sakralne oznake bez objave njihovih malih podskupina. Ako je jedan od prikazanih brojeva malen, skrivena su oba. To nije provjera točnosti ni potpunosti prepoznavanja. Dodatna datirana obrada titula i uvjeti javnog imenovanja primjenjuju se poslije ovog koraka.')
    methods+=f'''

## Javna identifikacija i uvjeti imenovanja

Ime se normalizira uz očuvanje dokaza o obliku u tekstu. Grupiranje traži kompatibilnost osobnog imena ili inicijala, prezimena i uloga. Nesuglasne uloge ne spajaju se samo zbog sličnog prezimena. Morfološki nejasni ili jednorječni oblici ostaju odvojeni.

Imenovani prikaz traži javno povezan identitet, najmanje {s('/constants/d6_documents')} objava i najmanje {s('/constants/d6_sources')} različita neprazna izvora. Naziv korisničkog računa nije automatski javan samo zato što je zapisan kao mrežna adresa. Neobjavljivi računi prikazuju se u skupini svoje platforme. Ćelije s manje od {s('/constants/minimum_cell')} opažanja ne objavljuju se, uključujući udjele koji bi ih omogućili izračunati.

## Vremenska valjanost službe i životnog razdoblja

Titula bez imena povezuje se s osobom samo ako javni zapis podržava jedinstvenog nositelja službe na datum teksta. Nepoznat početak mandata, preklop mogućih nositelja ili povijesni kontekst sprečavaju automatsko razrješenje. Datum imenovanja, ređenja, preuzimanja službe i umirovljenja nisu međusobno zamjenjivi.

Trenutačni službeni imenici korišteni su kao provjera pokrivenosti i izvor dopuštenih naziva, a ne kao potpuni povijesni registar [@hbkBishops2026; @bkbihBishops2026]. Za {s('/evidence/office_coverage_report/matched_titles')} od {s('/evidence/office_coverage_report/active_directory_entries')} aktivnih unosa pronađen je prihvatljiv datirani naslov. Preostale praznine nisu popunjene nagađanjem.

Zasebno je primijenjena pretpostavka da poznati početak službe stariji od {s('/evidence/office_coverage_report/maximum_tenure_years')} kalendarskih godina ne podržava sadašnju službu. To nije izmišljeni datum smrti ili završetka mandata. Izostanak zabilježene smrti također nije neovisno potvrđen dokaz da je osoba živa.

## Poznata imena kao provjera obuhvata

Uspoređen je poznati popis imena s rasponima koje je označio prepoznavač. Mjeri se njihov preklop u dostupnom tekstu. Ova provjera ne obuhvaća nepoznata imena i ne daje ukupnu točnost ni ukupnu sposobnost pronalaska svih osoba. Kad je udio ispod {s('/constants/ner_proxy_threshold',kind='percent')}, broj osoba na toj platformi čita se kao donja granica prema tom pokazatelju. Taj naziv označava upozorenje na moguće propuštene spomene, a ne dokazanu donju granicu stvarnog broja: nepoznat broj pogrešno prepoznatih spomena može djelovati u suprotnom smjeru.
'''
    rows=[]
    for i,item in enumerate(data['evidence']['gazetteer_report']['platforms']):
        p=f'/evidence/gazetteer_report/platforms/{i}'
        rows.append([s(p+'/platform'),s(p+'/gazetteer_hits',sensitive=True),s(p+'/ner_overlap',sensitive=True),r(p+'/ner_overlap',p+'/gazetteer_hits'),
          'donja granica' if item['lower_bound_label'] else 'prag dosegnut'])
    methods+=t('Preklop poznatih imena i automatskih raspona',['Platforma','Poznati rasponi','Preklop','Udio','Posljedica'],rows,
      'Izvor: poznati imenik i cijeli tekst korpusa. Dijeljenje barem jednog znaka smatra se preklopom. Platforma bez prihvatljivog nazivnika nema procjenu; prolazak praga nije dokaz ukupne točnosti.')
    methods+=f'''
## Stabilnost spajanja imena

Među vodećim {s('/evidence/cluster_report/top_entities')} osnovnim skupinama imena, njih {s('/evidence/cluster_report/shifted_over_five_percent',sensitive=True)} promijenilo je broj objava za više od {s('/constants/cluster_change_threshold',kind='percent')} pri promjeni praga. Osnovna skupina uspoređuje se s jednom alternativnom skupinom s najvećim zajedničkim brojem dokumenata. Nakon podjele ne spajaju se ponovno sva djeca iste skupine jer bi se time prikrila osjetljivost.

Ako alternativna skupina sadrži oblike povezane s različitim javnim identitetima, ona se ne pripisuje nijednome od njih kao sigurno proširenje. Datumi se ponovno provjeravaju, a titule razriješene prema službi ostaju fiksne. Prikazani raspon obuhvaća te scenarije; ne izračunava vjerojatnost da je stvaran broj u tom rasponu.

## Konstrukcijske provjere i tehnička obrada odgovora

Konstruirani slučajevi imaju unaprijed određena očekivanja. Njihovi tekstovi i očekivanja nisu oslabljeni nakon neuspjeha modela. Inačice razlikuju način zadavanja kandidata i kategorija; promjena inačice ne pretvara neprolaznu ocjenu ranije inačice u uspjeh.
'''
    rows=[]
    for i,item in enumerate(data['evidence']['model_gate_summary']['configurations']):
        p=f'/evidence/model_gate_summary/configurations/{i}'
        rows.append([s(p+'/protocol'),s(p+'/model'),s(p+'/passed'),s(p+'/cases'),'prolaz' if item['synthetic_gate_passed'] else 'neprolaz'])
    methods+=t('Sve završene konstruirane provjere',['Protokol','Model','Prolazni slučajevi','Ukupno','Odluka'],rows,
      'Izvor: nepromijenjeni konstruirani slučajevi i spremljeni odgovori, ponovno usklađeni s bazom. Rezultat vrijedi za ove zadatke i konfiguracije; nije procjena točnosti na stvarnom korpusu.')
    rows=[]
    for i,item in enumerate(data['evidence']['model_gate_summary']['configurations']):
        if not item['benchmark']:continue
        p=f'/evidence/model_gate_summary/configurations/{i}'
        rows.append([s(p+'/model'),s(p+'/benchmark/n'),s(p+'/benchmark/json_valid_first',kind='percent'),
          s(p+'/benchmark/mechanically_accepted_first',kind='percent'),s(p+'/benchmark/final_failed'),s(p+'/benchmark/effective_seconds_per_window',kind='number',digits=2)])
    methods+=t('Izmjerena tehnička izvedba kodera',['Model','Prozori','Valjan početni JSON','Početna mehanička prihvatljivost','Završne pogreške','Sekunde po prozoru'],rows,
      'Izvor: spremljena mjerenja stvarnih prozora. Mehanička prihvatljivost provjerava format i vezu s izvorom, ne semantičku ispravnost. Vrijeme uključuje potrebne ponovljene pokušaje.')
    rows=[]
    for i,_ in enumerate(data['evidence']['publication_audit']['benchmark_database_reconciliation']):
        p=f'/evidence/publication_audit/benchmark_database_reconciliation/{i}'
        rows.append([s(p+'/model'),s(p+'/calls'),s(p+'/mechanical_failures'),s(p+'/mechanical_failure_share',kind='percent')])
    methods+=t('Svi primljeni pokušaji i mehaničke pogreške',['Model','Primljeni pokušaji','Neprihvatljivi pokušaji','Udio'],rows,
      'Izvor: odgovori ponovno rekonstruirani iz baze. Nazivnik uključuje ponovljene pokušaje. Objedinjena provjera obuhvaća shemu, doslovne dokazne jedinice, kandidate i logička ograničenja; nije odvojena procjena semantičke ispravnosti svakog uvjeta.')
    methods+='''
## Provjere pripisivanja i posljedice za objavu

Provjera prvog lica uvjetovana je već povezanim potpisnikom i opaženim gramatičkim signalom. Ona pita vraća li pravilo tog potpisnika; ne provjerava samostalno je li objava autorska, citirana ili pravilno interpretirana. Objave s nepoznatim potpisnikom izvan su njezina nazivnika.
'''
    rows=[]
    for i,_ in enumerate(data['evidence']['speech_rule_report']['author_recovery']):
        p=f'/evidence/speech_rule_report/author_recovery/{i}'
        rows.append([s(p+'/platform'),s(p+'/eligible',sensitive=True),s(p+'/recovered',sensitive=True),r(p+'/recovered',p+'/eligible')])
    methods+=t('Uvjetni povrat poznatog potpisnika',['Platforma','Prihvatljive rečenice','Vraćen potpisnik','Udio'],rows,
      'Izvor: dovršeni rezultati pravila. Nema procjene za platforme bez prihvatljivih slučajeva. Ovo je unutarnja mehanička dosljednost, ne neovisna procjena prepoznavanja govora.')
    checks=data['evidence']['publication_audit']['checks'];death='/evidence/publication_audit/checks/M-ID-2'
    methods+=f'''
Za datirane papinske titule provjereno je {s('/evidence/publication_audit/checks/M-ID-1/resolved_papal_titles',sensitive=True)} razriješenih spomena, uz {s('/evidence/publication_audit/checks/M-ID-1/violations',sensitive=True)} kršenja poznatih vremenskih granica. Zaseban privatni uzorak od {s('/evidence/publication_audit/checks/M-ID-4/pairs')} parova spojenih imena izvezen je bez ljudskog bodovanja.

Provjera izravnih izjava obuhvatila je {s(death+'/direct_statements',sensitive=True)} pravilu pripisanih slučajeva, uz {s(death+'/violations',sensitive=True)} kršenja poznate granice smrti. Povijesni identiteti već su isključeni u ranijem koraku, pa je rezultat uvjetna dosljednost postupka. Nepostojanje zabilježenog kršenja ne dokazuje da su identiteti ili govornici neovisno potvrđeni.

Unaprijed zadano pravilo za prvo lice traži najmanje {s('/constants/author_threshold',kind='percent')} povrata poznatog potpisnika. Za glavne modelne nalaze tražilo bi se međumodelsko slaganje od najmanje {s('/constants/agreement_main',kind='number',digits=2)}, a za istraživački dodatak najmanje {s('/constants/agreement_appendix',kind='number',digits=2)}. Ponovljivost bi morala dosegnuti {s('/constants/repeat_threshold',kind='percent')}. Udio mehaničkih pogrešaka veći od {s('/constants/grounding_failure_limit',kind='percent')} povlači odgovarajući modelni nalaz. Ti su brojevi pravila odlučivanja, a ne izmjereni rezultati neprovedenih provjera.

Nije provedeno uspoređivanje modela na stvarnim prozorima niti ponovno kodiranje za procjenu determinističnosti jer nije zadovoljen njihov prethodni uvjet. Stoga se ne navode izmišljeni koeficijenti slaganja ili udjeli ponovljivosti. Nije provedena ni provjera distiliranog klasifikatora jer nije bilo prihvatljivih oznaka za obuku.

Robusnost govorne mreže na dodavanje i brisanje veza nije izračunana: nema prihvatljive govorne mreže. Usporedba strogog pravila i unije pravila s modelom iz istog razloga nema valjanu drugu stranu. Te se provjere ne zamjenjuju perturbacijom mreže spominjanja.
'''
    rows=[]
    descriptions=[('M-GR-1','Format odgovora','dovršeno; zajednička mehanička provjera'),
      ('M-GR-2','Dokazni odsječak iz izvora','dovršeno; zajednička mehanička provjera'),
      ('M-GR-3','Ime iz teksta ili potpisnika','dovršeno; zajednička mehanička provjera'),
      ('M-GR-4','Identitet među kandidatima','dovršeno; zajednička mehanička provjera'),
      ('M-ID-1','Datirani nositelj papinske službe','dovršeno; korpusna provjera'),('M-ID-2','Izravna izjava nakon smrti','dovršeno; uvjetna provjera'),
      ('M-ID-3','Osjetljivost grupiranja imena','dovršeno; rasponi prema pravilu'),('M-ID-4','Parovi spojenih imena','privatno izvezeno, bez bodovanja'),
      ('M-REC-1','Preklop poznatih imena','dovršeno po dostupnim nazivnicima'),('M-SP-1','Povrat poznatog potpisnika','dovršeno uvjetno'),
      ('M-AG-1','Slaganje dvaju modela','nije provedeno: prethodni uvjet nije zadovoljen'),('M-ST-1','Ponovljivost stvarnih oznaka','nije provedeno: prethodni uvjet nije zadovoljen'),
      ('M-AG-2','Slaganje klasifikatora s modelom','nije primjenjivo: nema prihvatljive obuke'),
      ('M-ROB-1','Perturbacija govorne mreže','nije primjenjivo: govorni sloj je povučen'),
      ('M-ROB-2','Strogo i prošireno govorno rangiranje','nije primjenjivo: modelni sloj je povučen')]
    for code,label,status in descriptions:rows.append([s('/evidence/publication_audit/checks/'+code+'/check_id'),label,status])
    methods+=t('Obuhvat strojnih provjera i neraspoložive procjene',['Oznaka','Provjera','Stanje i granica zaključka'],rows,
      'Izvor: završni audit i spremljene odluke. Dovršenost provjere znači da je postupak izveden; nije isto što i potvrđena točnost. Prethodni neprolaz ostaje vidljiv kao razlog neprovedene sljedeće provjere.')
    b.section('methods',methods)

    b.section('limitations','''
## Obuhvat i dostupnost sadržaja

Korpus opisuje prikupljene tragove javne komunikacije. Neke platforme daju kraći, posredan ili nepotpun tekst; za video to može biti naslov, opis ili drugi dostupan tekst. Takav zapis ne obuhvaća nužno izgovorene riječi. Ista se brojka zato ne smije bez objašnjenja tumačiti kao usporediva količina komunikacije na svim platformama.

Promjena izvora, pravila prikupljanja ili dostupnosti može promijeniti raspodjelu osoba i bez promjene njihova djelovanja. Odvajanje razdoblja umanjuje jedan poznat problem, ali ne uklanja sve promjene sastava korpusa. Udjeli i rangovi ostaju ovisni o dostupnom nazivniku.

## Identitet nije zajamčen nizom znakova

Slična imena mogu pripadati različitim osobama, a ista osoba može biti navedena različitim oblicima. Uloge, gramatički oblik i datumi pomažu razrješenju, ali ne čine ljudsku provjeru suvišnom. Povezivanje s javnim zapisom provodi se samo u zadanom vodećem skupu i zato je obuhvat drugih osoba ograničen.

Kratke, jednorječne, lokalne i rijetke inačice posebno su osjetljive na propuštanje. Uvjeti javnog imenovanja štite od objave slabo potkrijepljenih identiteta, ali istodobno sužavaju imenovani prikaz na vidljivije osobe. Izostanak osobe iz tablice nije dokaz da se u korpusu ne pojavljuje.

Službeni trenutačni imenik može potvrditi javno ime i naziv službe, ali sam ne daje cjelovitu povijest mandata. Nepotpuni datumi i otvorene službe ostaju ograničenje. Pravila se ne mogu smatrati povijesnom validacijom svih prepoznatih titula.

## Ograničenja mreža i kruženja

Mreža nasljeđuje pogreške prepoznavanja, povezivanja identiteta i granica konteksta. Statistička značajnost veze unutar modela ne popravlja pogrešan ulazni identitet. Prikazane zajednice mogu ovisiti o tome kako su izvori i odlomci zabilježeni.

Obitelji tekstova približno grupiraju sličan sadržaj. One nisu potpuna karta prenošenja. Najranija zabilježena objava nije dokaz izvornosti, a višestruko pojavljivanje nije samo po sebi dokaz koordinacije.

## Što ovim izdanjem nije ustanovljeno

Nisu ustanovljeni pouzdani rangovi govornika, udjeli tumačenja vjere, vrste autoriteta, odnosi podrške ili kritike, niti zajedničke skupine tvrdnji. Povlačenje tih rezultata ograničava doseg odgovora na naslovno pitanje. Objavljeni opis spominjanja ostaje koristan kao karta prisutnosti u korpusu, uz sve navedene uvjete.

Nema procjene točnosti, preciznosti ili potpunosti prepoznavanja na ljudski označenom uzorku. Ne izvodi se zaključak o vjerovanju, povjerenju ili utjecaju. Za takva bi pitanja trebali drugačiji podatci, drugačiji istraživački nacrt i neovisna provjera.
''')

    exploratory='''
## Tvrdnje i sadržajna sličnost

Neobvezni modul skupina tvrdnji izostavljen je iz ovog izdanja jer nema prihvatljive osnove sažetaka izjava. Tematska sličnost tvrdnji, kad bi bila dostupna, ne bi sama označavala slaganje ili zajedničko stajalište. U ovom se izvještaju stajalište ne kodira.

Govorni nalazi za YouTube i Twitter nisu premješteni u dodatak kao način zaobilaženja neprolaznih provjera. Ostaju povučeni zajedno s ostalim nevalidiranim govornim oznakama. Raspodjela njihovih dostupnih tekstova i automatskih spomena obuhvaćena je opisnim poglavljima.

## Nerazriješene službe u provjeri imenika

Sljedeći popis sažima nazive službi iz aktualne službene provjere za koje nije pronađen prihvatljiv datirani par. Imena tih nositelja ne prenose se u ovaj prilog samo zato što su na javnom popisu: imenovani korpusni nalazi i dalje podliježu uvjetima javnog prikaza. Praznina označava ograničenje registra i pravila, a ne osporavanje nečije službe.
'''
    rows=[];seen_roles=set()
    for i,item in enumerate(data['evidence']['office_coverage_report']['coverage']):
        if not item['matched'] and item['role'] not in seen_roles:
            rows.append([s(f'/evidence/office_coverage_report/coverage/{i}/role'),'bez prihvatljivog jedinstvenog datiranog para'])
            seen_roles.add(item['role'])
    exploratory+=t('Nepokriveni nazivi službi',['Naziv službe u provjeri','Stanje'],rows,
      'Izvor: aktualni službeni imenici i zamrznuti javni registar. Jednaki nazivi prikazani su jednom; broj redaka nije broj nepokrivenih nositelja. Nazivi mogu uključivati složene uloge koje nisu prihvaćene kao jednoznačan naslov. Nisu dodani pretpostavljeni datumi mandata.')
    exploratory+='''
## Dostupni trag postupka

Sačuvani su sirovi lokalni odgovori modela, mehaničke pogreške, ishodi konstruiranih slučajeva, postavke, verzije i zapis nastavka nakon prekida. Ti zapisi omogućuju odvajanje tehničkog neuspjeha od neuspjeha tumačenja. Privatni primjeri i neobjavljivi identiteti ostaju izvan javnih tablica.

Popis spojenih oblika imena izvezen je za mogući zaseban pregled, ali nije ljudski ocijenjen. Njegovo postojanje ne pretvara ga u validacijski skup. Buduće poboljšanje modela ili registra mora dobiti novu verziju i novu provjeru prije nego promijeni ovdje navedeni doseg zaključaka.
'''
    b.section('exploratory',exploratory,'not_applicable')
    return b.registry
