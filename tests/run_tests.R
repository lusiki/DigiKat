#!/usr/bin/env Rscript
# Dependency-light regression tests for the safety-critical DigiKat helpers.

source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/thematic_dictionaries.R", encoding = "UTF-8")
source("R/lib/page_summaries.R", encoding = "UTF-8")
source("R/lib/digikat_events.R", encoding = "UTF-8")
source("R/lib/moj_medij_metrics.R", encoding = "UTF-8")
source("R/lib/moj_medij_topics.R", encoding = "UTF-8")
source("R/lib/digikat_hr.R", encoding = "UTF-8")
source("R/lib/digikat_charts.R", encoding = "UTF-8")

failures <- character()
checks <- 0L

expect_true <- function(value, label) {
  checks <<- checks + 1L
  if (!isTRUE(value)) failures <<- c(failures, label)
}
expect_equal <- function(value, expected, label) {
  checks <<- checks + 1L
  if (!identical(value, expected)) {
    failures <<- c(
      failures,
      paste0(label, " (expected ", paste(expected, collapse = ", "), "; got ", paste(value, collapse = ", "), ")")
    )
  }
}

youtube_a <- digikat_canonicalize_url("https://www.youtube.com/watch?v=AAA&utm_source=newsletter")
youtube_b <- digikat_canonicalize_url("https://www.youtube.com/watch?v=BBB&utm_source=newsletter")
expect_true(youtube_a != youtube_b, "Distinct YouTube video IDs must remain distinct")
expect_equal(
  youtube_a,
  "https://youtube.com/watch?v=AAA",
  "YouTube tracking parameters should be removed without removing v"
)
expect_equal(
  digikat_canonicalize_url("https://youtu.be/AAA?si=tracking"),
  youtube_a,
  "Short and watch-form YouTube URLs should share one identity key"
)
expect_equal(
  digikat_canonicalize_url("http://www.example.com/Case/Path/?id=42&utm_medium=email#section"),
  "https://example.com/Case/Path?id=42",
  "General URL normalization should preserve path case and identity query values"
)
expect_equal(
  digikat_canonicalize_url("https://example.com/article?story=one"),
  "https://example.com/article?story=one",
  "Unknown query parameters must be preserved by default"
)
expect_true(is.na(digikat_canonicalize_url(NA_character_)), "NA URL should remain NA")
expect_true(is.na(digikat_canonicalize_url("  ")), "Blank URL should become NA")

expect_true(!digikat_parse_bool("0", "test"), "Boolean parser must treat 0 as false")
expect_true(digikat_parse_bool("true", "test"), "Boolean parser must treat true as true")
invalid_bool <- inherits(try(digikat_parse_bool("sometimes", "test"), silent = TRUE), "try-error")
expect_true(invalid_bool, "Boolean parser must reject ambiguous values")

date_test <- data.frame(
  DATE = c("2022-12-31", "2023-01-01"),
  year = c(2023, 2023),
  stringsAsFactors = FALSE
)
normalized <- digikat_normalize_date_year(date_test)
expect_equal(normalized$year, c(2022L, 2023L), "year must be derived from canonical DATE")
expect_equal(
  attr(normalized, "digikat_year_mismatch_rows"),
  1L,
  "DATE/year mismatches should be reported"
)

test_terms <- data.frame(
  term = c("vjera", "crkva", "molitva"),
  regex = c("\\bvjer\\w*", "\\bcrkv\\w*", "\\bmolitv\\w*"),
  stringsAsFactors = FALSE
)
match_result <- digikat_match_religious(
  c(
    "Vjera i crkva nalaze se u ovoj sintetičkoj rečenici.",
    "Samo molitva nalazi se u ovom retku.",
    NA_character_
  ),
  test_terms,
  min_matches = 2L,
  progress = FALSE
)
expect_equal(match_result$root_match_count, c(2L, 1L, 0L), "Distinct religious-term counts must be stable")
expect_true(
  !is.na(match_result$matched_terms[[1L]]) && is.na(match_result$matched_terms[[2L]]),
  "Detailed match text should be produced only for qualifying rows"
)

expect_equal(length(digikat_thematic_dictionaries), 16L, "Canonical thematic dictionary must have 16 categories")
expect_true(
  all(vapply(digikat_thematic_dictionaries, length, integer(1L)) > 0L),
  "Every thematic category must contain at least one term"
)
expect_equal(
  names(DIGIKAT_TOPIC_PROFILE_LABELS),
  names(digikat_thematic_dictionaries),
  "Public topic labels must cover the canonical dictionary in canonical order"
)

