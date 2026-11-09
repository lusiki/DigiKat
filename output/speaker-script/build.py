"""Private speaking manuscript. Never copied to the website or committed."""
from pathlib import Path
from html import escape
import hashlib
import json
import re
import fitz
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from reportlab.lib.styles import ParagraphStyle
from reportlab.platypus import Paragraph
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'output/pdf/Govorni-predlozak-DigiKat-demokrscanstvo-25-min.pdf'
QA=ROOT/'tmp/pdfs/speaker-script'
QA.mkdir(parents=True,exist_ok=True)
OUT.parent.mkdir(parents=True,exist_ok=True)
manifest=json.loads((ROOT/'output/demokrscanstvo-carousel/manifest.json').read_text(encoding='utf-8'))
source=ROOT/'assets/izvjestaji/demokrscanske-vrijednosti-karusel.pdf'
deck=fitz.open(source)
assert len(deck)==18

# Each entry maps to exactly one slide and one manuscript page.
NOTES=[
dict(cue='Naslovnica. Pogled prema publici, zatim kratko prema naslovu izlaganja.',
body=[
'Dobar dan svima i hvala na prilici da predstavim ovaj dio istraživanja projekta DigiKat. U okviru današnjeg skupa o izazovima i budućnosti demokršćanstva želim otvoriti jedno empirijsko pitanje. Kako se pojam demokršćanstva pojavljuje u digitalnom javnom prostoru i što o tome možemo saznati iz medijskih podataka?',
'Naslov izlaganja povezuje demokršćanske vrijednosti i narativne okvire. Moj će pristup danas biti usmjeren na podatke. Pogledat ćemo koje se teme i riječi pojavljuju u prikupljenim objavama, koga članci spominju, koji ih izvori objavljuju i u kojim se razdobljima njihov broj povećava.',
'Krenut ću od projekta i obuhvata analize, a zatim ću kroz nekoliko prikaza pokazati kako se takva zbirka može istraživati. Na kraju ću se vratiti pitanju što nam ti obrasci govore i što bi još trebalo provjeriti čitanjem samih tekstova.'
],transition='Za početak, nekoliko riječi o projektu iz kojeg ovo istraživanje proizlazi.'),
dict(cue='Dva stupca. Povezati medijski prostor s jezikom rasprave.',
body=[
'DigiKat je projekt Hrvatskoga katoličkog sveučilišta koji istražuje prisutnost katoličkih tema u digitalnom javnom prostoru. Zanima nas tko o tim temama govori, gdje se sadržaji pojavljuju i kako su oblikovani.',
'Na slajdu su dva povezana smjera. Prvi je medijski prostor. Tu promatramo izvore, platforme i objave. Drugi je jezik rasprave. Tu nas zanima kako se vjera povezuje s društvenim vrijednostima i javnim pitanjima.',
'Demokršćanstvo je prikladna tema za povezivanje tih dvaju smjerova. Možemo pratiti njegovu prisutnost među različitim medijima, a zatim istražiti riječi, političke pojmove i društvena pitanja koja se uz njega pojavljuju. Današnji prikaz pokazuje kako izgleda jedan takav istraživački put.'
],transition='Prije rezultata važno je razjasniti na koje se podatke pojedini brojevi odnose.'),
dict(cue='Pokazati broj lijevo, pa objašnjenje desno. Jasno izgovoriti razliku u obuhvatu.',
body=[
'Broj na lijevoj strani odnosi se na službeni korpus projekta DigiKat. On obuhvaća 413.985 objava na devet platformi, za razdoblje prikazano na slajdu. Taj broj daje predodžbu o veličini projektnoga korpusa.',
'Analiza demokršćanstva koju danas predstavljam ima zaseban odabir iz šire medijske arhive. U nju ulaze objave koje spominju demokršćanstvo ili povezuju kršćanska načela s javnim pitanjima. Zato se broj objava u toj analizi razlikuje od ukupnoga projektnog korpusa.',
'Ovdje želim precizirati i odnos prema naslovu izlaganja. Iako naslov polazi od katoličkih medija, nalazi koje ću pokazati obuhvaćaju i katoličke i opće medije. Ovo nije zasebno izdvojena analiza samo katoličkih nakladnika. Ta je razlika važna kada budemo gledali popis izvora i javnih osoba.'
],transition='Na sljedećem slajdu vidi se kako od široke arhive dolazimo do zbirke koju analiziramo.'),
dict(cue='Pratiti tri broja slijeva nadesno. Zadržati se na razlici između objave i teksta.',
body=[
'Polazište je pretraživa arhiva s više od 41 milijuna zapisa na četrnaest platformi. Iz nje je prema kriterijima ove analize izdvojeno 2.306 objava. To su objave u kojima se pojavljuje demokršćanstvo ili kršćanski utemeljen argument o javnom pitanju.',
'Za analizu jezika imamo 2.253 različita teksta. Razlika nastaje zato što se isti tekst može pojaviti više puta. Kada nas zanima medijska prisutnost, zasebne objave ostaju zasebne jedinice. Kada brojimo riječi, jednak tekst brojimo jednom.',
'Zato ćemo u nastavku susresti dva nazivnika. Tematski pregled odnosi se na 2.306 objava, a prikaz rječnika na 2.253 različita teksta. Razdoblje analize završava 10. rujna 2026. Sve te brojke opisuju odabrani medijski materijal. Iz njih ne možemo izravno zaključivati o potpori građana demokršćanstvu.'
],transition='Sada možemo pogledati kako su objave raspoređene po temama.'),
dict(cue='Čitati prvi stupac odozgo prema dolje, zatim pokazati širinu tema desno.',
body=[
'Ovo je tematska karta cijele zbirke. Svaka je objava prema sličnosti sadržaja pridružena jednoj glavnoj temi. Duljina stupca pokazuje njezinu zastupljenost, a uz stupac su broj objava i njihov udio.',
'Najveća skupina odnosi se na političku pripadnost i ideje, s 377 objava. Slijede vrijednosti i svjetonazorski prijepori s 335 te HDZ i demokršćanski identitet s 290 objava. Već taj raspored pokazuje da se pojam demokršćanstva u ovoj zbirci često pojavljuje u razgovoru o političkom položaju, identitetu i vrijednostima.',
'Desna strana karte proširuje pregled. Vidimo Europu, obitelj, idejnu tradiciju, izbore i međunarodne odnose. Za današnje izlaganje važno mi je pokazati tu raznolikost. Jedna opća riječ u pretraživanju vodi prema više različitih područja javne rasprave. Tematske oznake pritom opisuju sadržaj, a ne slaganje autora s demokršćanstvom.'
],transition='Teme daju širu strukturu. Rječnik nam pokazuje od kojih se riječi ta struktura sastoji.'),
dict(cue='Najprije oblak riječi, zatim tri brojke desno. Ne čitati sve riječi.',
body=[
'Na ovom slajdu prelazimo na 2.253 različita teksta. Brojene su riječi u rečenicama povezanima s temom. Različiti gramatički oblici objedinjeni su, pa se, primjerice, riječ vrijednosti broji pod osnovnim oblikom vrijednost. Ista se riječ unutar jednoga teksta broji najviše jednom.',
'Najraširenija je riječ vrijednost, koja se pojavljuje u 1.123 teksta, odnosno u približno polovici zbirke. Slijede stranka u 830 i HDZ u 818 tekstova. U oblaku vidimo i Europu, obitelj, domoljublje, narodnjaštvo i državotvornost.',
'Veličina riječi govori u koliko se tekstova ona pojavljuje. Njezin položaj i boja nemaju dodatno značenje. Iz prikaza su izostavljeni nazivi demokršćanstva i kršćanstva kako bi njihov kontekst bio vidljiviji. Ovaj nas pregled usmjerava prema riječima koje vrijedi dalje istražiti. Za razumijevanje njihove uloge potrebno je pogledati rečenice i argumente u kojima se pojavljuju.'
],transition='To se posebno dobro vidi kada riječi promatramo u međusobnoj vezi.'),
dict(cue='Pokazati dva ili tri retka tablice. Ostale ostaviti publici za pregled.',
body=[
'Ovdje su izdvojeni primjeri povezanih pojmova i pitanja koja se uz njih raspravljaju. Tablica sažima odabrane kontekste iz izvještaja. Nije riječ o rang-listi najčešćih parova.',
'Domoljublje i narodnjaštvo pojavljuju se u razgovoru o političkoj tradiciji i stranačkim vrijednostima. Kada se domoljublje poveže s državotvornošću, otvaraju se pitanja države, nacionalnih interesa i povijesnog nasljeđa. Povezivanje demokršćanstva i konzervativizma usmjerava nas prema sličnostima i granicama tih političkih tradicija.',
'Posebno su zanimljivi savjest i solidarnost. Savjest se može pojaviti u raspravi o prizivu savjesti, ali i kao osobna odgovornost pri političkom izboru. Solidarnost u europskom kontekstu može označavati suradnju i mogućnosti razvoja. Zato isti rječnik ne znači nužno isti argument. Za analizu je važno utvrditi što se pojedinim pojmom tvrdi u konkretnom tekstu.'
],transition='Sljedeće je pitanje mijenja li se tematski sastav objava kroz godine.'),
dict(cue='Objasniti čitanje po stupcima. Pokazati ćelije 2022., 2024. i 2025.',
body=[
'Ovu tablicu čitamo po stupcima, odnosno unutar svake godine. Tamnija boja znači veći udio teme u objavama te godine. Primjerice, udio od 25 posto znači da približno četvrtina godišnjih objava pripada toj temi.',
'Izdvojit ću tri primjera. U 2022. najzastupljenija je tema HDZ-a i demokršćanskog identiteta, s 24,4 posto. U 2024. to su Europa i kršćanski korijeni, s 24,8 posto. U 2025. vode vrijednosti i svjetonazorski prijepori, s 25,9 posto. Puna tablica omogućuje da te primjere smjestimo u odnos prema ostalim temama.',
'Ovdje uspoređujemo sastav prikupljenih objava. Godine nemaju jednak broj objava ni potpuno jednak obuhvat. Prikupljanje se promijenilo u travnju 2024., a za 2026. podaci završavaju 10. rujna. Stoga promjena boje sama po sebi nije dokaz promjene stava javnosti. Ona pokazuje promjenu tematske zastupljenosti u našoj zbirci.'
],transition='Osim vremena, na sastav zbirke utječe i platforma s koje objave dolaze.'),
dict(cue='Broj lijevo odnosi se na cijelu zbirku. Postoci desno odnose se na pojedinu platformu.',
body=[
'Web čini najveći dio zbirke. Na njega otpada 1.811 od ukupno 2.306 objava, odnosno 78,5 posto. To je važno jer web članci snažno određuju ukupnu sliku koju smo dosad gledali.',
'Desno su vodeće teme unutar nekoliko manjih platformskih zbirki. Na X-u, odnosno Twitteru, ističu se domoljublje i državotvornost. Na Facebooku vode desni centar i suradnja stranaka, a u komentarima HDZ i demokršćanski identitet. Ti su postoci izračunani zasebno za svaku platformu.',
'Ne bih iz toga izvodio opće zaključke o svim korisnicima tih platformi. Njihove su zbirke različite veličine, a razlikuju se i razdoblja te dostupnost teksta. Ovaj prikaz pomaže razumjeti sastav analiziranoga materijala. U sljedećem dijelu usredotočit ću se na web članke kako bismo osobe, izvore i vremenska kretanja promatrali unutar iste skupine.'
],transition='Krenimo od jednostavnog pitanja. Koje se odabrane javne osobe spominju u tim člancima?'),
dict(cue='Pokazati prva dva stupca i pravilo brojanja desno. Ne čitati cijeli popis.',
body=[
'U zbirci od 1.811 web članaka prebrojeno je spominjanje šest odabranih javnih osoba. Andrej Plenković pojavljuje se u 691 članku, a Franjo Tuđman u 248. Na slajdu su prikazani i Miroslav Škoro, Ivan Penava, Zoran Milanović te Davor Ivo Stier.',
'Po osobi se članak broji jednom, bez obzira na to koliko je puta ime ponovljeno. Isti članak može spominjati više osoba, pa udjele ne zbrajamo kao da su međusobno isključive skupine. Traži se puno ime i prezime, uz padežne oblike, u naslovu ili dostupnom tekstu. Spominjanje samo prezimena može zato ostati neprepoznato.',
'Ovo je odabrani popis, a ne iscrpna ljestvica svih osoba u zbirci. Broj govori o prisutnosti imena u člancima. Ne govori zagovara li osoba demokršćanstvo niti je li prikazana pozitivno ili negativno. Za to bismo morali analizirati kontekst svakog spominjanja.'
],transition='Uz osobe koje se spominju, možemo pogledati i izvore koji članke objavljuju.'),
dict(cue='Povezati šest prikazanih izvora s ukupnim brojem od 239.',
body=[
'Web članci u ovoj zbirci dolaze iz 239 različitih izvora. Lijevo je šest izvora s najvećim brojem uključenih članaka. Index ima 74 članka, Dragovoljac 70, a Direktno 66. Slijede Dnevno, Narod i Kamenjar.',
'Tih šest izvora zajedno ima 369 članaka, odnosno 20,4 posto web zbirke. To znači da se približno petina članaka nalazi kod šest prikazanih izvora, dok je preostali dio raspoređen među ostalima. Već takav pregled otvara pitanje koliko je rasprava koncentrirana, a koliko raspršena kroz medijski prostor.',
'Ovo su brojevi objavljenih članaka koji su ušli u našu zbirku. Oni ne mjere publiku, doseg ni utjecaj pojedinoga izvora. Veći broj članaka također ne znači nužno da je izvor temi skloniji. Može je pratiti, podržavati, kritizirati ili prenositi izjave drugih.'
],transition='Nakon pitanja tko objavljuje, pogledajmo kada se objavljuje.'),
dict(cue='Pratiti liniju, pokazati tri označena vrha i okomitu oznaku promjene obuhvata.',
body=[
'Linija prikazuje mjesečni broj web članaka od početka 2021. do 10. rujna 2026. Vidljivo je da objave nisu ravnomjerno raspoređene. Razdoblja s manjim brojem članaka prekidaju izraženiji vrhovi.',
'Najviši je vrh u svibnju 2021., sa 132 članka. U lipnju 2022. imamo 119, a u lipnju 2024. godine 109 članaka. To su dobra polazišta za detaljniji pregled sadržaja. Možemo pitati koje su teme tada zastupljene, koji izvori objavljuju i prenose li članci isti događaj ili više različitih rasprava.',
'Isprekidana okomita crta označuje promjenu obuhvata prikupljanja u travnju 2024. Zato visinu linije moramo čitati zajedno s informacijom o prikupljanju. Rast ili pad broja uključenih članaka nije sam po sebi mjera rasta ili pada javne potpore. Graf nam prije svega pokazuje gdje se u prikupljenom materijalu nalaze razdoblja veće aktivnosti.'
],transition='Koliko se zbirke zapravo koncentrira u nekoliko najaktivnijih mjeseci?'),
dict(cue='Najprije istaknuti 24,9 posto, zatim povezati s četiri mjeseca desno.',
body=[
'Četiri mjeseca s najvećim brojem članaka zajedno okupljaju 451 članak. To je 24,9 posto svih web članaka u analizi, dakle približno četvrtina zbirke.',
'Uz svibanj 2021., lipanj 2022. i lipanj 2024., ovdje je i travanj 2024. s 91 člankom. Takva koncentracija korisna je za organiziranje daljnjeg istraživanja. Ako želimo razumjeti zašto se tema u određenom trenutku pojavljuje češće, ova četiri mjeseca nude jasno određen skup članaka od kojeg možemo krenuti.',
'No velik broj objava još ne objašnjava njihov sadržaj. Također ne znači da je svaki članak zaseban događaj ili nova ideja. Zato brojanje nadopunjujemo tematskim pregledom. Na taj način vremenski vrh dobiva sadržaj koji možemo konkretnije opisati i zatim provjeriti čitanjem.'
],transition='Na sljedećem slajdu uspoređujem vodeće teme u tri najveća mjesečna vrha.'),
dict(cue='Tri retka čitati kao tri odvojena mjeseca. Naglasiti različite nazivnike.',
body=[
'U svibnju 2021. najzastupljenija je tema izbora i konzervativne scene. Njoj pripadaju 53 od 132 članka, odnosno 40,2 posto toga mjeseca.',
'U lipnju 2022. vode domoljublje i državotvornost, s 28 od 119 članaka. U lipnju 2024. vode Europa i kršćanski korijeni, s 48 od 109 članaka, odnosno 44 posto. Tako tri razdoblja povećane aktivnosti imaju različit tematski sastav.',
'Ove postotke računamo unutar svakog mjeseca. Oni pokazuju koja je tema u pojedinom vrhu najzastupljenija, ali ne tvrde da sve objave toga mjeseca govore o istoj stvari. Meni je ovdje važan prijelaz od pitanja koliko ima članaka prema pitanju o čemu ti članci govore. To nam daje precizniju osnovu za odabir tekstova koje ćemo dalje čitati.'
],transition='Isti postupak možemo primijeniti i na kraće razdoblje, primjerice na jedan dan.'),
dict(cue='Povezati 39 članaka s 26 izvora. Zatim kratko pokazati tematske udjele.',
body=[
'Dan s najvećim brojem uključenih web članaka bio je 11. lipnja 2022. Toga dana imamo 39 članaka iz 26 različitih izvora. To je primjer vremenski vrlo koncentrirane medijske aktivnosti.',
'Više od polovice tih članaka, njih 20, pripada temi domoljublja i državotvornosti. Deset se odnosi na političku pripadnost i ideje, a šest na vrijednosti i svjetonazorske prijepore. Na slajdu su prikazane tri vodeće teme.',
'Ovdje je posebno važno razlikovati broj članaka od broja događaja. Više medija može prenositi istu izjavu ili izvještavati o istom povodu. Sam broj izvora ne govori jesu li posrijedi neovisno nastali tekstovi. Za takav zaključak treba usporediti sadržaj članaka. Ovaj dnevni vrhunac zato vidim kao dobro određeno mjesto za nastavak istraživanja, a ne kao već dovršeno objašnjenje.'
],transition='Sada mogu povezati ova opažanja u nekoliko zaključaka o tome što podaci omogućuju.'),
dict(cue='Vratiti se na tri retka. Usporiti prije završne misli.',
body=[
'U ovom smo pregledu povezali tri skupine pitanja. Prva se odnosi na osobe i izvore. Koga članci spominju i kod kojih izvora nalazimo najviše uključenih objava? Druga se odnosi na vrijeme. Kada se objave koncentriraju? Treća se odnosi na teme. O čemu se govori u pojedinim razdobljima i na pojedinim platformama?',
'Takav pristup daje preglednu kartu medijske prisutnosti pojma demokršćanstva. Vidjeli smo različite tematske skupine, česte riječi te mjesečne i dnevne vrhove. Svaki od tih prikaza pomaže suziti i precizirati sljedeće istraživačko pitanje.',
'Za tumačenje je ipak potrebno povezati broj s tekstom. Tek čitanjem možemo utvrditi tko nešto tvrdi, na koji se događaj poziva i kako obrazlaže svoj stav. Vrijednost ovakve analize vidim upravo u tome što pregled velike zbirke može usmjeriti pažljivo čitanje na jasno određene osobe, izvore i razdoblja.'
],transition='Projekt DigiKat pruža nekoliko javnih resursa za takav nastavak rada.'),
dict(cue='Pokazati skupine poveznica. Ne otvarati ih tijekom izlaganja.',
body=[
'Na ovom su slajdu ulazi u širi projekt. Mapa medijskog prostora povezuje izvore, teme i vremenska kretanja. Metodološke stranice objašnjavaju obuhvat i način rada, a katalog izvora omogućuje pregled pojedinih medija i platformi.',
'Tu su i izvršni pregled, povezana tematska istraživanja te godišnji pregled. Za današnju temu to znači da se pojedini nalaz može staviti u širi kontekst katoličkih tema u digitalnom prostoru.',
'Moguć nastavak bio bi, primjerice, izdvojiti određeni skup izvora, usporediti njihovu tematsku strukturu ili detaljnije obraditi jedan vremenski vrhunac. Pritom bi svaki novi odabir trebao imati jasno određene kriterije i vlastiti opis obuhvata. Tako pregled podataka postaje polazište za preciznije istraživanje.'
],transition='Za kraj, ovdje su materijali koji izravno prate današnje izlaganje.'),
dict(cue='Pokazati izvještaje i QR kod. Nakon zahvale zastati i ostaviti slajd prikazan.',
body=[
'Prvi izvještaj donosi pregled demokršćanstva u medijskom prostoru, s temama, medijima i vremenskim prikazima. Drugi se usredotočuje na riječi i način na koji se u tekstovima oblikuju argumenti. Uz karusel su dostupni i zbirni podaci o osobama, izvorima i vremenskim vrhuncima.',
'QR kod vodi na stranicu s analizom i poveznicama. Ondje se mogu pogledati prikazi u vlastitom ritmu i provjeriti kako su pojedini nalazi dobiveni.',
'Za današnju raspravu ostavio bih jednu završnu misao. Ako želimo razumjeti prisutnost demokršćanstva u javnom prostoru, korisno je povezati pojam s konkretnim tekstovima, izvorima i vremenom u kojem se pojavljuje. Podaci nam omogućuju da to pitanje postavimo preciznije. Hvala vam na pozornosti. Veselim se pitanjima i raspravi.'
],transition=None),
]

