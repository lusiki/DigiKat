#!/usr/bin/env Rscript
# Build the "Riječi u tekstovima o Alojziju Stepincu" input for pages/mapa/događaji.qmd.
#
# The page's event sample (3 % of the corpus) holds only one to three texts per year that
# mention Stepinac, which is too few to say anything about a year's vocabulary. This step
# draws the Stepinac texts from the whole official corpus instead: at most PER_YEAR_CAP per
# year, chosen at random with a fixed seed, lemmatized with the project's udpipe model and
# scored with the same tone method as the other map pages. A year is published only when it
# has at least MIN_TEXTS texts.
#
# Output is aggregate only (year, word, count, mean tone, texts per year). No text, title,
# URL or source leaves this script.
#
#   Rscript R/07_stepinac_terms.R            # preview: build and print, write nothing
#   Rscript R/07_stepinac_terms.R --apply    # install data/page-ready/stepinac_terms.rds
#
# Run from the repo root after the corpus changes. Takes a few minutes.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
})
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/digikat_paths.R", encoding = "UTF-8")
source("R/lib/digikat_hr.R", encoding = "UTF-8")
source("R/lib/thematic_dictionaries.R", encoding = "UTF-8")
source("R/lib/page_summaries.R", encoding = "UTF-8")

args <- commandArgs(trailingOnly = TRUE)
apply_output <- digikat_cli_flag(args, "--apply")

SEED <- 123L
PER_YEAR_CAP <- 60L
MIN_TEXTS <- 20L
TOP_WORDS <- 12L
# Stepinac, Stepinca, Stepincu, Stepincem and the adjective Stepinčev/-a/-o.
PATTERN <- "(?i)\\bstepin(ac|c|č)"
OUTPUT <- "data/page-ready/stepinac_terms.rds"
MODEL <- "resources/models/croatian-set-ud-2.5-191206.udpipe"

corpus_path <- digikat_corpus_path()
manifest <- jsonlite::read_json("data/digikat_corpus_manifest.json", simplifyVector = TRUE)
if (!file.exists(corpus_path)) stop("Corpus not found: ", corpus_path, call. = FALSE)
if (!file.exists(MODEL)) stop("UDPIPE model not found: ", MODEL, call. = FALSE)

cat("Reading corpus...\n")
corpus <- readRDS(corpus_path)
digikat_require_columns(corpus, c("DATE", "SOURCE_TYPE", "FULL_TEXT", "FROM"), "corpus")
corpus_sha <- digikat_hash_file(corpus_path)
if (!identical(corpus_sha, manifest$corpus$sha256)) {
  stop("Corpus file does not match data/digikat_corpus_manifest.json.", call. = FALSE)
}

# Same eligibility as R/04_nlp.R, so the texts are comparable with the rest of the page.
mentions <- corpus |>
  as.data.frame() |>
  select(DATE, SOURCE_TYPE, FROM, FULL_TEXT) |>
  mutate(DATE = digikat_parse_date(DATE, name = "corpus DATE", allow_missing = FALSE)) |>
  filter(
    !is.na(SOURCE_TYPE), SOURCE_TYPE != "tiktok",
    !is.na(FULL_TEXT), nchar(FULL_TEXT) > 100,
    stringi::stri_detect_regex(FULL_TEXT, PATTERN)
  ) |>
  mutate(year = as.integer(format(DATE, "%Y")))
rm(corpus)
invisible(gc())

mentions_per_year <- count(mentions, year, name = "n_mentions")
cat("Corpus texts mentioning Stepinac, by year:\n")
print(as.data.frame(mentions_per_year), row.names = FALSE)

set.seed(SEED)
sample <- mentions |>
  group_by(year) |>
  slice_sample(n = PER_YEAR_CAP) |>
  ungroup() |>
  arrange(year, DATE) |>
  mutate(doc_id = row_number())

cat(sprintf("Annotating %d texts...\n", nrow(sample)))
model <- udpipe::udpipe_load_model(MODEL)
tokens <- udpipe::udpipe_annotate(
  model,
  x = sample$FULL_TEXT,
  doc_id = as.character(sample$doc_id),
  tagger = "default",
  parser = "none"
) |>
  as.data.frame() |>
  transmute(doc_id = as.integer(doc_id), token, lemma, upos)

lexicons <- digikat_load_atmosphere_lexicons(".")
atmosphere <- digikat_document_atmosphere(sample, tokens, digikat_thematic_dictionaries, lexicons)

texts_per_year <- atmosphere$final |>
  count(year, name = "n_texts") |>
  left_join(mentions_per_year, by = "year") |>
  mutate(published = n_texts >= MIN_TEXTS)

# Nouns and adjectives only, words only (hashtags, dates and numbers are tokenizer residue),
# without the generic lemmas every Croatian frequency list is topped by. Words are ranked by
# how many texts use them, so one long programme or timetable cannot top a year by itself.
terms <- atmosphere$tokens |>
  filter(upos %in% c("NOUN", "ADJ"), lemma != "stepinac") |>
  mutate(lemma = stringi::stri_trans_tolower(lemma)) |>
  filter(!digikat_is_generic_lemma(lemma), nchar(lemma) > 2L) |>
  inner_join(atmosphere$final |> select(doc_id, year, sentiment_score), by = "doc_id") |>
  group_by(year, lemma) |>
  summarise(
    total_cooccurrences = n(),
    n_docs = n_distinct(doc_id),
    avg_sentiment = mean(sentiment_score, na.rm = TRUE),
    .groups = "drop"
  ) |>
  semi_join(filter(texts_per_year, published), by = "year") |>
  group_by(year) |>
  arrange(desc(n_docs), desc(total_cooccurrences), lemma, .by_group = TRUE) |>
  slice_head(n = TOP_WORDS) |>
  ungroup()

year_tone <- atmosphere$final |>
  group_by(year) |>
  summarise(avg_sentiment = mean(sentiment_score, na.rm = TRUE), .groups = "drop")
texts_per_year <- left_join(texts_per_year, year_tone, by = "year")

cat("\nTexts per year (published when n_texts >= ", MIN_TEXTS, "):\n", sep = "")
print(as.data.frame(texts_per_year), row.names = FALSE)
cat("\nTop words per published year:\n")
print(as.data.frame(terms), row.names = FALSE)

result <- list(
  schema_version = 1L,
  page = "stepinac_terms",
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "R/07_stepinac_terms.R",
  corpus_sha256 = corpus_sha,
  disclosure = "aggregate word counts only; no text, title, URL, or source",
  parameters = list(
    seed = SEED, per_year_cap = PER_YEAR_CAP, min_texts = MIN_TEXTS,
    top_words = TOP_WORDS, pattern = PATTERN
  ),
  texts_per_year = texts_per_year,
  terms = terms
)

stopifnot(
  nrow(terms) > 0L,
  !any(c("FULL_TEXT", "URL", "FROM", "TITLE") %in% c(names(terms), names(texts_per_year)))
)

if (!apply_output) {
  cat("\nPreview only. Re-run with --apply to install", OUTPUT, "\n")
  quit(save = "no", status = 0L)
}

staged <- paste0(OUTPUT, ".tmp-", Sys.getpid())
saveRDS(result, staged, compress = TRUE)
check <- readRDS(staged)
if (!identical(check$corpus_sha256, corpus_sha) || !nrow(check$terms)) {
  unlink(staged)
  stop("Staged Stepinac summary failed validation.", call. = FALSE)
}
if (!file.rename(staged, OUTPUT)) stop("Could not install ", OUTPUT, call. = FALSE)
cat("Installed", OUTPUT, "\n")
