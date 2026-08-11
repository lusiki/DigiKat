#!/usr/bin/env Rscript
# Assemble all manuscript-facing tables and scalar claims from refreshed study outputs.

suppressPackageStartupMessages({
  library(dplyr)
  library(here)
})
source(here::here("studies/catholic-education/study_input.R"), encoding = "UTF-8")

study_dir <- here::here("studies/catholic-education")
out_dir <- file.path(study_dir, "output")
tab_dir <- file.path(out_dir, "tables")

slice <- readRDS(file.path(out_dir, "slice.rds"))
catholic_education_assert_slice_current(slice)
candidates <- read.csv(
  file.path(out_dir, "candidate_sites_of_memory.csv"),
  encoding = "UTF-8",
  stringsAsFactors = FALSE
)
temporal <- read.csv(
  file.path(tab_dir, "paper_temporal_pooled.csv"),
  encoding = "UTF-8",
  stringsAsFactors = FALSE
)
sources <- read.csv(
  file.path(tab_dir, "confessional_secular_by_entity.csv"),
  encoding = "UTF-8",
  stringsAsFactors = FALSE
)
affect <- read.csv(
  file.path(tab_dir, "affect_by_entity.csv"),
  encoding = "UTF-8",
  stringsAsFactors = FALSE,
  check.names = FALSE
)
affect_run <- read.csv(
  file.path(tab_dir, "affect_run_metrics.csv"),
  encoding = "UTF-8",
  stringsAsFactors = FALSE
)
subtokens <- read.csv(
  file.path(tab_dir, "bundle_subtoken_counts.csv"),
  encoding = "UTF-8",
  stringsAsFactors = FALSE
)
coverage <- attr(slice, "corpus_month_coverage")

labels <- c(
  odgoj_vrijednosti = "Upbringing and values",
  redovi_orders = "Teaching orders",
  katolicka_skola = "Catholic schools",
  vjeronauk = "Religious instruction",
  stepinac = "Alojzije Stepinac",
  strossmayer = "Josip Juraj Strossmayer",
  stadler = "Josip Stadler",
  petkovic_marija = "Marija Petković"
)
primary <- names(labels)

anchor_summary <- candidates |>
  filter(entity %in% primary) |>
  left_join(
    temporal |>
      select(entity, pooled_monthly_cv, modal_peak_month, years_peaking_that_month,
             n_years, eligible_years_modal_month),
    by = "entity"
  ) |>
  left_join(
    sources |>
      select(entity, pct_classified, confessional_share_of_classified,
             confessional_lower_bound_all, confessional_upper_bound_all),
    by = "entity"
  ) |>
  left_join(
    affect |>
      select(entity, n_sampled, polarity_token_coverage, emotion_doc_coverage,
             mean_sentiment, Ljutnja, Strah, Tuga, Gađenje, Povjerenje, Radost),
    by = "entity"
  ) |>
  mutate(
    anchor = unname(labels[entity]),
    order = match(entity, primary)
  ) |>
  arrange(order) |>
  select(-order)

reconciled_counts <- unname(vapply(anchor_summary$entity, function(entity) {
  sum(slice[[paste0("probe_", entity)]] %in% TRUE)
}, integer(1)))
if (!all(anchor_summary$recurrence_n == reconciled_counts)) {
  stop("Anchor recurrence counts do not reconcile with slice.rds.", call. = FALSE)
}

