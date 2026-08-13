#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 1)

required_packages <- c("data.table", "stringi", "jsonlite", "ggplot2", "scales", "digest")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1L), quietly = TRUE)]
if (length(missing_packages)) {
  stop("Missing required package(s): ", paste(missing_packages, collapse = ", "), call. = FALSE)
}

suppressPackageStartupMessages({
  library(data.table)
  library(stringi)
  library(ggplot2)
})

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (!length(script_arg)) stop("Run this file with Rscript.", call. = FALSE)
script_path <- normalizePath(sub("^--file=", "", script_arg[[1L]]), winslash = "/", mustWork = TRUE)
study_dir <- dirname(script_path)
repo_root <- normalizePath(file.path(study_dir, "../.."), winslash = "/", mustWork = TRUE)

old_wd <- setwd(repo_root)
on.exit(setwd(old_wd), add = TRUE)

source("R/lib/digikat_paths.R", encoding = "UTF-8")
source("R/lib/thematic_dictionaries.R", encoding = "UTF-8")
source("R/theme_digikat.R", encoding = "UTF-8")

output_dir <- file.path(study_dir, "output")
figure_dir <- file.path(output_dir, "figures")
private_dir <- file.path(output_dir, "private")
intermediate_dir <- file.path(output_dir, "intermediate")
invisible(lapply(c(output_dir, figure_dir, private_dir, intermediate_dir), dir.create,
                 recursive = TRUE, showWarnings = FALSE))

# Publication was authorised by the PI on 2026-08-13 as a provisional editorial diagnostic.
# This status is deliberately distinct from `validated_for_publication`: human topic validation
# remains pending and no public surface may imply otherwise.
study_status <- "published_provisional_pending_manual_dictionary_validation"

params <- list(
  main_start = as.Date("2024-07-01"),
  main_engagement_end = as.Date("2025-12-31"),
  main_supply_end = as.Date("2026-01-31"),
  headline_start = as.Date("2025-02-01"),
  headline_end = as.Date("2025-12-31"),
  excluded_months = as.Date(c("2024-09-01", "2025-01-01", "2025-03-01", "2025-04-01",
                              "2025-05-01", "2025-09-01")),
  historical_start = as.Date("2021-01-01"),
  historical_end = as.Date("2023-12-31"),
  min_posts_month = 30L,
  min_posts_week = 7L,
  min_interaction_coverage = 0.95,
  min_positive_rate = 0.05,
  min_product_topic_posts = 20,
  min_product_topic_months = 6L,
  public_min_topic_posts = 20,
  validation_per_topic = 40L,
  classification_text_characters = 3000L,
  hac_lag = 2L,
  bootstrap_reps = as.integer(Sys.getenv("NEWS_GAP_BOOT_REPS", unset = "999")),
  random_seed = 20260813L
)

if (is.na(params$bootstrap_reps) || params$bootstrap_reps < 99L) {
  stop("NEWS_GAP_BOOT_REPS must be an integer of at least 99.", call. = FALSE)
}

registry_path <- file.path(study_dir, "source_registry.csv")
registry <- fread(registry_path, encoding = "UTF-8", na.strings = c("", "NA"))
registry[, `:=`(
  source_type_key = stri_trans_tolower(stri_trim_both(source_type)),
  raw_from_key = stri_trans_tolower(stri_trim_both(raw_from)),
  url_host_key = stri_trans_tolower(stri_trim_both(url_host))
)]
if (anyDuplicated(registry$product_id) ||
    anyDuplicated(registry[, .(source_type_key, raw_from_key, url_host_key)])) {
  stop("Source registry product IDs and join keys must be unique.", call. = FALSE)
}

topics <- names(digikat_thematic_dictionaries)
if (length(topics) != 16L || anyDuplicated(topics)) {
  stop("The canonical thematic dictionary is not a unique 16-topic dictionary.", call. = FALSE)
}

topic_display_labels <- c(
  DUHOVNOST_I_LITURGIJA = "Duhovnost i liturgija",
  TEOLOGIJA_I_DOKTRINA = "Teologija i doktrina",
  CRKVENO_UPRAVLJANJE_I_STRUKTURA = "Crkveno upravljanje i struktura",
  PAPE_I_VATIKAN = "Pape i Vatikan",
  CRKVENE_FINANCIJE_I_IMOVINA = "Crkvene financije i imovina",
  GLOBALNA_CRKVA_I_MISIJE = "Globalna Crkva i misije",
  POLITIKA_I_ODNOS_S_DRZAVOM = "Politika i odnos s državom",
  BIOETIKA_I_KULTURNI_RATOVI = "Bioetika i kulturni ratovi",
  KARITAS_I_SOCIJALNA_PRAVDA = "Karitas i socijalna pravda",
  POVIJEST_I_NACIONALNI_IDENTITET = "Povijest i nacionalni identitet",
  ZNANOST_I_VJERA = "Znanost i vjera",
  MEDIJI_UMJETNOST_I_KULTURA = "Mediji, umjetnost i kultura",
  DIGITALNA_EVANGELIZACIJA_I_MLADI = "Digitalna evangelizacija i mladi",
  ZLOSTAVLJANJE_I_KRIZA_POVJERENJA = "Zlostavljanje i kriza povjerenja",
  UNUTARCRKVENI_PRIJEPORI_I_IDEOLOGIJE = "Unutarcrkveni prijepori i ideologije",
  ODNOS_S_DRUGIM_RELIGIJAMA_I_POGLEDIMA = "Odnos s drugim religijama i pogledima"
)
display_topic <- function(topic) unname(topic_display_labels[topic])
if (!setequal(names(topic_display_labels), topics) || anyNA(display_topic(topics))) {
  stop("Croatian display labels do not cover the canonical topic keys exactly.", call. = FALSE)
}

normalize_text <- function(x) {
  x[is.na(x)] <- ""
  stri_trans_tolower(stri_trans_nfkc(enc2utf8(x)), locale = "hr")
}

extract_host <- function(url) {
  host <- stri_trans_tolower(stri_trim_both(fifelse(is.na(url), "", url)))
  host <- sub("^[a-z][a-z0-9+.-]*://", "", host, perl = TRUE)
  host <- sub("^//", "", host, perl = TRUE)
  host <- sub("[/?#].*$", "", host, perl = TRUE)
  host <- sub(":[0-9]+$", "", host, perl = TRUE)
  sub("^www\\.", "", host, perl = TRUE)
}

add_month <- function(x) {
  as.Date(format(as.Date(x) + 32, "%Y-%m-01"))
}

month_index <- function(x) {
  as.integer(format(as.Date(x), "%Y")) * 12L + as.integer(format(as.Date(x), "%m"))
}

safe_ratio <- function(num, den) {
  output_length <- max(length(num), length(den))
  numerator <- rep_len(num, output_length)
  denominator <- rep_len(den, output_length)
  output <- rep(NA_real_, output_length)
  valid <- is.finite(denominator) & denominator > 0
  output[valid] <- numerator[valid] / denominator[valid]
  output
}

hash_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

message("Reading the official DigiKat corpus ...")
corpus_path <- digikat_corpus_path()
corpus_manifest <- jsonlite::fromJSON(digikat_corpus_manifest_path(), simplifyVector = TRUE)
observed_corpus_sha256 <- hash_file(corpus_path)
if (!identical(observed_corpus_sha256, corpus_manifest$corpus$sha256)) {
  stop("Official corpus file does not match its tracked manifest hash.", call. = FALSE)
}
corpus <- as.data.table(readRDS(corpus_path))
needed <- c("DATE", "TITLE", "FULL_TEXT", "FROM", "URL", "SOURCE_TYPE", "INTERACTIONS",
            "data_source", "dk_era", "dk_master_row")
missing_columns <- setdiff(needed, names(corpus))
if (length(missing_columns)) {
  stop("Official corpus is missing required column(s): ", paste(missing_columns, collapse = ", "),
       call. = FALSE)
}
corpus <- corpus[, ..needed]
corpus[, `:=`(
  date = as.Date(DATE),
  source_type_key = stri_trans_tolower(stri_trim_both(SOURCE_TYPE)),
  raw_from_key = stri_trans_tolower(stri_trim_both(FROM)),
  url_host_key = extract_host(URL)
)]

mapped_all <- merge(
  corpus,
  registry,
  by = c("source_type_key", "raw_from_key", "url_host_key"),
  all = FALSE,
  allow.cartesian = TRUE
)
rm(corpus)
invisible(gc())

mapped_all[, interactions := suppressWarnings(as.numeric(INTERACTIONS))]
mapped_all[, interaction_valid := is.finite(interactions) & interactions >= 0]

measurement_2026 <- mapped_all[
  data_source == "filtered_religious" & date >= as.Date("2026-01-01") & date <= as.Date("2026-06-30"),
  .(
    n_posts = .N,
    finite_rate = mean(interaction_valid),
    zero_rate = mean(interaction_valid & interactions == 0),
    positive_rate = mean(interaction_valid & interactions > 0)
  ),
  by = .(product_id, display_name, month = as.Date(format(date, "%Y-%m-01")))
]

analysis_posts <- mapped_all[
  (main_analysis & data_source == "filtered_religious" &
     date >= params$main_start & date <= params$main_supply_end) |
  (historical_replication & data_source == "original_dta" &
     date >= params$historical_start & date <= params$historical_end)
]
analysis_posts[, analysis_era := fifelse(data_source == "filtered_religious", "main_2024_2026", "historical_2021_2023")]

normalize_path <- function(url) {
  path <- stri_trans_tolower(stri_trim_both(fifelse(is.na(url), "", url)))
  path <- sub("^[a-z][a-z0-9+.-]*://", "", path, perl = TRUE)
  path <- sub("^[^/?#]*", "", path, perl = TRUE)
  sub("[?#].*$", "", path, perl = TRUE)
}

