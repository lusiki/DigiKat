#!/usr/bin/env Rscript
# 15_v2_ingest.R — ingest the three blind v2 recodes and build W1/W2 results.
#
# Reads one private labels.csv from each of a1/, a2/ and a3/. The tracked outputs contain
# labels and aggregates only; excerpts, notes, and named institutional units remain under
# output/private/. A three-way disagreement must be explicitly adjudicated in the private
# v2_adjudication.csv before the script will continue.

source("studies/inflation-salience/_lib.R")

rule("15_v2_ingest.R")

BD <- file.path(PRIVATE, "batches", "v2")
ann_files <- file.path(BD, paste0("a", 1:3), "labels.csv")
if (any(!file.exists(ann_files))) {
  stop("missing blind annotation file(s): ",
       paste(ann_files[!file.exists(ann_files)], collapse = ", "), call. = FALSE)
}

object_domain <- c("own", "household", "both", "other")
voice_domain  <- c("sector", "outside")
unit_domain   <- c("parish", "diocese", "order", "caritas", "conference",
                   "vatican", "church", "none")

read_ann <- function(f, a) {
  x <- fread(f, encoding = "UTF-8", na.strings = c("", "NA"))
  need <- c("item", "object", "voice", "unit", "unit_name", "note")
  if (!all(need %in% names(x))) stop(f, " lacks: ", paste(setdiff(need, names(x)), collapse = ", "))
  if (nrow(x) != 520L || uniqueN(x$item) != 520L) stop(f, " must contain 520 unique items")
  if (sum(!is.na(x$object)) != 179L || sum(!is.na(x$voice)) != 179L)
    stop(f, " must contain 179 object and voice decisions")
  bad_o <- setdiff(na.omit(unique(x$object)), object_domain)
  bad_v <- setdiff(na.omit(unique(x$voice)), voice_domain)
  bad_u <- setdiff(na.omit(unique(x$unit)), unit_domain)
  if (length(bad_o) || length(bad_v) || length(bad_u))
    stop(f, " contains out-of-domain labels")
  if (anyNA(x$unit)) stop(f, " has missing unit labels")
  setnames(x, setdiff(names(x), "item"), paste0(setdiff(names(x), "item"), "_a", a))
  x
}

L <- lapply(seq_along(ann_files), function(a) read_ann(ann_files[a], a))
lab <- Reduce(function(x, y) merge(x, y, by = "item", all = TRUE, sort = FALSE), L)
key <- fread(file.path(PRIVATE, "v2_key.csv"), encoding = "UTF-8")
if (!setequal(lab$item, key$item)) stop("annotation items do not equal v2_key items")
lab <- merge(key, lab, by = "item", all.x = TRUE, sort = FALSE)
setorder(lab, rid)

mode3 <- function(x) {
  x <- na.omit(as.character(x))
  if (!length(x)) return(NA_character_)
  z <- sort(table(x), decreasing = TRUE)
  if (z[1] < 2L) return(NA_character_)
  names(z)[1]
}

for (axis in c("object", "voice", "unit")) {
  cols <- paste0(axis, "_a", 1:3)
  lab[, (axis) := apply(.SD, 1L, mode3), .SDcols = cols]
  lab[, paste0(axis, "_agree_n") := apply(.SD, 1L, function(z) {
    z <- na.omit(z); if (!length(z)) return(NA_integer_); max(tabulate(match(z, unique(z))))
  }), .SDcols = cols]
}

## Three distinct labels have no majority. They are uncommon but may not be resolved silently.
ties <- rbindlist(lapply(c("object", "voice", "unit"), function(axis) {
  lab[is.na(get(axis)) & !is.na(get(paste0(axis, "_a1"))), .(item, axis)]
}))
ADJ <- file.path(PRIVATE, "v2_adjudication.csv")
if (nrow(ties)) {
  fwrite(ties, file.path(PRIVATE, "v2_threeway_ties.csv"))
  if (!file.exists(ADJ)) stop(nrow(ties), " three-way ties written to ",
                              file.path(PRIVATE, "v2_threeway_ties.csv"),
                              "; create v2_adjudication.csv (item,axis,label)")
  adj <- fread(ADJ, encoding = "UTF-8")
  if (!all(c("item", "axis", "label") %in% names(adj))) stop("bad v2_adjudication.csv schema")
  if (nrow(adj) != nrow(ties) || !all(paste(ties$item, ties$axis) %in% paste(adj$item, adj$axis)))
    stop("v2_adjudication.csv does not resolve every current tie exactly once")
  for (i in seq_len(nrow(adj))) lab[item == adj$item[i], (adj$axis[i]) := adj$label[i]]
}

if (anyNA(lab$unit) || anyNA(lab[register == "institution"]$object) ||
    anyNA(lab[register == "institution"]$voice)) stop("unresolved majority labels")

## --------------------------------------------------------- agreement ----

fleiss_kappa <- function(m, domain) {
  m <- as.matrix(m)
  n <- nrow(m); k <- length(domain); nr <- ncol(m)
  counts <- t(apply(m, 1L, function(z) tabulate(match(z, domain), nbins = k)))
  p_i <- (rowSums(counts^2) - nr) / (nr * (nr - 1))
  p_j <- colSums(counts) / (n * nr)
  p_bar <- mean(p_i); p_e <- sum(p_j^2)
  if (isTRUE(all.equal(p_e, 1))) return(NA_real_)
  (p_bar - p_e) / (1 - p_e)
}

