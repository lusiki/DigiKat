#!/usr/bin/env Rscript
# 04_sector_profile.R — the religious sector's three responses to the inflation shock.
#
# Recuts the measured core into the responses the sector framing asks about and reports
# their timing across the whole of January 2021 to June 2026. Every temporal quantity is
# split by collection stream, because the corpus changes instrument in 2024 and raw counts
# are not comparable across that seam.
#
# Writes into output/: sector_responses.csv, sector_shares.csv, sector_bridge_2024.csv,
# sector_outlets.csv, sector_seam_free.csv.

source("studies/inflation-salience/_lib.R")

rule("04_sector_profile.R")

coded <- readRDS(file.path(PRIVATE, "coded_core.rds"))
core  <- coded[domestic == 1L]
msg("measured core: ", nrow(core), " posts, ",
    format(min(core$date)), " .. ", format(max(core$date)))

## ------------------------------------------------- 2.1 the three responses -----

rule("2.1  Responses by year")
msg("Streams: 2021-2023 monitoring only | 2024 both | 2025-2026 backfill only.")
msg("2026 is a half-year, January to June — its counts are not comparable to a full year.\n")

resp <- core[!is.na(response)]
tab <- dcast(resp[, .N, by = .(response, year)], response ~ year, value.var = "N", fill = 0L)
setorder(tab, response)
ord <- c("Public voice", "Repricing", "Charitable response", "Normative response")
tab <- tab[match(ord, response)]
print(tab)
fwrite(tab, file.path(OUT, "sector_responses.csv"))

msg("\nposts outside the four responses (devotional, other, disputed): ",
    sum(is.na(core$response)))

## ----------------------------------------------------- 2.2 the sequencing -----

rule("2.2  Sequencing — when each response peaks")
pk <- resp[, .(peak_year = year[which.max(tabulate(match(year, sort(unique(year))))) ],
               n = .N), by = response]
for (r in ord) {
  s <- resp[response == r, .N, by = year][order(-N)]
  msg(sprintf("  %-20s peak %s (n = %d)   series: %s", r, s$year[1], s$N[1],
              paste(sprintf("%d:%d", sort(resp[response == r]$year) |> unique() |> sort(),
                            resp[response == r, .N, by = year][order(year)]$N), collapse = "  ")))
}

## ------------------------------------------- 2.3 stream conditioning -----

rule("2.3a  The seam-free anchor — inside the monitoring stream alone, 2021-2023")
mon <- resp[stream == "monitoring" & year <= 2023]
anchor <- mon[response %in% c("Public voice", "Repricing"),
              .(voice     = sum(response == "Public voice"),
                repricing = sum(response == "Repricing")), by = year][order(year)]
anchor[, total := voice + repricing]
anchor[, repricing_share := round(100 * repricing / total, 1)]
print(anchor)
msg("\n  Repricing rises from ", anchor[year == 2022]$repricing_share, "% of voice-plus-repricing in 2022 to ",
    anchor[year == 2023]$repricing_share, "% in 2023, inside one collection instrument.")
fwrite(anchor, file.path(OUT, "sector_seam_free.csv"))

rule("2.3b  Composition shares within stream — the primary temporal quantity")
sh <- resp[, .N, by = .(stream, year, response)]
sh[, share := round(100 * N / sum(N), 1), by = .(stream, year)]
wide <- dcast(sh, stream + year ~ response, value.var = "share", fill = 0)
setcolorder(wide, c("stream", "year", ord))
print(wide)
fwrite(sh[order(stream, year, response)], file.path(OUT, "sector_shares.csv"))

rule("2.3c  The 2024 bridge — the overlap year read both ways")
br <- resp[year == 2024, .N, by = .(stream, response)]
br[, share := round(100 * N / sum(N), 1), by = stream]
bw <- dcast(br, response ~ stream, value.var = c("N", "share"), fill = 0)
print(bw)
msg("\n  monitoring rows in 2024: ", sum(coded[year == 2024]$stream == "monitoring"),
    " coded, of which core ", sum(core[year == 2024]$stream == "monitoring"))
msg("  backfill rows in 2024  : ", sum(coded[year == 2024]$stream == "backfill"),
    " coded, of which core ", sum(core[year == 2024]$stream == "backfill"))
fwrite(br, file.path(OUT, "sector_bridge_2024.csv"))

msg("\n  Confirmation rate at the overlap (share of coded candidates that survive as core):")
cr <- coded[year == 2024, .(candidates = .N, core = sum(domestic), rate = round(sum(domestic)/.N, 2)),
            by = stream]
print(cr)

## -------------------------------------------- 2.4 the normative response -----

rule("2.4  The normative response")
nj <- sum(core$register == "justice")
msg("  strict coding            : ", nj, " posts, ", sprintf("%.1f%%", 100 * nj / nrow(core)), " of the core")
msg("  by year                  : ",
    paste(sprintf("%s:%d", core[register == "justice", .N, by = year][order(year)]$year,
                  core[register == "justice", .N, by = year][order(year)]$N), collapse = "  "))
msg("  by stream                : ",
    paste(sprintf("%s:%d", core[register == "justice", .N, by = stream]$stream,
                  core[register == "justice", .N, by = stream]$N), collapse = "  "))

## --------------------------------------------------- 2.5 who reports it -----

rule("2.5  Who reports the sector's economics")
ot <- core[, .N, by = otype][order(-N)]
ot[, share := round(100 * N / sum(N), 1)]
print(ot)
msg("\n  Read as a property of the observation instrument, not of outlet behaviour:")
msg("  the sector's economics is reported overwhelmingly from outside the sector.")

reg_out <- dcast(core[, .N, by = .(register, otype)], register ~ otype, value.var = "N", fill = 0L)
print(reg_out)
fwrite(reg_out, file.path(OUT, "sector_outlets.csv"))

msg("\ndone.")
