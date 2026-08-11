#!/usr/bin/env Rscript
# The window-only stratum: posts v3 admits ONLY on evidence past character 3000 -- evidence no
# human coder and not gate 2 has ever seen. 161 of 1653 gate-1 accepts in the pool (9,7%).
# Three turned up in the read 50 and all three were junk. Three is not a measurement, so this
# draws 15 of the 161 to read. Read-only; writes a private read pack.
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
OUT <- "studies/filter-validation/output/private"; CAP <- 3000L
set.seed(20260811L)
v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")
cc <- readRDS(file.path(OUT, "repair_pool_cache.rds")); g <- cc$g
dec <- v3$tier == "decisive"
kf <- rowSums(cc$Hf[, dec, drop = FALSE]) >= 1L & rowSums(cc$Hf) >= 2L
kw <- rowSums(cc$Hw[, dec, drop = FALSE]) >= 1L & rowSums(cc$Hw) >= 2L
i <- which(kf & !kw)
cat("window-only accepts:", length(i), "| median chars", median(g$nchar[i]), "\n")
fs <- readRDS(file.path(OUT, "pre2024_output_sample.rds"))$feed_scored
g$in_master <- g$url %in% fs$url[fs$in_master]
cat("of them, already in the master:", sum(g$in_master[i]),
    sprintf("(%.0f%%)\n", 100*mean(g$in_master[i])))
sel <- sample(i, 15)

L <- c("15 posts v3 admits only on evidence beyond character 3000.",
       "For each: the opening (what a coder sees) and then the matches, with their character",
       "position, that actually let it in.", "", strrep("=", 96), "")
for (k in seq_along(sel)) {
  r <- sel[k]; txt <- g$text_full[r]
  who <- which(cc$Hf[r, ])
  ev <- vapply(who, function(j) {
    lo <- stri_locate_first_regex(txt, v3$regex[j], case_insensitive = TRUE)
    if (is.na(lo[1,1])) return(NA_character_)
    a <- max(1L, lo[1,1]-60L); b <- min(nchar(txt), lo[1,2]+60L)
    sprintf("@%d [%s|%s] ...%s...", lo[1,1], v3$term[j], substr(v3$tier[j],1,3),
            gsub("\\s+", " ", substr(txt, a, b)))
  }, character(1))
  L <- c(L, sprintf("W%02d | %s | %d chars | %s", k, g$date[r], g$nchar[r],
                    ifelse(g$in_master[r], "ALREADY IN CORPUS", "NEW MATERIAL")),
         sprintf("  OPENING (first 700 chars): %s", gsub("\\s+", " ", substr(txt, 1, 700))),
         "  EVIDENCE:", paste0("      ", ev[!is.na(ev)]), "", strrep("-", 96), "")
}
cn <- file(file.path(OUT, "window_probe_readpack.txt"), open = "wb")
writeBin(charToRaw(enc2utf8(paste(L, collapse = "\n"))), cn); close(cn)
saveRDS(data.frame(id = sprintf("W%02d", seq_along(sel)), row = sel, url = g$url[sel],
                   nchar = g$nchar[sel], in_master = g$in_master[sel]),
        file.path(OUT, "window_probe_index.rds"))
cat("wrote window_probe_readpack.txt\n")
