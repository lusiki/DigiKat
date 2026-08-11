#!/usr/bin/env Rscript
# The 15 window-only posts, read 2026-08-10 by the same coder as round 4.
# Question answered: is the 9,7% of gate-1 accepts that passes only on evidence beyond character
# 3000 worth keeping? Combined with the three that turned up in round 4 that is 18 observations.
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "studies/filter-validation/output/private"

lab <- tibble::tribble(
  ~id,   ~label,             ~note,
  "W01", "not_religious",    "county portal index page: obituary, donations, Red Cross, a poet-priest headline",
  "W02", "catholic_mention", "essay on solitude; Christian anthropology quoted from char 6215 on",
  "W03", "not_religious",    "same portal index page; matches are other articles' headlines",
  "W04", "religious_other",  "New Age channelling ('Iluminati', 'Matthew'); molitva in an esoteric sense",
  "W05", "not_religious",    "1950s political history; 'Krizni put' here is the 1945 death march, not the devotion",
  "W06", "religious_other",  "New Age 'cry of the soul of planet Earth'; pobožnost in a generic sense",
  "W07", "not_religious",    "esoteric column; prorok = Baba Vanga, 'predaj brige Bogu' in passing",
  "W08", "catholic_mention", "foreign-minister visit to BiH; toured a Franciscan monastery museum",
  "W09", "catholic_mention", "biography of a foreign pop singer; torn Pope photo, abuse by priests, reform-school nuns",
  "W10", "catholic_mention", "newspaper feuilleton; a Mass and a pilgrim tragedy among many topics",
  "W11", "catholic_mention", "municipal weekend programme; one item is a chapel anniversary with Mass",
  "W12", "catholic_mention", "health-portal index page that also carries a full Easter liturgy explainer beyond char 3000",
  "W13", "not_religious",    "festival line-up; 'Zupnik' is a rapper's stage name",
  "W14", "not_religious",    "2012 Mayan apocalypse piece plus comments",
  "W15", "not_religious",    "political polemic; 'omiljeni svecenik' and 'posvecenja privatnih biznisa'"
)
ix <- readRDS(file.path(OUT, "window_probe_index.rds"))
stopifnot(setequal(lab$id, ix$id))
d <- left_join(ix, lab, by = "id")
d$clear <- d$label == "catholic_clear"
d$loose <- d$label %in% c("catholic_clear", "catholic_mention")

wil <- function(k, n) { p <- k/n; z <- 1.96; den <- 1 + z^2/n
  sprintf("%.1f [%.1f-%.1f]", 100*p,
          100*max(0, (p + z^2/(2*n))/den - z*sqrt(p*(1-p)/n + z^2/(4*n^2))/den),
          100*((p + z^2/(2*n))/den + z*sqrt(p*(1-p)/n + z^2/(4*n^2))/den)) }

cat("=== the window-only stratum, 15 posts read ===\n")
print(as.data.frame(table(d$label)), row.names = FALSE)
cat("\ngenuinely Catholic  :", wil(sum(d$clear), nrow(d)), "\n")
cat("incl. passing mention:", wil(sum(d$loose), nrow(d)), "\n")
cat("already in the master:", sum(d$in_master), "of", nrow(d), "\n")

r4 <- readRDS(file.path(OUT, "pre2024_output_coded.rds"))
w4 <- grepl("^WINDOW", r4$note)
cat("\n=== pooled with the three window cases found in round 4 ===\n")
cat("read:", nrow(d) + sum(w4), "| genuinely Catholic:", sum(d$clear) + sum(r4$clear[w4]), "\n")
cat("strict precision of this stratum:", wil(sum(d$clear) + sum(r4$clear[w4]), nrow(d) + sum(w4)), "\n")
cat("\nPopulation: 161 of 1653 gate-1 accepts (9,7%), projected 53 100 posts of 545 200.\n")
saveRDS(d, file.path(OUT, "window_probe_coded.rds"))
cat("wrote window_probe_coded.rds\n")
