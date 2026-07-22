#!/usr/bin/env Rscript
# moral-economy GATE 1 — per-domain precision hand-scan sheet (NO master read).
# Turns Stage A's captured precision sample into a ready-to-code CSV so a human (or the
# croatian-nlp-reviewer agent) can rate tagger precision per domain: is the ECONOMY match a true
# economic reference, and is the religion-in-window link genuine or incidental? These precision
# estimates feed (a) the Q1 candidate-count correction and (b) the H2 corrected-linkage denominators.
#
#   "/c/Program Files/R/R-4.4.1/bin/Rscript.exe" studies/moral-economy/02_gate1_precision_scan.R
suppressPackageStartupMessages({ library(here); library(dplyr) })
source(here::here("studies/moral-economy/lexicon.R"))

out_dir <- here::here("studies/moral-economy/output")
ps_path <- file.path(out_dir, "stageA_precision_sample.rds")
if (!file.exists(ps_path)) stop("Run 01_stageA_tag_linkage.R first (need stageA_precision_sample.rds).")
ps <- readRDS(ps_path)

# blank coding columns for the human/agent scan:
#   econ_true:   1 = the ECONOMY tag is a real economic reference; 0 = homonym/false positive
#   link_genuine:1 = religion genuinely in conversation w/ the economy in-window; 0 = incidental; NA if link_flag=0
#   note:        free text (which homonym, etc.)
sheet <- ps %>%
  arrange(domain, desc(linked)) %>%
  transmute(rid, domain, tier = ME_TIER[domain], link_flag = linked,
            FROM, stream, label,
            econ_true = NA_integer_, link_genuine = NA_integer_, note = "",
            window)

scan_path <- file.path(out_dir, "gate1_precision_sheet.csv")
write.csv(sheet, scan_path, row.names = FALSE, fileEncoding = "UTF-8")

cat("== GATE 1 precision sheet ==\n")
cat("rows:", nrow(sheet), " across", length(unique(sheet$domain)), "domains",
    sprintf("(~%d/domain)\n", round(nrow(sheet)/length(unique(sheet$domain)))))
cat("Per domain (n | linked share in the sample):\n")
print(sheet %>% group_by(domain, tier) %>%
        summarise(n = n(), linked = round(mean(link_flag), 2), .groups = "drop") %>%
        arrange(tier, domain), n = 100)
cat("\nHand-code econ_true (0/1) + link_genuine (0/1/NA) in:\n  ", scan_path, "\n")
cat("Then 02b (or reload here) computes per-domain precision = mean(econ_true) and\n",
    " genuine-linkage precision = mean(link_genuine[link_flag==1]) with Wilson CIs.\n")

# --- if the sheet has already been coded, summarise it (idempotent second run) -----------------
coded_path <- file.path(out_dir, "gate1_precision_sheet_coded.csv")
if (file.exists(coded_path)) {
  cd <- read.csv(coded_path, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
  wilson <- function(k,n,z=1.96){ if(!n||is.na(n))return(c(NA,NA)); p<-k/n; d<-1+z^2/n
    c(max(0,((p+z^2/(2*n))-z*sqrt(p*(1-p)/n+z^2/(4*n^2)))/d), min(1,((p+z^2/(2*n))+z*sqrt(p*(1-p)/n+z^2/(4*n^2)))/d)) }
  prec <- cd %>% group_by(domain, tier) %>% summarise(
    n = n(), econ_precision = round(mean(econ_true, na.rm = TRUE), 3),
    n_link = sum(link_flag == 1, na.rm = TRUE),
    link_precision = round(mean(link_genuine[link_flag == 1], na.rm = TRUE), 3), .groups = "drop")
  write.csv(prec, file.path(out_dir, "gate1_precision_by_domain.csv"), row.names = FALSE, fileEncoding = "UTF-8")
  cat("\n-- CODED precision by domain --\n"); print(as.data.frame(prec), row.names = FALSE)
}
