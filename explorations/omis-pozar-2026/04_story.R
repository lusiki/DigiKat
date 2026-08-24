# 04_story.R — turns derived.json into a DRAFT of the blog post (Croatian) and a LinkedIn post,
# with every number pulled from the aggregates. The prose is a scaffold to be edited by a human;
# the numbers are not to be retyped.
#
#   Rscript 04_story.R
#
# Writes output/story_hr.md, output/linkedin_hr.md, output/linkedin_en.md, output/story_numbers.md (a table
# of every scalar with its provenance).

setwd(dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE)[1]))))
source("lib.R")

D <- read_json(file.path(AGG_DIR, "derived.json"), simplifyVector = TRUE)
SYNTH <- isTRUE(D$synthetic)
rd <- function(name) fread(file.path(AGG_DIR, paste0(name, ".csv")), encoding = "UTF-8")
LAB <- c(sluzbeni = "službeni izvori", lokalni = "lokalni dalmatinski portali", nacionalni = "nacionalni mediji", ostali_web = "ostali web-izvori", strani = "strani mediji", drustveni = "društvene mreže")
LAB_EN <- c(sluzbeni = "official sources", lokalni = "local Dalmatian portals", nacionalni = "national media", ostali_web = "other web sources", strani = "foreign media", drustveni = "social platforms")
FRAME_HR <- sapply(FRAMES, `[[`, "hr")
h <- function(x, d = 1) fmt_hr(x, d)
pct <- function(x, d = 0) fmt_pct_hr(x, d)
clock <- function(hh) format(T0 + hh * 3600, "%A %d.%m. u %H:%M", tz = TZ)

# --- who was first, in order ---------------------------------------------------------------------
fbt <- rd("first_by_type")[order(first_h)]
order_sentence <- paste(sprintf("%s (sat %s)", LAB[fbt$outlet_type], h(fbt$first_h)), collapse = ", ")
first_type <- fbt$outlet_type[1]
pr <- rd("produced_rewarded_type")
top_prod <- pr[which.max(share_items)]; top_rew <- pr[which.max(share_interactions)]
gap_pos <- pr[which.max(gap_pp)]; gap_neg <- pr[which.min(gap_pp)]
rings <- rd("rings")
wt <- rd("window_type")[order(t50)]
st <- rd("sensational_type")[order(-sensational_share)]
fires <- rd("fires")
other_fires <- fires[fire != "omis" & fire != "neodređeno"]
ons <- rd("frames_onset")

banner <- if (SYNTH) paste0("> **", SYNTH_TAG_HR, ".** Ovaj tekst je generiran iz sintetičkog testnog izvoza; sve brojke su izmišljene i služe samo provjeri da predložak radi.\n\n") else ""

