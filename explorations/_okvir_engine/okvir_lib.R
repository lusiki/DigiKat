# Shared analytical engine for the „Okvir katoličanstva” report family.
#
# This file contains definitions and computations that must remain identical
# across the flagship and its narrower companion reports. Callers own their
# universes, aggregation tables, prose and public assets.

if (!exists("digikat_thematic_dictionaries", inherits = TRUE)) {
  source(file.path("R", "lib", "thematic_dictionaries.R"), encoding = "UTF-8")
}

say <- function(...) {
  cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n")
  flush.console()
}

normalise_key <- function(x) {
  x <- tolower(trimws(as.character(x)))
  sub("^www[.]", "", x)
}

safe_numeric <- function(x) {
  out <- suppressWarnings(as.numeric(x))
  out[!is.finite(out)] <- NA_real_
  out
}

normalise_share <- function(x) {
  x <- as.numeric(x)
  x[!is.finite(x) | x < 0] <- 0
  total <- sum(x)
  if (total <= 0) return(rep(0, length(x)))
  100 * x / total
}

wilson <- function(k, n, z = 1.96) {
  if (!is.finite(n) || n <= 0) return(c(NA_real_, NA_real_))
  p <- k / n
  den <- 1 + z^2 / n
  centre <- (p + z^2 / (2 * n)) / den
  half <- z * sqrt((p * (1 - p) + z^2 / (4 * n)) / n) / den
  c(centre - half, centre + half)
}

fmt_decimal <- function(x, digits = 2, signed = FALSE) {
  if (!is.finite(x)) return("nema procjene")
  value <- formatC(abs(x), format = "f", digits = digits, decimal.mark = ",")
  if (!signed) return(value)
  if (abs(x) < 0.5 * 10^(-digits)) return(formatC(0, format = "f", digits = digits, decimal.mark = ","))
  paste0(if (x > 0) "+" else "−", value)
}

fmt_slope <- function(est, unit = "", digits = 2) {
  suffix <- if (nzchar(unit)) paste0(" ", unit) else ""
  paste0(
    fmt_decimal(est[["estimate"]], digits, TRUE), suffix,
    " [", fmt_decimal(est[["lower"]], digits, TRUE), "; ",
    fmt_decimal(est[["upper"]], digits, TRUE), "]"
  )
}

json_escape <- function(x) {
  x <- enc2utf8(as.character(x))
  x <- gsub("\\\\", "\\\\\\\\", x, fixed = TRUE)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  x <- gsub("\r", "\\r", x, fixed = TRUE)
  x <- gsub("\n", "\\n", x, fixed = TRUE)
  x <- gsub("\t", "\\t", x, fixed = TRUE)
  paste0('"', x, '"')
}

to_json <- function(x) {
  if (is.null(x)) return("null")
  if (inherits(x, "Date") || inherits(x, "POSIXt")) return(to_json(as.character(x)))
  if (is.data.frame(x)) {
    rows <- lapply(seq_len(nrow(x)), function(i) as.list(x[i, , drop = FALSE]))
    return(to_json(rows))
  }
  if (is.list(x)) {
    if (!length(x)) return("[]")
    nm <- names(x)
    if (!is.null(nm) && all(nzchar(nm))) {
      pairs <- Map(function(key, value) paste0(json_escape(key), ":", to_json(value)), nm, x)
      return(paste0("{", paste(unlist(pairs, use.names = FALSE), collapse = ","), "}"))
    }
    return(paste0("[", paste(vapply(x, to_json, character(1)), collapse = ","), "]"))
  }
  if (length(x) > 1L) return(paste0("[", paste(vapply(as.list(x), to_json, character(1)), collapse = ","), "]"))
  if (length(x) == 0L || is.na(x)) return("null")
  if (is.logical(x)) return(if (isTRUE(x)) "true" else "false")
  if (is.numeric(x) || is.integer(x)) {
    if (!is.finite(x)) return("null")
    return(format(x, scientific = FALSE, trim = TRUE, digits = 15))
  }
  json_escape(x)
}

write_analysis_js <- function(object, path, variable = "ANALYSIS_RESULTS") {
  writeLines(
    c('"use strict";', paste0("window.", variable, " = ", to_json(object), ";")),
    path,
    useBytes = TRUE
  )
  invisible(path)
}

actor_definitions <- list(
  official = list(
    label = "Crkveni mediji i ustanove",
    short = "Crkveni izvori",
    color = "#0f4c5c",
    dash = ""
  ),
  independent = list(
    label = "Katolički mediji drugih osnivača",
    short = "Drugi katolički mediji",
    color = "#2f8f6b",
    dash = "8 3"
  ),
  creator = list(
    label = "Pastoralni i vjerski kanali i stvaratelji",
    short = "Vjerski stvaratelji",
    color = "#c47b21",
    dash = "2 3"
  ),
  public = list(
    label = "Ostali mediji i javni izvori",
    short = "Ostali javni izvori",
    color = "#2f73b8",
    dash = "10 3 2 3"
  )
)
actors <- unname(Map(function(key, value) c(list(key = key), value), names(actor_definitions), actor_definitions))
actor_levels <- names(actor_definitions)
actor_labels <- vapply(actor_definitions, `[[`, character(1), "label")

