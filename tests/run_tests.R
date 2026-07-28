#!/usr/bin/env Rscript
# Dependency-light regression tests for the safety-critical DigiKat helpers.

source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/thematic_dictionaries.R", encoding = "UTF-8")

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

if (length(failures)) {
  cat("FAILED", length(failures), "of", checks, "checks:\n")
  cat(paste0("- ", failures, collapse = "\n"), "\n")
  quit(save = "no", status = 1L)
}
cat("All", checks, "DigiKat regression checks passed.\n")
