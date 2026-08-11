#!/usr/bin/env Rscript
# Integrity check on an exported coding file BEFORE it is scored.
# Round-1 lesson (MEMORY.md): join the coding back on the item id and ASSERT the id agrees with
# the drawn sample, or a label silently attaches to the wrong post.
# Aggregates only — prints no post text, titles or URLs.
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "studies/filter-validation/output/private"

args <- commandArgs(trailingOnly = TRUE)
coded_path <- if (length(args)) args[[1]] else file.path(OUT, "coding_sample_coded(1).csv")
cat("checking:", basename(coded_path), "\n")
stopifnot(file.exists(coded_path))

rd <- function(p) {
  x <- read.csv(p, stringsAsFactors = FALSE, encoding = "UTF-8", colClasses = "character")
  names(x)[1] <- sub("^\ufeff|^X\\.U\\.FEFF\\.", "", names(x)[1])
  x
}
cd  <- rd(coded_path)
cat("rows:", nrow(cd), "| columns:", paste(names(cd), collapse = ", "), "\n\n")

## ---- which sample is this? --------------------------------------------------------------------
hold <- rd(file.path(OUT, "holdout_sample.csv"))
r1   <- readRDS(file.path(OUT, "coded.rds"))
pref <- substr(cd$id, 1, 1)
cat("id prefixes:", paste(names(table(pref)), table(pref), sep = " x ", collapse = ", "), "\n")
is_holdout <- all(cd$id %in% hold$id)
is_round1  <- all(cd$id %in% r1$id)
cat("all ids belong to the 300-item holdout:", is_holdout, "\n")
cat("all ids belong to the round-1 440     :", is_round1,  "\n\n")
if (!is_holdout) stop("this is not the holdout export — refusing to score it as one")
ref <- hold

## ---- completeness -----------------------------------------------------------------------------
cat("=== completeness ===\n")
cat("expected items:", nrow(ref), "| present:", nrow(cd),
    "| missing:", sum(!ref$id %in% cd$id), "| duplicated ids:", sum(duplicated(cd$id)), "\n")
blank <- is.na(cd$label) | !nzchar(trimws(cd$label))
cat("unlabelled rows:", sum(blank), "\n")

VALID <- c("catholic_clear", "catholic_mention", "religious_other", "not_religious", "cannot_tell")
cat("\n=== label values ===\n")
print(as.data.frame(table(label = cd$label, useNA = "ifany")), row.names = FALSE)
bad <- setdiff(unique(cd$label[!blank]), VALID)
if (length(bad)) cat("\n!! unrecognised label value(s):", paste(bad, collapse = ", "), "\n")

## ---- the id/url gate --------------------------------------------------------------------------
j <- left_join(cd[, c("id", "label", "stratum", "url")], ref[, c("id", "url", "stratum")],
               by = "id", suffix = c("_coded", "_drawn"))
mismatch_url <- sum(j$url_coded != j$url_drawn, na.rm = TRUE)
mismatch_str <- sum(j$stratum_coded != j$stratum_drawn, na.rm = TRUE)
cat("\n=== id integrity ===\n")
cat("id present in drawn sample but URL disagrees :", mismatch_url, "(must be 0)\n")
cat("id present in drawn sample but stratum differs:", mismatch_str, "(must be 0)\n")
overlap_r1 <- sum(cd$url %in% as.character(r1$url))
cat("items also present in round 1                 :", overlap_r1, "(must be 0)\n")

## ---- coverage by stratum ------------------------------------------------------------------------
cat("\n=== labels by stratum (rows) ===\n")
tab <- table(stratum = cd$stratum, label = ifelse(blank, "<UNCODED>", cd$label))
print(as.data.frame.matrix(tab))

## ---- encoding -----------------------------------------------------------------------------------
dia <- sum(grepl("[čćžšđČĆŽŠĐ]", cd$text))
cat("\n=== encoding ===\n")
cat("rows whose text contains Croatian diacritics:", dia, "of", nrow(cd),
    if (dia == 0) " !! suspicious — possible mojibake\n" else " (looks intact)\n")
mojibake <- sum(grepl("Ä‡|Å¾|Ä\u008d|Å¡|Ä‘|â€", cd$text))
cat("rows showing classic CP1250/UTF-8 mojibake  :", mojibake, "(must be 0)\n")

## ---- verdict ---------------------------------------------------------------------------------
ok <- nrow(cd) == nrow(ref) && sum(blank) == 0 && !length(bad) &&
  mismatch_url == 0 && mismatch_str == 0 && overlap_r1 == 0 &&
  sum(duplicated(cd$id)) == 0 && mojibake == 0
cat("\n==============================\n")
cat(if (ok) "VERDICT: clean — ready to score\n" else "VERDICT: NOT clean — see above\n")
cat("==============================\n")
if (ok) {
  saveRDS(cd, file.path(OUT, "holdout_coded.rds"))
  cat("saved", file.path(OUT, "holdout_coded.rds"), "\n")
}
