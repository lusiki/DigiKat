#!/usr/bin/env Rscript
# moral-economy — THE CST CORE SET (single source of truth for the analysis population).
#
# SOURCE this; never run it. `16_cst_viewer.R` renders it and `14_cst_core_profile.R` describes it.
# If each script rebuilt the population itself, the viewer could show one set of posts while the report
# described another — the drift lexicon.R, sem_lib.R and cst_lexicon.R all exist to prevent.
#
# THE DEFINITION. A post is in the core set when ALL THREE hold:
#   1. it carries Tier-1 CST vocabulary (cst_lexicon.R — an encyclical title or a doctrine coinage);
#   2. it has a (post, economic-domain) pair in the religion-linked economic layer
#      (stageA_candidates.rds: a religious term fell within +-220 chars of that domain's match);
#   3. the CST term is itself within +-220 chars of an economic term FROM THAT SAME DOMAIN.
#
# Condition 3 prevents a long post from transferring adjacency across subjects—for example, from a
# climate-adjacent Laudato si' title to an unrelated inflation pair. In the official run, 2,672 Stage-A
# posts carry Tier-1 vocabulary somewhere, but only 1,093 posts / 1,290 pairs satisfy same-domain
# adjacency. Every retained pair therefore has its own gap and adjacent-term record.
#
# The independent generic-religion gate deliberately prevents Tier 1 from defining both frame entry and
# numerator status. An inclusive full-corpus reconstruction adds 61 pairs / 38 posts: 20 posts were outside
# the main Stage-A post frame and 18 were already linked only on another subject. They remain excluded from
# the main estimand and are reported in the frame sensitivity rather than silently folded into the core.
suppressPackageStartupMessages({ library(here); library(stringi) })
source(here::here("studies/moral-economy/cst_lexicon.R"))
source(here::here("studies/moral-economy/lexicon.R"))
source(here::here("studies/moral-economy/rsp_input.R"))

CST_CORE_CACHE <- RSP_CORE_CACHE
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

cst_terms_era <- function(terms) {
  e <- unique(unname(CST_ERA[terms]))
  e <- e[!is.na(e) & e %in% c("francis", "classical", "conciliar", "benedict")]
  if (!length(e)) "marker_only" else if (length(e) == 1L) e else "mixed"
}

# Canonical pair view of the post-level cache. Requiring the named per-domain gap map makes the
# pair-specific adjacency definition executable: an older cache that merely attached every Stage-A
# domain to a qualifying post cannot pass this invariant.
cst_core_pairs <- function(core) {
  need <- c("rid", "domains", "domain_gaps", "domain_terms")
  if (!all(need %in% names(core))) {
    stop("Core cache lacks the pair-specific domain-gap map; rebuild it with refresh = TRUE.",
         call. = FALSE)
  }
  rows <- lapply(seq_len(nrow(core)), function(i) {
    ds <- strsplit(trimws(as.character(core$domains[i])), "\\s+")[[1]]
    ds <- ds[nzchar(ds)]
    gm <- core$domain_gaps[[i]]
    tm <- core$domain_terms[[i]]
    if (!length(ds) || is.null(names(gm)) || is.null(names(tm)) ||
        !setequal(ds, names(gm)) || !setequal(ds, names(tm))) {
      stop("Core domain labels, gap map, and term map disagree for rid ", core$rid[i], ".",
           call. = FALSE)
    }
    terms <- vapply(ds, function(d) paste(tm[[d]], collapse = " "), character(1))
    data.frame(rid = as.integer(core$rid[i]), domain = ds,
               gap = as.integer(gm[match(ds, names(gm))]), terms = terms,
               era = vapply(tm[ds], cst_terms_era, character(1)), stringsAsFactors = FALSE)
  })
  out <- if (length(rows)) do.call(rbind, rows) else
    data.frame(rid = integer(), domain = character(), gap = integer(),
               terms = character(), era = character())
  if (anyNA(out$gap) || any(out$gap < 0L | out$gap > ME_WINDOW) ||
      any(!out$domain %in% names(ME_ECON)) || any(!nzchar(out$terms)) ||
      anyDuplicated(out[c("rid", "domain")])) {
    stop("Core pair invariant failed: every unique pair must have a same-domain gap within ME_WINDOW.",
         call. = FALSE)
  }
  rownames(out) <- NULL
  out
}

