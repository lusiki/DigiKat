# Testable metric helpers for the public "Moj medij" aggregate.

digikat_top_n_interaction_share <- function(interactions, n = 10L) {
  interactions <- as.numeric(interactions)
  total <- sum(interactions, na.rm = TRUE)
  if (!is.finite(total) || total <= 0) return(NA_real_)
  100 * sum(sort(interactions[is.finite(interactions)], decreasing = TRUE)[seq_len(
    min(as.integer(n), sum(is.finite(interactions)))
  )], na.rm = TRUE) / total
}

digikat_zero_interaction_rate <- function(interactions) {
  interactions <- as.numeric(interactions)
  measured <- is.finite(interactions)
  if (!any(measured)) return(NA_real_)
  100 * mean(interactions[measured] == 0)
}

digikat_attention_metrics <- function(data) {
  required <- c("FROM", "SOURCE_TYPE", "INTERACTIONS")
  missing <- setdiff(required, names(data))
  if (length(missing)) stop("Attention input is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  data |>
    dplyr::group_by(FROM, SOURCE_TYPE) |>
    dplyr::summarise(
      posts = dplyr::n(),
      measured_posts = sum(is.finite(as.numeric(INTERACTIONS))),
      top10_share = digikat_top_n_interaction_share(INTERACTIONS),
      zero_rate = digikat_zero_interaction_rate(INTERACTIONS),
      .groups = "drop"
    )
}

digikat_attention_peer_medians <- function(metrics, min_peer_posts = 100L) {
  peer_median <- function(x) if (any(is.finite(x))) stats::median(x[is.finite(x)]) else NA_real_
  peers <- metrics[metrics$posts >= as.integer(min_peer_posts), , drop = FALSE] |>
    dplyr::group_by(SOURCE_TYPE) |>
    dplyr::summarise(
      peer_top10 = peer_median(top10_share),
      peer_zero = peer_median(zero_rate),
      peer_top10_n = sum(is.finite(top10_share)),
      peer_zero_n = sum(is.finite(zero_rate)),
      .groups = "drop"
    )
  dplyr::left_join(metrics, peers, by = "SOURCE_TYPE")
}

DIGIKAT_TIME_BANDS <- data.frame(
  band = 1:6,
  start_hour = c(0L, 6L, 10L, 14L, 18L, 22L),
  end_hour = c(5L, 9L, 13L, 17L, 21L, 23L),
  label = c("00–05", "06–09", "10–13", "14–17", "18–21", "22–23"),
  stringsAsFactors = FALSE
)

digikat_time_band <- function(hour) {
  hour <- as.integer(hour)
  out <- rep(NA_integer_, length(hour))
  for (i in seq_len(nrow(DIGIKAT_TIME_BANDS))) {
    out[hour >= DIGIKAT_TIME_BANDS$start_hour[[i]] &
          hour <= DIGIKAT_TIME_BANDS$end_hour[[i]]] <- DIGIKAT_TIME_BANDS$band[[i]]
  }
  out
}

digikat_audit_vendor_time <- function(data) {
  required <- c("DATE", "TIME", "SOURCE_TYPE")
  missing <- setdiff(required, names(data))
  if (length(missing)) stop("TIME audit input is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  time <- trimws(as.character(data$TIME))
  missing_time <- is.na(data$TIME) | !nzchar(time)
  format_ok <- !missing_time & grepl("^[0-9]{2}:[0-9]{2}:[0-9]{2}$", time)
  hour <- suppressWarnings(as.integer(substr(time, 1L, 2L)))
  minute <- suppressWarnings(as.integer(substr(time, 4L, 5L)))
  second <- suppressWarnings(as.integer(substr(time, 7L, 8L)))
  range_ok <- format_ok & hour >= 0L & hour <= 23L & minute >= 0L & minute <= 59L &
    second >= 0L & second <= 59L

  snowflake_n <- 0L
  zagreb_match_pct <- NA_real_
  if ("URL" %in% names(data)) {
    url <- as.character(data$URL)
    id <- sub(".*[/]status(?:es)?[/]([0-9]{15,20}).*", "\\1", url, perl = TRUE)
    snowflake <- as.character(data$SOURCE_TYPE) == "twitter" & grepl("^[0-9]{15,20}$", id)
    if (any(snowflake)) {
      snowflake_ms <- floor(as.numeric(id[snowflake]) / 4194304) + 1288834974657
      vendor_as_utc_ms <- as.numeric(as.POSIXct(
        paste(data$DATE[snowflake], time[snowflake]), tz = "UTC", format = "%Y-%m-%d %H:%M:%S"
      )) * 1000
      difference_hours <- (vendor_as_utc_ms - snowflake_ms) / 3600000
      instant <- as.POSIXct(snowflake_ms / 1000, origin = "1970-01-01", tz = "UTC")
      offset <- format(instant, tz = "Europe/Zagreb", format = "%z")
      offset_hours <- as.numeric(substr(offset, 1L, 3L)) + as.numeric(substr(offset, 4L, 5L)) / 60
      usable <- is.finite(difference_hours) & is.finite(offset_hours) & abs(difference_hours) < 48
      snowflake_n <- sum(usable)
      if (snowflake_n) {
        zagreb_match_pct <- 100 * mean(abs(difference_hours[usable] - offset_hours[usable]) <= 5 / 60)
      }
    }
  }

  list(
    rows = nrow(data),
    missing_pct = 100 * mean(missing_time),
    valid_pct = 100 * mean(range_ok),
    distinct_times = length(unique(time[range_ok])),
    second_precision_pct = 100 * mean(second[range_ok] != 0L),
    timezone = if (is.finite(zagreb_match_pct) && zagreb_match_pct >= 95) "Europe/Zagreb" else NA_character_,
    twitter_snowflakes = as.integer(snowflake_n),
    zagreb_match_pct = zagreb_match_pct,
    reliable = mean(range_ok) >= 0.99 && mean(missing_time) <= 0.01 &&
      snowflake_n >= 100L && is.finite(zagreb_match_pct) && zagreb_match_pct >= 95
  )
}

digikat_rhythm_cells <- function(data, min_cell_posts = 20L) {
  required <- c("FROM", "SOURCE_TYPE", "DATE", "TIME", "INTERACTIONS")
  missing <- setdiff(required, names(data))
  if (length(missing)) stop("Rhythm input is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  date <- as.Date(data$DATE)
  hour <- as.integer(substr(as.character(data$TIME), 1L, 2L))
  data$weekday <- as.integer(format(date, "%u"))
  data$band <- digikat_time_band(hour)
  data |>
    dplyr::filter(!is.na(weekday), !is.na(band)) |>
    dplyr::group_by(FROM, SOURCE_TYPE, weekday, band) |>
    dplyr::summarise(
      posts = dplyr::n(),
      engagement = if (any(is.finite(as.numeric(INTERACTIONS)))) {
        sum(as.numeric(INTERACTIONS), na.rm = TRUE) / dplyr::n()
      } else {
        NA_real_
      },
      .groups = "drop"
    ) |>
    dplyr::filter(posts >= as.integer(min_cell_posts))
}

digikat_rate_ratio <- function(event_posts, event_days, baseline_posts, baseline_days) {
  if (!is.finite(event_posts) || !is.finite(baseline_posts) || event_days <= 0 ||
      baseline_days <= 0 || baseline_posts <= 0) return(NA_real_)
  (event_posts / event_days) / (baseline_posts / baseline_days)
}
