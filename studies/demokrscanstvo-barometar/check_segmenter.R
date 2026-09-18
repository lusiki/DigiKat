# Independent pre-G2 boundary evaluation; never classifies topics or prints text.
# Run from the repository root after denominator representatives are ready.
# Rscript studies/demokrscanstvo-barometar/check_segmenter.R
# Output: configured private workdir/segmentation/{sample,reference,report} files.
source("studies/demokrscanstvo-barometar/02_panel.R", encoding = "UTF-8")
source("R/lib/barometar_engine.R", encoding = "UTF-8")

barometar_sentence_boundaries <- function(txt, segmenter) {
  sentences <- barometar_sentences(txt, segmenter)
  if (nrow(sentences) < 2L) return(integer())
  starts <- vapply(seq_len(nrow(sentences)), function(i) {
    part <- stringi::stri_sub(txt, sentences$start[i], sentences$end[i])
    first <- stringi::stri_locate_first_regex(part, "[^\\p{White_Space}]")[1L, 1L]
    if (is.na(first)) return(NA_integer_)
    as.integer(sentences$start[i] + first - 1L)
  }, integer(1L))
  starts <- unique(starts[!is.na(starts)])
  if (length(starts) < 2L) integer() else starts[-1L]
}

barometar_udpipe_boundaries <- function(txt, model, doc_key) {
  # TokenRange is zero-based Unicode code-point offset in this local build.
  # It avoids guessed string alignment and exposes no text in the returned data.
  raw <- udpipe::udpipe_annotate(model, x = txt, doc_id = doc_key,
    tokenizer = "tokenizer=ranges", tagger = "none", parser = "none", trace = FALSE)
  if (length(raw$error) && any(!is.na(raw$error) & nzchar(raw$error))) {
    stop("udpipe_annotation_error", call. = FALSE)
  }
  annotated <- suppressWarnings(as.data.frame(raw))
  if (!nrow(annotated)) stop("udpipe_empty_annotation", call. = FALSE)
  ranges <- stringi::stri_match_first_regex(annotated$misc, "TokenRange=([0-9]+):([0-9]+)")
  start <- as.integer(ranges[, 2L]) + 1L
  end <- as.integer(ranges[, 3L])
  usable <- !is.na(start) & !is.na(end) & end >= start
  if (!any(usable)) stop("udpipe_missing_ranges", call. = FALSE)
  # Validate the coordinate convention on every returned range. Multiword-token
  # expansions can have no range; their parent range remains available.
  recovered <- stringi::stri_sub(txt, start[usable], end[usable])
  if (!all(recovered == annotated$token[usable])) stop("udpipe_range_alignment_error", call. = FALSE)
  sentence <- paste(annotated$paragraph_id, annotated$sentence_id, sep = ":")
  first <- tapply(start[usable], sentence[usable], min)
  first <- sort(unique(as.integer(first)))
  if (length(first) < 2L) integer() else first[-1L]
}

barometar_segmenter_selfcheck <- function(model, segmenter) {
  invented <- "Prva rečenica. Druga rečenica!\nTreća rečenica."
  stopifnot(identical(barometar_sentence_boundaries(invented, segmenter),
    barometar_udpipe_boundaries(invented, model, "invented")))
  # A Unicode prefix distinguishes bytes from code points, including astral text.
  invented <- "Život čuva čovjeka. 😀 Druga rečenica."
  invisible(barometar_udpipe_boundaries(invented, model, "invented_unicode"))
}

