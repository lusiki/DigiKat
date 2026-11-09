"""Croatian analytical report; all numeric findings read from aggregate tables."""
from pathlib import Path
import csv,json,re,hashlib
from xml.sax.saxutils import escape
from reportlab.pdfgen import canvas
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph,Table,TableStyle,Spacer
from svglib.svglib import svg2rlg

ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'output/demokrscanstvo-analysis/v1';FIG=OUT/'figures'
PDF=ROOT/'output/pdf/demokrscanstvo-analiticki-izvjestaj.pdf'
QA=ROOT/'tmp/pdfs/demokrscanstvo-report';QA.mkdir(parents=True,exist_ok=True)
W,H=A4;M=45;CW=W-2*M
INK=colors.HexColor('#173e43');TEXT=colors.HexColor('#253b3e');MUTED=colors.HexColor('#526b6f')
COPPER=colors.HexColor('#a9643b');PAPER=colors.HexColor('#fcfbf7');PALE=colors.HexColor('#eef2ef');LINE=colors.HexColor('#cdd9d4');GOLD=colors.HexColor('#e2b58a')
for name,file in [('Body','calibri.ttf'),('BodyBold','calibrib.ttf'),('BodyItalic','calibrii.ttf'),('Display','georgia.ttf')]:pdfmetrics.registerFont(TTFont(name,'C:/Windows/Fonts/'+file))
pdfmetrics.registerFontFamily('Body',normal='Body',bold='BodyBold',italic='BodyItalic',boldItalic='BodyBold')
ST={
 'body':ParagraphStyle('body',fontName='Body',fontSize=11.2,leading=14.7,textColor=TEXT,spaceAfter=10),
 'small':ParagraphStyle('small',fontName='Body',fontSize=9.6,leading=12.4,textColor=MUTED,spaceAfter=8),
 'h1':ParagraphStyle('h1',fontName='Display',fontSize=24,leading=28.5,textColor=INK,spaceAfter=15),
 'h2':ParagraphStyle('h2',fontName='BodyBold',fontSize=13,leading=16.3,textColor=INK,spaceBefore=8,spaceAfter=7),
 'cell':ParagraphStyle('cell',fontName='Body',fontSize=10.5,leading=13,textColor=TEXT),
 'head':ParagraphStyle('head',fontName='BodyBold',fontSize=10.1,leading=12.3,textColor=colors.white),
}
def read(name):return json.loads((OUT/(name+'.json')).read_text(encoding='utf-8'))
def rows(name):
    with (OUT/(name+'.csv')).open(encoding='utf-8-sig') as f:return list(csv.DictReader(f))
def n(x):return f'{int(x):,}'.replace(',','.')
def f(x,d=1):return f'{float(x):.{d}f}'.replace('.',',')
def pct(x,y):return f(100*float(x)/float(y))
S=read('summary');LS=read('lexical_summary');LONG=read('long_text_summary');CS=read('content_review_summary');HS=read('human_validation_status')
TOP=rows('topic_sensitivity');PS=rows('platforms');MS=rows('model_stability');NS=rows('near_copy_summary');NEAR=rows('near_copy_sensitivity')
def t(scope,topic):return next(r for r in TOP if r['scope']==scope and r['topic']==topic)
def plat(p):return next(r for r in PS if r['platform']==p)
def lex(a,b,name='lexical_pairs'):return next(r for r in rows(name) if {r['a'],r['b']}=={a,b})
CLAIMS=[];PAGES=[]
def text(raw,style='body',source='',unit='',denominator='',control='',alternative=''):
    assert '\ufffd' not in raw
    # Editorial source is already Croatian; normalize dash variants for PDF portability.
    raw=re.sub('[\u2010-\u2014]','-',raw)
    if source:CLAIMS.append({'id':f'C{len(CLAIMS)+1:03d}','page':len(PAGES)+2,'claim':raw,'source':source,'unit':unit,'denominator':str(denominator),'control':control,'alternative':alternative})
    markup=escape(raw).replace('\n','<br/>');markup=re.sub(r'\*\*(.+?)\*\*',r'<b>\1</b>',markup)
    return Paragraph(markup,ST[style])
