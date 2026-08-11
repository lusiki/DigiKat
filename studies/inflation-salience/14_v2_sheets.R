#!/usr/bin/env Rscript
# 14_v2_sheets.R — assemble the refreshed v2 coding key.
#
# The original three-run object/voice/unit recoding is retained by stable `rid`. Ten
# domestic items from the official-corpus addendum receive the same extension in
# output/v2_labels_corpus_addendum.csv. This script verifies exact coverage and writes a
# current key without altering the original private annotation batches.

source("studies/inflation-salience/_lib.R")

rule("14_v2_sheets.R")

coded <- readRDS(file.path(PRIVATE, "coded_core.rds"))
core <- coded[domestic == 1L][order(rid)]
base_path <- file.path(PRIVATE, "v2_majority_full.csv")
add_path <- file.path(OUT, "v2_labels_corpus_addendum.csv")
if (!file.exists(base_path) || !file.exists(add_path))
  stop("missing original v2 majority file or official-corpus addendum")

base <- fread(base_path, encoding = "UTF-8", na.strings = c("", "NA"))
add <- fread(add_path, encoding = "UTF-8", na.strings = c("", "NA"))
old_ids <- intersect(core$rid, base$rid)
new_ids <- setdiff(core$rid, base$rid)
if (!setequal(new_ids, add$rid))
  stop("v2 addendum does not exactly cover refreshed domestic items absent from the original v2 labels")

key <- core[, .(rid, register, response, date, year, month, stream, otype, coding_source)]
key[, item := sprintf("C%03d", seq_len(.N))]
setcolorder(key, c("item", setdiff(names(key), "item")))
fwrite(key, file.path(PRIVATE, "v2_key.csv"))

rule("Refreshed v2 coverage")
msg("  domestic measured set                 : ", nrow(core))
msg("  covered by original three-run recoding: ", length(old_ids))
msg("  covered by corpus-v1 addendum          : ", length(new_ids))
msg("  institution-register items             : ", sum(core$register == "institution"))
msg("\nwrote ", file.path(PRIVATE, "v2_key.csv"))
msg("original batches and v2_majority_full.csv were left unchanged")
msg("\ndone.")
