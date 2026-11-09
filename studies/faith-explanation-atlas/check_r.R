cat(R.version.string, "\n")
x <- readRDS("studies/theological-voices/output/private/sample.rds")
cat("Saved sample read OK, rows", nrow(x), "\n")
