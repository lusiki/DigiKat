source("studies/demokrscanstvo-barometar/01_outlets.R", encoding = "UTF-8")
source("R/lib/barometar_text.R", encoding = "UTF-8")
source("R/lib/barometar_url_rules.R", encoding = "UTF-8")
source("R/lib/barometar_outlet_urls.R", encoding = "UTF-8")

# Exact vectorized shortcut for structurally simple ordinary web URLs. Every
# query/fragment/unusual authority and all YouTube forms use the project helper.
# The fast subset performs exactly its scheme/host/default-port/slash operations.
barometar_canonicalize_url <- function(url, verify = FALSE) {
  parts <- stringi::stri_match_first_regex(url,
    "^(?:(https?)://)?([A-Za-z0-9.-]+(?::[0-9]+)?)(/[^?#\\p{White_Space}]*)?$",
    opts_regex = stringi::stri_opts_regex(case_insensitive = TRUE))
  host <- stringi::stri_trans_tolower(parts[, 3L], locale = "en")
  scheme <- stringi::stri_trans_tolower(parts[, 2L], locale = "en")
  host_without_port <- stringi::stri_replace_first_regex(host, ":[0-9]+$", "")
  fast <- !is.na(parts[, 1L]) & !host_without_port %in% c("youtube.com", "www.youtube.com", "m.youtube.com",
    "music.youtube.com", "youtu.be", "www.youtu.be")
  result <- rep(NA_character_, length(url))
  if (any(fast)) {
    h <- stringi::stri_replace_first_regex(host[fast], "^www\\.", "")
    s <- scheme[fast]
    http <- !is.na(s) & s == "http"
    https <- !is.na(s) & s == "https"
    h[http] <- stringi::stri_replace_first_regex(h[http], ":80$", "")
    h[https] <- stringi::stri_replace_first_regex(h[https], ":443$", "")
    p <- parts[fast, 4L]
    p[is.na(p)] <- ""
    p <- stringi::stri_replace_first_regex(p, "/+$", "")
    result[fast] <- paste0("https://", h, p)
  }
  if (any(!fast)) result[!fast] <- digikat_canonicalize_url(url[!fast])
  if (verify && !identical(result, digikat_canonicalize_url(url))) {
    stop("Canonical URL shortcut differs from the project canonicalizer.", call. = FALSE)
  }
  result
}

barometar_url_host <- function(url) {
  host <- stringi::stri_match_first_regex(url, "^(?:[A-Za-z][A-Za-z0-9+.-]*://)?([^/?#]+)")[, 2L]
  host <- stringi::stri_trans_tolower(host, locale = "en")
  stringi::stri_replace_first_regex(host, "^www\\.", "")
}

barometar_cache_signature <- function(readiness, from_values) {
  inputs <- c("R/lib/barometar_text.R",
              "R/lib/barometar_url_rules.R", "R/lib/digikat_utils.R")
  digikat_hash_object(list(input_digest = readiness$input_digest, from_values = sort(from_values),
    source_snapshot = readiness$snapshot[c("file_bytes", "file_mtime", "logs_digest")],
    code = setNames(vapply(inputs, digikat_hash_file, character(1L)), inputs),
    canonicalizer = deparse(body(barometar_canonicalize_url)),
    host_extractor = deparse(body(barometar_url_host)),
    eligibility_contract = "exact_title_prefix;ICU_White_Space+P;nonnull_day>=90%;earliest_bodyeligible_then_noneditorial;within_batch_global_dedup_v2;NUL_transport_UFFFD_v1",
    min_chars = 200L))
}