frame_definitions <- list(
  devotional = list(label = "Duhovno-liturgijski", short = "Duhovno-liturgijski", color = "#2f8f6b"),
  institutional = list(label = "Institucionalno-administrativni", short = "Institucijski", color = "#5e7488"),
  identity = list(label = "Kulturno-identitetski", short = "Identitetski", color = "#c47b21"),
  political = list(label = "Politički antagonistički", short = "Politički", color = "#3f4fa0"),
  conflict = list(label = "Sukob i skandal", short = "Sukob i skandal", color = "#b5462f")
)
frames <- unname(Map(function(key, value) c(list(key = key), value), names(frame_definitions), frame_definitions))
frame_levels <- names(frame_definitions)
frame_labels <- vapply(frame_definitions, `[[`, character(1), "label")

# The public report uses the canonical 16-category DigiKat dictionary collapsed
# into six reader-facing themes. The older five-frame vocabulary remains an
# internal scoring instrument only, for the sharp / not-sharp split and I3.
theme_map <- data.table::data.table(
  category = names(digikat_thematic_dictionaries),
  theme = c(
    "faith", "faith",
    "institution", "institution", "institution", "institution",
    "public_questions", "public_questions", "community",
    "history_culture", "public_questions", "history_culture", "community",
    "abuse", "public_questions", "community"
  )
)
theme_labels <- c(
  faith = "Vjera i duhovni život",
  institution = "Crkveno vodstvo i Sveta Stolica",
  public_questions = "Javna pitanja i prijepori",
  community = "Služenje, mladi i dijalog",
  history_culture = "Povijest i kultura",
  abuse = "Zlostavljanje i kriza povjerenja"
)
theme_colors <- c(
  faith = "#2f8f6b",
  institution = "#55768c",
  public_questions = "#c47b21",
  community = "#5b8a72",
  history_culture = "#846d9b",
  abuse = "#b5462f"
)
category_labels <- c(
  DUHOVNOST_I_LITURGIJA = "Duhovnost i liturgija",
  TEOLOGIJA_I_DOKTRINA = "Teologija i nauk",
  CRKVENO_UPRAVLJANJE_I_STRUKTURA = "Crkveno upravljanje i ustroj",
  PAPE_I_VATIKAN = "Pape i Vatikan",
  CRKVENE_FINANCIJE_I_IMOVINA = "Crkvene financije i imovina",
  GLOBALNA_CRKVA_I_MISIJE = "Globalna Crkva i misije",
  POLITIKA_I_ODNOS_S_DRZAVOM = "Politika i odnos s državom",
  BIOETIKA_I_KULTURNI_RATOVI = "Bioetika i kulturni prijepori",
  KARITAS_I_SOCIJALNA_PRAVDA = "Karitas i socijalna pravda",
  POVIJEST_I_NACIONALNI_IDENTITET = "Povijest i nacionalni identitet",
  ZNANOST_I_VJERA = "Znanost i vjera",
  MEDIJI_UMJETNOST_I_KULTURA = "Mediji, umjetnost i kultura",
  DIGITALNA_EVANGELIZACIJA_I_MLADI = "Digitalna evangelizacija i mladi",
  ZLOSTAVLJANJE_I_KRIZA_POVJERENJA = "Zlostavljanje i kriza povjerenja",
  UNUTARCRKVENI_PRIJEPORI_I_IDEOLOGIJE = "Unutarcrkveni prijepori i ideologije",
  ODNOS_S_DRUGIM_RELIGIJAMA_I_POGLEDIMA = "Odnos s drugim religijama i pogledima"
)
theme_levels <- names(theme_labels)

if (!setequal(theme_map$category, names(category_labels))) {
  stop("Theme collapse and category labels do not cover the same categories.", call. = FALSE)
}

source_labels <- data.table::fread(
  file.path("resources", "dictionaries", "source_labels.csv"),
  encoding = "UTF-8",
  na.strings = c("", "NA")
)
source_labels[, key := normalise_key(from)]
source_labels <- unique(source_labels, by = "key")

source_registry_path <- file.path("explorations", "okvir-katolicanstva-prototype", "source-groups.csv")
if (!file.exists(source_registry_path)) {
  stop("Shared source registry was not found: ", source_registry_path, call. = FALSE)
}
source_registry <- data.table::fread(source_registry_path, encoding = "UTF-8", na.strings = c("", "NA"))
source_registry[, key := normalise_key(from)]
if (anyDuplicated(source_registry$key)) {
  stop("source-groups.csv contains duplicate normalized source names.", call. = FALSE)
}
if (any(!source_registry$actor_group %in% actor_levels)) {
  stop("source-groups.csv contains an unsupported actor_group.", call. = FALSE)
}

