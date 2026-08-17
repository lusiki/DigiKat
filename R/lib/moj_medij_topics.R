# Corpus-wide dictionary topic profiles for the public "Moj medij" lookup.
#
# The classifier deliberately mirrors the provisional news-gap method: Croatian
# NFKC/lower-case normalization, TITLE plus the first 3,000 FULL_TEXT characters,
# literal dictionary stems, and fractional allocation when topics tie for the
# largest number of matches. It does not use udpipe or publish row-level results.

DIGIKAT_TOPIC_PROFILE_LABELS <- c(
  DUHOVNOST_I_LITURGIJA = "Duhovnost i liturgija",
  TEOLOGIJA_I_DOKTRINA = "Teologija i doktrina",
  CRKVENO_UPRAVLJANJE_I_STRUKTURA = "Crkveno upravljanje i struktura",
  PAPE_I_VATIKAN = "Pape i Vatikan",
  CRKVENE_FINANCIJE_I_IMOVINA = "Crkvene financije i imovina",
  GLOBALNA_CRKVA_I_MISIJE = "Globalna Crkva i misije",
  POLITIKA_I_ODNOS_S_DRZAVOM = "Politika i odnos s državom",
  BIOETIKA_I_KULTURNI_RATOVI = "Bioetika i kulturni ratovi",
  KARITAS_I_SOCIJALNA_PRAVDA = "Karitas i socijalna pravda",
  POVIJEST_I_NACIONALNI_IDENTITET = "Povijest i nacionalni identitet",
  ZNANOST_I_VJERA = "Znanost i vjera",
  MEDIJI_UMJETNOST_I_KULTURA = "Mediji, umjetnost i kultura",
  DIGITALNA_EVANGELIZACIJA_I_MLADI = "Digitalna evangelizacija i mladi",
  ZLOSTAVLJANJE_I_KRIZA_POVJERENJA = "Zlostavljanje i kriza povjerenja",
  UNUTARCRKVENI_PRIJEPORI_I_IDEOLOGIJE = "Unutarcrkveni prijepori i ideologije",
  ODNOS_S_DRUGIM_RELIGIJAMA_I_POGLEDIMA = "Odnos s drugim religijama i pogledima"
)

digikat_topic_profile_key <- function(from, platform) {
  paste(enc2utf8(as.character(from)), enc2utf8(as.character(platform)), sep = "\u001f")
}

digikat_normalize_topic_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  stringi::stri_trans_tolower(stringi::stri_trans_nfkc(enc2utf8(x)), locale = "hr")
}

digikat_compile_topic_patterns <- function(dictionary) {
  if (!length(dictionary) || is.null(names(dictionary)) || anyDuplicated(names(dictionary)) ||
      any(!nzchar(names(dictionary)))) {
    stop("Topic dictionary must have unique, non-empty names.", call. = FALSE)
  }
  lapply(dictionary, function(terms) {
    clean <- unique(digikat_normalize_topic_text(terms))
    clean <- clean[nzchar(clean)]
    if (!length(clean)) stop("Every topic dictionary must contain a term.", call. = FALSE)
    clean <- clean[order(nchar(clean), decreasing = TRUE)]
    alternatives <- paste0("\\Q", gsub("\\\\E", "\\\\E\\\\\\\\E\\\\Q", clean), "\\E")
    paste0("(?<![\\p{L}\\p{M}\\p{N}_])(?:", paste(alternatives, collapse = "|"), ")")
  })
}

