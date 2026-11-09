# Shared loader for the theological-voices study. Run every stage from the repository root:
#   Rscript --vanilla studies/theological-voices/<stage>.R
# Input is the OFFICIAL corpus resolved through digikat_corpus_path(); set DIGIKAT_CORPUS_PATH when
# the file lives outside the repo. The corpus is read-only and its sha256 is checked against the
# tracked manifest before anything is computed.
invisible(Sys.setlocale("LC_CTYPE", "English_United States.utf8"))
suppressPackageStartupMessages({library(data.table); library(jsonlite); library(digest)})
setDTthreads(4L)
source("R/lib/digikat_paths.R", encoding = "UTF-8")
source("studies/catholic-influencers/actor_classification.R", encoding = "UTF-8")
source("R/lib/thematic_dictionaries.R", encoding = "UTF-8")

TV_OUT  <- "studies/theological-voices/output"
TV_PRIV <- file.path(TV_OUT, "private")
dir.create(TV_PRIV, recursive = TRUE, showWarnings = FALSE)
say <- function(...) {cat(format(Sys.time(), "%H:%M:%S"), ..., "\n"); flush.console()}

GROUP_LABELS <- c(church_media = "Crkveni mediji", church_org = "Crkvene ustanove i računi",
  independent = "Neovisni katolički mediji", clergy = "Svećenički profili",
  community = "Zajednice i udruge", devotional = "Pobožni i autorski kanali",
  other_christian = "Ostali kršćanski izvori", public = "Ostali i nerazvrstani izvori")

PLATFORM_LABELS <- c(web = "Portali", facebook = "Facebook", youtube = "YouTube",
  instagram = "Instagram", twitter = "X", tiktok = "TikTok", reddit = "Reddit",
  forum = "Forumi", comment = "Komentari")

tv_corpus_check <- function() {
  path <- digikat_corpus_path()
  man  <- fromJSON(digikat_corpus_manifest_path())
  hash <- digest(file = path, algo = "sha256", serialize = FALSE)
  if (!identical(hash, man$corpus$sha256))
    stop("Corpus hash ", hash, " does not match the manifest ", man$corpus$sha256, call. = FALSE)
  list(path = path, sha256 = hash, rows = man$corpus$rows)
}

# Pure definitions reused from the shared engine without running its pipeline.
local({
  needed <- c("normalise_key", "official_pattern", "independent_pattern", "creator_pattern")
  found <- character()
  for (expr in parse("explorations/_okvir_engine/okvir_lib.R", encoding = "UTF-8")) {
    if (is.call(expr) && identical(expr[[1]], as.name("<-")) && is.symbol(expr[[2]]) &&
        as.character(expr[[2]]) %in% needed) {
      eval(expr, envir = globalenv()); found <- c(found, as.character(expr[[2]]))
    }
  }
  stopifnot(setequal(needed, found))
})

# Actor grouping copied from studies/theological-authority/analyze.R so both studies classify a
# source identically. The classification describes the publishing CHANNEL, not the speaker.
tv_classify_sources <- function(s) {
  registry <- fread("explorations/okvir-katolicanstva-prototype/source-groups.csv", encoding = "UTF-8")
  registry[, key := normalise_key(from)]
  labels <- fread("resources/dictionaries/source_labels.csv", encoding = "UTF-8")
  labels[, key := normalise_key(from)]
  labels <- unique(labels, by = "key")
  s[, catalogue := labels$label[match(key, labels$key)]]
  s[, catalogue_kind := labels$kind[match(key, labels$key)]]
  s[, actor := "public"]; s[, rule := "unclassified"]
  s[catalogue == "confessional", `:=`(actor = "creator", rule = "catalogue_confessional")]
  s[catalogue == "secular", rule := "catalogue_secular"]
  s[grepl(creator_pattern, key, perl = TRUE), `:=`(actor = "creator", rule = "creator_pattern")]
  s[grepl(independent_pattern, key, perl = TRUE), `:=`(actor = "independent", rule = "independent_pattern")]
  s[grepl(official_pattern, key, perl = TRUE), `:=`(actor = "official", rule = "institution_pattern")]
  legacy <- rbindlist(lapply(s$key, function(k) as.data.table(classify_actor_source(k, has_social = TRUE))))
  s[, legacy_type := legacy$actor_type]
  s[, legacy_confidence := legacy$confidence]
  s[actor == "public" & legacy_type == "Independent Media", `:=`(actor = "independent", rule = "inherited_media_list")]
  s[actor == "public" & legacy_type %in% c("Institutional Official", "Diocesan", "Religious Orders", "Academic"),
    `:=`(actor = "official", rule = "inherited_institution_list")]
  s[actor == "public" & legacy_type %in% c("Individual Priests", "Charismatic Communities", "Youth Organizations", "Lay Influencers"),
    `:=`(actor = "creator", rule = "inherited_creator_list")]
  s[catalogue_kind %in% c("noise", "offtopic"), `:=`(actor = "public", rule = "catalogue_exclusion")]
  s[registry, on = "key", `:=`(actor = i.actor_group, rule = "existing_registry")]
  s[, group := fcase(actor == "official", "church_org", actor == "independent", "independent",
                     actor == "creator", "devotional", default = "public")]
  media_pattern <- "hkm|(^|[.])ika[.]|informativna katoli|hkr|katolički radio|glas.?koncila|kršćanska.?sadašnjost|krscanska.?sadasnjost|^ks[.]hr$|svjetlo.?rije|svjetlo.?riječ|tjednik|nedjelja.?ba|veritas[.]hr|ktabkbih|živo.?vrelo"
  s[actor == "official" & grepl(media_pattern, key, perl = TRUE), group := "church_media"]
  s[actor == "creator" & legacy_type %in% c("Charismatic Communities", "Youth Organizations"), group := "community"]
  s[actor == "creator" & (legacy_type == "Individual Priests" | key == "pulherissimus"), group := "clergy"]
  s[key == "novizivot.net", group := "other_christian"]
  s[, core := !group %in% c("public", "other_christian")]
  s[, secular := catalogue %in% "secular"]
  s[, group_label := unname(GROUP_LABELS[group])]
  s
}

