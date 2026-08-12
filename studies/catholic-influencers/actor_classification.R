# Study-local actor classifier recovered from Katolicki_Influenceri commit fa34ff5 and made
# source-consistent. It returns a rule and confidence so platform-dependent heuristic assignments
# can be excluded in robustness checks.

manual_overrides <- list(
  "Institutional Official" = c(
    "hrvatska biskupska konferencija", "tiskovni ured hbk", "hrvatska katolička mreža",
    "hrvatska katolicka mreza", "informativna katolička agencija",
    "informativna katolicka agencija", "hrvatski katolički radio",
    "hrvatski katolicki radio", "radio marija", "radiomarija", "caritas"
  ),
  "Independent Media" = c(
    "laudato tv", "laudatotv", "laudato.tv", "laudato.hr", "bitno.net", "glas koncila",
    "glaskoncila", "nova eva", "nova-eva", "verbum", "kršćanska sadašnjost",
    "krscanska sadasnjost", "katolički tjednik", "katolicki tjednik", "svjetlo riječi",
    "svjetlo rijeci", "novizivot.net", "novi zivot", "novi život", "totus tuus",
    "katolik.hr", "živo vrelo", "zivo vrelo"
  ),
  "Charismatic Communities" = c(
    "božja pobjeda", "bozja pobjeda", "bozjapobjeda", "muževni budite",
    "muzevni budite", "muzevnibudite", "cenacolo", "zajednica cenacolo",
    "srce isusovo", "srceisuovo", "molitvena zajednica", "molitvena snaga",
    "dom molitve", "karizmatska obnova", "neokatekumenat", "fokolari", "focolare",
    "emmanuel", "cursillo"
  ),
  "Lay Influencers" = c(
    "katolička obitelj", "katolicka obitelj", "marija majka isusova", "božanske molitve",
    "bozanske molitve", "moćne molitve", "mocne molitve", "katoličke molitve",
    "katolicke molitve", "hrana za dušu", "hrana za dusu", "dijete vjere",
    "kapljice ljubavi božje", "kapljice ljubavi bozje", "jutarnja molitva duhu svetom",
    "blago molitve", "biblija krunice molitve", "molitve bogu",
    "duhovne poruke i inspiracija", "duhovni kutak", "vojnik sreće", "vojnik srece",
    "pulherissimus", "pod smokvom", "molitva dana", "riječ dana", "rijec dana",
    "evanđelje dana", "evandelje dana", "svetac dana", "katolička inspiracija",
    "duhovne misli", "put vjere", "život u kristu", "katolička mama", "obitelj i vjera",
    "mladi katolici", "isus te voli", "bog te voli", "dobro jutro s bogom"
  ),
  "Diocesan" = c(
    "zagrebačka nadbiskupija", "zagrebacka nadbiskupija", "splitsko-makarska nadbiskupija",
    "riječka nadbiskupija", "rijecka nadbiskupija", "đakovačko-osječka nadbiskupija",
    "djakovacko-osjecka nadbiskupija", "zadarska nadbiskupija", "sisačka biskupija",
    "sisacka biskupija", "varaždinska biskupija", "varazdinska biskupija",
    "bjelovarsko-križevačka biskupija", "gospićko-senjska biskupija",
    "porečko-pulska biskupija", "krčka biskupija", "dubrovačka biskupija",
    "dubrovacka biskupija", "šibenska biskupija", "sibenska biskupija",
    "hvarska biskupija", "požeška biskupija", "križevačka eparhija", "vojni ordinarijat"
  ),
  "Youth Organizations" = c(
    "susret hrvatske katoličke mladeži", "susret hrvatske katolicke mladezi", "shkm",
    "frama", "katolička akcija", "katolicka akcija", "sveučilišna kapelanija",
    "studentska kapelanija", "pastoral mladih", "ministranti", "salezijanska mladež"
  ),
  "Academic" = c(
    "hrvatsko katoličko sveučilište", "hrvatsko katolicko sveuciliste", "unicath",
    "katolički bogoslovni fakultet", "katolicki bogoslovni fakultet",
    "teologija u rijeci", "teologija u splitu", "teologija u đakovu",
    "filozofski fakultet družbe isusove", "ffrz", "bogoslovija", "sjemenište"
  ),
  "Religious Orders" = c(
    "franjevci", "franjevački", "franjevacki", "mala braća", "kapucini", "kapucinski",
    "isusovci", "isusovački", "isusovacki", "družba isusova", "druzba isusova",
    "dominikanci", "dominikanski", "salezijanci", "salezijanski", "don bosco",
    "karmelićani", "karmelicani", "benediktinci", "benediktinski", "pavlini",
    "pavlinski", "trapisti", "augustinci", "lazaristi", "vincencijanci", "časne sestre",
    "casne sestre", "dominikanke", "franjevke", "karmelićanke", "milosrdnice",
    "školske sestre", "uršulinke", "ursulinke", "klarise", "služavke malog isusa",
    "klanjateljice"
  )
)

