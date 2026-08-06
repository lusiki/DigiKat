#!/usr/bin/env Rscript
# 17_v2_figures.R — black-and-white figures for PAPER_EMIP_v2.md.
#
# The figures read only tracked aggregate outputs. They contain no post text, URLs, outlet
# names, or identifying institutional names.

source("studies/inflation-salience/_lib.R")

rule("17_v2_figures.R")

R <- function(f) fread(file.path(OUT, f), encoding = "UTF-8", header = TRUE)
events <- R("event_process.csv")
objects <- R("attention_object_monthly.csv")
units <- R("unit_response.csv")
core <- R("v2_analysis_core.csv")

to_date <- function(x) as.Date(paste0(x, "-01"))
month_seq <- seq(as.Date("2021-01-01"), as.Date("2026-06-01"), by = "month")
year_ticks <- seq(as.Date("2021-01-01"), as.Date("2026-01-01"), by = "year")

## ----------------------------------------------------------- Figure 1 -----

own <- objects[attention_series == "Own position, sector voice", .(direct_own = sum(N)), by = month]
ev <- merge(data.table(month = format(month_seq, "%Y-%m")), events, by = "month", all.x = TRUE)
ev <- merge(ev, own, by = "month", all.x = TRUE)
for (j in c("public_voice", "repricing", "direct_own")) set(ev, which(is.na(ev[[j]])), j, 0)
ev[, date := to_date(month)]

fig1 <- file.path(OUT, "fig1_event_timeline.png")
png(fig1, width = 2200, height = 1450, res = 220, type = "cairo")
op <- par(no.readonly = TRUE)
layout(matrix(1:2, nrow = 2), heights = c(1.7, 1))
par(mar = c(1.2, 5.2, 1.0, 1.0), family = "serif", las = 1)

plot(ev$date, ev$public_voice, type = "n", xaxt = "n", xlab = "", ylab = "Coverage events",
     ylim = c(0, max(ev$public_voice, ev$repricing, ev$direct_own) * 1.08), bty = "l")
abline(v = as.Date(c("2022-10-01", "2022-11-01", "2024-06-01")),
       col = "grey75", lty = 3, lwd = 1)
lines(ev$date, ev$public_voice, lwd = 2.2, lty = 1, col = "black")
lines(ev$date, ev$direct_own, lwd = 2.2, lty = 2, col = "grey35")
lines(ev$date, ev$repricing, lwd = 2.2, lty = 4, col = "grey55")
legend("topright", c("All public voice", "Direct own-position speech", "Repricing coverage"),
       lty = c(1, 2, 4), lwd = 2.2, col = c("black", "grey35", "grey55"),
       bty = "n", cex = 0.88)
mtext("A. Monthly media events", side = 3, line = -0.2, adj = 0, font = 2)

par(mar = c(4.1, 5.2, 1.0, 1.0), family = "serif", las = 1)
plot(ev$date, ev$hicp_headline, type = "n", xaxt = "n", xlab = "", ylab = "HICP annual rate (%)",
     ylim = range(c(0, ev$hicp_headline), na.rm = TRUE), bty = "l")
abline(h = 0, col = "grey75", lwd = 0.8)
abline(v = as.Date(c("2022-10-01", "2022-11-01", "2024-06-01")),
       col = "grey75", lty = 3, lwd = 1)
lines(ev$date, ev$hicp_headline, lwd = 2.2, col = "black")
axis.Date(1, at = year_ticks, format = "%Y")
mtext("B. Croatian headline inflation", side = 3, line = -0.2, adj = 0, font = 2)
mtext("Month", side = 1, line = 2.4)
par(op)
dev.off()
msg("  wrote ", fig1)

## ----------------------------------------------------------- Figure 2 -----

unit_levels <- c("parish", "diocese", "order", "caritas", "conference",
                 "vatican", "church", "none")
unit_labels <- c("Parish", "Diocese or archdiocese", "Religious order or monastery",
                 "Caritas or relief body", "Bishops' conference", "Vatican or Pope",
                 "Church, no specific unit", "No church unit acts")

ur <- dcast(units[response %chin% c("Public voice", "Repricing")],
            unit ~ response, value.var = "N", fun.aggregate = sum, fill = 0L)
for (nm in c("Public voice", "Repricing")) if (!nm %in% names(ur)) ur[, (nm) := 0L]
own_u <- core[register == "institution" & voice == "sector" & object %chin% c("own", "both"),
              .(direct_own = .N), by = unit]
ur <- merge(data.table(unit = unit_levels), ur, by = "unit", all.x = TRUE)
ur <- merge(ur, own_u, by = "unit", all.x = TRUE)
for (j in setdiff(names(ur), "unit")) set(ur, which(is.na(ur[[j]])), j, 0)
ur[, unit_order := match(unit, unit_levels)]
setorder(ur, unit_order)

mat <- rbind(ur[["Public voice"]], ur$direct_own, ur[["Repricing"]])
fig2 <- file.path(OUT, "fig2_unit_responses.png")
png(fig2, width = 2200, height = 1400, res = 220, type = "cairo")
op <- par(no.readonly = TRUE)
par(mar = c(4.3, 12.5, 1.0, 1.0), family = "serif", las = 1)
barplot(mat, beside = TRUE, horiz = TRUE, names.arg = unit_labels,
        col = c("black", "grey55", "white"), border = "black", xlab = "Coverage events",
        xlim = c(0, max(mat) * 1.12), cex.names = 0.83, space = c(0.08, 0.55))
legend("bottomright", c("All public voice", "Direct own-position speech", "Repricing coverage"),
       fill = c("black", "grey55", "white"), border = "black", bty = "n", cex = 0.88)
par(op)
dev.off()
msg("  wrote ", fig2)

msg("\ndone.")