def h(raw):return text(raw,'h2')
def tab(data,widths):
    values=[[Paragraph(escape(str(c)).replace('\n','<br/>'),ST['head' if i==0 else 'cell']) for c in row] for i,row in enumerate(data)]
    obj=Table(values,colWidths=[CW*x for x in widths],hAlign='LEFT')
    rules=[('BACKGROUND',(0,0),(-1,0),INK),('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),8),('RIGHTPADDING',(0,0),(-1,-1),8),('TOPPADDING',(0,0),(-1,-1),7),('BOTTOMPADDING',(0,0),(-1,-1),7),('LINEBELOW',(0,-1),(-1,-1),.6,LINE)]
    for i in range(1,len(data)):
        if i%2:rules.append(('BACKGROUND',(0,i),(-1,i),PALE))
    obj.setStyle(TableStyle(rules));return obj
def chart(name,maxheight=370):
    d=svg2rlg(str(FIG/(name+'.svg')));scale=min(CW/d.width,maxheight/d.height);d.scale(scale,scale);d.width*=scale;d.height*=scale
    return d
def page(kicker,title,items):PAGES.append((kicker,[text(title,'h1')]+items))
def cap(raw,source,denominator='',unit=''):
    return text(raw,'small',source,unit,denominator,'Recomputed from aggregate tables','Archive selection and coding are not a random media sample')

# 02
four=sum(int(t('publications',k)['n']) for k in ('t01','t02','t03','t04'))
page('Ključni nalazi','Ime tradicije, sadržaj i odjek',[
 text('Demokršćanstvo u ovoj zbirci služi političkom smještanju, raspravi o vrijednostima i konkretnom obrazlaganju. Ta se značenja ne mogu svesti na broj spominjanja. Najpouzdaniji zaključak odnosi se na jezik odabranih zapisa, a ne na političku podršku ili sveukupnu društvenu važnost tradicije.'),
 h('1  Političko samoodređenje zauzima velik dio karte'),
 text(f'Četirima jezičnim temama koje opisuju pripadnost, domoljublje, HDZ-ov identitet i desni centar pripada {n(four)} od {n(S["records"])} zapisa ({pct(four,S["records"])}%). Najveća pojedinačna tema, "Politička pripadnost i ideje", obuhvaća {n(t("publications","t01")["n"])} zapisa. To su dodjele modela, a ne potvrđen udio objava koje iskazuju jednu političku funkciju.',source='topic_sensitivity.csv: publications, t01-t04',unit='archived records',denominator=S['records'],control='Exact / near-copy, A1 and web sensitivity',alternative='Topic boundaries are imperfect; identity language is favoured by retrieval'),
 h('2  Ponavljaju se formulacije, ne samo cijeli tekstovi'),
 text(f'Od {n(S["records"])} zapisa nastaje {n(S["exact_text_groups"])} skupina potpuno jednakog normaliziranog naslova i tijela, ali samo {n(S["distinct_contexts"])} različitih dokaznih konteksta. Ponavljanje citata zato je šire od ponavljanja identičnih zapisa. Glavne jezične teme opstaju u provjerama, uz promjene njihovih udjela.',source='summary.json; topic_sensitivity.csv; near_copy_sensitivity.csv',unit='records / exact texts / contexts',denominator='2306 / 2253 / 1731',control='Three near-copy thresholds',alternative='Different wording can report the same statement; no measure here counts independent stories'),
 h('3  Konkretna načela postoje, ali njihova učestalost nije potvrđena'),
 text('Pregledani primjeri povezuju solidarnost s radom i europskom suradnjom, supsidijarnost s razinama vlasti te savjest s političkom odlukom. Drugi primjeri samo nabrajaju vrijednosti ili kritiziraju nedosljednost aktera. Bez neovisnog kodiranja ne izvodimo postotak "stvarne primjene" niti tvrdnju da je ona u javnosti rijetka.',source='Private development review: 104,111,119,125,133,139; qualitative_review.md',unit='reviewed examples',denominator='purposive examples, no population estimate',control='Read named principle and linked proposition separately',alternative='A short qualifying context can omit a substantive argument'),
 cap('Status izdanja: proveden računalni i sadržajni pregled uz pomoć AI-ja. Neovisna ljudska validacija nije dovršena. Nalazi su opisni; ograničenja odabira vidljiva su od početka izvještaja.','content_review_summary.json; human_validation_status.json')
])
# 03
page('Podaci i pouzdanost','Što točno brojimo',[
 text(f'Polazni skup čini {n(S["records"])} automatski uključenih arhivskih zapisa od 1. siječnja 2021. do 10. rujna 2026. Izdanje potječe iz arhive s {n(S["eligible"])} pretraživih zapisa. Povezivanje identifikatora, klasifikacije, teksta i postojećih tema provjereno je jedan prema jedan.',source='summary.json; checks.csv',unit='records',denominator=S['eligible'],control='Manifest hashes and platform-month reconciliation'),
 tab([['Sloj','Broj','Značenje'],['Pretraživi arhivski zapisi',n(S['eligible']),'Nazivnik arhivske stope'],['Automatski uključeni',n(S['records']),'Zamrznuti skup ove analize'],['Eksplicitno pravilo A1',n(S['a1']),'Izričito demokršćansko nazivlje'],['Dodatno uključeni',n(S['records']-S['a1']),'Drugi kontekstualni putovi'],['Pohranjeno tijelo / isječak',n(S['stored_body'])+' / '+n(S['records']-S['stored_body']),'Polje teksta, bez jamstva cjelovitosti'],['Jednaki naslov i tijelo',n(S['exact_text_groups']),'Konzervativna kontrola kopija']],[.36,.19,.45]),Spacer(1,12),
 h('Kontrolni zbroj čuva datoteku; čitanje provjerava smisao'),
 text('Provjera sadržaja otkrila je vezu iz preporučenog članka koja ulazi u odabir te izraz o personalističkom vodstvu stranke koji nije dokaz kršćanskog personalizma. Takvi slučajevi znače da se svaki automatski pogodak ne može proglasiti sadržajno potvrđenom objavom o demokršćanstvu.',source='content_review_summary.json; private content_flags.json',unit='inspected cases',control='Full text inspected for the four flagged examples',alternative='Flags are not an estimate of total error'),
 text(f'Kontrolno izostavljanje {n(CS["flagged_context_counterparts"])} zapisa povezanih s pregledanim rizičnim kontekstima ostavlja {n(CS["remaining_for_sensitivity"])} zapisa. Time se provjerava utjecaj poznatih problema, ali ne čisti cijela zbirka. Glavni rezultati zadržavaju izvorni skup radi usporedivosti.',source='content_review_summary.json; flagged_case_sensitivity.csv',unit='records',denominator=S['records'],control='Exact-context counterpart exclusion',alternative='Other false positives and missed records remain unmeasured')
])
# 04
page('Vidljivost kroz vrijeme','Vrhovi pažnje unutar promjenjive arhive',[
 text('Broj zapisa govori koliko je materijala zabilježeno. Stopa uzima u obzir obujam iste arhive, ali ne uklanja promjene njezina sastava. Linije su zato prekinute na promjeni prikupljanja.'),
 chart('01-timeline',320),
 cap('Slika 1. Mjesečni broj automatskih pogodaka i stopa na 10.000 pretraživih zapisa. Nazivnik se mijenja po mjesecu. Isprekidana crta označuje 1. travnja 2024.; posljednji mjesec završava 10. rujna 2026.','timeline.csv','monthly eligible records','records / rate'),
 text(f'Ukupna stopa cijele zbirke iznosi {f(S["pooled_per_10000"],3)} na 10.000 zapisa. To je gustoća u prikupljenom materijalu, ne udio medijske publike. Visoki mjesečni vrhovi mogu nastati prenošenjem malog broja izjava.',source='summary.json; timeline.csv',unit='records per 10000 eligible records',denominator=S['eligible'],control='Ratio of sums, not mean of monthly rates'),
 text('Od travnja 2024. mijenja se arhiva, uključujući ulazni filtar samostalne riječi "i". Sirov pad ili rast preko te granice zato nema jednoznačno društveno tumačenje. Godina 2026. nije potpuna; usporedba godišnjih zbrojeva s cijelom 2025. nije opravdana.',source='Base MULTIPLATFORM.md; summary.json',unit='collection policy',control='Break shown in every timeline')
])
# 05
episodes=[r for r in rows('episode_selection') if r['selected']=='True']
page('Tri vremenska portreta','Iza vrha nije nužno jedan razgovor',[
 text('Odabrana su tri najbrojnija međusobno nesusjedna mjeseca. U svakom je pregledan sadržaj vodećih ponovljenih konteksta. Mjesec je jedinica portreta: broj ispod naslova obuhvaća cijeli mjesec, ne samo opisanu izjavu.'),
 *[item for r,title,body in zip(episodes,['Svibanj 2021. | izbori i vjerodostojnost identiteta','Lipanj 2022. | stranačko određenje i spor oko vrijednosti','Lipanj 2024. | izbori za Europu i jezik solidarnosti'],[
  'U pregledanim tekstovima isprepliću se izborno pozicioniranje, pozivanje na temeljne vrijednosti i osporavanje vjerodostojnosti demokršćanskog identiteta. Najbrojnija primarna tema mjeseca povezana je s izborima i konzervativnom scenom. Nisu svi zapisi odjek iste izjave.',
  'Tekstovi prenose opise stranačkog vodstva, nabrajanje vrijednosti i raspravu o političkoj otvorenosti. Drugi tekstovi osporavaju odnos stranačkog programa i obitelji. Isti mjesec zato uključuje afirmaciju i kritiku, koje broj spominjanja ne razdvaja.',
  'Europska kampanja povezuje nacionalne interese, demokršćanske vrijednosti i mjesto Hrvatske u Europi. U jednom pregledanom argumentu solidarnost se povezuje s razvojem članice Unije. To je sadržaj izjave, a ne dokaz ekonomskog učinka tradicije.'
 ]) for item in [h(title),text(f'{n(r["publications"])} zapisa; {n(r["groups_with_presence"])} točnih tekstova; {n(r["distinct_contexts"])} različita konteksta; stopa {f(r["per_10000"],2)} na 10.000.',source='episode_selection.csv: '+r['month'],unit='records / exact groups / contexts / rate',denominator=r['eligible'],control='Compare count peak with rate; inspect examples'),text(body,source='Private episode_review.json: '+r['month']+'; topic_profiles.csv',unit='reviewed contextual examples',control='Six leading exact contexts examined per month',alternative='No causal claim and no whole-month event attribution')]],
 cap('Prva dva portreta pripadaju starom, a treći novom režimu prikupljanja. Njihove stope nisu izravna usporedba javne relevantnosti. Arhivski datum ne dokazuje vrijeme izvorne objave ni smjer širenja.','episode_selection.csv; MULTIPLATFORM.md')
])
# 06
page('Tematska karta','Politički položaj ostaje u središtu karte',[
 text('Primarna tema opisuje najizraženiji jezični sklop u izdvojenom dokaznom kontekstu. Svaki zapis pripada jednoj temi, iako može sadržavati više problema i argumenata.'),
 chart('02-topics',403),
 cap('Slika 2. Udjeli po objavama i jednom predstavniku potpuno jednakog naslova i tijela. Brojevi uz tamne stupce jesu brojevi objava. Nazivnici: 2.306 objava i 2.253 tekstualne skupine; uključena je jedna nerazvrstana objava.','topic_sensitivity.csv: publications and exact_text_groups','2306 / 2253','records / exact text groups'),
 text('Kontrola identičnih tekstova zadržava najveću temu na prvom mjestu. Međutim, bliske teme dijele rječnik, a njihovi rubni primjeri prelaze sadržajne granice naslova. Kartu zato valja čitati kao orijentaciju kroz jezik zbirke, ne kao iscrpan popis značenja demokršćanstva.',source='topic_sensitivity.csv; topic_content_review.csv',unit='fixed-model topic assignments',control='Ten typical/boundary contexts per topic')
])
# 07
page('Ponavljanje','Kopija teksta i odjek citata dvije su stvari',[
 text(f'Potpuna tekstualna jednakost uklanja {n(S["extra_exact_copies"])} dodatnih kopija ({pct(S["extra_exact_copies"],S["records"])}% zapisa). Ponavljani dokazni konteksti brojniji su. Već promjena interpunkcije, naslova ili dodatnog odlomka može stvoriti drugi tekst, iako sadrži isti politički citat.',source='summary.json',unit='extra exact copies',denominator=S['records'],control='Exact context and near-copy comparisons'),
 chart('03-repetition',270),
 cap('Slika 3. Odabrane teme po trima jedinicama. Kratka smeđa crta ispod točaka pokazuje raspon udjela kroz tri istraživačka praga gotovo jednakih tekstova. Svaka serija ima vlastiti nazivnik.','topic_sensitivity.csv; near_copy_sensitivity.csv','2306 / 2253 / 1731; near-copy denominators 1793,1944,2123','records / texts / contexts'),
 text(f'Tema "Domoljublje i državotvornost" prelazi s {f(t("publications","t02")["percent"])}% objava na {f(t("exact_text_groups","t02")["percent"])}% točnih tekstova i {f(t("distinct_contexts","t02")["percent"])}% različitih konteksta. To upućuje na doprinos ponavljanih formulacija njezinoj vidljivosti, uz očuvanu prisutnost u različitim tekstovima.',source='topic_sensitivity.csv: t02',unit='topic shares',denominator='2306 / 2253 / 1731',control='Near-copy range; typical texts read',alternative='Contexts with differing punctuation can still convey the same statement'),
 text(f'Istraživačko grupiranje gotovo jednakih tekstova daje od {n(min(int(r["groups"]) for r in NS))} do {n(max(int(r["groups"]) for r in NS))} skupina. Taj raspon nije interval pouzdanosti niti broj samostalnih priča. Nije potvrđena jedinstvena granica koja bi opravdala zamjenu glavnog nazivnika.',source='near_copy_summary.csv',unit='algorithmic groups',control='Jaccard 0.85 / 0.90 / 0.95; complete pairwise similarity rule')
])
# 08
page('Teme kroz godine','Sastav se mijenja, granice tumačenja ostaju',[
 text('Svaki stupac prikazuje sastav uključenih zapisa te godine. Boja označuje postotak unutar godine, a broj ispod postotka apsolutni broj dodjela. To nisu stope u cjelokupnoj arhivi.'),
 chart('04-topic-time',365),
 cap('Slika 4. Deset primarnih tema; jedna nerazvrstana objava nije prikazana u retcima, ali ostaje u nazivniku svoje godine. † Godina 2024. sadrži oba režima prikupljanja. * Godina 2026. završava 10. rujna.','topic_profiles.csv: year','year-specific included records','topic assignments'),
 text('Promjene se mogu čitati kao razlike u zabilježenoj raspravi: pojedine godine ističu se kampanjskim ili vrijednosnim jezikom. Ne proizlazi da su građani promijenili ideološke stavove. Ponavljani citati, promjene platformi i duljina teksta ostaju moguća objašnjenja.',source='topic_profiles.csv; topic_content_review.csv',unit='descriptive topic mix',control='Exact text, web-only and model-start sensitivity',alternative='Changing archive and episode composition')
])
# 09
page('Učinak pravila odabira','Dodatni putovi proširuju idejni sadržaj',[
 text(f'Izričito nazivlje A1 obuhvaća {n(S["a1"])} zapisa, odnosno {pct(S["a1"],S["records"])}% skupa. Preostalih {n(S["records"]-S["a1"])} ulazi drugim pravilima. Ta mala skupina sadržajno se razlikuje od većine i zato je ne treba sakriti u ukupnom postotku.',source='summary.json',unit='records',denominator=S['records'],control='A1-only and additional-route tables'),
 chart('05-selection',237),
 cap('Slika 5. Primarna tema "Idejna tradicija i javne rasprave" u cijeloj zbirci, užem A1 skupu i dodatno uključenim zapisima. Isti model primjenjuje se u svim trima skupinama.','topic_sensitivity.csv: t08','2306 / 2211 / 95','records'),
 text(f'Temi pripada {n(t("additional_routes","t08")["n"])} od {n(t("additional_routes","t08")["denominator"])} dodatnih zapisa ({f(t("additional_routes","t08")["percent"])}%). U samom A1 skupu njezin je udio {f(t("a1","t08")["percent"])}%. Razlika potvrđuje da izbor ulaznog pravila oblikuje ono što vidimo kao temu zbirke.',source='topic_sensitivity.csv: t08',unit='topic assignments',denominator='95 / 2211',control='Same fixed model and manually read non-A1 examples',alternative='Additional routes include false or uncertain anchors'),
 text('Dodatni putovi uključuju socijalni nauk Crkve i argumentacijske obrasce, pa mogu otvoriti prostor za socijalna pitanja koja ne imenuju demokršćanstvo. Isti širi zahvat nosi rizik pogrešnog sidra. Ova usporedba ne dokazuje veću kvalitetu ili "autentičnost" jedne skupine.',source='MULTIPLATFORM.md; content_review_summary.json',unit='interpretation of selection rules',control='Inspected false-anchor case')
])
# 10
page('Platforme i pokrivenost','Web prevladava; male platforme traže skromniji opis',[
 text(f'Web čini {n(plat("web")["n"])} zapisa ({f(plat("web")["percent"])}% cjeline). Ostale platforme pružaju važne primjere, ali broj objava u zajedničkom razdoblju često ne dopušta razrađeno rangiranje udjela.',source='platforms.csv',unit='records',denominator=S['records'],control='Full-period vs 2025 comparison'),
 tab([['Platforma','Cijelo razdoblje','2025.','Dani s podacima u 2025.']]+[[r['label'],n(r['n']),n(r['n_2025']),n(r['days_2025'])] for r in PS],[.30,.23,.16,.31]),Spacer(1,10),
 cap('Tablica 1. Broj uključenih zapisa te broj dana s bilo kojim arhivskim podatkom na platformi. Dani ne dokazuju potpuno praćenje. Platforme počinju u različito vrijeme.','platforms.csv','platform-specific archived coverage','records and observed days'),
 text(f'Komentari u 2025. imaju samo {n(plat("comment")["eligible_2025"])} pretraživih zapisa, raspoređenih na {n(plat("comment")["days_2025"])} dana. Nula pogodaka zato ne znači odsutnost rasprave. X i Facebook imaju {n(plat("twitter")["n_2025"])} odnosno {n(plat("facebook")["n_2025"])} pogodaka: za ovu godinu prikladniji su brojevi i primjeri.',source='platforms.csv: comment, twitter, facebook',unit='records and observed days',denominator='2025 platform archives',control='Coverage before interpretation')
])
# 11
page('Opis platformi','Različit sastav zbirke, bez rangiranja publika',[
 text('Ovaj pregled koristi cijelo raspoloživo razdoblje pojedine platforme. Namijenjen je opisu zbirke, a ne usporedbi platformi pod jednakim uvjetima. Prikazane su samo platforme s najmanje 50 uključenih zapisa.'),
 chart('06-platform-topics',365),
 cap('Slika 6. Tematski sastav pet većih skupina. U ćeliji su udio i broj zapisa; n ispod platforme jest nazivnik. Razdoblja, izvori i obuhvat razlikuju se, osobito za tisak i komentare.','topic_profiles.csv: platform; platforms.csv','platform-specific included records','primary topic assignments'),
 text('Naglašena ćelija može potjecati od formata komunikacije, ponavljanih izjava ili sastava izvora. Iz nje ne proizlazi da platforma ili njezina publika više podupire neku ideju. Za usklađenu usporedbu 2025. većina društvenih platformi nema dovoljan broj uključenih zapisa.',source='platforms.csv; topic_profiles.csv',unit='descriptive platform composition',control='2025 feasibility; no significance tests',alternative='Text length, coverage and repetition')
])
# 12
page('Jezična susjedstva','Blizina riječi nije suglasnost s idejom',[
 text(f'U {n(LS["sentence_units"])} rečeničnih jedinica iz {n(LS["exact_text_representatives"])} točnih tekstova izmjerena su supojavljivanja odabranih riječi i fraza. NPMI uspoređuje zajedničku prisutnost s očekivanjem prema zasebnim učestalostima. Čitanje primjera određuje što ta blizina znači.',source='lexical_summary.json; lexical_pairs.csv',unit='sentence instances',denominator=LS['sentence_units'],control='Token offsets and original field boundaries'),
 chart('07-lexical',257),
 cap('Slika 7. Pet pregledanih parova. Uz NPMI je broj različitih točnih tekstova s parom. Skup rečenica uključuje i rečenice bez ijednog pojma; tekst se broji jednom za potporu para.','lexical_pairs.csv','7467 sentence instances / 2253 exact texts','lexical pairs'),
 text('Domoljublje, narodnjaštvo i državotvornost često su dio iste formule političkog određenja. Pregled sadrži i kritike aktera koji se navodno ne drže tih vrijednosti. Veza demokršćanstva i konzervativizma također uključuje razlikovanje i osporavanje: supojavljivanje nije dokaz da su pojmovi istoznačni.',source='Private pair_review.json; qualitative_review.md',unit='49 reviewed supporting examples',control='Read negations and oppositions',alternative='Shared quotations can produce strong lexical edges'),
 text(f'Par Europa-solidarnost podupire {n(lex("europa","solidarnost")["groups"])} tekstova; nakon uklanjanja svih tekstova s njegovom najraširenijom jednakom rečenicom ostaje {n(lex("europa","solidarnost")["groups_after_removing_largest_shared_sentence_groups"])}. Par HDZ-savjest prelazi s {n(lex("hdz","savjest")["groups"])} na {n(lex("hdz","savjest")["groups_after_removing_largest_shared_sentence_groups"])}. Obje veze postoje i izvan te rečenice, uz osjetljivost na formulaciju i širi kontekst.',source='lexical_pairs.csv: europa-solidarnost, hdz-savjest',unit='exact text groups',control='Largest shared-sentence group removal',alternative='Other paraphrases of the same quotation can remain')
])
# 13
page('Načela u primjeni','Što pokazuje čitanje povezanog argumenta',[
 text('Ovi primjeri prikazuju značenje, ne prevalenciju. Provjereno je postoji li u dostupnom odlomku načelo i izričita veza s problemom ili prosudbom. Parafraze su nastale čitanjem AI asistenta; nisu potvrda dvaju neovisnih ljudskih kodera.'),
 tab([['Pojam i okolnost','Što odlomak omogućuje zaključiti'],
 ['Solidarnost i dostojanstvo rada\nSvibanj 2026.','Poziv na produktivnost i gospodarsko jačanje povezuje se s kršćanskim načelom solidarnosti i dostojanstvom radnika. Potvrđena je argumentacijska veza u izjavi, ne učinak vladine politike.'],
 ['Opće dobro i dostojanstvo osobe\nTravanj 2024.','Kritika stranačkog probitka i ideološke isključivosti poziva se na dostojanstvo osobe i opće dobro; nastavlja se zahtjevom za slobodom izražavanja i zapošljavanjem prema sposobnosti.'],
 ['Supsidijarnost i razine vlasti\nVeljača 2021.','Razgovor načelo izričito povezuje s regionalnom i lokalnom samoupravom te europskim institucijama. Prenosi tumačenje tradicije; izvještaj ne ocjenjuje doktrinarnu potpunost tog tumačenja.'],
 ['Savjest i politička odluka\nTravanj 2022.','Demokršćanske vrijednosti navedene su kao obrazloženje protivljenja zabrani priziva savjesti. To je politička primjena vrijednosti, bez zaključka o opravdanosti odluke.']],[.33,.67]),Spacer(1,12),
 cap('Tablica 2. Pregledane parafraze iz privatnog razvojnog skupa: četiri različita argumentacijska slučaja. Izvorni tekst i identifikatori ostaju privatni.','Private development_review.json: 104,111,125,139; qualitative_review.md','purposefully selected examples','linked argument'),
 text('Nabrajanje solidarnosti među vrijednostima nije isti nalaz kao primjena načela. Isto tako, riječ "dostojanstvo" uz nacionalnu ili profesionalnu skupinu nije sama po sebi dovoljna za kod ljudskog dostojanstva. Nejasni slučajevi ostaju neodređeni; ne pretvaraju se u dokaz odsutnosti načela.')
])
# 14
page('Funkcija i glasovi','Kritika aktera ne znači odbacivanje tradicije',[
 h('Poštovanje načela uz odbijanje pripadnosti'),
 text('U pregledanoj izjavi politički akter istodobno izražava poštovanje prema demokršćanskim načelima i odbija vlastito svrstavanje u taj politički spektar. Automatsko brojanje bliskih pojmova vidjelo bi snažnu povezanost; čitanje pokazuje razliku između poštovanja ideje i pripadnosti.',source='Private development_review.json: 1,3,4',unit='qualitative case',control='Negation and target distinguished'),
 h('Demokršćanski svjetonazor uz kritiku HDZ-a'),
 text('Jedan sudionik rasprave vlastiti svjetonazor određuje kao demokršćanski, a istodobno snažno odbacuje HDZ. Pozitivan odnos prema tradiciji i negativan odnos prema stranci ovdje stoje u istom iskazu. Zato ne objavljujemo jedinstvenu automatsku ocjenu "pozitivnog" ili "negativnog" demokršćanstva.',source='Private development_review.json: 133',unit='qualitative case',control='Actor target separate from tradition',alternative='Single purposive example, no population frequency'),
 h('Objašnjenje tradicije uz politički argument'),
 text('U duljem razgovoru demokršćanstvo se razlikuje od liberalnog konzervativizma preko zajednice, solidarnosti i odnosa prema političkim razinama. Taj primjer pokazuje da česta identitetska uporaba ne iscrpljuje sadržaj skupa. Ne može se, međutim, upotrijebiti za mjerenje koliko je takvih objašnjenja u cijeloj zbirci.',source='Private development_review.json: 125',unit='qualitative case',control='Read definitions, contrasts and application separately'),
 h('Zašto nema ljestvice govornika'),
 text('Izdavač teksta nije automatski nositelj prenesenog stava. Osoba spomenuta uz načelo nije nužno govornik, a jedna objava može sadržavati novinarski glas i više suprotstavljenih izjava. Ovaj izvještaj zato zadržava opisne uloge u pregledanim primjerima, bez postotaka govornika, rangiranja utjecaja ili pripisivanja stava platformi.'),
 cap('Ovdje su namjerno odabrani kontrastni slučajevi. Oni dokazuju da različite funkcije postoje u materijalu, ne koliko su raširene.','qualitative_review.md; content_review_summary.json')
])
# 15
diff=max(abs(float(t('publications',r['topic'])['percent'])-float(r['percent'])) for r in rows('flagged_case_sensitivity'))
maxfull=max(abs(float(t('publications',k)['percent'])-float(t('stored_body',k)['percent'])) for k in [r['topic'] for r in TOP if r['scope']=='publications'])
page('Robusnost zaključka','Koje provjere mijenjaju priču',[
 tab([['Provjera','Rezultat','Posljedica za tumačenje'],
 ['Jednaki tekstovi',f'{n(S["records"])} → {n(S["exact_text_groups"])} jedinica','Glavna karta opstaje; pojedine formule gube udio.'],
 ['Gotovo jednaki tekstovi',f'{n(min(int(r["groups"]) for r in NS))} do {n(max(int(r["groups"]) for r in NS))} skupina','Raspon ovisi o pragu; ostaje dopunska kontrola.'],
 ['Samo pohranjeno tijelo',f'Najveća promjena udjela {f(maxfull,2)} postotnih bodova','Isječci ne određuju glavnu tematsku sliku.'],
 ['Poznati rizični konteksti',f'Izostavljeno {n(CS["flagged_context_counterparts"])} zapisa; najviše {f(diff,2)} boda promjene','Malen poznati učinak ne dokazuje da drugih pogrešaka nema.'],
 ['Drugi početci NMF-a',f'ARI {f(min(float(r["ari"]) for r in MS if "k=10" in r["comparison"]),2)} do {f(max(float(r["ari"]) for r in MS if "k=10" in r["comparison"]),2)}','Granice tema umjereno su stabilne; ne prikazivati ih kao istinite klase.'],
 ['Dulji tekst, isti model',f'{n(LONG["same"])} / {n(LONG["n"])} istih dodjela','Kontekst i cijeli pohranjeni tekst nisu ista analitička jedinica.'],
 ['Neovisno kodiranje','Nije dovršeno','Nema potvrđenih automatskih udjela načela, primjena ili glasova.']],[.28,.28,.44]),Spacer(1,13),
 cap('Tablica 3. Sve promjene udjela odnose se na isti zamrznuti tematski model. ARI je prilagođeno slaganje particija, ne točnost. Razvojni podskup duljeg teksta namjerno je odabran.','topic_sensitivity.csv; flagged_case_sensitivity.csv; near_copy_summary.csv; model_stability.csv; long_text_summary.json','scope-specific denominators','topic share changes and assignment agreement'),
 text('Najčvršća sinteza jest da političko određenje i ponavljane vrijednosne formule čine važan dio zabilježenog jezika, dok pregledani primjeri potvrđuju i konkretno obrazlaganje. Podaci ne određuju koliko je demokršćanstvo društveno utjecajno niti dopuštaju jedinstveni indeks njegove relevantnosti.',source='All sensitivity tables; qualitative_review.md',unit='synthesis',control='Explicit scope and counterexamples',alternative='Selection, repetition, text length and coding errors')
])
# 16
page('Metode | jedinice i stope','Od zapisa do usporedivog izračuna',[
 h('Zamrznuti ulaz i spajanje'),
 text(f'Provjereni su SHA256 kontrolni zbrojevi obaju javnih izdanja te povezano svih {n(S["records"])} odabranih ključeva s privatnim međurezultatima. Izvorna baza nije ponovno pretraživana i kriterij uključivanja nije izmijenjen. Ponovljeni arhivski zapis može predstavljati isti članak, prijenos ili drugi kontekst.',source='checks.csv; summary.json; prepare.R',unit='records',denominator=S['records'],control='1:1 join and per-platform/month equality'),
 h('Četiri jedinice koje ne treba zamijeniti'),
 tab([['Jedinica','Operativno pravilo'],['Objava / zapis','Svaki uključeni arhivski ključ jednom. Nije jedinstvena osoba ni jedinstvena priča.'],['Točan tekst','NFC, mala slova i ujednačeni razmaci u naslovu i tijelu nakon uklanjanja ponovljenog naslova. Interpunkcija ostaje.'],['Dokazni kontekst','Postojeći spoj odvojenih dokaznih prozora. Koristi se samo za postojeće teme i kontrolu jezičnog ponavljanja.'],['Rečenica','Izvorna granica polja i položaji; puni rečenični raspon koji dodiruje dokazni prozor, zatim UDPipe podjela.']],[.26,.74]),Spacer(1,10),
 h('Stope i pokrivenost'),
 text('Stopa razdoblja = 10.000 × zbroj uključenih / zbroj pretraživih zapisa iste platforme i razdoblja. Mjesečne stope ne prosječe se bez težina. Nema intervala koji bi sugerirali slučajan uzorak svih medija. Dani s podacima označuju zabilježenu aktivnost arhive; ne dokazuju potpunost.'),
 text('Skupina teksta može se pojaviti na više platformi ili u više mjeseci. Brojevi skupina po platformama i mjesecima zato se ne zbrajaju u globalni broj. Predstavnik skupine bira se prema raspoloživom tijelu i njegovoj duljini, zatim stabilnom identifikatoru, bez biranja povoljnog nalaza.')
])
# 17
page('Metode | teme i ponavljanje','Provjera modela bez traženja poželjnog rješenja',[
 text(f'Referentni TF-IDF/NMF model ponovno je uklopljen na {n(S["distinct_contexts"])} različitih konteksta uz {n(S["model_features"])} značajke. Najmanja frekvencija jest pet konteksta, najveća 85%; koriste se sublinearni TF i L2 normalizacija. Lematizirane su imenice, pridjevi i vlastita imena. Sve dodjele iz izvornog izdanja reproducirane su točno.',source='summary.json; checks.csv; thematic summary.json',unit='contexts / features / record assignments',denominator=S['records'],control='Input signature, original assignment equality'),
 tab([['Model / kontrola','ARI prema referentnom','Iteracije']]+[[r['comparison'].replace('seed=20260919; init=nndsvda','referentni početak').replace('; init=random',''),f(r['ari'],3),n(r['iterations'])] for r in MS],[.54,.27,.19]),Spacer(1,10),
 cap('Tablica 4. ARI se računa na 1.730 konteksta s barem jednom zadržanom značajkom. Usporedbe s različitim brojem tema nisu ocjena točnosti niti kriterij odabira pobjedničkog modela.','model_stability.csv','1730 nonzero contexts','topic partition agreement'),
 text(f'Na {n(LONG["n"])} razvojnih tekstova cijeli pohranjeni sadržaj projiciran je u isti rječnik, IDF i komponente modela. Dodjela ostaje ista u {n(LONG["same"])} slučaja ({pct(LONG["same"],LONG["n"])}%), a mijenja se u {n(LONG["n"]-LONG["same"])}. To je ciljana provjera osjetljivosti, bez procjene udjela promjene u cijeloj zbirci.',source='long_text_summary.json; long_text_sensitivity.csv',unit='development texts',denominator=LONG['n'],control='Same model; no full-text refit',alternative='Purposive sample enriched for boundary cases'),
 h('Gotovo jednaki tekstovi: dopunski, ne glavni nazivnik'),
 text('Uspoređeni su skupovi nizova od pet riječi. Za tekstove od barem 80 riječi i omjer duljina od najmanje 0,80 ispitani su Jaccardovi pragovi 0,85, 0,90 i 0,95. Svaki par unutar skupine mora prijeći prag, čime se sprječava ulančavanje. Pregledano je 15 parova oko pragova na razini naslova i dokaznih konteksta; ne tvrdi se da je utvrđena točnost grupiranja.',source='controls.py; near_copy_summary.csv; private near_copy_review.json',unit='algorithmic near-copy groups',control='All pairwise threshold condition; exploratory parameter range')
])
# 18
page('Metode | jezik i kodiranje','Što je provjereno, a što ostaje otvoreno',[
 text(f'Za jezične veze ponovno su anotirane izvorne rečenice lokalnim hrvatskim UDPipe modelom. Sačuvane su leme, vrste riječi, glagoli, negacija i položaji. Provjereno je {n(LS["tokens_offset_checked"])} tokena prema izvornim normaliziranim rasponima. Udaljeni odlomci i odvojena polja nisu spojeni u istu rečenicu.',source='lexical_summary.json; prepare.R; lexical.py',unit='token instances',control='Exact substring assertions'),
 h('Mjera veze i ograničenja segmentacije'),
 text('NPMI = log[p(a,b) / (p(a)p(b))] / -log[p(a,b)]. Marginalne i zajedničke učestalosti koriste isti skup rečeničnih jedinica. Vrijednost se računa samo kada je 0 < p(a,b) < 1. Ponavljane rečenice unutar predstavnika teksta ulaze jednom; potpora para broji različite točne tekstove.'),
 text('Dopunske tablice ispituju pragove potpore od 5, 10 i 20 tekstova, susjedne stvarne rečenice, potpuno različite rečenice, jednakost slijeda riječi bez interpunkcije te izostavljanje rečenica duljih od 120 riječi. Računalna granica rečenice može pogriješiti u lošem prijepisu ili nabrajanju; zato se veze ne tumače kao automatski potvrđeni argumenti.',source='lexical_thresholds.csv; lexical_adjacent_pairs.csv; lexical_distinct_sentence_pairs.csv; lexical_word_sequence_pairs.csv; lexical_short_sentence_pairs.csv',unit='lexical cooccurrences',control='Sentence unit and support sensitivity'),
 h('Proveden sadržajni pregled'),
 text(f'AI asistent pročitao je {n(CS["development_contexts_read"])} razvojnih konteksta: {n(CS["topic_typical"])} tipičnih, {n(CS["topic_boundary"])} graničnih i {n(CS["additional_diverse"])} dodatnih raznolikih slučajeva. Pročitani su i potporni primjeri za pet jezičnih parova te epizodni i rizični slučajevi. Uzorci su namjerni i ne daju ukupnu stopu pogreške.',source='content_review_summary.json; topic_content_review.csv; qualitative_review.md',unit='reviewed development contexts',denominator=CS['development_contexts_read'],control='Negative cases and full text for flagged selection risks'),
 h('Neovisna evaluacija nije izvršena'),
 text(f'Pripremljena su dva slijepa koderska paketa s istih {n(HS["pack_items"])} novih jedinica i zasebnom evidencijom uzorkovanja. Nema dovršenih ljudskih kodera, matrice pogrešaka, preciznosti, odziva ni kappe. Prema rezervnom postupku plana izostavljeni su automatski udjeli načela, matrica potvrđenih primjena i profili govornika.',source='human_validation_status.json',unit='prospective coding pack',denominator=HS['pack_items'],control='Previously read contexts and near-copy clusters excluded',alternative='Pack preparation is not validation')
])
# 19
topicids=[f't{i:02d}' for i in range(1,11)]+['unassigned']
page('Tehnički dodatak','Potpuna tematska tablica i revizijski trag',[
 tab([['Tema','Objave','Točni tekstovi','A1']]+[[('T'+k[1:] if k!='unassigned' else 'Ostalo')+' '+t('publications',k)['label'],n(t('publications',k)['n']),n(t('exact_text_groups',k)['n']),n(t('a1',k)['n'])] for k in topicids]+[['Ukupno',n(S['records']),n(S['exact_text_groups']),n(S['a1'])]],[.58,.14,.14,.14]),Spacer(1,12),
 cap('Tablica 5. Nazivnici stoje u zadnjem retku. Jedna primarna tema po jedinici; zasebni pojmovni kodovi ne zbrajaju se s ovim brojevima.','topic_sensitivity.csv','2306 / 2253 / 2211','primary topic counts'),
 h('Datoteke za ponavljanje i provjeru'),
 text('Paket agregata sadrži vremensku seriju, platforme, tematske profile, sve prikazane analize osjetljivosti, tablice jezičnih veza i registar tvrdnji. Manifest bilježi ulazna izdanja, kod i kontrolne zbrojeve izlaza. Izvorni tekst, identifikatori, dokazni rasponi i koderski paketi ostaju u privatnom radnom prostoru.'),
 text('Kod: studies/demokrscanstvo-barometar/report/.\nAgregati: output/demokrscanstvo-analysis/v1/.\nPostupak: prepare.R, analyze.py, long_text.R, lexical.py, controls.py, evaluation_pack.py, figures.py, render_report.py i verify.py. Točne naredbe i aktivne verzije zapisane su u README.md i manifestu.','small'),
 text('Ovaj PDF provjerava i tumači zamrznuto izdanje. Ne ispravlja izvornu klasifikaciju niti objavljuje izmjene barometra. Nalazi o pogrešnim sidrima i zaostalim preporukama članka trebaju ući u zasebnu reviziju selekcijskog postupka.')
])
# 20
references=[
 ('DigiKat. Analitički protokol 2.0, 19. 9. 2026.','Lokalni plan određuje jedinice, kontrole i rezervni postupak bez drugog čitatelja.',''),
 ('DigiKat. Multiplatform i thematic izdanje v1.','Zamrznuti agregati, privatni dokazni konteksti i postojeći NMF model. Metoda i SHA256 manifesti spremljeni su uz podatke.',''),
 ('scikit-learn. Topic extraction with NMF and LDA.','Službena dokumentacija TF-IDF/NMF postupka.','https://scikit-learn.org/stable/auto_examples/applications/plot_topics_extraction_with_nmf_lda.html'),
 ('Belford, Mac Namee i Greene (2017). Stability of Topic Modeling via Matrix Factorization.','Uporište za razlikovanje stabilnosti rješenja od valjanosti njegova sadržajnog tumačenja.','https://arxiv.org/abs/1702.07186'),
 ('Bouma (2009). Normalized (Pointwise) Mutual Information in Collocation Extraction.','Uporište mjere NPMI; izbor pragova i jedinica u ovom izvještaju projektna je odluka.','https://svn.spraakdata.gu.se/repos/gerlof/pub/www/Docs/npmi-pfd.pdf'),
 ('Papinsko vijeće Iustitia et Pax (2004). Kompendij socijalnog nauka Crkve.','Pojmovno uporište za socijalna načela, osobito odjeljke 160-163 i 189. Nije kriterij političke pravovjernosti zapisa.','https://www.vatican.va/roman_curia/pontifical_councils/justpeace/documents/rc_pc_justpeace_doc_20060526_compendio-dott-soc_en.html'),
 ("European People's Party (2012). Party Platform.",'Primjer političkog samorazumijevanja, odvojen od empirijske definicije analize.','https://www.epp.eu/files/uploads/2015/09/Platform2012_EN1.pdf')]
items=[]
for i,(title,note,url) in enumerate(references,1):
    items.append(text(f'{i}. {title}','h2'));items.append(text(note,'small'))
    if url:items.append(Paragraph(f'<link href="{escape(url)}" color="#a9643b"><u>Otvoriti izvornik</u></link>',ST['small']))
items.extend([h('Čitanje izvještaja nakon kontrole'),text('Brojevi su reproducirani i međusobno usklađeni. Tumačenje je namjerno uže od mogućih automatskih oznaka: vidljivost u arhivi, jezične teme, ponavljanje i pregledani argumenti. Neovisna ljudska evaluacija ostaje sljedeći korak za kvantificiranje novih sadržajnih kategorija.'),text('Izrađeno 19. rujna 2026. | DigiKat | Analiza i urednički pregled: Codex AI.\nLiteratura provjerena 19. rujna 2026. Empirijski brojevi potječu iz lokalnih podataka.','small')])
page('Izvori i status','Izvori koji podupiru postupak',items)

def cover(c):
    c.setFillColor(PAPER);c.rect(0,0,W,H,fill=1,stroke=0);c.setFillColor(INK);c.rect(0,267,W,H-267,fill=1,stroke=0)
    c.setFillColor(GOLD);c.setFont('BodyBold',10);c.drawString(M,H-62,'DIGIKAT   /   ANALITIČKI IZVJEŠTAJ')
    c.setFillColor(colors.white);c.setFont('Display',37);c.drawString(M,H-151,'Demokršćanstvo');c.drawString(M,H-199,'u javnom govoru')
    c.setFont('Body',17);c.setFillColor(colors.HexColor('#e1ebe5'));c.drawString(M,H-245,'Identitet, načela i društvena pitanja')
    c.setStrokeColor(GOLD);c.setLineWidth(1.5);c.line(M,H-278,M+80,H-278)
    c.setFont('Body',12);c.setFillColor(colors.white);c.drawString(M,H-313,'Analiza zamrznute zbirke 2021. - 10. 9. 2026.');c.drawString(M,H-335,'Izdanje 1.0  |  19. rujna 2026.')
    for x,val,label in [(M,n(S['records']),'automatski uključenih zapisa'),(M+178,n(S['exact_text_groups']),'skupina jednakih tekstova'),(M+350,'10','primarnih tema')]:
        c.setFillColor(GOLD);c.setFont('Display',25);c.drawString(x,340,val);c.setFillColor(colors.white);c.setFont('Body',9.5);c.drawString(x,319,label)
    p=text('Od političkog imena do javnog argumenta: što pokazuje jezik zbirke i koliko nalaz ovisi o ponavljanju.','h1');_,hh=p.wrap(CW,200);p.drawOn(c,M,231-hh)
    p=text('Provedeni izračuni, analize osjetljivosti i pregled dokaznih tekstova. Neovisna ljudska validacija nije dovršena.','body');_,hh=p.wrap(CW,100);p.drawOn(c,M,103-hh)
    c.setFont('Body',8.5);c.setFillColor(MUTED);c.drawString(M,29,'Samostalan izvještaj prema protokolu 2.0. Izvorni plan ostaje sačuvan.')

def frame(c,page,kicker,total):
    c.setFillColor(PAPER);c.rect(0,0,W,H,fill=1,stroke=0);c.setFillColor(COPPER);c.setFont('BodyBold',9.2);c.drawString(M,H-36,f'{page:02d}  /  {kicker.upper()}')
    c.setStrokeColor(LINE);c.setLineWidth(.6);c.line(M,44,W-M,44);c.setFillColor(MUTED);c.setFont('Body',8.2);c.drawString(M,29,'DIGIKAT  /  ANALITIČKI IZVJEŠTAJ 1.0  /  19. 9. 2026.');c.drawRightString(W-M,29,f'{page} / {total}')

def main():
    assert len(PAGES)==19
    PDF.parent.mkdir(parents=True,exist_ok=True);c=canvas.Canvas(str(PDF),pagesize=A4,pageCompression=1)
    c.setTitle('Demokršćanstvo u javnom govoru - analitički izvještaj');c.setAuthor('DigiKat; analiza i pregled: Codex AI')
    c.setSubject('Opisna analiza arhivskih zapisa, tema, ponavljanja i pregledanih argumenata; status ljudske validacije naveden u tekstu')
    c.setViewerPreference('DisplayDocTitle','true');c.bookmarkPage('cover');c.addOutlineEntry('Naslovnica','cover',0);cover(c);c.showPage();layout=[]
    for pg,(kicker,items) in enumerate(PAGES,2):
        height=sum(obj.getSpaceBefore()+obj.wrap(CW,10000)[1]+obj.getSpaceAfter() for obj in items)
        available=H-61-59
        if height>available:raise ValueError(f'Page {pg} overflow {height:.1f} > {available:.1f}')
        c.bookmarkPage('p'+str(pg));c.addOutlineEntry(kicker,'p'+str(pg),0);frame(c,pg,kicker,len(PAGES)+1)
        y=H-61
        for obj in items:
            y-=obj.getSpaceBefore();_,hh=obj.wrap(CW,10000);y-=hh;obj.drawOn(c,M,y);y-=obj.getSpaceAfter()
        layout.append({'page':pg,'content_height':height,'bottom_y':y});c.showPage()
    c.save()
    (QA/'layout.json').write_text(json.dumps(layout,indent=2),encoding='utf-8')
    (OUT/'claim_register.json').write_text(json.dumps(CLAIMS,ensure_ascii=False,indent=2),encoding='utf-8')
    print(json.dumps({'pdf':str(PDF),'pages':20,'claim_blocks':len(CLAIMS),'lowest_bottom':min(x['bottom_y'] for x in layout)},ensure_ascii=False))

if __name__=='__main__':main()
