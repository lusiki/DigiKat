#!/usr/bin/env Rscript
# Build disclosure-safe aggregate CSV downloads for the five analytical maps.
# This is an explicit production step. It does not alter data/ or recompute the
# analytical inputs used by the published pages.

source("R/lib/digikat_charts.R", encoding = "UTF-8")

out_dir <- file.path("assets", "downloads", "maps")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

write_chart <- function(slug, x) {
  digikat_write_chart_csv(x, file.path(out_dir, paste0(slug, ".csv")))
}

read_processed <- function(name) readRDS(file.path("data", "processed", paste0(name, ".rds")))
read_page <- function(name) readRDS(file.path("data", "page-ready", paste0(name, ".rds")))$objects

platform_summary <- read_processed("platform_summary")
proportions_summary <- read_processed("proportions_summary")
platform_monthly <- read_processed("platform_monthly")
source_summary <- read_processed("source_summary")

write_chart("mapa-platform-volume", platform_summary[c("year", "SOURCE_TYPE", "total_posts")])
write_chart(
  "mapa-platform-interactions",
  subset(platform_summary, total_interactions > 0,
         select = c("year", "SOURCE_TYPE", "total_interactions"))
)
write_chart(
  "mapa-platform-shares",
  proportions_summary[c(
    "year", "SOURCE_TYPE", "post_share", "interaction_share", "reach_share"
  )]
)

top_sources <- do.call(rbind, lapply(c("web", "youtube", "facebook"), function(platform) {
  x <- read_processed(paste0("top_", platform, "_sources"))
  x$platform <- platform
  x[c("platform", "FROM", "total_posts", "total_interactions", "total_reach")]
}))
row.names(top_sources) <- NULL
write_chart("mapa-top-sources", top_sources)

actor_map <- do.call(rbind, lapply(c("web", "youtube", "facebook"), function(platform) {
  x <- read_processed(paste0(platform, "_actors"))
  x$platform <- platform
  x[c("platform", "FROM", "total_posts", "total_interactions", "total_reach")]
}))
row.names(actor_map) <- NULL
write_chart("mapa-actor-map", actor_map)

write_chart(
  "evolucija-monthly-volume",
  platform_monthly[c("month", "SOURCE_TYPE", "total_posts")]
)

interaction_shares <- merge(
  expand.grid(
    month = sort(unique(platform_monthly$month)),
    SOURCE_TYPE = sort(unique(platform_monthly$SOURCE_TYPE)),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  ),
  platform_monthly[c("month", "SOURCE_TYPE", "total_interactions")],
  by = c("month", "SOURCE_TYPE"),
  all.x = TRUE,
  sort = TRUE
)
interaction_shares$total_interactions[is.na(interaction_shares$total_interactions)] <- 0
month_totals <- ave(interaction_shares$total_interactions, interaction_shares$month,
                    FUN = function(x) sum(x, na.rm = TRUE))
interaction_shares$interaction_share <- ifelse(
  month_totals > 0,
  interaction_shares$total_interactions / month_totals,
  0
)
write_chart("evolucija-interaction-shares", interaction_shares)

valid_sources <- subset(
  source_summary,
  !is.na(FROM) & !FROM %in% c(".", "anonymous_user") & total_interactions > 0
)
concentration <- do.call(rbind, lapply(split(valid_sources, valid_sources$year), function(x) {
  x <- x[order(x$total_interactions, decreasing = TRUE), , drop = FALSE]
  data.frame(
    year = x$year[[1L]],
    top10_share = sum(utils::head(x$total_interactions, 10L)) / sum(x$total_interactions),
    sources_with_interactions = nrow(x)
  )
}))
row.names(concentration) <- NULL
write_chart("evolucija-concentration", concentration)

