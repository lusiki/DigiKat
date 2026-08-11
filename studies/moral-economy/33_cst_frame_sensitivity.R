#!/usr/bin/env Rscript
# Independent frame-boundary reconstruction for the RSP paper.
#
# The main design requires a generic religion term to place a (post, domain) pair in Stage A before
# Tier-1 CST adjacency is tested. This script recomputes every Tier-1-to-domain adjacency in the
# official corpus and asks what changes if Tier-1 vocabulary itself may satisfy religion entry.
# It also independently asserts that the canonical core equals the intersection of those pairs with
# the predeclared Stage-A frame.
suppressPackageStartupMessages({ library(here); library(stringi) })
source(here::here("studies/moral-economy/sem_lib.R"))
source(here::here("studies/moral-economy/cst_core.R"))

rsp_assert_official_inputs()
cat("=== CST frame-boundary sensitivity ===\n")

prepared <- readRDS(RSP_CORPUS_PREPARED)
rid_all <- as.integer(sub("^dk_", "", prepared$doc_id))
if (anyNA(rid_all) || anyDuplicated(rid_all)) stop("Prepared corpus has an invalid rid key.")

t1 <- names(CST_TERMS)[CST_TIER %in% c("1_document", "1_marker")]
N <- nrow(prepared)
is_t1 <- logical(N)
for (a in seq(1L, N, by = 50000L)) {
  b <- min(a + 49999L, N)
  h <- cst_detect(stri_trans_tolower(prepared$text[a:b]))
  is_t1[a:b] <- rowSums(h[, t1, drop = FALSE]) > 0L
}
idx <- which(is_t1)
low <- stri_trans_tolower(prepared$text[idx])
sp_cst <- cst_locate_group(low, as.list(CST_TERMS[t1]), CST_FIXED[t1])

inclusive <- do.call(rbind, lapply(names(ME_ECON), function(d) {
  sp_domain <- cst_locate_group(low, as.list(ME_ECON[[d]]), FALSE)
  gap <- vapply(seq_along(idx), function(k) cst_gap(sp_cst[[k]], sp_domain[[k]])[1], integer(1))
  take <- !is.na(gap) & gap <= ME_WINDOW
  data.frame(rid = rid_all[idx[take]], domain = rep(d, sum(take)), gap = gap[take],
             stringsAsFactors = FALSE)
}))
inclusive <- unique(inclusive)

cand <- readRDS(RSP_STAGEA_CANDIDATES)
cand_pairs <- unique(data.frame(rid = as.integer(cand$rid), domain = as.character(cand$domain)))
key <- function(x) paste(x$rid, x$domain, sep = "\r")
cand_key <- key(cand_pairs); inclusive_key <- key(inclusive)
main_rebuilt <- inclusive[inclusive_key %in% cand_key, , drop = FALSE]
added <- inclusive[!inclusive_key %in% cand_key, , drop = FALSE]

core <- cst_build_core(verbose = FALSE)
core_pairs <- cst_core_pairs(core)[, c("rid", "domain", "gap")]
if (!setequal(key(main_rebuilt), key(core_pairs))) {
  stop("Independent full-corpus reconstruction disagrees with the canonical core pairs.", call. = FALSE)
}

count_domain <- function(x, name) {
  z <- as.data.frame(table(domain = factor(x$domain, levels = names(ME_ECON))), stringsAsFactors = FALSE)
  names(z)[2] <- name
  z
}
out <- Reduce(function(x, y) merge(x, y, by = "domain", all = TRUE), list(
  count_domain(cand_pairs, "linked_pairs_main"),
  count_domain(core_pairs, "core_pairs_main"),
  count_domain(added, "pairs_added_if_tier1_enters_frame"),
  count_domain(inclusive, "core_pairs_inclusive")))
out[is.na(out)] <- 0L
out$linked_pairs_inclusive <- out$linked_pairs_main + out$pairs_added_if_tier1_enters_frame
out$detected_rate_main <- round(100 * out$core_pairs_main / out$linked_pairs_main, 4)
out$detected_rate_inclusive <- round(100 * out$core_pairs_inclusive / out$linked_pairs_inclusive, 4)
sem_write_shareable(out, file.path(ME_OUT, "cst_frame_sensitivity.csv"))

added_posts_outside <- length(setdiff(unique(added$rid), unique(cand_pairs$rid)))
summary <- list(
  main = list(linked_posts = length(unique(cand_pairs$rid)), linked_pairs = nrow(cand_pairs),
              core_posts = nrow(core), core_pairs = nrow(core_pairs)),
  inclusive = list(linked_posts = length(unique(c(cand_pairs$rid, added$rid))),
                   linked_pairs = nrow(cand_pairs) + nrow(added),
                   core_posts = length(unique(inclusive$rid)), core_pairs = nrow(inclusive)),
  boundary = list(added_pairs = nrow(added), added_posts_outside_main_frame = added_posts_outside,
                  main_frame_posts_with_only_a_different_qualifying_domain =
                    length(setdiff(intersect(unique(added$rid), unique(cand_pairs$rid)),
                                   unique(core_pairs$rid))))
)
digikat_write_json_atomic(sem_manifest(
  generator = "studies/moral-economy/33_cst_frame_sensitivity.R",
  inputs = list(database_sha256 = rsp_read_input_manifest()$database$sha256,
                candidates_sha256 = digikat_hash_file(RSP_STAGEA_CANDIDATES),
                core_sha256 = digikat_hash_file(RSP_CORE_CACHE)),
  outputs = list(table = "output/cst_frame_sensitivity.csv",
                 table_sha256 = digikat_hash_file(file.path(ME_OUT, "cst_frame_sensitivity.csv"))),
  extra = summary
), file.path(ME_OUT, "cst_frame_sensitivity_manifest.json"))

print(out, row.names = FALSE)
cat(sprintf("main: %d posts / %d pairs; inclusive: %d posts / %d pairs; +%d denominator pairs\n",
            nrow(core), nrow(core_pairs), length(unique(inclusive$rid)), nrow(inclusive), nrow(added)))
cat("[PASS] canonical core equals the independently reconstructed Stage-A intersection\n")
