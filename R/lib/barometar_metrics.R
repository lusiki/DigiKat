# Pure date/count arithmetic. Input days are source DATE strings, never datetimes.
barometar_periods <- function(start, end, frequency) {
  dates <- seq(as.Date(start), as.Date(end), by = "day")
  monday <- dates - ((as.integer(dates) + 3L) %% 7L)
  if (frequency == "monthly") {
    ids <- format(dates, "%Y-%m")
    starts <- as.Date(paste0(ids, "-01"))
    next_month <- as.Date(format(starts + 32L, "%Y-%m-01"))
    ends <- next_month - 1L
  } else if (frequency == "weekly") {
    year <- format(monday + 3L, "%Y")
    jan4 <- as.Date(paste0(year, "-01-04"))
    week1 <- jan4 - ((as.integer(jan4) + 3L) %% 7L)
    ids <- paste0(year, "-W", sprintf("%02d", as.integer(monday - week1) %/% 7L + 1L))
    starts <- monday
    ends <- monday + 6L
  } else if (frequency == "rolling28") {
    ids <- as.character(dates)
    starts <- dates - 27L
    ends <- dates
  } else stop("Unsupported frequency.")
  rows <- !duplicated(ids)
  data.frame(frequency = frequency, period_id = ids[rows], period_start = as.character(starts[rows]),
    period_end = as.character(ends[rows]), is_complete = starts[rows] >= as.Date(start) & ends[rows] <= as.Date(end),
    stringsAsFactors = FALSE)
}

barometar_indicator_status <- function(observed, calendar, complete, active, panel, n, frequency) {
  if (!calendar || !panel || !n || observed == 0L) return(c(visibility = "unavailable", breadth = "unavailable"))
  coverage <- observed / calendar
  if (frequency == "rolling28") {
    value <- if (observed >= 24L && active / panel >= .9 && complete) "published" else "unavailable"
    return(c(visibility = value, breadth = value))
  }
  visibility_cut <- if (frequency == "weekly") 6/7 else .8
  breadth_cut <- if (frequency == "weekly") 1 else .9
  visibility <- if (coverage < .5) "unavailable" else if (!complete || coverage < visibility_cut) "partial" else "published"
  breadth <- if (active / panel < .9 || coverage < .5) "unavailable" else if (!complete || coverage < breadth_cut) "partial" else "published"
  c(visibility = visibility, breadth = breadth)
}

barometar_compare <- function(current, previous, break_policy = "not_comparable_seam") {
  output <- list(comparison_status = "unavailable", visibility_difference = NA_real_,
    breadth_difference_pp = NA_real_, test_p_value = NA_real_)
  if (is.null(previous) || !nrow(previous)) return(output)
  output$visibility_difference <- current$visibility_per_10000 - previous$visibility_per_10000
  output$breadth_difference_pp <- current$breadth_pct - previous$breadth_pct
  if (current$visibility_status != "published" || previous$visibility_status != "published" ||
      current$breadth_status != "published" || previous$breadth_status != "published") return(output)
  if (current$definition_version != previous$definition_version || current$panel_version != previous$panel_version) {
    output$comparison_status <- "not_comparable_version"
  } else if (previous$period_start < "2024-04-01" && current$period_end >= "2024-04-01" &&
             break_policy != "comparable_bridged") {
    output$comparison_status <- "not_comparable_seam"
  } else if (min(current$matching_articles, previous$matching_articles) < 10L) {
    output$comparison_status <- "too_few_cases"
  } else {
    output$test_p_value <- stats::binom.test(current$matching_articles,
      current$matching_articles + previous$matching_articles,
      p = current$total_articles / (current$total_articles + previous$total_articles))$p.value
    output$comparison_status <- if (output$test_p_value >= .05) "within_noise" else "comparable"
  }
  output
}

