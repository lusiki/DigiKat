#!/usr/bin/env Rscript
# 02_linkage_candidates.R — the +/-220-character proximity filter.
#
# Applies the linkage rule to the refreshed official corpus. A long news article
# can mention inflation in one paragraph and a saint's feast in another with no connection
# between them, so co-occurrence at the document level is not evidence of engagement. This
# script keeps an inflation post only when a religious term sits within 220 characters of
# an inflation mention. It is deliberately recall-oriented: it generates candidates for
# coding and accepts false positives, which the coding stage removes.
#
# Writes
#   output/private/linkage_candidates.rds
#   output/candidate_annotation_coverage.csv
#
# Baseline check: the refreshed run produces 761 candidates. Earlier three-run annotations
# cover 729; a documented single-coder addendum covers the remaining 32.

source("studies/inflation-salience/_lib.R")

rule("02_linkage_candidates.R")

tag <- readRDS(file.path(PRIVATE, "tagged_inflation.rds"))
msg("tagged inflation posts: ", nrow(tag))

m <- readRDS(MASTER)
row <- study_row_index(m, tag$rid)
txt <- dk_text(m$TITLE[row], m$FULL_TEXT[row])
rm(m); invisible(gc())

msg("masking documented homonyms ...")
txt_masked <- mask_homonyms(txt)

msg("locating inflation and religious matches ...")
relig_pat <- religious_regex()
gap <- min_gap(txt_masked, INFL_ANY, relig_pat)

cand <- tag[is.finite(gap) & gap <= LINK_WINDOW]
cand[, gap := gap[is.finite(gap) & gap <= LINK_WINDOW]]
saveRDS(cand, file.path(PRIVATE, "linkage_candidates.rds"))

rule("Baseline check — refreshed candidate pool")
fixture_report("linked candidates", nrow(cand), 761L)

pool <- fread(file.path(PRIVATE, "coding_pool_index.csv"), encoding = "UTF-8")
inter <- intersect(cand$rid, pool$rid)
msg("\n  prior three-run coding pool    : ", nrow(pool))
msg("  refreshed official-corpus pool: ", nrow(cand))
msg("  in both                       : ", length(inter),
    sprintf("  (%.1f%% of the refreshed pool)", 100 * length(inter) / nrow(cand)))
msg("  prior pool outside new database: ", length(setdiff(pool$rid, cand$rid)))
msg("  refreshed candidates needing addendum: ", length(setdiff(cand$rid, pool$rid)))

ov <- data.table(
  rid    = union(cand$rid, pool$rid)
)[, `:=`(in_june = rid %in% pool$rid, in_rebuild = rid %in% cand$rid)]
fwrite(ov, file.path(OUT, "candidate_annotation_coverage.csv"))
msg("\n  wrote ", file.path(OUT, "candidate_annotation_coverage.csv"))

rule("Candidates by stream and year")
print(dcast(cand[, .N, by = .(year, stream)], year ~ stream, value.var = "N", fill = 0L))
msg("\ndone.")
