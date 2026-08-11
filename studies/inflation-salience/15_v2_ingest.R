#!/usr/bin/env Rscript
# 15_v2_ingest.R — migrate the v2 labels to the refreshed official-corpus set.
#
# Original three-run majority labels are joined by stable source-row id. The ten newly
# coded domestic items are added explicitly. Agreement is recomputed on the retained
# original items from the three untouched private annotation files; single-coded addendum
# items are excluded from kappa and reported separately in v2_coding_provenance.csv.

source("studies/inflation-salience/_lib.R")

rule("15_v2_ingest.R")

BD <- file.path(PRIVATE, "batches", "v2")
ann_files <- file.path(BD, paste0("a", 1:3), "labels.csv")
base_path <- file.path(PRIVATE, "v2_majority_full.csv")
add_path <- file.path(OUT, "v2_labels_corpus_addendum.csv")
key_path <- file.path(PRIVATE, "v2_key.csv")
need_files <- c(ann_files, base_path, add_path, key_path)
if (any(!file.exists(need_files)))
  stop("missing v2 input(s): ", paste(need_files[!file.exists(need_files)], collapse = ", "))

key <- fread(key_path, encoding = "UTF-8", na.strings = c("", "NA"))
base <- fread(base_path, encoding = "UTF-8", na.strings = c("", "NA"))
add <- fread(add_path, encoding = "UTF-8", na.strings = c("", "NA"))

keep <- c("rid", "object", "voice", "unit", "unit_name", "object_agree_n",
          "voice_agree_n", "unit_agree_n")
if (!all(keep %in% names(base)) || !all(keep %in% names(add)))
  stop("original v2 labels and addendum do not share the required schema")

base_use <- base[rid %in% key$rid, ..keep]
base_use[, coding_source_v2 := "prior_three_run_majority"]
add_use <- add[, ..keep]
add_use[, coding_source_v2 := "corpus_v1_addendum"]
labels <- rbindlist(list(base_use, add_use), use.names = TRUE, fill = TRUE)
if (anyDuplicated(labels$rid) || !setequal(labels$rid, key$rid) || nrow(labels) != nrow(key))
  stop("v2 labels must cover every refreshed domestic item exactly once")
lab <- merge(key, labels, by = "rid", all.x = TRUE, sort = FALSE)
setorder(lab, rid)

object_domain <- c("own", "household", "both", "other")
voice_domain <- c("sector", "outside")
unit_domain <- c("parish", "diocese", "order", "caritas", "conference",
                 "vatican", "church", "none")
if (anyNA(lab$unit) || anyNA(lab[register == "institution"]$object) ||
    anyNA(lab[register == "institution"]$voice)) stop("unresolved refreshed v2 labels")
if (length(setdiff(na.omit(unique(lab$object)), object_domain)) ||
    length(setdiff(na.omit(unique(lab$voice)), voice_domain)) ||
    length(setdiff(unique(lab$unit), unit_domain))) stop("out-of-domain refreshed v2 label")

## ------------------------------------------------ agreement on retained original items ----

read_ann <- function(f, a) {
  x <- fread(f, encoding = "UTF-8", na.strings = c("", "NA"))
  need <- c("item", "object", "voice", "unit")
  if (!all(need %in% names(x))) stop(f, " lacks required annotation columns")
  setnames(x, setdiff(need, "item"), paste0(setdiff(need, "item"), "_a", a))
  x[, c("item", paste0(c("object", "voice", "unit"), "_a", a)), with = FALSE]
}

raw_ann <- Reduce(function(x, y) merge(x, y, by = "item", all = TRUE, sort = FALSE),
                  lapply(seq_along(ann_files), function(a) read_ann(ann_files[a], a)))
raw_ann <- merge(base[, .(item, rid, register)], raw_ann, by = "item", all.x = TRUE)
raw_ann <- raw_ann[rid %in% base_use$rid]

fleiss_kappa <- function(m, domain) {
  m <- as.matrix(m); n <- nrow(m); k <- length(domain); nr <- ncol(m)
  counts <- t(apply(m, 1L, function(z) tabulate(match(z, domain), nbins = k)))
  p_i <- (rowSums(counts^2) - nr) / (nr * (nr - 1))
  p_j <- colSums(counts) / (n * nr)
  p_bar <- mean(p_i); p_e <- sum(p_j^2)
  if (isTRUE(all.equal(p_e, 1))) return(NA_real_)
  (p_bar - p_e) / (1 - p_e)
}

agreement_row <- function(axis, domain, use) {
  z <- raw_ann[use, paste0(axis, "_a", 1:3), with = FALSE]
  p12 <- mean(z[[1]] == z[[2]]); p13 <- mean(z[[1]] == z[[3]]); p23 <- mean(z[[2]] == z[[3]])
  data.table(axis = axis, n = nrow(z),
             unanimous = round(mean(apply(z, 1L, uniqueN) == 1L), 3),
             majority = round(mean(apply(z, 1L, function(q) max(table(q))) >= 2L), 3),
             pairwise_agreement = round(mean(c(p12, p13, p23)), 3),
             fleiss_kappa = round(fleiss_kappa(z, domain), 3))
}