official_pattern <- paste(c(
  "(^|[.])hkm[.]hr$", "ika[.]hkm", "(^|[.])ika[.]hr$", "glas[-.]?koncila",
  "(^|[.])hkr[.]hr$", "(^|[.])caritas[.]hr$", "ktabkbih", "hbk[.]hr",
  "biskupij", "nadbiskupij", "ordinarijat", "eparhij", "redovnistvo",
  "franjev[acčk]", "isusovci", "isusovačk", "druzba.?isusova", "družba.?isusova",
  "dominikan", "salezijan", "karmel(?!ina)", "kapucin", "bazilika",
  "benediktin", "(^|[.])ofm", "djos[.]hr", "smn[.]hr", "ssmi[.]hr",
  "(^|[.])ks[.]hr$", "krscanska.?sadasnjost", "kršćanska.?sadašnjost",
  "svjetlo.?rijeci", "svjetlo.?riječi", "(^|[.])veritas[.]hr$",
  "katolicki.?tjednik", "katolički.?tjednik",
  "katoličk[[:alpha:]]*[ ._-]*tiskovn[[:alpha:]]*[ ._-]*agenc",
  "katoličk[[:alpha:]]*.*bogoslovn[[:alpha:]]*.*fakultet",
  "nedjelja.?ba", "unicath", "(^|[.])kbf",
  "hrvatsko.?katolicko.?sveuciliste", "hrvatsko katoličko sveučilište"
), collapse = "|")
independent_pattern <- paste(c(
  "^laudato([ ._-]?tv)?$", "(^|[.])laudato[.]hr$", "bitno[.]net",
  "radio.?marija", "vjera.?i.?djela",
  "vjeraidjela", "radio[-.]?medjugorje", "katolik[.]hr", "antemurale"
), collapse = "|")
creator_pattern <- paste(c(
  "(^|[. _-])zupa([. _-]|$)", "^zupa(?!n)",
  "(^|[[:space:]])žup(a|e|i|ni|na|no)([[:space:]]|$)",
  "novizivot[.]net", "nova.?eva", "pod.?smokvom", "hrana.?za.?dusu",
  "dijete.?vjere", "stopama.?padre.?pija", "bozanska.?ljubav", "budifrajer",
  "vjera.?u.?nama", "kraljica.?mira", "majko.?marijo", "molitv", "krunic",
  "gospa(?!r)", "bozja.?pobjeda", "srce.?isusovo", "mladifest", "shkm2026",
  "poslanik[.]gospodina", "pulherissimus", "duhovn", "isus", "krist(?!ijan)", "svjedocanstv",
  "svjedočanstv", "prihvati.?isusa", "omnia.?deo", "slavimo.?boga", "vjeronauk",
  "muzevni.?budite", "muževni.?budite", "duhos", "kursiljo", "cursillo",
  "skac[.]hr", "tabor[.]hr", "40.?dana.?za.?zivot", "40.?dana.?za.?život",
  "kršć", "krsc", "katoli", "crkva", "biblij", "evanđ", "evand",
  "vjera", "vjere", "vjeru", "vjerni", "vjerujem", "pastoral", "hodo",
  "misionar", "svetiste", "svetište", "sveto.?pismo", "duha.?svet",
  "^sveti.?ante$", "^sveti.?franjo", "svet[ae].?pjes",
  "(^|[^[:alpha:]])(bog|boga|bogu|bogom|božj[[:alpha:]]*|bozj[[:alpha:]]*)([^[:alpha:]]|$)"
), collapse = "|")

classify_actor_details <- function(from) {
  key <- normalise_key(from)
  source_label <- source_labels$label[match(key, source_labels$key)]
  source_label[is.na(source_label)] <- ""
  out <- rep("public", length(key))
  rule <- rep("other_public_default", length(key))
  rule[source_label == "secular"] <- "catalogue_secular"
  out[source_label == "confessional"] <- "creator"
  rule[source_label == "confessional"] <- "catalogue_confessional"

  creator <- grepl(creator_pattern, key, perl = TRUE)
  out[creator] <- "creator"
  rule[creator] <- "pastoral_or_creator_pattern"
  independent <- grepl(independent_pattern, key, perl = TRUE)
  out[independent] <- "independent"
  rule[independent] <- "independent_identity_pattern"
  official <- grepl(official_pattern, key, perl = TRUE)
  out[official] <- "official"
  rule[official] <- "church_institution_pattern"

  registry_match <- match(key, source_registry$key)
  checked <- !is.na(registry_match)
  out[checked] <- source_registry$actor_group[registry_match[checked]]
  rule[checked] <- "checked_registry"
  data.table::data.table(actor_group = out, actor_rule = rule)
}

classify_actor <- function(from) classify_actor_details(from)$actor_group

platform_group <- function(x) {
  x <- tolower(as.character(x))
  ifelse(x == "web", "web",
    ifelse(x == "facebook", "facebook",
      ifelse(x == "youtube", "video", "other")
    )
  )
}

period_id <- function(date) {
  date <- as.Date(date)
  year <- as.integer(format(date, "%Y"))
  half <- ifelse(as.integer(format(date, "%m")) <= 6L, 1L, 2L)
  paste0(year, "H", half)
}

era_id <- function(date) {
  ifelse(as.Date(date) < as.Date("2024-07-01"), "2021.–2023.", "2024. 2. pol.–2026. 1. pol.")
}

display_period <- function(date) {
  date <- as.Date(date)
  year <- as.integer(format(date, "%Y"))
  ifelse(year == 2026L, "2026. do lipnja", paste0(year, "."))
}

