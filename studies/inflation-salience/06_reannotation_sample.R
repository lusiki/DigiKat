#!/usr/bin/env Rscript
# 06_reannotation_sample.R — draw a blind re-annotation slice and write its coding sheet.
#
# No human will read a validation set, so the validation is model-based and the manuscript
# says so rather than implying a gold standard it does not have. This script draws a
# stratified slice of the coded pool, strips every existing label from it, and writes a
# text-only sheet for an independent annotator. It also carries all twelve disputed
# register cases, which need adjudicating whatever else is sampled.
#
# The sheet contains post text and titles, so it is written to output/private/ and never
# ships. The scored result (08_reannotation_score.R) is an agreement table with no text.
#
# Writes
#   output/private/reannotation_sheet.csv   blind: item, date, outlet type, excerpt
#   output/private/reannotation_key.csv     the withheld labels, for scoring afterwards

source("studies/inflation-salience/_lib.R")

rule("06_reannotation_sample.R")

set.seed(20260805L)   # fixed, so the slice is the same on any machine

coded <- readRDS(file.path(PRIVATE, "coded_core.rds"))
m <- readRDS(MASTER)

## ------------------------------------------------------------- strata -----

# Sampling is stratified on the coding outcome so that every decision the pipeline makes
# is put under test, including the two the paper leans on hardest: the linkage judgement
# that separates genuine engagement from co-occurrence, and the foreign/domestic boundary
# that defines the measured core.
coded[, stratum := fifelse(
  register == "disputed", "disputed",
  fifelse(domestic == 1L, paste0("core: ", register),
          fifelse(linked == 1L & c_foreign == 1L, "linked, foreign", "not linked")))]

target <- c(
  "not linked"          = 40L,
  "linked, foreign"     = 20L,
  "core: crl"           = 25L,
  "core: institution"   = 25L,
  "core: charity"       = 18L,
  "core: devotional"    = 10L,
  "core: justice"       = 15L,
  "core: other"         =  7L,
  "disputed"            = 99L   # take every disputed case, however many there are
)

pick <- rbindlist(lapply(names(target), function(s) {
  pool <- coded[stratum == s]
  n <- min(target[[s]], nrow(pool))
  pool[sample(.N, n)]
}))
setorder(pick, rid)
pick[, item := sprintf("R%03d", seq_len(.N))]

rule("Stratified slice")
print(pick[, .N, by = stratum][order(-N)])
msg("\n  total items: ", nrow(pick), "  (target was at least 150)")
msg("  every disputed register case is included: ",
    sum(pick$stratum == "disputed") == sum(coded$register == "disputed"),
    "  (", sum(pick$stratum == "disputed"), " of ", sum(coded$register == "disputed"), ")")

## --------------------------------------------------------- the excerpt -----

# The annotator sees the same evidence the original coding saw: the title and the text
# around the cost-of-living mention that triggered the match.
txt <- dk_text(m$TITLE[pick$rid], m$FULL_TEXT[pick$rid])
raw <- paste0(ifelse(is.na(m$TITLE[pick$rid]), "", as.character(m$TITLE[pick$rid])), " ",
              ifelse(is.na(m$FULL_TEXT[pick$rid]), "", as.character(m$FULL_TEXT[pick$rid])))
raw <- stri_replace_all_regex(raw, "[\\p{Zs}\\t\\r\\n]+", " ")

loc <- stri_locate_first_regex(txt, INFL_ANY)
ctr <- ifelse(is.na(loc[, 1]), 1L, as.integer((loc[, 1] + loc[, 2]) / 2))
excerpt <- stri_sub(raw, pmax(1L, ctr - 400L), pmin(nchar(raw), ctr + 400L))

sheet <- data.table(
  item     = pick$item,
  date     = format(pick$date),
  outlet_type = pick$otype,
  title    = m$TITLE[pick$rid],
  excerpt  = excerpt
)
key <- pick[, .(item, rid, stratum, c_infl, c_link, c_foreign, register, n_ann)]

fwrite(sheet, file.path(PRIVATE, "reannotation_sheet.csv"))
fwrite(key,   file.path(PRIVATE, "reannotation_key.csv"))
msg("\nwrote ", file.path(PRIVATE, "reannotation_sheet.csv"), " (", nrow(sheet), " items, no labels)")
msg("wrote ", file.path(PRIVATE, "reannotation_key.csv"),   " (withheld labels)")

msg("\n  excerpt length: median ", as.integer(median(nchar(sheet$excerpt))),
    " characters, range ", min(nchar(sheet$excerpt)), " to ", max(nchar(sheet$excerpt)))
msg("\ndone.")