digikat_topic_profiles <- function(data, dictionary = digikat_thematic_dictionaries,
                                   text_characters = 3000L, chunk_size = 25000L,
                                   progress = FALSE) {
  required <- c("FROM", "SOURCE_TYPE", "TITLE", "FULL_TEXT")
  missing <- setdiff(required, names(data))
  if (length(missing)) {
    stop("Topic-profile input is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  if (!requireNamespace("stringi", quietly = TRUE)) {
    stop("Package 'stringi' is required for topic profiles.", call. = FALSE)
  }
  text_characters <- as.integer(text_characters)
  chunk_size <- as.integer(chunk_size)
  if (!is.finite(text_characters) || text_characters < 1L ||
      !is.finite(chunk_size) || chunk_size < 1L) {
    stop("Topic text and chunk sizes must be positive integers.", call. = FALSE)
  }

  keep <- !is.na(data$FROM) & nzchar(trimws(as.character(data$FROM))) &
    !is.na(data$SOURCE_TYPE) & nzchar(trimws(as.character(data$SOURCE_TYPE)))
  data <- data[keep, required, drop = FALSE]
  if (!nrow(data)) stop("Topic-profile input has no source/platform rows.", call. = FALSE)

  topics <- names(dictionary)
  patterns <- digikat_compile_topic_patterns(dictionary)
  from <- enc2utf8(as.character(data$FROM))
  platform <- enc2utf8(as.character(data$SOURCE_TYPE))
  key <- digikat_topic_profile_key(from, platform)
  key_levels <- unique(key)
  group_id <- match(key, key_levels)
  first_group_row <- match(key_levels, key)
  n_groups <- length(key_levels)
  group_posts <- tabulate(group_id, nbins = n_groups)
  group_classified <- integer(n_groups)
  topic_mass <- matrix(0, nrow = n_groups, ncol = length(topics),
                       dimnames = list(key_levels, topics))

  starts <- seq.int(1L, nrow(data), by = chunk_size)
  for (chunk in seq_along(starts)) {
    idx <- starts[[chunk]]:min(nrow(data), starts[[chunk]] + chunk_size - 1L)
    title <- as.character(data$TITLE[idx])
    title[is.na(title)] <- ""
    body <- as.character(data$FULL_TEXT[idx])
    body[is.na(body)] <- ""
    body <- stringi::stri_sub(body, 1L, text_characters)
    text <- digikat_normalize_topic_text(paste(title, body, sep = "\n"))

    scores <- vapply(patterns, function(pattern) {
      stringi::stri_count_regex(
        text,
        pattern,
        opts_regex = stringi::stri_opts_regex(case_insensitive = FALSE)
      )
    }, integer(length(idx)))
    if (is.null(dim(scores))) scores <- matrix(scores, ncol = length(topics))
    colnames(scores) <- topics
    max_score <- apply(scores, 1L, max)
    classified <- max_score > 0L
    tie_count <- rowSums(scores == max_score & classified)
    chunk_groups <- group_id[idx]
    if (any(classified)) {
      group_classified <- group_classified +
        tabulate(chunk_groups[classified], nbins = n_groups)
      for (topic_index in seq_along(topics)) {
        winner <- classified & scores[, topic_index] == max_score
        if (any(winner)) {
          weighted <- rowsum(
            1 / tie_count[winner],
            group = chunk_groups[winner],
            reorder = FALSE
          )
          weighted_groups <- as.integer(rownames(weighted))
          topic_mass[weighted_groups, topic_index] <-
            topic_mass[weighted_groups, topic_index] + as.numeric(weighted[, 1L])
        }
      }
    }
    if (isTRUE(progress) && (chunk == 1L || chunk == length(starts) || chunk %% 4L == 0L)) {
      fmt_rows <- function(x) format(x, big.mark = ".", decimal.mark = ",",
                                     scientific = FALSE, trim = TRUE)
      message("Topic classification: ", fmt_rows(min(idx)), "–",
              fmt_rows(max(idx)), " / ", fmt_rows(nrow(data)))
    }
  }

  classified_mass <- rowSums(topic_mass)
  if (any(abs(classified_mass - group_classified) > 1e-8)) {
    stop("Fractional topic allocations do not reconcile to classified posts.", call. = FALSE)
  }
  share <- topic_mass
  positive <- group_classified > 0L
  share[positive, ] <- 100 * share[positive, , drop = FALSE] / group_classified[positive]
  share[!positive, ] <- 0

  data.frame(
    FROM = rep(from[first_group_row], each = length(topics)),
    SOURCE_TYPE = rep(platform[first_group_row], each = length(topics)),
    topic = rep(topics, times = n_groups),
    posts = rep(as.integer(group_posts), each = length(topics)),
    classified_posts = rep(as.integer(group_classified), each = length(topics)),
    topic_mass = as.vector(t(topic_mass)),
    topic_share = as.vector(t(share)),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

digikat_topic_comparisons <- function(profiles, listed_sources, min_classified_posts = 100L,
                                      max_neighbours = 4L, min_neighbours = 3L) {
  required <- c("FROM", "SOURCE_TYPE", "topic", "posts", "classified_posts", "topic_share")
  missing <- setdiff(required, names(profiles))
  if (length(missing)) {
    stop("Topic comparisons are missing: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  min_classified_posts <- as.integer(min_classified_posts)
  max_neighbours <- as.integer(max_neighbours)
  min_neighbours <- as.integer(min_neighbours)
  if (min_classified_posts < 1L || max_neighbours < min_neighbours || min_neighbours < 1L) {
    stop("Invalid topic comparison thresholds.", call. = FALSE)
  }

  profile_key <- digikat_topic_profile_key(profiles$FROM, profiles$SOURCE_TYPE)
  first <- !duplicated(profile_key)
  coverage <- profiles[first, c("FROM", "SOURCE_TYPE", "posts", "classified_posts"), drop = FALSE]
  coverage$key <- profile_key[first]
  coverage <- coverage[coverage$FROM %in% unique(as.character(listed_sources)), , drop = FALSE]
  coverage$eligible <- coverage$classified_posts >= min_classified_posts
  eligible_keys <- coverage$key[coverage$eligible]
  eligible <- profiles[profile_key %in% eligible_keys, , drop = FALSE]

  if (!nrow(eligible)) {
    return(list(profiles = eligible, coverage = coverage, neighbours = list(),
                topics = unique(profiles$topic)))
  }
  topics <- unique(profiles$topic)
  observed_topics <- table(digikat_topic_profile_key(eligible$FROM, eligible$SOURCE_TYPE))
  if (any(observed_topics != length(topics))) {
    stop("Every eligible source/platform profile must carry every topic.", call. = FALSE)
  }

  peer_share <- stats::aggregate(
    eligible$topic_share,
    by = list(SOURCE_TYPE = eligible$SOURCE_TYPE, topic = eligible$topic),
    FUN = mean
  )
  names(peer_share)[[3L]] <- "peer_share"
  peer_n <- stats::aggregate(
    eligible$FROM,
    by = list(SOURCE_TYPE = eligible$SOURCE_TYPE),
    FUN = function(x) length(unique(x))
  )
  names(peer_n)[[2L]] <- "peer_n"
  eligible <- merge(eligible, peer_share, by = c("SOURCE_TYPE", "topic"), all.x = TRUE,
                    sort = FALSE)
  eligible$peer_n <- as.integer(peer_n$peer_n[match(eligible$SOURCE_TYPE, peer_n$SOURCE_TYPE)])

  neighbours <- list()
  for (current_platform in unique(eligible$SOURCE_TYPE)) {
    block <- eligible[eligible$SOURCE_TYPE == current_platform, , drop = FALSE]
    sources <- sort(unique(block$FROM), method = "radix")
    vectors <- matrix(0, nrow = length(sources), ncol = length(topics),
                      dimnames = list(sources, topics))
    for (i in seq_along(sources)) {
      rows <- block[block$FROM == sources[[i]], , drop = FALSE]
      vectors[i, match(rows$topic, topics)] <- rows$topic_share
    }
    norms <- sqrt(rowSums(vectors ^ 2))
    similarity <- tcrossprod(vectors / norms)
    diag(similarity) <- -Inf
    for (i in seq_along(sources)) {
      candidates <- setdiff(seq_along(sources), i)
      if (length(candidates) < min_neighbours) next
      ordered <- candidates[order(
        -similarity[i, candidates],
        digikat_normalize_topic_text(sources[candidates]),
        sources[candidates],
        method = "radix"
      )]
      take <- head(ordered, min(max_neighbours, length(ordered)))
      neighbours[[digikat_topic_profile_key(sources[[i]], current_platform)]] <-
        unname(as.character(sources[take]))
    }
  }

  list(profiles = eligible, coverage = coverage, neighbours = neighbours, topics = topics)
}
