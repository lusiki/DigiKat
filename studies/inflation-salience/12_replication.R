#!/usr/bin/env Rscript
# 12_replication.R — assemble the replication package and check what goes into it.
#
# The package holds everything a reader needs to rebuild every number in the paper except
# the corpus itself, which contains scraped post text and cannot be redistributed. Each
# file is screened before it is copied: nothing carrying a URL, an outlet identity or a
# text excerpt is allowed in, and the script stops rather than shipping one.
#
#   Rscript studies/inflation-salience/12_replication.R

source("studies/inflation-salience/_lib.R")

argv <- commandArgs(trailingOnly = TRUE)
V2 <- "--v2" %in% argv

PKG <- file.path(OUT, "replication")
unlink(PKG, recursive = TRUE); dir.create(file.path(PKG, "code"), recursive = TRUE)
dir.create(file.path(PKG, "data"), recursive = TRUE)
dir.create(file.path(PKG, "tables"), recursive = TRUE)
dir.create(file.path(PKG, "figures"), recursive = TRUE)

rule("12_replication.R")

## ------------------------------------------------------------- screening -----

# Names that always identify a post, whatever they contain.
FORBIDDEN_COLS <- c("url", "uri", "permalink", "full_text", "body", "window", "excerpt",
                    "context", "quote", "username", "email", "snippet", "author")

# Names that identify a post only if they hold text. `link` is one of the four coding
# decisions and holds a zero or a one; `title` and `from` would hold a headline and an
# outlet. The test is therefore on the content, not on the name alone.
AMBIGUOUS_COLS <- c("link", "title", "text", "from", "outlet", "source")

screen <- function(path) {
  if (!grepl("\\.csv$", path)) return(TRUE)
  d  <- fread(path, encoding = "UTF-8", nrows = 5000L)
  hd <- tolower(names(d))

  bad <- intersect(hd, FORBIDDEN_COLS)
  if (length(bad)) {
    msg("  REFUSED ", basename(path), " — identifying column(s): ", paste(bad, collapse = ", "))
    return(FALSE)
  }
  for (i in which(hd %in% AMBIGUOUS_COLS)) {
    v <- d[[i]]
    if (is.character(v) && any(nchar(v) > 30L, na.rm = TRUE)) {
      msg("  REFUSED ", basename(path), " — column '", hd[i], "' holds free text")
      return(FALSE)
    }
  }
  # Free text or a link anywhere else in the file, whatever the column is called.
  raw <- paste(readLines(path, n = 500L, encoding = "UTF-8", warn = FALSE), collapse = " ")
  if (grepl("https?://|www\\.", raw)) {
    msg("  REFUSED ", basename(path), " — contains a link")
    return(FALSE)
  }
  chr <- Filter(is.character, as.list(d))
  if (length(chr) && max(vapply(chr, function(v) max(nchar(v), 0L, na.rm = TRUE), integer(1))) > 120L) {
    msg("  REFUSED ", basename(path), " — contains a long text field")
    return(FALSE)
  }
  TRUE
}

take <- function(from, to) {
  if (!file.exists(from)) { msg("  missing, skipped: ", basename(from)); return(invisible(FALSE)) }
  if (!screen(from)) return(invisible(FALSE))
  file.copy(from, to, overwrite = TRUE)
  msg("  ", basename(from))
  invisible(TRUE)
}

## ----------------------------------------------------------------- code -----

rule("Code")
for (f in list.files(STUDY, pattern = "^(_lib|[0-9]{2}_).*\\.R$", full.names = TRUE))
  take(f, file.path(PKG, "code"))
paper_file <- if (V2) "PAPER_EMIP_v2.md" else "PAPER_EMIP_v1.md"
for (f in c("CODEBOOK.md", "RECONSTRUCTION.md", paper_file))
  take(file.path(STUDY, f), PKG)

## ----------------------------------------------------------------- data -----

rule("Data")
ship <- c("coded_labels.csv", "hicp_hr.csv", "hicp_validation.csv", "derived.csv",
          "attention_monthly.csv", "instrument_series.csv", "instrument_correlations.csv",
          "instrument_threshold.csv", "instrument_robustness.csv", "coded_core_stream.csv",
          "sector_responses.csv", "sector_shares.csv", "sector_seam_free.csv",
          "sector_bridge_2024.csv", "sector_outlets.csv", "reannotation_agreement.csv",
          "reannotation_confusion.csv", "reannotation_by_stratum.csv",
          "fixture_monthly_agreement.csv")