frame_terms <- list(
  devotional = c(
    "molitv", "mis(a|e|u|om|ama)?([^[:alpha:]]|$)", "euharist", "liturgij", "sakrament",
    "hodočaš", "krunic", "blagdan", "svetkovin", "advent", "korizm", "evanđelj",
    "propovijed", "blagoslov", "klanjanj", "duhovn[[:space:]-]*(obnov|vježb)"
  ),
  institutional = c(
    "biskup", "nadbiskup", "kardinal", "(^|[^[:alpha:]])hbk([^[:alpha:]]|$)", "vatikan",
    "sveta[[:space:]]+stolica", "papa", "žup", "svećen", "imenovan", "dekret", "priopćenj",
    "financij", "imovin", "ugovor", "sinod", "dikasterij", "biskupija", "institucij"
  ),
  identity = c(
    "identitet", "nacionaln", "domovin", "domoljub", "hrvatsk", "tradicij", "baštin",
    "povijest", "stepinac", "branitelj", "vukovar", "bleiburg", "komuniz", "jugoslav",
    "obiteljsk[[:space:]-]*vrijednost", "kršćansk[[:space:]-]*vrijednost", "kulturn[[:space:]-]*naslje"
  ),
  conflict = c(
    "zlostavlj", "pedofil", "seksualn[[:space:]-]*(nasil|zlostavlj)", "skandal", "prikrivan",
    "afer(a|e|u|om|ama)?([^[:alpha:]]|$)", "optuž", "presud", "tužb", "istrag",
    "sukob", "raskol", "svađ", "kontroverz", "kriza[[:space:]-]*povjeren"
  )
)
political_topic_terms <- c(
  "politi", "vlada", "strank", "(^|[^[:alpha:]])hdz([^[:alpha:]]|$)",
  "(^|[^[:alpha:]])sdp([^[:alpha:]]|$)", "sabor", "zakon", "izbor", "milanović", "plenković",
  "pobačaj", "abortus", "(^|[^[:alpha:]])lgbt([^[:alpha:]]|$)", "rodn[[:space:]-]*ideolog",
  "istospoln", "eutanazij", "migrant", "brisel", "europsk[[:space:]-]*(unij|komis)"
)
antagonism_terms <- c(
  "neprijatelj", "izdaj", "nametan", "diktat", "cenzur", "propagand", "manipul",
  "zavjer", "skriven[[:space:]-]*(agenda|plan)", "globalist", "dubok[[:space:]-]*držav",
  "korumpiran", "lažu", "lažn[[:space:]-]*vijest", "medijsk[[:space:]-]*mrak", "jednouml",
  "ugrož", "napad[[:space:]-]*na", "progon[[:space:]-]*(kršć|vjern)", "totalitar",
  "kultur(a|e)[[:space:]-]*smrti", "relativizam", "woke", "protivnik"
)

make_pattern <- function(terms) paste0("(", paste(terms, collapse = "|"), ")")

count_pattern <- function(text, terms) {
  hits <- gregexpr(make_pattern(terms), text, perl = TRUE, useBytes = FALSE)
  lengths(regmatches(text, hits))
}

score_frames <- function(title, full_text, text_limit = 3000L) {
  analysis_text <- tolower(paste(
    ifelse(is.na(title), "", title),
    substr(ifelse(is.na(full_text), "", full_text), 1L, text_limit)
  ))
  scores <- vapply(frame_terms, function(terms) count_pattern(analysis_text, terms), integer(length(analysis_text)))
  political_topic_count <- count_pattern(analysis_text, political_topic_terms)
  antagonism_count <- count_pattern(analysis_text, antagonism_terms)
  political_score <- ifelse(
    (political_topic_count > 0L & antagonism_count > 0L) | antagonism_count >= 2L,
    political_topic_count + antagonism_count,
    0L
  )
  scores <- cbind(
    devotional = scores[, "devotional"],
    institutional = scores[, "institutional"],
    identity = scores[, "identity"],
    political = political_score,
    conflict = scores[, "conflict"]
  )
  tiebreak <- sweep(scores, 2L, seq(0, 0.04, length.out = ncol(scores)), "+")
  has_frame <- rowSums(scores) > 0L
  data.table::data.table(
    primary_frame = ifelse(has_frame, frame_levels[max.col(tiebreak, ties.method = "first")], "unknown"),
    frame_score = ifelse(has_frame, apply(scores, 1L, max), 0L)
  )
}

sharp_frame <- function(primary_frame) {
  as.character(primary_frame) %in% c("political", "conflict")
}

