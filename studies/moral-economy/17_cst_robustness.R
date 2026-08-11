#!/usr/bin/env Rscript
# moral-economy — ROBUSTNESS PROGRAMME for the RSP paper (PROPOSAL_v5_rsp.md Part V).
#
# Recomputes the domain invocation gradient under every stress the design allows and assembles the
# summary table reserved by Part V.6. Read-only with respect to every input; writes shareable
# domain-level aggregates to output/ and the outlet-keyed detail to output/private/.
#
#   Rscript studies/moral-economy/17_cst_robustness.R
#
# ---------------------------------------------------------------------------------------------------
# GRAIN — the thing that makes this script correct, and that v1 of it got wrong.
#
# Rates are doctrinal-domain-mentions / linked-domain-mentions. Both are counted on (rid, domain)
# PAIRS, not on posts. A robustness variant that drops candidate ROWS therefore has to drop the
# matching numerator PAIRS too. v1 filtered the numerator on rid alone, so a post whose (rid, domain)
# row had been removed could still contribute to that domain's numerator — inflating every rate whose
# variant filtered at row level. gradient() now semi-joins the numerator to the surviving pairs.
# Gate G1b asserts that every core pair exists among the candidate pairs in the first place.
#
# De-duplication is done at POST level (a duplicate article is a duplicate regardless of which domain
# matched), which keeps each surviving post's full domain structure intact.
# ---------------------------------------------------------------------------------------------------
#
# VARIANTS
#   baseline            the published gradient
#   dedup_window        R5  — one post per near-duplicate text cluster (syndication / boilerplate)
#   dedup_title         R5  — one post per normalised-title cluster
#   domestic            R11 — foreign-flagged posts removed (Vatican wire coverage)
#   ex_metaphor         R3  — metaphorical economic mentions removed (row-level, inflation only)
#   ex_caritas          the Caritas-organisation confound
#   stream_*            R12 — within each time-segregated collection stream (NOT a trend)
#   loo_NN / loo_topNN  R6  — leave-one-outlet-out and cumulative top-k removal
#   secular_min/max     R7  — outlet-label sensitivity, narrowest and widest plausible secular set
#   confessional_only   R7  — the contrast case
#
# PASS = green_energy still ranked first AND its Wilson interval disjoint from the runner-up's.
suppressPackageStartupMessages({
  library(here); library(dplyr); library(tidyr); library(stringi)
})
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/cst_core.R"))

OUT     <- ME_OUT
PRIVATE <- ME_PRIVATE
stopifnot(dir.exists(OUT), dir.exists(PRIVATE))

# Wilson score interval — same estimator as sem_lib::wilson(); reproduced locally so this script has
# no load-order dependency. Self-checked against the published green_energy CI at gate G2.
wilson <- function(x, n, conf = 0.95) {
  z <- stats::qnorm(1 - (1 - conf) / 2)
  p <- ifelse(n > 0, x / n, NA_real_)
  d <- 1 + z^2 / n
  c0 <- (p + z^2 / (2 * n)) / d
  h  <- (z / d) * sqrt(p * (1 - p) / n + z^2 / (4 * n^2))
  data.frame(rate = p, lo = pmax(0, c0 - h), hi = pmin(1, c0 + h))
}

cat("== 17_cst_robustness.R ==\n")

## ---------------------------------------------------------------------- inputs
rsp_assert_official_inputs()
cand <- readRDS(RSP_STAGEA_CANDIDATES)
core <- cst_build_core(verbose = FALSE)
cat("candidates:", nrow(cand), "rows /", dplyr::n_distinct(cand$rid), "posts\n")
cat("core      :", nrow(core), "posts\n")

core_long <- cst_core_pairs(core) |>
  dplyr::select(rid, domain) |>
  dplyr::distinct()
cat("core domain-mentions:", nrow(core_long), "\n")