# Full text is fetched only into bounded transient R batches. Cached records hold
# denominator metadata, never FULL_TEXT, TITLE or MENTION_SNIPPET.
barometar_eligible_metadata <- function(con = NULL, readiness = NULL, inventory = NULL,
                                        workdir = NULL, from_values = NULL, chunk_size = 5000L) {
  workdir <- barometar_workdir(workdir)
  if (is.null(readiness)) readiness <- readRDS(file.path(workdir, "readiness.rds"))
  if (is.null(inventory)) inventory <- readRDS(file.path(workdir, "outlet_inventory.rds"))
  if (is.null(from_values)) from_values <- inventory$candidate_from_values
  if (!length(from_values) || anyNA(from_values)) stop("No valid continuity candidates.", call. = FALSE)
  own_connection <- is.null(con)
  if (own_connection) con <- barometar_connect_readonly()
  if (own_connection) on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  barometar_assert_snapshot(readiness$snapshot, con)
  signature <- barometar_cache_signature(readiness, from_values)
  cache_dir <- file.path(workdir, "denominator", signature)
  dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  table <- barometar_table_sql(con)
  months <- unique(substr(readiness$days$day, 1L, 7L))
  quoted_from <- paste(as.character(DBI::dbQuoteString(con, from_values)), collapse = ",")
  audits <- vector("list", length(months))
  for (i in seq_along(months)) {
    month <- months[[i]]
    cache <- file.path(cache_dir, paste0(month, ".rds"))
    audit_path <- file.path(cache_dir, paste0(month, "-audit.rds"))
    if (file.exists(cache) && file.exists(audit_path)) {
      audits[[i]] <- readRDS(audit_path)
      message("Eligibility ", month, ": cached.")
      next
    }
    observed_days <- readiness$days$day[readiness$days$observed & substr(readiness$days$day, 1L, 7L) == month]
    empty <- data.table::data.table(source_batch = character(), from_value = character(),
      url_host = character(), canonical_url = character(), day = character(), captured_at = character(),
      doc_key = character(), body_chars = integer(), would_fail_i = logical(), noneditorial_reason = character())
    audit <- data.frame(month = month, fetched_rows = 0, body_eligible = 0,
      noneditorial = 0, missing_url = 0, retained_before_dedup = 0, elapsed_seconds = 0)
    if (!length(observed_days)) {
      saveRDS(empty, cache)
      saveRDS(audit, audit_path)
      audits[[i]] <- audit
      next
    }
    day_sql <- paste(as.character(DBI::dbQuoteString(con, observed_days)), collapse = ",")
    # The standalone-i flag is diagnostic only. No eligibility rule uses it.
    i_pattern <- "(^|[^\\p{L}\\p{N}_])[iIıİ]([^\\p{L}\\p{N}_]|$)"
    query <- paste0(
      'SELECT SOURCE_BATCH AS source_batch, lower("FROM") AS from_value, URL, ',
      "replace(TITLE, chr(0), '�') AS TITLE, replace(FULL_TEXT, chr(0), '�') AS FULL_TEXT, ",
      '"DATE" AS day, strftime(DATETIME, \'%Y-%m-%dT%H:%M:%S\') AS captured_at, ',
      "md5(concat_ws('|', SOURCE_BATCH, SOURCE_TYPE, coalesce(CAST(ITEM_ID AS VARCHAR), ''), ",
      "coalesce(URL, ''), strftime(DATETIME, '%Y-%m-%dT%H:%M:%S'), md5(coalesce(FULL_TEXT, '')))) AS doc_key, ",
      "NOT regexp_matches(coalesce(TITLE,'') || ' ' || coalesce(FULL_TEXT,'') || ' ' || ",
      "coalesce(MENTION_SNIPPET,''), ", DBI::dbQuoteString(con, i_pattern), ") AS would_fail_i ",
      'FROM ', table, " WHERE SOURCE_TYPE = 'web' AND lower(\"FROM\") IN (", quoted_from, ") ",
      'AND "DATE" IN (', day_sql, ') AND FULL_TEXT IS NOT NULL AND length(FULL_TEXT) >= 200')
    started <- proc.time()[[3L]]
    result <- DBI::dbSendQuery(con, query)
    pieces <- list()
    batch_number <- 0L
    repeat {
      rows <- DBI::dbFetch(result, n = chunk_size)
      if (!nrow(rows)) break
      audit$fetched_rows <- audit$fetched_rows + nrow(rows)
      chars <- barometar_body_chars(rows$TITLE, rows$FULL_TEXT)
      body_ok <- !is.na(chars) & chars >= 200L
      noneditorial_reason <- barometar_noneditorial_reason(rows$URL, title = rows$TITLE)
      noneditorial <- !is.na(noneditorial_reason)
      canonical <- barometar_canonicalize_url(rows$URL,
        verify = i == 1L && audit$fetched_rows <= 50000L)
      missing_url <- is.na(canonical) | !nzchar(canonical)
      # The representative is earliest BODY-eligible capture. URL/title rules
      # are applied afterwards; a later editorial-looking capture cannot replace
      # an earlier representative that is a section/archive/listing page.
      keep <- body_ok & !missing_url
      audit$body_eligible <- audit$body_eligible + sum(body_ok)
      audit$noneditorial <- audit$noneditorial + sum(body_ok & noneditorial)
      audit$missing_url <- audit$missing_url + sum(body_ok & !noneditorial & missing_url)
      if (any(keep)) {
        batch_number <- batch_number + 1L
        pieces[[batch_number]] <- data.table::data.table(
          source_batch = rows$source_batch[keep], from_value = rows$from_value[keep],
          url_host = barometar_url_host(rows$URL[keep]), canonical_url = canonical[keep],
          day = rows$day[keep], captured_at = rows$captured_at[keep], doc_key = rows$doc_key[keep],
          body_chars = chars[keep], would_fail_i = rows$would_fail_i[keep],
          noneditorial_reason = noneditorial_reason[keep])
      }
    }
    DBI::dbClearResult(result)
    metadata <- if (length(pieces)) data.table::rbindlist(pieces) else empty
    audit$retained_before_dedup <- nrow(metadata)
    audit$elapsed_seconds <- round(proc.time()[[3L]] - started, 3L)
    barometar_assert_snapshot(readiness$snapshot, con)
    saveRDS(metadata, cache, compress = FALSE)
    saveRDS(audit, audit_path)
    audits[[i]] <- audit
    message("Eligibility ", month, ": ", nrow(metadata), " eligible captures in ", audit$elapsed_seconds, " s.")
    rm(rows, pieces, metadata)
    gc(verbose = FALSE)
  }
  audit <- data.table::rbindlist(audits)
  barometar_write_csv(audit, file.path(cache_dir, "eligibility_audit.csv"))
  result <- list(signature = signature, cache_dir = cache_dir,
    month_paths = file.path(cache_dir, paste0(months, ".rds")), from_values = from_values,
    input_digest = readiness$input_digest, audit = as.data.frame(audit))
  saveRDS(result, file.path(workdir, "eligible_metadata_manifest.rds"))
  result
}

