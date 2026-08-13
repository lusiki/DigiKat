#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, warn = 1)

required_packages <- c("data.table", "jsonlite", "digest")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1L), quietly = TRUE)]
if (length(missing_packages)) {
  stop("Missing required package(s): ", paste(missing_packages, collapse = ", "), call. = FALSE)
}
suppressPackageStartupMessages(library(data.table))

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (!length(script_arg)) stop("Run this file with Rscript.", call. = FALSE)
script_path <- normalizePath(sub("^--file=", "", script_arg[[1L]]), winslash = "/", mustWork = TRUE)
study_dir <- dirname(script_path)
repo_root <- normalizePath(file.path(study_dir, "../.."), winslash = "/", mustWork = TRUE)
old_wd <- setwd(repo_root)
on.exit(setwd(old_wd), add = TRUE)

output_dir <- file.path(study_dir, "output")
intermediate_dir <- file.path(output_dir, "intermediate")
required_files <- file.path(output_dir, c(
  "gap_overall.csv", "outlet_profiles.csv", "event_results.csv", "lag_model.csv",
  "diagnostics.csv", "analysis_results.json", "manifest.json",
  "figures/produced_vs_rewarded.png", "figures/papal_transition_gap.png",
  "figures/lag_coefficient.png"
))
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files)) stop("Missing output(s): ", paste(missing_files, collapse = ", "), call. = FALSE)

assert_close <- function(value, target, tolerance, label) {
  if (any(!is.finite(value)) || any(abs(value - target) > tolerance)) {
    stop(label, " failed. Observed: ", paste(signif(value, 8), collapse = ", "), call. = FALSE)
  }
}

field <- fread(file.path(output_dir, "gap_overall.csv"), encoding = "UTF-8")
assert_close(sum(field$production_pct), 100, 1e-6, "Public production vector sum")
assert_close(sum(field$reward_pct), 100, 1e-6, "Public reward vector sum")
assert_close(sum(field$gap_pp), 0, 1e-6, "Public gap vector zero sum")
assert_close(sum(field$production_pct_full_text), 100, 1e-6, "Full-text production vector sum")
assert_close(sum(field$reward_pct_full_text), 100, 1e-6, "Full-text reward vector sum")
assert_close(sum(field$gap_pp_full_text), 0, 1e-6, "Full-text gap vector zero sum")
if (field[topic != "OSTALE_RIJETKE_TEME", any(total_post_mass < 20)]) {
  stop("Public exact topic below the 20-post disclosure/support threshold.", call. = FALSE)
}
if (field[topic != "OSTALE_RIJETKE_TEME", any(n_products_supported < 3L)]) {
  stop("Public exact topic has fewer than three products with five assigned posts.", call. = FALSE)
}
profiles <- fread(file.path(output_dir, "outlet_profiles.csv"), encoding = "UTF-8")
required_profile_columns <- c(
  "most_overrewarded_gap_pp_winsorized", "most_overrewarded_gap_pp_top_removed",
  "most_overrewarded_gap_pp_full_text", "most_overrewarded_direction_consistent",
  "most_underrewarded_gap_pp_winsorized", "most_underrewarded_gap_pp_top_removed",
  "most_underrewarded_gap_pp_full_text", "most_underrewarded_direction_consistent",
  "interpretation"
)
if (length(setdiff(required_profile_columns, names(profiles)))) {
  stop("Outlet profiles omit required robustness/interpretation fields.", call. = FALSE)
}
if (profiles[, any(most_overrewarded_post_mass < 20 | most_underrewarded_post_mass < 20)]) {
  stop("Outlet profile names a topic below the public 20-post support gate.", call. = FALSE)
}

outlet_topic_path <- file.path(output_dir, "private", "outlet_topic_profiles.csv")
outlet_figure_path <- file.path(output_dir, "private", "produced_vs_rewarded_by_outlet.png")
if (!file.exists(outlet_topic_path) || !file.exists(outlet_figure_path)) {
  stop("Private per-outlet produced-versus-rewarded outputs are missing.", call. = FALSE)
}
outlet_topics <- fread(outlet_topic_path, encoding = "UTF-8")
if (!setequal(unique(outlet_topics$product_id), profiles$product_id)) {
  stop("Private topic profiles do not cover exactly the six reported products.", call. = FALSE)
}
outlet_product_figure_paths <- file.path(
  output_dir, "private", "outlet_figures", paste0(sort(profiles$product_id), ".png")
)
if (any(!file.exists(outlet_product_figure_paths))) {
  stop("One or more private product-level charts are missing.", call. = FALSE)
}
outlet_vector_checks <- outlet_topics[, .(
  production_sum = sum(production_pct),
  reward_sum = sum(reward_pct),
  gap_sum = sum(gap_pp),
  winsorized_gap_sum = sum(gap_pp_winsorized),
  top_removed_gap_sum = sum(gap_pp_top_removed),
  production_full_sum = sum(production_pct_full_text),
  reward_full_sum = sum(reward_pct_full_text),
  gap_full_sum = sum(gap_pp_full_text),
  status_values = uniqueN(validation_status)
), by = product_id]
assert_close(outlet_vector_checks$production_sum, 100, 1e-6,
             "Private outlet production vector sums")
