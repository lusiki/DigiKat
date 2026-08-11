#!/usr/bin/env Rscript
# 03_finalize_coded.R — assemble the refreshed measured set from stable annotations.
#
# Earlier three-run majority decisions survive in output/coded_labels.csv. The new official
# corpus selects 32 additional candidates, documented in coded_labels_corpus_addendum.csv.
# This script keeps only candidates produced by the refreshed selector and joins both label
# sources through the stable accumulator-row id `dk_master_row`.
#
# `rid` is the accumulator's 1-based source-row id. The official corpus retains it in
# `dk_master_row`, so the join does not depend on corpus ordering or duplicated URLs.
#
# Writes
#   output/private/coded_core.rds      restricted: one row per coded item
#   output/coded_core_stream.csv       tracked aggregate: register x year x stream counts
#
# Baseline counts are printed from the refreshed corpus and then locked by the manuscript
# scalar checks.

source("studies/inflation-salience/_lib.R")

rule("03_finalize_coded.R")

prior <- fread(file.path(OUT, "coded_labels.csv"), encoding = "UTF-8")
add   <- fread(file.path(OUT, "coded_labels_corpus_addendum.csv"), encoding = "UTF-8")
pool  <- fread(file.path(PRIVATE, "coding_pool_index.csv"), encoding = "UTF-8")
cand  <- readRDS(file.path(PRIVATE, "linkage_candidates.rds"))

need <- c("rid", "n", "infl", "link", "foreign", "register")
if (!all(need %in% names(prior)) || !all(need %in% names(add)))
  stop("coding label files do not share the required schema")
new_ids <- setdiff(cand$rid, prior$rid)
if (!setequal(new_ids, add$rid))
  stop("the single-coder addendum does not exactly cover the refreshed candidates absent from the prior pool")
if (anyDuplicated(cand$rid) || anyDuplicated(add$rid)) stop("duplicated stable ids in refreshed coding inputs")

prior_use <- prior[rid %in% cand$rid, ..need]
prior_use[, coding_source := "prior_three_run_majority"]
add_use <- add[, ..need]
add_use[, coding_source := "corpus_v1_addendum"]
lab <- rbindlist(list(prior_use, add_use), use.names = TRUE)
setorder(lab, rid)
if (!setequal(lab$rid, cand$rid) || nrow(lab) != nrow(cand))
  stop("one coding decision is required for every refreshed candidate")
msg("refreshed annotation decisions: ", nrow(lab), " (", nrow(prior_use),
    " prior three-run majorities; ", nrow(add_use), " addendum decisions)")

m <- readRDS(MASTER)

## ------------------------------------------------------ assert the join key -----

rule("Join-key assertion — rid maps through dk_master_row")
row <- study_row_index(m, lab$rid)
msg("  stable ids found in official corpus: ", sum(!is.na(row)), " / ", nrow(lab))
msg("  duplicated URLs in the prior pool (why a URL join remains unsafe): ",
    sum(duplicated(pool$URL)) + sum(duplicated(pool$URL, fromLast = TRUE)))

## ------------------------------------------------------------ assemble -----

dates <- as.Date(m$DATE[row])

# Preserve the historical outlet typology where the prior pool already classified the
# exact row. For new rows, inherit the outlet's unambiguous prior classification; genuinely
# new outlets default to secular/other and are listed in the provenance audit.
otype_exact <- pool$otype[match(lab$rid, pool$rid)]
otype_map <- unique(pool[, .(FROM, otype)])
if (otype_map[, anyDuplicated(FROM)]) stop("an outlet has more than one prior outlet type")
cur_outlet <- as.character(m$FROM[row])
otype_inherit <- otype_map$otype[match(cur_outlet, otype_map$FROM)]
otype <- fifelse(!is.na(otype_exact), otype_exact,
                 fifelse(!is.na(otype_inherit), otype_inherit, "Secular/other"))

coded <- data.table(
  rid       = lab$rid,
  n_ann     = lab$n,
  c_infl    = lab$infl,
  c_link    = lab$link,
  c_foreign = lab$foreign,
  register  = lab$register,
  coding_source = lab$coding_source
)[, `:=`(
  date      = dates,
  year      = as.integer(format(dates, "%Y")),
  month     = format(dates, "%Y-%m"),
  stream    = unname(STREAM_LABEL[m$data_source[row]]),
  outlet    = cur_outlet,
  otype     = otype,
  sentiment = m$AUTO_SENTIMENT[row]
)]
coded[, register := fifelse(register == "cost_relig_life", "crl", register)]

# The measured core takes all three axes together: the post is genuinely about the cost of
# living, religion is genuinely linked to that content rather than incidental to it, and
# the inflation being discussed is Croatian. Dropping the first condition would readmit 13
# items the annotators judged not to be about inflation at all.
coded[, linked   := as.integer(c_infl == 1L & c_link == 1L)]
coded[, domestic := as.integer(c_infl == 1L & c_link == 1L & c_foreign == 0L)]
coded[, response := unname(RESPONSE_OF_REGISTER[register])]

saveRDS(coded, file.path(PRIVATE, "coded_core.rds"))
msg("\nwrote ", file.path(PRIVATE, "coded_core.rds"), " (", nrow(coded), " rows)")

## ------------------------------------------------------- fixture checks -----

rule("Refreshed funnel")
msg("  candidates coded             : ", nrow(coded))
msg("  confirmed literal inflation  : ", sum(coded$c_infl == 1L))
msg("  confirmed religion-linked    : ", sum(coded$linked == 1L))
msg("  ... foreign inflation        : ", sum(coded$linked == 1L & coded$c_foreign == 1L))
msg("  ... domestic measured set    : ", sum(coded$domestic == 1L))
print(coded[, .(candidates = .N, domestic = sum(domestic)), by = coding_source])

core <- coded[domestic == 1L]
rule("Register, outlet type and year of the refreshed domestic set")
print(core[, .N, by = register][order(-N)])
print(core[, .N, by = otype][order(-N)])
print(core[, .N, by = year][order(year)])

## ------------------------------- the stream label the execution brief wanted -----

rule("Collection stream of the measured core")
msg("The stable row id makes the stream exact for all ", nrow(core), " refreshed items.\n")
print(dcast(core[, .N, by = .(year, stream)], year ~ stream, value.var = "N", fill = 0L))

agg <- core[, .N, by = .(year, stream, register)][order(year, stream, register)]
fwrite(agg, file.path(OUT, "coded_core_stream.csv"))
prov <- coded[, .(candidates = .N, literal_inflation = sum(c_infl == 1L),
                  genuine_link = sum(linked), foreign = sum(linked == 1L & c_foreign == 1L),
                  domestic = sum(domestic)), by = coding_source]
fwrite(prov, file.path(OUT, "coding_provenance.csv"))
msg("\nwrote ", file.path(OUT, "coded_core_stream.csv"))
msg("wrote ", file.path(OUT, "coding_provenance.csv"))
msg("\ndone.")
