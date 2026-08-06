#!/usr/bin/env Rscript
# 02_linkage_candidates.R — the +/-220-character proximity filter.
#
# Rebuilds the linkage stage of the lost scratchpad/10_rerun_fixed.R. A long news article
# can mention inflation in one paragraph and a saint's feast in another with no connection
# between them, so co-occurrence at the document level is not evidence of engagement. This
# script keeps an inflation post only when a religious term sits within 220 characters of
# an inflation mention. It is deliberately recall-oriented: it generates candidates for
# coding and accepts false positives, which the coding stage removes.
#
# Writes
#   output/private/linkage_candidates.rds
#   output/fixture_linkage_overlap.csv
#
# Fixture check: the June 2026 run produced 1,450 candidates
# (output/private/coding_pool_index.csv).

source("studies/inflation-salience/_lib.R")

rule("02_linkage_candidates.R")

tag <- readRDS(file.path(PRIVATE, "tagged_inflation.rds"))
msg("tagged inflation posts: ", nrow(tag))

m <- readRDS(MASTER)
txt <- dk_text(m$TITLE[tag$rid], m$FULL_TEXT[tag$rid])
rm(m); invisible(gc())

msg("masking documented homonyms ...")
txt_masked <- mask_homonyms(txt)

msg("locating inflation and religious matches ...")
relig_pat <- religious_regex()
gap <- min_gap(txt_masked, INFL_ANY, relig_pat)

cand <- tag[is.finite(gap) & gap <= LINK_WINDOW]
cand[, gap := gap[is.finite(gap) & gap <= LINK_WINDOW]]
saveRDS(cand, file.path(PRIVATE, "linkage_candidates.rds"))

rule("Fixture check — candidate pool")
fixture_report("linked candidates", nrow(cand), 1450L)

pool <- fread(file.path(PRIVATE, "coding_pool_index.csv"), encoding = "UTF-8")
inter <- intersect(cand$rid, pool$rid)
msg("\n  June 2026 pool                : ", nrow(pool))
msg("  reconstructed pool            : ", nrow(cand))
msg("  in both                       : ", length(inter),
    sprintf("  (%.1f%% of the June pool)", 100 * length(inter) / nrow(pool)))
msg("  June only (recall miss)       : ", length(setdiff(pool$rid, cand$rid)))
msg("  reconstruction only (new)     : ", length(setdiff(cand$rid, pool$rid)))

ov <- data.table(
  rid    = union(cand$rid, pool$rid)
)[, `:=`(in_june = rid %in% pool$rid, in_rebuild = rid %in% cand$rid)]
fwrite(ov, file.path(OUT, "fixture_linkage_overlap.csv"))
msg("\n  wrote ", file.path(OUT, "fixture_linkage_overlap.csv"))

rule("Candidates by stream and year")
print(dcast(cand[, .N, by = .(year, stream)], year ~ stream, value.var = "N", fill = 0L))
msg("\ndone.")
