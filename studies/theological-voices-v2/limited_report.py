"""Reader-facing fallback explicitly permitted by the master instruction.

No model-derived semantic percentages or selected positive cases are presented when
primary machine checks fail. Raw estimates remain in private audit tables only.
"""
import json
from xml.sax.saxutils import escape
from build_report import Report, REPORT, FIG, PNG, OUT, CFG, M, W, TEAL, NAVY, ROLE_HR, n, p, read, bar, monthly, register_fonts, render_final

def build_limited(d,policy):
    if policy['config_hash']!=d['config_hash'] or d['completed_main']!=CFG['sample_size']:
        raise RuntimeError('Limited report still requires the complete frozen main run')
    for folder in [REPORT,FIG,PNG]:folder.mkdir(parents=True,exist_ok=True)
    register_fonts();pdf=REPORT/'tko-dobiva-rijec-o-vjeri-v2.pdf';r=Report(pdf)
    frame=d['frame'];N=frame['publications'];source=read('source_concentration.csv')
    quality=json.loads((OUT/'development_review.json').read_text(encoding='utf-8'))
    diagnostic=json.loads((OUT/'diagnostic_review.json').read_text(encoding='utf-8'))
    probe=json.loads((OUT/'statement_probe_review.json').read_text(encoding='utf-8'))
    challenge=json.loads((OUT/'challenge_disagreements.json').read_text(encoding='utf-8'))
    reuse_cases=json.loads((OUT/'deterministic_reuse_cases.json').read_text(encoding='utf-8'))['cases']
    runtime_record=json.loads((OUT/'configs'/f'{d["config_hash"]}.json').read_text(encoding='utf-8'))
    coding=runtime_record['configuration'];options=coding['options']
    failures=[x for x in diagnostic['checks'] if x['failures'] or x['structural_status']!='complete']

    r.new('Ograničeni istraživački izvještaj / drugo izdanje','Tko dobiva riječ<br/>o vjeri?',
          f'{n(N)} dohvaćenih publikacija i dovršena lokalna obrada uzorka od {n(d["sample"])} članaka. Brojčane tvrdnje o sadržaju povučene su zbog ishoda strojnih provjera.')
    r.para('Što građa dopušta<br/>pouzdano prebrojiti?',M,545,W-2*M,34,'SerifBold',110,TEAL)
    r.notes('Izvještaj donosi obuhvat, uzorkovanje, ponavljanje tekstova i stvarne ishode obrade. Ne donosi poredak teologa ili procjenu zastupljenosti njihovih glasova.',
            'Nema ljudske validacije ni izmjerene točnosti. Neuspjela provjera nije pretvorena u tvrdnju da u članku nema govornika.',
            f'Izvor: DigiKat, {CFG["period_start"]} - {CFG["period_end"]}. Lokalni Qwen3 14B. Način izvještavanja: limited_exploratory.')

    r.new('Nalaz / granica odgovora','Na glavno pitanje zasad nema održive brojčane procjene',
          'Postupak je dovršen, ali to ne znači da je svaki njegov sadržajni rezultat prihvatljiv za izvještavanje.')
    r.textblocks([('Što možemo reći',f'U zamrznutom okviru nalazi se {n(N)} web publikacija. Pet najzastupljenijih izvornih oznaka nosi {p(d["top5_source_share_pct"])} zabilježenih objava. To opisuje prikupljenu ponudu, ne publiku ili utjecaj.'),
      ('Što je povučeno','Učestalosti govornika, akademske teološke uloge, tumačenja, iskustva i sadržajnih tema ne prikazujemo kao nalaze. Dijagnostika nije zadovoljila unaprijed spremljenu politiku izvještavanja.'),
      ('Što to ne znači','Odsutnost brojčane procjene nije dokaz da teolozi nisu prisutni u medijima. Nije dokaz prevlasti druge skupine ni zaključak o kvaliteti javnoga govora o vjeri.')])

    r.new('Građa / jedinica analize','Izvozni redak nije nužno nova publikacija',
          'Zadržane su legitimne objave istoga sadržaja u različitim medijima, a uklonjeni ponovljeni zahvati iste publikacije.')
    r.textblocks([('Od arhiva do okvira',f'{n(frame["export_records"])} izvoznih redaka svedeno je na {n(N)} publikacija. Uklonjeno je {n(frame["duplicates_removed"])} ponovljenih izvoznih zapisa. Veza s izvornim retkom ostaje spremljena.'),
      ('Obuhvat','Analizira se službena dohvaćena tematska zbirka uredničkih web članaka. To nije popis svih hrvatskih medija ili svih članaka koji postoje. Regionalno preklapanje i izvorne lokacijske oznake ostaju dio građe.'),
      ('Nedostajući nazivnik','Bez usporedivoga broja svih medijskih sadržaja istih izvora i datuma ne može se izračunati udio ove teme u ukupnom novinarstvu. Vidljivost u arhivu nije društveni doseg.')])

    r.new('Vidljivost / vrijeme','Promjene prikupljanja ograničavaju vremensku usporedbu',
          'Mjesečne količine odnose se na cijeli dohvaćeni okvir i ne ovise o sadržajnoj klasifikaciji modela.')
    r.chart(monthly('limited-months.png',read('frame_month.csv')))
    r.notes('U 2026. obuhvat završava 11. lipnja. Od veljače do svibnja 2024. izvor nema tekstove.',
            'Promjena prikupljanja u srpnju 2024. znači da skok količine ne možemo pripisati rastu medijske pažnje.',
            f'Izvor: tables/frame_month.csv. Jedinica: publikacija. Baza: {n(N)}. Deterministički izračun.')

    r.new('Vidljivost / izvori','Najzastupljeniji izvori oblikuju prikupljenu ponudu',
          f'Pet izvora nosi {p(d["top5_source_share_pct"])} okvira. Prikazano je deset izvornih oznaka s najviše publikacija.')
    z=source.head(10);r.chart(bar('limited-sources.png',z.outlet_name,z.share_pct,'Udio u dohvaćenom okviru (%)'))
    r.notes('Broj se odnosi na objave, a isti sadržaj može imati više legitimnih publikacija.',
            'Pokrivenost dobavljača i ponovljeni sadržaj mogu utjecati na koncentraciju. Količina nije doseg ili autoritet.',
            f'Izvor: tables/source_concentration.csv. Baza: {n(N)} publikacija; {n(frame["sources"])} izvornih oznaka.')

    r.new('Uzorkovanje / glavni skup','Odabir obuhvaća cijelo razdoblje, razmjerno njegovim dijelovima',
          'Slučajno uzorkovanje bez zamjene stratificirano je po kalendarskim tromjesečjima. Glavni uzorak ostao je nepromijenjen.')
    alloc=read('sample_allocation.csv');r.chart(bar('limited-sampling.png',alloc.stratum,alloc.n_h,'Broj odabranih publikacija',color=NAVY,count_labels=True))
    r.notes('Svaki zapis ima vjerojatnost uključivanja i ponder. Zbroj pondera jednak je veličini zamrznutog okvira.',
            'Razvojnih 100 i svježih 30 članaka odvojeni su od glavnih 2.000. Ponderiranje ne uklanja pogreške modela ni pristranost zbog nedostupnog teksta.',
            'Izvor: main_manifest.csv i tables/sample_allocation.csv. Sjeme 20261017; proporcionalni odabir po tromjesečjima.')

    reuse=d['reuse'];den=reuse['eligible_publications'];share=100*reuse['publications_in_repeated_families']/den if den else 0
    r.new('Kruženje / jednakost teksta','Isti tekst može biti objavljen više puta',
          f'{p(share)} publikacija s najmanje 400 znakova dijeli identičan očišćeni tekst s drugom publikacijom u okviru.')
    r.chart(bar('limited-reuse.png',['U ponovljenim tekstovima','U ponavljanju između izvora'],
                [share,100*reuse['publications_in_cross_outlet_families']/den if den else 0],'Udio publikacija s najmanje 400 znakova (%)',color=NAVY))
    r.notes('Uspoređuje se cijelo očišćeno tijelo teksta. Naslovi ne određuju ovu jednakost.',
            'Jednakost nije dokaz smjera preuzimanja, izvornog autora ili plagijata. Blago izmijenjene verzije nisu obuhvaćene.',
            f'Izvor: tables/exact_reuse_families.csv. Baza: {n(den)} publikacija iz cijeloga okvira. Izračun bez modela.')

    for case in reuse_cases:
        heading='Isti spremljeni tekst na isti datum' if case['span_days']==0 else 'Isti spremljeni tekst na različite datume'
        r.new('Kruženje / odabrani primjer iz cijeloga okvira',heading,
              'Objave su povezane identičnim tijelom arhiviranog teksta, bez modelskih oznaka govornika. Naslovi služe identifikaciji zapisa.')
        r.para(f'{n(case["publications"])} objava · {n(case["outlets"])} izvornih oznaka',M,595,W-2*M,21,'SerifBold',40,TEAL)
        for index,member in enumerate(case['display_members']):
            y=542-index*61
            outlet=str(member['outlet_name']);outlet=outlet if len(outlet)<=50 else outlet[:47]+'…'
            title=str(member['title']);title=title if len(title)<=100 else title[:97]+'…'
            r.para(escape(outlet)+' · '+escape(str(member['published_at'])[:10]),M,y,W-2*M,10.2,'Bold',18)
            r.para(escape(title),M,y-21,W-2*M,9,maxheight=30)
            if str(member['url']).startswith(('https://','http://')):
                r.c.linkURL(str(member['url']),(M,y-51,W-M,y-19),relative=0,thickness=0)
        r.notes(f'Obitelj sadrži {n(case["publications"])} publikacija. Zabilježeni datumi: {case["first_date"]} do {case["last_date"]}. Prikazane su {n(len(case["display_members"]))} odabrane objave; naslov vodi na spremljenu izvornu poveznicu.',
                'Ovo je namjerno odabran primjer, ne procjena učestalosti. Jednak arhivski zapis može odražavati preuzimanje, predložak ili problem zahvata; uzrok, autorstvo i smjer nisu provjereni.',
                f'Izvor: frame.parquet i deterministic_reuse_cases.json; tekst ≥1.000 znakova, 3–5 izvornih oznaka. Otisak {case["text_hash"][:16]}. Poveznice nisu ponovno provjerene na mreži.')

    r.new('Obrada / račun svih odabranih zapisa','Neuspjeh ostaje vidljiv u rezultatu',
          f'Svih {n(d["sample"])} odabranih publikacija ima spremljen ishod. Članak se ne zamjenjuje zato što ga je teško obraditi.')
    labels={'complete':'Strukturno dovršeno','partial_processing':'Dio zadataka valjan','failed':'Neuspjela obrada','missing_text':'Nedostajući tekst'}
    status=d['status_counts'];r.chart(bar('limited-processing.png',[labels.get(k,k) for k in status],list(status.values()),'Broj publikacija glavnog uzorka',color=NAVY,count_labels=True))
    r.notes(f'Strukturno dovršen zapis može sadržavati pogrešnu oznaku ili nepotpun izvor. Za {n(d["input_delivery_counts"].get("confirmed_full",0))} zapisa potvrđeno je da spremljeni zahtjevi s modelskim odgovorom sadrže sve odlomke i naslov. To nije provjera razumijevanja ili točnosti.',
            'Nedostajući tekst, pogreška obrade, sadržajna neodređenost i uspješno utvrđena odsutnost različita su stanja.',
            'Izvor: tables/articles.csv i tables/input_delivery.csv. Baza: glavni uzorak. Operativne kategorije, bez sadržajnih udjela.')

    r.new('Izvori / potpunost teksta','Uspjela obrada ne znači da je izvor potpun',
          'Potpunost arhiviranog teksta vodi se zasebno od ispravnosti formata modelova odgovora. I nepotpuni izvori ostaju u evidenciji.')
    source_names={'complete':'Prividno potpun','partial':'Djelomičan','unresolved':'Nerazriješen','unavailable':'Nedostupan','unreadable':'Nečitljiv'}
    source_states=d['source_content_counts']
    r.chart(bar('limited-source-quality.png',[source_names.get(k,k) for k in source_states],list(source_states.values()),
                'Broj publikacija glavnog uzorka',color=NAVY,count_labels=True))
    r.notes('Oznake proizlaze iz spremljenih arhivskih signala i prosudbi lokalnog modela. Djelomičan tekst ne pretvara se u članak bez govornika.',
            'Nije provedena usporedba svake kopije sa živom izvornom stranicom. Prividna potpunost nije potvrđena autentičnost ili cjelovitost izvora.',
            f'Izvor: tables/articles.csv, polje source_content. Baza: svih {n(d["sample"])} odabranih publikacija. Dijagnostika izvora, bez procjene zastupljenosti glasova.')

    r.new('Obrada / zasebni zadaci','Valjanost jednog zadatka ne popravlja drugi',
          'Sačuvane su zasebne oznake za teme, spomene, govornike i opisane skupine. Ove baze služe reviziji postupka.')
    hr={'topics':'Relevantnost i teme','mentions':'Imenovani spomeni','speakers':'Pripisani govornici','groups':'Opisane skupine'}
    r.chart(bar('limited-bases.png',[hr[k] for k in d['bases']],[v['structurally_valid'] for v in d['bases'].values()],
                'Broj strukturno valjanih zadataka',color=NAVY,count_labels=True))
    r.notes('Broj prikazuje prolazak provjere formata, dokaza i pokrivenosti. Ne prikazuje semantičku točnost oznaka.',
            'Izračunate sadržajne tablice ostaju u privatnoj evidenciji, označene kao povučene iz izvještavanja. Ovdje se ne koriste za poredak glasova.',
            'Izvor: denominators.json, tables/failure_patterns.csv i report_policy.json. Baza: svih 2.000 odabranih publikacija.')

    r.new('Dijagnostika / stvarni ishod','Konstruirani primjeri otkrili su ograničenja postupka',
          'Ovi primjeri provjeravaju pravila. Nisu uzorak iz kojega se može izračunati točnost modela na stvarnim člancima.')
    explanations=[]
    for case in failures[:2]:
        role_failure=next((x for x in case['failures'] if x.get('field')=='role'),None)
        if role_failure:
            expected=ROLE_HR.get(role_failure['expected'],role_failure['expected'])
            actual=', '.join(ROLE_HR.get(x,x) for x in role_failure['actual']) or 'nijedna uloga'
            explanations.append(f"U primjeru {case['id']} zadana je uloga {expected.lower()}, a model je vratio: {actual.lower()}.")
        elif any(x.get('field')=='has_groups' for x in case['failures']):
            explanations.append(f"U primjeru {case['id']} nije ispravno prepoznata prisutnost skupine na koju se posljedica odnosi.")
        elif any(x.get('field')=='voices' for x in case['failures']):
            failure=next(x for x in case['failures'] if x.get('field')=='voices')
            explanations.append(f"U primjeru {case['id']} očekivani broj govornika bio je {failure['expected']}, a model je zadržao {failure['actual']}.")
        else:
            explanations.append(f"Primjer {case['id']} nije zadovoljio zadanu sadržajnu ili strukturnu provjeru.")
    failed_names=' '.join(explanations) or 'Sintetska pravila su zadovoljena; ograničenje proizlazi iz druge provjere zabilježene u politici izvještavanja.'
    r.textblocks([('Trideset sintetskih primjera',f'{n(30-len(failures))} primjera zadovoljilo je zadane provjere, a {n(len(failures))} nije. Posebno se provjeravaju spomen bez iskaza, najava, vlastito iskustvo, nepoznat kapacitet i iskaz na kraju dugoga teksta.'),
      ('Dodatni kontrasti',f'Četiri odvojena kontrasta razlikuju najavu od dostupne izjave. Zadovoljeno je {n(sum(x["passed"] for x in probe["checks"]))} od četiri provjere. Ni taj broj nije empirijska točnost.'),
      ('Što je konkretno pošlo pogrešno',escape(failed_names[:600])+' Potpuni popis i izvorni odgovori nalaze se u diagnostic_review.json, report_policy.json i coding.sqlite.')])

    task_hr={'topics':'teme','mentions':'spomeni','speakers':'govornici','groups':'skupine'}
    def rates(name):return ', '.join(task_hr[k]+' '+p(100*v) for k,v in quality['sets'][name]['task_validity_rates'].items())
    r.new('Razvoj / neovisni skupovi članaka','Svježi strojni izazov ne daje referentnu istinu',
          'Isti instalirani lokalni model korišten je s osnovnim i promijenjenim postavkama. Neslaganja su sačuvana.')
    r.textblocks([('Razvojnih 100 članaka','Strukturna valjanost po zadatku: '+rates('development')+'. Dugim i kratkim tekstovima namjerno je dano mjesto u razvoju.'),
      ('Svježih 30 članaka','Osnovna konfiguracija: '+rates('challenge')+'. Promijenjena konfiguracija: '+rates('challenge_challenge')+'. To je 30 članaka, a ne 60 neovisnih opažanja.'),
      ('Pravilo izvještavanja','Cilj od najmanje 95 % strukturno valjanih zadataka nije prag točnosti. Neuspjele primarne provjere aktiviraju povlačenje sadržajnih brojki; postupak ipak završava čitanje svih članaka i zapisuje ishod.')])

    comp=challenge['comparisons'];long=quality['sets']['development']
    r.new('Provjere / dugi tekstovi i neslaganja','Dva slična rezultata još nisu potvrđena istina',
          'Puna pokrivenost teksta provjerava se programom. Sadržajna neslaganja prikazuju se kao ograničenje, bez prosječenja oznaka.')
    longrates=long.get('segmented_task_validity_rates',{})
    longtext=(f'Razvoj sadrži {n(long["segmented_articles"])} višesegmentnih članaka. Najmanja strukturna valjanost među zadacima iznosi {p(100*min(longrates.values()))}.' if longrates else 'U razvojnom skupu nema višesegmentnih zapisa.')
    r.textblocks([('Dugi tekstovi',longtext+' Izvor se ne skraćuje na početak ili ključne riječi. Identitet i izjava mogu biti povezani odvojenim odlomcima.'),
      ('Neslaganja među provjerama',f'Među {n(len(comp))} uspoređenih članaka dvije konfiguracije različito su označile relevantnost u {n(sum(x["relevance_disagreement"] for x in comp))}, skup uloga u {n(sum(x["role_disagreement"] for x in comp))}, a potpunost izvora u {n(sum(x["source_completeness_disagreement"] for x in comp))} slučajeva. Unutar osnovne konfiguracije prvi i kontrolni prolaz razlikovali su se u relevantnosti barem jednog segmenta u {n(quality["sets"]["challenge"]["topic_disagreements"])} od {n(len(comp))} članaka.'),
      ('Što je sačuvano','Osnovni i alternativni rezultat ostaju dostupni. Ni jedan se ne proglašava istinitim zbog slaganja ili zadržavanja osnovne konfiguracije. Izvori: development_review.json i challenge_disagreements.json.')])

    r.new('Mjere / što bi značio sadržajni rezultat','Tri nazivnika odgovaraju na tri različita pitanja',
          'Definicije ostaju dio reproducibilne metode i kada brojčani rezultati nisu prihvatljivi za objavu.')
    r.textblocks([('Udio pojavljivanja aktera u ulozi','Tri različita govornika iste uloge u jednom članku daju tri pojavljivanja. Nazivnik je ukupan broj parova akter-uloga unutar članaka. To nije broj jedinstvenih osoba u cijelom arhivu.'),
      ('Udio prisutnosti uloga','Ista tri govornika daju jednu prisutnost te uloge u članku. Nazivnik je zbroj svih parova članak-uloga.'),
      ('Prevalencija u člancima','Članak s tom ulogom broji se jednom. Nazivnik uključuje potpune članke s valjanim rezultatom i razriješenim pripisivanjem iskaza, uključujući uspješno utvrđene članke bez govornika. Povučene procjene nisu zamijenjene nulama.')])

    r.new('Pojam / tko je ovdje teolog','Akademska uloga mora biti uspostavljena tekstom',
          'Metoda ispituje kako članak predstavlja govornika. Ne provjerava njegove stvarne diplome, mandate ili životopis.')
    r.textblocks([('Operativni uvjet','Oznaka akademskog teologa traži navod teologa, profesorice teologije ili odgovarajuće teološke pripadnosti i govor u toj ulozi. Sam naziv svećenik, biskup ili profesor nije dovoljan.'),
      ('Uloga i funkcija iskaza','Pastoralna služba, akademska uloga, tumačenje vjere i vlastito iskustvo odvojena su pitanja. Osoba bez poznate profesije može iznijeti stvaran pripisani iskaz; nepoznat kapacitet ostaje nerazriješen.'),
      ('Odgovor čitatelju','Ovo izdanje ne utvrđuje tko dominira medijskim tumačenjem vjere. Donosi granice građe, cjelovitu obradu uzorka i dokaz zašto bi takvu brojčanu tvrdnju zasad trebalo povući.')])

    r.new('Reproducibilnost / isporuka','Svaki korak ostaje provjerljiv',
          'Izvorni arhiv i prethodno izdanje nisu prepisani. Članci i njihovi odgovori ostaju lokalni; ništa se ne objavljuje izvana.')
    r.textblocks([('Ulaz i odabir','assignment.json, source_audit.json, freeze.json i main_manifest.csv određuju obuhvat, otiske datoteka, odabir i pondere. Novi izazov spremljen je u challenge_v32 datotekama; ne preklapa se s glavnim, razvojnim ni ranijim izazovnim uzorkom.'),
      ('Postavke lokalnog modela',f'Qwen3 14B, Q4_K_M; koder {escape(coding["version"])}; Ollama {escape(runtime_record["environment"]["runtime"]["version"])}. Think={str(coding["think"]).lower()}, kontekst {n(options["num_ctx"])} tokena, najviše {n(options["num_predict"])} izlaznih tokena. Osnovno: temperatura {options["temperature"]}, seed {options["seed"]}; alternativno: 0,2 i 20261019. Puni otisci modela, koda i ulaza nalaze se u configs.'),
      ('Model i dokaz','CODEBOOK.md i configs spremaju verzije pravila, postavki i izvornog koda. coding.sqlite čuva sve zahtjeve, odgovore, ponavljanja i dokaze. report_policy.json navodi razloge povlačenja, a claims.json status svake tvrdnje.'),
      ('Ponovna izgradnja','Programi analyse.py i build_report.py ponovno izrađuju tablice i ovaj PDF iz spremljenih odgovora. Ne traže novo zaključivanje. Mehanička provjera izgleda i pregled svih prikazanih stranica zasebni su koraci.')])
    r.finish();render_final(pdf)