# Build (or load) the canonical core table. `expect` is an optional external gate. A cache is reusable
# only when the database, prepared slice, candidates, lexicons, and pair-level definition agree.
cst_build_core <- function(cache = CST_CORE_CACHE, expect = rsp_expected_core_posts(),
                           refresh = FALSE, verbose = TRUE) {
  m <- rsp_assert_official_inputs()
  fp <- list(
    database_sha256 = as.character(m$database$sha256),
    prepared_sha256 = as.character(m$inputs$prepared$sha256),
    candidates_sha256 = as.character(m$inputs$candidates$sha256),
    cst_lexicon_md5 = unname(tools::md5sum(here::here("studies/moral-economy/cst_lexicon.R"))),
    economy_lexicon_md5 = unname(tools::md5sum(here::here("studies/moral-economy/lexicon.R"))),
    core_builder = "pair-specific-domain-adjacency-and-terms-v3",
    window = ME_WINDOW,
    slice_chars = CST_SLICE)
  if (!refresh && file.exists(cache)) {
    core <- readRDS(cache)
    fp_ok <- identical(attr(core, "fingerprint"), fp)
    n_ok <- is.null(expect) || identical(nrow(core), as.integer(expect))
    if (fp_ok && n_ok) {
      cst_core_pairs(core)
      if (verbose) cat(sprintf("  [cached] core set: %d posts (%s)\n", nrow(core), cache))
      return(core)
    }
    if (verbose) cat("  cached core is stale for the official inputs — rebuilding.\n")
  }
  corpus <- readRDS(RSP_CORPUS_PREPARED)
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
  cand <- readRDS(RSP_STAGEA_CANDIDATES)
  cand$rid <- as.integer(cand$rid)
  dom_by_rid <- lapply(split(as.character(cand$domain), cand$rid), function(d) sort(unique(d)))
  lab_by_rid <- tapply(cand$label, cand$rid, function(x) x[1])
  rid_all <- as.integer(sub("^dk_", "", corpus$doc_id))

  cons <- which(is_t1 & rid_all %in% as.integer(names(dom_by_rid)))
  if (verbose) cat(sprintf("  Tier-1 AND econ-linked: %d posts; measuring CST<->domain distance...\n",
                           length(cons)))

  low <- stri_trans_tolower(corpus$text[cons])
  sp_cst_by_term <- stats::setNames(lapply(t1_cols, function(t)
    cst_locate_group(low, as.list(CST_TERMS[[t]]), CST_FIXED[[t]])), t1_cols)
  sp_cst <- lapply(seq_along(cons), function(k) {
    z <- do.call(rbind, lapply(sp_cst_by_term, function(x) x[[k]]))
    if (!nrow(z)) matrix(integer(0), 0, 2) else z[order(z[, 1]), , drop = FALSE]
  })
  gap_by_domain <- matrix(NA_integer_, nrow = length(cons), ncol = length(ME_ECON),
                          dimnames = list(NULL, names(ME_ECON)))
  mid_by_domain <- gap_by_domain
  terms_by_domain <- replicate(length(cons), list(), simplify = FALSE)
  for (d in names(ME_ECON)) {
    sp_domain <- cst_locate_group(low, as.list(ME_ECON[[d]]), FALSE)
    gm <- vapply(seq_along(cons), function(k) cst_gap(sp_cst[[k]], sp_domain[[k]]), integer(2))
    gap_by_domain[, d] <- gm[1, ]
    mid_by_domain[, d] <- gm[2, ]
    in_candidate_pair <- vapply(seq_along(cons), function(k)
      d %in% dom_by_rid[[as.character(rid_all[cons[k]])]], logical(1))
    eligible <- which(in_candidate_pair & !is.na(gm[1, ]) & gm[1, ] <= ME_WINDOW)
    for (k in eligible) {
      term_ok <- vapply(t1_cols, function(t) {
        z <- cst_gap(sp_cst_by_term[[t]][[k]], sp_domain[[k]])[1]
        !is.na(z) && z <= ME_WINDOW
      }, logical(1))
      terms_by_domain[[k]][[d]] <- t1_cols[term_ok]
    }
  }
  qualifying <- lapply(seq_along(cons), function(k) {
    ds <- dom_by_rid[[as.character(rid_all[cons[k]])]]
    gd <- gap_by_domain[k, ds]
    ds[!is.na(gd) & gd <= ME_WINDOW]
  })
  keep <- which(lengths(qualifying) > 0L)                 # condition 3, at pair grain
  i <- cons[keep]
  rid <- rid_all[i]
  gap_maps <- lapply(keep, function(k) {
    ds <- qualifying[[k]]
    stats::setNames(as.integer(gap_by_domain[k, ds]), ds)
  })
  term_maps <- lapply(keep, function(k) {
    ds <- qualifying[[k]]
    stats::setNames(lapply(ds, function(d) terms_by_domain[[k]][[d]]), ds)
  })
  gap <- vapply(gap_maps, function(x) as.integer(min(x)), integer(1))
  mid <- vapply(keep, function(k) {
    ds <- qualifying[[k]]
    d <- ds[which.min(gap_by_domain[k, ds])]
    as.integer(mid_by_domain[k, d])
  }, integer(1))

  # junction-centred slice: guarantees the CST<->economy meeting point is inside the text handed to NLP
  n_ch <- stri_length(corpus$text[i])
  from <- pmax(1L, mid - CST_SLICE %/% 2L)
  to   <- pmin(n_ch, from + CST_SLICE - 1L)
  from <- pmax(1L, to - CST_SLICE + 1L)

  core <- data.frame(
    rid        = rid,
    gap        = gap,
    terms      = NA_character_,   # filled from the pair-specific term maps below
    platform   = corpus$platform[i],
    stream     = corpus$data_source[i],
    date       = as.Date(corpus$date[i]),
    actor      = corpus$actor[i],
    url        = corpus$url[i],
    domains    = vapply(qualifying[keep], paste, collapse = " ", FUN.VALUE = character(1)),
    label      = unname(lab_by_rid[as.character(rid)]),
    n_chars    = n_ch,
    slice_from = from,
    slice      = stri_sub(corpus$text[i], from, to),
    junction   = mid - from + 1L,
    stringsAsFactors = FALSE)
  core$domain_gaps <- I(gap_maps)
  core$domain_terms <- I(term_maps)

  # Post-level terms are the union of pair-specific adjacent terms, never distant hits elsewhere.
  core$terms <- vapply(term_maps, function(tm) {
    tt <- unique(unlist(tm, use.names = FALSE))
    paste(t1_cols[t1_cols %in% tt], collapse = " ")
  }, character(1))
  core$era <- vapply(strsplit(core$terms, " "), function(tt) {
    e <- unique(unname(CST_ERA[tt])); e <- e[e != "—"]
    if (!length(e)) "marker_only" else if (length(e) == 1L) e else "mixed"
  }, "")

  pairs <- cst_core_pairs(core)

  if (!is.null(expect) && nrow(core) != expect) {
    stop("Core set is ", nrow(core), " posts, expected ", expect,
         ". The population changed — reconcile before trusting any downstream number ",
         "(pass expect=NULL deliberately if the change is intended).", call. = FALSE)
  }
  attr(core, "fingerprint") <- fp
  dir.create(dirname(cache), recursive = TRUE, showWarnings = FALSE)
  saveRDS(core, cache)
  if (verbose) cat(sprintf("  core set: %d posts / %d same-domain pairs -> %s\n",
                           nrow(core), nrow(pairs), cache))
  core
}

invisible(TRUE)
