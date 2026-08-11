#!/usr/bin/env Rscript
# moral-economy — RE-ANALYSIS OF THE EXISTING 555-ITEM GOLD SET for the RSP paper.
#
# PROPOSAL_v5 (Part V, R4) recorded that Stage A linkage precision "has never been coded". That was
# WRONG: `08_build_gold_sheet.R` / `09b_iaa_validate.R` produced a 555-item adjudicated set carrying an
# `ax1_link_genuine` axis (Fleiss kappa 0.941), and PAPER_v1.md §4.1 already reports the pooled figure
# (34.6% genuine). What was never produced is the PER-DOMAIN breakdown, which is the quantity the RSP
# paper's gradient actually depends on. This script produces it, plus two by-products the paper needs.
#
#   Rscript studies/moral-economy/18_gold_reanalysis.R
#
# A. R4 — genuine-link rate by economic domain, with Wilson intervals.
# B. §6 — hand-coded register (charity / justice / object) by domain, on genuine links only.
# C. R1 — agreement between the human "names an encyclical / KSN principle" codes and Tier-1 core
#         membership, as an external check on the doctrine detector.
#
# SAMPLING CAVEAT, and it is the whole ballgame: the 555 is a STRATIFIED set built for several purposes
# (domain_core, poverty_split, precision_gap, random_linked, recall_gap, register_cell). Only the
# `random_linked` stratum is an unbiased draw from the linked layer. Every quantity is therefore reported
# BOTH on random_linked alone (unbiased, small n) and on all strata (larger n, biased). Where they
# disagree, the random_linked figure is the one that may be generalised.
suppressPackageStartupMessages({ library(here); library(dplyr); library(tidyr) })
source(here::here("studies/moral-economy/rsp_input.R"))
source(here::here("studies/moral-economy/cst_core.R"))

OUT <- here::here("studies/moral-economy/output"); PRIVATE <- file.path(OUT, "private")

wilson <- function(x, n, conf = 0.95) {
  z <- stats::qnorm(1 - (1 - conf) / 2); p <- ifelse(n > 0, x / n, NA_real_)
  d <- 1 + z^2 / n; c0 <- (p + z^2 / (2 * n)) / d
  h <- (z / d) * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))
  data.frame(rate = round(100 * p, 1), lo = round(100 * pmax(0, c0 - h), 1),
             hi = round(100 * pmin(1, c0 + h), 1))
}

gold <- utils::read.csv(file.path(PRIVATE, "gold_core.csv"), fileEncoding = "UTF-8",
                        stringsAsFactors = FALSE)
cand <- readRDS(RSP_STAGEA_CANDIDATES)
cand$rid <- as.integer(cand$rid)
pair_key <- paste(cand$rid, cand$domain, sep = "\r")
gold_key <- paste(as.integer(gold$rid), gold$domain, sep = "\r")
n_legacy <- nrow(gold)
gold <- gold[gold_key %in% pair_key, , drop = FALSE]
cat("gold rows retained in the official linked layer:", nrow(gold), "of", n_legacy, "\n")
cat("strata:\n"); print(table(gold$stratum))
cat("\npooled retained-set genuine-link rate:",
    round(100 * mean(gold$ax1_link_genuine == "genuine"), 1), "%\n")

## ---------------------------------------------------------- A. R4 by domain
by_dom <- function(d, tag) {
  s <- d |> dplyr::group_by(domain) |>
    dplyr::summarise(n = dplyr::n(), genuine = sum(ax1_link_genuine == "genuine"), .groups = "drop")
  dplyr::bind_cols(s, wilson(s$genuine, s$n)) |> dplyr::mutate(subset = tag) |>
    dplyr::arrange(dplyr::desc(rate))
}
rl <- dplyr::filter(gold, stratum == "random_linked")
cat("\n===== A. GENUINE-LINK RATE BY DOMAIN =====\n")
cat("\n-- random_linked stratum only (unbiased; n =", nrow(rl), ") --\n")
a_rl <- by_dom(rl, "random_linked"); print(as.data.frame(a_rl), row.names = FALSE)
cat("\n-- all strata (n =", nrow(gold), "; BIASED by design, for comparison only) --\n")
a_all <- by_dom(gold, "all_strata"); print(as.data.frame(a_all), row.names = FALSE)