analysis_posts[, `:=`(
  title_normalized = normalize_text(TITLE),
  url_path = normalize_path(URL)
)]
analysis_posts[, path_label := normalize_text(
  gsub("[-_]+", " ", gsub("^/|/$", "", url_path), perl = TRUE)
)]
editorial_base_counts <- analysis_posts[, .(
  mapped_rows_before_editorial_gate = .N,
  mapped_interactions_before_editorial_gate = sum(interactions, na.rm = TRUE)
), by = .(analysis_era, organization_id, product_id, display_name)]
analysis_posts[, non_editorial_reason := fcase(
  grepl("(^|/)(page|stranica)/[0-9]+/?$", url_path, perl = TRUE), "pagination_url",
  grepl("^/(category|tag|author|search|taxonomy|kategorija|oznaka|autor|pretraga|feed)(/|$)",
        url_path, perl = TRUE), "listing_url",
  url_path %in% c("/najnovije/", "/feljtoni/", "/arhiva/", "/archive/") &
    title_normalized %in% c("najnovije", "feljtoni", "arhiva", "archive"),
  "named_listing_url",
  title_normalized == path_label & title_normalized %in% c(
    "vijesti", "novosti", "najava", "najave", "duhovnost", "vjera", "kultura",
    "kultura i znanost", "obitelj", "kolumne", "multimedija", "mulitmedija",
    "emisije", "video", "mladi", "život", "zivot", "dokumenti", "prikazi",
    "biskupije", "feljtoni", "najnovije"
  ),
  "section_landing_url",
  url_path == "/najave/" &
    grepl("[?&]date=", stri_trans_tolower(fifelse(is.na(URL), "", URL)), perl = TRUE) &
    grepl("^najav", title_normalized, perl = TRUE),
  "calendar_listing_url",
  grepl("^arhiva(?:\\s|$)", title_normalized, perl = TRUE), "archive_title",
  product_id == "glas_koncila_web" &
    grepl("^/(glas-koncila|prilika)-br-", url_path, perl = TRUE),
  "issue_landing_url",
  title_normalized == "početna" &
    (url_path %in% c("", "/") |
       grepl("(^|/)(page|stranica)/[0-9]+/?$", url_path, perl = TRUE)),
  "homepage_title",
  url_path %in% c("", "/") &
    grepl("[?&](photo|view)=(list|archive|category)(?:&|$)",
          stri_trans_tolower(fifelse(is.na(URL), "", URL)), perl = TRUE),
  "root_query_listing",
  url_path %in% c("", "/") & title_normalized %in%
    c("naslovnica", "home", "arhiva", "pretraživanje", "rezultati pretraživanja"),
  "generic_root_page",
  default = NA_character_
)]
editorial_item_diagnostics <- analysis_posts[!is.na(non_editorial_reason), .(
  non_editorial_rows_removed = .N,
  non_editorial_interactions_removed = sum(interactions, na.rm = TRUE)
), by = .(analysis_era, organization_id, product_id, display_name, non_editorial_reason)]
editorial_item_summary <- editorial_item_diagnostics[, .(
  non_editorial_rows_removed = sum(non_editorial_rows_removed),
  non_editorial_interactions_removed = sum(non_editorial_interactions_removed)
), by = .(analysis_era, organization_id, product_id, display_name)]
editorial_item_summary <- merge(
  editorial_base_counts, editorial_item_summary,
  by = c("analysis_era", "organization_id", "product_id", "display_name"), all.x = TRUE
)
editorial_item_summary[is.na(non_editorial_rows_removed), `:=`(
  non_editorial_rows_removed = 0L,
  non_editorial_interactions_removed = 0
)]
editorial_item_summary[, editorial_removal_rate :=
                         non_editorial_rows_removed / mapped_rows_before_editorial_gate]
analysis_posts <- analysis_posts[is.na(non_editorial_reason)]

# A URL is one editorial item. Remove duplicate captures within the same product and era,
# while retaining rows without a usable URL as distinct records.
setorder(analysis_posts, analysis_era, product_id, date, dk_master_row)
analysis_posts[, url_key := normalize_text(URL)]
analysis_posts[, duplicate_capture := nzchar(url_key) & duplicated(url_key),
               by = .(analysis_era, product_id)]
duplicate_diagnostics <- analysis_posts[, .(
  rows_before_deduplication = .N,
  duplicate_urls_removed = sum(duplicate_capture)
), by = .(analysis_era, product_id, display_name)]
analysis_posts <- analysis_posts[duplicate_capture == FALSE]
analysis_posts[, row_id := .I]
analysis_posts[, interactions := suppressWarnings(as.numeric(INTERACTIONS))]
analysis_posts[, interaction_valid := is.finite(interactions) & interactions >= 0]

coverage_calendar <- data.table(
  date = seq(params$main_start, params$main_engagement_end, by = "day")
)
daily_primary_counts <- analysis_posts[
  analysis_era == "main_2024_2026" & date <= params$main_engagement_end,
  .(primary_posts = .N), by = date
]
daily_primary_coverage <- merge(coverage_calendar, daily_primary_counts, by = "date", all.x = TRUE)
daily_primary_coverage[is.na(primary_posts), primary_posts := 0L]
monthly_primary_coverage <- daily_primary_coverage[, .(
  calendar_days = .N,
  zero_post_days = sum(primary_posts == 0L),
  days_below_10_posts = sum(primary_posts < 10L),
  median_daily_posts = as.numeric(stats::median(primary_posts))
), by = .(month = as.Date(format(date, "%Y-%m-01")))]
monthly_primary_coverage[, low_day_share := days_below_10_posts / calendar_days]

compile_topic_patterns <- function(dictionary) {
  lapply(dictionary, function(terms) {
    clean <- unique(normalize_text(terms))
    clean <- clean[nzchar(clean)]
    clean <- clean[order(nchar(clean), decreasing = TRUE)]
    alternatives <- paste0("\\Q", gsub("\\\\E", "\\\\E\\\\\\\\E\\\\Q", clean), "\\E")
    paste0("(?<![\\p{L}\\p{M}\\p{N}_])(?:", paste(alternatives, collapse = "|"), ")")
  })
}

message("Classifying posts with the canonical 16-topic dictionary ...")
topic_patterns <- compile_topic_patterns(digikat_thematic_dictionaries)
score_topic_text <- function(text, row_ids) {
  score_matrix <- vapply(topic_patterns, function(pattern) {
    stri_count_regex(text, pattern, opts_regex = stri_opts_regex(case_insensitive = FALSE))
  }, integer(length(row_ids)))
  if (is.null(dim(score_matrix))) score_matrix <- matrix(score_matrix, ncol = length(topics))
  colnames(score_matrix) <- topics
  max_score <- apply(score_matrix, 1L, max)
  tie_count <- rowSums(score_matrix == max_score & max_score > 0L)
  winning_index <- which(score_matrix == max_score & max_score > 0L, arr.ind = TRUE)
  assignment_rows <- data.table(
    row_id = row_ids[winning_index[, 1L]],
    topic = topics[winning_index[, 2L]],
    topic_score = score_matrix[winning_index],
    allocation = 1 / tie_count[winning_index[, 1L]]
  )
  signatures <- assignment_rows[, .(
    winner_signature = paste(sort(topic), collapse = "|")
  ), by = row_id]
  list(
    classified = max_score > 0L,
    winning_score = max_score,
    winning_topics = tie_count,
    assignments = assignment_rows,
    signatures = signatures
  )
}

bounded_body <- stri_sub(fifelse(is.na(analysis_posts$FULL_TEXT), "", analysis_posts$FULL_TEXT),
                         1L, params$classification_text_characters)
primary_scores <- score_topic_text(
  normalize_text(paste(analysis_posts$TITLE, bounded_body, sep = "\n")),
  analysis_posts$row_id
)
analysis_posts[, `:=`(
  classified = primary_scores$classified,
  winning_score = primary_scores$winning_score,
  winning_topics = primary_scores$winning_topics
)]
assignments <- primary_scores$assignments

message("Scoring full-page text for classification-window sensitivity ...")
full_text_scores <- score_topic_text(
  normalize_text(paste(analysis_posts$TITLE, analysis_posts$FULL_TEXT, sep = "\n")),
  analysis_posts$row_id
)
analysis_posts_full <- copy(analysis_posts)
analysis_posts_full[, `:=`(
  classified = full_text_scores$classified,
  winning_score = full_text_scores$winning_score,
  winning_topics = full_text_scores$winning_topics
)]
assignments_full <- full_text_scores$assignments
winner_comparison <- merge(
  primary_scores$signatures,
  full_text_scores$signatures,
  by = "row_id", suffixes = c("_bounded", "_full"), all = TRUE
)
winner_comparison[, winner_agreement :=
                    winner_signature_bounded == winner_signature_full &
                    !is.na(winner_signature_bounded) & !is.na(winner_signature_full)]
winner_agreement_rate <- winner_comparison[
  !is.na(winner_signature_bounded) & !is.na(winner_signature_full),
  mean(winner_agreement)
]
rm(bounded_body)
invisible(gc())

make_validation_sample <- function(posts, assignment_rows, per_topic, seed) {
  set.seed(seed)
  topic_pool <- assignment_rows[, .N, by = topic]
  sampling_assignment <- merge(
    unique(assignment_rows[, .(row_id, topic)]), topic_pool,
    by = "topic", all.x = TRUE
  )
  setorder(sampling_assignment, row_id, N, topic)
  sampling_assignment <- sampling_assignment[, .SD[1L], by = row_id]
  predictions <- assignment_rows[, .(
    predicted_topics = paste(sort(topic), collapse = ";"),
    predicted_allocations = paste(sprintf("%s=%.3f", topic, allocation), collapse = ";")
  ), by = row_id]
  candidates <- merge(
    sampling_assignment[, .(row_id, sampling_topic = topic)],
    posts[, .(row_id, analysis_era, product_id, display_name, date, TITLE, URL, FULL_TEXT,
              winning_score, winning_topics)],
    by = "row_id",
    all = FALSE
  )
  candidates <- merge(candidates, predictions, by = "row_id", all.x = TRUE)
  candidates[, quarter := paste0(format(date, "%Y"), "-Q",
                                 (as.integer(format(date, "%m")) - 1L) %/% 3L + 1L)]
  candidates[, random_order := runif(.N)]
  candidates[, stratum_rank := frank(random_order, ties.method = "first"),
             by = .(sampling_topic, product_id, quarter)]
  setorder(candidates, sampling_topic, stratum_rank, random_order)
  sampled <- candidates[, head(.SD, min(.N, per_topic)), by = sampling_topic]
  sampled[, excerpt := stri_sub(stri_replace_all_regex(FULL_TEXT, "\\s+", " "),
                                1L, params$classification_text_characters)]
  sampled[, `:=`(
    FULL_TEXT = NULL,
    random_order = NULL,
    stratum_rank = NULL,
    human_topic_primary = "",
    human_topic_secondary = "",
    none_or_unclear = "",
    coder_id = "",
    coder_notes = ""
  )]
  setorder(sampled, sampling_topic, product_id, date)
  sampled
}

