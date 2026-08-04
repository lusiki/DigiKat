#!/usr/bin/env Rscript
# moral-economy R1/R2 — WHAT THE 150-CARD NUMERATOR AUDIT SAYS ABOUT THE 1,198.
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

cat("=== R1/R2 — numerator precision ===\n")
sheet <- read.csv(file.path(ME_PRIVATE, "r1_sheet.csv"), fileEncoding = "UTF-8", stringsAsFactors = FALSE)
ann   <- read.delim(file.path(ME_PRIVATE, "r1_ann1.tsv"), fileEncoding = "UTF-8", stringsAsFactors = FALSE)
key   <- read.csv(file.path(ME_PRIVATE, "r1_key.csv"), fileEncoding = "UTF-8", stringsAsFactors = FALSE)

digikat_require_columns(ann, c("item", "rid", "r1_invocation", "r2_econ_true"), "r1_ann1.tsv")
m <- match(ann$item, sheet$item)
if (anyNA(m) || any(sheet$rid[m] != ann$rid)) stop("rid mismatch between annotation and sheet.", call. = FALSE)
if (!all(ann$r1_invocation %in% c("genuine", "mention", "false"))) stop("bad r1 value", call. = FALSE)
if (!all(ann$r2_econ_true %in% c("yes", "no"))) stop("bad r2 value", call. = FALSE)
sem_gate_report("R1a annotation integrity", TRUE, sprintf("%d cards, rid matched", nrow(ann)))

k <- key[match(ann$rid, key$rid), ]
ann$era <- k$era; ann$band <- k$band; ann$domain_tier <- k$domain_tier

pct <- function(x) sprintf("%.1f%%", 100 * mean(x))
ci  <- function(x) { w <- wilson(sum(x), length(x)); sprintf("[%.1f, %.1f]", 100 * w[1], 100 * w[2]) }

cat("\n===== R1 — is the detected doctrine actually INVOKED? =====\n")
print(table(ann$r1_invocation))
gen <- ann$r1_invocation == "genuine"
cat(sprintf("\nprecision (genuine): %s %s   n = %d\n", pct(gen), ci(gen), length(gen)))
cat(sprintf("genuine + mention (doctrine really present, detector not in error): %s %s\n",
            pct(ann$r1_invocation != "false"), ci(ann$r1_invocation != "false")))

cat("\nby era (the axis the recency argument turns on):\n")
for (e in sort(unique(ann$era))) {
  x <- gen[ann$era == e]
  cat(sprintf("  %-12s %2d/%2d  %s %s\n", e, sum(x), length(x), pct(x), ci(x)))
}
cat("\nby outlet band (concentration check — the largest outlet is 32.0%% of the population):\n")
for (b in c("top1", "top2_3", "top4_10", "rest")) {
  x <- gen[ann$band == b]
  if (length(x)) cat(sprintf("  %-8s %2d/%2d  %s %s\n", b, sum(x), length(x), pct(x), ci(x)))
}

cat("\n===== R2 — is the adjacent ECONOMIC term a real economic reference? =====\n")
ec <- ann$r2_econ_true == "yes"
cat(sprintf("overall: %s %s\n", pct(ec), ci(ec)))
cat("\nby domain tier of the post (A = system/aggregate, B = sectoral, C = lived):\n")
for (t in sort(unique(ann$domain_tier))) {
  x <- ec[ann$domain_tier == t]
  cat(sprintf("  %-6s %2d/%2d  %s %s\n", t, sum(x), length(x), pct(x), ci(x)))
}
cat("\njointly genuine invocation AND real economic term:\n")
both <- gen & ec
cat(sprintf("  %s %s  (%d of %d cards)\n", pct(both), ci(both), sum(both), length(both)))

cat("\n===== VERDICT AGAINST THE PRE-DECLARED RULE (PROPOSAL_v5 V.1) =====\n")
p <- mean(gen)
cat(sprintf("R1 precision = %.3f -> %s\n", p,
            if (p >= 0.80) "PASS: report the rate as measured"
            else if (p >= 0.60) "CONDITIONAL: report both raw and precision-adjusted"
            else "FAIL: the headline number cannot be published as-is"))

out <- data.frame(
  axis = c("r1_genuine", "r1_not_false", "r2_econ_true", "r1_and_r2"),
  k = c(sum(gen), sum(ann$r1_invocation != "false"), sum(ec), sum(both)),
  n = nrow(ann), stringsAsFactors = FALSE)
w <- t(mapply(wilson, out$k, out$n))
out$rate <- round(100 * out$k / out$n, 1)
out$lo <- round(100 * w[, 1], 1); out$hi <- round(100 * w[, 2], 1)
sem_write_shareable(out, file.path(ME_OUT, "r1_numerator_precision.csv"))

by_era <- do.call(rbind, lapply(sort(unique(ann$era)), function(e) {
  x <- gen[ann$era == e]; w <- wilson(sum(x), length(x))
  data.frame(era = e, k = sum(x), n = length(x), rate = round(100 * mean(x), 1),
             lo = round(100 * w[1], 1), hi = round(100 * w[2], 1))
}))
sem_write_shareable(by_era, file.path(ME_OUT, "r1_precision_by_era.csv"))
cat("\nwrote output/{r1_numerator_precision,r1_precision_by_era}.csv\n")
