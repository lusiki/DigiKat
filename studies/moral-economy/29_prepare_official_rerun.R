#!/usr/bin/env Rscript
# moral-economy — build the official-corpus inputs for the refreshed RSP analysis.
#
# The official corpus is an exact row subset of the accumulator and carries the original row number
# in `dk_master_row`. Stage A is row-independent: restricting its old (rid, domain) results to those
# stable IDs is exactly equivalent to re-running its regexes on the subset, while avoiding a multi-hour
# pass. The old prepared corpus is restricted in the same way so its doc_id remains compatible with the
# existing semantic store. Every identity claim is checked below before anything is installed.
#
# Reads protected data read-only. Writes only ignored study derivatives plus aggregate manifests.
#   Rscript studies/moral-economy/29_prepare_official_rerun.R
suppressPackageStartupMessages({ library(here) })
source(here::here("R/lib/digikat_utils.R"))
source(here::here("R/lib/digikat_paths.R"))
source(here::here("studies/moral-economy/rsp_input.R"))
source(here::here("studies/moral-economy/lexicon.R"))

OFFICIAL <- here::here(digikat_corpus_path())
LEGACY_PREP <- here::here("data/semantic/corpus_prepared.rds")
LEGACY_CAND <- here::here("studies/moral-economy/output/stageA_candidates.rds")
SOURCE_LABELS <- here::here("resources/dictionaries/source_labels.csv")

for (p in c(OFFICIAL, LEGACY_PREP, LEGACY_CAND, SOURCE_LABELS)) {
  if (!file.exists(p)) stop("Required input is missing: ", p, call. = FALSE)
}

mf <- digikat_read_corpus_manifest()
cat("=== official-corpus bridge for the RSP paper ===\n")
cat("reading official corpus...\n")
official <- readRDS(OFFICIAL)
digikat_require_columns(official,
  c("dk_master_row", "URL", "DATE", "FULL_TEXT", "TITLE", "FROM", "SOURCE_TYPE", "data_source"),
  "official corpus")
ids <- as.integer(official$dk_master_row)
if (nrow(official) != as.integer(mf$corpus$rows) || ncol(official) != as.integer(mf$corpus$columns)) {
  stop("Official corpus dimensions disagree with its manifest.", call. = FALSE)
}
if (anyNA(ids) || anyDuplicated(ids) || any(ids < 1L)) {
  stop("dk_master_row is not a complete unique positive stable key.", call. = FALSE)
}

actual_sha <- digikat_hash_file(OFFICIAL)
if (!identical(actual_sha, as.character(mf$corpus$sha256))) {
  stop("Official corpus SHA-256 disagrees with its manifest.", call. = FALSE)
}
cat(sprintf("  %s rows; SHA-256 %s... verified\n",
            digikat_format_integer(nrow(official)), substr(actual_sha, 1, 12)))

cat("reading accumulator-keyed prepared corpus...\n")
prepared <- readRDS(LEGACY_PREP)
digikat_require_columns(prepared, c("doc_id", "date", "url", "text", "data_source", "platform", "actor"),
                        "legacy corpus_prepared")
prepared_ids <- suppressWarnings(as.integer(sub("^dk_", "", prepared$doc_id)))
if (anyNA(prepared_ids) || anyDuplicated(prepared_ids)) {
  stop("Legacy prepared corpus has an invalid doc_id key.", call. = FALSE)
}
i <- match(ids, prepared_ids)
if (anyNA(i)) stop("An official dk_master_row is absent from corpus_prepared.rds.", call. = FALSE)

eq_na <- function(a, b) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & as.character(a) == as.character(b))
url_ok <- eq_na(prepared$url[i], official$URL)
date_ok <- eq_na(as.Date(prepared$date[i]), as.Date(substr(official$DATE, 1, 10)))
text_ok <- eq_na(prepared$text[i], trimws(as.character(official$FULL_TEXT)))
platform_ok <- eq_na(prepared$platform[i], official$SOURCE_TYPE)
stream_ok <- eq_na(prepared$data_source[i], official$data_source)
actor_ok <- eq_na(prepared$actor[i], official$FROM)
if (!all(url_ok) || !all(date_ok) || !all(text_ok) || !all(platform_ok) ||
    !all(stream_ok) || !all(actor_ok)) {
  stop(sprintf(paste("Stable-key identity failed: URL %d/%d, DATE %d/%d, FULL_TEXT %d/%d,",
                     "SOURCE_TYPE %d/%d, data_source %d/%d, FROM %d/%d."),
               sum(url_ok), length(url_ok), sum(date_ok), length(date_ok), sum(text_ok), length(text_ok),
               sum(platform_ok), length(platform_ok), sum(stream_ok), length(stream_ok),
               sum(actor_ok), length(actor_ok)),
       call. = FALSE)
}
cat(sprintf(paste("  stable-key identity: URL %d/%d, DATE %d/%d, FULL_TEXT %d/%d,",
                  "SOURCE_TYPE %d/%d, data_source %d/%d, FROM %d/%d exact\n"),
            sum(url_ok), length(url_ok), sum(date_ok), length(date_ok), sum(text_ok), length(text_ok),
            sum(platform_ok), length(platform_ok), sum(stream_ok), length(stream_ok),
            sum(actor_ok), length(actor_ok)))