validation_sample <- make_validation_sample(
  analysis_posts[analysis_era == "main_2024_2026"], assignments,
  params$validation_per_topic, params$random_seed
)
fwrite(validation_sample, file.path(private_dir, "topic_validation_sample.csv"), bom = TRUE)
validation_coder_sheet <- copy(validation_sample)
validation_answer_key <- validation_coder_sheet[, .(
  row_id, sampling_topic, predicted_topics, predicted_allocations,
  winning_score, winning_topics
)]
validation_coder_sheet[, c(
  "sampling_topic", "predicted_topics", "predicted_allocations",
  "winning_score", "winning_topics"
) := NULL]
setorder(validation_coder_sheet, row_id)
fwrite(validation_coder_sheet, file.path(private_dir, "topic_validation_coder_sheet.csv"), bom = TRUE)
fwrite(validation_answer_key, file.path(private_dir, "topic_validation_answer_key.csv"), bom = TRUE)

period_floor <- function(date, frequency) {
  if (identical(frequency, "month")) return(as.Date(format(date, "%Y-%m-01")))
  if (identical(frequency, "week")) {
    weekday <- as.integer(format(date, "%u"))
    return(as.Date(date - (weekday - 1L)))
  }
  stop("Unsupported frequency: ", frequency, call. = FALSE)
}

build_vector_panel <- function(posts, assignment_rows, frequency = "month", min_posts = 30L) {
  p <- copy(posts)
  p[, period := period_floor(date, frequency)]
  p[, int_raw := fifelse(interaction_valid, interactions, NA_real_)]
  cell_keys <- c("analysis_era", "organization_id", "product_id", "display_name", "period")

  p[, interaction_cap_99 := {
    valid <- int_raw[classified == TRUE & is.finite(int_raw)]
    if (length(valid)) as.numeric(stats::quantile(valid, 0.99, names = FALSE, type = 7L)) else NA_real_
  }, by = cell_keys]
  p[, int_winsorized := fifelse(is.finite(int_raw), pmin(int_raw, interaction_cap_99), NA_real_)]
  p[, top_interaction_row := FALSE]
  p[interaction_valid == TRUE & classified == TRUE,
    top_interaction_row := seq_len(.N) == which.max(int_raw), by = cell_keys]
  p[, int_top_removed := fifelse(interaction_valid & !top_interaction_row, int_raw,
                                 fifelse(interaction_valid, 0, NA_real_))]

  base <- p[, .(
    n_posts = .N,
    n_classified = sum(classified),
    n_interactions_valid = sum(interaction_valid),
    n_positive_interactions = sum(interaction_valid & interactions > 0),
    interactions_all = sum(int_raw, na.rm = TRUE),
    interactions_classified = sum(int_raw[classified], na.rm = TRUE),
    interactions_unclassified = sum(int_raw[!classified], na.rm = TRUE)
  ), by = cell_keys]
  base[, `:=`(
    classification_rate = safe_ratio(n_classified, n_posts),
    interaction_coverage = safe_ratio(n_interactions_valid, n_posts),
    positive_rate = safe_ratio(n_positive_interactions, n_interactions_valid),
    unclassified_interaction_share = safe_ratio(interactions_unclassified, interactions_all)
  )]
  base[, eligible_supply := n_classified >= min_posts]
  base[, eligible_measurement := eligible_supply &
         interaction_coverage >= params$min_interaction_coverage &
         positive_rate >= params$min_positive_rate & interactions_classified > 0]

  joined <- merge(
    assignment_rows,
    p[, c("row_id", cell_keys, "int_raw", "int_winsorized", "int_top_removed"), with = FALSE],
    by = "row_id",
    all = FALSE
  )
  joined[, log_interaction := fifelse(is.finite(int_raw), log1p(int_raw), NA_real_)]
  topic_sums <- joined[, .(
    post_mass = sum(allocation),
    interaction_mass = sum(allocation * int_raw, na.rm = TRUE),
    interaction_mass_winsorized = sum(allocation * int_winsorized, na.rm = TRUE),
    interaction_mass_top_removed = sum(allocation * int_top_removed, na.rm = TRUE),
    log_interaction_sum = sum(allocation * log_interaction, na.rm = TRUE),
    log_interaction_mass = sum(allocation * is.finite(log_interaction))
  ), by = c(cell_keys, "topic")]

  cells <- unique(base[, ..cell_keys])
  n_cells <- nrow(cells)
  topic_grid <- cells[rep(seq_len(n_cells), each = length(topics))]
  topic_grid[, topic := rep(topics, times = n_cells)]
  panel <- merge(topic_grid, topic_sums, by = c(cell_keys, "topic"), all.x = TRUE)
  zero_columns <- c("post_mass", "interaction_mass", "interaction_mass_winsorized",
                    "interaction_mass_top_removed", "log_interaction_sum", "log_interaction_mass")
  for (column in zero_columns) set(panel, which(is.na(panel[[column]])), column, 0)
  panel <- merge(panel, base, by = cell_keys, all.x = TRUE)

  panel[, `:=`(
    production_share = safe_ratio(post_mass, n_classified),
    reward_share = safe_ratio(interaction_mass, sum(interaction_mass)),
    reward_share_winsorized = safe_ratio(interaction_mass_winsorized, sum(interaction_mass_winsorized)),
    reward_share_top_removed = safe_ratio(interaction_mass_top_removed, sum(interaction_mass_top_removed)),
    topic_mean_log_interaction = safe_ratio(log_interaction_sum, log_interaction_mass),
    cell_mean_log_interaction = safe_ratio(sum(log_interaction_sum), sum(log_interaction_mass))
  ), by = cell_keys]
  panel[, `:=`(
    production_pct = 100 * production_share,
    reward_pct = 100 * reward_share,
    gap_pp = 100 * (reward_share - production_share),
    gap_pp_winsorized = 100 * (reward_share_winsorized - production_share),
    gap_pp_top_removed = 100 * (reward_share_top_removed - production_share),
    reward_multiplier = safe_ratio(reward_share, production_share),
    log_interaction_premium = topic_mean_log_interaction - cell_mean_log_interaction
  )]
  panel[, `:=`(
    gap_distance_pp = 0.5 * sum(abs(gap_pp)),
    gap_distance_winsorized_pp = 0.5 * sum(abs(gap_pp_winsorized)),
    gap_distance_top_removed_pp = 0.5 * sum(abs(gap_pp_top_removed)),
    period_type = frequency
  ), by = cell_keys]
  setorder(panel, analysis_era, product_id, period, topic)
  panel[]
}

message("Building product-month topic vectors ...")
month_panel <- build_vector_panel(analysis_posts, assignments, "month", params$min_posts_month)
saveRDS(month_panel, file.path(intermediate_dir, "news_gap_month_panel.rds"), compress = "xz")
month_panel_full <- build_vector_panel(
  analysis_posts_full, assignments_full, "month", params$min_posts_month
)
saveRDS(month_panel_full, file.path(intermediate_dir, "news_gap_month_panel_full_text.rds"),
        compress = "xz")

message("Creating the 2025 field and product summaries ...")
headline_panel <- month_panel[
  analysis_era == "main_2024_2026" &
    period >= as.Date(format(params$headline_start, "%Y-%m-01")) &
    period <= as.Date(format(params$headline_end, "%Y-%m-01")) &
    !period %in% params$excluded_months & eligible_measurement
]
headline_panel_full <- month_panel_full[
  analysis_era == "main_2024_2026" &
    period >= as.Date(format(params$headline_start, "%Y-%m-01")) &
    period <= as.Date(format(params$headline_end, "%Y-%m-01")) &
    !period %in% params$excluded_months & eligible_measurement
]

headline_product_topic <- headline_panel[, .(
  post_mass = sum(post_mass),
  interaction_mass = sum(interaction_mass),
  interaction_mass_winsorized = sum(interaction_mass_winsorized),
  interaction_mass_top_removed = sum(interaction_mass_top_removed)
), by = .(organization_id, product_id, display_name, topic)]
headline_product_topic[, `:=`(
  production_share = safe_ratio(post_mass, sum(post_mass)),
  reward_share = safe_ratio(interaction_mass, sum(interaction_mass)),
  reward_share_winsorized = safe_ratio(interaction_mass_winsorized, sum(interaction_mass_winsorized)),
  reward_share_top_removed = safe_ratio(interaction_mass_top_removed, sum(interaction_mass_top_removed))
), by = .(organization_id, product_id, display_name)]
headline_product_topic[, `:=`(
  production_pct = 100 * production_share,
  reward_pct = 100 * reward_share,
  gap_pp = 100 * (reward_share - production_share),
  gap_pp_winsorized = 100 * (reward_share_winsorized - production_share),
  gap_pp_top_removed = 100 * (reward_share_top_removed - production_share)
)]

headline_product_topic_full <- headline_panel_full[, .(
  post_mass = sum(post_mass),
  interaction_mass = sum(interaction_mass)
), by = .(organization_id, product_id, display_name, topic)]
headline_product_topic_full[, `:=`(
  production_pct_full_text = 100 * safe_ratio(post_mass, sum(post_mass)),
  reward_pct_full_text = 100 * safe_ratio(interaction_mass, sum(interaction_mass))
), by = .(organization_id, product_id, display_name)]
headline_product_topic_full[, gap_pp_full_text := reward_pct_full_text - production_pct_full_text]

