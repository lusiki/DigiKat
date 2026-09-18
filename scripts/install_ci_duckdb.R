# Source-free Windows CI tests use this verified CRAN binary. The empirical
# machine retains renv.lock's DuckDB 1.5.4 and its recorded source fingerprints.
# That version no longer has a CRAN Windows binary; source compilation was the
# reason the existing CI omitted DuckDB. Do not silently upgrade the data run.
digikat_install_ci_duckdb <- function(library=.libPaths()[1L],archive=NULL) {
  if(.Platform$OS.type!="windows")stop("This CI binary is Windows-only.")
  if(is.null(archive)) {
    archive <- tempfile(fileext=".zip")
    utils::download.file("https://cran.r-project.org/bin/windows/contrib/4.6/duckdb_1.5.5.zip",archive,mode="wb",quiet=TRUE)
  }
  expected <- "98ac934d36f63bb088bb7c5384f7f3d916e20fa7f94cbb2850a697b19c0a229f"
  if(!identical(digest::digest(file=archive,algo="sha256",serialize=FALSE),expected))stop("CI DuckDB archive checksum mismatch.")
  dir.create(library,recursive=TRUE,showWarnings=FALSE)
  utils::install.packages(archive,repos=NULL,type="win.binary",lib=library,quiet=TRUE)
  if(as.character(utils::packageVersion("duckdb",lib.loc=library))!="1.5.5")stop("CI DuckDB binary version mismatch.")
  invisible(library)
}
if(any(endsWith(commandArgs(FALSE),"scripts/install_ci_duckdb.R")))digikat_install_ci_duckdb()
