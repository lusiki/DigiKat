#!/usr/bin/env Rscript
# Gate 0 — is the machine and the data in a state that can produce this edition?
#
# Fails CLOSED on anything that would let the report print current corpus figures over aggregates
# built from a different dataset.

suppressPackageStartupMessages({ library(here); library(jsonlite) })
source(here::here("studies", "annual-report", "report_lib.R"), encoding = "UTF-8")

results <- list()
record <- function(check, status, detail) {
  status <- toupper(status)
  if (!status %in% c("PASS", "WARN", "FAIL")) stop("Unknown readiness status: ", status)
  results[[length(results) + 1L]] <<- data.frame(
    check = check, status = status, detail = as.character(detail), stringsAsFactors = FALSE
  )
  cat(sprintf("[%s] %-34s %s\n", status, check, detail))
}

## --- Tooling -----------------------------------------------------------------------------------
required_packages <- c("here", "jsonlite", "digest", "dplyr", "tidyr", "stringr", "purrr",
                       "tibble", "readxl", "ggplot2", "scales")
for (pkg in required_packages) {
  have <- requireNamespace(pkg, quietly = TRUE)
  record(paste0("package_", pkg), if (have) "PASS" else "FAIL", if (have) "available" else "missing")
}
record("renv_scoped_waiver", "WARN",
       "project misses lmtest and sandwich; the annual-report chain imports neither")

## --- The corpus is the dataset this edition describes -------------------------------------------
corpus_manifest_path <- here::here("data", "digikat_corpus_manifest.json")
processed_manifest_path <- here::here("data", "processed", "manifest.json")
nlp_manifest_path <- here::here("data", "nlp", "manifest.json")

record("corpus_manifest_exists", if (file.exists(corpus_manifest_path)) "PASS" else "FAIL",
       "data/digikat_corpus_manifest.json")
cm <- fromJSON(corpus_manifest_path, simplifyVector = TRUE)

corpus_path <- here::here(cm$corpus$path)
record("corpus_present", if (file.exists(corpus_path)) "PASS" else "FAIL", cm$corpus$path)
corpus_hash <- if (file.exists(corpus_path)) ar_sha256(corpus_path) else NA_character_
record("corpus_hash_matches_manifest",
       if (identical(corpus_hash, cm$corpus$sha256)) "PASS" else "FAIL",
       sprintf("%s rows; %s", ar_fmt_int_hr(cm$corpus$rows), substr(cm$corpus$sha256, 1, 12)))
record("corpus_rule", "PASS",
       sprintf("%s terms, threshold %.2f, window fix %s", cm$rule$terms_count, cm$rule$threshold,
               if (isTRUE(cm$rule$window_fix)) "on" else "off"))

pm <- fromJSON(processed_manifest_path, simplifyVector = FALSE)
current <- digikat_assert_aggregates_current(
  aggregate_manifest = processed_manifest_path,
  corpus_manifest = corpus_manifest_path,
  strict = FALSE
)
record("processed_built_from_corpus", if (isTRUE(current)) "PASS" else "FAIL",
       if (isTRUE(current)) "data/processed/ carries the corpus sha256" else attr(current, "reason"))

for (nm in names(pm$outputs)) {
  meta <- pm$outputs[[nm]]
  path <- here::here("data", "processed", meta$file)
  if (!file.exists(path)) {
    record(paste0("processed_", nm), "FAIL", "file missing")
  } else {
    match_ok <- identical(ar_sha256(path), meta$sha256)
    record(paste0("processed_", nm), if (match_ok) "PASS" else "FAIL",
           if (match_ok) paste(meta$rows, "rows; hash matches") else "hash mismatch")
  }
}

