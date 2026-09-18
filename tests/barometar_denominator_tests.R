# Synthetic denominator checks. Writes only within a temporary test directory.
# Run from repository root after setting a valid UTF-8 system locale.
source("studies/demokrscanstvo-barometar/02_panel.R", encoding = "UTF-8")
source("studies/demokrscanstvo-barometar/00_readiness.R", encoding = "UTF-8")

run_barometar_denominator_tests <- function() {
  root <- tempfile("barometar-denominator-test-")
  dir.create(root)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  test_parent <- paste0(tolower(normalizePath(tempdir(), winslash = "/", mustWork = TRUE)), "/")
  if (!startsWith(tolower(root), test_parent)) stop("Synthetic test cleanup escaped tempdir().")
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  urls <- c(NA_character_, "", " https://WWW.Example.invalid:443/a/// ",
    "http://WWW.Example.invalid:80/a/", "EXAMPLE.invalid:443/a", "example.invalid",
    "https://example.invalid/a?id=2&utm_source=x#top", "https://example.invalid/a?b=2&a=1",
    "https://youtube.com:443/shorts/test", "https://youtu.be/test", "https://youtube.com/embed/test",
    "https://example.invalid/članak/", "https://example.invalid/ć/%C4%8D", "ftp://example.invalid/a",
    "https://example.invalid:80/a", "http://example.invalid:443/a", "https://www.www.example.invalid/a")
  stopifnot(identical(barometar_canonicalize_url(urls, verify = TRUE), digikat_canonicalize_url(urls)))
  product <- barometar_outlet_url_policy(barometar_canonicalize_url(c(
    "https://mojtv.hr/magazin/123/first.aspx", "https://mojtv.hr/magazin/123/second.aspx",
    "https://mojtv.hr/m2/magazin/clanak.aspx?id=123&utm_source=x", "https://mojtv.hr/magazin/124/other.aspx",
    "https://mojtv.hr/m2/film.aspx?id=123", "https://mojtv.hr/m2/magazin/clanak.aspx?id=bad")))
  stopifnot(length(unique(product$article_url_key[1:3]))==1L,
    product$article_url_key[1L]!=product$article_url_key[4L],
    all(is.na(product$noneditorial_reason[1:4])),all(!is.na(product$noneditorial_reason[5:6])))
  stopifnot(identical(barometar_membership_months("2021-03-15"), c("2021-01", "2021-02")))
  stopifnot(identical(barometar_membership_months("2021-02-28"), c("2021-01", "2021-02")))
  registry <- data.frame(outlet_id = c("alpha", "beta"), from_values = c("alpha.invalid", "beta.invalid"),
    url_hosts = c("alpha.invalid;sub.alpha.invalid", "beta.invalid"), display_name = c("Alpha", "Beta"),
    segment = "national", editorial = TRUE, croatia_link = TRUE, evidence_note = "invented fixture",
    seed_source = "synthetic", panel_v1 = FALSE, status = "proposed", stringsAsFactors = FALSE)
  registry_path <- file.path(root, "registry.csv")
  barometar_write_csv(registry, registry_path)
  maps <- barometar_registry_maps(registry)
  stopifnot(maps$host$outlet_id[match("sub.alpha.invalid", maps$host$value)] == "alpha")
  # Same article recurs in February: one earliest eligible representative in Jan.
  # Same URL belonging to beta remains a distinct article. Different source batch
  # remains distinct even for the same outlet and URL, as required by the brief.
  metadata <- data.table::data.table(source_batch = c("luka_opce", "luka_opce", "luka_opce", "mediaspace_full"),
    from_value = c("alpha.invalid", "alpha.invalid", "beta.invalid", "alpha.invalid"),
    url_host = c("alpha.invalid", "alpha.invalid", "beta.invalid", "alpha.invalid"),
    canonical_url = "https://example.invalid/article", day = c("2021-01-31", "2021-02-01", "2021-01-31", "2021-02-01"),
    captured_at = c("2021-01-31T23:59:59", "2021-02-01T00:00:00", "2021-01-31T23:59:59", "2021-02-01T00:00:00"),
    doc_key = c("d1", "d2", "d3", "d4"), body_chars = 250L, would_fail_i = FALSE,
    noneditorial_reason = NA_character_)
  cache_path <- file.path(root, "month.rds")
  saveRDS(metadata, cache_path)
  manifest <- list(cache_dir = root, month_paths = cache_path, from_values = c("alpha.invalid", "beta.invalid"), input_digest = "synthetic")
  readiness <- list(input_digest = "synthetic")
  inventory <- list(membership_months = c("2021-01", "2021-02"), monthly = data.frame(
    from_value = rep(c("alpha.invalid", "beta.invalid"), each = 2L), month = rep(c("2021-01", "2021-02"), 2L), raw_rows = 30L),
    candidate_from_values = c("alpha.invalid", "beta.invalid"),
    hosts = data.frame(from_value = c("alpha.invalid", "beta.invalid"), url_host = c("alpha.invalid", "beta.invalid")))
  result <- barometar_panel_proposal(readiness = readiness, inventory = inventory,
    registry_path = registry_path, workdir = root, metadata = manifest)
  stopifnot(result$audit$captures == 4, result$audit$representatives == 3,
    result$audit$cross_month_duplicate_keys == 1,
    result$audit$january_2021$representatives == 2, nrow(result$panel) == 0)
  # A first capture classified as a section landing page must not be replaced
  # by a later article-looking capture of the identical canonical URL.
  metadata$noneditorial_reason[1L] <- "section_landing_url"
  saveRDS(metadata, cache_path)
  filtered <- barometar_panel_proposal(readiness = readiness, inventory = inventory,
    registry_path = registry_path, workdir = root, metadata = manifest)
  stopifnot(filtered$audit$body_representatives == 3, filtered$audit$representatives == 2,
    filtered$audit$noneditorial_representatives_removed == 1,
    filtered$audit$january_2021$representatives == 1)
  body <- strrep("a", 200L)
  chars <- barometar_body_chars(c("Title", "Title", "Title", "Title"),
    c(paste0("Title: ", body), paste0("Title: ", strrep("a", 199L)), NA_character_, "Title"))
  stopifnot(identical(chars, c(200L, 199L, NA_integer_, 0L)))
  stopifnot(is.na(barometar_canonicalize_url(NA_character_)),
    barometar_noneditorial_url("https://example.invalid/"),
    !barometar_noneditorial_url("https://example.invalid/?id=42"))
  # Day mask uses all web rows before an outlet panel exists. Test the exact
  # 90% boundary, an 89% day, and a wholly absent day; preserve original DATE.
  db <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  on.exit(DBI::dbDisconnect(db, shutdown = TRUE), add = TRUE)
  columns <- barometar_expected_schema()
  declaration <- paste(as.character(DBI::dbQuoteIdentifier(db, names(columns))), columns)
  DBI::dbExecute(db, paste0("CREATE TABLE main.media_data_all (", paste(declaration, collapse = ","), ")"))
  records <- data.frame(DATE = rep(c("2021-01-01", "2021-01-02", "2021-01-04"), each = 100L),
    TITLE = "Title", FROM = "alpha.invalid", URL = "https://alpha.invalid/article", SOURCE_TYPE = "web",
    FULL_TEXT = c(rep(paste0("Title: ", body), 90L), rep(NA_character_, 10L),
      rep(paste0("Title: ", body), 89L), rep(NA_character_, 11L), rep(paste0("Title: ", body), 100L)),
    DATETIME = as.POSIXct("2021-01-01 23:59:59", tz = "UTC"), ITEM_ID = seq_len(300L),
    SOURCE_BATCH = "luka_opce", MENTION_SNIPPET = "unused", stringsAsFactors = FALSE)
  for (name in setdiff(names(columns), names(records))) records[[name]] <- NA_character_
  records <- records[, names(columns)]
  DBI::dbAppendTable(db, "media_data_all", records)
  ready <- barometar_readiness(con = db, workdir = file.path(root, "mask"))
  stopifnot(identical(ready$days$observed, c(TRUE, FALSE, FALSE, TRUE)),
    identical(ready$masked_days$day, c("2021-01-02", "2021-01-03")),
    is.character(ready$days$url_hash_sum), is.character(ready$days$text_hash_sum),
    ready$web_rows == 300, ready$data_through == "2021-01-04")
  changed_mask <- ready$days
  changed_mask$text_rows[1L] <- changed_mask$text_rows[1L] + 1
  stopifnot(!identical(barometar_daily_digest(changed_mask), ready$input_digest))
  DBI::dbExecute(db, "UPDATE main.media_data_all SET DATE='2021-02-30' WHERE ITEM_ID=1")
  invalid_date <- tryCatch(barometar_readiness(con = db, workdir = file.path(root, "bad-date")), error = identity)
  stopifnot(inherits(invalid_date, "error"), stringi::stri_detect_fixed(conditionMessage(invalid_date), "invalid calendar"))
  DBI::dbExecute(db, "ALTER TABLE main.media_data_all DROP COLUMN TAGS")
  schema_error <- tryCatch(barometar_readiness(con = db, workdir = file.path(root, "bad-schema")), error = identity)
  stopifnot(inherits(schema_error, "error"), stringi::stri_detect_fixed(conditionMessage(schema_error), "schema drift"))
  DBI::dbExecute(db, 'ALTER TABLE main.media_data_all DROP COLUMN FULL_TEXT')
  missing_error <- tryCatch(barometar_readiness(con = db, workdir = file.path(root, "missing-text")), error = identity)
  stopifnot(inherits(missing_error, "error"), stringi::stri_detect_fixed(conditionMessage(missing_error), "required-column"))
  message("Barometar denominator checks passed: cross-month/batch/outlet dedup, date strings, exact canonicalization, title eligibility, registry mapping.")
  invisible(TRUE)
}

if (barometar_script_main("barometar_denominator_tests.R")) run_barometar_denominator_tests()
