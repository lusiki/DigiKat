source("studies/demokrscanstvo-barometar/lib/io.R", encoding = "UTF-8")

barometar_membership_months <- function(data_through, excluded_months = c("2024-01", "2024-02", "2024-03")) {
  # Calendar arithmetic only; article day assignment always uses the original DATE string.
  cutoff <- as.Date(data_through)
  month_start <- as.Date(paste0(substr(data_through, 1L, 7L), "-01"))
  last_day <- seq(month_start, by = "month", length.out = 2L)[2L] - 1L
  last_complete <- if (cutoff == last_day) month_start else seq(month_start, by = "-1 month", length.out = 2L)[2L]
  months <- format(seq(as.Date("2021-01-01"), last_complete, by = "month"), "%Y-%m")
  setdiff(months, excluded_months)
}

barometar_outlet_inventory <- function(con = NULL, readiness = NULL, workdir = NULL) {
  workdir <- barometar_workdir(workdir)
  own_connection <- is.null(con)
  if (own_connection) con <- barometar_connect_readonly()
  if (own_connection) on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  snapshot <- barometar_source_snapshot(con)
  table <- barometar_table_sql(con)
  if (is.null(readiness)) {
    cutoff <- DBI::dbGetQuery(con, paste0('SELECT MAX("DATE") AS data_through FROM ', table,
      " WHERE SOURCE_TYPE = 'web'"))$data_through[[1L]]
  } else cutoff <- readiness$data_through
  months <- barometar_membership_months(cutoff)
  monthly <- DBI::dbGetQuery(con, paste0(
    'SELECT lower("FROM") AS from_value, substr("DATE",1,7) AS month, SOURCE_BATCH AS source_batch, ',
    'COUNT(*) AS raw_rows, COUNT(FULL_TEXT) AS text_rows FROM ', table,
    ' WHERE SOURCE_TYPE = \'web\' AND "DATE" >= \'2021-01-01\' GROUP BY 1,2,3 ORDER BY 1,2,3'))
  monthly$raw_rows <- as.numeric(monthly$raw_rows)
  monthly$text_rows <- as.numeric(monthly$text_rows)
  dt <- data.table::as.data.table(monthly)
  by_month <- dt[, .(raw_rows = sum(raw_rows)), by = .(from_value, month)]
  continuity <- by_month[month %in% months, .(months_present = data.table::uniqueN(month),
    min_raw_rows = min(raw_rows), raw_rows = sum(raw_rows)), by = from_value]
  continuity$window_months <- length(months)
  continuity$raw_continuity_1 <- continuity$months_present == length(months) & continuity$min_raw_rows >= 1
  continuity$raw_continuity_20 <- continuity$months_present == length(months) & continuity$min_raw_rows >= 20
  data.table::setorder(continuity, from_value)
  hosts <- DBI::dbGetQuery(con, paste0(
    'SELECT lower("FROM") AS from_value, ',
    "lower(regexp_extract(URL, '^(?:[A-Za-z][A-Za-z0-9+.-]*://)?([^/?#]+)', 1)) AS url_host, ",
    'COUNT(*) AS raw_rows FROM ', table, ' WHERE SOURCE_TYPE = \'web\' ',
    'AND "DATE" >= \'2021-01-01\' GROUP BY 1,2 ORDER BY 1,2'))
  hosts$raw_rows <- as.numeric(hosts$raw_rows)
  result <- list(data_through = cutoff, snapshot = snapshot, membership_months = months, monthly = monthly,
    continuity = as.data.frame(continuity), hosts = hosts,
    candidate_from_values = continuity$from_value[continuity$raw_continuity_20],
    review_from_values = continuity$from_value[continuity$raw_continuity_1])
  barometar_assert_snapshot(snapshot, con)
  barometar_write_csv(monthly, file.path(workdir, "outlet_monthly_inventory.csv"))
  barometar_write_csv(continuity, file.path(workdir, "outlet_continuity_inventory.csv"))
  barometar_write_csv(hosts, file.path(workdir, "outlet_host_inventory.csv"))
  saveRDS(result, file.path(workdir, "outlet_inventory.rds"))
  message("Inventory: ", length(result$review_from_values), " FROM values at >=1 raw row/month; ",
    length(result$candidate_from_values), " at >=20 across ", length(months), " months.")
  result
}

if (barometar_script_main("01_outlets.R")) invisible(barometar_outlet_inventory())