prepared_official <- prepared[i, , drop = FALSE]
attr(prepared_official, "official_corpus_sha256") <- actual_sha
attr(prepared_official, "stable_id") <- "dk_master_row -> accumulator-keyed doc_id"
stage <- digikat_stage_rds(prepared_official, RSP_CORPUS_PREPARED,
  validate = function(x) {
    stopifnot(nrow(x) == nrow(official), identical(x$doc_id, prepared_official$doc_id))
    invisible(TRUE)
  })
digikat_atomic_replace_file(stage, RSP_CORPUS_PREPARED)
rm(prepared, prepared_official); invisible(gc())

cat("restricting row-independent Stage-A results...\n")
cand_old <- readRDS(LEGACY_CAND)
digikat_require_columns(cand_old,
  c("rid", "domain", "URL", "DATE", "window", "FROM", "SOURCE_TYPE", "stream", "TITLE", "label"),
  "legacy Stage A")
cand_old$rid <- as.integer(cand_old$rid)
legacy_fp <- attr(cand_old, "fingerprint")
relig <- me_build_religion_regex(verbose = FALSE)
fp_ok <- is.list(legacy_fp) && identical(legacy_fp$econ, ME_ECON) &&
  identical(as.character(legacy_fp$relig), as.character(relig$with_caritas)) &&
  identical(as.character(legacy_fp$infl_rx), as.character(ME_INFLATION_METAPHOR)) &&
  identical(as.character(legacy_fp$foreign_rx), as.character(ME_FOREIGN_HINT)) &&
  identical(as.integer(legacy_fp$window), as.integer(ME_WINDOW))
if (!fp_ok) stop("Legacy Stage-A derivative does not match the current frozen lexicons.", call. = FALSE)
current_relterms_md5 <- unname(tools::md5sum(here::here("R/religious_terms.R")))
relterms_source_hash_matches <- identical(as.character(legacy_fp$relterms_md5), current_relterms_md5)
if (!relterms_source_hash_matches) {
  cat("  note: religious_terms.R source hash changed, but the compiled Stage-A religion regex is identical\n")
}
cand_new <- cand_old[cand_old$rid %in% ids, , drop = FALSE]
if (!nrow(cand_new) || any(!cand_new$rid %in% ids)) stop("Stage-A restriction failed.", call. = FALSE)

