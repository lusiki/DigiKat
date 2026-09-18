# Pure ICU URL eligibility rules: no DB dependency and no topic matching.
# Copied/adapted from studies/news-gap/analysis.R:219-252 (2026-09-18).
# Source SHA256: c341c95f01969f5866e92137904fd068ca928d14314f581e157eed0cbad1d0a0
# Related source helpers: normalize_text (110-113), normalize_path (200-205).
# Preserve first-match precedence and original NFKC title semantics here. This
# URL-label comparison is separate from the NFC article-text normalizer.
# Deliberate extensions: exact Glas Koncila host infers its existing product id;
# a root URL with no substantive query is a homepage (BRIEF section 4.1).
# These rules remove articles from BOTH denominator and numerator.
BAROMETAR_URL_RULES_VERSION <- "url_rules_v1-proposed"
BAROMETAR_URL_RULES_PROVENANCE <- list(
  source_file = "studies/news-gap/analysis.R",
  source_lines = "219-252",
  source_sha256 = "c341c95f01969f5866e92137904fd068ca928d14314f581e157eed0cbad1d0a0",
  added = "2026-09-18",
  status = "proposed: panel G1 ratification pending"
)

.barometar_url_vector <- function(x, size, label) {
  if (is.null(x)) return(rep("", size))
  if (!is.character(x) || length(x) != size) {
    stop(label, " must be NULL or a character vector matching url.", call. = FALSE)
  }
  x[is.na(x)] <- ""
  enc2utf8(x)
}

# Reason is NA_character_ for URLs not rejected by these rules. Missing URL is
# not itself classified as noneditorial: the caller must reject missing article
# keys separately. Title/product arguments are needed for conditional seed rules.
barometar_noneditorial_reason <- function(url, title = NULL, product_id = NULL) {
  if (!is.character(url)) stop("url must be a character vector.", call. = FALSE)
  size <- length(url)
  if (!size) return(character())
  url <- .barometar_url_vector(url, size, "url")
  title <- .barometar_url_vector(title, size, "title")
  product_id <- .barometar_url_vector(product_id, size, "product_id")
  low_url <- stringi::stri_trans_tolower(stringi::stri_trim_both(url), locale = "hr")
  title <- stringi::stri_trans_tolower(stringi::stri_trans_nfkc(title), locale = "hr")
  authority_path <- stringi::stri_replace_first_regex(
    low_url, "^[a-z][a-z0-9+.-]*://", "")
  authority_path <- stringi::stri_replace_first_regex(authority_path, "^//", "")
  host <- stringi::stri_replace_first_regex(authority_path, "[/?#].*$", "")
  host <- stringi::stri_replace_first_regex(host, ":[0-9]+$", "")
  inferred_glas <- product_id == "" & host %in% c("glas-koncila.hr", "www.glas-koncila.hr")
  product_id[inferred_glas] <- "glas_koncila_web"
  path <- stringi::stri_replace_first_regex(authority_path, "^[^/?#]*", "")
  path <- stringi::stri_replace_first_regex(path, "[?#].*$", "")
  path_label <- stringi::stri_replace_all_regex(path, "^/|/$", "")
  path_label <- stringi::stri_replace_all_regex(path_label, "[-_]+", " ")
  path_label <- stringi::stri_trans_tolower(stringi::stri_trans_nfkc(path_label), locale = "hr")
  pagination <- stringi::stri_detect_regex(path, "(^|/)(page|stranica)/[0-9]+/?$")
  root <- path %in% c("", "/")
  reason <- rep(NA_character_, size)
  set_reason <- function(condition, label) {
    matched <- !is.na(condition) & condition & is.na(reason)
    reason[matched] <<- label
  }
  set_reason(pagination, "pagination_url")
  set_reason(stringi::stri_detect_regex(
    path, "^/(category|tag|author|search|taxonomy|kategorija|oznaka|autor|pretraga|feed)(/|$)"),
    "listing_url")
  set_reason(path %in% c("/najnovije/", "/feljtoni/", "/arhiva/", "/archive/") &
               title %in% c("najnovije", "feljtoni", "arhiva", "archive"), "named_listing_url")
  set_reason(title == path_label & title %in% c(
    "vijesti", "novosti", "najava", "najave", "duhovnost", "vjera", "kultura",
    "kultura i znanost", "obitelj", "kolumne", "multimedija", "mulitmedija",
    "emisije", "video", "mladi", "život", "zivot", "dokumenti", "prikazi",
    "biskupije", "feljtoni", "najnovije"), "section_landing_url")
  set_reason(path == "/najave/" & stringi::stri_detect_regex(low_url, "[?&]date=") &
               stringi::stri_detect_regex(title, "^najav"), "calendar_listing_url")
  set_reason(stringi::stri_detect_regex(title, "^arhiva(?:\\s|$)"), "archive_title")
  set_reason(product_id == "glas_koncila_web" &
               stringi::stri_detect_regex(path, "^/(glas-koncila|prilika)-br-"), "issue_landing_url")
  set_reason(title == "početna" & (root | pagination), "homepage_title")
  set_reason(root & stringi::stri_detect_regex(
    low_url, "[?&](photo|view)=(list|archive|category)(?:&|$)"), "root_query_listing")
  set_reason(root & title %in% c("naslovnica", "home", "arhiva", "pretraživanje",
                                "rezultati pretraživanja"), "generic_root_page")
  # A root carrying ?id=, ?p=, or any unknown key may identify a real article.
  # Drop known analytics keys only; query values are never used to infer topics.
  root_candidates <- which(root & host != "" & is.na(reason))
  if (length(root_candidates)) {
    if (!exists("digikat_tracking_parameters", mode = "function")) {
      stop("Source R/lib/digikat_utils.R before applying URL rules.", call. = FALSE)
    }
    fragment_free <- stringi::stri_replace_first_regex(low_url[root_candidates], "#.*$", "")
    query <- stringi::stri_extract_first_regex(fragment_free, "(?<=\\?).*$")
    query[is.na(query)] <- ""
    tracking_only <- vapply(stringi::stri_split_fixed(query, "&", omit_empty = TRUE), function(parts) {
      keys <- stringi::stri_replace_first_regex(parts, "=.*$", "")
      keys <- stringi::stri_trans_tolower(utils::URLdecode(keys), locale = "en")
      length(keys) == 0L || all(startsWith(keys, "utm_") | keys %in% digikat_tracking_parameters())
    }, logical(1L))
    reason[root_candidates[tracking_only]] <- "homepage_root_url"
  }
  reason
}

barometar_noneditorial_url <- function(url, title = NULL, product_id = NULL) {
  !is.na(barometar_noneditorial_reason(url, title, product_id))
}
