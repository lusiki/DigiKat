#!/usr/bin/env Rscript
# Round 5 coding: the 100 posts the second step discards, read 2026-08-10.
#
# With round 4's 50 accepts this is a two-stratum sample of the SAME population (gate-1 accepts),
# so the threshold can finally be priced by reweighting instead of projected out-of-fold:
#   accepts  1302 in the pool, 50 read  -> each read post stands for 26,04
#   rejects   351 in the pool, 100 read -> each read post stands for  3,51
# Everything below is a Horvitz-Thompson estimate on those weights.
#
# Coder: assistant, same coder and same rule as round 4 (see 21_code_pre2024_output.R).
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/religious_filter.R", encoding = "UTF-8")
source("R/lib/religious_filter_v2.R", encoding = "UTF-8")
source("studies/filter-validation/lib_rule_v4.R", encoding = "UTF-8")
OUT <- "studies/filter-validation/output/private"

lab <- tibble::tribble(
  ~id,   ~label,
  "R001","catholic_mention", "R002","catholic_mention", "R003","not_religious",
  "R004","catholic_mention", "R005","catholic_mention", "R006","religious_other",
  "R007","not_religious",    "R008","catholic_mention", "R009","catholic_mention",
  "R010","catholic_clear",   "R011","catholic_clear",   "R012","catholic_mention",
  "R013","religious_other",  "R014","not_religious",    "R015","catholic_clear",
  "R016","catholic_mention", "R017","catholic_mention", "R018","not_religious",
  "R019","catholic_mention", "R020","catholic_mention", "R021","not_religious",
  "R022","not_religious",    "R023","not_religious",    "R024","catholic_mention",
  "R025","not_religious",    "R026","not_religious",    "R027","catholic_mention",
  "R028","catholic_mention", "R029","not_religious",    "R030","not_religious",
  "R031","catholic_mention", "R032","catholic_mention", "R033","catholic_mention",
  "R034","not_religious",    "R035","catholic_mention", "R036","not_religious",
  "R037","catholic_mention", "R038","catholic_mention", "R039","catholic_clear",
  "R040","not_religious",    "R041","not_religious",    "R042","not_religious",
  "R043","catholic_mention", "R044","not_religious",    "R045","not_religious",
  "R046","not_religious",    "R047","catholic_mention", "R048","catholic_mention",
  "R049","catholic_mention", "R050","not_religious",    "R051","not_religious",
  "R052","catholic_mention", "R053","not_religious",    "R054","catholic_mention",
  "R055","catholic_mention", "R056","catholic_mention", "R057","catholic_mention",
  "R058","not_religious",    "R059","catholic_mention", "R060","catholic_mention",
  "R061","catholic_clear",   "R062","catholic_mention", "R063","catholic_mention",
  "R064","catholic_mention", "R065","catholic_mention", "R066","catholic_mention",
  "R067","religious_other",  "R068","not_religious",    "R069","catholic_mention",
  "R070","catholic_mention", "R071","catholic_mention", "R072","not_religious",
  "R073","not_religious",    "R074","catholic_mention", "R075","not_religious",
  "R076","religious_other",  "R077","catholic_mention", "R078","catholic_mention",
  "R079","catholic_mention", "R080","not_religious",    "R081","not_religious",
  "R082","catholic_mention", "R083","not_religious",    "R084","not_religious",
  "R085","not_religious",    "R086","not_religious",    "R087","catholic_mention",
  "R088","not_religious",    "R089","not_religious",    "R090","not_religious",
  "R091","not_religious",    "R092","catholic_mention", "R093","not_religious",
  "R094","catholic_clear",   "R095","not_religious",    "R096","catholic_mention",
  "R097","catholic_mention", "R098","catholic_mention", "R099","not_religious",
  "R100","catholic_mention"
)
# What the errors are made of, for the write-up. Not used in any calculation.
NOTE <- c(
  window = "R003 R007 R014 R018 R021 R022 R023 R034 R042 R050 R051 R053 R073 R084 R095",
  toponym_or_name = "R029 R072 R081 R088 R089 R091 R093 (Opcina Biskupija, Sveti Kriz Zacretje, Vatikanska ulica, Opcina Kapela)",
  aggregator = "R030 R044 R068 R086",
  idiom_metaphor = "R083 (oltar Domovine) R085 (nema boga isusa) R075 (gaming sign-off)",
  commemoration = "the dominant class: state or local commemorations, funerals and civic events that include a Mass, a prayer or a priest")

s <- readRDS(file.path(OUT, "gate2_reject_sample.rds"))
stopifnot(nrow(lab) == 100L, setequal(lab$id, s$id))
d <- left_join(s, lab, by = "id")
d$clear <- d$label == "catholic_clear"
d$loose <- d$label %in% c("catholic_clear", "catholic_mention")

wil <- function(k, n) { p <- k/n; z <- 1.96; den <- 1 + z^2/n
  sprintf("%.1f [%.1f-%.1f]", 100*p,
          100*max(0,(p + z^2/(2*n))/den - z*sqrt(p*(1-p)/n + z^2/(4*n^2))/den),
          100*((p + z^2/(2*n))/den + z*sqrt(p*(1-p)/n + z^2/(4*n^2))/den)) }

