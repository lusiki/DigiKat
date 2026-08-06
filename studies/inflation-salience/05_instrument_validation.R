#!/usr/bin/env Rscript
# 05_instrument_validation.R — does media coverage track the real price shock?
#
# Under the sector framing the attention series is not a headline claim but a check that
# the observation instrument works: if the share of corpus posts mentioning the cost of
# living moves with the Croatian HICP, then media coverage is measuring something real
# about prices, which is what licenses using it to observe a sector that publishes no price
# statistics of its own.
#
# The corpus changes collection instrument in 2024, so the check is run once per stream.
# Two independent validations on two different collection methods are a stronger claim
# than one, and they double as the comparability evidence the temporal analysis needs.
#
# Writes into output/: instrument_series.csv, instrument_correlations.csv,
# instrument_threshold.csv, instrument_robustness.csv.

source("studies/inflation-salience/_lib.R")
suppressWarnings(suppressMessages(library(MASS)))

rule("05_instrument_validation.R")

att  <- fread(file.path(OUT, "attention_monthly.csv"), encoding = "UTF-8")
hicp <- fread(file.path(OUT, "hicp_hr.csv"), encoding = "UTF-8")

# A month enters a stream's series only if that stream collected enough of it to give a
# meaningful share. The rule is one number applied identically to both streams; without it
# the monitoring stream's 2024 tail (one month at 436 posts against a normal seven
# thousand) would dominate its own correlation.
MIN_MONTH_N <- 2000L

ser <- merge(att, hicp, by = "month")[month <= "2026-06"]
ser[, keep := n_total >= MIN_MONTH_N]

rule("Coverage")
msg("  minimum monthly corpus volume for inclusion: ", format(MIN_MONTH_N, big.mark = " "), " posts")
print(ser[, .(months = .N, kept = sum(keep), dropped = sum(!keep),
              first = min(month), last = max(month)), by = stream])
drp <- ser[keep == FALSE]
if (nrow(drp)) {
  msg("\n  dropped months (stream, month, n_total):")
  for (i in seq_len(nrow(drp))) msg("    ", drp$stream[i], "  ", drp$month[i], "  ",
                                    format(drp$n_total[i], big.mark = " "))
}
msg("\n  months with no rows at all in a stream are absent from the table, not zero.")
msg("  the monitoring stream has no February to May 2024 whatsoever.")

ser <- ser[keep == TRUE][, keep := NULL]
fwrite(ser, file.path(OUT, "instrument_series.csv"))

rule("Windows actually used")
for (s in unique(ser$stream)) {
  w <- ser[stream == s]
  msg(sprintf("  %-11s %s .. %s   %2d months   monthly volume %s .. %s",
              s, min(w$month), max(w$month), nrow(w),
              format(min(w$n_total), big.mark = " "), format(max(w$n_total), big.mark = " ")))
}
msg("\n  PAPER_v1 described the monitoring window as 2021-2024 and the June series carried")
msg("  39 months. Three of those were partial: January 2024 at 1 911 posts and July 2024 at")
msg("  436 against a normal seven thousand, and February to May 2024 do not exist at all.")
msg("  The usable window is 2021-01 to 2024-06 with a four-month hole, 37 months.")

rule("How much price variation each window contains")
rng <- ser[, .(months = .N,
               hicp_min = min(hicp_headline), hicp_max = max(hicp_headline),
               hicp_sd  = round(sd(hicp_headline), 2),
               months_above_4 = sum(hicp_headline >= 4)), by = stream]
print(rng)
msg("\n  This governs how the two validations should be read. The monitoring window contains")
msg("  the shock itself; the backfill window is the plateau after it, where headline")
msg("  inflation never leaves a two-point band and is above the 4% threshold in most months.")
msg("  A window with almost no variation in the regressor cannot validate anything, and a")
msg("  weak correlation there is not evidence against the instrument.")

## ------------------------------------------------------------ correlations -----

rule("Correlation with HICP, once per stream")
comp <- c(headline = "hicp_headline", food = "hicp_food", energy = "hicp_energy")
cors <- rbindlist(lapply(unique(ser$stream), function(s) {
  w <- ser[stream == s]
  rbindlist(lapply(names(comp), function(cn) {
    x <- w[[comp[[cn]]]]; y <- w$share
    pt <- cor.test(x, y)
    data.table(stream = s, n = nrow(w), component = cn,
               pearson = round(unname(pt$estimate), 2), p = signif(pt$p.value, 3),
               spearman = round(cor(x, y, method = "spearman"), 2))
  }))
}))
print(cors)
fwrite(cors, file.path(OUT, "instrument_correlations.csv"))

