#!/usr/bin/env Rscript
# Stage 2 — the reading layers: what the year talked about, and in what tone.
#
# The three stratified NLP samples were drawn from the accumulator before the corpus was cut, so
# they mix corpus and non-corpus rows. Every document is therefore matched back to the corpus on URL
# and everything outside the corpus is dropped. Because corpus membership is a deterministic
# property of a row and the draw was random within year x platform, what remains is still a random
# sample of the corpus in each stratum — at a lower rate, which this script measures and records.
#
# udpipe is NOT re-run. The existing tokens are reused; only the document set changes.

suppressPackageStartupMessages({
  library(here); library(dplyr); library(tidyr); library(stringr); library(purrr)
  library(tibble); library(jsonlite)
})
source(here::here("studies", "annual-report", "report_lib.R"), encoding = "UTF-8")
source(here::here("R", "lib", "thematic_dictionaries.R"), encoding = "UTF-8")
source(here::here("R", "lib", "page_summaries.R"), encoding = "UTF-8")
ar_readiness_ok()

say <- function(...) { cat(format(Sys.time(), "%H:%M:%S"), "|", ..., "\n"); flush.console() }
YEAR <- AR_REPORT_YEAR
cm <- digikat_read_corpus_manifest(here::here("data", "digikat_corpus_manifest.json"))

## --- Corpus membership key -----------------------------------------------------------------------
say("reading corpus keys")
corpus <- readRDS(here::here(cm$corpus$path))
corpus_keys <- data.frame(
  URL = as.character(corpus$URL),
  DATE = as.Date(corpus$DATE),
  source_key = sub("^www[.]", "", tolower(trimws(as.character(corpus$FROM)))),
  stringsAsFactors = FALSE
)
rm(corpus); invisible(gc())
member_urls <- unique(corpus_keys$URL)
corpus_year_rows <- sum(format(corpus_keys$DATE, "%Y") == as.character(YEAR))

restrict <- function(sample, label) {
  sample$DATE <- as.Date(sample$DATE)
  sample$year <- as.integer(format(sample$DATE, "%Y"))
  in_corpus <- as.character(sample$URL) %in% member_urls
  out <- sample[in_corpus & sample$year == YEAR, , drop = FALSE]
  stats <- data.frame(
    layer = label,
    sample_rows = nrow(sample),
    sample_rows_year = sum(sample$year == YEAR),
    in_corpus_rows_year = nrow(out),
    membership_rate = mean(in_corpus[sample$year == YEAR]),
    corpus_year_rows = corpus_year_rows,
    effective_rate = nrow(out) / corpus_year_rows,
    stringsAsFactors = FALSE
  )
  list(sample = out, stats = stats)
}

## --- Theme layer ----------------------------------------------------------------------------------
say("theme layer: reading the 5 % sample")
mapa <- readRDS(here::here("data", "nlp", "mapa_stats_sample.rds"))
mapa_r <- restrict(mapa, "teme")
rm(mapa); invisible(gc())
say("theme documents in the corpus for", YEAR, ":", ar_fmt_int_hr(nrow(mapa_r$sample)))

say("scoring the frozen 16-category dictionary")
themes_raw <- digikat_enrich_themes(mapa_r$sample, digikat_thematic_dictionaries)
topic_keys <- names(digikat_thematic_dictionaries)

mentions <- vapply(topic_keys, function(k) sum(as.numeric(themes_raw[[k]]), na.rm = TRUE), numeric(1))
dominant <- table(factor(themes_raw$dominant_topic, levels = c(topic_keys, "Nema Teme")))
n_docs <- nrow(themes_raw)

