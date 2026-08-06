#!/usr/bin/env Rscript
# 01_tag_inflation.R — tag cost-of-living mentions across the master corpus.
#
# Rebuilds the tagging stage of the lost scratchpad/10_rerun_fixed.R.
# Run from the repository root:
#   & 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/inflation-salience/01_tag_inflation.R
#
# Writes
#   output/private/tagged_inflation.rds   restricted: rid, date, stream, outlet, title, url
#   output/attention_monthly.csv          tracked aggregate: month, stream, n_total, n_infl, share
#
# Fixture check: the June 2026 run reported 8,105 raw / 8,019 clean inflation posts and a
# 39-month monitoring-stream series in output/h1_attention_hicp_series.csv.

source("studies/inflation-salience/_lib.R")

rule("01_tag_inflation.R")
msg("reading the master ...")
m <- readRDS(MASTER)
msg("  ", format(nrow(m), big.mark = " "), " rows x ", ncol(m), " columns")

txt <- dk_text(m$TITLE, m$FULL_TEXT)

msg("tagging ...")
raw   <- tag_inflation_raw(txt)
clean <- tag_inflation(txt)
stopifnot(all(clean <= raw))

rule("Fixture check — corpus funnel")
fixture_report("inflation posts, before guard", sum(raw),   8105L)
fixture_report("inflation posts, after guard",  sum(clean), 8019L)
fixture_report("removed by the metaphor guard", sum(raw) - sum(clean), 86L)

## ------------------------------------------------------------ tagged set -----

dates <- as.Date(m$DATE)
tag <- data.table(
  rid       = which(clean),
  date      = dates[clean],
  month     = format(dates[clean], "%Y-%m"),
  year      = as.integer(format(dates[clean], "%Y")),
  stream    = unname(STREAM_LABEL[m$data_source[clean]]),
  outlet    = m$FROM[clean],
  src_type  = m$SOURCE_TYPE[clean],
  sentiment = m$AUTO_SENTIMENT[clean],
  title     = m$TITLE[clean],
  url       = m$URL[clean]
)
saveRDS(tag, file.path(PRIVATE, "tagged_inflation.rds"))
msg("\nwrote ", file.path(PRIVATE, "tagged_inflation.rds"), " (", nrow(tag), " rows)")

## ------------------------------------------------- monthly attention series -----

all_months <- data.table(
  month  = format(dates, "%Y-%m"),
  stream = unname(STREAM_LABEL[m$data_source]),
  infl   = clean
)
att <- all_months[, .(n_total = .N, n_infl = sum(infl)), by = .(month, stream)][order(stream, month)]
att[, share := 100 * n_infl / n_total]
fwrite(att, file.path(OUT, "attention_monthly.csv"))
msg("wrote ", file.path(OUT, "attention_monthly.csv"), " (", nrow(att), " month x stream cells)")

## ------------------------------------- fixture check against the June series -----

rule("Fixture check — monthly series (monitoring stream, 2021-01 .. 2024-07)")
june <- fread(file.path(OUT, "h1_attention_hicp_series.csv"), encoding = "UTF-8")
cmp <- merge(june[, .(month, n_total_june = n_total, n_infl_june = n_infl)],
             att[stream == "monitoring", .(month, n_total, n_infl)], by = "month")
cmp[, `:=`(d_total = n_total - n_total_june, d_infl = n_infl - n_infl_june)]

msg("  months compared            : ", nrow(cmp))
msg("  n_total identical          : ", all(cmp$d_total == 0))
msg("  n_infl mean absolute error : ", sprintf("%.2f posts/month", mean(abs(cmp$d_infl))))
msg("  n_infl RMSE                : ", sprintf("%.2f posts/month", sqrt(mean(cmp$d_infl^2))))
msg("  n_infl mean bias           : ", sprintf("%+.2f posts/month", mean(cmp$d_infl)))
msg("  correlation of the shares  : ",
    sprintf("%.4f", cor(cmp$n_infl_june / cmp$n_total_june, cmp$n_infl / cmp$n_total)))

fwrite(cmp, file.path(OUT, "fixture_monthly_agreement.csv"))
msg("\n  wrote ", file.path(OUT, "fixture_monthly_agreement.csv"))

rule("Coverage of the full span")
print(att[, .(months = .N, n_total = sum(n_total), n_infl = sum(n_infl),
              share = round(100 * sum(n_infl) / sum(n_total), 3)), by = stream])
msg("\ndone.")
