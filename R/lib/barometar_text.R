# Pure text preparation for the Christian-democracy barometer.
# Contract: BRIEF sections 3.3-3.5. No database or source-text access occurs here.
# Version labels describe algorithms; they do not establish a G2 definition freeze.
BAROMETAR_NORMALIZER_VERSION <- "normalizer_v1"
BAROMETAR_SEGMENTER_VERSION <- "segmenter_v1-proposed"

.barometar_character <- function(x, label) {
  if (!is.character(x)) stop(label, " must be a character vector.", call. = FALSE)
  enc2utf8(x)
}

.barometar_strip_title <- function(title, full_text) {
  title <- .barometar_character(title, "title")
  body <- .barometar_character(full_text, "full_text")
  if (length(title) != length(body)) {
    stop("title and full_text must have equal lengths.", call. = FALSE)
  }
  prefix <- !is.na(title) & !is.na(body) & stringi::stri_length(title) > 0L
  prefix[prefix] <- stringi::stri_startswith_fixed(body[prefix], title[prefix])
  if (any(prefix)) {
    body[prefix] <- stringi::stri_sub(body[prefix],
                                    from = stringi::stri_length(title[prefix]) + 1L)
    body[prefix] <- stringi::stri_replace_first_regex(
      body[prefix], "^[\\p{White_Space}\\p{P}]+", "")
  }
  body
}

# Denominator-only fast entry point: no normalization, cap, or retained body.
# It uses exactly the same stripping helper as classifier preparation.
barometar_body_chars <- function(title, full_text) {
  stringi::stri_length(.barometar_strip_title(title, full_text))
}

# Separate the exact, case-sensitive raw title prefix BEFORE normalization.
# The returned body remains raw (except prefix removal and the common cap).
# body_chars is the pre-cap number of code points and determines eligibility.
# Missing full text remains missing: a title or snippet never substitutes for it.
barometar_prepare_text <- function(title, full_text, min_chars = 200L,
                                   cap = 32000L) {
  for (arg in c("min_chars", "cap")) {
    value <- get(arg, inherits = FALSE)
    if (length(value) != 1L || !is.numeric(value) || is.na(value) ||
        !is.finite(value) || value < 1 || value != floor(value) ||
        value > .Machine$integer.max) {
      stop(arg, " must be one positive integer.", call. = FALSE)
    }
  }
  body <- .barometar_strip_title(title, full_text)
  title <- .barometar_character(title, "title")
  body_chars <- stringi::stri_length(body)
  capped <- !is.na(body_chars) & body_chars > cap
  if (any(capped)) {
    shortened <- stringi::stri_sub(body[capped], to = as.integer(cap))
    last_space <- stringi::stri_locate_last_regex(shortened, "\\p{White_Space}")[, 1L]
    # If a field has no whitespace at all, retain the first cap code points.
    # This preserves the hard cap without inventing a token boundary.
    has_space <- !is.na(last_space)
    shortened[has_space] <- stringi::stri_sub(
      shortened[has_space], to = last_space[has_space] - 1L)
    body[capped] <- shortened
  }
  data.frame(
    eligible = !is.na(body_chars) & body_chars >= min_chars,
    body_chars = body_chars, body = body, title = title,
    cap_applied = capped, stringsAsFactors = FALSE
  )
}

# Explicit NFC plus the approved compatibility subset. Deliberately NOT NFKC:
# e.g. circled digits and superscripts retain their distinct characters.
# Case is preserved, including capital/titlecase Croatian digraphs.
barometar_normalize_text <- function(txt) {
  txt <- .barometar_character(txt, "txt")
  txt <- stringi::stri_replace_all_regex(txt, "\\r\\n|\\r|\\u2028|\\u2029", "\n")
  txt <- stringi::stri_trans_nfc(txt)
  from <- c(intToUtf8(0x01c4:0x01cc, multiple = TRUE),
            intToUtf8(0xfb00:0xfb06, multiple = TRUE),
            intToUtf8(0xff01:0xff5e, multiple = TRUE), "\u00f0", "\u0130")
  to <- c("DŽ", "Dž", "dž", "LJ", "Lj", "lj", "NJ", "Nj", "nj",
          "ff", "fi", "fl", "ffi", "ffl", "st", "st",
          intToUtf8(0x21:0x7e, multiple = TRUE), "đ", "I")
  txt <- stringi::stri_replace_all_fixed(txt, from, to, vectorize_all = FALSE)
  txt <- stringi::stri_replace_all_regex(txt, "\\p{Cf}", "")
  txt <- stringi::stri_replace_all_regex(txt, "[\\p{Zs}\\t]", " ")
  txt <- stringi::stri_replace_all_regex(txt, " +", " ")
  stringi::stri_trans_nfc(txt)
}

# Use when both case-sensitive and case-insensitive matching offsets are needed.
barometar_text_fields <- function(txt) {
  txt <- barometar_normalize_text(txt)
  low <- stringi::stri_trans_tolower(txt, locale = "hr")
  lengths_equal <- stringi::stri_length(txt) == stringi::stri_length(low)
  if (any(!lengths_equal, na.rm = TRUE)) {
    stop("Croatian lowercasing changed code-point offsets.", call. = FALSE)
  }
  data.frame(txt = txt, low = low, stringsAsFactors = FALSE)
}

# One normalized field at a time; offsets are one-based code points, inclusive.
# Hyphens split tokens, combining marks remain attached to their letter run.
barometar_tokens <- function(txt) {
  txt <- .barometar_character(txt, "txt")
  if (length(txt) != 1L) stop("Tokenize one field at a time.", call. = FALSE)
  positions <- stringi::stri_locate_all_regex(
    txt, "[\\p{L}\\p{M}\\p{N}]+", omit_no_match = TRUE)[[1L]]
  positions <- positions[!is.na(positions[, 1L]), , drop = FALSE]
  data.frame(
    token = stringi::stri_sub(txt, from = positions[, 1L], to = positions[, 2L]),
    start = positions[, 1L], end = positions[, 2L],
    index = seq_len(nrow(positions)), stringsAsFactors = FALSE
  )
}

# Canonical segment text used BEFORE hashing. SQL must mirror these operations
# on raw text; no normalizer, NFC conversion, or boilerplate dictionary is applied.
# ASCII [0-9] is deliberate: DuckDB RE2's digit class is ASCII.
# The explicit whitespace set includes U+200B, as required by BRIEF section 3.5.
barometar_boilerplate_key_text <- function(segment) {
  segment <- .barometar_character(segment, "segment")
  key <- stringi::stri_trans_tolower(segment, locale = "hr")
  # Greek final sigma has contextual ICU lowercasing but simple SQL lowercasing.
  # Canonicalize both lowercase forms identically in both implementations.
  key <- stringi::stri_replace_all_fixed(key,"ς","σ")
  key <- stringi::stri_replace_all_regex(key, "[0-9]", "#")
  key <- stringi::stri_replace_all_regex(
    key, "[\\p{White_Space}\\u2000-\\u200B]+", " ")
  stringi::stri_trim_both(key)
}

# The literal splitter is shared with the future SQL boilerplate producer.
# It is intentionally different from the linguistic sentence segmenter.
BAROMETAR_BOILERPLATE_SPLIT_PATTERN <- "\\n|[.!?…][\"”“»]?[ \\t\\x{00A0}]+"

barometar_boilerplate_segments <- function(raw_body) {
  raw_body <- .barometar_character(raw_body, "raw_body")
  stringi::stri_split_regex(raw_body, BAROMETAR_BOILERPLATE_SPLIT_PATTERN,
                           omit_empty = FALSE)
}