barometar_check_segmenter <- function(workdir = NULL, seed = 20260918L, n_per_batch = 300L) {
  stopifnot(identical(as.integer(n_per_batch), 300L))
  workdir <- barometar_workdir(workdir)
  folder <- file.path(workdir, "segmentation")
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)
  model_path <- "resources/models/croatian-set-ud-2.5-191206.udpipe"
  if (!requireNamespace("udpipe", quietly = TRUE) || !file.exists(model_path)) stop("missing_udpipe_input")
  prerequisites <- file.path(workdir, c("readiness.rds", "eligible_metadata_manifest.rds", "panel_proposal.rds"))
  if (!all(file.exists(prerequisites))) {
    barometar_write_json(list(status = "blocked_missing_completed_denominator", gate_pass = FALSE,
      n_per_batch = n_per_batch, seed = seed, missing = basename(prerequisites[!file.exists(prerequisites)])),
      file.path(folder, "report.json"))
    message("Segmentation not run: completed denominator metadata/proposal is required.")
    return(invisible(NULL))
  }
  readiness <- readRDS(prerequisites[1L])
  metadata <- readRDS(prerequisites[2L])
  proposal <- readRDS(prerequisites[3L])
  if (!identical(metadata$input_digest, readiness$input_digest)) stop("stale_metadata_digest")
  if (!nrow(proposal$panel)) stop("empty_proposed_panel")
  if (!all(proposal$panel$input_digest == readiness$input_digest)) stop("stale_panel_digest")
  policy_hash <- digikat_hash_file("R/lib/barometar_outlet_urls.R")
  if (!"url_policy_hash" %in% names(proposal$panel) ||
      !all(proposal$panel$url_policy_hash == policy_hash)) {
    barometar_write_json(list(status = "blocked_outlet_url_policy_rebuild", gate_pass = FALSE),
      file.path(folder, "report.json"))
    message("Segmentation not run: representative metadata needs the current outlet URL policy.")
    return(invisible(NULL))
  }
  definition <- barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")
  engine_sha256 <- digikat_hash_file("R/lib/barometar_engine.R")
  segmenter <- definition$documents[["segmenter.yaml"]]
  model <- udpipe::udpipe_load_model(model_path)
  barometar_segmenter_selfcheck(model, segmenter)
  sample_identity <- list(input_digest = readiness$input_digest, panel_hash = unique(proposal$panel$panel_hash),
    seed = seed, n_per_batch = n_per_batch, selection = "seeded_hash_order_of_dev_representatives_no_keywords")
  sample_path <- file.path(folder, "sample.rds")
  if (file.exists(sample_path)) {
    stored <- readRDS(sample_path)
    if (!identical(stored$identity, sample_identity)) stop("existing_sample_identity_mismatch")
    selected <- stored$selected
  } else {
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = proposal$private_db, read_only = TRUE)
    selected <- tryCatch({
      outlets <- paste(DBI::dbQuoteString(con, proposal$panel$outlet_id), collapse = ",")
      query <- paste0("WITH keyed AS (SELECT doc_key,source_batch,day,from_value, ",
        "md5(outlet_id || '|' || canonical_url) AS article_hash FROM representatives WHERE outlet_id IN (", outlets,
        ")), development AS (SELECT * FROM keyed WHERE CAST(('0x' || substr(article_hash,1,7)) AS BIGINT)%10<3), ",
        "ranked AS (SELECT *, row_number() OVER (PARTITION BY source_batch ORDER BY md5('", seed,
        "|' || article_hash),article_hash,doc_key) AS sample_rank FROM development) ",
        "SELECT * FROM ranked WHERE sample_rank<=", n_per_batch, " ORDER BY source_batch,sample_rank")
      DBI::dbGetQuery(con, query)
    }, finally = DBI::dbDisconnect(con, shutdown = TRUE))
    if (!setequal(unique(selected$source_batch), c("luka_opce", "mediaspace_full")) ||
        any(table(selected$source_batch) != n_per_batch) || anyDuplicated(selected$article_hash)) stop("incomplete_or_duplicate_sample")
    stopifnot(all(strtoi(substr(selected$article_hash, 1L, 7L), 16L) %% 10L < 3L))
    saveRDS(list(identity = sample_identity, selected = selected), sample_path)
    exclusions <- selected[, c("doc_key", "article_hash", "source_batch")]
    exclusions$purpose <- "segmenter_development_reference"
    exclusions$seed <- seed
    exclusions$development <- TRUE
    barometar_write_csv(exclusions, file.path(folder, "evaluation_exclusions.csv"))
  }
  # This stores raw input only inside WORKDIR. Never print it, or copy it into
  # the repository. Reuse lets code revisions compare exactly the same sample.
  input_path <- file.path(folder, "input_private.rds")
  if (file.exists(input_path)) {
    inputs <- readRDS(input_path)
    if (!setequal(inputs$doc_key, selected$doc_key) || anyDuplicated(inputs$doc_key)) stop("cached_sample_keys_mismatch")
  } else {
    con <- barometar_connect_readonly()
    inputs <- tryCatch({
      barometar_assert_snapshot(readiness$snapshot, con)
      table <- barometar_table_sql(con)
      key <- "md5(concat_ws('|',SOURCE_BATCH,SOURCE_TYPE,coalesce(CAST(ITEM_ID AS VARCHAR),''),coalesce(URL,''),strftime(DATETIME,'%Y-%m-%dT%H:%M:%S'),md5(coalesce(FULL_TEXT,''))))"
      pieces <- list()
      for (month in unique(substr(selected$day, 1L, 7L))) {
        chunk <- selected[substr(selected$day, 1L, 7L) == month, , drop = FALSE]
        quote <- function(x) paste(DBI::dbQuoteString(con, unique(x)), collapse = ",")
        query <- paste0("SELECT DISTINCT ", key, " AS doc_key,replace(TITLE,chr(0),'�') AS title,",
          "replace(FULL_TEXT,chr(0),'�') AS full_text FROM ", table,
          " WHERE SOURCE_TYPE='web' AND \"DATE\" IN (", quote(chunk$day), ") AND lower(\"FROM\") IN (",
          quote(chunk$from_value), ") AND ", key, " IN (", quote(chunk$doc_key), ")")
        pieces[[length(pieces) + 1L]] <- DBI::dbGetQuery(con, query)
        message("Segmentation private input chunks prepared: ", length(pieces), ".")
      }
      barometar_assert_snapshot(readiness$snapshot, con)
      as.data.frame(data.table::rbindlist(pieces))
    }, finally = DBI::dbDisconnect(con, shutdown = TRUE))
    if (!setequal(inputs$doc_key, selected$doc_key) || anyDuplicated(inputs$doc_key)) stop("source_sample_keys_mismatch")
    saveRDS(inputs, input_path)
  }
  inputs <- inputs[match(selected$doc_key, inputs$doc_key), , drop = FALSE]
  prepared <- barometar_prepare_text(inputs$title, inputs$full_text, cap = definition$text_cap)
  if (!all(prepared$eligible)) stop("sample_eligibility_drift")
  normalized <- barometar_normalize_text(prepared$body)
  reference_identity <- list(sample = sample_identity, model_sha256 = digikat_hash_file(model_path),
    normalizer_sha256 = digikat_hash_file("R/lib/barometar_text.R"), text_cap = definition$text_cap,
    udpipe_version = as.character(utils::packageVersion("udpipe")))
  reference_path <- file.path(folder,paste0("reference-",substr(digikat_hash_object(reference_identity),1L,24L),"_private.rds"))
  if (file.exists(reference_path)) {
    cached <- readRDS(reference_path)
    if (!identical(cached$identity, reference_identity)) stop("reference_identity_mismatch")
    reference <- cached$boundaries
  } else {
    reference <- vector("list", nrow(selected))
    for (i in seq_len(nrow(selected))) {
      reference[[i]] <- barometar_udpipe_boundaries(normalized[i], model, selected$doc_key[i])
      if (i %% 50L == 0L) message("Segmentation reference documents processed: ", i, "/", nrow(selected), ".")
    }
    saveRDS(list(identity = reference_identity, boundaries = reference), reference_path)
  }
  per_doc <- selected[, c("doc_key", "article_hash", "source_batch")]
  per_doc$predicted <- per_doc$reference <- per_doc$true_positive <- integer(nrow(per_doc))
  for (i in seq_len(nrow(selected))) {
    predicted <- barometar_sentence_boundaries(normalized[i], segmenter)
    per_doc$predicted[i] <- length(predicted)
    per_doc$reference[i] <- length(reference[[i]])
    per_doc$true_positive[i] <- length(intersect(predicted, reference[[i]]))
  }
  aggregate <- data.table::as.data.table(per_doc)[, .(documents = .N, predicted = sum(predicted),
    reference = sum(reference), true_positive = sum(true_positive)), by = source_batch]
  aggregate$precision <- aggregate$true_positive / aggregate$predicted
  aggregate$recall <- aggregate$true_positive / aggregate$reference
  aggregate$pass <- aggregate$documents == 300L & is.finite(aggregate$precision) & is.finite(aggregate$recall) &
    aggregate$precision >= .93 & aggregate$recall >= .93
  report <- list(status = "completed", gate_pass = all(aggregate$pass), seed = seed,
    selection = sample_identity$selection, sample_status = "development_only_excluded_from_evaluation",
    definition_version = definition$definition_version, input_digest = readiness$input_digest,
    engine_sha256 = engine_sha256, reference = reference_identity,
    metric = "micro exact internal next-sentence starts at first non-whitespace code point; document starts and terminal ends omitted; normalized capped body; no boilerplate mask",
    batches = as.data.frame(aggregate))
  barometar_write_csv(per_doc, file.path(folder, "per_document_metrics_private.csv"))
  barometar_write_csv(as.data.frame(aggregate), file.path(folder, "metrics.csv"))
  barometar_write_json(report, file.path(folder, "report.json"))
  print(as.data.frame(aggregate), row.names = FALSE)
  message("Segmentation gate pass: ", report$gate_pass, ". No topic classifications or period series computed.")
  invisible(report)
}

