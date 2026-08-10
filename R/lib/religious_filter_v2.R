# Tier-aware religious matching for the v2 term list.
#
# ADDITIVE ONLY. `R/lib/religious_filter.R` is not modified; this file sources it and adds the
# tier logic on top. Code that has not opted into v2 keeps the old behaviour exactly.
#
# Inclusion rule (v2): a row qualifies when it matches >= 1 DECISIVE term AND >= 2 terms in total.
# The v1 contract (>= 2 distinct terms of any kind) stays available via digikat_match_religious().

if (!exists("digikat_match_religious", mode = "function")) {
  source(file.path("R", "lib", "religious_filter.R"), encoding = "UTF-8")
}

digikat_load_religious_terms_v2 <- function(path = "R/religious_terms_v2.R") {
  if (!file.exists(path)) stop("v2 religious terms file not found: ", path, call. = FALSE)
  terms <- source(path, local = new.env(parent = baseenv()), encoding = "UTF-8")$value
  terms <- digikat_validate_religious_terms(terms)
  if (!"tier" %in% names(terms)) {
    stop("v2 religious terms must carry a `tier` column.", call. = FALSE)
  }
  bad <- setdiff(unique(terms$tier), c("decisive", "ambiguous"))
  if (length(bad)) {
    stop("Unknown tier value(s): ", paste(bad, collapse = ", "), call. = FALSE)
  }
  terms
}

# Logical hit matrix: rows = texts, cols = terms (in `terms` order).
digikat_hit_matrix <- function(text, terms, batch_size = 5000L, progress = FALSE) {
  if (!requireNamespace("stringi", quietly = TRUE)) {
    stop("Package 'stringi' is required for religious-term matching.", call. = FALSE)
  }
  text <- as.character(text)
  n <- length(text)
  out <- matrix(FALSE, nrow = n, ncol = nrow(terms),
                dimnames = list(NULL, terms$term))
  if (!n) return(out)

  starts <- seq.int(1L, n, by = as.integer(batch_size))
  for (b in seq_along(starts)) {
    first <- starts[[b]]
    last <- min(first + as.integer(batch_size) - 1L, n)
    idx <- first:last
    chunk <- text[idx]
    hits <- vapply(
      terms$regex,
      function(pattern) {
        r <- stringi::stri_detect_regex(chunk, pattern,
                                        opts_regex = list(case_insensitive = TRUE))
        r[is.na(r)] <- FALSE
        r
      },
      logical(length(idx))
    )
    if (is.null(dim(hits))) hits <- matrix(hits, nrow = length(idx), ncol = nrow(terms))
    out[idx, ] <- hits
    if (isTRUE(progress)) {
      cat(sprintf("\r  v2 filter batch %d/%d (%d%%)", b, length(starts), round(100 * last / n)))
      flush.console()
    }
  }
  if (isTRUE(progress)) cat("\n")
  out
}

# Per-row decisive / ambiguous / total counts.
digikat_tier_counts <- function(hit_matrix, terms) {
  stopifnot(ncol(hit_matrix) == nrow(terms))
  dec <- terms$tier == "decisive"
  data.frame(
    decisive_match_count  = as.integer(rowSums(hit_matrix[, dec,  drop = FALSE])),
    ambiguous_match_count = as.integer(rowSums(hit_matrix[, !dec, drop = FALSE])),
    total_match_count     = as.integer(rowSums(hit_matrix)),
    stringsAsFactors = FALSE
  )
}

# The v2 inclusion rule.
digikat_passes_inclusion_v2 <- function(counts, min_decisive = 1L, min_total = 2L) {
  counts$decisive_match_count >= min_decisive & counts$total_match_count >= min_total
}

# --- nesting collapse -------------------------------------------------------------------------
# "biskup", "nadbiskup", "biskupija" and "nadbiskupija" all fire on the single token
# `nadbiskupija`, so ">= 2 distinct terms" can be satisfied by ONE word. This collapses matches
# whose matched span is contained inside another matched term's span, so a term only counts when
# it contributes an independent piece of text. Ties (identical spans, e.g. "časna sestra" vs
# "časne sestre") keep the earlier term.
digikat_collapse_nested <- function(text, terms, hit_matrix) {
  text <- as.character(text)
  out <- hit_matrix
  for (i in seq_len(nrow(hit_matrix))) {
    idx <- which(hit_matrix[i, ])
    if (length(idx) < 2L || is.na(text[i]) || !nzchar(text[i])) next
    spans <- lapply(idx, function(j) {
      m <- stringi::stri_locate_all_regex(
        text[i], terms$regex[[j]], opts_regex = list(case_insensitive = TRUE)
      )[[1]]
      m[!is.na(m[, 1]), , drop = FALSE]
    })
    keep <- rep(TRUE, length(idx))
    for (a in seq_along(idx)) {
      sa <- spans[[a]]
      if (!nrow(sa)) { keep[a] <- FALSE; next }
      covered <- vapply(seq_len(nrow(sa)), function(k) {
        any(vapply(seq_along(idx), function(b) {
          if (b == a) return(FALSE)
          sb <- spans[[b]]
          if (!nrow(sb)) return(FALSE)
          contains <- sb[, 1] <= sa[k, 1] & sb[, 2] >= sa[k, 2]
          strictly <- (sb[, 2] - sb[, 1]) > (sa[k, 2] - sa[k, 1])
          any(contains & (strictly | (!strictly & b < a)))
        }, logical(1)))
      }, logical(1))
      if (all(covered)) keep[a] <- FALSE
    }
    out[i, idx[!keep]] <- FALSE
  }
  out
}
