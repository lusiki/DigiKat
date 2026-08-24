#!/usr/bin/env Rscript
# Check the coded pre-2024 sample, then score it. The mirror of R/check_discarded_coding.R, run on
# the other era so the two precision figures are produced by the same arithmetic.
#
#   Rscript R/check_pre2024_coding.R [coded_csv]
#
# The coded file is joined back to the drawn sample ON id, and the join asserts that the URL agrees.
# That gate is not ceremony: it has already caught mis-keyed items once in this project, and without
# it a transcription slip attaches a label to the wrong post and the wrong pile.
# Aggregates only; no post text, titles or URLs are printed.
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "data/rebuild"

args <- commandArgs(trailingOnly = TRUE)
coded_path <- if (length(args)) args[[1]] else file.path(OUT, "pre2024_coded_labels.csv")
cat("checking:", basename(coded_path), "\n")
stopifnot(file.exists(coded_path))

rd <- function(p) {
  x <- read.csv(p, stringsAsFactors = FALSE, encoding = "UTF-8", colClasses = "character")
  names(x)[1] <- sub("^\ufeff|^X\\.U\\.FEFF\\.", "", names(x)[1]); x
}
cd  <- rd(coded_path)
ref <- rd(file.path(OUT, "pre2024_sample.csv"))
cat("rows:", nrow(cd), "| reference sample:", nrow(ref), "\n\n")

## ---- integrity ---------------------------------------------------------------------------------
cat("=== integrity ===\n")
if (!all(cd$id %in% ref$id)) stop("this file does not belong to the pre-2024 sample")
blank <- is.na(cd$label) | !nzchar(trimws(cd$label))
cat("missing items      :", sum(!ref$id %in% cd$id), "\n")
cat("duplicated ids     :", sum(duplicated(cd$id)), "\n")
cat("unlabelled         :", sum(blank), "\n")
VALID <- c("catholic_clear","catholic_mention","religious_other","not_religious","cannot_tell")
bad <- setdiff(unique(cd$label[!blank]), VALID)
if (length(bad)) cat("!! unrecognised labels:", paste(bad, collapse = ", "), "\n")
if ("url" %in% names(cd)) {
  j <- left_join(cd[, c("id","url")], ref[, c("id","url")], by = "id", suffix = c("_c","_r"))
  cat("URL disagreements  :", sum(j$url_c != j$url_r, na.rm = TRUE), "(must be 0)\n")
  url_ok <- sum(j$url_c != j$url_r, na.rm = TRUE) == 0
} else { cat("URL column         : not supplied by the coder (join is on id alone)\n"); url_ok <- TRUE }
mojibake_pattern <- paste(c(
  intToUtf8(0x00C3),
  paste0(intToUtf8(0x00E2), intToUtf8(0x20AC)),
  paste0(intToUtf8(0x00C4), "[", paste0(intToUtf8(c(0x2021, 0x0164, 0x2018)), collapse = ""), "]"),
  paste0(intToUtf8(0x00C5), "[", paste0(intToUtf8(c(0x00BE, 0x00A1)), collapse = ""), "]")
), collapse = "|")
mojibake <- sum(grepl(mojibake_pattern, ref$text, perl = TRUE))
cat("mojibake rows      :", mojibake, "(must be 0)\n")
ok <- nrow(cd) == nrow(ref) && sum(blank) == 0 && !length(bad) && url_ok &&
  sum(duplicated(cd$id)) == 0 && mojibake == 0
cat("\n", if (ok) "VERDICT: clean\n" else "VERDICT: NOT clean - stop and look above\n", sep = "")
if (!ok) quit(status = 1)

# labels attach to the drawn sample, never the other way round
cd <- ref |> select(-label, -note) |> left_join(cd[, c("id","label")], by = "id")
cd$score <- as.numeric(cd$score); cd$nchar <- as.integer(cd$nchar)
cd$clear <- cd$label == "catholic_clear"
cd$loose <- cd$label %in% c("catholic_clear", "catholic_mention")
wil <- function(k, n) { p <- k/n; z <- 1.96; den <- 1 + z^2/n
  sprintf("%.1f [%.1f-%.1f]", 100*p,
          100*((p+z^2/(2*n))/den - z*sqrt(p*(1-p)/n + z^2/(4*n^2))/den),
          100*((p+z^2/(2*n))/den + z*sqrt(p*(1-p)/n + z^2/(4*n^2))/den)) }

d <- readRDS(file.path(OUT, "pre2024_decisions_v4.rds"))
POP <- c(KEPT     = sum(d$decision == "accepted"),
         R_SECOND = sum(d$decision == "rejected: second pass"),
         R_WORD   = sum(d$decision == "rejected: word rule"))
LBL <- c(KEPT = "kept in the corpus", R_SECOND = "thrown out by the second step",
         R_WORD = "thrown out by the word list")

cat("\n=== what is in each pile (pre-2024) ===\n")
print(as.data.frame(bind_rows(lapply(names(POP), function(s) {
  i <- cd$stratum == s
  data.frame(pile = LBL[[s]], population = POP[[s]], read = sum(i),
             genuinely_catholic = wil(sum(cd$clear[i]), sum(i)),
             incl_passing_mentions = wil(sum(cd$loose[i]), sum(i)))
}))), row.names = FALSE)

cat("\n=== label breakdown ===\n")
print(as.data.frame.matrix(table(pile = LBL[cd$stratum], label = cd$label)))

## ---- corpus-level arithmetic --------------------------------------------------------------------
rate <- vapply(names(POP), function(s) mean(cd$clear[cd$stratum == s]), numeric(1))
genuine <- POP * rate
cat("\n=== the pre-2024 half, measured ===\n")
tab <- data.frame(pile = LBL[names(POP)], posts = POP,
                  genuine = round(genuine), junk = round(POP - genuine),
                  pct_genuine = round(100 * rate, 1))
print(tab, row.names = FALSE)
tot_genuine <- sum(genuine)
cat(sprintf("\nprecision of the corpus you now have : %.1f%%\n", 100 * rate[["KEPT"]]))
cat(sprintf("recall - genuine posts kept          : %.1f%% (%s of an estimated %s)\n",
            100 * genuine[["KEPT"]] / tot_genuine,
            format(round(genuine[["KEPT"]]), big.mark = " "),
            format(round(tot_genuine), big.mark = " ")))
cat(sprintf("before any of this, the same %s posts were %.1f%% genuine\n",
            format(sum(POP), big.mark = " "), 100 * tot_genuine / sum(POP)))
cat(sprintf("\nlost to the second step : %s genuine posts\n",
            format(round(genuine[["R_SECOND"]]), big.mark = " ")))
cat(sprintf("lost to the word list   : %s genuine posts\n",
            format(round(genuine[["R_WORD"]]), big.mark = " ")))

## ---- the open window question, measured on read posts -------------------------------------------
if ("word_rule_window" %in% names(d)) {
  w <- d$word_rule_window[match(cd$url, d$url)]
  k <- cd$stratum == "KEPT" & !is.na(w) & !w
  cat(sprintf("\nkept posts passing only on evidence past 3000 characters: %d of %d read (%.0f%% genuine)\n",
              sum(k), sum(cd$stratum == "KEPT"), 100 * mean(cd$clear[k])))
}

saveRDS(cd, file.path(OUT, "pre2024_coded.rds"))
write.csv(tab, file.path(OUT, "pre2024_measured.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote pre2024_coded.rds and pre2024_measured.csv\n")