secular_exclusions <- c(
  "slobodnadalmacija", "vecernji", "jutarnji", "24sata", "index.hr", "net.hr",
  "tportal", "dnevnik.hr", "novilist", "telegram.hr", "rtl.hr", "n1info", "nova tv",
  "novatv", "direktno.hr", "nacional", "dnevno.hr", "7dnevno", "story.hr",
  "gloria.hr", "glas slavonije", "glas istre", "zadarski list", "dubrovački vjesnik",
  "hkv.hr", "narod.hr", "maxportal", "forum.hr", "reddit", "anonymous_user", "wikipedia",
  "turistička zajednica", "turisticka zajednica", "demokratska zajednica"
)

contains_any <- function(text, patterns) {
  any(vapply(patterns, function(pattern) grepl(pattern, text, fixed = TRUE), logical(1)))
}

classify_actor_source <- function(from_value, url_context = "", has_social = FALSE) {
  from_lower <- tolower(trimws(as.character(from_value)))
  combined <- paste(from_lower, tolower(url_context))

  for (actor_type in names(manual_overrides)) {
    if (contains_any(from_lower, manual_overrides[[actor_type]])) {
      return(list(actor_type = actor_type, rule = paste0("manual_", actor_type), confidence = "high"))
    }
  }

  if (from_lower %in% c("hbk", "ika", "hkm", "hkr")) {
    return(list(actor_type = "Institutional Official", rule = "official_acronym", confidence = "high"))
  }
  if (from_lower %in% c("hks", "kbf")) {
    return(list(actor_type = "Academic", rule = "academic_acronym", confidence = "high"))
  }

  if (contains_any(combined, secular_exclusions)) {
    return(list(actor_type = "Other", rule = "secular_exclusion", confidence = "high"))
  }

  if (grepl("biskupij|nadbiskupij|eparhij|ordinarijat|(^|[^[:alpha:]])(župa|zupa)([^[:alpha:]]|$)|župna|zupna", from_lower)) {
    return(list(actor_type = "Diocesan", rule = "diocesan_pattern", confidence = "high"))
  }
  if (grepl("franjev|isusov|dominikan|salezijan|karmel|benediktin|kapucin|redovnic|klaris|uršulink", from_lower)) {
    return(list(actor_type = "Religious Orders", rule = "order_pattern", confidence = "medium"))
  }
  if (grepl("(^|[[:space:]])(fra|don|vlč\\.|vlc\\.|msgr\\.|mons\\.|pater)[[:space:]]", from_lower)) {
    return(list(actor_type = "Individual Priests", rule = "priest_prefix", confidence = "high"))
  }
  if (grepl("molitven|karizmat|duhovn.*obnov|zajednic", from_lower)) {
    return(list(actor_type = "Charismatic Communities", rule = "community_pattern", confidence = "medium"))
  }
  devotional_name_pattern <- paste0(
    "(^|[^[:alpha:]])(",
    "vjera|molitv[[:alpha:]]*|isus[[:alpha:]]*|krist($|[^[:alpha:]])|krista|kristu|kristom|kristov[[:alpha:]]*|",
    "gospa|sveti($|[^[:alpha:]])|sveta($|[^[:alpha:]])|svetac|evanđelj[[:alpha:]]*|evandelj[[:alpha:]]*|",
    "duhovn[[:alpha:]]*|biblij[[:alpha:]]*|krunic[[:alpha:]]*|rozarij[[:alpha:]]*",
    ")"
  )
  if (isTRUE(has_social) &&
      grepl(devotional_name_pattern, from_lower, perl = TRUE) &&
      !grepl("\\.hr|\\.net|\\.com|portal|vijesti|news|radio|tv|agencija|biskupij|nadbiskupij|fakultet|sveučilište", from_lower)) {
    return(list(actor_type = "Lay Influencers", rule = "social_devotional_pattern", confidence = "low"))
  }

  list(actor_type = "Other", rule = "unclassified", confidence = "low")
}