story <- paste0(banner, sprintf('# Kako se širi priča o požaru: %s u %s

*Požar kod Omiša, %s Rekonstrukcija iz izvoza servisa za praćenje medija: %s o požaru (od %s u izvozu, koji je pokrio i istodobne požare drugdje), %s, prvih %s.*

## Zašto ovo uopće mjeriti

Svaki veliki događaj ima dva požara. Jedan gori na terenu i gase ga vatrogasci. Drugi gori u medijima i nitko ga ne gasi, on se sam ugasi kad ponestane novog. Prvi se mjeri hektarima, drugi objavama po satu. Ovaj tekst prati drugi, sat po sat, s jednim pitanjem: **kako se priča širi, tko je nosi, kada se mijenja i što od nje dopre do ljudi.** Odgovor nije samo zanimljiv, on je uputa svakome tko će jednom morati brzo komunicirati u krizi, ili tko želi razumjeti zašto se o nečemu piše tri dana, a o nečemu drugom tri sata.

## 1. Dva požara

Prva objava pojavila se %s sata nakon dojave (%s), i to od izvora vrste *%s*. Redoslijed ulaska po vrstama izvora bio je: %s. Vrhunac objavljivanja stigao je u satu %s (%s), kada je u jednom satu izašlo %s, a nakon vrhunca trebalo je %s da se satni volumen prepolovi.

Polovica svega što je ikada objavljeno o požaru izašla je unutar **%s**, četiri petine unutar **%s**. U prva 24 sata objavljeno je %s objava, ali te su objave skupile **%s svih interakcija** koje je priča ikad dobila. Drugim riječima, pažnja publike stigla je brže nego što su mediji stigli pisati.

![Dva požara](figures/01_dva_pozara.png)

## 2. Štafeta: tko je prvi, tko je najviše

U priču je ušlo %s, %s njih u prvih šest sati. %s.

![Štafeta](figures/02_stafeta.png)

## 3. O čemu se pisalo, i kada se to promijenilo

Priča nije jedna priča nego niz priča koje se smjenjuju. Okvir gašenja i vatrogasaca nosi prve sate; %s. Ta smjena okvira nije sitnica za nekoga tko želi biti čut: prve sate drže operativne informacije i nema smisla ulaziti s drugom porukom, a nakon dan-dva mediji traže *sljedeći kut* i tada ulaze uzrok, politika i solidarnost.

![Spektrogram](figures/03_spektrogram.png)

## 4. Objavljeno i nagrađeno

Najviše su objavljivali %s (%s objava), a najviše interakcija skupili su %s (%s interakcija). Najveći dobitak u odnosu na udio u objavama imaju %s (%s postotnih bodova), najveći gubitak %s (%s postotnih bodova). Deset objava s najviše interakcija nosi %s svih zabilježenih interakcija; jedna jedina %s. Na webu %s objava nema nijednu zabilježenu interakciju.

![Objavljeno i nagrađeno](figures/04_objavljeno_nagradeno.png)

## 5. Koliko daleko je priča stigla

%s priče ostalo je u Hrvatskoj. Regionalni mediji (BiH, Srbija, Slovenija, Crna Gora) ušli su u satu %s, ostatak svijeta u satu %s; ukupno %s izvora izvan Hrvatske i %s objava.

![Krugovi](figures/05_krugovi.png)

## 6. Prozor

Različite vrste izvora imaju različit tempo. %s. To je mjera koliko dugo tko ostaje na priči, i ujedno odgovor na pitanje „koliko imam vremena”.

![Prozor](figures/06_prozor.png)

## 7. Temperatura jezika

%s naslova nosi senzacionalan rječnik (apokalipsa, pakao, katastrofa, horor, neviđeno i slično). Najviše ga koriste %s (%s), najmanje %s (%s).

![Temperatura](figures/07_temperatura.png)

## 8. Jeka

%s web-objava o požaru bio je isti naslov na tri ili više portala; %s web-objava izrijekom navodi Hinu. Velik dio onoga što izgleda kao „stotine članaka” zapravo je nekoliko desetaka tekstova umnoženih preko portala.

![Jeka](figures/08_jeka.png)

## Što bih iz ovoga ponio (za svakoga tko će jednom komunicirati u krizi)

1. **Prozor je uzak.** Polovica svega objavljeno je unutar %s. Tko u tom prozoru nema jasnu, provjerljivu informaciju, prepustio je priču drugima.
2. **Ulazna vrata su lokalna i društvena.** Prvi su ušli %s. Nacionalni mediji dolaze za njima i velikim dijelom prepričavaju.
3. **Priča se smjenjuje.** Operativno → žrtve i šteta → politika → uzrok → solidarnost. Poruka koja stigne u pogrešnoj fazi neće biti čuta, koliko god bila točna.
4. **Volumen nije pažnja.** %s.
5. **Jeka je stvarna.** %s istih naslova znači da jedan dobar, točan tekst rano u priči putuje daleko sam od sebe.

## Kako je ovo mjereno

Izvor je izvoz servisa za praćenje medija (Determ) za razdoblje od %s do kraja izvoza; svaka objava nosi vrijeme, izvor, platformu, naslov, tekst i vrijednosti angažmana koje servis bilježi. Objave su svedene na jedinstvene URL-ove, a „o kojem je požaru riječ” odlučuje naslov, pa prvih 300 znakova, pa cijeli tekst, jer je isti tjedan gorjelo i drugdje%s. Vrste izvora dodijeljene su po domeni ili imenu stranice iz javne tablice u kodu i mogu se ispraviti. Tematski okviri su rječnički pogoci u naslovu i prvih 3 000 znakova; jedna objava može nositi više okvira. Interakcije su vrijednosti servisa i razlikuju se po platformi, pa se uspoređuju oprezno i uvijek unutar iste platforme. Sve je opisno: „tko je bio prvi” je usporedba vremenskih oznaka, ne dokaz utjecaja; „nagrađeno” je zabilježena pažnja, ne kvaliteta. Zatvorene grupe (WhatsApp, Viber, Facebook grupe) kojima je u prvim satima kolala najvažnija informacija ovdje su nevidljive. Kod i sve tablice: `explorations/omis-pozar-2026/`.
',
  hr_n(D$n_items, "objava"), hr_n(round(D$span_hours), "sat"),
  hr_date(T0), hr_n(D$n_items, "objava"), hr_n(D$n_items_all_fires, "objava"), hr_n(D$n_sources, "izvor"), hr_n(round(D$span_hours), "sat"),
  h(D$first_item$h, 1), clock(D$first_item$h), LAB[D$first_item$outlet_type], order_sentence, D$peak_hour, D$peak_clock, hr_n(D$peak_n, "objava"), hr_n(D$half_life_hours, "sat"),
  hr_n(D$t50_hours, "sat"), hr_n(D$t80_hours, "sat"), pct(D$share_items_first_24h), pct(D$share_interactions_first_24h),
  hr_n(D$n_sources, "izvor"), h(D$sources_entered_by_6h, 0),
  sprintf("Prvi %s pojavili su se u satu %s, prvi nacionalni u satu %s (razmak %s sati), prvi službeni u satu %s, a prvi strani u satu %s", LAB[first_type], h(fbt$first_h[1]), h(D$first_h_nacionalni), h(D$lag_local_to_national_h), h(D$first_h_sluzbeni), h(D$first_h_strani)),
  paste(sprintf("okvir „%s” prvi put nosi barem četvrtinu objava u satu %s", FRAME_HR[ons$frame], h(ons$onset_h, 0))[ons$frame %in% c("politika", "uzrok", "solidarnost")], collapse = ", "),
  LAB[top_prod$outlet_type], pct(top_prod$share_items), LAB[top_rew$outlet_type], pct(top_rew$share_interactions), LAB[gap_pos$outlet_type], h(gap_pos$gap_pp, 1), LAB[gap_neg$outlet_type], h(gap_neg$gap_pp, 1),
  pct(D$top10_share_all, 1), pct(D$top1_share_all, 1), pct(D$zero_share_web),
  pct(100 - D$foreign_share), h(rings[ring == 3, first_h]), h(rings[ring == 4, first_h]), h(sum(rings[ring >= 3, sources]), 0), h(sum(rings[ring >= 3, n]), 0),
  paste(sprintf("%s prešli su polovicu svojih objava u satu %s", LAB[wt$outlet_type], h(wt$t50, 0)), collapse = "; "),
  pct(D$sensational_share_all, 1), LAB[st$outlet_type[1]], pct(st$sensational_share[1], 1), LAB[st$outlet_type[nrow(st)]], pct(st$sensational_share[nrow(st)], 1),
  pct(D$echo_share_web), pct(D$hina_share_web),
  hr_n(D$t50_hours, "sat"), LAB[first_type],
  cap1(sprintf("%s su imali %s objava i %s interakcija; %s %s objava i %s interakcija", LAB[top_prod$outlet_type], pct(top_prod$share_items), pct(top_prod$share_interactions), LAB[top_rew$outlet_type], pct(top_rew$share_items), pct(top_rew$share_interactions))),
  pct(D$echo_share_web),
  format(T0, "%d.%m.%Y. %H:%M", tz = TZ),
  if (nrow(other_fires)) paste0(" (", paste(sprintf("%s: %s objava", other_fires$fire, h(other_fires$items, 0)), collapse = ", "), ")") else ""
))
writeLines(story, file.path(OUT_DIR, "story_hr.md"), useBytes = FALSE)

