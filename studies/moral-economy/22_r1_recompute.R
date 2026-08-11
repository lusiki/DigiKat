#!/usr/bin/env Rscript
# moral-economy R1/R2 — WHAT THE 150-CARD NUMERATOR AUDIT SAYS ABOUT THE OFFICIAL CORE.
#
# PROPOSAL_v5_rsp.md R1 sets the decision rule in advance:
#   precision >= 0.80 -> report the rate as measured
#   0.60-0.80         -> report both raw and precision-adjusted
#   < 0.60            -> the headline number cannot be published as-is
# and R2 adds: no domain below 0.70 for the economic-term check, green_energy >= 0.80 specifically,
# because the whole argument turns on that row.
#
# Applying a pre-declared rule to a number you have already seen is not a test, so the rule is read
# out of the proposal and printed alongside the verdict rather than restated here from memory.
#
#   Rscript studies/moral-economy/22_r1_recompute.R
suppressPackageStartupMessages({ library(here) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/rsp_input.R"))
source(here::here("studies/moral-economy/cst_core.R"))

cat("=== R1/R2 — numerator precision ===\n")
sheet <- read.csv(RSP_R1_SHEET, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
ann   <- read.delim(RSP_R1_ANN, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
key   <- read.csv(RSP_R1_KEY, fileEncoding = "UTF-8", stringsAsFactors = FALSE)

digikat_require_columns(ann, c("item", "rid", "r1_invocation", "r2_econ_true"), "r1_ann1.tsv")
m <- match(ann$item, sheet$item)
if (anyNA(m) || any(sheet$rid[m] != ann$rid)) stop("rid mismatch between annotation and sheet.", call. = FALSE)
if (!all(ann$r1_invocation %in% c("genuine", "mention", "false"))) stop("bad r1 value", call. = FALSE)
if (!all(ann$r2_econ_true %in% c("yes", "no"))) stop("bad r2 value", call. = FALSE)
sem_gate_report("R1a annotation integrity", TRUE, sprintf("%d cards, rid matched", nrow(ann)))

k <- key[match(ann$rid, key$rid), ]
ann$era <- k$era; ann$band <- k$band; ann$domain_tier <- k$domain_tier
core <- cst_build_core(verbose = FALSE)
ci <- match(ann$rid, core$rid)
if (anyNA(ci)) stop("An R1 sampled rid is absent from the current core.", call. = FALSE)
ann$audit_domain <- vapply(core$domain_gaps[ci], function(g) names(g)[which.min(g)], character(1))

# The design is proportional era x outlet-band stratification, with a one-card floor and integer
# rounding. Post-stratification removes the small remaining allocation imbalance. Wilson limits use
# the Kish effective n of those weights and are explicitly measurement-audit intervals.
alloc <- read.csv(file.path(ME_OUT, "r1_sample_allocation.csv"), fileEncoding = "UTF-8")
alloc$stratum <- paste(alloc$era, alloc$outlet_band, sep = "|")
ann$stratum <- paste(ann$era, ann$band, sep = "|")
ann$weight <- alloc$population[match(ann$stratum, alloc$stratum)] /
              alloc$target[match(ann$stratum, alloc$stratum)]
if (anyNA(ann$weight) || any(!is.finite(ann$weight))) stop("R1 post-stratification weights failed.")
wmean <- function(x, w = ann$weight) sum(w * x) / sum(w)
neff <- function(w) sum(w)^2 / sum(w^2)
wci <- function(x, w = ann$weight) {
  p <- wmean(x, w); n <- neff(w); z <- wilson(p * n, n)
  c(rate = 100 * p, lo = 100 * z[1], hi = 100 * z[2], n_eff = n)
}

pct <- function(x, w = ann$weight) sprintf("%.1f%%", 100 * wmean(x, w))
ci  <- function(x, w = ann$weight) { z <- wci(x, w); sprintf("[%.1f, %.1f]", z["lo"], z["hi"]) }

cat("\n===== R1 — is the detected doctrine actually INVOKED? =====\n")
print(table(ann$r1_invocation))
gen <- ann$r1_invocation == "genuine"
cat(sprintf("\nprecision (genuine): %s %s   n = %d\n", pct(gen), ci(gen), length(gen)))
cat(sprintf("genuine + mention (doctrine really present, detector not in error): %s %s\n",
            pct(ann$r1_invocation != "false"), ci(ann$r1_invocation != "false")))

cat("\nby era (the axis the recency argument turns on):\n")
for (e in sort(unique(ann$era))) {
  take <- ann$era == e; x <- gen[take]; w <- ann$weight[take]
  cat(sprintf("  %-12s %2d/%2d  %s %s\n", e, sum(x), length(x), pct(x, w), ci(x, w)))
}
cat("\nby outlet band (concentration check — the largest outlet is 32.0%% of the population):\n")
for (b in c("top1", "top2_3", "top4_10", "rest")) {
  take <- ann$band == b; x <- gen[take]; w <- ann$weight[take]
  if (length(x)) cat(sprintf("  %-8s %2d/%2d  %s %s\n", b, sum(x), length(x), pct(x, w), ci(x, w)))
}

cat("\n===== R2 — is the adjacent ECONOMIC term a real economic reference? =====\n")
ec <- ann$r2_econ_true == "yes"
cat(sprintf("overall: %s %s\n", pct(ec), ci(ec)))
cat("\nby domain tier of the post (A = system/aggregate, B = sectoral, C = lived):\n")
for (t in sort(unique(ann$domain_tier))) {
  take <- ann$domain_tier == t; x <- ec[take]; w <- ann$weight[take]
  cat(sprintf("  %-6s %2d/%2d  %s %s\n", t, sum(x), length(x), pct(x, w), ci(x, w)))
}

cat("\nby nearest adjacent economic subject (the predeclared R2 gate):\n")
by_domain <- do.call(rbind, lapply(names(ME_ECON), function(d) {
  take <- ann$audit_domain == d
  if (!any(take)) return(data.frame(domain = d, k = 0L, n = 0L, rate = NA_real_,
                                    lo = NA_real_, hi = NA_real_, n_eff = NA_real_))
  z <- wci(ec[take], ann$weight[take])
  data.frame(domain = d, k = sum(ec[take]), n = sum(take), rate = round(z["rate"], 1),
             lo = round(z["lo"], 1), hi = round(z["hi"], 1), n_eff = round(z["n_eff"], 1))
}))
print(by_domain, row.names = FALSE)
r2_complete <- all(by_domain$n > 0L)
r2_green <- by_domain$rate[by_domain$domain == "green_energy"]
r2_below <- by_domain$domain[by_domain$n > 0L & by_domain$rate < 70]
cat(sprintf("R2 gate: %s; green = %.1f%%; unsampled domains = %d; sampled domains below 70%%: %s\n",
            if (r2_complete && r2_green >= 80 && !length(r2_below)) "PASS" else "FAIL/UNEVALUABLE",
            r2_green, sum(by_domain$n == 0L), if (length(r2_below)) paste(r2_below, collapse = ", ") else "none"))
cat("\njointly genuine invocation AND real economic term:\n")
both <- gen & ec
cat(sprintf("  %s %s  (%d of %d cards)\n", pct(both), ci(both), sum(both), length(both)))

cat("\n===== VERDICT AGAINST THE PRE-DECLARED RULE (PROPOSAL_v5 V.1) =====\n")
p <- wmean(gen)
cat(sprintf("R1 precision = %.3f -> %s\n", p,
            if (p >= 0.80) "PASS: report the rate as measured"
            else if (p >= 0.60) "CONDITIONAL: report both raw and precision-adjusted"
            else "FAIL: the headline number cannot be published as-is"))

axes <- list(gen, ann$r1_invocation != "false", ec, both)
ww <- t(vapply(axes, wci, numeric(4)))
out <- data.frame(
  axis = c("r1_genuine", "r1_not_false", "r2_econ_true", "r1_and_r2"),
  k = c(sum(gen), sum(ann$r1_invocation != "false"), sum(ec), sum(both)),
  n = nrow(ann), stringsAsFactors = FALSE)
out$rate <- round(ww[, "rate"], 1)
out$lo <- round(ww[, "lo"], 1); out$hi <- round(ww[, "hi"], 1)
out$n_eff <- round(ww[, "n_eff"], 1)
sem_write_shareable(out, file.path(ME_OUT, "r1_numerator_precision.csv"))

by_era <- do.call(rbind, lapply(sort(unique(ann$era)), function(e) {
  take <- ann$era == e; x <- gen[take]; w <- ann$weight[take]; z <- wci(x, w)
  data.frame(era = e, k = sum(x), n = length(x), rate = round(z["rate"], 1),
             lo = round(z["lo"], 1), hi = round(z["hi"], 1), n_eff = round(z["n_eff"], 1))
}))
sem_write_shareable(by_era, file.path(ME_OUT, "r1_precision_by_era.csv"))
sem_write_shareable(by_domain, file.path(ME_OUT, "r1_precision_by_domain.csv"))
cat("\nwrote output/{r1_numerator_precision,r1_precision_by_era,r1_precision_by_domain}.csv\n")