# Assign one canonical category per row and keep the row-level result private.
# text_dt must contain row_id and text. The fingerprint is supplied by the
# caller so it can include the corpus and dictionary hashes as well as its row
# universe. A valid cache is reused byte-for-byte.
classify_themes <- function(text_dt, cache_dir, fingerprint) {
  if (!requireNamespace("stringi", quietly = TRUE)) {
    stop("Package 'stringi' is required for theme classification.", call. = FALSE)
  }
  text_dt <- data.table::as.data.table(text_dt)
  if (!all(c("row_id", "text") %in% names(text_dt))) {
    stop("Theme input must contain row_id and text.", call. = FALSE)
  }
  if (anyDuplicated(text_dt$row_id)) {
    stop("Theme input row_id values must be unique.", call. = FALSE)
  }
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  cache_path <- file.path(cache_dir, "theme_rows.rds")
  manifest_path <- file.path(cache_dir, "theme_manifest.json")

  use_cache <- FALSE
  if (file.exists(cache_path) && file.exists(manifest_path)) {
    old_manifest <- jsonlite::read_json(manifest_path, simplifyVector = TRUE)
    use_cache <- identical(old_manifest$fingerprint, fingerprint)
  }
  if (use_cache) {
    say("Reusing private theme cache", cache_path)
    rows <- data.table::as.data.table(readRDS(cache_path))
    if (!identical(as.character(rows$row_id), as.character(text_dt$row_id))) {
      stop("Private theme cache row identifiers do not match its fingerprint.", call. = FALSE)
    }
    return(rows)
  }

  patterns <- vapply(
    digikat_thematic_dictionaries,
    function(terms) paste0("(", paste(tolower(terms), collapse = "|"), ")"),
    character(1)
  )
  chunk_starts <- seq.int(1L, nrow(text_dt), by = 25000L)
  category <- rep("not_recognised", nrow(text_dt))
  for (chunk_index in seq_along(chunk_starts)) {
    start <- chunk_starts[[chunk_index]]
    end <- min(start + 24999L, nrow(text_dt))
    say("Theme chunk", chunk_index, "of", length(chunk_starts), "| rows", start, "to", end)
    text <- tolower(text_dt$text[start:end])
    scores <- vapply(patterns, function(pattern) {
      values <- stringi::stri_count_regex(text, pattern)
      values[is.na(values)] <- 0L
      as.integer(values)
    }, integer(length(text)))
    has_theme <- rowSums(scores) > 0L
    if (any(has_theme)) {
      selected <- (start:end)[has_theme]
      category[selected] <- names(patterns)[
        max.col(scores[has_theme, , drop = FALSE], ties.method = "first")
      ]
    }
  }
  rows <- text_dt[, .(row_id)]
  rows[, category := category]
  saveRDS(rows, cache_path)
  digikat_write_json_atomic(list(
    fingerprint = fingerprint,
    rows = nrow(rows),
    disclosure = "row identifiers and computed canonical category only"
  ), manifest_path)
  rows
}

load_conflict_lexicon <- function() {
  negative <- data.table::fread(
    file.path("resources", "lexicons", "crosentilex-negatives.txt"),
    sep = " ", header = FALSE, encoding = "UTF-8", fill = TRUE
  )
  data.table::setnames(negative, c("word", "weight"))
  negative[, weight := safe_numeric(weight)]
  emotion <- data.table::as.data.table(readxl::read_excel(
    file.path("resources", "dictionaries", "lilaHR_clean.xlsx"),
    sheet = "Sheet1",
    .name_repair = "unique_quiet"
  ))
  emotion_conflict <- emotion[
    safe_numeric(Anger) == 1 | safe_numeric(Disgust) == 1 | safe_numeric(Fear) == 1,
    tolower(trimws(as.character(HR)))
  ]
  unique(c(
    emotion_conflict,
    tolower(trimws(negative[weight >= 0.75, word])),
    c(
      "laž", "skandal", "napad", "radikalan", "ideologija", "licemjerje",
      "sramotno", "mržnja", "podjela", "raskol", "manipulacija", "propaganda",
      "ekstrem", "kontroverzan", "sukob", "kriza"
    )
  ))
}

compute_text_measures <- function(sample, tokens, expected_topic = "primary_frame") {
  sample <- data.table::as.data.table(sample)
  tokens <- data.table::as.data.table(tokens)
  if (!all(c("doc_id", "FROM", expected_topic) %in% names(sample))) {
    stop("Text sample lacks doc_id, FROM or expected-topic column.", call. = FALSE)
  }
  tokens[, doc_id := as.integer(doc_id)]
  tokens[, lemma_norm := tolower(trimws(as.character(lemma)))]
  frequencies <- tokens[, .(word_frequency = .N), by = .(doc_id, lemma_norm)]

  gold <- data.table::fread(
    file.path("resources", "lexicons", "gs-sentiment-annotations.txt"),
    sep = " ", header = FALSE, encoding = "UTF-8", fill = TRUE
  )
  data.table::setnames(gold, c("word", "sentiment"))
  gold <- gold[sentiment %in% c("+", "-"), .(
    lemma_norm = tolower(trimws(word)),
    sentiment_value = ifelse(sentiment == "+", 1, -1)
  )]
  gold <- unique(gold, by = "lemma_norm")
  sentiment_docs <- gold[frequencies, on = "lemma_norm", nomatch = 0L][, .(
    positive_words = sum(word_frequency[sentiment_value == 1L]),
    negative_words = sum(word_frequency[sentiment_value == -1L])
  ), by = doc_id]
  sentiment_docs[, tone := (positive_words - negative_words) /
    (positive_words + negative_words + 1e-6)]

  conflict_lexicon <- load_conflict_lexicon()
  cli_docs <- frequencies[, .(
    total_words = sum(word_frequency),
    conflict_words = sum(word_frequency[lemma_norm %in% conflict_lexicon])
  ), by = doc_id]
  cli_docs[, cli := 1000 * conflict_words / total_words]

  topic_values <- sample[[expected_topic]]
  base <- data.table::data.table(
    doc_id = as.integer(sample$doc_id),
    FROM = sample$FROM,
    expected_topic_value = topic_values
  )
  docs <- sentiment_docs[base, on = "doc_id"]
  docs <- cli_docs[docs, on = "doc_id"]
  docs[is.na(tone), tone := 0]
  docs[is.na(cli), cli := 0]
  source_cli <- docs[, .(source_cli = mean(cli)), by = FROM]
  topic_cli <- docs[, .(topic_cli = mean(cli)), by = expected_topic_value]
  docs <- source_cli[docs, on = "FROM"]
  docs <- topic_cli[docs, on = "expected_topic_value"]
  docs[, expected_cli := 0.5 * source_cli + 0.5 * topic_cli]
  docs[, rik := cli - expected_cli]
  docs[, .(doc_id, tone, cli, rik)]
}

