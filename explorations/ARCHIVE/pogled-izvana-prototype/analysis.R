#!/usr/bin/env Rscript

# Reproducible analysis behind „Što iz crkvenoga života dospijeva u vijesti?”.
# The official corpus is read-only. The analysis never selects the AUTHOR or URL
# columns. Row-level working material remains under output/private/.

options(stringsAsFactors = FALSE, encoding = "UTF-8", width = 160)
Sys.setenv(TZ = "Europe/Zagreb")

suppressPackageStartupMessages({
  library(data.table)
})

if (!requireNamespace("stringi", quietly = TRUE)) {
  stop("Package 'stringi' is required.", call. = FALSE)
}

source(file.path("R", "lib", "digikat_paths.R"), encoding = "UTF-8")
source(file.path("R", "lib", "digikat_utils.R"), encoding = "UTF-8")
source(file.path("R", "lib", "thematic_dictionaries.R"), encoding = "UTF-8")
source(file.path("explorations", "_okvir_engine", "okvir_lib.R"), encoding = "UTF-8")

analysis_dir <- file.path("explorations", "pogled-izvana-prototype")
output_dir <- file.path(analysis_dir, "output")
private_dir <- file.path(output_dir, "private")
dir.create(private_dir, recursive = TRUE, showWarnings = FALSE)

registry_path <- file.path(analysis_dir, "secular_outlets.csv")
flagship_arc_path <- file.path("explorations", "okvir-katolicanstva-prototype", "output", "event_arcs.csv")
corpus_manifest_path <- file.path("data", "digikat_corpus_manifest.json")
general_news_types <- c("national", "regional", "public_service", "tabloid_lifestyle")
catholic_actor_groups <- c("official", "independent", "creator")

for (path in c(registry_path, flagship_arc_path, corpus_manifest_path)) {
  if (!file.exists(path)) stop("Missing required input: ", path, call. = FALSE)
}

registry <- fread(registry_path, encoding = "UTF-8", na.strings = c("", "NA"))
if (!identical(names(registry), c("from", "brand", "type", "publish", "note"))) {
  stop("secular_outlets.csv has an unexpected schema.", call. = FALSE)
}
registry[, key := normalise_key(from)]
if (anyDuplicated(registry$key)) stop("The outlet registry contains duplicate normalized names.", call. = FALSE)
registry[, publish := tolower(trimws(publish))]
general_registry <- registry[type %in% general_news_types & publish == "yes"]
if (!nrow(general_registry)) stop("The outlet registry contains no publishable general-news outlets.", call. = FALSE)

corpus_manifest <- jsonlite::read_json(corpus_manifest_path, simplifyVector = TRUE)
corpus_sha256 <- corpus_manifest$corpus$sha256
corpus_path <- digikat_corpus_path()
if (!identical(digikat_hash_file(corpus_path), corpus_sha256)) {
  stop("The corpus hash does not match data/digikat_corpus_manifest.json.", call. = FALSE)
}

say("01_universe | reading required columns from the official corpus")
corpus_raw <- readRDS(corpus_path)
required <- c("DATE", "FROM", "SOURCE_TYPE", "FULL_TEXT")
missing_required <- setdiff(required, names(corpus_raw))
if (length(missing_required)) stop("Corpus lacks: ", paste(missing_required, collapse = ", "), call. = FALSE)
corpus <- as.data.table(corpus_raw[, required])
rm(corpus_raw)
invisible(gc())

corpus[, `:=`(
  row_id = .I,
  DATE = as.Date(DATE),
  key = normalise_key(FROM),
  source_type = tolower(trimws(as.character(SOURCE_TYPE))),
  era = era_id(DATE)
)]
actor_details <- classify_actor_details(corpus$FROM)
corpus[, `:=`(actor_group = actor_details$actor_group, actor_rule = actor_details$actor_rule)]

registry_match <- match(corpus$key, general_registry$key)
corpus[, `:=`(
  general_brand = general_registry$brand[registry_match],
  general_type = general_registry$type[registry_match]
)]

corpus[, media_circle := NA_character_]
corpus[source_type == "web" & actor_group %in% catholic_actor_groups, media_circle := "catholic"]
corpus[source_type == "web" & actor_group == "public" & !is.na(general_brand), media_circle := "general"]
comparison <- corpus[!is.na(media_circle)]

if (comparison[, anyDuplicated(row_id)]) stop("A corpus row entered both media circles.", call. = FALSE)
if (!all(c("catholic", "general") %in% comparison$media_circle)) {
  stop("Both media circles must contain posts.", call. = FALSE)
}

