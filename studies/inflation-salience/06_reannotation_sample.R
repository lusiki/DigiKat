#!/usr/bin/env Rscript
# 06_reannotation_sample.R — migrate the frozen blind recoding audit to the new database.
#
# The independent recoding was completed on a stratified slice of the earlier candidate
# pool. Its item-to-rid key is preserved once, then restricted to candidates retained by
# the official corpus. No new text sheet is generated: the 32 addendum candidates were not
# part of that blind audit and are reported separately as single-coded.

source("studies/inflation-salience/_lib.R")

rule("06_reannotation_sample.R")

current_path <- file.path(PRIVATE, "reannotation_key.csv")
prior_path <- file.path(PRIVATE, "reannotation_key_prior.csv")
out_path <- file.path(PRIVATE, "reannotation_key_corpus.csv")
if (!file.exists(prior_path)) {
  if (!file.exists(current_path)) stop("original reannotation_key.csv is missing")
  if (!file.copy(current_path, prior_path, overwrite = FALSE))
    stop("could not preserve the original reannotation key")
  msg("preserved the original blind-audit key at ", prior_path)
}

prior <- fread(prior_path, encoding = "UTF-8")
coded <- readRDS(file.path(PRIVATE, "coded_core.rds"))
retained <- prior[rid %in% coded$rid]
if (!nrow(retained)) stop("none of the frozen blind-audit items survives the refreshed selector")
fwrite(retained, out_path)

scope <- data.table(
  metric = c("original blind-audit items", "retained official-corpus audit items",
             "refreshed candidates", "single-coded addendum candidates",
             "single-coded domestic addendum items"),
  value = c(nrow(prior), nrow(retained), nrow(coded),
            sum(coded$coding_source == "corpus_v1_addendum"),
            sum(coded$coding_source == "corpus_v1_addendum" & coded$domestic == 1L))
)
fwrite(scope, file.path(OUT, "reannotation_scope.csv"))

print(retained[, .N, by = stratum][order(-N)])
msg("\n  original blind-audit items : ", nrow(prior))
msg("  retained for refreshed audit: ", nrow(retained))
msg("  addendum candidates excluded : ", sum(coded$coding_source == "corpus_v1_addendum"))
msg("\nwrote ", out_path)
msg("done.")
