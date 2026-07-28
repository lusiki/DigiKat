#!/usr/bin/env Rscript
# Generate a fully synthetic, redistributable corpus fixture.
#
# The fixture has the production schema but contains no sampled source rows,
# source URLs, actor names, titles, or post text. It is large enough for every
# year x platform stratum to produce at least one row at a 2% sampling rate.
#
# Usage:
#   Rscript R/make_sample.R

suppressPackageStartupMessages(library(dplyr))
source("R/lib/digikat_utils.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
if ("--help" %in% args) {
  cat("Usage: Rscript R/make_sample.R [--output=PATH]\n")
  quit(save = "no", status = 0L)
}

output <- digikat_cli_value(args, "--output", "data/sample/merged_sample.rds")
manifest_path <- sub("\\.rds$", "_manifest.json", output)
if (identical(manifest_path, output)) manifest_path <- paste0(output, "_manifest.json")

set.seed(20260728L)
platforms <- c(
  "web", "youtube", "facebook", "twitter", "reddit",
  "forum", "instagram", "comment", "tiktok"
)
years <- 2021:2026
rows_per_stratum <- 50L
grid <- expand.grid(
  SOURCE_TYPE = platforms,
  year = years,
  row_in_stratum = seq_len(rows_per_stratum),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
n <- nrow(grid)
row_id <- seq_len(n)

month <- ((grid$row_in_stratum - 1L) %% 12L) + 1L
day <- ((grid$row_in_stratum - 1L) %% 27L) + 1L
date <- as.Date(sprintf("%04d-%02d-%02d", grid$year, month, day))
actor_index <- ((grid$row_in_stratum - 1L) %% 12L) + 1L
actor <- sprintf("Sintetički izvor %s %02d", grid$SOURCE_TYPE, actor_index)

synthetic_sentences <- c(
  "Sintetička objava opisuje molitvu, liturgiju i djelovanje župe u potpuno izmišljenom primjeru.",
  "Ovaj umjetni tekst povezuje Caritas, solidarnost i pomoć zajednici bez preuzimanja stvarnog sadržaja.",
  "Izmišljeni primjer govori o vjeri, obrazovanju mladih i digitalnoj evangelizaciji u testnom korpusu.",
  "Sintetički zapis spominje biskupiju, svećenika i crkveno upravljanje isključivo radi provjere analitičkog toka.",
  "Umjetna objava razmatra znanost, bioetiku i društveni dijalog bez tvrdnji o stvarnim osobama ili događajima."
)
full_text <- paste(
  synthetic_sentences[((row_id - 1L) %% length(synthetic_sentences)) + 1L],
  "Sadržaj je generiran za reproducibilni test i ne predstavlja stvarnu medijsku objavu.",
  sprintf("Jedinstveni sintetički identifikator je DK-SYN-%05d.", row_id)
)

reach <- as.numeric(500L + (row_id * 137L) %% 50000L)
interactions <- as.numeric(5L + (row_id * 29L) %% 5000L)
likes <- floor(interactions * 0.60)
comments <- floor(interactions * 0.15)
shares <- interactions - likes - comments

sample <- data.frame(
  DATE = as.character(date),
  TIME = sprintf("%02d:%02d:00", row_id %% 24L, row_id %% 60L),
  TITLE = sprintf("Sintetički naslov %05d", row_id),
  FROM = actor,
  AUTHOR = sprintf("Sintetički autor %02d", actor_index),
  URL = sprintf(
    "https://example.invalid/%s/item?id=DK-SYN-%05d&utm_source=fixture",
    grid$SOURCE_TYPE,
    row_id
  ),
  URL_PHOTO = NA_character_,
  SOURCE_TYPE = grid$SOURCE_TYPE,
  GROUP_NAME = "DigiKat sintetička provjera",
  KEYWORD_NAME = "sintetički religijski upit",
  FOUND_KEYWORDS = "vjera; crkva",
  LANGUAGES = "hr",
  LOCATIONS = "Sintetička lokacija",
  TAGS = NA,
  MANUAL_SENTIMENT = NA,
  AUTO_SENTIMENT = c("positive", "neutral", "negative")[(row_id %% 3L) + 1L],
  MENTION_SNIPPET = "[SINTETIČKI ISJEČAK]",
  REACH = reach,
  VIRALITY = interactions / pmax(reach, 1),
  ENGAGEMENT_RATE = interactions / pmax(reach, 1),
  INTERACTIONS = interactions,
  FOLLOWERS_COUNT = reach * 2,
  LIKE_COUNT = as.numeric(likes),
  COMMENT_COUNT = as.numeric(comments),
  SHARE_COUNT = as.numeric(shares),
  TWEET_COUNT = NA,
  LOVE_COUNT = floor(likes * 0.10),
  WOW_COUNT = floor(likes * 0.03),
  HAHA_COUNT = floor(likes * 0.02),
  SAD_COUNT = floor(likes * 0.02),
  ANGRY_COUNT = floor(likes * 0.01),
  TOTAL_REACTIONS_COUNT = as.numeric(likes),
  FAVORITE_COUNT = as.numeric(likes),
  RETWEET_COUNT = as.numeric(shares),
  VIEW_COUNT = reach,
  DISLIKE_COUNT = 0,
  COUNT = NA,
  REPOST_COUNT = as.numeric(shares),
  REDDIT_TYPE = ifelse(grid$SOURCE_TYPE == "reddit", "synthetic", NA_character_),
  REDDIT_SCORE = ifelse(grid$SOURCE_TYPE == "reddit", interactions, NA_real_),
  INFLUENCE_SCORE = log1p(interactions),
  TWEET_TYPE = ifelse(grid$SOURCE_TYPE == "twitter", "synthetic", NA_character_),
  TWEET_SOURCE_NAME = ifelse(grid$SOURCE_TYPE == "twitter", actor, NA_character_),
  TWEET_SOURCE_URL = ifelse(
    grid$SOURCE_TYPE == "twitter",
    sprintf("https://example.invalid/twitter/source/%02d", actor_index),
    NA_character_
  ),
  FULL_TEXT = full_text,
  year = as.numeric(grid$year),
  data_source = ifelse(grid$year <= 2023, "original_dta", "filtered_religious"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

expected_schema <- c(
  "DATE", "TIME", "TITLE", "FROM", "AUTHOR", "URL", "URL_PHOTO", "SOURCE_TYPE",
  "GROUP_NAME", "KEYWORD_NAME", "FOUND_KEYWORDS", "LANGUAGES", "LOCATIONS", "TAGS",
  "MANUAL_SENTIMENT", "AUTO_SENTIMENT", "MENTION_SNIPPET", "REACH", "VIRALITY",
  "ENGAGEMENT_RATE", "INTERACTIONS", "FOLLOWERS_COUNT", "LIKE_COUNT", "COMMENT_COUNT",
  "SHARE_COUNT", "TWEET_COUNT", "LOVE_COUNT", "WOW_COUNT", "HAHA_COUNT", "SAD_COUNT",
  "ANGRY_COUNT", "TOTAL_REACTIONS_COUNT", "FAVORITE_COUNT", "RETWEET_COUNT",
  "VIEW_COUNT", "DISLIKE_COUNT", "COUNT", "REPOST_COUNT", "REDDIT_TYPE", "REDDIT_SCORE",
  "INFLUENCE_SCORE", "TWEET_TYPE", "TWEET_SOURCE_NAME", "TWEET_SOURCE_URL", "FULL_TEXT",
  "year", "data_source"
)
if (!identical(names(sample), expected_schema)) stop("Synthetic fixture schema drifted.", call. = FALSE)
if (anyDuplicated(sample$URL)) stop("Synthetic fixture URLs must be unique.", call. = FALSE)
if (nrow(sample) != length(platforms) * length(years) * rows_per_stratum) {
  stop("Synthetic fixture row count is incorrect.", call. = FALSE)
}

dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
saveRDS(sample, output)
round_trip <- readRDS(output)
if (!identical(names(round_trip), expected_schema) || nrow(round_trip) != nrow(sample)) {
  stop("Synthetic fixture round-trip validation failed.", call. = FALSE)
}

manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "R/make_sample.R",
  synthetic = TRUE,
  contains_source_rows = FALSE,
  contains_source_text = FALSE,
  rows = nrow(sample),
  columns = ncol(sample),
  rows_per_year_platform_stratum = rows_per_stratum,
  year_min = min(sample$year),
  year_max = max(sample$year),
  source_types = as.list(platforms),
  sha256 = digikat_hash_file(output)
)
digikat_write_json_atomic(manifest, manifest_path)

cat("Wrote synthetic fixture:", output, "\n")
cat("  Rows:", nrow(sample), "| columns:", ncol(sample), "| SHA-256:", manifest$sha256, "\n")
cat("  Contains no rows, URLs, actor names, titles, or post text from the protected corpus.\n")