# Product-level vectors are analytically useful for the Moj medij profile, but they remain private
# until the blinded validation gate passes. Pool every topic below the product-level support floor so
# the eventual chart is complete without turning tiny cells into named performance claims.
outlet_topic_private_source <- merge(
  headline_product_topic,
  headline_product_topic_full[, .(
    organization_id, product_id, display_name, topic,
    production_pct_full_text, reward_pct_full_text, gap_pp_full_text
  )],
  by = c("organization_id", "product_id", "display_name", "topic"),
  all.x = TRUE
)
outlet_topic_private_source[, profile_topic := fifelse(
  post_mass < params$public_min_topic_posts,
  "OSTALE_RIJETKE_TEME",
  topic
)]
outlet_topic_private <- outlet_topic_private_source[, .(
  production_pct = sum(production_pct),
  reward_pct = sum(reward_pct),
  gap_pp = sum(gap_pp),
  gap_pp_winsorized = sum(gap_pp_winsorized),
  gap_pp_top_removed = sum(gap_pp_top_removed),
  production_pct_full_text = sum(production_pct_full_text),
  reward_pct_full_text = sum(reward_pct_full_text),
  gap_pp_full_text = sum(gap_pp_full_text),
  post_mass = sum(post_mass),
  topics_pooled = .N
), by = .(
  organization_id, product_id, display_name,
  topic = profile_topic
)]
outlet_topic_private[, `:=`(
  topic_label = fifelse(
    topic == "OSTALE_RIJETKE_TEME",
    "Ostale rijetke teme",
    display_topic(topic)
  ),
  reward_multiplier = safe_ratio(reward_pct, production_pct),
  validation_status = study_status
)]
setcolorder(outlet_topic_private, c(
  "organization_id", "product_id", "display_name", "topic", "topic_label",
  "production_pct", "reward_pct", "gap_pp", "reward_multiplier",
  "gap_pp_winsorized", "gap_pp_top_removed", "production_pct_full_text",
  "reward_pct_full_text", "gap_pp_full_text", "post_mass", "topics_pooled",
  "validation_status"
))
setorder(outlet_topic_private, display_name, -gap_pp)
fwrite(outlet_topic_private, file.path(private_dir, "outlet_topic_profiles.csv"), bom = TRUE)
public_outlet_topic_path <- file.path(output_dir, "outlet_topic_profiles.csv")
if (study_status %in% c(
  "published_provisional_pending_manual_dictionary_validation",
  "validated_for_publication"
)) {
  fwrite(outlet_topic_private, public_outlet_topic_path, bom = TRUE)
} else if (file.exists(public_outlet_topic_path)) {
  stop(
    "A public outlet topic table exists while the study is not validated. Remove the stale file explicitly.",
    call. = FALSE
  )
}

field_full_text <- headline_product_topic_full[, .(
  production_pct_full_text = mean(production_pct_full_text),
  reward_pct_full_text = mean(reward_pct_full_text),
  gap_pp_full_text = mean(gap_pp_full_text)
), by = topic]

field_exact <- headline_product_topic[, .(
  production_pct = mean(production_pct),
  reward_pct = mean(reward_pct),
  gap_pp = mean(gap_pp),
  gap_pp_winsorized = mean(gap_pp_winsorized),
  gap_pp_top_removed = mean(gap_pp_top_removed),
  n_products = uniqueN(product_id),
  n_products_positive = sum(post_mass > 0),
  n_products_supported = sum(post_mass >= 5),
  total_post_mass = sum(post_mass)
), by = topic]
field_exact <- merge(field_exact, field_full_text, by = "topic", all.x = TRUE)
field_exact[, reward_multiplier := safe_ratio(reward_pct, production_pct)]
field_exact[, reward_multiplier_full_text := safe_ratio(reward_pct_full_text, production_pct_full_text)]
field_exact[, topic_label := display_topic(topic)]
setcolorder(field_exact, c("topic", "topic_label", "production_pct", "reward_pct", "gap_pp",
                           "reward_multiplier", "gap_pp_winsorized", "gap_pp_top_removed",
                           "production_pct_full_text", "reward_pct_full_text", "gap_pp_full_text",
                           "reward_multiplier_full_text",
                           "n_products", "n_products_positive", "n_products_supported", "total_post_mass"))
fwrite(field_exact, file.path(intermediate_dir, "gap_overall_16_topics.csv"), bom = TRUE)

rare_topics <- field_exact[
  total_post_mass < params$public_min_topic_posts | n_products_supported < 3L,
  topic
]
field_public_source <- copy(field_exact)
field_public_source[, public_topic := fifelse(topic %in% rare_topics,
                                               "OSTALE_RIJETKE_TEME", topic)]
field_public <- field_public_source[, .(
  production_pct = sum(production_pct),
  reward_pct = sum(reward_pct),
  gap_pp = sum(gap_pp),
  gap_pp_winsorized = sum(gap_pp_winsorized),
  gap_pp_top_removed = sum(gap_pp_top_removed),
  production_pct_full_text = sum(production_pct_full_text),
  reward_pct_full_text = sum(reward_pct_full_text),
  gap_pp_full_text = sum(gap_pp_full_text),
  n_products = min(n_products),
  n_products_positive = if (public_topic[[1L]] == "OSTALE_RIJETKE_TEME")
    NA_integer_ else min(n_products_positive),
  n_products_supported = if (public_topic[[1L]] == "OSTALE_RIJETKE_TEME")
    NA_integer_ else min(n_products_supported),
  total_post_mass = sum(total_post_mass)
), by = .(topic = public_topic)]
field_public[, `:=`(
  topic_label = fifelse(topic == "OSTALE_RIJETKE_TEME", "Ostale rijetke teme",
                        display_topic(topic)),
  reward_multiplier = safe_ratio(reward_pct, production_pct),
  reward_multiplier_full_text = safe_ratio(reward_pct_full_text, production_pct_full_text)
)]
setcolorder(field_public, c("topic", "topic_label", "production_pct", "reward_pct", "gap_pp",
                            "reward_multiplier", "gap_pp_winsorized", "gap_pp_top_removed",
                            "production_pct_full_text", "reward_pct_full_text", "gap_pp_full_text",
                            "reward_multiplier_full_text",
                            "n_products", "n_products_positive", "n_products_supported", "total_post_mass"))
setorder(field_public, -gap_pp)
fwrite(field_public, file.path(output_dir, "gap_overall.csv"), bom = TRUE)

headline_cells <- unique(headline_panel[, .(
  organization_id, product_id, display_name, period, n_posts, n_classified,
  classification_rate, interactions_all, gap_distance_pp
)])
product_totals <- headline_cells[, .(
  n_months = uniqueN(period),
  total_posts = sum(n_posts),
  classified_posts = sum(n_classified),
  total_interactions = sum(interactions_all),
  classification_rate = safe_ratio(sum(n_classified), sum(n_posts))
), by = .(organization_id, product_id, display_name)]
product_distances <- headline_product_topic[, .(
  gap_distance_pp = 0.5 * sum(abs(gap_pp)),
  gap_distance_winsorized_pp = 0.5 * sum(abs(gap_pp_winsorized)),
  gap_distance_top_removed_pp = 0.5 * sum(abs(gap_pp_top_removed))
), by = .(organization_id, product_id, display_name)]
supported_product_topics <- merge(
  headline_product_topic[post_mass >= params$public_min_topic_posts],
  headline_product_topic_full[, .(
    organization_id, product_id, display_name, topic, gap_pp_full_text
  )],
  by = c("organization_id", "product_id", "display_name", "topic"),
  all.x = TRUE
)
top_topics <- supported_product_topics[order(-gap_pp), .SD[1L],
                                       by = .(organization_id, product_id, display_name)]
bottom_topics <- supported_product_topics[order(gap_pp), .SD[1L],
                                          by = .(organization_id, product_id, display_name)]
top_topics <- top_topics[, .(
  organization_id, product_id, display_name,
  most_overrewarded_topic = display_topic(topic),
  most_overrewarded_gap_pp = gap_pp,
  most_overrewarded_gap_pp_winsorized = gap_pp_winsorized,
  most_overrewarded_gap_pp_top_removed = gap_pp_top_removed,
  most_overrewarded_gap_pp_full_text = gap_pp_full_text,
  most_overrewarded_direction_consistent =
    gap_pp > 0 & gap_pp_winsorized > 0 & gap_pp_top_removed > 0 & gap_pp_full_text > 0,
  most_overrewarded_post_mass = post_mass
)]
bottom_topics <- bottom_topics[, .(
  organization_id, product_id, display_name,
  most_underrewarded_topic = display_topic(topic),
  most_underrewarded_gap_pp = gap_pp,
  most_underrewarded_gap_pp_winsorized = gap_pp_winsorized,
  most_underrewarded_gap_pp_top_removed = gap_pp_top_removed,
  most_underrewarded_gap_pp_full_text = gap_pp_full_text,
  most_underrewarded_direction_consistent =
    gap_pp < 0 & gap_pp_winsorized < 0 & gap_pp_top_removed < 0 & gap_pp_full_text < 0,
  most_underrewarded_post_mass = post_mass
)]
outlet_profiles <- Reduce(
  function(x, y) merge(x, y, by = c("organization_id", "product_id", "display_name"), all = TRUE),
  list(product_totals, product_distances, top_topics, bottom_topics)
)
outlet_profiles[, interpretation :=
  "Descriptive profile; named topics are validation leads, not performance rankings or client-ready claims"]
setorder(outlet_profiles, -gap_distance_pp)
fwrite(outlet_profiles, file.path(output_dir, "outlet_profiles.csv"), bom = TRUE)

message("Building the weekly event view ...")
event_posts <- analysis_posts[
  analysis_era == "main_2024_2026" &
    date >= as.Date("2025-03-10") & date <= as.Date("2025-06-08")
]
event_assignments <- assignments[row_id %in% event_posts$row_id]
week_panel <- build_vector_panel(event_posts, event_assignments, "week", params$min_posts_week)
saveRDS(week_panel, file.path(intermediate_dir, "news_gap_week_panel.rds"), compress = "xz")

weekly_cells <- unique(week_panel[eligible_measurement == TRUE, .(
  product_id, display_name, period, gap_distance_pp, n_posts
)])
weekly_observed <- weekly_cells[, .(
  estimate = mean(gap_distance_pp),
  cross_product_sd = if (.N > 1L) stats::sd(gap_distance_pp) else NA_real_,
  n_products = uniqueN(product_id),
  n_product_periods = .N
), by = period]
event_calendar <- data.table(period = seq(as.Date("2025-03-10"), as.Date("2025-06-02"), by = "week"))
weekly_system <- merge(event_calendar, weekly_observed, by = "period", all.x = TRUE)
weekly_system[is.na(n_products), `:=`(n_products = 0L, n_product_periods = 0L)]
blackout_intervals <- data.table(
  blackout_start = as.Date(c("2025-03-29", "2025-04-28")),
  blackout_end = as.Date(c("2025-04-10", "2025-05-10"))
)
weekly_system[, blackout_overlap := vapply(period, function(week_start) {
  week_end <- week_start + 6L
  any(week_start <= blackout_intervals$blackout_end & week_end >= blackout_intervals$blackout_start)
}, logical(1L))]
weekly_system[, sufficient_coverage := n_products >= 3L & !blackout_overlap]
weekly_system[sufficient_coverage == FALSE,
              c("estimate", "cross_product_sd") := list(NA_real_, NA_real_)]
