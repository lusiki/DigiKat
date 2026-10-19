#!/usr/bin/env Rscript
# Draw a blind precision sample from the 2024+ era of the corpus as cut from DetermDB
# (plan 2026-10-18_corpus-extension-to-2026-10-16.md, step 3).
#
#   Rscript R/draw_determ_sample.R --old-corpus=PATH   # the 2026-08-10 corpus, for the strata
#
# The question is how much of what the general feed adds is genuinely Catholic content. So the kept
# 2024+ posts are split in two strata and read blind, in the same coder and with the same five labels
# as every earlier round:
#   NEW   100 kept posts whose canonical URL the 2026-08-10 corpus did not hold (what DetermDB adds)
#   OLD    50 kept posts the 2026-08-10 corpus also held (control: should match the earlier 87,0%)
# Precision for the era is the stratum rates weighted by the strata's sizes, which this script
# records in determ_sample_weights.csv so the scoring step cannot re-weight after reading.
#
# Read-only on both corpora. Writes to data/rebuild/ (self-ignoring; carries text and URLs).
suppressPackageStartupMessages({library(dplyr); library(jsonlite)})
.script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(.script_arg)) {
  setwd(normalizePath(file.path(dirname(sub("^--file=", "", .script_arg[[1]])), ".."),
                      mustWork = TRUE))
}
rm(.script_arg)
source("R/lib/digikat_utils.R", encoding = "UTF-8")
source("R/lib/digikat_paths.R", encoding = "UTF-8")
args <- commandArgs(trailingOnly = TRUE)
OLD  <- digikat_cli_value(args, "--old-corpus", "")
if (!nzchar(OLD) || !file.exists(OLD)) stop("give --old-corpus=PATH to the 2026-08-10 corpus", call. = FALSE)
SEED <- 20261018L; set.seed(SEED)
OUT <- "data/rebuild"; TEXT_CAP <- 3000L
DRAW <- c(NEW = 100L, OLD = 50L)

co <- readRDS(digikat_corpus_path())
co <- co[co$dk_era == "post2024", ]
old_cu <- digikat_canonicalize_url(as.character(readRDS(OLD)$URL))
co$cu <- digikat_canonicalize_url(as.character(co$URL))
co$stratum <- ifelse(co$cu %in% old_cu, "OLD", "NEW")
w <- as.data.frame(table(stratum = co$stratum), stringsAsFactors = FALSE)
names(w)[2] <- "kept_posts"; w$weight <- w$kept_posts / sum(w$kept_posts)
cat("2024+ kept posts by stratum:\n"); print(w, row.names = FALSE)
cat("\nNEW by platform:\n"); print(table(co$SOURCE_TYPE[co$stratum == "NEW"]))

trim <- function(x, n = TEXT_CAP) {
  x <- as.character(x); x[is.na(x)] <- ""
  ifelse(nchar(x) > n, paste0(substr(x, 1, n), " […]"), x)
}
pick <- function(tag) {
  idx <- sample(which(co$stratum == tag), DRAW[[tag]])
  data.frame(stratum = tag, origin = "accepted", date = as.character(co$DATE[idx]),
             platform = as.character(co$SOURCE_TYPE[idx]),
             source = ifelse(is.na(co$FROM[idx]), "", as.character(co$FROM[idx])),
             title = ifelse(is.na(co$TITLE[idx]), "", as.character(co$TITLE[idx])),
             url = as.character(co$URL[idx]), text = trim(co$FULL_TEXT[idx]),
             match_count = co$dk_n_total[idx], n_decisive = co$dk_n_decisive[idx],
             score = co$dk_score[idx], nchar = nchar(as.character(co$FULL_TEXT[idx])),
             stringsAsFactors = FALSE)
}
all <- bind_rows(pick("NEW"), pick("OLD"))
all <- all[sample(nrow(all)), ]                       # blind: stratum is not in reading order
all$id <- sprintf("D%03d", seq_len(nrow(all)))
all$label <- ""; all$note <- ""
all <- all[, c("id","label","note","stratum","origin","date","platform","source","title","url",
               "match_count","n_decisive","score","nchar","text")]

wr <- function(path, s) { cc <- file(path, open = "wb"); writeBin(charToRaw(enc2utf8(s)), cc); close(cc) }
csv <- file.path(OUT, "determ_sample.csv")
wr(csv, paste0("﻿", paste(names(all), collapse = ","), "\n",
   paste(apply(all, 1, function(r)
     paste0('"', gsub('"', '""', r, fixed = TRUE), '"', collapse = ",")), collapse = "\n"), "\n"))
write.csv(w, file.path(OUT, "determ_sample_weights.csv"), row.names = FALSE, fileEncoding = "UTF-8")

tpl <- readLines("studies/filter-validation/coder_template.tpl", encoding = "UTF-8", warn = FALSE)
html <- sub("/*__DATA__*/[]", toJSON(all, dataframe = "rows", auto_unbox = TRUE, na = "string"),
            paste(tpl, collapse = "\n"), fixed = TRUE)
html <- sub("__SAMPLE_ID__", paste0("digikat-determ2024-", SEED), html, fixed = TRUE)
wr(file.path(OUT, "determ_coder.html"), html)
cat("\nwrote", csv, "and data/rebuild/determ_coder.html -", nrow(all), "items,",
    format(sum(nchar(all$text)), big.mark = " "), "characters to read\n")