build_daily_arcs <- function(corpus, date_col = "DATE", years = 2021:2026) {
  dates <- as.Date(corpus[[date_col]])
  date_min <- min(dates, na.rm = TRUE)
  date_max <- max(dates, na.rm = TRUE)
  daily_parts <- list()
  gap_rows <- list()
  for (year in years) {
    year_start <- as.Date(sprintf("%d-01-01", year))
    year_end <- as.Date(sprintf("%d-12-31", year))
    calendar <- data.table::data.table(date = seq(year_start, year_end, by = "day"))
    counts <- data.table::data.table(date = dates)[as.integer(format(date, "%Y")) == year, .(posts = .N), by = date]
    calendar <- counts[calendar, on = "date"]
    calendar[is.na(posts), posts := 0L]
    calendar[, observed_range := date >= date_min & date <= date_max]
    zero_runs <- rle(calendar$posts == 0L & calendar$observed_range)
    run_end <- cumsum(zero_runs$lengths)
    run_start <- run_end - zero_runs$lengths + 1L
    missing_idx <- which(zero_runs$values & zero_runs$lengths >= 2L)
    calendar[, collected := observed_range]
    if (length(missing_idx)) {
      for (idx in missing_idx) {
        calendar[run_start[idx]:run_end[idx], collected := FALSE]
        gap_rows[[length(gap_rows) + 1L]] <- data.table::data.table(
          year = year,
          start_date = calendar$date[run_start[idx]],
          end_date = calendar$date[run_end[idx]],
          start = run_start[idx] - 1L,
          end = run_end[idx] - 1L,
          label = "nije prikupljano",
          kind = "missing"
        )
      }
    }
    if (year == max(years) && date_max < year_end) {
      future_start <- which(calendar$date == date_max)[1] + 1L
      if (future_start <= nrow(calendar)) {
        calendar[future_start:.N, collected := FALSE]
        gap_rows[[length(gap_rows) + 1L]] <- data.table::data.table(
          year = year,
          start_date = calendar$date[future_start],
          end_date = year_end,
          start = future_start - 1L,
          end = nrow(calendar) - 1L,
          label = "izvan obuhvata",
          kind = "future"
        )
      }
    }
    observed_counts <- calendar[collected == TRUE, posts]
    z_denom <- stats::sd(observed_counts)
    if (!is.finite(z_denom) || z_denom == 0) z_denom <- 1
    calendar[, z := ifelse(collected, (posts - mean(observed_counts)) / z_denom, NA_real_)]
    calendar[, `:=`(year = year, index = .I - 1L)]
    daily_parts[[as.character(year)]] <- calendar
  }
  daily <- data.table::rbindlist(daily_parts)
  gaps <- if (length(gap_rows)) data.table::rbindlist(gap_rows) else data.table::data.table()

  easter_dates <- as.Date(c(
    "2021-04-04", "2022-04-17", "2023-04-09", "2024-03-31", "2025-04-20", "2026-04-05"
  ))
  events <- data.table::rbindlist(list(
    data.table::data.table(date = easter_dates, label = "Uskrs", type = "liturgical"),
    data.table::data.table(date = as.Date(sprintf("%d-08-15", years)), label = "Velika Gospa", type = "liturgical"),
    data.table::data.table(date = as.Date(sprintf("%d-11-01", years)), label = "Svi sveti", type = "liturgical"),
    data.table::data.table(date = as.Date(sprintf("%d-12-25", years)), label = "Božić", type = "liturgical"),
    data.table::data.table(
      date = as.Date(c("2025-04-21", "2025-04-26")),
      label = c("Smrt pape Franje", "Sprovod pape Franje"),
      type = "papal"
    )
  ))
  spikes <- daily[collected == TRUE & z > 3]
  data.table::setorder(spikes, date)
  spikes[, arc := cumsum(c(TRUE, diff(date) > 1L))]
  arcs <- spikes[, {
    peak_i <- which.max(z)
    .(
      start_date = min(date),
      end_date = max(date),
      peak_date = date[peak_i],
      peak_posts = posts[peak_i],
      peak_z = z[peak_i],
      arc_posts = sum(posts)
    )
  }, by = arc]
  if (nrow(arcs)) {
    arc_labels <- lapply(seq_len(nrow(arcs)), function(i) {
      row <- arcs[i]
      candidate <- events[date >= row$start_date - 1L & date <= row$end_date + 1L]
      if (!nrow(candidate)) return(list(label = "Događaj nije prepoznat", type = "other"))
      candidate[, distance := abs(as.integer(date - row$peak_date))]
      candidate <- candidate[order(distance, date)][1]
      list(label = candidate$label, type = candidate$type)
    })
    arcs[, label := vapply(arc_labels, `[[`, character(1), "label")]
    arcs[, type := vapply(arc_labels, `[[`, character(1), "type")]
    arcs[, year := as.integer(format(peak_date, "%Y"))]
  }
  list(
    date_min = date_min,
    date_max = date_max,
    daily = daily,
    gaps = gaps,
    arcs = arcs,
    events = events,
    daily_z = lapply(years, function(year_value) {
      row <- daily[year == year_value]
      list(year = year_value, values = lapply(row$z, function(value) if (is.finite(value)) value else NULL))
    }),
    peak_events = lapply(seq_len(nrow(arcs)), function(i) {
      row <- arcs[i]
      list(
        year = row$year,
        index = as.integer(format(row$peak_date, "%j")) - 1L,
        label = row$label,
        type = row$type,
        amplitude = row$peak_z
      )
    }),
    collection_gaps = lapply(seq_len(nrow(gaps)), function(i) as.list(gaps[i, .(year, start, end, label, kind)]))
  )
}

