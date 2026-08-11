#!/usr/bin/env Rscript
# Analyse the hand-coded validation sample: precision by stratum, miss rate,
# and which patterns drive the errors.
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")

f <- "studies/filter-validation/output/private/coding_sample_coded.csv"
d <- read.csv(f, encoding = "UTF-8", stringsAsFactors = FALSE)
cat("rows:", nrow(d), "\n")

d$label[is.na(d$label)] <- ""
cat("\n=== completion ===\n")
cat("coded:", sum(d$label != ""), "of", nrow(d), "\n")
print(table(d$stratum, d$label == "", dnn = c("stratum","uncoded")))

cat("\n=== raw label counts by stratum ===\n")
print(table(d$stratum, d$label))

# Wilson CI
wil <- function(k, n) {
  if (n == 0) return(c(NA, NA, NA))
  p <- k/n; z <- 1.96; den <- 1 + z^2/n
  ctr <- (p + z^2/(2*n))/den
  hw <- z*sqrt(p*(1-p)/n + z^2/(4*n^2))/den
  c(100*p, 100*(ctr-hw), 100*(ctr+hw))
}

cod <- d[d$label != "" & d$label != "cannot_tell", ]
cat("\n=== PRECISION by stratum (excluding 'cannot_tell') ===\n")
res <- lapply(sort(unique(cod$stratum)), function(s) {
  x <- cod[cod$stratum == s, ]
  n <- nrow(x)
  strict <- sum(x$label == "catholic_clear")
  loose  <- sum(x$label %in% c("catholic_clear","catholic_mention"))
  a <- wil(strict, n); b <- wil(loose, n)
  data.frame(stratum = s, n = n,
    strict_pct = round(a[1],1), strict_lo = round(a[2],1), strict_hi = round(a[3],1),
    loose_pct  = round(b[1],1), loose_lo  = round(b[2],1), loose_hi  = round(b[3],1),
    rel_other = sum(x$label=="religious_other"), not_rel = sum(x$label=="not_religious"))
})
print(bind_rows(res), row.names = FALSE)

cat("\n=== what the ORIGIN labels mean ===\n")
print(as.data.frame(table(d$stratum, d$origin)) %>% filter(Freq > 0), row.names = FALSE)

cat("\n=== which matched TERMS appear in FALSE POSITIVES vs TRUE POSITIVES ===\n")
acc <- cod[cod$stratum %in% c("A","B","C"), ]
acc$tp <- acc$label == "catholic_clear"
tl <- strsplit(acc$matched_terms, "; ", fixed = TRUE)
allt <- unique(unlist(tl)); allt <- allt[!is.na(allt) & nzchar(allt)]
tab <- lapply(allt, function(tm) {
  hit <- vapply(tl, function(x) tm %in% x, logical(1))
  data.frame(term = tm, in_rows = sum(hit),
             true_pos = sum(hit & acc$tp), false_pos = sum(hit & !acc$tp),
             pct_false = round(100*sum(hit & !acc$tp)/max(1,sum(hit)),1))
})
tab <- bind_rows(tab) %>% filter(in_rows >= 8) %>% arrange(desc(pct_false), desc(in_rows))
print(as.data.frame(tab), row.names = FALSE)

cat("\n=== stratum D: what the >=2 threshold THROWS AWAY (1-term posts) ===\n")
dd <- cod[cod$stratum == "D", ]
cat("coded:", nrow(dd), "\n")
print(table(dd$label))
w <- wil(sum(dd$label == "catholic_clear"), nrow(dd))
cat(sprintf("clearly Catholic among rejected 1-term posts: %.1f%% [%.1f - %.1f]\n", w[1], w[2], w[3]))

cat("\n=== stratum E: zero-term control ===\n")
print(table(cod$label[cod$stratum == "E"]))

cat("\n=== notes left by the coder ===\n")
nn <- d[!is.na(d$note) & d$note != "", c("id","stratum","label","note")]
if (nrow(nn)) print(nn, row.names = FALSE) else cat("(none)\n")

saveRDS(d, "studies/filter-validation/output/private/coded.rds")
