invisible(Sys.setlocale("LC_CTYPE", "English_United States.utf8"))
options(encoding = "UTF-8")
source("R/lib/digikat_paths.R", encoding = "UTF-8")
study <- "studies/catholic-voices-network"
config <- jsonlite::fromJSON(file.path(study, "config.json"))
manifest <- jsonlite::fromJSON("data/digikat_corpus_manifest.json")
config_hash <- digest::digest(file = file.path(study, "config.json"), algo = "sha256")
utc <- function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
workdir <- Sys.getenv("DIGIKAT_VOICES_WORKDIR")
if (!nzchar(workdir)) stop("Set DIGIKAT_VOICES_WORKDIR outside Git and Dropbox.")
workdir <- normalizePath(workdir, winslash = "/", mustWork = FALSE)
root <- normalizePath(getwd(), winslash = "/")
if (!grepl("^([A-Za-z]:/|/)", workdir) ||
    startsWith(tolower(paste0(workdir, "/")), tolower(paste0(root, "/"))) ||
    "dropbox" %in% tolower(strsplit(workdir, "/", fixed = TRUE)[[1]]))
  stop("Workdir must be an absolute directory outside repository and Dropbox.")
dir.create(workdir, recursive = TRUE, showWarnings = FALSE)
clean_text <- function(x) {
  x <- enc2utf8(as.character(x)); x[is.na(x)] <- ""
  stringi::stri_replace_all_regex(x, "[\\x{0000}-\\x{0008}\\x{000B}\\x{000C}\\x{000E}-\\x{001F}\\x{FFFE}\\x{FFFF}]", "")
}
open_db <- function() {
  con <- DBI::dbConnect(duckdb::duckdb(), file.path(workdir, "voices.duckdb"))
  DBI::dbExecute(con, "CREATE TABLE IF NOT EXISTS run_metadata (corpus_sha256 VARCHAR, config_hash VARCHAR, created_utc VARCHAR)")
  old <- DBI::dbReadTable(con, "run_metadata")
  if (nrow(old)) {
    if (nrow(old) != 1 || old$corpus_sha256 != manifest$corpus$sha256 || old$config_hash != config_hash)
      stop("Corpus/config differs from saved run. Use a new workdir; never mix runs.")
  } else DBI::dbAppendTable(con, "run_metadata", data.frame(corpus_sha256 = manifest$corpus$sha256, config_hash = config_hash, created_utc = utc()))
  con
}