## --- Schemas the report depends on --------------------------------------------------------------
platform <- readRDS(here::here("data", "processed", "platform_summary.rds"))
monthly <- readRDS(here::here("data", "processed", "platform_monthly.rds"))
sources <- readRDS(here::here("data", "processed", "source_summary.rds"))
schema_ok <- function(x, need) all(need %in% names(x))
record("platform_schema",
       if (schema_ok(platform, c("year", "SOURCE_TYPE", "total_posts", "total_interactions", "total_reach"))) "PASS" else "FAIL",
       paste(names(platform), collapse = ", "))
record("monthly_schema",
       if (schema_ok(monthly, c("month", "SOURCE_TYPE", "total_posts"))) "PASS" else "FAIL",
       paste(names(monthly), collapse = ", "))
record("source_schema",
       if (schema_ok(sources, c("year", "FROM", "productivity", "total_interactions", "total_reach"))) "PASS" else "FAIL",
       paste(names(sources), collapse = ", "))

included <- as.numeric(pm$corpus$included_rows)
record("platform_reconciliation", if (sum(platform$total_posts) == included) "PASS" else "FAIL",
       paste(ar_fmt_int_hr(sum(platform$total_posts)), "of", ar_fmt_int_hr(included), "rows"))

p_year <- platform[platform$year == AR_REPORT_YEAR, ]
m_year <- monthly[format(as.Date(monthly$month), "%Y") == as.character(AR_REPORT_YEAR), ]
record("report_year_present", if (nrow(p_year) > 0L && nrow(m_year) > 0L) "PASS" else "FAIL",
       sprintf("platform=%d monthly=%d rows", nrow(p_year), nrow(m_year)))
# A month with no row is a collection fact about the year, not a broken build: 2024 carries data in
# eight of twelve months. Stage 01 measures the interruption day by day and the report discloses it,
# so this gate records what the calendar holds instead of refusing to describe an interrupted year.
months_present <- length(unique(format(as.Date(m_year$month), "%Y-%m")))
record("report_year_months", if (months_present == 12L) "PASS" else "WARN",
       if (months_present == 12L) "12 months" else
         sprintf("%d of 12 months carry data; stage 01 measures the interruption", months_present))
record("report_year_closed",
       if (as.Date(cm$corpus$date_max) > as.Date(sprintf("%d-12-31", AR_REPORT_YEAR))) "PASS" else "FAIL",
       paste("corpus runs to", cm$corpus$date_max, "- the reporting year is complete"))
record("latest_year_partial", "WARN",
       sprintf("%s ends on %s and is not an annual result", cm$corpus$year_max, cm$corpus$date_max))

## --- The 2024 seam ------------------------------------------------------------------------------
record("collection_seam", "WARN",
       paste("one inclusion rule, two collection eras; kept share steps at the 2024 break, so only",
             "within-stream comparison is instrument-comparable"))
record("stream_dimension_available",
       if (!is.null(cm$eras$post2024$span)) "PASS" else "FAIL",
       paste("post-2024 stream spans", cm$eras$post2024$span))

## --- NLP layers: reused tokens, corpus-restricted ------------------------------------------------
record("nlp_manifest_exists", if (file.exists(nlp_manifest_path)) "PASS" else "FAIL", "data/nlp/manifest.json")
nlp <- fromJSON(nlp_manifest_path, simplifyVector = FALSE)
nlp_from_corpus <- identical(nlp$inputs$master$sha256, cm$corpus$sha256)
record("nlp_generation_source", if (nlp_from_corpus) "PASS" else "WARN",
       if (nlp_from_corpus) "tokens were drawn from the corpus"
       else paste("tokens were drawn from the accumulator; the report restricts every NLP layer to",
                  "corpus members and reports the restricted sample size"))
nlp_files <- unlist(lapply(c("mapa_stats", "diskurs"),
                           function(p) file.path(here::here("data", "nlp"),
                                                 paste0(p, c("_sample.rds", "_tokens.rds")))))
record("nlp_inputs_present", if (all(file.exists(nlp_files))) "PASS" else "FAIL",
       paste(sum(file.exists(nlp_files)), "of", length(nlp_files), "sample/token files"))