calendar_registry_dir <- file.path("explorations", "_okvir_engine", "registry")

load_calendar_registry <- function(kind = c("liturgical", "political")) {
  kind <- match.arg(kind)
  path <- file.path(calendar_registry_dir, paste0(kind, "_calendar.csv"))
  if (!file.exists(path)) stop("Calendar registry was not found: ", path, call. = FALSE)
  calendar <- data.table::fread(path, encoding = "UTF-8", na.strings = c("", "NA"))
  required <- c("date", "label", "type", "review_status")
  if (!identical(names(calendar), required)) {
    stop("Calendar registry has an unexpected schema: ", path, call. = FALSE)
  }
  calendar[, date := as.Date(date)]
  if (anyNA(calendar$date) || anyDuplicated(calendar[, .(date, label)])) {
    stop("Calendar registry has invalid dates or duplicate events: ", path, call. = FALSE)
  }
  calendar[]
}

load_event_calendars <- function() {
  list(
    liturgical = load_calendar_registry("liturgical"),
    political = load_calendar_registry("political")
  )
}

fit_rhythm <- function(dt, seed, bootstrap_reps = 120L) {
  model_formula <- log1p(posts) ~ liturgical_window + factor(weekday) +
    factor(halfyear) + factor(platform_group)
  fit <- stats::lm(model_formula, data = dt)
  coefficient <- unname(stats::coef(fit)["liturgical_windowTRUE"])
  if (!is.finite(coefficient)) {
    return(list(estimate = NA_real_, lower = NA_real_, upper = NA_real_))
  }

  set.seed(seed)
  blocks <- unique(dt$week_block)
  bootstrap_values <- replicate(bootstrap_reps, {
    sampled_blocks <- sample(blocks, length(blocks), replace = TRUE)
    bootstrap_data <- data.table::rbindlist(lapply(sampled_blocks, function(block) dt[week_block == block]))
    bootstrap_fit <- try(stats::lm(model_formula, data = bootstrap_data), silent = TRUE)
    if (inherits(bootstrap_fit, "try-error")) return(NA_real_)
    unname(stats::coef(bootstrap_fit)["liturgical_windowTRUE"])
  })
  bootstrap_values <- bootstrap_values[is.finite(bootstrap_values)]
  if (length(bootstrap_values) < bootstrap_reps * 0.8) {
    stop("Too few valid rhythm bootstrap estimates.", call. = FALSE)
  }
  interval <- stats::quantile(bootstrap_values, c(0.025, 0.975), na.rm = TRUE)
  list(
    estimate = 100 * (exp(coefficient) - 1),
    lower = 100 * (exp(interval[[1L]]) - 1),
    upper = 100 * (exp(interval[[2L]]) - 1)
  )
}

pre_periods <- paste0(rep(2021:2023, each = 2L), "H", rep(1:2, 3L))
post_periods <- c("2024H2", "2025H1", "2025H2", "2026H1")
all_periods <- c(pre_periods, post_periods)
trend_platform_levels <- c("web", "facebook", "video", "other")
trend_platforms <- list(
  list(key = "web", label = "Web", color = "#0f4c5c", dash = ""),
  list(key = "facebook", label = "Facebook", color = "#2f73b8", dash = "8 3"),
  list(key = "video", label = "YouTube", color = "#c47b21", dash = "5 3"),
  list(key = "other", label = "Ostale platforme", color = "#92969c", dash = "2 4")
)

complete_cells <- function(dt, value_col = "value", min_n = 20L) {
  grid <- data.table::CJ(halfyear = all_periods, platform_group = trend_platform_levels, unique = TRUE)
  out <- dt[grid, on = c("halfyear", "platform_group")]
  out[get("n") < min_n | !is.finite(get(value_col)), (value_col) := NA_real_]
  out
}