## ------------------------------------------------------------------- gate G1
if (nrow(core_long) < nrow(core) || !setequal(unique(core_long$rid), core$rid)) {
  stop("GATE G1 FAILED - the pair view does not cover every core post.")
}
cat("GATE G1 ok - every stored pair has same-domain CST adjacency (",
    nrow(core), "posts /", nrow(core_long), "pairs )\n")

## ------------------------------------------------------------------ gate G1b
cand_pairs <- dplyr::distinct(cand, rid, domain)
orphans <- dplyr::anti_join(core_long, cand_pairs, by = c("rid", "domain"))
if (nrow(orphans) > 0) {
  cat("GATE G1b FAILED -", nrow(orphans), "core (rid,domain) pairs absent from the candidate layer.\n")
  print(utils::head(as.data.frame(orphans), 10))
  stop("Numerator is not a subset of the denominator. Every rate below would be ill-defined.")
}
cat("GATE G1b ok - every core pair exists in the candidate layer (numerator subset of denominator)\n")

## -------------------------------------------------- normalised text keys (R5)
norm_txt <- function(x) {
  x <- stringi::stri_trans_tolower(as.character(x))
  x <- stringi::stri_replace_all_regex(x, "[^\\p{L}\\p{N}]+", " ")
  stringi::stri_trim_both(stringi::stri_replace_all_regex(x, "\\s+", " "))
}
cand <- cand |>
  dplyr::mutate(k_win = substr(norm_txt(window), 1, 300),
                k_tit = norm_txt(TITLE))

# POST-level keys: one key per post, chosen deterministically from its longest window.
post_keys <- cand |>
  dplyr::arrange(rid, domain) |>
  dplyr::group_by(rid) |>
  dplyr::summarise(k_win = k_win[which.max(nchar(window))][1],
                   k_tit = k_tit[1], .groups = "drop")

dup_report <- function(key) {
  valid <- !is.na(post_keys[[key]]) & nzchar(post_keys[[key]])
  d <- post_keys[valid, , drop = FALSE] |>
    dplyr::count(.data[[key]], name = "cluster_size")
  list(dist = dplyr::count(d, cluster_size, name = "n_clusters"),
       n_multi = sum(d$cluster_size > 1), max = max(d$cluster_size),
       absorbed = sum(d$cluster_size) - nrow(d),
       keep = post_keys[valid, , drop = FALSE] |>
         dplyr::group_by(.data[[key]]) |> dplyr::slice_min(rid, n = 1, with_ties = FALSE) |>
         dplyr::ungroup() |> dplyr::pull(rid) |>
         c(post_keys$rid[!valid]))
}
dw <- dup_report("k_win"); dt <- dup_report("k_tit")
n_posts0 <- dplyr::n_distinct(cand$rid)
cat("\n-- R5 near-duplicate clusters (POST level) --\n")
cat(sprintf("window key: %d clusters >1, largest %d, posts removed %d (%.1f%% of %d)\n",
            dw$n_multi, dw$max, n_posts0 - length(dw$keep), 100*(n_posts0 - length(dw$keep))/n_posts0, n_posts0))
cat(sprintf("title  key: %d clusters >1, largest %d, posts removed %d (%.1f%% of %d)\n",
            dt$n_multi, dt$max, n_posts0 - length(dt$keep), 100*(n_posts0 - length(dt$keep))/n_posts0, n_posts0))

## --------------------------------------------------------------- the engine
gradient <- function(cd, variant) {
  pairs <- dplyr::distinct(cd, rid, domain)
  den <- dplyr::count(pairs, domain, name = "linked")
  num <- core_long |> dplyr::semi_join(pairs, by = c("rid", "domain")) |>
    dplyr::count(domain, name = "doctrinal")
  out <- den |> dplyr::left_join(num, by = "domain") |>
    dplyr::mutate(doctrinal = tidyr::replace_na(doctrinal, 0L))
  dplyr::bind_cols(out, wilson(out$doctrinal, out$linked)) |>
    dplyr::mutate(variant = variant) |> dplyr::arrange(dplyr::desc(rate))
}

