#!/usr/bin/env Rscript
# moral-economy — INSTALL THE GENERATED TABLE FRAGMENTS INTO THE RSP MANUSCRIPT.
#
# 26_rsp_tables.R writes the seven tables to output/tables/ and 25_paper_checks.R asserts that each
# one still appears in PAPER_RSP_v1.md byte-for-byte. Between those two steps the fragments used to
# be pasted by hand, which is the one place in this study where a table could drift by a typo.
# This script does the paste. It finds each table's existing block in the manuscript, from the
# caption line down to the end of the source note, and swaps in the fragment as generated.
#
# Prose is never touched: the block boundaries are the caption and the closing "*" of the source
# note, both of which only the generator writes.
#
# Both manuscript versions carry the same seven tables, so both are targets. --all installs into
# every version present, which is what to run after regenerating the fragments.
#
#   Rscript studies/moral-economy/26_rsp_tables.R      # regenerate the fragments
#   Rscript studies/moral-economy/27_sync_tables.R     # install them into v1
#   Rscript studies/moral-economy/27_sync_tables.R --v2
#   Rscript studies/moral-economy/27_sync_tables.R --all
#   Rscript studies/moral-economy/25_paper_checks.R    # confirm the manuscript reconciles
suppressPackageStartupMessages({ library(here) })
source(here::here("studies/moral-economy/sem_lib.R"))

argv     <- commandArgs(trailingOnly = TRUE)
versions <- if ("--all" %in% argv) c("v1", "v2") else if ("--v2" %in% argv) "v2" else "v1"
PAPERS   <- here::here(sprintf("studies/moral-economy/PAPER_RSP_%s.md", versions))
PAPERS   <- PAPERS[file.exists(PAPERS)]
if (!length(PAPERS)) stop("No manuscript found for version(s): ", paste(versions, collapse = ", "))
TABDIR <- file.path(ME_OUT, "tables")
frags  <- sort(list.files(TABDIR, pattern = "^tab.*\\.md$", full.names = TRUE))
if (!length(frags)) stop("No table fragments in output/tables/; run 26_rsp_tables.R first.")

sync_one <- function(PAPER) {
  txt <- readLines(PAPER, encoding = "UTF-8", warn = FALSE)
  changed <- 0L

  for (f in frags) {
    new <- readLines(f, encoding = "UTF-8", warn = FALSE)
    new <- new[seq_len(max(which(nzchar(trimws(new)))))]      # drop any trailing blank lines
    id  <- sub("^\\*\\*Table ([A-Z]?[0-9]+)\\.\\*\\*.*$", "\\1", new[1])
    if (identical(id, new[1])) stop("Fragment ", basename(f), " has no '**Table N.**' caption.")

    hit <- grep(paste0("^\\*\\*Table ", id, "\\.\\*\\*"), txt)
    if (length(hit) != 1L) stop("Table ", id, " appears ", length(hit), " times in ", basename(PAPER), ".")

    # The block ends at the closing line of the source note that follows the grid.
    src <- hit + which(grepl("^\\*Source:", txt[(hit + 1):length(txt)]))[1]
    end <- src + which(grepl("\\*$", txt[src:length(txt)]))[1] - 1L
    if (is.na(src) || is.na(end)) stop("Could not find the source note closing table ", id, ".")

    if (!identical(txt[hit:end], new)) changed <- changed + 1L
    txt <- append(txt[-(hit:end)], new, after = hit - 1L)
    cat(sprintf("[sync] %s  Table %-2s  %s\n", basename(PAPER), id, basename(f)))
  }

  con <- file(PAPER, open = "wt", encoding = "UTF-8"); writeLines(txt, con); close(con)
  cat(sprintf("%d of %d tables rewritten in %s\n\n", changed, length(frags), basename(PAPER)))
  invisible(changed)
}

for (p in PAPERS) sync_one(p)