topic_fixture <- data.frame(
  FROM = rep(LETTERS[1:5], each = 3L),
  SOURCE_TYPE = "web",
  TITLE = c(
    "crkva", "crkva", "film",
    "crkva", "crkva", "film",
    "film", "film", "crkva",
    "crkva", "film", "crkva film",
    "crkva", "crkva", "crkva"
  ),
  FULL_TEXT = "",
  stringsAsFactors = FALSE
)
topic_fixture_profiles <- digikat_topic_profiles(
  topic_fixture,
  dictionary = list(CRKVA = "crkv", KULTURA = "film"),
  chunk_size = 4L
)
topic_a <- topic_fixture_profiles[topic_fixture_profiles$FROM == "A", , drop = FALSE]
expect_true(
  all(abs(topic_a$topic_share - c(66.6666667, 33.3333333)) < 1e-6),
  "Topic profiles must convert classified posts to production shares"
)
topic_d <- topic_fixture_profiles[topic_fixture_profiles$FROM == "D", , drop = FALSE]
expect_true(
  all(abs(topic_d$topic_mass - c(1.5, 1.5)) < 1e-9),
  "Tied dictionary winners must divide one post fractionally"
)
topic_fixture_comparison <- digikat_topic_comparisons(
  topic_fixture_profiles,
  listed_sources = LETTERS[1:5],
  min_classified_posts = 3L,
  max_neighbours = 4L,
  min_neighbours = 3L
)
topic_fixture_peer <- unique(topic_fixture_comparison$profiles[
  , c("SOURCE_TYPE", "topic", "peer_share"), drop = FALSE
])
expect_true(
  all(abs(tapply(topic_fixture_peer$peer_share,
                 topic_fixture_peer$SOURCE_TYPE, sum) - 100) < 1e-9),
  "Same-platform peer topic averages must sum to 100 percent"
)
expect_equal(
  topic_fixture_comparison$neighbours[[digikat_topic_profile_key("A", "web")]][[1L]],
  "B",
  "Cosine neighbours must rank an identical same-platform topic vector first"
)
expect_true(
  all(vapply(topic_fixture_comparison$neighbours, length, integer(1L)) == 4L),
  "Eligible topic profiles must store four neighbours when four are available"
)

topic_window_fixture <- data.frame(
  FROM = c("outside", "inside"),
  SOURCE_TYPE = "web",
  TITLE = "",
  FULL_TEXT = c(paste0(strrep("x", 3001L), " crkva"), "crkva"),
  stringsAsFactors = FALSE
)
topic_window_profiles <- digikat_topic_profiles(
  topic_window_fixture,
  dictionary = list(CRKVA = "crkv"),
  text_characters = 3000L,
  chunk_size = 1L
)
expect_equal(
  topic_window_profiles$classified_posts,
  c(0L, 1L),
  "Topic classification must stop at the first 3,000 body characters"
)

expect_equal(
  digikat_top_n_interaction_share(c(50, 25, 25, 0), n = 1L),
  50,
  "Attention concentration must publish an interaction share, not top posts"
)
expect_equal(
  digikat_zero_interaction_rate(c(0, 2, NA_real_)),
  50,
  "Zero-interaction rate must use vendor-measured posts as its denominator"
)
expect_equal(
  digikat_time_band(c(0L, 5L, 6L, 13L, 22L, 23L)),
  c(1L, 1L, 2L, 3L, 6L, 6L),
  "Publishing hours must map to the six public time bands"
)
expect_equal(
  digikat_rate_ratio(9, 3, 28, 28),
  3,
  "Calendar surge must compare daily event and baseline rates"
)

profile_events <- digikat_calendar_events(c(2024L, 2025L), moj_medij_only = TRUE)
expect_equal(
  as.integer(table(format(profile_events$date, "%Y"))),
  c(4L, 6L),
  "Moj medij must carry four to six reviewed calendar events per complete year"
)
calendar_2024 <- seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")
easter_gap <- seq(as.Date("2024-03-30"), as.Date("2024-04-01"), by = "day")
test_windows <- digikat_event_windows(
  profile_events[profile_events$id == "easter-2024", , drop = FALSE],
  calendar_2024[!calendar_2024 %in% easter_gap]
)
expect_true(
  !test_windows$registry$measurable[[1L]] &&
    identical(test_windows$registry$reason[[1L]], "collection_gap"),
  "An event overlapping a collection gap must be unmeasurable, never zero"
)

rhythm_fixture <- data.frame(
  FROM = rep("example.invalid", 39),
  SOURCE_TYPE = rep("web", 39),
  DATE = c(rep("2025-01-06", 20), rep("2025-01-07", 19)),
  TIME = c(rep("10:30:00", 20), rep("10:30:00", 19)),
  INTERACTIONS = c(rep(2, 20), rep(5, 19)),
  stringsAsFactors = FALSE
)
rhythm_test <- digikat_rhythm_cells(rhythm_fixture, min_cell_posts = 20L)
expect_equal(nrow(rhythm_test), 1L, "Publishing-rhythm cells below 20 posts must be suppressed")
expect_equal(rhythm_test$engagement, 2, "Rhythm cells must report interactions per post")

