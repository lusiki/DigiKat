#!/usr/bin/env Rscript
# moral-economy STAGE V (part 2a) — split the blind gold sheet into annotator batches.
#
# The sheet is a CSV whose text fields contain embedded newlines and quotes; an annotator reading it
# line-by-line would mis-align rows and silently code the wrong post. This emits clean, numbered,
# whitespace-collapsed blocks instead — one file per batch, nothing but rid, domain, window and text.
#
# BLINDNESS is enforced here, not just intended: the batch files are built from the blind sheet only,
# and the script refuses to run if that sheet carries any withheld field.
#
#   Rscript studies/moral-economy/09a_annotate_prep.R [--batch=93]
suppressPackageStartupMessages({ library(here) })
source(here::here("studies/moral-economy/sem_lib.R"))

args <- commandArgs(trailingOnly = TRUE)
BATCH <- as.integer(digikat_cli_value(args, "--batch", "93"))

sheet <- read.csv(file.path(ME_PRIVATE, "gold_sheet.csv"), fileEncoding = "UTF-8",
                  stringsAsFactors = FALSE, colClasses = "character")
digikat_require_columns(sheet, c("rid", "domain", "window", "text_800"), "gold sheet")

# structural blindness assertion — the runner must never see any of these
LEAK <- c("stratum", "split", "label", "FROM", "URL", "DATE", "stream", "SOURCE_TYPE",
          "sem_register", "sem_domain_score", "z_econ_minus_doct")
if (any(LEAK %in% names(sheet))) {
  stop("Blind sheet leaks withheld field(s): ", paste(intersect(LEAK, names(sheet)), collapse = ", "),
       call. = FALSE)
}

bdir <- file.path(ME_PRIVATE, "batches")
unlink(bdir, recursive = TRUE); dir.create(bdir, recursive = TRUE, showWarnings = FALSE)

flat <- function(x) gsub("\\s+", " ", trimws(as.character(x)))
n <- nrow(sheet)
groups <- split(seq_len(n), ceiling(seq_len(n) / BATCH))
cat(sprintf("gold sheet: %d posts -> %d batches of <=%d\n", n, length(groups), BATCH))

for (g in names(groups)) {
  ix <- groups[[g]]
  lines <- c(sprintf("# Gold-sample batch %s of %d — %d posts", g, length(groups), length(ix)),
             "", "Code every post. Do not skip. Output one TSV row per post, in this order.", "")
  for (k in seq_along(ix)) {
    i <- ix[k]
    lines <- c(lines,
      sprintf("### POST %d | rid=%s | domain=%s", k, sheet$rid[i], sheet$domain[i]),
      sprintf("WINDOW: %s", flat(sheet$window[i])),
      sprintf("TEXT: %s", flat(sheet$text_800[i])), "")
  }
  writeLines(lines, file.path(bdir, sprintf("batch_%02d.md", as.integer(g))), useBytes = FALSE)
}

# the rid order each annotator must return, so 09b can assert alignment
writeLines(as.character(sheet$rid), file.path(ME_PRIVATE, "gold_rid_order.txt"))
cat(sprintf("batches -> %s\n", bdir))
cat(sprintf("rid order -> %s\n", file.path(ME_PRIVATE, "gold_rid_order.txt")))