# Loads the corpus, collapses repeated captures of one platform+URL (keeping the largest recorded
# interaction snapshot) and attaches the source group. Returns a data.table with `text` = FULL_TEXT.
tv_load <- function(keep_text = TRUE) {
  chk <- tv_corpus_check()
  say("Reading corpus", chk$path)
  d <- as.data.table(readRDS(chk$path))
  stopifnot(nrow(d) == chk$rows)
  d[, date := as.IDate(DATE)]
  stopifnot(!anyNA(d$date))
  d[, input_order := .I]
  d[, observed := is.finite(INTERACTIONS) & INTERACTIONS >= 0]
  d[, duplicate_key := fifelse(!is.na(URL) & nzchar(trimws(URL)),
                               paste(SOURCE_TYPE, trimws(URL), sep = "|"), paste0("missing-url-", input_order))]
  setorderv(d, c("duplicate_key", "observed", "INTERACTIONS", "input_order"), c(1, -1, -1, 1), na.last = TRUE)
  d <- d[!duplicated(duplicate_key)]
  setorder(d, input_order)
  attr(d, "duplicates_removed") <- chk$rows - nrow(d)
  d[, key := normalise_key(FROM)]
  d[is.na(key) | key == "", key := "[unknown]"]
  d[, source_id := paste(SOURCE_TYPE, key, sep = "::")]
  s <- unique(d[, .(source_id, SOURCE_TYPE, key)])
  s[, source := d$FROM[match(source_id, d$source_id)]]
  s <- tv_classify_sources(s)
  d[s, on = "source_id", `:=`(group = i.group, core = i.core, secular = i.secular, rule = i.rule)]
  stopifnot(!anyNA(d$group))
  d[, year := as.integer(format(date, "%Y"))]
  d[, interactions := fifelse(observed, INTERACTIONS, NA_real_)]
  d[, text := fifelse(is.na(FULL_TEXT), "", FULL_TEXT)]
  keep <- c("input_order", "dk_master_row", "date", "year", "SOURCE_TYPE", "FROM", "key", "source_id",
            "group", "core", "secular", "rule", "URL", "TITLE", "AUTO_SENTIMENT", "REACH",
            "observed", "interactions", "data_source", if (keep_text) "text")
  d <- d[, ..keep]
  attr(d, "sources") <- s
  attr(d, "corpus") <- chk
  d
}

# Title normalised for story grouping: lower case, letters/digits only, first 90 characters.
tv_title_key <- function(x) {
  x <- tolower(fifelse(is.na(x), "", x))
  x <- gsub("[^[:alnum:]čćžšđ ]+", " ", x, perl = TRUE)
  x <- gsub("\\s+", " ", trimws(x))
  substr(x, 1, 90)
}

hr_num <- function(x, digits = 0) {
  out <- formatC(round(x, digits), format = "f", digits = digits, big.mark = ".", decimal.mark = ",")
  out
}