weekly_system[, `:=`(
  result_type = "weekly_distance",
  period_or_contrast = format(period, "%Y-%m-%d"),
  standard_error = NA_real_,
  conf_low = NA_real_,
  conf_high = NA_real_,
  unit = "percentage-point distance",
  notes = fifelse(
    sufficient_coverage,
    "Equal-product weekly mean; eligible product-weeks only",
    "Not reported: week overlaps a collection blackout or has fewer than three eligible products"
  )
)]

event_feasibility <- data.table(
  result_type = "event_feasibility",
  period_or_contrast = "papal_transition_minus_pre",
  estimate = NA_real_,
  standard_error = NA_real_,
  conf_low = NA_real_,
  conf_high = NA_real_,
  n_products = uniqueN(weekly_cells$product_id),
  n_product_periods = nrow(weekly_cells),
  unit = "percentage-point distance",
  notes = paste(
    "Not estimable: primary-source collection is nearly absent 29 March-10 April",
    "and 28 April-10 May 2025, including the conclave and election of Leo XIV"
  )
)

event_results <- rbindlist(list(
  weekly_system[, .(result_type, period_or_contrast, estimate, standard_error, conf_low, conf_high,
                    cross_product_sd, n_products, n_product_periods, unit, notes)],
  event_feasibility[, .(result_type, period_or_contrast, estimate, standard_error, conf_low, conf_high,
                        n_products, n_product_periods, unit, notes)]
), fill = TRUE)
fwrite(event_results, file.path(output_dir, "event_results.csv"), bom = TRUE)

prepare_lag_panel <- function(panel, era, current_start, current_end, excluded = as.Date(character())) {
  current <- panel[
    analysis_era == era & period >= current_start & period <= current_end &
      !period %in% excluded & eligible_measurement
  ]
  current[, product_topic := paste(product_id, topic, sep = "::")]
  current[, next_period := add_month(period)]

  next_supply <- panel[
    analysis_era == era & eligible_supply & !period %in% excluded,
    .(product_id, topic, next_period = period, next_production_pct = production_pct)
  ]
  lagged <- merge(current, next_supply, by = c("product_id", "topic", "next_period"), all = FALSE)
  support <- lagged[, .(
    product_topic_posts = sum(post_mass),
    product_topic_present_transitions = uniqueN(period[post_mass > 0])
  ), by = product_topic]
  supported <- support[
    product_topic_posts >= params$min_product_topic_posts &
      product_topic_present_transitions >= params$min_product_topic_months,
    product_topic
  ]
  lagged <- lagged[product_topic %in% supported]
  lagged[, `:=`(
    topic_month = paste(topic, format(period, "%Y-%m-%d"), sep = "::"),
    change_in_production_pp = next_production_pct - production_pct
  )]
  setorder(lagged, period, product_id, topic)
  lagged[]
}

fit_time_hac <- function(data, outcome, predictor, include_production = TRUE, hac_lag = 2L,
                         time_variable = "period", topic_time_variable = "topic_month") {
  needed_vars <- c(outcome, predictor, "product_topic", topic_time_variable, time_variable)
  if (include_production) needed_vars <- c(needed_vars, "production_pct")
  d <- copy(data[complete.cases(data[, ..needed_vars])])
  rhs <- c(predictor, if (include_production) "production_pct",
           "factor(product_topic)", paste0("factor(", topic_time_variable, ")"))
  model_formula <- stats::as.formula(paste(outcome, "~", paste(rhs, collapse = " + ")))
  fit <- stats::lm(model_formula, data = d, x = TRUE, y = TRUE, model = TRUE)
  coefficient <- stats::coef(fit)[predictor]
  if (!length(coefficient) || !is.finite(coefficient)) {
    stop("Predictor was not estimable: ", predictor, call. = FALSE)
  }

  full_x <- stats::model.matrix(fit)
  keep <- fit$qr$pivot[seq_len(fit$rank)]
  x <- full_x[, keep, drop = FALSE]
  residual <- stats::residuals(fit)
  time_value <- as.Date(d[[time_variable]])
  score <- rowsum(x * residual, group = format(time_value, "%Y-%m-%d"), reorder = TRUE)
  score_month <- as.Date(rownames(score))
  score_index <- month_index(score_month)

  meat <- crossprod(score)
  if (nrow(score) > 1L && hac_lag > 0L) {
    for (lag in seq_len(hac_lag)) {
      pairs <- which(outer(score_index, score_index, "-") == lag, arr.ind = TRUE)
      if (!nrow(pairs)) next
      weight <- 1 - lag / (hac_lag + 1)
      for (pair in seq_len(nrow(pairs))) {
        cross <- tcrossprod(score[pairs[pair, 1L], ], score[pairs[pair, 2L], ])
        meat <- meat + weight * (cross + t(cross))
      }
    }
  }
  bread <- qr.solve(crossprod(x), diag(ncol(x)))
  variance <- bread %*% meat %*% bread
  if (nrow(score) > 1L) variance <- variance * nrow(score) / (nrow(score) - 1L)
  predictor_position <- match(predictor, colnames(x))
  if (is.na(predictor_position)) stop("Predictor dropped from full-rank model.", call. = FALSE)
  variance_value <- variance[predictor_position, predictor_position]
  standard_error <- sqrt(max(variance_value, 0))
  degrees_freedom <- nrow(score) - 1L
  critical <- stats::qt(0.975, degrees_freedom)
  p_value <- 2 * stats::pt(abs(coefficient / standard_error), degrees_freedom, lower.tail = FALSE)

  list(
    fit = fit,
    data = d,
    estimate = unname(coefficient),
    standard_error = standard_error,
    conf_low = unname(coefficient - critical * standard_error),
    conf_high = unname(coefficient + critical * standard_error),
    p_value = p_value,
    degrees_freedom = degrees_freedom,
    n_obs = stats::nobs(fit),
    n_products = uniqueN(d$product_id),
    n_organizations = uniqueN(d$organization_id),
    n_product_topics = uniqueN(d$product_topic),
    n_periods = uniqueN(d[[time_variable]])
  )
}

model_row <- function(result, analysis_era, specification, predictor, uncertainty, notes) {
  data.table(
    analysis_era = analysis_era,
    specification = specification,
    predictor = predictor,
    estimate = result$estimate,
    standard_error = result$standard_error,
    conf_low = result$conf_low,
    conf_high = result$conf_high,
    p_value = result$p_value,
    degrees_freedom = result$degrees_freedom,
    n_obs = result$n_obs,
    n_products = result$n_products,
    n_organizations = result$n_organizations,
    n_product_topics = result$n_product_topics,
    n_periods = result$n_periods,
    uncertainty = uncertainty,
    notes = notes
  )
}

month_cluster_bootstrap <- function(data, outcome, predictor, include_production = TRUE,
                                    reps = 999L, seed = 1L) {
  months <- sort(unique(as.Date(data$period)))
  if (length(months) < 4L) stop("Too few periods for month-cluster bootstrap.", call. = FALSE)
  set.seed(seed)
  estimates <- rep(NA_real_, reps)
  for (replicate_id in seq_len(reps)) {
    sampled <- sample(months, length(months), replace = TRUE)
    pieces <- lapply(seq_along(sampled), function(slot) {
      piece <- copy(data[period == sampled[[slot]]])
      piece[, bootstrap_slot := slot]
      piece
    })
    boot <- rbindlist(pieces, use.names = TRUE)
    boot[, topic_time_boot := paste(topic, bootstrap_slot, sep = "::")]
    rhs <- c(predictor, if (include_production) "production_pct",
             "factor(product_topic)", "factor(topic_time_boot)")
    formula <- stats::as.formula(paste(outcome, "~", paste(rhs, collapse = " + ")))
    estimates[[replicate_id]] <- tryCatch(
      unname(stats::coef(stats::lm(formula, data = boot))[predictor]),
      error = function(e) NA_real_
    )
    if (replicate_id %% 100L == 0L) {
      message("  month-cluster bootstrap: ", replicate_id, "/", reps)
    }
  }
  estimates[is.finite(estimates)]
}

message("Estimating the lagged fixed-effects panel ...")
main_lag <- prepare_lag_panel(
  month_panel, "main_2024_2026", params$main_start,
  as.Date(format(params$main_engagement_end, "%Y-%m-01")),
  params$excluded_months
)
saveRDS(main_lag, file.path(intermediate_dir, "lag_panel_main.rds"), compress = "xz")
main_lag_full <- prepare_lag_panel(
  month_panel_full, "main_2024_2026", params$main_start,
  as.Date(format(params$main_engagement_end, "%Y-%m-01")),
  params$excluded_months
)
saveRDS(main_lag_full, file.path(intermediate_dir, "lag_panel_main_full_text.rds"), compress = "xz")

historical_lag <- prepare_lag_panel(
  month_panel, "historical_2021_2023", params$historical_start,
  as.Date(format(as.Date(format(params$historical_end, "%Y-%m-01")) - 1L, "%Y-%m-01"))
)
saveRDS(historical_lag, file.path(intermediate_dir, "lag_panel_historical.rds"), compress = "xz")

message("Building the high-interaction validation audit from analytical cells ...")
main_assignment_details <- merge(
  assignments,
  analysis_posts[
    analysis_era == "main_2024_2026" & interaction_valid == TRUE,
    .(
      row_id, product_id, display_name,
      period = as.Date(format(date, "%Y-%m-01")), date, TITLE, URL, FULL_TEXT, interactions
    )
  ],
  by = "row_id", all = FALSE
)
main_assignment_details[, interaction_contribution := allocation * interactions]

# The audit is the union of three directly checkable samples: the five largest
# topic contributions in every headline product-topic, the exact post removed by
# the top-post sensitivity in every headline product-month, and the largest
# contribution in every non-empty product-topic-month used by the lag model.
headline_audit_cells <- unique(headline_panel[, .(product_id, period)])
headline_assignment_details <- merge(
  main_assignment_details, headline_audit_cells,
  by = c("product_id", "period"), all = FALSE
)
setorder(headline_assignment_details, product_id, topic,
         -interaction_contribution, -interactions, row_id)