moj_medij_raw <- paste(readLines("data/page-ready/moj_medij.json", encoding = "UTF-8", warn = FALSE),
                       collapse = "\n")
moj_medij <- jsonlite::fromJSON(moj_medij_raw, simplifyVector = FALSE)
expect_equal(moj_medij$schema_version, 4L, "Moj medij public artifact must use topic schema v4")
expect_true(
  all(vapply(moj_medij$sources, function(source) length(source$bh) > 0L, logical(1L))),
  "Every public Moj medij profile must contain platform-specific behavioural metrics"
)
published_rhythm_counts <- unlist(lapply(moj_medij$sources, function(source) {
  unlist(lapply(source$bh, function(platform) {
    if (length(platform$r)) vapply(platform$r, function(cell) cell$p, integer(1L)) else integer()
  }))
}))
expect_true(
  all(published_rhythm_counts >= moj_medij$policy$rhythm_min_cell_posts),
  "No sub-threshold rhythm-cell count may enter the public artifact"
)
expect_equal(
  moj_medij$behaviour$topics$status,
  "provisional_validation_leads_not_rankings",
  "The public topic panel must preserve its provisional validation-only status"
)
expect_equal(
  length(moj_medij$behaviour$topics$labels),
  16L,
  "The public topic panel must carry all 16 canonical topic labels"
)
published_platform_profiles <- unlist(lapply(moj_medij$sources, function(source) source$bh),
                                      recursive = FALSE)
published_topic_profiles <- Filter(function(platform) !is.null(platform$tm),
                                   published_platform_profiles)
expect_true(length(published_topic_profiles) > 0L, "Eligible public profiles must carry topic mixes")
expect_true(
  all(vapply(published_topic_profiles, function(platform) {
    platform$tm$n >= moj_medij$policy$topic_min_classified_posts &&
      length(platform$tm$s) == 16L && length(platform$tm$f) == 16L &&
      abs(sum(unlist(platform$tm$s)) - 100) <= 0.1 &&
      abs(sum(unlist(platform$tm$f)) - 100) <= 0.1
  }, logical(1L))),
  "Published topic mixes must clear the support floor and reconcile to 100 percent"
)
published_neighbours <- Filter(function(platform) !is.null(platform$sn),
                               published_platform_profiles)
expect_true(
  all(vapply(published_neighbours, function(platform) {
    is.character(unlist(platform$sn)) && length(platform$sn) %in% 3:4
  }, logical(1L))),
  "Similar-source payloads must contain only three or four source names"
)
public_easter_2024 <- Filter(
  function(event) identical(event$id, "easter-2024"),
  moj_medij$behaviour$calendar$events
)[[1L]]
expect_true(
  identical(public_easter_2024$ok, FALSE) && identical(public_easter_2024$rs, "collection_gap"),
  "The public artifact must label Easter 2024 unmeasurable because of the collection gap"
)
expect_true(
  !grepl("FULL_TEXT|\\\"URL\\\"|http://|https://", moj_medij_raw, perl = TRUE),
  "Moj medij public artifact must not expose text, URLs or post identifiers"
)

sample_path <- "data/sample/merged_sample.rds"
expect_true(file.exists(sample_path), "Synthetic fixture must exist")
if (file.exists(sample_path)) {
  sample <- readRDS(sample_path)
  expect_equal(ncol(sample), 47L, "Synthetic fixture must match the 47-column production schema")
  expect_equal(nrow(sample), 2700L, "Synthetic fixture must retain every planned stratum row")
  expect_equal(length(unique(sample$SOURCE_TYPE)), 9L, "Synthetic fixture must cover nine source types")
  expect_true(
    all(grepl("^https://example\\.invalid/", sample$URL)),
    "Synthetic fixture must not contain source URLs"
  )
  expect_true(
    all(grepl("sinteti", sample$FULL_TEXT, ignore.case = TRUE)),
    "Synthetic fixture text must be visibly synthetic"
  )
  sample_manifest <- jsonlite::read_json(
    "data/sample/merged_sample_manifest.json",
    simplifyVector = TRUE
  )
  expect_equal(
    sample_manifest$sha256,
    digikat_hash_file(sample_path),
    "Synthetic fixture manifest hash must match the fixture"
  )
}