registry_audit <- general_registry[, .(from, brand, type, publish, note)]
web_source_counts <- corpus[source_type == "web", .N, by = key]
registry_audit[, `:=`(
  in_corpus = normalise_key(from) %in% corpus$key,
  web_posts = web_source_counts$N[match(normalise_key(from), web_source_counts$key)]
)]
registry_audit[is.na(web_posts), web_posts := 0L]
fwrite(registry_audit, file.path(private_dir, "general_news_registry_audit.csv"), bom = TRUE)

universe <- comparison[, .(
  posts = .N,
  sources = uniqueN(FROM),
  posts_with_text = sum(!is.na(FULL_TEXT) & nzchar(trimws(FULL_TEXT)))
), by = media_circle]
universe[, text_coverage := 100 * posts_with_text / posts]
fwrite(universe, file.path(output_dir, "comparison_universe.csv"), bom = TRUE)

theme_map <- data.table(
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

if (!setequal(theme_map$category, names(category_labels))) {
  stop("Theme collapse and category labels do not cover the same categories.", call. = FALSE)
}

say("02_themes | classifying the two web-media circles")
theme_input <- comparison[!is.na(FULL_TEXT) & nzchar(trimws(FULL_TEXT)), .(
  row_id,
  media_circle,
  text = substr(FULL_TEXT, 1L, 3000L)
)]
theme_input_fingerprint <- digikat_hash_object(list(
  corpus_sha256 = corpus_sha256,
  registry_sha256 = digikat_hash_file(registry_path),
  dictionaries = digikat_thematic_dictionaries,
  selected_rows = theme_input[, .(row_id, media_circle)]
))
theme_cache_path <- file.path(private_dir, "crossover_theme_rows.rds")
theme_cache_manifest_path <- file.path(private_dir, "crossover_theme_manifest.json")
use_theme_cache <- FALSE
if (file.exists(theme_cache_path) && file.exists(theme_cache_manifest_path)) {
  old_cache_manifest <- jsonlite::read_json(theme_cache_manifest_path, simplifyVector = TRUE)
  use_theme_cache <- identical(old_cache_manifest$fingerprint, theme_input_fingerprint)
}

if (use_theme_cache) {
  say("  reusing the private theme cache")
  theme_rows <- as.data.table(readRDS(theme_cache_path))
} else {
  patterns <- vapply(
    digikat_thematic_dictionaries,
    function(terms) paste0("(", paste(tolower(terms), collapse = "|"), ")"),
    character(1)
  )
  chunk_starts <- seq.int(1L, nrow(theme_input), by = 25000L)
  category <- rep("not_recognised", nrow(theme_input))
  for (chunk_index in seq_along(chunk_starts)) {
    start <- chunk_starts[chunk_index]
    end <- min(start + 24999L, nrow(theme_input))
    say("  theme chunk", chunk_index, "of", length(chunk_starts), "| rows", start, "to", end)
    text <- tolower(theme_input$text[start:end])
    scores <- vapply(patterns, function(pattern) {
      values <- stringi::stri_count_regex(text, pattern)
      values[is.na(values)] <- 0L
      as.integer(values)
    }, integer(length(text)))
    has_theme <- rowSums(scores) > 0L
    if (any(has_theme)) {
      selected_index <- (start:end)[has_theme]
      category[selected_index] <- names(patterns)[
        max.col(scores[has_theme, , drop = FALSE], ties.method = "first")
      ]
    }
  }
  theme_rows <- theme_input[, .(row_id, media_circle)]
  theme_rows[, category := category]
  saveRDS(theme_rows, theme_cache_path)
  digikat_write_json_atomic(list(
    fingerprint = theme_input_fingerprint,
    rows = nrow(theme_rows),
    disclosure = "row identifiers, media-circle labels and computed category only"
  ), theme_cache_manifest_path)
}
rm(theme_input)
invisible(gc())

if (!identical(theme_rows$row_id, sort(theme_rows$row_id))) setorder(theme_rows, row_id)
theme_rows[, theme := theme_map$theme[match(category, theme_map$category)]]

theme_coverage <- theme_rows[, .(
  text_posts = .N,
  recognised_posts = sum(category != "not_recognised")
), by = media_circle]
theme_coverage[, recognised_share := 100 * recognised_posts / text_posts]

category_comparison <- theme_rows[category != "not_recognised", .(posts = .N), by = .(media_circle, category)]
category_comparison[, share := 100 * posts / sum(posts), by = media_circle]
category_comparison[, label := unname(category_labels[category])]
category_wide <- dcast(
  category_comparison,
  category + label ~ media_circle,
  value.var = c("posts", "share"),
  fill = 0
)
setnames(
  category_wide,
  c("posts_catholic", "posts_general", "share_catholic", "share_general"),
  c("catholic_posts", "general_posts", "catholic_share", "general_share")
)
category_wide[, gap := general_share - catholic_share]
category_wide[, abs_gap := abs(gap)]
setorder(category_wide, -abs_gap, category)
category_wide[, abs_gap := NULL]
fwrite(category_wide, file.path(output_dir, "category_selection_gap.csv"), bom = TRUE)

theme_comparison <- theme_rows[!is.na(theme), .(posts = .N), by = .(media_circle, theme)]
theme_comparison[, share := 100 * posts / sum(posts), by = media_circle]
theme_comparison[, `:=`(
  label = unname(theme_labels[theme]),
  color = unname(theme_colors[theme])
)]
theme_wide <- dcast(
  theme_comparison,
  theme + label + color ~ media_circle,
  value.var = c("posts", "share"),
  fill = 0
)
setnames(
  theme_wide,
  c("posts_catholic", "posts_general", "share_catholic", "share_general"),
  c("catholic_posts", "general_posts", "catholic_share", "general_share")
)
theme_wide[, gap := general_share - catholic_share]
theme_wide[, max_share := pmax(catholic_share, general_share)]
setorder(theme_wide, -max_share, theme)
theme_wide[, max_share := NULL]
fwrite(theme_wide, file.path(output_dir, "theme_selection.csv"), bom = TRUE)

say("03_events | comparing named event waves with their period baselines")
shared_events <- build_daily_arcs(corpus, years = 2021:2026)
flagship_arcs <- fread(flagship_arc_path, encoding = "UTF-8")
for (column in c("start_date", "end_date", "peak_date")) flagship_arcs[, (column) := as.Date(get(column))]
arc_columns <- c("arc", "start_date", "end_date", "peak_date", "peak_posts", "peak_z", "arc_posts", "label", "type", "year")
arc_comparison <- all.equal(
  as.data.frame(shared_events$arcs[, ..arc_columns]),
  as.data.frame(flagship_arcs[, ..arc_columns]),
  check.attributes = FALSE,
  tolerance = 1e-10
)
if (!isTRUE(arc_comparison)) stop("Shared event arcs differ from the flagship report.", call. = FALSE)

era_baselines <- comparison[, .(
  general_posts = sum(media_circle == "general"),
  catholic_posts = sum(media_circle == "catholic")
), by = era]
era_baselines[, baseline_general_share := 100 * general_posts / (general_posts + catholic_posts)]

named_arcs <- flagship_arcs[type %in% c("liturgical", "papal")]
event_rows <- lapply(seq_len(nrow(named_arcs)), function(i) {
  arc <- named_arcs[i]
  window <- comparison[DATE >= arc$start_date & DATE <= arc$end_date]
  general_posts <- window[media_circle == "general", .N]
  catholic_posts <- window[media_circle == "catholic", .N]
  event_share <- if (general_posts + catholic_posts > 0L) {
    100 * general_posts / (general_posts + catholic_posts)
  } else {
    NA_real_
  }
  arc_era <- era_id(arc$peak_date)
  baseline <- era_baselines[era == arc_era, baseline_general_share]
  data.table(
    peak_date = arc$peak_date,
    year = arc$year,
    label = arc$label,
    type = arc$type,
    general_posts = general_posts,
    catholic_posts = catholic_posts,
    general_share = event_share,
    baseline_share = baseline,
    difference = event_share - baseline,
    above_baseline = event_share > baseline
  )
})
event_table <- rbindlist(event_rows)
setorder(event_table, peak_date)
fwrite(event_table, file.path(output_dir, "event_crossover.csv"), bom = TRUE)

event_summary <- event_table[, .(
  events = .N,
  above_baseline = sum(above_baseline, na.rm = TRUE),
  general_posts = sum(general_posts),
  catholic_posts = sum(catholic_posts),
  mean_difference = mean(difference, na.rm = TRUE)
), by = .(label, type)]
event_summary[, general_share := 100 * general_posts / (general_posts + catholic_posts)]
setorder(event_summary, -general_share, label)
fwrite(event_summary, file.path(output_dir, "event_crossover_summary.csv"), bom = TRUE)

general_theme <- theme_wide[which.max(gap)]
catholic_theme <- theme_wide[which.min(gap)]
general_category <- category_wide[which.max(gap)]
catholic_category <- category_wide[which.min(gap)]
event_above <- event_table[above_baseline == TRUE, .N]
event_total <- nrow(event_table)

hero_title <- if (catholic_theme$theme == "faith" && event_above >= ceiling(0.6 * event_total)) {
  "Veliki crkveni događaji ulaze u opće vijesti, ali svakodnevna vjera ondje zauzima manje mjesta."
} else {
  "Katolički i opći mediji ne izdvajaju iste dijelove crkvenoga života."
}

findings <- list(
  heroTitle = hero_title,
  generalTheme = as.list(general_theme),
  catholicTheme = as.list(catholic_theme),
  generalCategory = as.list(general_category),
  catholicCategory = as.list(catholic_category),
  eventsAboveBaseline = event_above,
  namedEvents = event_total,
  generalPosts = comparison[media_circle == "general", .N],
  catholicPosts = comparison[media_circle == "catholic", .N],
  generalSources = comparison[media_circle == "general", uniqueN(FROM)],
  generalBrands = comparison[media_circle == "general", uniqueN(general_brand)],
  catholicSources = comparison[media_circle == "catholic", uniqueN(FROM)]
)

hr_months <- c(
  "siječnja", "veljače", "ožujka", "travnja", "svibnja", "lipnja",
  "srpnja", "kolovoza", "rujna", "listopada", "studenoga", "prosinca"
)
date_max <- max(corpus$DATE)
scope_text <- paste0(
  "Web-objave od ", format(min(corpus$DATE), "%Y."), " do ",
  as.integer(format(date_max, "%d")), ". ",
  hr_months[as.integer(format(date_max, "%m"))], " ",
  format(date_max, "%Y." )
)

result <- list(
  meta = list(
    status = "real_exploratory_analysis",
    generatedUtc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    corpusSha256 = corpus_sha256,
    corpusRows = nrow(corpus),
    dateMin = as.character(min(corpus$DATE)),
    dateMax = as.character(max(corpus$DATE)),
    unit = "posts in two audited web-media circles",
    authorRead = FALSE,
    urlRead = FALSE,
    topicMethod = "canonical 16-category dictionary collapsed to six reader-facing themes"
  ),
  scope = scope_text,
  circles = list(
    list(key = "catholic", label = "Katolički izvori", color = "#2f8f6b"),
    list(key = "general", label = "Opći informativni mediji", color = "#156b82")
  ),
  themes = unname(lapply(names(theme_labels), function(key) list(
    key = key,
    label = unname(theme_labels[[key]]),
    color = unname(theme_colors[[key]])
  ))),
  universe = universe,
  themeCoverage = theme_coverage,
  figures = list(
    themeSelection = theme_wide,
    categoryGap = category_wide,
    eventCrossover = event_table,
    eventSummary = event_summary,
    eraBaselines = era_baselines
  ),
  findings = findings,
  method = list(
    generalNewsTypes = as.list(general_news_types),
    themeCollapse = lapply(seq_len(nrow(theme_map)), function(i) list(
      category = unname(category_labels[[theme_map$category[i]]]),
      theme = unname(theme_labels[[theme_map$theme[i]]])
    )),
    caveats = as.list(c(
      "Opći informativni mediji čine unaprijed provjeren panel nacionalnih, regionalnih i lokalnih web-medija. Panel nije popis svih hrvatskih medija.",
      "Katolički izvori obuhvaćaju tri skupine iz glavnog izvještaja. To su crkveni mediji i ustanove, katolički mediji drugih osnivača te pastoralni i vjerski kanali i stvaratelji.",
      "Teme su računalno prepoznate prema postojećem projektnom rječniku. Oznaka opisuje najizraženiju temu, a ne namjeru autora niti kvalitetu objave.",
      "Događajni val opisuje razdoblje povećanog broja objava. Ne dokazuje da je imenovani događaj uzrokovao svaku objavu u tome razdoblju.",
      "Način prikupljanja promijenjen je 2024. Događaji se zato uspoređuju s osnovicom svojega razdoblja, a ne jednim prosjekom za cijeli niz.",
      "Analiza je na razini izvora. Podatci o autoru i mrežnoj adresi nisu pročitani ni analizirani."
    ))
  )
)

say("04_outputs | writing aggregate-only public results")
js_path <- file.path(output_dir, "analysis-data.js")
write_analysis_js(result, js_path, variable = "CROSSOVER_RESULTS")

manifest <- list(
  schema_version = 2L,
  generated_utc = result$meta$generatedUtc,
  corpus_sha256 = corpus_sha256,
  registry_sha256 = digikat_hash_file(registry_path),
  shared_engine_sha256 = digikat_hash_file(file.path("explorations", "_okvir_engine", "okvir_lib.R")),
  flagship_arcs_sha256 = digikat_hash_file(flagship_arc_path),
  theme_cache = list(
    fingerprint = theme_input_fingerprint,
    rows = nrow(theme_rows)
  ),
  public_output = list(
    analysis_data_sha256 = digikat_hash_file(js_path),
    disclosure = "aggregate only; no text, title, source name, URL, AUTHOR or journalist-level measure"
  )
)
digikat_write_json_atomic(manifest, file.path(output_dir, "manifest.json"))

say("05_checks | running reconciliation, privacy and public-copy guards")
stopifnot(
  nrow(corpus) == corpus_manifest$corpus$rows,
  nrow(comparison) == sum(universe$posts),
  sum(theme_rows$category != "not_recognised") == sum(category_comparison$posts),
  abs(sum(theme_wide$catholic_share) - 100) < 1e-8,
  abs(sum(theme_wide$general_share) - 100) < 1e-8,
  abs(sum(category_wide$catholic_share) - 100) < 1e-8,
  abs(sum(category_wide$general_share) - 100) < 1e-8,
  nrow(event_table) == nrow(named_arcs),
  !"AUTHOR" %in% required,
  !"URL" %in% required,
  file.info(js_path)$size > 1000
)

public_files <- c(
  file.path(output_dir, "analysis-data.js"),
  file.path(output_dir, "comparison_universe.csv"),
  file.path(output_dir, "theme_selection.csv"),
  file.path(output_dir, "category_selection_gap.csv"),
  file.path(output_dir, "event_crossover.csv"),
  file.path(output_dir, "event_crossover_summary.csv"),
  file.path(output_dir, "manifest.json")
)
public_text <- paste(vapply(public_files, function(path) {
  paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
}, character(1)), collapse = "\n")
forbidden <- c('"AUTHOR":', '"URL":', '"FULL_TEXT":', '"TITLE":', "http://", "https://")
for (needle in forbidden) {
  if (grepl(needle, public_text, fixed = TRUE)) stop("Public-output disclosure guard found: ", needle, call. = FALSE)
}

page_sources <- paste(
  readLines(file.path(analysis_dir, "index.html"), encoding = "UTF-8", warn = FALSE),
  readLines(file.path(analysis_dir, "prototype.js"), encoding = "UTF-8", warn = FALSE),
  collapse = " "
)
flat_page <- gsub("[[:space:]]+", " ", page_sources)
required_copy <- c(
  "Što iz crkvenoga života dospijeva u vijesti?",
  "Opći informativni mediji",
  "nije popis svih hrvatskih medija",
  "računalno prepoznate",
  "promijenjen je 2024."
)
missing_copy <- required_copy[!vapply(required_copy, grepl, logical(1), x = flat_page, fixed = TRUE)]
if (length(missing_copy)) stop("The public page lacks required guard text: ", paste(missing_copy, collapse = " | "), call. = FALSE)
if (grepl("nekonfesional|Relativni indeks konflikta|tonalitet", flat_page, ignore.case = TRUE) ||
    grepl("\\bRIK\\b", flat_page)) {
  stop("Legacy report terminology remains in the public page.", call. = FALSE)
}
if (grepl("Ã|Ä|Å|Â", flat_page)) stop("Possible mojibake detected in public source.", call. = FALSE)

summary_lines <- c(
  "ŠTO IZ CRKVENOGA ŽIVOTA DOSPIJEVA U VIJESTI — ANALYSIS RUN",
  paste("Generated UTC:", result$meta$generatedUtc),
  paste("Corpus SHA-256:", corpus_sha256),
  paste("General-news panel posts:", formatC(findings$generalPosts, format = "d", big.mark = ".", decimal.mark = ",")),
  paste("Catholic-source posts:", formatC(findings$catholicPosts, format = "d", big.mark = ".", decimal.mark = ",")),
  paste("General-news brands:", findings$generalBrands),
  paste("Recognised theme posts:", formatC(sum(theme_rows$category != "not_recognised"), format = "d", big.mark = ".", decimal.mark = ",")),
  paste("Named event waves above baseline:", event_above, "of", event_total),
  paste("Headline:", hero_title)
)
writeLines(summary_lines, file.path(output_dir, "analysis-summary.txt"), useBytes = TRUE)

say("Analysis complete:", js_path)
cat(paste(summary_lines, collapse = "\n"), "\n")