headline_assignment_details[, candidate_count := uniqueN(row_id), by = .(product_id, topic)]
headline_topic_top <- headline_assignment_details[
  , head(.SD, 5L), by = .(product_id, topic)
]
headline_topic_top[, audit_rank := seq_len(.N), by = .(product_id, topic)]
headline_topic_coverage <- headline_topic_top[, .(
  row_id,
  audit_scope = "headline_product_topic_top5",
  audit_key = paste(product_id, topic, sep = "::"),
  audit_rank,
  candidate_count,
  product_id,
  topic,
  period,
  interactions,
  weighted_interaction_contribution = interaction_contribution
)]

headline_month_candidates <- unique(headline_assignment_details[, .(
  row_id, product_id, period, interactions
)], by = "row_id")
setorder(headline_month_candidates, product_id, period, -interactions, row_id)
headline_month_candidates[, candidate_count := .N, by = .(product_id, period)]
headline_month_top <- headline_month_candidates[, .SD[1L], by = .(product_id, period)]
headline_month_coverage <- headline_month_top[, .(
  row_id,
  audit_scope = "headline_product_month_top1",
  audit_key = paste(product_id, format(period, "%Y-%m"), sep = "::"),
  audit_rank = 1L,
  candidate_count,
  product_id,
  topic = NA_character_,
  period,
  interactions,
  weighted_interaction_contribution = interactions
)]

lag_audit_cells <- unique(main_lag[post_mass > 0, .(product_id, topic, period)])
lag_assignment_details <- merge(
  main_assignment_details, lag_audit_cells,
  by = c("product_id", "topic", "period"), all = FALSE
)
setorder(lag_assignment_details, product_id, topic, period,
         -interaction_contribution, -interactions, row_id)
lag_assignment_details[, candidate_count := uniqueN(row_id), by = .(product_id, topic, period)]
lag_cell_top <- lag_assignment_details[, .SD[1L], by = .(product_id, topic, period)]
lag_cell_coverage <- lag_cell_top[, .(
  row_id,
  audit_scope = "lag_product_topic_month_top1",
  audit_key = paste(product_id, topic, format(period, "%Y-%m"), sep = "::"),
  audit_rank = 1L,
  candidate_count,
  product_id,
  topic,
  period,
  interactions,
  weighted_interaction_contribution = interaction_contribution
)]

interaction_audit_coverage <- unique(rbindlist(list(
  headline_topic_coverage,
  headline_month_coverage,
  lag_cell_coverage
), use.names = TRUE))
setorder(interaction_audit_coverage, audit_scope, audit_key, audit_rank, row_id)
fwrite(
  interaction_audit_coverage,
  file.path(private_dir, "high_interaction_audit_coverage.csv"),
  bom = TRUE
)

interaction_audit_annotations <- interaction_audit_coverage[, .(
  audit_scopes = paste(sort(unique(audit_scope)), collapse = ";"),
  audit_keys = paste(sort(unique(paste(audit_scope, audit_key, sep = "="))), collapse = ";")
), by = row_id]
interaction_audit_product_topics <- interaction_audit_coverage[!is.na(topic), .(
  audit_for_product_topics = paste(sort(unique(paste(product_id, topic, sep = "::"))), collapse = ";")
), by = row_id]
interaction_predictions <- assignments[, .(
  predicted_topics = paste(sort(topic), collapse = ";"),
  predicted_allocations = paste(sprintf("%s=%.3f", topic, allocation), collapse = ";")
), by = row_id]
interaction_audit <- merge(
  interaction_audit_annotations,
  unique(main_assignment_details[, .(
    row_id, product_id, display_name, period, date, TITLE, URL, FULL_TEXT, interactions
  )], by = "row_id"),
  by = "row_id", all.x = TRUE
)
interaction_audit <- merge(
  interaction_audit, interaction_audit_product_topics,
  by = "row_id", all.x = TRUE
)
interaction_audit[is.na(audit_for_product_topics), audit_for_product_topics := ""]
interaction_audit <- merge(interaction_audit, interaction_predictions, by = "row_id", all.x = TRUE)
interaction_audit[, excerpt := stri_sub(stri_replace_all_regex(FULL_TEXT, "\\s+", " "),
                                        1L, params$classification_text_characters)]
interaction_audit[, `:=`(
  FULL_TEXT = NULL,
  human_topic_primary = "",
  human_topic_secondary = "",
  none_or_unclear = "",
  coder_id = "",
  coder_notes = ""
)]
setorder(interaction_audit, product_id, -interactions, row_id)
fwrite(interaction_audit, file.path(private_dir, "high_interaction_topic_audit.csv"), bom = TRUE)

high_interaction_coder_sheet <- interaction_audit[, .(
  row_id, TITLE, excerpt,
  human_topic_primary, human_topic_secondary, none_or_unclear, coder_id, coder_notes
)]
setorder(high_interaction_coder_sheet, row_id)
high_interaction_answer_key <- interaction_audit[, .(
  row_id, product_id, display_name, period, date, URL, interactions,
  audit_scopes, audit_keys, audit_for_product_topics,
  predicted_topics, predicted_allocations
)]
setorder(high_interaction_answer_key, row_id)
fwrite(
  high_interaction_coder_sheet,
  file.path(private_dir, "high_interaction_coder_sheet.csv"),
  bom = TRUE
)
fwrite(
  high_interaction_answer_key,
  file.path(private_dir, "high_interaction_answer_key.csv"),
  bom = TRUE
)

model_results <- list()
main_raw <- fit_time_hac(main_lag, "next_production_pct", "gap_pp", TRUE, params$hac_lag)
model_results[[length(model_results) + 1L]] <- model_row(
  main_raw, "main_2024_2026", "headline_raw", "gap_pp", "time-HAC (Bartlett, lag 2)",
  "Product-by-topic and topic-by-current-month fixed effects; controls current production share"
)
full_text_result <- fit_time_hac(
  main_lag_full, "next_production_pct", "gap_pp", TRUE, params$hac_lag
)
model_results[[length(model_results) + 1L]] <- model_row(
  full_text_result, "main_2024_2026", "classification_full_text", "gap_pp",
  "time-HAC (Bartlett, lag 2)",
  "Classification uses title plus full page text instead of the primary 3,000-character body window"
)

message("Running ", params$bootstrap_reps, " month-cluster bootstrap replications ...")
bootstrap_estimates <- month_cluster_bootstrap(
  main_lag, "next_production_pct", "gap_pp", TRUE,
  params$bootstrap_reps, params$random_seed
)
if (length(bootstrap_estimates) < ceiling(0.9 * params$bootstrap_reps)) {
  stop("More than 10% of month-cluster bootstrap models failed.", call. = FALSE)
}
bootstrap_row <- model_row(
  main_raw, "main_2024_2026", "headline_raw", "gap_pp", "IID whole-month cluster bootstrap",
  paste0(length(bootstrap_estimates),
         " successful IID whole-current-month cluster replications; percentile interval; HAC is primary")
)
bootstrap_row[, `:=`(
  standard_error = stats::sd(bootstrap_estimates),
  conf_low = as.numeric(stats::quantile(bootstrap_estimates, 0.025, names = FALSE)),
  conf_high = as.numeric(stats::quantile(bootstrap_estimates, 0.975, names = FALSE)),
  p_value = NA_real_,
  degrees_freedom = NA_integer_
)]
model_results[[length(model_results) + 1L]] <- bootstrap_row

robust_specs <- list(
  list(name = "winsorized_99", predictor = "gap_pp_winsorized", outcome = "next_production_pct",
       include_production = TRUE, note = "Interactions capped at each product-month's 99th percentile"),
  list(name = "top_post_removed", predictor = "gap_pp_top_removed", outcome = "next_production_pct",
       include_production = TRUE, note = "Highest-interaction post removed from each product-month"),
  list(name = "change_score", predictor = "gap_pp", outcome = "change_in_production_pp",
       include_production = TRUE,
       note = "Outcome is next minus current production share; controls current production share")
)
for (spec in robust_specs) {
  fit_result <- fit_time_hac(main_lag, spec$outcome, spec$predictor,
                             spec$include_production, params$hac_lag)
  model_results[[length(model_results) + 1L]] <- model_row(
    fit_result, "main_2024_2026", spec$name, spec$predictor,
    "time-HAC (Bartlett, lag 2)", spec$note
  )
}

log_lag <- main_lag[post_mass >= 3 & is.finite(log_interaction_premium)]
if (nrow(log_lag) && uniqueN(log_lag$period) >= 6L) {
  log_result <- fit_time_hac(log_lag, "next_production_pct", "log_interaction_premium",
                             TRUE, params$hac_lag)
  model_results[[length(model_results) + 1L]] <- model_row(
    log_result, "main_2024_2026", "mean_log1p_premium_min3", "log_interaction_premium",
    "time-HAC (Bartlett, lag 2)",
    "Centered mean log(1 + interactions); topic-month requires at least three assigned posts"
  )
}

if (nrow(historical_lag) && uniqueN(historical_lag$period) >= 6L) {
  historical_raw <- fit_time_hac(historical_lag, "next_production_pct", "gap_pp",
                                 TRUE, params$hac_lag)
  model_results[[length(model_results) + 1L]] <- model_row(
    historical_raw, "historical_2021_2023", "historical_replication", "gap_pp",
    "time-HAC (Bartlett, lag 2)",
    "Separate-era consistency check with four products from two organizations; never pooled with the main estimate"
  )
}

for (left_out in unique(main_lag$product_id)) {
  reduced <- main_lag[product_id != left_out]
  leave_result <- tryCatch(
    fit_time_hac(reduced, "next_production_pct", "gap_pp", TRUE, params$hac_lag),
    error = function(e) NULL
  )
  if (!is.null(leave_result)) {
    model_results[[length(model_results) + 1L]] <- model_row(
      leave_result, "main_2024_2026", paste0("leave_product_out:", left_out), "gap_pp",
      "time-HAC (Bartlett, lag 2)", "Influence diagnostic"
    )
  }
}
for (left_out in unique(main_lag$organization_id)) {
  reduced <- main_lag[organization_id != left_out]
  leave_result <- tryCatch(
    fit_time_hac(reduced, "next_production_pct", "gap_pp", TRUE, params$hac_lag),
    error = function(e) NULL
  )
  if (!is.null(leave_result)) {
    model_results[[length(model_results) + 1L]] <- model_row(
      leave_result, "main_2024_2026", paste0("leave_organization_out:", left_out), "gap_pp",
      "time-HAC (Bartlett, lag 2)", "Influence diagnostic"
    )
  }
}

lag_model <- rbindlist(model_results, fill = TRUE)
fwrite(lag_model, file.path(output_dir, "lag_model.csv"), bom = TRUE)
saveRDS(bootstrap_estimates, file.path(intermediate_dir, "bootstrap_estimates.rds"), compress = "xz")

