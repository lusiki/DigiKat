# Render the explicit synthetic preview while its tempdir payload still exists.
# Run from repository root. The page remains excluded from ordinary site builds.
if(.Platform$OS.type=="windows")Sys.setlocale("LC_CTYPE","English_United States.utf8")
source("studies/demokrscanstvo-barometar/sample.R",encoding="UTF-8")
sample <- barometar_sample()
source("studies/demokrscanstvo-barometar/09_figures.R",encoding="UTF-8")
source("studies/demokrscanstvo-barometar/11_checks.R",encoding="UTF-8")
barometar_figures(sample$directory,synthetic_allowed=TRUE)
barometar_release_checks(sample$directory,synthetic_allowed=TRUE)
quarto <- "C:/Program Files/Quarto/bin/quarto.exe"
if(!file.exists(quarto))quarto <- Sys.which("quarto")
if(!nzchar(quarto))stop("Quarto is unavailable.")
protected <- list.files("data/processed",full.names=TRUE)
before <- vapply(protected,digikat_hash_file,character(1L))
Sys.setenv(DIGIKAT_BAROMETAR_DATA_DIR=sample$directory,
  QUARTO_R=normalizePath(file.path(R.home("bin"),"R.exe"),winslash="/",mustWork=TRUE))
render_preview <- function() {
  # An explicitly excluded input is treated as a standalone document by Quarto.
  # Temporarily lift that one exclusion, then restore the exact original bytes.
  config <- "_quarto.yml"
  original <- readBin(config,"raw",file.info(config)$size)
  on.exit(writeBin(original,config),add=TRUE)
  lines <- readLines(config,encoding="UTF-8",warn=FALSE)
  exclusion <- '    - "!pages/demokrscanstvo/index.qmd"'
  if(sum(lines==exclusion)!=1L)stop("Expected one preview exclusion.")
  writeLines(lines[lines!=exclusion],config,useBytes=TRUE)
  system2(quarto,c("render","pages/demokrscanstvo/index.qmd","--no-clean"))
}
status <- render_preview()
after <- vapply(protected,digikat_hash_file,character(1L))
if(!identical(before,after))stop("Protected aggregates changed during preview render.")
if(status!=0L)stop("Synthetic page render failed.")
html <- "docs/pages/demokrscanstvo/index.html"
if(!file.exists(html))stop("Quarto did not write the expected preview path.")
page <- paste(readLines(html,encoding="UTF-8",warn=FALSE),collapse="\n")
if(!stringi::stri_detect_fixed(page,"SINTETIČKI PODACI"))stop("Synthetic banner missing.")
# Copy only checked synthetic public artifacts for local preview downloads.
destination <- "docs/data/barometar/demokrscanstvo"
for(name in list.files(sample$directory,recursive=TRUE)) {
  target <- file.path(destination,name);dir.create(dirname(target),recursive=TRUE,showWarnings=FALSE)
  if(!file.copy(file.path(sample$directory,name),target,overwrite=TRUE))stop("Preview download copy failed.")
}
message("Synthetic local preview rendered. Do not publish its generated HTML.")