assert_close(outlet_vector_checks$reward_sum, 100, 1e-6,
             "Private outlet reward vector sums")
assert_close(outlet_vector_checks$gap_sum, 0, 1e-6,
             "Private outlet gap vector zero sums")
assert_close(outlet_vector_checks$winsorized_gap_sum, 0, 1e-6,
             "Private outlet winsorized gap vector zero sums")
assert_close(outlet_vector_checks$top_removed_gap_sum, 0, 1e-6,
             "Private outlet top-removed gap vector zero sums")
assert_close(outlet_vector_checks$production_full_sum, 100, 1e-6,
             "Private outlet full-text production vector sums")
assert_close(outlet_vector_checks$reward_full_sum, 100, 1e-6,
             "Private outlet full-text reward vector sums")
assert_close(outlet_vector_checks$gap_full_sum, 0, 1e-6,
             "Private outlet full-text gap vector zero sums")
allowed_outlet_status <- c(
  "exploratory_pending_manual_dictionary_validation",
  "published_provisional_pending_manual_dictionary_validation",
  "validated_for_publication"
)
observed_outlet_status <- unique(outlet_topics$validation_status)
if (any(outlet_vector_checks$status_values != 1L) || length(observed_outlet_status) != 1L ||
    !observed_outlet_status %in% allowed_outlet_status) {
  stop("Private outlet profiles do not carry one recognized study status.", call. = FALSE)
}
if (outlet_topics[
  topic != "OSTALE_RIJETKE_TEME",
  any(post_mass < 20 | topics_pooled != 1L)
]) {
  stop("A named private outlet topic falls below the support gate or pools multiple topics.",
       call. = FALSE)
}
results_json <- jsonlite::fromJSON(file.path(output_dir, "analysis_results.json"), simplifyVector = TRUE)
if (!identical(as.character(results_json$status), observed_outlet_status)) {
  stop("Private outlet profile status differs from the analysis result status.", call. = FALSE)
}
public_outlet_topic_path <- file.path(output_dir, "outlet_topic_profiles.csv")
public_outlet_status <- observed_outlet_status %in% c(
  "published_provisional_pending_manual_dictionary_validation",
  "validated_for_publication"
)
if (public_outlet_status !=
    file.exists(public_outlet_topic_path)) {
  stop("Public outlet topic table does not match the validation status.", call. = FALSE)
}
expected_headline_months <- c("2025-02", "2025-06", "2025-07", "2025-08",
                              "2025-10", "2025-11", "2025-12")
if (!identical(as.character(results_json$headline_months), expected_headline_months)) {
  stop("Headline months differ from the seven audited complete months.", call. = FALSE)
}

month_panel_path <- file.path(intermediate_dir, "news_gap_month_panel.rds")
if (!file.exists(month_panel_path)) stop("Missing private month panel.", call. = FALSE)
panel <- as.data.table(readRDS(month_panel_path))
cell_keys <- c("analysis_era", "product_id", "period")
panel_checks <- panel[, .(
  n_topics = uniqueN(topic),
  production_sum = sum(production_pct),
  reward_sum = if (all(is.na(reward_pct))) NA_real_ else sum(reward_pct),
  gap_sum = if (all(is.na(gap_pp))) NA_real_ else sum(gap_pp),
  reward_winsorized_sum = if (all(is.na(reward_share_winsorized))) NA_real_ else 100 * sum(reward_share_winsorized),
  reward_top_removed_sum = if (all(is.na(reward_share_top_removed))) NA_real_ else 100 * sum(reward_share_top_removed),
  gap_winsorized_sum = if (all(is.na(gap_pp_winsorized))) NA_real_ else sum(gap_pp_winsorized),
  gap_top_removed_sum = if (all(is.na(gap_pp_top_removed))) NA_real_ else sum(gap_pp_top_removed),
  mass_sum = sum(post_mass),
  classified = unique(n_classified)
), by = cell_keys]
if (any(panel_checks$n_topics != 16L)) stop("A product-period does not contain exactly 16 topics.", call. = FALSE)
assert_close(panel_checks$mass_sum, panel_checks$classified, 1e-6, "Fractional assignment mass")
classified_checks <- panel_checks[classified > 0]
assert_close(classified_checks$production_sum, 100, 1e-6, "Product-period production vector sums")
eligible_checks <- classified_checks[is.finite(reward_sum)]
assert_close(eligible_checks$reward_sum, 100, 1e-6, "Product-period reward vector sums")
assert_close(eligible_checks$gap_sum, 0, 1e-6, "Product-period gap zero sums")
robust_checks <- classified_checks[is.finite(reward_winsorized_sum) & is.finite(reward_top_removed_sum)]
assert_close(robust_checks$reward_winsorized_sum, 100, 1e-6, "Winsorized reward vector sums")
assert_close(robust_checks$reward_top_removed_sum, 100, 1e-6, "Top-removed reward vector sums")
assert_close(robust_checks$gap_winsorized_sum, 0, 1e-6, "Winsorized gap zero sums")
assert_close(robust_checks$gap_top_removed_sum, 0, 1e-6, "Top-removed gap zero sums")

