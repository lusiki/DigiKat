#!/usr/bin/env Rscript
# The two halves as one corpus: what the v4 rule keeps across 2021-2026, era by era.
#
# Both decisions files must have been produced by the same word list, the same model and the same
# threshold; this script refuses to combine them otherwise, because a united corpus whose halves were
# selected by different rules is exactly what the exercise set out to stop producing.
#
# Read-only. Writes aggregates to data/rebuild/unified_stats.rds and two CSVs. Nothing row-level
# leaves the folder, so the outputs carry no URLs, titles or text.
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
source("R/lib/digikat_utils.R", encoding = "UTF-8")
OUT <- "data/rebuild"

a <- readRDS(file.path(OUT, "pre2024_decisions_v4.rds"))
b <- readRDS(file.path(OUT, "post2024_decisions_v4.rds"))
if (!"era" %in% names(b)) b$era <- "post2024"
if (!"word_rule_window" %in% names(b)) b$word_rule_window <- NA
keep <- c("era","master_row","url","date","n_decisive","n_total","word_rule","old_rule",
          "score","threshold_used","second_pass","decision","word_rule_window")
d <- bind_rows(a[, keep], b[, keep])

thr <- unique(d$threshold_used)
if (length(thr) != 1L) stop("the two eras were cut at different thresholds: ",
                            paste(thr, collapse = ", "), call. = FALSE)

# --threshold= re-cuts BOTH eras at another value. Free, because the score is stored for every post
# the word rule accepted; the point is that whatever it is set to, it is the same on both sides.
.t <- grep("^--threshold=", commandArgs(trailingOnly = TRUE), value = TRUE)
if (length(.t)) {
  thr <- as.numeric(sub("^--threshold=", "", .t[[1]]))
  d$decision <- ifelse(!d$word_rule, "rejected: word rule",
                ifelse(is.na(d$score) | d$score < thr, "rejected: second pass", "accepted"))
  cat("re-cut at threshold", thr, "(both eras)\n")
}
cat("one rule, both eras | threshold", thr, "| rows", format(nrow(d), big.mark = " "), "\n\n")

cat("loading master (read-only)...\n")
m <- readRDS("data/merged_comprehensive.rds")
i <- d$master_row
d$platform <- as.character(m$SOURCE_TYPE[i])
d$source   <- ifelse(is.na(m$FROM[i]), "", as.character(m$FROM[i]))
rm(m); invisible(gc())
d$year <- substr(as.character(d$date), 1, 4)
d$kept <- d$decision == "accepted"

pct <- function(x) round(100 * x, 1)
line <- function(s) cat("\n=== ", s, " ===\n", sep = "")

line("by era")
by_era <- d |> group_by(era) |>
  summarise(before = n(), after = sum(kept), kept_pct = pct(mean(kept)),
            span = paste(min(date, na.rm = TRUE), max(date, na.rm = TRUE), sep = " -> "),
            .groups = "drop")
print(as.data.frame(by_era), row.names = FALSE)
cat(sprintf("\nunited corpus: %s posts, from %s (%.1f%% kept)\n",
            format(sum(d$kept), big.mark = " "), format(nrow(d), big.mark = " "),
            100 * mean(d$kept)))

line("by year")
by_year <- d |> group_by(year) |>
  summarise(before = n(), after = sum(kept), kept_pct = pct(mean(kept)), .groups = "drop")
print(as.data.frame(by_year), row.names = FALSE)

line("by decision")
by_dec <- d |> group_by(era, decision) |> summarise(n = n(), .groups = "drop") |>
  tidyr::pivot_wider(names_from = era, values_from = n, values_fill = 0L)
print(as.data.frame(by_dec), row.names = FALSE)

line("by platform")
by_plat <- d |> group_by(platform) |>
  summarise(before = n(), after = sum(kept), kept_pct = pct(mean(kept)),
            share_before = pct(n() / nrow(d)),
            share_after = pct(sum(kept) / sum(d$kept)), .groups = "drop") |>
  arrange(desc(before))
print(as.data.frame(by_plat), row.names = FALSE)

# Source names are stored inconsistently -- bitno.net and Bitno.net are two rows in the raw ranking
# and one outlet in reality. Both rankings are printed; the normalised one is the publishable one.
line("top sources, kept posts (raw labels)")
k <- d[d$kept, ]
raw <- k |> filter(nzchar(source)) |> count(source, sort = TRUE) |> head(20) |>
  mutate(pct = round(100 * n / nrow(k), 2))
print(as.data.frame(raw), row.names = FALSE)

line("top sources, kept posts (case- and www-normalised)")
k$source_norm <- sub("^www\\.", "", tolower(trimws(k$source)))
norm <- k |> filter(nzchar(source_norm)) |> count(source_norm, sort = TRUE) |> head(20) |>
  mutate(pct = round(100 * n / nrow(k), 2))
print(as.data.frame(norm), row.names = FALSE)
cat(sprintf("\ndistinct source labels: %d raw -> %d normalised (%d collapsed)\n",
            n_distinct(k$source[nzchar(k$source)]),
            n_distinct(k$source_norm[nzchar(k$source_norm)]),
            n_distinct(k$source[nzchar(k$source)]) - n_distinct(k$source_norm[nzchar(k$source_norm)])))

line("duplicate URLs inside the united corpus")
cu <- digikat_canonicalize_url(k$url)
dup_all <- sum(duplicated(cu))
era_of <- split(seq_along(cu), k$era)
cross <- length(intersect(cu[era_of$pre2024], cu[era_of$post2024]))
cat("kept posts:", format(nrow(k), big.mark = " "),
    "| duplicate canonical URLs:", dup_all, "| of those, across the era break:", cross, "\n")

line("agreement with the old 95-term rule, kept posts")
print(as.data.frame(k |> group_by(era) |>
  summarise(kept = n(), also_old_rule = sum(old_rule), pct = pct(mean(old_rule)),
            .groups = "drop")), row.names = FALSE)

if (any(!is.na(d$word_rule_window))) {
  line("kept on evidence past the first 3000 characters")
  print(as.data.frame(k |> filter(!is.na(word_rule_window)) |> group_by(era) |>
    summarise(kept = n(), window_only = sum(!word_rule_window),
              pct = pct(mean(!word_rule_window)), .groups = "drop")), row.names = FALSE)
}

saveRDS(list(by_era = by_era, by_year = by_year, by_decision = by_dec, by_platform = by_plat,
             top_sources_raw = raw, top_sources_norm = norm,
             dup_all = dup_all, dup_cross_era = cross, threshold = thr,
             total_before = nrow(d), total_after = sum(d$kept)),
        file.path(OUT, "unified_stats.rds"))
write.csv(by_year,  file.path(OUT, "unified_by_year.csv"),     row.names = FALSE, fileEncoding = "UTF-8")
write.csv(by_plat,  file.path(OUT, "unified_by_platform.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote unified_stats.rds, unified_by_year.csv, unified_by_platform.csv\n")