barometar_segmenter_diagnostics <- function(workdir = NULL) {
  folder <- file.path(barometar_workdir(workdir), "segmentation")
  selected <- readRDS(file.path(folder, "sample.rds"))$selected
  inputs <- readRDS(file.path(folder, "input_private.rds"))
  inputs <- inputs[match(selected$doc_key, inputs$doc_key), , drop = FALSE]
  reference <- readRDS(file.path(folder, "reference_private.rds"))$boundaries
  definition <- barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")
  segmenter <- definition$documents[["segmenter.yaml"]]
  prepared <- barometar_prepare_text(inputs$title, inputs$full_text, cap = definition$text_cap)
  normalized <- barometar_normalize_text(prepared$body)
  rows <- list()
  for (i in seq_along(normalized)) {
    boundary <- barometar_sentence_boundaries(normalized[i], segmenter)
    if (!length(boundary)) next
    prefix <- stringi::stri_sub(normalized[i], 1L, boundary - 1L)
    whitespace <- stringi::stri_extract_last_regex(prefix, "\\p{White_Space}+$")
    newline <- !is.na(whitespace) & stringi::stri_detect_fixed(whitespace, "\n")
    clean <- stringi::stri_trim_right(prefix)
    terminal <- stringi::stri_detect_regex(clean, '[.!?…]["”’»\\)\\]]*$')
    type <- ifelse(newline, ifelse(terminal, "newline_after_terminal", "newline_without_terminal"), "soft_punctuation")
    stem <- stringi::stri_replace_last_regex(clean, '[.!?…]["”’»\\)\\]]*$', "")
    previous <- stringi::stri_extract_last_regex(stem, "[\\p{L}\\p{N}]+$")
    category <- rep("word", length(previous))
    category[stringi::stri_trans_tolower(previous, "hr") %in% unlist(segmenter$abbreviations)] <- "known_abbreviation"
    category[which(stringi::stri_detect_regex(previous, "^\\p{Lu}$"))] <- "single_capital"
    category[which(stringi::stri_detect_regex(previous, "^[IVXLCDM]+$"))] <- "roman"
    category[which(stringi::stri_detect_regex(previous, "^[0-9]+$"))] <- "number_long"
    category[which(stringi::stri_detect_regex(previous, "^[0-9]{1,4}$"))] <- "number_1_4"
    category[is.na(previous)] <- "none"
    near <- vapply(boundary, function(k) length(reference[[i]]) && min(abs(reference[[i]] - k)) <= 3L, logical(1L))
    rows[[length(rows) + 1L]] <- data.frame(source_batch = selected$source_batch[i], type = type,
      previous_category = category, preceding_closer = stringi::stri_detect_regex(clean, '["”’»\\)\\]]$'),
      following_opener = stringi::stri_detect_regex(stringi::stri_sub(normalized[i], boundary, boundary), '^["“„«]'),
      correct = boundary %in% reference[[i]], reference_within_3_codepoints = near)
  }
  all <- data.table::rbindlist(rows)
  categories <- all[, .(boundaries = .N, true_positive = sum(correct), false_positive = sum(!correct)), by = .(source_batch, type)]
  previous <- all[correct == FALSE, .(false_positive = .N), by = .(source_batch, previous_category)]
  quotes <- all[correct == FALSE, .(false_positive = .N, near_reference = sum(reference_within_3_codepoints)), by = .(source_batch, preceding_closer, following_opener)]
  for (x in list(categories, previous, quotes)) print(as.data.frame(x), row.names = FALSE)
  message("Documents containing newline: ", sum(stringi::stri_detect_fixed(normalized, "\n")), ".")
  saveRDS(all, file.path(folder, "boundary_categories_private.rds"))
  barometar_write_json(list(boundary_types = as.data.frame(categories), preceding_categories = as.data.frame(previous),
    quote_patterns = as.data.frame(quotes)), file.path(folder, "diagnostic_categories.json"))
  invisible(all)
}

