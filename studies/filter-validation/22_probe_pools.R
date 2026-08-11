#!/usr/bin/env Rscript
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "studies/filter-validation/output/private"
for (f in c("coded.rds", "holdout_coded.rds", "pre2024_output_coded.rds")) {
  x <- readRDS(file.path(OUT, f))
  cat("==", f, "| rows", nrow(x), "\n  cols:", paste(names(x), collapse = ", "), "\n")
  cat("  strata:", paste(names(table(x$stratum)), table(x$stratum), sep = "=", collapse = " "), "\n")
  cat("  labels:", paste(names(table(x$label)), table(x$label), sep = "=", collapse = " "), "\n")
  cat("  nchar(text): median", median(nchar(as.character(x$text))), "max", max(nchar(as.character(x$text))), "\n")
}
x <- readRDS("data/rebuild/discarded_coded.rds")
cat("== discarded_coded.rds | rows", nrow(x), "\n  cols:", paste(names(x), collapse = ", "), "\n")
cat("  strata:", paste(names(table(x$stratum)), table(x$stratum), sep = "=", collapse = " "), "\n")
cat("  labels:", paste(names(table(x$label)), table(x$label), sep = "=", collapse = " "), "\n")
cat("  nchar(text): median", median(nchar(as.character(x$text))), "max", max(nchar(as.character(x$text))), "\n")
