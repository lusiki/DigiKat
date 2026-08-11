#!/usr/bin/env Rscript
# Stage-A SECOND PASS (part 1 of 2): temporal-peaking (signal #2, WITHIN-stream) + actor decomposition (Q2½).
# Reads the corrected slice READ-ONLY; writes only into output/. No NLP needed (that is signal3_affect.R).
#   Signal #2  — is an entity's volume peaked, and does the peak RECUR on a commemorative calendar
#                (site-of-memory) vs a one-off news spike? Computed within each data_source stream, because
#                the streams are time-segregated (2025 = 100% filtered_religious; MEMORY.md) — never across 2024.
#   Q2½ (actors) — WHO activates the memory anchor (Stepinac) vs the present-tense institutions (vjeronauk/škole)?
#                top FROM sources per entity, platform mix, and the Divovi/Megafoni/Graditelji/Specijalizirani quadrant.
suppressPackageStartupMessages({ library(here); library(dplyr); library(stringr); library(ggplot2); library(tidyr) })
source(here::here("studies/catholic-education/study_input.R"), encoding = "UTF-8")

out_dir <- here::here("studies/catholic-education/output")
tab_dir <- file.path(out_dir, "tables"); fig_dir <- file.path(out_dir, "figures")
for (d in c(tab_dir, fig_dir)) if (!dir.exists(d)) dir.create(d, recursive = TRUE)
theme_ok <- tryCatch({ source(here::here("R/theme_digikat.R")); TRUE }, error = function(e) FALSE)
if (!theme_ok) theme_set(theme_minimal(base_size = 12))

slice <- readRDS(file.path(out_dir, "slice.rds"))
catholic_education_assert_slice_current(slice)
coverage <- attr(slice, "corpus_month_coverage")
stream_coverage <- attr(slice, "corpus_month_stream_counts")
if (is.null(coverage) || is.null(stream_coverage)) {
  stop("Slice lacks corpus-month coverage metadata; re-run slice.R.", call. = FALSE)
}
observed_months <- coverage$ym[coverage$observed]
slice$date  <- as.Date(slice$DATE)
slice$month <- as.integer(format(slice$date, "%m"))
slice$ym    <- format(slice$date, "%Y-%m")
KEY <- c("stepinac", "vjeronauk", "katolicka_skola", "odgoj_vrijednosti", "redovi_orders", "rituali", "strossmayer")
pcol <- function(e) paste0("probe_", e)

