#!/usr/bin/env Rscript
# 09_sync_tables.R — install the generated table fragments into the manuscript.
#
# 08_tables.R writes the tables to output/tables/ and 10_paper_checks.R asserts that each
# one still appears in the manuscript byte for byte. This script does the pasting, so no
# table is ever edited by hand and a regenerated number cannot fail to reach the paper.
#
# On the first run each table is placed at its marker, a line reading <!-- TABLE n -->.
# After that the marker is gone and the script finds the installed block instead, from the
# caption line down to the closing asterisk of the source note. Both of those lines are
# written only by the generator, so prose is never touched.
#
#   Rscript studies/inflation-salience/08_tables.R
#   Rscript studies/inflation-salience/09_sync_tables.R
#   Rscript studies/inflation-salience/10_paper_checks.R

source("studies/inflation-salience/_lib.R")

argv <- commandArgs(trailingOnly = TRUE)
V2 <- "--v2" %in% argv
PAPER <- file.path(STUDY, if (V2) "PAPER_EMIP_v2.md" else "PAPER_EMIP_v1.md")
if (!file.exists(PAPER)) stop("no manuscript at ", PAPER)

frags <- sort(list.files(TABLES, pattern = "^tab[0-9]+_.*\\.md$", full.names = TRUE))
tab_no <- as.integer(sub("^tab([0-9]+)_.*$", "\\1", basename(frags)))
frags <- frags[tab_no <= if (V2) 9L else 7L]
if (!length(frags)) stop("no table fragments in ", TABLES, "; run 08_tables.R first")

rule("09_sync_tables.R")
txt <- readLines(PAPER, encoding = "UTF-8", warn = FALSE)
changed <- 0L

for (f in frags) {
  new <- readLines(f, encoding = "UTF-8", warn = FALSE)
  new <- new[seq_len(max(which(nzchar(trimws(new)))))]
  n   <- sub("^tab([0-9]+)_.*$", "\\1", basename(f))

  cap <- grep(paste0("^\\*\\*Table ", n, "\\."), txt)
  mrk <- grep(paste0("^<!-- TABLE ", n, " -->$"), txt)

  if (length(cap) == 1L) {
    src <- cap + which(grepl("^\\*Source:", txt[(cap + 1):length(txt)]))[1]
    end <- src + which(grepl("\\*$", txt[src:length(txt)]))[1] - 1L
    if (is.na(src) || is.na(end)) stop("cannot find the source note closing Table ", n)
    if (!identical(txt[cap:end], new)) changed <- changed + 1L
    txt <- append(txt[-(cap:end)], new, after = cap - 1L)
    msg("  Table ", n, "  replaced in place  <- ", basename(f))
  } else if (length(mrk) == 1L) {
    txt <- append(txt[-mrk], new, after = mrk - 1L)
    changed <- changed + 1L
    msg("  Table ", n, "  installed at marker <- ", basename(f))
  } else {
    stop("Table ", n, ": found ", length(cap), " captions and ", length(mrk),
         " markers in the manuscript; expected exactly one of the two")
  }
}

con <- file(PAPER, open = "wt", encoding = "UTF-8"); writeLines(txt, con); close(con)
msg("\n", changed, " of ", length(frags), " tables rewritten in ", basename(PAPER))
msg("\ndone.")