barometar_registry_maps <- function(registry) {
  expand <- function(column) {
    entries <- stringi::stri_split_fixed(registry[[column]], ";", omit_empty = TRUE)
    data.frame(value = unlist(entries, use.names = FALSE),
      outlet_id = rep(registry$outlet_id, lengths(entries)), stringsAsFactors = FALSE)
  }
  from <- expand("from_values")
  host <- expand("url_hosts")
  # FROM keys are exact lower(FROM), including a vendor trailing-space anomaly.
  from$value <- stringi::stri_trans_tolower(from$value, locale = "en")
  host$value <- stringi::stri_replace_first_regex(
    stringi::stri_trans_tolower(stringi::stri_trim_both(host$value), locale = "en"), "^www\\.", "")
  if (anyDuplicated(from$value) || anyDuplicated(host$value)) stop("Registry keys are ambiguous.", call. = FALSE)
  list(from = from, host = host)
}

barometar_registry_candidate_from_values <- function(inventory, registry) {
  maps <- barometar_registry_maps(registry)
  host <- inventory$hosts
  host$url_host <- stringi::stri_replace_first_regex(host$url_host, "^www\\.", "")
  host$outlet_id <- maps$host$outlet_id[match(host$url_host, maps$host$value)]
  aliases <- unique(rbind(data.frame(from_value = maps$from$value, outlet_id = maps$from$outlet_id),
    host[!is.na(host$outlet_id), c("from_value", "outlet_id")]))
  raw <- merge(inventory$monthly, aliases, by = "from_value")
  raw <- data.table::as.data.table(raw)
  raw <- raw[month %in% inventory$membership_months,
    .(raw_rows = sum(raw_rows)), by = .(outlet_id, month)]
  pass <- raw[, .(qualifies = .N == length(inventory$membership_months) && min(raw_rows) >= 20), by = outlet_id]
  sort(unique(c(inventory$candidate_from_values,
    aliases$from_value[aliases$outlet_id %in% pass$outlet_id[pass$qualifies]])))
}