# --- LinkedIn posts --------------------------------------------------------------------------------
li_hr <- paste0(if (SYNTH) paste0("[", SYNTH_TAG_HR, "]\n\n") else "", sprintf(
'Svaki veliki događaj ima dva požara. Jedan gase vatrogasci. Drugi gori u medijima i sam se ugasi.

Uzeo sam izvoz servisa za praćenje medija za požar kod Omiša (%s) i pratio drugi požar sat po sat: %s, %s, %s.

Što se vidi:

• Prozor je uzak. Polovica svega objavljeno je unutar %s, četiri petine unutar %s. Prva 24 sata dala su %s objava, ali %s svih interakcija.
• Ulazna vrata su %s: prva objava %s sata nakon dojave. Nacionalni mediji ušli su u satu %s.
• Priča se smjenjuje. Gašenje → žrtve i šteta → politika (sat %s) → uzrok i istraga (sat %s) → solidarnost (sat %s).
• Volumen nije pažnja. %s objavili su %s svega, a skupili %s interakcija; %s %s objava, %s interakcija.
• Jeka: %s web-objava bio je isti naslov na 3+ portala.
• %s priče ostalo je u Hrvatskoj; regija je ušla u satu %s.

Sve je opisno, ništa uzročno. Metoda, kod i grafike u komentaru.

#mediji #krizneKomunikacije #podaci #Omiš',
  format(T0, "%d.%m.", tz = TZ), hr_n(D$n_items, "objava"), hr_n(D$n_sources, "izvor"), hr_n(round(D$span_hours), "sat"),
  hr_n(D$t50_hours, "sat"), h(D$t80_hours, 0), pct(D$share_items_first_24h), pct(D$share_interactions_first_24h),
  LAB[first_type], h(fbt$first_h[1]), h(D$first_h_nacionalni),
  h(D$frame_politika_onset_h, 0), h(D$frame_uzrok_onset_h, 0), h(D$frame_solidarnost_onset_h, 0),
  cap1(LAB[top_prod$outlet_type]), pct(top_prod$share_items), pct(top_prod$share_interactions), LAB[top_rew$outlet_type], pct(top_rew$share_items), pct(top_rew$share_interactions),
  pct(D$echo_share_web), pct(100 - D$foreign_share), h(rings[ring == 3, first_h])
))
writeLines(li_hr, file.path(OUT_DIR, "linkedin_hr.md"))

