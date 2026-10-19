# Croatian agreement for generated numbers, for the website.
#
# Every headline figure on the site is computed, never typed, so the noun after it cannot be typed
# either: 9 platforms wants "vrsta", 2 wants "vrste", 54 wants "stupca" and 47 wants "stupaca". The
# count changes whenever the data is refreshed, so hand-written nouns silently go wrong. Use
# digikat_hr_count() wherever a number is followed by a noun in reader-visible prose.
#
# The annual report carries the same logic locally (ar_plural_hr / ar_noun_hr in
# studies/annual-report/report_lib.R). That copy stays where it is: an edition is frozen once
# published and must not shift because a shared helper changed under it.
#
# Adjective and verb agreement are NOT handled. Phrase around them.
#   good: "Na 56 izvora otpada polovica"      bad: "56 izvora čini polovicu"

# n / forms = c(<uz 1>, <uz 2-4>, <uz 5+>). Croatian: 11-14 always take the 5+ form.
digikat_hr_plural <- function(n, forms) {
  if (length(forms) != 3L) stop("A Croatian noun needs three forms (1 / 2-4 / 5+).", call. = FALSE)
  n <- abs(as.integer(round(as.numeric(n))))
  last_two <- n %% 100L
  last <- n %% 10L
  if (last_two >= 11L && last_two <= 14L) return(forms[3])
  if (last == 1L) return(forms[1])
  if (last >= 2L && last <= 4L) return(forms[2])
  forms[3]
}

# The nouns the site counts. Keyed by the singular, so a page reads digikat_hr_count(n, "objava").
# Add a noun here rather than inlining forms at a call site.
DIGIKAT_NOUN_HR <- list(
  objava    = c("objava", "objave", "objava"),
  članak    = c("članak", "članka", "članaka"),
  tjedan    = c("tjedan", "tjedna", "tjedana"),
  mjesec    = c("mjesec", "mjeseca", "mjeseci"),
  izvor     = c("izvor", "izvora", "izvora"),
  stupac    = c("stupac", "stupca", "stupaca"),
  redak     = c("redak", "retka", "redaka"),
  znak      = c("znak", "znaka", "znakova"),
  vrsta     = c("vrsta", "vrste", "vrsta"),
  platforma = c("platforma", "platforme", "platformi"),
  kategorija = c("kategorija", "kategorije", "kategorija"),
  pojam     = c("pojam", "pojma", "pojmova"),
  dokument  = c("dokument", "dokumenta", "dokumenata"),
  godina    = c("godina", "godine", "godina"),
  dan       = c("dan", "dana", "dana"),
  medij     = c("medij", "medija", "medija"),
  akter     = c("akter", "aktera", "aktera"),
  profil    = c("profil", "profila", "profila")
)

digikat_hr_noun <- function(n, noun) {
  forms <- DIGIKAT_NOUN_HR[[noun]]
  if (is.null(forms)) {
    stop("No Croatian forms registered for the noun '", noun,
         "'. Add it to DIGIKAT_NOUN_HR in R/lib/digikat_hr.R.", call. = FALSE)
  }
  digikat_hr_plural(n, forms)
}

# The pairing a sentence almost always wants: the Croatian-formatted count and its agreeing noun.
# Needs digikat_hr_int() from R/lib/digikat_paths.R.
digikat_hr_count <- function(n, noun) paste(digikat_hr_int(n), digikat_hr_noun(n, noun))

# Reader-visible platform labels. Raw SOURCE_TYPE keys are code identifiers and must never reach
# prose; this is the one place they are translated.
DIGIKAT_PLATFORM_HR <- c(
  web = "web-portali", youtube = "YouTube", facebook = "Facebook", twitter = "Twitter / X",
  reddit = "Reddit", forum = "forumi", instagram = "Instagram",
  comment = "komentari", tiktok = "TikTok"
)

digikat_platform_hr <- function(x) {
  out <- unname(DIGIKAT_PLATFORM_HR[as.character(x)])
  ifelse(is.na(out), as.character(x), out)
}

# Croatian list joining: "a, b i c". For reader-visible enumerations built from data.
digikat_hr_list <- function(x) {
  x <- as.character(x)
  if (length(x) == 0L) return("")
  if (length(x) == 1L) return(x)
  paste0(paste(utils::head(x, -1), collapse = ", "), " i ", utils::tail(x, 1))
}

DIGIKAT_MONTH_HR_GENITIVE <- c(
  "siječnja", "veljače", "ožujka", "travnja", "svibnja", "lipnja",
  "srpnja", "kolovoza", "rujna", "listopada", "studenoga", "prosinca"
)

digikat_hr_date <- function(x) {
  x <- as.Date(x)
  if (length(x) != 1L || is.na(x)) return(NA_character_)
  paste0(
    as.integer(format(x, "%d")), ". ",
    DIGIKAT_MONTH_HR_GENITIVE[as.integer(format(x, "%m"))], " ",
    format(x, "%Y"), "."
  )
}

# Generic lemmas that dominate any Croatian frequency list without saying anything about the
# subject: quantifiers and pronouns (sav, sam, mnogi), ordinals, size and time words, title
# abbreviations, and the commonest reporting and auxiliary verbs. Display-only. Word charts
# drop them so that a ranking shows vocabulary, never used to filter the corpus.
DIGIKAT_GENERIC_LEMMAS <- c(
  "sav", "sam", "svoj", "mnogi", "mnog", "neki", "svaki", "takav", "isti", "ovaj", "taj", "onaj",
  "jedan", "prvi", "drugi", "treći", "posljednji", "zadnji", "nov", "novi", "star", "velik",
  "veći", "mali", "cijel", "važan", "brojan", "dobar", "poseban",
  "sv.", "dr.", "fra", "mons.", "prof.", "don", "o.",
  "godina", "dan", "sat", "put", "način", "dio", "broj", "vrijeme", "mjesto", "trenutak",
  "tjedan", "mjesec", "kraj", "početak", "čovjek", "osoba", "ime", "stvar", "primjer", "slučaj",
  "biti", "imati", "moći", "htjeti", "trebati", "morati", "reći", "kazati", "činiti", "učiniti",
  "postojati", "značiti", "dolaziti", "doći", "voditi", "tražiti", "istaknuti", "objaviti",
  "održati", "dati", "uzeti", "vidjeti", "znati", "ostati", "postati", "nalaziti", "govoriti"
)

digikat_is_generic_lemma <- function(lemma) {
  # stringi, not base tolower(): base errors on stray noncharacters in corpus text.
  stringi::stri_trans_tolower(lemma) %in% DIGIKAT_GENERIC_LEMMAS |
    !grepl("^\\p{L}[\\p{L}-]*$", lemma, perl = TRUE)
}