verdict <- function(g, cd) {
  g <- dplyr::arrange(g, dplyr::desc(rate))
  gi <- which(g$domain == "green_energy")
  if (!length(gi)) return(NULL)
  oth <- g[g$domain != "green_energy", ]
  nb  <- oth[which.max(oth$rate), ]
  data.frame(variant = g$variant[1],
             posts = dplyr::n_distinct(cd$rid), pairs = nrow(dplyr::distinct(cd, rid, domain)),
             top_domain = g$domain[1],
             green_rate = round(100 * g$rate[gi], 2),
             next_domain = nb$domain, next_rate = round(100 * nb$rate, 2),
             ratio = round(g$rate[gi] / nb$rate, 2),
             green_first = identical(g$domain[1], "green_energy"),
             intervals_disjoint = g$lo[gi] > nb$hi,
             stringsAsFactors = FALSE)
}

variants <- list(); res <- list()
add <- function(name, cd) {
  g <- gradient(cd, name); variants[[name]] <<- g; res[[name]] <<- verdict(g, cd); invisible(NULL)
}

## ------------------------------------------------------------- baseline + G2
add("baseline", cand)
gb <- variants[["baseline"]]; gr <- gb[gb$domain == "green_energy", ]
green_den <- sum(cand_pairs$domain == "green_energy")
green_num <- sum(core_long$domain == "green_energy")
cat(sprintf("\nGATE G2 - official baseline green %.2f%% [%0.2f, %.2f] (%d/%d pairs)\n",
            100*gr$rate, 100*gr$lo, 100*gr$hi, green_num, green_den))
if (nrow(gr) != 1L || gr$linked != green_den || gr$doctrinal != green_num ||
    abs(gr$rate - green_num / green_den) > 1e-12) {
  stop("GATE G2 FAILED - baseline does not reconcile to the official numerator/denominator pairs.")
}
cat("GATE G2 ok - independently counted official pairs reproduce the baseline\n")

## ---------------------------------------------------------------- R5 / R11 / R3
add("dedup_window", dplyr::filter(cand, rid %in% dw$keep))
add("dedup_title",  dplyr::filter(cand, rid %in% dt$keep))

# foreign_hint / actor_only_caritas: verify they are post-level before treating them as such.
mixed_fh <- cand |> dplyr::group_by(rid) |> dplyr::summarise(k = dplyr::n_distinct(foreign_hint)) |>
  dplyr::filter(k > 1) |> nrow()
cat("\nposts with mixed foreign_hint across their domain rows:", mixed_fh,
    if (mixed_fh == 0) "(post-level flag, as assumed)\n" else "(row-level; pair semi-join handles it)\n")
add("domestic",    dplyr::filter(cand, !foreign_hint))
add("ex_metaphor", dplyr::filter(cand, !infl_metaphor_hint))
add("ex_caritas",  dplyr::filter(cand, !actor_only_caritas))

## ------------------------------------------------------------------- R12 streams
for (s in sort(unique(cand$stream))) add(paste0("stream_", s), dplyr::filter(cand, stream == s))

## --------------------------------------------------------------------- R6 outlets
top_outlets <- core |> dplyr::filter(!is.na(actor)) |> dplyr::count(actor, sort = TRUE) |> utils::head(10)
loo_map <- data.frame(rank = seq_len(nrow(top_outlets)), outlet = top_outlets$actor,
                      core_posts = top_outlets$n, stringsAsFactors = FALSE)
for (i in seq_len(nrow(loo_map)))
  add(sprintf("loo_%02d", i), dplyr::filter(cand, is.na(FROM) | FROM != loo_map$outlet[i]))
for (k in c(1, 3, 5, 10))
  add(sprintf("loo_top%02d", k), dplyr::filter(cand, is.na(FROM) | !(FROM %in% loo_map$outlet[seq_len(k)])))