expected_aggregates <- sort(c(
  "facebook_actors.rds", "instagram_actors.rds", "platform_monthly.rds",
  "platform_summary.rds", "proportions_summary.rds", "source_summary.rds",
  "tiktok_actors.rds", "top_facebook_sources.rds", "top_sources_by_year.rds",
  "top_web_sources.rds", "top_youtube_sources.rds", "twitter_actors.rds",
  "web_actors.rds", "youtube_actors.rds"
))
actual_aggregates <- sort(list.files("data/processed", pattern = "\\.rds$"))
expect_equal(
  actual_aggregates,
  expected_aggregates,
  "Tracked production aggregate generation must contain the canonical 14 files"
)

provenance <- utils::read.csv(
  "resources/PROVENANCE.csv",
  stringsAsFactors = FALSE,
  check.names = FALSE,
  fileEncoding = "UTF-8-BOM"
)
expect_true(all(file.exists(provenance$path)), "Every inventoried language resource must exist")
if (all(file.exists(provenance$path))) {
  expect_true(
    all(as.double(file.info(provenance$path)$size) == as.double(provenance$bytes)),
    "Every inventoried language-resource byte count must match"
  )
  resource_hashes <- vapply(provenance$path, digikat_hash_file, character(1L))
  expect_true(
    identical(unname(resource_hashes), provenance$sha256),
    "Every inventoried language-resource SHA-256 must match"
  )
}

citation <- yaml::read_yaml("CITATION.cff", eval.expr = FALSE)
expect_equal(citation[["cff-version"]], "1.2.0", "CITATION.cff must parse at the supported schema version")

retired_active_paths <- c(
  "R/Croatian_stemmer.py", "R/stemmer.R", "R/text_analysis.R",
  "R/write_tokens.R", "R/load_merge_filter_religious.R", "R/merge_and_save_data.R",
  "R/general_catholic_mediaspace.qmd", "load_and_merge_xlsx.R", "patch_master.R"
)
expect_true(
  !any(file.exists(retired_active_paths)),
  "Retired pipeline scripts must not return to the active R directory"
)

page_files <- c(
  "pages/mapa/mapa_stats.qmd",
  "pages/mapa/događaji.qmd",
  "pages/mapa/diskurs.qmd"
)
embedded_dictionary_definitions <- sum(vapply(
  page_files,
  function(path) {
    lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
    sum(grepl("DUHOVNOST_I_LITURGIJA\\s*=\\s*c\\(", lines))
  },
  integer(1L)
))
expect_equal(
  embedded_dictionary_definitions,
  0L,
  "Analytical pages must source, not duplicate, the thematic dictionary"
)
direct_nlp_reads <- sum(vapply(
  page_files,
  function(path) {
    lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
    # The guard is about ROW-LEVEL generations: anything under data/nlp/ except its manifest, plus the
    # _tokens/_sample files. data/nlp/manifest.json is metadata only (sample sizes and proportions the
    # page prints), and reading it is what keeps those figures from being typed by hand.
    sum(grepl("data/nlp(?!/manifest\\.json)|_tokens\\.rds|_sample\\.rds", lines, perl = TRUE))
  },
  integer(1L)
))
expect_equal(
  direct_nlp_reads,
  0L,
  "Analytical pages must read compact page-ready summaries, not row-level NLP generations"
)

page_summary_schema <- digikat_page_summary_schema()
expect_equal(
  names(page_summary_schema),
  c("mapa_stats", "diskurs", "dogadjaji"),
  "Page-summary schema must cover the canonical three NLP pages"
)
for (page in names(page_summary_schema)) {
  path <- file.path("data", "page-ready", paste0(page, ".rds"))
  expect_true(file.exists(path), paste("Page-ready summary must exist:", page))
  if (file.exists(path)) {
    valid <- !inherits(
      try(digikat_validate_page_summary(readRDS(path), page), silent = TRUE),
      "try-error"
    )
    expect_true(valid, paste("Page-ready summary must validate:", page))
  }
}

expect_equal(
  digikat_hr_date(as.Date("2026-06-11")),
  "11. lipnja 2026.",
  "Shared Croatian dates must use a lowercase genitive month"
)
safe_chart_fixture <- data.frame(year = 2026L, total_posts = 10L)
expect_true(
  !inherits(try(digikat_assert_chart_download(safe_chart_fixture), silent = TRUE), "try-error"),
  "Aggregate chart downloads must pass disclosure validation"
)
unsafe_chart_fixture <- data.frame(year = 2026L, URL = "https://example.invalid")
expect_true(
  inherits(try(digikat_assert_chart_download(unsafe_chart_fixture), silent = TRUE), "try-error"),
  "Chart downloads must reject URL-bearing columns"
)

if (length(failures)) {
  cat("FAILED", length(failures), "of", checks, "checks:\n")
  cat(paste0("- ", failures, collapse = "\n"), "\n")
  quit(save = "no", status = 1L)
}
cat("All", checks, "DigiKat regression checks passed.\n")
