#!/usr/bin/env Rscript
# Round 4 coding: the 50 posts drawn by 20_draw_pre2024_output.R, read 2026-08-10.
#
# CODER: Claude (assistant), single coder, not the PI. Recorded here rather than in the browser
# coder so the decisions are auditable and re-scorable. Eight items are marked borderline in the
# note column and need PI adjudication; the report prints the result with and without them.
#
# Coding rule applied (the README scheme, with the one judgement call it leaves open written down):
#   catholic_clear    Catholic institutions, clergy, liturgy, devotion or Catholic-identified
#                     discourse IS the subject.
#   catholic_mention  a real Catholic reference (church as venue, monastery as landmark, pilgrimage
#                     in a life story) in an item about something else.
#   religious_other   religious but not Catholic. Applied to Muslim content AND to
#                     evangelical/charismatic Protestant devotional content, which the word list
#                     cannot currently distinguish from Catholic devotion.
#   not_religious     no religious content; a pious formula ("za ime Božje", "Bog i Hrvati") is not
#                     religious content.
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "studies/filter-validation/output/private"

lab <- tibble::tribble(
  ~id,   ~label,              ~note,
  "P01", "catholic_mention",  "tree-of-the-year contest; Franciscan monastery garden is the location",
  "P02", "catholic_clear",    "Marian concert in a parish church, TV news item",
  "P03", "catholic_mention",  "BORDERLINE: public-broadcaster schedule listing; one block is the Velika Gospa pilgrimage Mass",
  "P04", "religious_other",   "Muslim: hafiz, mosque, mukabela, Ramadan (BiH)",
  "P05", "catholic_clear",    "Easter Monday procession and Mass",
  "P06", "religious_other",   "BORDERLINE: forum exegesis of the Gospels, no Catholic marker anywhere",
  "P07", "catholic_clear",    "diocesan catechesis camp, nuns, catechists",
  "P08", "catholic_clear",    "Sunday-Gospel column by a Catholic priest (don)",
  "P09", "catholic_clear",    "first Mass of a newly ordained priest",
  "P10", "not_religious",     "party obituary; passed on 'miru Bozjem' + 'Bog i Hrvati'",
  "P11", "religious_other",   "BORDERLINE: foreign rock musician on faith and churchgoing; not Catholic-framed",
  "P12", "catholic_clear",    "BORDERLINE: forum thread on Christ, explicitly on Catholic Church teaching and exegesis",
  "P13", "catholic_clear",    "Blessed Ivan Merz commemoration, postulator, Catholic youth movement",
  "P14", "catholic_clear",    "parish Facebook: invitation to Eucharistic adoration",
  "P15", "catholic_clear",    "BORDERLINE: Catholic TV programme on church music, organ concerts in a parish",
  "P16", "catholic_mention",  "celebrity romance; 'crkveno vjencanje' in passing, plus 'blazenoj romansi' as noise",
  "P17", "catholic_mention",  "cinema listing for the film The Pope's Exorcist",
  "P18", "catholic_clear",    "BORDERLINE: audio-Bible psalm channel, Catholic canon named",
  "P19", "catholic_clear",    "parish church restoration financed partly by the archdiocese",
  "P20", "catholic_clear",    "Caritas and a parish housing Ukrainian refugees",
  "P21", "religious_other",   "charismatic/Protestant 'prophetic' channel",
  "P22", "catholic_clear",    "hagiography of St Anastasia, patron of Zadar",
  "P23", "catholic_mention",  "BORDERLINE: concert in the earthquake-damaged cathedral; cathedral-restoration committee involved",
  "P24", "catholic_clear",    "farewell to a parish priest after 25 years",
  "P25", "catholic_clear",    "forum post on personal Catholic devotion, rosary, Mass",
  "P26", "catholic_clear",    "saint of the day, St Giles",
  "P27", "catholic_clear",    "priest on the Holy Spirit and the sacraments",
  "P28", "catholic_mention",  "celebrity gossip; pilgrimage to Marija Bistrica inside a life story",
  "P29", "catholic_clear",    "Laudato TV prayer day sells out Arena Zagreb",
  "P30", "not_religious",     "Kardashian gossip; passed on 'za ime Bozje' + 'dusu'",
  "P31", "religious_other",   "evangelical devotional (novizivot.net), no Catholic marker",
  "P32", "catholic_clear",    "Franciscan anniversary Mass and biography",
  "P33", "catholic_clear",    "retreat for diaconate candidates",
  "P34", "catholic_clear",    "parish-adjacent Facebook devotional, #SVETAMARIJA #SVETIJOSIP",
  "P35", "catholic_clear",    "BORDERLINE: Marian apparition/prophecy channel; Gospa, Isus, sveci",
  "P36", "catholic_clear",    "Catholic TV talk on evangelisation, Franciscan guest, Pope quoted",
  "P37", "not_religious",     "WINDOW: 28k-char aggregator page; only 'Boga' (mole Boga) inside 3000 chars, 13 further matches beyond",
  "P38", "catholic_clear",    "Pope vaccinated; reaction of Croatian Catholic milieu",
  "P39", "catholic_clear",    "daily Gospel reflection, hkm.hr",
  "P40", "catholic_clear",    "traditionalist attack on Pope Francis and the synod",
  "P41", "catholic_clear",    "bishop at a parish first-graders' meeting",
  "P42", "catholic_clear",    "new leadership of a female religious congregation",
  "P43", "catholic_clear",    "Gospel of the day with reflection, priest named",
  "P44", "catholic_clear",    "BORDERLINE: rock concert opening a Catholic shrine festival; Mass, procession, bishop covered",
  "P45", "catholic_clear",    "seminar for nurse-religious",
  "P46", "not_religious",     "WINDOW: 10k-char political column; ZERO matches inside the first 3000 chars",
  "P47", "catholic_mention",  "the 1645 Zagreb fire; churches and monastery as objects destroyed",
  "P48", "catholic_clear",    "parish Facebook: novena to St Joseph",
  "P49", "religious_other",   "charismatic network 'Krist je Internacionalan', Rijeka",
  "P50", "not_religious",     "WINDOW: 8k-char war-veteran biography; ZERO matches inside the first 3000 chars"
)

