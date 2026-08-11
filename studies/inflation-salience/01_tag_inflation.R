#!/usr/bin/env Rscript
# 01_tag_inflation.R — tag cost-of-living mentions across the official corpus.
#
# Rebuilds the tagging stage of the lost scratchpad/10_rerun_fixed.R.
# Run from the repository root:
#   & 'C:\Program Files\R\R-4.6.0\bin\Rscript.exe' studies/inflation-salience/01_tag_inflation.R
#
# Writes
#   output/private/tagged_inflation.rds   restricted: rid, date, stream, outlet, title, url
#   output/attention_monthly.csv          tracked aggregate: month, stream, n_total, n_infl, share
#
# Baseline check: the August 2026 official corpus yields 1,537 raw / 1,486 clean mentions.

source("studies/inflation-salience/_lib.R")

rule("01_tag_inflation.R")
msg("reading the official corpus ...")
m <- readRDS(MASTER)
msg("  ", format(nrow(m), big.mark = " "), " rows x ", ncol(m), " columns")
if (nrow(m) != MASTER_MANIFEST$corpus$rows)
  stop("corpus row count disagrees with data/digikat_corpus_manifest.json")

txt <- dk_text(m$TITLE, m$FULL_TEXT)

msg("tagging ...")
raw   <- tag_inflation_raw(txt)
clean <- tag_inflation(txt)
stopifnot(all(clean <= raw))

rule("Baseline check — official-corpus funnel")
fixture_report("inflation posts, before guard", sum(raw),   1537L)
fixture_report("inflation posts, after guard",  sum(clean), 1486L)
fixture_report("removed by the metaphor guard", sum(raw) - sum(clean), 51L)

## ------------------------------------------------------------ tagged set -----

dates <- as.Date(m$DATE)
tag <- data.table(
  rid       = study_row_id(m)[clean],
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

## ------------------------------------------ database-change audit -----

rule("Database-change audit — old accumulator series against the official corpus")
june <- fread(file.path(OUT, "h1_attention_hicp_series.csv"), encoding = "UTF-8")
cmp <- merge(june[, .(month, n_total_june = n_total, n_infl_june = n_infl)],
             att[stream == "monitoring", .(month, n_total, n_infl)], by = "month")
cmp[, `:=`(d_total = n_total - n_total_june, d_infl = n_infl - n_infl_june)]

msg("  months compared            : ", nrow(cmp))
msg("  denominator changed        : ", any(cmp$d_total != 0))
msg("  cost-of-living count change: ", sprintf("%+.2f posts/month on average", mean(cmp$d_infl)))
msg("  correlation of old/new shares: ",
    sprintf("%.4f", cor(cmp$n_infl_june / cmp$n_total_june, cmp$n_infl / cmp$n_total)))

fwrite(cmp, file.path(OUT, "database_delta_monthly.csv"))
msg("\n  wrote ", file.path(OUT, "database_delta_monthly.csv"))

rule("Coverage of the full span")
print(att[, .(months = .N, n_total = sum(n_total), n_infl = sum(n_infl),
              share = round(100 * sum(n_infl) / sum(n_total), 3)), by = stream])
msg("\ndone.")