agree <- rbind(
  agreement_row("object", object_domain, raw_ann$register == "institution"),
  agreement_row("voice", voice_domain, raw_ann$register == "institution"),
  agreement_row("unit", unit_domain, rep(TRUE, nrow(raw_ann)))
)
fwrite(agree, file.path(OUT, "v2_agreement.csv"))
print(agree)

## ------------------------------------------------ private names ----

norm_name <- function(x) {
  x <- stri_trans_tolower(ifelse(is.na(x), "", x))
  x <- stri_trans_general(x, "Latin-ASCII")
  x <- stri_replace_all_regex(x, "[^a-z0-9]+", " ")
  x <- stri_replace_all_regex(x, "\\b(sveti|sveta|svetog|svete|sv|mons|vlc|fra|don)\\b", " ")
  vapply(strsplit(stri_trim_both(x), " +"), function(tok) {
    tok <- tok[nchar(tok) >= 3L]
    if (!length(tok)) return("")
    paste(sort(unique(substr(tok, 1L, 7L))), collapse = " ")
  }, character(1))
}
lab[, unit_norm := norm_name(unit_name)]

private_keep <- c("item", "rid", "register", "response", "date", "year", "month", "stream",
                  "otype", "object", "voice", "unit", "unit_name", "unit_norm",
                  "object_agree_n", "voice_agree_n", "unit_agree_n", "coding_source_v2")
fwrite(lab[, ..private_keep], file.path(PRIVATE, "v2_majority_corpus.csv"))

# No text, URL, outlet, note or unit name enters the tracked outputs.
tracked <- lab[, .(rid, object, voice, unit, object_agree_n, voice_agree_n,
                   unit_agree_n, coding_source_v2)]
fwrite(tracked, file.path(OUT, "v2_labels.csv"))
analysis_core <- lab[, .(rid, register, response, date, year, month, stream, otype,
                         object, voice, unit, object_agree_n, voice_agree_n,
                         unit_agree_n, coding_source_v2)]
fwrite(analysis_core, file.path(OUT, "v2_analysis_core.csv"))
fwrite(lab[, .(items = .N, institution_items = sum(register == "institution")),
           by = coding_source_v2], file.path(OUT, "v2_coding_provenance.csv"))

## --------------------------------------------------- W1 time series ----

obj <- lab[register == "institution"]
obj[, attention_series := fcase(
  object %in% c("own", "both") & voice == "sector", "Own position, sector voice",
  object %in% c("household", "both") & voice == "sector", "Household hardship, sector voice",
  object %in% c("own", "both") & voice == "outside", "Own position, outside report",
  object %in% c("household", "both") & voice == "outside", "Household hardship, outside report",
  default = "Other"
)]
obj_month <- obj[, .N, by = .(stream, month, object, voice, attention_series)][order(stream, month)]
obj_year <- obj[, .N, by = .(stream, year, object, voice, attention_series)][order(stream, year)]
fwrite(obj_month, file.path(OUT, "attention_object_monthly.csv"))
fwrite(obj_year, file.path(OUT, "attention_object_yearly.csv"))

## --------------------------------------------------- W2 unit matching ----

unit_response <- lab[, .N, by = .(unit, response, register)][order(unit, response, register)]
fwrite(unit_response, file.path(OUT, "unit_response.csv"))

episodes <- unique(lab[nzchar(unit_norm), .(
  unit_norm, unit_name, unit, date,
  action = fcase(register == "crl", "repricing",
                 register == "institution" & voice == "sector" & object %in% c("own", "both"),
                 "own_speech", default = "other")
)][action != "other"])
speech <- episodes[action == "own_speech"]
price <- episodes[action == "repricing"]
pairs <- merge(speech, price, by = "unit_norm", allow.cartesian = TRUE,
               suffixes = c("_speech", "_repricing"))
pairs[, lag_days := as.integer(date_repricing - date_speech)]
pairs <- pairs[lag_days > 0L]
if (nrow(pairs)) pairs <- pairs[order(unit_norm, lag_days, date_speech), .SD[1], by = unit_norm]
fwrite(pairs, file.path(PRIVATE, "v2_matched_pairs.csv"))

matched_summary <- data.table(
  named_units = uniqueN(episodes$unit_norm), own_speech_units = uniqueN(speech$unit_norm),
  repricing_units = uniqueN(price$unit_norm), matched_units = uniqueN(pairs$unit_norm),
  matched_units_over_365_days = uniqueN(pairs[lag_days >= 365L]$unit_norm),
  median_lag_days = if (nrow(pairs)) round(median(pairs$lag_days)) else NA_real_,
  min_lag_days = if (nrow(pairs)) min(pairs$lag_days) else NA_integer_,
  max_lag_days = if (nrow(pairs)) max(pairs$lag_days) else NA_integer_
)
fwrite(matched_summary, file.path(OUT, "unit_matched_summary.csv"))
matched_by_type <- if (nrow(pairs)) {
  pairs[, .(matched_named_units = uniqueN(unit_norm)), by = .(unit = unit_speech)]
} else data.table(unit = character(), matched_named_units = integer())
fwrite(matched_by_type, file.path(OUT, "unit_matched_by_type.csv"))

rule("Refreshed v2 outputs")
print(lab[, .N, by = coding_source_v2])
print(matched_summary)
msg("\nwrote refreshed v2 labels, agreement, attention-object series and unit aggregates")
msg("done.")
