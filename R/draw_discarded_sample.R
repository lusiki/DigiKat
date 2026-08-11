#!/usr/bin/env Rscript
# 1) Diagnose WHAT KIND of post was discarded — by platform and by length, because the second
#    step's biggest coefficient is on text length and that could be a systematic bias.
# 2) Draw a blind sample of discarded posts so the PI can read them.
#
# Read-only on the master. Writes to data/rebuild/ (self-ignoring; carries text and URLs).
suppressPackageStartupMessages({library(dplyr); library(jsonlite)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
SEED <- 20260810L; set.seed(SEED)
OUT <- "data/rebuild"; TEXT_CAP <- 3000L
DRAW <- c(word = 100L, second = 100L, accepted = 50L)

d <- readRDS(file.path(OUT, "post2024_decisions.rds"))
cat("decisions:", nrow(d), "\n")

cat("loading master (read-only)...\n")
m <- readRDS("data/merged_comprehensive.rds")
i <- d$master_row
d$platform <- as.character(m$SOURCE_TYPE[i])
d$source   <- ifelse(is.na(m$FROM[i]),  "", as.character(m$FROM[i]))
d$title    <- ifelse(is.na(m$TITLE[i]), "", as.character(m$TITLE[i]))
txt        <- as.character(m$FULL_TEXT[i])
rm(m); invisible(gc())
d$nchar <- nchar(txt)

## ---- 1. diagnosis --------------------------------------------------------------------------
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

## ---- 2. the blind sample --------------------------------------------------------------------
trim <- function(x, n = TEXT_CAP) {
  x <- as.character(x); x[is.na(x)] <- ""
  ifelse(nchar(x) > n, paste0(substr(x, 1, n), " […]"), x)
}
pick <- function(rows, tag, n) {
  idx <- sample(rows, min(n, length(rows)))
  data.frame(stratum = tag, origin = d$decision[idx],
             date = d$date[idx], platform = d$platform[idx], source = d$source[idx],
             title = d$title[idx], url = d$url[idx], text = trim(txt[idx]),
             match_count = d$n_total[idx],
             matched_terms = sprintf("odluka: %s · pojmova: %d (odlučnih: %d) · rezultat 2. koraka: %s",
                                     d$decision[idx], d$n_total[idx], d$n_decisive[idx],
                                     ifelse(is.na(d$score[idx]), "—", sprintf("%.3f", d$score[idx]))),
             stringsAsFactors = FALSE)
}
all <- bind_rows(
  pick(which(d$decision == "rejected: word rule"),   "R_WORD",   DRAW[["word"]]),
  pick(which(d$decision == "rejected: second pass"), "R_SECOND", DRAW[["second"]]),
  pick(which(d$decision == "accepted"),              "KEPT",     DRAW[["accepted"]])
)
all <- all[sample(nrow(all)), ]                       # blind: reason is hidden behind the reveal
all$id <- sprintf("D%03d", seq_len(nrow(all)))
all$label <- ""; all$note <- ""
all <- all[, c("id","label","note","stratum","origin","date","platform","source","title","url",
               "match_count","matched_terms","text")]

cat("\n=== sample drawn ===\n")
print(as.data.frame(table(all$stratum)), row.names = FALSE)

csv <- file.path(OUT, "discarded_sample.csv")
cc <- file(csv, open = "wb"); writeBin(charToRaw("\ufeff"), cc)
writeBin(charToRaw(enc2utf8(paste0(
  paste(names(all), collapse = ","), "\n",
  paste(apply(all, 1, function(r)
    paste0('"', gsub('"', '""', r, fixed = TRUE), '"', collapse = ",")), collapse = "\n"), "\n"))), cc)
close(cc)

tpl <- readLines("studies/filter-validation/coder_template.tpl", encoding = "UTF-8", warn = FALSE)
html <- sub("/*__DATA__*/[]", toJSON(all, dataframe = "rows", auto_unbox = TRUE, na = "string"),
            paste(tpl, collapse = "\n"), fixed = TRUE)
html <- sub("__SAMPLE_ID__", paste0("digikat-discarded-", SEED), html, fixed = TRUE)
hp <- file.path(OUT, "discarded_coder.html")
ch <- file(hp, open = "wb"); writeBin(charToRaw(enc2utf8(html)), ch); close(ch)
cat("\nwrote", csv, "\nwrote", hp, "\n")
cat("\n250 items: 100 rejected by the word list, 100 rejected by the second step, 50 KEPT as a\n")
cat("control. Shuffled and unlabelled — the reason is hidden behind the same reveal as the terms.\n")