themes <- data.frame(
  topic = topic_keys,
  topic_hr = unname(ar_topic_hr[topic_keys]),
  mentions = as.numeric(mentions),
  docs_dominant = as.integer(dominant[topic_keys]),
  stringsAsFactors = FALSE
)
themes$share_of_mentions <- themes$mentions / sum(themes$mentions)
themes$share_of_docs <- themes$docs_dominant / n_docs
wil <- t(vapply(themes$docs_dominant, function(k) ar_wilson(k, n_docs), numeric(2)))
themes$docs_ci_lower <- wil[, 1]
themes$docs_ci_upper <- wil[, 2]
themes <- themes[order(-themes$mentions), ]
themes$rank <- seq_len(nrow(themes))
ar_write_csv(themes, file.path(AR_OUT, "themes.csv"))

no_theme <- data.frame(
  docs_scored = n_docs,
  docs_without_theme = as.integer(dominant[["Nema Teme"]]),
  share_without_theme = as.numeric(dominant[["Nema Teme"]]) / n_docs,
  total_mentions = sum(themes$mentions),
  mentions_per_doc = sum(themes$mentions) / n_docs,
  stringsAsFactors = FALSE
)
ar_write_csv(no_theme, file.path(AR_OUT, "themes_coverage.csv"))

# The theme signature of the year's attention arcs: what were the peak days actually about?
arcs <- ar_out_csv("event_arcs.csv")
signature <- do.call(rbind, lapply(seq_len(nrow(arcs)), function(i) {
  win <- themes_raw[themes_raw$DATE >= as.Date(arcs$start[i]) & themes_raw$DATE <= as.Date(arcs$end[i]), ]
  if (!nrow(win)) return(NULL)
  tab <- sort(table(win$dominant_topic), decreasing = TRUE)
  tab <- tab[names(tab) != "Nema Teme"]
  top <- head(names(tab), 3L)
  data.frame(arc = arcs$arc[i], start = arcs$start[i], end = arcs$end[i],
             docs = nrow(win),
             topic = top,
             topic_hr = unname(ar_topic_hr[top]),
             docs_topic = as.integer(tab[top]),
             share = as.numeric(tab[top]) / nrow(win),
             stringsAsFactors = FALSE)
}))
ar_write_csv(signature, file.path(AR_OUT, "event_signature.csv"))
rm(themes_raw); invisible(gc())

## --- Tone layer -------------------------------------------------------------------------------------
say("tone layer: reading the 2 % sample and its tokens")
disk <- readRDS(here::here("data", "nlp", "diskurs_sample.rds"))
disk_r <- restrict(disk, "ton")
rm(disk); invisible(gc())
say("tone documents in the corpus for", YEAR, ":", ar_fmt_int_hr(nrow(disk_r$sample)))

tokens <- readRDS(here::here("data", "nlp", "diskurs_tokens.rds"))
tokens <- tokens[tokens$doc_id %in% disk_r$sample$doc_id, , drop = FALSE]
say("tokens retained:", ar_fmt_int_hr(nrow(tokens)))

say("loading sentiment and emotion lexicons")
lexicons <- digikat_load_atmosphere_lexicons(root = here::here())
atmos <- digikat_document_atmosphere(disk_r$sample, tokens, digikat_thematic_dictionaries, lexicons)
docs <- atmos$final
rm(tokens); invisible(gc())

mean_ci <- function(x) {
  x <- x[!is.na(x)]
  n <- length(x)
  if (n < 2L) return(c(mean = if (n) mean(x) else NA_real_, lower = NA_real_, upper = NA_real_, n = n))
  se <- stats::sd(x) / sqrt(n)
  c(mean = mean(x), lower = mean(x) - 1.96 * se, upper = mean(x) + 1.96 * se, n = n)
}

overall <- as.data.frame(t(mean_ci(docs$sentiment_score)))
names(overall) <- c("sentiment_mean", "sentiment_lower", "sentiment_upper", "n")
cli_overall <- mean_ci(docs$cli)
overall$cli_mean <- cli_overall[["mean"]]
overall$cli_lower <- cli_overall[["lower"]]
overall$cli_upper <- cli_overall[["upper"]]
overall$share_negative <- mean(docs$sentiment_score < 0)
overall$share_positive <- mean(docs$sentiment_score > 0)
overall$share_neutral <- mean(docs$sentiment_score == 0)
ar_write_csv(overall, file.path(AR_OUT, "tone_overall.csv"))

