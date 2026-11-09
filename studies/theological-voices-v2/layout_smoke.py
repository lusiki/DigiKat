"""Typography-only test using clearly labelled synthetic values, never a report."""
from pathlib import Path
import fitz
import build_report as b
from analyse import ROLE_HR

out=Path('tmp/pdfs/theological-v2-layout');out.mkdir(parents=True,exist_ok=True)
b.REPORT=out;b.FIG=out;b.register_fonts()
r=b.Report(out/'layout-test.pdf')
r.new('Provjera prijeloma / testni podaci','Hrvatski medijski prostor promatramo kroz prikupljenu građu',
      'Ovo je tehnička provjera tipografije i prikaza. Vrijednosti na grafikonu služe isključivo provjeri prijeloma i nisu nalazi istraživanja.')
r.chart(b.bar('chart-test.png',list(ROLE_HR.values()),list(range(15,0,-1)),'TESTNI PODACI - provjera grafikona'))
r.notes('Tekst služi provjeri prostora za objašnjenje. Hrvatski znakovi: č ć ž š đ. Govornici, njihove uloge i tvrdnje u stvarnom izvještaju dolaze isključivo iz spremljenih rezultata.',
        'Ovo nije završni izvještaj. Glavni uzorak još nije obrađen. Prikaz provjerava razmake, kontrast, duge oznake i cjelovitost tipografije.',
        'TEHNIČKI TEST. Nema empirijskih tvrdnji. Ne distribuirati kao istraživački nalaz.')
r.new('Provjera prijeloma / metodološka stranica','Svaki zadatak zadržava vlastitu evidenciju uspjeha',
      'Primjer rasporeda metodoloških objašnjenja bez rezultata glavnog uzorka.')
r.textblocks([('Cjelovit tekst','Svaki tekst zadržava sve odlomke, uključujući završetak članka. Oznake odlomaka omogućuju dohvat izvornog dokaza. Ovo je tehnička probna stranica.'),
              ('Odvojeni nazivnici','Različite mjere govornika odgovaraju na različita pitanja. Ispravnost računa provjerava zaseban programski test, a ne ovaj prikaz.'),
              ('Provjera izgleda','Sve stranice dovršenog izvještaja treba ponovno pregledati nakon izračuna stvarnih rezultata. Ova provjera ne zamjenjuje pregled isporuke.')])
r.new('TESTNI PODACI / provjera izvornog odlomka','Teološka uloga vidljiva u tekstu',
      'Sintetski odlomak služi provjeri prikaza punog dokaza. Nije izvorni članak ni nalaz istraživanja.')
r.para('IZMIŠLJENI IZVOR | TEHNIČKA PROVJERA',b.M,590,b.W-2*b.M,10,'Bold',30,b.TEAL)
quote=('Ovo je sintetski tekst za provjeru prijeloma cijelog odlomka. Hrvatski znakovi čćžšđ ostaju vidljivi. '*20)[:1250]
r.para('P0001 - '+quote,b.M,557,b.W-2*b.M,11,'Serif',260)
r.notes('TEHNIČKI TEST. Odlomak je izmišljen. Provjerava se može li puni dokaz ostati čitljiv bez skraćivanja završetka.',
        'Ovo nije istraživački nalaz. Završni izvještaj zahtijeva zasebnu provjeru svih stranica sa stvarnim rezultatima.',
        'Sintetski tekst. Ne distribuirati kao izvještaj o medijskim nalazima.')
r.new('TESTNI PODACI / prikaz rezultata provjera','Valjan izlaz još ne jamči ispravno tumačenje',
      'Ovo je provjera prijeloma metodoloških rezultata s izmišljenim vrijednostima. Nije rezultat lokalnog kodiranja.')
r.textblocks([('Razvojni članci','TEST. Na 100 razvojnih članaka valjanost iznosi: teme 100,0 %, spomeni 100,0 %, govornici 100,0 %, skupine 100,0 %. Sintetski primjeri provjeravaju zadana pravila, a ne uspješnost na reprezentativnom skupu ljudskih oznaka.'),
              ('Svježi strojni izazov','TEST. Za 30 odvojenih članaka osnovna konfiguracija daje: teme 100,0 %, spomeni 100,0 %, govornici 100,0 %, skupine 100,0 %. Promijenjena konfiguracija daje: teme 100,0 %, spomeni 100,0 %, govornici 100,0 %, skupine 100,0 %. Isti članci nisu dodatna neovisna opažanja.'),
              ('Neslaganja ostaju u evidenciji','TEST. Od 30 uspoređenih članaka konfiguracije se razlikuju u relevantnosti za 12, skupu uloga za 15, a potpunosti izvora za 19. Osnovna konfiguracija zadržana je bez proglašavanja njezinih oznaka istinitima.')])
r.finish();d=fitz.open(out/'layout-test.pdf')
for i,page in enumerate(d):page.get_pixmap(matrix=fitz.Matrix(1.2,1.2),alpha=False).save(out/f'page-{i+1}.png')
assert 'građu' in d[0].get_text() and 'č ć ž š đ' in d[0].get_text()
print(f'Typography test: {len(d)} pages rendered, Croatian text verified. Not an empirical report.')
