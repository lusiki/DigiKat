#!/usr/bin/env Rscript
# 16_v2_event.R — W3/W4 reporting diagnostics and event-process description.
#
# This is deliberately descriptive. Media coverage is an event register without a risk set,
# so the script reports timings, lags, concentration, and a chained HICP price-level gap. It
# does not call coverage counts a price-change hazard or estimate a structural duration model.

source("studies/inflation-salience/_lib.R")

rule("16_v2_event.R")

key  <- fread(file.path(PRIVATE, "v2_key.csv"), encoding = "UTF-8")
hicp <- fread(file.path(OUT, "hicp_hr.csv"), encoding = "UTF-8")

month_id <- function(x) {
  y <- as.integer(substr(x, 1L, 4L)); m <- as.integer(substr(x, 6L, 7L))
  12L * y + m
}

## ------------------------------------------------------- event register ----

cal <- data.table(month = format(seq(as.Date("2021-01-01"), as.Date("2026-06-01"), by = "month"), "%Y-%m"))
ev <- key[response %chin% c("Public voice", "Repricing"), .N, by = .(month, response)]
ev <- dcast(ev, month ~ response, value.var = "N", fill = 0L)
setnames(ev, c("Public voice", "Repricing"), c("public_voice", "repricing"))
ev <- merge(cal, ev, by = "month", all.x = TRUE)
ev[is.na(public_voice), public_voice := 0L]
ev[is.na(repricing), repricing := 0L]
ev <- merge(ev, hicp[, .(month, hicp_headline)], by = "month", all.x = TRUE)

# Reconstruct the HICP level change from the same calendar month in 2021 by chaining each
# observed year-on-year rate. This avoids pretending that an annual rate is a monthly rate.
ev[, `:=`(year = as.integer(substr(month, 1L, 4L)), mon = substr(month, 6L, 7L))]
ev[, price_gap_from_2021 := {
  yy <- year
  vapply(seq_along(yy), function(i) {
    if (yy[i] == 2021L) return(0)
    rates <- hicp_headline[year >= 2022L & year <= yy[i]]
    if (anyNA(rates)) return(NA_real_)
    100 * (prod(1 + rates / 100) - 1)
  }, numeric(1))
}, by = mon]
ev[, price_gap_from_2021 := round(price_gap_from_2021, 1)]
setorder(ev, month)
fwrite(ev[, .(month, public_voice, repricing, hicp_headline, price_gap_from_2021)],
       file.path(OUT, "event_process.csv"))

voice_peak <- ev[public_voice == max(public_voice), month][1]
price_peak <- ev[repricing == max(repricing), month][1]
hicp_peak  <- ev[hicp_headline == max(hicp_headline, na.rm = TRUE), month][1]
first_price <- ev[repricing > 0L, month][1]
lag_voice_price <- month_id(price_peak) - month_id(voice_peak)
lag_hicp_price  <- month_id(price_peak) - month_id(hicp_peak)
gap_peak <- ev[month == price_peak, price_gap_from_2021]

## ---------------------------------------------------- W3 diagnostics ----

a <- key[stream == "monitoring"]
cap <- a[response == "Repricing" & year %in% 2022:2023, .N, by = year][order(year)]
anchor <- a[year %in% 2022:2023 & response %chin% c("Public voice", "Repricing"),
            .(voice = sum(response == "Public voice"),
              repricing = sum(response == "Repricing")), by = year]
anchor[, repricing_share := round(100 * repricing / (voice + repricing), 1)]
crl <- key[register == "crl"]
secular_crl <- crl[otype == "Secular/other", .N]

detection <- rbind(
  data.table(diagnostic = "Monitoring-stream repricing coverage, 2022", value = cap[year == 2022, N], unit = "posts"),
  data.table(diagnostic = "Monitoring-stream repricing coverage, 2023", value = cap[year == 2023, N], unit = "posts"),
  data.table(diagnostic = "Repricing share of voice plus repricing, 2022", value = anchor[year == 2022, repricing_share], unit = "percent"),
  data.table(diagnostic = "Repricing share of voice plus repricing, 2023", value = anchor[year == 2023, repricing_share], unit = "percent"),
  data.table(diagnostic = "Repricing reports from secular outlets", value = secular_crl, unit = "posts"),
  data.table(diagnostic = "All repricing reports", value = nrow(crl), unit = "posts")
)
fwrite(detection, file.path(OUT, "detection_diagnostics.csv"))

event_summary <- data.table(
  voice_peak_month = voice_peak,
  voice_peak_n = ev[month == voice_peak, public_voice],
  repricing_first_month = first_price,
  repricing_peak_month = price_peak,
  repricing_peak_n = ev[month == price_peak, repricing],
  hicp_peak_month = hicp_peak,
  hicp_peak_rate = ev[month == hicp_peak, hicp_headline],
  voice_to_repricing_months = lag_voice_price,
  hicp_to_repricing_months = lag_hicp_price,
  price_gap_at_repricing_peak = gap_peak,
  repricing_peak_share_all = round(100 * ev[month == price_peak, repricing] / sum(ev$repricing), 1),
  repricing_peak_share_2024 = round(100 * ev[month == price_peak, repricing] /
                                      sum(ev[substr(month, 1L, 4L) == "2024", repricing]), 1)
)
fwrite(event_summary, file.path(OUT, "event_summary.csv"))

print(event_summary)
print(detection)
msg("\nThe event register supports lags and concentration, not a structural hazard without a risk set.")
msg("done.")