# Does linkage precision vary by domain?
# The unbiased stratum (n = 28) cannot support any test - at most one domain reaches n >= 5. Say so
# rather than running a test that silently degenerates into a goodness-of-fit on a single row.
tb_rl <- table(rl$domain, rl$ax1_link_genuine == "genuine")
cat("\nrandom_linked: domains reaching n>=5:", sum(rowSums(tb_rl) >= 5), "of", nrow(tb_rl),
    "- TOO SMALL FOR ANY TEST. No inference is drawn from this stratum.\n")

# On all strata the sample is biased, but the question "does the genuine rate differ across domains
# WITHIN this sample" is still answerable and is informative about the size of the threat.
tb_all <- table(gold$domain, gold$ax1_link_genuine == "genuine")
ct <- suppressWarnings(stats::chisq.test(tb_all))
cat("\nchi-square, genuine ~ domain (ALL STRATA - biased sample, descriptive only):\n")
cat(sprintf("  X-squared = %.1f, df = %d, p = %s\n", ct$statistic, ct$parameter,
            format.pval(ct$p.value, digits = 3)))
cat("  range of genuine rates across domains:", min(a_all$rate), "% to", max(a_all$rate), "%\n")
cat("  INTERPRETATION: within this (non-random) sample the genuine-link rate varies by more than an\n",
    "  order of magnitude across domains. That is the R4 threat made concrete. It does NOT establish\n",
    "  the size of the effect in the linked layer, because the sample was not drawn for that purpose.\n")

## --------------------------------------------- precision-adjusted gradient
cat("\n===== PRECISION-ADJUSTED GRADIENT (the R4 correction) =====\n")
core <- cst_build_core(verbose = FALSE)
core_long <- cst_core_pairs(core) |> dplyr::select(rid, domain) |> dplyr::distinct()
den <- cand |> dplyr::distinct(rid, domain) |> dplyr::count(domain, name = "linked")
num <- dplyr::count(core_long, domain, name = "doctrinal")

adj <- den |> dplyr::left_join(num, by = "domain") |>
  dplyr::mutate(doctrinal = tidyr::replace_na(doctrinal, 0L)) |>
  dplyr::left_join(dplyr::select(a_rl, domain, prec_rl = rate, prec_lo = lo, prec_hi = hi),
                   by = "domain") |>
  dplyr::left_join(dplyr::select(a_all, domain, prec_all = rate), by = "domain") |>
  dplyr::mutate(
    raw_rate  = round(100 * doctrinal / linked, 2),
    adj_rate  = round(100 * doctrinal / (linked * prec_rl / 100), 2),
    adj_rate_allstrata = round(100 * doctrinal / (linked * prec_all / 100), 2)) |>
  dplyr::arrange(dplyr::desc(raw_rate))
print(as.data.frame(adj), row.names = FALSE)

cat("\nRank correlation raw vs precision-adjusted (random_linked): ",
    round(stats::cor(adj$raw_rate, adj$adj_rate, method = "spearman", use = "complete.obs"), 3), "\n")
cat("Top domain raw:", adj$domain[which.max(adj$raw_rate)],
    "| adjusted:", adj$domain[which.max(adj$adj_rate)], "\n")

## --------------------------------------------- B. register by domain (hand-coded)
cat("\n===== B. HAND-CODED REGISTER BY DOMAIN (genuine links only) =====\n")
gen <- dplyr::filter(gold, ax1_link_genuine == "genuine")
cat("genuine links:", nrow(gen), "\n")
reg <- gen |> dplyr::count(domain, ax4_3way) |>
  tidyr::pivot_wider(names_from = ax4_3way, values_from = n, values_fill = 0) |>
  dplyr::mutate(n = rowSums(dplyr::across(where(is.numeric))))