monthly <- transform(
  platform_monthly,
  year = as.integer(format(month, "%Y")),
  calendar_month = as.integer(format(month, "%m"))
)
coverage <- aggregate(calendar_month ~ year, unique(monthly[c("year", "calendar_month")]), length)
names(coverage)[2L] <- "n_months"
complete_years <- coverage$year[coverage$n_months == 12L]
rhythm_by_year <- aggregate(
  total_posts ~ year + calendar_month,
  subset(monthly, year %in% complete_years),
  sum
)
rhythm <- aggregate(total_posts ~ calendar_month, rhythm_by_year, mean)
names(rhythm)[2L] <- "average_posts"
write_chart("evolucija-annual-rhythm", rhythm)

topics <- read_page("mapa_stats")
top_words <- topics$word_freq_for_cloud[order(topics$word_freq_for_cloud$n, decreasing = TRUE), ]
write_chart("teme-top-terms", utils::head(top_words, 25L))
write_chart("teme-topic-trends", topics$topic_trends_guided)

intensity_summary <- do.call(rbind, lapply(split(topics$thematic_intensity_data$intensity,
                                                topics$thematic_intensity_data$topic), function(x) {
  q <- stats::quantile(x, c(0.1, 0.25, 0.5, 0.75, 0.9), na.rm = TRUE, names = FALSE)
  data.frame(n = sum(is.finite(x)), p10 = q[[1L]], p25 = q[[2L]], median = q[[3L]],
             p75 = q[[4L]], p90 = q[[5L]])
}))
intensity_summary$topic <- row.names(intensity_summary)
row.names(intensity_summary) <- NULL
intensity_summary <- intensity_summary[c("topic", "n", "p10", "p25", "median", "p75", "p90")]
write_chart("teme-topic-intensity", intensity_summary)
write_chart("teme-topic-interactions", topics$engagement_by_topic)
write_chart("teme-facebook-reactions", topics$polarization_by_topic)
write_chart("teme-actors", topics$top_actors_in_top_topics)
write_chart("teme-network", topics$topic_pairs)

discourse <- read_page("diskurs")
write_chart("diskurs-emotion-tonality", discourse$heatmap_data)
write_chart("diskurs-source-conflict", discourse$media_strategy_data)
write_chart("diskurs-topic-network", discourse$graph_data)

events <- read_page("dogadjaji")
write_chart(
  "dogadjaji-volume-anomalies",
  events$spikes_detected_z[c("date", "year", "n_articles", "z_score_volume", "is_volume_spike")]
)
write_chart(
  "dogadjaji-conflict-anomalies",
  events$spikes_detected_z[c("date", "year", "avg_cli", "z_score_cli", "is_cli_spike")]
)
write_chart("dogadjaji-easter-window", events$daily_duhovnost_dynamics)
write_chart("dogadjaji-stepinac-terms", events$top_associated_words_final)

expected <- c(
  "mapa-platform-volume", "mapa-platform-interactions", "mapa-platform-shares",
  "mapa-top-sources", "mapa-actor-map", "evolucija-monthly-volume",
  "evolucija-interaction-shares", "evolucija-concentration", "evolucija-annual-rhythm",
  "teme-top-terms", "teme-topic-trends", "teme-topic-intensity",
  "teme-topic-interactions", "teme-facebook-reactions", "teme-actors", "teme-network",
  "diskurs-emotion-tonality", "diskurs-source-conflict", "diskurs-topic-network",
  "dogadjaji-volume-anomalies", "dogadjaji-conflict-anomalies",
  "dogadjaji-easter-window", "dogadjaji-stepinac-terms"
)

paths <- file.path(out_dir, paste0(expected, ".csv"))
if (!all(file.exists(paths))) stop("One or more expected map downloads were not built.", call. = FALSE)

manifest <- data.frame(
  file = basename(paths),
  bytes = unname(file.info(paths)$size),
  rows = vapply(paths, function(path) nrow(utils::read.csv(path, check.names = FALSE)), integer(1L)),
  stringsAsFactors = FALSE
)
utils::write.csv(manifest, file.path(out_dir, "manifest.csv"), row.names = FALSE,
                 fileEncoding = "UTF-8")

cat("Built ", length(paths), " disclosure-safe map downloads in ", out_dir, ".\n", sep = "")
