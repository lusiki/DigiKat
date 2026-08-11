#!/usr/bin/env Rscript
# Descriptive portrait of the cleaned corpus: size, shape over time, platforms, outlets, reach.
#
#   Rscript R/describe_corpus.R [--threshold=0.8]
#
# Both eras are cut at the SAME threshold, whatever it is set to — that is the point of the
# exercise. Read-only. Writes aggregates only (no URLs, titles or post text) to
# data/rebuild/descriptive_<thr>.rds so a report can be built from them.
suppressPackageStartupMessages({library(dplyr)})
setwd("c:/Users/lsikic/Dropbox/HKS/Projekti/Digitalni Kat/SHKM/DigiKat")
OUT <- "data/rebuild"

.t <- grep("^--threshold=", commandArgs(trailingOnly = TRUE), value = TRUE)
THR <- if (length(.t)) as.numeric(sub("^--threshold=", "", .t[[1]])) else 0.80
cat("threshold:", THR, "(applied to both eras)\n")

a <- readRDS(file.path(OUT, "pre2024_decisions_v4.rds"))
b <- readRDS(file.path(OUT, "post2024_decisions_v4.rds"))
if (!"era" %in% names(b)) b$era <- "post2024"
if (!"era" %in% names(a)) a$era <- "pre2024"
keep <- c("era","master_row","url","date","n_decisive","n_total","word_rule","old_rule","score")
d <- bind_rows(a[, keep], b[, keep])
d$accepted <- d$word_rule & !is.na(d$score) & d$score >= THR
cat("rows:", format(nrow(d), big.mark=" "), "| accepted:", format(sum(d$accepted), big.mark=" "),
    sprintf("(%.1f%%)\n", 100*mean(d$accepted)))

cat("loading master (read-only)...\n")
m <- readRDS("data/merged_comprehensive.rds")
i <- d$master_row
d$platform <- as.character(m$SOURCE_TYPE[i])
d$source   <- ifelse(is.na(m$FROM[i]), "(nepoznato)", as.character(m$FROM[i]))
d$reach    <- suppressWarnings(as.numeric(m$REACH[i]))
d$inter    <- suppressWarnings(as.numeric(m$INTERACTIONS[i]))
d$nchar    <- nchar(as.character(m$FULL_TEXT[i]))
rm(m); invisible(gc())

d$date <- as.Date(substr(d$date, 1, 10))
d$year <- format(d$date, "%Y")
d$ym   <- format(d$date, "%Y-%m")
k <- d[d$accepted, ]

norm <- function(x) {
  x <- tolower(trimws(x))
  x <- sub("^www\\.", "", x)
  x <- sub("\\s+$", "", x)
  x
}
k$source_norm <- norm(k$source)

res <- list()
res$threshold   <- THR
res$total_before<- nrow(d)
res$total_after <- nrow(k)
res$span        <- range(k$date, na.rm = TRUE)

res$by_era <- d %>% group_by(era) %>%
  summarise(before = n(), after = sum(accepted), kept_pct = round(100*mean(accepted),1),
            from = min(date, na.rm=TRUE), to = max(date, na.rm=TRUE), .groups="drop")

res$by_year <- d %>% group_by(year) %>%
  summarise(before = n(), after = sum(accepted), kept_pct = round(100*mean(accepted),1),
            .groups="drop") %>% filter(!is.na(year))

res$by_month <- k %>% count(ym) %>% filter(!is.na(ym)) %>% arrange(ym)

res$by_platform <- d %>% group_by(platform) %>%
  summarise(before=n(), after=sum(accepted), kept_pct=round(100*mean(accepted),1), .groups="drop") %>%
  mutate(share_before = round(100*before/sum(before),1),
         share_after  = round(100*after/sum(after),1)) %>% arrange(desc(after))

res$platform_by_year <- k %>% count(year, platform) %>% group_by(year) %>%
  mutate(share = round(100*n/sum(n),1)) %>% ungroup() %>% filter(!is.na(year))

res$top_sources <- k %>% count(source_norm, sort=TRUE) %>% head(25) %>%
  mutate(pct = round(100*n/nrow(k),2))

res$sources_by_era <- k %>% count(era, source_norm) %>% group_by(era) %>%
  slice_max(n, n = 12) %>% mutate(pct = round(100*n/sum(k$era==era[1]),2)) %>% ungroup()

nsrc <- k %>% count(source_norm, sort=TRUE)
res$n_sources    <- nrow(nsrc)
res$top10_share  <- round(100*sum(head(nsrc$n,10))/nrow(k),1)
res$top50_share  <- round(100*sum(head(nsrc$n,50))/nrow(k),1)
res$one_post_src <- sum(nsrc$n == 1)

res$evidence <- k %>% mutate(band = pmin(n_decisive, 6L)) %>% count(band) %>%
  mutate(pct = round(100*n/sum(n),1))
res$old_rule_share <- round(100*mean(k$old_rule), 1)
res$old_rule_by_era <- k %>% group_by(era) %>%
  summarise(pct_old_rule = round(100*mean(old_rule),1), .groups="drop")

res$len_median <- k %>% group_by(platform) %>%
  summarise(median_chars = median(nchar, na.rm=TRUE), .groups="drop") %>% arrange(desc(median_chars))

res$reach <- k %>% filter(is.finite(reach), reach > 0) %>%
  summarise(n_with_reach = n(), median = median(reach), total = sum(reach))
res$reach_by_platform <- k %>% filter(is.finite(reach), reach>0) %>% group_by(platform) %>%
  summarise(n = n(), median_reach = round(median(reach)), total_reach = sum(reach), .groups="drop") %>%
  arrange(desc(total_reach))

res$dupes <- sum(duplicated(k$url[!is.na(k$url)]))

saveRDS(res, file.path(OUT, sprintf("descriptive_%02d.rds", round(100*THR))))
for (nm in setdiff(names(res), c("by_month","platform_by_year","sources_by_era"))) {
  cat("\n===", nm, "===\n"); print(as.data.frame(res[[nm]]), row.names = FALSE)
}
cat("\n=== months:", nrow(res$by_month), "| first/last:", res$by_month$ym[1],
    tail(res$by_month$ym,1), "===\n")
print(as.data.frame(head(res$by_month, 6)), row.names = FALSE)
cat("\nwrote", file.path(OUT, sprintf("descriptive_%02d.rds", round(100*THR))), "\n")
