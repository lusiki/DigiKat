#!/usr/bin/env Rscript
# 03_finalize_coded.R — assemble the measured core from the surviving annotation.
#
# Rebuilds the lost scratchpad/14_finalize_coded.R. The 1,450 annotation decisions
# themselves survive in output/coded_labels.csv, so nothing here re-codes anything; the
# script joins those labels back to the master and attaches the collection stream.
#
# The join key. PAPER_v1 called it `rid` without saying what it was, and the execution
# brief assumed it was lost. It is the 1-based row index of the master data frame: for all
# 1,450 pooled items both the URL and the date at that row agree with the pool index. The
# script asserts this before using it, so a changed master fails loudly instead of
# silently attaching labels to the wrong posts. That matters because five pooled URLs are
# duplicated in the master, so a URL join would be ambiguous for them.
#
# Writes
#   output/private/coded_core.rds      restricted: one row per coded item
#   output/coded_core_stream.csv       tracked aggregate: register x year x stream counts
#
# Fixture check: 652 linked / 132 foreign / 520 domestic core.

source("studies/inflation-salience/_lib.R")

rule("03_finalize_coded.R")

lab  <- fread(file.path(OUT, "coded_labels.csv"), encoding = "UTF-8")
pool <- fread(file.path(PRIVATE, "coding_pool_index.csv"), encoding = "UTF-8")
msg("annotation decisions: ", nrow(lab), " (", sum(lab$n == 3), " coded by all three annotators)")

m <- readRDS(MASTER)

## ------------------------------------------------------ assert the join key -----

rule("Join-key assertion — rid is the master row index")
stopifnot(all(lab$rid %in% pool$rid), nrow(lab) == nrow(pool))
url_ok  <- sum(as.character(m$URL[pool$rid]) == pool$URL)
date_ok <- sum(as.character(m$DATE[pool$rid]) == as.character(pool$DATE))
msg("  URL agrees at rid  : ", url_ok,  " / ", nrow(pool))
msg("  DATE agrees at rid : ", date_ok, " / ", nrow(pool))
if (url_ok != nrow(pool) || date_ok != nrow(pool))
  stop("rid no longer indexes the master — the master has changed; do not proceed.")
msg("  duplicated URLs among pooled items (why a URL join would be unsafe): ",
    sum(duplicated(pool$URL)) + sum(duplicated(pool$URL, fromLast = TRUE)))

## ------------------------------------------------------------ assemble -----

dates <- as.Date(m$DATE)
coded <- data.table(
  rid       = lab$rid,
  n_ann     = lab$n,
  c_infl    = lab$infl,
  c_link    = lab$link,
  c_foreign = lab$foreign,
  register  = lab$register
)[, `:=`(
  date      = dates[rid],
  year      = as.integer(format(dates[rid], "%Y")),
  month     = format(dates[rid], "%Y-%m"),
  stream    = unname(STREAM_LABEL[m$data_source[rid]]),
  outlet    = m$FROM[rid],
  otype     = pool$otype[match(rid, pool$rid)],
  sentiment = m$AUTO_SENTIMENT[rid]
)]
coded[, register := fifelse(register == "cost_relig_life", "crl", register)]

# The measured core takes all three axes together: the post is genuinely about the cost of
# living, religion is genuinely linked to that content rather than incidental to it, and
# the inflation being discussed is Croatian. Dropping the first condition would readmit 13
# items the annotators judged not to be about inflation at all.
coded[, linked   := as.integer(c_infl == 1L & c_link == 1L)]
coded[, domestic := as.integer(c_infl == 1L & c_link == 1L & c_foreign == 0L)]
coded[, response := unname(RESPONSE_OF_REGISTER[register])]

saveRDS(coded, file.path(PRIVATE, "coded_core.rds"))
msg("\nwrote ", file.path(PRIVATE, "coded_core.rds"), " (", nrow(coded), " rows)")

## ------------------------------------------------------- fixture checks -----

rule("Fixture check — the funnel")
fixture_report("candidates coded",             nrow(coded),                    1450L)
fixture_report("confirmed inflation",          sum(coded$c_infl == 1L),        1329L)
fixture_report("confirmed religion-linked",    sum(coded$linked == 1L),         652L)
fixture_report("... foreign inflation",        sum(coded$linked == 1L & coded$c_foreign == 1L), 132L)
fixture_report("... domestic measured core",   sum(coded$domestic == 1L),       520L)

core <- coded[domestic == 1L]
rule("Fixture check — register of the domestic core (PAPER_v1 Table 2)")
exp_reg <- c(crl = 194L, institution = 179L, charity = 87L, devotional = 26L,
             justice = 15L, disputed = 12L, other = 7L)
for (r in names(exp_reg)) fixture_report(REGISTER_LABEL[[r]], sum(core$register == r), exp_reg[[r]])

rule("Fixture check — outlet type and year (PAPER_v1 sections 4.2, 4.4)")
fixture_report("secular / other outlets", sum(core$otype == "Secular/other"), 442L)
fixture_report("Catholic outlets",        sum(core$otype == "Catholic"),       75L)
# Year targets are the June figures with one correction. Six posts carry the date
# 2022-12-31 in both the master and the June core file, yet that file's own `year` column
# says 2023 for them, so PAPER_v1 Table 4 reads 2022 -> 201 and 2023 -> 100. The date is
# unambiguous and 2022 is right, which makes the corrected split 207 / 94. The check below
# prints the corrected target and the size of the correction.
june_year <- c(`2021` = 12L, `2022` = 201L, `2023` = 100L, `2024` = 88L,
               `2025` = 66L, `2026` = 53L)
corr_year <- c(`2021` = 12L, `2022` = 207L, `2023` =  94L, `2024` = 88L,
               `2025` = 66L, `2026` = 53L)
for (y in 2021:2026)
  fixture_report(paste("core posts in", y), sum(core$year == y), corr_year[[as.character(y)]])
msg("\n  posts dated 2022-12-31 that the June run booked to 2023: ",
    sum(as.character(core$date) == "2022-12-31"))
msg("  (June split 2022/2023 was ", june_year[["2022"]], " / ", june_year[["2023"]],
    "; corrected ", corr_year[["2022"]], " / ", corr_year[["2023"]], ")")

## ------------------------------- the stream label the execution brief wanted -----

rule("Collection stream of the measured core")
msg("The brief expected the stream to be recoverable for the 88 posts dated 2024 only.")
msg("Because rid indexes the master, it is exact for all ", nrow(core), ".\n")
print(dcast(core[, .N, by = .(year, stream)], year ~ stream, value.var = "N", fill = 0L))

agg <- core[, .N, by = .(year, stream, register)][order(year, stream, register)]
fwrite(agg, file.path(OUT, "coded_core_stream.csv"))
msg("\nwrote ", file.path(OUT, "coded_core_stream.csv"))
msg("\ndone.")
