#!/usr/bin/env Rscript
# Check the coded discard sample, then score it. This is the FIRST measurement taken on the
# actual post-2024 output rather than on a training sample.
# Aggregates only; no post text, titles or URLs are printed.
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "data/rebuild"

args <- commandArgs(trailingOnly = TRUE)
coded_path <- if (length(args)) args[[1]] else
  "studies/filter-validation/output/private/coding_sample_coded(2).csv"
cat("checking:", basename(coded_path), "\n")
stopifnot(file.exists(coded_path))

rd <- function(p) {
  x <- read.csv(p, stringsAsFactors = FALSE, encoding = "UTF-8", colClasses = "character")
  names(x)[1] <- sub("^\ufeff|^X\\.U\\.FEFF\\.", "", names(x)[1]); x
}
cd  <- rd(coded_path)
ref <- rd(file.path(OUT, "discarded_sample.csv"))
cat("rows:", nrow(cd), "| reference sample:", nrow(ref), "\n\n")

## ---- integrity ---------------------------------------------------------------------------------
cat("=== integrity ===\n")
if (!all(cd$id %in% ref$id)) stop("this file does not belong to the discard sample")
blank <- is.na(cd$label) | !nzchar(trimws(cd$label))
j <- left_join(cd[, c("id","label","stratum","url")], ref[, c("id","url","stratum")],
               by = "id", suffix = c("_c", "_r"))
cat("missing items      :", sum(!ref$id %in% cd$id), "\n")
cat("duplicated ids     :", sum(duplicated(cd$id)), "\n")
cat("unlabelled         :", sum(blank), "\n")
cat("URL disagreements  :", sum(j$url_c != j$url_r, na.rm = TRUE), "(must be 0)\n")
cat("stratum disagreements:", sum(j$stratum_c != j$stratum_r, na.rm = TRUE), "(must be 0)\n")
VALID <- c("catholic_clear","catholic_mention","religious_other","not_religious","cannot_tell")
bad <- setdiff(unique(cd$label[!blank]), VALID)
if (length(bad)) cat("!! unrecognised labels:", paste(bad, collapse = ", "), "\n")
mojibake <- sum(grepl("Ä‡|Å¾|Å¡|Ä‘|â€", cd$text))
cat("mojibake rows      :", mojibake, "(must be 0)\n")
ok <- nrow(cd) == nrow(ref) && sum(blank) == 0 && !length(bad) &&
  sum(j$url_c != j$url_r, na.rm = TRUE) == 0 && sum(duplicated(cd$id)) == 0 && mojibake == 0
cat("\n", if (ok) "VERDICT: clean\n" else "VERDICT: NOT clean — stop and look above\n", sep = "")
if (!ok) quit(status = 1)

## ---- the result --------------------------------------------------------------------------------
cd$clear <- cd$label == "catholic_clear"
cd$loose <- cd$label %in% c("catholic_clear", "catholic_mention")
wil <- function(k, n) { p <- k/n; z <- 1.96; den <- 1 + z^2/n
  sprintf("%.1f [%.1f-%.1f]", 100*p,
          100*((p+z^2/(2*n))/den - z*sqrt(p*(1-p)/n + z^2/(4*n^2))/den),
          100*((p+z^2/(2*n))/den + z*sqrt(p*(1-p)/n + z^2/(4*n^2))/den)) }

d <- readRDS(file.path(OUT, "post2024_decisions.rds"))
POP <- c(KEPT     = sum(d$decision == "accepted"),
         R_SECOND = sum(d$decision == "rejected: second pass"),
         R_WORD   = sum(d$decision == "rejected: word rule"))
LBL <- c(KEPT = "kept in the corpus", R_SECOND = "thrown out by the second step",
         R_WORD = "thrown out by the word list")

cat("\n=== what is in each pile (post-2024) ===\n")
res <- bind_rows(lapply(names(POP), function(s) {
  i <- cd$stratum == s
  data.frame(pile = LBL[[s]], population = POP[[s]], read = sum(i),
             genuinely_catholic = wil(sum(cd$clear[i]), sum(i)),
             incl_passing_mentions = wil(sum(cd$loose[i]), sum(i)))
}))
print(as.data.frame(res), row.names = FALSE)

cat("\n=== label breakdown ===\n")
print(as.data.frame.matrix(table(pile = LBL[cd$stratum], label = cd$label)))

## ---- corpus-level arithmetic --------------------------------------------------------------------
rate <- vapply(names(POP), function(s) mean(cd$clear[cd$stratum == s]), numeric(1))
genuine <- POP * rate
cat("\n=== the post-2024 half, measured ===\n")
tab <- data.frame(pile = LBL[names(POP)], posts = POP,
                  genuine = round(genuine), junk = round(POP - genuine),
                  pct_genuine = round(100 * rate, 1))
print(tab, row.names = FALSE)
tot_genuine <- sum(genuine)
cat(sprintf("\nprecision of the corpus you now have : %.1f%%\n", 100 * rate[["KEPT"]]))
cat(sprintf("recall — genuine posts kept          : %.1f%% (%s of an estimated %s)\n",
            100 * genuine[["KEPT"]] / tot_genuine,
            format(round(genuine[["KEPT"]]), big.mark = " "),
            format(round(tot_genuine), big.mark = " ")))
cat(sprintf("before any of this, the same %s posts were %.1f%% genuine\n",
            format(sum(POP), big.mark = " "), 100 * tot_genuine / sum(POP)))
cat(sprintf("\nlost to the second step : %s genuine posts\n",
            format(round(genuine[["R_SECOND"]]), big.mark = " ")))
cat(sprintf("lost to the word list   : %s genuine posts\n",
            format(round(genuine[["R_WORD"]]), big.mark = " ")))
saveRDS(cd, file.path(OUT, "discarded_coded.rds"))
write.csv(tab, file.path(OUT, "post2024_measured.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote discarded_coded.rds and post2024_measured.csv\n")