## ---------------------------------------------------------------------- R7 labels
prop_path <- file.path(PRIVATE, "proposed_source_labels.csv")
lab <- dplyr::mutate(cand, lab0 = as.character(label), lab1 = as.character(label))
if (!file.exists(prop_path)) {
  stop("R7 proposal-based outlet sensitivity requires: ", prop_path,
       "\nRun 15_propose_source_labels.R first.", call. = FALSE)
}
pl  <- utils::read.csv(prop_path, fileEncoding = "UTF-8", stringsAsFactors = FALSE)
key <- intersect(c("FROM", "from", "source", "outlet", "actor"), names(pl))[1]
val <- intersect(c("label", "proposed_label", "label_proposed", "type"), names(pl))[1]
if (is.na(key) || is.na(val) || anyDuplicated(pl[[key]])) {
  stop("R7 proposal file is malformed or has duplicate outlet keys.", call. = FALSE)
}
map <- stats::setNames(pl[[val]], pl[[key]])
lab <- lab |> dplyr::mutate(
  lab1 = ifelse(lab0 %in% c("confessional", "secular"), lab0,
                ifelse(FROM %in% names(map), unname(map[FROM]), lab0)))
cat(sprintf("\nR7: joined %d unratified proposed labels on '%s' -> '%s' (sensitivity only)\n",
            nrow(pl), key, val))
lab_share <- round(100 * mean(lab$lab1 %in% c("confessional", "secular")), 1)
cat("R7: share of candidate rows carrying a confessional/secular label:", lab_share, "%\n")

# secular_min: only outlets explicitly labelled secular (narrowest).
# secular_max: labelled secular PLUS every still-unlabelled outlet (widest / most adversarial —
#              it maximises the chance that confessional material is hiding inside "secular").
add("secular_min",       dplyr::filter(lab, lab1 == "secular"))
add("secular_max",       dplyr::filter(lab, lab1 == "secular" | !(lab1 %in% c("confessional", "secular"))))
add("confessional_only", dplyr::filter(lab, lab1 == "confessional"))

## ------------------------------------------------------------------- assemble
summary_tbl <- dplyr::bind_rows(res)
detail_tbl  <- dplyr::bind_rows(variants) |>
  dplyr::mutate(rate = round(100*rate, 3), lo = round(100*lo, 3), hi = round(100*hi, 3)) |>
  dplyr::select(variant, domain, linked, doctrinal, rate, lo, hi)

cat("\n===================== ROBUSTNESS SUMMARY =====================\n")
print(as.data.frame(summary_tbl), row.names = FALSE)
cat("\ngreen_energy first in", sum(summary_tbl$green_first), "of", nrow(summary_tbl), "variants;",
    "intervals disjoint in", sum(summary_tbl$intervals_disjoint), "of", nrow(summary_tbl), "\n")
if (any(!summary_tbl$green_first))
  cat("NOT FIRST in:", paste(summary_tbl$variant[!summary_tbl$green_first], collapse = ", "), "\n")
if (any(!summary_tbl$intervals_disjoint))
  cat("OVERLAPPING in:", paste(summary_tbl$variant[!summary_tbl$intervals_disjoint], collapse = ", "), "\n")

# SHAREABLE — domain-level only; outlets appear as ranks, never as names.
utils::write.csv(summary_tbl, file.path(OUT, "cst_robustness_summary.csv"), row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(detail_tbl,  file.path(OUT, "cst_robustness_detail.csv"),  row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(dplyr::bind_rows(dplyr::mutate(dw$dist, key = "window"),
                                  dplyr::mutate(dt$dist, key = "title")),
                 file.path(OUT, "cst_duplicate_clusters.csv"), row.names = FALSE, fileEncoding = "UTF-8")
# RESTRICTED — the rank -> outlet key.
utils::write.csv(loo_map, file.path(PRIVATE, "cst_loo_outlet_key.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("\nwrote output/{cst_robustness_summary,cst_robustness_detail,cst_duplicate_clusters}.csv\n")
cat("wrote output/private/cst_loo_outlet_key.csv (RESTRICTED - names outlets)\n")