EXTRA={
2:'Ta dva smjera mogu se povezati na sasvim praktičan način. Najprije pronađemo skup objava o određenoj temi, zatim pogledamo njihov raspored među izvorima, a potom se vratimo tekstovima. Tako se pregled medijskog prostora nadopunjuje analizom sadržaja.',
3:'Važno je stoga uz svaku brojku zadržati pitanje što je točno prebrojeno. Broj za cijeli projekt daje širi okvir, dok broj uključenih objava opisuje ovu posebnu analizu. Njih ne treba zbrajati niti izravno uspoređivati kao dva dijela iste cjeline.',
4:'Zamislimo da jednak tekst prenesu dva portala. Za pitanje gdje se sadržaj pojavio to su dvije objave. Za pitanje koje riječi taj sadržaj upotrebljava dovoljno ga je pročitati i prebrojiti jednom. Različito brojanje odgovara različitim istraživačkim pitanjima.',
5:'Oba stupca koriste isto mjerilo, pa možemo uspoređivati duljine svih prikazanih traka. Kartu čitamo od najzastupljenije teme prema manjima. Manja skupina pritom može biti vrlo zanimljiva za istraživanje, iako se pojavljuje u manjem dijelu zbirke.',
6:'Primjerice, broj uz riječ vrijednost ne znači da je ta riječ ukupno izgovorena ili napisana toliko puta. Znači da je pronađena u toliko različitih tekstova. Time jedan tekst s mnogo ponavljanja iste riječi ne dobiva veću težinu od ostalih.',
7:'Za daljnji rad mogli bismo uzeti jedan od tih parova i usporediti rečenice u kojima se pojavljuje. Tada bismo mogli razlikovati predstavljanje vlastitih načela od kritike tuđega djelovanja. Tablica nam daje početni smjer za takvo čitanje.',
8:'Udio i broj objava pritom odgovaraju na različita pitanja. Tema može imati veći udio u godini s manjom zbirkom, a ipak manje članaka. Ovdje gledamo relativnu zastupljenost, dok ćemo apsolutne mjesečne brojeve vidjeti nešto kasnije.',
9:'Isti postotak na dvije platforme zato ne mora značiti i isti broj objava. Za čitanje ovakve usporedbe uvijek trebamo znati veličinu skupine iz koje je postotak izračunan. To je razlog zbog kojeg najprije pokazujem koliko web sudjeluje u ukupnoj zbirci.',
10:'Dva članka koja spominju istu osobu mogu pritom imati vrlo različite teme. Jedan može govoriti o stranačkom identitetu, a drugi o europskoj politici. Povezivanje popisa osoba s tematskim oznakama bio bi sljedeći korak kojim bismo razjasnili tu razliku.',
11:'Zanimljivo bi bilo usporediti i koje teme objavljuje svaki izvor. Dva izvora mogu imati sličan broj članaka, ali drukčiji sadržaj. Jedan se, primjerice, može više baviti stranačkim odnosima, a drugi društvenim vrijednostima. To bi trebalo zasebno provjeriti.',
12:'Na liniji zato najprije tražim mjesta koja odskaču od susjednih mjeseci. Nakon toga pitam je li porast raspršen među izvorima i temama ili je koncentriran. Takav redoslijed pomaže da objašnjenje ne izvedemo samo iz oblika grafikona.',
13:'Ovdje je korisno pogledati i ostatak zbirke. Većina članaka ipak se nalazi izvan ta četiri mjeseca. Za širu sliku zato bismo uz vrhunce trebali čitati i mirnija razdoblja, kako istraživanje ne bi ostalo ograničeno samo na najuočljivije trenutke.',
14:'Usporedba također pokazuje zašto nije dovoljno sve vrhunce opisati istom rečenicom. Sličan broj članaka može pratiti različite teme. Razvrstavanje po sadržaju omogućuje da svaki mjesec promatramo zasebno, a zatim tražimo ono što im je zajedničko.',
15:'Praktičan nastavak bio bi složiti te članke prema vremenu objave i usporediti njihove naslove i tekstove. Tako bismo mogli vidjeti ponavlja li se ista poruka, tko je prenosi i pojavljuju li se uz nju dodatna tumačenja ili kritike.',
16:'Važno mi je i da se put do nalaza može pratiti. Ako znamo jedinicu brojanja, razdoblje i obuhvat, lakše možemo provjeriti što pojedini prikaz znači. To olakšava i razgovor između ljudi koji se više bave podacima i onih koji bolje poznaju sadržaj rasprave.',
17:'Takav se rad može organizirati postupno. Jedno istraživanje može krenuti od medija, drugo od pojma, a treće od razdoblja. Zajednička osnova omogućuje da se nalazi usporede, uz jasno navođenje razlika u odabranom materijalu i načinu analize.'
}
for slide,text in EXTRA.items():
    NOTES[slide-1]['body'].insert(2,text)

