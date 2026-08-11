# Where the DigiKat data lives. One definition, so no path is typed twice.
#
# There are TWO datasets in this project and they are not interchangeable:
#
#   digikat_corpus_path()   data/digikat_corpus.rds
#       THE official DigiKat database. Every post in it passed one inclusion rule, identical across
#       both collection eras: word list v4 over the first 3 000 characters, then the second-pass
#       model at the deployment threshold. This is what the website describes and what new work
#       should use.
#
#   digikat_legacy_master_path()   data/merged_comprehensive.rds
#       The accumulator the corpus is cut FROM: everything the vendor supplied, 710 307 rows, still
#       written by R/append_new_data.R. It is also the input every completed paper was computed
#       from, so those papers keep reading it BY NAME. Not deprecated, not primary for analysis.
#
# Both are gitignored and neither is reproducible from a clean clone. The tracked manifest beside
# the corpus carries its size, span and cutting rule, so pages can quote corpus figures on a machine
# that has no data at all.
#
# Environment overrides exist for replication on another machine:
#   DIGIKAT_CORPUS_PATH, DIGIKAT_MASTER_PATH

digikat_corpus_path <- function() {
  Sys.getenv("DIGIKAT_CORPUS_PATH", unset = "data/digikat_corpus.rds")
}

digikat_legacy_master_path <- function() {
  Sys.getenv("DIGIKAT_MASTER_PATH", unset = "data/merged_comprehensive.rds")
}

digikat_corpus_manifest_path <- function() {
  paste0(tools::file_path_sans_ext(digikat_corpus_path()), "_manifest.json")
}

# The manifest is TRACKED and PII-free: counts, spans and hashes, never a row. Reading it is the
# supported way for a Quarto page to state how large the corpus is, because it works without the
# 1 GB file present and cannot drift from it (the corpus sha256 is recorded in it).
digikat_read_corpus_manifest <- function(path = digikat_corpus_manifest_path(),
                                         base_dir = NULL) {
  if (!is.null(base_dir)) path <- file.path(base_dir, basename(path))
  if (!file.exists(path)) {
    stop("Corpus manifest not found: ", path,
         "\nBuild the corpus with: Rscript R/build_corpus.R", call. = FALSE)
  }
  jsonlite::fromJSON(path, simplifyVector = TRUE)
}

# --- staleness guard --------------------------------------------------------------------------
# data/processed/*.rds and data/nlp/*.rds are built from whatever dataset R/03_aggregate.R and
# R/04_nlp.R were pointed at, and they record it in their own manifest. When the corpus moves and the
# aggregates have not been rebuilt, a page would print the new headline count over old charts. That
# is a silently wrong site, so this fails CLOSED: it stops rather than warns.
#
# Pass `strict = FALSE` for a diagnostic that reports instead of stopping.
digikat_assert_aggregates_current <- function(aggregate_manifest = "data/processed/manifest.json",
                                              corpus_manifest = digikat_corpus_manifest_path(),
                                              strict = TRUE) {
  if (!file.exists(aggregate_manifest) || !file.exists(corpus_manifest)) {
    msg <- paste0("Cannot check aggregate freshness: missing ",
                  if (!file.exists(aggregate_manifest)) aggregate_manifest else corpus_manifest)
    if (strict) stop(msg, call. = FALSE)
    return(invisible(structure(FALSE, reason = msg)))
  }
  agg <- jsonlite::fromJSON(aggregate_manifest, simplifyVector = TRUE)
  cor <- jsonlite::fromJSON(corpus_manifest, simplifyVector = TRUE)
  built_from <- if (is.null(agg$input$sha256)) NA_character_ else agg$input$sha256
  expected <- cor$corpus$sha256

  # Invisible: the check is called at the top level of Quarto chunks, where a visible return value
  # is PRINTED into the rendered page ("[1] TRUE / attr(,\"reason\")"). Assignment still works.
  if (!is.na(built_from) && identical(built_from, expected)) return(invisible(structure(TRUE, reason = "ok")))

  msg <- paste0(
    "data/processed/ was NOT built from the current corpus.\n",
    "  aggregates built from : ", if (is.null(agg$input$path)) "?" else agg$input$path,
    " (", substr(if (is.na(built_from)) "?" else built_from, 1, 12), "…)\n",
    "  official corpus now   : ", cor$corpus$path,
    " (", substr(expected, 1, 12), "…, ", cor$corpus$rows, " rows)\n",
    "Rendering now would print current corpus figures over stale charts. Regenerate first:\n",
    "  Rscript R/03_aggregate.R            # preview\n",
    "  Rscript R/03_aggregate.R --apply    # HARD GATE - confirm with the PI\n",
    "  Rscript R/04_nlp.R --build\n",
    "  Rscript R/05_page_summaries.R --build"
  )
  if (strict) stop(msg, call. = FALSE)
  invisible(structure(FALSE, reason = msg))
}

# --- for Quarto pages -------------------------------------------------------------------------
# One call for a page that quotes corpus figures AND draws from data/processed: read the manifest,
# refuse to render against stale aggregates. `root` is the page's way back to the repository root
# ("." for index.qmd, ".." for pages/, "../.." for pages/mapa/).
digikat_page_corpus <- function(root = "../..", check_aggregates = TRUE) {
  mf <- digikat_read_corpus_manifest(base_dir = file.path(root, "data"))
  if (isTRUE(check_aggregates)) {
    digikat_assert_aggregates_current(
      aggregate_manifest = file.path(root, "data", "processed", "manifest.json"),
      corpus_manifest = file.path(root, "data", "digikat_corpus_manifest.json")
    )
  }
  mf
}

# Croatian thousands separator. decimal.mark is set only to silence formatC's warning about
# big.mark and decimal.mark both being "." — these are integers and carry no decimal part.
digikat_hr_int <- function(x) {
  formatC(as.numeric(x), big.mark = ".", decimal.mark = ",", format = "d")
}

# Rounded DOWN to a whole unit of `to`, with a trailing "+", for headline figures that should not
# claim more precision than a moving snapshot has.
digikat_hr_approx <- function(x, to = 10000) {
  paste0(digikat_hr_int(floor(as.numeric(x) / to) * to), "+")
}
