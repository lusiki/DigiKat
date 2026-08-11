#!/usr/bin/env Rscript
# moral-economy R4 — RECOMPUTE THE INVOCATION GRADIENT ON A PRECISION-CORRECTED DENOMINATOR.
#
# The gradient PROPOSAL_v5_rsp.md builds its headline on is
#     rate(d) = doctrinal(d) / linked(d)
# where linked(d) counts Stage-A keyword-linked (rid, domain) pairs. R4's threat is that linked(d)
# contains a domain-varying share of posts where religion and economics merely CO-OCCUR. If that
# share varies across domains the way it varies inside the 555-item gold set (3.1%-53.1%), the
# gradient is an artefact of the denominator, not a fact about doctrine.
#
# The official refresh draws and codes a fresh sample of 60 (rid, domain) pairs per subject. This
# script uses those Axis-1 codes for a denominator-only sensitivity analysis.
#
#   Rscript studies/moral-economy/20_r4_recompute.R
#
# TWO CODES, DELIBERATELY. The coding sheet carries `ax1_link_genuine` (the codebook reading, under
# which religious discourse that takes an economic term as its SUBJECT counts as genuine — this is
# the reading the 555-item gold set used, since it assigns a `devotional` register to genuine links)
# and `ax1_strict` (which additionally requires the economic term to have a real economic referent,
# so a homily on spiritual poverty is `incidental`). Neither is obviously right. Reporting both
# brackets the correction the way the proposal's secular_min / secular_max rows bracket R7.
#
# WHAT IS ADJUSTED, AND WHAT IS ASSUMED. Only the DENOMINATOR is deflated:
#     adj_rate(d) = doctrinal(d) / (linked(d) * precision(d))
# This is the invocation rate among GENUINELY religion-economy-linked pairs, and it assumes every
# doctrinal pair is itself a genuine link. That assumption is favourable to the denominator
# correction being large, i.e. it is the conservative direction for anyone defending the raw
# gradient. R1 evaluates the numerator separately; do not multiply post-level and pair-level audits.
#
# INTERVALS. Wilson intervals do not propagate through a ratio, so the adjusted rate's uncertainty
# is obtained by Monte Carlo over Jeffreys posteriors for each domain's precision, with the census
# counts held fixed (they are the population, not a sample). The reported quantity that matters is
# not any single adjusted rate but P(green_energy ranks first after adjustment).
suppressPackageStartupMessages({ library(here) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/rsp_input.R"))

DRAWS <- 20000L
OUT   <- ME_OUT

cat("=== R4 — precision-corrected invocation gradient ===\n")

## ---------------------------------------------------------------- gate R4a: annotation integrity
sheet <- read.csv(RSP_R4_SHEET, fileEncoding = "UTF-8",
                  stringsAsFactors = FALSE)
ann   <- read.delim(RSP_R4_ANN, fileEncoding = "UTF-8",
                    stringsAsFactors = FALSE)

# The annotation was transcribed item-by-item, so a mis-keyed rid is a live failure mode, not a
# hypothetical one. Join on `item` and assert the rid agrees; a silent mismatch would attach a
# coding decision to the wrong post and the wrong domain.
digikat_require_columns(ann, c("item", "rid", "ax1_link_genuine", "ax1_strict"), "r4_ann1.tsv")
if (nrow(ann) != nrow(sheet)) {
  stop("Annotation has ", nrow(ann), " rows, sheet has ", nrow(sheet), ".", call. = FALSE)
}
m <- match(ann$item, sheet$item)
if (anyNA(m)) stop("Annotation carries item id(s) absent from the sheet.", call. = FALSE)
bad <- which(sheet$rid[m] != ann$rid)
if (length(bad)) {
  stop("rid mismatch on item(s) ", paste(ann$item[bad], collapse = ", "),
       " — annotation says ", paste(ann$rid[bad], collapse = ", "),
       ", sheet says ", paste(sheet$rid[m][bad], collapse = ", "), ".", call. = FALSE)
}
ok <- c("genuine", "incidental")
if (!all(ann$ax1_link_genuine %in% ok) || !all(ann$ax1_strict %in% ok)) {
  stop("Axis 1 values outside {genuine, incidental}.", call. = FALSE)
}
# strict is a refinement of the codebook code: nothing may be strict-genuine but codebook-incidental
if (any(ann$ax1_strict == "genuine" & ann$ax1_link_genuine == "incidental")) {
  stop("An item is strict-genuine but codebook-incidental — the two codes are inconsistent.",
       call. = FALSE)
}
ann$domain <- sheet$domain[m]
sem_gate_report("R4a annotation integrity",
                TRUE, sprintf("%d items, rid matched to sheet, codes nested", nrow(ann)))

## ---------------------------------------------------------------- the census counts
cand <- readRDS(RSP_STAGEA_CANDIDATES)
cand$rid <- as.integer(cand$rid)
den <- as.data.frame(table(unique(cand[, c("rid", "domain")])$domain), stringsAsFactors = FALSE)
names(den) <- c("domain", "linked")

source(here::here("studies/moral-economy/cst_core.R"))
core <- cst_build_core(verbose = FALSE)
core_long <- cst_core_pairs(core)[, c("rid", "domain")]
num <- as.data.frame(table(core_long$domain), stringsAsFactors = FALSE)
names(num) <- c("domain", "doctrinal")

g <- merge(den, num, by = "domain", all.x = TRUE)
g$doctrinal[is.na(g$doctrinal)] <- 0L
g$raw_rate <- 100 * g$doctrinal / g$linked

# G2-equivalent: the baseline must reproduce the independently generated official robustness table.
gr <- g$raw_rate[g$domain == "green_energy"]
rob <- read.csv(file.path(OUT, "cst_robustness_detail.csv"), fileEncoding = "UTF-8")
gr_expected <- rob$rate[rob$variant == "baseline" & rob$domain == "green_energy"]
sem_gate_report("R4b baseline reproduction",
                length(gr_expected) == 1L && abs(gr - gr_expected) < 0.002,
                sprintf("green_energy raw rate = %.2f%% / robustness %.2f%%", gr, gr_expected))

## ---------------------------------------------------------------- per-domain linkage precision
prec <- function(code) {
  s <- aggregate(list(genuine = ann[[code]] == "genuine"), by = list(domain = ann$domain),
                 FUN = function(x) c(k = sum(x), n = length(x)))
  out <- data.frame(domain = s$domain, k = s$genuine[, "k"], n = s$genuine[, "n"],
                    stringsAsFactors = FALSE)
  ci <- t(mapply(wilson, out$k, out$n))
  out$precision <- 100 * out$k / out$n
  out$lo <- 100 * ci[, 1]; out$hi <- 100 * ci[, 2]
  out$code <- code
  out
}
p_cb <- prec("ax1_link_genuine")
p_st <- prec("ax1_strict")

cat("\n===== A. LINKAGE PRECISION BY DOMAIN (official probability sample, n = 60 per domain) =====\n")
cat("\n-- codebook reading (`ax1_link_genuine`) --\n")
print(p_cb[order(-p_cb$precision), c("domain", "k", "n", "precision", "lo", "hi")], row.names = FALSE)
cat("\n-- strict reading (`ax1_strict`: economic referent required) --\n")
print(p_st[order(-p_st$precision), c("domain", "k", "n", "precision", "lo", "hi")], row.names = FALSE)

cat(sprintf("\npooled (unweighted across domains): codebook %.1f%%  strict %.1f%%\n",
            100 * mean(ann$ax1_link_genuine == "genuine"), 100 * mean(ann$ax1_strict == "genuine")))
# The sample is allocated equally across domains, so its pooled mean is NOT the layer's precision.
# Reweight by each domain's share of the linked layer to get that.
w <- den$linked / sum(den$linked); names(w) <- den$domain
lw <- function(p) sum(p$precision * w[p$domain]) / sum(w[p$domain])
cat(sprintf("layer-weighted precision:          codebook %.1f%%  strict %.1f%%",
            lw(p_cb), lw(p_st)))
cat("   <- this is the layer estimate; the pooled sample mean is not\n")

# Does precision vary across domains at all? (Descriptive: this IS the population of the sample.)
for (nm in c("ax1_link_genuine", "ax1_strict")) {
  tb <- table(ann$domain, ann[[nm]] == "genuine")
  ct <- suppressWarnings(stats::chisq.test(tb))
  cat(sprintf("%-18s chi-square across domains: X2 = %.1f, df = %d, p = %s\n",
              nm, ct$statistic, ct$parameter, format.pval(ct$p.value, digits = 3)))
}

## ---------------------------------------------------------------- adjusted gradient + rank test
adjust <- function(p, label) {
  d <- merge(g, p[, c("domain", "k", "n", "precision")], by = "domain")
  d$adj_rate <- 100 * d$doctrinal / (d$linked * d$precision / 100)

  set.seed(ME_SEED)
  # Jeffreys posterior for each domain's precision; census counts are fixed (population, not sample)
  P <- matrix(rbeta(DRAWS * nrow(d), rep(d$k + 0.5, each = DRAWS), rep(d$n - d$k + 0.5, each = DRAWS)),
              nrow = DRAWS)
  R <- sweep(matrix(rep(100 * d$doctrinal / d$linked, each = DRAWS), nrow = DRAWS), 2, 1, "*") / P
  colnames(R) <- d$domain
  q <- t(apply(R, 2, quantile, c(0.025, 0.975), na.rm = TRUE))
  d$adj_lo <- q[match(d$domain, rownames(q)), 1]
  d$adj_hi <- q[match(d$domain, rownames(q)), 2]

  first <- colnames(R)[apply(R, 1, which.max)]
  tab <- sort(table(first), decreasing = TRUE) / DRAWS
  d$rank_first_prob <- as.numeric(tab[match(d$domain, names(tab))])
  d$rank_first_prob[is.na(d$rank_first_prob)] <- 0
  d <- d[order(-d$adj_rate), ]
  cat(sprintf("\n===== B. ADJUSTED GRADIENT — %s =====\n", label))
  print(d[, c("domain", "linked", "doctrinal", "raw_rate", "precision", "adj_rate", "adj_lo", "adj_hi")],
        row.names = FALSE, digits = 3)
  cat("\nP(ranks first after adjustment), top 3:\n")
  print(round(utils::head(tab, 3), 3))
  cat(sprintf("P(green_energy first) = %.3f\n", if ("green_energy" %in% names(tab)) tab[["green_energy"]] else 0))
  cat(sprintf("Spearman rank correlation raw vs adjusted: %.3f\n",
              stats::cor(d$raw_rate, d$adj_rate, method = "spearman")))
  d$code <- label
  d
}
a_cb <- adjust(p_cb, "ax1_link_genuine")
a_st <- adjust(p_st, "ax1_strict")

## ---------------------------------------------------------------- C1 restated on a valid base
# PROPOSAL_v5 Part III grades C1 ("doctrine is rare — 1.10%") CONTINGENT precisely because its
# denominator was unvalidated. It now is, so the headline has to be restated rather than repeated.
# Work in (rid, domain) pairs throughout: that is the unit the precision sample was drawn on, and
# mixing pair-level precision with post-level counts is the error gate G1b exists to prevent.
cat("\n===== C. DENOMINATOR-ONLY SENSITIVITY (ALL DETECTED NUMERATOR PAIRS ASSUMED GENUINE) =====\n")
pairs_all <- sum(g$linked); pairs_doc <- sum(g$doctrinal)
cat(sprintf("raw:            %s doctrinal / %s linked pairs = %.2f%%  (1 in %.0f)\n",
            digikat_format_integer(pairs_doc), digikat_format_integer(pairs_all),
            100 * pairs_doc / pairs_all, pairs_all / pairs_doc))
for (r in list(list("codebook", lw(p_cb)), list("strict", lw(p_st)))) {
  gen <- pairs_all * r[[2]] / 100
  cat(sprintf("%-8s reading: genuine pairs = %s (%.1f%% of the layer) -> %.2f%%  (1 in %.0f)\n",
              r[[1]], digikat_format_integer(round(gen)), r[[2]],
              100 * pairs_doc / gen, gen / pairs_doc))
}
cat("NB this is a denominator-only adjustment; R1 evaluates the detected numerator separately.\n")

cat("\ngreen_energy vs runner-up, before and after adjustment:\n")
for (a in list(list("raw", g[order(-g$raw_rate), "raw_rate"]),
               list("adj codebook", a_cb$adj_rate), list("adj strict", a_st$adj_rate))) {
  v <- sort(a[[2]], decreasing = TRUE)
  cat(sprintf("  %-13s %.2f%% vs %.2f%%  = %.2fx\n", a[[1]], v[1], v[2], v[1] / v[2]))
}

## ---------------------------------------------------------------- write out (aggregate only)
sem_write_shareable(rbind(p_cb, p_st)[, c("code", "domain", "k", "n", "precision", "lo", "hi")],
                    file.path(OUT, "r4_linkage_precision.csv"))
sem_write_shareable(rbind(a_cb, a_st)[, c("code", "domain", "linked", "doctrinal", "raw_rate",
                                          "precision", "adj_rate", "adj_lo", "adj_hi",
                                          "rank_first_prob")],
                    file.path(OUT, "cst_gradient_adjusted.csv"))
digikat_write_json_atomic(sem_manifest(
  generator = "studies/moral-economy/20_r4_recompute.R",
  inputs = list(sheet = "output/private/r4_sheet_official.csv",
                annotation = "output/private/r4_ann1_official.tsv",
                candidates = "output/stageA_candidates_official.rds",
                core = "output/private/cst_core_official.rds"),
  outputs = list(precision = "output/r4_linkage_precision.csv",
                 gradient = "output/cst_gradient_adjusted.csv"),
  extra = list(n_coded = nrow(ann), per_domain = as.integer(min(table(ann$domain))), draws = DRAWS,
               adjustment = "denominator only; detected numerator evaluated separately by R1")
), file.path(ME_SEM, "r4_recompute_manifest.json"))

cat("\nwrote output/{r4_linkage_precision,cst_gradient_adjusted}.csv\n")