pct <- reg |> dplyr::mutate(dplyr::across(-c(domain, n), ~ round(100 * .x / n, 1)))
print(as.data.frame(dplyr::arrange(pct, dplyr::desc(n))), row.names = FALSE)

pov <- dplyr::filter(gen, domain == "poverty_social")
oth <- dplyr::filter(gen, domain != "poverty_social")
cat("\npoverty vs rest (3-way register, genuine links):\n")
cat(sprintf("  poverty (n=%d): charity %.1f%%  justice %.1f%%\n", nrow(pov),
            100*mean(pov$ax4_3way == "charity"), 100*mean(pov$ax4_3way == "justice")))
cat(sprintf("  others  (n=%d): charity %.1f%%  justice %.1f%%\n", nrow(oth),
            100*mean(oth$ax4_3way == "charity"), 100*mean(oth$ax4_3way == "justice")))

## --------------------------------------------- C. R1 external check on the detector
cat("\n===== C. DOCTRINE DETECTOR vs HUMAN CODES =====\n")
gold$in_core   <- as.integer(gold$rid) %in% core$rid
gold$human_cst <- gold$ax7_encyclical != "none" | gold$ax6_ksn_principle != "none"
tt <- table(detector_core = gold$in_core, human_names_cst = gold$human_cst)
print(tt)
if (all(dim(tt) == c(2, 2))) {
  tp <- tt["TRUE", "TRUE"]; fp <- tt["TRUE", "FALSE"]; fn <- tt["FALSE", "TRUE"]
  ci <- wilson(tp, tp + fp)
  cat(sprintf("\nprecision of core membership vs human CST coding: %.1f%% [%.1f, %.1f]  (%d/%d)\n",
              ci$rate, ci$lo, ci$hi, tp, tp + fp))
  cat(sprintf("recall: %.1f%% (%d/%d)\n", 100*tp/(tp+fn), tp, tp+fn))
  cat("NB recall is EXPECTED to be low: core membership additionally requires the doctrine term to be\n",
      "   within +/-220 chars of an economic term, which the human axes do not require.\n")
  cat("NB the precision interval is uselessly wide at n =", tp + fp, "- this is a WARNING SIGN, not an\n",
      "  estimate. R1 (a ~150-card stratified audit) is still required and is not substituted by this.\n")
}
cat("\noverlap of retained gold set with the", nrow(core),
    "post doctrinal population:", sum(gold$in_core), "posts\n")

## ---------------------------------------------------------------- write out
utils::write.csv(dplyr::bind_rows(a_rl, a_all), file.path(OUT, "gold_linkage_precision_by_domain.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(dplyr::select(adj, -prec_lo, -prec_hi),
                 file.path(OUT, "cst_precision_adjusted_gradient.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(pct, file.path(OUT, "gold_register_by_domain.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
input_manifest <- rsp_read_input_manifest()
gold_in_database <- if (!is.null(input_manifest$legacy_gold_survival$retained_in_official_database)) {
  input_manifest$legacy_gold_survival$retained_in_official_database
} else if (!is.null(input_manifest$legacy_gold_survival$gold_retained)) {
  input_manifest$legacy_gold_survival$gold_retained
} else if (!is.null(input_manifest$legacy_annotation_survival$gold_retained)) {
  input_manifest$legacy_annotation_survival$gold_retained
} else NA_integer_
gold_summary <- data.frame(
  legacy_rows = n_legacy,
  official_database_rows = as.integer(gold_in_database),
  official_linked_rows = nrow(gold),
  genuine_links = nrow(gen),
  displayed_n_ge_10 = sum(pct$n[pct$n >= 10]),
  stringsAsFactors = FALSE
)
utils::write.csv(gold_summary, file.path(OUT, "gold_reanalysis_summary.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
cat("\nwrote output/{gold_linkage_precision_by_domain,cst_precision_adjusted_gradient,",
    "gold_register_by_domain,gold_reanalysis_summary}.csv\n", sep = "")
