source("studies/demokrscanstvo-barometar/lib/io.R", encoding = "UTF-8")

barometar_expected_schema <- function() {
  c(DATE = "VARCHAR", TIME = "VARCHAR", TITLE = "VARCHAR", FROM = "VARCHAR", AUTHOR = "VARCHAR",
    URL = "VARCHAR", URL_PHOTO = "VARCHAR", SOURCE_TYPE = "VARCHAR", GROUP_NAME = "VARCHAR",
    KEYWORD_NAME = "VARCHAR", FOUND_KEYWORDS = "VARCHAR", LANGUAGES = "VARCHAR", LOCATIONS = "VARCHAR",
    TAGS = "BOOLEAN", MANUAL_SENTIMENT = "BOOLEAN", AUTO_SENTIMENT = "VARCHAR", MENTION_SNIPPET = "VARCHAR",
    REACH = "DOUBLE", VIRALITY = "DOUBLE", ENGAGEMENT_RATE = "DOUBLE", INTERACTIONS = "DOUBLE",
    FOLLOWERS_COUNT = "DOUBLE", LIKE_COUNT = "DOUBLE", COMMENT_COUNT = "DOUBLE", SHARE_COUNT = "DOUBLE",
    TWEET_COUNT = "BOOLEAN", LOVE_COUNT = "DOUBLE", WOW_COUNT = "DOUBLE", HAHA_COUNT = "DOUBLE",
    SAD_COUNT = "DOUBLE", ANGRY_COUNT = "DOUBLE", TOTAL_REACTIONS_COUNT = "DOUBLE", FAVORITE_COUNT = "DOUBLE",
    RETWEET_COUNT = "DOUBLE", VIEW_COUNT = "DOUBLE", DISLIKE_COUNT = "BOOLEAN", COUNT = "BOOLEAN",
    REPOST_COUNT = "BOOLEAN", REDDIT_TYPE = "VARCHAR", REDDIT_SCORE = "DOUBLE", INFLUENCE_SCORE = "DOUBLE",
    TWEET_TYPE = "VARCHAR", TWEET_SOURCE_NAME = "VARCHAR", TWEET_SOURCE_URL = "VARCHAR", FULL_TEXT = "VARCHAR",
    DATETIME = "TIMESTAMP", ITEM_ID = "BIGINT", SOURCE_BATCH = "VARCHAR", I_FILTERED = "BOOLEAN")
}

barometar_daily_digest <- function(days) {
  # text_rows additionally distinguishes NULL from empty text: the approved
  # coalesced text hash intentionally cannot distinguish them, but the mask can.
  lines <- paste(days$day, days$web_rows, days$text_rows, days$url_hash_sum, days$text_hash_sum, sep = "|")
  digest::digest(paste(lines, collapse = "\n"), algo = "sha256", serialize = FALSE)
}

