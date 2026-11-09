invisible(Sys.setlocale("LC_CTYPE", "English_United States.utf8"))
options(encoding = "UTF-8")
packages <- c("duckdb", "DBI", "digest", "jsonlite", "stringi")
print(setNames(vapply(packages, requireNamespace, logical(1), quietly = TRUE), packages))
source("R/lib/digikat_paths.R", encoding = "UTF-8")
cat("Configured corpus exists:", file.exists(digikat_corpus_path()), "\n")
if ("--inspect" %in% commandArgs(TRUE)) {
  x <- readRDS(digikat_corpus_path())
  print(names(x))
  print(dim(x))
}
