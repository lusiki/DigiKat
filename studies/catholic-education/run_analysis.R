#!/usr/bin/env Rscript
# End-to-end official-corpus analysis runner. Run from the repository root.

scripts <- c(
  "studies/catholic-education/slice.R",
  "studies/catholic-education/stageA_checks.R",
  "studies/catholic-education/signal2_actors.R",
  "studies/catholic-education/conf_secular.R",
  "studies/catholic-education/signal3_affect.R",
  "studies/catholic-education/paper_figures.R",
  "studies/catholic-education/paper_tables.R",
  "studies/catholic-education/paper_checks.R"
)

rscript <- file.path(R.home("bin"), "Rscript.exe")
if (!file.exists(rscript)) rscript <- file.path(R.home("bin"), "Rscript")
for (script in scripts) {
  cat("\n==>", script, "\n")
  status <- system2(rscript, script)
  if (!identical(status, 0L)) {
    stop("Study pipeline failed at ", script, " (exit ", status, ").", call. = FALSE)
  }
}
cat("\nCatholic-education official-corpus pipeline completed.\n")