add_month <- function(x) as.Date(format(as.Date(x) + 32, "%Y-%m-01"))
main_lag <- as.data.table(readRDS(file.path(intermediate_dir, "lag_panel_main.rds")))
if (!nrow(main_lag)) stop("Main lag panel is empty.", call. = FALSE)
if (any(main_lag$next_period != add_month(main_lag$period))) {
  stop("Lag panel contains a non-consecutive month transition.", call. = FALSE)
}
excluded <- as.Date(c("2024-09-01", "2025-01-01", "2025-03-01", "2025-04-01", "2025-05-01", "2025-09-01"))
if (any(main_lag$period %in% excluded) || any(main_lag$next_period %in% excluded)) {
  stop("Lag panel crosses an excluded incomplete month.", call. = FALSE)
}
if (max(main_lag$period) > as.Date("2025-12-01") || max(main_lag$next_period) > as.Date("2026-01-01")) {
  stop("Lag panel exceeds the declared engagement/supply windows.", call. = FALSE)
}

models <- fread(file.path(output_dir, "lag_model.csv"), encoding = "UTF-8")
headline <- models[
  analysis_era == "main_2024_2026" & specification == "headline_raw" &
    uncertainty == "time-HAC (Bartlett, lag 2)"
]
if (nrow(headline) != 1L || !is.finite(headline$estimate) || !is.finite(headline$standard_error)) {
  stop("Headline fixed-effects result is absent or non-finite.", call. = FALSE)
}
if (headline$n_periods != 8L) {
  stop("Headline model does not contain the eight audited exact month transitions.", call. = FALSE)
}
bootstrap <- models[
  analysis_era == "main_2024_2026" & specification == "headline_raw" &
    uncertainty == "IID whole-month cluster bootstrap"
]
if (nrow(bootstrap) != 1L || !is.finite(bootstrap$conf_low) || !is.finite(bootstrap$conf_high)) {
  stop("Bootstrap result is absent or non-finite.", call. = FALSE)
}

events <- fread(file.path(output_dir, "event_results.csv"), encoding = "UTF-8")
event_feasibility <- events[result_type == "event_feasibility"]
if (nrow(event_feasibility) != 1L || !is.na(event_feasibility$estimate) ||
    !grepl("Not estimable", event_feasibility$notes, fixed = TRUE)) {
  stop("Event feasibility failure is not represented explicitly.", call. = FALSE)
}
expected_event_weeks <- format(seq(as.Date("2025-03-10"), as.Date("2025-06-02"), by = "week"), "%Y-%m-%d")
observed_event_weeks <- events[result_type == "weekly_distance", period_or_contrast]
if (!setequal(expected_event_weeks, observed_event_weeks)) {
  stop("Event output does not explicitly represent every planned week.", call. = FALSE)
}