# ============================ PART 1 — TEMPORAL PEAKING (within-stream) =======================
# peakedness = coefficient of variation of MONTHLY counts within a stream (higher = spikier);
# commemorative recurrence = for the modal peak month-of-year, in how many distinct years is that
# month the entity's own annual maximum (a repeating calendar peak = memory; a one-off = news).
peaking <- do.call(rbind, lapply(KEY, function(e) {
  do.call(rbind, lapply(unique(slice$data_source), function(ds) {
    sub <- slice[slice[[pcol(e)]] %in% TRUE & slice$data_source == ds & !is.na(slice$date), ]
    if (nrow(sub) < 30) return(NULL)
    stream_months <- stream_coverage |>
      filter(data_source == ds, corpus_posts > 0L) |>
      pull(ym)
    calendar <- data.frame(ym = stream_months, stringsAsFactors = FALSE) |>
      mutate(
        y = substr(ym, 1, 4),
        month = as.integer(substr(ym, 6, 7))
      )
    mm <- calendar |>
      left_join(sub |> count(ym), by = "ym") |>
      mutate(n = coalesce(n, 0L))
    cv  <- sd(mm$n) / mean(mm$n)
    moy <- mm |> select(y, month, n)
    peak_by_year <- moy |> group_by(y) |> slice_max(n, n = 1, with_ties = FALSE) |> ungroup()
    modal_peak_month <- as.integer(names(sort(table(peak_by_year$month), decreasing = TRUE))[1])
    recur <- sum(peak_by_year$month == modal_peak_month)   # in how many years is the modal month the annual max
    eligible <- n_distinct(calendar$y[calendar$month == modal_peak_month])
    data.frame(entity = e, stream = ds, n = nrow(sub), n_months = nrow(mm),
               peakedness_cv = round(cv, 2), modal_peak_month = modal_peak_month,
               years_peaking_that_month = recur, n_years = nrow(peak_by_year),
               eligible_years_modal_month = eligible, stringsAsFactors = FALSE)
  }))
}))
write.csv(peaking, file.path(tab_dir, "temporal_peaking_by_entity.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("-- temporal peaking (within-stream) --\n"); print(peaking, row.names = FALSE)

# Stepinac seasonality: month-of-year share (death 10 Feb 1960; beatification 3 Oct 1998). Does Feb/Oct recur?
moy_share <- do.call(rbind, lapply(c("stepinac", "vjeronauk", "odgoj_vrijednosti"), function(e) {
  sub <- slice[slice[[pcol(e)]] %in% TRUE & !is.na(slice$month), ]
  exposure <- data.frame(ym = observed_months, stringsAsFactors = FALSE) |>
    mutate(month = as.integer(substr(ym, 6, 7))) |>
    count(month, name = "observed_periods")
  s <- sub |>
    count(month) |>
    right_join(exposure, by = "month") |>
    mutate(n = coalesce(n, 0L), monthly_rate = n / observed_periods,
           share = monthly_rate / sum(monthly_rate), entity = e)
  s
}))
p_seas <- ggplot(moy_share, aes(x = factor(month), y = share, fill = entity)) +
  geom_col(position = "dodge") +
  scale_x_discrete(labels = c("sij","velj","ožu","tra","svi","lip","srp","kol","ruj","lis","stu","pro")) +
  labs(title = "Sezonalnost po mjesecu u godini — Stepinac vs obrazovne institucije",
       subtitle = "Stepinac vrhunci u veljači (smrt 10.2.1960.) i listopadu (beatifikacija 3.10.1998.) = komemorativni ritam;\ninstitucije prate školsku/političku godinu. Udio objava po mjesecu (svi stream-ovi, indikativno).",
       x = NULL, y = "udio objava", fill = NULL)
ggsave(file.path(fig_dir, "seasonality_month_of_year.png"), p_seas, width = 10, height = 5.5, dpi = 150)

# Stepinac monthly time series, faceted by stream (the peak-structure visual)
st <- slice[slice$probe_stepinac %in% TRUE & !is.na(slice$date), ] |> count(data_source, ym)
st <- stream_coverage |>
  filter(corpus_posts > 0L) |>
  select(data_source, ym) |>
  left_join(st, by = c("data_source", "ym")) |>
  mutate(n = coalesce(n, 0L), date = as.Date(paste0(ym, "-01")))
p_ts <- ggplot(st, aes(x = date, y = n)) + geom_col() +
  facet_wrap(~data_source, scales = "free_x", ncol = 1) +
  labs(title = "Stepinac — mjesečni volumen objava po stream-u prikupljanja",
       subtitle = "Unutar-stream (stream-ovi su vremenski segregirani, MEMORY.md). Ponavljajući godišnji vrhunci = komemoracija.",
       x = NULL, y = "broj objava")
ggsave(file.path(fig_dir, "stepinac_monthly.png"), p_ts, width = 10, height = 6, dpi = 150)

# ============================ PART 2 — ACTOR DECOMPOSITION (Q2½) ==============================
# top FROM sources per key entity (raw actor signal: confessional vs secular is the PI's call — not hard-coded)
top_sources <- do.call(rbind, lapply(KEY, function(e) {
  sub <- slice[slice[[pcol(e)]] %in% TRUE & !is.na(slice$FROM) & slice$FROM != "", ]
  if (!nrow(sub)) return(NULL)
  sub |> count(SOURCE_TYPE, FROM, name = "posts") |> slice_max(posts, n = 12) |> mutate(entity = e)
}))
write.csv(top_sources, file.path(tab_dir, "top_sources_by_entity.csv"), row.names = FALSE, fileEncoding = "UTF-8")

# platform mix per entity (row-normalized share)
pmix <- do.call(rbind, lapply(KEY, function(e) {
  sub <- slice[slice[[pcol(e)]] %in% TRUE, ]
  t <- prop.table(table(sub$SOURCE_TYPE))
  data.frame(entity = e, platform = names(t), share = round(as.numeric(t), 3))
}))
pmix_wide <- tidyr::pivot_wider(pmix, names_from = platform, values_from = share, values_fill = 0)
write.csv(pmix_wide, file.path(tab_dir, "platform_mix_by_entity.csv"), row.names = FALSE, fileEncoding = "UTF-8")
cat("\n-- platform mix per entity (share of posts) --\n"); print(as.data.frame(pmix_wide), row.names = FALSE)

# typology quadrant on WEB actors (dominant platform, 87% of the slice), following mapa.qmd:
# x = total interactions (angažman), y = total reach (doseg), median split; size = volume.
web <- slice[slice$SOURCE_TYPE == "web" & !is.na(slice$FROM) & slice$FROM != "", ]
actors <- web |> group_by(FROM) |>
  summarise(total_posts = n(),
            total_interactions = sum(INTERACTIONS, na.rm = TRUE),
            total_reach = sum(REACH, na.rm = TRUE),
            stepinac_share = mean(probe_stepinac %in% TRUE),
            .groups = "drop") |>
  filter(total_posts >= 50)
mi <- median(actors$total_interactions); mr <- median(actors$total_reach)
actors$typology <- with(actors, ifelse(total_interactions >= mi & total_reach >= mr, "Divovi",
                                 ifelse(total_interactions <  mi & total_reach >= mr, "Megafoni",
                                 ifelse(total_interactions >= mi & total_reach <  mr, "Graditelji zajednica",
                                                                                      "Specijalizirani akteri"))))
write.csv(actors[order(-actors$total_posts), ], file.path(tab_dir, "web_actor_typology.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
cat(sprintf("\n-- web actors (>=50 posts): %d; typology counts --\n", nrow(actors)))
print(table(actors$typology))
cat("\n-- mean Stepinac-share of posts, by actor typology (are memory-anchor carriers a distinct type?) --\n")
print(actors |> group_by(typology) |> summarise(mean_stepinac_share = round(mean(stepinac_share), 3),
                                                 n_actors = n(), .groups = "drop"))

cat("\nsignal2_actors.R done — tables + figures in output/.\n")