li_en <- paste0(if (SYNTH) paste0("[", SYNTH_TAG_EN, "]\n\n") else "", sprintf(
'Every big event is two fires. One is put out by firefighters. The other burns in the media and burns itself out.

I took a media-monitoring export for the Omiš wildfire (Croatia, %s) and followed the second fire hour by hour: %s items, %s sources, %s hours.

What shows up:

• The window is narrow. Half of everything was published within %s hours, four fifths within %s. The first 24 hours produced %s of the items but %s of all interactions.
• The entry point is %s: first item %s h after the alarm. National media entered at hour %s.
• The story rotates. Firefighting → casualties and damage → politics (hour %s) → cause and investigation (hour %s) → solidarity (hour %s).
• Volume is not attention. %s produced %s of the items and earned %s of interactions; %s %s of items, %s of interactions.
• Echo: %s of web items were the same headline on 3+ outlets.
• %s of the story stayed inside Croatia; the region entered at hour %s.

Descriptive, not causal. Method, code and charts in the comments.

#media #crisiscommunication #data #Croatia',
  format(T0, "%d %b", tz = TZ), h(D$n_items, 0), h(D$n_sources, 0), h(D$span_hours, 0),
  h(D$t50_hours, 0), h(D$t80_hours, 0), pct(D$share_items_first_24h), pct(D$share_interactions_first_24h),
  LAB_EN[first_type], h(fbt$first_h[1]), h(D$first_h_nacionalni),
  h(D$frame_politika_onset_h, 0), h(D$frame_uzrok_onset_h, 0), h(D$frame_solidarnost_onset_h, 0),
  cap1(LAB_EN[top_prod$outlet_type]), pct(top_prod$share_items), pct(top_prod$share_interactions), LAB_EN[top_rew$outlet_type], pct(top_rew$share_items), pct(top_rew$share_interactions),
  pct(D$echo_share_web), pct(100 - D$foreign_share), h(rings[ring == 3, first_h])
))
writeLines(li_en, file.path(OUT_DIR, "linkedin_en.md"))

# --- provenance table: every scalar the text uses ------------------------------------------------
flat <- function(x, prefix = "") {
  out <- list()
  for (n in names(x)) { v <- x[[n]]; key <- paste0(prefix, n)
    if (is.list(v) && !is.data.frame(v)) out <- c(out, flat(v, paste0(key, "."))) else if (is.data.frame(v)) out[[key]] <- paste0("<table ", nrow(v), " rows>") else out[[key]] <- paste(v, collapse = ", ") }
  out
}
fl <- flat(D)
prov <- data.table(k = names(fl), value = unlist(fl))
writeLines(c("# Every scalar in derived.json (source: 02_analyze.R)", "", "| key | value |", "|---|---|", sprintf("| `%s` | %s |", prov$k, prov$value)), file.path(OUT_DIR, "story_numbers.md"))

cat("Wrote story_hr.md, linkedin_hr.md, linkedin_en.md, story_numbers.md to", OUT_DIR, "\n")
if (SYNTH) cat(">>> ", SYNTH_TAG_EN, " <<<\n")