# Exact identity on every retained candidate row, not merely a spot check.
j <- match(cand_new$rid, ids)
c_url <- eq_na(cand_new$URL, official$URL[j])
c_date <- eq_na(as.Date(substr(cand_new$DATE, 1, 10)), as.Date(substr(official$DATE[j], 1, 10)))
c_actor <- eq_na(cand_new$FROM, official$FROM[j])
c_platform <- eq_na(cand_new$SOURCE_TYPE, official$SOURCE_TYPE[j])
c_stream <- eq_na(cand_new$stream, official$data_source[j])
c_title <- eq_na(cand_new$TITLE, official$TITLE[j])
labels <- read.csv(SOURCE_LABELS, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
digikat_require_columns(labels, c("from", "label"), "source label dictionary")
if (anyDuplicated(labels$from[nzchar(labels$from)])) stop("Source label dictionary has duplicate keys.")
label_map <- stats::setNames(labels$label, labels$from)
expected_label <- rep("neoznačeno", nrow(cand_new))
label_hit <- !is.na(cand_new$FROM) & cand_new$FROM %in% names(label_map)
expected_label[label_hit] <- unname(label_map[cand_new$FROM[label_hit]])
c_label <- eq_na(cand_new$label, expected_label)
if (!all(c_url) || !all(c_date) || !all(c_actor) || !all(c_platform) || !all(c_stream) ||
    !all(c_title) || !all(c_label)) {
  stop("Retained Stage-A candidates do not match URL/DATE/FROM/platform/stream/TITLE/current labels.",
       call. = FALSE)
}
attr(cand_new, "official_corpus_sha256") <- actual_sha
attr(cand_new, "derivation") <- "exact stable-ID restriction of accumulator Stage A"
stage <- digikat_stage_rds(cand_new, RSP_STAGEA_CANDIDATES,
  validate = function(x) {
    stopifnot(nrow(x) == nrow(cand_new), identical(x$rid, cand_new$rid), identical(x$domain, cand_new$domain))
    invisible(TRUE)
  })
digikat_atomic_replace_file(stage, RSP_STAGEA_CANDIDATES)

by_domain <- merge(
  as.data.frame(table(domain = cand_old$domain), stringsAsFactors = FALSE),
  as.data.frame(table(domain = cand_new$domain), stringsAsFactors = FALSE),
  by = "domain", suffixes = c("_accumulator", "_official"), all = TRUE)
names(by_domain)[2:3] <- c("pairs_accumulator", "pairs_official")
by_domain[is.na(by_domain)] <- 0L
by_domain$retained_pct <- round(100 * by_domain$pairs_official / pmax(by_domain$pairs_accumulator, 1), 2)
write.csv(by_domain, file.path(RSP_OUT, "rsp_database_delta_by_domain.csv"), row.names = FALSE,
          fileEncoding = "UTF-8")

gold_path <- file.path(RSP_PRIVATE, "gold_core.csv")
gold <- if (file.exists(gold_path)) read.csv(gold_path, fileEncoding = "UTF-8", stringsAsFactors = FALSE) else NULL

relative_metadata <- function(path, rel) {
  z <- digikat_file_metadata(path)
  z$path <- rel
  z
}

manifest <- list(
  schema_version = 1L,
  generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  generator = "studies/moral-economy/29_prepare_official_rerun.R",
  database = list(path = "data/digikat_corpus.rds", sha256 = actual_sha,
                  rows = nrow(official), columns = ncol(official),
                  date_min = mf$corpus$date_min, date_max = mf$corpus$date_max,
                  stable_id = "dk_master_row"),
  relation = list(type = "exact row subset of the accumulator",
                  identity_checks = list(URL = sum(url_ok), DATE = sum(date_ok), FULL_TEXT = sum(text_ok),
                                         SOURCE_TYPE = sum(platform_ok), data_source = sum(stream_ok),
                                         FROM = sum(actor_ok), candidate_TITLE = sum(c_title),
                                         candidate_current_label = sum(c_label)),
                  prepared_text_transform = "trimws(FULL_TEXT), matching R/semantic/10_prep.R",
                  prepared_doc_id = "dk_<zero-padded dk_master_row>"),
  source_inputs = list(
    accumulator_prepared = relative_metadata(LEGACY_PREP, "data/semantic/corpus_prepared.rds"),
    accumulator_stageA = relative_metadata(
      LEGACY_CAND, "studies/moral-economy/output/stageA_candidates.rds"),
    current_source_labels = relative_metadata(
      SOURCE_LABELS, "resources/dictionaries/source_labels.csv"),
    stageA_fingerprint_verified = list(
      compiled_economic_and_religion_regexes = TRUE,
      window = TRUE,
      religious_terms_source_hash_matches = relterms_source_hash_matches,
      legacy_religious_terms_md5 = as.character(legacy_fp$relterms_md5),
      current_religious_terms_md5 = current_relterms_md5)),
  inputs = list(
    prepared = c(relative_metadata(
      RSP_CORPUS_PREPARED, "studies/moral-economy/output/intermediate/corpus_prepared_official.rds"),
      list(rows = nrow(official))),
    candidates = c(relative_metadata(
      RSP_STAGEA_CANDIDATES, "studies/moral-economy/output/stageA_candidates_official.rds"),
                   list(rows = nrow(cand_new), posts = length(unique(cand_new$rid))))),
  reconciliation = list(
    accumulator_rows = length(prepared_ids), official_rows = nrow(official),
    candidate_pairs_accumulator = nrow(cand_old), candidate_pairs_official = nrow(cand_new),
    candidate_posts_accumulator = length(unique(cand_old$rid)),
    candidate_posts_official = length(unique(cand_new$rid))),
  legacy_gold_survival = list(
    gold_old = if (is.null(gold)) NA_integer_ else nrow(gold),
    gold_retained = if (is.null(gold)) NA_integer_ else sum(as.integer(gold$rid) %in% ids)),
  method_note = paste(
    "Stage A is a row-independent deterministic transform. Because the official corpus is an exact",
    "stable-ID subset and retained URL/DATE/text identities passed, restricting its accumulator result",
    "is algebraically equivalent to rerunning it on the selected rows while preserving semantic-store IDs."))
digikat_write_json_atomic(manifest, RSP_INPUT_MANIFEST)

cat(sprintf("\ninstalled official prepared corpus: %s rows\n", digikat_format_integer(nrow(official))))
cat(sprintf("installed official Stage A: %s pairs / %s posts\n",
            digikat_format_integer(nrow(cand_new)), digikat_format_integer(length(unique(cand_new$rid)))))
cat("manifest -> ", RSP_INPUT_MANIFEST, "\n", sep = "")
