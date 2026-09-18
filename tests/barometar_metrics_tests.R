source("R/lib/barometar_metrics.R", encoding = "UTF-8")
local({
  iso <- barometar_periods("2021-01-01", "2021-01-10", "weekly")
  stopifnot(identical(iso$period_id, c("2020-W53", "2021-W01")), !iso$is_complete[1L], iso$is_complete[2L])
  iso2 <- barometar_periods("2026-09-01", "2026-09-10", "weekly")
  stopifnot(tail(iso2$period_id, 1L) == "2026-W37", !tail(iso2$is_complete, 1L))
  days <- data.frame(day = as.character(seq(as.Date("2024-01-01"), as.Date("2024-03-31"), by = "day")))
  days$observed <- !startsWith(days$day, "2024-02")
  daily <- expand.grid(day = days$day[days$observed], outlet_id = c("a", "b"), scope = c("siri", "uze"), stringsAsFactors = FALSE)
  daily$N <- 10L
  daily$D <- as.integer(daily$scope == "siri" & daily$outlet_id == "a" & daily$day == "2024-01-01")
  versions <- list(panel_version = "synthetic", definition_version = "synthetic", release_version = "synthetic")
  monthly <- barometar_aggregate_daily(daily, days, c("a", "b"), versions, "monthly")
  stopifnot(all(is.na(monthly$visibility_per_10000[monthly$period_id == "2024-02"])),
    all(monthly$visibility_status[monthly$period_id == "2024-02"] == "unavailable"),
    all(monthly$visibility_per_10000[monthly$period_id == "2024-03"] == 0),
    monthly$matching_outlets[monthly$scope == "siri" & monthly$period_id == "2024-01"] == 1)
  rolling <- barometar_aggregate_daily(daily, days, c("a", "b"), versions, "rolling28")
  stopifnot(rolling$visibility_status[rolling$scope == "siri" & rolling$period_id == "2024-03-24"] == "published",
    rolling$visibility_status[rolling$scope == "siri" & rolling$period_id == "2024-03-23"] == "unavailable")
  # A monthly outlet with one included article contributes M but not P_t.
  sparse <- daily[daily$day == "2024-01-01", ]
  sparse$N <- 1L
  low <- barometar_aggregate_daily(sparse, days, c("a", "b"), versions, "monthly")
  stopifnot(low$matching_outlets[1L] == 1L, low$panel_active[1L] == 0L, is.na(low$breadth_pct[1L]))
  cat("Barometer metrics: ISO boundaries, zero/missing, exact periods, rolling28 and active-panel checks passed.\n")
})
