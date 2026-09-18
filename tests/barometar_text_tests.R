#!/usr/bin/env Rscript
# Invented-only fixtures. Run from repo root:
# Rscript --vanilla tests/barometar_text_tests.R
# Safe to source from tests/run_tests.R; all test bindings are local.
local({
  if (!requireNamespace("stringi", quietly = TRUE)) {
    stop("barometar text tests require stringi.", call. = FALSE)
  }
  source("R/lib/barometar_text.R", local = TRUE, encoding = "UTF-8")
  source("R/lib/barometar_url_rules.R", local = TRUE, encoding = "UTF-8")
  failures <- character()
  checks <- 0L
  equal <- function(actual, expected, label) {
    checks <<- checks + 1L
    if (!identical(actual, expected)) failures <<- c(failures, label)
  }
  okay <- function(actual, label) equal(isTRUE(actual), TRUE, label)
  errors <- function(expr, label) okay(inherits(try(expr, silent = TRUE), "try-error"), label)
  fixture <- read.csv("tests/fixtures/barometar_text_cases.csv", fileEncoding = "UTF-8",
                      stringsAsFactors = FALSE, na.strings = character())
  input <- stringi::stri_unescape_unicode(fixture$input)
  expected <- stringi::stri_unescape_unicode(fixture$expected)
  normalized <- barometar_normalize_text(input)
  for (i in seq_len(nrow(fixture))) equal(normalized[i], expected[i], fixture$case_id[i])
  equal(barometar_normalize_text(normalized), normalized, "normalization is idempotent")
  equal(barometar_normalize_text(c(NA_character_, "")), c(NA_character_, ""), "normalizer NA and empty")
  equal(barometar_normalize_text(character()), character(), "normalizer zero rows")
  fields <- barometar_text_fields(c("ŽIVOT ĐAK \u0130 \u01C4", NA_character_))
  equal(fields$low, c("život đak i dž", NA_character_), "Croatian lower case offsets")
  okay(identical(stringi::stri_length(fields$txt), stringi::stri_length(fields$low)),
       "case-sensitive and lowercase code-point offsets agree")

  body200 <- stringi::stri_dup("č", 200L)
  body199 <- stringi::stri_dup("č", 199L)
  prepared <- barometar_prepare_text(
    c("Naslov", "Naslov", NA_character_, "", "Naslov", "Naslov", "NASLOV", ""),
    c(paste0("Naslov: \n", body200), paste0("Naslov — ", body199), body200,
      body200, "Naslov", NA_character_, paste0("Naslov: ", body199), NA_character_))
  equal(prepared$body_chars, c(200L, 199L, 200L, 200L, 0L, NA_integer_, 207L, NA_integer_),
        "title stripping precedes code-point eligibility")
  equal(prepared$eligible, c(TRUE, FALSE, TRUE, TRUE, FALSE, FALSE, TRUE, FALSE),
        "200-character threshold is inclusive, NA is ineligible")
  equal(prepared$body[1L], body200, "title separator stripped exactly")
  equal(prepared$title[1L], "Naslov", "title kept as separate field")
  equal(prepared$body[7L], paste0("Naslov: ", body199), "title prefix case is exact")
  equal(barometar_body_chars(c("Naslov", "", NA_character_),
                            c(paste0("Naslov: ", body200), body199, NA_character_)),
        c(200L, 199L, NA_integer_), "denominator length helper uses identical title stripping")
  equal(barometar_body_chars(character(), character()), integer(), "zero-row body lengths")
  no_prefix <- barometar_prepare_text("Naslov", paste0(" : ", body200))
  equal(no_prefix$body_chars, 203L, "no prefix means no leading-punctuation removal")
  decomposed_title <- paste0("C\u030C", "lanak")
  decomposed <- barometar_prepare_text("Članak", paste0(decomposed_title, " ", body200))
  okay(decomposed$body_chars > 200L, "title equality is tested before NFC")
  exact <- barometar_prepare_text("Naslov", "Naslov")
  equal(exact$body, "", "title alone produces empty body")
  equal(nrow(barometar_prepare_text(character(), character())), 0L, "zero-row prepare")
  errors(barometar_prepare_text("a", c("a", "b")), "reject recycling unequal fields")
  errors(barometar_prepare_text("", "body", min_chars = NA_integer_), "reject missing threshold")
  errors(barometar_prepare_text("", "body", cap = 3.5), "reject fractional cap")
  errors(barometar_prepare_text("", "body", cap = 0L), "reject zero cap")

  capped <- barometar_prepare_text(
    rep("", 4L), c("alpha beta gamma", "abcdefghijk", "abcd\u00A0efghijk", "abcd\nefghijk"),
    min_chars = 1L, cap = 10L)
  equal(capped$body, c("alpha", "abcdefghij", "abcd", "abcd"), "cap backs off to Unicode whitespace")
  equal(capped$body_chars, c(16L, 11L, 12L, 12L), "pre-cap lengths retained")
  equal(capped$cap_applied, rep(TRUE, 4L), "cap audit flag")
  no_cap <- barometar_prepare_text("", "alpha beta", min_chars = 1L, cap = 10L)
  equal(no_cap$body, "alpha beta", "exact cap boundary remains intact")
  equal(no_cap$cap_applied, FALSE, "exact cap boundary not flagged")
  long_cap <- barometar_prepare_text("", paste0(stringi::stri_dup("č", 31999L), " xyz"))
  equal(stringi::stri_length(long_cap$body), 31999L, "default cap counts code points not bytes")
  equal(long_cap$body_chars, 32003L, "default cap preserves original eligibility count")
  equal(long_cap$eligible, TRUE, "cap never changes eligibility")
  emoji_cap <- barometar_prepare_text("", "😀😀 čćž", min_chars = 1L, cap = 5L)
  equal(emoji_cap$body, "😀😀", "astral characters count as one code point")

  tokens <- barometar_tokens("Život kršćansko-socijalni 2026.")
  equal(tokens$token, c("Život", "kršćansko", "socijalni", "2026"), "Croatian token runs and hyphens")
  equal(tokens$index, 1:4, "one-based token index")
  equal(stringi::stri_sub("Život kršćansko-socijalni 2026.", tokens$start, tokens$end),
        tokens$token, "token positions recover exact surfaces")
  equal(nrow(barometar_tokens("— …")), 0L, "punctuation-only has no tokens")
  equal(nrow(barometar_tokens(NA_character_)), 0L, "missing field has no tokens")
  equal(barometar_tokens("c\u030C")$token, "c\u030C", "combining mark stays in token")

  equal(barometar_boilerplate_key_text(" \u00A0ŽIVOT\u200B 2026\tRAD\n "),
        "život #### rad", "boilerplate key whitespace and digit contract")
  equal(barometar_boilerplate_key_text("Članak ١"), "članak ١", "boilerplate digit class is RE2-compatible")
  equal(barometar_boilerplate_key_text(NA_character_), NA_character_, "boilerplate NA preserved")
  equal(barometar_boilerplate_segments("Prvo. Drugo!\u00A0Treće\nČetvrto")[[1L]],
        c("Prvo", "Drugo", "Treće", "Četvrto"), "literal SQL boilerplate splitting contract")

  url_cases <- data.frame(
    url = c("https://example.hr/page/2/", "https://example.hr/clanak/stranica/4",
      "https://example.hr/tag/rad", "https://example.hr/autor/izmisljeni",
      "https://example.hr/najnovije/", "https://example.hr/kultura-i-znanost/",
      "https://example.hr/najave/?date=2026-09-24", "https://example.hr/prica",
      "https://glas-koncila.hr/glas-koncila-br-1/", "https://example.hr/prilika-br-1/",
      "https://example.hr/", "https://example.hr/?view=archive",
      "https://example.hr/?p=42", "https://example.hr/vijesti/neka-prica/",
      "https://example.hr/vijesti/", "https://example.hr/?id=42&utm_source=x",
      "https://example.hr/", "https://example.hr/?utm_source=x#vrh",
      "https://example.hr/#vrh", "https://example.hr/?unknown=42",
      "https://example.hr/?", "https://example.hr/?utm_source=x&story=42",
      "https://example.hr/vijesti/", "https://example.hr/kultura_i_znanost/",
      "//www.glas-koncila.hr/prilika-br-1/", NA_character_, ""),
    title = c("Priča", "Priča", "Priča", "Priča", "Najnovije", "Kultura i znanost",
      "Najave sljedećeg dana", "Arhiva 2020", "Broj časopisa", "Priča", "Početna",
      "Fotografije", "Stvarna vijest", "Vijesti", "Stvarna vijest", "Stvarna vijest",
      "Medijski portal", "Medijski portal", "Medijski portal", "Stvarna vijest", "Portal",
      "Stvarna vijest", "Vijesti", "Kultura i znanost", "Broj časopisa", NA_character_, ""),
    reason = c("pagination_url", "pagination_url", "listing_url", "listing_url",
      "named_listing_url", "section_landing_url", "calendar_listing_url", "archive_title",
      "issue_landing_url", NA, "homepage_title", "root_query_listing", NA, NA, NA, NA,
      "homepage_root_url", "homepage_root_url", "homepage_root_url", NA, "homepage_root_url",
      NA, "section_landing_url", "section_landing_url", "issue_landing_url", NA, NA),
    stringsAsFactors = FALSE)
  reasons <- barometar_noneditorial_reason(url_cases$url, url_cases$title)
  for (i in seq_len(nrow(url_cases))) equal(reasons[i], url_cases$reason[i], paste("URL case", i))
  equal(barometar_noneditorial_url(url_cases$url, url_cases$title), !is.na(url_cases$reason),
        "logical URL wrapper agrees with reasons")
  equal(barometar_noneditorial_reason(character()), character(), "zero-row URL reasons")
  tracking_urls <- paste0("https://example.invalid/?", c(digikat_tracking_parameters(),
    "%75tm_source", "%69gshid"), "=tracking")
  equal(barometar_noneditorial_reason(tracking_urls), rep("homepage_root_url", length(tracking_urls)),
        "all canonicalizer tracking keys, including encoded names, exclude homepages")
  equal(barometar_noneditorial_reason("https://example.invalid/?igshid=x&p=123"), NA_character_,
        "tracking plus a content identifier remains eligible")
  errors(barometar_noneditorial_reason(c("a", "b"), "x"), "URL titles cannot silently recycle")
  equal(barometar_noneditorial_reason("https://other.hr/prilika-br-1/", product_id = "glas_koncila_web"),
        "issue_landing_url", "explicit registry product overrides host inference")

  if (length(failures)) stop(paste(c("Barometer text tests failed:", failures), collapse = "\n"), call. = FALSE)
  cat("Barometer text/URL tests: ", checks, " checks passed (invented fixtures only).\n", sep = "")
})
