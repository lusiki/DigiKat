#!/usr/bin/env Rscript
# Draw a blind stratified sample from the PRE-2024 output, in the same shape and the same sizes as
# the post-2024 read (100 word-rule rejects, 100 second-step rejects, 50 kept as a control). Same
# protocol and same sample sizes on purpose: the two eras' precision figures are only comparable if
# the measurements behind them are.
#
# Two things this draw does that the post-2024 draw did not need to:
#   1. It excludes every URL that has already been coded in any earlier round. Rounds 1-2 sampled
#      the raw feed, and the pre-2024 master is a subset of that feed, so some of those posts ARE
#      pre-2024 master rows -- and they are exactly the posts the second-pass model was trained on.
#      Scoring the model on its own training items would flatter it.
#   2. The reading pack is blind in both directions: it carries no decision, no score, and no list
#      of which terms fired, because the number of matched terms alone gives the word-rule pile away.
#
# Read-only on the master. Writes to data/rebuild/ (self-ignoring; carries text and URLs).
suppressPackageStartupMessages({library(dplyr); library(jsonlite)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
SEED <- 20260810L; set.seed(SEED)
OUT <- "data/rebuild"; TEXT_CAP <- 3000L        # exactly what the post-2024 coder saw
DRAW <- c(word = 100L, second = 100L, accepted = 50L)
CHUNK <- 50L                                    # readpack is split so it can be read in passes

d <- readRDS(file.path(OUT, "pre2024_decisions_v4.rds"))
cat("decisions:", nrow(d), "| threshold", unique(d$threshold_used), "\n")

## ---- everything already read, in any round ---------------------------------------------------
already <- character(0)
for (p in c("studies/filter-validation/output/private/coded.rds",
            "studies/filter-validation/output/private/holdout_coded.rds",
            "studies/filter-validation/output/private/pre2024_output_coded.rds",
            "studies/filter-validation/output/private/gate2_reject_coded.rds",
            "data/rebuild/discarded_coded.rds")) {
  if (!file.exists(p)) next
  x <- readRDS(p)
  u <- if (is.data.frame(x)) x else x$sample
  if (is.data.frame(u) && "url" %in% names(u)) already <- c(already, as.character(u$url))
}
already <- unique(already)
d$fresh <- !(d$url %in% already)
cat("already-coded URLs:", length(already), "| of them in this era:", sum(!d$fresh), "\n")

cat("loading master (read-only)...\n")
m <- readRDS("data/merged_comprehensive.rds")
i <- d$master_row
d$platform <- as.character(m$SOURCE_TYPE[i])
d$source   <- ifelse(is.na(m$FROM[i]),  "", as.character(m$FROM[i]))
d$title    <- ifelse(is.na(m$TITLE[i]), "", as.character(m$TITLE[i]))
txt        <- as.character(m$FULL_TEXT[i])
rm(m); invisible(gc())
d$nchar <- nchar(txt)

## ---- 1. diagnosis, before anything is read ----------------------------------------------------
cat("\n=== kept, by platform ===\n")
print(as.data.frame(d |> group_by(platform) |>
  summarise(posts = n(), word_rule = round(100 * mean(word_rule), 1),
            kept = round(100 * mean(decision == "accepted"), 1),
            median_chars = median(nchar), .groups = "drop") |>
  arrange(desc(posts))), row.names = FALSE)

cat("\n=== kept, by text length (posts that PASSED the word list) ===\n")
p <- d[d$word_rule, ]
p$band <- cut(p$nchar, c(-1, 300, 600, 1200, 2500, 5000, Inf),
              labels = c("<300", "300-600", "600-1200", "1200-2500", "2500-5000", "5000+"))
print(as.data.frame(p |> group_by(band) |>
  summarise(posts = n(), kept_by_second_step = round(100 * mean(second_pass), 1),
            .groups = "drop")), row.names = FALSE)

## ---- 2. the blind sample ----------------------------------------------------------------------
trim <- function(x, n = TEXT_CAP) {
  x <- as.character(x); x[is.na(x)] <- ""
  ifelse(nchar(x) > n, paste0(substr(x, 1, n), " […]"), x)
}
pick <- function(rows, tag, n) {
  rows <- rows[d$fresh[rows]]
  idx <- sample(rows, min(n, length(rows)))
  data.frame(stratum = tag, origin = d$decision[idx],
             date = d$date[idx], platform = d$platform[idx], source = d$source[idx],
             title = d$title[idx], url = d$url[idx], text = trim(txt[idx]),
             match_count = d$n_total[idx], n_decisive = d$n_decisive[idx],
             score = d$score[idx], nchar = d$nchar[idx],
             stringsAsFactors = FALSE)
}
all <- bind_rows(
  pick(which(d$decision == "rejected: word rule"),   "R_WORD",   DRAW[["word"]]),
  pick(which(d$decision == "rejected: second pass"), "R_SECOND", DRAW[["second"]]),
  pick(which(d$decision == "accepted"),              "KEPT",     DRAW[["accepted"]])
)
all <- all[sample(nrow(all)), ]                       # blind: the reason is not in reading order
all$id <- sprintf("E%03d", seq_len(nrow(all)))
all$label <- ""; all$note <- ""
all <- all[, c("id","label","note","stratum","origin","date","platform","source","title","url",
               "match_count","n_decisive","score","nchar","text")]

cat("\n=== sample drawn ===\n")
print(as.data.frame(table(all$stratum)), row.names = FALSE)

wr <- function(path, s) { cc <- file(path, open = "wb"); writeBin(charToRaw(enc2utf8(s)), cc); close(cc) }

csv <- file.path(OUT, "pre2024_sample.csv")
wr(csv, paste0("\ufeff", paste(names(all), collapse = ","), "\n",
   paste(apply(all, 1, function(r)
     paste0('"', gsub('"', '""', r, fixed = TRUE), '"', collapse = ",")), collapse = "\n"), "\n"))

# HTML coder, same template as every earlier round, for a human second pass over the same items
tpl <- readLines("studies/filter-validation/coder_template.tpl", encoding = "UTF-8", warn = FALSE)
html <- sub("/*__DATA__*/[]", toJSON(all, dataframe = "rows", auto_unbox = TRUE, na = "string"),
            paste(tpl, collapse = "\n"), fixed = TRUE)
html <- sub("__SAMPLE_ID__", paste0("digikat-pre2024-", SEED), html, fixed = TRUE)
wr(file.path(OUT, "pre2024_coder.html"), html)

# blind reading packs: id, date, platform, source, title, text. Nothing else.
n_chunk <- ceiling(nrow(all) / CHUNK)
for (b in seq_len(n_chunk)) {
  ii <- ((b - 1L) * CHUNK + 1L):min(b * CHUNK, nrow(all))
  lines <- c(sprintf("PRE-2024 CODING PACK %d/%d - items %s..%s", b, n_chunk,
                     all$id[ii[1]], all$id[ii[length(ii)]]),
             "Label each: catholic_clear | catholic_mention | religious_other | not_religious | cannot_tell",
             "", strrep("=", 96), "")
  for (i in ii) {
    lines <- c(lines,
      sprintf("%s | %s | %s | %s", all$id[i], all$date[i], all$platform[i],
              ifelse(nzchar(all$source[i]), all$source[i], "(no source)")),
      sprintf("  TITLE: %s", ifelse(nzchar(all$title[i]), all$title[i], "(none)")),
      sprintf("  TEXT: %s", gsub("[[:space:]]+", " ", all$text[i])),
      "", strrep("-", 96), "")
  }
  wr(file.path(OUT, sprintf("pre2024_pack_%02d.txt", b)), paste(lines, collapse = "\n"))
}

cat("\nwrote", csv, "\nwrote pre2024_coder.html and", n_chunk, "reading packs\n")
cat(sprintf("250 items: 100 rejected by the word list, 100 by the second step, 50 KEPT as control.\n"))
cat(sprintf("Total text to read: %s characters\n", format(sum(nchar(all$text)), big.mark = " ")))