barometar_segmenter_recovery_diagnostics <- function(workdir = NULL) {
  folder <- file.path(barometar_workdir(workdir), "segmentation")
  selected <- readRDS(file.path(folder, "sample.rds"))$selected
  inputs <- readRDS(file.path(folder, "input_private.rds"))
  inputs <- inputs[match(selected$doc_key, inputs$doc_key), , drop = FALSE]
  reference <- readRDS(file.path(folder, "reference_private.rds"))$boundaries
  definition <- barometar_load_definition("resources/dictionaries/demokrscanstvo/v1")
  segmenter <- definition$documents[["segmenter.yaml"]]
  prepared <- barometar_prepare_text(inputs$title, inputs$full_text, cap = definition$text_cap)
  normalized <- barometar_normalize_text(prepared$body)
  errors <- list()
  scenarios <- list()
  for (i in seq_along(normalized)) {
    txt <- normalized[i]
    predicted <- barometar_sentence_boundaries(txt, segmenter)
    missed <- setdiff(reference[[i]], predicted)
    if (length(missed)) {
      prefix <- stringi::stri_sub(txt, 1L, missed - 1L)
      space <- stringi::stri_extract_last_regex(prefix, "\\p{White_Space}+$")
      space[is.na(space)] <- ""
      breaks <- stringi::stri_count_fixed(space, "\n")
      whitespace <- ifelse(breaks >= 2L, "blank_line", ifelse(breaks == 1L, "single_newline", ifelse(nzchar(space), "space", "none")))
      terminal <- stringi::stri_detect_regex(stringi::stri_trim_right(prefix), '[.!?…]["”’»\\)\\]]*$')
      next_char <- stringi::stri_sub(txt, missed, missed)
      next_class <- ifelse(stringi::stri_detect_regex(next_char, "\\p{Ll}"), "lowercase",
        ifelse(stringi::stri_detect_regex(next_char, "\\p{Lu}"), "uppercase",
          ifelse(stringi::stri_detect_regex(next_char, "[0-9]"), "digit", "punctuation_or_symbol")))
      errors[[length(errors) + 1L]] <- data.frame(batch = selected$source_batch[i], whitespace, terminal, next_class)
    }
    # Structural alternatives are scored as proposals, on the full unchanged
    # reference. No false boundaries are removed from any denominator.
    lines <- stringi::stri_locate_all_regex(txt, "\\n[\\p{White_Space}]*[^\\p{White_Space}]", omit_no_match = TRUE)[[1L]]
    blank <- integer()
    if (nrow(lines)) {
      b <- lines[, 2L]
      space <- stringi::stri_extract_last_regex(stringi::stri_sub(txt, 1L, b - 1L), "\\p{White_Space}+$")
      blank <- b[stringi::stri_count_fixed(space, "\n") >= 2L]
    }
    endings <- stringi::stri_locate_all_regex(txt,
      '[.!?…]["”’»\\)\\]]*[ \\n]+(?=[\\p{Ll}\\(\\-–—])', omit_no_match = TRUE)[[1L]]
    extra <- integer()
    if (nrow(endings)) for (j in seq_len(nrow(endings))) {
      at <- endings[j, 1L]
      previous <- stringi::stri_extract_last_regex(stringi::stri_sub(txt, to = at - 1L), "[\\p{L}\\p{N}]+$")
      dot <- stringi::stri_sub(txt, at, at) == "."
      # Preserve the brief's abbreviation and lower-case ordinal exclusions.
      exempt <- !is.na(previous) && (stringi::stri_trans_tolower(previous, "hr") %in% unlist(segmenter$abbreviations) ||
        stringi::stri_detect_regex(previous, "^(?:[0-9]{1,4}|[IVXLCDM]+|\\p{Lu})$"))
      if (!dot || !exempt) extra <- c(extra, endings[j, 2L] + 1L)
    }
    symbol_extra <- extra[stringi::stri_detect_regex(stringi::stri_sub(txt, extra, extra), "^[\\(\\-–—]")]
    for (name in c("current", "blank_lines", "additional_terminal_starts", "dialogue_or_parenthesis_starts", "both")) {
      candidate <- sort(unique(c(predicted, if (name %in% c("blank_lines", "both")) blank else integer(),
        if (name %in% c("additional_terminal_starts", "both")) extra else integer(),
        if (name == "dialogue_or_parenthesis_starts") symbol_extra else integer())))
      scenarios[[length(scenarios) + 1L]] <- data.frame(batch = selected$source_batch[i], proposal = name,
        predicted = length(candidate), reference = length(reference[[i]]), true_positive = length(intersect(candidate, reference[[i]])))
    }
  }
  grouped <- data.table::rbindlist(errors)[, .(false_negative = .N), by = .(batch, whitespace, terminal, next_class)]
  result <- data.table::rbindlist(scenarios)[, .(predicted = sum(predicted), reference = sum(reference), true_positive = sum(true_positive)), by = .(batch, proposal)]
  result$precision <- result$true_positive / result$predicted
  result$recall <- result$true_positive / result$reference
  print(as.data.frame(grouped), row.names = FALSE)
  print(as.data.frame(result), row.names = FALSE)
  barometar_write_json(list(status = "development_proposals_not_engine_changes", false_negative_categories = as.data.frame(grouped),
    proposals = as.data.frame(result)), file.path(folder, "recovery_proposals.json"))
  invisible(result)
}

if (barometar_script_main("check_segmenter.R")) {
  if (!nzchar(Sys.getenv("DIGIKAT_BAROMETAR_WORKDIR"))) readRenviron(path.expand("~/.Renviron"))
  # No exception text is emitted: external libraries can put source inputs in
  # error strings. Failure is never reported as passing or silently omitted.
  tryCatch(barometar_check_segmenter(), error = function(e) {
    safe <- c("udpipe_annotation_error", "udpipe_empty_annotation", "udpipe_missing_ranges",
      "udpipe_range_alignment_error", "missing_udpipe_input", "stale_metadata_digest", "empty_proposed_panel",
      "stale_panel_digest", "existing_sample_identity_mismatch", "incomplete_or_duplicate_sample",
      "cached_sample_keys_mismatch", "source_sample_keys_mismatch", "sample_eligibility_drift", "reference_identity_mismatch")
    code <- if (conditionMessage(e) %in% safe) conditionMessage(e) else "external_or_assertion_error"
    message("Segmentation check failed; no metrics claimed. Safe error code: ", code, ".")
    quit(save = "no", status = 1L)
  })
}
