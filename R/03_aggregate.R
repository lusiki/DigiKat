#!/usr/bin/env Rscript
# R/03_aggregate.R — produce the tracked data/processed/*.rds aggregates from the master.
#
# Aggregate production is an EXPLICIT pipeline step, NEVER a render side-effect (CLAUDE.md
# principle 4). This logic was extracted from pages/mapa/mapa.qmd's in-render saveRDS() block.
#
# Run from the REPO ROOT:   Rscript R/03_aggregate.R
# Reads:  data/merged_comprehensive.rds  (master; gitignored)
# Writes: data/processed/{platform_summary, proportions_summary, platform_monthly, source_summary,
#         top_sources_by_year, top_{web,youtube,facebook}_sources, {web,youtube,facebook}_actors}.rds
#
# Scope: corpus span 2021–2026, ALL source types present in the master
#        (web, youtube, facebook, twitter, reddit, forum, instagram, comment, tiktok).
#
# HARD GATE: this OVERWRITES the 10 tracked data/processed/*.rds. The tracked versions are the
# git backup (restore with `git checkout -- data/processed/`). Confirm before running.

suppressPackageStartupMessages(library(dplyr))

master_path   <- "data/merged_comprehensive.rds"
processed_dir <- "data/processed"
year_min      <- 2021L
year_max      <- 2026L
source_levels <- c("web", "youtube", "facebook", "twitter", "reddit",
                   "forum", "instagram", "comment", "tiktok")

stopifnot(file.exists(master_path))
dir.create(processed_dir, showWarnings = FALSE, recursive = TRUE)

message("Reading master: ", master_path, " …")
dta <- readRDS(master_path)
message("  master rows: ", nrow(dta), " | cols: ", ncol(dta))

dta <- dta %>%
  mutate(SOURCE_TYPE = factor(SOURCE_TYPE, levels = source_levels)) %>%
  filter(!is.na(SOURCE_TYPE)) %>%
  filter(DATE >= as.Date(sprintf("%d-01-01", year_min)) &
         DATE <= as.Date(sprintf("%d-12-31", year_max))) %>%
  filter(year >= year_min & year <= year_max)

message("  rows after filter (", year_min, "-", year_max, ", valid SOURCE_TYPE): ", nrow(dta))
message("  source types present: ",
        paste(levels(droplevels(dta$SOURCE_TYPE)), collapse = ", "))

# 1. platform_summary --------------------------------------------------------
platform_summary <- dta %>%
  group_by(year, SOURCE_TYPE) %>%
  summarise(
    total_posts        = n(),
    total_interactions = sum(INTERACTIONS, na.rm = TRUE),
    total_reach        = sum(REACH, na.rm = TRUE),
    .groups = "drop"
  )
saveRDS(platform_summary, file.path(processed_dir, "platform_summary.rds"))

# 2. proportions_summary -----------------------------------------------------
proportions_summary <- platform_summary %>%
  group_by(year) %>%
  mutate(
    post_share        = total_posts / sum(total_posts),
    interaction_share = total_interactions / sum(total_interactions),
    reach_share       = total_reach / sum(total_reach)
  ) %>%
  ungroup()
saveRDS(proportions_summary, file.path(processed_dir, "proportions_summary.rds"))

# 2b. platform_monthly (year-month × SOURCE_TYPE) ----------------------------
# Monthly rollup for the longitudinal map (pages/mapa/evolucija.qmd) — enables the
# annual-rhythm/seasonality view. NB: master DATE is a CHARACTER ISO date ("YYYY-MM-DD"),
# NOT a Date object — so floor to month via the "YYYY-MM" prefix (format(DATE, ...) on a
# character vector would misread the pattern as `trim=` and error). Surgical by design:
# this does NOT touch the shared `dta`, so the 10 existing aggregates are unchanged.
# Page only READS this; never written at render time.
platform_monthly <- dta %>%
  mutate(month = as.Date(paste0(substr(DATE, 1, 7), "-01"))) %>%
  group_by(month, SOURCE_TYPE) %>%
  summarise(
    total_posts        = n(),
    total_interactions = sum(INTERACTIONS, na.rm = TRUE),
    total_reach        = sum(REACH, na.rm = TRUE),
    .groups = "drop"
  )
saveRDS(platform_monthly, file.path(processed_dir, "platform_monthly.rds"))

# 3. source_summary & top_sources_by_year ------------------------------------
source_summary <- dta %>%
  filter(!is.na(FROM)) %>%
  group_by(year, FROM) %>%
  summarise(
    productivity        = n(),
    total_interactions  = sum(INTERACTIONS, na.rm = TRUE),
    avg_engagement_rate = mean(ENGAGEMENT_RATE, na.rm = TRUE),
    total_reach         = sum(REACH, na.rm = TRUE),
    .groups = "drop"
  )
saveRDS(source_summary, file.path(processed_dir, "source_summary.rds"))

top_sources_by_year <- source_summary %>%
  group_by(year) %>%
  slice_max(order_by = total_interactions, n = 15) %>%
  ungroup()
saveRDS(top_sources_by_year, file.path(processed_dir, "top_sources_by_year.rds"))

# 4. top_XX_sources for web/youtube/facebook ---------------------------------
for (pl in c("web", "youtube", "facebook")) {
  df <- dta %>%
    filter(SOURCE_TYPE == pl, !is.na(FROM)) %>%
    group_by(FROM) %>%
    summarise(
      total_posts        = n(),
      total_interactions = sum(INTERACTIONS, na.rm = TRUE),
      total_reach        = sum(REACH, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    slice_max(order_by = total_interactions, n = 20)
  saveRDS(df, file.path(processed_dir, sprintf("top_%s_sources.rds", pl)))
}

# 5. web/youtube/facebook actors (top by interactions ∪ top by reach) --------
get_top_actors <- function(data, platform_filter) {
  platform_data <- data %>%
    filter(SOURCE_TYPE == platform_filter & !is.na(FROM)) %>%
    group_by(FROM) %>%
    summarise(
      total_posts        = n(),
      total_interactions = sum(INTERACTIONS, na.rm = TRUE),
      total_reach        = sum(REACH, na.rm = TRUE),
      .groups = "drop"
    )
  top_by_interactions <- slice_max(platform_data, order_by = total_interactions, n = 15)
  top_by_reach        <- slice_max(platform_data, order_by = total_reach, n = 15)
  bind_rows(top_by_interactions, top_by_reach) %>%
    distinct(FROM, .keep_all = TRUE)
}

for (pl in c("web", "youtube", "facebook")) {
  saveRDS(get_top_actors(dta, pl), file.path(processed_dir, sprintf("%s_actors.rds", pl)))
}

message("Done. Wrote 11 aggregates to ", processed_dir, "/")