agreement_row <- function(axis, domain, use) {
  z <- lab[use, paste0(axis, "_a", 1:3), with = FALSE]
  p12 <- mean(z[[1]] == z[[2]]); p13 <- mean(z[[1]] == z[[3]]); p23 <- mean(z[[2]] == z[[3]])
  data.table(
    axis = axis, n = nrow(z), unanimous = round(mean(apply(z, 1L, uniqueN) == 1L), 3),
    majority = round(mean(apply(z, 1L, function(q) max(table(q))) >= 2L), 3),
    pairwise_agreement = round(mean(c(p12, p13, p23)), 3),
    fleiss_kappa = round(fleiss_kappa(z, domain), 3)
  )
}

agree <- rbind(
  agreement_row("object", object_domain, lab$register == "institution"),
  agreement_row("voice",  voice_domain,  lab$register == "institution"),
  agreement_row("unit",   unit_domain,   rep(TRUE, nrow(lab)))
)
fwrite(agree, file.path(OUT, "v2_agreement.csv"))
print(agree)

## ----------------------------------------------------- private names ----

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

for (a in 1:3) lab[, paste0("unit_norm_a", a) := norm_name(get(paste0("unit_name_a", a)))]
lab[, unit_norm := apply(.SD, 1L, function(z) {
  z <- z[nzchar(z)]; if (!length(z)) return("")
  tt <- sort(table(z), decreasing = TRUE); names(tt)[1]
}), .SDcols = paste0("unit_norm_a", 1:3)]
lab[, unit_name := mapply(function(target, n1, n2, n3, r1, r2, r3) {
  nn <- c(n1, n2, n3); rr <- c(r1, r2, r3)
  hit <- rr[!is.na(rr) & nzchar(rr) & nn == target]
  if (length(hit)) return(hit[1])
  hit <- rr[!is.na(rr) & nzchar(rr)]
  if (length(hit)) hit[1] else ""
}, unit_norm, unit_norm_a1, unit_norm_a2, unit_norm_a3,
unit_name_a1, unit_name_a2, unit_name_a3)]

private_keep <- c("item", "rid", "register", "response", "date", "year", "month", "stream",
                  "otype", "object", "voice", "unit", "unit_name", "unit_norm",
                  "object_agree_n", "voice_agree_n", "unit_agree_n")
fwrite(lab[, ..private_keep], file.path(PRIVATE, "v2_majority_full.csv"))

## The tracked file contains no text, source, URL, name, or note.
tracked <- lab[, .(rid, object, voice, unit, object_agree_n, voice_agree_n, unit_agree_n)]
fwrite(tracked, file.path(OUT, "v2_labels.csv"))
analysis_core <- lab[, .(rid, register, response, date, year, month, stream, otype,
                         object, voice, unit, object_agree_n, voice_agree_n, unit_agree_n)]
fwrite(analysis_core, file.path(OUT, "v2_analysis_core.csv"))

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
obj_year  <- obj[, .N, by = .(stream, year, object, voice, attention_series)][order(stream, year)]
fwrite(obj_month, file.path(OUT, "attention_object_monthly.csv"))
fwrite(obj_year,  file.path(OUT, "attention_object_yearly.csv"))

rule("W1 — direct sector speech by attention object")
direct <- obj[voice == "sector", .N, by = .(object, year)][order(object, year)]
print(direct)
peaks <- obj[voice == "sector" & object %in% c("own", "household", "both"),
             .N, by = .(object, month)][order(object, -N, month), .SD[1], by = object]
print(peaks)

## --------------------------------------------------- W2 unit matching ----

unit_response <- lab[, .N, by = .(unit, response, register)][order(unit, response, register)]
fwrite(unit_response, file.path(OUT, "unit_response.csv"))

# Named units only. Multiple reports of the same unit/event are collapsed to unit × day × action.
episodes <- unique(lab[nzchar(unit_norm), .(
  unit_norm, unit_name, unit, date,
  action = fcase(register == "crl", "repricing",
                 register == "institution" & voice == "sector" & object %in% c("own", "both"),
  "own_speech", default = "other")
)][action != "other"])

speech <- episodes[action == "own_speech"]
price  <- episodes[action == "repricing"]
pairs <- merge(speech, price, by = "unit_norm", allow.cartesian = TRUE,
               suffixes = c("_speech", "_repricing"))
pairs[, lag_days := as.integer(date_repricing - date_speech)]
pairs <- pairs[lag_days > 0L]
if (nrow(pairs)) pairs <- pairs[order(unit_norm, lag_days, date_speech), .SD[1], by = unit_norm]
fwrite(pairs, file.path(PRIVATE, "v2_matched_pairs.csv"))

matched_summary <- data.table(
  named_units = uniqueN(episodes$unit_norm),
  own_speech_units = uniqueN(speech$unit_norm),
  repricing_units = uniqueN(price$unit_norm),
  matched_units = uniqueN(pairs$unit_norm),
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
print(matched_summary)

msg("\nwrote v2 labels, agreement, attention-object series, unit aggregates, and private matched pairs")
msg("done.")
