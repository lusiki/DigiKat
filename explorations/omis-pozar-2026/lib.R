# explorations/omis-pozar-2026/lib.R
# Shared definitions for the Omiš wildfire media-diffusion exploration.
# Sourced by every numbered script. Self-contained on purpose: this exploration is NOT
# part of the DigiKat corpus pipeline and must stay portable to a personal blog build.
#
# Everything here is a DEFINITION (dictionaries, registries, theme, helpers).
# No data is read at source time.

suppressPackageStartupMessages({
  library(data.table)
  library(stringi)
  library(jsonlite)
})

options(stringsAsFactors = FALSE, warn = 1, datatable.print.class = TRUE)
Sys.setlocale("LC_COLLATE", "C")

# ---------------------------------------------------------------------------
# Paths (all relative to the exploration folder; scripts cd here first)
# ---------------------------------------------------------------------------
EX_DIR   <- normalizePath(".", winslash = "/", mustWork = TRUE)
IN_DIR   <- file.path(EX_DIR, "input")
OUT_DIR  <- file.path(EX_DIR, "output")
AGG_DIR  <- file.path(OUT_DIR, "agg")
FIG_DIR  <- file.path(OUT_DIR, "figures")
PRIV_DIR <- file.path(OUT_DIR, "private")   # row-level exports (titles, URLs) — never leaves the machine
for (d in c(IN_DIR, OUT_DIR, AGG_DIR, FIG_DIR, PRIV_DIR)) dir.create(d, showWarnings = FALSE, recursive = TRUE)

# The repo root (two levels up) — only used to borrow the URL canonicaliser.
REPO_ROOT <- normalizePath(file.path(EX_DIR, "..", ".."), winslash = "/", mustWork = TRUE)

TZ <- "Europe/Zagreb"