message("Writing diagnostics and figures ...")
classification_diagnostics <- analysis_posts[, .(
  n_posts = .N,
  classification_rate = mean(classified),
  tie_rate_all_posts = mean(winning_topics > 1L),
  tie_rate_classified_posts = mean(winning_topics[classified] > 1L),
  unclassified_interaction_share = safe_ratio(
    sum(interactions[interaction_valid & !classified]),
    sum(interactions[interaction_valid])
  )
), by = analysis_era]

headline_post_rows <- copy(analysis_posts[analysis_era == "main_2024_2026"])
headline_post_rows[, period := as.Date(format(date, "%Y-%m-01"))]
headline_post_rows <- headline_post_rows[
  paste(product_id, period) %in% paste(headline_panel$product_id, headline_panel$period)
]
headline_interaction_diagnostics <- headline_post_rows[, {
  valid_interactions <- interactions[interaction_valid]
  sorted_interactions <- sort(valid_interactions, decreasing = TRUE)
  .(
    interaction_zero_rate = if (length(valid_interactions)) mean(valid_interactions == 0) else NA_real_,
    top_10_interaction_share = if (sum(valid_interactions) > 0)
      sum(head(sorted_interactions, 10L)) / sum(valid_interactions) else NA_real_,
    n_posts = .N,
    recorded_interactions = sum(valid_interactions)
  )
}, by = .(product_id, display_name)]

diagnostics <- rbindlist(list(
  data.table(section = "corpus", metric = "official_corpus_rows", group = "all",
             value = jsonlite::fromJSON(digikat_corpus_manifest_path())$corpus$rows,
             notes = "Rows in the official corpus manifest"),
  data.table(section = "corpus", metric = "mapped_rows_all_dates", group = "registered_products",
             value = nrow(mapped_all), notes = "Rows matching source label plus URL host registry"),
  classification_diagnostics[, .(
    section = "classification", metric = "posts", group = analysis_era,
    value = n_posts, notes = "Deduplicated posts sent to topic scorer"
  )],
  classification_diagnostics[, .(
    section = "classification", metric = "classification_rate", group = analysis_era,
    value = classification_rate, notes = "Share with at least one dictionary match"
  )],
  classification_diagnostics[, .(
    section = "classification", metric = "tie_rate_classified", group = analysis_era,
    value = tie_rate_classified_posts, notes = "Share of classified posts with co-max topic winners"
  )],
  classification_diagnostics[, .(
    section = "classification", metric = "unclassified_interaction_share", group = analysis_era,
    value = unclassified_interaction_share,
    notes = "Recorded interactions excluded because the post had no topic assignment"
  )],
  data.table(
    section = "classification",
    metric = "bounded_vs_full_winner_agreement",
    group = "all_eligible_posts",
    value = winner_agreement_rate,
    notes = paste0("Exact co-winner-set agreement; primary window is title plus first ",
                   params$classification_text_characters, " body characters")
  ),
  validation_sample[, .(
    section = "validation", metric = "sampled_unique_posts",
    group = sampling_topic, value = uniqueN(row_id),
    notes = "Private audit sample; separate prediction-free coder sheet and answer key were written"
  ), by = sampling_topic][, sampling_topic := NULL],
  data.table(
    section = "validation",
    metric = c(
      "high_interaction_unique_posts",
      "headline_product_topics_covered",
      "headline_product_months_covered",
      "lag_product_topic_months_covered"
    ),
    group = "high_interaction_audit",
    value = c(
      uniqueN(interaction_audit$row_id),
      uniqueN(headline_topic_coverage$audit_key),
      uniqueN(headline_month_coverage$audit_key),
      uniqueN(lag_cell_coverage$audit_key)
    ),
    notes = c(
      "Deduplicated articles in the mandatory high-interaction audit",
      "Top five interaction contributors sampled within every non-empty retained headline product-topic",
      "Top classified interaction post sampled within every retained headline product-month",
      "Top interaction contributor sampled within every non-empty product-topic-month in the main lag panel"
    )
  ),
  headline_interaction_diagnostics[, .(
    section = "interaction_profile", metric = "zero_interaction_rate",
    group = product_id, value = interaction_zero_rate,
    notes = paste0(n_posts, " posts across retained 2025 months")
  )],
  headline_interaction_diagnostics[, .(
    section = "interaction_profile", metric = "top_10_interaction_share",
    group = product_id, value = top_10_interaction_share,
    notes = paste0(recorded_interactions, " total recorded interactions")
  )],
  editorial_item_summary[, .(
    section = "editorial_gate", metric = "non_editorial_rows_removed",
    group = paste(analysis_era, product_id, sep = ":"), value = non_editorial_rows_removed,
    notes = paste0(sprintf("%.1f", 100 * editorial_removal_rate),
                   "% of mapped study rows; ", non_editorial_interactions_removed,
                   " recorded interactions removed")
  )],
  editorial_item_diagnostics[, .(
    section = "editorial_gate", metric = paste0("rule:", non_editorial_reason),
    group = paste(analysis_era, product_id, sep = ":"), value = non_editorial_rows_removed,
    notes = paste0(non_editorial_interactions_removed, " recorded interactions removed")
  )],
  duplicate_diagnostics[, .(
    section = "deduplication", metric = "duplicate_urls_removed",
    group = paste(analysis_era, product_id, sep = ":"), value = duplicate_urls_removed,
    notes = paste0("From ", rows_before_deduplication, " mapped rows")
  )],
  measurement_2026[, .(
    section = "measurement_2026", metric = "zero_interaction_rate",
    group = paste(product_id, format(month, "%Y-%m"), sep = ":"), value = zero_rate,
    notes = paste0(n_posts, " posts; positive rate ", sprintf("%.3f", positive_rate))
  )],
  monthly_primary_coverage[, .(
    section = "collection_coverage", metric = "days_below_10_primary_posts",
    group = format(month, "%Y-%m"), value = days_below_10_posts,
    notes = paste0(zero_post_days, " zero-post days out of ", calendar_days,
                   "; median daily posts ", median_daily_posts)
  )],
  data.table(section = "headline", metric = "eligible_products", group = "2025_complete_months",
             value = uniqueN(headline_panel$product_id), notes = "Equal-weighted in field result"),
  data.table(section = "headline", metric = "eligible_product_months", group = "2025_complete_months",
             value = uniqueN(headline_panel[, .(product_id, period)]),
             notes = "January, March, April, May, and September excluded; minimum 30 classified posts and engagement gates"),
  data.table(section = "event", metric = "weeks_below_three_products", group = "papal_transition_window",
             value = sum(!weekly_system$sufficient_coverage),
             notes = "Event contrast is not estimated because key weeks are missing"),
  data.table(section = "lag_model", metric = "observations", group = "main",
             value = main_raw$n_obs, notes = "Product-month-topic transitions after support gate"),
  data.table(section = "lag_model", metric = "periods", group = "main",
             value = main_raw$n_periods, notes = "Current months; exact next-calendar-month transitions only"),
  data.table(section = "lag_model", metric = "bootstrap_successful", group = "main",
             value = length(bootstrap_estimates), notes = paste0(params$bootstrap_reps, " requested"))
), fill = TRUE)
setorder(diagnostics, section, metric, group)
fwrite(diagnostics, file.path(output_dir, "diagnostics.csv"), bom = TRUE)

plot_field <- copy(field_public)
plot_field[, topic_label := factor(topic_label, levels = topic_label[order(gap_pp)])]
plot_points <- melt(
  plot_field,
  id.vars = c("topic", "topic_label"),
  measure.vars = c("production_pct", "reward_pct"),
  variable.name = "series", value.name = "share_pct"
)
plot_points[, series := factor(series,
                               levels = c("production_pct", "reward_pct"),
                               labels = c("Objavljeno", "Nagrađeno"))]

flagship_plot <- ggplot(plot_field, aes(y = topic_label)) +
  geom_segment(aes(x = production_pct, xend = reward_pct, yend = topic_label),
               linewidth = 1.1, color = dk_col$line, alpha = 0.65) +
  geom_point(data = plot_points, aes(x = share_pct, color = series), size = 3.2) +
  scale_color_manual(values = c("Objavljeno" = dk_col$ink, "Nagrađeno" = dk_col$accent),
                     name = NULL) +
  scale_x_continuous(labels = scales::label_number(suffix = "%", decimal.mark = ","),
                     expand = expansion(mult = c(0.02, 0.08))) +
  labs(
    title = "Što katolički mediji objavljuju — i što publika nagrađuje",
    subtitle = "Prosječni tematski udio po proizvodu, sedam potpunih mjeseci 2025.",
    x = "Udio u tematskoj košarici", y = NULL,
    caption = "DigiKat · šest web-proizvoda ima jednaku težinu · siječanj, ožujak–svibanj i rujan isključeni su zbog praznina u prikupljanju"
  ) +
  theme_digikat(base_size = 13) +
  theme(legend.position = "top", panel.grid.major.y = element_blank())
ggsave(file.path(figure_dir, "produced_vs_rewarded.png"), flagship_plot,
       width = 11, height = 8.2, dpi = 300, bg = dk_col$paper)

outlet_plot <- copy(outlet_topic_private)
setorder(outlet_plot, product_id, gap_pp)
outlet_plot[, topic_plot := factor(
  paste(product_id, topic_label, sep = "___"),
  levels = unique(paste(product_id, topic_label, sep = "___"))
)]
outlet_plot_points <- melt(
  outlet_plot,
  id.vars = c("product_id", "display_name", "topic_plot"),
  measure.vars = c("production_pct", "reward_pct"),
  variable.name = "series", value.name = "share_pct"
)
outlet_plot_points[, series := factor(
  series,
  levels = c("production_pct", "reward_pct"),
  labels = c("Objavljeno", "Zabilježene interakcije")
)]
outlet_profile_plot <- ggplot(outlet_plot, aes(y = topic_plot)) +
  geom_segment(
    aes(x = production_pct, xend = reward_pct, yend = topic_plot),
    linewidth = 0.9, color = dk_col$line, alpha = 0.65
  ) +
  geom_point(data = outlet_plot_points, aes(x = share_pct, color = series), size = 2.5) +
  facet_wrap(vars(display_name), ncol = 2, scales = "free_y") +
  scale_y_discrete(labels = function(x) sub("^.*___", "", x)) +
  scale_color_manual(
    values = c("Objavljeno" = dk_col$ink, "Zabilježene interakcije" = dk_col$accent),
    name = NULL
  ) +
  scale_x_continuous(
    labels = scales::label_number(suffix = "%", decimal.mark = ","),
    expand = expansion(mult = c(0.02, 0.09))
  ) +
  labs(
    title = "Objavljeno i zabilježena pažnja po medijskom proizvodu",
    subtitle = "Privremeni prikaz za sedam potpunih mjeseci 2025.",
    x = "Udio u tematskoj košarici", y = NULL,
    caption = paste(
      "INTERNO · tematske oznake čekaju ljudsku provjeru",
      "· interakcije mjere zabilježenu pažnju, ne duboku sklonost publike"
    )
  ) +
  theme_digikat(base_size = 11) +
  theme(
    legend.position = "top",
    panel.grid.major.y = element_blank(),
    strip.text = element_text(face = "bold")
  )
