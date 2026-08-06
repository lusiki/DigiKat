#!/usr/bin/env Rscript
# 00_hicp_eurostat.R — Croatian HICP annual rate of change, January 2021 to June 2026.
#
# The June 2026 pull used prc_hicp_manr and stopped at December 2025. That table has since
# been frozen: Eurostat closed it at 2025-12 when it migrated the HICP to ECOICOP ver.2,
# and current months are published in prc_hicp_minr instead. The two are queried on
# different dimensions and different aggregate codes, so this script pulls both, checks
# them against each other on every month they share, and only then splices.
#
# Run from the repository root. Needs network access.
#
# Writes
#   output/hicp_hr.csv               month, headline, food, energy, source table
#   output/hicp_validation.csv       old vs new vs the June 2026 file, month by month

source("studies/inflation-salience/_lib.R")
suppressWarnings(suppressMessages(library(jsonlite)))

rule("00_hicp_eurostat.R")

API <- "https://ec.europa.eu/eurostat/api/dissemination/statistics/1.0/data/"

# One series from a JSON-stat response. Every dimension except time is pinned to a single
# value by the query, so the flat value index is the time index.
eurostat_series <- function(dataset, ..., since = "2021-01") {
  q <- c(list(format = "JSON", lang = "EN", geo = "HR", sinceTimePeriod = since), list(...))
  url <- paste0(API, dataset, "?", paste0(names(q), "=", unlist(q), collapse = "&"))
  d <- jsonlite::fromJSON(url, simplifyVector = FALSE)
  if (!is.null(d$error)) stop(dataset, ": ", d$error[[1]]$label)
  months <- names(d$dimension$time$category$index)
  pos    <- unlist(d$dimension$time$category$index)
  val    <- rep(NA_real_, length(months))
  v      <- d$value
  if (length(v)) {
    ix <- as.integer(names(v))
    val[match(ix, pos)] <- as.numeric(unlist(v))
  }
  data.table(month = months[order(pos)], value = val[order(pos)])
}

pull <- function(dataset, dim, codes, since = "2021-01") {
  out <- NULL
  for (nm in names(codes)) {
    q <- setNames(list(codes[[nm]]), dim)
    s <- do.call(eurostat_series, c(list(dataset, unit = "RCH_A"), q, list(since = since)))
    setnames(s, "value", nm)
    out <- if (is.null(out)) s else merge(out, s, by = "month", all = TRUE)
    msg("  ", dataset, " / ", dim, "=", codes[[nm]], " -> ", sum(!is.na(s[[nm]])), " months")
  }
  out[order(month)]
}

## ------------------------------------------------------ the two source tables -----

# Food is CP01, food and non-alcoholic beverages, not the FOOD special aggregate, which
# folds in alcohol and tobacco and runs up to 3,4 percentage points away. CP01 reproduces
# the June 2026 file in all 60 of its months; FOOD reproduces 3. The all-items code
# changed name across the migration, CP00 becoming TOTAL, while CP01 and NRG did not.
msg("pulling prc_hicp_manr (ECOICOP ver.1, closed at 2025-12) ...")
v1 <- pull("prc_hicp_manr", "coicop",
           list(headline = "CP00", food = "CP01", energy = "NRG"))

msg("\npulling prc_hicp_minr (ECOICOP ver.2, current) ...")
v2 <- pull("prc_hicp_minr", "coicop18",
           list(headline = "TOTAL", food = "CP01", energy = "NRG"))

msg("\n  ver.1 span: ", min(v1$month), " .. ", max(v1$month))
msg("  ver.2 span: ", min(v2$month), " .. ", max(v2$month))

## ------------------------------------------- do the two vintages agree? -----

rule("Check 1 — ECOICOP ver.1 against ver.2 on every shared month")
both <- merge(v1, v2, by = "month", suffixes = c("_v1", "_v2"))
for (c in c("headline", "food", "energy")) {
  d <- both[[paste0(c, "_v2")]] - both[[paste0(c, "_v1")]]
  d <- d[!is.na(d)]
  msg(sprintf("  %-9s shared months %2d | identical %2d | max |difference| %.2f pp",
              c, length(d), sum(abs(d) < 1e-9), if (length(d)) max(abs(d)) else 0))
}

## ------------------------------- and against the file the June 2026 run wrote -----

rule("Check 2 — against the existing output/hicp_hr.csv (June 2026 pull)")
old_path <- file.path(OUT, "hicp_hr.csv")
old <- if (file.exists(old_path)) fread(old_path, encoding = "UTF-8") else NULL
if (!is.null(old) && "hicp_headline" %in% names(old)) {
  setnames(old, c("hicp_headline", "hicp_food", "hicp_energy"),
           c("headline_june", "food_june", "energy_june"), skip_absent = TRUE)
  chk <- merge(old[, .(month, headline_june, food_june, energy_june)], v1, by = "month")
  msg("  overlapping months: ", nrow(chk), " (", min(chk$month), " .. ", max(chk$month), ")")
  for (c in c("headline", "food", "energy")) {
    d <- chk[[c]] - chk[[paste0(c, "_june")]]
    d <- d[!is.na(d)]
    msg(sprintf("  %-9s identical %2d/%2d | max |difference| %.2f pp",
                c, sum(abs(d) < 1e-9), length(d), if (length(d)) max(abs(d)) else 0))
  }
  fwrite(merge(chk, v2, by = "month", all = TRUE, suffixes = c("_v1", "_v2")),
         file.path(OUT, "hicp_validation.csv"))
  msg("\n  wrote ", file.path(OUT, "hicp_validation.csv"))
} else {
  msg("  no comparable existing file found — skipping")
}

## ----------------------------------------------------------------- splice -----

rule("Splice")
SPAN <- format(seq(as.Date("2021-01-01"), as.Date("2026-06-01"), by = "month"), "%Y-%m")
hicp <- data.table(month = SPAN)
hicp <- merge(hicp, v1, by = "month", all.x = TRUE)
hicp <- merge(hicp, v2, by = "month", all.x = TRUE, suffixes = c("", "_v2"))

# ver.2 is the current vintage, so it wins wherever it exists; ver.1 fills the tail it
# does not reach back to.
hicp[, source := fifelse(!is.na(headline_v2), "prc_hicp_minr", "prc_hicp_manr")]
for (c in c("headline", "food", "energy")) {
  v <- paste0(c, "_v2")
  hicp[[c]] <- fifelse(!is.na(hicp[[v]]), hicp[[v]], hicp[[c]])
}
hicp <- hicp[, .(month, hicp_headline = headline, hicp_food = food, hicp_energy = energy, source)]

msg("  months in span            : ", nrow(hicp))
msg("  complete on all three     : ", sum(complete.cases(hicp[, 2:4])))
msg("  from prc_hicp_minr        : ", sum(hicp$source == "prc_hicp_minr"))
msg("  from prc_hicp_manr        : ", sum(hicp$source == "prc_hicp_manr"))
if (any(!complete.cases(hicp[, 2:4])))
  msg("  INCOMPLETE MONTHS         : ", paste(hicp[!complete.cases(hicp[, 2:4])]$month, collapse = ", "))

if (nrow(hicp) != 66L) stop("expected 66 months, 2021-01 .. 2026-06")
if (any(!complete.cases(hicp[, 2:4]))) stop("HICP has gaps — do not overwrite the tracked file")

fwrite(hicp, old_path)
msg("\nwrote ", old_path)
print(hicp[month >= "2025-10"])
msg("\ndone.")
