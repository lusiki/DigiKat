# Read-only adapter. Run from repository root, with DIGIKAT_CORPUS_PATH set.
# Uses installed global packages explicitly because this clone's renv is unrestored.
invisible(Sys.setlocale("LC_CTYPE", "English_United States.utf8"))
suppressPackageStartupMessages({library(data.table); library(jsonlite); library(digest)})
setDTthreads(4L)
source("R/lib/digikat_paths.R", encoding = "UTF-8")
dest <- "studies/theological-voices-v2/output/private"
dir.create(dest, recursive = TRUE, showWarnings = FALSE)
target <- file.path(dest, "source_web.csv.gz")
if (file.exists(target)) stop("Frozen export already exists; use a new run directory to re-export.")
manifest <- fromJSON("data/digikat_corpus_manifest.json")
path <- digikat_corpus_path()
hash <- digest(file = path, algo = "sha256", serialize = FALSE)
stopifnot(identical(hash, manifest$corpus$sha256))
d <- as.data.table(readRDS(path))
stopifnot(nrow(d) == manifest$corpus$rows)
d[, record_id := sprintf("DK%07d", .I)]
w <- d[SOURCE_TYPE == "web" & as.IDate(DATE) >= "2021-01-01" & as.IDate(DATE) <= "2026-06-11",
  .(record_id, master_row = dk_master_row, published_at = DATE, published_time = TIME,
    outlet_name = FROM, url = URL, platform = SOURCE_TYPE, language = LANGUAGES,
    location = LOCATIONS, title = TITLE, body_raw = FULL_TEXT,
    data_source, collection_era = dk_era)]
fwrite(w, target, compress = "gzip", bom = FALSE, na = "")
audit <- list(input_path = normalizePath(path, winslash = "/"), sha256 = hash,
  rows = nrow(d), web_export_records = nrow(w), columns = names(d),
  export_sha256 = digest(file = target, algo = "sha256", serialize = FALSE),
  corpus_manifest = manifest, R_version = R.version.string,
  packages = list(data.table = as.character(packageVersion("data.table")),
    jsonlite = as.character(packageVersion("jsonlite")), digest = as.character(packageVersion("digest"))),
  environment_note = "Explicit standalone --vanilla R session using installed global packages; project renv unchanged.")
write_json(audit, file.path(dest, "source_audit.json"), pretty = TRUE, auto_unbox = TRUE)
cat("Exported", nrow(w), "web records; source hash verified.\n")
print(w[, .N, by = language][order(-N)][1:12])
print(w[, .N, by = location][order(-N)][1:12])