manifest <- jsonlite::fromJSON(file.path(output_dir, "manifest.json"), simplifyVector = FALSE)
hash_file <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
current_hashes <- c(
  analysis_sha256 = hash_file(file.path(study_dir, "analysis.R")),
  checks_sha256 = hash_file(script_path),
  registry_sha256 = hash_file(file.path(study_dir, "source_registry.csv")),
  dictionary_file_sha256 = hash_file("R/lib/thematic_dictionaries.R")
)
manifest_hashes <- c(
  analysis_sha256 = manifest$code$analysis_sha256,
  checks_sha256 = manifest$code$checks_sha256,
  registry_sha256 = manifest$input$registry_sha256,
  dictionary_file_sha256 = manifest$input$dictionary_file_sha256
)
if (!identical(current_hashes, manifest_hashes)) {
  stop("Manifest code/input hashes do not match the current files; rerun analysis.R.", call. = FALSE)
}
corpus_path <- manifest$input$corpus_path
if (!file.exists(corpus_path) || !identical(hash_file(corpus_path), manifest$input$corpus_sha256)) {
  stop("Manifest corpus hash does not match the current corpus file.", call. = FALSE)
}
listed_outputs <- vapply(manifest$public_outputs, `[[`, character(1L), "path")
required_relative <- vapply(required_files[basename(required_files) != "manifest.json"], function(path) {
  sub(paste0(gsub("\\\\", "/", repo_root), "/"), "", gsub("\\\\", "/", path), fixed = TRUE)
}, character(1L))
if (!all(required_relative %in% listed_outputs)) {
  stop("Manifest does not list every required public output.", call. = FALSE)
}
for (entry in manifest$public_outputs) {
  path <- file.path(repo_root, entry$path)
  if (!file.exists(path)) stop("Manifest output missing: ", entry$path, call. = FALSE)
  observed <- digest::digest(file = path, algo = "sha256", serialize = FALSE)
  if (!identical(observed, entry$sha256)) stop("Manifest hash mismatch: ", entry$path, call. = FALSE)
}

restricted_paths <- c(
  file.path(intermediate_dir, "news_gap_month_panel.rds"),
  file.path(intermediate_dir, "news_gap_month_panel_full_text.rds"),
  file.path(intermediate_dir, "lag_panel_main.rds"),
  file.path(intermediate_dir, "lag_panel_main_full_text.rds"),
  file.path(output_dir, "private", "topic_validation_sample.csv"),
  file.path(output_dir, "private", "topic_validation_coder_sheet.csv"),
  file.path(output_dir, "private", "topic_validation_answer_key.csv"),
  file.path(output_dir, "private", "high_interaction_topic_audit.csv"),
  file.path(output_dir, "private", "high_interaction_audit_coverage.csv"),
  file.path(output_dir, "private", "high_interaction_coder_sheet.csv"),
  file.path(output_dir, "private", "high_interaction_answer_key.csv"),
  outlet_topic_path,
  outlet_figure_path,
  outlet_product_figure_paths
)
ignore_status <- vapply(restricted_paths, function(path) {
  normalized_path <- gsub("\\\\", "/", normalizePath(path, winslash = "/", mustWork = TRUE))
  normalized_root <- paste0(gsub("\\\\", "/", repo_root), "/")
  relative_path <- if (startsWith(normalized_path, normalized_root)) {
    substring(normalized_path, nchar(normalized_root) + 1L)
  } else {
    normalized_path
  }
  status <- suppressWarnings(system2("git", c("check-ignore", "-q", "--", relative_path)))
  identical(status, 0L)
}, logical(1L))
if (!all(ignore_status)) {
  stop("One or more restricted artifacts are not covered by .gitignore: ",
       paste(restricted_paths[!ignore_status], collapse = ", "), call. = FALSE)
}

coder_sheet <- fread(file.path(output_dir, "private", "topic_validation_coder_sheet.csv"),
                     encoding = "UTF-8")
answer_key <- fread(file.path(output_dir, "private", "topic_validation_answer_key.csv"),
                   encoding = "UTF-8")
forbidden_coder_columns <- c("sampling_topic", "predicted_topics", "predicted_allocations",
                             "winning_score", "winning_topics")
if (length(intersect(names(coder_sheet), forbidden_coder_columns))) {
  stop("Prediction-free coder sheet exposes model predictions.", call. = FALSE)
}
if (!setequal(coder_sheet$row_id, answer_key$row_id) || anyDuplicated(coder_sheet$row_id) ||
    anyDuplicated(answer_key$row_id)) {
  stop("Validation coder sheet and answer key do not have a unique one-to-one row mapping.", call. = FALSE)
}