record("nlp_sampling_design", "WARN",
       sprintf("year x platform stratified: themes %.0f%%, tone %.0f%%; excludes %s; minimum %d characters",
               100 * nlp$parameters$page_proportions$mapa_stats,
               100 * nlp$parameters$page_proportions$diskurs,
               paste(unlist(nlp$parameters$excluded_source_types), collapse = ", "),
               nlp$parameters$minimum_text_characters))

lexicon_paths <- c(
  here::here("resources", "lexicons", "crosentilex-negatives.txt"),
  here::here("resources", "lexicons", "crosentilex-positives.txt"),
  here::here("resources", "lexicons", "gs-sentiment-annotations.txt"),
  here::here("resources", "dictionaries", "lilaHR_clean.xlsx")
)
record("lexicons_present", if (all(file.exists(lexicon_paths))) "PASS" else "FAIL",
       paste(sum(file.exists(lexicon_paths)), "of", length(lexicon_paths), "lexicon files"))

## --- Editorial label sidecar --------------------------------------------------------------------
labels_path <- here::here("resources", "dictionaries", "source_labels.csv")
labels <- read.csv(labels_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE, colClasses = "character")
record("label_schema",
       if (all(c("from", "entity", "kind", "label", "publish", "status") %in% names(labels))) "PASS" else "FAIL",
       paste(nrow(labels), "sidecar rows"))
record("label_status", "WARN",
       paste("sidecar status:", paste(unique(labels$status), collapse = ", "),
             "- composition figures stay indicative"))

## --- Verdict -------------------------------------------------------------------------------------
readiness <- do.call(rbind, results)
ar_write_csv(readiness, file.path(AR_OUT, "readiness.csv"))

readiness_manifest <- list(
  schema_version = 2L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  reporting_year = AR_REPORT_YEAR,
  dataset = list(
    name = "digikat_corpus",
    path = cm$corpus$path,
    rows = cm$corpus$rows,
    sha256 = cm$corpus$sha256,
    date_min = cm$corpus$date_min,
    date_max = cm$corpus$date_max,
    rule = cm$rule$description,
    threshold = cm$rule$threshold,
    terms_count = cm$rule$terms_count
  ),
  accumulator_opened = FALSE,
  upstream = list(
    corpus_manifest = list(path = "data/digikat_corpus_manifest.json", sha256 = ar_sha256(corpus_manifest_path)),
    processed_manifest = list(path = "data/processed/manifest.json", sha256 = ar_sha256(processed_manifest_path)),
    nlp_manifest = list(path = "data/nlp/manifest.json", sha256 = ar_sha256(nlp_manifest_path)),
    source_labels = list(path = "resources/dictionaries/source_labels.csv", sha256 = ar_sha256(labels_path))
  ),
  nlp_sampling = list(
    generation_source = if (nlp_from_corpus) "corpus" else "accumulator_restricted_to_corpus",
    strata = unlist(nlp$parameters$strata),
    theme_proportion = nlp$parameters$page_proportions$mapa_stats,
    tone_proportion = nlp$parameters$page_proportions$diskurs,
    excluded_source_types = unlist(nlp$parameters$excluded_source_types),
    minimum_text_characters = nlp$parameters$minimum_text_characters
  ),
  verdict = if (any(readiness$status == "FAIL")) "FAIL" else "READY_WITH_WARNINGS"
)
write_json(readiness_manifest, file.path(AR_OUT, "readiness_manifest.json"),
           pretty = TRUE, auto_unbox = TRUE, na = "null")

cat(sprintf("\nReadiness: %s (%d PASS, %d WARN, %d FAIL)\n", readiness_manifest$verdict,
            sum(readiness$status == "PASS"), sum(readiness$status == "WARN"),
            sum(readiness$status == "FAIL")))
if (any(readiness$status == "FAIL")) stop("Annual-report readiness failed.", call. = FALSE)