barometar_readiness <- function(con = NULL, workdir = NULL) {
  workdir <- barometar_workdir(workdir)
  own_connection <- is.null(con)
  if (own_connection) con <- barometar_connect_readonly()
  if (own_connection) on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  snapshot <- barometar_source_snapshot(con)
  table <- barometar_table_sql(con)
  schema <- DBI::dbGetQuery(con, paste("DESCRIBE", table))
  expected <- c(DATE = "VARCHAR", TITLE = "VARCHAR", FROM = "VARCHAR", URL = "VARCHAR",
                SOURCE_TYPE = "VARCHAR", FULL_TEXT = "VARCHAR", DATETIME = "TIMESTAMP",
                ITEM_ID = "BIGINT", SOURCE_BATCH = "VARCHAR", MENTION_SNIPPET = "VARCHAR")
  observed <- setNames(schema$column_type, schema$column_name)
  if (anyNA(observed[names(expected)]) || !identical(unname(observed[names(expected)]), unname(expected))) {
    stop("DetermDB required-column schema differs from the approved snapshot.", call. = FALSE)
  }
  full_expected <- barometar_expected_schema()
  if (!identical(observed, full_expected)) {
    stop("DetermDB schema drift: names, order or types differ from the approved 49 columns; review readiness schema. Missing: ",
      paste(setdiff(names(full_expected), names(observed)), collapse = ","), "; extra: ",
      paste(setdiff(names(observed), names(full_expected)), collapse = ","), call. = FALSE)
  }
  message("Readiness: fingerprinting all web days (no topic queries).")
  days <- DBI::dbGetQuery(con, paste0(
    'SELECT "DATE" AS day, COUNT(*) AS web_rows, COUNT(FULL_TEXT) AS text_rows, ',
    'CAST(SUM(CAST(hash(URL) AS HUGEINT)) AS VARCHAR) AS url_hash_sum, ',
    'CAST(SUM(CAST(hash(coalesce(FULL_TEXT,\'\')) AS HUGEINT)) AS VARCHAR) AS text_hash_sum ',
    'FROM ', table, ' WHERE SOURCE_TYPE = \'web\' AND "DATE" >= \'2021-01-01\' ',
    'GROUP BY "DATE" ORDER BY "DATE"'))
  if (!nrow(days) || anyNA(days$day) ||
      any(!stringi::stri_detect_regex(days$day, "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"))) {
    stop("Invalid or absent DATE strings in web input.", call. = FALSE)
  }
  parsed <- as.Date(days$day, format = "%Y-%m-%d")
  if (anyNA(parsed) || any(format(parsed, "%Y-%m-%d") != days$day)) {
    stop("DATE contains an invalid calendar day; the input is not safe to bin.", call. = FALSE)
  }
  # HUGEINT fingerprints stay character strings, never IEEE doubles.
  days$web_rows <- as.numeric(days$web_rows)
  days$text_rows <- as.numeric(days$text_rows)
  calendar <- data.frame(day = as.character(seq(as.Date("2021-01-01"), as.Date(max(days$day)), by = "day")))
  days <- merge(calendar, days, by = "day", all.x = TRUE, sort = TRUE)
  days$web_rows[is.na(days$web_rows)] <- 0
  days$text_rows[is.na(days$text_rows)] <- 0
  days$observed <- days$web_rows > 0 & days$text_rows * 10 >= days$web_rows * 9
  days$text_fraction <- ifelse(days$web_rows > 0, days$text_rows / days$web_rows, NA_real_)
  input_digest <- barometar_daily_digest(days)
  masked <- days[!days$observed, c("day", "web_rows", "text_rows", "text_fraction")]
  masked$reason <- ifelse(masked$web_rows == 0, "no_web_rows", "nonnull_full_text_below_90pct")
  masked$mask_version <- "mask_v1_proposed"
  masked$input_digest <- input_digest
  result <- list(data_through = max(days$day), input_digest = input_digest,
    snapshot = snapshot, schema = schema, days = days, masked_days = masked,
    web_rows = sum(days$web_rows), days_observed = sum(days$observed),
    environment = list(R = as.character(getRversion()), locale = Sys.getlocale(),
      duckdb = as.character(utils::packageVersion("duckdb")),
      stringi = as.character(utils::packageVersion("stringi")),
      icu = stringi::stri_info()$ICU.version))
  barometar_assert_snapshot(snapshot, con)
  barometar_write_csv(days, file.path(workdir, "daily_fingerprints.csv"))
  barometar_write_csv(masked, file.path(workdir, "masked_days_proposed.csv"))
  barometar_write_json(result[setdiff(names(result), "days")], file.path(workdir, "readiness.json"))
  saveRDS(result, file.path(workdir, "readiness.rds"))
  message("Readiness: ", result$web_rows, " web rows; ", nrow(masked), " masked days; through ", result$data_through, ".")
  result
}

if (barometar_script_main("00_readiness.R")) invisible(barometar_readiness())