# ---------------------------------------------------------------------------
# The fire itself: an event registry for annotating the media timeline.
# Times are Europe/Zagreb. `precision` says how the time is known:
#   "official"  — stated by DORH / ŽVOC / HVZ with a clock time
#   "liveblog"  — the timestamp of a live-blog entry reporting it (upper bound on the event time)
#   "day"       — only the day is known
# The registry is a reading aid, not a measurement. Edit freely as better times surface.
# ---------------------------------------------------------------------------
FIRE_EVENTS <- fread(sep = "|", text = "
t|label_hr|label_en|phase|precision
2026-08-13 20:15|Dojava o požaru u Lokvi Rogoznici|Fire reported at Lokva Rogoznica|ignition|official
2026-08-13 23:00|Magistrala zatvorena; evakuacija u dvoranu Ribnjak|Coastal road closed; evacuation to Ribnjak hall|operational|liveblog
2026-08-14 01:30|Vatra 50 m od centra Omiša|Fire 50 m from Omiš centre|operational|liveblog
2026-08-14 06:00|Četiri kanadera na požarištu|Four Canadairs deployed|operational|liveblog
2026-08-14 08:55|Tucaković: 900–1000 ha; ~1000 evakuiranih|Chief: 900–1000 ha; ~1000 evacuated|operational|liveblog
2026-08-14 13:30|Pronađena mrtva osoba|Body found|casualties|official
2026-08-14 16:08|Ministrica: 42 pregledana; 7 na respiratoru|Minister: 42 examined; 7 on ventilators|casualties|liveblog
2026-08-14 17:00|Milanović u Omišu: „neviđeno”; stiže Plenković|President in Omiš; PM arrives|politics|day
2026-08-15 11:30|HVZ: stanje povoljnije; sanacija|Fire service: situation favourable|aftermath|liveblog
2026-08-15 20:10|DORH: opseg 23 km × 1,5 km; 1 mrtav; 38 ozlijeđenih|Prosecutor: 23 km × 1.5 km; 1 dead; 38 injured|investigation|liveblog
2026-08-15 15:54|Pula donira 20 000 € Omišu|Pula donates €20 000|solidarity|liveblog
")
FIRE_EVENTS[, t := as.POSIXct(t, tz = TZ, format = "%Y-%m-%d %H:%M")]
T0 <- FIRE_EVENTS[phase == "ignition", t][1]   # hour zero of the story

# ---------------------------------------------------------------------------
# Which fire? The same week had several. A "požar" query catches all of them.
# Order matters: the first pattern that matches wins.
# ---------------------------------------------------------------------------
FIRE_TAGS <- list(
  omis      = "omi[šs]|rogoznic|stani[ćc]|nemir[ai]|ruskamen|dugi rat|medi[ćc]i|omi[šs]k",
  peljesac  = "pelje[šs]|kun[ae] pelje|orebi[ćc]|ston",
  dugi_otok = "dug(i|om|og) otok|savar|sali\\b|božav|bozav",
  brac      = "\\bbra[čc]\\b|bra[čc]k|supetar|bol\\b",
  skrljevo  = "[šs]krljev|bakar\\b|kostren"
)

# ---------------------------------------------------------------------------
# Frames — what the story is ABOUT at a given hour. Multi-label; matched on
# title + first 3 000 characters, lower-cased, diacritics kept AND folded.
# Stems, not words: Croatian inflects everything.
# ---------------------------------------------------------------------------
FRAMES <- list(
  operativno = list(
    hr = "Gašenje i vatrogasci", en = "Firefighting",
    rx = "vatrogas|ga[šs]enj|\\bgasi|kanader|air ?tractor|zrakoplov|intervencij|po[žz]ari[šs]t|lokaliziran|pod kontrolom|[šs]iri se|\\bbur[aeu]\\b|vjetar|vjetr|linij[aeu] obrane|dežurstv|dezurstv"),
  evakuacija = list(
    hr = "Evakuacija i promet", en = "Evacuation and traffic",
    rx = "evakuac|evakuir|prihvatn|dvoran|magistral|promet|zatvoren[ai]? za promet|obilaznic|\\bhak\\b|trajekt|brodom|autobus|gripe|ribnjak"),
  zrtve = list(
    hr = "Ozlijeđeni i žrtve", en = "Casualties",
    rx = "ozlije[đd]|pogin|\\bmrtv|smrtno|stradal|\\bkbc\\b|bolnic|respirator|hospitaliz|[žz]ivotno ugro[žz]|intenzivn|hitn[ae] pomo[ćc]|opeklin|dim[au]? |udisanj"),
  steta = list(
    hr = "Šteta i razmjeri", en = "Damage and scale",
    rx = "izgorj|izgorio|izgorje|\\bku[ćc][aeu]\\b|vozil|automobil|\\b[šs]tet[aeu]\\b|uni[šs]ten|hektar|opo[žz]aren|vikendic|objekt[ai]?\\b|krov"),
  politika = list(
    hr = "Političari i institucije", en = "Politics and officials",
    rx = "milanovi[ćc]|plenkovi[ćc]|ministar|ministric|premijer|predsjedni[kc]|\\bvlad[aeu]\\b|gradona[čc]elni|\\b[žz]upan(a|u|om|e|i|ic[aeu])?\\b|bo[žz]inovi[ćc]|sabor|hrsti[ćc]|medved|anu[šs]i[ćc]|oporb|\\bsdp\\b|\\bhdz\\b|\\bmost\\b|mo[žz]emo"),
  uzrok = list(
    hr = "Uzrok i istraga", en = "Cause and investigation",
    rx = "uzrok|istrag|\\bdorh|dr[žz]avn[oa] odvjetni|o[čc]evid|podmetn|pale[žz]|piroman|vje[šs]ta[čc]|kamer[aeu]|namjern|nemar|krivnj|osumnji[čc]|kazn"),
  solidarnost = list(
    hr = "Solidarnost i pomoć", en = "Solidarity and aid",
    rx = "\\bpomo[ćc]|donac|donir|prikuplj|crveni kri[žz]|\\bhck\\b|humanitar|solidarn|volont|obnov|sanacij|zahval|heroj|junak|hrabr|akcij[aeu] prikupljanja"),
  turizam = list(
    hr = "Turisti i sezona", en = "Tourists and season",
    rx = "turist|\\bgost|sezon|apartman|ma[đd]ar|stranac|stranih|strani dr[žz]avljan|kamp\\b|hotel")
)

# Sensational vocabulary — the "temperature" of the language, kept separate from frames.
SENSATIONAL_RX <- "apokalips|\\bpak[ao]o\\b|paklen|katastrof|horor|dram[ae]\\b|dramati[čc]|u[žz]as|strav|nevi[đd]en|kaos|inferno|armagedon|jeziv|[šs]ok(antn|iran)|nezapam[ćc]en|vatren[aeio] stihij|stihij"

# ---------------------------------------------------------------------------
# Outlet typology. A `FROM` value (domain or page name) is assigned the FIRST
# type whose test it passes. Everything is a lookup, so it can be corrected by
# editing this file; the ingest report prints the biggest unclassified sources.
# ---------------------------------------------------------------------------
OUTLET_TYPES <- c(
  sluzbeni   = "Službeni izvori",          # fire service, civil protection, ministries, city, Red Cross
  lokalni    = "Lokalni i regionalni (Dalmacija)",
  nacionalni = "Nacionalni mediji",
  ostali_web = "Ostali web (specijalizirani, regionalni izvan Dalmacije)",
  strani     = "Strani mediji",
  drustveni  = "Društvene mreže i forumi"
)
OUTLET_TYPES_EN <- c(
  sluzbeni = "Official sources", lokalni = "Local & regional (Dalmatia)", nacionalni = "National media",
  ostali_web = "Other web", strani = "Foreign media", drustveni = "Social platforms & forums"
)

OFFICIAL_RX <- "vatrogastvo\\.hr|\\bhvz\\b|(^|\\W)hvz\\.hr|(^|\\W)mup\\.hr|civilna-zastita|gov\\.hr|(^|\\W)omis\\.hr|(^|\\W)dalmacija\\.hr|(^|\\W)vlada\\.|(^|\\W)hck\\.hr|crveni.?kri|dhmz|(^|\\W)hak\\.hr|kbc-split|kbcsplit|\\bdorh\\b|(^|\\W)dzs\\.hr|meteo\\.hr|hgss|\\bhrm\\b|\\bmorh\\b|policij|vatrogasn[aeio] zajednic|vatrogasci hrvatske|\\bdvd\\b|\\bjvp\\b|civilna za[šs]tita"
LOCAL_DALMATIA_RX <- paste(c(
  "slobodnadalmacija", "dalmacijadanas", "dalmatinskiportal", "dalmacijanews", "morski\\.hr", "splitski",
  "ferata", "radio-?split", "radiodalmacija", "makarska", "omi[šs]", "dugirat", "sinj", "imotsk", "trogir",
  "ka[šs]tel", "solin", "hvar", "bra[čc]", "vis\\.hr", "057info", "antenazadar", "ezadar", "zadarski",
  "[šs]ibenik", "sibenik", "tris\\.com", "dubrova[čc]ki", "dubrovacki", "dubrovniknet", "dulist",
  "dubrovnik", "metkovi[ćc]", "plo[čc]e", "neretva", "biokovo", "podstrana", "radio ?omi[šs]",
  "hrt\\.hr/radio-split", "tv ?jadran", "tvjadran", "sd\\.hr", "splitcity", "dalmacij", "dalmatin"
), collapse = "|")
NATIONAL_RX <- paste(c(
  "index\\.hr", "jutarnji", "vecernji", "24sata", "net\\.hr", "tportal", "dnevnik\\.hr", "hrt\\.hr", "rtl\\.hr",
  "telegram\\.hr", "n1info", "hina\\.hr", "novilist", "glas-slavonije", "slobodna-?dalmacija",
  "direktno\\.hr", "narod\\.hr", "dnevno\\.hr", "express\\.hr", "nacional\\.hr", "novosti\\.hr",
  "hrvatska-danas", "priznajem", "maxportal", "poslovni\\.hr", "lider", "story\\.hr", "gloria",
  "vijesti\\.hrt", "danas\\.hr", "zagreb\\.info", "otvoreno\\.hr", "hkm\\.hr", "laudato", "bitno\\.net",
  "ika\\.hkm", "glas-koncila", "hrsvijet", "kamenjar", "sloboda", "sportske", "gol\\.hr", "germanijak",
  "media-?servis", "vijesti\\.hr", "novi ?list", "regionalni\\.com", "aktualno", "srednja\\.hr"
), collapse = "|")
FOREIGN_TLD_RX <- "\\.(rs|ba|si|me|mk|hu|de|at|it|uk|co\\.uk|com\\.au|us|pl|cz|sk|fr|es|nl|be|ch|se|no|dk|fi|ie|ro|bg|gr|tr|ru|ua|al|xk)$"
FOREIGN_NAME_RX <- "sputnik|klix|avaz|oslobodjenje|nezavisne|blic|kurir|telegraf|b92|rts\\.rs|n1info\\.rs|n1info\\.ba|slobodnaevropa|rtvslo|24ur|delo\\.si|siol|dnevnik\\.si|vecer\\.com|index\\.hu|origo|hvg|telex|24\\.hu|portfolio|bild|spiegel|welt|orf\\.at|krone|kleinezeitung|reuters|bbc|guardian|dailymail|euronews|apnews|dw\\.com|nova\\.rs|vijesti\\.me|cdm\\.me|rtcg|hercegovina\\.info|bljesak|dnevnik\\.ba|federalna|radiosarajevo|fokus\\.ba|vecernji\\.ba|jabuka\\.tv|hms\\.ba|poskok|tacno\\.net"

SOCIAL_PLATFORMS <- c("facebook", "twitter", "instagram", "tiktok", "youtube", "reddit", "forum", "comment")

# Geographic ring of the story — the "blast radius". 0 is closest to the fire.
RINGS <- data.table(
  ring = 0:4,
  ring_hr = c("Službeni izvori", "Dalmacija (lokalni)", "Hrvatska (nacionalni i ostali)", "Regija (BA · RS · SI · ME · MK)", "Ostatak svijeta"),
  ring_en = c("Official sources", "Dalmatia (local)", "Croatia (national & other)", "Region (BA · RS · SI · ME · MK)", "Rest of the world")
)
REGION_CC <- c("BA", "RS", "SI", "ME", "MK", "XK")

# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------
fold <- function(x) stri_trans_general(stri_trans_tolower(x), "Latin-ASCII")

# match a stem regex against BOTH the folded and unfolded lower-cased text
rx_hit <- function(text_lc, text_folded, rx) {
  stri_detect_regex(text_lc, rx) | stri_detect_regex(text_folded, rx)
}

hours_since <- function(t, t0 = T0) as.numeric(difftime(t, t0, units = "hours"))

# Croatian number formatting: non-breaking space thousands separator, comma decimals
fmt_hr <- function(x, digits = 0) {
  s <- formatC(round(x, digits), format = "f", digits = digits, big.mark = " ", decimal.mark = ",")
  gsub(" ", " ", s, fixed = TRUE)
}
fmt_pct_hr <- function(x, digits = 1) paste0(fmt_hr(x, digits), " %")

# Croatian numeral agreement for the nouns the story counts. Integers only; decimals take
# the genitive singular ("0,4 sata"). hr_n(51, "objava") -> "51 objava", hr_n(63, "sat") -> "63 sata".
HR_NOUNS <- list(objava = c("objava", "objave", "objava"), izvor = c("izvor", "izvora", "izvora"),
                 sat = c("sat", "sata", "sati"), portal = c("portal", "portala", "portala"), naslov = c("naslov", "naslova", "naslova"))
hr_n <- function(n, noun, digits = 0) {
  f <- HR_NOUNS[[noun]]; if (is.null(f)) stop("unknown noun: ", noun)
  if (digits > 0 || n != round(n)) return(paste(fmt_hr(n, max(digits, 1)), f[2]))
  n <- as.integer(round(n)); m10 <- n %% 10L; m100 <- n %% 100L
  w <- if (m10 == 1L && m100 != 11L) f[1] else if (m10 %in% 2:4 && !(m100 %in% 12:14)) f[2] else f[3]
  paste(fmt_hr(n), w)
}
cap1 <- function(s) paste0(toupper(substr(s, 1, 1)), substr(s, 2, nchar(s)))
HR_MONTHS_GEN <- c("siječnja", "veljače", "ožujka", "travnja", "svibnja", "lipnja", "srpnja", "kolovoza", "rujna", "listopada", "studenoga", "prosinca")
hr_date <- function(t) sprintf("%d. %s %d.", as.integer(format(t, "%d", tz = TZ)), HR_MONTHS_GEN[as.integer(format(t, "%m", tz = TZ))], as.integer(format(t, "%Y", tz = TZ)))

# hour-of-story bins used everywhere (so figures agree)
hour_bin <- function(h, width = 1) floor(h / width) * width

# Sanity gate: refuse to run on nothing
assert_rows <- function(dt, min_rows = 1L, what = "input") {
  if (nrow(dt) < min_rows) stop(sprintf("%s has %d rows (< %d). Nothing to analyse.", what, nrow(dt), min_rows), call. = FALSE)
  invisible(TRUE)
}

# The synthetic flag travels with the data so no output can be mistaken for a finding
is_synthetic <- function(dt) "GROUP_NAME" %in% names(dt) && any(dt$GROUP_NAME == "SYNTHETIC", na.rm = TRUE)
SYNTH_TAG_HR <- "SINTETIČKI PODACI — test pipelinea, ne nalaz"
SYNTH_TAG_EN <- "SYNTHETIC DATA — pipeline test, not a finding"

# Read the vendor export(s): every .xlsx / .csv in input/, bound together
read_vendor_exports <- function(dir = IN_DIR) {
  files <- list.files(dir, pattern = "\\.(xlsx|xls|csv)$", full.names = TRUE, ignore.case = TRUE)
  files <- files[!grepl("^~\\$", basename(files))]
  if (!length(files)) return(NULL)
  parts <- lapply(files, function(f) {
    dt <- if (grepl("\\.csv$", f, ignore.case = TRUE)) {
      fread(f, encoding = "UTF-8", colClasses = "character", na.strings = c("", "NA"))
    } else {
      x <- readxl::read_xlsx(f, col_types = "text", .name_repair = "minimal")
      as.data.table(x)
    }
    dt[, .source_file := basename(f)]
    dt
  })
  rbindlist(parts, fill = TRUE, use.names = TRUE)
}