fit_slope <- function(dt, value_col = "value", era = c("pre", "post")) {
  era <- match.arg(era)
  selected <- if (era == "pre") pre_periods else post_periods
  x <- data.table::copy(dt[halfyear %in% selected & is.finite(get(value_col)) & n >= 20L])
  x[, t := match(halfyear, selected) - 1L]
  if (nrow(x) < 6L || data.table::uniqueN(x$t) < 3L) {
    return(c(estimate = NA_real_, lower = NA_real_, upper = NA_real_, n = nrow(x)))
  }
  x[, platform_group := factor(platform_group, levels = trend_platform_levels)]
  fit <- stats::lm(stats::reformulate(c("t", "platform_group"), response = value_col), data = x, weights = n)
  cf <- summary(fit)$coefficients
  if (!"t" %in% rownames(cf)) return(c(estimate = NA_real_, lower = NA_real_, upper = NA_real_, n = nrow(x)))
  est <- cf["t", "Estimate"]
  se <- cf["t", "Std. Error"]
  c(estimate = est, lower = est - 1.96 * se, upper = est + 1.96 * se, n = nrow(x))
}

status_adverse <- function(est, adverse = c("up", "down")) {
  adverse <- match.arg(adverse)
  if (!is.finite(est[["estimate"]])) return("excluded")
  if (adverse == "up") {
    if (est[["lower"]] > 0) return("worse")
    if (est[["upper"]] < 0) return("better")
  } else {
    if (est[["upper"]] < 0) return("worse")
    if (est[["lower"]] > 0) return("better")
  }
  "stable"
}

status_evidence <- function(status) {
  switch(status,
    worse = "vidi se jasan pomak u nepovoljnome smjeru",
    better = "vidi se jasan pomak u povoljnome smjeru",
    stable = "ne vidi se dovoljno jasna promjena",
    excluded = "nema dovoljno podataka za siguran zaključak"
  )
}

describe_change <- function(est, increase, decrease, steady = "Ne vidi se jasna promjena.") {
  if (!is.finite(est[["estimate"]])) return("Nema dovoljno podataka za siguran zaključak.")
  if (est[["lower"]] > 0) return(increase)
  if (est[["upper"]] < 0) return(decrease)
  steady
}

trend_series <- function(cells) {
  lapply(trend_platform_levels, function(key) {
    values <- cells$value[match(paste(all_periods, key), paste(cells$halfyear, cells$platform_group))]
    list(
      platform = trend_platforms[[match(key, trend_platform_levels)]],
      pre = lapply(values[seq_along(pre_periods)], function(value) if (is.finite(value)) value else NULL),
      post = lapply(values[length(pre_periods) + seq_along(post_periods)], function(value) if (is.finite(value)) value else NULL)
    )
  })
}

build_verdict <- function(i2_status, i1_status, estimates = list()) {
  share_title <- switch(i2_status,
    worse = "Crkveni glasovi čine manji dio razgovora",
    better = "Crkveni glasovi čine veći dio razgovora",
    stable = "Udio crkvenih glasova ne pokazuje jasan pomak",
    excluded = "Za udio crkvenih glasova nema dovoljno podataka",
    stop("Unsupported I2 status: ", i2_status, call. = FALSE)
  )
  tone_title <- switch(i1_status,
    worse = "konfliktni rječnik od 2024. postaje nešto gušći",
    better = "konfliktni rječnik od 2024. postaje nešto rjeđi",
    stable = "tonalitet od 2024. ne pokazuje jasan pomak",
    excluded = "za noviji tonalitet nema dovoljno podataka",
    stop("Unsupported I1 status: ", i1_status, call. = FALSE)
  )
  summary_parts <- c(
    switch(i2_status,
      worse = "U novijem razdoblju udio web objava crkvenih medija i ustanova smanjuje se unutar istoga načina prikupljanja.",
      better = "U novijem razdoblju udio web objava crkvenih medija i ustanova raste unutar istoga načina prikupljanja.",
      stable = "U novijem razdoblju nema jasnoga smjera udjela web objava crkvenih medija i ustanova.",
      excluded = "Za smjer udjela web objava crkvenih medija i ustanova nema dovoljno podataka."
    ),
    switch(i1_status,
      worse = "Relativni indeks konflikta pritom pokazuje pomak prema gušćem konfliktnom rječniku.",
      better = "Tekstualne mjere pritom pokazuju pomak prema manje konfliktnom rječniku.",
      stable = "Tekstualne mjere pritom ne pokazuju jasan pomak tonaliteta.",
      excluded = "Za smjer tekstualnih mjera nema dovoljno podataka."
    )
  )
  slope_note <- character()
  if (length(estimates)) {
    if (!is.null(estimates$post_official)) {
      slope_note <- c(slope_note, paste0(
        "Procijenjeni noviji pomak udjela crkvenih web objava iznosi ",
        fmt_slope(estimates$post_official, "postotnih bodova po polugodištu"), "."
      ))
    }
    if (!is.null(estimates$post_rik)) {
      slope_note <- c(slope_note, paste0(
        "Procijenjeni noviji pomak RIK-a iznosi ",
        fmt_slope(estimates$post_rik, "bodova po polugodištu"), "."
      ))
    }
  }
  list(
    key = paste(i2_status, i1_status, sep = "-"),
    title = paste0(share_title, ", a ", tone_title),
    summary = paste(summary_parts, collapse = " "),
    estimateNote = paste(slope_note, collapse = " "),
    shareStatus = i2_status,
    toneStatus = i1_status
  )
}