ggsave(
  file.path(private_dir, "produced_vs_rewarded_by_outlet.png"),
  outlet_profile_plot, width = 12, height = 13, dpi = 300, bg = dk_col$paper
)

outlet_figure_dir <- file.path(private_dir, "outlet_figures")
dir.create(outlet_figure_dir, recursive = TRUE, showWarnings = FALSE)
for (current_product in unique(outlet_plot$product_id)) {
  product_plot <- copy(outlet_plot[product_id == current_product])
  setorder(product_plot, gap_pp)
  product_plot[, topic_label := factor(topic_label, levels = topic_label)]
  product_points <- melt(
    product_plot,
    id.vars = c("product_id", "display_name", "topic_label"),
    measure.vars = c("production_pct", "reward_pct"),
    variable.name = "series", value.name = "share_pct"
  )
  product_points[, series := factor(
    series,
    levels = c("production_pct", "reward_pct"),
    labels = c("Objavljeno", "Zabilježene interakcije")
  )]
  product_figure <- ggplot(product_plot, aes(y = topic_label)) +
    geom_segment(
      aes(x = production_pct, xend = reward_pct, yend = topic_label),
      linewidth = 1, color = dk_col$line, alpha = 0.65
    ) +
    geom_point(data = product_points, aes(x = share_pct, color = series), size = 3) +
    scale_color_manual(
      values = c("Objavljeno" = dk_col$ink, "Zabilježene interakcije" = dk_col$accent),
      name = NULL
    ) +
    scale_x_continuous(
      labels = scales::label_number(suffix = "%", decimal.mark = ","),
      expand = expansion(mult = c(0.02, 0.09))
    ) +
    labs(
      title = unique(product_plot$display_name),
      subtitle = "Objavljeno i zabilježena pažnja u sedam potpunih mjeseci 2025.",
      x = "Udio u tematskoj košarici", y = NULL,
      caption = paste(
        "INTERNO · tematske oznake čekaju ljudsku provjeru",
        "· interakcije mjere zabilježenu pažnju, ne duboku sklonost publike"
      )
    ) +
    theme_digikat(base_size = 12) +
    theme(legend.position = "top", panel.grid.major.y = element_blank())
  ggsave(
    file.path(outlet_figure_dir, paste0(current_product, ".png")),
    product_figure,
    width = 8.5,
    height = max(4.4, 2.6 + 0.42 * nrow(product_plot)),
    dpi = 300,
    bg = dk_col$paper
  )
}

event_plot <- ggplot(weekly_system, aes(x = period, y = estimate)) +
  annotate("rect", xmin = as.Date("2025-04-21"), xmax = as.Date("2025-05-11"),
           ymin = -Inf, ymax = Inf, fill = dk_col$accent_050, alpha = 0.8) +
  geom_line(color = dk_col$accent, linewidth = 1.1, na.rm = TRUE) +
  geom_point(color = dk_col$accent, size = 2.2, na.rm = TRUE) +
  geom_vline(xintercept = as.Date(c("2025-04-21", "2025-05-08")),
             color = dk_col$line, linetype = "dashed", linewidth = 0.6) +
  scale_x_date(date_breaks = "2 weeks", date_labels = "%d.%m.",
               expand = expansion(mult = c(0.02, 0.02))) +
  scale_y_continuous(labels = scales::label_number(suffix = " pp", decimal.mark = ",")) +
  labs(
    title = "Papinska tranzicija: ključni tjedni nedostaju",
    subtitle = "Deskriptivni tjedni prosjek prikazan je samo gdje postoje barem tri prihvatljiva proizvoda",
    x = NULL, y = "Ukupna udaljenost",
    caption = "Nije moguće testirati sužavanje jaza: prikupljanje gotovo izostaje 29.3.–10.4. i 28.4.–10.5.2025."
  ) +
  theme_digikat(base_size = 13) +
  theme(legend.position = "none")
ggsave(file.path(figure_dir, "papal_transition_gap.png"), event_plot,
       width = 10.5, height = 6.4, dpi = 300, bg = dk_col$paper)

coefficient_plot_data <- lag_model[
  analysis_era == "main_2024_2026" & specification == "headline_raw" &
    uncertainty == "time-HAC (Bartlett, lag 2)"
]
coefficient_plot_data[, label := "Učinak premije ovog mjeseca\nna udio teme idućeg mjeseca"]
coefficient_plot <- ggplot(coefficient_plot_data, aes(x = estimate, y = label)) +
  geom_vline(xintercept = 0, color = dk_col$line, linewidth = 0.7) +
  geom_errorbar(aes(xmin = conf_low, xmax = conf_high), width = 0.13,
                linewidth = 0.9, color = dk_col$accent, orientation = "y") +
  geom_point(size = 3.6, color = dk_col$accent) +
  scale_x_continuous(labels = scales::label_number(accuracy = 0.01, decimal.mark = ",")) +
  labs(
    title = "Prati li ponuda ono što je publika nagradila?",
    subtitle = "Koeficijent fiksnih učinaka i 95-postotni vremenski HAC interval",
    x = "Promjena idućeg udjela (pp) za 1 pp aktualnog jaza", y = NULL,
    caption = "Kontroliran aktualni udio teme · fiksni učinci proizvod×tema i tema×mjesec"
  ) +
  theme_digikat(base_size = 13) +
  theme(panel.grid.major.y = element_blank())
ggsave(file.path(figure_dir, "lag_coefficient.png"), coefficient_plot,
       width = 9.5, height = 4.6, dpi = 300, bg = dk_col$paper)

result_payload <- list(
  study = "The News Gap, Catholic edition",
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  status = study_status,
  definitions = list(
    production = "Share of fractionally assigned classified post mass by topic.",
    rewarded = "Share of recorded interactions allocated with the same fractional topic assignments.",
    gap_pp = "Rewarded share minus production share, in percentage points.",
    distance_pp = "Half the sum of absolute topic gaps; the share of the vector that would need to move to align them.",
    lag_coefficient = "Change in next-month topic share for a one-percentage-point current gap, conditional on current share and fixed effects.",
    headline_aggregation = "Pool retained months within each product, convert each product to shares, then average the six product vectors equally."
  ),
  headline_months = sort(unique(format(headline_panel$period, "%Y-%m"))),
  caveats = c(
    "The canonical dictionary includes broad stems; the audit sample shows face-validity failures in several categories. Findings are provisional and blocked from publication or client use pending human validation and revised study-specific rules.",
    "Interactions are platform-recorded signals, not a complete measure of audience preference or demand.",
    "September 2024 and January, March, April, May, and September 2025 are excluded because primary-source collection is incomplete.",
    "January 2026 is used only as a supply outcome; the engagement headline ends in December 2025.",
    "The papal-transition contrast is not estimable because collection is nearly absent during two key multi-day windows, including the conclave and election."
  ),
  field_gap_2025 = as.data.frame(field_public),
  outlet_profiles_2025 = as.data.frame(outlet_profiles),
  event_results = as.data.frame(event_results),
  lag_models = as.data.frame(lag_model),
  diagnostics = as.data.frame(diagnostics)
)
jsonlite::write_json(result_payload, file.path(output_dir, "analysis_results.json"),
                     pretty = TRUE, auto_unbox = TRUE, digits = 8, na = "null")

public_files <- list.files(output_dir, recursive = TRUE, full.names = TRUE)
public_files <- public_files[file.exists(public_files) & !dir.exists(public_files)]
public_files <- public_files[!grepl("/(private|intermediate)/", gsub("\\\\", "/", public_files))]
public_files <- public_files[basename(public_files) != "manifest.json"]
relative_to_repo <- function(path) {
  normalized_path <- gsub("\\\\", "/", normalizePath(path, winslash = "/", mustWork = TRUE))
  normalized_root <- paste0(gsub("\\\\", "/", repo_root), "/")
  if (startsWith(normalized_path, normalized_root)) {
    substring(normalized_path, nchar(normalized_root) + 1L)
  } else {
    normalized_path
  }
}
public_hashes <- lapply(public_files, function(path) list(
  path = relative_to_repo(path),
  sha256 = hash_file(path),
  bytes = unname(file.info(path)$size)
))

corpus_manifest <- jsonlite::fromJSON(digikat_corpus_manifest_path(), simplifyVector = TRUE)
manifest_params <- lapply(params, function(value) {
  if (inherits(value, "Date")) format(value, "%Y-%m-%d") else value
})
manifest <- list(
  study = "news-gap",
  generated_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
  analysis_status = "exploratory_pending_manual_dictionary_validation",
  input = list(
    corpus_path = corpus_path,
    corpus_sha256 = corpus_manifest$corpus$sha256,
    corpus_rows = corpus_manifest$corpus$rows,
    dictionary_path = "R/lib/thematic_dictionaries.R",
    dictionary_file_sha256 = hash_file("R/lib/thematic_dictionaries.R"),
    registry_path = "studies/news-gap/source_registry.csv",
    registry_sha256 = hash_file(registry_path)
  ),
  code = list(
    analysis_sha256 = hash_file(script_path),
    checks_sha256 = if (file.exists(file.path(study_dir, "checks.R"))) hash_file(file.path(study_dir, "checks.R")) else NULL,
    r_version = R.version.string
  ),
  parameters = manifest_params,
  public_outputs = public_hashes
)
jsonlite::write_json(manifest, file.path(output_dir, "manifest.json"),
                     pretty = TRUE, auto_unbox = TRUE, digits = 10, na = "null")

message("News-gap analysis complete. Public outputs: ", output_dir)