barometar_panel_proposal <- function(con = NULL, readiness = NULL, inventory = NULL,
                                     registry_path = "studies/demokrscanstvo-barometar/config/outlet_registry.csv",
                                     workdir = NULL, metadata = NULL) {
  workdir <- barometar_workdir(workdir)
  if (is.null(readiness)) readiness <- readRDS(file.path(workdir, "readiness.rds"))
  if (is.null(inventory)) inventory <- readRDS(file.path(workdir, "outlet_inventory.rds"))
  if (is.null(metadata)) metadata <- readRDS(file.path(workdir, "eligible_metadata_manifest.rds"))
  if (!identical(metadata$input_digest, readiness$input_digest)) {
    stop("Eligibility cache belongs to a different input fingerprint.", call. = FALSE)
  }
  if (!is.null(readiness$snapshot)) {
    own_connection <- is.null(con)
    if (own_connection) con <- barometar_connect_readonly()
    if (own_connection) on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
    barometar_assert_snapshot(readiness$snapshot, con)
    if (is.null(inventory$snapshot) || !identical(inventory$snapshot, readiness$snapshot)) {
      stop("Outlet inventory belongs to a different source snapshot.", call. = FALSE)
    }
  }
  registry <- utils::read.csv(registry_path, fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
  maps <- barometar_registry_maps(registry)
  if (anyDuplicated(registry$outlet_id)) stop("Duplicate registry outlet_id.", call. = FALSE)
  # Include possible continuity achieved jointly by aliases and host overrides.
  needs <- barometar_registry_candidate_from_values(inventory, registry)
  missing <- setdiff(needs, metadata$from_values)
  if (length(missing)) stop("Registry merges add raw continuity candidates; rebuild metadata with their FROM values.", call. = FALSE)
  registry_digest <- digikat_hash_file(registry_path)
  url_policy_hash <- digikat_hash_file("R/lib/barometar_outlet_urls.R")
  private_db <- file.path(metadata$cache_dir, paste0("representatives-", substr(registry_digest, 1L, 12L), ".duckdb"))
  local <- DBI::dbConnect(duckdb::duckdb(), dbdir = private_db)
  on.exit(DBI::dbDisconnect(local, shutdown = TRUE), add = TRUE)
  DBI::dbExecute(local, "DROP TABLE IF EXISTS eligible_captures")
  for (path in metadata$month_paths) {
    rows <- readRDS(path)
    product <- barometar_outlet_url_policy(rows$canonical_url)
    rows$canonical_url_original <- rows$canonical_url
    rows$canonical_url <- product$article_url_key
    apply_policy <- !is.na(product$noneditorial_reason) & is.na(rows$noneditorial_reason)
    rows$noneditorial_reason[apply_policy] <- product$noneditorial_reason[apply_policy]
    rows$outlet_id <- maps$from$outlet_id[match(rows$from_value, maps$from$value)]
    override <- maps$host$outlet_id[match(rows$url_host, maps$host$value)]
    rows$outlet_id[!is.na(override)] <- override[!is.na(override)]
    rows <- rows[!is.na(outlet_id)]
    if (!DBI::dbExistsTable(local, "eligible_captures")) DBI::dbWriteTable(local, "eligible_captures", as.data.frame(rows))
    else if (nrow(rows)) DBI::dbAppendTable(local, "eligible_captures", as.data.frame(rows))
  }
  DBI::dbExecute(local, "CREATE OR REPLACE TABLE body_representatives AS SELECT * FROM eligible_captures QUALIFY row_number() OVER (PARTITION BY source_batch, outlet_id, canonical_url ORDER BY captured_at ASC NULLS LAST, day, doc_key) = 1")
  DBI::dbExecute(local, "CREATE OR REPLACE TABLE representatives AS SELECT * FROM body_representatives WHERE noneditorial_reason IS NULL")
  monthly <- DBI::dbGetQuery(local, "SELECT outlet_id, substr(day,1,7) AS month, COUNT(*) AS eligible_articles FROM representatives GROUP BY 1,2 ORDER BY 1,2")
  monthly$eligible_articles <- as.numeric(monthly$eligible_articles)
  dt <- data.table::as.data.table(monthly)
  continuity <- dt[month %in% inventory$membership_months,
    .(months_with_eligible = .N, min_eligible_articles = min(eligible_articles),
      total_eligible_articles = sum(eligible_articles)), by = outlet_id]
  continuity$continuity_eligible <- continuity$months_with_eligible == length(inventory$membership_months) & continuity$min_eligible_articles >= 20
  proposal <- merge(registry, as.data.frame(continuity), by = "outlet_id", all.x = TRUE, sort = TRUE)
  proposal$continuity_eligible[is.na(proposal$continuity_eligible)] <- FALSE
  yes <- function(x) stringi::stri_trans_tolower(as.character(x), locale = "en") %in% c("true", "yes", "1")
  proposal$proposed_member <- proposal$continuity_eligible & yes(proposal$editorial) & yes(proposal$croatia_link) &
    !proposal$segment %in% c("non_news", "institutional", "aggregator")
  members <- proposal[proposal$proposed_member, c("outlet_id", "display_name", "segment")]
  members$k <- rep(20L, nrow(members))
  members$window_start <- rep(min(inventory$membership_months), nrow(members))
  members$window_end <- rep(max(inventory$membership_months), nrow(members))
  members$excluded_months <- rep("2024-01;2024-02;2024-03", nrow(members))
  members$input_digest <- rep(readiness$input_digest, nrow(members))
  members$registry_hash <- rep(registry_digest, nrow(members))
  members$url_policy_hash <- rep(url_policy_hash,nrow(members))
  members$panel_hash <- rep(digikat_hash_object(list(outlet_ids = sort(members$outlet_id), k = 20L,
    months = inventory$membership_months, input_digest = readiness$input_digest, registry_hash = registry_digest,
    url_policy_hash=url_policy_hash)), nrow(members))
  members$panel_version <- rep("panel_v1-proposed", nrow(members))
  members$status <- rep("awaiting_G1", nrow(members))
  audit <- DBI::dbGetQuery(local, "SELECT (SELECT COUNT(*) FROM eligible_captures) AS captures, COUNT(*) AS representatives, SUM(CASE WHEN source_batch='luka_opce' THEN 1 ELSE 0 END) AS old_eligible, SUM(CASE WHEN source_batch='luka_opce' AND would_fail_i THEN 1 ELSE 0 END) AS old_would_fail_i FROM representatives")
  audit <- lapply(audit, as.numeric)
  audit$body_representatives <- as.numeric(DBI::dbGetQuery(local, "SELECT COUNT(*) AS n FROM body_representatives")$n)
  audit$noneditorial_representatives_removed <- audit$body_representatives - audit$representatives
  member_sql <- if (nrow(members)) paste(as.character(DBI::dbQuoteString(local, members$outlet_id)), collapse = ",") else "NULL"
  panel_i <- DBI::dbGetQuery(local, paste0("SELECT COUNT(*) AS old_eligible, ",
    "COUNT(*) FILTER (WHERE would_fail_i) AS old_would_fail_i FROM representatives ",
    "WHERE source_batch='luka_opce' AND outlet_id IN (", member_sql, ")"))
  audit$standalone_i_scope <- "proposed_panel_only; awaiting_G1"
  audit$panel_old_eligible <- as.numeric(panel_i$old_eligible)
  audit$panel_old_would_fail_i <- as.numeric(panel_i$old_would_fail_i)
  audit$old_i_failure_fraction <- if (audit$panel_old_eligible > 0) audit$panel_old_would_fail_i / audit$panel_old_eligible else NA_real_
  audit$old_i_threshold_pass <- if (audit$panel_old_eligible > 0) isTRUE(audit$old_i_failure_fraction <= 0.0001) else NA
  jan <- DBI::dbGetQuery(local, "SELECT (SELECT COUNT(*) FROM eligible_captures WHERE day >= '2021-01-01' AND day < '2021-02-01') AS captures, COUNT(*) AS representatives FROM representatives WHERE day >= '2021-01-01' AND day < '2021-02-01'")
  audit$january_2021 <- lapply(jan, as.numeric)
  audit$cross_month_duplicate_keys <- as.numeric(DBI::dbGetQuery(local, "SELECT COUNT(*) AS n FROM (SELECT source_batch,outlet_id,canonical_url FROM eligible_captures GROUP BY 1,2,3 HAVING COUNT(DISTINCT substr(day,1,7))>1)")$n)
  duplicates <- as.numeric(DBI::dbGetQuery(local, "SELECT COUNT(*) AS n FROM (SELECT source_batch,outlet_id,canonical_url FROM representatives GROUP BY 1,2,3 HAVING COUNT(*)>1)")$n)
  stopifnot(duplicates == 0, audit$representatives <= audit$captures,
            audit$january_2021$representatives <= audit$january_2021$captures)
  barometar_write_csv(monthly, file.path(workdir, "outlet_eligible_monthly_private.csv"))
  barometar_write_csv(proposal, file.path(workdir, "outlet_panel_review_private.csv"))
  barometar_write_csv(members, file.path(workdir, "panel_v1_proposed.csv"))
  barometar_write_json(audit, file.path(workdir, "denominator_audit.json"))
  result <- list(panel = members, review = proposal, monthly = monthly, audit = audit, private_db = private_db,
    metadata_signature=metadata$signature,registry_hash=registry_digest,url_policy_hash=url_policy_hash)
  if (!is.null(readiness$snapshot)) barometar_assert_snapshot(readiness$snapshot, con)
  saveRDS(result, file.path(workdir, "panel_proposal.rds"))
  message("Panel proposal: ", nrow(members), " members await G1; no membership frozen.")
  if (isFALSE(audit$old_i_threshold_pass)) warning("Standalone-i diagnostic exceeds 0.01%; inspect denominator_audit.json before G1.", call. = FALSE)
  result
}

if (barometar_script_main("02_panel.R")) {
  invisible(barometar_eligible_metadata())
  invisible(barometar_panel_proposal())
}
