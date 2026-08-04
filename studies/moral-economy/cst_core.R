#!/usr/bin/env Rscript
# moral-economy — THE CST CORE SET (single source of truth for the analysis population).
#
# SOURCE this; never run it. `16_cst_viewer.R` renders it and `14_cst_core_profile.R` describes it.
# If each script rebuilt the population itself, the viewer could show one set of posts while the report
# described another — the drift lexicon.R, sem_lib.R and cst_lexicon.R all exist to prevent.
#
# THE DEFINITION. A post is in the core set when ALL THREE hold:
#   1. it carries Tier-1 CST vocabulary (cst_lexicon.R — an encyclical title or a doctrine coinage);
#   2. it is in the religion-linked economic layer (stageA_candidates.rds: an economic domain matched
#      AND a religious term fell within +-220 chars of that economic match);
#   3. the CST term is itself within +-220 chars of an economic term (ME_WINDOW).
#
# Condition 3 is the one added on 2026-08-04. Without it the census counted any post that mentioned
# doctrine ANYWHERE, so a long article could discuss inflation early and cite Laudato si' in an unrelated
# closing paragraph and still count. Condition 3 costs 1,677 of the 2,875 loose posts and buys a
# population where every member has doctrine genuinely adjacent to economics.
#
# NOTE the 30: posts satisfying 1 and 3 but NOT 2. Their CST term sits beside an economic term, yet no
# religious word from the 95-term lexicon fell near the economic match — because "socijalni nauk" and
# encyclical titles are not IN that lexicon. They are excluded here (condition 2 is the study's frame)
# but reported, never silently dropped.
suppressPackageStartupMessages({ library(here); library(stringi) })
source(here::here("studies/moral-economy/cst_lexicon.R"))
source(here::here("studies/moral-economy/lexicon.R"))

CST_CORE_CACHE <- here::here("studies/moral-economy/output/private/cst_core.rds")
CST_SLICE      <- 2000L   # chars of junction-centred text carried for downstream NLP

# One vectorized locate per pattern over all texts, then regrouped per post. The other way round
# (loop posts, loop patterns) is ~40x more regex invocations for the same answer.
cst_locate_group <- function(low, patterns, fixed) {
  M <- length(low)
  acc <- vector("list", M)
  for (j in seq_along(patterns)) {
    # fixed[[j]] not fixed[j]: isTRUE() is identical(TRUE, x), so a NAMED logical never passes it.
    L <- if (isTRUE(fixed[[j]])) stri_locate_all_fixed(low, patterns[[j]])
         else stri_locate_all_regex(low, patterns[[j]])
    for (k in seq_len(M)) {
      m <- L[[k]]
      if (!is.na(m[1, 1])) acc[[k]] <- rbind(acc[[k]], m)
    }
  }
  lapply(acc, function(m) if (is.null(m)) matrix(integer(0), 0, 2) else m[order(m[, 1]), , drop = FALSE])
}

# Character gap between the closest CST match and the closest economic match; 0 = adjacent/overlapping,
# NA = no economic match at all. Also returns the midpoint of the closest pair, used to centre excerpts.
cst_gap <- function(A, B) {
  if (!nrow(A) || !nrow(B)) return(c(NA_integer_, NA_integer_))
  g <- Inf; mid <- NA_integer_
  for (i in seq_len(nrow(A))) {
    d <- pmax(0L, pmax(A[i, 1], B[, 1]) - pmin(A[i, 2], B[, 2]) - 1L)
    j <- which.min(d)
    if (d[j] < g) {
      g <- d[j]
      mid <- as.integer((min(A[i, 1], B[j, 1]) + max(A[i, 2], B[j, 2])) %/% 2L)
    }
  }
  c(as.integer(g), mid)
}

