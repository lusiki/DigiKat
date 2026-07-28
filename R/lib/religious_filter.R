# Shared religious-term matching for full and incremental ingestion.
#
# The corpus inclusion contract remains unchanged: a row qualifies when at
# least two DISTINCT term patterns match its FULL_TEXT.

digikat_load_religious_terms <- function(path = "R/religious_terms.R") {
  if (!requireNamespace("stringi", quietly = TRUE)) {
    stop("Package 'stringi' is required for religious-term matching.", call. = FALSE)
  }
  if (!file.exists(path)) stop("Religious terms file not found: ", path, call. = FALSE)
  terms <- source(path, local = new.env(parent = baseenv()), encoding = "UTF-8")$value
  digikat_validate_religious_terms(terms)
}

digikat_validate_religious_terms <- function(terms) {
  if (!is.data.frame(terms)) stop("Religious terms must be a data frame.", call. = FALSE)
  digikat_require_columns(terms, c("term", "regex"), "religious terms")
  terms$term <- stringi::stri_trans_tolower(trimws(as.character(terms$term)))
  terms$regex <- as.character(terms$regex)

  if (anyNA(terms$term) || any(!nzchar(terms$term))) {
    stop("Religious terms contain blank/NA term labels.", call. = FALSE)
  }
  if (anyNA(terms$regex) || any(!nzchar(terms$regex))) {
    stop("Religious terms contain blank/NA regular expressions.", call. = FALSE)
  }
  if (anyDuplicated(terms$term)) {
    stop("Religious term labels must be unique.", call. = FALSE)
  }

  bad <- vapply(
    terms$regex,
    function(pattern) {
      inherits(
        try(stringi::stri_detect_regex("", pattern, opts_regex = list(case_insensitive = TRUE)), silent = TRUE),
        "try-error"
      )
    },
    logical(1L)
  )
  if (any(bad)) {
    stop("Invalid religious-term regex(es): ", paste(terms$term[bad], collapse = ", "), call. = FALSE)
  }
  terms
}

digikat_religious_match_details <- function(text, terms, term_indices) {
  if (is.na(text) || !nzchar(text) || !length(term_indices)) {
    return(list(
      matched_terms = NA_character_,
      matched_words = NA_character_,
      matched_sentences = NA_character_
    ))
  }

  sentences <- unlist(stringi::stri_split_regex(text, "(?<=[.!?])\\s+"))
  words <- character()
  matched_sentences <- character()
  for (term_index in term_indices) {
    pattern <- terms$regex[[term_index]]
    found_words <- unlist(stringi::stri_extract_all_regex(
      text,
      pattern,
      opts_regex = list(case_insensitive = TRUE)
    ))
    words <- c(words, found_words[!is.na(found_words) & nzchar(found_words)])
    found_sentences <- sentences[stringi::stri_detect_regex(
      sentences,
      pattern,
      opts_regex = list(case_insensitive = TRUE)
    )]
    matched_sentences <- c(matched_sentences, found_sentences)
  }

  list(
    matched_terms = paste(unique(terms$term[term_indices]), collapse = "; "),
    matched_words = if (length(words)) paste(unique(words), collapse = "; ") else NA_character_,
    matched_sentences = if (length(matched_sentences)) {
      paste(unique(matched_sentences), collapse = " | ")
    } else {
      NA_character_
    }
  )
}

digikat_match_religious <- function(text, terms, min_matches = 2L, include_details = TRUE,
                                    batch_size = 5000L, progress = interactive()) {
  if (!requireNamespace("stringi", quietly = TRUE)) {
    stop("Package 'stringi' is required for religious-term matching.", call. = FALSE)
  }
  terms <- digikat_validate_religious_terms(terms)
  text <- as.character(text)
  n <- length(text)
  if (!n) {
    return(data.frame(
      root_match_count = integer(),
      matched_terms = character(),
      matched_words = character(),
      matched_sentences = character(),
      stringsAsFactors = FALSE
    ))
  }

  batch_size <- as.integer(batch_size)
  if (is.na(batch_size) || batch_size < 1L) stop("batch_size must be a positive integer.", call. = FALSE)
  min_matches <- as.integer(min_matches)
  if (is.na(min_matches) || min_matches < 1L) stop("min_matches must be a positive integer.", call. = FALSE)

  counts <- integer(n)
  matched_terms <- rep(NA_character_, n)
  matched_words <- rep(NA_character_, n)
  matched_sentences <- rep(NA_character_, n)

  starts <- seq.int(1L, n, by = batch_size)
  for (batch_number in seq_along(starts)) {
    first <- starts[[batch_number]]
    last <- min(first + batch_size - 1L, n)
    indices <- first:last
    chunk <- text[indices]

    hit_matrix <- vapply(
      terms$regex,
      function(pattern) {
        result <- stringi::stri_detect_regex(
          chunk,
          pattern,
          opts_regex = list(case_insensitive = TRUE)
        )
        result[is.na(result)] <- FALSE
        result
      },
      logical(length(indices))
    )
    if (is.null(dim(hit_matrix))) {
      hit_matrix <- matrix(hit_matrix, nrow = length(indices), ncol = nrow(terms))
    }
    counts[indices] <- as.integer(rowSums(hit_matrix))

    if (isTRUE(include_details)) {
      qualifying_local <- which(counts[indices] >= min_matches)
      for (local_index in qualifying_local) {
        global_index <- indices[[local_index]]
        details <- digikat_religious_match_details(
          chunk[[local_index]],
          terms,
          which(hit_matrix[local_index, ])
        )
        matched_terms[[global_index]] <- details$matched_terms
        matched_words[[global_index]] <- details$matched_words
        matched_sentences[[global_index]] <- details$matched_sentences
      }
    }

    if (isTRUE(progress)) {
      cat(sprintf(
        "\r  Religious filter batch %d/%d (%d%%)",
        batch_number,
        length(starts),
        round(100 * last / n)
      ))
      flush.console()
    }
  }
  if (isTRUE(progress)) cat("\n")

  data.frame(
    root_match_count = counts,
    matched_terms = matched_terms,
    matched_words = matched_words,
    matched_sentences = matched_sentences,
    stringsAsFactors = FALSE
  )
}
