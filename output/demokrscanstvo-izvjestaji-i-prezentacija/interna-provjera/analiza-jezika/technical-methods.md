# Interna metodološka dokumentacija

Ova bilješka prati javni izvještaj „Demokršćanstvo: od riječi do argumenta”. Nije dio javnog PDF-a.

## Podloga i jedinice

Polazište su zamrznuta izdanja `demokrscanstvo-multiplatform/v1`, `demokrscanstvo-themes/v1` i tekstualna analiza `demokrscanstvo-text-addendum/v1`. Izvorni obuhvat nije ponovno prikupljen niti preklasificiran. Obuhvat arhive: 1. 1. 2021. - 10. 9. 2026.; prvi uključeni zapis: 6. 1. 2021. Broj zapisa je 2.306, a broj skupina jednakoga teksta 2.253.

Jednaki tekstovi prepoznati su po naslovu i pohranjenom tijelu bez ponovljenog naslova, nakon NFC normalizacije, pretvorbe velikih slova i razmaka. Interpunkcija je zadržana. Ova jedinica nije neovisni događaj, priča ili govornik. Slični, ali nejednaki preneseni tekstovi mogu ostati odvojeni. Javni izvještaj koristi isključivo nazivnik 2.253 za udjele tema, riječi i izraza.

Uključivanje je preuzeto iz postojećih putova A1/B/C. Točan rječnik, oblici, iznimke i pravila su u `baseline/inclusion-definitions.json` i pratećoj bilješci `baseline/inclusion-readme.md`. Izravno demokršćansko nazivlje i kršćanska društvena argumentacija predstavljaju različite ulazne putove. Zbog toga javni opis ne tvrdi da svaka objava izrijekom spominje demokršćanstvo.

## Rječnik i oblaci riječi

Rječnik koristi izvorne rečenice koje dodiruju prozore relevantnog konteksta. Analiza obuhvaća 7.467 rečeničnih jedinica i 99.681 zadržani token. Ponovljena jednaka rečenica unutar predstavnika broji se jednom. Rečenice i izvorna polja nisu spojeni preko granica. Za primjere su pročitani dostupni naslovi i cijela pohranjena tijela, koja ne moraju biti potpuni izvorni članci.

Lematizacija je provedena hrvatskim SET UD 2.5 modelom UDPipe. Zadržane su vrste riječi NOUN, PROPN, ADJ, VERB i ADV, uz eksplicitno očuvanu negaciju i odabrane konektore. Izostavljeni su glagoli biti, htjeti, moći, imati, kazati i reći. Točne verzije, model i ulazni sažeci nalaze se u `baseline/analysis-manifest.json`.

Veličina riječi u oblaku temelji se na broju različitih tekstova s lemom, a ne broju svih ponavljanja riječi ili TF-IDF-u. Za izbor riječi traži se da dominantna pripisana vrsta bude imenica, vlastito ime ili pridjev. Jedinstveni urednički filtar uklanja opće riječi, nazive demokršćanstva/kršćanstva, nejasna osobna imena bez prezimena te uočene nepogodne oblike lematizatora. Filtar je isti za sve oblake; dokumentiran je u `preparation.json` i `prepare.py` u repozitoriju. Izostavljanje iz slike ne mijenja izvorne frekvencije.

Ukupni oblak prikazuje 48 riječi. Svaki tematski oblak prikazuje 18 riječi s najvećim brojem tekstova, uz najmanje tri potporna teksta. Neriješene jednakosti uređuju se abecedno. U svakoj je slici veličina slova monotona s frekvencijom, uz korijensku transformaciju i donju granicu čitljivosti. Veličine su prilagođene zasebno po oblaku i ne uspoređuju se između oblaka. Položaj je deterministički raspored bez preklapanja; boja i razmak nemaju semantičko značenje. To nije mreža semantičkih sličnosti među riječima. Potpune brojčane podloge 228 prikazanih riječi nalaze se u `../tables/word-clouds.csv`.

## Tematske skupine