write.csv(
  anchor_summary,
  file.path(tab_dir, "paper_anchor_summary.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

fmt_n <- function(x) formatC(as.numeric(x), format = "d", big.mark = ",", decimal.mark = ".")
fmt_pct <- function(x) paste0(formatC(100 * x, format = "f", digits = 1), "%")
fmt_cv <- function(x) formatC(x, format = "f", digits = 2)

month_names <- month.name
temporal_cell <- function(i) {
  if (is.na(anchor_summary$pooled_monthly_cv[i])) return("Not estimated")
  month <- month_names[anchor_summary$modal_peak_month[i]]
  paste0(
    "CV ", fmt_cv(anchor_summary$pooled_monthly_cv[i]), "; ", month, " peak in ",
    anchor_summary$years_peaking_that_month[i], " of ",
    anchor_summary$eligible_years_modal_month[i], " eligible years"
  )
}
source_cell <- function(i) {
  if (is.na(anchor_summary$pct_classified[i])) return("Not estimated")
  paste0(
    fmt_pct(1 - anchor_summary$confessional_share_of_classified[i]),
    " non-confessional (", fmt_pct(anchor_summary$pct_classified[i]), " classified)"
  )
}
affect_cell <- function(i) {
  entity <- anchor_summary$entity[i]
  if (is.na(anchor_summary$mean_sentiment[i])) return("Not estimated")
  if (entity == "stepinac") return("Highest anger, fear, sadness and disgust; lowest trust")
  if (entity == "katolicka_skola") return("Highest trust; low conflict-language shares")
  if (entity == "vjeronauk") return("Trust-leaning; lower conflict-language shares")
  if (entity == "odgoj_vrijednosti") return("Trust-leaning present-oriented register")
  if (entity == "redovi_orders") return("Trust-leaning institutional register")
  if (entity == "strossmayer") return("Trust-leaning; no distinct conflict profile")
  "Not estimated"
}

table_rows <- vapply(seq_len(nrow(anchor_summary)), function(i) {
  paste0(
    "| ", anchor_summary$anchor[i],
    " | ", fmt_n(anchor_summary$recurrence_n[i]),
    " | ", fmt_pct(anchor_summary$past_anchor_genuine[i]),
    " | ", temporal_cell(i),
    " | ", source_cell(i),
    " | ", affect_cell(i), " |"
  )
}, character(1))

table_md <- c(
  "**Table 1. Comparative profile of the eight primary anchors in the official corpus**",
  "",
  "| Anchor | Posts | Local past linkage | Temporal rhythm | Source boundary | Affective profile |",
  "|---|---:|---:|---|---|---|",
  table_rows,
  "",
  paste0(
    "*Note.* Local past linkage is an anchor-specific ±160-character proximity measure, not a semantic ",
    "classification. Temporal rates exclude the four unobserved months from February through May 2024. ",
    "Source shares use only classified posts. Affect is supporting evidence from the deterministic union sample."
  )
)
writeLines(table_md, file.path(tab_dir, "paper_table1.md"), useBytes = TRUE)

value_of <- function(data, key) data$value[data$metric == key][1]
affect_value <- function(key) value_of(affect_run, key)
candidate_value <- function(entity, column) candidates[[column]][candidates$entity == entity][1]
temporal_value <- function(entity, column) temporal[[column]][temporal$entity == entity][1]
source_value <- function(entity, column) sources[[column]][sources$entity == entity][1]
subtoken_value <- function(bundle, token) {
  subtokens$n[subtokens$bundle == bundle & subtokens$sub_token == token][1]
}

doc_overlap <- mean(slice$past_anchor_doc, na.rm = TRUE)
local_overlap <- mean(slice$past_anchor_genuine, na.rm = TRUE)
removed_overlap <- 1 - local_overlap / doc_overlap
derived <- bind_rows(
  data.frame(metric = "official_corpus_n", value = attr(slice, "cache_fingerprint")$input$rows,
             display = fmt_n(attr(slice, "cache_fingerprint")$input$rows), source = "analysis_input_manifest.json"),
  data.frame(metric = "corpus_2021_2025_n", value = sum(coverage$corpus_posts),
             display = fmt_n(sum(coverage$corpus_posts)), source = "corpus_month_coverage.csv"),
  data.frame(metric = "education_strand_n", value = nrow(slice), display = fmt_n(nrow(slice)), source = "slice.rds"),
  data.frame(metric = "observed_months", value = sum(coverage$observed), display = fmt_n(sum(coverage$observed)), source = "corpus_month_coverage.csv"),
  data.frame(metric = "unobserved_months", value = sum(!coverage$observed), display = fmt_n(sum(!coverage$observed)), source = "corpus_month_coverage.csv"),
  data.frame(metric = "document_overlap_share", value = doc_overlap, display = fmt_pct(doc_overlap), source = "slice.rds"),
  data.frame(metric = "local_overlap_share", value = local_overlap, display = fmt_pct(local_overlap), source = "slice.rds"),
  data.frame(metric = "overlap_removed_share", value = removed_overlap, display = fmt_pct(removed_overlap), source = "slice.rds"),
  data.frame(metric = "stepinac_n", value = candidate_value("stepinac", "recurrence_n"), display = fmt_n(candidate_value("stepinac", "recurrence_n")), source = "candidate_sites_of_memory.csv"),
  data.frame(metric = "stepinac_local_share", value = candidate_value("stepinac", "past_anchor_genuine"), display = fmt_pct(candidate_value("stepinac", "past_anchor_genuine")), source = "candidate_sites_of_memory.csv"),
  data.frame(metric = "foil_local_share", value = candidate_value("odgoj_vrijednosti", "past_anchor_genuine"), display = fmt_pct(candidate_value("odgoj_vrijednosti", "past_anchor_genuine")), source = "candidate_sites_of_memory.csv"),
  data.frame(metric = "stepinac_foil_ratio", value = candidate_value("stepinac", "past_anchor_genuine") / candidate_value("odgoj_vrijednosti", "past_anchor_genuine"), display = paste0(formatC(candidate_value("stepinac", "past_anchor_genuine") / candidate_value("odgoj_vrijednosti", "past_anchor_genuine"), format = "f", digits = 1), " times"), source = "candidate_sites_of_memory.csv"),
  data.frame(metric = "stepinac_cv", value = temporal_value("stepinac", "pooled_monthly_cv"), display = fmt_cv(temporal_value("stepinac", "pooled_monthly_cv")), source = "paper_temporal_pooled.csv"),
  data.frame(metric = "stepinac_february_peak_years", value = temporal_value("stepinac", "years_peaking_that_month"), display = fmt_n(temporal_value("stepinac", "years_peaking_that_month")), source = "paper_temporal_pooled.csv"),
  data.frame(metric = "stepinac_february_eligible_years", value = temporal_value("stepinac", "eligible_years_modal_month"), display = fmt_n(temporal_value("stepinac", "eligible_years_modal_month")), source = "paper_temporal_pooled.csv"),
  data.frame(metric = "stepinac_source_coverage", value = source_value("stepinac", "pct_classified"), display = fmt_pct(source_value("stepinac", "pct_classified")), source = "confessional_secular_by_entity.csv"),
  data.frame(metric = "stepinac_nonconf_share", value = 1 - source_value("stepinac", "confessional_share_of_classified"), display = fmt_pct(1 - source_value("stepinac", "confessional_share_of_classified")), source = "confessional_secular_by_entity.csv"),
  data.frame(metric = "affect_unique_posts", value = affect_value("unique_posts"), display = fmt_n(affect_value("unique_posts")), source = "affect_run_metrics.csv"),
  data.frame(metric = "affect_token_coverage", value = affect_value("crosentilex_token_coverage"), display = fmt_pct(affect_value("crosentilex_token_coverage")), source = "affect_run_metrics.csv"),
  data.frame(metric = "web_share_strand", value = mean(slice$SOURCE_TYPE == "web", na.rm = TRUE), display = fmt_pct(mean(slice$SOURCE_TYPE == "web", na.rm = TRUE)), source = "slice.rds"),
  data.frame(metric = "value_token_n", value = subtoken_value("odgoj_vrijednosti", "vrijednost"), display = fmt_n(subtoken_value("odgoj_vrijednosti", "vrijednost")), source = "bundle_subtoken_counts.csv"),
  data.frame(metric = "upbringing_token_n", value = subtoken_value("odgoj_vrijednosti", "odgoj"), display = fmt_n(subtoken_value("odgoj_vrijednosti", "odgoj")), source = "bundle_subtoken_counts.csv"),
  data.frame(metric = "curriculum_token_n", value = subtoken_value("odgoj_vrijednosti", "kurikul"), display = fmt_n(subtoken_value("odgoj_vrijednosti", "kurikul")), source = "bundle_subtoken_counts.csv"),
  data.frame(metric = "christian_roots_token_n", value = subtoken_value("odgoj_vrijednosti", "krscanski_korijen"), display = fmt_n(subtoken_value("odgoj_vrijednosti", "krscanski_korijen")), source = "bundle_subtoken_counts.csv")
)
write.csv(
  derived,
  file.path(tab_dir, "paper_derived.csv"),
  row.names = FALSE,
  fileEncoding = "UTF-8"
)

cat("Wrote paper_anchor_summary.csv, paper_table1.md and paper_derived.csv.\n")