interaction_audit <- fread(
  file.path(output_dir, "private", "high_interaction_topic_audit.csv"),
  encoding = "UTF-8"
)
interaction_coder_sheet <- fread(
  file.path(output_dir, "private", "high_interaction_coder_sheet.csv"),
  encoding = "UTF-8"
)
interaction_answer_key <- fread(
  file.path(output_dir, "private", "high_interaction_answer_key.csv"),
  encoding = "UTF-8"
)
interaction_coverage <- fread(
  file.path(output_dir, "private", "high_interaction_audit_coverage.csv"),
  encoding = "UTF-8"
)
if (anyDuplicated(interaction_audit$row_id) ||
    !setequal(interaction_audit$row_id, interaction_coverage$row_id) ||
    interaction_coverage[, anyDuplicated(.SD), .SDcols = c("row_id", "audit_scope", "audit_key")]) {
  stop("High-interaction audit rows and coverage map are not uniquely aligned.", call. = FALSE)
}
forbidden_interaction_coder_columns <- c(
  "product_id", "display_name", "period", "date", "URL", "interactions",
  "audit_scopes", "audit_keys", "audit_for_product_topics",
  "predicted_topics", "predicted_allocations", "winning_score", "winning_topics"
)
if (length(intersect(names(interaction_coder_sheet), forbidden_interaction_coder_columns))) {
  stop("Prediction-free high-interaction coder sheet exposes audit or model metadata.", call. = FALSE)
}
if (anyDuplicated(interaction_coder_sheet$row_id) ||
    anyDuplicated(interaction_answer_key$row_id) ||
    !setequal(interaction_coder_sheet$row_id, interaction_answer_key$row_id) ||
    !setequal(interaction_coder_sheet$row_id, interaction_audit$row_id)) {
  stop("High-interaction coder sheet, answer key, and combined audit are not one-to-one.", call. = FALSE)
}
required_audit_scopes <- c(
  "headline_product_topic_top5",
  "headline_product_month_top1",
  "lag_product_topic_month_top1"
)
if (!setequal(unique(interaction_coverage$audit_scope), required_audit_scopes)) {
  stop("High-interaction audit does not contain all required analytical scopes.", call. = FALSE)
}

headline_panel <- panel[
  analysis_era == "main_2024_2026" &
    period >= as.Date("2025-02-01") & period <= as.Date("2025-12-01") &
    !period %in% excluded & eligible_measurement
]
expected_headline_topics <- unique(headline_panel[post_mass > 0, .(
  audit_key = paste(product_id, topic, sep = "::")
)])$audit_key
expected_headline_months <- unique(headline_panel[, .(
  audit_key = paste(product_id, format(period, "%Y-%m"), sep = "::")
)])$audit_key
expected_lag_cells <- unique(main_lag[post_mass > 0, .(
  audit_key = paste(product_id, topic, format(period, "%Y-%m"), sep = "::")
)])$audit_key

audit_coverage_sets <- list(
  headline_product_topic_top5 = expected_headline_topics,
  headline_product_month_top1 = expected_headline_months,
  lag_product_topic_month_top1 = expected_lag_cells
)
for (scope in names(audit_coverage_sets)) {
  observed_keys <- unique(interaction_coverage[audit_scope == scope, audit_key])
  missing_keys <- setdiff(audit_coverage_sets[[scope]], observed_keys)
  unexpected_keys <- setdiff(observed_keys, audit_coverage_sets[[scope]])
  if (length(missing_keys) || length(unexpected_keys)) {
    stop(
      "High-interaction audit coverage mismatch for ", scope,
      "; missing=", length(missing_keys), ", unexpected=", length(unexpected_keys),
      call. = FALSE
    )
  }
}

coverage_cardinality <- interaction_coverage[, .(
  n_rows = .N,
  min_rank = min(audit_rank),
  max_rank = max(audit_rank),
  n_ranks = uniqueN(audit_rank),
  candidate_counts = uniqueN(candidate_count),
  candidate_count = unique(candidate_count)[1L]
), by = .(audit_scope, audit_key)]
if (coverage_cardinality[, any(candidate_counts != 1L | !is.finite(candidate_count) |
                               candidate_count < n_rows)]) {
  stop("High-interaction audit has invalid candidate counts.", call. = FALSE)
}
single_row_scopes <- c("headline_product_month_top1", "lag_product_topic_month_top1")
if (coverage_cardinality[
  audit_scope %in% single_row_scopes,
  any(n_rows != 1L | min_rank != 1L | max_rank != 1L | n_ranks != 1L)
]) {
  stop("A top-one high-interaction audit key does not contain exactly one row.", call. = FALSE)
}
if (coverage_cardinality[
  audit_scope == "headline_product_topic_top5",
  any(n_rows != pmin(5L, candidate_count) | min_rank != 1L |
        max_rank != n_rows | n_ranks != n_rows)
]) {
  stop("A headline product-topic audit key lacks its complete contiguous top-five sample.",
       call. = FALSE)
}

cat(sprintf(
  "News-gap checks passed: %d public topics, %s lag observations, %s current months.\n",
  nrow(field), format(headline$n_obs, big.mark = ","), format(headline$n_periods, big.mark = ",")
))