s <- readRDS(file.path(OUT, "pre2024_output_sample.rds"))
d <- s$sample
stopifnot(nrow(lab) == 50L, !anyDuplicated(lab$id), setequal(lab$id, d$id))
d <- left_join(d, lab, by = "id")
d$clear <- d$label == "catholic_clear"
d$loose <- d$label %in% c("catholic_clear", "catholic_mention")
d$borderline <- grepl("^BORDERLINE", d$note)

wil <- function(k, n) { p <- k/n; z <- 1.96; den <- 1 + z^2/n
  sprintf("%.1f [%.1f-%.1f]", 100*p,
          100*((p + z^2/(2*n))/den - z*sqrt(p*(1-p)/n + z^2/(4*n^2))/den),
          100*((p + z^2/(2*n))/den + z*sqrt(p*(1-p)/n + z^2/(4*n^2))/den)) }

cat("=== round 4: 50 posts from the pre-2024 rebuild output, coded ===\n")
print(as.data.frame(table(d$label)), row.names = FALSE)
cat("\nstrict precision (catholic_clear)      :", wil(sum(d$clear), nrow(d)), "\n")
cat("loose  precision (incl. passing mention):", wil(sum(d$loose), nrow(d)), "\n")
cat("borderline items needing PI adjudication:", sum(d$borderline), "\n")

cat("\n=== split by whether the post is already in the corpus ===\n")
print(as.data.frame(d |> group_by(in_master) |>
  summarise(read = n(), clear = wil(sum(clear), n()), loose = wil(sum(loose), n()),
            .groups = "drop")), row.names = FALSE)

cat("\n=== what the errors are ===\n")
err <- d[!d$clear, c("id", "label", "in_master", "n_tot", "n_dec", "score", "note")]
print(as.data.frame(err), row.names = FALSE)

cat("\n=== gate 2's score on each class (it is confident about the wrong ones too) ===\n")
print(as.data.frame(d |> group_by(label) |>
  summarise(n = n(), median_score = round(median(score), 3),
            min = round(min(score), 3), max = round(max(score), 3), .groups = "drop")),
  row.names = FALSE)

saveRDS(d, file.path(OUT, "pre2024_output_coded.rds"))
write.csv(d[, c("id","label","note","in_master","n_tot","n_dec","score")],
          file.path(OUT, "pre2024_output_coded_public.csv"), row.names = FALSE,
          fileEncoding = "UTF-8")
cat("\nwrote pre2024_output_coded.rds (with text) and pre2024_output_coded_public.csv (no text/URL)\n")
