# run_all.R — the whole chain in one command.
#
#   Rscript run_all.R              real export(s) in input/  → items, aggregates, figures, story drafts, replay
#   Rscript run_all.R --synthetic  regenerate the synthetic export first, then the same chain (pipeline test)
#
# Stops at the first failing step. Each step is also runnable on its own (see the header of each script).

setwd(dirname(normalizePath(sub("--file=", "", grep("--file=", commandArgs(), value = TRUE)[1]))))
args <- commandArgs(trailingOnly = TRUE)
SYNTH <- "--synthetic" %in% args
rscript <- file.path(R.home("bin"), "Rscript")

steps <- c(if (SYNTH) "00_make_synthetic.R", "01_ingest.R", "02_analyze.R", "03_figures.R", "04_story.R", "05_replay.R")
t_start <- Sys.time()
for (s in steps) {
  cat("\n=== ", s, " ===\n", sep = "")
  a <- if (s == "01_ingest.R" && SYNTH) c(s, "--synthetic") else s
  rc <- system2(rscript, a)
  if (rc != 0) stop(sprintf("%s failed (exit %d). Fix and rerun; earlier steps' outputs are intact.", s, rc), call. = FALSE)
}
cat(sprintf("\nAll %d steps done in %.1f min. Outputs in output/ (figures/, agg/, story_hr.md, linkedin_*.md, replay.html).\n",
            length(steps), as.numeric(difftime(Sys.time(), t_start, units = "mins"))))
if (SYNTH) cat("SYNTHETIC run — nothing produced is a finding.\n")
