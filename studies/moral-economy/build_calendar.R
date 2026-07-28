#!/usr/bin/env Rscript
# moral-economy — liturgical / ecclesial event calendar 2021-2026 for the H3 "two calendars" test.
# Deterministic (computus for movable feasts; fixed dates otherwise). Emits output/liturgical_calendar.csv
# with a secular_twin flag: events collinear with a secular economic-news date (1 May = Workers' Day,
# Advent/Christmas = consumption/budget season) are FLAGGED so H3 can restrict to twin-free events
# (Lent onset, Corpus Christi, World Day of the Poor) — the identification fix from the referee review.
#   Rscript studies/moral-economy/build_calendar.R
suppressPackageStartupMessages({ library(here) })
out_dir <- here::here("studies/moral-economy/output"); dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Western (Gregorian) Easter — Anonymous Gregorian algorithm (Meeus/Jones/Butcher).
easter <- function(y) {
  a<-y%%19; b<-y%/%100; c<-y%%100; d<-b%/%4; e<-b%%4; f<-(b+8)%/%25; g<-(b-f+1)%/%3
  h<-(19*a+b-d-g+15)%%30; i<-c%/%4; k<-c%%4; l<-(32+2*e+2*i-h-k)%%7
  m<-(a+11*h+22*l)%/%451; mo<-(h+l-7*m+114)%/%31; da<-((h+l-7*m+114)%%31)+1
  as.Date(sprintf("%04d-%02d-%02d", y, mo, da))
}
# 1st Sunday of Advent = 4th Sunday before Dec 25
advent1 <- function(y) { xmas<-as.Date(sprintf("%d-12-25", y))
  dow<-as.integer(format(xmas,"%u")); last_sun<-xmas-dow; last_sun-21 }  # %u: Mon=1..Sun=7
# World Day of the Poor (33rd Sun in Ordinary Time) — published dates, hardcoded for accuracy.
wdp <- c(`2021`="2021-11-14",`2022`="2022-11-13",`2023`="2023-11-19",
         `2024`="2024-11-17",`2025`="2025-11-16",`2026`="2026-11-15")

years <- 2021:2026
rows <- do.call(rbind, lapply(years, function(y) {
  E <- easter(y); ash <- E-46; corpus <- E+60; adv <- advent1(y)
  data.frame(rbind(
    c(y,"ash_wednesday_lent_onset", as.character(ash),     "movable","FALSE","Lent begins; no secular economic twin — CLEAN for H3"),
    c(y,"easter",                   as.character(E),        "movable","TRUE", "spring consumption season — secular twin"),
    c(y,"corpus_christi",           as.character(corpus),   "movable","FALSE","Thu after Trinity; CLEAN for H3"),
    c(y,"st_joseph_worker",         sprintf("%d-05-01",y),  "fixed",  "TRUE", "1 May = International Workers' Day — COLLINEAR, exclude from clean H3"),
    c(y,"world_day_of_poor",        wdp[[as.character(y)]], "movable","FALSE","key poverty observance; near but not on a fixed secular econ date"),
    c(y,"advent_1",                 as.character(adv),      "movable","TRUE", "year-end consumption/budget season — COLLINEAR"),
    c(y,"christmas",                sprintf("%d-12-25",y),  "fixed",  "TRUE", "consumption peak — secular twin")
  ), stringsAsFactors = FALSE)
}))
names(rows) <- c("year","event","date","type","secular_twin","note")
rows$date <- as.character(as.Date(rows$date))
write.csv(rows, file.path(out_dir, "liturgical_calendar.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("== liturgical_calendar.csv (", nrow(rows), "rows,", length(years), "years ) ==\n")
cat("Twin-free events usable for a clean H3 test:",
    paste(unique(rows$event[rows$secular_twin == "FALSE"]), collapse = ", "), "\n")
print(rows[rows$year == 2023, c("event","date","secular_twin")], row.names = FALSE)
cat("Output ->", file.path(out_dir, "liturgical_calendar.csv"), "\n")