# daily: one private row per day/outlet/scope, with N and D. This routine always
# recomputes distinct outlet sets per exact interval; it never sums breadth.
barometar_aggregate_daily <- function(daily, days, panel_ids, versions, frequency, break_policy = "not_comparable_seam") {
  required <- c("day", "outlet_id", "scope", "N", "D")
  if (!all(required %in% names(daily)) || anyNA(daily[required]) ||
      any(daily$N < daily$D | daily$D < 0) || !all(daily$outlet_id %in% panel_ids) ||
      anyDuplicated(daily[c("day", "outlet_id", "scope")])) stop("Invalid private outlet-day facts.")
  if (anyDuplicated(days$day) || anyNA(days$observed)) stop("Invalid day mask.")
  if (any(!daily$day %in% days$day[days$observed])) stop("Facts on unobserved days cannot enter counts.")
  periods <- barometar_periods(min(days$day), max(days$day), frequency)
  P <- length(unique(panel_ids))
  result <- list()
  for (scope in c("siri", "uze")) for (i in seq_len(nrow(periods))) {
    period <- periods[i, , drop = FALSE]
    first <- period$period_start
    last <- period$period_end
    d <- daily[daily$scope == scope & daily$day >= first & daily$day <= last, , drop = FALSE]
    counts <- if (nrow(d)) stats::aggregate(d[c("N", "D")], list(outlet_id = d$outlet_id), sum) else data.frame(outlet_id = character(), N = numeric(), D = numeric())
    observed <- days$day >= first & days$day <= last & days$observed
    calendar <- as.integer(as.Date(last) - as.Date(first)) + 1L
    N <- sum(counts$N)
    D <- sum(counts$D)
    M <- sum(counts$D > 0L)
    active <- sum(counts$N >= if (frequency == "monthly") 5L else 1L)
    status <- barometar_indicator_status(sum(observed), calendar, period$is_complete, active, P, N, frequency)
    balanced <- counts[counts$N >= 20L, , drop = FALSE]
    row <- data.frame(period, scope = scope, visibility_status = status[["visibility"]], breadth_status = status[["breadth"]],
      coverage_days_observed = sum(observed), coverage_days_calendar = calendar,
      backfilled_days = if ("backfilled" %in% names(days)) sum(days$backfilled[days$day >= first & days$day <= last]) else 0L,
      unmanifested_days = sum(days$day >= first & days$day <= last & days$day >= "2026-04-01"),
      total_articles = N, matching_articles = D, panel_outlets = P, panel_active = active, matching_outlets = M,
      visibility_per_10000 = if (status[["visibility"]] == "unavailable") NA_real_ else 1e4 * D/N,
      breadth_pct = if (status[["breadth"]] == "unavailable") NA_real_ else 100 * M/P,
      visibility_balanced = if (nrow(balanced)) mean(1e4 * balanced$D/balanced$N) else NA_real_,
      panel_version = versions$panel_version, definition_version = versions$definition_version,
      release_version = versions$release_version, data_through = max(days$day), stringsAsFactors = FALSE)
    stopifnot(N >= D, P >= M, P >= active)
    if (frequency != "monthly") stopifnot(active >= M)
    result[[length(result) + 1L]] <- row
  }
  result <- do.call(rbind, result)
  result$comparison_period_id <- NA_character_
  result$comparison_status <- "unavailable"
  result$visibility_difference <- result$breadth_difference_pp <- result$test_p_value <- NA_real_
  if (frequency != "rolling28") for (i in seq_len(nrow(result))) {
    target <- if (frequency == "monthly") paste0(as.integer(substr(result$period_id[i], 1L, 4L)) - 1L, substr(result$period_id[i], 5L, 7L)) else {
      d <- as.character(as.Date(result$period_start[i]) - 7L)
      barometar_periods(d, d, "weekly")$period_id
    }
    previous <- result[result$scope == result$scope[i] & result$period_id == target, , drop = FALSE]
    result$comparison_period_id[i] <- target
    comparison <- barometar_compare(result[i, , drop = FALSE], previous, break_policy)
    for (key in names(comparison)) result[[key]][i] <- comparison[[key]]
  }
  result[order(result$scope, result$period_start, method = "radix"), , drop = FALSE]
}
