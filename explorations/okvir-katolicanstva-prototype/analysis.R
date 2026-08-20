#!/usr/bin/env Rscript

# Reproducible analysis behind the merged „Kako se govori o Crkvi?” report.
# Run from the repository root. The official corpus is read-only. AUTHOR and URL
# are never selected. Row-level work remains under output/private/ or the
# separately ignored 15% NLP generation.

options(stringsAsFactors = FALSE, encoding = "UTF-8", width = 180)
Sys.setenv(TZ = "Europe/Zagreb")

suppressPackageStartupMessages({
  library(data.table)
  library(readxl)
})

if (!requireNamespace("stringi", quietly = TRUE)) stop("Package 'stringi' is required.", call. = FALSE)
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Package 'jsonlite' is required.", call. = FALSE)

source(file.path("R", "lib", "digikat_utils.R"), encoding = "UTF-8")
source(file.path("R", "lib", "digikat_paths.R"), encoding = "UTF-8")
source(file.path("R", "lib", "thematic_dictionaries.R"), encoding = "UTF-8")
source(file.path("explorations", "_okvir_engine", "okvir_lib.R"), encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
analysis_dir <- file.path("explorations", "okvir-katolicanstva-prototype")
output_dir <- file.path(analysis_dir, "output")
private_dir <- file.path(output_dir, "private")
archive_dir <- file.path("explorations", "ARCHIVE", "2026-08-19_pre-merge")
dir.create(private_dir, recursive = TRUE, showWarnings = FALSE)

sample_path <- digikat_cli_value(args, "--sample", file.path(output_dir, "nlp-15pct", "sample.rds"))
tokens_path <- digikat_cli_value(args, "--tokens", file.path(dirname(sample_path), "tokens.rds"))
sample_manifest_path <- digikat_cli_value(
  args, "--sample-manifest", file.path(dirname(sample_path), "manifest.json")
)
required_private <- c(sample_path, tokens_path, sample_manifest_path)
if (!all(file.exists(required_private))) {
  stop(
    "The private 15% text generation is incomplete. Run ",
    "explorations/okvir-katolicanstva-prototype/build-15pct-nlp.R or supply ",
    "--sample, --tokens and --sample-manifest.",
    call. = FALSE
  )
}

sample_manifest <- jsonlite::read_json(sample_manifest_path, simplifyVector = TRUE)
sample_proportion <- as.numeric(sample_manifest$parameters$proportion)
if (!isTRUE(all.equal(sample_proportion, 0.15))) {
  stop("The report requires the documented 15% text sample.", call. = FALSE)
}

fmt_count <- function(x) formatC(as.integer(round(x)), format = "d", big.mark = ".", decimal.mark = ",")
fmt_pct <- function(x, digits = 1L) paste0(fmt_decimal(x, digits), " %")
fmt_pp <- function(x, digits = 1L, signed = TRUE) {
  paste0(fmt_decimal(x, digits, signed = signed), " postotnih bodova")
}
month_genitive <- c(
  "siječnja", "veljače", "ožujka", "travnja", "svibnja", "lipnja",
  "srpnja", "kolovoza", "rujna", "listopada", "studenoga", "prosinca"
)
format_hr_date <- function(x) {
  x <- as.Date(x)
  paste0(
    as.integer(format(x, "%d")), ". ",
    month_genitive[as.integer(format(x, "%m"))], " ", format(x, "%Y"), "."
  )
}
actor_value <- function(dt, key, column) {
  value <- dt[actor_group == key, get(column)]
  if (length(value)) value[[1L]] else 0
}
actor_share_object <- function(dt) {
  total <- dt[, sum(posts)]
  values <- vapply(actor_levels, function(key) {
    if (total > 0) 100 * actor_value(dt, key, "posts") / total else 0
  }, numeric(1))
  as.list(stats::setNames(values, actor_levels))
}

say("01_corpus | reading the official corpus without AUTHOR or URL")
corpus_manifest_path <- file.path("data", "digikat_corpus_manifest.json")
corpus_manifest <- jsonlite::read_json(corpus_manifest_path, simplifyVector = TRUE)
if (!identical(sample_manifest$input$corpus$sha256, corpus_manifest$corpus$sha256)) {
  stop("The private 15% generation was built from a different corpus.", call. = FALSE)
}
corpus_path <- digikat_corpus_path()
if (!file.exists(corpus_path)) stop("DigiKat corpus was not found: ", corpus_path, call. = FALSE)
if (!identical(digikat_hash_file(corpus_path), corpus_manifest$corpus$sha256)) {
  stop("The corpus hash differs from data/digikat_corpus_manifest.json.", call. = FALSE)
}

corpus_raw <- readRDS(corpus_path)
required <- c("DATE", "FROM", "SOURCE_TYPE", "INTERACTIONS", "FULL_TEXT")
missing_required <- setdiff(required, names(corpus_raw))
if (length(missing_required)) stop("Corpus lacks: ", paste(missing_required, collapse = ", "), call. = FALSE)
corpus <- as.data.table(corpus_raw)[, ..required]
rm(corpus_raw)
invisible(gc())

corpus[, `:=`(
  row_id = .I,
  DATE = as.Date(DATE),
  source_type = tolower(trimws(as.character(SOURCE_TYPE))),
  interactions = safe_numeric(INTERACTIONS)
)]
classification <- classify_actor_details(corpus$FROM)
corpus[, `:=`(
  actor_group = classification$actor_group,
  actor_rule = classification$actor_rule,
  platform_group = platform_group(SOURCE_TYPE),
  interaction_observed = !is.na(interactions),
  period = display_period(DATE),
  halfyear = period_id(DATE),
  source_key = normalise_key(FROM)
)]
rm(classification)
corpus[is.na(interactions) | interactions < 0, interactions := 0]

periods <- c("2021.", "2022.", "2023.", "2024.", "2025.", "2026. do lipnja")
corpus <- corpus[period %in% periods]
if (nrow(corpus) != corpus_manifest$corpus$rows) stop("Unexpected corpus row loss.", call. = FALSE)

actor_period <- corpus[, .(posts = .N, interactions = sum(interactions)), by = .(period, actor_group)]
actor_total <- corpus[, .(posts = .N, interactions = sum(interactions)), by = actor_group]
interaction_observed_pct <- 100 * corpus[, mean(interaction_observed)]
actor_rule_audit <- corpus[, .(
  posts = .N, interactions = sum(interactions), sources = uniqueN(FROM)
), by = .(actor_group, actor_rule)][order(actor_group, -posts)]
actor_source_audit <- corpus[, .(
  posts = .N,
  interactions = sum(interactions),
  platforms = paste(sort(unique(SOURCE_TYPE)), collapse = "|")
), by = .(actor_group, actor_rule, source = FROM)][order(actor_group, -posts, source)]

anchor_path <- file.path(archive_dir, "okvir", "actor_totals.csv")
if (!file.exists(anchor_path)) stop("Pre-merge actor anchor was not found.", call. = FALSE)
anchor <- fread(anchor_path, encoding = "UTF-8")
anchor_match <- identical(as.character(actor_total$actor_group), as.character(anchor$actor_group)) &&
  identical(as.integer(actor_total$posts), as.integer(anchor$posts)) &&
  isTRUE(all.equal(as.numeric(actor_total$interactions), as.numeric(anchor$interactions)))
if (!anchor_match) stop("Actor totals differ from the pre-merge anchor.", call. = FALSE)

actor_shares <- lapply(periods, function(period_value) {
  row <- actor_period[period == period_value]
  post_values <- row$posts[match(actor_levels, row$actor_group)]
  interaction_values <- row$interactions[match(actor_levels, row$actor_group)]
  post_values[is.na(post_values)] <- 0
  interaction_values[is.na(interaction_values)] <- 0
  list(
    period = period_value,
    posts = normalise_share(post_values),
    interactions = normalise_share(interaction_values)
  )
})

fwrite(actor_period, file.path(output_dir, "actor_period.csv"), bom = TRUE)
fwrite(actor_total, file.path(output_dir, "actor_totals.csv"), bom = TRUE)
fwrite(actor_rule_audit, file.path(output_dir, "actor_classification_rules.csv"), bom = TRUE)
fwrite(actor_source_audit, file.path(private_dir, "actor_source_audit.csv"), bom = TRUE)

say("02_events | detecting daily peaks, event composition and repeated liturgical rhythm")
event_layer <- build_daily_arcs(corpus, years = 2021:2026)
date_min <- event_layer$date_min
date_max <- event_layer$date_max
daily <- event_layer$daily
gaps <- event_layer$gaps
arcs <- event_layer$arcs
events <- event_layer$events
fwrite(daily, file.path(output_dir, "daily_volume.csv"), bom = TRUE)
fwrite(arcs, file.path(output_dir, "event_arcs.csv"), bom = TRUE)
fwrite(gaps, file.path(output_dir, "collection_gaps.csv"), bom = TRUE)

named_arcs <- arcs[label != "Događaj nije prepoznat"][order(-peak_z)]
top_named_arcs <- named_arcs[seq_len(min(8L, .N))]
if (!nrow(top_named_arcs)) stop("No named event peaks were detected.", call. = FALSE)

event_actor_daily <- corpus[, .(posts = .N), by = .(DATE, actor_group)]
baseline_mix <- copy(actor_total[, .(actor_group, posts)])
event_composition <- list(list(
  key = "baseline",
  label = "Sve objave",
  period = paste0(format_hr_date(date_min), " – ", format_hr_date(date_max)),
  type = "baseline",
  startDate = as.character(date_min),
  endDate = as.character(date_max),
  peakDate = NULL,
  peakZ = NULL,
  posts = baseline_mix[, sum(posts)],
  shares = actor_share_object(baseline_mix)
))
event_mix_rows <- list()
for (i in seq_len(nrow(top_named_arcs))) {
  arc <- top_named_arcs[i]
  mix <- event_actor_daily[
    DATE >= arc$start_date & DATE <= arc$end_date,
    .(posts = sum(posts)), by = actor_group
  ]
  mix <- data.table(actor_group = actor_levels)[mix, on = "actor_group"]
  mix[is.na(posts), posts := 0L]
  mix[, `:=`(
    event_key = paste0("event-", i),
    event_label = arc$label,
    period = format_hr_date(arc$peak_date),
    event_type = arc$type,
    peak_z = arc$peak_z
  )]
  event_mix_rows[[i]] <- copy(mix)
  event_composition[[length(event_composition) + 1L]] <- list(
    key = paste0("event-", i),
    label = arc$label,
    period = format_hr_date(arc$peak_date),
    type = arc$type,
    startDate = as.character(arc$start_date),
    endDate = as.character(arc$end_date),
    peakDate = as.character(arc$peak_date),
    peakZ = arc$peak_z,
    posts = mix[, sum(posts)],
    shares = actor_share_object(mix)
  )
}
event_mix_table <- rbindlist(event_mix_rows)
fwrite(event_mix_table, file.path(output_dir, "event_composition.csv"), bom = TRUE)

# Load the two shared registries so schema drift is caught centrally. The rhythm
# estimate intentionally keeps the original four repeated feast families from
# build_daily_arcs(), preserving the pre-merge model byte-for-byte.
calendar_registries <- load_event_calendars()
liturgical_events <- events[type == "liturgical" & date >= date_min & date <= date_max]
papal_dates <- events[type == "papal" & date >= date_min & date <= date_max, date]
if (length(papal_dates)) {
  liturgical_events <- liturgical_events[
    !vapply(date, function(x) any(abs(as.integer(x - papal_dates)) <= 4L), logical(1))
  ]
}
liturgical_window_dates <- unique(as.Date(
  unlist(lapply(liturgical_events$date, function(x) x + (-2L:2L))),
  origin = "1970-01-01"
))
valid_dates <- daily[collected == TRUE & date >= date_min & date <= date_max, unique(date)]
platform_levels <- c("web", "facebook", "video", "other")
daily_counts <- corpus[, .(posts = .N), by = .(date = DATE, actor_group, platform_group)]
panel <- CJ(
  date = valid_dates,
  actor_group = actor_levels,
  platform_group = platform_levels,
  unique = TRUE
)
panel <- daily_counts[panel, on = c("date", "actor_group", "platform_group")]
panel[is.na(posts), posts := 0L]
panel[, `:=`(
  liturgical_window = date %in% liturgical_window_dates,
  weekday = as.integer(format(date, "%u")),
  halfyear = period_id(date),
  week_block = as.integer(as.integer(date - min(date)) %/% 7L)
)]
available_platforms <- corpus[, .N, by = .(actor_group, platform_group)]
panel <- available_platforms[panel, on = c("actor_group", "platform_group"), nomatch = 0L]
rhythm_effects <- rbindlist(lapply(seq_along(actor_levels), function(i) {
  actor_key <- actor_levels[[i]]
  estimate <- fit_rhythm(panel[actor_group == actor_key], seed = 20260819L + i)
  data.table(
    actor_group = actor_key,
    estimate = estimate$estimate,
    lower = estimate$lower,
    upper = estimate$upper,
    status = if (estimate$lower > 0) "higher" else if (estimate$upper < 0) "lower" else "unclear"
  )
}))
fwrite(rhythm_effects, file.path(output_dir, "rhythm_effects.csv"), bom = TRUE)

say("03_themes | assigning the canonical categories to all posts with text")
has_text <- !is.na(corpus$FULL_TEXT) & nzchar(trimws(corpus$FULL_TEXT))
theme_input <- corpus[has_text, .(row_id, text = substr(FULL_TEXT, 1L, 3000L))]
theme_fingerprint <- digikat_hash_object(list(
  corpus_sha256 = corpus_manifest$corpus$sha256,
  dictionaries = digikat_thematic_dictionaries,
  selected_rows = theme_input$row_id,
  window = 3000L
))
theme_rows <- classify_themes(
  theme_input,
  file.path(private_dir, "full-corpus-themes"),
  theme_fingerprint
)
theme_meta <- corpus[has_text, .(
  row_id, actor_group, platform_group, source_type, source_key
)]
theme_rows <- theme_meta[theme_rows, on = "row_id"]
theme_rows[, theme := unname(theme_map$theme[match(category, theme_map$category)])]

theme_coverage <- theme_rows[, .(
  text_posts = .N,
  recognised_posts = sum(category != "not_recognised")
), by = actor_group]
theme_coverage[, recognised_share := 100 * recognised_posts / text_posts]
theme_coverage <- theme_coverage[match(actor_levels, actor_group)]
fallback_web <- any(theme_coverage$recognised_share < 60)
theme_basis <- if (fallback_web) theme_rows[platform_group == "web"] else theme_rows
theme_basis_label <- if (fallback_web) "web-only" else "all-platforms"

complete_theme_actor <- function(rows) {
  counts <- rows[!is.na(theme), .(posts = .N), by = .(actor_group, theme)]
  grid <- CJ(actor_group = actor_levels, theme = theme_levels, unique = TRUE)
  out <- merge(grid, counts, by = c("actor_group", "theme"), all.x = TRUE, sort = FALSE)
  out[is.na(posts), posts := 0L]
  out[, share := if (sum(posts) > 0) 100 * posts / sum(posts) else 0, by = actor_group]
  out[, `:=`(label = unname(theme_labels[theme]), color = unname(theme_colors[theme]))]
  out[, actor_order := match(actor_group, actor_levels)]
  out[, theme_order := match(theme, theme_levels)]
  setorder(out, actor_order, theme_order)
  out[, c("actor_order", "theme_order") := NULL]
  out[]
}
theme_by_actor_all <- complete_theme_actor(theme_rows)
theme_by_actor_web <- complete_theme_actor(theme_rows[platform_group == "web"])
theme_by_actor <- if (fallback_web) theme_by_actor_web else theme_by_actor_all
fwrite(theme_by_actor, file.path(output_dir, "theme_by_actor.csv"), bom = TRUE)
fwrite(theme_by_actor_web, file.path(output_dir, "theme_by_actor_web.csv"), bom = TRUE)
fwrite(theme_coverage, file.path(output_dir, "theme_recognition.csv"), bom = TRUE)

catholic_actor_groups <- c("official", "independent", "creator")
comparison_rows <- copy(theme_basis[actor_group %in% c(catholic_actor_groups, "public")])
comparison_rows[, comparison_group := ifelse(actor_group == "public", "outside", "catholic")]

category_observed <- comparison_rows[category != "not_recognised", .(posts = .N), by = .(comparison_group, category)]
category_counts <- merge(
  CJ(comparison_group = c("catholic", "outside"), category = names(category_labels), unique = TRUE),
  category_observed,
  by = c("comparison_group", "category"),
  all.x = TRUE,
  sort = FALSE
)
category_counts[is.na(posts), posts := 0L]
category_counts[, share := 100 * posts / sum(posts), by = comparison_group]
category_wide <- dcast(category_counts, category ~ comparison_group, value.var = c("posts", "share"), fill = 0)
setnames(
  category_wide,
  c("posts_catholic", "posts_outside", "share_catholic", "share_outside"),
  c("catholic_posts", "outside_posts", "catholic_share", "outside_share")
)
category_wide[, `:=`(
  label = unname(category_labels[category]),
  gap = outside_share - catholic_share,
  abs_gap = abs(outside_share - catholic_share)
)]
setorder(category_wide, -abs_gap, category)
category_wide[, abs_gap := NULL]
fwrite(category_wide, file.path(output_dir, "category_gap.csv"), bom = TRUE)

theme_observed <- comparison_rows[!is.na(theme), .(posts = .N), by = .(comparison_group, theme)]
theme_counts <- merge(
  CJ(comparison_group = c("catholic", "outside"), theme = theme_levels, unique = TRUE),
  theme_observed,
  by = c("comparison_group", "theme"),
  all.x = TRUE,
  sort = FALSE
)
theme_counts[is.na(posts), posts := 0L]
theme_counts[, share := 100 * posts / sum(posts), by = comparison_group]
theme_selection <- dcast(theme_counts, theme ~ comparison_group, value.var = c("posts", "share"), fill = 0)
setnames(
  theme_selection,
  c("posts_catholic", "posts_outside", "share_catholic", "share_outside"),
  c("catholic_posts", "outside_posts", "catholic_share", "outside_share")
)
theme_selection[, `:=`(
  label = unname(theme_labels[theme]),
  color = unname(theme_colors[theme]),
  gap = outside_share - catholic_share
)]
theme_selection[, theme_order := match(theme, theme_levels)]
setorder(theme_selection, theme_order)
theme_selection[, theme_order := NULL]
fwrite(theme_selection, file.path(output_dir, "theme_selection.csv"), bom = TRUE)

panel_registry_path <- file.path(analysis_dir, "secular_outlets.csv")
panel_registry <- fread(panel_registry_path, encoding = "UTF-8", na.strings = c("", "NA"))
panel_keys <- normalise_key(panel_registry[tolower(trimws(publish)) == "yes", from])
panel_theme_rows <- theme_rows[
  platform_group == "web" & actor_group == "public" & source_key %in% panel_keys & !is.na(theme),
  .(posts = .N), by = theme
]
panel_theme_rows[, `:=`(
  universe = "curated_general_news_panel",
  share = 100 * posts / sum(posts)
)]
group4_web_rows <- theme_rows[
  platform_group == "web" & actor_group == "public" & !is.na(theme),
  .(posts = .N), by = theme
]
group4_web_rows[, `:=`(
  universe = "group4_web",
  share = 100 * posts / sum(posts)
)]
general_panel_comparison <- rbindlist(list(panel_theme_rows, group4_web_rows), use.names = TRUE, fill = TRUE)
general_panel_comparison[, label := unname(theme_labels[theme])]
setcolorder(general_panel_comparison, c("universe", "theme", "label", "posts", "share"))
fwrite(general_panel_comparison, file.path(output_dir, "general_panel_comparison.csv"), bom = TRUE)

full_half_actor <- corpus[, .(
  n = .N,
  official = sum(actor_group == "official")
), by = .(halfyear, platform_group)]
corpus_rows <- nrow(corpus)
rm(corpus, theme_input, theme_meta, panel_registry)
invisible(gc())

say("04_text_measures | calculating tone, RIK and the binary sharp split on the 15% sample")
sample_raw <- readRDS(sample_path)
sample_required <- c("doc_id", "DATE", "SOURCE_TYPE", "FROM", "INTERACTIONS", "TITLE", "FULL_TEXT")
sample_missing <- setdiff(sample_required, names(sample_raw))
if (length(sample_missing)) stop("Text sample lacks: ", paste(sample_missing, collapse = ", "), call. = FALSE)
sample <- as.data.table(sample_raw)[, ..sample_required]
rm(sample_raw)
tokens <- as.data.table(readRDS(tokens_path))
if (!identical(as.integer(sample_manifest$sample$rows), nrow(sample))) {
  stop("The sample row count differs from its manifest.", call. = FALSE)
}
if (!identical(as.integer(sample_manifest$tokens$rows), nrow(tokens))) {
  stop("The token row count differs from its manifest.", call. = FALSE)
}
sample[, DATE := as.Date(DATE)]
sample_actor <- classify_actor_details(sample$FROM)
sample[, `:=`(
  actor_group = sample_actor$actor_group,
  actor_rule = sample_actor$actor_rule,
  platform_group = platform_group(SOURCE_TYPE),
  halfyear = period_id(DATE),
  interactions = safe_numeric(INTERACTIONS)
)]
rm(sample_actor)
sample[is.na(interactions) | interactions < 0, interactions := 0]
sample[, c("primary_frame", "frame_score") := score_frames(TITLE, FULL_TEXT)]
sample[, sharp := sharp_frame(primary_frame)]

sample_theme_input <- sample[, .(row_id = doc_id, text = substr(FULL_TEXT, 1L, 3000L))]
sample_theme_fingerprint <- digikat_hash_object(list(
  sample_sha256 = digikat_hash_file(sample_path),
  dictionaries = digikat_thematic_dictionaries,
  window = 3000L
))
sample_theme_rows <- classify_themes(
  sample_theme_input,
  file.path(private_dir, "sample-themes"),
  sample_theme_fingerprint
)
sample[, category := sample_theme_rows$category[match(doc_id, sample_theme_rows$row_id)]]
sample[, theme := unname(theme_map$theme[match(category, theme_map$category)])]

measures <- compute_text_measures(sample, tokens, expected_topic = "primary_frame")
docs <- sample[, .(
  doc_id, DATE, halfyear, platform_group, FROM, actor_group,
  primary_frame, sharp, category, theme, interactions
)]
docs <- measures[docs, on = "doc_id"]
rm(tokens, measures, sample_theme_input)
invisible(gc())

sharp_by_actor <- docs[, .(
  posts = .N,
  sharp_posts = sum(sharp),
  interactions = sum(interactions),
  sharp_interactions = sum(interactions[sharp])
), by = actor_group]
sharp_by_actor[, `:=`(
  post_share = 100 * sharp_posts / posts,
  interaction_share = ifelse(interactions > 0, 100 * sharp_interactions / interactions, 0)
)]
sharp_by_actor <- sharp_by_actor[match(actor_levels, actor_group)]
fwrite(sharp_by_actor, file.path(output_dir, "sharp_by_actor.csv"), bom = TRUE)

MIN_CELL <- 20L
heat_observed <- docs[!is.na(theme), .(
  n = .N,
  tone = mean(tone),
  rik = mean(rik)
), by = .(theme, actor_group)]
heat_grid <- CJ(theme = theme_levels, actor_group = actor_levels, unique = TRUE)
heat <- merge(heat_grid, heat_observed, by = c("theme", "actor_group"), all.x = TRUE, sort = FALSE)
heat[is.na(n), n := 0L]
heat[, reportable := n >= MIN_CELL]
heat[reportable == FALSE, c("tone", "rik") := .(NA_real_, NA_real_)]
heat[, `:=`(
  theme_label = unname(theme_labels[theme]),
  actor_label = unname(actor_labels[actor_group])
)]
heat[, theme_order := match(theme, theme_levels)]
heat[, actor_order := match(actor_group, actor_levels)]
setorder(heat, theme_order, actor_order)
heat[, c("theme_order", "actor_order") := NULL]
fwrite(heat, file.path(output_dir, "tone_rik_by_theme_actor.csv"), bom = TRUE)

say("05_trends | fitting within-era trends only")
full_half_actor[, value := 100 * official / n]
tone_cells <- docs[, .(n = .N, value = mean(tone)), by = .(halfyear, platform_group)]
rik_cells <- docs[, .(n = .N, value = mean(rik)), by = .(halfyear, platform_group)]
sharp_cells <- docs[, .(n = .N, value = 100 * mean(sharp)), by = .(halfyear, platform_group)]
full_half_actor <- complete_cells(full_half_actor, min_n = 30L)
tone_cells <- complete_cells(tone_cells)
rik_cells <- complete_cells(rik_cells)
sharp_cells <- complete_cells(sharp_cells)

pre_tone <- fit_slope(tone_cells, era = "pre")
post_tone <- fit_slope(tone_cells, era = "post")
pre_rik <- fit_slope(rik_cells, era = "pre")
post_rik <- fit_slope(rik_cells, era = "post")
pre_official <- fit_slope(full_half_actor, era = "pre")
post_official <- fit_slope(full_half_actor, era = "post")
pre_sharp <- fit_slope(sharp_cells, era = "pre")
post_sharp <- fit_slope(sharp_cells, era = "post")

i1_components <- c(status_adverse(post_tone, "down"), status_adverse(post_rik, "up"))
i1_status <- if ("worse" %in% i1_components) "worse" else if (all(i1_components == "better")) "better" else "stable"
i2_status <- status_adverse(post_official, "down")
i3_status <- status_adverse(post_sharp, "up")
trend_diagnostics <- rbindlist(list(
  data.table(indicator = "I1_tone", era = c("pre", "post"), rbind(pre_tone, post_tone)),
  data.table(indicator = "I1_rik", era = c("pre", "post"), rbind(pre_rik, post_rik)),
  data.table(indicator = "I2", era = c("pre", "post"), rbind(pre_official, post_official)),
  data.table(indicator = "I3", era = c("pre", "post"), rbind(pre_sharp, post_sharp))
), fill = TRUE)
fwrite(trend_diagnostics, file.path(output_dir, "trend_estimates.csv"), bom = TRUE)

web_trend <- trend_series(full_half_actor)[[match("web", trend_platform_levels)]]
church_media_trend <- list(
  title = "Koliki dio web-objava dolazi iz crkvenih medija i ustanova?",
  unit = "udio web objava (%)",
  yMin = 0,
  yMax = 40,
  yTicks = c(0, 10, 20, 30, 40),
  series = web_trend
)

say("06_verdict | composing the status-driven title and synthesis")
verdict <- build_verdict(
  i2_status,
  i1_status,
  estimates = list(post_official = post_official, post_rik = post_rik)
)
stub_grid <- CJ(
  i2 = c("worse", "better", "stable"),
  i1 = c("worse", "stable"),
  unique = TRUE
)
stub_titles <- vapply(seq_len(nrow(stub_grid)), function(i) {
  build_verdict(stub_grid$i2[i], stub_grid$i1[i])$title
}, character(1))
if (uniqueN(stub_titles) != nrow(stub_grid)) {
  stop("Verdict-title stub test failed.", call. = FALSE)
}

top_arcs <- arcs[order(-peak_z)][seq_len(min(8L, .N))]
peak_table <- rbindlist(lapply(seq_len(nrow(top_arcs)), function(i) {
  arc <- top_arcs[i]
  tone_window <- docs[DATE >= arc$start_date & DATE <= arc$end_date]
  year_value <- as.integer(format(arc$peak_date, "%Y"))
  year_tone <- docs[as.integer(format(DATE, "%Y")) == year_value, mean(tone)]
  data.table(
    period = paste0(month_genitive[as.integer(format(arc$peak_date, "%m"))], " ", year_value, "."),
    event = arc$label,
    type = arc$type,
    tone_shift = if (nrow(tone_window) >= 8L) mean(tone_window$tone) - year_tone else NA_real_,
    sampled_documents = nrow(tone_window),
    peak_z = arc$peak_z,
    peak_posts = arc$peak_posts,
    peak_date = as.character(arc$peak_date)
  )
}))
fwrite(peak_table, file.path(output_dir, "event_table.csv"), bom = TRUE)

actor_posts_leader <- actor_total[which.max(posts)]
actor_interactions_leader <- actor_total[which.max(interactions)]
actor_posts_leader_share <- 100 * actor_posts_leader$posts / actor_total[, sum(posts)]
actor_interactions_leader_share <- 100 * actor_interactions_leader$interactions / actor_total[, sum(interactions)]

overall_themes <- theme_basis[!is.na(theme), .(posts = .N), by = theme]
overall_themes[, share := 100 * posts / sum(posts)]
leading_theme <- overall_themes[which.max(share)]
largest_gap <- category_wide[which.max(abs(gap))]

overall_sharp_post <- 100 * mean(docs$sharp)
overall_sharp_interaction <- 100 * sum(docs$interactions[docs$sharp]) / sum(docs$interactions)
reportable_heat <- heat[reportable == TRUE]
if (!nrow(reportable_heat)) stop("No tone/RIK heatmap cell is reportable.", call. = FALSE)
max_rik_cell <- reportable_heat[which.max(rik)]

largest_peak <- arcs[which.max(peak_z)]
baseline_shares <- vapply(actor_levels, function(key) {
  100 * actor_value(actor_total, key, "posts") / actor_total[, sum(posts)]
}, numeric(1))
composition_deviations <- copy(event_mix_table)
composition_deviations[, event_total := sum(posts), by = event_key]
composition_deviations[, share := 100 * posts / event_total]
composition_deviations[, baseline_share := baseline_shares[actor_group]]
composition_deviations[, difference := share - baseline_share]
largest_composition_shift <- composition_deviations[which.max(abs(difference))]
most_responsive <- rhythm_effects[which.max(estimate)]
creator_total <- actor_total[actor_group == "creator"]
creator_post_share <- 100 * creator_total$posts / actor_total[, sum(posts)]
creator_interaction_share <- 100 * creator_total$interactions / actor_total[, sum(interactions)]
public_sharp <- sharp_by_actor[actor_group == "public"]
creator_faith <- theme_by_actor[actor_group == "creator" & theme == "faith"]
public_faith <- theme_by_actor[actor_group == "public" & theme == "faith"]
newer_web_values <- as.numeric(unlist(church_media_trend$series$post, use.names = FALSE))
if (length(newer_web_values) != 4L || any(!is.finite(newer_web_values))) {
  stop("Unexpected newer web-series values.", call. = FALSE)
}

verdict$title <- "Većina razgovora o Crkvi odvija se izvan katoličkih izvora"
verdict$summary <- paste0(
  "Od svakih deset objava o Crkvi približno šest dolazi iz ostalih medija i javnih izvora. ",
  "Ta skupina dobiva i ", fmt_pct(actor_interactions_leader_share), " svih zabilježenih reakcija."
)
verdict$estimateNote <- paste0(
  "Kada veliki događaji privuku širu pozornost, njezin udio raste još više. ",
  "U razdoblju smrti pape Franje dosegnuo je ", fmt_pct(largest_composition_shift$share), "."
)

coverage_text <- paste(vapply(actor_levels, function(key) {
  row <- theme_coverage[actor_group == key]
  paste0(actor_definitions[[key]]$short, " ", fmt_pct(row$recognised_share))
}, character(1)), collapse = ", ")

narrative <- list(
  actor = paste0(
    "Većina digitalnog razgovora o Crkvi odvija se izvan katoličkih izvora. Ostali mediji i javni izvori objavljuju ",
    fmt_pct(actor_posts_leader_share), " sadržaja i dobivaju ", fmt_pct(actor_interactions_leader_share),
    " svih zabilježenih reakcija. Vjerski stvaratelji ističu se drukčije. Objavljuju ",
    fmt_pct(creator_post_share), " sadržaja, ali dobivaju ", fmt_pct(creator_interaction_share), " reakcija."
  ),
  themes = paste0(
    "Vjera i duhovni život vodeća su tema u sve četiri skupine. Na njih otpada ",
    fmt_pct(leading_theme$share), " svih objava. Kod vjerskih stvaratelja čine ",
    fmt_pct(creator_faith$share), ", odnosno približno četiri od pet objava. Ostali javni izvori biraju raznovrsnije teme, ",
    "ali i kod njih vjera i duhovni život ostaju na prvome mjestu s ", fmt_pct(public_faith$share), "."
  ),
  categoryGap = paste0(
    "Najveća razlika vidi se kod teme „", largest_gap$label, "”. Ona čini ",
    fmt_pct(largest_gap$catholic_share), " objava katoličkih izvora i ", fmt_pct(largest_gap$outside_share),
    " objava ostalih javnih izvora. To je približno ", fmt_decimal(abs(largest_gap$gap), 0),
    " objava više na svakih 100 objava katoličkih izvora. Sve druge razlike mnogo su manje."
  ),
  sharp = paste0(
    "Takav je rječnik rijedak. Pojavljuje se u približno četiri od 100 objava, odnosno u ",
    fmt_pct(overall_sharp_post), ", ali na te objave otpada ", fmt_pct(overall_sharp_interaction),
    " zabilježenih reakcija. Razlika je najvidljivija kod ostalih javnih izvora. Ondje oštriji govor čini ",
    fmt_pct(public_sharp$post_share), " objava, ali dobiva ", fmt_pct(public_sharp$interaction_share), " reakcija."
  ),
  tone = paste0(
    "Najviše riječi sukoba u odnosu na uobičajenu razinu pojavljuje se u objavama ostalih javnih izvora o zlostavljanju i krizi povjerenja. ",
    "To je razumljivo jer sama tema često uključuje riječi povezane sa skandalom, optužbama, istragama i krizom. ",
    "Objave o vjeri i duhovnom životu u prosjeku su pozitivnije i imaju manje riječi sukoba."
  ),
  peaks = paste0(
    "Najviše se objavljivalo ", format_hr_date(largest_peak$peak_date), " Bio je to dan smrti pape Franje. ",
    "Toga je dana zabilježeno ", fmt_count(largest_peak$peak_posts), " objava. Drugi veliki porasti uglavnom prate Božić, Uskrs i Veliku Gospu. ",
    "Ritam razgovora o Crkvi tako snažno prati velike blagdane i papinske događaje."
  ),
  composition = paste0(
    "U svih osam prikazanih događaja ostali mediji i javni izvori zauzimaju veći dio prostora nego u cijelom razdoblju. ",
    "Najizraženije je to uz smrt pape Franje. Njihov udio tada raste s ", fmt_pct(actor_posts_leader_share),
    " na ", fmt_pct(largest_composition_shift$share), " objava. Veliki događaji tako razgovor o Crkvi snažno šire izvan katoličkih kanala."
  ),
  rhythm = paste0(
    "Oko Uskrsa, Velike Gospe, Svih svetih i Božića ostali mediji i javni izvori objavljuju približno ",
    fmt_pct(most_responsive$estimate), " više nego inače. Kod triju katoličkih skupina promjene su male i nisu dovoljno jasne. ",
    "Veliki blagdani zato ponajprije uvode temu Crkve u širi javni razgovor."
  ),
  trend = paste0(
    "Crkveni mediji i ustanove činili su približno trećinu web-objava tijekom 2022. i 2023. U novijem dijelu niza njihov udio pada s ",
    fmt_pct(newer_web_values[1]), " u drugoj polovici 2024. na ", fmt_pct(newer_web_values[2]),
    " u prvoj polovici 2025. U sljedeća dva polugodišta ostaje oko ", fmt_pct(mean(newer_web_values[3:4])),
    ". To znači da približno svaka peta web-objava o Crkvi dolazi iz njezinih medija i ustanova."
  )
)

synthesis <- c(
  paste0("Ostali mediji i javni izvori nose većinu razgovora. Objavljuju ", fmt_pct(actor_posts_leader_share), " sadržaja o Crkvi."),
  paste0("Vjera i duhovni život najčešća su tema s ", fmt_pct(leading_theme$share), " objava, a osobito su važni vjerskim stvarateljima."),
  paste0("Oštriji govor ostaje rijedak s ", fmt_pct(overall_sharp_post), " objava, ali dobiva nešto veći udio reakcija od ", fmt_pct(overall_sharp_interaction), "."),
  paste0("Veliki blagdani i papinski događaji šire razgovor prema općoj javnosti. Uz smrt pape Franje ostali javni izvori objavili su ", fmt_pct(largest_composition_shift$share), " sadržaja."),
  paste0("U posljednja dva prikazana polugodišta približno svaka peta web-objava dolazi iz crkvenih medija i ustanova.")
)
capability_sentence <- paste0(
  "Za crkvene komunikatore glavni je signal jednostavan. Svakodnevni duhovni razgovor ostaje najbliži katoličkim izvorima, ",
  "dok veliki blagdani i papinski događaji temu Crkve brzo pretvaraju u razgovor cijele javnosti."
)

event_type_definitions <- list(
  liturgical = list(label = "Liturgijski", color = "#2f8f6b", shape = "circle"),
  papal = list(label = "Papinski", color = "#0f4c5c", shape = "square"),
  political = list(label = "Politički spor", color = "#3f4fa0", shape = "diamond"),
  scandal = list(label = "Sukob ili skandal", color = "#b5462f", shape = "triangle"),
  other = list(label = "Događaj nije prepoznat", color = "#92969c", shape = "ring"),
  baseline = list(label = "Sve objave", color = "#7d878c", shape = "line")
)

actor_totals_list <- lapply(actor_levels, function(key) {
  row <- actor_total[actor_group == key]
  definition <- actors[[match(key, actor_levels)]]
  list(
    key = key,
    label = definition$label,
    short = definition$short,
    color = definition$color,
    posts = row$posts,
    interactions = row$interactions,
    postShare = 100 * row$posts / actor_total[, sum(posts)]
  )
})
rhythm_list <- lapply(seq_len(nrow(rhythm_effects)), function(i) as.list(rhythm_effects[i]))

headline_numbers <- list(
  list(key = "actor_posts", figure = 1L, label = actor_labels[[actor_posts_leader$actor_group]], value = actor_posts_leader_share, unit = "% objava"),
  list(key = "leading_theme", figure = 2L, label = theme_labels[[leading_theme$theme]], value = leading_theme$share, unit = "% objava"),
  list(key = "category_gap", figure = 3L, label = largest_gap$label, value = largest_gap$gap, unit = "postotnih bodova"),
  list(key = "sharp_posts", figure = 4L, label = "Oštriji govor", value = overall_sharp_post, unit = "% objava"),
  list(key = "max_rik", figure = 5L, label = theme_labels[[max_rik_cell$theme]], value = max_rik_cell$rik, unit = "RIK bodova"),
  list(key = "largest_peak", figure = 6L, label = largest_peak$label, value = largest_peak$peak_posts, unit = "objava u danu"),
  list(key = "composition_shift", figure = 7L, label = actor_labels[[largest_composition_shift$actor_group]], value = largest_composition_shift$difference, unit = "postotnih bodova"),
  list(key = "rhythm", figure = 8L, label = actor_labels[[most_responsive$actor_group]], value = most_responsive$estimate, unit = "% promjene"),
  list(key = "web_trend", figure = 9L, label = "Noviji smjer udjela crkvenih web objava", value = post_official[["estimate"]], unit = "postotnih bodova po polugodištu")
)

say("07_write | reconciling and writing aggregate-only public results")
reconciliation_paths <- data.table(
  artifact = c("actor_totals", "event_arcs", "rhythm_effects", "theme_selection"),
  premerge_path = c(
    file.path(archive_dir, "okvir", "actor_totals.csv"),
    file.path(archive_dir, "okvir", "event_arcs.csv"),
    file.path(archive_dir, "glas", "rhythm_effects.csv"),
    file.path(archive_dir, "pogled", "theme_selection.csv")
  ),
  merged_path = c(
    file.path(output_dir, "actor_totals.csv"),
    file.path(output_dir, "event_arcs.csv"),
    file.path(output_dir, "rhythm_effects.csv"),
    file.path(output_dir, "theme_selection.csv")
  ),
  expected = c("identical", "identical", "identical", "redefined")
)
reconciliation_paths[, `:=`(
  premerge_sha256 = vapply(premerge_path, digikat_hash_file, character(1)),
  merged_sha256 = vapply(merged_path, digikat_hash_file, character(1))
)]
reconciliation_paths[, identical := premerge_sha256 == merged_sha256]
reconciliation_paths[, note := fifelse(
  artifact == "theme_selection",
  "Intentional: group 4 replaces the curated general-news panel.",
  fifelse(identical, "Reproduced byte-for-byte.", "Unexpected difference.")
)]
fwrite(
  reconciliation_paths[, .(artifact, expected, identical, premerge_sha256, merged_sha256, note)],
  file.path(output_dir, "reconciliation.csv"),
  bom = TRUE
)
if (reconciliation_paths[expected == "identical", any(!identical)]) {
  bad <- reconciliation_paths[expected == "identical" & !identical, artifact]
  stop("Unexpected reconciliation difference: ", paste(bad, collapse = ", "), call. = FALSE)
}

scope_text <- paste0(
  "Objave od ", format(date_min, "%Y."), " do ", format_hr_date(date_max),
  " · istraživački korpus projekta DigiKat"
)
result <- list(
  meta = list(
    status = "merged_exploratory_analysis",
    generatedUtc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    corpusSha256 = corpus_manifest$corpus$sha256,
    corpusRows = corpus_rows,
    dateMin = as.character(date_min),
    dateMax = as.character(date_max),
    sampleRows = nrow(docs),
    sampleProportion = sample_proportion,
    interactionObservedPct = interaction_observed_pct,
    authorRead = FALSE,
    urlRead = FALSE,
    themeWindowCharacters = 3000L,
    themeBasis = theme_basis_label,
    themeFallbackWeb = fallback_web,
    topicMethod = "canonical 16-category dictionary collapsed to six reader-facing themes",
    sharpMethod = "binarna rječnička mjera oštrijega i ostaloga govora",
    trendModel = "weighted within-era half-year slopes with platform controls"
  ),
  scope = scope_text,
  actors = actors,
  actorTotals = actor_totals_list,
  themes = unname(lapply(theme_levels, function(key) list(
    key = key,
    label = unname(theme_labels[[key]]),
    color = unname(theme_colors[[key]])
  ))),
  periods = periods,
  actorShares = actor_shares,
  themeByActor = theme_by_actor,
  themeRecognition = theme_coverage,
  categoryGap = category_wide,
  sharpByActor = sharp_by_actor,
  toneRikByThemeActor = heat,
  eventTypes = event_type_definitions,
  dailyZ = event_layer$daily_z,
  peakEvents = event_layer$peak_events,
  collectionGaps = event_layer$collection_gaps,
  peakRows = peak_table,
  eventComposition = event_composition,
  rhythmEffects = rhythm_list,
  churchMediaTrend = church_media_trend,
  statuses = list(i1 = i1_status, i2 = i2_status, i3 = i3_status),
  findings = list(
    verdict = verdict,
    narrative = narrative,
    synthesis = as.list(synthesis),
    capability = capability_sentence,
    headlineNumbers = headline_numbers,
    themeBasis = theme_basis_label,
    recognisedThemePosts = theme_rows[category != "not_recognised", .N],
    heatmapMinCell = MIN_CELL,
    heatmapReportableCells = sum(heat$reportable),
    heatmapTotalCells = nrow(heat),
    namedPeakCount = nrow(named_arcs),
    displayedPeakCount = nrow(top_named_arcs),
    liturgicalEventsUsed = nrow(liturgical_events),
    reconciliation = lapply(seq_len(nrow(reconciliation_paths)), function(i) {
      as.list(reconciliation_paths[i, .(artifact, expected, identical, note)])
    })
  ),
  method = list(
    themeCollapse = lapply(seq_len(nrow(theme_map)), function(i) list(
      category = unname(category_labels[[theme_map$category[i]]]),
      theme = unname(theme_labels[[theme_map$theme[i]]])
    )),
    liturgicalRegistryRows = nrow(calendar_registries$liturgical),
    politicalRegistryRows = nrow(calendar_registries$political),
    caveats = as.list(c(
      paste0("Izvještaj obuhvaća prikupljene objave do ", format_hr_date(date_max), " Ne opisuje cijeli internet ni svaku objavu o Crkvi."),
      "Skupina izvora govori tko stoji iza medija ili kanala. Ne ocjenjuje pouzdanost, crkveno odobrenje ni kvalitetu sadržaja.",
      "Teme, ton i jezik sukoba prepoznaju se prema riječima u tekstu. Ne otkrivaju namjeru autora ni istinitost objave.",
      "Reakcije nisu jednako definirane na svim platformama. Zato pokazuju zabilježeni odjek, a ne točan broj ljudi koji je sadržaj dosegnuo.",
      "Povezanost događaja i većeg broja objava opisuje vremensko podudaranje. Ne znači da je svaku objavu izazvao taj događaj."
    ))
  )
)

js_path <- file.path(output_dir, "analysis-data.js")
write_analysis_js(result, js_path)

summary_lines <- c(
  "KAKO SE GOVORI O CRKVI — MERGED ANALYSIS RUN",
  paste("Generated UTC:", result$meta$generatedUtc),
  paste("Corpus rows:", fmt_count(result$meta$corpusRows)),
  paste("Scope:", scope_text),
  paste("Discourse sample rows:", fmt_count(result$meta$sampleRows)),
  paste("Discourse sample proportion:", fmt_pct(100 * sample_proportion)),
  paste("Posts with observed interaction counts:", fmt_pct(interaction_observed_pct)),
  paste("Theme text window:", fmt_count(result$meta$themeWindowCharacters), "characters"),
  paste("Heatmap reporting threshold:", MIN_CELL, "posts"),
  paste("Heatmap reportable cells:", sum(heat$reportable), "of", nrow(heat)),
  paste("Repeated liturgical events used:", nrow(liturgical_events)),
  "Collection-method seam: 2024",
  "Rhythm exclusion: Easter 2025",
  paste("Theme basis:", theme_basis_label),
  paste("Theme fallback to web-only:", fallback_web),
  paste("Recognised theme share by group:", coverage_text),
  paste("I1 tone status:", i1_status),
  paste("I2 church-media web-share status:", i2_status),
  paste("I3 sharp-share status:", i3_status),
  paste("Verdict:", verdict$title),
  paste("Verdict summary:", verdict$summary),
  paste("Within-era estimate note:", verdict$estimateNote),
  paste("Largest reaction-share group:", actor_labels[[actor_interactions_leader$actor_group]], fmt_pct(actor_interactions_leader_share)),
  paste("Sharp-language interaction share:", fmt_pct(overall_sharp_interaction)),
  paste("Max-RIK cell posts:", fmt_count(max_rik_cell$n)),
  paste("Largest peak date:", format_hr_date(largest_peak$peak_date)),
  paste("Largest composition-shift event:", largest_composition_shift$event_label),
  paste("Rhythm interval:", fmt_pct(most_responsive$lower), "to", fmt_pct(most_responsive$upper)),
  "HEADLINE NUMBERS",
  vapply(headline_numbers, function(item) paste0(
    "F", item$figure, " | ", item$label, " | ",
    fmt_decimal(
      item$value,
      if (item$key == "largest_peak") 0 else 1,
      signed = item$key %in% c("category_gap", "max_rik", "composition_shift", "rhythm", "web_trend")
    ),
    " ", item$unit
  ), character(1)),
  "RECONCILIATION",
  vapply(seq_len(nrow(reconciliation_paths)), function(i) paste(
    reconciliation_paths$artifact[i],
    if (reconciliation_paths$identical[i]) "identical" else "different",
    reconciliation_paths$note[i],
    sep = " | "
  ), character(1))
)
writeLines(summary_lines, file.path(output_dir, "analysis-summary.txt"), useBytes = TRUE)

public_files <- c(
  js_path,
  file.path(output_dir, c(
    "actor_period.csv", "actor_totals.csv", "actor_classification_rules.csv",
    "daily_volume.csv", "event_arcs.csv", "collection_gaps.csv",
    "event_composition.csv", "event_table.csv", "rhythm_effects.csv",
    "theme_by_actor.csv", "theme_by_actor_web.csv", "theme_recognition.csv",
    "category_gap.csv", "theme_selection.csv", "general_panel_comparison.csv",
    "sharp_by_actor.csv", "tone_rik_by_theme_actor.csv", "trend_estimates.csv",
    "reconciliation.csv", "analysis-summary.txt"
  ))
)
root_public_files <- list.files(output_dir, full.names = TRUE, recursive = FALSE)
root_public_files <- root_public_files[tolower(tools::file_ext(root_public_files)) %in% c("csv", "js", "txt", "json")]
public_files <- unique(c(public_files, root_public_files))
if (!all(file.exists(public_files))) stop("A required public aggregate is missing.", call. = FALSE)
public_text <- paste(vapply(public_files, function(path) {
  paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
}, character(1)), collapse = "\n")
forbidden <- c("http://", "https://", "FULL_TEXT", "AUTHOR", "URL\"", "TITLE\"")
hits <- forbidden[vapply(forbidden, function(needle) grepl(needle, public_text, fixed = TRUE), logical(1))]
if (length(hits)) stop("Disclosure gate found: ", paste(hits, collapse = ", "), call. = FALSE)
if (grepl("Ã|Ä|Å|Â", public_text)) stop("Possible mojibake in a public output.", call. = FALSE)
public_csv <- public_files[tolower(tools::file_ext(public_files)) == "csv"]
forbidden_columns <- c("author", "url", "full_text", "title", "from", "source", "source_key", "text")
for (path in public_csv) {
  columns <- tolower(names(fread(path, nrows = 0L, encoding = "UTF-8")))
  bad_columns <- intersect(columns, forbidden_columns)
  if (length(bad_columns)) {
    stop("Disclosure gate found forbidden column(s) in ", path, ": ", paste(bad_columns, collapse = ", "), call. = FALSE)
  }
}

page_text <- paste(
  readLines(file.path(analysis_dir, "index.html"), encoding = "UTF-8", warn = FALSE),
  readLines(file.path(analysis_dir, "prototype.js"), encoding = "UTF-8", warn = FALSE),
  collapse = " "
)
if (grepl("Ã|Ä|Å|Â", page_text)) stop("Possible mojibake in the public page source.", call. = FALSE)
if (grepl("usluga|ponuda|klijent", page_text, ignore.case = TRUE)) {
  stop("Commercial vocabulary remains in the public page.", call. = FALSE)
}

stopifnot(
  result$meta$corpusRows == 413985L,
  length(result$actorShares) == length(periods),
  length(result$themes) == 6L,
  nrow(theme_by_actor) == 24L,
  nrow(heat) == 24L,
  nrow(sharp_by_actor) == 4L,
  length(result$eventComposition) == nrow(top_named_arcs) + 1L,
  nrow(rhythm_effects) == 4L,
  length(result$findings$synthesis) == 5L,
  file.info(js_path)$size > 20000
)

say("Merged analysis complete:", js_path)
cat(paste(summary_lines, collapse = "\n"), "\n")