Preuzeta je postojeća desetokomponentna NMF podjela, bez ponovnog modeliranja. Model je procijenjen na 1.731 različitom kontekstu, uz TF-IDF, minimalnu dokumentnu frekvenciju 5, maksimalnu 85% i najviše 6.000 značajki; ostvareno je 1.372 značajke. Jedinica prikaza u ovom izvještaju ipak je različit tekst. Nema skupina jednakoga teksta s različitim izvornim tematskim oznakama. Deset tema obuhvaća 2.252 teksta, a jedan je nerazvrstan. Model, parametri, izbor broja komponenti i provjere stabilnosti sačuvani su u `baseline/topic-methods.md` i `baseline/topic-summary.json`.

Teme su interpretativni nazivi skupina sličnog rječnika, a ne ručno potvrđene klase namjere ili ideološkog stava. Zbroj tema t01-t04 od 1.105 tekstova (49,0%) opisuje četiri imenovane tematske skupine; nije udio ručno potvrđenih „identitetskih” iskaza u cijelom korpusu.

## Izrazi i interpretacija primjera

Osam izraza u javnom grafikonu odabrano je za prikaz političkog i vrijednosnog jezika. Brojevi dolaze iz izvornog računa susjednih lematiziranih riječi; interpunkcija prekida niz. Tekst se po izrazu broji jednom, a više izraza u istom tekstu može se preklapati. Nisu prikazane samo najčešće neselektirane bigramske kombinacije, među kojima su i gramatički nizovi.

Tri glavna portreta ciljano su odabrana kako bi pokazala razgraničenje pripadnosti (K05), pozivanje na vrijednosti radi određene odluke (K02) i obrazlaganje europske suradnje (K01). Razgovor s Jakovom Žižićem (K03) služi tumačenju idejne razlike. Ove interpretacije rezultat su čitanja Codex AI-a; ne predstavljaju neovisno ljudsko dvostruko kodiranje niti reprezentativan uzorak argumenata. Datumi, govornici i navodi provjereni su prema cjelovitim dostupnim arhivskim tijelima; za tri glavna portreta dodane su javno dostupne poveznice.

Arhivski zapis Glasa Slavonije za K05 nosi datum 30. 8. 2024. (tisak), a mrežna objava i događaj 29. 8. 2024. To je jasno razdvojeno u javnom tekstu. K01 je u arhivi Telegramov prijenos Hine, a javno dostupna poveznica vodi na isti Hinin izvještaj na tportalu. K02 je Kamenjarov prijenos Hine, uz poveznicu na odgovarajući izvještaj Vlade/Hine. K03 provjeren je prema arhivskom tekstu; njegov izvorni mrežni URL nije potvrđen i nije izmišljen.

## Zadržane provjere i granice

Prethodna računalna provjera i usporedba dvaju potpunih izvođenja analize pohranjene su u `baseline`. Trinaest temeljnih tablica bilo je identično u ponovljenom izračunu. Izvorna analiza sadrži osjetljivosti na prošireni kontekst, velike izvore, dominantne rečenice, vremenske i platformske opsege; javni PDF ne izlaže te kontrolne postupke.

Neovisno ljudsko kodiranje 400 tekstova i pilota nije provedeno. Izvještaj stoga ne objavljuje prevalenciju primjene načela, afirmativnog/kritičkog stava ni pouzdanost kodera. Nije provedeno naknadno sentiment-bodovanje. Učestalost riječi i tematskih skupina ne tumači se kao potpora stanovništva, doseg objave ili učinak politike.

PDF sadrži tekstualni sloj, ugrađene fontove, oznaku hrvatskog jezika i knjižne oznake. Nije deklariran kao PDF/UA. HTML pruža semantičke naslove, navigaciju, povećanje teksta i tablice svih vrijednosti prikazanih grafikonima i oblacima. Točan zapis brojčanih, sadržajnih i vizualnih provjera nalazi se u `verification.md`, `verification.json`, `claim-register.csv` i `visual-qa.json`.