MIN_CELL <- 30L
tone_topic <- docs |>
  filter(dominant_topic != "Nema Teme") |>
  group_by(dominant_topic) |>
  summarise(n_docs = n(),
            sentiment_mean = mean(sentiment_score),
            sentiment_sd = stats::sd(sentiment_score),
            cli_mean = mean(cli),
            .groups = "drop") |>
  mutate(sentiment_lower = sentiment_mean - 1.96 * sentiment_sd / sqrt(n_docs),
         sentiment_upper = sentiment_mean + 1.96 * sentiment_sd / sqrt(n_docs),
         topic_hr = unname(ar_topic_hr[dominant_topic]),
         reportable = n_docs >= MIN_CELL) |>
  arrange(desc(n_docs)) |>
  as.data.frame()
ar_write_csv(tone_topic, file.path(AR_OUT, "tone_by_theme.csv"))

# Does the recorded tone differ between confessional and secular outlets? The label sidecar is
# proposed, so this is reported as indicative, with its own document counts.
docs$source_key <- sub("^www[.]", "", tolower(trimws(as.character(docs$FROM))))
labels <- read.csv(here::here("resources", "dictionaries", "source_labels.csv"),
                   fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE, colClasses = "character")
labels$key <- sub("^www[.]", "", tolower(trimws(labels$from)))
docs$label <- labels$label[match(docs$source_key, labels$key)]
docs$label[is.na(docs$label) | !docs$label %in% c("confessional", "secular")] <- "unclassified"
tone_label <- docs |>
  group_by(label) |>
  summarise(n_docs = n(),
            sentiment_mean = mean(sentiment_score),
            sentiment_sd = stats::sd(sentiment_score),
            cli_mean = mean(cli),
            cli_sd = stats::sd(cli),
            .groups = "drop") |>
  mutate(sentiment_lower = sentiment_mean - 1.96 * sentiment_sd / sqrt(n_docs),
         sentiment_upper = sentiment_mean + 1.96 * sentiment_sd / sqrt(n_docs),
         cli_lower = cli_mean - 1.96 * cli_sd / sqrt(n_docs),
         cli_upper = cli_mean + 1.96 * cli_sd / sqrt(n_docs),
         label_hr = c(confessional = "Konfesionalni izvori", secular = "Sekularni izvori",
                      unclassified = "Neoznačeni izvori")[label]) |>
  as.data.frame()
ar_write_csv(tone_label, file.path(AR_OUT, "tone_by_label.csv"))

emotions <- docs |>
  count(dominant_emotion, name = "docs") |>
  mutate(share = docs / sum(docs)) |>
  arrange(desc(docs)) |>
  as.data.frame()
ar_write_csv(emotions, file.path(AR_OUT, "tone_emotions.csv"))

## --- Coverage record --------------------------------------------------------------------------------
coverage <- rbind(mapa_r$stats, disk_r$stats)
ar_write_csv(coverage, file.path(AR_OUT, "nlp_coverage.csv"))

say("NLP layers complete")
print(coverage[, c("layer", "sample_rows_year", "in_corpus_rows_year", "membership_rate", "effective_rate")],
      row.names = FALSE)
cat("  documents without any dictionary theme:", ar_fmt_pct_hr(100 * no_theme$share_without_theme), "\n")
cat("  leading category by mentions          :", themes$topic_hr[1], ar_fmt_pct_hr(100 * themes$share_of_mentions[1]), "\n")
cat("  overall sentiment                     :", ar_fmt_num_hr(overall$sentiment_mean, 3), "\n")
cat("  conflict language index (per 1 000)   :", ar_fmt_num_hr(overall$cli_mean, 1), "\n")
