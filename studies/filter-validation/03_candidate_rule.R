#!/usr/bin/env Rscript
# Build a CANDIDATE repaired term list + tiered rule, and score it against the
# 440 hand-coded items. Does NOT touch R/religious_terms.R (HARD GATE).
suppressPackageStartupMessages({library(dplyr); library(stringi)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")

d <- readRDS("studies/filter-validation/output/private/coded.rds")
d$truth <- d$label == "catholic_clear"
canon <- digikat_load_religious_terms()

# ---- the one zero-term item coded as clearly Catholic: what vocabulary is missing?
cat("=== stratum E item coded clearly Catholic (0 canonical term matches) ===\n")
e <- d[d$stratum == "E" & d$truth, ]
if (nrow(e)) for (i in seq_len(nrow(e)))
  cat(" ", e$platform[i], "|", e$source[i], "\n  title:", substr(e$title[i],1,90),
      "\n  text :", substr(e$text[i],1,400), "\n")

# ---- REPAIRS: anchor the ten leaking patterns to whole words -----------------
repairs <- c(
  "misa"        = "\\bmis[aeu]\\b|\\bmisi\\b|\\bmisom\\b|\\bmisama\\b|\\bmisn[aeiou]",
  "gospa"       = "\\bgosp[aeiu]\\b|\\bgospom\\b|\\bgospin[aeiou]*\\b",
  "papa"        = "\\bpap[aeiou]\\b|\\bpapom\\b|\\bpapin[aeiou]*\\b",
  "križ"        = "\\bkriž(a|u|em|evi|eva)?\\b",
  "demon"       = "\\bdemon(a|i|u|om|ima)?\\b|\\bdemonsk[aeiou]",
  "posvećenje"  = "\\bposvećenj[aeu]\\b",
  "ukazanje"    = "\\bukazanj[aeu]\\b",
  "kler"        = "\\bkler[aui]?\\b|\\bklerik",
  "kaptol"      = "\\bkaptol[aeiou]?\\b",
  "časna"       = NA_character_   # redundant: "časna sestra" already exists as its own term
)
cand <- canon
for (tm in names(repairs)) {
  i <- which(cand$term == tm)
  if (!length(i)) next
  if (is.na(repairs[[tm]])) cand <- cand[-i, ] else cand$regex[i] <- repairs[[tm]]
}
cat("\ncanonical terms:", nrow(canon), "| candidate terms:", nrow(cand), "\n")

# ---- TIERS: decisive terms stand alone; ambiguous ones need company ----------
AMBIG <- c("misa","gospa","papa","križ","demon","posvećenje","ukazanje","kler",
           "kaptol","kršćanin","kršćanstvo","vatikan","duhovnost","blagoslov")
cand$tier <- ifelse(cand$term %in% AMBIG, "ambiguous", "decisive")
cat("decisive:", sum(cand$tier=="decisive"), "| ambiguous:", sum(cand$tier=="ambiguous"), "\n")

hits <- function(txt, terms) {
  t(vapply(seq_along(txt), function(i) {
    if (is.na(txt[i]) || !nzchar(txt[i])) return(rep(FALSE, nrow(terms)))
    stri_detect_regex(txt[i], terms$regex, opts_regex = list(case_insensitive = TRUE))
  }, logical(nrow(terms))))
}
cat("\nscoring 440 items...\n")
H <- hits(d$text, cand)
n_dec <- rowSums(H[, cand$tier == "decisive",  drop = FALSE])
n_amb <- rowSums(H[, cand$tier == "ambiguous", drop = FALSE])

wil <- function(k,n){ if(!n) return(c(NA,NA,NA)); p<-k/n; z<-1.96; den<-1+z^2/n
  c(100*p, 100*((p+z^2/(2*n))/den - z*sqrt(p*(1-p)/n+z^2/(4*n^2))/den),
          100*((p+z^2/(2*n))/den + z*sqrt(p*(1-p)/n+z^2/(4*n^2))/den)) }

score <- function(keep, name) {
  tp <- sum(keep & d$truth); fp <- sum(keep & !d$truth); fn <- sum(!keep & d$truth)
  pr <- wil(tp, tp+fp); rc <- wil(tp, tp+fn)
  data.frame(rule = name, kept = sum(keep),
             precision = round(pr[1],1), p_lo = round(pr[2],1), p_hi = round(pr[3],1),
             recall = round(rc[1],1), r_lo = round(rc[2],1), r_hi = round(rc[3],1),
             f1 = round(2*pr[1]*rc[1]/max(1e-9,pr[1]+rc[1]),1))
}

base_mc <- digikat_match_religious(d$text, canon, min_matches=2L, include_details=FALSE)$root_match_count
rows <- list(
  score(base_mc >= 2,                       "CURRENT: any 2 of 95 (canonical)"),
  score(rowSums(H) >= 2,                    "repaired list, any 2"),
  score(rowSums(H) >= 3,                    "repaired list, any 3"),
  score(n_dec >= 1,                         "tiered: >=1 decisive"),
  score(n_dec >= 2,                         "tiered: >=2 decisive"),
  score(n_dec >= 1 & (n_dec + n_amb) >= 2,  "tiered: >=1 decisive AND >=2 total"),
  score(n_dec >= 2 | (n_dec >= 1 & n_amb >= 2), "tiered: 2 decisive OR 1 decisive + 2 ambiguous")
)
cat("\n=== RULE COMPARISON on the 440 hand-coded items ===\n")
print(bind_rows(rows), row.names = FALSE)

cat("\n=== best candidate rule, by stratum ===\n")
best <- n_dec >= 1 & (n_dec + n_amb) >= 2
print(bind_rows(lapply(sort(unique(d$stratum)), function(s) {
  k <- d$stratum == s
  data.frame(stratum = s, n = sum(k), kept = sum(best[k]),
             precision = round(100*sum(best[k] & d$truth[k])/max(1,sum(best[k])),1),
             recall = round(100*sum(best[k] & d$truth[k])/max(1,sum(d$truth[k])),1))
})), row.names = FALSE)