# Approximate pacing, including pauses, rounded to five seconds and totaling 25 minutes.
word_counts=[sum(len(re.findall(r'\S+',p)) for p in n['body']+([n['transition']] if n['transition'] else [])) for n in NOTES]
weights=[n+16 for n in word_counts]
raw=[300*w/sum(weights) for w in weights]
units=[int(x) for x in raw]
for j in sorted(range(18),key=lambda j:raw[j]-units[j],reverse=True)[:300-sum(units)]:
    units[j]+=1
durations=[n*5 for n in units]
assert sum(durations)==1500
clock=lambda n:f'{n//60:02d}:{n%60:02d}'

for name,file in [('Body','calibri.ttf'),('Bold','calibrib.ttf'),('Title','georgia.ttf')]:
    pdfmetrics.registerFont(TTFont(name,'C:/Windows/Fonts/'+file))
INK=HexColor('#152f49'); MUTED=HexColor('#526274'); GOLD=HexColor('#8a782e'); LINE=HexColor('#d2d8db')
styles={
 'title':ParagraphStyle('title',fontName='Title',fontSize=21,leading=26,textColor=INK),
 'body':ParagraphStyle('body',fontName='Body',fontSize=16,leading=24.5,textColor=INK,spaceAfter=16),
 'cue':ParagraphStyle('cue',fontName='Body',fontSize=10.5,leading=14,textColor=MUTED),
 'transition':ParagraphStyle('transition',fontName='Body',fontSize=14.5,leading=21,textColor=INK),
}
W,H=595.2756,841.8898
left,right=48,48
width=W-left-right
layout=[]
spoken_words=sum(len(re.findall(r'\S+',p)) for n in NOTES for p in n['body']+([n['transition']] if n['transition'] else []))
def paragraph(c,text,x,y,w,style):
    markup=escape(text)
    if style=='body':
        markup=re.sub(r'\b\d[\d.,]*\d\b|\b\d\b',lambda m:'<font name="Bold">'+m[0]+'</font>',markup)
    p=Paragraph(markup,styles[style]); _,h=p.wrap(w,H)
    p.drawOn(c,x,y-h)
    return y-h