# Build (or load) the canonical core table. `expect` fails loudly on drift: the viewer reported 1,552 on
# 2026-08-04, and if a lexicon edit silently changes the population every downstream number moves with it.
# expect = 1198: measured with TIER-1 spans only. An earlier viewer build measured the distance against
# all 28 terms and reported 1,552 — 354 of those qualified solely because a Tier-2 word ("solidarnost",
# "opće dobro") sat near the economy while the actual doctrine term was far away. Tier 2 bounds the count,
# it never defines membership, so it must not enter the distance either.
cst_build_core <- function(cache = CST_CORE_CACHE, expect = 1198L, refresh = FALSE, verbose = TRUE) {
  if (!refresh && file.exists(cache)) {
    core <- readRDS(cache)
    if (verbose) cat(sprintf("  [cached] core set: %d posts (%s)\n", nrow(core), cache))
    return(core)
  }
  corpus <- readRDS(here::here("data/semantic/corpus_prepared.rds"))
  N <- nrow(corpus)
  if (verbose) cat(sprintf("  scanning %s posts for Tier-1 CST vocabulary...\n", format(N, big.mark = ".")))

  t1_cols <- names(CST_TERMS)[CST_TIER %in% c("1_document", "1_marker")]
  hits <- matrix(FALSE, N, length(CST_TERMS), dimnames = list(NULL, names(CST_TERMS)))
  for (a in seq(1L, N, by = 50000L)) {
    b <- min(a + 49999L, N)
    hits[a:b, ] <- cst_detect(stri_trans_tolower(corpus$text[a:b]))
  }
  is_t1 <- rowSums(hits[, t1_cols, drop = FALSE]) > 0

  # condition 2 — the religion-linked economic layer
  cand <- readRDS(here::here("studies/moral-economy/output/stageA_candidates.rds"))
  cand$rid <- as.integer(cand$rid)
  dom_by_rid <- tapply(cand$domain, cand$rid, function(d) paste(sort(unique(d)), collapse = " "))
  lab_by_rid <- tapply(cand$label, cand$rid, function(x) x[1])
  rid_all <- as.integer(sub("^dk_", "", corpus$doc_id))

  cons <- which(is_t1 & rid_all %in% as.integer(names(dom_by_rid)))
  if (verbose) cat(sprintf("  Tier-1 AND econ-linked: %d posts; measuring CST<->economy distance...\n",
                           length(cons)))

  low <- stri_trans_tolower(corpus$text[cons])
  sp_cst  <- cst_locate_group(low, as.list(CST_TERMS[t1_cols]), CST_FIXED[t1_cols])
  sp_econ <- cst_locate_group(low, as.list(unlist(ME_ECON)), rep(FALSE, length(ME_ECON)))
  gm <- vapply(seq_along(cons), function(k) cst_gap(sp_cst[[k]], sp_econ[[k]]), integer(2))
  gap <- gm[1, ]; mid <- gm[2, ]

  keep <- which(!is.na(gap) & gap <= ME_WINDOW)          # condition 3
  i <- cons[keep]
  rid <- rid_all[i]

  # junction-centred slice: guarantees the CST<->economy meeting point is inside the text handed to NLP
  n_ch <- stri_length(corpus$text[i])
  from <- pmax(1L, mid[keep] - CST_SLICE %/% 2L)
  to   <- pmin(n_ch, from + CST_SLICE - 1L)
  from <- pmax(1L, to - CST_SLICE + 1L)

  core <- data.frame(
    rid        = rid,
    gap        = gap[keep],
    terms      = NA_character_,   # filled from the hit matrix below
    platform   = corpus$platform[i],
    stream     = corpus$data_source[i],
    date       = as.Date(corpus$date[i]),
    actor      = corpus$actor[i],
    url        = corpus$url[i],
    domains    = unname(dom_by_rid[as.character(rid)]),
    label      = unname(lab_by_rid[as.character(rid)]),
    n_chars    = n_ch,
    slice_from = from,
    slice      = stri_sub(corpus$text[i], from, to),
    junction   = mid[keep] - from + 1L,
    stringsAsFactors = FALSE)

  # terms per post, recovered from the hit matrix (clearer than reconstructing from spans)
  core$terms <- vapply(seq_along(i), function(k)
    paste(t1_cols[hits[i[k], t1_cols]], collapse = " "), "")
  core$era <- vapply(strsplit(core$terms, " "), function(tt) {
    e <- unique(unname(CST_ERA[tt])); e <- e[e != "—"]
    if (!length(e)) "marker_only" else if (length(e) == 1L) e else "mixed"
  }, "")

  if (!is.null(expect) && nrow(core) != expect) {
    stop("Core set is ", nrow(core), " posts, expected ", expect,
         ". The population changed — reconcile before trusting any downstream number ",
         "(pass expect=NULL deliberately if the change is intended).", call. = FALSE)
  }
  dir.create(dirname(cache), recursive = TRUE, showWarnings = FALSE)
  saveRDS(core, cache)
  if (verbose) cat(sprintf("  core set: %d posts -> %s\n", nrow(core), cache))
  core
}

invisible(TRUE)
