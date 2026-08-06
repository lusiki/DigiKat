#!/usr/bin/env Rscript
# RUN_ALL.R — run the whole study in order.
#
# Run from the repository root:
#   & 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/inflation-salience/RUN_ALL.R
#
# Options:
#   --no-corpus   skip the scripts that read the corpus (01, 02, 03, 04, 06), which is what
#                 a reader of the replication package does, since the corpus does not ship
#   --no-network  skip the Eurostat retrieval and use the archived price series
#   --v2          run the economic-reframe recode/analysis and check/render PAPER_EMIP_v2
#
# The run stops at the first script that fails. 10_paper_checks.R is the one that matters:
# it fails if any table or any number in the manuscript has stopped matching the analysis.

argv <- commandArgs(trailingOnly = TRUE)
CORPUS  <- !("--no-corpus"  %in% argv)
NETWORK <- !("--no-network" %in% argv)
V2      <- "--v2" %in% argv

STEPS <- list(
  list(f = "00_hicp_eurostat.R",         need = "network", v2 = FALSE),
  list(f = "01_tag_inflation.R",         need = "corpus",  v2 = FALSE),
  list(f = "02_linkage_candidates.R",    need = "corpus",  v2 = FALSE),
  list(f = "03_finalize_coded.R",        need = "corpus",  v2 = FALSE),
  list(f = "04_sector_profile.R",        need = "corpus",  v2 = FALSE),
  list(f = "05_instrument_validation.R", need = "",        v2 = FALSE),
  list(f = "06_reannotation_sample.R",   need = "corpus",  v2 = FALSE),
  list(f = "07_reannotation_score.R",    need = "",        v2 = FALSE),
  list(f = "14_v2_sheets.R",             need = "corpus",  v2 = TRUE),
  list(f = "15_v2_ingest.R",             need = "",        v2 = TRUE),
  list(f = "16_v2_event.R",              need = "",        v2 = TRUE),
  list(f = "17_v2_figures.R",            need = "",        v2 = TRUE),
  list(f = "08_tables.R",                need = "",        v2 = FALSE),
  list(f = "09_sync_tables.R",           need = "",        v2 = FALSE),
  list(f = "10_paper_checks.R",          need = "",        v2 = FALSE),
  list(f = "11_render_paper.R",          need = "",        v2 = FALSE),
  list(f = "18_publish_paper.R",         need = "",        v2 = TRUE),
  list(f = "12_replication.R",           need = "",        v2 = FALSE)
)

RSCRIPT <- file.path(R.home("bin"), "Rscript")
started <- Sys.time()
ran <- skipped <- character(0)

for (s in STEPS) {
  if (s$v2 && !V2) { skipped <- c(skipped, s$f); next }
  if (s$need == "corpus"  && !CORPUS)  { skipped <- c(skipped, s$f); next }
  if (s$need == "network" && !NETWORK) { skipped <- c(skipped, s$f); next }
  cat("\n", strrep("=", 78), "\n>>> ", s$f, "\n", strrep("=", 78), "\n", sep = "")
  step_args <- c(file.path("studies/inflation-salience", s$f),
                 if (V2 && s$f %in% c("08_tables.R", "09_sync_tables.R", "10_paper_checks.R",
                                        "11_render_paper.R", "12_replication.R")) "--v2")
  rc <- system2(RSCRIPT, step_args)
  if (rc != 0L) stop("FAILED at ", s$f, " (exit ", rc, ")", call. = FALSE)
  ran <- c(ran, s$f)
}

cat("\n", strrep("=", 78), "\n", sep = "")
cat(sprintf("ran %d scripts in %.1f minutes\n", length(ran),
            as.numeric(difftime(Sys.time(), started, units = "mins"))))
if (length(skipped)) cat("skipped: ", paste(skipped, collapse = ", "), "\n", sep = "")
cat("all checks passed\n")