c=canvas.Canvas(str(OUT),pagesize=(W,H),initialFontName='Body',initialFontSize=16)
c.setTitle('Govorni predložak uz karusel o demokršćanstvu')
c.setAuthor('Luka Šikić')
c.setSubject('Osobni primjerak za izlaganje 24. rujna 2026. Prati 18 slajdova karusela.')
elapsed=0
for i,note in enumerate(NOTES,1):
    title=manifest['slide_titles'][i-1]
    c.bookmarkPage(f'slide-{i}');c.addOutlineEntry(f'{i:02d} | {title}',f'slide-{i}',0)
    c.setFillColor(INK);c.setFont('Bold',10)
    c.drawString(left,H-35,'DIGIKAT / GOVORNI PREDLOŽAK')
    c.setFont('Body',9);c.setFillColor(MUTED)
    c.drawRightString(W-right,H-35,'OSOBNI PRIMJERAK · 24. 9. 2026.')
    c.setStrokeColor(GOLD);c.setLineWidth(.8);c.line(left,H-46,W-right,H-46)
    c.setFillColor(GOLD);c.setFont('Title',32);c.drawString(left,H-92,f'{i:02d}')
    c.setFont('Body',10);c.drawString(left+51,H-89,'/ 18 · SLAJD')
    elapsed+=durations[i-1]
    c.setFont('Body',10);c.setFillColor(MUTED)
    c.drawString(left,H-110,f'Okvirno {clock(durations[i-1])} · do {clock(elapsed)} od 25:00')
    # Small exact slide image anchors orientation without competing with the script.
    thumb=QA/f'thumb-{i:02d}.png'
    deck[i-1].get_pixmap(matrix=fitz.Matrix(.3,.3),alpha=False).save(thumb)
    c.drawImage(str(thumb),W-right-117,H-120,width=117,height=65.8125)
    title_text=title if i!=1 else 'Demokršćanske vrijednosti u digitalnom javnom prostoru'
    y=paragraph(c,title_text,left,H-130,width,'title')-12
    c.setFont('Bold',9);c.setFillColor(MUTED);c.drawString(left,y,'PODSJETNIK ZA IZLAGANJE · NE ČITA SE NAGLAS')
    y=paragraph(c,note['cue'],left,y-7,width,'cue')-18
    c.setFont('Bold',9);c.setFillColor(GOLD);c.drawString(left,y,'TEKST ZA GOVOR')
    y-=10
    for body in note['body']:
        y=paragraph(c,body,left,y,width,'body')-13
    if note['transition']:
        y-=2;c.setStrokeColor(LINE);c.setLineWidth(.5);c.line(left,y,W-right,y);y-=17
        c.setFont('Bold',9);c.setFillColor(GOLD);c.drawString(left,y,'PRIJELAZ NA SLJEDEĆI SLAJD');y-=9
        y=paragraph(c,note['transition'],left,y,width,'transition')
    assert y>62,(i,y)
    c.setStrokeColor(LINE);c.setLineWidth(.5);c.line(left,48,W-right,48)
    c.setFont('Body',9);c.setFillColor(MUTED)
    footer='Jedna stranica = jedan slajd. Vremena su okvirna, uključuju stanke.' if i!=1 else 'Približno 25 minuta. Podsjetnici i vremenske oznake ne čitaju se naglas.'
    c.drawString(left,33,footer);c.drawRightString(W-right,33,f'{i:02d} / 18')
    layout.append(dict(slide=i,title=title,bottom=y))
    c.showPage()
c.save()
proof=fitz.open(OUT)
assert len(proof)==18
for i,page in enumerate(proof,1):
    assert '\ufffd' not in page.get_text()
    for block in page.get_text('dict')['blocks']:
        for line in block.get('lines',[]):
            for span in line['spans']:
                x0,y0,x1,y1=span['bbox']
                assert x0>=44 and x1<=W-44 and y0>=20 and y1<=H-20,(i,span)
    page.get_pixmap(matrix=fitz.Matrix(1.2,1.2),alpha=False).save(QA/f'page-{i:02d}.png')
(QA/'verification.json').write_text(json.dumps(dict(pages=18,spoken_words=spoken_words,layout=layout,
    source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
    output_sha256=hashlib.sha256(OUT.read_bytes()).hexdigest()),ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(dict(pdf=str(OUT),pages=18,spoken_words=spoken_words,minimum_bottom=min(r['bottom'] for r in layout)),ensure_ascii=False))