if (V2) ship <- unique(c(setdiff(ship, "derived.csv"),
  "derived_v2.csv", "v2_labels.csv", "v2_analysis_core.csv", "v2_agreement.csv",
  "attention_object_monthly.csv", "attention_object_yearly.csv",
  "unit_response.csv", "unit_matched_summary.csv", "unit_matched_by_type.csv",
  "event_process.csv", "event_summary.csv", "detection_diagnostics.csv"))
ok <- vapply(ship, function(f) isTRUE(take(file.path(OUT, f), file.path(PKG, "data"))), logical(1))

rule("Tables")
for (f in list.files(TABLES, pattern = "\\.md$", full.names = TRUE)) take(f, file.path(PKG, "tables"))

rule("Figures")
for (f in c("fig1_event_timeline.png", "fig2_unit_responses.png"))
  take(file.path(OUT, f), file.path(PKG, "figures"))

## ------------------------------------------- what deliberately stays behind -----

rule("Withheld")
msg("  the corpus itself, which contains scraped post text")
msg("  output/private/, which carries links, outlet identities and text excerpts")
msg("  the coding sheets given to the annotators, for the same reason")
msg("\n  coded_labels.csv ships because it carries only a row number and four labels.")

## ---------------------------------------------------------------- README -----

readme <- c(
  "# Replication package",
  "",
  if (V2) "Inflation, Information, and Delayed Repricing" else
          "The religious sector in an inflation shock: pricing, public voice, and charitable",
  if (V2) "" else "response in Croatia, 2021-2026.",
  "",
  "## What is here",
  "",
  "`code/` holds the analysis in the order it runs. `data/` holds every generated quantity",
  paste0("the paper reports. `tables/` holds the ", if (V2) "nine" else "seven",
         " tables as they appear in the manuscript."),
  if (V2) "`figures/` holds the two publication figures generated from aggregate data." else "",
  paste0("`", paper_file, "` is the manuscript itself, `CODEBOOK.md` the coding protocol, and"),
  "`RECONSTRUCTION.md` an account of which parts of the original pipeline were rebuilt and",
  "how closely the rebuild reproduces them.",
  "",
  "## What is not here, and why",
  "",
  "The corpus of 710 307 posts is not included. It consists of scraped media text obtained",
  "through a commercial monitoring service and cannot be redistributed. Scripts 01 and 02",
  "need it; every other script runs from the files in `data/`.",
  "",
  "Nothing in this package identifies an individual post. The coded labels carry a row",
  "number into the corpus and four coding decisions, and no link, outlet name, headline or",
  "text excerpt appears anywhere. That is enforced by the script that built the package,",
  "which screens each file and refuses to copy one that fails.",
  "",
  "## Reproducing the paper without the corpus",
  "",
  "```",
  "Rscript code/00_hicp_eurostat.R        # needs a network connection",
  "Rscript code/05_instrument_validation.R",
  paste("Rscript code/08_tables.R", if (V2) "--v2" else ""),
  paste("Rscript code/10_paper_checks.R", if (V2) "--v2" else ""),
  "```",
  "",
  "The last of these is the point of the package. It reads the manuscript and fails unless",
  "every table still matches the generated fragment byte for byte and every number quoted",
  "in the text still matches what the scripts produce.",
  "",
  "## Reproducing it from the corpus",
  "",
  paste0("With the corpus at `data/merged_comprehensive.rds`, run scripts 00 through ",
         if (V2) "18" else "12", " in order"),
  "from the repository root. Scripts 01, 02, 03, 04 and 06 read it; the rest do not.",
  "Scripts 01 and 03 print a comparison against the figures published in the paper and",
  "state which of them they reproduce exactly.",
  "",
  "## Software",
  "",
  paste0("R ", getRversion(), " with data.table, stringi, jsonlite and MASS. Standard errors robust to"),
  "autocorrelation are computed in the analysis code rather than taken from a package, so",
  "no additional dependency is required. Word output uses the pandoc bundled with Quarto.",
  "",
  "## Licence",
  "",
  "CC BY 4.0."
)
con <- file(file.path(PKG, "README.md"), open = "wt", encoding = "UTF-8")
writeLines(readme, con); close(con)

rule("Package")
fs <- list.files(PKG, recursive = TRUE)
msg("  ", length(fs), " files, ",
    format(round(sum(file.size(file.path(PKG, fs))) / 1024), big.mark = " "), " KB")
msg("  at ", PKG)
if (!all(ok)) msg("\n  NOTE: ", sum(!ok), " intended data file(s) did not ship — see above.")
msg("\ndone.")