cat("=== what the second step throws away (100 read) ===\n")
print(as.data.frame(table(d$label)), row.names = FALSE)
cat("\ngenuinely Catholic   :", wil(sum(d$clear), nrow(d)), "\n")
cat("incl. passing mention:", wil(sum(d$loose), nrow(d)), "\n")
cat("\nby whether already in the corpus:\n")
print(as.data.frame(d |> group_by(in_master) |>
  summarise(read = n(), clear = wil(sum(clear), n()), .groups = "drop")), row.names = FALSE)
cat("\nthe six genuine ones, by score:", paste(sprintf("%.3f", sort(d$score[d$clear])), collapse = ", "),
    "\n(median score of the whole reject pile:", sprintf("%.3f)\n", median(d$score)))

## ---- the two strata, reweighted ---------------------------------------------------------------
r4 <- readRDS(file.path(OUT, "pre2024_output_coded.rds"))
sp <- readRDS(file.path(OUT, "pre2024_output_sample.rds"))
N_ACC <- 1302L; N_REJ <- 351L; N_G1 <- N_ACC + N_REJ
POOL <- nrow(sp$feed_scored); N_TEXT <- 16736191
SCALE <- N_TEXT / readRDS(file.path(OUT, "repair_pool_cache.rds"))$n_text * 1  # = 1, kept explicit
FEED_ROWS <- 50744L

pool <- bind_rows(
  data.frame(id = r4$id, score = r4$score, clear = r4$clear, in_master = r4$in_master,
             w = N_ACC/nrow(r4), stratum = "accept"),
  data.frame(id = d$id, score = d$score, clear = d$clear, in_master = d$in_master,
             w = N_REJ/nrow(d), stratum = "reject"))
per_post <- N_TEXT / FEED_ROWS        # one pool post stands for this many feed rows
est <- function(keep) {
  posts <- sum(pool$w[keep]); gen <- sum(pool$w[keep & pool$clear])
  c(posts = posts, genuine = gen, precision = 100*gen/posts)
}
tot_gen <- sum(pool$w[pool$clear])
cat(sprintf("\n=== gate 1 accepts: %d posts in the pool, estimated %.1f%% genuine ===\n",
            N_G1, 100*tot_gen/N_G1))
cat(sprintf("    -> projected %s posts, %s genuine, across the feed\n",
            format(round(N_G1*per_post), big.mark = " "),
            format(round(tot_gen*per_post), big.mark = " ")))

cat("\n=== the threshold, measured (not projected) ===\n")
curve <- bind_rows(lapply(c(0, 0.05, 0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 0.95),
  function(t) { k <- pool$score >= t; e <- est(k)
    data.frame(threshold = t, posts = round(e[["posts"]]*per_post),
               genuine = round(e[["genuine"]]*per_post),
               precision = round(e[["precision"]], 1),
               recall = round(100*sum(pool$w[k & pool$clear])/tot_gen, 1),
               f1 = round(2*e[["precision"]]*100*sum(pool$w[k & pool$clear])/tot_gen /
                          (e[["precision"]] + 100*sum(pool$w[k & pool$clear])/tot_gen), 1)) }))
print(as.data.frame(curve), row.names = FALSE)

cat("\n=== is the second step worth running? ===\n")
e0 <- est(rep(TRUE, nrow(pool))); e5 <- est(pool$score >= 0.50)
cat(sprintf("gate 1 only          : %s posts, %.1f%% clean\n",
            format(round(e0[["posts"]]*per_post), big.mark = " "), e0[["precision"]]))
cat(sprintf("gate 1 + gate 2 0,50 : %s posts, %.1f%% clean\n",
            format(round(e5[["posts"]]*per_post), big.mark = " "), e5[["precision"]]))
cat(sprintf("it costs %.1f%% of the volume and %.1f%% of the genuine posts, for +%.1f points\n",
            100*(1 - e5[["posts"]]/e0[["posts"]]), 100*(1 - e5[["genuine"]]/e0[["genuine"]]),
            e5[["precision"]] - e0[["precision"]]))

## ---- with the v4 gate 1 underneath -------------------------------------------------------------
v3 <- digikat_load_religious_terms_v2("R/religious_terms_v3.R")
v4r <- digikat_rule_v4(d$text_full, v3)$keep
v4a <- digikat_rule_v4(r4$text_full, v3)$keep
pool$v4 <- c(v4a, v4r)
cat("\n=== the same question with the repaired gate 1 (v4) underneath ===\n")
for (t in c(0, 0.30, 0.50, 0.70)) {
  k <- pool$v4 & pool$score >= t; e <- est(k)
  cat(sprintf("v4 + threshold %.2f : %s posts, %.1f%% clean, keeps %.1f%% of the genuine\n", t,
              format(round(e[["posts"]]*per_post), big.mark = " "), e[["precision"]],
              100*sum(pool$w[k & pool$clear])/tot_gen))
}
saveRDS(d, file.path(OUT, "gate2_reject_coded.rds"))
write.csv(curve, file.path(OUT, "threshold_curve_measured.csv"), row.names = FALSE,
          fileEncoding = "UTF-8")
cat("\nwrote gate2_reject_coded.rds and threshold_curve_measured.csv\n")