## -------------------------------------------------------- the 4% threshold -----

rule("The attention threshold — mean attention below and above 4% headline HICP")
thr <- ser[, .(months = .N, mean_share = round(mean(share), 2)),
           by = .(stream, above = hicp_headline >= 4)][order(stream, above)]
print(thr)
jump <- dcast(thr, stream ~ above, value.var = "mean_share")
setnames(jump, c("FALSE", "TRUE"), c("below_4", "at_or_above_4"), skip_absent = TRUE)
jump[, ratio := round(at_or_above_4 / below_4, 2)]
print(jump)
fwrite(merge(thr, jump, by = "stream"), file.path(OUT, "instrument_threshold.csv"))

## ------------------------------------------------------------- robustness -----

# Newey-West heteroskedasticity- and autocorrelation-consistent standard errors, written
# out rather than taken from a package so the replication archive needs no extra
# dependency. Bandwidth follows the usual rule of thumb.
newey_west <- function(fit) {
  X <- model.matrix(fit); u <- residuals(fit); n <- nrow(X)
  L <- floor(4 * (n / 100)^(2 / 9))
  S <- crossprod(X * u)
  for (l in seq_len(L)) {
    w  <- 1 - l / (L + 1)
    Xu <- X * u
    G  <- crossprod(Xu[(l + 1):n, , drop = FALSE], Xu[1:(n - l), , drop = FALSE])
    S  <- S + w * (G + t(G))
  }
  bread <- solve(crossprod(X))
  list(se = sqrt(diag(bread %*% S %*% bread)), lag = L)
}

rule("Robustness — three specifications, per stream")
msg("  1  levels with Newey-West standard errors")
msg("  2  first differences, which removes any common trend")
msg("  3  a negative binomial count model with log(monthly corpus volume) as offset,")
msg("     so the result does not depend on how the share's denominator moves\n")

rob <- rbindlist(lapply(unique(ser$stream), function(s) {
  w <- ser[order(month)][stream == s]
  out <- list()

  f1 <- lm(share ~ hicp_headline, data = w)
  nw <- newey_west(f1)
  b  <- coef(f1)[["hicp_headline"]]
  out[[1]] <- data.table(stream = s, spec = "levels, Newey-West", n = nrow(w),
                         estimate = round(b, 4),
                         se = round(nw$se[["hicp_headline"]], 4),
                         t = round(b / nw$se[["hicp_headline"]], 2),
                         note = paste0("HAC lag ", nw$lag))

  # Differences are taken only between genuinely consecutive months. The monitoring stream
  # has a four-month hole in 2024 and differencing across it would compare June with the
  # previous January.
  mnum <- as.integer(substr(w$month, 1, 4)) * 12L + as.integer(substr(w$month, 6, 7))
  adj  <- which(diff(mnum) == 1L)
  d <- data.table(ds = w$share[adj + 1] - w$share[adj],
                  dh = w$hicp_headline[adj + 1] - w$hicp_headline[adj])
  f2 <- lm(ds ~ dh, data = d)
  s2 <- summary(f2)$coefficients["dh", ]
  out[[2]] <- data.table(stream = s, spec = "first differences", n = nrow(d),
                         estimate = round(s2[["Estimate"]], 4), se = round(s2[["Std. Error"]], 4),
                         t = round(s2[["t value"]], 2),
                         note = sprintf("p = %.3f", s2[["Pr(>|t|)"]]))

  f3 <- tryCatch(MASS::glm.nb(n_infl ~ hicp_headline + offset(log(n_total)), data = w),
                 error = function(e) NULL)
  if (!is.null(f3)) {
    s3 <- summary(f3)$coefficients["hicp_headline", ]
    out[[3]] <- data.table(stream = s, spec = "negative binomial, volume offset", n = nrow(w),
                           estimate = round(s3[["Estimate"]], 4), se = round(s3[["Std. Error"]], 4),
                           t = round(s3[["z value"]], 2),
                           note = sprintf("incidence ratio %.3f per pp", exp(s3[["Estimate"]])))
  }
  rbindlist(out)
}))
print(rob)
fwrite(rob, file.path(OUT, "instrument_robustness.csv"))

rule("Monthly corpus volume, for the record")
print(ser[, .(min = min(n_total), median = as.integer(median(n_total)), max = max(n_total)),
          by = stream])

msg("\ndone.")
